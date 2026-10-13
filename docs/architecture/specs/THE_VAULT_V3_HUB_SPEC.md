# The Vault Hub (Version 3) — Architectural Specification & Scoping Blueprint

> **Enterprise Endorsement Target:** Lona Group & South African Commercial Agri-Enterprises  
> **Target Environment:** Cloudflare Pages (Zero-Build Static) & Supabase PostgreSQL / Deno Edge Runtime  
> **Status:** Approved Architectural Blueprint | **Target Release:** Q4 2026 / Q1 2027  
> **Author:** Antigravity Principal Systems Architect

---

## Executive Summary & Strategic Context

Following the enterprise endorsement and commercial expansion with the **Lona Group** (one of Southern Africa's premier integrated citrus, deciduous fruit, and cold-chain supply chain enterprises), **The Vault** platform is evolving from a localized digital induction tool into **The Vault Hub (Version 3)**.

Version 3 consolidates multi-tenant workforce management, statutory compliance registers (OHSA Act 85 of 1993, General Administrative Regulations 9, SIZA Social Standard v8, GlobalG.A.P. IFA v6), multilingual video learning management, and real-time partner supply-chain attribution into an enterprise-grade, zero-build web platform.

Following executive project decisions from our Lona Group strategy session, this specification establishes the technical architecture, data models, security boundaries, and implementation roadmaps for the seven core pillars of The Vault Hub.

```
+----------------------------------------------------------------------------------------------------+
|                                      THE VAULT HUB (V3) ARCHITECTURE                                |
+----------------------------------------------------------------------------------------------------+
|                                                                                                    |
|   +----------------------------------+     +----------------------------------+                    |
|   |   ZERO-BUILD VANILLA ES6 DOM     |     |   MULTILINGUAL VIDEO STREAMING   |                    |
|   |   - Centralized LayoutEngine     |     |   - High-Density Responsive Grid |                    |
|   |   - Synchronous Header/Sidebar   |     |   - Vimeo Hot-Swap Audio Switch  |                    |
|   |   - Route Normalization          |     |   - Multi-Track Canonical IDs    |                    |
|   +----------------------------------+     +----------------------------------+                    |
|                     │                                       │                                      |
|                     ▼                                       ▼                                      |
|   +---------------------------------------------------------------------------+                    |
|   |                         OFFLINE FIELD WORKSPACE                           |                    |
|   |   - IndexedDB Workforce Cache (`company_employees`)                       |                    |
|   |   - Optimistic Batch Induction Queue & Supervisor Sign-off                |                    |
|   |   - Background Reconciliation Worker (Automatic Reconnection Sync)        |                    |
|   +---------------------------------------------------------------------------+                    |
|                     │                                       │                                      |
|                     ▼                                       ▼                                      |
|   +----------------------------------+     +----------------------------------+                    |
|   |    STATUTORY INCIDENT REGISTER   |     |    ENTERPRISE SECURITY & ASSETS  |                    |
|   |   - OHSA Section 24 / DoL Annex 1|     |   - Server-Side Crop Pack Redact |                    |
|   |   - Dedicated `incidents.html`   |     |   - Dynamic Aspect-Ratio Stamp   |                    |
|   |   - Root Cause & Severity Matrix |     |   - Legacy Table / Bloat Cleanup |                    |
|   +----------------------------------+     +----------------------------------+                    |
|                                                                                                    |
+----------------------------------------------------------------------------------------------------+
```

---

## 1. Codebase Architecture & Modularity (Zero-Build Vanilla ES6)

### 1.1 The Multi-Page Problem
Currently, 11 root HTML documents (`index.html`, `vault.html`, `module.html`, `records.html`, `risk-assessments.html`, `sop.html`, `partner-portal.html`, `invite.html`, `support.html`, `systems.html`, `404.html`) repeat roughly 160 lines of static markup per view:
- **Header Topbar**: Brand badges, dynamic tenant indicator, corporate partner sponsor dropdown, notification bell, profile menu trigger, and mobile hamburger.
- **Sidebar Drawer**: Workspace navigation links (`vault.html`, `records.html`, `incidents.html`, `sop.html`, `risk-assessments.html`, `support.html`), SVG icons, and active state styles (`bg-primary text-white`).
- **Footer**: Legal notices, statutory disclaimers, copyright, and co-branding badges.

**Direct Consequences Identified in v2:**
1. *Fragile Maintenance*: Changing a navigation item requires synchronized edits across 6–11 files. Any omission results in broken active states (as observed with `records.html`).
2. *Clean URL Route Mismatch*: Cloudflare Pages serves extensionless clean URLs (e.g. `/records` rather than `/records.html`). Legacy `main.js` route matching relies on `window.location.pathname.split('/').pop() || 'vault.html'`, which fails string equality (`'records' === 'records.html'`).

### 1.2 Synchronous Layout Architecture & Anti-FOUC Details

To eliminate layout shifts (Cumulative Layout Shift, CLS) and Flash of Unstyled Content (FOUC) in a zero-build static architecture, Version 3 enforces a two-tier mounting pattern:
1. **Baseline Structural HTML Shell**: Every authenticated view retains structural container tags with basic Tailwind dimensions, fixed coordinates, and background colors.
2. **Synchronous JavaScript Injection**: `/js/modules/layout.js` mounts synchronously on script parse before initial layout paint.

```
       HTML Document Parse
                │
                ▼
   <header id="app-header" class="fixed top-0 left-0 right-0 h-[72px] bg-white ..."></header>
   <aside id="app-sidebar" class="fixed left-0 top-0 bottom-0 w-64 bg-[#f8fafc] ..."></aside>
                │
                ▼
   [ /js/modules/layout.js Evaluates Synchronously ]
   - Resolves Canonical Active Route via getActiveRoute()
   - Injects Synchronous Template Literals
   - Sets Active Tab Styling (bg-primary text-white font-semibold)
                │
                ▼
   [ /js/profile-engine.js Hydrates Session ]
   - Injects #profileModal Container
   - Populates Tenant Name & Sponsor Pill
   - Updates Avatar & Dynamic Tier Badges
```

#### A. Baseline Structural Containers in HTML Views
Every authenticated application view (`vault.html`, `module.html`, `records.html`, `incidents.html`, `sop.html`, `risk-assessments.html`, `support.html`) maintains baseline structural containers directly in static HTML:

```html
<!-- Baseline Structural Layout Containers (Zero-FOUC Shell) -->
<header id="app-header" class="fixed top-0 left-0 right-0 z-40 h-[72px] bg-white border-b border-slate-200/80 flex items-center justify-between px-4 sm:px-6"></header>
<div id="sidebar-backdrop" class="fixed inset-0 z-40 hidden bg-slate-950/40 lg:hidden" aria-hidden="true"></div>
<aside id="app-sidebar" class="fixed left-0 top-0 bottom-0 z-50 w-64 -translate-x-full lg:translate-x-0 transition-transform duration-300 lg:top-[72px] lg:z-30 border-r border-slate-200/80 bg-[#f8fafc] flex flex-col justify-between p-4"></aside>
```

#### B. Component Engine Implementation (`/js/modules/layout.js`)
```javascript
/**
 * The Vault Hub (v3) - Centralized Layout Engine
 * Zero-build, synchronous DOM injection preserving active state and eliminating FOUC.
 */
export const LayoutEngine = {
  // Normalize clean URLs: '/records', '/records.html', '/records/' -> 'records'
  getActiveRoute() {
    const raw = window.location.pathname.split('/').filter(Boolean).pop() || 'vault';
    return raw.replace(/\.html$/, '').toLowerCase();
  },

  renderSidebar(activeRoute) {
    const navItems = [
      { id: 'vault', label: 'Video Library', href: 'vault.html', icon: 'M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z M21 12a9 9 0 11-18 0 9 9 0 0118 0z' },
      { id: 'records', label: 'Training Records', href: 'records.html', icon: 'M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z' },
      { id: 'incidents', label: 'Incident Register', href: 'incidents.html', icon: 'M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z' },
      { id: 'sop', label: 'SOPs', href: 'sop.html', icon: 'M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z' },
      { id: 'risk-assessments', label: 'Risk Assessments', href: 'risk-assessments.html', icon: 'M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4' },
      { id: 'support', label: 'Help & Support', href: 'support.html', icon: 'M18.364 5.636l-3.536 3.536m0 5.656l3.536 3.536M9.172 9.172L5.636 5.636m3.536 9.192l-3.536 3.536M21 12a9 9 0 11-18 0 9 9 0 0118 0zm-5 0a4 4 0 11-8 0 4 4 0 018 0z' }
    ];

    const linksHtml = navItems.map(item => {
      const isActive = activeRoute === item.id;
      const btnClass = isActive
        ? 'bg-primary text-white shadow-sm font-semibold'
        : 'text-slate-600 font-medium hover:text-slate-900 hover:bg-slate-200/60';
      const iconClass = isActive ? 'text-white' : 'text-slate-400';

      return `
        <a href="${item.href}" title="${item.label}" class="sidebar-nav-btn flex items-center gap-3.5 px-3.5 py-3 rounded-xl text-[15px] transition-all ${btnClass}">
          <svg class="w-6 h-6 shrink-0 ${iconClass}" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="${item.icon}"/>
          </svg>
          <span class="sidebar-text truncate">${item.label}</span>
        </a>
      `;
    }).join('');

    return `
      <div class="space-y-6">
        <div>
          <p class="sidebar-category-header px-3 text-xs font-bold uppercase tracking-wider text-slate-400 mb-2.5">Workspace</p>
          <nav class="space-y-1.5">${linksHtml}</nav>
        </div>
      </div>
      <div id="sidebar-footer-tier" class="pt-4 border-t border-slate-200/80">
        <!-- Injected dynamically by ProfileEngine -->
      </div>
    `;
  },

  renderHeader() {
    return `
      <div class="flex items-center gap-4">
        <button id="mobile-menu-btn" class="lg:hidden p-2 text-slate-600 hover:text-slate-900 focus:outline-none" aria-label="Open Navigation">
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"/></svg>
        </button>
        <a href="vault.html" class="flex items-center gap-2.5">
          <div class="w-9 h-9 rounded-lg bg-primary flex items-center justify-center text-white font-serif font-bold text-lg shadow-sm">V</div>
          <div class="flex flex-col">
            <span class="font-serif font-bold text-slate-900 leading-tight">The Vault</span>
            <span class="text-[10px] text-muted uppercase tracking-wider font-semibold" id="header-tenant-indicator">Agricultural Safety</span>
          </div>
        </a>
      </div>
      <div class="flex items-center gap-3">
        <div id="topbar-sponsor-badge" class="hidden sm:flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-slate-100 border border-slate-200 text-xs font-semibold text-slate-700"></div>
        <button type="button" onclick="openProfileModal()" class="flex items-center gap-2.5 p-1.5 rounded-xl hover:bg-slate-100 transition-colors">
          <img id="userAvatar" src="assets/branding/Simple_Logo.jpg" class="w-8 h-8 rounded-full object-cover border border-slate-200 shadow-sm" alt="User Avatar">
          <span id="userName" class="hidden md:inline text-xs font-semibold text-slate-700 max-w-[120px] truncate">My Account</span>
        </button>
      </div>
    `;
  },

  mount() {
    const activeRoute = this.getActiveRoute();
    const sidebar = document.getElementById('app-sidebar');
    if (sidebar) sidebar.innerHTML = this.renderSidebar(activeRoute);

    const header = document.getElementById('app-header');
    if (header) header.innerHTML = this.renderHeader();

    document.body.dataset.layoutMounted = 'true';
    window.dispatchEvent(new CustomEvent('vault:layout-mounted', { detail: { activeRoute } }));
  }
};
```

---

## 2. Database Hardening & Bloat Cleanup

### 2.1 Server-Side Asset Redaction for Crop Packs (The Scraping Vulnerability)
In Version 2, gating for specialized crop curricula (Macadamia, Banana, Citrus) is enforced **solely in client-side JavaScript**:
- `vault.html` queries `public.videos` via Supabase JS. The RLS policy `USING (true)` delivers all rows.
- The client receives raw `id` (the Vimeo embed ID), `thumbnail_url`, `questions`, and `objectives`.
- In `module.html`, the URL parameter `module.html?v=102345678` is intercepted in JS (`isCropLocked`), but the raw Vimeo embed source `https://player.vimeo.com/video/102345678` is fully accessible in the browser console or network tab.
- In `sop.html`, the RLS policy allows `company_id IS NULL`, exposing downloadable DOCX/PDF storage URLs (`doc_url`) for unpurchased crop packs to anyone logged in.

#### Architectural Rectification: Secure Views & Authoritative RPC Gateway

```
Client (vault.html / module.html)
        │
        ▼
   [ RPC: get_vault_catalog() ]
        │
        ├─► User has Crop Entitlement? ──────────┐
        │                                        │
        ▼ NO                                     ▼ YES
   - video_id: "locked_citrus_pack"        - video_id: "102345678" (Vimeo ID)
   - stream_ready: false                   - stream_ready: true
   - thumbnail: Redacted/Watermarked       - thumbnail: Full Res Co-Branded
   - questions: NULL                       - questions: Complete JSONB
   - sop_url: NULL                         - sop_url: Authenticated Storage Link
```

#### SQL Implementation Specification
We deprecate direct client SELECT on `public.videos` and `public.sops` for authenticated users and introduce authoritative security-definer procedures:

```sql
-- 1. Secure RPC: get_vault_catalog()
CREATE OR REPLACE FUNCTION public.get_vault_catalog()
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER
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

    -- Check if tenant has a private estate library (Elliott, Doveton, Outlook)
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
                WHEN lower(v.sub_tag) IN ('general safety', 'machinery & workshop') THEN false
                -- Locked on basic tier for other sub-tags
                WHEN lower(coalesce(v_tier, 'basic')) = 'basic' THEN true
                -- Custom private library override
                WHEN v_has_custom_library AND v.company_id = v_company_id THEN false
                -- Master unlock
                WHEN v_unlock_all OR v_is_subsidized THEN false
                -- Crop pack entitlement check
                WHEN v.curriculum_slug IS NOT NULL AND (
                    v.curriculum_slug = ANY(v_sponsored) OR v.curriculum_slug = ANY(v_purchased)
                ) THEN false
                ELSE true
            END AS is_locked
        FROM public.videos v
        WHERE (v.company_id IS NULL AND NOT v_has_custom_library)
           OR (v.company_id = v_company_id)
        ORDER BY v.title ASC
    ) v;

    RETURN coalesce(v_result, '[]'::jsonb);
END;
$$;
```

#### Authoritative Stream Resolution RPC (`get_module_stream`)
When `module.html` initializes, it calls `get_module_stream(p_video_id)`. The function evaluates entitlement on the server. If unauthorized, it raises an exception (`P0001: Unauthorized access to gated crop pack`) preventing any video stream leak.

---

### 2.2 Schema & Asset Bloat Audit

A comprehensive audit of `.ai/SUPABASE_SCHEMA.md` and repository assets identifies the following candidates for formal retirement in Version 3:

| Object Name | Type | Current Location | Audit Findings & Retirement Rationale |
| :--- | :--- | :--- | :--- |
| **`sandbox_jsonb_backup`** | Table | Schema line 1072 | **Orphaned Legacy Snapshot**: Created during early JSONB transformations. Contains zero foreign keys, zero RLS policies, and zero code references. **Action:** Schedule `DROP TABLE public.sandbox_jsonb_backup;` in v3 migration. |
| **`videos.company_name`** | Column | `public.videos` line 1162 | **Redundant Denormalization**: Foreign key `videos.company_id REFERENCES companies(id)` is already indexed. Denormalized company names fall out of sync when companies rebrand or update names. **Action:** Retire column; resolve via JOIN. |
| **`sops.company_name`** | Column | `public.sops` line 1096 | **Redundant Denormalization**: Same flaw as `videos.company_name`. **Action:** Retire column; resolve via JOIN. |
| **`training_records.signature_url`** | Column | `public.training_records` line 978 | **Obsolete Storage Link**: Early prototype artifact. Production sign-offs capture dual inline base64 canvas data (`supervisor_signature_data`, `employee_signature_data`). Only retained in legacy fallback view. **Action:** Deprecate; migrate any legacy rows to storage. |
| **`crop_pack_addon_purchases`** | Table | Schema line 906 | **Missing RLS Policy**: Table has `ENABLE ROW LEVEL SECURITY` but 0 policies, preventing client audit views. **Action:** Add tenant SELECT policy matching `company_id = get_my_company_id()`. |
| **`assets/workflow_pics/`** | Directory | Root repository (14 PNGs) | **Prototype Bloat**: Several large mock screenshots (PM intake, construction gantt) referenced only on marketing test routes (`systems.html`). **Action:** Compress or migrate to Supabase Storage CDN before production build. |

---

## 3. Video Library & Playback Engine

### 3.1 Video Catalog UI Scope Adjustment: Retaining High-Density Grid
Following strategic evaluation during our Lona Group executive session, the proposal to implement a horizontal "Netflix-style" carousel on `vault.html` is **officially cancelled**.

#### Strategic & Operational Rationale
1. **Visibility & Discoverability**: Farm compliance managers require immediate, high-density visual scanning of all compliance modules. Carousels hide cards off-screen, requiring high-friction horizontal swiping that slows down induction scheduling.
2. **Category Density Balance**: Specialized crop packs (such as Citrus, Macadamia, or Banana) frequently launch with 2 to 4 modules. In a horizontal carousel, rows with 2 cards look sparse, broken, and visually unbalanced.
3. **Audit Verification Efficiency**: During SIZA or GlobalG.A.P. audits, supervisors need to quickly display the entire training curriculum to external auditors on a single screen without nested pagination.

#### The Approved Layout: Categorical High-Density Responsive Grid
`vault.html` will retain and polish its clean, responsive grid layout grouped into semantic compliance sections:

```html
<!-- Category Section Component on vault.html -->
<section class="mb-10 space-y-4">
  <div class="flex items-center justify-between border-b border-slate-200/80 pb-3">
    <div>
      <h2 class="text-lg sm:text-xl font-serif font-bold text-foreground">Citrus Processing & Field Operations</h2>
      <p class="text-xs text-muted">Statutory safety procedures for picking, ladder work, tractor haulage, and packhouse sorting.</p>
    </div>
    <span class="text-xs font-semibold text-slate-500 bg-slate-100 px-2.5 py-1 rounded-full">4 Modules</span>
  </div>

  <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-5">
    <!-- Clean, high-density video card with clear badges and duration -->
    <a href="module.html?v=..." class="video-card group block bg-white rounded-xl border border-slate-200 overflow-hidden shadow-sm hover:shadow-lg transition-all duration-200">
      <div class="relative aspect-video bg-slate-900 overflow-hidden">
        <img src="..." class="w-full h-full object-cover group-hover:scale-102 transition-transform duration-300" alt="Module Thumbnail">
        <span class="absolute bottom-2 right-2 px-2 py-0.5 rounded bg-black/80 text-[11px] font-mono font-medium text-white">05:42</span>
      </div>
      <div class="p-4 space-y-1.5">
        <span class="inline-block text-[10px] font-bold uppercase tracking-wider text-orange-700 bg-orange-50 px-2 py-0.5 rounded">Citrus Pack</span>
        <h3 class="font-bold text-sm text-foreground group-hover:text-primary transition-colors line-clamp-1">Orchard Ladder & Harvesting Safety</h3>
        <p class="text-xs text-muted line-clamp-2">Mandatory safety protocols for pickers, picking bags, and tripod orchard ladders.</p>
      </div>
    </a>
  </div>
</section>
```

---

### 3.2 Dynamic Multi-Language Stream Switcher

#### The Canonical Single-Module Pattern
Agricultural crews in South Africa frequently require training in English, isiZulu, Afrikaans, or isiXhosa. Rather than creating separate database rows for each language (which fragments audit logs and duplicates records), a single canonical module row in `public.videos` contains a structured audio map:

```sql
-- Schema Migration: Support Multilingual Stream Map in public.videos
ALTER TABLE public.videos 
ADD COLUMN IF NOT EXISTS streams jsonb DEFAULT '{}'::jsonb;

-- Example Data Structure:
-- {
--   "en": { "vimeo_id": "104928172", "label": "English" },
--   "zu": { "vimeo_id": "104928173", "label": "isiZulu" },
--   "af": { "vimeo_id": "104928174", "label": "Afrikaans" },
--   "xh": { "vimeo_id": "104928175", "label": "isiXhosa" }
-- }
```

#### Dynamic Hot-Swap Execution in `module.html`
When a supervisor switches language during crew training, the Vimeo Player SDK hot-swaps the underlying video stream without reloading the page, maintaining the exact playback timestamp and playback state:

```javascript
/**
 * Hot-swaps the active Vimeo video stream while preserving current playback position.
 * @param {string} targetLang - Language key ('en', 'zu', 'af', 'xh')
 */
async function switchAudioStream(targetLang) {
  if (!window.vimeoPlayer || !currentVideoStreams[targetLang]) return;

  try {
    const streamConfig = currentVideoStreams[targetLang];
    const newVimeoId = streamConfig.vimeo_id;

    // 1. Capture current playback state before switching
    const currentSeconds = await window.vimeoPlayer.getCurrentTime();
    const isPaused = await window.vimeoPlayer.getPaused();

    // 2. Hot-swap video stream using Vimeo SDK loadVideo()
    await window.vimeoPlayer.loadVideo(newVimeoId);

    // 3. Re-seek to preserved timestamp
    await window.vimeoPlayer.setCurrentTime(currentSeconds);

    // 4. Restore playback if it was active
    if (!isPaused) {
      await window.vimeoPlayer.play();
    }

    // 5. Update UI active button
    document.querySelectorAll('.language-stream-btn').forEach(btn => {
      const active = btn.dataset.lang === targetLang;
      btn.className = active
        ? 'language-stream-btn px-3 py-1.5 rounded-lg text-xs font-bold bg-primary text-white shadow-sm'
        : 'language-stream-btn px-3 py-1.5 rounded-lg text-xs font-medium bg-slate-100 text-slate-600 hover:bg-slate-200';
    });

    console.log(`[VimeoEngine] Successfully switched audio stream to ${streamConfig.label} at ${Math.floor(currentSeconds)}s`);
  } catch (err) {
    console.error('[VimeoEngine] Failed to hot-swap audio stream:', err);
  }
}
```

*Audit Progress Integrity:* Watch progress saved to `public.user_video_progress` and verified training records logged to `public.training_records` continue to reference the canonical `video.id`, completely preventing fragmented training records across language preferences.

---

## 4. Offline Capabilities & Video Download Feasibility Audit

### 4.1 The Technical & Legal Reality Check: In-Browser Video Downloads

| Consideration | Browser Reality & Constraints | Verdict |
| :--- | :--- | :--- |
| **Vimeo DRM & API Terms** | Vimeo standard iframe embeds (`player.vimeo.com`) stream adaptive HLS/DASH segmented chunks. Vimeo's API Terms of Service strictly forbid scraping, proxying, or downloading video media without enterprise direct MP4 file licenses. | **BLOCKED BY TERMS** |
| **Browser Storage Quotas** | An hour of 1080p video requires ~1.2GB–2.5GB. Low-end Android smartphones (standard issue for farm supervisors) frequently enforce strict 50MB–250MB IndexedDB origin quotas or evict storage automatically when device flash storage drops below 10%. | **UNFEASIBLE FOR MASS VIDEO** |
| **Zero-Build Architecture** | In a zero-build static web app without native bridge wrappers (Capacitor / Cordova / React Native), managing large chunked binary downloads causes JavaScript heap memory crashes and browser tab terminations on mobile Chrome. | **ARCHITECTURAL ANTI-PATTERN** |

### 4.2 Realistic Offline Boundaries for Version 3 (The Field Workspace)

Rather than attempting brittle in-browser video caching, Version 3 scopes offline capability to the specific field workflows required by farm supervisors out in orchards and remote packing sheds where cellular signals drop.

```
+----------------------------------------------------------------------------------------------------+
|                                    OFFLINE CAPABILITIES MATRIX                                     |
+------------------------------------+-----------------------------------+---------------------------+
| Operational Feature                | Storage Mechanism                 | Reconnection Sync Strategy|
+------------------------------------+-----------------------------------+---------------------------+
| 1. Employee Roster Verification    | IndexedDB (`company_employees`)   | Cache-first, background   |
|    - Search active workers by name | Persisted on successful login     | refresh on app load       |
|    - Lookup employee number/team   |                                   |                           |
+------------------------------------+-----------------------------------+---------------------------+
| 2. Group Induction Sign-off Queue  | IndexedDB (`induction_queue`)     | Background Worker drains  |
|    - Select attendees from cache   | Encrypted pending array with      | queue via atomic RPC      |
|    - Capture supervisor signature  | timestamp & local UUID            | `log_induction_session`   |
+------------------------------------+-----------------------------------+---------------------------+
| 3. Statutory SOP & Checklist Docs  | Service Worker (`/sw.js`)         | Stale-While-Revalidate    |
|    - Access emergency procedures   | Cache API (`vault-static-v3`)     | automatic asset updates   |
|    - Baseline hazard registers     |                                   |                           |
+------------------------------------+-----------------------------------+---------------------------+
| 4. Incident Draft Logging          | LocalStorage (`incident_drafts`)  | Auto-posts when           |
|    - Capture injury details        | JSON serialized draft             | `navigator.onLine = true` |
+------------------------------------+-----------------------------------+---------------------------+
```

#### Reconnection Synchronization Engine (`/js/modules/sync-worker.js`)
```javascript
// Synchronizes queued offline training sign-offs once connectivity resumes
window.addEventListener('online', async () => {
  console.log('[SyncWorker] Internet connectivity detected. Scanning offline induction queue...');
  const queue = await OfflineDB.getPendingInductions();
  if (queue.length === 0) return;

  showSyncBadge(`Syncing ${queue.length} offline training record(s)...`);

  for (const session of queue) {
    try {
      const { data, error } = await window.dbClient.rpc('log_induction_session', session.payload);
      if (error) throw error;
      await OfflineDB.removePendingInduction(session.id);
    } catch (err) {
      console.error(`[SyncWorker] Failed to sync session ${session.id}:`, err);
    }
  }

  hideSyncBadge('✓ All offline records synced successfully.');
  if (typeof fetchAndRenderRecords === 'function') fetchAndRenderRecords();
});
```

---

## 5. Employee Directory, Training Expiry & Farm Roster Specification

### 5.1 Farm Roster Table Specification: `public.company_employees`

To support the approved Roster Engine ([`docs/architecture/specs/UNIFIED_INDUCTION_AND_ROSTER_SPEC.md`](file:///home/luca/dev/the-vault-web/docs/architecture/specs/UNIFIED_INDUCTION_AND_ROSTER_SPEC.md)), Version 3 implements the authoritative employee roster table with complete multi-tenant isolation keyed directly to `public.companies.id`.

#### A. PostgreSQL DDL Schema
```sql
CREATE TABLE public.company_employees (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    first_name text NOT NULL,
    last_name text NOT NULL,
    employee_number text NOT NULL, -- Clock number, Farm ID, or Payroll code
    id_passport_number text,      -- South African ID or Foreign Passport
    gender text,                  -- 'Male', 'Female', 'Other'
    team_or_orchard text,         -- Division (e.g. "Citrus Orchard 4B", "Packhouse Night Shift")
    is_active boolean DEFAULT true NOT NULL, -- Soft-deactivation for seasonal turnover
    created_at timestamptz DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamptz DEFAULT timezone('utc'::text, now()) NOT NULL,

    CONSTRAINT company_employees_gender_check CHECK (gender = ANY (ARRAY['Male'::text, 'Female'::text, 'Other'::text])),
    CONSTRAINT company_employees_company_id_employee_number_key UNIQUE (company_id, employee_number)
);

-- Performance & Reporting Indexes
CREATE INDEX idx_company_employees_company_active ON public.company_employees USING btree (company_id, is_active);
CREATE INDEX idx_company_employees_company_team ON public.company_employees USING btree (company_id, team_or_orchard);
CREATE INDEX idx_company_employees_search ON public.company_employees USING btree (company_id, employee_number, first_name, last_name);
```

#### B. Strict Multi-Tenant Row Level Security (RLS)
The platform guarantees strict privacy between independent commercial agricultural entities (e.g., Lona Citrus Estate vs Doveton Farms) in full compliance with **Section 19 of the Protection of Personal Information Act (POPIA, Act 4 of 2013)**.

```sql
-- Enable Row Level Security
ALTER TABLE public.company_employees ENABLE ROW LEVEL SECURITY;

-- 1. Read Policy: Users can only query workers belonging to their authenticated tenant
CREATE POLICY "Tenants can view own company employees"
ON public.company_employees FOR SELECT TO authenticated
USING (company_id = public.get_my_company_id());

-- 2. Insert Policy: Admins & managers can only enroll workers into their own tenant
CREATE POLICY "Admins and managers can insert company employees"
ON public.company_employees FOR INSERT TO authenticated
WITH CHECK (company_id = public.get_my_company_id());

-- 3. Update Policy: Admins & managers can only modify workers in their own tenant
CREATE POLICY "Admins and managers can update company employees"
ON public.company_employees FOR UPDATE TO authenticated
USING (company_id = public.get_my_company_id())
WITH CHECK (company_id = public.get_my_company_id());

-- 4. Hard Deletion Revocation: Raw DELETE is strictly prohibited
REVOKE DELETE ON public.company_employees FROM public, authenticated;
```

#### C. Cross-Tenant Protection Guarantee
- `public.get_my_company_id()` resolves the caller's tenant directly from `public.profiles` using `auth.uid()`.
- Client-side manipulation of `company_id` is cryptographically ignored by the database engine.
- Even if an attacker executes `supabase.from('company_employees').select('*')` in the browser console, the database engine returns zero rows belonging to external estates.

#### D. Linking Training Records
```sql
-- Link training records to company employees with snapshot retention
ALTER TABLE public.training_records
ADD COLUMN IF NOT EXISTS employee_id uuid REFERENCES public.company_employees(id) ON DELETE SET NULL;
```

---

### 5.2 365-Day Statutory Renewal & Overdue Logic
Under South African occupational safety standards (OHSA GSR 2(1)) and agricultural certification standards (SIZA & GlobalG.A.P.), general farm safety inductions expire **annually (every 365 days)**.

#### Status Calculation Contract
```javascript
export function calculateComplianceStatus(lastCompletedAt) {
  if (!lastCompletedAt) {
    return { status: 'Untrained', badgeClass: 'bg-red-100 text-red-800 border-red-200', daysRemaining: 0 };
  }

  const completionDate = new Date(lastCompletedAt);
  const now = new Date();
  const daysSince = Math.floor((now - completionDate) / (1000 * 60 * 60 * 24));
  const daysRemaining = 365 - daysSince;

  if (daysRemaining < 0) {
    return { 
      status: 'Overdue', 
      badgeClass: 'bg-red-100 text-red-800 border-red-200', 
      daysRemaining,
      label: `Expired ${Math.abs(daysRemaining)} days ago` 
    };
  } else if (daysRemaining <= 30) {
    return { 
      status: 'Expiring Soon', 
      badgeClass: 'bg-amber-100 text-amber-800 border-amber-200', 
      daysRemaining,
      label: `Expires in ${daysRemaining} days` 
    };
  } else {
    return { 
      status: 'Compliant', 
      badgeClass: 'bg-emerald-100 text-emerald-800 border-emerald-200', 
      daysRemaining,
      label: `Valid (${daysRemaining} days remaining)` 
    };
  }
}
```

#### Automated Email Notification via Supabase Edge Function (`cron-training-expiry`)
A scheduled Deno Edge Function (`supabase/functions/cron-training-expiry`) runs weekly:
1. Identifies active workers (`is_active = true`) who are either **Expiring Soon ($\le 30$ days)** or **Overdue ($< 0$ days)**.
2. Formats a consolidated compliance digest for the farm general manager.
3. Dispatches the notification via the existing Resend API integration.

### 5.3 Record Delete & Soft-Archive Governance (OHSA 5-Year Rule)
Under OHSA Regulations and SIZA Standard v8, agricultural employers must retain employee health and safety training records for a minimum of **5 years** (and 30 years for hazardous chemical spraying). Allowing supervisors or standard users to hard-delete records represents a severe legal and audit liability.

#### Governance Rules
1. **Raw DELETE Revoked**: `REVOKE DELETE ON public.training_records FROM authenticated, public;`
2. **Master Admin Soft-Archive Interface**: Only users with `role = 'Master Admin'` in `public.profiles` can soft-archive records.
3. **Audit Ledger**: Soft-archived rows remain in `public.training_records` with `status = 'Archived'`, suppressed from active compliance tallies but immediately exportable upon auditor demand.

---

## 6. Statutory Incident Reporting Module (`incidents.html`)

### 6.1 Statutory Alignment: OHSA Section 24, GAR 9 & SIZA / GlobalG.A.P.

Under **Section 24 of the Occupational Health and Safety Act (Act 85 of 1993)** and **General Administrative Regulations 9 (GAR 9)**, an employer must maintain a formal investigation register of all workplace incidents and must notify the Provincial Chief Inspector of the Department of Employment and Labour within **7 days** using statutory **Annexure 1 (WCL 1/2 equivalent)** if an incident resulted in:
1. Fatality or permanent loss of a limb / part of a limb.
2. Incapacitation rendering an employee unable to perform normal duties for 14 days or longer.
3. Loss of consciousness from chemical exposure, asphyxiation, or electrical contact.
4. Dangerous machinery failure (crane / forklift rollover, pressure vessel rupture).

Agricultural audit frameworks (**SIZA Principle 4** and **GlobalG.A.P. IFA v6**) require farms to maintain a dedicated, auditable on-farm **Incident & Near-Miss Register** documenting root causes, corrective preventative actions, and supervisor verification.

### 6.2 Data Model: `public.incident_reports`

```sql
CREATE TABLE public.incident_reports (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    incident_number text NOT NULL, -- e.g. "INC-2026-001" (Auto-generated per tenant)
    incident_date date NOT NULL,
    incident_time time NOT NULL,
    reported_at timestamptz DEFAULT now() NOT NULL,
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
    investigator_signature text NOT NULL, -- Base64 Canvas Signature
    status text DEFAULT 'Open' NOT NULL,
    attachments jsonb DEFAULT '[]'::jsonb NOT NULL,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL,

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

-- Multi-Tenant Indexes & RLS
CREATE INDEX idx_incidents_company ON public.incident_reports (company_id, incident_date DESC);
CREATE INDEX idx_incidents_statutory ON public.incident_reports (company_id, is_section_24_statutory);

ALTER TABLE public.incident_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Tenants can manage their own incident reports"
ON public.incident_reports FOR ALL TO authenticated
USING (company_id = public.get_my_company_id())
WITH CHECK (company_id = public.get_my_company_id());
```

---

### 6.3 Dedicated Root View Architecture: `incidents.html`
Rather than overburdening `records.html` (which already spans ~1850 lines of complex training and certification logic), incident management lives as a dedicated, focused root view: **`incidents.html`**.

#### User Interface Features in `incidents.html`:
1. **Summary KPI Strip**: Total Incidents YTD, Near Misses, Lost-Time Injuries, Days Since Last Incident.
2. **New Incident Modal**: Fast-entry form with employee roster autocompletion from `public.company_employees`.
3. **Statutory Section 24 Toggle**: Highlights legal reporting obligations (countdown banner: "DoL Annexure 1 submission required within 7 days").
4. **Digital Signature Canvas**: Single Supervisor / Safety Officer verification canvas.

#### Dual jsPDF Export Engine
The view includes two dedicated jsPDF generators built under South African legal standards:

```
                          Incident Record in incidents.html
                                         │
                 ┌───────────────────────┴───────────────────────┐
                 ▼                                               ▼
   [ Statutory DoL Annexure 1 PDF ]               [ SIZA / GlobalG.A.P. Audit Register ]
   - General Admin Reg 9 Formal Layout            - Landscape A4 Multi-Row Table
   - Prescribed DoL Inspectorate Fields           - Full Date-Range Filterable Ledger
   - Employer, Employee & Witness Details         - Corrective Action Tracking Proof
   - Root Cause & Causal Factor Analysis          - Auditor-Ready Compliance Hand-off
```

1. **Department of Employment & Labour Annexure 1 Investigation PDF (Portrait A4)**:
   - Prescribed statutory format under General Administrative Regulations 9.
   - Formal sections: Employer Details, Injured Employee Details, Circumstances & Description, Causal Machine/Substance, Root Cause Analysis, Corrective Preventative Measures, Section 16(2) Investigator Declaration, and Inspectorate Notification Stamp.
2. **SIZA / GlobalG.A.P. Incident & Near-Miss Audit Register (Landscape A4)**:
   - Full tabular audit ledger detailing Incident #, Date/Time, Location/Orchard, Worker Name & Clock #, Severity Class, Root Cause, Action Plan, Responsible Person, Completion Date, and Status (Open / In Progress / Closed).

---

## 7. Profile Modal: Official Company Stamp Upload & Dynamic Stamp Engine

### 7.1 Stamp Storage Architecture
Farm enterprises often require their official corporate stamp or round estate seal affixed to training certificates for GlobalG.A.P. acceptance.

1. **Database Column**:
   ```sql
   ALTER TABLE public.companies 
   ADD COLUMN IF NOT EXISTS company_stamp_url text;
   ```
2. **Storage Bucket**: Bucket `company-assets` (or per-tenant folder in `avatars` bucket):
   - Path format: `${company_id}/stamp_${Date.now()}.png`
   - Restrictions: Restricted to PNG / JPG, max 1.5MB, with transparent PNG strongly encouraged in the UI.

### 7.2 UI Integration in `profile-modal.html`
Inside the "Organization" tab of `#profileModal`, a dedicated Company Seal Dropzone allows farm managers to upload and preview their seal:

```html
<div class="mt-6 p-4 rounded-xl border border-slate-200 bg-slate-50/50 space-y-3">
  <div class="flex items-center justify-between">
    <div>
      <h4 class="text-sm font-bold text-foreground">Official Estate Stamp / Seal</h4>
      <p class="text-xs text-muted">Upload a transparent PNG seal to automatically watermark training certificates.</p>
    </div>
    <div id="company-stamp-preview-container" class="w-16 h-16 rounded-lg border border-dashed border-slate-300 bg-white flex items-center justify-center overflow-hidden">
      <img id="company-stamp-preview" src="" class="hidden w-full h-full object-contain p-1" alt="Estate Stamp">
      <span id="stamp-placeholder-icon" class="text-xs text-slate-400">No Seal</span>
    </div>
  </div>
  <div class="flex items-center gap-3">
    <input type="file" id="company-stamp-input" accept="image/png,image/jpeg" class="hidden" onchange="handleCompanyStampUpload(event)">
    <button type="button" onclick="document.getElementById('company-stamp-input').click()" class="px-4 py-2 bg-white border border-slate-300 rounded-lg text-xs font-semibold text-slate-700 hover:bg-slate-50 transition-all shadow-sm">
      Upload Stamp Image
    </button>
    <button type="button" id="remove-stamp-btn" onclick="removeCompanyStamp()" class="hidden text-xs text-red-600 hover:underline">
      Remove Stamp
    </button>
  </div>
</div>
```

---

### 7.3 Dynamic Certificate Stamp Engine (Aspect-Ratio Preservation Algorithm)

In `records.html` and `module.html`, the statutory certificate generator embeds the company seal. To ensure oval farm seals (common for citrus cooperatives) and rectangular corporate marks are **never distorted or stretched**, the engine dynamically computes proportional scaling within a **30mm wide $\times$ 25mm high** bounding box:

```javascript
/**
 * Renders the verified company stamp block onto the statutory certificate canvas
 * with strict aspect-ratio preservation to prevent seal distortion.
 * 
 * @param {jsPDF} doc - Active jsPDF document instance
 * @param {Object} company - Current company data object
 * @param {number} x - Target horizontal start coordinate (mm)
 * @param {number} y - Target vertical start coordinate (mm)
 */
async function renderCertificateStamp(doc, company, x, y) {
  const BOUNDING_BOX = { width: 30, height: 25 }; // Max dimensions in mm

  // Strategy 1: User-Uploaded Corporate Estate Stamp with Aspect-Ratio Calculation
  if (company?.company_stamp_url) {
    try {
      // 1. Fetch image and determine natural dimensions
      const img = new Image();
      img.crossOrigin = 'anonymous';
      
      const loaded = await new Promise((resolve, reject) => {
        img.onload = () => resolve(true);
        img.onerror = reject;
        img.src = company.company_stamp_url;
      });

      if (loaded && img.naturalWidth > 0 && img.naturalHeight > 0) {
        const naturalRatio = img.naturalWidth / img.naturalHeight;
        const boxRatio = BOUNDING_BOX.width / BOUNDING_BOX.height;

        let renderWidth, renderHeight;

        // Constrain dimensions to bounding box while preserving natural aspect ratio
        if (naturalRatio > boxRatio) {
          // Wider than box ratio: constrained by width
          renderWidth = BOUNDING_BOX.width;
          renderHeight = BOUNDING_BOX.width / naturalRatio;
        } else {
          // Taller than or equal to box ratio: constrained by height
          renderHeight = BOUNDING_BOX.height;
          renderWidth = BOUNDING_BOX.height * naturalRatio;
        }

        // Center within the bounding box
        const offsetX = x + (BOUNDING_BOX.width - renderWidth) / 2;
        const offsetY = y + (BOUNDING_BOX.height - renderHeight) / 2;

        // Convert to canvas Base64 for jsPDF
        const canvas = document.createElement('canvas');
        canvas.width = img.naturalWidth;
        canvas.height = img.naturalHeight;
        const ctx = canvas.getContext('2d');
        ctx.drawImage(img, 0, 0);
        const stampBase64 = canvas.toDataURL('image/png');

        doc.addImage(stampBase64, 'PNG', offsetX, offsetY, renderWidth, renderHeight);
        return;
      }
    } catch (err) {
      console.warn('[PDFEngine] Failed to render uploaded company stamp, falling back to vector seal:', err);
    }
  }

  // Strategy 2: Default Programmatic Vector Compliance Seal
  const centerX = x + BOUNDING_BOX.width / 2;
  const centerY = y + BOUNDING_BOX.height / 2;

  doc.setDrawColor(30, 58, 95); // Brand Primary (#1e3a5f)
  doc.setLineWidth(0.8);
  doc.circle(centerX, centerY, 11);
  doc.setLineWidth(0.3);
  doc.circle(centerX, centerY, 9.8);

  doc.setFont('helvetica', 'bold');
  doc.setFontSize(5.5);
  doc.setTextColor(30, 58, 95);
  doc.text('THE VAULT COMPLIANCE', centerX, centerY - 3, { align: 'center' });
  doc.setFontSize(4.5);
  doc.text('OFFICIALLY VERIFIED', centerX, centerY + 0.5, { align: 'center' });
  doc.text('OHSA ACT 85 OF 1993', centerX, centerY + 4, { align: 'center' });
}
```

---

## 8. Version 3 Phased Development Roadmap

```
+----------------------------------------------------------------------------------------------------+
|                                    V3 IMPLEMENTATION PHASES                                        |
+----------------------------------------------------------------------------------------------------+
|                                                                                                    |
|  PHASE 1: FOUNDATION, HARDENING & LAYOUT                                                           |
|  - Drop `sandbox_jsonb_backup` and clean redundant columns                                         |
|  - Deploy server-side `get_vault_catalog()` and `get_module_stream()` RPCs                          |
|  - Deploy `/js/modules/layout.js` zero-build synchronous component injector                        |
|                                                                                                    |
|  PHASE 2: VIDEO HUB & MULTILINGUAL AUDIO                                                           |
|  - Polish high-density categorical responsive grid on `vault.html`                                 |
|  - Add multilingual audio streams JSONB structure in `public.videos`                               |
|  - Build Vimeo Player SDK hot-swap switcher in `module.html`                                       |
|                                                                                                    |
|  PHASE 3: FIELD WORKSPACE & OFFLINE ENGINE                                                         |
|  - Deploy `public.company_employees` table & RLS policies                                          |
|  - Implement client-side IndexedDB roster cache for `company_employees`                            |
|  - Implement offline induction batch queue & signature capture                                      |
|  - Build automatic background sync worker on `online` event                                        |
|                                                                                                    |
|  PHASE 4: STATUTORY INCIDENT REGISTER & STAMP ENGINE                                               |
|  - Deploy `public.incident_reports` table & RLS policies                                           |
|  - Create dedicated `incidents.html` root view with Annexure 1 & SIZA landscape exports            |
|  - Connect 365-day renewal status badges in `records.html`                                         |
|  - Deploy scheduled Edge Function `cron-training-expiry` for email digests                         |
|  - Implement company stamp upload in `profile-modal.html` and proportional jsPDF engine            |
|                                                                                                    |
+----------------------------------------------------------------------------------------------------+
```

---

## 9. Architectural Sign-off & Verification

- **Architect:** Antigravity Principal Systems Architect
- **Target Compliance:** OHSA (Act 85 of 1993), General Administrative Regulations 9 (GAR 9), SIZA Social Standard v8, GlobalG.A.P. IFA v6, POPIA (Act 4 of 2013)
- **Deployment Strategy:** Zero-Build Static Hosting (Cloudflare Pages) + Supabase Enterprise
- **Document Master:** [`docs/architecture/specs/THE_VAULT_V3_HUB_SPEC.md`](file:///home/luca/dev/the-vault-web/docs/architecture/specs/THE_VAULT_V3_HUB_SPEC.md) (Aliased: [`architecture/specs/THE_VAULT_V3_HUB_SPEC.md`](file:///home/luca/dev/the-vault-web/architecture/specs/THE_VAULT_V3_HUB_SPEC.md))
