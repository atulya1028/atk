<script lang="ts">
	import type { PageData } from './$types';
	let { data } = $props<{ data: PageData }>();

	let searchTerm = $state('');
	let statusFilter = $state('all');
	let stageFilter = $state('all');
	let categoryFilter = $state('all');
	let riskFilter = $state('all');
	let triageFilter = $state('all');

	let isModalOpen = $state(false);
	let isLoading = $state(false);
	let selectedSubmission = $state<any>(null);
	let isExportDropdownOpen = $state(false);
	let isSavingTriage = $state(false);

	let filteredSubmissions = $derived(
		data.submissions.filter((s: any) => {
			const matchesSearch =
				s.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
				s.id.toString().includes(searchTerm) ||
				(s.userPinCode && s.userPinCode.toLowerCase().includes(searchTerm.toLowerCase()));
			const matchesStatus = statusFilter === 'all' || s.status === statusFilter;
			const matchesStage = stageFilter === 'all' || s.surveyType === stageFilter;
			const matchesCategory = categoryFilter === 'all' || s.surveyCategory === categoryFilter;
			const matchesTriage = triageFilter === 'all' || (s.triageStatus || 'NEW') === triageFilter;

			// Compute critical status
			const categorySettings = data.settings.find((setting: any) => setting.surveyCategory === s.surveyCategory);
			const criticalValue = categorySettings?.criticalValue ?? 50;
			const isCritical = s.surveyType === 'DETAILED' && s.score >= criticalValue;
			const matchesRisk = riskFilter === 'all' || (riskFilter === 'critical' && isCritical);

			return matchesSearch && matchesStatus && matchesStage && matchesCategory && matchesRisk && matchesTriage;
		})
	);

	async function viewDetails(id: number) {
		isModalOpen = true;
		isLoading = true;
		selectedSubmission = null;

		try {
			const res = await fetch(`/admin/submissions/${id}/api`);
			const sub = await res.json();

			sub.chatMessages = sub.answers.map((a: any) => ({
				id: a.id,
				question: a.question.text,
				answer:
					a.choices && a.choices.length > 0
						? a.choices.map((c: any) => c.option.label || c.option.value).join(', ')
						: a.legacyValueText || a.valueString || a.valueInt || a.valueText || '-',
				section: a.question.section?.title
			}));

			sub.triageStatus = sub.triageStatus || 'NEW';
			sub.assignedDoctorId = sub.assignedDoctorId || '';
			sub.clinicalNotes = sub.clinicalNotes || '';

			selectedSubmission = sub;
		} catch (e) {
			console.error(e);
		} finally {
			isLoading = false;
		}
	}

	function closeModal() {
		isModalOpen = false;
		selectedSubmission = null;
	}

	let isEmailing = $state(false);

	async function sendEmailReport(params: string) {
		isEmailing = true;
		try {
			const res = await fetch(`/api/submissions/export?action=email&${params}`);
			const result = await res.json();
			if (result.success) {
				alert('Report CSV email sent to Super Admin successfully!');
			} else {
				alert('Failed to send email report: ' + (result.error || 'Unknown error'));
			}
		} catch (e: any) {
			console.error(e);
			alert('Network error while sending email report: ' + e.message);
		} finally {
			isEmailing = false;
		}
	}

	async function saveTriage() {
		if (!selectedSubmission) return;
		isSavingTriage = true;
		try {
			const formData = new FormData();
			formData.append('submissionId', String(selectedSubmission.id));
			formData.append('triageStatus', selectedSubmission.triageStatus || 'NEW');
			if (selectedSubmission.assignedDoctorId) {
				formData.append('assignedDoctorId', String(selectedSubmission.assignedDoctorId));
			}
			formData.append('clinicalNotes', selectedSubmission.clinicalNotes || '');

			const res = await fetch('?/updateTriage', {
				method: 'POST',
				body: formData
			});

			if (res.ok) {
				alert('Clinical triage & notes saved successfully.');
				const local = data.submissions.find((s: any) => s.id === selectedSubmission.id);
				if (local) {
					local.triageStatus = selectedSubmission.triageStatus;
					local.assignedDoctorId = selectedSubmission.assignedDoctorId ? Number(selectedSubmission.assignedDoctorId) : null;
					const doc = data.doctors.find((d: any) => d.id === Number(selectedSubmission.assignedDoctorId));
					local.assignedDoctorName = doc ? (doc.name || doc.email) : null;
					local.clinicalNotes = selectedSubmission.clinicalNotes;
				}
			} else {
				alert('Failed to save triage.');
			}
		} catch (err: any) {
			alert('Failed to save triage: ' + err.message);
		} finally {
			isSavingTriage = false;
		}
	}

	async function handleDeleteSubmission(id: number) {
		if (!confirm(`Are you sure you want to permanently delete submission #${id}? All associated answers will be deleted.`)) {
			return;
		}
		try {
			const fd = new FormData();
			fd.append('id', String(id));
			const res = await fetch('?/deleteSubmission', {
				method: 'POST',
				body: fd
			});
			if (res.ok) {
				alert(`Submission #${id} deleted successfully.`);
				data.submissions = data.submissions.filter((s: any) => s.id !== id);
				if (selectedSubmission?.id === id) {
					closeModal();
				}
			} else {
				alert('Failed to delete submission.');
			}
		} catch (e: any) {
			alert('Failed to delete submission: ' + e.message);
		}
	}

	function getTriageBadge(status: string) {
		switch (status) {
			case 'IN_REVIEW':
				return 'bg-amber-50 text-amber-700 border-amber-200';
			case 'CONTACTED':
				return 'bg-blue-50 text-blue-700 border-blue-200';
			case 'ASSIGNED':
				return 'bg-purple-50 text-purple-700 border-purple-200';
			case 'RESOLVED':
				return 'bg-emerald-50 text-emerald-700 border-emerald-200';
			default:
				return 'bg-slate-100 text-slate-700 border-slate-200';
		}
	}
</script>

<div class="flex h-full flex-col bg-white">
	<div class="border-b border-slate-100 bg-white px-10 py-6">
		<div class="flex flex-col gap-6">
			<!-- Row 1: Search and Category Switch -->
			<div class="flex items-center justify-between gap-8">
				<div class="relative max-w-md flex-1">
					<svg
						class="absolute top-1/2 left-4 h-4 w-4 -translate-y-1/2 text-slate-300"
						fill="none"
						stroke="currentColor"
						viewBox="0 0 24 24"
					>
						<path
							stroke-linecap="round"
							stroke-linejoin="round"
							stroke-width="2"
							d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
						/>
					</svg>
					<input
						type="text"
						placeholder="Search by participant email, ID, or postcode..."
						class="w-full rounded-[8px] border border-slate-200 bg-slate-50 py-2.5 pr-4 pl-11 text-xs font-semibold transition-all focus:bg-white focus:ring-1 focus:ring-indigo-500 focus:outline-none"
						bind:value={searchTerm}
					/>
				</div>

				<div class="flex rounded-[10px] bg-slate-100 p-1 shadow-inner">
					<button
						class="rounded-[8px] px-6 py-1.5 text-xs font-black tracking-widest uppercase transition-all cursor-pointer {categoryFilter ===
						'all'
							? 'bg-white text-slate-900 shadow-sm'
							: 'text-slate-500 hover:text-slate-700'}"
						onclick={() => (categoryFilter = 'all')}
					>
						All Paths
					</button>
					<button
						class="rounded-[8px] px-6 py-1.5 text-xs font-black tracking-widest uppercase transition-all cursor-pointer {categoryFilter ===
						'ADDICTION'
							? 'bg-white text-indigo-600 shadow-sm'
							: 'text-slate-500 hover:text-slate-700'}"
						onclick={() => (categoryFilter = 'ADDICTION')}
					>
						Addiction
					</button>
					<button
						class="rounded-[8px] px-6 py-1.5 text-xs font-black tracking-widest uppercase transition-all cursor-pointer {categoryFilter ===
						'MENTAL'
							? 'bg-white text-pink-600 shadow-sm'
							: 'text-slate-500 hover:text-slate-700'}"
						onclick={() => (categoryFilter = 'MENTAL')}
					>
						Mental Health
					</button>
				</div>
			</div>

			<!-- Row 2: Secondary Filters -->
			<div class="flex items-center justify-between border-t border-slate-50 pt-4 gap-4">
				<div class="flex flex-wrap items-center gap-6">
					<!-- Lifecycle filter -->
					<div class="flex items-center gap-2">
						<span class="text-[10px] font-black tracking-[0.2em] text-slate-400 uppercase">Lifecycle:</span>
						<div class="flex gap-1">
							{#each ['all', 'COMPLETED', 'DRAFT'] as status}
								<button
									class="rounded-[6px] px-2.5 py-1 text-[10px] font-black tracking-widest uppercase transition-all cursor-pointer
	                                       {statusFilter === status
										? status === 'COMPLETED'
											? 'bg-emerald-600 text-white'
											: status === 'DRAFT'
												? 'bg-amber-500 text-white'
												: 'bg-slate-900 text-white'
										: 'text-slate-500 hover:bg-slate-50'}"
									onclick={() => (statusFilter = status)}
								>
									{status === 'all' ? 'Any' : status}
								</button>
							{/each}
						</div>
					</div>

					<!-- Clinical stage filter -->
					<div class="flex items-center gap-2">
						<span class="text-[10px] font-black tracking-[0.2em] text-slate-400 uppercase">Stage:</span>
						<div class="flex gap-1">
							{#each ['all', 'INITIAL', 'DETAILED'] as stage}
								<button
									class="rounded-[6px] px-2.5 py-1 text-[10px] font-black tracking-widest uppercase transition-all cursor-pointer
	                                       {stageFilter === stage
										? stage === 'INITIAL'
											? 'bg-indigo-600 text-white'
											: stage === 'DETAILED'
												? 'bg-purple-600 text-white'
												: 'bg-slate-900 text-white'
										: 'text-slate-500 hover:bg-slate-50'}"
									onclick={() => (stageFilter = stage)}
								>
									{stage === 'all' ? 'All' : stage === 'INITIAL' ? 'Stage 2' : 'Stage 3'}
								</button>
							{/each}
						</div>
					</div>

					<!-- Risk filter -->
					<div class="flex items-center gap-2">
						<span class="text-[10px] font-black tracking-[0.2em] text-slate-400 uppercase">Risk:</span>
						<div class="flex gap-1">
							{#each ['all', 'critical'] as risk}
								<button
									class="rounded-[6px] px-2.5 py-1 text-[10px] font-black tracking-widest uppercase transition-all cursor-pointer
	                                       {riskFilter === risk
										? risk === 'critical'
											? 'bg-red-600 text-white'
											: 'bg-slate-900 text-white'
										: 'text-slate-500 hover:bg-slate-50'}"
									onclick={() => (riskFilter = risk)}
								>
									{risk === 'all' ? 'All' : '🚨 Critical'}
								</button>
							{/each}
						</div>
					</div>

					<!-- Triage filter -->
					<div class="flex items-center gap-2">
						<span class="text-[10px] font-black tracking-[0.2em] text-slate-400 uppercase">Triage:</span>
						<div class="flex gap-1">
							{#each ['all', 'NEW', 'IN_REVIEW', 'CONTACTED', 'RESOLVED'] as tStatus}
								<button
									class="rounded-[6px] px-2.5 py-1 text-[10px] font-black tracking-widest uppercase transition-all cursor-pointer
	                                       {triageFilter === tStatus ? 'bg-indigo-600 text-white' : 'text-slate-500 hover:bg-slate-50'}"
									onclick={() => (triageFilter = tStatus)}
								>
									{tStatus === 'all' ? 'All' : tStatus.replace('_', ' ')}
								</button>
							{/each}
						</div>
					</div>
				</div>

				<div class="relative shrink-0">
					<button
						onclick={() => (isExportDropdownOpen = !isExportDropdownOpen)}
						class="inline-flex items-center gap-1.5 rounded-[8px] border border-slate-200 bg-white px-3 py-1.5 text-xs font-bold tracking-wide text-slate-700 transition-colors hover:border-slate-300 hover:bg-slate-50 cursor-pointer"
					>
						<svg class="h-4 w-4 text-slate-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
							<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"/>
						</svg>
						Export CSV
						<svg class="h-3.5 w-3.5 text-slate-400 transition-transform {isExportDropdownOpen ? 'rotate-180' : ''}" fill="none" viewBox="0 0 24 24" stroke="currentColor">
							<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/>
						</svg>
					</button>

					{#if isExportDropdownOpen}
						<div class="fixed inset-0 z-40" onclick={() => (isExportDropdownOpen = false)}></div>

						<div class="absolute right-0 mt-1.5 z-50 w-72 origin-top-right rounded-[8px] border border-slate-100 bg-white p-1.5 shadow-xl ring-1 ring-black/5 focus:outline-none">
							<div class="px-3 py-1.5 text-[10px] font-black uppercase tracking-wider text-slate-400">Download CSV</div>
							<a
								href={`/api/submissions/export?category=${categoryFilter}&stage=${stageFilter}&status=${statusFilter}&risk=${riskFilter}`}
								onclick={() => (isExportDropdownOpen = false)}
								class="flex items-center rounded-[6px] px-3 py-2 text-xs text-slate-700 transition-colors hover:bg-slate-50 hover:text-slate-900"
							>
								Download Current View
							</a>
							<a
								href="/api/submissions/export?category=all&stage=all&status=all&risk=critical"
								onclick={() => (isExportDropdownOpen = false)}
								class="flex items-center rounded-[6px] px-3 py-2 text-xs font-bold text-red-600 transition-colors hover:bg-red-50"
							>
								🚨 Download All Critical Risk
							</a>

							<div class="my-1.5 border-t border-slate-100"></div>
							
							<div class="px-3 py-1.5 text-[10px] font-black uppercase tracking-wider text-slate-400">Email CSV to Admin</div>
							<button
								onclick={() => { isExportDropdownOpen = false; sendEmailReport(`category=${categoryFilter}&stage=${stageFilter}&status=${statusFilter}&risk=${riskFilter}`); }}
								class="w-full text-left flex items-center rounded-[6px] px-3 py-2 text-xs text-slate-700 transition-colors hover:bg-slate-50 hover:text-slate-900 bg-transparent border-0 cursor-pointer"
								disabled={isEmailing}
							>
								Email Current View
							</button>
							<button
								onclick={() => { isExportDropdownOpen = false; sendEmailReport('category=all&stage=all&status=all&risk=critical'); }}
								class="w-full text-left flex items-center rounded-[6px] px-3 py-2 text-xs font-bold text-red-600 transition-colors hover:bg-red-50 bg-transparent border-0 cursor-pointer"
								disabled={isEmailing}
							>
								🚨 Email All Critical Risk
							</button>
						</div>
					{/if}
				</div>
			</div>
		</div>
	</div>

	<!-- Submissions Table -->
	<div class="flex-1 overflow-auto p-10">
		<div class="overflow-hidden rounded-[8px] border border-slate-200 bg-white">
			<table class="w-full border-collapse text-left">
				<thead>
					<tr class="border-b border-slate-100 bg-slate-50/50">
						<th class="px-6 py-5 text-[10px] font-black tracking-[0.2em] text-slate-400 uppercase">Participant / ID</th>
						<th class="px-6 py-5 text-[10px] font-black tracking-[0.2em] text-slate-400 uppercase">Stage / Category</th>
						<th class="px-6 py-5 text-[10px] font-black tracking-[0.2em] text-slate-400 uppercase">Status & Risk</th>
						<th class="px-6 py-5 text-[10px] font-black tracking-[0.2em] text-slate-400 uppercase">Score</th>
						<th class="px-6 py-5 text-[10px] font-black tracking-[0.2em] text-slate-400 uppercase">Triage Status</th>
						<th class="px-6 py-5 text-[10px] font-black tracking-[0.2em] text-slate-400 uppercase">Clinician</th>
						<th class="px-6 py-5 text-right text-[10px] font-black tracking-[0.2em] text-slate-400 uppercase">Actions</th>
					</tr>
				</thead>
				<tbody class="divide-y divide-slate-50">
					{#each filteredSubmissions as sub}
						{@const categorySettings = data.settings.find((s: any) => s.surveyCategory === sub.surveyCategory)}
						{@const criticalValue = categorySettings?.criticalValue ?? 50}
						{@const isCritical = sub.surveyType === 'DETAILED' && sub.score >= criticalValue}
						<tr class="group transition-colors {isCritical ? 'bg-red-50/60 hover:bg-red-100/50' : 'hover:bg-slate-50/50'}">
							<td class="px-6 py-5">
								<div class="flex items-center gap-3">
									<div class="flex h-9 w-9 shrink-0 items-center justify-center rounded-[8px] bg-slate-100 text-xs font-black text-slate-500">
										{sub.email[0].toUpperCase()}
									</div>
									<div class="flex min-w-0 flex-col">
										<span class="truncate text-xs font-bold text-slate-800">{sub.email}</span>
										<div class="flex items-center gap-2 text-[10px] font-bold text-slate-400">
											<span>#{sub.id}</span>
											{#if sub.userPinCode}
												<span class="font-mono text-slate-500">📍 {sub.userPinCode}</span>
											{/if}
										</div>
									</div>
								</div>
							</td>
							<td class="px-6 py-5">
								<div class="flex flex-col gap-1">
									<span class="inline-flex w-fit items-center rounded-full border px-2 py-0.5 text-[8px] font-black tracking-widest uppercase {sub.surveyType === 'INITIAL' ? 'border-indigo-100 bg-indigo-50 text-indigo-600' : 'border-purple-100 bg-purple-50 text-purple-600'}">
										{sub.surveyType === 'INITIAL' ? 'Initial (Stg 2)' : 'Detailed (Stg 3)'}
									</span>
									<span class="inline-flex w-fit items-center rounded-full border px-2 py-0.5 text-[8px] font-black tracking-widest uppercase {sub.surveyCategory === 'MENTAL' ? 'border-pink-100 bg-pink-50 text-pink-600' : 'border-slate-100 bg-slate-50 text-slate-600'}">
										{sub.surveyCategory === 'MENTAL' ? 'Mental Health' : 'Addiction'}
									</span>
								</div>
							</td>
							<td class="px-6 py-5">
								<div class="flex flex-col gap-1 items-start">
									<span class="rounded-full border px-2 py-0.5 text-[9px] font-black tracking-widest uppercase {sub.status === 'COMPLETED' ? 'border-emerald-100 bg-emerald-50 text-emerald-600' : 'border-amber-100 bg-amber-50 text-amber-600'}">
										{sub.status}
									</span>
									{#if isCritical}
										<span class="inline-flex items-center gap-1 rounded-full border border-red-200 bg-red-100 px-2 py-0.5 text-[8px] font-black tracking-widest text-red-700 uppercase animate-pulse">
											🚨 Critical Risk
										</span>
									{/if}
								</div>
							</td>
							<td class="px-6 py-5">
								<span class="text-xs font-black {isCritical ? 'text-red-600 font-extrabold text-sm' : sub.score >= 30 ? 'text-indigo-600' : 'text-slate-400'}">
									{sub.score !== null && sub.score !== undefined ? sub.score : '-'}
								</span>
							</td>
							<td class="px-6 py-5">
								<span class="inline-flex items-center rounded-full border px-2.5 py-0.5 text-[9px] font-black tracking-wider uppercase {getTriageBadge(sub.triageStatus || 'NEW')}">
									{(sub.triageStatus || 'NEW').replace('_', ' ')}
								</span>
							</td>
							<td class="px-6 py-5">
								{#if sub.assignedDoctorName}
									<span class="text-xs font-bold text-slate-800">Dr. {sub.assignedDoctorName}</span>
								{:else}
									<span class="text-xs text-slate-400 italic">Unassigned</span>
								{/if}
							</td>
							<td class="px-6 py-5 text-right whitespace-nowrap">
								<div class="flex items-center justify-end gap-2">
									<button
										onclick={() => viewDetails(sub.id)}
										class="rounded-[6px] border border-slate-200 bg-white px-3 py-1.5 text-xs font-bold text-slate-700 hover:bg-slate-900 hover:text-white transition-all cursor-pointer"
									>
										Triage & Review
									</button>
									<a
										href={`/admin/submissions/${sub.id}/pdf?autoprint=true`}
										target="_blank"
										class="rounded-[6px] border border-indigo-200 bg-indigo-50 px-2.5 py-1.5 text-xs font-bold text-indigo-700 hover:bg-indigo-100 transition-all cursor-pointer"
										title="Download PDF"
									>
										📄
									</a>
									<button
										onclick={() => handleDeleteSubmission(sub.id)}
										class="rounded-[6px] border border-rose-200 bg-white px-2.5 py-1.5 text-xs font-bold text-rose-600 hover:bg-rose-50 hover:border-rose-300 transition-all cursor-pointer"
										title="Delete Submission"
									>
										<svg class="h-3.5 w-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
											<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
										</svg>
									</button>
								</div>
							</td>
						</tr>
					{:else}
						<tr>
							<td colspan="7" class="px-8 py-20 text-center">
								<div class="flex flex-col items-center opacity-40">
									<svg class="w-12 h-12 mb-4 text-slate-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
										<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
									</svg>
									<p class="font-bold text-slate-500">No submissions match your search.</p>
								</div>
							</td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
	</div>

	<!-- Detail & Triage Modal -->
	{#if isModalOpen}
		<div
			class="fixed inset-0 z-[100] flex items-center justify-end bg-slate-900/40 p-6 backdrop-blur-xs"
			onclick={closeModal}
		>
			<div
				class="flex h-full w-full max-w-2xl flex-col overflow-hidden rounded-[16px] border border-slate-200 bg-white shadow-2xl"
				onclick={(e) => e.stopPropagation()}
			>
				<div class="flex shrink-0 items-center justify-between border-b border-slate-100 px-8 py-5">
					<div>
						<h2 class="text-base font-black tracking-tight text-slate-900">Clinical Review & Case Triage</h2>
						{#if selectedSubmission}
							<p class="mt-0.5 text-xs font-bold text-slate-400">
								{selectedSubmission.user?.email || 'Guest Participant'} &bull; Submission #{selectedSubmission.id}
								{#if selectedSubmission.score}
									&bull; <span class="text-indigo-600 font-extrabold">Score: {selectedSubmission.score} pts</span>
								{/if}
							</p>
						{/if}
					</div>
					<button
						onclick={closeModal}
						class="rounded-full p-2 text-slate-400 hover:text-slate-900 cursor-pointer"
					>
						✕
					</button>
				</div>

				<div class="flex-1 space-y-6 overflow-y-auto bg-slate-50/30 p-8">
					{#if isLoading}
						<div class="flex h-full flex-col items-center justify-center space-y-4">
							<div class="h-8 w-8 animate-spin rounded-full border-3 border-indigo-600 border-t-transparent"></div>
							<p class="text-xs font-black tracking-[0.2em] text-slate-400 uppercase">
								Loading Submission Records...
							</p>
						</div>
					{:else if selectedSubmission}
						<!-- Triage Action Box -->
						<div class="rounded-xl border border-indigo-100 bg-white p-5 shadow-xs space-y-4">
							<div class="flex items-center justify-between border-b border-slate-100 pb-3">
								<h3 class="text-xs font-black uppercase tracking-wider text-slate-800 flex items-center gap-2">
									<span>📋</span> Case Triage & Clinician Assignment
								</h3>
								<button
									onclick={saveTriage}
									disabled={isSavingTriage}
									class="rounded-[6px] bg-indigo-600 px-3.5 py-1.5 text-xs font-bold text-white hover:bg-indigo-700 disabled:opacity-50 cursor-pointer"
								>
									{isSavingTriage ? 'Saving...' : 'Save Triage'}
								</button>
							</div>

							<div class="grid grid-cols-2 gap-4">
								<div>
									<label for="modal-triage-status" class="block text-[10px] font-black uppercase tracking-wider text-slate-500 mb-1">
										Triage Status
									</label>
									<select
										id="modal-triage-status"
										bind:value={selectedSubmission.triageStatus}
										class="w-full rounded-[8px] border border-slate-200 bg-white px-3 py-2 text-xs font-semibold focus:ring-1 focus:ring-indigo-500 focus:outline-none"
									>
										<option value="NEW">NEW (Awaiting Review)</option>
										<option value="IN_REVIEW">IN_REVIEW</option>
										<option value="CONTACTED">CONTACTED (Followed Up)</option>
										<option value="ASSIGNED">ASSIGNED to Doctor</option>
										<option value="RESOLVED">RESOLVED (Case Closed)</option>
									</select>
								</div>

								<div>
									<label for="modal-assigned-doctor" class="block text-[10px] font-black uppercase tracking-wider text-slate-500 mb-1">
										Assigned Clinician
									</label>
									<select
										id="modal-assigned-doctor"
										bind:value={selectedSubmission.assignedDoctorId}
										class="w-full rounded-[8px] border border-slate-200 bg-white px-3 py-2 text-xs font-semibold focus:ring-1 focus:ring-indigo-500 focus:outline-none"
									>
										<option value="">Unassigned</option>
										{#each data.doctors as doc}
											<option value={doc.id}>Dr. {doc.name || doc.email} ({doc.specialization || 'Clinical'})</option>
										{/each}
									</select>
								</div>
							</div>

							<div>
								<label for="modal-clinical-notes" class="block text-[10px] font-black uppercase tracking-wider text-slate-500 mb-1">
									Clinical Case Notes / Review Remarks
								</label>
								<textarea
									id="modal-clinical-notes"
									rows="2"
									bind:value={selectedSubmission.clinicalNotes}
									placeholder="e.g. Telehealth call scheduled for 21st Nov. Participant screened for alcohol withdrawal symptoms."
									class="w-full rounded-[8px] border border-slate-200 px-3 py-2 text-xs font-medium focus:ring-1 focus:ring-indigo-500 focus:outline-none"
								></textarea>
							</div>
						</div>

						<!-- Participant Info Summary Banner -->
						{#if selectedSubmission.user}
							<div class="rounded-xl border border-slate-100 bg-slate-100/60 p-4 grid grid-cols-4 gap-2 text-xs">
								<div>
									<span class="text-[9px] font-bold text-slate-400 uppercase">Age / Gender:</span>
									<p class="font-bold text-slate-700">{selectedSubmission.user.age || 'N/A'} / {selectedSubmission.user.gender || 'N/A'}</p>
								</div>
								<div>
									<span class="text-[9px] font-bold text-slate-400 uppercase">Phone:</span>
									<p class="font-bold text-slate-700">{selectedSubmission.user.phoneNumber || 'N/A'}</p>
								</div>
								<div>
									<span class="text-[9px] font-bold text-slate-400 uppercase">Postcode:</span>
									<p class="font-bold text-slate-700 font-mono">{selectedSubmission.user.pinCode || 'N/A'}</p>
								</div>
								<div>
									<span class="text-[9px] font-bold text-slate-400 uppercase">Occupation:</span>
									<p class="font-bold text-slate-700">{selectedSubmission.user.occupation || 'N/A'}</p>
								</div>
							</div>
						{/if}

						<!-- Question & Answer Chat Stream -->
						<div class="space-y-4 pt-2">
							<h4 class="text-[10px] font-black uppercase tracking-widest text-slate-400">Clinical Protocol Responses</h4>
							{#each selectedSubmission.chatMessages as msg}
								<div class="space-y-2">
									<div class="flex max-w-[85%] flex-col items-start gap-1">
										<div class="rounded-[8px] rounded-tl-none border border-slate-200 bg-white p-3.5 shadow-xs">
											<p class="text-xs leading-relaxed font-bold text-slate-800">{msg.question}</p>
											{#if msg.section}
												<span class="mt-1.5 inline-block rounded-[4px] bg-indigo-50 px-2 py-0.5 text-[9px] font-bold text-indigo-500">
													{msg.section}
												</span>
											{/if}
										</div>
									</div>

									<div class="ml-auto flex max-w-[85%] flex-col items-end gap-1">
										<div class="rounded-[8px] rounded-tr-none bg-indigo-600 p-3.5 shadow-xs">
											<p class="text-xs leading-relaxed font-bold text-white">{msg.answer}</p>
										</div>
									</div>
								</div>
							{/each}
						</div>
					{/if}
				</div>

				<div class="flex shrink-0 items-center justify-between border-t border-slate-100 bg-white px-8 py-4">
					{#if selectedSubmission}
						<div class="flex items-center gap-4">
							<a
								href={`/admin/submissions/${selectedSubmission.id}`}
								class="text-xs font-bold tracking-widest text-slate-400 uppercase transition-colors hover:text-indigo-600"
							>
								Technical Dossier &rarr;
							</a>
							<a
								href={`/admin/submissions/${selectedSubmission.id}/pdf?autoprint=true`}
								target="_blank"
								class="inline-flex items-center gap-1.5 rounded-md bg-indigo-50 border border-indigo-200 px-3 py-1.5 text-xs font-bold text-indigo-700 hover:bg-indigo-100 transition-colors cursor-pointer"
								title="Download or Print PDF Clinical Dossier"
							>
								<span>📄</span> Download PDF
							</a>
							<button
								type="button"
								onclick={() => handleDeleteSubmission(selectedSubmission.id)}
								class="inline-flex items-center gap-1.5 rounded-md bg-rose-50 border border-rose-200 px-3 py-1.5 text-xs font-bold text-rose-700 hover:bg-rose-100 transition-colors cursor-pointer"
								title="Delete this submission record"
							>
								<span>🗑️</span> Delete Case
							</button>
						</div>
					{:else}
						<div></div>
					{/if}
					<button
						onclick={closeModal}
						class="rounded-[8px] bg-slate-900 px-5 py-2 text-xs font-bold text-white transition-all hover:bg-slate-800 cursor-pointer"
					>
						Close
					</button>
				</div>
			</div>
		</div>
	{/if}
</div>
