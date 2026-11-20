<script lang="ts">
	import type { PageData } from './$types';
	import { page } from '$app/state';
	let { data } = $props<{ data: PageData }>();

	let currentCategory = $derived(page.url.searchParams.get('surveyCategory') || page.url.searchParams.get('category') || '');
</script>

<div class="h-full space-y-8 overflow-y-auto bg-slate-50/30 p-8">
	<!-- Page Header & Filter -->
	<div class="flex items-end justify-between">
		<div>
			<h1 class="text-2xl font-black tracking-tighter text-slate-900 uppercase">Dashboard</h1>
			<p class="text-[10px] font-bold tracking-widest text-slate-400 uppercase">System Analytics Overview</p>
		</div>

		<div class="flex gap-1 rounded-xl bg-slate-200/50 p-1">
			<a 
				href="/admin" 
				class="rounded-lg px-4 py-2 text-[10px] font-black uppercase transition-all {!currentCategory ? 'bg-white text-slate-900 shadow-sm' : 'text-slate-500 hover:text-slate-700'}"
			>
				All Paths
			</a>
			<a 
				href="/admin?surveyCategory=ADDICTION" 
				class="rounded-lg px-4 py-2 text-[10px] font-black uppercase transition-all {currentCategory === 'ADDICTION' ? 'bg-indigo-600 text-white shadow-sm' : 'text-slate-500 hover:text-slate-700'}"
			>
				Addiction
			</a>
			<a 
				href="/admin?surveyCategory=MENTAL" 
				class="rounded-lg px-4 py-2 text-[10px] font-black uppercase transition-all {currentCategory === 'MENTAL' ? 'bg-purple-600 text-white shadow-sm' : 'text-slate-500 hover:text-slate-700'}"
			>
				Mental Health
			</a>
		</div>
	</div>
	<div class="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-5">
		<!-- 1. Total Registered Users -->
		<div
			class="rounded-[12px] border border-slate-200 bg-white p-6 shadow-sm transition-all hover:shadow-md"
		>
			<div class="mb-4 flex items-center gap-3">
				<div class="rounded-lg bg-indigo-50 p-2 text-indigo-600">
					<svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"
						><path
							stroke-linecap="round"
							stroke-linejoin="round"
							stroke-width="2"
							d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"
						/></svg
					>
				</div>
				<p class="text-[10px] font-black tracking-widest text-slate-400 uppercase">
					Registered Users
				</p>
			</div>
			<div class="flex items-baseline gap-2">
				<h3 class="text-3xl leading-none font-black text-slate-900">
					{data.stats.totalRegistered}
				</h3>
				<span class="text-[10px] font-bold tracking-tighter text-slate-400 uppercase"
					>Profile Completed</span
				>
			</div>
			<div class="mt-4 h-1.5 overflow-hidden rounded-full bg-slate-100">
				<div
					class="h-full rounded-full bg-indigo-500 transition-all"
					style="width: {(data.stats.totalRegistered / Math.max(1, data.stats.totalUsers)) * 100}%"
				></div>
			</div>
		</div>

		<!-- 2. Completed Stage 2 -->
		<div
			class="rounded-[12px] border border-slate-200 bg-white p-6 shadow-sm transition-all hover:shadow-md"
		>
			<div class="mb-4 flex items-center gap-3">
				<div class="rounded-lg bg-emerald-50 p-2 text-emerald-600">
					<svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"
						><path
							stroke-linecap="round"
							stroke-linejoin="round"
							stroke-width="2"
							d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
						/></svg
					>
				</div>
				<p class="text-[10px] font-black tracking-widest text-slate-400 uppercase">
					Stage 2 Completed
				</p>
			</div>
			<div class="flex items-baseline gap-2">
				<h3 class="text-3xl leading-none font-black text-slate-900">{data.stats.totalStage2}</h3>
				<span class="text-[10px] font-bold tracking-tighter text-slate-400 uppercase"
					>Initial Survey</span
				>
			</div>
			<p class="mt-4 text-[10px] font-bold text-slate-500">
				{Math.round((data.stats.totalStage2 / Math.max(1, data.stats.totalRegistered)) * 100)}%
				Conversion from Registration
			</p>
		</div>

		<!-- 3. Unlocked Stage 3 -->
		<div
			class="rounded-[12px] border border-slate-200 bg-white p-6 shadow-sm transition-all hover:shadow-md"
		>
			<div class="mb-4 flex items-center gap-3">
				<div class="rounded-lg bg-purple-50 p-2 text-purple-600">
					<svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"
						><path
							stroke-linecap="round"
							stroke-linejoin="round"
							stroke-width="2"
							d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
						/></svg
					>
				</div>
				<p class="text-[10px] font-black tracking-widest text-slate-400 uppercase">
					Stage 3 Unlocked
				</p>
			</div>
			<div class="flex items-baseline gap-2">
				<h3 class="text-3xl leading-none font-black text-purple-600">
					{data.stats.totalStage3Unlocked}
				</h3>
				<span class="text-[10px] font-bold tracking-tighter text-slate-400 uppercase"
					>Detailed Survey</span
				>
			</div>
			<p class="mt-4 text-[10px] font-bold text-slate-500">
				{Math.round((data.stats.totalStage3Unlocked / Math.max(1, data.stats.totalStage2)) * 100)}%
				Qualification Rate
			</p>
		</div>

		<!-- 4. Submissions Breakdown -->
		<div
			class="flex flex-col justify-between rounded-[12px] border border-slate-200 bg-white p-6 shadow-sm transition-all hover:shadow-md"
		>
			<p class="mb-4 text-[10px] font-black tracking-widest text-slate-400 uppercase">
				Total Submissions
			</p>
			<div class="space-y-3">
				<div class="flex items-center justify-between rounded-lg bg-indigo-50/50 px-3 py-2">
					<span class="text-[9px] font-black text-indigo-700 uppercase">Stage 2</span>
					<span class="text-sm font-black text-indigo-900">{data.stats.initialSubmissions}</span>
				</div>
				<div class="flex items-center justify-between rounded-lg bg-purple-50/50 px-3 py-2">
					<span class="text-[9px] font-black text-purple-700 uppercase">Stage 3</span>
					<span class="text-sm font-black text-purple-900">{data.stats.detailedSubmissions}</span>
				</div>
			</div>
		</div>

		<!-- 5. Active Users -->
		<div
			class="flex flex-col justify-between rounded-[12px] border border-slate-200 bg-white p-6 shadow-sm transition-all hover:shadow-md"
		>
			<p class="mb-4 text-[10px] font-black tracking-widest text-slate-400 uppercase">
				Active Users
			</p>
			<div class="grid grid-cols-2 gap-4">
				<div>
					<h4 class="text-xl font-black text-slate-900">{data.stats.active7d}</h4>
					<p class="text-[8px] font-bold text-slate-400 uppercase">Last 7D</p>
				</div>
				<div class="border-l border-slate-100 pl-4">
					<h4 class="text-xl font-black text-slate-900">{data.stats.active30d}</h4>
					<p class="text-[8px] font-bold text-slate-400 uppercase">Last 30D</p>
				</div>
			</div>
			<div class="mt-4 flex items-center gap-1">
				<div class="h-1.5 w-1.5 rounded-full bg-emerald-500"></div>
				<span class="text-[9px] font-bold text-slate-400 uppercase">Tracking Live</span>
			</div>
		</div>
	</div>

	<!-- Clinical Command Shortcuts -->
	<div class="grid grid-cols-1 md:grid-cols-3 gap-6">
		<a
			href="/admin/submissions?risk=critical"
			class="flex items-center justify-between rounded-[12px] border border-red-100 bg-red-50/40 p-4 transition-all hover:bg-red-50 hover:border-red-200 group"
		>
			<div class="flex items-center gap-3">
				<div class="flex h-10 w-10 items-center justify-center rounded-lg bg-red-100 text-red-600 text-lg">
					🚨
				</div>
				<div>
					<p class="text-[10px] font-black uppercase tracking-wider text-red-700">Critical Risk Cases</p>
					<p class="text-xs font-bold text-slate-700">{data.stats.criticalAlerts} Submissions Flagged</p>
				</div>
			</div>
			<span class="text-xs font-black text-red-600 group-hover:translate-x-1 transition-transform">&rarr;</span>
		</a>

		<a
			href="/admin/doctors"
			class="flex items-center justify-between rounded-[12px] border border-indigo-100 bg-indigo-50/30 p-4 transition-all hover:bg-indigo-50 hover:border-indigo-200 group"
		>
			<div class="flex items-center gap-3">
				<div class="flex h-10 w-10 items-center justify-center rounded-lg bg-indigo-100 text-indigo-600 text-lg">
					🩺
				</div>
				<div>
					<p class="text-[10px] font-black uppercase tracking-wider text-indigo-700">Clinician Coverage</p>
					<p class="text-xs font-bold text-slate-700">{data.stats.totalDoctors} Active Practitioners</p>
				</div>
			</div>
			<span class="text-xs font-black text-indigo-600 group-hover:translate-x-1 transition-transform">&rarr;</span>
		</a>

		<a
			href="/admin/statistics"
			class="flex items-center justify-between rounded-[12px] border border-slate-200 bg-white p-4 transition-all hover:border-slate-300 hover:shadow-xs group"
		>
			<div class="flex items-center gap-3">
				<div class="flex h-10 w-10 items-center justify-center rounded-lg bg-slate-100 text-slate-700 text-lg">
					📊
				</div>
				<div>
					<p class="text-[10px] font-black uppercase tracking-wider text-slate-700">Funnel & Geographic Mapping</p>
					<p class="text-xs font-bold text-slate-500">Cohort drop-off & hotspot analytics</p>
				</div>
			</div>
			<span class="text-xs font-black text-slate-400 group-hover:translate-x-1 transition-transform">&rarr;</span>
		</a>
	</div>

	<div class="grid grid-cols-1 items-start gap-8 lg:grid-cols-12">
		<!-- Age Group Segmentation -->
		<div
			class="rounded-[12px] border border-slate-200 bg-white p-6 shadow-sm transition-all hover:shadow-md lg:col-span-4"
		>
			<h3 class="mb-6 text-[10px] font-black tracking-widest text-slate-400 uppercase">
				Age Group Distribution
			</h3>
			<div class="space-y-4">
				{#each data.segmentation.age as group}
					{@const p = (group.value / Math.max(1, data.stats.totalRegistered)) * 100}
					<div class="space-y-1.5">
						<div class="flex justify-between text-[10px] font-black uppercase">
							<span class="text-slate-600">{group.label}</span>
							<span class="text-indigo-600">{group.value}</span>
						</div>
						<div class="h-1.5 overflow-hidden rounded-full bg-slate-50">
							<div
								class="h-full rounded-full bg-indigo-500 transition-all duration-1000"
								style="width: {p}%"
							></div>
						</div>
					</div>
				{/each}
			</div>
		</div>

		<!-- Gender Segmentation -->
		<div
			class="rounded-[12px] border border-slate-200 bg-white p-6 shadow-sm transition-all hover:shadow-md lg:col-span-4"
		>
			<h3 class="mb-6 text-[10px] font-black tracking-widest text-slate-400 uppercase">
				Gender Identity
			</h3>
			<div class="space-y-4">
				{#each data.segmentation.gender as group}
					{@const p = (group.value / Math.max(1, data.stats.totalRegistered)) * 100}
					<div class="space-y-1.5">
						<div class="flex justify-between text-[10px] font-black uppercase">
							<span class="text-slate-600">{group.label}</span>
							<span class="text-indigo-600">{group.value}</span>
						</div>
						<div class="h-1.5 overflow-hidden rounded-full bg-slate-50">
							<div
								class="h-full rounded-full bg-indigo-400 transition-all duration-1000"
								style="width: {p}%"
							></div>
						</div>
					</div>
				{/each}
			</div>
		</div>

		<!-- Marital Status Segmentation -->
		<div
			class="rounded-[12px] border border-slate-200 bg-white p-6 shadow-sm transition-all hover:shadow-md lg:col-span-4"
		>
			<h3 class="mb-6 text-[10px] font-black tracking-widest text-slate-400 uppercase">
				Marital Status
			</h3>
			<div class="space-y-4">
				{#each data.segmentation.marital as group}
					{@const p = (group.value / Math.max(1, data.stats.totalRegistered)) * 100}
					<div class="space-y-1.5">
						<div class="flex justify-between text-[10px] font-black uppercase">
							<span class="text-slate-600">{group.label}</span>
							<span class="text-indigo-600">{group.value}</span>
						</div>
						<div class="h-1.5 overflow-hidden rounded-full bg-slate-50">
							<div
								class="h-full rounded-full bg-indigo-300 transition-all duration-1000"
								style="width: {p}%"
							></div>
						</div>
					</div>
				{/each}
			</div>
		</div>
	</div>

	<!-- Submission Volume Trend Section -->
	<div
		class="rounded-[12px] border border-slate-200 bg-white p-8 shadow-sm transition-all hover:shadow-md"
	>
		<div class="mb-6 flex items-center justify-between">
			<div>
				<h2 class="text-sm font-black tracking-tighter text-slate-900 uppercase">
					Submission Volume Trend
				</h2>
				<p class="mt-1 text-[10px] font-bold tracking-widest text-slate-400 uppercase">
					14-Day Performance Tracking
				</p>
			</div>
			<div class="flex items-center gap-2">
				<span class="h-2 w-2 rounded-full bg-indigo-500"></span>
				<span class="text-[9px] font-black text-slate-400 uppercase">Completed Surveys</span>
			</div>
		</div>
		<div class="flex h-32 w-full items-end gap-2 px-2">
			{#each data.dailyTrend as point}
				{@const height =
					Math.max(...data.dailyTrend.map((d: any) => d.count), 0) > 0
						? (point.count / Math.max(...data.dailyTrend.map((d: any) => d.count), 1)) * 100
						: 2}
				<div
					class="group relative flex-1 cursor-help rounded-t-[4px] bg-indigo-500/10 transition-all hover:bg-indigo-500"
					style="height: {height}%"
				>
					<div
						class="pointer-events-none absolute bottom-full left-1/2 z-20 mb-2 -translate-x-1/2 rounded bg-slate-900 px-3 py-1.5 text-[10px] font-black whitespace-nowrap text-white opacity-0 transition-all group-hover:opacity-100"
					>
						{point.date}: <span class="text-indigo-400">{point.count}</span>
					</div>
				</div>
			{/each}
		</div>
		<div class="mt-4 flex justify-between px-2">
			{#each data.dailyTrend.filter((_: any, i: number) => i % 2 === 0) as point}
				<span class="text-[9px] font-bold text-slate-400 uppercase">{point.date}</span>
			{/each}
		</div>
	</div>

	<div class="grid grid-cols-1 gap-8 lg:grid-cols-12">
		<div
			class="flex flex-col rounded-[12px] border border-slate-200 bg-white shadow-sm lg:col-span-4"
		>
			<div class="flex items-center justify-between border-b border-slate-100 px-6 py-4">
				<h2 class="text-sm font-black tracking-tighter text-slate-900 uppercase">
					Recent Activity
				</h2>
				<a
					href="/admin/participants"
					class="text-[9px] font-black tracking-widest text-slate-400 uppercase transition-colors hover:text-slate-900"
					>Full List</a
				>
			</div>
			<div class="divide-y divide-slate-50 overflow-y-auto">
				{#each data.recentUsers.slice(0, 8) as user}
					<div class="flex items-center justify-between p-4 transition-colors hover:bg-slate-50/50">
						<div class="flex items-center gap-3">
							<div
								class="flex h-8 w-8 items-center justify-center rounded-lg bg-slate-100 text-[10px] font-black text-slate-400 uppercase"
							>
								{user.email[0]}
							</div>
							<div class="flex min-w-0 flex-col">
								<span class="max-w-[140px] truncate text-xs font-bold text-slate-700"
									>{user.email}</span
								>
								<div class="mt-0.5 flex items-center gap-1.5">
									<span
										class="text-[8px] font-black {user.isProfileComplete
											? 'text-emerald-500'
											: 'text-amber-500'} uppercase"
									>
										{user.isProfileComplete ? 'REGISTERED' : 'OTP ONLY'}
									</span>
								</div>
							</div>
						</div>
						<div class="text-right whitespace-nowrap">
							<p class="text-[10px] leading-none font-black text-slate-900">
								{new Date(user.lastActivity).toLocaleDateString([], {
									month: 'short',
									day: 'numeric'
								})}
							</p>
							<p class="mt-1 text-[8px] font-bold text-slate-400 uppercase">
								{new Date(user.lastActivity).toLocaleTimeString([], {
									hour: '2-digit',
									minute: '2-digit'
								})}
							</p>
						</div>
					</div>
				{/each}
			</div>
		</div>
	</div>

	<!-- System Status Footer -->
	<div
		class="flex items-center justify-between rounded-[12px] border border-slate-200 bg-white p-6"
	>
		<div class="flex items-center gap-8 divide-x divide-slate-100">
			<div class="pr-8">
				<p class="text-[8px] font-black tracking-widest text-slate-400 uppercase">
					Protocol Latency
				</p>
				<p class="text-lg font-black text-slate-900 italic">0.82ms</p>
			</div>
			<div class="px-8">
				<p class="text-[8px] font-black tracking-widest text-slate-400 uppercase">Network Uptime</p>
				<p class="text-lg font-black text-slate-900 italic">99.9%</p>
			</div>
			<div class="px-8">
				<p class="text-[8px] font-black tracking-widest text-slate-400 uppercase">Security Layer</p>
				<p class="text-lg font-black text-indigo-600 uppercase italic">Encrypted</p>
			</div>
		</div>
		<div class="flex items-center gap-3 rounded-full border border-slate-100 bg-slate-50 px-4 py-2">
			<span class="h-1.5 w-1.5 animate-pulse rounded-full bg-emerald-500"></span>
			<span class="text-[10px] font-black tracking-wider text-slate-600 uppercase"
				>Clinical Node: Healthy</span
			>
		</div>
	</div>
</div>
