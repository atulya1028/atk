<script lang="ts">
	import type { PageData } from './$types';
	let { data } = $props<{ data: PageData }>();

	let dateFilter = $state('');
	let isPurgeModalOpen = $state(false);
	let purgeTimeframe = $state('30days');
	let isPurging = $state(false);

	let filteredLogs = $derived(
		data.logs.filter((log: any) => {
			if (!dateFilter) return true;
			const logDate = new Date(log.createdAt).toISOString().slice(0, 10);
			return logDate === dateFilter;
		})
	);

	function getActionBadgeClass(action: string) {
		if (action.startsWith('DELETE') || action.startsWith('PURGE')) {
			return 'bg-red-50 text-red-700 border-red-100';
		}
		if (action.startsWith('RESET')) {
			return 'bg-amber-50 text-amber-700 border-amber-200';
		}
		if (action.includes('TRIAGE')) {
			return 'bg-indigo-50 text-indigo-700 border-indigo-200';
		}
		if (action.startsWith('CREATE')) {
			return 'bg-emerald-50 text-emerald-700 border-emerald-100';
		}
		if (action.startsWith('UPDATE') || action === 'REORDER_QUESTIONS') {
			return 'bg-blue-50 text-blue-700 border-blue-100';
		}
		if (action.endsWith('REPORT')) {
			return 'bg-purple-50 text-purple-700 border-purple-100';
		}
		return 'bg-slate-50 text-slate-700 border-slate-100';
	}

	function formatActionName(action: string) {
		return action.replace(/_/g, ' ');
	}

	function exportLogsCsv() {
		const headers = ['Log ID', 'Timestamp (UTC)', 'Action Type', 'Description'];
		const escapeCsv = (str: string) => `"${String(str || '').replace(/"/g, '""')}"`;

		const rows = filteredLogs.map((log: any) => [
			`#${log.id}`,
			new Date(log.createdAt).toISOString().replace('T', ' ').slice(0, 19),
			escapeCsv(log.action),
			escapeCsv(log.description)
		].join(','));

		const csvContent = [headers.join(','), ...rows].join('\n');
		const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
		const url = URL.createObjectURL(blob);
		const link = document.createElement('a');
		link.setAttribute('href', url);
		link.setAttribute('download', `ATK_Audit_Logs_${new Date().toISOString().slice(0, 10)}.csv`);
		document.body.appendChild(link);
		link.click();
		document.body.removeChild(link);
		URL.revokeObjectURL(url);
	}
</script>

<div class="flex h-full flex-col bg-white">
	<!-- Top Bar -->
	<div class="flex shrink-0 items-center justify-between border-b border-slate-100 bg-white px-10 py-6">
		<!-- Filter by date layout -->
		<div class="flex items-center gap-4">
			<div class="flex items-center gap-3">
				<span class="text-xs font-bold text-slate-400 uppercase tracking-wider">Filter by Date:</span>
				<div class="relative">
					<input
						type="date"
						bind:value={dateFilter}
						class="rounded-[8px] border border-slate-200 bg-slate-50 px-3 py-2 text-xs font-bold text-slate-600 outline-none transition-all hover:border-slate-300 focus:bg-white focus:ring-1 focus:ring-indigo-500"
					/>
					{#if dateFilter}
						<button
							onclick={() => (dateFilter = '')}
							class="absolute right-8 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 text-xs font-bold border-0 bg-transparent cursor-pointer"
							title="Clear Date"
						>
							✕
						</button>
					{/if}
				</div>
			</div>
			<span class="text-xs font-bold text-slate-400">
				Showing {filteredLogs.length} of {data.logs.length} logs
			</span>
		</div>

		<!-- Action Controls -->
		<div class="flex items-center gap-3">
			<button
				onclick={exportLogsCsv}
				class="inline-flex items-center gap-2 rounded-xl border border-slate-200 bg-white px-4 py-2 text-xs font-bold text-slate-700 shadow-sm transition-all hover:bg-slate-50 cursor-pointer"
			>
				<svg class="h-4 w-4 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
					<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
				</svg>
				Export CSV
			</button>

			<button
				onclick={() => (isPurgeModalOpen = true)}
				class="inline-flex items-center gap-2 rounded-xl border border-rose-200 bg-rose-50 px-4 py-2 text-xs font-bold text-rose-700 transition-all hover:bg-rose-100 cursor-pointer"
			>
				<svg class="h-4 w-4 text-rose-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
					<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
				</svg>
				Purge Logs
			</button>
		</div>
	</div>

	<!-- Audit Logs Table -->
	<div class="flex-1 overflow-auto p-10">
		<div class="overflow-hidden rounded-[8px] border border-slate-200 bg-white">
			<table class="w-full border-collapse text-left">
				<thead>
					<tr class="border-b border-slate-100 bg-slate-50/50">
						<th class="px-8 py-5 text-[10px] font-black tracking-[0.2em] text-slate-400 uppercase w-48">Timestamp</th>
						<th class="px-8 py-5 text-[10px] font-black tracking-[0.2em] text-slate-400 uppercase w-56">Action Type</th>
						<th class="px-8 py-5 text-[10px] font-black tracking-[0.2em] text-slate-400 uppercase">Activity Log</th>
					</tr>
				</thead>
				<tbody class="divide-y divide-slate-50">
					{#each filteredLogs as log (log.id)}
						<tr class="group transition-colors hover:bg-slate-50/50">
							<td class="px-8 py-5 align-middle">
								<p class="text-xs font-bold text-slate-500">
									{new Date(log.createdAt).toLocaleString()}
								</p>
							</td>
							<td class="px-8 py-5 align-middle">
								<span class="inline-flex items-center rounded-full border px-2.5 py-0.5 text-[10px] font-black tracking-wider uppercase {getActionBadgeClass(log.action)}">
									{formatActionName(log.action)}
								</span>
							</td>
							<td class="px-8 py-5 align-middle">
								<p class="text-xs font-bold text-slate-700">
									{log.description}
								</p>
							</td>
						</tr>
					{:else}
						<tr>
							<td colspan="3" class="px-8 py-20 text-center">
								<div class="flex flex-col items-center opacity-40">
									<svg class="w-12 h-12 mb-4 text-slate-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
										<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01" />
									</svg>
									<p class="font-bold text-slate-500">No activity logs recorded for this selection.</p>
								</div>
							</td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
	</div>
</div>

<!-- Purge Modal -->
{#if isPurgeModalOpen}
	<div class="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 p-4 backdrop-blur-sm">
		<div class="w-full max-w-md rounded-2xl bg-white p-6 shadow-2xl border border-slate-200">
			<div class="flex items-center justify-between pb-4 border-b border-slate-100">
				<div class="flex items-center gap-2">
					<div class="flex h-9 w-9 items-center justify-center rounded-xl bg-rose-50 text-rose-600">
						<svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
							<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
						</svg>
					</div>
					<div>
						<h3 class="text-base font-black text-slate-900">Purge Audit Logs</h3>
						<p class="text-xs text-slate-500">Clean up historical activity logs</p>
					</div>
				</div>
				<button onclick={() => (isPurgeModalOpen = false)} class="text-slate-400 hover:text-slate-600 cursor-pointer text-sm">✕</button>
			</div>

			<form method="POST" action="?/purgeLogs" onsubmit={() => (isPurging = true)} class="mt-5 space-y-4">
				<div>
					<label for="timeframe-select" class="block text-xs font-bold text-slate-600 mb-1.5">Purge Criteria</label>
					<select
						id="timeframe-select"
						name="timeframe"
						bind:value={purgeTimeframe}
						class="w-full rounded-xl border border-slate-200 bg-slate-50 px-3.5 py-2.5 text-xs font-bold text-slate-700 outline-none focus:bg-white focus:ring-2 focus:ring-rose-500"
					>
						<option value="7days">Older than 7 days</option>
						<option value="30days">Older than 30 days (Recommended)</option>
						<option value="90days">Older than 90 days</option>
						<option value="all">Purge All Logs (Permanent Reset)</option>
					</select>
				</div>

				<div class="rounded-xl bg-rose-50 border border-rose-100 p-3 text-xs text-rose-800">
					<p class="font-bold">⚠️ Warning:</p>
					<p class="mt-0.5">This action permanently deletes selected audit log records from the database. A new log recording this purge operation will be preserved.</p>
				</div>

				<div class="flex items-center justify-end gap-3 pt-3 border-t border-slate-100">
					<button
						type="button"
						onclick={() => (isPurgeModalOpen = false)}
						class="rounded-xl border border-slate-200 px-4 py-2 text-xs font-bold text-slate-600 hover:bg-slate-50 cursor-pointer"
					>
						Cancel
					</button>
					<button
						type="submit"
						disabled={isPurging}
						class="rounded-xl bg-rose-600 px-4 py-2 text-xs font-bold text-white shadow-sm hover:bg-rose-700 disabled:opacity-50 cursor-pointer"
					>
						{isPurging ? 'Purging...' : 'Confirm Purge'}
					</button>
				</div>
			</form>
		</div>
	</div>
{/if}
