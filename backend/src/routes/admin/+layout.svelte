<script lang="ts">
	import { page } from '$app/state';
	import type { LayoutData } from './$types';

	let { data, children } = $props<{ data: LayoutData; children: any }>();

	// Side drawer state
	let isDrawerCollapsed = $state(false);
	let isMobileDrawerOpen = $state(false);

	// AWS Diagnostics modal state
	let isAwsModalOpen = $state(false);
	let isLoadingAwsStatus = $state(false);
	let isSendingTestEmail = $state(false);
	let testEmailResult = $state<any>(null);
	let awsStatusData = $state<any>(null);

	let navSections = $derived([
		{
			title: 'Clinical Operations',
			items: [
				{
					id: 'dashboard',
					label: 'Dashboard',
					description: 'Overview & telemetry',
					icon: 'M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6',
					path: '/admin',
					badge: null,
					badgeClass: ''
				},
				{
					id: 'submissions',
					label: 'Submissions & Triage',
					description: 'Clinical case review & PDF',
					icon: 'M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0a2 2 0 01-2 2H6a2 2 0 01-2-2m16 0l-8 5-8-5',
					path: '/admin/submissions',
					badge: data?.systemCounts?.critical > 0 ? `${data.systemCounts.critical} Critical` : (data?.systemCounts?.pendingTriage > 0 ? `${data.systemCounts.pendingTriage} New` : null),
					badgeClass: data?.systemCounts?.critical > 0 ? 'bg-rose-100 text-rose-700 font-black' : 'bg-amber-100 text-amber-700 font-bold'
				},
				{
					id: 'doctors',
					label: 'Doctors & Clinicians',
					description: 'Practitioner coverage & caseload',
					icon: 'M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7zm7-7v2m0 2v-2m0 0h-2m2 0h2',
					path: '/admin/doctors',
					badge: data?.systemCounts?.doctors > 0 ? `${data.systemCounts.doctors}` : null,
					badgeClass: 'bg-indigo-100 text-indigo-700'
				}
			]
		},
		{
			title: 'Population Health',
			items: [
				{
					id: 'participants',
					label: 'Participants',
					description: 'Directory, profiles & survey reset',
					icon: 'M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z',
					path: '/admin/participants',
					badge: data?.systemCounts?.participants > 0 ? `${data.systemCounts.participants}` : null,
					badgeClass: 'bg-slate-100 text-slate-600'
				},
				{
					id: 'statistics',
					label: 'Analytics & Trends',
					description: 'Drop-off funnel & hotspots',
					icon: 'M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z',
					path: '/admin/statistics',
					badge: null,
					badgeClass: ''
				}
			]
		},
		{
			title: 'System & Governance',
			items: [
				{
					id: 'editor',
					label: 'Survey Editor',
					description: 'Questions, types & scoring logic',
					icon: 'M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4',
					path: '/admin/editor',
					badge: null,
					badgeClass: ''
				},
				{
					id: 'logs',
					label: 'Audit Logs',
					description: 'Security & compliance audit trail',
					icon: 'M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01',
					path: '/admin/logs',
					badge: null,
					badgeClass: ''
				}
			]
		}
	]);

	function isActive(path: string) {
		if (path === '/admin') return page.url.pathname === '/admin';
		return page.url.pathname.startsWith(path);
	}

	async function openAwsDiagnostics() {
		isAwsModalOpen = true;
		isLoadingAwsStatus = true;
		testEmailResult = null;
		try {
			const res = await fetch('/api/system/status');
			if (res.ok) {
				awsStatusData = await res.json();
			} else {
				awsStatusData = { status: 'error', error: 'Failed to fetch status telemetry' };
			}
		} catch (err: any) {
			awsStatusData = { status: 'error', error: err.message };
		} finally {
			isLoadingAwsStatus = false;
		}
	}

	async function runTestEmail() {
		isSendingTestEmail = true;
		testEmailResult = null;
		try {
			const fd = new FormData();
			fd.append('action', 'test-email');
			const res = await fetch('/api/system/status', {
				method: 'POST',
				body: fd
			});
			const result = await res.json();
			testEmailResult = result;
		} catch (e: any) {
			testEmailResult = { success: false, error: e.message };
		} finally {
			isSendingTestEmail = false;
		}
	}
</script>

<div class="flex h-screen w-screen overflow-hidden bg-slate-50 font-sans text-slate-900">
	<!-- ========================================================================= -->
	<!-- 1. DESKTOP SIDE DRAWER (Collapsible between w-64 and w-20)                -->
	<!-- ========================================================================= -->
	<aside
		class="hidden md:flex flex-col border-r border-slate-200 bg-white transition-all duration-300 ease-in-out shrink-0 z-40 select-none {isDrawerCollapsed ? 'w-20' : 'w-64'}"
	>
		<!-- Side Drawer Header -->
		<div class="flex h-16 items-center justify-between border-b border-slate-100 px-4">
			{#if !isDrawerCollapsed}
				<div class="flex items-center gap-3 overflow-hidden">
					<div class="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-gradient-to-tr from-indigo-600 to-indigo-500 text-white shadow-xs">
						<svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
							<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
						</svg>
					</div>
					<div class="flex flex-col">
						<span class="text-xs font-black tracking-wider text-slate-900 uppercase">Novtek ATK</span>
						<span class="text-[9px] font-bold text-slate-400 uppercase tracking-widest">Clinical Admin</span>
					</div>
				</div>
			{:else}
				<div class="mx-auto flex h-9 w-9 items-center justify-center rounded-xl bg-gradient-to-tr from-indigo-600 to-indigo-500 text-white shadow-xs">
					<svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
						<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
					</svg>
				</div>
			{/if}

			<!-- Collapse Toggle Button -->
			<button
				onclick={() => (isDrawerCollapsed = !isDrawerCollapsed)}
				class="rounded-lg p-1.5 text-slate-400 hover:bg-slate-100 hover:text-slate-700 transition-colors cursor-pointer"
				title={isDrawerCollapsed ? 'Expand Side Drawer' : 'Collapse Side Drawer'}
				aria-label="Toggle Side Drawer"
			>
				<svg class="h-4 w-4 transition-transform duration-200 {isDrawerCollapsed ? 'rotate-180' : ''}" fill="none" stroke="currentColor" viewBox="0 0 24 24">
					<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 19l-7-7 7-7m8 14l-7-7 7-7" />
				</svg>
			</button>
		</div>

		<!-- Drawer Navigation List -->
		<div class="flex-1 overflow-y-auto px-3 py-4 space-y-6">
			{#each navSections as section}
				<div>
					{#if !isDrawerCollapsed}
						<p class="px-3 mb-2 text-[10px] font-black tracking-widest text-slate-400 uppercase">
							{section.title}
						</p>
					{:else}
						<div class="mx-auto my-2 h-px w-6 bg-slate-200"></div>
					{/if}

					<nav class="space-y-1">
						{#each section.items as item}
							{@const active = isActive(item.path)}
							<a
								href={item.path}
								class="group relative flex items-center rounded-xl px-3 py-2.5 text-xs font-bold transition-all duration-150 {isDrawerCollapsed ? 'justify-center' : 'justify-between'} {active ? 'bg-indigo-50 text-indigo-700 shadow-xs' : 'text-slate-600 hover:bg-slate-100/70 hover:text-slate-900'}"
								title={isDrawerCollapsed ? item.label : undefined}
							>
								<div class="flex items-center gap-3 min-w-0">
									<svg
										class="h-5 w-5 shrink-0 transition-colors {active ? 'text-indigo-600' : 'text-slate-400 group-hover:text-slate-600'}"
										fill="none"
										stroke="currentColor"
										viewBox="0 0 24 24"
									>
										<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d={item.icon} />
									</svg>
									{#if !isDrawerCollapsed}
										<span class="truncate">{item.label}</span>
									{/if}
								</div>

								{#if !isDrawerCollapsed && item.badge}
									<span class="shrink-0 rounded-full px-2 py-0.5 text-[9px] {item.badgeClass || 'bg-slate-100 text-slate-600'}">
										{item.badge}
									</span>
								{/if}

								<!-- Active Left Glow Marker -->
								{#if active}
									<div class="absolute left-0 top-1.5 bottom-1.5 w-1 rounded-r-full bg-indigo-600"></div>
								{/if}

								<!-- Floating Tooltip when Collapsed -->
								{#if isDrawerCollapsed}
									<div
										class="pointer-events-none absolute left-full ml-3 z-50 rounded-lg bg-slate-900 px-2.5 py-1.5 text-[11px] font-bold text-white shadow-lg whitespace-nowrap opacity-0 group-hover:opacity-100 transition-opacity"
									>
										{item.label}
									</div>
								{/if}
							</a>
						{/each}
					</nav>
				</div>
			{/each}

			<!-- AWS Cloud & System Health Action in Drawer -->
			<div class="pt-2">
				{#if !isDrawerCollapsed}
					<p class="px-3 mb-2 text-[10px] font-black tracking-widest text-slate-400 uppercase">
						Cloud Infrastructure
					</p>
				{/if}
				<button
					onclick={openAwsDiagnostics}
					class="w-full group relative flex items-center rounded-xl px-3 py-2.5 text-xs font-bold transition-all text-slate-600 hover:bg-indigo-50 hover:text-indigo-700 cursor-pointer {isDrawerCollapsed ? 'justify-center' : 'justify-between'}"
					title="AWS Cloud & Database Health Diagnostics"
				>
					<div class="flex items-center gap-3">
						<div class="relative flex h-5 w-5 shrink-0 items-center justify-center">
							<svg class="h-5 w-5 text-indigo-500 group-hover:text-indigo-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
								<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 15a4 4 0 004 4h9a5 5 0 10-.1-9.999 5.002 5.002 0 00-9.78 2.096A4.001 4.001 0 003 15z" />
							</svg>
							<span class="absolute -top-0.5 -right-0.5 flex h-2 w-2">
								<span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
								<span class="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
							</span>
						</div>
						{#if !isDrawerCollapsed}
							<div class="flex flex-col text-left">
								<span>AWS & Cloud Health</span>
								<span class="text-[9px] font-normal text-slate-400">RDS & SES Diagnostic</span>
							</div>
						{/if}
					</div>

					{#if !isDrawerCollapsed}
						<span class="rounded-full bg-emerald-50 border border-emerald-200 px-2 py-0.5 text-[9px] font-black text-emerald-700">
							Online
						</span>
					{/if}

					{#if isDrawerCollapsed}
						<div
							class="pointer-events-none absolute left-full ml-3 z-50 rounded-lg bg-slate-900 px-2.5 py-1.5 text-[11px] font-bold text-white shadow-lg whitespace-nowrap opacity-0 group-hover:opacity-100 transition-opacity"
						>
							AWS & Cloud Diagnostics
						</div>
					{/if}
				</button>
			</div>
		</div>

		<!-- Drawer Footer (User & Logout) -->
		<div class="border-t border-slate-100 p-3 bg-slate-50/50">
			{#if !isDrawerCollapsed}
				<div class="flex items-center justify-between gap-3">
					<div class="flex items-center gap-2.5 min-w-0">
						<div class="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-slate-200 text-slate-600 text-xs font-black">
							SA
						</div>
						<div class="flex flex-col min-w-0">
							<span class="truncate text-xs font-bold text-slate-800">Super Admin</span>
							<span class="truncate text-[9px] font-medium text-slate-400">{data?.systemEnv?.provider || 'Connected'}</span>
						</div>
					</div>

					<form method="POST" action="/admin-login?/logout">
						<button
							type="submit"
							class="rounded-lg p-2 text-slate-400 hover:bg-rose-50 hover:text-rose-600 transition-colors cursor-pointer"
							title="Sign Out"
							aria-label="Sign Out"
						>
							<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
								<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
							</svg>
						</button>
					</form>
				</div>
			{:else}
				<div class="flex flex-col items-center gap-2">
					<form method="POST" action="/admin-login?/logout">
						<button
							type="submit"
							class="flex h-9 w-9 items-center justify-center rounded-lg text-slate-400 hover:bg-rose-50 hover:text-rose-600 transition-colors cursor-pointer"
							title="Sign Out"
							aria-label="Sign Out"
						>
							<svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
								<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
							</svg>
						</button>
					</form>
				</div>
			{/if}
		</div>
	</aside>

	<!-- ========================================================================= -->
	<!-- 2. MOBILE SLIDE-OUT DRAWER OVERLAY (Screens < md)                         -->
	<!-- ========================================================================= -->
	{#if isMobileDrawerOpen}
		<div class="fixed inset-0 z-50 flex md:hidden" role="dialog" aria-modal="true">
			<!-- Dark Backdrop -->
			<button
				type="button"
				onclick={() => (isMobileDrawerOpen = false)}
				class="fixed inset-0 bg-slate-900/60 backdrop-blur-xs transition-opacity cursor-pointer border-none"
				aria-label="Close Mobile Drawer"
			></button>

			<!-- Slide-in Drawer Container -->
			<div class="relative flex w-72 max-w-[85vw] flex-1 flex-col bg-white shadow-2xl transition-transform duration-300">
				<!-- Header -->
				<div class="flex h-16 items-center justify-between border-b border-slate-100 px-5">
					<div class="flex items-center gap-3">
						<div class="flex h-9 w-9 items-center justify-center rounded-xl bg-indigo-600 text-white shadow-xs">
							<svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
								<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
							</svg>
						</div>
						<div class="flex flex-col">
							<span class="text-xs font-black tracking-wider text-slate-900 uppercase">Novtek ATK</span>
							<span class="text-[9px] font-bold text-slate-400 uppercase tracking-widest">Clinical Admin</span>
						</div>
					</div>

					<button
						onclick={() => (isMobileDrawerOpen = false)}
						class="rounded-lg p-2 text-slate-400 hover:bg-slate-100 hover:text-slate-700 cursor-pointer"
						aria-label="Close Drawer"
					>
						<svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
							<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
						</svg>
					</button>
				</div>

				<!-- Mobile Navigation List -->
				<div class="flex-1 overflow-y-auto px-4 py-5 space-y-6">
					{#each navSections as section}
						<div>
							<p class="px-3 mb-2 text-[10px] font-black tracking-widest text-slate-400 uppercase">
								{section.title}
							</p>
							<nav class="space-y-1">
								{#each section.items as item}
									{@const active = isActive(item.path)}
									<a
										href={item.path}
										onclick={() => (isMobileDrawerOpen = false)}
										class="flex items-center justify-between rounded-xl px-3 py-2.5 text-xs font-bold transition-all {active ? 'bg-indigo-50 text-indigo-700' : 'text-slate-600 hover:bg-slate-50 hover:text-slate-900'}"
									>
										<div class="flex items-center gap-3">
											<svg class="h-5 w-5 {active ? 'text-indigo-600' : 'text-slate-400'}" fill="none" stroke="currentColor" viewBox="0 0 24 24">
												<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d={item.icon} />
											</svg>
											<span>{item.label}</span>
										</div>
										{#if item.badge}
											<span class="rounded-full px-2 py-0.5 text-[9px] {item.badgeClass || 'bg-slate-100 text-slate-600'}">
												{item.badge}
											</span>
										{/if}
									</a>
								{/each}
							</nav>
						</div>
					{/each}

					<!-- Cloud Diagnostics Button -->
					<div class="pt-2">
						<button
							onclick={() => { isMobileDrawerOpen = false; openAwsDiagnostics(); }}
							class="w-full flex items-center justify-between rounded-xl px-3 py-2.5 text-xs font-bold text-slate-600 bg-slate-50 hover:bg-indigo-50 hover:text-indigo-700 cursor-pointer"
						>
							<div class="flex items-center gap-3">
								<svg class="h-5 w-5 text-indigo-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
									<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 15a4 4 0 004 4h9a5 5 0 10-.1-9.999 5.002 5.002 0 00-9.78 2.096A4.001 4.001 0 003 15z" />
								</svg>
								<span>AWS & Cloud Health</span>
							</div>
							<span class="rounded-full bg-emerald-100 text-emerald-800 text-[9px] font-black px-2 py-0.5">Online</span>
						</button>
					</div>
				</div>

				<!-- Mobile Footer -->
				<div class="border-t border-slate-100 p-4 bg-slate-50 flex items-center justify-between">
					<div class="flex items-center gap-2.5">
						<div class="flex h-8 w-8 items-center justify-center rounded-lg bg-indigo-100 text-indigo-700 text-xs font-black">
							SA
						</div>
						<div class="flex flex-col">
							<span class="text-xs font-bold text-slate-800">Super Admin</span>
							<span class="text-[9px] text-slate-400">Authenticated Session</span>
						</div>
					</div>

					<form method="POST" action="/admin-login?/logout">
						<button
							type="submit"
							class="rounded-lg p-2 text-rose-600 hover:bg-rose-50 cursor-pointer"
							title="Sign Out"
						>
							<svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
								<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
							</svg>
						</button>
					</form>
				</div>
			</div>
		</div>
	{/if}

	<!-- ========================================================================= -->
	<!-- 3. MAIN CONTENT AREA                                                      -->
	<!-- ========================================================================= -->
	<main class="relative flex h-full min-w-0 flex-1 flex-col bg-slate-50 overflow-hidden">
		<!-- Top Navigation Header -->
		<header class="flex h-16 shrink-0 items-center justify-between border-b border-slate-200 bg-white px-6 md:px-8 z-20">
			<div class="flex items-center gap-4">
				<!-- Hamburger Button (Mobile Only) -->
				<button
					onclick={() => (isMobileDrawerOpen = true)}
					class="md:hidden rounded-lg p-2 text-slate-500 hover:bg-slate-100 hover:text-slate-800 cursor-pointer"
					aria-label="Open Navigation Drawer"
				>
					<svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
						<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
					</svg>
				</button>

				<!-- Current Section Breadcrumb -->
				<div class="flex items-center gap-3">
					<div class="flex h-7 w-7 items-center justify-center rounded-lg bg-indigo-50 text-indigo-600">
						<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
							<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
						</svg>
					</div>
					<div>
						<h1 class="text-sm font-black tracking-tight text-slate-800">
							{#if isActive('/admin/editor')}
								Survey Editor & Protocol Logic
							{:else if isActive('/admin/submissions')}
								Clinical Submissions & Triage
							{:else if isActive('/admin/participants')}
								Participant Directory & Care
							{:else if isActive('/admin/doctors')}
								Doctors & Clinician Coverage
							{:else if isActive('/admin/statistics')}
								Analytics, Funnel & Hotspots
							{:else if isActive('/admin/logs')}
								System Audit & Security Logs
							{:else}
								Clinical Command Dashboard
							{/if}
						</h1>
					</div>
				</div>
			</div>

			<!-- Header Right Actions: AWS Status & Admin Menu -->
			<div class="flex items-center gap-3">
				<!-- AWS Cloud Status Pill -->
				<button
					onclick={openAwsDiagnostics}
					class="hidden sm:flex items-center gap-2 rounded-full border border-emerald-200 bg-emerald-50/70 hover:bg-emerald-100/80 px-3 py-1.5 text-[11px] font-bold text-emerald-800 transition-colors cursor-pointer shadow-2xs"
					title="Click to inspect AWS Cloud, RDS & SES Health"
				>
					<span class="flex h-2 w-2 relative">
						<span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
						<span class="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
					</span>
					<span>AWS Cloud: {data?.systemEnv?.isAws ? 'RDS Active' : 'Live'}</span>
				</button>

				<!-- User Profile & Logout -->
				<div class="flex items-center gap-3 pl-2 border-l border-slate-100">
					<div class="hidden sm:block text-right">
						<p class="text-xs font-bold text-slate-800 leading-tight">Super Admin</p>
						<p class="text-[9px] font-medium text-slate-400">Clinical Oversight</p>
					</div>

					<form method="POST" action="/admin-login?/logout">
						<button
							type="submit"
							class="flex h-9 w-9 items-center justify-center rounded-xl border border-slate-200 bg-white text-slate-500 hover:border-rose-200 hover:bg-rose-50 hover:text-rose-600 transition-all cursor-pointer shadow-2xs"
							title="Sign Out"
							aria-label="Sign Out"
						>
							<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
								<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
							</svg>
						</button>
					</form>
				</div>
			</div>
		</header>

		<!-- Main Scrollable Page Outlet -->
		<div class="relative flex-1 overflow-y-auto">
			{@render children()}
		</div>
	</main>
</div>

<!-- ========================================================================= -->
<!-- 4. AWS & SYSTEM STATUS DIAGNOSTICS MODAL                                   -->
<!-- ========================================================================= -->
{#if isAwsModalOpen}
	<div class="fixed inset-0 z-50 flex items-center justify-center p-4" role="dialog" aria-modal="true">
		<!-- Backdrop -->
		<button
			type="button"
			onclick={() => (isAwsModalOpen = false)}
			class="fixed inset-0 bg-slate-900/60 backdrop-blur-xs transition-opacity cursor-pointer border-none"
			aria-label="Close Diagnostics"
		></button>

		<!-- Modal Container -->
		<div class="relative w-full max-w-2xl rounded-2xl bg-white shadow-2xl border border-slate-200 overflow-hidden flex flex-col max-h-[90vh]">
			<!-- Modal Header -->
			<div class="flex items-center justify-between border-b border-slate-100 bg-slate-50/70 px-6 py-4">
				<div class="flex items-center gap-3">
					<div class="flex h-9 w-9 items-center justify-center rounded-xl bg-indigo-600 text-white shadow-xs">
						<svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
							<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 15a4 4 0 004 4h9a5 5 0 10-.1-9.999 5.002 5.002 0 00-9.78 2.096A4.001 4.001 0 003 15z" />
						</svg>
					</div>
					<div>
						<h2 class="text-sm font-black text-slate-900 uppercase tracking-wide">AWS Cloud & System Diagnostics</h2>
						<p class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Infrastructure Health & Email Verification</p>
					</div>
				</div>

				<button
					onclick={() => (isAwsModalOpen = false)}
					class="rounded-lg p-1.5 text-slate-400 hover:bg-slate-200 hover:text-slate-700 cursor-pointer"
					aria-label="Close"
				>
					<svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
						<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
					</svg>
				</button>
			</div>

			<!-- Modal Body -->
			<div class="flex-1 overflow-y-auto p-6 space-y-6">
				{#if isLoadingAwsStatus}
					<div class="flex h-64 flex-col items-center justify-center space-y-3">
						<div class="h-8 w-8 animate-spin rounded-full border-3 border-indigo-600 border-t-transparent"></div>
						<p class="text-xs font-bold text-slate-500">Querying AWS RDS, SES and telemetry endpoints...</p>
					</div>
				{:else if awsStatusData}
					<!-- Status Cards Grid -->
					<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
						<!-- 1. Database Connection Card -->
						<div class="rounded-xl border border-slate-200 bg-white p-4 shadow-2xs space-y-2">
							<div class="flex items-center justify-between">
								<span class="text-[10px] font-black uppercase tracking-wider text-slate-400">Database Engine</span>
								<span class="rounded-full px-2 py-0.5 text-[9px] font-black uppercase {awsStatusData.db?.connected ? 'bg-emerald-100 text-emerald-800' : 'bg-rose-100 text-rose-800'}">
									{awsStatusData.db?.connected ? 'Connected' : 'Disconnected'}
								</span>
							</div>
							<div class="flex items-baseline gap-2">
								<p class="text-base font-black text-slate-800">{awsStatusData.db?.provider}</p>
								{#if awsStatusData.db?.latencyMs >= 0}
									<span class="text-xs font-bold text-emerald-600">({awsStatusData.db.latencyMs}ms)</span>
								{/if}
							</div>
							<p class="text-[11px] font-mono text-slate-500 break-all bg-slate-50 p-2 rounded-lg border border-slate-100">
								{awsStatusData.db?.endpoint}
							</p>
						</div>

						<!-- 2. AWS SES Email Card -->
						<div class="rounded-xl border border-slate-200 bg-white p-4 shadow-2xs space-y-2">
							<div class="flex items-center justify-between">
								<span class="text-[10px] font-black uppercase tracking-wider text-slate-400">Email Gateway (SES)</span>
								<span class="rounded-full px-2 py-0.5 text-[9px] font-black uppercase {awsStatusData.aws?.sesConfigured ? 'bg-indigo-100 text-indigo-800' : 'bg-amber-100 text-amber-800'}">
									{awsStatusData.aws?.sesConfigured ? 'Configured' : 'Needs Config'}
								</span>
							</div>
							<p class="text-base font-black text-slate-800">{awsStatusData.aws?.sesHost}</p>
							<div class="text-[11px] text-slate-500 space-y-1">
								<p><span class="font-bold text-slate-600">Sender:</span> {awsStatusData.aws?.senderAddress}</p>
								<p><span class="font-bold text-slate-600">Alert Recipient:</span> {awsStatusData.aws?.alertRecipient}</p>
							</div>
						</div>

						<!-- 3. Server Telemetry -->
						<div class="rounded-xl border border-slate-200 bg-white p-4 shadow-2xs space-y-2">
							<span class="text-[10px] font-black uppercase tracking-wider text-slate-400">Container Telemetry</span>
							<div class="grid grid-cols-2 gap-2 text-xs pt-1">
								<div>
									<span class="text-slate-400 text-[10px] uppercase font-bold block">Uptime</span>
									<span class="font-bold text-slate-700">{awsStatusData.system?.uptimeFormatted}</span>
								</div>
								<div>
									<span class="text-slate-400 text-[10px] uppercase font-bold block">Runtime</span>
									<span class="font-bold text-slate-700">Node {awsStatusData.system?.nodeVersion}</span>
								</div>
								<div>
									<span class="text-slate-400 text-[10px] uppercase font-bold block">Memory Heap</span>
									<span class="font-bold text-slate-700">{awsStatusData.system?.memoryMb?.heapUsed} MB / {awsStatusData.system?.memoryMb?.heapTotal} MB</span>
								</div>
								<div>
									<span class="text-slate-400 text-[10px] uppercase font-bold block">Environment</span>
									<span class="font-bold text-slate-700 uppercase">{awsStatusData.system?.environment}</span>
								</div>
							</div>
						</div>

						<!-- 4. Clinical Metrics Summary -->
						<div class="rounded-xl border border-slate-200 bg-white p-4 shadow-2xs space-y-2">
							<span class="text-[10px] font-black uppercase tracking-wider text-slate-400">Database Record Totals</span>
							<div class="grid grid-cols-2 gap-2 text-xs pt-1">
								<div>
									<span class="text-slate-400 text-[10px] uppercase font-bold block">Submissions</span>
									<span class="font-bold text-slate-700">{awsStatusData.metrics?.totalSubmissions}</span>
								</div>
								<div>
									<span class="text-slate-400 text-[10px] uppercase font-bold block">Critical Risk</span>
									<span class="font-bold text-rose-600">{awsStatusData.metrics?.criticalSubmissions}</span>
								</div>
								<div>
									<span class="text-slate-400 text-[10px] uppercase font-bold block">Participants</span>
									<span class="font-bold text-slate-700">{awsStatusData.metrics?.totalUsers}</span>
								</div>
								<div>
									<span class="text-slate-400 text-[10px] uppercase font-bold block">Doctors</span>
									<span class="font-bold text-slate-700">{awsStatusData.metrics?.totalDoctors}</span>
								</div>
							</div>
						</div>
					</div>

					<!-- Test AWS SES Email Trigger -->
					<div class="rounded-xl border border-indigo-100 bg-indigo-50/50 p-4 space-y-3">
						<div class="flex items-center justify-between">
							<div>
								<h3 class="text-xs font-black uppercase tracking-wider text-indigo-950">Verify AWS SES Email Delivery</h3>
								<p class="text-[11px] text-indigo-700">Dispatches a live test verification email to {awsStatusData.aws?.alertRecipient}</p>
							</div>
							<button
								onclick={runTestEmail}
								disabled={isSendingTestEmail}
								class="rounded-lg bg-indigo-600 px-3.5 py-2 text-xs font-bold text-white hover:bg-indigo-700 transition-colors disabled:opacity-50 cursor-pointer shadow-xs"
							>
								{isSendingTestEmail ? 'Sending...' : 'Send Test Alert'}
							</button>
						</div>

						{#if testEmailResult}
							{#if testEmailResult.success}
								<div class="rounded-lg bg-emerald-100 border border-emerald-200 p-3 text-xs text-emerald-800 font-medium">
									✅ Test email successfully delivered via AWS SES in {testEmailResult.durationMs}ms! (Message ID: {testEmailResult.messageId})
								</div>
							{:else}
								<div class="rounded-lg bg-rose-100 border border-rose-200 p-3 text-xs text-rose-800 font-medium">
									❌ Email dispatch test failed: {testEmailResult.error}
								</div>
							{/if}
						{/if}
					</div>
				{/if}
			</div>

			<!-- Modal Footer -->
			<div class="flex items-center justify-between border-t border-slate-100 bg-slate-50 px-6 py-3">
				<span class="text-[11px] text-slate-500 font-medium">AWS Region: {awsStatusData?.aws?.region || 'eu-west-2'}</span>
				<div class="flex items-center gap-2">
					<button
						onclick={openAwsDiagnostics}
						disabled={isLoadingAwsStatus}
						class="rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-xs font-bold text-slate-700 hover:bg-slate-100 cursor-pointer"
					>
						Refresh
					</button>
					<button
						onclick={() => (isAwsModalOpen = false)}
						class="rounded-lg bg-slate-900 px-3.5 py-1.5 text-xs font-bold text-white hover:bg-slate-800 cursor-pointer"
					>
						Close
					</button>
				</div>
			</div>
		</div>
	</div>
{/if}
