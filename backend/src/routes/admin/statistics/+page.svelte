<script lang="ts">
	import type { PageData } from './$types';
	let { data } = $props<{ data: PageData }>();

	function changeCategory(cat: string) {
		const url = new URL(window.location.href);
		if (cat === 'ALL') {
			url.searchParams.delete('category');
		} else {
			url.searchParams.set('category', cat);
		}
		window.location.href = url.toString();
	}

	function exportAnalyticsCsv() {
		const escapeCsv = (str: string) => `"${String(str || '').replace(/"/g, '""')}"`;
		const lines: string[] = [];

		lines.push(`ATK Clinical Analytics Report - Category: ${data.selectedCategory}`);
		lines.push(`Generated: ${new Date().toISOString()}`);
		lines.push('');

		// Key Metrics
		lines.push('Key Metrics,Value');
		lines.push(`Total Completed Assessments,${data.totalCompletedSubmissions}`);
		lines.push(`Critical Severity Alerts,${data.criticalAlertsCount}`);
		lines.push(`Overall Critical Rate,${data.totalCompletedSubmissions ? Math.round((data.criticalAlertsCount / data.totalCompletedSubmissions) * 100) : 0}%`);
		lines.push(`Top Risk Pincode,${data.topPincodes[0]?.pincode || 'None'}`);
		lines.push('');

		// Progression Funnel
		lines.push('Stage Number,Progression Funnel Stage,Participants,Percentage');
		data.funnel.forEach((f: any, i: number) => {
			lines.push(`${i + 1},${escapeCsv(f.stage)},${f.count},${f.pct}%`);
		});
		lines.push('');

		// Risk Distribution
		lines.push('Risk Level,Participants Count');
		data.riskDistribution.forEach((r: any) => {
			lines.push(`${escapeCsv(r.label)},${r.count}`);
		});
		lines.push('');

		// Geographic Hotspots
		lines.push('Pincode / Postal Area,Total Assessments,Critical Cases,Critical Severity Ratio (%)');
		data.topPincodes.forEach((p: any) => {
			lines.push(`${escapeCsv(p.pincode)},${p.totalSubmissions},${p.criticalCount},${p.criticalRate}%`);
		});

		const csvContent = lines.join('\n');
		const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
		const url = URL.createObjectURL(blob);
		const link = document.createElement('a');
		link.setAttribute('href', url);
		link.setAttribute('download', `ATK_Analytics_${data.selectedCategory}_${new Date().toISOString().slice(0, 10)}.csv`);
		document.body.appendChild(link);
		link.click();
		document.body.removeChild(link);
		URL.revokeObjectURL(url);
	}
</script>

<div class="flex h-full flex-col bg-white overflow-auto">
	<!-- Top Bar -->
	<div class="border-b border-slate-100 bg-white px-10 py-6">
		<div class="flex flex-col gap-6">
			<div class="flex items-center justify-between gap-8">
				<div>
					<h1 class="text-xl font-black tracking-tight text-slate-900">Clinical Analytics & Trends</h1>
					<p class="text-xs font-semibold text-slate-400">
						Cohort drop-off funnel, risk severity breakdowns, and geographic hotspot mapping
					</p>
				</div>

				<div class="flex items-center gap-3">
					<button
						onclick={exportAnalyticsCsv}
						class="inline-flex items-center gap-2 rounded-xl border border-slate-200 bg-white px-3.5 py-2 text-xs font-bold text-slate-700 shadow-sm transition-all hover:bg-slate-50 cursor-pointer"
					>
						<svg class="h-4 w-4 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
							<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
						</svg>
						Export CSV
					</button>

					<!-- Category Switcher -->
					<div class="flex rounded-[8px] bg-slate-100 p-1 border border-slate-200">
						<button
							onclick={() => changeCategory('ALL')}
							class="rounded-[6px] px-3 py-1.5 text-xs font-bold transition-all cursor-pointer {data.selectedCategory === 'ALL' ? 'bg-white text-indigo-600 shadow-xs' : 'text-slate-600 hover:text-slate-900'}"
						>
							All Categories
						</button>
						<button
							onclick={() => changeCategory('ADDICTION')}
							class="rounded-[6px] px-3 py-1.5 text-xs font-bold transition-all cursor-pointer {data.selectedCategory === 'ADDICTION' ? 'bg-white text-indigo-600 shadow-xs' : 'text-slate-600 hover:text-slate-900'}"
						>
							Addiction
						</button>
						<button
							onclick={() => changeCategory('MENTAL')}
							class="rounded-[6px] px-3 py-1.5 text-xs font-bold transition-all cursor-pointer {data.selectedCategory === 'MENTAL' ? 'bg-white text-indigo-600 shadow-xs' : 'text-slate-600 hover:text-slate-900'}"
						>
							Mental Health
						</button>
					</div>
				</div>
			</div>

			<!-- Top Metrics -->
			<div class="grid grid-cols-4 gap-4">
				<div class="rounded-[8px] border border-slate-200 bg-slate-50/50 p-4">
					<span class="text-[10px] font-black tracking-[0.2em] text-slate-400 uppercase">Completed Assessments</span>
					<p class="mt-1 text-2xl font-black text-slate-800">{data.totalCompletedSubmissions}</p>
				</div>
				<div class="rounded-[8px] border border-slate-200 bg-slate-50/50 p-4">
					<span class="text-[10px] font-black tracking-[0.2em] text-slate-400 uppercase">Critical Severity Alerts</span>
					<p class="mt-1 text-2xl font-black text-rose-600">{data.criticalAlertsCount}</p>
				</div>
				<div class="rounded-[8px] border border-slate-200 bg-slate-50/50 p-4">
					<span class="text-[10px] font-black tracking-[0.2em] text-slate-400 uppercase">Overall Critical Rate</span>
					<p class="mt-1 text-2xl font-black text-amber-600">
						{data.totalCompletedSubmissions ? Math.round((data.criticalAlertsCount / data.totalCompletedSubmissions) * 100) : 0}%
					</p>
				</div>
				<div class="rounded-[8px] border border-slate-200 bg-slate-50/50 p-4">
					<span class="text-[10px] font-black tracking-[0.2em] text-slate-400 uppercase">Top Risk Area</span>
					<p class="mt-1 text-xl font-black text-indigo-600 truncate">
						{data.topPincodes[0]?.pincode || 'None Yet'}
					</p>
				</div>
			</div>
		</div>
	</div>

	<!-- Main Analytics Grid -->
	<div class="p-10 space-y-8">
		<!-- Section 1: Funnel & Risk Distribution -->
		<div class="grid grid-cols-12 gap-8">
			<!-- Clinical Assessment Funnel -->
			<div class="col-span-7 rounded-[8px] border border-slate-200 bg-white p-6 shadow-xs">
				<div class="flex items-center justify-between mb-6">
					<div>
						<h2 class="text-sm font-black text-slate-900 uppercase tracking-wider">Clinical Progression Funnel</h2>
						<p class="text-xs text-slate-400 font-medium">Drop-off from user onboarding through stage 3 critical triage</p>
					</div>
					<span class="rounded-full bg-indigo-50 px-2.5 py-1 text-[10px] font-bold text-indigo-600">6 Stages</span>
				</div>

				<div class="space-y-4">
					{#each data.funnel as step, i}
						<div>
							<div class="flex items-center justify-between text-xs font-bold text-slate-700 mb-1">
								<span class="flex items-center gap-2">
									<span class="flex h-5 w-5 items-center justify-center rounded-full bg-slate-100 text-[10px] font-black text-slate-600">
										{i + 1}
									</span>
									{step.stage}
								</span>
								<span>{step.count} ({step.pct}%)</span>
							</div>
							<div class="h-2.5 w-full rounded-full bg-slate-100 overflow-hidden">
								<div
									class="h-full rounded-full transition-all duration-500 {i === 5 ? 'bg-rose-500' : 'bg-indigo-600'}"
									style="width: {Math.max(step.pct, 2)}%"
								></div>
							</div>
						</div>
					{/each}
				</div>
			</div>

			<!-- Risk Classification -->
			<div class="col-span-5 rounded-[8px] border border-slate-200 bg-white p-6 shadow-xs flex flex-col justify-between">
				<div>
					<h2 class="text-sm font-black text-slate-900 uppercase tracking-wider mb-1">Severity Distribution</h2>
					<p class="text-xs text-slate-400 font-medium mb-6">Stratified participant assessment scores</p>

					<div class="space-y-4">
						{#each data.riskDistribution as risk}
							<div class="rounded-[8px] border border-slate-100 p-4 {risk.bgLight}">
								<div class="flex items-center justify-between mb-2">
									<div class="flex items-center gap-2">
										<span class="h-3 w-3 rounded-full {risk.color}"></span>
										<span class="text-xs font-bold {risk.text}">{risk.label}</span>
									</div>
									<span class="text-sm font-black text-slate-800">{risk.count}</span>
								</div>
								<div class="h-2 w-full rounded-full bg-white/80 overflow-hidden">
									<div
										class="h-full {risk.color} rounded-full"
										style="width: {data.totalCompletedSubmissions ? Math.round((risk.count / data.totalCompletedSubmissions) * 100) : 0}%"
									></div>
								</div>
							</div>
						{/each}
					</div>
				</div>

				<div class="mt-6 pt-4 border-t border-slate-100 flex items-center justify-between text-xs text-slate-400">
					<span>Auto-escalation triggers on Critical Severity</span>
					<span class="font-bold text-rose-600">{data.criticalAlertsCount} active cases</span>
				</div>
			</div>
		</div>

		<!-- Section 2: Geographic Hotspots -->
		<div class="rounded-[8px] border border-slate-200 bg-white overflow-hidden shadow-xs">
			<div class="px-8 py-5 border-b border-slate-100 flex items-center justify-between bg-slate-50/30">
				<div>
					<h2 class="text-sm font-black text-slate-900 uppercase tracking-wider">Geographic Hotspot Mapping (Top Pincodes)</h2>
					<p class="text-xs text-slate-400 font-medium">Identifies high-density areas of critical clinical need</p>
				</div>
				<span class="text-xs font-bold text-slate-400">Top {data.topPincodes.length} Regions</span>
			</div>

			<table class="w-full border-collapse text-left">
				<thead>
					<tr class="border-b border-slate-100 bg-slate-50/50">
						<th class="px-8 py-4 text-[10px] font-black tracking-[0.2em] text-slate-400 uppercase">Pincode / Postal Area</th>
						<th class="px-8 py-4 text-[10px] font-black tracking-[0.2em] text-slate-400 uppercase">Total Assessments</th>
						<th class="px-8 py-4 text-[10px] font-black tracking-[0.2em] text-slate-400 uppercase">Critical Cases</th>
						<th class="px-8 py-4 text-[10px] font-black tracking-[0.2em] text-slate-400 uppercase">Critical Severity Ratio</th>
						<th class="px-8 py-4 text-right text-[10px] font-black tracking-[0.2em] text-slate-400 uppercase">Risk Level</th>
					</tr>
				</thead>
				<tbody class="divide-y divide-slate-50">
					{#each data.topPincodes as pin}
						<tr class="hover:bg-slate-50/50 transition-colors">
							<td class="px-8 py-4">
								<span class="font-mono text-xs font-bold text-slate-800 bg-slate-100 px-2 py-1 rounded">
									{pin.pincode}
								</span>
							</td>
							<td class="px-8 py-4 text-xs font-bold text-slate-700">{pin.totalSubmissions}</td>
							<td class="px-8 py-4">
								<span class="text-xs font-bold {pin.criticalCount > 0 ? 'text-rose-600' : 'text-slate-400'}">
									{pin.criticalCount}
								</span>
							</td>
							<td class="px-8 py-4">
								<div class="flex items-center gap-2 max-w-xs">
									<div class="h-2 w-24 rounded-full bg-slate-100 overflow-hidden">
										<div
											class="h-full rounded-full {pin.criticalRate > 30 ? 'bg-rose-500' : 'bg-amber-500'}"
											style="width: {pin.criticalRate}%"
										></div>
									</div>
									<span class="text-xs font-bold text-slate-600">{pin.criticalRate}%</span>
								</div>
							</td>
							<td class="px-8 py-4 text-right">
								{#if pin.criticalRate >= 40}
									<span class="inline-flex items-center rounded-full bg-rose-50 border border-rose-100 px-2.5 py-0.5 text-[10px] font-black text-rose-700 uppercase">
										High Risk Area
									</span>
								{:else if pin.criticalRate > 15}
									<span class="inline-flex items-center rounded-full bg-amber-50 border border-amber-100 px-2.5 py-0.5 text-[10px] font-black text-amber-700 uppercase">
										Moderate Risk
									</span>
								{:else}
									<span class="inline-flex items-center rounded-full bg-emerald-50 border border-emerald-100 px-2.5 py-0.5 text-[10px] font-black text-emerald-700 uppercase">
										Stable
									</span>
								{/if}
							</td>
						</tr>
					{:else}
						<tr>
							<td colspan="5" class="px-8 py-12 text-center text-xs font-bold text-slate-400">
								No geographic submissions recorded yet.
							</td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
	</div>
</div>
