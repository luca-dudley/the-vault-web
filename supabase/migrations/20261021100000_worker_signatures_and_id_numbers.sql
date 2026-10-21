-- Migration: 20261021100000_worker_signatures_and_id_numbers.sql
-- Description: Add id_passport_number to training_records, index it, and update log_induction_session RPC to store worker digital signatures and resolve ID numbers.

-- 1. ADD COLUMN id_passport_number TO public.training_records
ALTER TABLE public.training_records 
ADD COLUMN IF NOT EXISTS id_passport_number text;

-- 2. CREATE INDEX ON (company_id, id_passport_number)
CREATE INDEX IF NOT EXISTS idx_training_records_company_id_passport 
ON public.training_records USING btree (company_id, id_passport_number);

-- 3. BACKFILL EXISTING RECORDS FROM company_employees IF NULL
UPDATE public.training_records tr
SET id_passport_number = ce.id_passport_number
FROM public.company_employees ce
WHERE tr.employee_id = ce.id
  AND tr.id_passport_number IS NULL
  AND ce.id_passport_number IS NOT NULL;

-- 4. UPDATE ATOMIC RPC: log_induction_session
CREATE OR REPLACE FUNCTION public.log_induction_session(
    p_module_title text,
    p_supervisor_name text,
    p_supervisor_signature text,
    p_trainees jsonb -- Array of { employee_id, employee_name, employee_number, id_passport_number, gender, employee_signature_data }
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
    v_emp_id uuid;
    v_emp_number text;
    v_id_passport_number text;
    v_employee_sig text;
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

        v_emp_id := NULLIF(TRIM(v_trainee->>'employee_id'), '')::uuid;
        v_emp_number := NULLIF(TRIM(v_trainee->>'employee_number'), '');
        
        -- Resolve id_passport_number:
        -- 1. Direct from trainee payload
        v_id_passport_number := NULLIF(TRIM(v_trainee->>'id_passport_number'), '');
        -- 2. Fallback: If empty but employee_id exists, lookup from company_employees
        IF v_id_passport_number IS NULL AND v_emp_id IS NOT NULL THEN
            SELECT ce.id_passport_number INTO v_id_passport_number
            FROM public.company_employees ce
            WHERE ce.id = v_emp_id
              AND ce.company_id = v_company_id;
        END IF;

        -- Fallback for employee_number if empty but employee_id exists
        IF v_emp_number IS NULL AND v_emp_id IS NOT NULL THEN
            SELECT ce.employee_number INTO v_emp_number
            FROM public.company_employees ce
            WHERE ce.id = v_emp_id
              AND ce.company_id = v_company_id;
        END IF;

        -- Worker digital signature data: NULLIF empty string, remains NULL if not provided
        v_employee_sig := NULLIF(TRIM(v_trainee->>'employee_signature_data'), '');

        INSERT INTO public.training_records (
            company_id,
            employee_id,
            employee_name,
            employee_number,
            id_passport_number,
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
            v_emp_id,
            v_name,
            v_emp_number,
            v_id_passport_number,
            v_parsed_gender,
            TRIM(p_module_title),
            v_training_type,
            TRIM(p_supervisor_name),
            p_supervisor_signature,
            v_employee_sig,
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
