/**
 * The Vault Hub (v3) - Centralized Layout Engine
 * Zero-build, synchronous DOM injection preserving active state and eliminating FOUC.
 */
export const LayoutEngine = {
  // Normalize clean URLs: '/records', '/records.html', '/records/' -> 'records'
  getActiveRoute() {
    const raw = window.location.pathname.split('/').filter(Boolean).pop() || 'vault';
    const clean = raw.replace(/\.html$/, '').toLowerCase();
    if (clean === 'module') return 'vault';
    return clean;
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
      <div class="space-y-3">
        <div id="sidebar-footer-tier" class="pt-4 border-t border-slate-200/80">
          <!-- Injected dynamically by ProfileEngine -->
        </div>
        <button id="sidebarToggle" type="button" class="w-full flex items-center justify-center gap-2 p-2.5 text-xs font-medium text-slate-600 hover:text-slate-900 hover:bg-white border border-transparent hover:border-slate-200 rounded-xl transition-all shadow-sm" title="Toggle Sidebar">
          <svg class="w-4 h-4 shrink-0 transition-transform duration-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 19l-7-7 7-7m8 14l-7-7 7-7"/>
          </svg>
          <span class="truncate">Collapse View</span>
        </button>
      </div>
    `;
  },

  renderHeader() {
    return `
      <div class="flex items-center gap-2 sm:gap-4 min-w-0">
        <button id="mobile-menu-btn" type="button" aria-label="Open Navigation" aria-expanded="false" class="lg:hidden min-h-[44px] min-w-[44px] -ml-2 p-2 rounded-lg text-slate-600 hover:text-slate-900 hover:bg-slate-100 transition-colors focus:outline-none">
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"/></svg>
        </button>
        <!-- Official Brand Mark (Version 2 vault icon + serif wordmark) -->
        <a href="vault.html" class="flex items-center gap-2.5 sm:gap-3.5 group shrink-0" aria-label="The Vault — Video Library">
          <div class="w-9 h-9 sm:w-11 sm:h-11 rounded-xl bg-primary/10 flex items-center justify-center text-primary group-hover:bg-primary group-hover:text-white transition-colors shadow-sm shrink-0">
            <svg class="w-5 h-5 sm:w-6 sm:h-6" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
              <path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-7 14c-3.31 0-6-2.69-6-6s2.69-6 6-6 6 2.69 6 6-2.69 6-6 6zm0-10c-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4-1.79-4-4-4z"/>
            </svg>
          </div>
          <span class="font-serif font-bold text-slate-900 tracking-tight text-xl sm:text-2xl lg:text-[1.75rem] leading-none">The Vault</span>
        </a>
      </div>
      <div class="flex items-center gap-2 sm:gap-3 lg:gap-4 shrink-0">
        <!-- Live Company Name & Tier Badge (hydrated by profile-engine.js) -->
        <div class="hidden md:flex items-center gap-2.5 px-3.5 py-1.5 bg-white border border-slate-200 rounded-full text-xs font-medium text-slate-700 shadow-sm">
          <span class="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
          <span id="topbar-company-name" class="font-medium truncate max-w-[160px]">Loading…</span>
          <span class="text-slate-300">|</span>
          <span id="topbar-tier-tag" class="font-bold text-primary uppercase text-[10px] tracking-wide">…</span>
        </div>

        <!-- Live Partner Subsidy Dropdown Pill (revealed by renderTopbarSponsorPill() in profile-engine.js) -->
        <div id="topbar-sponsor-pill-container" class="relative hidden">
          <button id="topbar-sponsor-btn" onclick="typeof toggleSponsorDropdown === 'function' && toggleSponsorDropdown(event)" type="button" aria-haspopup="true" class="flex items-center gap-2 px-3 py-1.5 min-h-[36px] bg-white border border-slate-200 rounded-full text-xs font-semibold text-slate-700 shadow-sm hover:border-slate-300 hover:bg-slate-50 transition-all">
            <span class="w-2 h-2 rounded-full bg-primary/70"></span>
            <span id="topbar-sponsor-label" class="hidden sm:inline">Sponsors</span>
            <svg class="w-3.5 h-3.5 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/>
            </svg>
          </button>

          <!-- Dropdown Menu -->
          <div id="topbar-sponsor-dropdown" class="hidden absolute right-0 mt-2 w-[calc(100vw-2rem)] max-w-xs sm:w-72 bg-white border border-slate-200 rounded-2xl shadow-xl z-50 overflow-hidden py-1.5">
            <div class="px-4 py-2 border-b border-slate-100 bg-slate-50/70 flex items-center justify-between">
              <span class="text-[10px] font-bold uppercase tracking-wider text-slate-500">Active Subsidies</span>
              <span id="topbar-sponsor-count" class="text-[10px] font-bold text-primary px-2 py-0.5 rounded-full bg-primary/10">0 Active</span>
            </div>
            <div id="topbar-sponsor-items" class="divide-y divide-slate-100 max-h-64 overflow-y-auto">
              <!-- Injected via profile-engine.js -->
            </div>
          </div>
        </div>

        <!-- Notifications Bell -->
        <div class="relative">
          <button id="notification-bell-btn" onclick="typeof toggleNotificationDropdown === 'function' && toggleNotificationDropdown(event)" class="relative p-2.5 rounded-xl bg-white border border-slate-200 text-slate-500 hover:text-slate-800 transition-colors shadow-sm" title="Notifications">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"/></svg>
            <span id="bell-unread-dot" class="absolute top-2 right-2 w-2 h-2 bg-red-500 rounded-full ring-2 ring-white"></span>
          </button>

          <div id="notification-dropdown" class="hidden absolute right-0 mt-3 w-[calc(100vw-2rem)] max-w-sm bg-white border border-slate-200 rounded-2xl shadow-xl z-50 overflow-hidden">
            <div class="p-4 bg-slate-50 border-b border-slate-200 flex items-center justify-between">
              <span class="text-xs font-bold text-foreground uppercase tracking-wider">Notifications</span>
              <button onclick="typeof markAllNotificationsRead === 'function' && markAllNotificationsRead()" class="text-[11px] font-medium text-primary hover:underline">Mark all read</button>
            </div>
            <div class="divide-y divide-slate-100 max-h-64 overflow-y-auto">
              <div class="p-3.5 hover:bg-slate-50 transition-colors flex gap-3 items-start">
                <span class="p-1.5 rounded-lg bg-blue-50 text-blue-600 shrink-0 text-sm">🚀</span>
                <div>
                  <p class="text-xs font-semibold text-slate-800">Workspace Active</p>
                  <p class="text-[11px] text-slate-500 leading-snug mt-0.5">Your organization's Vault streaming modules are unlocked and ready.</p>
                </div>
              </div>
              <div class="p-3.5 hover:bg-slate-50 transition-colors flex gap-3 items-start">
                <span class="p-1.5 rounded-lg bg-emerald-50 text-emerald-600 shrink-0 text-sm">🛡️</span>
                <div>
                  <p class="text-xs font-semibold text-slate-800">Compliance Tracking Live</p>
                  <p class="text-[11px] text-slate-500 leading-snug mt-0.5">Digital sign-off logging and team management are available.</p>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="hidden sm:block h-6 w-px bg-slate-300/80"></div>

        <!-- User Profile Avatar / Profile Modal Trigger -->
        <button id="profile-trigger-btn" type="button" onclick="typeof openProfileModal === 'function' && openProfileModal()" aria-label="Open my account" class="flex items-center gap-2.5 p-1 sm:p-1.5 rounded-xl border border-transparent hover:bg-white hover:border-slate-200 transition-all text-left group" title="My Account">
          <div class="relative w-9 h-9 sm:w-10 sm:h-10 rounded-full bg-slate-200 text-slate-600 font-bold text-xs sm:text-sm flex items-center justify-center overflow-hidden border border-slate-300 shadow-sm shrink-0">
            <span data-dynamic-initials>?</span>
            <img id="userAvatar" data-dynamic-profile-img class="absolute inset-0 w-full h-full object-cover hidden" alt="User Avatar">
          </div>
          <div class="hidden lg:flex flex-col leading-tight">
            <span id="userName" class="text-sm font-bold text-slate-900 group-hover:text-primary transition-colors max-w-[140px] truncate">Loading…</span>
            <span id="topbar-user-role" class="text-xs text-muted max-w-[140px] truncate">Primary Admin</span>
          </div>
          <svg class="hidden lg:block w-4 h-4 text-slate-400 group-hover:text-slate-700 transition-colors" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/></svg>
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

// Global attachment for non-module scripts if accessed via window
if (typeof window !== 'undefined') {
  window.LayoutEngine = LayoutEngine;
}
