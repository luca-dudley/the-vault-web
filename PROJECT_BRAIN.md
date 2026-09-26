# The Vault Web — Master Project Brain

> **Production Architectural Specification & System Documentation**  
> *Last Verified: September 2026 | Deployment Environment: Cloudflare Pages (Production `main`, Development `v3-dev`)*

---

## 1. System Overview & Architecture

### Core Purpose
**The Vault** (`the-vault-web`) is a mission-critical, enterprise agricultural safety, occupational compliance, and operational workforce training platform developed for South African farming enterprises, packhouses, agricultural processors, and exporting syndicates.

The platform directly addresses statutory compliance with the **Occupational Health and Safety Act (OHSA, Act 85 of 1993)**, its subordinate regulations (General Safety Regulations, Driven Machinery Regulations, Construction Regulations), agricultural audit frameworks (**GlobalG.A.P.**, **SIZA** [Sustainability Initiative of South Africa], **BRCGS**, **Fairtrade**), and data privacy mandates under the **Protection of Personal Information Act (POPIA, Act 4 of 2013)** and **GDPR**.

Key capabilities include:
- **Multilingual Video Training LMS**: Mobile-optimized, low-bandwidth video training delivered in English and isiZulu, covering general farm safety, workshop & machinery operations, pumping/irrigation, fleet & vehicle safety, and specialized crop processing operations.
- **Statutory Risk Assessment Registers**: Baseline Risk Assessments (BRAs) and task-specific risk matrices with annual statutory review scheduling, Section 16(2) appointee signing workflows, and automated A4 landscape PDF generation.
- **Auditable Employee Training Logs**: Digital supervisor-and-worker dual-signature sign-off kiosks for single and group induction batches with tamper-resistant audit trails.
- **Crop-Pack Stacking & Co-Branded Portals (3-Layer Content Architecture)**:
  - *Layer 1 (Core Universal Safety)*: Universal farm modules (General Safety, Machinery & Workshop, Pumping & Irrigation, Vehicles & Fleet) accessible across all tiers.
  - *Layer 2 (Specialized Crop Packs)*: Gated curriculum modules for Macadamia, Banana, and Citrus crops unlocked via subsidized grower codes or self-funded R80/mo recurring bolt-on add-ons.
  - *Layer 3 (Partner Attribution & Portals)*: Commercial processors (e.g. Macadamia and Banana handlers) sponsor grower subscriptions and track supply chain audit compliance in real time via zero-login encrypted 35-day magic link portals with custom branded SOP overrides and video badges.
- **Standard Operating Procedures (SOPs)**: Centralized library of statutory and operational SOP documentation linked directly to training modules with corporate partner document overrides.

### Hosting & Infrastructure
- **Hosting Platform**: **Cloudflare Pages**
- **Git Branches**: `main` (Production deployment target) and `v3-dev` (Active development target).
- **DNS / Domain**: `www.simpleza.co.za` (Simple Solutions Safety & Operations).
- **Content Delivery Network**: Global Cloudflare Edge CDN with zero-latency edge caching for static HTML/JS/CSS assets and pre-rendered vector brand assets. Automatic SSL/TLS termination with HTTP/2 and HTTP/3 multiplexing.

### Deployment Model
- **Zero-Build Static Architecture**: Cloudflare Pages serves static files directly from the repository root. There is **strictly no client-side Node.js compilation**, no bundler (no Vite, Webpack, Parcel, Rollup, or esbuild), and no build command (`npm run build` is strictly prohibited).
- **Continuous Deployment**: Commits pushed directly to the `main` branch trigger automated atomic deployments on Cloudflare Pages.
- **Edge Compute**: Supabase Deno runtime hosts backend edge functions (`/supabase/functions/`) deployed directly to Supabase global infrastructure.

---

## 2. Frontend Conventions

### Tech Stack
- **Markup**: Semantic Vanilla HTML5 with mobile-first responsive container layouts.
- **Scripts**: Native ECMAScript 6+ modules and scripts (`/js/main.js`, `/js/profile-engine.js`, and inline scoped DOM controllers).
- **Styling**: Tailwind CSS delivered via official CDN script (`https://cdn.tailwindcss.com`) with custom brand theme extensions.
- **No Client Frameworks**: Strictly **no React, no Vue, no Svelte, and no Angular**. All dynamic DOM manipulation uses native browser APIs (`document.querySelector`, `addEventListener`, template literals, and Canvas 2D contexts).

### Tailwind Theme & Palette Configuration
Every page includes the standardized Tailwind theme extension:
```javascript
tailwind.config = {
  theme: {
    extend: {
      colors: {
        primary: '#1e3a5f',    // Deep Navy (Brand Primary)
        foreground: '#0f172a', // Slate 900
        muted: '#64748b'       // Slate 500
      }
    }
  }
}
```

Key mobile UX conventions:
- Minimum interactive touch target height of 44px (`min-h-[44px]` on select dropdowns, inputs, and primary action buttons).
- Horizontal scrolling pill bars for category filters, status tabs, and baseline categories (`flex overflow-x-auto no-scrollbar gap-2`).
- Responsive modal footers (`flex flex-col-reverse sm:flex-row items-stretch sm:items-center gap-3`).
- Wide data tables enclosed in dedicated horizontal overflow wrappers (`w-full overflow-x-auto -mx-3 px-3 sm:mx-0 sm:px-0`).

### Script Loading Rules & Execution Order
1. **Head Loading Order**:
   - Google Tag Manager (`gtag.js` with ID `G-L0HP7V44GT`, automated localhost suppression, and `disable_analytics=true` localStorage flag).
   - Tailwind CSS CDN script (`https://cdn.tailwindcss.com`).
   - Supabase Client v2 (`https://unpkg.com/@supabase/supabase-js@2`).
   - Paystack Inline v2 (`https://js.paystack.co/v2/inline.js`).
   - Vimeo Player SDK (`https://player.vimeo.com/api/player.js` on video routes: `vault.html`, `module.html`).
   - jsPDF UMD (`https://unpkg.com/jspdf@latest/dist/jspdf.umd.min.js` on audit/export routes: `records.html`, `risk-assessments.html`, `partner-portal.html`).
   - Chart.js (`https://cdn.jsdelivr.net/npm/chart.js` on `partner-portal.html`).
2. **Body Termination Loading Order**:
   - `js/main.js`: Responsive navigation, mobile backdrop toggle, body scroll locking on open drawer, resize cleanup, and collapsible sidebar (`lg:ml-64` to `lg:ml-20`).
   - `js/profile-engine.js`: Profile modal injector, session bootstrap, multi-tenant state resolution, crop-pack gating, seat limit verification, and Paystack billing engine.
   - Route-specific inline scripts: Executed on `DOMContentLoaded` or after `profile-engine.js` has established `window.dbClient`.

### Shared Component Injection
- Dynamic multi-page injection is handled by `injectProfileModalContainer()` in `js/profile-engine.js`.
- Authenticated pages (`vault.html`, `module.html`, `records.html`, `risk-assessments.html`, `sop.html`, `support.html`) do not duplicate the 390-line profile modal DOM; instead, they asynchronously fetch and inject `profile-modal.html` into `document.body` before binding authentication and tab triggers.
- Tab management inside `profile-modal.html`:
  - **Profile**: Personal name, job title, and avatar image upload to Supabase Storage bucket `avatars`.
  - **Organization**: Company name, VAT/Tax registration number, telephone, postal/physical address, contact email, and Processor Grower Code claiming interface.
  - **Security**: Password reset email trigger and Google OAuth identity linking (`linkIdentity`).
  - **Plans**: Current tier badge, plan comparison matrix, Paystack upgrade/downgrade modals (`vaultUpgradeReviewModal`), and cancellation workflow.
  - **Team Seats**: Seat limit indicator, team member listing, manager invite link generator (`/invite.html?company=...`), and manager removal via `remove_team_member` RPC.

---

## 3. Backend & Supabase

### Database Architecture
- **Supabase PostgreSQL Host**: `https://ujhfkvoaaebdntuheyqo.supabase.co`
- **Client Configuration**: Initialized as `window.dbClient` (and aliased to `window.supabaseClient`) using public anonymous JWT key:
  `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVqaGZrdm9hYWViZG50dWhleXFvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE4NTQzODYsImV4cCI6MjA5NzQzMDM4Nn0._r6CkysZr5qpV1zKz-otN_FZJfNzKlCJvm6ggO9qTV0`
- **Server-Side Execution**: Supabase Edge Functions on Deno runtime operate with elevated `SUPABASE_SERVICE_ROLE_KEY` privileges to execute administrative mutations and webhook reconciliations.

### Multi-Tenant Database Rules (Tenant Isolation)
- **Tenant Key**: **`company_id`** (UUID foreign key referencing `companies.id`).
- All multi-tenant tables (`profiles`, `training_records`, `company_risk_assessments`, `company_baseline_assessments`, `support_tickets`, `crop_pack_addon_subscriptions`, `crop_pack_addon_purchases`, `processor_referral_leads`) enforce tenant isolation strictly by `company_id`.
- Tenant users belong to an organization defined in `companies` and map 1:1 to an auth user via `profiles.id = auth.uid()`.
- **Catalog Partitioning**:
  - Master catalog rows (`videos`, `sops`) have `company_id IS NULL` to indicate global master availability across all tenants.
  - Proprietary estate branded rows (e.g. customized footage or procedures for Doveton Farms, Elliott Farms, Outlook Farms) have a non-null `company_id` and are filtered exclusively to users belonging to that specific tenant.
- **Access Control & Session Enforcement**:
  - Function `get_my_company_id()` resolves the caller's `company_id` server-side in RLS policies without recursive queries.
  - When `companies.subscription_status` is `suspended`, `cancelled`, or `deactivated`, `js/profile-engine.js` immediately blocks workspace access and displays a full-screen reactivation terminal.

### Core Database Tables & Models

| Table Name | Primary Key | Key Columns & Types | Nullability & Constraints | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| `companies` | `id` (UUID) | `name` (text), `subscription_status` (text, default `'active'`), `seat_limit` (int4, default `5`), `tier` (text, default `'Base'`), `paystack_subscription_code` (text), `paystack_customer_code` (text), `vat_number` (text), `postal_address` (text), `phone` (text), `contact_email` (text), `partner_grower_codes` (text[]), `sponsored_crop_packs` (text[]), `purchased_crop_packs` (text[]), `is_subsidized` (bool, default `false`), `unlock_all_crops` (bool, default `false`), `created_at` (timestamptz) | `name` NOT NULL | Primary tenant accounts. Encapsulates billing state, tier, seat limits, subsidized crop packs, purchased bolt-ons, and claimed partner grower codes. |
| `profiles` | `id` (UUID) | `company_id` (UUID fk `companies.id`), `first_name` (text), `last_name` (text), `role` (text, default `'Staff'`), `tier` (text, default `'basic'`), `avatar_url` (text), `created_at` (timestamptz) | `id` maps 1:1 to `auth.users.id`. `company_id` nullable during registration. | User profile linked directly to Supabase Auth users. Maps user to tenant company and seat permissions. |
| `videos` | `id` (Text) | `title` (text), `description` (text), `category` (text, default `'Agriculture'`), `sub_tag` (text), `language` (text, default `'English'`), `total_seconds` (int4), `thumbnail_url` (text), `partner_thumbnails` (JSONB, default `'{}'`), `objectives` (JSONB, default `'[]'`), `questions` (JSONB, default `'[]'`), `curriculum_slug` (text), `company_id` (UUID fk `companies.id`), `company_name` (text) | `id`, `title`, `total_seconds` NOT NULL. `company_id IS NULL` for master catalog. | Master and tenant-specific video training modules. |
| `sops` | `id` (UUID) | `title` (text), `description` (text), `category` (text, default `'Agriculture'`), `sub_tag` (text, default `'General Safety'`), `doc_url` (text), `video_id` (text), `partner_docs` (JSONB, default `'{}'`), `curriculum_slug` (text), `company_id` (UUID fk `companies.id`), `company_name` (text), `created_at` (timestamptz), `updated_at` (timestamptz) | `id`, `title`, `doc_url` NOT NULL. `company_id IS NULL` for master catalog. | Standard Operating Procedures repository with partner-branded document download overrides (`partner_docs`). |
| `user_video_progress` | `id` (UUID) | `user_id` (UUID), `video_id` (text), `video_title` (text), `progress_seconds` (numeric, default `0`), `duration_seconds` (numeric, default `0`), `percentage` (numeric, default `0`), `is_completed` (bool, default `false`), `updated_at` (timestamptz) | `user_id`, `video_id`, `progress_seconds`, `duration_seconds`, `percentage` NOT NULL. Unique composite index on `(user_id, video_id)`. | Granular per-user video watch progress and completion milestones ($\ge 90\%$). |
| `training_records` | `id` (UUID) | `company_id` (UUID fk `companies.id`), `module_title` (text), `employee_name` (text), `employee_number` (text), `gender` (text), `training_type` (text, default `'Individual'`), `completed_at` (date, default `CURRENT_DATE`), `status` (text, default `'Verified'`), `supervisor_name` (text), `supervisor_signature_data` (text), `employee_signature_data` (text), `signature_url` (text), `batch_session_id` (UUID), `created_at` (timestamptz) | `id`, `employee_name`, `module_title`, `completed_at`, `status` NOT NULL. | Tamper-evident employee statutory training sign-offs with canvas signatures for individual and group batches. |
| `corporate_partners` | `id` (UUID) | `name` (text), `slug` (text), `logo_url` (text), `sponsored_crop_pack` (text), `contact_email` (text), `created_at` (timestamptz) | `id`, `name`, `slug`, `sponsored_crop_pack` NOT NULL. | Commercial processor and packhouse partners sponsoring grower networks. |
| `partner_grower_registry` | `id` (UUID) | `partner_id` (UUID fk `corporate_partners.id`), `grower_code` (text), `company_name` (text), `contact_email` (text), `is_active` (bool, default `true`), `claimed_by_company_id` (UUID fk `companies.id`), `claimed_at` (timestamptz), `created_at` (timestamptz) | `id`, `grower_code`, `company_name` NOT NULL. | Registry of issued grower codes and their claiming farm enterprise. |
| `partner_portal_tokens` | `id` (UUID) | `partner_id` (UUID fk `corporate_partners.id`), `token` (text, default `gen_random_uuid()`), `expires_at` (timestamptz, default `now() + '90 days'`), `revoked_at` (timestamptz), `created_at` (timestamptz) | `id`, `partner_id`, `token` NOT NULL. | Encrypted, 35-day revolving magic link tokens for partner compliance portals. |
| `partner_supply_chain_metrics` (View) | N/A (View) | `partner_id` (UUID), `partner_name` (text), `company_id` (UUID), `company_name` (text), `grower_code` (text), `claimed_at` (timestamptz), `is_subsidized` (bool), `total_training_records_90d` (int8), `distinct_modules_completed` (int8), `last_training_at` (date), `is_dark_supplier` (bool), `baseline_reviews_overdue` (int8), `baseline_reviews_total` (int8), `gender_mix_suppressed_under_5` (JSONB) | Read-only view aggregating supply chain performance across grower networks. | Supplies aggregated KPIs and POPIA/GDPR small-sample suppressed metrics to corporate partner portals. |
| `baseline_ra_templates` | `id` (UUID) | `title` (text), `category` (text), `regulation_reference` (text), `review_interval_months` (int4, default `12`), `hazards_register` (JSONB, default `'[]'`), `created_at` (timestamptz) | `id`, `title`, `category`, `hazards_register` NOT NULL. | Master statutory Baseline Risk Assessment templates under OHSA. |
| `company_baseline_assessments` | `id` (UUID) | `company_id` (UUID fk `companies.id`), `template_id` (UUID fk `baseline_ra_templates.id`), `title` (text), `category` (text), `assessment_date` (date, default `CURRENT_DATE`), `review_due_date` (date), `designated_person_name` (text), `designated_person_signature` (text), `hazards_register` (JSONB, default `'[]'`), `status` (text, default `'Active'`), `created_at` (timestamptz) | `id`, `title`, `category`, `assessment_date`, `review_due_date`, `designated_person_name`, `hazards_register` NOT NULL. | Tenant-authorized annual Baseline Risk Assessments with Section 16(2) appointee signing. |
| `risk_assessment_templates` | `id` (UUID) | `title` (text), `sub_tag` (text), `hazards` (JSONB, default `'[]'`), `required_ppe` (JSONB, default `'[]'`), `pre_use_checks` (JSONB, default `'[]'`), `safe_work_procedures` (JSONB, default `'[]'`), `emergency_procedures` (JSONB, default `'[]'`), `curriculum_slug` (text), `created_at` (timestamptz) | `id`, `title`, `sub_tag`, `hazards`, `required_ppe`, `pre_use_checks`, `safe_work_procedures` NOT NULL. | Issue-based and task-specific risk assessment master templates. |
| `company_risk_assessments` | `id` (UUID) | `company_id` (UUID fk `companies.id`), `template_id` (UUID fk `risk_assessment_templates.id`), `title` (text), `work_area` (text), `equipment_id` (text), `assessor_name` (text), `assessment_date` (date, default `CURRENT_DATE`), `review_due_date` (date), `risk_items` (JSONB, default `'[]'`), `ppe_verified` (JSONB, default `'[]'`), `pre_use_verified` (JSONB, default `'[]'`), `assessor_signature` (text), `status` (text, default `'Active'`), `created_at` (timestamptz) | `id`, `title`, `work_area`, `assessor_name`, `assessment_date`, `review_due_date`, `risk_items`, `ppe_verified` NOT NULL. | Tenant customized task-specific risk assessments. |
| `crop_pack_addon_subscriptions` | `id` (UUID) | `company_id` (UUID fk `companies.id`), `crop_name` (text), `paystack_subscription_code` (text), `paystack_email_token` (text), `status` (text, default `'active'`), `cancellation_requested_at` (timestamptz), `cancelled_at` (timestamptz), `created_at` (timestamptz) | `id`, `company_id`, `crop_name`, `status` NOT NULL. Unique on `(company_id, crop_name)`. | Recurring Paystack subscriptions for self-funded R80/mo bolt-on packs. |
| `crop_pack_addon_purchases` | `id` (UUID) | `company_id` (UUID fk `companies.id`), `crop_name` (text), `paystack_ref` (text), `purchased_by` (UUID fk `profiles.id`), `created_at` (timestamptz) | `id`, `company_id`, `crop_name`, `paystack_ref` NOT NULL. Unique on `paystack_ref`. | Audit ledger recording completed Paystack charge transactions for crop pack bolt-ons. |
| `support_tickets` | `id` (UUID) | `company_id` (UUID fk `companies.id`), `user_id` (UUID), `user_name` (text), `user_email` (text), `ticket_type` (text), `subject` (text), `message` (text), `status` (text, default `'open'`), `created_at` (timestamptz) | `id`, `user_email`, `ticket_type`, `subject`, `message`, `status` NOT NULL. | In-app support and ticket submissions. |
| `processor_referral_leads` | `id` (UUID) | `company_id` (UUID fk `companies.id`), `user_id` (UUID), `crop_name` (text), `processor_name` (text), `status` (text, default `'pending'`), `created_at` (timestamptz) | `id`, `crop_name`, `processor_name`, `status` NOT NULL. | Commercial pipeline leads submitted when growers refer their processors for sponsorship. |
| `sandbox_jsonb_backup` | N/A | `table_name` (text), `row_id` (text), `column_name` (text), `original_value` (JSONB), `backed_up_at` (timestamptz) | `table_name`, `row_id`, `column_name`, `backed_up_at` NOT NULL. | Safety backup ledger for JSONB transformations during data schema migrations. |

#### Storage Buckets & Policies
1. **`sops`** (Private/Authenticated):
   - Contains Word (`.docx`) and PDF documents organized by partner/estate folders (`corporate_partners/Test-Banana/`, `corporate_partners/Test-Mac/`, `doveton_farm/`, `elliott_farm/`, `outlook_farm/`, `simple_solutions/`).
   - Accessible via signed URLs or authenticated client downloads.
2. **`thumbnails`** (Public/Authenticated):
   - Contains vector SVG thumbnail artwork organized by directory (`corporate_partners/`, `doveton_farm/`, `elliott_farm/`, `outlook_farm/`, `simple_solutions/`).
   - Publicly readable to allow low-latency catalog rendering.
3. **`avatars`** (Public/Authenticated):
   - Path scoped to `${userId}/avatar.${ext}`.
   - Upload policy enforces `auth.uid() = (storage.foldername(name))[1]` with upsert capability.

### Stored Procedures & RPC Patterns

1. **`validate_grower_code(p_grower_code text)` $\to$ `jsonb`**:
   - `SECURITY DEFINER`. Read-only validator.
   - Checks `partner_grower_registry` joined with `corporate_partners`.
   - Returns `{ valid: boolean, partner_name: text, crop: text, is_claimed: boolean, message: text }`.
   - Does not perform database mutations; used for instant client validation during checkout and modal entry.
2. **`claim_additional_grower_subsidy(p_grower_code text)` $\to$ `jsonb`**:
   - `SECURITY DEFINER`. Authenticates caller via `auth.uid()`.
   - Validates that the grower code exists, is active, and is not already claimed by another enterprise.
   - Atomically updates `partner_grower_registry` (`is_claimed = true`, `claimed_by_company_id = caller_company_id`, `claimed_at = now()`).
   - Appends the crop to `companies.sponsored_crop_packs` and the code to `companies.partner_grower_codes`.
   - Automatically detects and drains/removes any existing self-funded bolt-on subscription in `purchased_crop_packs` for that crop.
3. **`provision_company_subscription(p_company_name text, p_user_email text, p_paystack_ref text, p_target_tier text, p_grower_code text)` $\to$ `uuid`**:
   - `SECURITY DEFINER`. Executed post-checkout to atomically provision a new tenant workspace.
   - Creates the `companies` row with assigned tier (`basic`, `essential`, `enterprise`), appropriate seat limit (1, 4, or 8), and billing status.
   - If `p_grower_code` is provided, re-validates the code authoritatively on the server, links it in `partner_grower_registry`, and unlocks the corresponding `sponsored_crop_packs`.
   - Creates or updates the primary `profiles` record with `role = 'Master Admin'` and assigns `company_id`.
   - Invokes `provision_company_baseline_register(new_company_id)` to initialize standard statutory baseline assessments.
4. **`purchase_crop_pack_addon(p_company_id uuid, p_user_id uuid, p_crop_name text, p_paystack_ref text)` $\to$ `jsonb`**:
   - **Strictly granted to `service_role` only**. Browser clients are forbidden from invoking this function.
   - Called exclusively by the server-side `paystack-webhook` Deno edge function upon verified `charge.success`.
   - Validates that `p_user_id` belongs to `p_company_id`.
   - Idempotent on `paystack_ref`: inserts into `crop_pack_addon_purchases` (`ON CONFLICT (paystack_ref) DO NOTHING`).
   - Appends `p_crop_name` to `companies.purchased_crop_packs` (`array_append`).
5. **`upgrade_company_tier(p_target_tier text, p_paystack_ref text)` $\to$ `jsonb`**:
   - `SECURITY DEFINER`. Authenticates caller via `auth.uid()`.
   - Verifies the user is an Admin of their company.
   - Updates `companies.tier` to `p_target_tier`, adjusts `seat_limit` (4 for essential, 8 for enterprise), and updates billing timestamps.
6. **`remove_team_member(p_target_user_id uuid)` $\to$ `jsonb`**:
   - `SECURITY DEFINER`. Disassociates a manager profile from a tenant (`company_id = NULL`, `role = 'Staff'`).
   - Evaluates admin authorization server-side in a single atomic query. **Completely eliminates the PostgreSQL infinite recursion trap (`42P17`)** that occurs when an RLS policy queries `profiles` to check admin status.
7. **`provision_company_baseline_register(p_company_id uuid)` $\to$ `record`**:
   - `SECURITY DEFINER`. Copies master baseline templates from `baseline_ra_templates` into `company_baseline_assessments` for new tenant workspaces, setting default 12-month review schedules.
8. **`get_partner_portal_data(p_token text)` $\to$ `jsonb`**:
   - `SECURITY DEFINER`. Validates 35-day tokens against `partner_portal_tokens` (`expires_at > now()` and `revoked_at IS NULL`).
   - Returns partner branding and aggregate supply chain metrics from `partner_supply_chain_metrics` without exposing cross-tenant raw records.
9. **`submit_processor_referral(p_crop_name text, p_processor_name text)` $\to$ `void`**:
   - `SECURITY DEFINER`. Inserts commercial referral lead into `processor_referral_leads` capturing the caller's `company_id` and `user_id`.
10. **`get_my_company_id()` $\to$ `uuid`**:
    - `SECURITY DEFINER STABLE`. Fast cached lookup returning `company_id` from `profiles` for `auth.uid()`. Used extensively in RLS policies.
11. **`sync_profile_to_auth_meta()` $\to$ `trigger`**:
    - Trigger function keeping `auth.users.raw_user_meta_data` synchronized with `profiles` first/last names.

### Row Level Security (RLS) & Auth Policies

All 18 public database tables enforce Row Level Security (`rls_enabled = true`).

```mermaid
graph TD
    User([Authenticated User: auth.uid()]) --> Profile[profiles]
    Profile -->|get_my_company_id()| Company[companies: company_id]
    
    Company --> TR[training_records]
    Company --> CBA[company_baseline_assessments]
    Company --> CRA[company_risk_assessments]
    Company --> ST[support_tickets]
    Company --> CPAS[crop_pack_addon_subscriptions]
    Company --> PRL[processor_referral_leads]
    
    User --> UVP[user_video_progress: user_id = auth.uid()]
    
    subgraph Master Catalog
        V[videos: company_id IS NULL]
        S[sops: company_id IS NULL]
        BRT[baseline_ra_templates]
        RAT[risk_assessment_templates]
    end
    
    Company -.->|Private Custom Assets| V
    Company -.->|Private Custom Assets| S
```

#### Detailed Table RLS Policies:
- **`profiles`**:
  - `SELECT`: `((id = auth.uid()) OR (company_id = get_my_company_id()))`
  - `INSERT`: `(auth.uid() = id)`
  - `UPDATE`: `(auth.uid() = id)` for self updates, OR `(EXISTS (SELECT 1 FROM profiles admin_p WHERE admin_p.id = auth.uid() AND admin_p.company_id = profiles.company_id AND (lower(admin_p.role) LIKE '%admin%')))` for admins.
- **`companies`**:
  - `SELECT`: `(id IN (SELECT company_id FROM profiles WHERE id = auth.uid()))`
  - `INSERT`: Public during registration checkout (`true`).
  - `UPDATE`: Restricted to company members/admins (`id IN (SELECT company_id FROM profiles WHERE id = auth.uid()))`. Direct browser mutations to `tier`, `seat_limit`, and `sponsored_crop_packs` are forbidden by business logic; mutations are mediated by RPCs.
- **`corporate_partners`**:
  - `SELECT`: Authenticated users can view (`true`).
- **`partner_grower_registry`**:
  - `SELECT`: Users can view claimed codes belonging to their company (`claimed_by_company_id = get_my_company_id()`).
- **`company_baseline_assessments`**:
  - `SELECT / INSERT / UPDATE`: `(company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()))`
- **`baseline_ra_templates`**:
  - `SELECT`: Authenticated users can read master templates (`true`).
- **`training_records`**:
  - `SELECT / INSERT`: `(company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()))`
- **`sops`**:
  - `SELECT`: Master catalog or tenant-specific (`(company_id IS NULL) OR (company_id = (SELECT company_id FROM profiles WHERE id = auth.uid() LIMIT 1))`).
- **`company_risk_assessments`**:
  - `SELECT / INSERT / ALL`: `((company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid())) OR (company_id IS NULL))`
- **`user_video_progress`**:
  - `SELECT / INSERT / UPDATE`: `(auth.uid() = user_id)`
- **`risk_assessment_templates`**:
  - `SELECT`: Public read access (`true`).
- **`crop_pack_addon_subscriptions`**:
  - `SELECT`: `(company_id = get_my_company_id())`
- **`processor_referral_leads`**:
  - `SELECT`: `(company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()))`
- **`support_tickets`**:
  - `INSERT`: `(auth.uid() = user_id)`
  - `SELECT`: `(company_id IN (SELECT company_id FROM profiles WHERE id = auth.uid()))`
- **`videos`**:
  - `SELECT`: Authenticated users can view videos (`true`); public users can view master catalog (`company_id IS NULL`).

---

## 4. Third-Party Integrations

### Paystack Payment & Subscription Infrastructure
- **Client SDK**: Paystack Inline v2 (`https://js.paystack.co/v2/inline.js`).
- **Live Public Key**: `pk_live_6e9ead28ba957dc643c949c5dc8164e3d62c0d09`
- **Subscription Plans & Pricing**:
  - **Basic Vault**: `PLN_q37eti0fct6aazv` — **R180 /mo** (18,000 cents). 1 Admin Seat, full multi-language streaming library, no training records or sign-offs.
  - **Essential Vault**: `PLN_glbt6ice9adjj45` — **R280 /mo** (28,000 cents). 4 Total Seats (1 Admin + 3 Managers), Training Records dashboard, digital compliance sign-offs, 10 Individual Worker Certificates/mo, 5 Group Registers/mo.
  - **Enterprise Solution (Retail Full Price)**: `PLN_xx7w3l93tke10kh` — **R450 /mo** (45,000 cents). 8 Total Seats (1 Admin + 7 Managers), Unlimited PDF downloads, Digital Risk Assessments (Baseline & Task registers), full SOP library with custom hosting, Priority Support.
  - **Enterprise Solution (Corporate Subsidized)**: `PLN_v8iouh4li43y60u` — **R337.50 /mo** (33,750 cents). 25% processor-subsidized price for growers delivering to verified commercial partners. 8 Seats, all Enterprise features.
  - **Crop Pack Add-on Bolt-On**: `PLN_8n5qrpeh23evvnu` — **R80 /mo** (8,000 cents) per individual crop pack (Macadamia, Banana, Citrus).
- **Paystack Webhook (`/supabase/functions/paystack-webhook`)**:
  - Verifies HMAC SHA512 signature using `x-paystack-signature` header against `PAYSTACK_SECRET_KEY`.
  - Handles `subscription.create`: Captures recurring subscription code and email token into `crop_pack_addon_subscriptions` for automated billing management.
  - Handles `charge.success`: Server-side execution of `purchase_crop_pack_addon` via `SUPABASE_SERVICE_ROLE_KEY`. Idempotent on `paystack_ref`. Browser clients cannot call this RPC directly.
  - Handles cancellation queue: Opportunistically queries `crop_pack_addon_subscriptions` for rows with `status = 'pending_cancellation'` and calls Paystack's subscription disable endpoint (`https://api.paystack.co/subscription/disable`).

### Vimeo Player SDK & Video Streaming
- **SDK**: Vimeo Player API (`https://player.vimeo.com/api/player.js`).
- Embedded iframe in `module.html` with parameters:
  `https://player.vimeo.com/video/{videoId}?title=0&byline=0&portrait=0&badge=0&autoplay=1#t={startTime}s`
- **Progress Tracking & Synchronization**:
  - Listens to player events: `timeupdate`, `pause`, and `ended`.
  - Throttled progress flush: Client-side throttling buffers database updates to once every 5 seconds via `flushProgress()`, saving network bandwidth on rural farm connections.
  - Syncs `progress_seconds`, `duration_seconds`, and `percentage` to `user_video_progress`.
  - Milestone completion: When `percentage >= 90`, marks `is_completed = true` and emits GA4 event `video_complete`.

### Resend Transactional Mail Engine
- **Endpoint**: Direct REST calls to `https://api.resend.com/emails` within Deno edge functions using `RESEND_API_KEY`.
- **Edge Functions**:
  1. `notify-referral-lead`:
     - Triggered when growers refer a commercial processor in `vault.html`, `module.html`, or `sop.html`.
     - Authenticated via timing-safe comparison on `x-webhook-secret` (`REFERRAL_WEBHOOK_SECRET`) or service role token.
     - Sanitizes user input with `escapeHtml()` to eliminate script injection risks.
     - Delivers branded HTML notification to `luca@simpleza.co.za` with `reply_to` pointing to the submitter's email.
  2. `notify-support-ticket`:
     - Triggered on new support ticket submissions in `support.html`.
     - Delivers formatted notification to support team with `reply_to` set to user's registered email address.
  3. `partner-monthly-digest`:
     - Cron-triggered batch dispatch for corporate partners.
     - Authenticated via `CRON_SECRET` or service role bearer.
     - Iterates active partners in `corporate_partners`, revokes prior tokens, mints fresh 35-day tokens in `partner_portal_tokens`, and emails formatted HTML digest with zero-login magic links to `partner.contact_email`.

### Compliance, PDF Generation & External Workflows
- **Client-Side PDF Engines**: `jspdf.umd.min.js` generates statutory legal documents in the browser:
  - **Individual Worker Training Certificate**: A4 landscape certificate with South African OHSA compliance stamp, supervisor digital signature, worker signature data, identity numbers, and date stamps.
  - **Group Induction Log Sheet**: A4 landscape attendance register with batch session ID, supervisor declaration, and worker attendance roster.
  - **Baseline Risk Assessment Register**: A4 landscape statutory report including hazard register matrices, inherent/residual risk scoring, review intervals, and Section 16(2) appointee digital signature.
  - **Task-Specific Risk Assessment Register**: A4 landscape audit report with work area, equipment ID, verified PPE checklist, and assessor sign-off.
  - **Corporate Supply Chain Audit Certificate & CSV Manifest**: A4 landscape audit certificate and CSV export with a 16-character SHA-256 cryptographic canonical data checksum.
- **Quota Management**:
  - Essential Plan: Enforces 10 Individual Worker Certificates/mo and 5 Group Registers/mo via monthly localStorage tracking keys (`cert_quota_{companyId}_{year}_{month}` and `group_quota_{companyId}_{year}_{month}`).
  - Enterprise Plan: Unlimited PDF certificates and registers.
- **Google Analytics 4 (GA4)**:
  - Measurement ID: `G-L0HP7V44GT`.
  - Tracks ecommerce actions: `begin_checkout`, `purchase`.
  - Tracks compliance milestones: `video_complete`, `generate_individual_cert`, `click_book_scoping_call`.
  - Automatic suppression on `localhost` and for internal users (`disable_analytics=true`).
- **External Workflows (`systems.html`)**:
  - Architectural showcase of ClickUp ERP implementations, Procurement intake workflows, and Construction Gantt tracking.

---

## 5. Route & File Map

| Path / File | Purpose | Scripts Loaded | Tables & RPCs Accessed |
| :--- | :--- | :--- | :--- |
| [`index.html`](file:///home/luca/dev/the-vault-web/index.html) | Public landing page, marketing video demo carousel, pricing matrix, Paystack subscription checkout, grower code validator, and login modal. | Tailwind CDN, Supabase JS v2, Paystack Inline v2, GA4. | `videos` (master catalog), `validate_grower_code` RPC, `provision_company_subscription` RPC. |
| [`vault.html`](file:///home/luca/dev/the-vault-web/vault.html) | Authenticated training catalog dashboard. Displays continue watching banner, category filters, progress indicators, crop-pack gating locks, and bolt-on purchase modals. | Tailwind CDN, Supabase JS v2, Paystack Inline v2, Vimeo Player SDK, `js/main.js`, `js/profile-engine.js`. | `videos`, `user_video_progress`, `profiles`, `companies`, `claim_additional_grower_subsidy` RPC, `submit_processor_referral` RPC. |
| [`module.html`](file:///home/luca/dev/the-vault-web/module.html) | Interactive video classroom & compliance sign-off terminal. Embeds Vimeo player, tracks watch progress, and captures supervisor/worker digital signatures for single and group inductions. | Tailwind CDN, Supabase JS v2, Paystack Inline v2, Vimeo Player SDK, `js/main.js`, `js/profile-engine.js`. | Vimeo Player API, `videos`, `user_video_progress`, `training_records`, `profiles`, `companies`, `claim_additional_grower_subsidy` RPC, `submit_processor_referral` RPC. |
| [`records.html`](file:///home/luca/dev/the-vault-web/records.html) | Employee training audit register. Displays verified completions, supervisor signatures, batch session logs, PDF certificates, and enforces monthly export quotas. | Tailwind CDN, Supabase JS v2, jsPDF UMD, `js/main.js`, `js/profile-engine.js`. | `training_records`, `companies`, `profiles`, `videos`, jsPDF engine. |
| [`risk-assessments.html`](file:///home/luca/dev/the-vault-web/risk-assessments.html) | Statutory OHSA risk assessment module. Houses Baseline Risk Assessments (BRAs) and task-specific risk registers, annual review authorizations, and landscape A4 PDF export. | Tailwind CDN, Supabase JS v2, jsPDF UMD, `js/main.js`, `js/profile-engine.js`. | `baseline_ra_templates`, `company_baseline_assessments`, `risk_assessment_templates`, `company_risk_assessments`, `provision_company_baseline_register` RPC, jsPDF engine. |
| [`sop.html`](file:///home/luca/dev/the-vault-web/sop.html) | Standard Operating Procedures repository. Searchable SOP library with category filters, crop pack gating, and partner-branded document download overrides. | Tailwind CDN, Supabase JS v2, Paystack Inline v2, `js/main.js`, `js/profile-engine.js`. | `sops`, `companies`, `profiles`, `claim_additional_grower_subsidy` RPC, `submit_processor_referral` RPC. |
| [`partner-portal.html`](file:///home/luca/dev/the-vault-web/partner-portal.html) | Zero-login corporate partner compliance portal. Evaluates 35-day tokens to display grower adoption, BRA compliance, Chart.js visuals, CSV exports, and statutory PDF certificates. | Tailwind CDN, Supabase JS v2, Chart.js, jsPDF UMD. | `get_partner_portal_data` RPC, Chart.js engine, jsPDF engine. |
| [`invite.html`](file:///home/luca/dev/the-vault-web/invite.html) | Manager onboarding portal. Enforces seat caps, supports Google OAuth or email/password signup, and attaches user to the inviting company. | Tailwind CDN, Supabase JS v2. | Supabase Auth, `companies`, `profiles`. |
| [`support.html`](file:///home/luca/dev/the-vault-web/support.html) | In-app support ticket intake form. Allows users to submit technical, billing, and operational support requests directly into Supabase. | Tailwind CDN, Supabase JS v2, `js/main.js`, `js/profile-engine.js`. | `support_tickets`, `profiles`, `companies`. |
| [`systems.html`](file:///home/luca/dev/the-vault-web/systems.html) | Enterprise showcase illustrating PM suites, Procurement architecture, and Construction ERP workflows with screenshot modal galleries. | Tailwind CDN, Vanilla JS gallery controller, GA4. | Static HTML/CSS, Vanilla JS modal controllers. |
| [`profile-modal.html`](file:///home/luca/dev/the-vault-web/profile-modal.html) | Master profile & organization management modal dynamically fetched and injected into all authenticated pages by `profile-engine.js`. | DOM template fetched asynchronously by `profile-engine.js`. | Controlled by `profile-engine.js` (Auth, Storage, RPCs). |
| [`404.html`](file:///home/luca/dev/the-vault-web/404.html) | Custom error page for invalid routes. | Tailwind CDN. | Static navigation link returning to `vault.html`. |
| [`js/main.js`](file:///home/luca/dev/the-vault-web/js/main.js) | Sidebar layout controller, mobile menu toggles, body scroll lock, and active navigation route synchronization. | Native ES6 DOM controller. | Native DOM APIs. |
| [`js/profile-engine.js`](file:///home/luca/dev/the-vault-web/js/profile-engine.js) | Core platform engine: session lifecycle, dynamic modal injection, multi-tenant state resolution, crop-pack gating, seat limits, and Paystack upgrade handlers. | Native ES6 module. | Supabase Client, Paystack Inline v2, Storage API, RPCs (`upgrade_company_tier`, `remove_team_member`, `claim_additional_grower_subsidy`, `validate_grower_code`). |
| [`scripts/sync_schema.sh`](file:///home/luca/dev/the-vault-web/scripts/sync_schema.sh) | Schema synchronization shell script dumping Supabase remote schema into `.ai/SUPABASE_SCHEMA.md`. | Bash script. | Supabase CLI (`npx supabase db dump`). |
| [`supabase/config.toml`](file:///home/luca/dev/the-vault-web/supabase/config.toml) | Supabase CLI configuration declaring edge function entrypoints, import maps, and JWT verification settings. | TOML configuration. | Supabase CLI. |
| [`supabase/functions/paystack-webhook/index.ts`](file:///home/luca/dev/the-vault-web/supabase/functions/paystack-webhook/index.ts) | Deno edge function verifying HMAC SHA512 signatures, handling Paystack events (`subscription.create`, `charge.success`), invoking `purchase_crop_pack_addon`, and disabling cancelled subscriptions. | Deno, Supabase Admin Client, Paystack REST API. | `crop_pack_addon_subscriptions`, `purchase_crop_pack_addon` RPC. |
| [`supabase/functions/notify-referral-lead/index.ts`](file:///home/luca/dev/the-vault-web/supabase/functions/notify-referral-lead/index.ts) | Deno edge function dispatching transactional emails via Resend when a grower submits a processor referral. Features timing-safe auth and HTML escaping. | Deno, Resend REST API. | Resend API (`alerts@simpleza.co.za`). |
| [`supabase/functions/notify-support-ticket/index.ts`](file:///home/luca/dev/the-vault-web/supabase/functions/notify-support-ticket/index.ts) | Deno edge function dispatching transactional emails via Resend when a user submits a support ticket in `support.html`. | Deno, Resend REST API. | Resend API (`alerts@simpleza.co.za`). |
| [`supabase/functions/partner-monthly-digest/index.ts`](file:///home/luca/dev/the-vault-web/supabase/functions/partner-monthly-digest/index.ts) | Cron-triggered Deno edge function generating revolving 35-day tokens and emailing compliance digests to corporate partner contacts. | Deno, Supabase Admin Client, Resend REST API. | `corporate_partners`, `partner_portal_tokens`, Resend API. |
| [`docs/*.pdf`](file:///home/luca/dev/the-vault-web/docs) | Statutory legal documentation: Aggregated Underwriter Data Feed Terms, Cookie & Local Storage Policy, Corporate Partner Subsidy Agreement, Master Terms of Service, POPIA Section 21 Operator Agreement, Statutory Risk Assessment Appointee Schedule, and Website Privacy Policy. | Static PDF documents. | Static download links. |

---

## 6. Hard Architectural Constraints

### Security Rules
1. **Never Expose Sensitive Keys**:
   - The client browser must **only ever** receive the Supabase anonymous public key (`window.supabaseClient`) and Paystack public key (`pk_live_6e9ead28ba957dc643c949c5dc8164e3d62c0d09`).
   - `SUPABASE_SERVICE_ROLE_KEY`, `PAYSTACK_SECRET_KEY`, `RESEND_API_KEY`, `REFERRAL_WEBHOOK_SECRET`, and `CRON_SECRET` must **never** appear in client-side HTML, JavaScript, or git commits. They belong exclusively in Supabase Edge Function environment variables.
2. **Strict Multi-Tenant Scoping**:
   - Every database query for tenant data must filter by `company_id`.
   - Never allow client queries to update `companies.tier`, `companies.seat_limit`, or `companies.sponsored_crop_packs` directly. All entitlement mutations must be mediated by `SECURITY DEFINER` RPCs or verified server-side webhooks.
3. **Paystack Signature Verification**:
   - The Paystack webhook endpoint must always verify the HMAC SHA512 signature in `x-paystack-signature` using `PAYSTACK_SECRET_KEY` before reading request bodies.
4. **HTML Sanitization in Notifications**:
   - Edge functions rendering email templates with user input (e.g. `notify-referral-lead`, `notify-support-ticket`) must pass all user-controlled text through `escapeHtml()` to eliminate HTML and script injection risks.
5. **Locked RPC Privileges**:
   - `purchase_crop_pack_addon` is strictly granted to `service_role` only. The browser console cannot execute this procedure.

### Zero-Build Guidelines
1. **No Client Node.js Toolchains**:
   - Do not install Vite, Webpack, esbuild, Babel, or Parcel for client assets.
   - Do not run `npm build` or `npm run build` in CI/CD. Cloudflare Pages must serve raw files directly from the repository root.
2. **Native ES6+ in Browsers**:
   - Use standard ES6 features supported natively by modern browsers (`async/await`, optional chaining, modules, template literals).
   - Do not write JSX, TypeScript, or Sass in the frontend web directories.
3. **Tailwind via CDN**:
   - Maintain styling strictly using Tailwind utility classes configured through the official Tailwind CDN script.

### Forbidden Patterns
- **No Infinite RLS Recursion (Error `42P17`)**:
  - Never write an RLS policy on `profiles` that queries `profiles` to check if `role = 'Admin'`. Doing so triggers infinite recursion in PostgreSQL. Use dedicated `SECURITY DEFINER` stored procedures (e.g., `remove_team_member`) for multi-profile administration.
- **No Stale Profile Overwrites on Auth**:
  - During OAuth callbacks or invite linking, never overwrite an existing user's `profiles.company_id` with a stale value from `localStorage`. Check if the user already has an established profile before applying an invite parameter.
- **No Direct Table Writing for Gated Crops**:
  - Unlocking crop packs must occur exclusively through `validate_grower_code` $\to$ `claim_additional_grower_subsidy` or through verified Paystack webhooks triggering `purchase_crop_pack_addon`.
- **No Direct Mutation of Billing Tiers from Browser**:
  - The frontend client must never issue an `UPDATE` on `companies` to alter `tier`, `seat_limit`, or `subscription_status`. All tier transitions must route through `upgrade_company_tier` or Paystack webhooks.

---

## 7. Changelog & Current State

### Baseline Entry (2026-09-26)
- **Repo Restructuring & Audit**: Completed comprehensive audit of all HTML routes, Deno edge functions, client JS engines, and legal documents.
- **Platform Directory Restructuring (`v3-dev`)**:
  - Migrated legacy `assets/java_files/` to `js/` (`js/main.js`, `js/profile-engine.js`) and established `js/modules/`.
  - Realigned master branding assets to `assets/branding/` (`Simple_Logo.jpg`, `Simple_Logo-removebg-preview.png`, `Simple_Logo-White.png`).
  - Updated all HTML script tags and favicon/image asset references to new locations.
  - Initialized `.ai/ARCHITECTURE.md` and `AGENTS.md` defining strict zero-build rules, preserved root HTML entry points, and multi-tenant RLS constraints.
- **Standardized Multi-Tenant Field**: Confirmed full standardization on `company_id` across `profiles`, `companies`, `training_records`, and assessment tables.
- **Crop-Pack Stacking Architecture (Layer 1, 2, 3)**:
  - *Layer 1 (Core Farm Safety)*: Universal farm modules (general safety, workshops, irrigation, fleet) accessible to all tiers without co-branding.
  - *Layer 2 (Specialized Crop Packs)*: Gating operational for Macadamia, Banana, and Citrus packs via subsidized grower codes or R80/mo bolt-on add-ons.
  - *Layer 3 (Partner Attribution)*: Co-branding badges, topbar partner pill, and footer sponsor chains dynamically populated from `partner_grower_registry` joins.
- **Paystack Webhook & Edge Security**:
  - Secured `purchase_crop_pack_addon` RPC with `service_role` privileges, preventing client-side execution.
  - Hardened HMAC verification on `/supabase/functions/paystack-webhook`.
  - Added timing-safe authorization guards and HTML escaping to `/supabase/functions/notify-referral-lead`.
- **Closer Protocol Configuration**:
  - Verified `.agents/agents/closer/agent.md` protocol to maintain and update this `PROJECT_BRAIN.md` at the conclusion of every development session.

### Mobile Optimization & Responsive Audit Pass (2026-09-26)
- **Eliminated Horizontal Overflow & Blowout (< 768px Viewports)**:
  - Fixed scaling overflow in `index.html` on the featured Essential Vault card (`scale-100 lg:scale-105 hover:scale-[1.02] lg:hover:scale-[1.07]`), preventing viewport blowout on 360px–414px mobile devices.
  - Ensured `<meta name="viewport" content="width=device-width, initial-scale=1.0">` is uniformly enforced across all 11 HTML entry points.
- **Top Bars & Dynamic Controls**:
  - Re-anchored topbar dropdowns (`topbar-sponsor-dropdown`, `notification-dropdown`) across `vault.html`, `records.html`, `sop.html`, `risk-assessments.html`, `support.html`, and `module.html` to fluid widths (`w-[calc(100vw-2rem)] max-w-xs sm:w-72` and `w-[calc(100vw-2rem)] max-w-sm`) to prevent clipping off-screen.
  - Added smooth text truncation (`truncate max-w-[140px]`) to company names in desktop and tablet headers.
  - Truncated partner identity badge elements in `partner-portal.html` (`truncate max-w-[90px]`, `truncate max-w-[70px]`, `max-w-[200px] sm:max-w-none`).
- **Sidebar & Mobile Drawer Behavior**:
  - Inserted missing `#sidebar-backdrop` into `risk-assessments.html` for clean overlay dimming and backdrop-click closing.
  - In `js/main.js`: Bound body scroll locking (`document.body.classList.add/remove('overflow-hidden')`) upon drawer open/close. Added `Escape` key close listener and window `resize` handler that auto-dismisses drawer when scaling up to desktop (>= 1024px).
- **Search Bars, Filters & Tab Strips**:
  - Refactored search inputs and filter `<select>` dropdowns across all catalog and table pages to stack full-width vertically on mobile with 44px touch targets (`py-2.5 min-h-[44px]`).
  - Added cross-browser `.no-scrollbar` styling rules across all views and applied horizontal scroll strips (`flex overflow-x-auto no-scrollbar gap-2 pb-1/pb-2`) to category pills, baseline filters, and status tabs.
- **Data Grids, Cards & Data Tables**:
  - Refactored dynamic SOP cards in `sop.html` and Baseline Assessment cards in `risk-assessments.html` with responsive inner padding (`p-4 sm:p-6`) and full-width, touch-friendly action buttons (`w-full sm:w-auto min-h-[38px]`).
  - Ensured wide compliance tables (`records.html`, `risk-assessments.html`, `partner-portal.html`) are isolated within dedicated horizontal scroll containers (`w-full overflow-x-auto -mx-3 px-3 sm:mx-0 sm:px-0`).
- **Modals & Overlays**:
  - Refactored `#profileModal` in `profile-modal.html`: modal container converted to fluid responsive flex layout (`p-0 sm:p-4`, `h-full sm:h-[600px] flex flex-col sm:flex-row`), navigation converted to horizontally scrollable tab bar (`flex overflow-x-auto no-scrollbar flex-nowrap shrink-0 border-b`), headings responsive (`text-2xl sm:text-3xl`), and close button offset adjusted.
  - Refactored `#vaultUpgradeReviewModal`, `#newAssessmentModal`, `#baselineReviewModal`, and `#inspectBaselineModal` footers to `flex flex-col-reverse sm:flex-row items-stretch sm:items-center` with full-width primary action buttons on mobile.

### Upcoming Priority Tasks
1. **Citrus Processing Pack**: Finalize dedicated SOP documentation and master risk assessment templates for citrus harvesting, packing, and cold-storage operations.
2. **Paystack Bolt-On Automation**: Verify live webhook processing of `charge.success` events for `PLN_8n5qrpeh23evvnu` across production testing farms.
3. **Cloudflare Security Headers**: Configure `_headers` file in Cloudflare Pages to enforce strict Content Security Policy (CSP), HTTP Strict Transport Security (HSTS), and frame options.