# Live Supabase Schema Manifest
> **Last Synchronized:** 2026-10-02 09:36:30 UTC
> **Source:** Remote Supabase Instance via pg_dump (Direct Connection)

---

## 1. Relational Database Schema & Policies (DDL)

```sql
--
-- PostgreSQL database dump
--

\restrict xksefeBOjc5hZVxvO8kPM3rsjAHpNHbG2R4Ev9PUafQEhLMIKlhfGv5KE2uj7Am

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.11 (Ubuntu 17.11-1.pgdg24.04+2)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA public;


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: claim_additional_grower_subsidy(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.claim_additional_grower_subsidy(p_grower_code text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$declare
  v_caller_id    uuid := auth.uid();
  v_caller_role  text;
  v_company_id   uuid;
  v_registry_row public.partner_grower_registry%rowtype;
  v_partner_row  public.corporate_partners%rowtype;
  v_crop         text;
  v_sponsored    text[];
  v_purchased    text[];
  v_codes        text[];
  v_was_boltOn   boolean := false;
begin
  if v_caller_id is null then
    raise exception 'Not authenticated.';
  end if;

  select company_id, role into v_company_id, v_caller_role
  from public.profiles
  where id = v_caller_id;

  if v_company_id is null then
    raise exception 'Your account is not linked to an organization.';
  end if;

  if coalesce(v_caller_role, '') not in ('Master Admin') then
    raise exception 'Only an organization admin can link a processor grower code.';
  end if;

  if p_grower_code is null or btrim(p_grower_code) = '' then
    raise exception 'No grower code supplied.';
  end if;

  select * into v_registry_row
  from public.partner_grower_registry
  where upper(grower_code) = upper(btrim(p_grower_code))
  for update;

  if not found then
    raise exception 'Grower code not recognized.';
  end if;

  if not coalesce(v_registry_row.is_active, false) then
    raise exception 'This grower code is no longer active.';
  end if;

  if v_registry_row.claimed_by_company_id is not null
     and v_registry_row.claimed_by_company_id <> v_company_id then
    raise exception 'This grower code has already been claimed by another organization.';
  end if;

  select * into v_partner_row
  from public.corporate_partners
  where id = v_registry_row.partner_id;

  if not found then
    raise exception 'Sponsoring partner record is missing.';
  end if;

  v_crop := v_partner_row.sponsored_crop_pack;

  select coalesce(purchased_crop_packs, '{}'::text[]) into v_purchased
  from public.companies where id = v_company_id for update;

  v_was_boltOn := v_purchased @> array[v_crop]::text[];

  select array(
    select distinct unnest(coalesce((select sponsored_crop_packs from public.companies where id = v_company_id), '{}'::text[]) || array[v_crop]::text[])
  ) into v_sponsored;

  select array(
    select distinct unnest(coalesce((select partner_grower_codes from public.companies where id = v_company_id), '{}'::text[]) || array[upper(btrim(p_grower_code))]::text[])
  ) into v_codes;

  update public.companies
  set sponsored_crop_packs = v_sponsored,
      partner_grower_codes = v_codes,
      -- Bolt-on → sponsored transition: a crop can't be both self-funded and
      -- processor-sponsored at once. array_remove is a no-op if it wasn't there.
      purchased_crop_packs = array_remove(coalesce(purchased_crop_packs, '{}'::text[]), v_crop)
  where id = v_company_id;

  update public.partner_grower_registry
  set claimed_by_company_id = v_company_id,
      claimed_at = now()
  where id = v_registry_row.id
    and claimed_by_company_id is null;

  -- Queue the Paystack cancellation for the Edge Function worker to pick up.
  -- This never touches Paystack directly from here - see note at top of file.
  if v_was_boltOn then
    update public.crop_pack_addon_subscriptions
    set status = 'pending_cancellation',
        cancellation_requested_at = now()
    where company_id = v_company_id
      and crop_name = v_crop
      and status = 'active';
  end if;

  return jsonb_build_object(
    'success', true,
    'crop', v_crop,
    'partner_name', v_partner_row.name,
    'partner_logo_url', v_partner_row.logo_url,
    'sponsored_crop_packs', v_sponsored,
    'bolt_on_cancelled', v_was_boltOn
  );
end;$$;


--
-- Name: get_my_company_id(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_my_company_id() RETURNS uuid
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT company_id
  FROM public.profiles
  WHERE id = auth.uid()
$$;


--
-- Name: get_partner_portal_data(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_partner_portal_data(p_token text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_partner_id   uuid;
  v_partner      record;
  v_growers      jsonb;
  v_modules      jsonb;
  v_total_codes  int;
begin
  -- 1. Validate Token (active, unexpired, unrevoked)
  select partner_id into v_partner_id
  from public.partner_portal_tokens
  where token = p_token
    and (expires_at is null or expires_at > now())
    and revoked_at is null;

  if v_partner_id is null then
    return jsonb_build_object('success', false, 'error', 'Invalid or expired access token.');
  end if;

  -- 2. Partner Metadata & Allocation
  select id, name, slug, logo_url, sponsored_crop_pack, contact_email
  into v_partner
  from public.corporate_partners
  where id = v_partner_id;

  select count(*) into v_total_codes
  from public.partner_grower_registry
  where partner_id = v_partner_id
    and is_active = true;

  -- 3. True Module Breakdown across all growers for this partner (Last 90 Days)
  select coalesce(jsonb_agg(m_row), '[]'::jsonb) into v_modules
  from (
    select 
      tr.module_title as module_name,
      count(*) as completions
    from public.training_records tr
    join public.partner_grower_registry pgr on pgr.claimed_by_company_id = tr.company_id
    where pgr.partner_id = v_partner_id
      and tr.completed_at >= (current_date - interval '90 days')
    group by tr.module_title
    order by completions desc
    limit 6
  ) m_row;

  -- 4. Grower Roster with Audit-Grade Evidence
  select coalesce(jsonb_agg(g_row), '[]'::jsonb) into v_growers
  from (
    select 
      pgr.grower_code,
      c.id as company_id,
      coalesce(c.name, pgr.company_name) as company_name,
      pgr.claimed_at is not null as is_claimed,
      coalesce(c.is_subsidized, false) as is_subsidized,
      
      -- Workforce Denominator (SIZA/GlobalGAP: trained vs total on estate)
      coalesce(w_stats.total_workforce, c.seat_limit, 10) as total_workforce_headcount,

      -- Headcount vs Total Completions
      coalesce(t_stats.unique_headcount, 0) as unique_workers_inducted_90d,
      coalesce(t_stats.total_completions, 0) as total_training_records_90d,
      coalesce(t_stats.distinct_modules, 0) as distinct_modules_completed,
      t_stats.last_training_at,
      
      -- Signature Integrity Metric
      case 
        when coalesce(t_stats.total_completions, 0) = 0 then 100
        else round((t_stats.signed_completions::numeric / t_stats.total_completions::numeric) * 100)
      end as signature_integrity_pct,

      -- Dark Supplier Definition (>60 days inactive)
      case 
        when t_stats.last_training_at is null then true
        when t_stats.last_training_at < (current_date - interval '60 days') then true
        else false
      end as is_dark_supplier,

      -- Statutory Baseline Risk Assessments
      coalesce(bra_stats.bra_overdue, 0) as baseline_reviews_overdue,
      coalesce(bra_stats.bra_total, 0) as baseline_reviews_total,
      bra_stats.last_bra_date,
      bra_stats.next_bra_due_date,
      
      -- Equipment/Task-Level Operational Risk Assessments
      coalesce(ora_stats.ora_total, 0) as operational_assessments_total

    from public.partner_grower_registry pgr
    left join public.companies c on c.id = pgr.claimed_by_company_id
    
    -- Workforce headcount calculation
    left join lateral (
      select count(*) as total_workforce
      from public.profiles p
      where p.company_id = c.id
    ) w_stats on true

    -- Training metrics & digital signature verification join
    left join lateral (
      select 
        count(distinct tr.employee_name) as unique_headcount,
        count(*) as total_completions,
        count(*) filter (
          where tr.supervisor_signature_data is not null 
             or tr.signature_url is not null
        ) as signed_completions,
        count(distinct tr.module_title) as distinct_modules,
        max(tr.completed_at) as last_training_at
      from public.training_records tr
      where tr.company_id = c.id
        and tr.completed_at >= (current_date - interval '90 days')
    ) t_stats on true

    -- Baseline Risk Assessments
    left join lateral (
      select 
        count(*) filter (where cba.review_due_date < current_date) as bra_overdue,
        count(*) as bra_total,
        max(cba.assessment_date) as last_bra_date,
        min(cba.review_due_date) as next_bra_due_date
      from public.company_baseline_assessments cba
      where cba.company_id = c.id
    ) bra_stats on true

    -- Operational Risk Assessments
    left join lateral (
      select count(*) as ora_total
      from public.company_risk_assessments cra
      where cra.company_id = c.id
    ) ora_stats on true

    where pgr.partner_id = v_partner_id
      and pgr.is_active = true
    order by c.name nulls last, pgr.grower_code asc
  ) g_row;

  return jsonb_build_object(
    'success', true,
    'partner', jsonb_build_object(
      'id', v_partner.id,
      'name', v_partner.name,
      'slug', v_partner.slug,
      'logo_url', v_partner.logo_url,
      'sponsored_crop_pack', v_partner.sponsored_crop_pack,
      'contact_email', v_partner.contact_email,
      'total_allotted_growers', v_total_codes
    ),
    'modules', v_modules,
    'growers', v_growers
  );
end;
$$;


--
-- Name: provision_company_baseline_register(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.provision_company_baseline_register(p_company_id uuid, p_designated_person text) RETURNS TABLE(inserted integer, total integer)
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
DECLARE 
  v_inserted integer;
BEGIN
  IF p_designated_person IS NULL OR btrim(p_designated_person) = '' THEN
    RAISE EXCEPTION 'p_designated_person is required (designated_person_name is NOT NULL)';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM public.companies WHERE id = p_company_id) THEN
    RAISE EXCEPTION 'Company UUID % does not exist in registry', p_company_id;
  END IF;

  INSERT INTO public.company_baseline_assessments
    (company_id, template_id, title, category, assessment_date, review_due_date,
     designated_person_name, hazards_register, status)
  SELECT 
    p_company_id, 
    t.id, 
    t.title, 
    t.category, 
    CURRENT_DATE,
    (CURRENT_DATE + make_interval(months => coalesce(t.review_interval_months, 12)))::date,
    btrim(p_designated_person), 
    t.hazards_register,
    'Active'
  FROM public.baseline_ra_templates t
  WHERE NOT EXISTS (
    SELECT 1 FROM public.company_baseline_assessments c
    WHERE c.company_id = p_company_id AND c.template_id = t.id
  );

  GET DIAGNOSTICS v_inserted = ROW_COUNT;
  
  RETURN QUERY SELECT 
    v_inserted,
    (SELECT count(*)::int FROM public.company_baseline_assessments WHERE company_id = p_company_id);
END;
$$;


--
-- Name: provision_company_subscription(text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.provision_company_subscription(p_company_name text, p_user_email text, p_paystack_ref text, p_target_tier text, p_grower_code text DEFAULT NULL::text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_user_id uuid := auth.uid();
  v_new_company_id uuid;
  v_seat_limit int;
  v_first_name text;
  v_last_name text;
  v_registry_row record;
  v_sponsored jsonb := '[]'::jsonb;
  v_final_tier text := p_target_tier;
begin
  if v_user_id is null then
    raise exception 'provision_company_subscription must be called by an authenticated user';
  end if;

  if v_final_tier not in ('basic', 'essential', 'enterprise') then
    raise exception 'Invalid target tier: %', v_final_tier;
  end if;

  select coalesce(raw_user_meta_data->>'first_name', 'User'),
         coalesce(raw_user_meta_data->>'last_name', '')
    into v_first_name, v_last_name
  from auth.users
  where id = v_user_id;

  -- Authoritative grower-code validation + claim
  if p_grower_code is not null and length(trim(p_grower_code)) > 0 then
    select pgr.*, cp.name as partner_name, cp.logo_url as partner_logo_url, cp.sponsored_crop_pack
      into v_registry_row
    from public.partner_grower_registry pgr
    join public.corporate_partners cp on cp.id = pgr.partner_id
    where upper(pgr.grower_code) = upper(trim(p_grower_code))
      and pgr.is_active = true
      and cp.is_active = true
    for update;

    if not found or v_registry_row.claimed_by_company_id is not null then
      raise exception 'Grower code % is invalid, already claimed, or expired', p_grower_code;
    end if;

    v_final_tier := 'enterprise';
    v_sponsored := jsonb_build_array(
      jsonb_build_object(
        'crop', v_registry_row.sponsored_crop_pack,
        'partner_name', v_registry_row.partner_name,
        'partner_logo_url', v_registry_row.partner_logo_url
      )
    );
  end if;

  v_seat_limit := case v_final_tier
    when 'basic' then 1
    when 'essential' then 4
    when 'enterprise' then 8
  end;

  v_new_company_id := gen_random_uuid();

  insert into public.companies (
    id, name, tier, subscription_status, seat_limit,
    paystack_subscription_code, sponsored_crop_packs,
    partner_grower_codes, contact_email
  ) values (
    v_new_company_id, p_company_name, v_final_tier, 'active', v_seat_limit,
    p_paystack_ref, v_sponsored,
    case when p_grower_code is not null then array[upper(trim(p_grower_code))] else '{}' end,
    p_user_email
  );

  insert into public.profiles (id, first_name, last_name, role, company_id, tier)
  values (v_user_id, v_first_name, v_last_name, 'Master Admin', v_new_company_id, v_final_tier)
  on conflict (id) do update set
    first_name = excluded.first_name,
    last_name = excluded.last_name,
    role = excluded.role,
    company_id = excluded.company_id,
    tier = excluded.tier;

  if v_registry_row.id is not null then
    update public.partner_grower_registry
    set claimed_by_company_id = v_new_company_id,
        claimed_at = now()
    where id = v_registry_row.id;
  end if;

  return v_new_company_id;
end;
$$;


--
-- Name: purchase_crop_pack_addon(uuid, uuid, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.purchase_crop_pack_addon(p_company_id uuid, p_user_id uuid, p_crop_name text, p_paystack_ref text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_purchased           text[];
  v_profile_company_id  uuid;
  v_inserted            boolean;
begin
  if p_company_id is null then
    raise exception 'Missing company_id.';
  end if;

  if p_crop_name is null or btrim(p_crop_name) = '' then
    raise exception 'No crop specified.';
  end if;

  if p_paystack_ref is null or btrim(p_paystack_ref) = '' then
    raise exception 'Missing payment reference.';
  end if;

  -- Validate that user_id genuinely belongs to company_id
  if p_user_id is not null then
    select company_id into v_profile_company_id
    from public.profiles
    where id = p_user_id;

    if v_profile_company_id is null then
      raise exception 'Unknown user_id %.', p_user_id;
    end if;

    if v_profile_company_id <> p_company_id then
      raise exception 'user_id % does not belong to company_id %.', p_user_id, p_company_id;
    end if;
  end if;

  -- Atomic insert: only update companies if this is a brand-new, uncredited purchase
  with ins as (
    insert into public.crop_pack_addon_purchases
      (company_id, crop_name, paystack_ref, purchased_by)
    values
      (p_company_id, p_crop_name, p_paystack_ref, p_user_id)
    on conflict (paystack_ref) do nothing
    returning company_id
  )
  select exists(select 1 from ins) into v_inserted;

  if not v_inserted then
    select purchased_crop_packs into v_purchased
    from public.companies
    where id = p_company_id;

    return jsonb_build_object(
      'success', false,
      'reason', 'ref_already_processed',
      'crop', p_crop_name,
      'purchased_crop_packs', coalesce(v_purchased, '{}'::text[])
    );
  end if;

  select array(
    select distinct unnest(coalesce(purchased_crop_packs, '{}'::text[]) || array[p_crop_name]::text[])
  ) into v_purchased
  from public.companies
  where id = p_company_id;

  if v_purchased is null then
    raise exception 'Company % not found while crediting crop pack purchase (ref %).', p_company_id, p_paystack_ref;
  end if;

  update public.companies
  set purchased_crop_packs = v_purchased
  where id = p_company_id;

  return jsonb_build_object(
    'success', true,
    'crop', p_crop_name,
    'purchased_crop_packs', v_purchased
  );
end;
$$;


--
-- Name: remove_team_member(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.remove_team_member(p_target_user_id uuid) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_caller_company_id uuid;
  v_caller_role       text;
  v_target_company_id uuid;
  v_target_role       text;
  v_updated_rows      int;
begin
  if p_target_user_id = auth.uid() then
    raise exception 'You cannot remove yourself via this function.' using errcode = '42501';
  end if;

  -- Resolve the CALLER's identity from their own row, server-side.
  -- This SELECT is inside a SECURITY DEFINER function, so it does
  -- not go through the profiles RLS policy - no recursion risk.
  select company_id, role
    into v_caller_company_id, v_caller_role
  from public.profiles
  where id = auth.uid();

  if v_caller_company_id is null then
    raise exception 'Caller has no associated company.' using errcode = 'P0001';
  end if;

  if v_caller_role not in ('Master Admin', 'Primary Admin') then
    raise exception 'Insufficient privileges: only a Master Admin or Primary Admin may remove team members.' using errcode = '42501';
  end if;

  -- Lock the target row so a double-click / concurrent removal
  -- can't double-decrement the seat count.
  select company_id, role
    into v_target_company_id, v_target_role
  from public.profiles
  where id = p_target_user_id
  for update;

  if v_target_company_id is null then
    raise exception 'Target user was not found, or is already unassigned.' using errcode = 'P0002';
  end if;

  if v_target_company_id != v_caller_company_id then
    raise exception 'Target user does not belong to your company.' using errcode = '42501';
  end if;

  if v_target_role in ('Master Admin', 'Primary Admin') then
    raise exception 'Admins cannot be removed via this function.' using errcode = '42501';
  end if;

  update public.profiles
  set company_id = null,
      role       = 'Unassigned',
      tier       = 'basic'
  where id = p_target_user_id;

  get diagnostics v_updated_rows = row_count;

  return jsonb_build_object(
    'success', true,
    'updated_user_id', p_target_user_id,
    'rows_affected', v_updated_rows
  );
end;
$$;


--
-- Name: submit_processor_referral(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.submit_processor_referral(p_crop_name text, p_processor_name text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_company_id uuid;
begin
  -- Resolve company_id from calling profile
  select company_id into v_company_id
  from public.profiles
  where id = auth.uid();

  insert into public.processor_referral_leads (
    user_id,
    company_id,
    crop_name,
    processor_name
  )
  values (
    auth.uid(),
    v_company_id,
    trim(p_crop_name),
    trim(p_processor_name)
  );
end;
$$;


--
-- Name: sync_profile_to_auth_meta(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sync_profile_to_auth_meta() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  UPDATE auth.users
  SET raw_user_meta_data = jsonb_set(
    jsonb_set(
      jsonb_set(
        coalesce(raw_user_meta_data, '{}'::jsonb),
        '{first_name}',
        to_jsonb(coalesce(NEW.first_name, ''))
      ),
      '{last_name}',
      to_jsonb(coalesce(NEW.last_name, ''))
    ),
    '{full_name}',
    to_jsonb(trim(coalesce(NEW.first_name, '') || ' ' || coalesce(NEW.last_name, '')))
  )
  WHERE id = NEW.id;

  RETURN NEW;
END;
$$;


--
-- Name: upgrade_company_tier(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.upgrade_company_tier(p_target_tier text, p_paystack_ref text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_company_id UUID;
  v_user_role TEXT;
BEGIN
  -- Resolve caller's profile and company
  SELECT company_id, role INTO v_company_id, v_user_role
  FROM public.profiles
  WHERE id = auth.uid();

  IF v_company_id IS NULL THEN
    RAISE EXCEPTION 'No company associated with caller profile.';
  END IF;

  -- Only company admins may change plans
  IF LOWER(v_user_role) NOT IN ('admin', 'primary admin', 'master admin') THEN
    RAISE EXCEPTION 'Only an authorized administrator may modify subscription tiers.';
  END IF;

  -- Validate target tier input
  IF LOWER(p_target_tier) NOT IN ('basic', 'essential', 'enterprise') THEN
    RAISE EXCEPTION 'Invalid target tier: %', p_target_tier;
  END IF;

  -- Atomically apply upgrade
  UPDATE public.companies
  SET 
    tier = LOWER(p_target_tier),
    subscription_status = 'active',
    paystack_subscription_code = COALESCE(p_paystack_ref, paystack_subscription_code),
    seat_limit = CASE 
      WHEN LOWER(p_target_tier) = 'basic' THEN 1
      WHEN LOWER(p_target_tier) = 'essential' THEN 4
      WHEN LOWER(p_target_tier) = 'enterprise' THEN 8
      ELSE 1 
    END,
    updated_at = NOW()
  WHERE id = v_company_id;

  RETURN jsonb_build_object(
    'success', true,
    'tier', LOWER(p_target_tier),
    'company_id', v_company_id
  );
END;
$$;


--
-- Name: validate_grower_code(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.validate_grower_code(p_grower_code text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_registry_row public.partner_grower_registry%rowtype;
  v_partner_row  public.corporate_partners%rowtype;
begin
  if p_grower_code is null or btrim(p_grower_code) = '' then
    return jsonb_build_object('valid', false, 'message', 'No grower code supplied.');
  end if;

  select * into v_registry_row
  from public.partner_grower_registry
  where upper(grower_code) = upper(btrim(p_grower_code));

  if not found then
    return jsonb_build_object('valid', false, 'message', 'Grower code not recognized.');
  end if;

  if not coalesce(v_registry_row.is_active, false) then
    return jsonb_build_object('valid', false, 'message', 'This grower code is no longer active.');
  end if;

  select * into v_partner_row
  from public.corporate_partners
  where id = v_registry_row.partner_id;

  if not found then
    return jsonb_build_object('valid', false, 'message', 'Sponsoring partner record is missing.');
  end if;

  return jsonb_build_object(
    'valid', true,
    'crop', v_partner_row.sponsored_crop_pack,
    'partner_name', v_partner_row.name,
    'partner_logo_url', v_partner_row.logo_url,
    'already_claimed', v_registry_row.claimed_by_company_id is not null
  );
end;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: baseline_ra_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.baseline_ra_templates (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    title text NOT NULL,
    category text NOT NULL,
    regulation_reference text,
    review_interval_months integer DEFAULT 12,
    hazards_register jsonb DEFAULT '[]'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: companies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.companies (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    subscription_status text DEFAULT 'active'::text,
    seat_limit integer DEFAULT 5,
    tier text DEFAULT 'Base'::text,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    paystack_subscription_code text,
    paystack_customer_code text,
    vat_number text,
    postal_address text,
    phone text,
    contact_email text,
    partner_grower_codes text[] DEFAULT '{}'::text[],
    sponsored_crop_packs text[] DEFAULT '{}'::text[],
    purchased_crop_packs text[] DEFAULT '{}'::text[],
    is_subsidized boolean DEFAULT false NOT NULL,
    unlock_all_crops boolean DEFAULT false NOT NULL
);


--
-- Name: company_baseline_assessments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.company_baseline_assessments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    company_id uuid,
    template_id uuid,
    title text NOT NULL,
    category text NOT NULL,
    assessment_date date DEFAULT CURRENT_DATE NOT NULL,
    review_due_date date NOT NULL,
    designated_person_name text NOT NULL,
    designated_person_signature text,
    hazards_register jsonb DEFAULT '[]'::jsonb NOT NULL,
    status text DEFAULT 'Active'::text,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: company_risk_assessments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.company_risk_assessments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    company_id uuid,
    template_id uuid,
    title text NOT NULL,
    work_area text NOT NULL,
    equipment_id text,
    assessor_name text NOT NULL,
    assessment_date date DEFAULT CURRENT_DATE NOT NULL,
    review_due_date date NOT NULL,
    risk_items jsonb DEFAULT '[]'::jsonb NOT NULL,
    ppe_verified jsonb DEFAULT '[]'::jsonb NOT NULL,
    assessor_signature text,
    status text DEFAULT 'Active'::text,
    created_at timestamp with time zone DEFAULT now(),
    pre_use_verified jsonb DEFAULT '[]'::jsonb
);


--
-- Name: corporate_partners; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.corporate_partners (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    slug text NOT NULL,
    logo_url text,
    sponsored_crop_pack text NOT NULL,
    contact_email text,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: crop_pack_addon_purchases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.crop_pack_addon_purchases (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    company_id uuid NOT NULL,
    crop_name text NOT NULL,
    paystack_ref text NOT NULL,
    purchased_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: crop_pack_addon_subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.crop_pack_addon_subscriptions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    company_id uuid NOT NULL,
    crop_name text NOT NULL,
    paystack_subscription_code text,
    paystack_email_token text,
    status text DEFAULT 'active'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    cancellation_requested_at timestamp with time zone,
    cancelled_at timestamp with time zone,
    CONSTRAINT crop_pack_addon_subscriptions_status_check CHECK ((status = ANY (ARRAY['active'::text, 'pending_cancellation'::text, 'cancelled'::text])))
);


--
-- Name: partner_grower_registry; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.partner_grower_registry (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    partner_id uuid,
    grower_code text NOT NULL,
    company_name text NOT NULL,
    contact_email text,
    is_active boolean DEFAULT true,
    claimed_by_company_id uuid,
    claimed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: partner_portal_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.partner_portal_tokens (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    partner_id uuid NOT NULL,
    token text DEFAULT (gen_random_uuid())::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone DEFAULT (now() + '90 days'::interval),
    revoked_at timestamp with time zone
);


--
-- Name: training_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.training_records (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    company_id uuid,
    employee_name text NOT NULL,
    module_title text NOT NULL,
    completed_at date DEFAULT CURRENT_DATE NOT NULL,
    status text DEFAULT 'Verified'::text NOT NULL,
    supervisor_name text,
    signature_url text,
    training_type text DEFAULT 'Individual'::text,
    employee_number text,
    gender text,
    batch_session_id uuid,
    supervisor_signature_data text,
    employee_signature_data text
);


--
-- Name: partner_supply_chain_metrics; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.partner_supply_chain_metrics AS
 SELECT cp.id AS partner_id,
    cp.name AS partner_name,
    c.id AS company_id,
    c.name AS company_name,
    pgr.grower_code,
    pgr.claimed_at,
    c.is_subsidized,
    count(tr.id) AS total_training_records_90d,
    count(DISTINCT tr.module_title) AS distinct_modules_completed,
    max(tr.completed_at) AS last_training_at,
    ((max(tr.completed_at) IS NULL) OR (max(tr.completed_at) < (CURRENT_DATE - '60 days'::interval))) AS is_dark_supplier,
    count(cba.id) FILTER (WHERE (cba.review_due_date < CURRENT_DATE)) AS baseline_reviews_overdue,
    count(cba.id) AS baseline_reviews_total,
        CASE
            WHEN (count(tr.id) >= 5) THEN jsonb_build_object('male', count(tr.id) FILTER (WHERE (lower(tr.gender) = 'male'::text)), 'female', count(tr.id) FILTER (WHERE (lower(tr.gender) = 'female'::text)), 'unspecified', count(tr.id) FILTER (WHERE ((tr.gender IS NULL) OR (lower(tr.gender) <> ALL (ARRAY['male'::text, 'female'::text])))))
            ELSE NULL::jsonb
        END AS gender_mix_suppressed_under_5
   FROM ((((public.corporate_partners cp
     JOIN public.partner_grower_registry pgr ON (((pgr.partner_id = cp.id) AND (pgr.is_active = true))))
     JOIN public.companies c ON ((c.id = pgr.claimed_by_company_id)))
     LEFT JOIN public.training_records tr ON (((tr.company_id = c.id) AND (tr.completed_at >= (CURRENT_DATE - '90 days'::interval)))))
     LEFT JOIN public.company_baseline_assessments cba ON ((cba.company_id = c.id)))
  GROUP BY cp.id, cp.name, c.id, c.name, pgr.grower_code, pgr.claimed_at, c.is_subsidized;


--
-- Name: processor_referral_leads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.processor_referral_leads (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    user_id uuid,
    company_id uuid,
    crop_name text NOT NULL,
    processor_name text NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL
);


--
-- Name: profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profiles (
    id uuid NOT NULL,
    first_name text,
    last_name text,
    role text DEFAULT 'Staff'::text,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    avatar_url text,
    company_id uuid,
    tier text DEFAULT 'basic'::text
);


--
-- Name: risk_assessment_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.risk_assessment_templates (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    title text NOT NULL,
    sub_tag text NOT NULL,
    hazards jsonb DEFAULT '[]'::jsonb NOT NULL,
    required_ppe jsonb DEFAULT '[]'::jsonb NOT NULL,
    pre_use_checks jsonb DEFAULT '[]'::jsonb NOT NULL,
    safe_work_procedures jsonb DEFAULT '[]'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    emergency_procedures jsonb DEFAULT '[]'::jsonb,
    curriculum_slug text,
    CONSTRAINT check_rat_slug_format CHECK (((curriculum_slug IS NULL) OR (curriculum_slug ~ '^[a-z0-9_]+$'::text)))
);


--
-- Name: sandbox_jsonb_backup; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sandbox_jsonb_backup (
    table_name text NOT NULL,
    row_id text NOT NULL,
    column_name text NOT NULL,
    original_value jsonb,
    backed_up_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: sops; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sops (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    title text NOT NULL,
    description text,
    category text DEFAULT 'Agriculture'::text,
    sub_tag text DEFAULT 'General Safety'::text,
    doc_url text NOT NULL,
    video_id text,
    company_id uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    company_name text,
    curriculum_slug text,
    partner_docs jsonb DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT check_sops_slug_format CHECK (((curriculum_slug IS NULL) OR (curriculum_slug ~ '^[a-z0-9_]+$'::text)))
);


--
-- Name: COLUMN sops.partner_docs; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.sops.partner_docs IS 'Map of partner_id (UUID string) -> public URL for pre-formatted co-branded .docx files.';


--
-- Name: support_tickets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.support_tickets (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    company_id uuid,
    user_id uuid,
    user_name text,
    user_email text NOT NULL,
    ticket_type text NOT NULL,
    subject text NOT NULL,
    message text NOT NULL,
    status text DEFAULT 'open'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT support_tickets_status_check CHECK ((status = ANY (ARRAY['open'::text, 'in_progress'::text, 'resolved'::text, 'closed'::text]))),
    CONSTRAINT support_tickets_ticket_type_check CHECK ((ticket_type = ANY (ARRAY['technical_support'::text, 'video_request'::text, 'audit_compliance'::text, 'billing_inquiry'::text, 'crop_subsidy'::text, 'general'::text])))
);


--
-- Name: user_video_progress; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_video_progress (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    video_id text NOT NULL,
    video_title text,
    progress_seconds numeric DEFAULT 0 NOT NULL,
    duration_seconds numeric DEFAULT 0 NOT NULL,
    percentage numeric DEFAULT 0 NOT NULL,
    is_completed boolean DEFAULT false,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);


--
-- Name: videos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.videos (
    id text NOT NULL,
    title text NOT NULL,
    category text DEFAULT 'Agriculture'::text,
    language text DEFAULT 'English'::text,
    total_seconds integer NOT NULL,
    thumbnail_url text,
    description text,
    objectives jsonb DEFAULT '[]'::jsonb,
    company_id uuid,
    sub_tag text,
    company_name text,
    questions jsonb DEFAULT '[]'::jsonb,
    curriculum_slug text,
    partner_thumbnails jsonb DEFAULT '{}'::jsonb,
    CONSTRAINT check_videos_slug_format CHECK (((curriculum_slug IS NULL) OR (curriculum_slug ~ '^[a-z0-9_]+$'::text)))
);


--
-- Name: baseline_ra_templates baseline_ra_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.baseline_ra_templates
    ADD CONSTRAINT baseline_ra_templates_pkey PRIMARY KEY (id);


--
-- Name: baseline_ra_templates baseline_ra_templates_title_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.baseline_ra_templates
    ADD CONSTRAINT baseline_ra_templates_title_key UNIQUE (title);


--
-- Name: company_baseline_assessments company_baseline_assessments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.company_baseline_assessments
    ADD CONSTRAINT company_baseline_assessments_pkey PRIMARY KEY (id);


--
-- Name: company_baseline_assessments company_baseline_template_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.company_baseline_assessments
    ADD CONSTRAINT company_baseline_template_unique UNIQUE (company_id, template_id);


--
-- Name: corporate_partners corporate_partners_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.corporate_partners
    ADD CONSTRAINT corporate_partners_name_key UNIQUE (name);


--
-- Name: corporate_partners corporate_partners_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.corporate_partners
    ADD CONSTRAINT corporate_partners_pkey PRIMARY KEY (id);


--
-- Name: corporate_partners corporate_partners_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.corporate_partners
    ADD CONSTRAINT corporate_partners_slug_key UNIQUE (slug);


--
-- Name: crop_pack_addon_purchases crop_pack_addon_purchases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crop_pack_addon_purchases
    ADD CONSTRAINT crop_pack_addon_purchases_pkey PRIMARY KEY (id);


--
-- Name: crop_pack_addon_purchases crop_pack_addon_purchases_ref_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crop_pack_addon_purchases
    ADD CONSTRAINT crop_pack_addon_purchases_ref_unique UNIQUE (paystack_ref);


--
-- Name: crop_pack_addon_subscriptions crop_pack_addon_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crop_pack_addon_subscriptions
    ADD CONSTRAINT crop_pack_addon_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: company_risk_assessments farm_risk_assessments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.company_risk_assessments
    ADD CONSTRAINT farm_risk_assessments_pkey PRIMARY KEY (id);


--
-- Name: companies farms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.companies
    ADD CONSTRAINT farms_pkey PRIMARY KEY (id);


--
-- Name: partner_grower_registry partner_grower_registry_grower_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.partner_grower_registry
    ADD CONSTRAINT partner_grower_registry_grower_code_key UNIQUE (grower_code);


--
-- Name: partner_grower_registry partner_grower_registry_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.partner_grower_registry
    ADD CONSTRAINT partner_grower_registry_pkey PRIMARY KEY (id);


--
-- Name: partner_portal_tokens partner_portal_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.partner_portal_tokens
    ADD CONSTRAINT partner_portal_tokens_pkey PRIMARY KEY (id);


--
-- Name: partner_portal_tokens partner_portal_tokens_token_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.partner_portal_tokens
    ADD CONSTRAINT partner_portal_tokens_token_key UNIQUE (token);


--
-- Name: processor_referral_leads processor_referral_leads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.processor_referral_leads
    ADD CONSTRAINT processor_referral_leads_pkey PRIMARY KEY (id);


--
-- Name: profiles profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);


--
-- Name: risk_assessment_templates rat_title_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.risk_assessment_templates
    ADD CONSTRAINT rat_title_unique UNIQUE (title);


--
-- Name: risk_assessment_templates risk_assessment_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.risk_assessment_templates
    ADD CONSTRAINT risk_assessment_templates_pkey PRIMARY KEY (id);


--
-- Name: sandbox_jsonb_backup sandbox_jsonb_backup_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sandbox_jsonb_backup
    ADD CONSTRAINT sandbox_jsonb_backup_pkey PRIMARY KEY (table_name, row_id, column_name);


--
-- Name: sops sops_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sops
    ADD CONSTRAINT sops_pkey PRIMARY KEY (id);


--
-- Name: support_tickets support_tickets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.support_tickets
    ADD CONSTRAINT support_tickets_pkey PRIMARY KEY (id);


--
-- Name: training_records training_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.training_records
    ADD CONSTRAINT training_records_pkey PRIMARY KEY (id);


--
-- Name: user_video_progress user_video_progress_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_video_progress
    ADD CONSTRAINT user_video_progress_pkey PRIMARY KEY (id);


--
-- Name: user_video_progress user_video_progress_user_id_video_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_video_progress
    ADD CONSTRAINT user_video_progress_user_id_video_id_key UNIQUE (user_id, video_id);


--
-- Name: videos videos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.videos
    ADD CONSTRAINT videos_pkey PRIMARY KEY (id);


--
-- Name: idx_baseline_ra_templates_cat; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_baseline_ra_templates_cat ON public.baseline_ra_templates USING btree (category);


--
-- Name: idx_cba_company_template_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cba_company_template_date ON public.company_baseline_assessments USING btree (company_id, template_id, assessment_date DESC);


--
-- Name: idx_company_baseline_assessments_cid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_company_baseline_assessments_cid ON public.company_baseline_assessments USING btree (company_id);


--
-- Name: idx_crop_pack_addon_subscriptions_active_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_crop_pack_addon_subscriptions_active_unique ON public.crop_pack_addon_subscriptions USING btree (company_id, crop_name) WHERE (status = 'active'::text);


--
-- Name: idx_partner_grower_registry_claimed_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_partner_grower_registry_claimed_by ON public.partner_grower_registry USING btree (claimed_by_company_id);


--
-- Name: unique_active_claimed_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_active_claimed_code ON public.partner_grower_registry USING btree (grower_code) WHERE (claimed_by_company_id IS NOT NULL);


--
-- Name: processor_referral_leads on_processor_referral_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER on_processor_referral_insert AFTER INSERT ON public.processor_referral_leads FOR EACH ROW EXECUTE FUNCTION supabase_functions.http_request('https://ujhfkvoaaebdntuheyqo.supabase.co/functions/v1/notify-referral-lead', 'POST', '{"Content-type":"application/json","x-webhook-secret":"[REDACTED]"}', '{}', '5000');


--
-- Name: support_tickets on_support_ticket_created; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER on_support_ticket_created AFTER INSERT ON public.support_tickets FOR EACH ROW EXECUTE FUNCTION supabase_functions.http_request('https://ujhfkvoaaebdntuheyqo.supabase.co/functions/v1/notify-support-ticket', 'POST', '{"Content-type":"application/json"}', '{}', '5000');


--
-- Name: profiles trigger_sync_profile_meta; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_sync_profile_meta AFTER UPDATE OF first_name, last_name ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.sync_profile_to_auth_meta();


--
-- Name: company_baseline_assessments company_baseline_assessments_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.company_baseline_assessments
    ADD CONSTRAINT company_baseline_assessments_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE CASCADE;


--
-- Name: company_baseline_assessments company_baseline_assessments_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.company_baseline_assessments
    ADD CONSTRAINT company_baseline_assessments_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.baseline_ra_templates(id);


--
-- Name: company_risk_assessments company_risk_assessments_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.company_risk_assessments
    ADD CONSTRAINT company_risk_assessments_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE CASCADE;


--
-- Name: company_risk_assessments company_risk_assessments_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.company_risk_assessments
    ADD CONSTRAINT company_risk_assessments_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.risk_assessment_templates(id);


--
-- Name: crop_pack_addon_purchases crop_pack_addon_purchases_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crop_pack_addon_purchases
    ADD CONSTRAINT crop_pack_addon_purchases_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE CASCADE;


--
-- Name: crop_pack_addon_purchases crop_pack_addon_purchases_purchased_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crop_pack_addon_purchases
    ADD CONSTRAINT crop_pack_addon_purchases_purchased_by_fkey FOREIGN KEY (purchased_by) REFERENCES public.profiles(id) ON DELETE SET NULL;


--
-- Name: crop_pack_addon_subscriptions crop_pack_addon_subscriptions_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.crop_pack_addon_subscriptions
    ADD CONSTRAINT crop_pack_addon_subscriptions_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE CASCADE;


--
-- Name: partner_grower_registry partner_grower_registry_claimed_by_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.partner_grower_registry
    ADD CONSTRAINT partner_grower_registry_claimed_by_company_id_fkey FOREIGN KEY (claimed_by_company_id) REFERENCES public.companies(id) ON DELETE SET NULL;


--
-- Name: partner_grower_registry partner_grower_registry_partner_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.partner_grower_registry
    ADD CONSTRAINT partner_grower_registry_partner_id_fkey FOREIGN KEY (partner_id) REFERENCES public.corporate_partners(id) ON DELETE CASCADE;


--
-- Name: partner_portal_tokens partner_portal_tokens_partner_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.partner_portal_tokens
    ADD CONSTRAINT partner_portal_tokens_partner_id_fkey FOREIGN KEY (partner_id) REFERENCES public.corporate_partners(id) ON DELETE CASCADE;


--
-- Name: processor_referral_leads processor_referral_leads_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.processor_referral_leads
    ADD CONSTRAINT processor_referral_leads_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE CASCADE;


--
-- Name: processor_referral_leads processor_referral_leads_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.processor_referral_leads
    ADD CONSTRAINT processor_referral_leads_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: profiles profiles_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE SET NULL;


--
-- Name: profiles profiles_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: sops sops_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sops
    ADD CONSTRAINT sops_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE CASCADE;


--
-- Name: support_tickets support_tickets_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.support_tickets
    ADD CONSTRAINT support_tickets_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE SET NULL;


--
-- Name: support_tickets support_tickets_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.support_tickets
    ADD CONSTRAINT support_tickets_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: training_records training_records_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.training_records
    ADD CONSTRAINT training_records_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE CASCADE;


--
-- Name: user_video_progress user_video_progress_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_video_progress
    ADD CONSTRAINT user_video_progress_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: videos videos_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.videos
    ADD CONSTRAINT videos_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE CASCADE;


--
-- Name: profiles Admins can update company member profiles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can update company member profiles" ON public.profiles FOR UPDATE TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.profiles admin_p
  WHERE ((admin_p.id = auth.uid()) AND (admin_p.company_id = profiles.company_id) AND ((lower(admin_p.role) ~~ '%admin%'::text) OR (lower(admin_p.role) = 'master admin'::text)))))) WITH CHECK (true);


--
-- Name: companies Admins can update own company; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins can update own company" ON public.companies FOR UPDATE TO authenticated USING ((id IN ( SELECT profiles.company_id
   FROM public.profiles
  WHERE (profiles.id = auth.uid())))) WITH CHECK ((id IN ( SELECT profiles.company_id
   FROM public.profiles
  WHERE (profiles.id = auth.uid()))));


--
-- Name: baseline_ra_templates Allow authenticated users to read baseline templates; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow authenticated users to read baseline templates" ON public.baseline_ra_templates FOR SELECT TO authenticated USING (true);


--
-- Name: companies Allow insert on companies during registration; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow insert on companies during registration" ON public.companies FOR INSERT WITH CHECK (true);


--
-- Name: companies Allow members to update their company; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow members to update their company" ON public.companies FOR UPDATE TO authenticated USING ((id IN ( SELECT profiles.company_id
   FROM public.profiles
  WHERE (profiles.id = auth.uid())))) WITH CHECK ((id IN ( SELECT profiles.company_id
   FROM public.profiles
  WHERE (profiles.id = auth.uid()))));


--
-- Name: risk_assessment_templates Allow read access to all users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow read access to all users" ON public.risk_assessment_templates FOR SELECT USING (true);


--
-- Name: corporate_partners Allow read corporate partners; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow read corporate partners" ON public.corporate_partners FOR SELECT TO authenticated USING (true);


--
-- Name: profiles Allow self insert on profiles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow self insert on profiles" ON public.profiles FOR INSERT TO authenticated WITH CHECK ((auth.uid() = id));


--
-- Name: profiles Allow self update on profiles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow self update on profiles" ON public.profiles FOR UPDATE TO authenticated USING ((auth.uid() = id)) WITH CHECK ((auth.uid() = id));


--
-- Name: profiles Allow users to update their profiles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow users to update their profiles" ON public.profiles FOR UPDATE TO authenticated USING ((auth.uid() = id)) WITH CHECK ((auth.uid() = id));


--
-- Name: sops Allow users to view accessible SOPs; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow users to view accessible SOPs" ON public.sops FOR SELECT TO authenticated USING (((company_id IS NULL) OR (company_id = ( SELECT profiles.company_id
   FROM public.profiles
  WHERE (profiles.id = auth.uid())
 LIMIT 1))));


--
-- Name: videos Authenticated users can view videos; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users can view videos" ON public.videos FOR SELECT TO authenticated USING (true);


--
-- Name: videos Public can view master catalog videos; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Public can view master catalog videos" ON public.videos FOR SELECT TO authenticated, anon USING ((company_id IS NULL));


--
-- Name: company_risk_assessments Tenants can view and insert own risk assessments; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Tenants can view and insert own risk assessments" ON public.company_risk_assessments USING ((company_id = ( SELECT profiles.company_id
   FROM public.profiles
  WHERE (profiles.id = auth.uid()))));


--
-- Name: support_tickets Users can create support tickets; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can create support tickets" ON public.support_tickets FOR INSERT TO authenticated WITH CHECK ((auth.uid() = user_id));


--
-- Name: company_risk_assessments Users can insert company risk assessments; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert company risk assessments" ON public.company_risk_assessments FOR INSERT TO authenticated WITH CHECK (((company_id IN ( SELECT profiles.company_id
   FROM public.profiles
  WHERE (profiles.id = auth.uid()))) OR (company_id IS NULL)));


--
-- Name: training_records Users can insert company training records; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert company training records" ON public.training_records FOR INSERT WITH CHECK ((company_id IN ( SELECT profiles.company_id
   FROM public.profiles
  WHERE (profiles.id = auth.uid()))));


--
-- Name: company_baseline_assessments Users can insert own company baseline assessments; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert own company baseline assessments" ON public.company_baseline_assessments FOR INSERT TO authenticated WITH CHECK ((company_id IN ( SELECT profiles.company_id
   FROM public.profiles
  WHERE (profiles.id = auth.uid()))));


--
-- Name: user_video_progress Users can insert own video progress; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert own video progress" ON public.user_video_progress FOR INSERT TO authenticated WITH CHECK ((auth.uid() = user_id));


--
-- Name: profiles Users can insert their own profile; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert their own profile" ON public.profiles FOR INSERT WITH CHECK ((auth.uid() = id));


--
-- Name: user_video_progress Users can insert/update own video progress; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert/update own video progress" ON public.user_video_progress FOR INSERT WITH CHECK ((auth.uid() = user_id));


--
-- Name: support_tickets Users can read company support tickets; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can read company support tickets" ON public.support_tickets FOR SELECT TO authenticated USING ((company_id IN ( SELECT profiles.company_id
   FROM public.profiles
  WHERE (profiles.id = auth.uid()))));


--
-- Name: company_baseline_assessments Users can update own company baseline assessments; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update own company baseline assessments" ON public.company_baseline_assessments FOR UPDATE TO authenticated USING ((company_id IN ( SELECT profiles.company_id
   FROM public.profiles
  WHERE (profiles.id = auth.uid())))) WITH CHECK ((company_id IN ( SELECT profiles.company_id
   FROM public.profiles
  WHERE (profiles.id = auth.uid()))));


--
-- Name: profiles Users can update own profile; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE TO authenticated USING ((auth.uid() = id));


--
-- Name: user_video_progress Users can update own video progress; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update own video progress" ON public.user_video_progress FOR UPDATE TO authenticated USING ((auth.uid() = user_id));


--
-- Name: profiles Users can update their own profile; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update their own profile" ON public.profiles FOR UPDATE USING ((auth.uid() = id));


--
-- Name: company_risk_assessments Users can view company risk assessments; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view company risk assessments" ON public.company_risk_assessments FOR SELECT TO authenticated USING (((company_id IN ( SELECT profiles.company_id
   FROM public.profiles
  WHERE (profiles.id = auth.uid()))) OR (company_id IS NULL)));


--
-- Name: training_records Users can view company training records; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view company training records" ON public.training_records FOR SELECT USING ((company_id IN ( SELECT profiles.company_id
   FROM public.profiles
  WHERE (profiles.id = auth.uid()))));


--
-- Name: companies Users can view own company; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view own company" ON public.companies FOR SELECT TO authenticated USING ((id IN ( SELECT profiles.company_id
   FROM public.profiles
  WHERE (profiles.id = auth.uid()))));


--
-- Name: crop_pack_addon_subscriptions Users can view own company addon subscriptions; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view own company addon subscriptions" ON public.crop_pack_addon_subscriptions FOR SELECT TO authenticated USING ((company_id = public.get_my_company_id()));


--
-- Name: company_baseline_assessments Users can view own company baseline assessments; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view own company baseline assessments" ON public.company_baseline_assessments FOR SELECT TO authenticated USING ((company_id IN ( SELECT profiles.company_id
   FROM public.profiles
  WHERE (profiles.id = auth.uid()))));


--
-- Name: processor_referral_leads Users can view own company referral leads; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view own company referral leads" ON public.processor_referral_leads FOR SELECT TO authenticated USING ((company_id IN ( SELECT profiles.company_id
   FROM public.profiles
  WHERE (profiles.id = auth.uid()))));


--
-- Name: user_video_progress Users can view own video progress; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view own video progress" ON public.user_video_progress FOR SELECT TO authenticated USING ((auth.uid() = user_id));


--
-- Name: profiles Users can view profiles in same company; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view profiles in same company" ON public.profiles FOR SELECT USING (((id = auth.uid()) OR (company_id = public.get_my_company_id())));


--
-- Name: partner_grower_registry Users can view their own company's claimed grower codes; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view their own company's claimed grower codes" ON public.partner_grower_registry FOR SELECT TO authenticated USING ((claimed_by_company_id = public.get_my_company_id()));


--
-- Name: baseline_ra_templates; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.baseline_ra_templates ENABLE ROW LEVEL SECURITY;

--
-- Name: companies; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;

--
-- Name: company_baseline_assessments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.company_baseline_assessments ENABLE ROW LEVEL SECURITY;

--
-- Name: company_risk_assessments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.company_risk_assessments ENABLE ROW LEVEL SECURITY;

--
-- Name: corporate_partners; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.corporate_partners ENABLE ROW LEVEL SECURITY;

--
-- Name: crop_pack_addon_purchases; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.crop_pack_addon_purchases ENABLE ROW LEVEL SECURITY;

--
-- Name: crop_pack_addon_subscriptions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.crop_pack_addon_subscriptions ENABLE ROW LEVEL SECURITY;

--
-- Name: partner_grower_registry; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.partner_grower_registry ENABLE ROW LEVEL SECURITY;

--
-- Name: partner_portal_tokens; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.partner_portal_tokens ENABLE ROW LEVEL SECURITY;

--
-- Name: processor_referral_leads; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.processor_referral_leads ENABLE ROW LEVEL SECURITY;

--
-- Name: profiles; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

--
-- Name: risk_assessment_templates; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.risk_assessment_templates ENABLE ROW LEVEL SECURITY;

--
-- Name: sandbox_jsonb_backup; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.sandbox_jsonb_backup ENABLE ROW LEVEL SECURITY;

--
-- Name: sops; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.sops ENABLE ROW LEVEL SECURITY;

--
-- Name: support_tickets; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;

--
-- Name: training_records; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.training_records ENABLE ROW LEVEL SECURITY;

--
-- Name: user_video_progress; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.user_video_progress ENABLE ROW LEVEL SECURITY;

--
-- Name: videos; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.videos ENABLE ROW LEVEL SECURITY;

--
-- PostgreSQL database dump complete
--

\unrestrict xksefeBOjc5hZVxvO8kPM3rsjAHpNHbG2R4Ev9PUafQEhLMIKlhfGv5KE2uj7Am

```
