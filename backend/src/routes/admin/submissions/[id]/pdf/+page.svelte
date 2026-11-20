<script lang="ts">
	import { onMount } from 'svelte';
	import type { PageData } from './$types';

	let { data } = $props<{ data: PageData }>();
	let submission = $derived(data.submission);

	onMount(() => {
		if (typeof window !== 'undefined' && window.location.search.includes('autoprint=true')) {
			setTimeout(() => {
				window.print();
			}, 400);
		}
	});

	function formatDate(d: string | null | undefined) {
		if (!d) return 'N/A';
		return new Date(d).toLocaleString('en-GB', {
			day: '2-digit',
			month: 'short',
			year: 'numeric',
			hour: '2-digit',
			minute: '2-digit'
		});
	}

	let answers = $derived(
		submission.answers.map((a: any) => {
			let displayValue =
				a.legacyValueText ||
				a.valueString ||
				(typeof a.valueInt === 'number' ? String(a.valueInt) : null) ||
				a.valueText;
			let score = 0;
			if (a.choices && a.choices.length > 0) {
				displayValue = a.choices.map((c: any) => c.option.label || c.option.value).join(', ');
				score = a.choices.reduce((sum: number, c: any) => sum + (c.option?.scoreValue || 0), 0);
			}

			return {
				...a,
				displayValue,
				score,
				questionText: a.question.text,
				sectionTitle: a.question.section?.title,
				parentSectionTitle: a.question.section?.parent?.title
			};
		})
	);
</script>

<svelte:head>
	<title>Clinical Assessment Dossier - #{submission.id} - {submission.user?.email}</title>
</svelte:head>

<div class="min-h-screen bg-slate-100 p-6 print:bg-white print:p-0 font-sans text-slate-900">
	<!-- Print Navigation Bar (Hidden when printing) -->
	<div class="max-w-4xl mx-auto mb-6 flex items-center justify-between rounded-xl bg-white p-4 shadow-sm border border-slate-200 print:hidden">
		<div class="flex items-center gap-3">
			<a
				href={`/admin/submissions/${submission.id}`}
				class="inline-flex items-center gap-1.5 rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-xs font-bold text-slate-700 hover:bg-slate-50"
			>
				&larr; Back to Dossier
			</a>
			<span class="text-xs text-slate-400">|</span>
			<span class="text-xs font-bold text-slate-700">Clinical Summary Report: Submission #{submission.id}</span>
		</div>

		<button
			onclick={() => window.print()}
			class="flex items-center gap-2 rounded-lg bg-indigo-600 px-5 py-2 text-xs font-bold text-white shadow-sm hover:bg-indigo-700 cursor-pointer"
		>
			<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
				<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z" />
			</svg>
			Print / Save as PDF
		</button>
	</div>

	<!-- Printable A4 Document Sheet -->
	<div class="max-w-4xl mx-auto bg-white p-10 rounded-2xl shadow-md border border-slate-200 print:shadow-none print:border-none print:p-0 print:max-w-none print:rounded-none">
		<!-- Header -->
		<div class="border-b-2 border-slate-900 pb-6 mb-6">
			<div class="flex items-start justify-between">
				<div>
					<div class="flex items-center gap-2 mb-1">
						<span class="bg-indigo-600 text-white font-black text-xs px-2 py-0.5 rounded tracking-wider uppercase">ATK Clinical</span>
						<span class="text-xs font-bold text-slate-400 uppercase tracking-widest">Medical Assessment Summary</span>
					</div>
					<h1 class="text-2xl font-black text-slate-900 tracking-tight">Patient Assessment & Triage Dossier</h1>
					<p class="text-xs text-slate-500 font-medium">Novtek Healthcare Diagnostic & Wellbeing Protocol</p>
				</div>
				<div class="text-right">
					<span class="inline-block border border-slate-900 px-3 py-1 text-[10px] font-black uppercase tracking-widest text-slate-900 mb-1">
						Confidential Medical Record
					</span>
					<p class="text-xs font-mono font-bold text-slate-600">REF: #ATK-REP-{submission.id}</p>
					<p class="text-[10px] text-slate-400">Generated: {new Date().toLocaleDateString('en-GB')}</p>
				</div>
			</div>
		</div>

		<!-- Risk Alert Banner (If Critical) -->
		{#if data.isCritical}
			<div class="mb-6 rounded-lg border-2 border-rose-500 bg-rose-50 p-4 text-rose-900">
				<div class="flex items-center gap-2 font-black text-sm uppercase tracking-wider">
					<span>🚨</span>
					<span>High Clinical Risk Alert Flagged</span>
				</div>
				<p class="mt-1 text-xs text-rose-800 leading-relaxed font-medium">
					This assessment score ({submission.score} pts) meets or exceeds the critical severity threshold ({data.criticalValue} pts). Immediate clinician review and targeted outreach recommended.
				</p>
			</div>
		{/if}

		<!-- Grid: Patient Info & Clinical Score -->
		<div class="grid grid-cols-2 gap-6 mb-6">
			<!-- Patient Identification Block -->
			<div class="rounded-xl border border-slate-200 p-4 bg-slate-50/50">
				<h2 class="text-[10px] font-black uppercase tracking-wider text-slate-400 mb-3 border-b border-slate-200 pb-1.5">
					Participant Identification
				</h2>
				<table class="w-full text-xs">
					<tbody>
						<tr class="border-b border-slate-100">
							<td class="py-1.5 font-bold text-slate-500 w-32">Full Name:</td>
							<td class="py-1.5 font-bold text-slate-800">{submission.user?.name || 'Not provided'}</td>
						</tr>
						<tr class="border-b border-slate-100">
							<td class="py-1.5 font-bold text-slate-500">Email Address:</td>
							<td class="py-1.5 font-mono text-slate-800">{submission.user?.email || 'N/A'}</td>
						</tr>
						<tr class="border-b border-slate-100">
							<td class="py-1.5 font-bold text-slate-500">Contact Number:</td>
							<td class="py-1.5 font-bold text-slate-800">{submission.user?.phoneNumber || 'N/A'}</td>
						</tr>
						<tr class="border-b border-slate-100">
							<td class="py-1.5 font-bold text-slate-500">Postcode / Territory:</td>
							<td class="py-1.5 font-mono font-bold text-slate-800">{submission.user?.pinCode || 'N/A'}</td>
						</tr>
						<tr>
							<td class="py-1.5 font-bold text-slate-500">Age / Gender:</td>
							<td class="py-1.5 font-bold text-slate-800">{submission.user?.age || 'N/A'} / {submission.user?.gender || 'N/A'}</td>
						</tr>
					</tbody>
				</table>
			</div>

			<!-- Evaluation & Triage Block -->
			<div class="rounded-xl border border-slate-200 p-4 bg-slate-50/50">
				<h2 class="text-[10px] font-black uppercase tracking-wider text-slate-400 mb-3 border-b border-slate-200 pb-1.5">
					Evaluation & Triage Summary
				</h2>
				<table class="w-full text-xs">
					<tbody>
						<tr class="border-b border-slate-100">
							<td class="py-1.5 font-bold text-slate-500 w-32">Pathway Track:</td>
							<td class="py-1.5 font-black uppercase {submission.surveyCategory === 'MENTAL' ? 'text-pink-600' : 'text-indigo-600'}">
								{submission.surveyCategory === 'MENTAL' ? 'Mental Health' : 'Addiction Recovery'}
							</td>
						</tr>
						<tr class="border-b border-slate-100">
							<td class="py-1.5 font-bold text-slate-500">Clinical Stage:</td>
							<td class="py-1.5 font-bold text-slate-800">
								{submission.surveyType === 'INITIAL' ? 'Stage 2 Initial Screening' : 'Stage 3 Detailed Assessment'}
							</td>
						</tr>
						<tr class="border-b border-slate-100">
							<td class="py-1.5 font-bold text-slate-500">Assessment Score:</td>
							<td class="py-1.5 font-black text-sm {data.isCritical ? 'text-rose-600' : 'text-indigo-600'}">
								{submission.score} pts
							</td>
						</tr>
						<tr class="border-b border-slate-100">
							<td class="py-1.5 font-bold text-slate-500">Triage Status:</td>
							<td class="py-1.5 font-bold text-slate-800">
								<span class="inline-block px-2 py-0.5 rounded bg-slate-200 text-[10px] font-black uppercase">
									{(submission.triageStatus || 'NEW').replace('_', ' ')}
								</span>
							</td>
						</tr>
						<tr>
							<td class="py-1.5 font-bold text-slate-500">Assigned Doctor:</td>
							<td class="py-1.5 font-bold text-slate-800">
								{submission.assignedDoctor ? `Dr. ${submission.assignedDoctor.name || submission.assignedDoctor.email}` : 'Unassigned'}
							</td>
						</tr>
					</tbody>
				</table>
			</div>
		</div>

		<!-- Clinical Progress Notes (If any) -->
		{#if submission.clinicalNotes}
			<div class="mb-6 rounded-xl border border-slate-200 bg-slate-50 p-4">
				<h3 class="text-[10px] font-black uppercase tracking-wider text-slate-400 mb-1">
					Clinical Progress Remarks & Case Notes
				</h3>
				<p class="text-xs text-slate-800 leading-relaxed font-medium">
					{submission.clinicalNotes}
				</p>
			</div>
		{/if}

		<!-- Question & Answer Clinical Log Table -->
		<div class="mb-8">
			<h2 class="text-xs font-black uppercase tracking-wider text-slate-900 mb-3 border-b border-slate-200 pb-2 flex items-center justify-between">
				<span>Assessment Protocol Responses</span>
				<span class="text-[10px] font-semibold text-slate-400">{answers.length} Questions Answered</span>
			</h2>

			<table class="w-full text-left text-xs border border-slate-200 rounded-lg overflow-hidden">
				<thead>
					<tr class="bg-slate-100 border-b border-slate-200 text-[9px] font-black uppercase tracking-wider text-slate-600">
						<th class="py-2.5 px-3 w-8">#</th>
						<th class="py-2.5 px-3">Assessment Question</th>
						<th class="py-2.5 px-3 w-40">Section / Context</th>
						<th class="py-2.5 px-3">Recorded Response</th>
						<th class="py-2.5 px-3 text-right w-16">Points</th>
					</tr>
				</thead>
				<tbody class="divide-y divide-slate-100">
					{#each answers as answer, i}
						<tr class="hover:bg-slate-50/50 page-break-inside-avoid">
							<td class="py-2.5 px-3 font-mono text-slate-400 font-bold">{i + 1}</td>
							<td class="py-2.5 px-3 font-semibold text-slate-800 leading-snug">{answer.questionText}</td>
							<td class="py-2.5 px-3 text-[10px] text-slate-500 font-medium">{answer.sectionTitle || 'General'}</td>
							<td class="py-2.5 px-3 font-bold text-slate-900">{answer.displayValue || '-'}</td>
							<td class="py-2.5 px-3 text-right font-mono font-bold {answer.score > 0 ? 'text-indigo-600' : 'text-slate-400'}">
								{answer.score > 0 ? `+${answer.score}` : '0'}
							</td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>

		<!-- Sign-off & Medical Disclaimer Footer -->
		<div class="pt-6 border-t-2 border-slate-200 page-break-inside-avoid">
			<div class="grid grid-cols-2 gap-10 mb-6 text-xs">
				<div>
					<p class="font-bold text-slate-400 text-[10px] uppercase mb-4">Reviewing Medical Practitioner</p>
					<div class="border-b border-slate-400 w-48 mb-1"></div>
					<p class="text-[10px] text-slate-500">Signature / Registration Stamp</p>
				</div>
				<div>
					<p class="font-bold text-slate-400 text-[10px] uppercase mb-4">Date of Clinical Sign-off</p>
					<div class="border-b border-slate-400 w-36 mb-1"></div>
					<p class="text-[10px] text-slate-500">Date (DD / MM / YYYY)</p>
				</div>
			</div>

			<div class="text-[9px] text-slate-400 leading-normal border-t border-slate-100 pt-3">
				<p>
					<strong>MEDICAL CONFIDENTIALITY NOTICE:</strong> This document contains sensitive medical assessment data intended solely for clinical review, case management, and healthcare triage by authorized medical personnel. Any unauthorized copying, distribution, or disclosure is strictly prohibited under data protection and health privacy regulations (UK Data Protection Act / GDPR).
				</p>
			</div>
		</div>
	</div>
</div>

<style>
	@media print {
		@page {
			size: A4 portrait;
			margin: 12mm;
		}
		body {
			background: white !important;
			color: black !important;
		}
		.page-break-inside-avoid {
			page-break-inside: avoid;
			break-inside: avoid;
		}
	}
</style>
