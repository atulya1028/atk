<script lang="ts">
	import type { PageData } from './$types';

	let { data } = $props<{ data: PageData }>();
	let submission = $derived(data.submission);

	function formatDate(date: Date | string | null | undefined) {
		if (!date) return 'N/A';
		return new Date(date).toLocaleString('en-US', {
			month: 'long',
			day: 'numeric',
			year: 'numeric',
			hour: 'numeric',
			minute: 'numeric',
			hour12: true
		});
	}

	let answers = $derived(
		submission.answers.map((a: any) => {
			let displayValue =
				a.legacyValueText ||
				a.valueString ||
				(typeof a.valueInt === 'number' ? String(a.valueInt) : null) ||
				a.valueText;
			if (a.choices && a.choices.length > 0) {
				displayValue = a.choices.map((c: any) => c.option.label || c.option.value).join(', ');
			}

			return {
				...a,
				displayValue,
				questionText: a.question.text,
				sectionTitle: a.question.section?.title,
				parentSectionTitle: a.question.section?.parent?.title
			};
		})
	);

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

<div class="min-h-screen bg-slate-50/30 p-10 font-sans text-slate-900">
	<div class="mx-auto max-w-4xl space-y-8">
		<!-- Header -->
		<div class="flex items-start justify-between border-b border-slate-200 bg-white p-8 rounded-xl shadow-xs">
			<div>
				<a
					href="/admin/submissions"
					class="mb-3 inline-flex items-center gap-2 text-xs font-bold text-indigo-600 transition-colors hover:text-indigo-700"
				>
					<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
						<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
					</svg>
					Back to Submissions
				</a>
				<h1 class="text-3xl font-black tracking-tight text-slate-900">Submission Technical Dossier</h1>
				<div class="mt-2 flex flex-wrap items-center gap-3 text-xs font-semibold text-slate-500">
					<span class="font-bold text-slate-900">{submission.user?.name || submission.user?.email || 'Guest Participant'}</span>
					<span class="text-slate-300">&bull;</span>
					<span class="rounded bg-slate-100 px-2 py-0.5 text-[10px] font-black tracking-wider text-slate-600 uppercase">
						{submission.surveyType === 'INITIAL' ? 'Initial (Stg 2)' : 'Detailed (Stg 3)'}
					</span>
					<span class="text-slate-300">&bull;</span>
					<span class="rounded px-2 py-0.5 text-[10px] font-black tracking-wider uppercase {submission.surveyCategory === 'MENTAL' ? 'bg-pink-50 text-pink-600' : 'bg-indigo-50 text-indigo-600'}">
						{submission.surveyCategory === 'MENTAL' ? 'Mental Health' : 'Addiction'}
					</span>
					<span class="text-slate-300">&bull;</span>
					<span>Submission #{submission.id}</span>
					<span class="text-slate-300">&bull;</span>
					<span>{formatDate(submission.startedAt)}</span>
					{#if submission.score > 0}
						<span class="text-slate-300">&bull;</span>
						<span class="font-black text-indigo-600">Score: {submission.score} pts</span>
					{/if}
				</div>
			</div>
			<div class="flex flex-col items-end gap-3">
				<div class="flex items-center gap-2">
					<a
						href={`/admin/submissions/${submission.id}/pdf?autoprint=true`}
						target="_blank"
						class="rounded-[8px] bg-indigo-50 border border-indigo-200 px-3 py-1.5 text-xs font-bold text-indigo-700 hover:bg-indigo-100 transition-colors cursor-pointer print:hidden flex items-center gap-1.5"
						title="Download or Print PDF Clinical Summary"
					>
						<span>📄</span> Download PDF
					</a>
					<form
						method="POST"
						action="?/deleteSubmission"
						onsubmit={(e) => {
							if (!confirm(`Are you sure you want to permanently delete submission #${submission.id}? All associated answers will be deleted.`)) {
								e.preventDefault();
							}
						}}
					>
						<button
							type="submit"
							class="rounded-[8px] bg-rose-50 border border-rose-200 px-3 py-1.5 text-xs font-bold text-rose-700 hover:bg-rose-100 transition-colors cursor-pointer print:hidden flex items-center gap-1.5"
							title="Delete this submission"
						>
							<span>🗑️</span> Delete
						</button>
					</form>
					<span
						class={`rounded-full border px-3 py-1 text-[10px] font-black tracking-widest uppercase ${
							submission.status?.toUpperCase() === 'COMPLETED'
								? 'border-emerald-200 bg-emerald-50 text-emerald-700'
								: 'border-amber-200 bg-amber-50 text-amber-700'
						}`}
					>
						{submission.status}
					</span>
				</div>
				<span class="inline-flex items-center rounded-full border px-2.5 py-0.5 text-[10px] font-black tracking-wider uppercase {getTriageBadge(submission.triageStatus || 'NEW')}">
					Triage: {(submission.triageStatus || 'NEW').replace('_', ' ')}
				</span>
			</div>
		</div>

		<!-- Clinical Case Triage Management Box -->
		<div class="rounded-xl border border-indigo-100 bg-white p-6 shadow-xs space-y-4">
			<div class="border-b border-slate-100 pb-3 flex items-center justify-between">
				<h2 class="text-xs font-black uppercase tracking-wider text-slate-800 flex items-center gap-2">
					<span>📋</span> Clinical Triage & Case Allocation
				</h2>
				{#if submission.assignedDoctor}
					<span class="text-xs font-bold text-indigo-600">Assigned: Dr. {submission.assignedDoctor.name || submission.assignedDoctor.email}</span>
				{/if}
			</div>

			<form method="POST" action="?/updateTriage" class="space-y-4">
				<div class="grid grid-cols-2 gap-4">
					<div>
						<label for="triage-status" class="block text-[10px] font-black uppercase tracking-wider text-slate-500 mb-1">
							Update Status
						</label>
						<select
							id="triage-status"
							name="triageStatus"
							value={submission.triageStatus || 'NEW'}
							class="w-full rounded-[8px] border border-slate-200 bg-white px-3 py-2 text-xs font-semibold focus:ring-1 focus:ring-indigo-500 focus:outline-none"
						>
							<option value="NEW">NEW (Awaiting Triage)</option>
							<option value="IN_REVIEW">IN_REVIEW</option>
							<option value="CONTACTED">CONTACTED (Followed Up)</option>
							<option value="ASSIGNED">ASSIGNED to Doctor</option>
							<option value="RESOLVED">RESOLVED (Case Closed)</option>
						</select>
					</div>

					<div>
						<label for="triage-doctor" class="block text-[10px] font-black uppercase tracking-wider text-slate-500 mb-1">
							Assign Practitioner
						</label>
						<select
							id="triage-doctor"
							name="assignedDoctorId"
							value={submission.assignedDoctorId || ''}
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
					<label for="triage-notes" class="block text-[10px] font-black uppercase tracking-wider text-slate-500 mb-1">
						Clinical Review Remarks / Progress Notes
					</label>
					<textarea
						id="triage-notes"
						name="clinicalNotes"
						rows="2"
						placeholder="Document participant contact, referrals, or assessment outcomes..."
						class="w-full rounded-[8px] border border-slate-200 px-3 py-2 text-xs font-medium focus:ring-1 focus:ring-indigo-500 focus:outline-none"
					>{submission.clinicalNotes || ''}</textarea>
				</div>

				<div class="flex justify-end">
					<button
						type="submit"
						class="rounded-[8px] bg-indigo-600 px-5 py-2 text-xs font-bold text-white hover:bg-indigo-700 cursor-pointer"
					>
						Update Case Triage
					</button>
				</div>
			</form>
		</div>

		<!-- Participant Demographics Card -->
		{#if submission.user}
			<div class="rounded-xl border border-slate-200 bg-white p-6 shadow-xs">
				<h3 class="text-xs font-black uppercase tracking-wider text-slate-400 mb-4">Participant Identifying Record</h3>
				<div class="grid grid-cols-4 gap-4 text-xs">
					<div class="rounded-lg bg-slate-50 p-3">
						<span class="text-[9px] font-bold text-slate-400 uppercase">Full Name</span>
						<p class="font-bold text-slate-800">{submission.user.name || 'Not provided'}</p>
					</div>
					<div class="rounded-lg bg-slate-50 p-3">
						<span class="text-[9px] font-bold text-slate-400 uppercase">Email</span>
						<p class="font-bold text-slate-800 truncate">{submission.user.email}</p>
					</div>
					<div class="rounded-lg bg-slate-50 p-3">
						<span class="text-[9px] font-bold text-slate-400 uppercase">Phone</span>
						<p class="font-bold text-slate-800">{submission.user.phoneNumber || 'Not provided'}</p>
					</div>
					<div class="rounded-lg bg-slate-50 p-3">
						<span class="text-[9px] font-bold text-slate-400 uppercase">Postcode</span>
						<p class="font-bold text-slate-800 font-mono">{submission.user.pinCode || 'Not provided'}</p>
					</div>
				</div>
			</div>
		{/if}

		<!-- Question & Answer Breakdown -->
		<div class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-xs">
			<div class="bg-slate-50 px-8 py-4 border-b border-slate-100 flex items-center justify-between">
				<h2 class="text-xs font-black uppercase tracking-wider text-slate-700">Detailed Questionnaire Responses ({answers.length})</h2>
				<span class="text-[10px] font-bold text-slate-400">Order by submission timeline</span>
			</div>
			{#if answers.length === 0}
				<div class="p-20 text-center font-medium text-slate-400 italic">
					No answers recorded for this submission.
				</div>
			{:else}
				<div class="divide-y divide-slate-100">
					{#each answers as answer, i}
						<div class="p-6 transition-colors hover:bg-slate-50/50">
							<div class="mb-3 flex items-start justify-between gap-6">
								<div class="flex items-start gap-2">
									<span class="text-xs font-mono font-bold text-slate-300">{i + 1}.</span>
									<h3 class="text-xs font-bold leading-relaxed text-slate-600">
										{answer.questionText}
									</h3>
								</div>
								{#if answer.sectionTitle}
									<span class="inline-flex shrink-0 items-center gap-1 rounded bg-slate-100 px-2 py-0.5 text-[9px] font-bold text-slate-500 uppercase">
										{#if answer.parentSectionTitle}
											<span class="opacity-60">{answer.parentSectionTitle} /</span>
										{/if}
										<span class="text-indigo-600">{answer.sectionTitle}</span>
									</span>
								{/if}
							</div>

							<div class="ml-5 text-sm font-bold text-slate-900 bg-slate-50 p-3 rounded-lg border border-slate-100">
								{answer.displayValue || '-'}
							</div>
						</div>
					{/each}
				</div>
			{/if}
		</div>
	</div>
</div>
