-- ==============================================================================
-- The Vault Hub (Version 3) — Migration: 20261008020000_v3_phase3_roster.sql
-- Phase 3: Field Workspace & Roster Engine
-- Reference: docs/architecture/specs/UNIFIED_INDUCTION_AND_ROSTER_SPEC.md
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. CREATE public.company_employees TABLE
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.company_employees (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    company_id uuid NOT NULL,
    employee_number text NOT NULL,
    first_name text NOT NULL,
    last_name text NOT NULL,
    id_passport_number text,
    gender text,
    team_or_orchard text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT company_employees_gender_check CHECK ((gender IS NULL OR gender = ANY (ARRAY['Male'::text, 'Female'::text, 'Other'::text])))
);

-- Primary Key
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'company_employees_pkey'
    ) THEN
        ALTER TABLE ONLY public.company_employees
            ADD CONSTRAINT company_employees_pkey PRIMARY KEY (id);
    END IF;
END $$;

-- Foreign Key to companies
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'company_employees_company_id_fkey'
    ) THEN
        ALTER TABLE ONLY public.company_employees
            ADD CONSTRAINT company_employees_company_id_fkey 
            FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE CASCADE;
    END IF;
END $$;

-- Unique constraint: Unique employee_number per company
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'company_employees_company_id_employee_number_key'
    ) THEN
        ALTER TABLE ONLY public.company_employees
            ADD CONSTRAINT company_employees_company_id_employee_number_key 
            UNIQUE (company_id, employee_number);
    END IF;
END $$;

-- Performance & Multi-Tenant Indexes
CREATE INDEX IF NOT EXISTS idx_company_employees_company_active 
    ON public.company_employees USING btree (company_id, is_active);

CREATE INDEX IF NOT EXISTS idx_company_employees_company_team 
    ON public.company_employees USING btree (company_id, team_or_orchard);

CREATE INDEX IF NOT EXISTS idx_company_employees_search 
    ON public.company_employees USING btree (company_id, employee_number, first_name, last_name);


-- ------------------------------------------------------------------------------
-- 2. ROW LEVEL SECURITY & POLICIES FOR company_employees
-- ------------------------------------------------------------------------------
ALTER TABLE public.company_employees ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view company employees" ON public.company_employees;
CREATE POLICY "Users can view company employees" 
    ON public.company_employees FOR SELECT 
    TO authenticated
    USING (company_id = public.get_my_company_id());

DROP POLICY IF EXISTS "Admins and Managers can mutate company employees" ON public.company_employees;
CREATE POLICY "Admins and Managers can mutate company employees" 
    ON public.company_employees FOR ALL 
    TO authenticated
    USING (
        company_id = public.get_my_company_id()
        AND EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE id = auth.uid() 
              AND company_id = public.company_employees.company_id
              AND lower(role) = ANY (ARRAY['master admin', 'admin', 'manager', 'safety officer'])
        )
    )
    WITH CHECK (
        company_id = public.get_my_company_id()
        AND EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE id = auth.uid() 
              AND company_id = public.company_employees.company_id
              AND lower(role) = ANY (ARRAY['master admin', 'admin', 'manager', 'safety officer'])
        )
    );

-- Statutory soft-deactivation protection: revoke raw DELETE from standard roles
REVOKE DELETE ON public.company_employees FROM public, authenticated;


-- ------------------------------------------------------------------------------
-- 3. NON-DESTRUCTIVE ALTER ON training_records
-- ------------------------------------------------------------------------------
ALTER TABLE public.training_records 
ADD COLUMN IF NOT EXISTS employee_id uuid REFERENCES public.company_employees(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_training_records_employee_id 
    ON public.training_records USING btree (employee_id);

CREATE INDEX IF NOT EXISTS idx_training_records_batch_session 
    ON public.training_records USING btree (batch_session_id);


-- ------------------------------------------------------------------------------
-- 4. ATOMIC RPC: sync_company_roster
-- ------------------------------------------------------------------------------
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
                TRIM(COALESCE(v_emp->>'first_name', 'Employee')),
                TRIM(COALESCE(v_emp->>'last_name', '')),
                NULLIF(TRIM(v_emp->>'id_passport_number'), ''),
                CASE 
                    WHEN lower(COALESCE(v_emp->>'gender', '')) IN ('m', 'male', 'man', 'seun') THEN 'Male'
                    WHEN lower(COALESCE(v_emp->>'gender', '')) IN ('f', 'female', 'vrou', 'meisie') THEN 'Female'
                    ELSE 'Other'
                END,
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


-- ------------------------------------------------------------------------------
-- 5. ATOMIC RPC: log_induction_session
-- ------------------------------------------------------------------------------
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
    IF v_trainee_count = 1 THEN
        v_training_type := 'Individual';
        v_batch_session_id := NULL;
    ELSE
        v_training_type := 'Batch';
        v_batch_session_id := gen_random_uuid();
    END IF;

    -- 4. Insert each trainee record atomically
    FOR v_trainee IN SELECT * FROM jsonb_array_elements(p_trainees)
    LOOP
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
            TRIM(COALESCE(v_trainee->>'employee_name', 'Unnamed Worker')),
            NULLIF(TRIM(v_trainee->>'employee_number'), ''),
            COALESCE(NULLIF(TRIM(v_trainee->>'gender'), ''), 'Male'),
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
