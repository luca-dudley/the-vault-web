-- =============================================================================
-- Migration: 20261008030000_v3_phase4_incidents_stamp.sql
-- Description: Phase 4 Statutory Incident Register & Company Stamp Engine
-- Prime Authority: THE_VAULT_V3_HUB_SPEC.md Sections 6 & 7
-- Zero-Downtime Guarantee: Additive DDL with IF NOT EXISTS. Existing data intact.
-- =============================================================================

-- 1. Add company_stamp_url to public.companies
ALTER TABLE public.companies 
ADD COLUMN IF NOT EXISTS company_stamp_url text;

COMMENT ON COLUMN public.companies.company_stamp_url IS 'Public storage URL to official transparent PNG company seal or round stamp.';

-- 2. Create public.incident_reports Table (OHSA Sec 24, GAR 9, SIZA & GlobalG.A.P.)
CREATE TABLE IF NOT EXISTS public.incident_reports (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    incident_number text NOT NULL, -- e.g. "INC-2026-001"
    incident_date date NOT NULL,
    incident_time time NOT NULL,
    reported_at timestamptz DEFAULT timezone('utc'::text, now()) NOT NULL,
    location_or_orchard text NOT NULL, -- e.g. "Citrus Block 12B - Packhouse Sorting Line"
    employee_id uuid REFERENCES public.company_employees(id) ON DELETE SET NULL,
    injured_person_name text NOT NULL,
    injured_person_id_number text,
    injured_person_role text NOT NULL, -- e.g. "Picker", "Tractor Driver", "Packhouse Operator"
    gender text,
    incident_severity text NOT NULL,
    nature_of_injury text, -- e.g. "Laceration", "Chemical Exposure", "Fracture"
    body_part text,        -- e.g. "Right Hand", "Left Eye", "Lumbar Spine"
    equipment_chemical_involved text, -- e.g. "Tractor PTO Shaft", "Copper Fungicide", "Hydraulic Sorter"
    incident_description text NOT NULL,
    root_cause_analysis text NOT NULL,
    corrective_preventative_actions text NOT NULL,
    action_assigned_to text NOT NULL,
    action_target_date date NOT NULL,
    action_completed_date date,
    is_section_24_statutory boolean DEFAULT false NOT NULL, -- Mandatory DoL 7-Day Trigger
    section_24_reported_at timestamptz,
    investigated_by_name text NOT NULL,
    investigated_by_role text NOT NULL, -- e.g. "Section 16(2) Appointee", "Safety Officer"
    investigator_signature text NOT NULL, -- Base64 Canvas Signature Data
    status text DEFAULT 'Open' NOT NULL,
    attachments jsonb DEFAULT '[]'::jsonb NOT NULL,
    created_at timestamptz DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamptz DEFAULT timezone('utc'::text, now()) NOT NULL,

    CONSTRAINT incident_severity_check CHECK (incident_severity = ANY (ARRAY[
        'Near Miss'::text,
        'First Aid Only'::text,
        'Medical Treatment (Doctor)'::text,
        'Disabling Injury (> 3 Days Lost Time)'::text,
        'Fatal / Section 24 Major'::text
    ])),
    CONSTRAINT incident_status_check CHECK (status = ANY (ARRAY[
        'Open'::text,
        'Under Investigation'::text,
        'Action Pending'::text,
        'Resolved / Closed'::text
    ]))
);

-- Performance & Reporting Indexes
CREATE INDEX IF NOT EXISTS idx_incidents_company ON public.incident_reports USING btree (company_id, incident_date DESC);
CREATE INDEX IF NOT EXISTS idx_incidents_statutory ON public.incident_reports USING btree (company_id, is_section_24_statutory);
CREATE INDEX IF NOT EXISTS idx_incidents_employee ON public.incident_reports USING btree (employee_id);

-- 3. Multi-Tenant Row Level Security (RLS)
ALTER TABLE public.incident_reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Tenants can manage their own incident reports" ON public.incident_reports;

CREATE POLICY "Tenants can manage their own incident reports"
ON public.incident_reports FOR ALL TO authenticated
USING (company_id = public.get_my_company_id())
WITH CHECK (company_id = public.get_my_company_id());
