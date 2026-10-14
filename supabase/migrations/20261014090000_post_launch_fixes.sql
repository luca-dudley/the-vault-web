-- ==============================================================================
-- POST-LAUNCH FIXES: GENDER NORMALIZATION & STATUTORY TRAINING REGISTERS
-- Migration: 20261014090000_post_launch_fixes.sql
-- ==============================================================================

-- 1. UPDATE ATOMIC RPC: sync_company_roster
-- Adds comprehensive gender parsing (M, Male, m, Man, F, Female, f, Woman, Vrou, etc.)
-- and title fallback (Mr/Ms/Miss) to prevent fallback to 'Other'.
CREATE OR REPLACE FUNCTION public.sync_company_roster(
    p_employees jsonb,
    p_deactivate_missing boolean DEFAULT false
) 
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
    v_company_id uuid;
    v_emp jsonb;
    v_inserted int := 0;
    v_deactivated int := 0;
    v_uploaded_numbers text[] := '{}';
    v_caller_role text;
    v_raw_gender text;
    v_fn text;
    v_parsed_gender text;
BEGIN
    -- 1. Resolve tenant company ID
    v_company_id := get_my_company_id();
    IF v_company_id IS NULL THEN
        RAISE EXCEPTION 'Unauthorized: Caller has no active company profile.';
    END IF;

    -- 2. Verify caller permissions (Admin, Manager, Safety Officer)
    SELECT lower(role) INTO v_caller_role FROM public.profiles WHERE id = auth.uid();
    IF v_caller_role NOT IN ('master admin', 'admin', 'manager', 'safety officer') THEN
        RAISE EXCEPTION 'Forbidden: Insufficient privileges to update employee roster.';
    END IF;

    -- 3. Loop through employees array and UPSERT
    FOR v_emp IN SELECT * FROM jsonb_array_elements(p_employees)
    LOOP
        IF NULLIF(TRIM(v_emp->>'employee_number'), '') IS NOT NULL THEN
            v_uploaded_numbers := array_append(v_uploaded_numbers, TRIM(v_emp->>'employee_number'));
            v_raw_gender := lower(TRIM(COALESCE(v_emp->>'gender', '')));
            v_fn := TRIM(COALESCE(v_emp->>'first_name', 'Employee'));

            -- Robust gender normalization for real-world payroll exports
            IF v_raw_gender IN ('f', 'female', 'fem', 'w', 'woman', 'women', 'vrou', 'vroulik', 'vroue', 'meisie', 'girl', 'lady', 'dame', 'mrs', 'ms', 'miss', 'mej')
               OR v_raw_gender LIKE 'f%'
               OR v_raw_gender LIKE 'w%'
               OR v_raw_gender LIKE 'v%'
               OR v_raw_gender ~* '\m(female|woman|women|vrou|vroulik|meisie|girl|lady)\M' THEN
                v_parsed_gender := 'Female';
            ELSIF v_raw_gender IN ('m', 'male', 'man', 'men', 'seun', 'boy', 'manlik', 'mr', 'mnr')
               OR (v_raw_gender LIKE 'm%' AND v_raw_gender NOT LIKE 'me%')
               OR v_raw_gender ~* '\m(male|man|men|seun|boy|manlik)\M' THEN
                v_parsed_gender := 'Male';
            ELSIF v_fn ~* '^(ms|mrs|miss|mej)[\. ]' THEN
                v_parsed_gender := 'Female';
            ELSIF v_fn ~* '^(mr|mnr)[\. ]' THEN
                v_parsed_gender := 'Male';
            ELSIF v_raw_gender = 'other' THEN
                v_parsed_gender := 'Other';
            ELSE
                v_parsed_gender := 'Other';
            END IF;

            INSERT INTO public.company_employees (
                company_id,
                employee_number,
                first_name,
                last_name,
                id_passport_number,
                gender,
                team_or_orchard,
                is_active,
                updated_at
            ) VALUES (
                v_company_id,
                TRIM(v_emp->>'employee_number'),
                v_fn,
                TRIM(COALESCE(v_emp->>'last_name', '')),
                NULLIF(TRIM(v_emp->>'id_passport_number'), ''),
                v_parsed_gender,
                NULLIF(TRIM(v_emp->>'team_or_orchard'), ''),
                true,
                now()
            )
            ON CONFLICT (company_id, employee_number) 
            DO UPDATE SET
                first_name = EXCLUDED.first_name,
                last_name = EXCLUDED.last_name,
                id_passport_number = COALESCE(EXCLUDED.id_passport_number, company_employees.id_passport_number),
                gender = EXCLUDED.gender,
                team_or_orchard = COALESCE(EXCLUDED.team_or_orchard, company_employees.team_or_orchard),
                is_active = true,
                updated_at = now();

            v_inserted := v_inserted + 1;
        END IF;
    END LOOP;

    -- 4. Deactivate employees not in upload if seasonal replace requested
    IF p_deactivate_missing THEN
        UPDATE public.company_employees
        SET is_active = false, updated_at = now()
        WHERE company_id = v_company_id
          AND is_active = true
          AND NOT (employee_number = ANY(v_uploaded_numbers));
        
        GET DIAGNOSTICS v_deactivated = ROW_COUNT;
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'upserted_count', v_inserted,
        'deactivated_count', v_deactivated,
        'total_processed', jsonb_array_length(p_employees)
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.sync_company_roster(jsonb, boolean) TO authenticated;


-- 2. UPDATE ATOMIC RPC: log_induction_session
-- Ensures v_batch_session_id is ALWAYS generated (for 1 person or 50 people)
-- and trainee gender is normalized.
CREATE OR REPLACE FUNCTION public.log_induction_session(
    p_module_title text,
    p_supervisor_name text,
    p_supervisor_signature text,
    p_trainees jsonb -- Array of { employee_id, employee_name, employee_number, gender }
)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
    v_company_id uuid;
    v_trainee_count int;
    v_batch_session_id uuid;
    v_training_type text;
    v_trainee jsonb;
    v_inserted_ids uuid[] := '{}';
    v_new_id uuid;
    v_raw_gender text;
    v_name text;
    v_parsed_gender text;
BEGIN
    -- 1. Authenticate caller and resolve company_id
    v_company_id := get_my_company_id();
    IF v_company_id IS NULL THEN
        RAISE EXCEPTION 'Unauthorized: Caller has no active company profile.';
    END IF;

    -- 2. Validate inputs
    v_trainee_count := jsonb_array_length(p_trainees);
    IF v_trainee_count = 0 THEN
        RAISE EXCEPTION 'Validation Failed: At least one trainee must be selected.';
    END IF;

    IF v_trainee_count > 80 THEN
        RAISE EXCEPTION 'Statutory Limit Exceeded: Induction batches cannot exceed 80 workers per session.';
    END IF;

    IF TRIM(COALESCE(p_supervisor_name, '')) = '' THEN
        RAISE EXCEPTION 'Validation Failed: Supervising Officer name is mandatory.';
    END IF;

    IF TRIM(COALESCE(p_supervisor_signature, '')) = '' THEN
        RAISE EXCEPTION 'Validation Failed: Supervisor digital signature is mandatory.';
    END IF;

    -- 3. Determine training format & session ID
    -- Always assign a batch_session_id for statutory register generation and audit traceability
    v_batch_session_id := gen_random_uuid();
    IF v_trainee_count = 1 THEN
        v_training_type := 'Individual';
    ELSE
        v_training_type := 'Batch';
    END IF;

    -- 4. Insert each trainee record atomically
    FOR v_trainee IN SELECT * FROM jsonb_array_elements(p_trainees)
    LOOP
        v_raw_gender := lower(TRIM(COALESCE(v_trainee->>'gender', '')));
        v_name := TRIM(COALESCE(v_trainee->>'employee_name', 'Unnamed Worker'));

        IF v_raw_gender IN ('f', 'female', 'fem', 'w', 'woman', 'women', 'vrou', 'vroulik', 'vroue', 'meisie', 'girl', 'lady', 'dame', 'mrs', 'ms', 'miss', 'mej')
           OR v_raw_gender LIKE 'f%'
           OR v_raw_gender LIKE 'w%'
           OR v_raw_gender LIKE 'v%'
           OR v_raw_gender ~* '\m(female|woman|women|vrou|vroulik|meisie|girl|lady)\M' THEN
            v_parsed_gender := 'Female';
        ELSIF v_raw_gender IN ('m', 'male', 'man', 'men', 'seun', 'boy', 'manlik', 'mr', 'mnr')
           OR (v_raw_gender LIKE 'm%' AND v_raw_gender NOT LIKE 'me%')
           OR v_raw_gender ~* '\m(male|man|men|seun|boy|manlik)\M' THEN
            v_parsed_gender := 'Male';
        ELSIF v_name ~* '^(ms|mrs|miss|mej)[\. ]' THEN
            v_parsed_gender := 'Female';
        ELSIF v_name ~* '^(mr|mnr)[\. ]' THEN
            v_parsed_gender := 'Male';
        ELSIF v_raw_gender = 'other' THEN
            v_parsed_gender := 'Other';
        ELSE
            v_parsed_gender := 'Male'; -- Fallback default for training sign-offs if unspecified
        END IF;

        INSERT INTO public.training_records (
            company_id,
            employee_id,
            employee_name,
            employee_number,
            gender,
            module_title,
            training_type,
            supervisor_name,
            supervisor_signature_data,
            employee_signature_data,
            batch_session_id,
            status,
            completed_at,
            created_at
        ) VALUES (
            v_company_id,
            NULLIF(v_trainee->>'employee_id', '')::uuid,
            v_name,
            NULLIF(TRIM(v_trainee->>'employee_number'), ''),
            v_parsed_gender,
            TRIM(p_module_title),
            v_training_type,
            TRIM(p_supervisor_name),
            p_supervisor_signature,
            NULL, -- Individual canvas signature bypassed in favor of ECTA §13 Supervisor Gate
            v_batch_session_id,
            'Verified',
            CURRENT_DATE,
            now()
        )
        RETURNING id INTO v_new_id;

        v_inserted_ids := array_append(v_inserted_ids, v_new_id);
    END LOOP;

    RETURN jsonb_build_object(
        'success', true,
        'training_type', v_training_type,
        'batch_session_id', v_batch_session_id,
        'trainee_count', v_trainee_count,
        'record_ids', v_inserted_ids
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.log_induction_session(text, text, text, jsonb) TO authenticated;


-- 3. DATA RECONCILIATION & BACKFILL
-- Backfill existing training_records with null batch_session_id
UPDATE public.training_records
SET batch_session_id = gen_random_uuid()
WHERE batch_session_id IS NULL;

-- Heal existing company_employees where gender is 'Other' but title is present in first_name
UPDATE public.company_employees
SET gender = 'Female', updated_at = now()
WHERE gender = 'Other' AND first_name ~* '^(ms|mrs|miss|mej)[\. ]';

UPDATE public.company_employees
SET gender = 'Male', updated_at = now()
WHERE gender = 'Other' AND first_name ~* '^(mr|mnr)[\. ]';

-- Heal existing training_records where gender is 'Other' but title is present in employee_name
UPDATE public.training_records
SET gender = 'Female'
WHERE gender = 'Other' AND employee_name ~* '^(ms|mrs|miss|mej)[\. ]';

UPDATE public.training_records
SET gender = 'Male'
WHERE gender = 'Other' AND employee_name ~* '^(mr|mnr)[\. ]';
