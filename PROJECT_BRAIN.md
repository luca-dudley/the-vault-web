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

### Standard Client-Side Helpers & Utility Contracts
Every authenticated route implements or relies upon standard client-side utility patterns:
1. **`escapeHtml(value)`**:
   - Escapes special characters (`&`, `<`, `>`, `"`, `'`) for safe HTML string interpolation into innerHTML.
   - Prevents XSS when rendering dynamic user data, worker names, clock numbers, or incident narratives.
2. **`waitForDbClient(maxWaitMs = 5000)`**:
   - Asynchronous polling loop (50ms interval) awaiting initialization of `window.dbClient` by `js/profile-engine.js`.
   - Guarantees database queries, roster lookups, and session bootstrapping never fail due to asynchronous race conditions.
3. **`getCanvasCoordinates(canvas, clientX, clientY)`**:
   - Scales mouse and touch pointer events to actual high-DPI canvas internal bitmap dimensions: `x = (clientX - rect.left) * (canvas.width / rect.width)`.
   - Eliminates drawing offset and pointer drift on retina displays and mobile touchscreens across signature pads (`module.html`, `incidents.html`, `records.html`).
4. **Dynamic Guest Worker Repeater Pattern (`module.html`)**:
   - Pinned trigger button (`#btnAddGuestWorker`) anchored directly underneath the primary filtered roster container.
   - Dynamically renders individual guest worker rows (`#guestWorkersList`) beneath the button using `createGuestWorkerRowHtml(rowId, data)`.
   - Provides per-row deletion via `removeGuestWorkerRow(btn)` with live form validation re-checks and clean layout collapse.
   - Collects valid unlisted workers via `getValidGuestWorkers()` to merge with selected roster members during statutory sign-off.

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
| `companies` | `id` (UUID) | `name` (text), `subscription_status` (text, default `'active'`), `seat_limit` (int4, default `5`), `tier` (text, default `'Base'`), `paystack_subscription_code` (text), `paystack_customer_code` (text), `vat_number` (text), `postal_address` (text), `phone` (text), `contact_email` (text), `partner_grower_codes` (text[]), `sponsored_crop_packs` (text[]), `purchased_crop_packs` (text[]), `is_subsidized` (bool, default `false`), `unlock_all_crops` (bool, default `false`), `company_stamp_url` (text), `created_at` (timestamptz) | `name` NOT NULL | Primary tenant accounts. Encapsulates billing state, tier, seat limits, subsidized crop packs, purchased bolt-ons, official estate stamp URL, and claimed partner grower codes. |
| `profiles` | `id` (UUID) | `company_id` (UUID fk `companies.id`), `first_name` (text), `last_name` (text), `role` (text, default `'Staff'`), `tier` (text, default `'basic'`), `avatar_url` (text), `created_at` (timestamptz) | `id` maps 1:1 to `auth.users.id`. `company_id` nullable during registration. | User profile linked directly to Supabase Auth users. Maps user to tenant company and seat permissions. |
| `company_employees` | `id` (UUID) | `company_id` (UUID fk `companies.id`), `employee_number` (text), `first_name` (text), `last_name` (text), `id_passport_number` (text), `gender` (text), `team_or_orchard` (text), `is_active` (bool, default `true`), `created_at` (timestamptz), `updated_at` (timestamptz) | `id`, `company_id`, `employee_number`, `first_name`, `last_name`, `is_active` NOT NULL. | Farm workforce directory and employee roster for group induction attendance, certificate generation, and 365-day statutory compliance tracking. |
| `videos` | `id` (Text) | `title` (text), `description` (text), `category` (text, default `'Agriculture'`), `sub_tag` (text), `language` (text, default `'English'`), `total_seconds` (int4), `thumbnail_url` (text), `partner_thumbnails` (JSONB, default `'{}'`), `objectives` (JSONB, default `'[]'`), `questions` (JSONB, default `'[]'`), `curriculum_slug` (text), `company_id` (UUID fk `companies.id`), `company_name` (text), `streams` (JSONB) | `id`, `title`, `total_seconds` NOT NULL. `company_id IS NULL` for master catalog. | Master and tenant-specific video training modules. |
| `sops` | `id` (UUID) | `title` (text), `description` (text), `category` (text, default `'Agriculture'`), `sub_tag` (text, default `'General Safety'`), `doc_url` (text), `video_id` (text), `partner_docs` (JSONB, default `'{}'`), `curriculum_slug` (text), `company_id` (UUID fk `companies.id`), `company_name` (text), `created_at` (timestamptz), `updated_at` (timestamptz) | `id`, `title`, `doc_url` NOT NULL. `company_id IS NULL` for master catalog. | Standard Operating Procedures repository with partner-branded document download overrides (`partner_docs`). |
| `user_video_progress` | `id` (UUID) | `user_id` (UUID), `video_id` (text), `video_title` (text), `progress_seconds` (numeric, default `0`), `duration_seconds` (numeric, default `0`), `percentage` (numeric, default `0`), `is_completed` (bool, default `false`), `updated_at` (timestamptz) | `user_id`, `video_id`, `progress_seconds`, `duration_seconds`, `percentage` NOT NULL. Unique composite index on `(user_id, video_id)`. | Granular per-user video watch progress and completion milestones ($\ge 90\%$). |
| `training_records` | `id` (UUID) | `company_id` (UUID fk `companies.id`), `employee_id` (UUID fk `company_employees.id`), `module_title` (text), `employee_name` (text), `employee_number` (text), `gender` (text), `training_type` (text, default `'Individual'`), `completed_at` (date, default `CURRENT_DATE`), `status` (text, default `'Verified'`), `supervisor_name` (text), `supervisor_signature_data` (text), `employee_signature_data` (text), `signature_url` (text), `batch_session_id` (UUID), `created_at` (timestamptz) | `id`, `employee_name`, `module_title`, `completed_at`, `status` NOT NULL. | Tamper-evident employee statutory training sign-offs with canvas signatures for individual and group batches. |
| `incident_reports` | `id` (UUID) | `company_id` (UUID fk `companies.id`), `incident_number` (text), `incident_date` (date), `incident_time` (time), `reported_at` (timestamptz), `location_or_orchard` (text), `employee_id` (UUID fk `company_employees.id`), `injured_person_name` (text), `injured_person_id_number` (text), `injured_person_role` (text), `gender` (text), `incident_severity` (text), `nature_of_injury` (text), `body_part` (text), `equipment_chemical_involved` (text), `incident_description` (text), `root_cause_analysis` (text), `corrective_preventative_actions` (text), `action_assigned_to` (text), `action_target_date` (date), `action_completed_date` (date), `is_section_24_statutory` (bool, default `false`), `section_24_reported_at` (timestamptz), `investigated_by_name` (text), `investigated_by_role` (text), `investigator_signature` (text), `status` (text, default `'Open'`), `attachments` (JSONB, default `'[]'`), `created_at` (timestamptz), `updated_at` (timestamptz) | `id`, `company_id`, `incident_number`, `incident_date`, `incident_time`, `location_or_orchard`, `injured_person_name`, `injured_person_role`, `incident_severity`, `incident_description`, `root_cause_analysis`, `corrective_preventative_actions`, `action_assigned_to`, `action_target_date`, `investigated_by_name`, `investigated_by_role`, `investigator_signature`, `status` NOT NULL. | Statutory workplace incident and near-miss register under OHSA Section 24, DoL Annexure 1, and SIZA Social Audit standards. |
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
12. **`get_vault_catalog()` $\to$ `jsonb`**:
    - `SECURITY DEFINER`. Resolves caller's company tier, unlocked crop packs, and sponsored subsidies to return the full video and SOP catalog with computed access entitlements (`is_locked: boolean`).
13. **`get_module_stream(p_video_id text)` $\to$ `jsonb`**:
    - `SECURITY DEFINER`. Server-side entitlement validator for video streaming playback. Evaluates user subscription tier (`enterprise` full catalog vs basic), unlocked crop packs, and private estate library boundaries before releasing video stream IDs.
14. **`archive_training_record(p_record_id uuid)` $\to$ `jsonb`**:
    - `SECURITY DEFINER`. Enables Master Admins to softly archive training records (`status = 'Archived'`) for retraining supersedence without physical deletion of audit records.
15. **`log_induction_session(p_module_title text, p_supervisor_name text, p_supervisor_signature text, p_trainees jsonb)` $\to$ `jsonb`**:
    - `SECURITY DEFINER`. Records group or individual induction sessions, atomically linking trainees with `company_employees` and recording digital dual signatures. Generates a statutory `batch_session_id` UUID for all sessions (including single-trainee inductions) for register retrieval and audit traceability, and normalizes trainee gender using regex and title fallbacks.
16. **`sync_company_roster(p_employees jsonb, p_deactivate_missing boolean)` $\to$ `jsonb`**:
    - `SECURITY DEFINER`. Upserts employee rosters from CSV or form input into `company_employees`, matching by employee number and maintaining active compliance status. Features defensive worker surname de-duplication (preventing duplicate surname concatenation when payroll exports provide full names in first name fields), multi-lingual South African agricultural payroll gender normalization (`M`, `F`, `Man`, `Vrou`, `Meisie`, honorific prefixes), and supports optional deactivation of unlisted seasonal employees.

### Row Level Security (RLS) & Auth Policies

All 20 public database tables enforce Row Level Security (`rls_enabled = true`).

```mermaid
graph TD
    User([Authenticated User: auth.uid()]) --> Profile[profiles]
    Profile -->|get_my_company_id()| Company[companies: company_id]
    
    Company --> CE[company_employees]
    Company --> TR[training_records]
    Company --> IR[incident_reports]
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
| [`docs/architecture/specs/UNIFIED_INDUCTION_AND_ROSTER_SPEC.md`](file:///home/luca/dev/the-vault-web/docs/architecture/specs/UNIFIED_INDUCTION_AND_ROSTER_SPEC.md) | Comprehensive architectural and schema specification for the unified induction pipeline, Single Supervisor Statutory Gate (ECTA §13), and farm employee roster sync engine (`company_employees`). | Markdown architectural blueprint. | `company_employees`, `training_records`, RPCs (`log_induction_session`, `sync_company_roster`). |
| [`docs/legal/*.pdf`](file:///home/luca/dev/the-vault-web/docs/legal) | Statutory legal documentation: Aggregated Underwriter Data Feed Terms, Cookie & Local Storage Policy, Corporate Partner Subsidy Agreement, Master Terms of Service, POPIA Section 21 Operator Agreement, Statutory Risk Assessment Appointee Schedule, and Website Privacy Policy. | Static PDF documents. | Static download links. |

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

### Statutory Compliance, Section 49 CPA Notice & Checkout Hardening (2026-09-27)
- **Checkout Modal Hardening & Terms Gate (`index.html`)**:
  - Removed outdated `#enterprise-branding-note` disclaimer banner above submit button to streamline the checkout conversion funnel.
  - Implemented mandatory **Section 49 CPA Statutory Notice** highlighting Clauses 4, 5, 6, 7, and 9 under Consumer Protection Act 68 of 2008 and OHSA 85 of 1993 statutory liability disclaimers.
  - Added required interactive checkbox `#checkout-terms-agree` directly linking to `docs/MASTER TERMS OF SERVICE & STATUTORY OHSA LIABILITY WAIVER.pdf`, with front-end validation gating checkout progression.
  - Modernized checkout security footnote to a unified SSL / PCI-DSS compliance badge.
- **In-App Plan Upgrade Terms Gate (`profile-modal.html`, `js/profile-engine.js`)**:
  - Injected Section 49 CPA Statutory Notice and mandatory checkbox `#upgrade-terms-agree` into `#vaultUpgradeReviewModal`.
  - Added programmatic validation inside `executeVaultPaystackUpgrade()` in `js/profile-engine.js` preventing unconsented upgrades.
- **Statutory Audit Packs & Schedule Downloads (`profile-modal.html`, `records.html`)**:
  - Added dedicated Statutory Compliance & Audit Schedules card grid in `profile-modal.html` under the Organization tab with instant downloads for Master Terms & OHSA Liability Waiver, POPIA Section 21 Operator Agreement / DPA, and Statutory Risk Assessment Template Notice & Appointee Schedule.
  - Added direct audit pack action button in `records.html` header providing agricultural managers immediate access to the Section 21 DPA for SIZA and GlobalG.A.P. audits.
- **Digital Sign-off Statutory Declarations & Legal PDF Footers (`module.html`, `risk-assessments.html`, `records.html`)**:
  - Embedded mandatory ECTA Section 13 Supervisor / Appointee Declaration checkboxes in individual/group training modals (`module.html`) and risk assessment review registers (`risk-assessments.html`).
  - Hardened dynamic button states during immutable record generation (`DIGITALLY SIGNING & LOGGING IMMUTABLE RECORD...`).
  - Strengthened jsPDF exported disclaimers across training certificates and Baseline Risk Assessments to explicitly confirm procedural benchmark nature and affirm on-site physical verification by registered Section 16(2) appointees.

### Unified Induction Architecture, Schema Sync & Legal Asset Reorganization (2026-10-02)
- **Architectural Specification Baseline (`docs/architecture/specs/UNIFIED_INDUCTION_AND_ROSTER_SPEC.md`)**:
  - Authored comprehensive specification eliminating manual worker canvas signature repeaters in favor of a Single Supervisor Statutory Gate under ECTA Section 13 and OHSA Section 8(2)(e).
  - Designed multi-tenant `public.company_employees` table with unique constraint on `(company_id, employee_number)` and RLS policies.
  - Specified zero-build client-side CSV parser with header aliasing (`HEADER_ALIASES`) and atomic `sync_company_roster` RPC supporting seasonal soft-deactivation (`is_active = false`).
  - Specified atomic `log_induction_session` RPC reducing batch network payloads by ~98.6% and enforcing statutory batch credibility caps (recommendation: 50, hard ceiling: 80).
  - Resolved 5-year statutory retention rules across OHSA, SIZA Social Standard v8, GlobalG.A.P. IFA v6, and POPIA §14(1)(a), establishing an immutable frozen snapshot model on `training_records` with `ON DELETE SET NULL`.
  - Formulated 4-stage rollout plan: (1) Supabase Migrations & RPCs, (2) HR Roster Management UI, (3) Unified Induction Drawer, (4) Compliance & Renewal Reporting.
- **Legal Asset Directory Reorganization & Link Verification**:
  - Consolidated all 7 statutory PDFs from root `docs/` into organized subfolder [`docs/legal/`](file:///home/luca/dev/the-vault-web/docs/legal).
  - Updated and audited every static hyperlink and download attribute across `index.html`, `partner-portal.html`, `profile-modal.html`, `records.html`, and `systems.html`, resolving path and filename discrepancies.
- **Direct Live Schema Sync Tooling (`scripts/sync_schema.sh`)**:
  - Upgraded `./scripts/sync_schema.sh` to leverage direct `pg_dump` via `DATABASE_URL` with automated secret sanitization (`x-webhook-secret`), formatting `.ai/SUPABASE_SCHEMA.md` into clean DDL.
- **Architect Persona Strict Operating Directives (`.agents/agents/architect/agent.md`)**:
  - Re-anchored architect agent as an advisory, read-only system design persona requiring formal ADR authoring in `docs/architecture/decisions/`.

### Version 3 (The Vault Hub) Architectural Scoping & Blueprint Refinement (2026-10-06 / 2026-10-07)
- **Master Blueprint Specification ([`docs/architecture/specs/THE_VAULT_V3_HUB_SPEC.md`](file:///home/luca/dev/the-vault-web/docs/architecture/specs/THE_VAULT_V3_HUB_SPEC.md))**:
  - Authored and refined comprehensive architectural blueprint following the enterprise endorsement and strategy session with the Lona Group.
  - **Video Catalog UI Scope Adjustment**: Officially cancelled the horizontal "Netflix-style" carousel on `vault.html` in favor of retaining the clean, high-density categorical responsive grid (`grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-5`) to prevent hiding compliance modules in low-card crop categories and streamline auditor verification.
  - **Dynamic Multilingual Audio Stream Switcher**: Retained and detailed Vimeo Player SDK `loadVideo(newVimeoId)` hot-swapping on `module.html`, preserving exact playback timestamp and play/pause state across English, isiZulu, Afrikaans, and isiXhosa.
  - **Synchronous Anti-FOUC Layout Architecture (`/js/modules/layout.js`)**: Retained baseline structural container tags (`<header id="app-header">`, `<aside id="app-sidebar">`) in static HTML with basic Tailwind dimensions (`h-[72px]`, `w-64`) and background colors, ensuring zero CLS while `LayoutEngine.mount()` synchronously normalizes routes (`getActiveRoute()`) and populates navigation links.
  - **Dynamic Company Stamp Engine (Aspect-Ratio Preservation)**: Replaced fixed square stamp embedding in `records.html` and `module.html` jsPDF generators with an aspect-ratio calculation algorithm constrained within a `30mm x 25mm` bounding box, preventing distortion of oval farm seals and rectangular corporate marks.
  - **Farm Roster Specification (`public.company_employees`)**: Confirmed complete DDL schema and strict multi-tenant Row Level Security policies keyed to `get_my_company_id()`, guaranteeing cryptographic tenant isolation between independent farming operations under POPIA Section 19.
  - **Statutory Incident Reporting Module (`incidents.html`)**: Established dedicated root view for OHSA Section 24 and General Administrative Regulations 9 (GAR 9) compliance, featuring worker roster lookup, 7-day DoL mandatory reporting flag, supervisor signature canvas, and dual jsPDF exports (formal DoL Annexure 1 PDF and SIZA/GlobalG.A.P. Landscape A4 Incident Register).
  - **Database Hardening & Bloat Cleanup**: Scheduled deprecation of orphaned table `sandbox_jsonb_backup`, cleanup of redundant denormalized `company_name` columns in `videos` and `sops`, and deployment of server-side catalog/stream redaction RPCs (`get_vault_catalog()`, `get_module_stream()`).

### Version 3 (The Vault Hub) Phase 1 Implementation — Foundation, Hardening & Layout (2026-10-08)
- **Backend Hardening & Catalog Redaction Migration (`supabase/migrations/20261008000000_v3_phase1_baseline.sql`)**:
  - **Zero-Downtime Safe Cleanup**: Executed safe drop of confirmed orphaned snapshot table `public.sandbox_jsonb_backup` (zero code references, zero foreign keys, zero RLS). Documented explicit deprecation comments for denormalized legacy columns `videos.company_name`, `sops.company_name`, and `training_records.signature_url` without schema-dropping live dependencies.
  - **Multi-Tenant RLS Policy**: Added missing tenant `SELECT` policy on `public.crop_pack_addon_purchases` constrained to `company_id = public.get_my_company_id()`.
  - **Authoritative Catalog Redaction RPC (`public.get_vault_catalog()`)**: Implemented `SECURITY DEFINER` catalog function per Section 2.1 of `THE_VAULT_V3_HUB_SPEC.md`. Evaluates company tier and crop entitlements, sets `is_locked`, redacts sensitive Vimeo IDs to `'locked'` and empties questions for unentitled packs, while exposing watermarked teaser thumbnails and keeping core universal safety modules unlocked.
  - **Authoritative Stream Resolution RPC (`public.get_module_stream(p_video_id text)`)**: Implemented stream gatekeeper function resolving caller company entitlement and returning the true Vimeo ID, raising exception `P0001: Access denied` if unentitled or locked.
  - **Statutory 5-Year OHSA Retention Guard**: Revoked raw `DELETE` permissions on `public.training_records` from `public` and `authenticated` roles to satisfy statutory compliance under OHSA §8(2)(e) and audit retention guidelines. Deployed `public.archive_training_record(p_record_id uuid)` restricted to `master admin`.
- **Synchronous Master Layout Engine (`/js/modules/layout.js`)**:
  - Implemented zero-build native ES6 `LayoutEngine` per Section 1.2 with `getActiveRoute()`, `renderSidebar(activeRoute)`, `renderHeader()`, and `mount()`.
  - Added clean route normalization (`.replace(/\.html$/, '').toLowerCase()`), ensuring `/records` and `/records.html` both seamlessly highlight active navigation tabs, and mapped child views (`module`) to parent navigation items (`vault`).
  - Implemented responsive mobile drawer toggle, live tenant indicator (`#header-tenant-indicator`), company tier pill (`#topbar-company-name`, `#topbar-tier-tag`), active subsidy dropdown container (`#topbar-sponsor-pill-container`), notifications, and user avatar anchors.
  - Sets `document.body.dataset.layoutMounted = 'true'` and dispatches custom event `vault:layout-mounted`.
- **Zero-FOUC Baseline Containers Refactor**:
  - Replaced hundreds of lines of duplicate static header and sidebar markup across all authenticated views (`vault.html`, `records.html`, `sop.html`, `risk-assessments.html`, `support.html`, and `module.html`) with baseline structural tags (`<header id="app-header">`, `<div id="sidebar-backdrop">`, `<aside id="app-sidebar">`).
  - Synchronously invokes `LayoutEngine.mount()` prior to `main.js` and `profile-engine.js`, eliminating layout shifts and race conditions during profile hydration.
  - Updated `js/main.js` to target `#app-sidebar` and normalize clean routes during active button evaluation.

### Version 3 (The Vault Hub) Phase 2 Implementation — Video Hub & Multilingual Audio Streams (2026-10-08)
- **Database Migration: Multilingual Streams (`supabase/migrations/20261008010000_v3_phase2_streams.sql`)**:
  - **Non-Destructive DDL**: Added `streams` (`jsonb DEFAULT '{}'::jsonb`) column to `public.videos` table.
  - **Multilingual Audio Seeding**: Seeded canonical core training video `1187071628` ("General Farm Employees") and crop pack module `1229871127` ("Citrus Harvesting Safety") with structured multi-track audio streams for English (`en`), isiZulu (`zu`), and Afrikaans (`af`).
  - **Authoritative Catalog Redaction RPC Upgrade**: Updated `get_vault_catalog()` to include `streams` (redacted to `{}` if locked, delivered if unlocked) and `language`.
  - **Stream Resolution RPC Upgrade**: Updated `get_module_stream(p_video_id text)` to evaluate tenant access before delivering full stream maps (`video.streams`), auto-defaulting legacy un-migrated modules to English.
- **Authoritative Catalog Integration on `vault.html`**:
  - Replaced direct client queries on `videos` table in both `fetchVideoLibraryMap()` and `fetchAndRenderVault()` with authoritative `window.dbClient.rpc('get_vault_catalog')`.
  - Fully decoupled catalog presentation from client-side gating logic. Cleanly renders unlocked modules, watermarked teaser thumbnails for locked crop packs (`handleCropPackLockClick`) and basic tier modules (`handleLockedModuleClick`), and partner co-branded thumbnails (`partner_thumbnails`).
- **Security Stream Gate & Hot-Swapper on `module.html`**:
  - **Authoritative Security Gate**: Embedded `window.dbClient.rpc('get_module_stream', { p_video_id: videoId })` on initial module load. Gracefully catches unauthorized access exceptions (`P0001`) and displays a locked restriction banner with direct navigation back to `vault.html`.
  - **Accessible Language Switcher**: Added `#audioStreamSwitcherContainer` and dynamically renders language pills (`.language-stream-btn`) when a module has multiple language streams.
  - **Zero-Flicker Audio Hot-Swapper (`switchAudioStream(targetLang)`)**: Seamlessly hot-swaps video stream using Vimeo SDK `player.loadVideo(newVimeoId)` while preserving playback timestamp (`getCurrentTime()`) and paused state (`getPaused()`) without page reloads.
  - **Statutory Audit Trail Integrity**: Watch progress (`user_video_progress`) and verified training records (`training_records`) strictly reference `window.canonicalVideoId`, keeping compliance records unified across all language options.

### Version 3 (The Vault Hub) Phase 3 Implementation — Field Workspace & Roster Engine (2026-10-08)
- **Database Migration: Roster Engine & Atomic Stored Procedures (`supabase/migrations/20261008020000_v3_phase3_roster.sql`)**:
  - **`public.company_employees` Table**: Created multi-tenant employee roster table with UUID primary key, `company_id` foreign key (`ON DELETE CASCADE`), `UNIQUE(company_id, employee_number)`, and indexes (`idx_company_employees_company_active`, `idx_company_employees_company_team`, `idx_company_employees_search`).
  - **Tenant RLS & Statutory Deletion Guard**: Implemented strict tenant `SELECT` policy (`company_id = get_my_company_id()`), mutation policy restricted to safety management roles (`master admin`, `admin`, `manager`, `safety officer`), and revoked raw `DELETE` from `public` and `authenticated` roles to enforce soft-deactivation (`is_active = false`).
  - **Non-Destructive Link on `training_records`**: Added `employee_id uuid REFERENCES public.company_employees(id) ON DELETE SET NULL` with btree index and index on `batch_session_id`, while preserving immutable historical columns (`employee_name`, `employee_number`, `gender`, `supervisor_name`) as frozen snapshots.
  - **Atomic Roster Synchronization RPC (`public.sync_company_roster`)**: Stored procedure supporting "Upsert & Keep" vs. "Seasonal Replace & Sync" (soft-deactivating departed seasonal workers without touching historical training certificates).
  - **Atomic Induction Intake RPC (`public.log_induction_session`)**: High-throughput stored procedure committing single and batch induction sessions with ECTA §13 supervisor attestation in a single ACID transaction, enforcing the statutory 80-worker maximum cap.
  - **Live Schema Synchronization**: Synchronized live database schema via `./scripts/sync_schema.sh` into [`.ai/SUPABASE_SCHEMA.md`](file:///home/luca/dev/the-vault-web/.ai/SUPABASE_SCHEMA.md).
- **Farm Employee Roster Management View (`records.html`)**:
  - **Segmented View Navigation**: Deployed toggle control switching between `[ 📋 Training Records Register ]` and `[ 👥 Farm Employee Roster ]`.
  - **Roster Overview & Metrics**: Real-time stats pills showing Active Crew, Seasonal Inactive Crew, and Total on File, alongside quick-add employee modal (`#addEmployeeModal`).
  - **Search & Dynamic Filters**: Live search across clock number, full name, ID/passport, and orchard; dynamic team/orchard dropdown; active/inactive filter.
  - **High-Density Crew Table**: Displays Clock #, Worker Full Name, ID/Passport, Gender, Team/Orchard, Status badge, Last Induction Date (cross-referenced from completed records), and inline Activate/Deactivate status toggle button.
  - **Zero-Build RFC 4180 CSV Ingestion Pipeline**: Browser-native `FileReader` parser supporting `,`, `;`, and `\t` delimiters with `HEADER_ALIASES` normalizer across South African payroll systems (Sage VIP, Pastel, AgriCol, PaySoft).
  - **Pre-Commit Modal & Strategy Radios**: Shows detected row count, column mapping badges, 5-row preview, and selection between "Upsert & Keep" and "Seasonal Replace & Sync" before executing `sync_company_roster`.
- **Unified Induction Intake Drawer & Supervisor Attestation Gate (`module.html`)**:
  - **Streamlined Workflow**: Removed artificial Individual vs. Group mode toggle and eliminated repetitive 50-worker signature pad loops, dropping network batch payloads by ~98.6%.
  - **Active Roster Trainee Checklist**: Loads active farm personnel (`is_active = true`), supporting live search, orchard filtering, "Select All Filtered", and individual checkboxes.
  - **Statutory Guardrails & Advisories**: Real-time counter badge resolving Individual vs. Batch mode, statutory advisory warning for sessions > 50 workers, and hard validation block exceeding 80 workers.
  - **Quick-Add Unlisted Worker**: Expandable inline form for guest or unlisted seasonal workers that immediately incorporates them into the active induction session.
  - **ECTA §13 Statutory Supervisor Gate**: Supervising officer declaration checkbox and digital signature pad committing through `log_induction_session` RPC.
  - **Attendance Register PDF Fallback**: Enhanced landscape register generator in `records.html` to render `[Attested (ECTA §13)]` when individual trainee signatures are omitted.

### Version 3 (The Vault Hub) Phase 4 Implementation — Statutory Incident Register & Stamp Engine (2026-10-08)
- **Database Migration: Incident Register & Company Stamp (`supabase/migrations/20261008030000_v3_phase4_incidents_stamp.sql`)**:
  - **Company Stamp DDL**: Added `company_stamp_url text` column to `public.companies` table in a non-destructive manner.
  - **`public.incident_reports` Table**: Created statutory incident register table conforming strictly to Section 6.2 of `THE_VAULT_V3_HUB_SPEC.md` (`id`, `company_id`, `incident_number`, `incident_date`, `incident_time`, `reported_at`, `location_or_orchard`, `employee_id`, `injured_person_name`, `injured_person_id_number`, `injured_person_role`, `gender`, `incident_severity`, `nature_of_injury`, `body_part`, `equipment_chemical_involved`, `incident_description`, `root_cause_analysis`, `corrective_preventative_actions`, `action_assigned_to`, `action_target_date`, `action_completed_date`, `is_section_24_statutory`, `section_24_reported_at`, `investigated_by_name`, `investigated_by_role`, `investigator_signature`, `status`, `attachments`, `created_at`, `updated_at`).
  - **Multi-Tenant Indexes & RLS**: Created performance indexes `idx_incidents_company`, `idx_incidents_statutory`, and `idx_incidents_employee`. Enabled RLS with policy `"Tenants can manage their own incident reports"` enforcing `company_id = public.get_my_company_id()`.
  - **Live Schema Synchronization**: Verified migration on live production Supabase database and updated [`.ai/SUPABASE_SCHEMA.md`](file:///home/luca/dev/the-vault-web/.ai/SUPABASE_SCHEMA.md) via `sync_schema.sh`.
- **Dedicated Statutory Incident Reporting View (`incidents.html`)**:
  - **Zero-FOUC Layout Integration**: Deployed root view with semantic baseline layout tags (`<header id="app-header">`, `<div id="sidebar-backdrop">`, `<aside id="app-sidebar">`) mounted via `LayoutEngine.mount()`.
  - **Summary KPI Strip**: Deployed 4-card metric strip calculating Total Incidents YTD, Near Misses, Lost-Time Injuries (LTI &gt; 3 days), and Safety Streak (Days Since Last Incident).
  - **Statutory Section 24 Alert Banner**: Real-time warning alert displayed when active incidents trigger South African OHSA Section 24 and General Administrative Regulation 9 mandatory 7-day notification to the Department of Employment and Labour.
  - **Incident Capture Modal (`#incidentModal`)**: Multi-section form capturing circumstances, active roster worker lookup and autocompletion (`company_employees` where `is_active = true`), severity selection with automatic Section 24 trigger, CAPA assignment, and HTML5 investigator digital signature canvas.
  - **Dual jsPDF Export Engines**:
    1. *DoL Annexure 1 Investigation PDF (Portrait A4)*: Prescribed statutory format under General Administrative Regulations 9 (GAR 9) featuring Sections A through H, legal declaration, embedded investigator signature, and verified company stamp.
    2. *SIZA / GlobalG.A.P. Incident Register (Landscape A4)*: High-density multi-row tabular audit ledger for farm certification inspections with date/time, orchard, injury, root cause, corrective action, responsible person, and official stamp watermark.
- **Official Estate Stamp Upload UI & Logic (`profile-modal.html` & `js/profile-engine.js`)**:
  - **Organization Tab Integration**: Added official estate stamp dropzone, preview container (`#company-stamp-preview`), and upload/remove triggers in `profile-modal.html`.
  - **Storage & Mutation Handlers (`js/profile-engine.js`)**: Implemented `handleCompanyStampUpload(event)` validating file type (PNG/JPG) and size (&le;1.5MB), uploading to Supabase Storage `avatars` bucket at `company-stamps/${companyId}/stamp_${Date.now()}.${ext}`, updating `companies.company_stamp_url`, and refreshing the UI. Added `removeCompanyStamp()` resetting the seal to null.
  - **Administrative Access Control**: Enforced Primary Admin permissions (`master admin`, `admin`) for stamp modifications, locking controls for non-admin managers.
- **Dynamic Certificate Stamp Engine with Aspect-Ratio Preservation (`records.html` & `incidents.html`)**:
  - **Proportional Scaling Algorithm (`renderCertificateStamp`)**: Implemented Section 7.3 algorithm dynamically calculating natural image aspect ratio versus a `30mm x 25mm` bounding box, centering the seal and eliminating distortion for oval farm seals and rectangular marks.
  - **Vector Seal Fallback**: Programmatic dual-ring vector compliance seal (`THE VAULT COMPLIANCE — OFFICIALLY VERIFIED — OHSA ACT 85 OF 1993`) rendered cleanly when no user stamp is uploaded.
  - **Certificate Engine Integration**: Refactored both Individual Training Certificate and Group Induction Sign-off Register in `records.html`, as well as DoL Annexure 1 and SIZA audit registers in `incidents.html` to invoke `renderCertificateStamp`.
- **365-Day Statutory Refresher Tracking (`records.html`)**:
  - **Compliance Status Engine (`calculateComplianceStatus`)**: Implemented Section 5.2 contract calculating days remaining out of 365 days under OHSA GSR 2(1) (Compliant &ge; 30d [emerald], Expiring Soon &le; 30d [amber], Overdue &lt; 0d [red], Untrained [red/gray]).
  - **UI Integration**: Added compliance status badges to Employee Directory cards and Farm Employee Roster table rows.
  - **Active Roster Isolation**: Updated roster metrics strip and added compliance status filter options (`Compliant`, `Expiring Soon`, `Overdue / Untrained`), calculating metrics strictly against active farm workers (`is_active = true`).

### Version 3 (The Vault Hub) UI/UX & Gating Remediation Pass (2026-10-12)
- **Database Enterprise Catalog Gating Remediation (`supabase/migrations/20261008040000_fix_enterprise_catalog_gating.sql`)**:
  - Resolved entitlement fallthrough bug in `get_vault_catalog()` and `get_module_stream()` where accounts on `tier = 'enterprise'` saw standard crop packs (Citrus, Macadamia, Banana) locked due to `unlock_all_crops` defaulting to `false`.
  - Added explicit enterprise evaluation condition (`lower(coalesce(v_tier, '')) = 'enterprise' => is_locked = false`), granting full access to standard agricultural crop packs.
  - Hardened private estate library rules in `get_module_stream()` to deny cross-tenant streaming of proprietary estate footage.
  - Added sub-tag keyword entitlement matching for crop names in `sponsored_crop_packs` and `purchased_crop_packs`.
  - Applied migration to remote database and synchronized schema into [`.ai/SUPABASE_SCHEMA.md`](file:///home/luca/dev/the-vault-web/.ai/SUPABASE_SCHEMA.md) via `./scripts/sync_schema.sh`.
- **Top Block Scroll Padding Remediation (Fixed Header Compensation)**:
  - Compensated for `#app-header` fixed 72px height across all 7 views (`vault.html`, `records.html`, `incidents.html`, `sop.html`, `risk-assessments.html`, `support.html`, and `module.html`) using standardized `pt-[72px]` on `<main id="mainContent">`.
  - Decoupled content padding onto responsive inner wrappers (`p-4 sm:p-8` / `p-4 sm:p-10`), guaranteeing full scroll-to-top visibility of page titles, search inputs, breadcrumbs, and metrics without clipping behind the fixed header.
- **Centralized Master Header Component Polish (`js/modules/layout.js` & `js/profile-engine.js`)**:
  - Restored authentic Version 2 brand mark: SVG vault mark in rounded primary container paired with `font-serif font-bold text-slate-900` typography (`text-xl sm:text-2xl lg:text-[1.75rem]`).
  - Restored all RHS interactive controls: live company name and tier badge pill (`#topbar-company-name`, `#topbar-tier-tag`), partner subsidy dropdown container (`#topbar-sponsor-pill-container`), notifications bell with unread dot indicator, and user profile avatar trigger (`#userAvatar`, `#userName`, and click handler calling `openProfileModal()`).
  - Fixed profile engine hydration in `js/profile-engine.js` to synchronously bind the user's name to the visible `#userName` header element.
- **Estate Stamp Card UI & jsPDF Placement Hardening (`profile-modal.html`, `incidents.html`, `records.html`)**:
  - Polished Estate Stamp card in `profile-modal.html` under Organization tab with 96px dashed preview square, descriptive statutory guidelines, and 44px mobile-first action buttons (`#upload-stamp-btn`, `#remove-stamp-btn`).
  - Hardened jsPDF coordinates in `incidents.html`:
    - Added page boundary guard (`currentY > pageHeight - margin - 45`) before Section G in DoL Annexure 1 to prevent signature/stamp collision with footer.
    - Adjusted pagination ceiling (`startY > pageHeight - 45`) and anchored the stamp neatly (`stampY = Math.min(Math.max(startY + 4, pageHeight - margin - 32), pageHeight - margin - 28)`) with an official verified label in SIZA Incident Register, eliminating row collisions and disclaimer overlap.
    - Verified `records.html` individual certificate and group induction sign-off blocks maintain clean coordinate margins without overlap.
- **Incident Register Heading Alignment & Application Footer (`incidents.html`)**:
  - Aligned page heading typography to standard `font-serif font-bold text-2xl text-slate-900` with muted statutory sub-caption.
  - Injected standard application footer with Simple Solutions branding, quick links, statutory 5-year OHSA §24 and POPIA §14(1)(a) audit retention notice, and copyright block.
- **Video Module Language Switcher Dropdown (`module.html`)**:
  - Implemented styled `<select id="moduleLanguageSelect">` dropdown in the video sub-header / controls bar below the Vimeo player.
  - Populated options dynamically from `video.streams` (e.g. English, isiZulu, Afrikaans).
  - Handles single-language videos by displaying "English" as selected and disabling the dropdown with an informative helper note.
  - Wired `onchange` to `switchAudioStream(selectedLang)` with Vimeo Player SDK hot-swapping via `loadVideo()`, preserving current timestamp (`getCurrentTime()`) and active play/pause state without page reload, keeping watch progress unified on `window.canonicalVideoId`.

### Version 3 (The Vault Hub) Records View Harmonization & Directory Refactor (2026-10-12)
- **Page-Level Layout Harmonization (`records.html`)**:
  - **Outer Frame Elimination**: Stripped the enclosing boxed card wrapper (`border border-slate-200 bg-white rounded-2xl p-6` / `max-w-5xl mx-auto w-full p-4 sm:p-8 bg-white rounded-2xl border border-slate-200 shadow-sm`), letting content sit directly on the `#f8fafc` canvas background inside `<div class="max-w-6xl mx-auto w-full">`, mirroring `risk-assessments.html`.
  - **Permanent Static Title & Subtitle**: Set the main page title permanently to `Training Records` with subtext (`Manage employee compliance, verified induction registers, and farm workforce rosters.`), removing tab title swapping.
  - **Dynamic Top-Right Action Controls**: Placed tab-specific actions in the top-right of the title block:
    - *Register Tab*: `[ ⬇ Export Audit Pack (DPA) ]`, `#pdf-quota-pill`, and `Live HR Sync` pill.
    - *Roster Tab*: `[ ⬆ Import Roster (CSV) ]` and `[ + Add Worker ]`.
  - **Segmented Sub-View Switcher Row**: Positioned the tab switcher (`[ 📋 Training Records Register ]` vs `[ 👥 Farm Employee Roster ]`) on its own full-width row (`border-b border-slate-200 pb-5 mb-6`) below the title block with dynamic sub-caption description (`#activeViewDescription`).
  - **Full-Width Search & Filter Bar**: Positioned clean horizontal search inputs and filter dropdowns directly below the switcher row across both tabs. Fixed roster search input ID collision (`#rosterSearchInput`).
- **Collapsible Employee Directory Table Refactor (`records.html`)**:
  - **Column Harmonization**: Refactored the employee card accordion table columns to: `MODULE TITLE` | `SUPERVISOR` | `COMPLETION DATE` | `RENEWAL DUE` | `STATUS` | `ACTIONS`.
  - **Removed Redundant Columns**: Removed the `TRAINING TYPE` column and pill badges, and removed individual certificate downloads and the `CERTIFICATE` column, standardizing compliance audits strictly on Group Induction & Audit Register exports.
  - **Statutory 365-Day Renewal & Module Status Engine**:
    - Calculated `RENEWAL DUE` as exactly 365 days after `completed_at` (OHSA GSR 2(1) annual induction cycle).
    - Rendered granular module `STATUS` badges: `Compliant` (>30d remaining, emerald), `Expiring Soon` (<=30d remaining, amber), and `Overdue` (<0d remaining, red).
  - **Overall Worker Compliance Rollup (`calculateWorkerCompliance`)**:
    - Evaluates all active modules for a worker:
      - If ANY module is overdue -> `Overdue` (red).
      - Else if ANY module is expiring within 30 days -> `Expiring Soon` (amber).
      - Else -> `Compliant` (emerald).
  - **Retraining Module Replacement Engine**:
    - Deduplicates modules per worker by `module_title` (case-insensitive normalized), keeping ONLY the latest completed record per module. Refresher training cleanly supersedes historical runs in active registers.
  - **Record & Worker Deletion / Dismissal Handling**:
    - *Delete Individual Module Record*: Added trash button in `ACTIONS` column with confirmation prompt. Invokes `archive_training_record` RPC (with fallback to direct status update or delete), immediately pruning local state and updating compliance counts without full page refresh.
    - *Worker Deactivation / Dismissal*: Added `[ Remove / Deactivate Worker ]` button inside the expanded worker card header. Confirms action, updates `company_employees.is_active = false`, updates roster statistics, and immediately reflects status across directory and roster views.

### Version 3 (The Vault Hub) Records & Incidents UI Polish (2026-10-13)
- **Training Records Metric Strip & Filter Refinement (`records.html`)**:
  - **Compliance Metric Strip Relocation**: Moved the detailed compliance summary pill (`● 0 Active (0 Valid • 0 Expiring • 0 Overdue/Untrained)`) exclusively to the `[ 📋 Training Records Register ]` view positioned directly above the search & filter bar.
  - **Clean Roster Headcount Strip**: Replaced the detailed status pill on the `[ 👥 Employee Roster ]` view with a concise headcount strip: `● 0 Active Crew  |  ● 0 Inactive  |  0 Total on File`.
  - **Removal of Team/Orchard Filter Dropdown**: Removed the `#rosterTeamFilter` (`All Teams / Orchards`) dropdown from the Roster view, retaining strictly the text search input (`#rosterSearchInput`) and active status filter (`#rosterStatusFilter`). Verified no team filter dropdown remains on either view.
  - **Dynamic State Synchronization**: Hooked `updateRosterStatsAndFilters()` into training records resolution so active compliance metrics automatically refresh upon data loading across both tabs.
- **Incident Register Subtext & Modal Verification (`incidents.html`)**:
  - **Header Subtext Caption**: Verified and confirmed subtext caption under the main `Incident Register` heading: `"Log, investigate, and track farm workplace incidents, near misses, and statutory safety records."`.
  - **Modal Investigation & CAPA Verification**:
    - Confirmed Section 4: Narrative Description (`#formDescription`) & Root Cause Analysis (`#formRootCause`).
    - Confirmed Section 5: Corrective & Preventative Actions (`#formCapa`) with Assigned Person (`#formActionAssignedTo`) and Target Date (`#formActionTargetDate`).
    - Confirmed Section 6: Section 16(2) / Safety Officer Signature Canvas (`#signatureCanvas`) and Investigator Name (`#formInvestigatedBy`) & Role (`#formInvestigatorRole`).
- **Roster Table Cleanup & Permanent Worker Deletion (`records.html`)**:
  - **Removed "LAST INDUCTION" Column**: Removed `LAST INDUCTION` header (`<th>`) and table data cells (`<td>`), leaving the table columns strictly: `CLOCK #` | `WORKER NAME` | `ID / PASSPORT` | `GENDER` | `TEAM / ORCHARD` | `STATUS` | `ACTION`.
  - **Audit-Safe "Delete Worker" Action (`deleteEmployee`)**: Added permanent `[ Delete ]` button with trash icon alongside `[ Deactivate ]`.
  - **Audit Retention Protection & Policy Fallback**: If worker has existing training records in `training_records`, deactivates worker (`is_active = false`) to preserve statutory compliance audit trails. If zero training records exist, executes hard deletion from `public.company_employees`. If a database-level security policy rejects hard deletion (e.g. `REVOKE DELETE`), gracefully and defensively falls back to soft-deactivation (`is_active = false`), alerting the user and preserving state without throwing an unhandled exception.
  - **Instant State Refresh**: Refreshes table and updates headcount counters (`● X Active Crew | ● Y Inactive | Z Total on File`) in place without page reload.
- **Bilingual Stream Dropdown Alignment & Hot-Swap (`module.html`)**:
  - **Compound Stream Labels**: Configured `<select id="moduleLanguageSelect">` to map compound language labels from `video.streams` (e.g. `"English & Zulu"` and `"English & Afrikaans"`).
  - **Default Video ID Stream Selection**: Automatically selects the stream matching the active query video ID (`video.streams[key].vimeo_id === videoId`).
  - **Single Stream Fallback**: When `video.streams` has &le;1 option or is empty, displays the video's default `language` (e.g., "English & Zulu") and keeps the selector disabled.
  - **Timestamp-Preserved Hot-Swap**: Seamlessly switches Vimeo streams via `player.loadVideo()`, re-seeks to preserved playback position, restores play state, and guarantees progress tracking and signatures persist under `window.canonicalVideoId`.
- **Remote Database Schema Synchronization & Manifest Update (`.ai/SUPABASE_SCHEMA.md` & `PROJECT_BRAIN.md`)**:
  - Ran `./scripts/sync_schema.sh` direct `pg_dump` against production Supabase PostgreSQL instance.
  - Formally captured live database schema manifest changes including newly provisioned `company_employees` (roster management) and `incident_reports` (OHSA §24 and SIZA incident tracking) tables.
  - Documented new columns `companies.company_stamp_url`, `training_records.employee_id`, and updated RLS table coverage (20 total tables).
- **Trainee Roster Checklist & Streamlined Guest Worker Experience (`module.html`)**:
  - **Resolved "0 Active Crew" Root Cause**: Identified and fixed missing `escapeHtml` and `waitForDbClient` helper definitions in `module.html` that previously caused silent `ReferenceError` crashes during roster fetch and checklist rendering.
  - **Search-Driven Roster Display & Sorting by Clock #**: Refactored `#rosterChecklistContainer` to only display worker names once the supervisor begins typing a name or employee number. If the search query is empty, displays a search prompt (or exclusively the currently selected trainees for clean review). Filtered results are naturally sorted by `employee_number`.
  - **Checklist Height & Responsive Rendering**: Ensured `#rosterChecklistContainer` has an explicit non-zero height (`min-h-[140px] max-h-60 overflow-y-auto block`) and wired `#activeCrewCount` to reflect actual roster counts.
  - **Pinned Guest Worker Trigger & Layout**: Pinned the `[ + Quick-Add Unlisted Guest Worker ]` button directly underneath the main filtered roster block, rendering newly created guest worker rows below the button so it remains anchored without shifting downward.
  - **Instant Worker Row Removal**: Each guest worker row includes an instant remove button (`[ − ]` / trash icon) that updates trainee selection totals dynamically and collapses the section cleanly when all rows are removed.
- **Pre-Deployment Security Audit Pass — GO Verdict (2026-10-13)**:
  - **Multi-Tenant RLS & Cryptographic Isolation**: Audited all 20 public database tables. Confirmed all tenant tables enforce `rls_enabled = true` with strict filtering via `company_id = public.get_my_company_id()`. Revocation of raw `DELETE` permissions on `training_records` verified under OHSA §8(2)(e) and SIZA social audit standards.
  - **Server-Side Entitlement & Gating**: Confirmed catalog and streaming entitlements are authoritatively validated server-side by `SECURITY DEFINER` RPCs (`get_vault_catalog()`, `get_module_stream()`), completely preventing client-side bypass of crop-pack paywalls or private estate libraries.
  - **OWASP Client-Side Security**: Verified DOM sanitization via `escapeHtml()` across all user-controlled text inputs, zero occurrences of dangerous evaluation (`eval()`, `Function()`, `innerHTML` on unsanitized payloads), secure `localStorage` usage, and zero exposure of service role keys or private secrets in client assets.
  - **Digital Signature & Statutory Integrity**: Verified ECTA §13 compliant dual-signatures, supervisor declarations, Section 16(2) appointee sign-offs, and DPI-aware coordinate mapping without coordinate drift.
  - **Production Deployment Verdict**: Unconditional **GO** for production release.

### Post-Launch Enhancements & Fixes (2026-10-14)
- **Downloadable CSV Roster Template (`records.html`)**:
  - Added dedicated **"Download Sample Template (CSV)"** button inside the `#csvImportModal` drop zone.
  - Generates RFC 4180 compliant CSV (`the_vault_employee_roster_template.csv`) with standard column headers (`Employee Number`, `First Name`, `Last Name`, `ID / Passport`, `Gender`, `Team / Orchard`) and South African agricultural worker sample data.
- **Agricultural Payroll Gender Normalization (`records.html` & Migration `20261014090000_post_launch_fixes.sql`)**:
  - Implemented dual-layer client/server gender normalization via `normalizeGender()` and updated PostgreSQL RPCs `sync_company_roster` and `log_induction_session`.
  - Normalizes common real-world payroll notations including `M`, `Male`, `m`, `Man`, `seun`, `manlik`, `mr`, `mnr`, `boy`, `F`, `Female`, `f`, `Woman`, `WOMAN`, `Vrou`, `vrou`, `vroulik`, `vroue`, `meisie`, `w`, `W`, `girl`, `lady`, `dame`, `ms`, `mrs`, `miss`, `mej`, and whitespace-padded variants.
  - Added title-based heuristic fallback (`Mr`, `Mnr`, `Ms`, `Mrs`, `Miss`, `Mej`) when payroll systems omit the gender column or export honorifics in the first name.
  - Data backfill: Healed all 210 historical rows in `company_employees` and 2 rows in `training_records` where gender previously defaulted to `'Other'`.
- **Video Topic & Module Filter (`records.html`)**:
  - Added `#moduleFilterSelect` dropdown directly to the Training Records Register search bar with categories (`General Safety`, `Machinery & Workshop`, `Citrus Processing`, `Vehicles & Fleet`, `Estate Modules`) and broad category filter shortcuts.
  - Seamlessly filters the directory of training records to show all employees who have completed the selected video module or category, without intrusive popup banners or clutter.
- **Statutory PDF Training Register Restoration & Pagination (`records.html`)**:
  - Restored the `Register (PDF)` export button unconditionally for all recorded training modules across both individual and batch sessions.
  - Enhanced `generateAttendanceRegisterPDF` to look up records by `batch_session_id` and defensively fallback to primary key `id` for single sessions.
  - Added multi-page table pagination (15 trainees per page) so batches of up to 80 trainees generate complete, formatted landscape A4 sign-off registers without row truncation.
  - Backfilled all 10 historical training records with generated `batch_session_id` UUIDs.

- **Training Records Compliance Metrics Pill Refinement (`records.html`)**:
  - Completely removed "Untrained" from the overdue calculation. Active roster workers with zero logged training modules are classified as `'No Records'` with a neutral slate badge (`bg-slate-100 text-slate-600`) and no longer inflate the overdue counter.
  - Refactored `calculateComplianceStatus`, `calculateWorkerCompliance`, and `updateRosterStatsAndFilters` to strictly evaluate actual completed modules against their statutory 365-day renewal cycle:
    - **Valid**: Completed modules with >30 days remaining before renewal.
    - **Expiring**: Completed modules due for annual renewal within 30 days.
    - **Overdue**: Completed modules that have genuinely exceeded their 365-day statutory renewal date (<0 days).
  - Updated summary pill display copy to: `● X Active Workers (A Valid • B Expiring • C Overdue)`.
  - Updated `#rosterStatusFilter` dropdown to decouple `Overdue (>365d)` from `No Records on File`, giving managers targeted visibility into genuine expirations versus unassigned workers.
- **Company Verification Stamp Seal Redesign (`records.html` & `incidents.html`)**:
  - Redesigned the programmatic fallback vector seal in `renderCertificateStamp()` across `records.html` and `incidents.html` into a clean, authentic round estate/corporate rubber verification mark.
  - Stripped all statutory references and legal liability text ("OHSA ACT 85 OF 1993", "THE VAULT COMPLIANCE", "OFFICIALLY VERIFIED").
  - Formatted the vector seal with concentric double outer rings (10.8mm and 9.5mm radii), fitted uppercase organization name along the top arc, clean horizontal divider bars with centered `VERIFIED` text, and dynamic bottom reference (VAT/Registration number, estate location, or `ESTATE RECORD`).
  - Implemented dynamic vertical clearance calculation in the attendance register PDF generator (`generateAttendanceRegisterPDF`), splitting multiline address blocks and centering the seal between the company details and bottom label to eliminate overlapping.
- **Terminology Alignment & UI Consistency (`module.html`)**:
  - Replaced legacy references to "clock number" with standardized "employee number" across trainee search placeholders and guest trainee repeater inputs to align with roster headers and agricultural HR standards.
- **Statutory Attendance Register PDF Uniform Row Typography (`records.html`)**:
  - Resolved typography state leakage in `generateAttendanceRegisterPDF` table drawing loop where secondary attestation styling (`doc.setFont('helvetica', 'italic')`, `doc.setFontSize(6.5)`, `doc.setTextColor(148, 163, 184)`) in the final column of Row 1 persisted into all subsequent rows.
  - Enforced baseline row styling (`doc.setFont('helvetica', 'normal')`, `doc.setFontSize(8.5)`, `doc.setTextColor(15, 23, 42)`) at the start of every row iteration.
  - Explicitly formatted Employee Number as bold dark slate (`helvetica bold`, 8.5pt, `#0f172a`), Worker Name as regular weight dark slate, and Gender as regular weight dark slate across all rows.
  - Isolated secondary italic styling strictly to the unsigned attestation cell (`Attested (ECTA §13)`) and immediately restored the standard 8.5pt dark slate typography before proceeding to subsequent cells or rows.
- **Worker Name De-duplication & Payroll CSV Normalization (`records.html`, `module.html`, `incidents.html`, & Migration `20261014113000_normalize_worker_names.sql`)**:
  - **CSV Parser Normalization (`parseAndNormalizeRosterCsv`)**: Resolved issue where agricultural payroll exports (Sage VIP, Pastel, AgriCol, PaySoft) supply a `Name` column containing titles, initials, and surnames (e.g. `Ms Z BALENI`) alongside a `Surname` column (`BALENI`). Automatically strips trailing surnames from `first_name` while preserving titles and initials. Cleanly supports single-column `Full Name` / `Worker Name` mapping without forcing artificial splits when no separate surname column exists.
  - **Frontend Display De-duplication (`formatWorkerName`)**: Added defensive helper `formatWorkerName(first, last)` across `records.html`, `module.html`, and `incidents.html`. Guarantees duplicated surnames never render on screen, in the trainee completion drawer, in roster tables, in incident pickers, or in official statutory PDF attendance registers.
  - **Database Migration & RPC Hardening**: Applied migration `20261014113000_normalize_worker_names.sql` cleaning up all 210 existing rows in `public.company_employees` where `first_name` ended with `last_name` (e.g. `P031` healed from `Ms Z BALENI BALENI` to `Ms Z BALENI`). Hardened `sync_company_roster` RPC to prevent recurrence on future CSV uploads.
- **Mandatory Template Warning Card & Bulletproof Header Ranking (`records.html`)**:
  - **High-Visibility Warning Card**: Added prominent red warning banner (`#csvTemplateWarningBanner`) directly inside `#csvImportModal` above the upload drop zone with clear instructions that raw payroll exports with custom display names or payroll codes will not import correctly, paired with a prominent red download button.
  - **Bulletproof Header Priority**: Refactored `detectColumnMapping()` with tiered alias matching. Prioritizes dedicated `First Name` / `Voornaam` columns over generic or composite headers (`Display Name`, `Full Name`, `Name`). Prevents payroll exports containing both `Display Name` (e.g. `Mr F MBANGI`) and `First Name` (`FANISILE`) from hijacking the worker's genuine first name.
  - **Clean & Minimal CSV Template**: Updated `downloadSampleRosterCsv()` to generate the exact required 6 columns (`Employee Number`, `First Name`, `Last Name`, `ID / Passport Number`, `Gender`, `Team / Orchard`) with realistic South African farm crew examples.

### Upcoming Priority Tasks
1. **Citrus Processing Pack**: Finalize dedicated SOP documentation and master risk assessment templates for citrus harvesting, packing, and cold-storage operations.
2. **Paystack Bolt-On Automation**: Verify live webhook processing of `charge.success` events for `PLN_8n5qrpeh23evvnu` across production testing farms.
3. **Cloudflare Security Headers**: Configure `_headers` file in Cloudflare Pages to enforce strict Content Security Policy (CSP), HTTP Strict Transport Security (HSTS), and frame options.