<script lang="ts">
	import type { PageData } from './$types';
	let { data } = $props<{ data: PageData }>();

	let searchTerm = $state('');
	let isAddModalOpen = $state(false);
	let isEditModalOpen = $state(false);
	let selectedDoctor = $state<any>(null);

	let filteredDoctors = $derived(
		data.doctors.filter((d: any) => {
			const term = searchTerm.toLowerCase();
			return (
				d.name.toLowerCase().includes(term) ||
				d.email.toLowerCase().includes(term) ||
				d.specialization.toLowerCase().includes(term) ||
				d.servicePincode.toLowerCase().includes(term)
			);
		})
	);

	const totalCoveredPincodes = $derived(
		new Set(data.doctors.flatMap((d: any) => d.pincodesList)).size
	);

	const totalCriticalUnderCoverage = $derived(
		data.doctors.reduce((sum: number, d: any) => sum + (d.criticalPatientsCount || 0), 0)
	);

	function openEditModal(doctor: any) {
		selectedDoctor = { ...doctor };
		isEditModalOpen = true;
	}

	function closeModals() {
		isAddModalOpen = false;
		isEditModalOpen = false;
		selectedDoctor = null;
	}

	async function handleDeleteDoctor(id: number, name: string) {
		if (!confirm(`Are you sure you want to remove Dr. ${name}? Any assigned submissions will be unlinked.`)) {
			return;
		}

		const formData = new FormData();
		formData.append('id', String(id));

		await fetch('?/deleteDoctor', {
			method: 'POST',
			body: formData
		});
		window.location.reload();
	}
</script>

<div class="flex h-full flex-col bg-white">
	<!-- Top Bar -->
	<div class="border-b border-slate-100 bg-white px-10 py-6">
		<div class="flex flex-col gap-6">
			<div class="flex items-center justify-between gap-8">
				<div class="flex items-center gap-4">
					<div>
						<h1 class="text-xl font-black tracking-tight text-slate-900">Clinicians & Doctors</h1>
						<p class="text-xs font-semibold text-slate-400">
							Manage registered clinical practitioners and their geographical coverage pincodes
						</p>
					</div>
				</div>

				<div class="flex items-center gap-3">
					<button
						onclick={() => (isAddModalOpen = true)}
						class="flex items-center gap-2 rounded-[8px] bg-indigo-600 px-4 py-2.5 text-xs font-bold text-white shadow-sm transition-all hover:bg-indigo-700 active:scale-95 cursor-pointer"
					>
						<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
							<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
						</svg>
						Add Clinician
					</button>
				</div>
			</div>

			<!-- Quick Metric Cards -->
			<div class="grid grid-cols-4 gap-4">
				<div class="rounded-[8px] border border-slate-200 bg-slate-50/50 p-4">
					<span class="text-[10px] font-black tracking-[0.2em] text-slate-400 uppercase">Total Clinicians</span>
					<p class="mt-1 text-2xl font-black text-slate-800">{data.doctors.length}</p>
				</div>
				<div class="rounded-[8px] border border-slate-200 bg-slate-50/50 p-4">
					<span class="text-[10px] font-black tracking-[0.2em] text-slate-400 uppercase">Pincodes Covered</span>
					<p class="mt-1 text-2xl font-black text-indigo-600">{totalCoveredPincodes}</p>
				</div>
				<div class="rounded-[8px] border border-slate-200 bg-slate-50/50 p-4">
					<span class="text-[10px] font-black tracking-[0.2em] text-slate-400 uppercase">Coverage Reach</span>
					<p class="mt-1 text-2xl font-black text-emerald-600">
						{data.doctors.reduce((sum: number, d: any) => sum + (d.matchingPatientsCount || 0), 0)} Patients
					</p>
				</div>
				<div class="rounded-[8px] border border-slate-200 bg-slate-50/50 p-4">
					<span class="text-[10px] font-black tracking-[0.2em] text-slate-400 uppercase">Critical in Territory</span>
					<p class="mt-1 text-2xl font-black text-rose-600">{totalCriticalUnderCoverage} Alerts</p>
				</div>
			</div>

			<!-- Search -->
			<div class="relative max-w-md">
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
					placeholder="Search by name, email, specialization, or pincode..."
					class="w-full rounded-[8px] border border-slate-200 bg-slate-50 py-2.5 pr-4 pl-11 text-xs font-semibold transition-all focus:bg-white focus:ring-1 focus:ring-indigo-500 focus:outline-none"
					bind:value={searchTerm}
				/>
			</div>
		</div>
	</div>

	<!-- Doctors Table -->
	<div class="flex-1 overflow-auto p-10">
		<div class="overflow-hidden rounded-[8px] border border-slate-200 bg-white">
			<table class="w-full border-collapse text-left">
				<thead>
					<tr class="border-b border-slate-100 bg-slate-50/50">
						<th class="px-8 py-5 text-[10px] font-black tracking-[0.2em] text-slate-400 uppercase">Clinician</th>
						<th class="px-8 py-5 text-[10px] font-black tracking-[0.2em] text-slate-400 uppercase">Specialization</th>
						<th class="px-8 py-5 text-[10px] font-black tracking-[0.2em] text-slate-400 uppercase">Contact</th>
						<th class="px-8 py-5 text-[10px] font-black tracking-[0.2em] text-slate-400 uppercase">Service Pincodes</th>
						<th class="px-8 py-5 text-[10px] font-black tracking-[0.2em] text-slate-400 uppercase">Caseload / Reach</th>
						<th class="px-8 py-5 text-right text-[10px] font-black tracking-[0.2em] text-slate-400 uppercase">Actions</th>
					</tr>
				</thead>
				<tbody class="divide-y divide-slate-50">
					{#each filteredDoctors as doctor (doctor.id)}
						<tr class="group transition-colors hover:bg-slate-50/50">
							<td class="px-8 py-6">
								<div class="flex items-center gap-3">
									<div class="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-indigo-50 font-bold text-indigo-600 text-xs">
										{doctor.name ? doctor.name.slice(0, 2).toUpperCase() : 'DR'}
									</div>
									<div>
										<p class="text-sm font-bold text-slate-900">Dr. {doctor.name}</p>
										<p class="text-xs font-semibold text-slate-400">{doctor.email}</p>
									</div>
								</div>
							</td>
							<td class="px-8 py-6">
								<span class="inline-flex items-center rounded-md bg-slate-100 px-2.5 py-1 text-[11px] font-bold text-slate-700">
									{doctor.specialization}
								</span>
							</td>
							<td class="px-8 py-6">
								<p class="text-xs font-bold text-slate-600">{doctor.phoneNumber}</p>
							</td>
							<td class="px-8 py-6">
								{#if doctor.pincodesList.length > 0}
									<div class="flex flex-wrap gap-1.5 max-w-xs">
										{#each doctor.pincodesList.slice(0, 4) as pin}
											<span class="inline-flex items-center rounded bg-indigo-50 border border-indigo-100 px-2 py-0.5 text-[10px] font-bold text-indigo-700">
												{pin}
											</span>
										{/each}
										{#if doctor.pincodesList.length > 4}
											<span class="inline-flex items-center rounded bg-slate-100 px-1.5 py-0.5 text-[10px] font-bold text-slate-500">
												+{doctor.pincodesList.length - 4} more
											</span>
										{/if}
									</div>
								{:else}
									<span class="text-xs font-medium text-slate-300 italic">No pincodes configured</span>
								{/if}
							</td>
							<td class="px-8 py-6">
								<div class="flex flex-col gap-1">
									<div class="flex items-center gap-2">
										<span class="text-xs font-bold text-slate-700">{doctor.matchingPatientsCount}</span>
										<span class="text-[10px] font-semibold text-slate-400">patients in area</span>
									</div>
									{#if doctor.criticalPatientsCount > 0}
										<div class="flex items-center gap-1.5 text-rose-600">
											<span class="h-1.5 w-1.5 rounded-full bg-rose-500 animate-pulse"></span>
											<span class="text-[10px] font-black">{doctor.criticalPatientsCount} Critical Risk</span>
										</div>
									{/if}
								</div>
							</td>
							<td class="px-8 py-6 text-right">
								<div class="flex items-center justify-end gap-2">
									<button
										onclick={() => openEditModal(doctor)}
										class="rounded-[6px] border border-slate-200 bg-white px-3 py-1.5 text-xs font-bold text-slate-600 transition-colors hover:bg-slate-50 hover:text-indigo-600 cursor-pointer"
									>
										Edit
									</button>
									<button
										onclick={() => handleDeleteDoctor(doctor.id, doctor.name)}
										class="rounded-[6px] border border-red-100 bg-red-50/50 px-3 py-1.5 text-xs font-bold text-red-600 transition-colors hover:bg-red-100 cursor-pointer"
									>
										Delete
									</button>
								</div>
							</td>
						</tr>
					{:else}
						<tr>
							<td colspan="6" class="px-8 py-20 text-center">
								<div class="flex flex-col items-center opacity-40">
									<svg class="h-12 w-12 text-slate-300 mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
										<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
									</svg>
									<p class="font-bold text-slate-500">No clinicians found matching your search.</p>
								</div>
							</td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
	</div>
</div>

<!-- Add Clinician Modal -->
{#if isAddModalOpen}
	<div class="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/40 backdrop-blur-xs p-4">
		<div class="w-full max-w-lg rounded-xl border border-slate-200 bg-white shadow-xl overflow-hidden animate-in fade-in zoom-in-95 duration-200">
			<div class="flex items-center justify-between border-b border-slate-100 px-6 py-4">
				<h3 class="text-sm font-black text-slate-900 uppercase tracking-wider">Register New Clinician</h3>
				<button onclick={closeModals} class="text-slate-400 hover:text-slate-600 cursor-pointer text-sm">✕</button>
			</div>

			<form method="POST" action="?/createDoctor" class="p-6 space-y-4">
				<div>
					<label for="create-email" class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">Email Address *</label>
					<input
						id="create-email"
						type="email"
						name="email"
						required
						placeholder="doctor@clinic.nhs.uk"
						class="w-full rounded-[8px] border border-slate-200 px-3 py-2 text-xs font-semibold focus:ring-1 focus:ring-indigo-500 focus:outline-none"
					/>
				</div>

				<div>
					<label for="create-name" class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">Doctor Full Name</label>
					<input
						id="create-name"
						type="text"
						name="name"
						placeholder="e.g. Sarah Jenkins"
						class="w-full rounded-[8px] border border-slate-200 px-3 py-2 text-xs font-semibold focus:ring-1 focus:ring-indigo-500 focus:outline-none"
					/>
				</div>

				<div class="grid grid-cols-2 gap-4">
					<div>
						<label for="create-specialization" class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">Specialization</label>
						<input
							id="create-specialization"
							type="text"
							name="specialization"
							placeholder="Addiction Medicine / Psychiatry"
							class="w-full rounded-[8px] border border-slate-200 px-3 py-2 text-xs font-semibold focus:ring-1 focus:ring-indigo-500 focus:outline-none"
						/>
					</div>
					<div>
						<label for="create-phone" class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">Phone Number</label>
						<input
							id="create-phone"
							type="text"
							name="phoneNumber"
							placeholder="+44 7911 123456"
							class="w-full rounded-[8px] border border-slate-200 px-3 py-2 text-xs font-semibold focus:ring-1 focus:ring-indigo-500 focus:outline-none"
						/>
					</div>
				</div>

				<div>
					<label for="create-pincodes" class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">Service Pincodes / Postcodes</label>
					<textarea
						id="create-pincodes"
						name="servicePincode"
						rows="3"
						placeholder="Comma-separated: SW1A 1AA, 110001, EC1A, W1D"
						class="w-full rounded-[8px] border border-slate-200 px-3 py-2 text-xs font-semibold focus:ring-1 focus:ring-indigo-500 focus:outline-none"
					></textarea>
					<p class="text-[10px] text-slate-400 mt-1">Patients located in these pincodes will be linked to this doctor's dashboard for critical clinical triage.</p>
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
						Save Clinician
					</button>
				</div>
			</form>
		</div>
	</div>
{/if}

<!-- Edit Clinician Modal -->
{#if isEditModalOpen && selectedDoctor}
	<div class="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/40 backdrop-blur-xs p-4">
		<div class="w-full max-w-lg rounded-xl border border-slate-200 bg-white shadow-xl overflow-hidden animate-in fade-in zoom-in-95 duration-200">
			<div class="flex items-center justify-between border-b border-slate-100 px-6 py-4">
				<h3 class="text-sm font-black text-slate-900 uppercase tracking-wider">Edit Clinician Profile</h3>
				<button onclick={closeModals} class="text-slate-400 hover:text-slate-600 cursor-pointer text-sm">✕</button>
			</div>

			<form method="POST" action="?/updateDoctor" class="p-6 space-y-4">
				<input type="hidden" name="id" value={selectedDoctor.id} />

				<div>
					<label for="edit-email" class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">Email (Read-only)</label>
					<input
						id="edit-email"
						type="email"
						value={selectedDoctor.email}
						disabled
						class="w-full rounded-[8px] border border-slate-200 bg-slate-50 px-3 py-2 text-xs font-semibold text-slate-500"
					/>
				</div>

				<div>
					<label for="edit-name" class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">Doctor Full Name</label>
					<input
						id="edit-name"
						type="text"
						name="name"
						bind:value={selectedDoctor.name}
						class="w-full rounded-[8px] border border-slate-200 px-3 py-2 text-xs font-semibold focus:ring-1 focus:ring-indigo-500 focus:outline-none"
					/>
				</div>

				<div class="grid grid-cols-2 gap-4">
					<div>
						<label for="edit-specialization" class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">Specialization</label>
						<input
							id="edit-specialization"
							type="text"
							name="specialization"
							bind:value={selectedDoctor.specialization}
							class="w-full rounded-[8px] border border-slate-200 px-3 py-2 text-xs font-semibold focus:ring-1 focus:ring-indigo-500 focus:outline-none"
						/>
					</div>
					<div>
						<label for="edit-phone" class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">Phone Number</label>
						<input
							id="edit-phone"
							type="text"
							name="phoneNumber"
							bind:value={selectedDoctor.phoneNumber}
							class="w-full rounded-[8px] border border-slate-200 px-3 py-2 text-xs font-semibold focus:ring-1 focus:ring-indigo-500 focus:outline-none"
						/>
					</div>
				</div>

				<div>
					<label for="edit-pincodes" class="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1.5">Service Pincodes / Postcodes</label>
					<textarea
						id="edit-pincodes"
						name="servicePincode"
						rows="3"
						bind:value={selectedDoctor.servicePincode}
						class="w-full rounded-[8px] border border-slate-200 px-3 py-2 text-xs font-semibold focus:ring-1 focus:ring-indigo-500 focus:outline-none"
					></textarea>
				</div>

				<div class="flex items-center gap-2">
					<input
						type="checkbox"
						id="edit-profile-complete"
						name="isProfileComplete"
						bind:checked={selectedDoctor.isProfileComplete}
						class="h-4 w-4 rounded border-slate-300 text-indigo-600 focus:ring-indigo-500"
					/>
					<label for="edit-profile-complete" class="text-xs font-bold text-slate-700">Verified & Profile Active</label>
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
						Update Clinician
					</button>
				</div>
			</form>
		</div>
	</div>
{/if}
