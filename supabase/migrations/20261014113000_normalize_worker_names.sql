-- ==============================================================================
-- The Vault Hub — Migration: 20261014113000_normalize_worker_names.sql
-- Fix Duplicate Surname Parsing & Normalize Worker Names
-- ==============================================================================

-- 1. Remediation: Clean up existing rows in public.company_employees
-- where first_name ends with last_name (e.g. 'Ms Z BALENI' and 'BALENI')
-- Preserves titles (Mr, Ms, Mrs, Miss) and initials cleanly.
UPDATE public.company_employees
SET 
    first_name = TRIM(SUBSTRING(first_name FROM 1 FOR LENGTH(first_name) - LENGTH(last_name))),
    updated_at = NOW()
WHERE 
    last_name IS NOT NULL 
    AND TRIM(last_name) <> ''
    AND LENGTH(TRIM(first_name)) > LENGTH(TRIM(last_name))
    AND (
        LOWER(TRIM(first_name)) LIKE '% ' || LOWER(TRIM(last_name))
        OR LOWER(TRIM(first_name)) LIKE '%-' || LOWER(TRIM(last_name))
    );

-- 2. Update sync_company_roster RPC to defensively normalize surnames on import
CREATE OR REPLACE FUNCTION public.sync_company_roster(
    p_employees jsonb,
    p_deactivate_missing boolean DEFAULT false
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
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
    v_ln text;
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
            v_ln := TRIM(COALESCE(v_emp->>'last_name', ''));

            -- Defensive de-duplication: if first_name ends with last_name (e.g. 'Ms Z BALENI' and 'BALENI')
            IF v_ln <> '' AND length(v_fn) > length(v_ln) AND (lower(v_fn) LIKE '% ' || lower(v_ln) OR lower(v_fn) LIKE '%-' || lower(v_ln)) THEN
                v_fn := TRIM(substring(v_fn from 1 for length(v_fn) - length(v_ln)));
            ELSIF v_ln <> '' AND lower(v_fn) = lower(v_ln) THEN
                v_fn := v_ln;
                v_ln := '';
            END IF;

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
                v_ln,
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
        'upserted_count', v_inserted,
        'deactivated_count', v_deactivated,
        'total_processed', array_length(v_uploaded_numbers, 1)
    );
END;
$$;
