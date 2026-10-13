-- ==============================================================================
-- The Vault Hub (Version 3) — Migration: 20261008010000_v3_phase2_streams.sql
-- Phase 2: Video Hub & Multilingual Audio Streams
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. ADD STREAMS COLUMN (NON-DESTRUCTIVE)
-- ------------------------------------------------------------------------------
ALTER TABLE public.videos 
ADD COLUMN IF NOT EXISTS streams jsonb DEFAULT '{}'::jsonb;

-- ------------------------------------------------------------------------------
-- 2. SEED CANONICAL TRAINING VIDEOS WITH MULTILINGUAL STREAMS
-- ------------------------------------------------------------------------------
-- Seed General Farm Employees (1187071628) with English, isiZulu, and Afrikaans
UPDATE public.videos
SET streams = jsonb_build_object(
    'en', jsonb_build_object('vimeo_id', '1187071628', 'label', 'English'),
    'zu', jsonb_build_object('vimeo_id', '1187071628', 'label', 'isiZulu'),
    'af', jsonb_build_object('vimeo_id', '1187071628', 'label', 'Afrikaans')
)
WHERE id = '1187071628';

-- Seed Citrus Harvesting Safety (1229871127) with English, isiZulu, and Afrikaans
UPDATE public.videos
SET streams = jsonb_build_object(
    'en', jsonb_build_object('vimeo_id', '1229871127', 'label', 'English'),
    'zu', jsonb_build_object('vimeo_id', '1229871127', 'label', 'isiZulu'),
    'af', jsonb_build_object('vimeo_id', '1229871127', 'label', 'Afrikaans')
)
WHERE id = '1229871127';


-- ------------------------------------------------------------------------------
-- 3. UPDATE CATALOG REDACTION RPC (public.get_vault_catalog())
-- ------------------------------------------------------------------------------
-- Includes 'streams' (redacted when locked, delivered when unlocked) and 'language'

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
            'language', v.language,
            'is_locked', is_locked,
            -- REDACTED SENSITIVE ASSETS IF LOCKED
            'id', CASE WHEN is_locked THEN 'locked' ELSE v.id END,
            'thumbnail_url', CASE 
                WHEN is_locked THEN 'https://ujhfkvoaaebdntuheyqo.supabase.co/storage/v1/object/public/thumbnails/Simple/Locked_Module_Teaser.svg'
                ELSE v.thumbnail_url 
            END,
            'partner_thumbnails', CASE WHEN is_locked THEN '{}'::jsonb ELSE coalesce(v.partner_thumbnails, '{}'::jsonb) END,
            'streams', CASE WHEN is_locked THEN '{}'::jsonb ELSE coalesce(v.streams, '{}'::jsonb) END
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
-- 4. UPDATE STREAM RESOLUTION RPC (public.get_module_stream(p_video_id text))
-- ------------------------------------------------------------------------------
-- Validates authorization and delivers multi-language stream definitions

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
           curriculum_slug, company_id, objectives, questions, language, streams
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
        'language', v_video.language,
        'objectives', coalesce(v_video.objectives, '[]'::jsonb),
        'questions', coalesce(v_video.questions, '[]'::jsonb),
        'streams', CASE 
            WHEN v_video.streams IS NOT NULL AND jsonb_typeof(v_video.streams) = 'object' AND v_video.streams <> '{}'::jsonb 
            THEN v_video.streams 
            ELSE jsonb_build_object('en', jsonb_build_object('vimeo_id', v_video.id, 'label', coalesce(v_video.language, 'English')))
        END
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_module_stream(text) TO authenticated;
