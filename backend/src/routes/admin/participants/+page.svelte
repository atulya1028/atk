<script lang="ts">
	import type { PageData } from './$types';
	let { data } = $props<{ data: PageData }>();

	let searchTerm = $state('');
	let selectedParticipant = $state<any | null>(null);
	let editingParticipant = $state<any | null>(null);
	let isAddModalOpen = $state(false);

	function getRelativeTime(dateString: string) {
		if (!dateString) return 'Never';
		const date = new Date(dateString);
		const now = new Date();
		const diffInSeconds = Math.floor((now.getTime() - date.getTime()) / 1000);

		if (diffInSeconds < 60) return 'Just now';
		if (diffInSeconds < 3600) return `${Math.floor(diffInSeconds / 60)}m ago`;
		if (diffInSeconds < 86400) return `${Math.floor(diffInSeconds / 3600)}h ago`;
		return `${Math.floor(diffInSeconds / 86400)}d ago`;
	}

	async function deleteParticipant(id: number, email: string) {
		if (
			!confirm(
				`Are you sure you want to delete participant ${email}? This action cannot be undone.`
			)
		)
			return;

		const formData = new FormData();
		formData.append('id', String(id));

		await fetch('?/deleteParticipant', {
			method: 'POST',
			body: formData
		});
		window.location.reload();
	}

	async function resetSurvey(id: number, email: string) {
		if (
			!confirm(
				`Are you sure you want to RESET all survey progress for participant ${email}? All their assessment submissions will be deleted and they will be unlocked to retake from Stage 2.`
			)
		) {
			return;
		}

		const formData = new FormData();
		formData.append('id', String(id));

		const res = await fetch('?/resetParticipantSurvey', {
			method: 'POST',
			body: formData
		});

		if (res.ok) {
			alert(`Survey progress reset successfully for ${email}.`);
			window.location.reload();
		} else {
			alert('Failed to reset survey progress.');
		}
	}

	function openEditModal(p: any) {
		editingParticipant = { ...p };
	}

	function closeModals() {
		editingParticipant = null;
		isAddModalOpen = false;
	}

	let filteredParticipants = $derived(
		data.participants.filter(
			(p: any) =>
				p.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
				(p.name && p.name.toLowerCase().includes(searchTerm.toLowerCase())) ||
				(p.pinCode && p.pinCode.toLowerCase().includes(searchTerm.toLowerCase()))
		)
	);
</script>

<div class="flex h-full flex-col bg-white">
	<div
		class="flex shrink-0 items-center justify-between gap-6 border-b border-slate-100 bg-white px-10 py-6"
	>
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
				placeholder="Search by name, email, or postcode..."
				class="w-full rounded-[8px] border border-slate-200 bg-slate-50 py-2.5 pr-4 pl-11 text-xs font-semibold transition-all focus:bg-white focus:ring-1 focus:ring-indigo-500 focus:outline-none"
				bind:value={searchTerm}
			/>
		</div>

		<div class="flex items-center gap-4 text-xs font-bold text-slate-500">
			<span>Total Participants: <strong class="text-slate-900">{data.participants.length}</strong></span>
			<button
				onclick={() => (isAddModalOpen = true)}
				class="rounded-lg bg-indigo-600 px-4 py-2 text-xs font-bold text-white shadow-xs hover:bg-indigo-700 transition-colors flex items-center gap-2 cursor-pointer"
			>
				<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
					<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
				</svg>
				<span>Add Participant</span>
			</button>
		</div>
	</div>

	<div class="flex-1 overflow-auto p-10">
		<div class="overflow-hidden rounded-[8px] border border-slate-200 bg-white">
			<table class="w-full border-collapse text-left">
				<thead>
					<tr class="border-b border-slate-100 bg-slate-50/50">
						<th class="px-8 py-5 text-[10px] font-black tracking-[0.2em] text-slate-400 uppercase"
							>Participant</th
						>
						<th class="px-8 py-5 text-[10px] font-black tracking-[0.2em] text-slate-400 uppercase"
							>Postcode / Contact</th
						>
						<th class="px-8 py-5 text-[10px] font-black tracking-[0.2em] text-slate-400 uppercase"
							>Joined</th
						>
						<th class="px-8 py-5 text-[10px] font-black tracking-[0.2em] text-slate-400 uppercase"
							>Submissions</th
						>
						<th class="px-8 py-5 text-[10px] font-black tracking-[0.2em] text-slate-400 uppercase"
							>Latest Activity</th
						>
						<th
							class="px-8 py-5 text-right text-[10px] font-black tracking-[0.2em] text-slate-400 uppercase"
							>Actions</th
						>
					</tr>
				</thead>
				<tbody class="divide-y divide-slate-50">
					{#each filteredParticipants as p}
						<tr class="group transition-colors hover:bg-slate-50/50">
							<td class="px-8 py-6">
								<div class="flex items-center gap-3">
									<div
										class="flex h-10 w-10 shrink-0 items-center justify-center rounded-[8px] bg-slate-100 text-sm font-black text-slate-500 transition-colors group-hover:bg-indigo-50 group-hover:text-indigo-600"
									>
										{(p.name || p.email)[0].toUpperCase()}
									</div>
									<div>
										<p class="text-sm font-bold text-slate-700">
											{p.name || 'Unnamed Participant'}
										</p>
										<p class="text-xs font-medium text-slate-400">{p.email}</p>
									</div>
								</div>
							</td>
							<td class="px-8 py-6">
								<div class="flex flex-col gap-0.5">
									<span class="text-xs font-bold text-slate-700 font-mono">{p.pinCode || 'No Postcode'}</span>
									<span class="text-[11px] font-medium text-slate-400">{p.phoneNumber || 'No phone'}</span>
								</div>
							</td>
							<td class="px-8 py-6">
								<p class="text-xs font-bold text-slate-500">
									{new Date(p.createdAt).toLocaleDateString()}
								</p>
							</td>
							<td class="px-8 py-6">
								<div class="flex items-center gap-2">
									<span class="text-xs font-bold text-slate-600">{p.submissions.length}</span>
									{#if p.submissions.some((s: any) => s.score >= 50)}
										<span class="h-2 w-2 rounded-full bg-rose-500" title="Has critical submissions"></span>
									{/if}
								</div>
							</td>
							<td class="px-8 py-6">
								<span class="text-xs font-bold text-slate-500">
									{p.submissions[0] ? getRelativeTime(p.submissions[0].startedAt) : 'Inactive'}
								</span>
							</td>
							<td class="space-x-1.5 px-8 py-6 text-right whitespace-nowrap">
								<button
									onclick={() => (selectedParticipant = p)}
									class="rounded-[6px] border border-slate-200 bg-white px-3 py-1.5 text-xs font-bold text-slate-600 transition-all hover:bg-slate-50 hover:text-indigo-600 cursor-pointer"
								>
									Profile
								</button>
								<button
									onclick={() => openEditModal(p)}
									class="rounded-[6px] border border-slate-200 bg-white px-3 py-1.5 text-xs font-bold text-slate-600 transition-all hover:bg-slate-50 hover:text-indigo-600 cursor-pointer"
								>
									Edit
								</button>
								<button
									onclick={() => resetSurvey(p.id, p.email)}
									class="rounded-[6px] border border-amber-200 bg-amber-50/50 px-2.5 py-1.5 text-xs font-bold text-amber-700 transition-all hover:bg-amber-100 cursor-pointer"
									title="Reset Survey Submissions"
								>
									Reset
								</button>
								<button
									onclick={() => deleteParticipant(p.id, p.email)}
									class="rounded-[6px] border border-red-100 bg-red-50/50 px-2.5 py-1.5 text-xs font-bold text-red-600 transition-all hover:bg-red-100 cursor-pointer"
									title="Delete Participant"
								>
									✕
								</button>
							</td>
						</tr>
					{:else}
						<tr>
							<td colspan="6" class="px-8 py-20 text-center">
								<div class="flex flex-col items-center opacity-40">
									<svg class="w-12 h-12 mb-4 text-slate-300" fill="none" stroke="currentColor" viewBox="0 0 24 24"
										><path
											stroke-linecap="round"
											stroke-linejoin="round"
											stroke-width="2"
											d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"
										/></svg
									>
									<p class="font-bold text-slate-500">No participants found.</p>
								</div>
							</td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
	</div>
</div>

<!-- Participant Details Modal -->
{#if selectedParticipant}
	<div
		class="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/40 p-6 backdrop-blur-xs"
	>
		<div
			class="flex max-h-[90vh] w-full max-w-lg flex-col overflow-hidden rounded-[16px] bg-white shadow-xl border border-slate-200"
		>
			<div class="flex items-center justify-between border-b border-slate-100 px-8 py-5">
				<div>
					<h2 class="text-sm font-black tracking-wider text-slate-900 uppercase">Participant Profile</h2>
					<p class="text-xs font-semibold text-slate-400">
						Clinical record & demographic data
					</p>
				</div>
				<button
					onclick={() => (selectedParticipant = null)}
					class="text-slate-400 hover:text-slate-600 cursor-pointer text-sm"
				>
					✕
				</button>
			</div>

			<div class="flex-1 space-y-6 overflow-y-auto p-8">
				<div class="flex items-center gap-4">
					<div
						class="flex h-14 w-14 items-center justify-center rounded-[12px] bg-indigo-50 text-xl font-black text-indigo-600"
					>
						{(selectedParticipant.name || selectedParticipant.email)[0].toUpperCase()}
					</div>
					<div>
						<h3 class="text-base font-black text-slate-900">
							{selectedParticipant.name || 'Unnamed Participant'}
						</h3>
						<p class="text-xs font-bold text-indigo-600">{selectedParticipant.email}</p>
					</div>
				</div>

				<div class="grid grid-cols-2 gap-3">
					<div class="rounded-[8px] border border-slate-100 bg-slate-50 p-3">
						<p class="mb-0.5 text-[9px] font-black tracking-widest text-slate-400 uppercase">Age</p>
						<p class="text-xs font-bold text-slate-700">
							{selectedParticipant.age || 'Not provided'}
						</p>
					</div>
					<div class="rounded-[8px] border border-slate-100 bg-slate-50 p-3">
						<p class="mb-0.5 text-[9px] font-black tracking-widest text-slate-400 uppercase">
							Gender
						</p>
						<p class="text-xs font-bold text-slate-700">
							{selectedParticipant.gender || 'Not provided'}
						</p>
					</div>
					<div class="rounded-[8px] border border-slate-100 bg-slate-50 p-3">
						<p class="mb-0.5 text-[9px] font-black tracking-widest text-slate-400 uppercase">
							Phone Number
						</p>
						<p class="text-xs font-bold text-slate-700">
							{selectedParticipant.phoneNumber || 'Not provided'}
						</p>
					</div>
					<div class="rounded-[8px] border border-slate-100 bg-slate-50 p-3">
						<p class="mb-0.5 text-[9px] font-black tracking-widest text-slate-400 uppercase">
							Postcode / Pincode
						</p>
						<p class="text-xs font-bold text-slate-700 font-mono">
							{selectedParticipant.pinCode || 'Not provided'}
						</p>
					</div>
					<div class="rounded-[8px] border border-slate-100 bg-slate-50 p-3">
						<p class="mb-0.5 text-[9px] font-black tracking-widest text-slate-400 uppercase">
							Occupation
						</p>
						<p class="text-xs font-bold text-slate-700">
							{selectedParticipant.occupation || 'Not provided'}
						</p>
					</div>
					<div class="rounded-[8px] border border-slate-100 bg-slate-50 p-3">
						<p class="mb-0.5 text-[9px] font-black tracking-widest text-slate-400 uppercase">
							Marital Status
						</p>
						<p class="text-xs font-bold text-slate-700">
							{selectedParticipant.maritalStatus || 'Not provided'}
						</p>
					</div>
				</div>

				<div class="rounded-[10px] border border-indigo-100 bg-indigo-50/50 p-5">
					<h4 class="mb-3 text-[10px] font-black tracking-widest text-indigo-900 uppercase">
						Clinical Assessment History
					</h4>
					<div class="space-y-2.5">
						<div class="flex items-center justify-between text-xs">
							<span class="font-bold text-indigo-600 opacity-60">Joined Platform</span>
							<span class="font-black text-indigo-900"
								>{new Date(selectedParticipant.createdAt).toLocaleString()}</span
							>
						</div>
						<div class="flex items-center justify-between text-xs">
							<span class="font-bold text-indigo-600 opacity-60">Addiction Submissions</span>
							<span class="font-black text-indigo-900"
								>{selectedParticipant.submissions.filter((s: any) => s.surveyCategory === 'ADDICTION' || !s.surveyCategory).length}</span
							>
						</div>
						<div class="flex items-center justify-between text-xs">
							<span class="font-bold text-indigo-600 opacity-60">Mental Health Submissions</span>
							<span class="font-black text-indigo-900"
								>{selectedParticipant.submissions.filter((s: any) => s.surveyCategory === 'MENTAL').length}</span
							>
						</div>
						<div class="flex items-center justify-between text-xs pt-2 border-t border-indigo-100/60">
							<span class="font-bold text-red-600 flex items-center gap-1">
								<span>🚨</span> Critical Addiction Risk
							</span>
							<span class="font-black text-red-700 bg-red-50 px-2 py-0.5 rounded-[4px]">
								{selectedParticipant.submissions.filter((s: any) => {
									const isAddiction = s.surveyCategory === 'ADDICTION' || !s.surveyCategory;
									if (!isAddiction) return false;
									const categorySettings = data.settings.find((setting: any) => setting.surveyCategory === 'ADDICTION');
									const criticalValue = categorySettings?.criticalValue ?? 50;
									return s.surveyType === 'DETAILED' && s.score >= criticalValue;
								}).length}
							</span>
						</div>
						<div class="flex items-center justify-between text-xs">
							<span class="font-bold text-red-600 flex items-center gap-1">
								<span>🚨</span> Critical Mental Health Risk
							</span>
							<span class="font-black text-red-700 bg-red-50 px-2 py-0.5 rounded-[4px]">
								{selectedParticipant.submissions.filter((s: any) => {
									return s.surveyCategory === 'MENTAL' && s.surveyType === 'DETAILED' && s.score >= (data.settings.find((setting: any) => setting.surveyCategory === 'MENTAL')?.criticalValue ?? 50);
								}).length}
							</span>
						</div>
					</div>
				</div>
			</div>

			<div class="flex items-center justify-between border-t border-slate-100 bg-slate-50 px-8 py-4">
				<button
					onclick={() => { const p = selectedParticipant; selectedParticipant = null; resetSurvey(p.id, p.email); }}
					class="text-xs font-bold text-amber-700 hover:text-amber-800 cursor-pointer"
				>
					Reset Assessment
				</button>
				<button
					onclick={() => (selectedParticipant = null)}
					class="rounded-[8px] bg-slate-900 px-5 py-2 text-xs font-bold text-white hover:bg-slate-800 cursor-pointer"
				>
					Close
				</button>
			</div>
		</div>
	</div>
{/if}

<!-- Edit Demographic Profile Modal -->
{#if editingParticipant}
	<div class="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/40 p-4 backdrop-blur-xs">
		<div class="w-full max-w-md rounded-xl border border-slate-200 bg-white shadow-xl overflow-hidden animate-in fade-in zoom-in-95 duration-200">
			<div class="flex items-center justify-between border-b border-slate-100 px-6 py-4">
				<h3 class="text-sm font-black text-slate-900 uppercase tracking-wider">Edit Participant Profile</h3>
				<button onclick={closeModals} class="text-slate-400 hover:text-slate-600 cursor-pointer text-sm">✕</button>
			</div>

			<form method="POST" action="?/updateParticipant" class="p-6 space-y-4">
				<input type="hidden" name="id" value={editingParticipant.id} />

				<div>
					<label for="edit-part-email" class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">Email (Read-only)</label>
					<input
						id="edit-part-email"
						type="email"
						value={editingParticipant.email}
						disabled
						class="w-full rounded-[8px] border border-slate-200 bg-slate-50 px-3 py-2 text-xs font-semibold text-slate-500"
					/>
				</div>

				<div>
					<label for="edit-part-name" class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">Participant Name</label>
					<input
						id="edit-part-name"
						type="text"
						name="name"
						bind:value={editingParticipant.name}
						placeholder="Full Name"
						class="w-full rounded-[8px] border border-slate-200 px-3 py-2 text-xs font-semibold focus:ring-1 focus:ring-indigo-500 focus:outline-none"
					/>
				</div>

				<div class="grid grid-cols-2 gap-4">
					<div>
						<label for="edit-part-phone" class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">Phone Number</label>
						<input
							id="edit-part-phone"
							type="text"
							name="phoneNumber"
							bind:value={editingParticipant.phoneNumber}
							placeholder="+44 7911..."
							class="w-full rounded-[8px] border border-slate-200 px-3 py-2 text-xs font-semibold focus:ring-1 focus:ring-indigo-500 focus:outline-none"
						/>
					</div>
					<div>
						<label for="edit-part-pincode" class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">Postcode / Pincode</label>
						<input
							id="edit-part-pincode"
							type="text"
							name="pinCode"
							bind:value={editingParticipant.pinCode}
							placeholder="SW1A 1AA"
							class="w-full rounded-[8px] border border-slate-200 px-3 py-2 text-xs font-semibold focus:ring-1 focus:ring-indigo-500 focus:outline-none"
						/>
					</div>
				</div>

				<div class="grid grid-cols-2 gap-4">
					<div>
						<label for="edit-part-age" class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">Age Bracket / Age</label>
						<input
							id="edit-part-age"
							type="text"
							name="age"
							bind:value={editingParticipant.age}
							placeholder="25-34 or 28"
							class="w-full rounded-[8px] border border-slate-200 px-3 py-2 text-xs font-semibold focus:ring-1 focus:ring-indigo-500 focus:outline-none"
						/>
					</div>
					<div>
						<label for="edit-part-gender" class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">Gender</label>
						<input
							id="edit-part-gender"
							type="text"
							name="gender"
							bind:value={editingParticipant.gender}
							placeholder="Male, Female, Non-binary"
							class="w-full rounded-[8px] border border-slate-200 px-3 py-2 text-xs font-semibold focus:ring-1 focus:ring-indigo-500 focus:outline-none"
						/>
					</div>
				</div>

				<div class="grid grid-cols-2 gap-4">
					<div>
						<label for="edit-part-occupation" class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">Occupation</label>
						<input
							id="edit-part-occupation"
							type="text"
							name="occupation"
							bind:value={editingParticipant.occupation}
							placeholder="Employed, Student..."
							class="w-full rounded-[8px] border border-slate-200 px-3 py-2 text-xs font-semibold focus:ring-1 focus:ring-indigo-500 focus:outline-none"
						/>
					</div>
					<div>
						<label for="edit-part-marital" class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">Marital Status</label>
						<input
							id="edit-part-marital"
							type="text"
							name="maritalStatus"
							bind:value={editingParticipant.maritalStatus}
							placeholder="Single, Married..."
							class="w-full rounded-[8px] border border-slate-200 px-3 py-2 text-xs font-semibold focus:ring-1 focus:ring-indigo-500 focus:outline-none"
						/>
					</div>
				</div>

				<div class="flex items-center justify-end gap-3 pt-4 border-t border-slate-100">
					<button
						type="button"
						onclick={closeModals}
						class="rounded-[8px] border border-slate-200 px-4 py-2 text-xs font-bold text-slate-600 hover:bg-slate-50 cursor-pointer"
					>
						Cancel
					</button>
					<button
						type="submit"
						class="rounded-[8px] bg-indigo-600 px-5 py-2 text-xs font-bold text-white hover:bg-indigo-700 cursor-pointer"
					>
						Save Changes
					</button>
				</div>
			</form>
		</div>
	</div>
{/if}

<!-- Add Participant Modal -->
{#if isAddModalOpen}
	<div class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-xs">
		<div class="w-full max-w-lg rounded-2xl bg-white shadow-2xl border border-slate-100 overflow-hidden">
			<div class="flex items-center justify-between border-b border-slate-100 px-6 py-4">
				<h3 class="text-sm font-black uppercase tracking-wider text-slate-800">
					Add / Enroll New Participant
				</h3>
				<button onclick={closeModals} class="rounded-lg p-1.5 text-slate-400 hover:text-slate-600 cursor-pointer">
					✕
				</button>
			</div>

			<form method="POST" action="?/createParticipant" class="p-6 space-y-4">
				<div class="grid grid-cols-2 gap-4">
					<div class="col-span-2">
						<label for="new-part-email" class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">Email Address *</label>
						<input
							id="new-part-email"
							type="email"
							name="email"
							required
							placeholder="participant@example.com"
							class="w-full rounded-[8px] border border-slate-200 px-3 py-2 text-xs font-semibold focus:ring-1 focus:ring-indigo-500 focus:outline-none"
						/>
					</div>
					<div>
						<label for="new-part-name" class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">Full Name</label>
						<input
							id="new-part-name"
							type="text"
							name="name"
							placeholder="John Doe"
							class="w-full rounded-[8px] border border-slate-200 px-3 py-2 text-xs font-semibold focus:ring-1 focus:ring-indigo-500 focus:outline-none"
						/>
					</div>
					<div>
						<label for="new-part-phone" class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">Phone Number</label>
						<input
							id="new-part-phone"
							type="text"
							name="phoneNumber"
							placeholder="+44 7700 900077"
							class="w-full rounded-[8px] border border-slate-200 px-3 py-2 text-xs font-semibold focus:ring-1 focus:ring-indigo-500 focus:outline-none"
						/>
					</div>
					<div>
						<label for="new-part-pincode" class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">Postcode / Pincode</label>
						<input
							id="new-part-pincode"
							type="text"
							name="pinCode"
							placeholder="SW1A 1AA"
							class="w-full rounded-[8px] border border-slate-200 px-3 py-2 text-xs font-semibold focus:ring-1 focus:ring-indigo-500 focus:outline-none font-mono"
						/>
					</div>
					<div>
						<label for="new-part-category" class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">Clinical Pathway</label>
						<select
							id="new-part-category"
							name="surveyCategory"
							class="w-full rounded-[8px] border border-slate-200 bg-white px-3 py-2 text-xs font-semibold focus:ring-1 focus:ring-indigo-500 focus:outline-none"
						>
							<option value="ADDICTION">Addiction Recovery</option>
							<option value="MENTAL">Mental Health Screening</option>
						</select>
					</div>
					<div>
						<label for="new-part-age" class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">Age Bracket</label>
						<select
							id="new-part-age"
							name="age"
							class="w-full rounded-[8px] border border-slate-200 bg-white px-3 py-2 text-xs font-semibold focus:ring-1 focus:ring-indigo-500 focus:outline-none"
						>
							<option value="">Select Age</option>
							<option value="Under 18">Under 18</option>
							<option value="18-24">18-24</option>
							<option value="25-34">25-34</option>
							<option value="35-44">35-44</option>
							<option value="45-54">45-54</option>
							<option value="55-64">55-64</option>
							<option value="65+">65+</option>
						</select>
					</div>
					<div>
						<label for="new-part-gender" class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">Gender</label>
						<select
							id="new-part-gender"
							name="gender"
							class="w-full rounded-[8px] border border-slate-200 bg-white px-3 py-2 text-xs font-semibold focus:ring-1 focus:ring-indigo-500 focus:outline-none"
						>
							<option value="">Select Gender</option>
							<option value="Male">Male</option>
							<option value="Female">Female</option>
							<option value="Non-binary">Non-binary</option>
							<option value="Prefer not to say">Prefer not to say</option>
						</select>
					</div>
					<div>
						<label for="new-part-occupation" class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">Occupation</label>
						<input
							id="new-part-occupation"
							type="text"
							name="occupation"
							placeholder="Employed, Student..."
							class="w-full rounded-[8px] border border-slate-200 px-3 py-2 text-xs font-semibold focus:ring-1 focus:ring-indigo-500 focus:outline-none"
						/>
					</div>
					<div>
						<label for="new-part-marital" class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">Marital Status</label>
						<input
							id="new-part-marital"
							type="text"
							name="maritalStatus"
							placeholder="Single, Married..."
							class="w-full rounded-[8px] border border-slate-200 px-3 py-2 text-xs font-semibold focus:ring-1 focus:ring-indigo-500 focus:outline-none"
						/>
					</div>
				</div>

				<div class="flex items-center justify-end gap-3 pt-4 border-t border-slate-100">
					<button
						type="button"
						onclick={closeModals}
						class="rounded-[8px] border border-slate-200 px-4 py-2 text-xs font-bold text-slate-600 hover:bg-slate-50 cursor-pointer"
					>
						Cancel
					</button>
					<button
						type="submit"
						class="rounded-[8px] bg-indigo-600 px-5 py-2 text-xs font-bold text-white hover:bg-indigo-700 cursor-pointer"
					>
						Enroll Participant
					</button>
				</div>
			</form>
		</div>
	</div>
{/if}
