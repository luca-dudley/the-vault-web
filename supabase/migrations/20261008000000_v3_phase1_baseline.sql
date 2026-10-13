-- ==============================================================================
-- The Vault Hub (Version 3) — Migration: 20261008000000_v3_phase1_baseline.sql
-- Phase 1: Foundation, Hardening & Security Baseline
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. SAFE CLEANUP & POLICY ADDITION
-- ------------------------------------------------------------------------------

-- Drop confirmed orphaned snapshot table (zero references, zero foreign keys, zero RLS)
DROP TABLE IF EXISTS public.sandbox_jsonb_backup;

-- Deprecation notes on redundant denormalized columns (retained for zero-downtime compatibility)
-- NOTE: public.videos.company_name is DEPRECATED. Resolve company names via company_id join.
-- NOTE: public.sops.company_name is DEPRECATED. Resolve company names via company_id join.
-- NOTE: public.training_records.signature_url is DEPRECATED. Signatures stored in supervisor_signature_data / employee_signature_data.

-- Ensure RLS is active on crop_pack_addon_purchases and add tenant SELECT policy
ALTER TABLE public.crop_pack_addon_purchases ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Tenants can view own crop pack addon purchases" ON public.crop_pack_addon_purchases;
CREATE POLICY "Tenants can view own crop pack addon purchases"
ON public.crop_pack_addon_purchases
FOR SELECT
TO authenticated
USING (company_id = public.get_my_company_id());


-- ------------------------------------------------------------------------------
-- 2. CATALOG REDACTION RPC (public.get_vault_catalog())
-- ------------------------------------------------------------------------------
-- Authoritative security-definer catalog provider.
-- Redacts Vimeo video IDs and partner thumbnails for locked crop packs.
-- Core modules ('General Safety', 'Machinery & Workshop') and entitled packs remain unlocked.

CREATE OR REPLACE FUNCTION public.get_vault_catalog()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
    v_company_id uuid;
    v_tier text;
    v_unlock_all boolean;
    v_is_subsidized boolean;
    v_sponsored text[];
    v_purchased text[];
    v_has_custom_library boolean;
    v_result jsonb;
BEGIN
    -- Resolve calling user tenant context
    SELECT p.company_id, c.tier, c.unlock_all_crops, c.is_subsidized, 
           coalesce(c.sponsored_crop_packs, '{}'), coalesce(c.purchased_crop_packs, '{}')
    INTO v_company_id, v_tier, v_unlock_all, v_is_subsidized, v_sponsored, v_purchased
    FROM public.profiles p
    LEFT JOIN public.companies c ON c.id = p.company_id
    WHERE p.id = auth.uid();

    -- Check if tenant has a private estate library (e.g. Elliott, Doveton, Outlook)
    SELECT EXISTS (SELECT 1 FROM public.videos WHERE company_id = v_company_id)
    INTO v_has_custom_library;

    SELECT jsonb_agg(
        jsonb_build_object(
            'title', v.title,
            'category', v.category,
            'sub_tag', v.sub_tag,
            'curriculum_slug', v.curriculum_slug,
            'description', v.description,
            'total_seconds', v.total_seconds,
            'is_locked', is_locked,
            -- REDACTED SENSITIVE ASSETS IF LOCKED
            'id', CASE WHEN is_locked THEN 'locked' ELSE v.id END,
            'thumbnail_url', CASE 
                WHEN is_locked THEN 'https://ujhfkvoaaebdntuheyqo.supabase.co/storage/v1/object/public/thumbnails/Simple/Locked_Module_Teaser.svg'
                ELSE v.thumbnail_url 
            END,
            'partner_thumbnails', CASE WHEN is_locked THEN '{}'::jsonb ELSE v.partner_thumbnails END
        )
    ) INTO v_result
    FROM (
        SELECT v.*,
            CASE
                -- Core modules unlocked on all tiers
                WHEN lower(coalesce(v.sub_tag, '')) IN ('general safety', 'machinery & workshop') THEN false
                -- Locked on basic tier for other sub-tags
                WHEN lower(coalesce(v_tier, 'basic')) = 'basic' THEN true
                -- Custom private library override
                WHEN v_has_custom_library AND v.company_id = v_company_id THEN false
                -- Master unlock
                WHEN coalesce(v_unlock_all, false) OR coalesce(v_is_subsidized, false) THEN false
                -- Crop pack entitlement check
                WHEN v.curriculum_slug IS NOT NULL AND (
                    v.curriculum_slug = ANY(v_sponsored) OR v.curriculum_slug = ANY(v_purchased)
                ) THEN false
                -- Default locked if unpurchased / unsponsored specialized module
                ELSE true
            END AS is_locked
        FROM public.videos v
        WHERE (v.company_id IS NULL AND NOT coalesce(v_has_custom_library, false))
           OR (v.company_id = v_company_id)
        ORDER BY v.title ASC
    ) v;

    RETURN coalesce(v_result, '[]'::jsonb);
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_vault_catalog() TO authenticated;


-- ------------------------------------------------------------------------------
-- 3. STREAM RESOLUTION RPC (public.get_module_stream(p_video_id text))
-- ------------------------------------------------------------------------------
-- Authoritative stream validator that evaluates caller entitlement before
-- delivering the raw Vimeo stream ID to module.html, raising P0001 if unauthorized.

CREATE OR REPLACE FUNCTION public.get_module_stream(p_video_id text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
    v_caller_id uuid := auth.uid();
    v_company_id uuid;
    v_tier text;
    v_unlock_all boolean;
    v_is_subsidized boolean;
    v_sponsored text[];
    v_purchased text[];
    v_has_custom_library boolean;
    v_video record;
    v_is_locked boolean := true;
BEGIN
    IF v_caller_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated.' USING ERRCODE = 'P0001';
    END IF;

    -- Fetch target video metadata
    SELECT id, title, sub_tag, category, description, total_seconds, 
           curriculum_slug, company_id, objectives, questions
    INTO v_video
    FROM public.videos
    WHERE id = p_video_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Module not found: %', p_video_id USING ERRCODE = 'P0002';
    END IF;

    -- Resolve caller company context
    SELECT p.company_id, c.tier, c.unlock_all_crops, c.is_subsidized,
           coalesce(c.sponsored_crop_packs, '{}'), coalesce(c.purchased_crop_packs, '{}')
    INTO v_company_id, v_tier, v_unlock_all, v_is_subsidized, v_sponsored, v_purchased
    FROM public.profiles p
    LEFT JOIN public.companies c ON c.id = p.company_id
    WHERE p.id = v_caller_id;

    -- Check if company has custom private library
    SELECT EXISTS (SELECT 1 FROM public.videos WHERE company_id = v_company_id)
    INTO v_has_custom_library;

    -- Evaluate entitlement
    IF lower(coalesce(v_video.sub_tag, '')) IN ('general safety', 'machinery & workshop') THEN
        v_is_locked := false;
    ELSIF lower(coalesce(v_tier, 'basic')) = 'basic' THEN
        v_is_locked := true;
    ELSIF v_has_custom_library AND v_video.company_id = v_company_id THEN
        v_is_locked := false;
    ELSIF coalesce(v_unlock_all, false) OR coalesce(v_is_subsidized, false) THEN
        v_is_locked := false;
    ELSIF v_video.curriculum_slug IS NOT NULL AND (
        v_video.curriculum_slug = ANY(v_sponsored) OR v_video.curriculum_slug = ANY(v_purchased)
    ) THEN
        v_is_locked := false;
    ELSE
        v_is_locked := true;
    END IF;

    IF v_is_locked THEN
        RAISE EXCEPTION 'Unauthorized access to gated crop pack: %', p_video_id USING ERRCODE = 'P0001';
    END IF;

    RETURN jsonb_build_object(
        'id', v_video.id,
        'title', v_video.title,
        'category', v_video.category,
        'sub_tag', v_video.sub_tag,
        'description', v_video.description,
        'total_seconds', v_video.total_seconds,
        'curriculum_slug', v_video.curriculum_slug,
        'objectives', coalesce(v_video.objectives, '[]'::jsonb),
        'questions', coalesce(v_video.questions, '[]'::jsonb)
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_module_stream(text) TO authenticated;


-- ------------------------------------------------------------------------------
-- 4. STATUTORY TRAINING RECORDS DELETION GUARD & ARCHIVE RPC
-- ------------------------------------------------------------------------------

-- Revoke raw DELETE on public.training_records from standard roles (OHSA 5-year retention mandate)
REVOKE DELETE ON public.training_records FROM public, authenticated;

-- Master Admin soft-archive RPC
CREATE OR REPLACE FUNCTION public.archive_training_record(p_record_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
    -- Only Master Admin can archive records
    IF NOT EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE id = auth.uid() 
          AND lower(role) = 'master admin'
          AND company_id = (SELECT company_id FROM public.training_records WHERE id = p_record_id)
    ) THEN
        RAISE EXCEPTION 'Unauthorized: Only Master Admins may archive training records.' USING ERRCODE = 'P0001';
    END IF;

    UPDATE public.training_records
    SET status = 'Archived'
    WHERE id = p_record_id;

    RETURN jsonb_build_object('success', true, 'record_id', p_record_id);
END;
$$;

GRANT EXECUTE ON FUNCTION public.archive_training_record(uuid) TO authenticated;
