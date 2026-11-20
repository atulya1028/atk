<script lang="ts">
	import type { PageData } from './$types';
	import { goto } from '$app/navigation';
	import { enhance, deserialize } from '$app/forms';
	import { fade } from 'svelte/transition';
	let { data } = $props<{ data: PageData }>();

	let showQuestionSaved = $state(false);
	let saveMessage = $state('Changes saved successfully!');

	let activeSurveyCategory = $state(data.surveyCategory);
	let activeSectionId = $state<number | null>(data.sections[0]?.id || null);

	function switchCategory(category: string) {
		goto(`?surveyCategory=${category}`);
	}

	$effect(() => {
		activeSurveyCategory = data.surveyCategory;
		if (data.sections.length > 0 && !data.sections.some((s: any) => s.id === activeSectionId)) {
			activeSectionId = data.sections[0].id;
		}
	});
	let searchTerm = $state('');
	let editingQuestion = $state<any | null>(null);
	let logicQuestion = $state<any | null>(null);
	let isEditing = $state(false);

	let tempOptions = $state<any[]>([]);
	let tempRules = $state<any[]>([]);

	function selectQuestion(q: any) {
		let meta = q.metadata;
		if (typeof meta === 'string') {
			try {
				meta = JSON.parse(meta);
			} catch {
				meta = {};
			}
		}
		editingQuestion = { ...q, metadata: meta || {}, isNew: false };
		isEditing = false;
		tempOptions = q.options ? [...q.options] : [];
		tempRules = q.prerequisites ? [...q.prerequisites] : [];
	}

	function addTempOption() {
		tempOptions = [...tempOptions, { label: 'New Option', value: '', scoreValue: 0 }];
	}

	function removeTempOption(index: number) {
		tempOptions = tempOptions.filter((_, i) => i !== index);
	}

	function addTempRule() {
		tempRules = [...tempRules, { triggerQuestionId: '', operator: 'eq', triggerValue: '' }];
	}

	function removeTempRule(index: number) {
		tempRules = tempRules.filter((_, i) => i !== index);
	}

	let activeSection = $derived(data.sections.find((s: any) => s.id === activeSectionId));
	let availableLogicTriggers = $derived(
		activeSection
			? activeSection.questions.filter((q: any) => editingQuestion && q.id !== editingQuestion.id)
			: []
	);

	const inputTypeColors: Record<string, string> = {
		yesno: 'bg-pink-100 text-pink-700 border-pink-200',
		select: 'bg-blue-100 text-blue-700 border-blue-200',
		multi_select: 'bg-purple-100 text-purple-700 border-purple-200',
		text: 'bg-slate-100 text-slate-700 border-slate-200',
		number: 'bg-emerald-100 text-emerald-700 border-emerald-200'
	};

	let rootSections = $derived(data.sections.filter((s: any) => !s.parentId));

	function getChildSections(parentId: number) {
		return data.sections.filter((s: any) => s.parentId === parentId);
	}

	async function deleteQuestionById(q: any) {
		if (!q || !q.id) return;

		// Check for dependencies
		const dependentQuestions = data.sections
			.flatMap((s: any) => s.questions)
			.filter((other: any) => other.prerequisites && other.prerequisites.some((p: any) => p.triggerQuestionId === q.id));

		let confirmMessage = `Are you sure you want to delete "${q.text}"? This will also delete any answers and child questions.`;

		if (dependentQuestions.length > 0) {
			const depList = dependentQuestions.map((other: any) => `- ${other.text}`).join('\n');
			confirmMessage = `⚠️ WARNING: Deleting this question will break the Display Logic for ${dependentQuestions.length} other question(s):\n${depList}\n\nAre you sure you want to proceed?`;
		}

		if (!confirm(confirmMessage)) return;

		const formData = new FormData();
		formData.append('id', String(q.id));

		await fetch('?/deleteQuestion', {
			method: 'POST',
			body: formData
		});

		if (editingQuestion?.id === q.id) {
			editingQuestion = null;
			isEditing = false;
		}
		window.location.reload();
	}

	async function deleteSelectedQuestion() {
		if (!editingQuestion || editingQuestion.isNew) return;
		await deleteQuestionById(editingQuestion);
	}

	let isAddingSection = $state(false);
	let newSectionTitle = $state('');
	let newSectionType = $state('general');
	let newSurveyType = $state('INITIAL');
	let newSectionParentId = $state<number | null>(null);

	let savedThreshold = $state(data.settings.threshold);
	let pendingThreshold = $state(data.settings.threshold);
	let savedCriticalValue = $state(data.settings.criticalValue ?? 50);
	let pendingCriticalValue = $state(data.settings.criticalValue ?? 50);

	let isEmailTemplateModalOpen = $state(false);
	let emailSubject = $state(data.settings.emailTemplate?.subject || '');
	let editorRef = $state<HTMLDivElement | null>(null);
	let showEmailTemplateSuccess = $state(false);
	let isSavingEmailTemplate = $state(false);

	let isCodeView = $state(false);
	let currentHtml = $state(data.settings.emailTemplate?.bodyHtml || '');

	$effect(() => {
		savedThreshold = data.settings.threshold;
		pendingThreshold = data.settings.threshold;
		savedCriticalValue = data.settings.criticalValue ?? 50;
		pendingCriticalValue = data.settings.criticalValue ?? 50;
		emailSubject = data.settings.emailTemplate?.subject || '';
	});

	$effect(() => {
		if (!isEmailTemplateModalOpen) {
			emailSubject = data.settings.emailTemplate?.subject || '';
			currentHtml = data.settings.emailTemplate?.bodyHtml || '';
			isCodeView = false;
		}
	});

	$effect(() => {
		if (isEmailTemplateModalOpen && editorRef && !isCodeView) {
			editorRef.innerHTML = currentHtml;
			document.execCommand('defaultParagraphSeparator', false, 'p');
		}
	});

	function toggleCodeView() {
		if (!isCodeView) {
			if (!editorRef) return;
			currentHtml = editorRef.innerHTML;
			isCodeView = true;
		} else {
			isCodeView = false;
		}
	}

	function execCmd(command: string, value: string = '') {
		if (isCodeView) return;
		if (editorRef) {
			editorRef.focus();
		}
		document.execCommand(command, false, value);
	}

	function handleEditorClick(event: MouseEvent) {
		const target = event.target as HTMLElement;
		const anchor = target.closest('a');
		if (anchor) {
			event.preventDefault();
			const currentHref = anchor.getAttribute('href') || '';
			const newUrl = prompt('Edit Website Link URL:', currentHref);
			if (newUrl !== null) {
				if (newUrl.trim() === '') {
					// Remove the link (unwrap the text content)
					const parent = anchor.parentNode;
					if (parent) {
						while (anchor.firstChild) {
							parent.insertBefore(anchor.firstChild, anchor);
						}
						parent.removeChild(anchor);
					}
				} else {
					// Update anchor link target
					anchor.setAttribute('href', newUrl);
				}
				if (editorRef) {
					currentHtml = editorRef.innerHTML;
				}
			}
		}
	}

	async function saveEmailTemplate() {
		const bodyHtml = isCodeView ? currentHtml : (editorRef?.innerHTML || '');
		const bodyText = isCodeView ? currentHtml.replace(/<[^>]*>/g, '') : (editorRef?.innerText || '');

		const strippedHtml = bodyHtml.replace(/<[^>]*>/g, '').trim();
		const isRevert = !emailSubject.trim() || !bodyHtml.trim() || bodyHtml === '<p><br></p>' || bodyHtml === '<br>' || bodyHtml === '<p></p>' || strippedHtml === '';

		isSavingEmailTemplate = true;
		const formData = new FormData();
		formData.append('surveyCategory', activeSurveyCategory);
		formData.append('subject', emailSubject);
		formData.append('bodyHtml', bodyHtml);
		formData.append('bodyText', bodyText);

		try {
			const res = await fetch('?/updateEmailTemplate', {
				method: 'POST',
				body: formData
			});
			if (res.ok) {
				showEmailTemplateSuccess = true;
				setTimeout(() => { showEmailTemplateSuccess = false; }, 2000);

				const responseText = await res.text();
				const result = deserialize(responseText);

				if (result.type === 'success' && result.data && (result.data as any).reverted && (result.data as any).defaultTemplate) {
					const def = (result.data as any).defaultTemplate;
					data.settings.emailTemplate = {
						subject: def.subject,
						bodyHtml: def.bodyHtml,
						bodyText: def.bodyText
					};
					emailSubject = def.subject;
					currentHtml = def.bodyHtml;
					if (editorRef) {
						editorRef.innerHTML = def.bodyHtml;
					}
				} else {
					if (!data.settings.emailTemplate) {
						data.settings.emailTemplate = {};
					}
					data.settings.emailTemplate.subject = emailSubject;
					data.settings.emailTemplate.bodyHtml = bodyHtml;
					data.settings.emailTemplate.bodyText = bodyText;
					currentHtml = bodyHtml;
				}
			} else {
				alert('Failed to save email template');
			}
		} catch (e) {
			console.error(e);
			alert('Error saving email template');
		} finally {
			isSavingEmailTemplate = false;
		}
	}

	let isEditingSection = $state(false);
	let editSectionTitle = $state('');
	let editSectionType = $state('general');
	let editSurveyType = $state('INITIAL');
	let editSurveyCategory = $state('ADDICTION');
	let showThresholdSuccess = $state(false);
	let showCriticalSuccess = $state(false);
	let editSectionRules = $state<any[]>([]);

	function addSectionRule() {
		editSectionRules = [...editSectionRules, { triggerQuestionId: '', operator: 'eq', triggerValue: '' }];
	}

	function removeSectionRule(index: number) {
		editSectionRules = editSectionRules.filter((_, i) => i !== index);
	}

	function startEditingSection() {
		if (!activeSection) return;
		editSectionTitle = activeSection.title;
		editSectionType = activeSection.sectionType;
		editSurveyType = activeSection.surveyType;
		editSurveyCategory = activeSection.surveyCategory || activeSurveyCategory;
		// Load relational section-level display rules
		if (activeSection.displayRules && Array.isArray(activeSection.displayRules)) {
			editSectionRules = activeSection.displayRules.map((r: any) => ({
				triggerQuestionId: String(r.triggerQuestionId),
				operator: r.operator,
				triggerValue: r.triggerValue
			}));
		} else {
			editSectionRules = [];
		}
		isEditingSection = true;
	}

	async function saveSectionDetails() {
		if (!activeSectionId || !editSectionTitle.trim()) return;

		const formData = new FormData();
		formData.append('id', String(activeSectionId));
		formData.append('title', editSectionTitle);
		formData.append('sectionType', editSectionType);
		formData.append('surveyType', editSurveyType);
		formData.append('surveyCategory', editSurveyCategory);
		formData.append('sectionRules', JSON.stringify(editSectionRules));

		await fetch('?/updateSection', {
			method: 'POST',
			body: formData
		});

		isEditingSection = false;
		window.location.reload();
	}

	async function saveSettings(newThreshold: number, newCriticalValue: number, trigger: 'threshold' | 'critical') {
		const formData = new FormData();
		formData.append('surveyCategory', activeSurveyCategory);
		formData.append('threshold', String(newThreshold));
		formData.append('criticalValue', String(newCriticalValue));

		await fetch('?/updateSettings', {
			method: 'POST',
			body: formData
		});
		
		// Update reactive states so UI reacts immediately
		savedThreshold = newThreshold;
		savedCriticalValue = newCriticalValue;
		if (trigger === 'threshold') {
			showThresholdSuccess = true;
			setTimeout(() => { showThresholdSuccess = false; }, 2000);
		} else {
			showCriticalSuccess = true;
			setTimeout(() => { showCriticalSuccess = false; }, 2000);
		}
	}

	async function addSection() {
		if (!newSectionTitle.trim()) return;

		const formData = new FormData();
		formData.append('title', newSectionTitle);
		formData.append('sectionType', newSectionType);
		formData.append('surveyType', newSurveyType);
		formData.append('surveyCategory', activeSurveyCategory);
		if (newSectionParentId) formData.append('parentId', String(newSectionParentId));

		await fetch('?/createSection', {
			method: 'POST',
			body: formData
		});

		isAddingSection = false;
		newSectionTitle = '';
		window.location.reload();
	}

	async function deleteActiveSection() {
		if (!activeSectionId) return;
		if (
			!confirm(
				`Are you sure you want to delete the section "${activeSection?.title}"? This will delete ALL questions and answers within it.`
			)
		)
			return;

		const formData = new FormData();
		formData.append('id', String(activeSectionId));

		await fetch('?/deleteSection', {
			method: 'POST',
			body: formData
		});

		activeSectionId = data.sections[0]?.id || null;
		window.location.reload();
	}
</script>

<div class="flex h-full overflow-hidden font-sans text-slate-900">
	<aside
		class="z-30 flex h-full min-w-[240px] flex-1 shrink-0 flex-col border-r border-slate-200 bg-white"
	>
		<div class="border-b border-slate-100 p-4">
			<div class="flex rounded-[10px] bg-slate-100 p-1">
				<button
					class="flex-1 rounded-[8px] py-1.5 text-xs font-bold transition-all
                           {activeSurveyCategory === 'ADDICTION'
						? 'bg-white text-indigo-600 shadow-sm'
						: 'text-slate-500 hover:text-slate-700'}"
					onclick={() => switchCategory('ADDICTION')}
				>
					Addiction
				</button>
				<button
					class="flex-1 rounded-[8px] py-1.5 text-xs font-bold transition-all
                           {activeSurveyCategory === 'MENTAL'
						? 'bg-white text-indigo-600 shadow-sm'
						: 'text-slate-500 hover:text-slate-700'}"
					onclick={() => switchCategory('MENTAL')}
				>
					Mental Health
				</button>
			</div>

			<div class="mt-4 flex flex-col gap-1.5 rounded-[12px] bg-indigo-50/50 p-3 border border-indigo-100/50">
				<div class="flex items-center justify-between">
					<label class="text-[10px] font-bold tracking-widest text-indigo-400 uppercase">Stage 3 Unlock</label>
					{#if showThresholdSuccess}
						<span class="text-[9px] font-bold text-emerald-500 animate-bounce">SAVED!</span>
					{:else}
						<span class="text-[10px] font-mono text-indigo-300">Min Score</span>
					{/if}
				</div>
				<div class="flex items-center gap-2 pt-1">
					<input 
						type="number" 
						min="0"
						step="1"
						onkeydown={(e) => {
							if (['.', '-', 'e', 'E', '+'].includes(e.key)) e.preventDefault();
						}}
						bind:value={pendingThreshold}
						class="w-16 shrink-0 bg-transparent text-2xl font-bold text-indigo-900 outline-none"
					/>
					
					{#if pendingThreshold !== savedThreshold}
						<button 
							onclick={() => saveSettings(pendingThreshold, pendingCriticalValue, 'threshold')}
							class="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-indigo-600 text-white shadow-md hover:bg-indigo-700 transition-all hover:scale-110 active:scale-95"
							title="Save Changes"
						>
							<svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
								<path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
							</svg>
						</button>
					{/if}

					<div class="h-8 w-[1px] bg-indigo-200 shrink-0 mx-1"></div>
					
					<div class="flex-1 text-[10px] leading-[1.2] text-indigo-400/80 italic">
						Score required to unlock detailed modules
					</div>
				</div>
			</div>

			<div class="mt-3 flex flex-col gap-1.5 rounded-[12px] bg-red-50/50 p-3 border border-red-100/50">
				<div class="flex items-center justify-between">
					<label class="text-[10px] font-bold tracking-widest text-red-500 uppercase">Critical Value</label>
					{#if showCriticalSuccess}
						<span class="text-[9px] font-bold text-emerald-500 animate-bounce">SAVED!</span>
					{:else}
						<span class="text-[10px] font-mono text-red-400">Min Score</span>
					{/if}
				</div>
				<div class="flex items-center gap-2 pt-1">
					<input 
						type="number" 
						min="0"
						step="1"
						onkeydown={(e) => {
							if (['.', '-', 'e', 'E', '+'].includes(e.key)) e.preventDefault();
						}}
						bind:value={pendingCriticalValue}
						class="w-16 shrink-0 bg-transparent text-2xl font-bold text-red-950 outline-none"
					/>
					
					{#if pendingCriticalValue !== savedCriticalValue}
						<button 
							onclick={() => saveSettings(pendingThreshold, pendingCriticalValue, 'critical')}
							class="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-red-600 text-white shadow-md hover:bg-red-700 transition-all hover:scale-110 active:scale-95"
							title="Save Changes"
						>
							<svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
								<path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
							</svg>
						</button>
					{/if}

					<div class="flex-1 text-[10px] leading-[1.2] text-red-500/80 italic">
						Score threshold for highlighting critical risk
					</div>
				</div>
			</div>

			<div class="mt-4 border-t border-slate-100 pt-4">
				<button
					onclick={() => (isEmailTemplateModalOpen = true)}
					class="w-full inline-flex items-center justify-center gap-1.5 rounded-[8px] border border-slate-200 bg-white px-4 py-2 text-xs font-black tracking-wider text-slate-700 transition-colors hover:border-slate-300 hover:bg-slate-50 uppercase"
				>
					✉️ Edit Follow-up Email
				</button>
			</div>
		</div>

		<div
			class="flex-1 space-y-4 overflow-y-auto p-3"
			style="scrollbar-width: none; -ms-overflow-style: none;"
		>
			<style>
				aside div::-webkit-scrollbar {
					display: none;
				}
			</style>

			{#each rootSections as root}
				<div class="space-y-1">
					{#if getChildSections(root.id).length === 0}
						<!-- Flat section: make the root itself clickable -->
						<button
							class="flex w-full items-center gap-2 rounded-none border-l border-transparent px-8 py-2 text-left transition-all duration-200
                                   {activeSectionId === root.id
								? 'border-indigo-500 bg-indigo-50 font-semibold text-indigo-900'
								: 'text-slate-600 hover:bg-slate-50'}"
							onclick={() => (activeSectionId = root.id)}
						>
							<div class="flex flex-1 flex-col overflow-hidden">
								<div class="flex items-center gap-1.5 overflow-hidden">
									<span class="truncate text-sm">{root.title}</span>
									{#if root.displayRules && root.displayRules.length > 0}
										<span
											class="flex items-center gap-0.5 rounded-[4px] border border-amber-200 bg-amber-50 px-1 text-[9px] text-amber-700"
											title="Has Logic"
										>
											⚡ {root.displayRules.length}
										</span>
									{/if}
								</div>
								<span class="text-[9px] font-bold tracking-tighter text-slate-400 uppercase">
									{root.surveyType === 'INITIAL' ? 'Stage 2' : 'Stage 3'}
								</span>
							</div>
							{#if root.sectionType !== 'general'}
								<span
									class="h-2 w-2 rounded-full {root.sectionType === 'safety'
										? 'bg-red-500'
										: 'bg-amber-500'} animate-pulse"
								></span>
							{/if}
						</button>
					{:else}
						<!-- Hierarchical section: non-clickable header + clickable children -->
						<div class="group flex items-center justify-between px-8 py-2">
							<span
								class="text-[10px] leading-none font-bold tracking-widest text-slate-400 uppercase"
								>{root.title}</span
							>
							{#if root.sectionType !== 'general'}
								<span
									class="h-2 w-2 rounded-full {root.sectionType === 'safety'
										? 'bg-red-500'
										: 'bg-amber-500'} animate-pulse"
								></span>
							{/if}
						</div>

						<div class="space-y-0.5">
							{#each getChildSections(root.id) as module}
								<button
									class="group flex w-full items-center gap-2 rounded-none border-l border-transparent px-8 py-2 text-left transition-all duration-200
                                           {activeSectionId === module.id
										? 'border-indigo-500 bg-indigo-50 font-semibold text-indigo-900'
										: 'text-slate-600 hover:bg-slate-50'}"
									onclick={() => (activeSectionId = module.id)}
								>
									<div class="flex flex-1 items-center gap-1.5 overflow-hidden">
										<span class="truncate text-sm">{module.title}</span>
										{#if module.displayRules && module.displayRules.length > 0}
											<span
												class="flex items-center gap-0.5 rounded-[4px] border border-amber-200 bg-amber-50 px-1 text-[9px] text-amber-700"
												title="Has Logic"
											>
												⚡ {module.displayRules.length}
											</span>
										{/if}
									</div>
									{#if getChildSections(module.id).length > 0}
										<svg
											class="h-3 w-3 text-slate-300 transition-transform group-hover:text-slate-400 {activeSectionId ===
												module.id || activeSection?.parentId === module.id
												? 'rotate-90'
												: ''}"
											fill="none"
											stroke="currentColor"
											viewBox="0 0 24 24"
											><path
												stroke-linecap="round"
												stroke-linejoin="round"
												stroke-width="2"
												d="M9 5l7 7-7 7"
											/></svg
										>
									{/if}
								</button>

								{#if activeSectionId === module.id || activeSection?.parentId === module.id}
									<div class="mt-0.5 mb-2 ml-0 space-y-0.5 border-l border-slate-100 pl-8">
										{#each getChildSections(module.id) as sub}
											<button
												class="relative flex w-full items-center gap-2 px-8 py-1.5 text-left transition-all
                                                       {activeSectionId === sub.id
													? 'font-bold text-indigo-600'
													: 'text-slate-500 hover:text-slate-800'}"
												onclick={() => (activeSectionId = sub.id)}
											>
												<div class="h-[1px] w-1.5 bg-slate-200"></div>
												<div class="flex flex-1 items-center gap-1.5 overflow-hidden">
													<span class="truncate">{sub.title}</span>
													{#if sub.displayRules && sub.displayRules.length > 0}
														<span
															class="flex items-center gap-0.5 rounded-[4px] border border-amber-200 bg-amber-50 px-1 text-[9px] text-amber-700 font-normal"
															title="Has Logic"
														>
															⚡ {sub.displayRules.length}
														</span>
													{/if}
												</div>
											</button>
										{/each}
									</div>
								{/if}
							{/each}
						</div>
					{/if}
				</div>
			{/each}
		</div>

		<div class="border-t border-slate-100 bg-white px-8 py-4">
			<button
				onclick={() => (isAddingSection = true)}
				class="flex w-full items-center justify-center gap-1.5 rounded-[8px] border border-dashed border-slate-300 py-2 text-xs text-slate-500 transition-all hover:border-indigo-300 hover:bg-indigo-50 hover:text-indigo-600"
			>
				<span>+ Section</span>
			</button>
			<a
				href="/admin"
				class="mt-3 flex items-center justify-center gap-1 text-xs text-slate-400 hover:text-slate-600"
			>
				&larr; Dashboard
			</a>
		</div>
	</aside>

	<div class="flex h-full flex-[2] flex-col overflow-hidden border-r border-slate-200 bg-slate-50">
		{#if activeSection}
			<header
				class="sticky top-0 z-20 flex h-16 shrink-0 items-center justify-between border-b border-slate-200 bg-white/80 px-8 py-4 backdrop-blur-md"
			>
				<div class="flex items-center gap-3 overflow-hidden">
					<div class="overflow-hidden">
						<div class="flex items-center gap-2">
							<h2 class="truncate text-lg font-bold text-slate-900">{activeSection.title}</h2>
							<span
								class="rounded-full bg-slate-100 px-2 py-0.5 text-[10px] font-bold text-slate-500 uppercase"
							>
								{activeSection.surveyType === 'INITIAL' ? 'Stage 2' : 'Stage 3'}
							</span>
						</div>
						<p class="truncate text-xs text-slate-500">{activeSection.slug}</p>
					</div>
				</div>

				<div class="flex gap-2">
					<button
						onclick={startEditingSection}
						class="p-2 text-slate-400 transition-colors hover:text-indigo-600"
						title="Edit Section Details"
					>
						<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"
							><path
								stroke-linecap="round"
								stroke-linejoin="round"
								stroke-width="2"
								d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
							/></svg
						>
					</button>
					<button
						onclick={deleteActiveSection}
						class="p-2 text-slate-400 transition-colors hover:text-red-500"
						title="Delete Section"
					>
						<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"
							><path
								stroke-linecap="round"
								stroke-linejoin="round"
								stroke-width="2"
								d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
							/></svg
						>
					</button>
					<button
						onclick={() => {
							editingQuestion = {
								sectionId: activeSectionId,
								isNew: true,
								inputType: 'select'
							};
							isEditing = true;
						}}
						class="rounded-[8px] bg-indigo-600 px-3 py-1.5 text-xs font-bold tracking-wide whitespace-nowrap text-white uppercase transition-colors hover:bg-indigo-500"
					>
						+ Add Question
					</button>
				</div>
			</header>

			<div class="flex-1 space-y-3 overflow-y-auto p-8" role="list">
				<div class="relative mb-6">
					<input
						type="text"
						bind:value={searchTerm}
						placeholder="Filter questions..."
						class="w-full rounded-[8px] border border-slate-200 bg-white py-2.5 pr-3 pl-10 text-sm outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"
					/>
					<svg
						class="absolute top-3 left-3.5 h-4 w-4 text-slate-400"
						fill="none"
						stroke="currentColor"
						viewBox="0 0 24 24"
						><path
							stroke-linecap="round"
							stroke-linejoin="round"
							stroke-width="2"
							d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
						/></svg
					>
				</div>

				{#each activeSection.questions
					.filter((q: any) => q.text
								.toLowerCase()
								.includes(searchTerm.toLowerCase()) || q.slug.includes(searchTerm))
					.sort((a: any, b: any) => a.sortOrder - b.sortOrder) as question, index (question.id)}
					<div
						role="button"
						tabindex="0"
						onclick={() => selectQuestion(question)}
						onkeydown={(e) => {
							if (e.key === 'Enter') selectQuestion(question);
						}}
						class="group relative flex w-full cursor-pointer gap-3 rounded-[8px] border p-3 text-left transition-all select-none
                               {editingQuestion?.id === question.id
							? 'z-10 border-indigo-500 bg-white ring-1 ring-indigo-500'
							: 'border-slate-200 bg-white hover:border-indigo-300'}"
						ondrop={async (e) => {
							e.preventDefault();
							const fromIndex = Number(e.dataTransfer!.getData('text/plain'));
							const toIndex = index;
							if (fromIndex === toIndex) return;

							const questions = [...activeSection.questions];
							const filteredQuestions = questions
								.filter(
									(q: any) =>
										q.text.toLowerCase().includes(searchTerm.toLowerCase()) ||
										q.slug.includes(searchTerm)
								)
								.sort((a: any, b: any) => a.sortOrder - b.sortOrder);

							const [movedItem] = filteredQuestions.splice(fromIndex, 1);
							filteredQuestions.splice(toIndex, 0, movedItem);

							const updates = filteredQuestions.map((q: any, i: number) => ({
								id: q.id,
								sortOrder: i * 10
							}));

							activeSection.questions = questions.map((q) => {
								const update = updates.find((u: any) => u.id === q.id);
								return update ? { ...q, sortOrder: update.sortOrder } : q;
							});

							const formData = new FormData();
							formData.append('updates', JSON.stringify(updates));
							await fetch('?/reorderQuestions', {
								method: 'POST',
								body: formData
							});
						}}
						ondragover={(e) => e.preventDefault()}
					>
						<div
							class="shrink-0 cursor-move py-1 text-slate-300 hover:text-slate-500"
							draggable="true"
							ondragstart={(e) => {
								e.dataTransfer?.setData('text/plain', String(index));

								if (e.currentTarget.parentElement) {
									e.dataTransfer?.setDragImage(e.currentTarget.parentElement, 20, 20);
								}
							}}
						>
							<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"
								><path
									stroke-linecap="round"
									stroke-linejoin="round"
									stroke-width="2"
									d="M4 8h16M4 16h16"
								/></svg
							>
						</div>

						<div class="pointer-events-none flex-1 overflow-hidden">
							<div class="mb-1 flex items-center gap-2">
								<span
									class={`rounded-[4px] border px-1.5 py-0.5 text-[9px] font-bold tracking-wider uppercase ${inputTypeColors[question.inputType] || inputTypeColors['text']}`}
								>
									{question.inputType}
								</span>
								{#if question.prerequisites && question.prerequisites.length > 0}
									<span
										class="flex items-center gap-0.5 rounded-[4px] border border-amber-200 bg-amber-50 px-1 text-[9px] text-amber-700"
										title="Has Logic"
									>
										⚡ {question.prerequisites.length}
									</span>
								{/if}
							</div>
							<h3 class="line-clamp-2 text-sm leading-snug font-medium text-slate-800">
								{question.text}
							</h3>
						</div>

						<button
							type="button"
							onclick={(e) => {
								e.stopPropagation();
								deleteQuestionById(question);
							}}
							class="shrink-0 self-center p-1.5 rounded-md text-slate-300 hover:text-rose-600 hover:bg-rose-50 transition-colors opacity-0 group-hover:opacity-100 cursor-pointer"
							title="Delete this question"
						>
							<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
								<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
							</svg>
						</button>

						{#if editingQuestion?.id === question.id}
							<div
								class="pointer-events-none absolute top-0 right-0 bottom-0 w-1 rounded-r-[8px] bg-indigo-500"
							></div>
						{/if}
					</div>
				{/each}

				{#if activeSection.questions.length === 0}
					<div class="p-4 py-20 text-center text-sm opacity-50">
						<p>No questions yet.</p>
						<button
							onclick={() => {
								editingQuestion = {
									sectionId: activeSectionId,
									isNew: true,
									inputType: 'select'
								};
								isEditing = true;
							}}
							class="mt-2 text-indigo-600 hover:underline">Create one</button
						>
					</div>
				{/if}
			</div>
		{:else}
			<div class="flex flex-1 items-center justify-center text-sm text-slate-400">
				Select a section to begin.
			</div>
		{/if}
	</div>

	<div
		class="z-20 flex h-full w-full flex-[2] flex-col overflow-hidden border-l border-slate-100 bg-white"
	>
		{#if editingQuestion}
			<div
				class="sticky top-0 flex h-16 shrink-0 items-center justify-between border-b border-slate-100 bg-white px-8"
			>
				<div>
					<h2 class="text-lg font-bold text-slate-900">
						{editingQuestion.isNew
							? 'New Question'
							: isEditing
								? 'Editing Question'
								: 'Question Details'}
					</h2>
					{#if !editingQuestion.isNew}
						<span class="font-mono text-xs text-slate-500">ID: {editingQuestion.id}</span>
					{/if}
				</div>
				<div class="flex items-center gap-2">
					{#if !editingQuestion.isNew}
						<button
							type="button"
							class="flex items-center gap-2 rounded-[8px] bg-red-50 border border-red-200 px-3.5 py-2 text-sm font-semibold text-red-600 transition-colors hover:bg-red-100 cursor-pointer"
							onclick={deleteSelectedQuestion}
							title="Delete this question"
						>
							<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
								<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
							</svg>
							Delete
						</button>
					{/if}

					{#if !isEditing && !editingQuestion.isNew}
						<button
							type="button"
							class="flex items-center gap-2 rounded-[8px] bg-slate-100 px-4 py-2 text-sm font-semibold text-slate-700 transition-colors hover:bg-slate-200 cursor-pointer"
							onclick={() => (isEditing = true)}
						>
							<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
								<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" />
							</svg>
							Edit
						</button>
					{:else}
						{#if !editingQuestion.isNew}
							<button
								type="button"
								class="px-4 py-2 text-sm font-medium text-slate-500 hover:text-slate-800 cursor-pointer"
								onclick={() => {
									isEditing = false;
									selectQuestion(editingQuestion);
								}}
							>
								Cancel
							</button>
						{/if}
						<button
							class="rounded-[8px] bg-indigo-600 px-6 py-2 text-sm font-bold text-white transition-all hover:bg-indigo-700 cursor-pointer shadow-xs"
							form="mainQuestionForm"
						>
							{editingQuestion.isNew ? 'Create Question' : 'Save Changes'}
						</button>
					{/if}
				</div>
			</div>

			<div class="flex-1 overflow-y-auto">
				<form
					id="mainQuestionForm"
					method="POST"
					action={editingQuestion.id ? '?/updateQuestion' : '?/createQuestion'}
					use:enhance={() => {
						const isNew = editingQuestion.isNew;
						return async ({ result, update }) => {
							if (result.type === 'success') {
								saveMessage = isNew ? 'Question created successfully!' : 'Question updated successfully!';
								showQuestionSaved = true;
								setTimeout(() => { showQuestionSaved = false; }, 3000);
								isEditing = false;
								await update();
								if (isNew && data.sections) {
									const updatedSection = data.sections.find((s: any) => s.id === activeSectionId);
									if (updatedSection && updatedSection.questions.length > 0) {
										const sortedQs = [...updatedSection.questions].sort((a: any, b: any) => a.sortOrder - b.sortOrder);
										selectQuestion(sortedQs[sortedQs.length - 1]);
									} else {
										editingQuestion = null;
									}
								} else if (editingQuestion && !isNew) {
									const updatedSection = data.sections.find((s: any) => s.id === activeSectionId);
									const updatedQ = updatedSection?.questions.find((q: any) => q.id === editingQuestion.id);
									if (updatedQ) {
										selectQuestion(updatedQ);
									}
								}
							} else {
								await update();
							}
						};
					}}
					class="space-y-8 p-8"
				>
					<input type="hidden" name="id" value={editingQuestion.id || ''} />
					<input
						type="hidden"
						name="sectionId"
						value={editingQuestion.sectionId || activeSection?.id}
					/>
					{#if !editingQuestion.isNew}
						<input type="hidden" name="slug" value={editingQuestion.slug} />
					{/if}

					<input type="hidden" name="options" value={JSON.stringify(tempOptions)} />
					<input type="hidden" name="rules" value={JSON.stringify(tempRules)} />
					<input
						type="hidden"
						name="metadata"
						value={JSON.stringify(editingQuestion.metadata || {})}
					/>

					<div class="space-y-6">
						<div>
							<label class="mb-2 block text-xs font-bold tracking-widest text-slate-400 uppercase"
								>Question text</label
							>
							<textarea
								name="text"
								disabled={!isEditing && !editingQuestion.isNew}
								class="w-full rounded-[8px] border border-slate-200 bg-slate-50 p-4 text-base font-medium text-slate-900 transition-all outline-none focus:border-indigo-500 focus:ring-2 focus:ring-indigo-500/10 disabled:resize-none disabled:border-transparent disabled:bg-white disabled:px-0"
								rows="3"
								required
								bind:value={editingQuestion.text}
							></textarea>
						</div>

						<div class="grid grid-cols-2 gap-6">
							<div>
								<label class="mb-2 block text-xs font-bold tracking-widest text-slate-400 uppercase"
									>Slug (Internal ID)</label
								>
								<input
									type="text"
									name="slug"
									disabled
									class="w-full cursor-not-allowed rounded-[8px] border border-slate-200 bg-slate-50 p-3 font-mono text-xs text-slate-500 outline-none focus:ring-0 disabled:bg-slate-100"
									placeholder={editingQuestion.isNew ? '(Auto-generated)' : editingQuestion.slug}
									value={editingQuestion.isNew ? '' : editingQuestion.slug}
								/>
							</div>
							<div>
								<label class="mb-2 block text-xs font-bold tracking-widest text-slate-400 uppercase"
									>Input Type</label
								>
								<select
									name="inputType"
									disabled={!isEditing && !editingQuestion.isNew}
									class="w-full rounded-[8px] border border-slate-200 bg-white p-3 text-sm text-slate-900 outline-none focus:border-indigo-500 focus:ring-2 focus:ring-indigo-500/10 disabled:border-transparent disabled:bg-slate-50 disabled:cursor-not-allowed"
									bind:value={editingQuestion.inputType}
								>
									<option value="select">Single Select (Dropdown / Radio)</option>
									<option value="multi_select">Multi-Select (Checkboxes)</option>
									<option value="yesno">Yes / No Toggle</option>
									<option value="text">Free Text Input</option>
									<option value="number">Numeric Score Input</option>
								</select>
							</div>
						</div>

						<div class="grid grid-cols-1 gap-4">
							<label
								class="flex cursor-pointer items-center gap-3 rounded-[8px] border border-slate-100 p-4 transition-colors hover:bg-slate-50 disabled:cursor-default"
							>
								<input
									type="checkbox"
									name="isRequired"
									disabled={!isEditing && !editingQuestion.isNew}
									class="h-5 w-5 rounded-[4px] border-slate-300 text-indigo-600 focus:ring-indigo-500"
									bind:checked={editingQuestion.isRequired}
								/>
								<div class="flex flex-col">
									<span class="text-sm font-bold text-slate-700">Required</span>
									<span class="text-[10px] text-slate-400">Must be answered</span>
								</div>
							</label>
							<!-- Clinical Alert hidden for now
							<label
								class="flex cursor-pointer items-center gap-3 rounded-[8px] border border-slate-100 p-4 transition-colors hover:bg-slate-50 disabled:cursor-default"
							>
								<input
									type="checkbox"
									name="metadata_flag"
									disabled={!isEditing && !editingQuestion.isNew}
									class="h-5 w-5 rounded-[4px] border-slate-300 text-red-600 focus:ring-red-500"
									onchange={(e) => {
										if (!editingQuestion.metadata) editingQuestion.metadata = {};
										editingQuestion.metadata.flag_red = e.currentTarget.checked;
									}}
									checked={!!editingQuestion.metadata?.flag_red}
								/>
								<div class="flex flex-col">
									<span class="text-sm font-bold text-slate-700">Clinical Alert</span>
									<span class="text-[10px] text-slate-400">Flags risky answers</span>
								</div>
							</label>
							-->
						</div>

						{#if ['select', 'radio', 'multi_select', 'yesno'].includes(editingQuestion.inputType)}
							<div class="border-t border-slate-100 pt-6">
								<div class="mb-4 flex items-center justify-between">
									<label class="text-xs font-bold tracking-widest text-slate-400 uppercase"
										>Options</label
									>
									{#if isEditing || editingQuestion.isNew}
										<button
											type="button"
											class="text-xs font-bold text-indigo-600 hover:text-indigo-800"
											onclick={addTempOption}>+ Add Option</button
										>
									{/if}
								</div>

								<div class="space-y-3">
									{#each tempOptions as opt, i}
										<div class="group flex items-center gap-3">
											<div class="flex flex-1 gap-2">
												<div class="flex-[3]">
													<input
														type="text"
														disabled={!isEditing && !editingQuestion.isNew}
														class="w-full rounded-[8px] border border-slate-100 bg-slate-50 px-3 py-2 text-sm outline-none focus:ring-1 focus:ring-indigo-500 disabled:border-transparent disabled:bg-white"
														placeholder="Option Label"
														bind:value={opt.label}
													/>
												</div>
												<div class="flex-1">
													<input
														type="number"
														min="0"
														step="1"
														onkeydown={(e) => {
															if (['.', '-', 'e', 'E', '+'].includes(e.key)) e.preventDefault();
														}}
														disabled={!isEditing && !editingQuestion.isNew}
														class="w-full rounded-[8px] border border-slate-100 bg-slate-50 px-3 py-2 text-center text-sm outline-none focus:ring-1 focus:ring-indigo-500 disabled:border-transparent disabled:bg-white"
														placeholder="Pts"
														title="Points for this option (Integer only)"
														bind:value={opt.scoreValue}
													/>
												</div>
											</div>

											{#if isEditing || editingQuestion.isNew}
												<button
													type="button"
													class="mt-2 self-start text-slate-300 hover:text-red-500"
													onclick={() => removeTempOption(i)}>✕</button
												>
											{/if}
										</div>
									{/each}
									{#if tempOptions.length === 0}
										<p class="py-2 text-xs text-slate-400 italic">No options defined yet.</p>
									{/if}
								</div>
							</div>
						{/if}

						<div class="border-t border-slate-100 pt-6">
							<div class="mb-4 flex items-center justify-between">
								<label class="text-xs font-bold tracking-widest text-slate-400 uppercase"
									>Display Logic</label
								>
								{#if isEditing || editingQuestion.isNew}
									<button
										type="button"
										class="text-xs font-bold text-indigo-600 hover:text-indigo-800"
										onclick={addTempRule}>+ Add Rule</button
									>
								{/if}
							</div>

							<div class="space-y-3">
								{#each tempRules as rule, i}
									{@const triggerQ = data.sections
										.flatMap((s: any) => s.questions)
										.find((q: any) => q.id === Number(rule.triggerQuestionId))}
									{@const triggerSection = rule.triggerQuestionId
										? data.sections.find((s: any) =>
												s.questions.some((q: any) => q.id === Number(rule.triggerQuestionId))
											)
										: null}
									<div
										class="flex flex-col gap-2.5 rounded-[8px] border border-slate-200 bg-white p-3 text-sm text-slate-700 shadow-sm"
									>
										<!-- Header row: label + delete button -->
										<div class="flex items-center justify-between">
											<span class="text-xs font-semibold text-slate-500">Show this question <b class="text-slate-800">ONLY IF</b> the answer to:</span>
											{#if isEditing || editingQuestion.isNew}
												<button
													type="button"
													class="shrink-0 rounded-[6px] p-1 text-slate-300 hover:bg-red-50 hover:text-red-500 transition-colors"
													title="Remove Rule"
													onclick={() => removeTempRule(i)}>✕</button
												>
											{/if}
										</div>

										<!-- Section name badge (shown after question is selected) -->
										{#if triggerSection}
											<div class="flex items-center gap-1.5">
												<span class="inline-flex items-center gap-1 rounded-[6px] bg-indigo-50 px-2 py-0.5 text-[10px] font-bold tracking-wide text-indigo-600 border border-indigo-100">
													<svg class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"/></svg>
													{triggerSection.parent ? `${triggerSection.parent.title} › ${triggerSection.title}` : triggerSection.title}
												</span>
											</div>
										{/if}

										<!-- Question select dropdown -->
										<select
											disabled={!isEditing && !editingQuestion.isNew}
											class="w-full appearance-none rounded-[8px] border border-slate-200 bg-slate-50 px-2.5 py-1.5 text-xs font-medium text-slate-900 disabled:border-transparent disabled:bg-transparent disabled:font-bold disabled:text-indigo-600 focus:border-indigo-500 focus:bg-white focus:ring-1 focus:ring-indigo-500 outline-none"
											bind:value={rule.triggerQuestionId}
										>
											<option value="">— Select a Question —</option>
											{#each data.sections.filter((s: any) => s.questions.length > 0) as s}
												<optgroup label={s.parent ? `${s.parent.title} → ${s.title}` : s.title}>
													{#each s.questions.filter((q: any) => editingQuestion && q.id !== editingQuestion.id) as q}
														<option value={q.id}>{q.text}</option>
													{/each}
												</optgroup>
											{/each}
										</select>

										<!-- Condition and Value row (only shown after question is selected) -->
										{#if rule.triggerQuestionId}
											<div class="flex items-center gap-2 border-t border-slate-100 pt-2">
												<select
													disabled={!isEditing && !editingQuestion.isNew}
													class="w-28 shrink-0 appearance-none rounded-[8px] border border-slate-200 bg-slate-50 px-2 py-1.5 text-xs font-medium text-slate-900 disabled:border-transparent disabled:bg-transparent disabled:text-slate-900 focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 outline-none"
													bind:value={rule.operator}
												>
													<option value="eq">is exactly</option>
													<option value="neq">is not</option>
												</select>

												{#if triggerQ && triggerQ.options && triggerQ.options.length > 0}
													<select
														disabled={!isEditing && !editingQuestion.isNew}
														class="min-w-0 flex-1 appearance-none rounded-[8px] border border-slate-200 bg-slate-50 px-2 py-1.5 text-xs font-medium text-slate-900 disabled:border-transparent disabled:bg-transparent disabled:font-bold disabled:text-indigo-600 focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 outline-none"
														bind:value={rule.triggerValue}
													>
														<option value="">Select Answer...</option>
														{#each triggerQ.options as opt}
															<option value={opt.value}>{opt.label}</option>
														{/each}
													</select>
												{:else}
													<input
														type="text"
														disabled={!isEditing && !editingQuestion.isNew}
														class="min-w-0 flex-1 rounded-[8px] border border-slate-200 bg-slate-50 px-2 py-1.5 text-xs font-medium text-slate-900 disabled:border-transparent disabled:bg-transparent disabled:font-bold disabled:text-indigo-600 focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 outline-none"
														placeholder="Type value..."
														bind:value={rule.triggerValue}
													/>
												{/if}
											</div>
										{/if}
									</div>
								{/each}
								{#if tempRules.length === 0}
									<p class="py-2 text-xs text-slate-400 italic">Always visible (no logic rules).</p>
								{/if}
							</div>
						</div>
					</div>
				</form>
			</div>
		{:else}
			<div class="flex flex-1 flex-col items-center justify-center p-10 text-center text-slate-300">
				<svg
					class="mb-4 h-16 w-16 text-slate-200"
					fill="none"
					stroke="currentColor"
					viewBox="0 0 24 24"
					><path
						stroke-linecap="round"
						stroke-linejoin="round"
						stroke-width="1.5"
						d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
					/></svg
				>
				<h3 class="mb-1 text-lg font-semibold text-slate-400">No Question Selected</h3>
				<p class="max-w-xs text-sm">
					Select a question from the list to view or edit its properties.
				</p>
			</div>
		{/if}
	</div>
</div>

{#if isAddingSection}
	<div
		class="fixed inset-0 z-[100] flex items-center justify-center bg-slate-900/50 p-4 backdrop-blur-sm"
	>
		<div class="w-full max-w-md overflow-hidden rounded-[16px] bg-white shadow-2xl">
			<div class="flex items-center justify-between border-b border-slate-100 px-6 py-4">
				<h3 class="font-bold text-slate-900">Add New Section</h3>
				<button
					onclick={() => (isAddingSection = false)}
					class="text-slate-400 hover:text-slate-600">✕</button
				>
			</div>

			<div class="space-y-4 p-6">
				<div>
					<label class="mb-1.5 block text-xs font-bold tracking-widest text-slate-400 uppercase"
						>Section Title</label
					>
					<input
						type="text"
						bind:value={newSectionTitle}
						class="w-full rounded-[8px] border border-slate-200 bg-slate-50 px-3 py-2 text-sm outline-none focus:border-indigo-500 focus:ring-2 focus:ring-indigo-500/10"
						placeholder="e.g. Health & Safety"
					/>
				</div>

				<div>
					<label class="mb-1.5 block text-xs font-bold tracking-widest text-slate-400 uppercase"
						>Survey Stage</label
					>
					<select
						bind:value={newSurveyType}
						class="w-full appearance-none rounded-[8px] border border-slate-200 bg-slate-50 px-3 py-2 text-sm outline-none focus:border-indigo-500 focus:ring-2 focus:ring-indigo-500/10"
					>
						<option value="INITIAL">Stage 2 (Initial)</option>
						<option value="DETAILED">Stage 3 (Detailed)</option>
					</select>
				</div>

				<div>
					<label class="mb-1.5 block text-xs font-bold tracking-widest text-slate-400 uppercase"
						>Category</label
					>
					<select
						bind:value={activeSurveyCategory}
						class="w-full appearance-none rounded-[8px] border border-slate-200 bg-slate-50 px-3 py-2 text-sm outline-none focus:border-indigo-500 focus:ring-2 focus:ring-indigo-500/10"
					>
						<option value="ADDICTION">Addiction</option>
						<option value="MENTAL">Mental Health</option>
					</select>
				</div>
			</div>

			<div class="flex justify-end gap-3 border-t border-slate-100 bg-slate-50 px-6 py-4">
				<button
					onclick={() => (isAddingSection = false)}
					class="px-4 py-2 text-sm font-semibold text-slate-600 hover:text-slate-900">Cancel</button
				>
				<button
					onclick={addSection}
					disabled={!newSectionTitle.trim()}
					class="rounded-[8px] bg-indigo-600 px-6 py-2 text-sm font-bold text-white transition-all hover:bg-indigo-700 disabled:bg-slate-300"
				>
					Create Section
				</button>
			</div>
		</div>
	</div>
{/if}

{#if isEditingSection}
	<div
		class="fixed inset-0 z-[100] flex items-center justify-center bg-slate-900/50 p-4 backdrop-blur-sm"
	>
		<div class="w-full max-w-xl overflow-hidden rounded-[16px] bg-white shadow-2xl">
			<div class="flex items-center justify-between border-b border-slate-100 px-6 py-4">
				<h3 class="font-bold text-slate-900">Edit Section Details</h3>
				<button
					onclick={() => (isEditingSection = false)}
					class="text-slate-400 hover:text-slate-600">✕</button
				>
			</div>

			<div class="space-y-4 p-6">
				<div>
					<label class="mb-1.5 block text-xs font-bold tracking-widest text-slate-400 uppercase"
						>Section Title</label
					>
					<input
						type="text"
						bind:value={editSectionTitle}
						class="w-full rounded-[8px] border border-slate-200 bg-slate-50 px-3 py-2 text-sm outline-none focus:border-indigo-500 focus:ring-2 focus:ring-indigo-500/10"
					/>
				</div>

				<div>
					<label class="mb-1.5 block text-xs font-bold tracking-widest text-slate-400 uppercase"
						>Survey Stage</label
					>
					<select
						bind:value={editSurveyType}
						class="w-full appearance-none rounded-[8px] border border-slate-200 bg-slate-50 px-3 py-2 text-sm outline-none focus:border-indigo-500 focus:ring-2 focus:ring-indigo-500/10"
					>
						<option value="INITIAL">Stage 2 (Initial)</option>
						<option value="DETAILED">Stage 3 (Detailed)</option>
					</select>
				</div>

				<div>
					<label class="mb-1.5 block text-xs font-bold tracking-widest text-slate-400 uppercase"
						>Category</label
					>
					<select
						bind:value={editSurveyCategory}
						class="w-full appearance-none rounded-[8px] border border-slate-200 bg-slate-50 px-3 py-2 text-sm outline-none focus:border-indigo-500 focus:ring-2 focus:ring-indigo-500/10"
					>
						<option value="ADDICTION">Addiction</option>
						<option value="MENTAL">Mental Health</option>
					</select>
				</div>
			</div>

			<!-- Section-level Display Logic -->
			<div class="border-t border-slate-100 px-6 pb-2 pt-5">
				<div class="mb-3 flex items-center justify-between">
					<div>
						<p class="text-xs font-bold tracking-widest text-slate-400 uppercase">Section Display Logic</p>
						<p class="mt-0.5 text-[10px] text-slate-400">Hide this entire section unless conditions are met</p>
					</div>
					<button
						type="button"
						class="text-xs font-bold text-indigo-600 hover:text-indigo-800"
						onclick={addSectionRule}>+ Add Rule</button
					>
				</div>

				<div class="space-y-2">
					{#each editSectionRules as rule, i}
						{@const triggerQ = data.sections
							.flatMap((s: any) => s.questions)
							.find((q: any) => q.id === Number(rule.triggerQuestionId))}
						{@const triggerSection = rule.triggerQuestionId
							? data.sections.find((s: any) =>
									s.questions.some((q: any) => String(q.id) === rule.triggerQuestionId)
								)
							: null}
						<div class="flex flex-col gap-2.5 rounded-[8px] border border-slate-200 bg-white p-3 text-sm text-slate-700 shadow-sm">
							<!-- Header row: label + delete button -->
							<div class="flex items-center justify-between">
								<span class="text-xs font-semibold text-slate-500">Show section <b class="text-slate-800">ONLY IF</b> the answer to:</span>
								<button
									type="button"
									class="shrink-0 rounded-[6px] p-1 text-slate-300 hover:bg-red-50 hover:text-red-500 transition-colors"
									title="Remove Rule"
									onclick={() => removeSectionRule(i)}>✕</button
								>
							</div>

							<!-- Section badge (shown after question is selected) -->
							{#if triggerSection}
								<div class="flex items-center gap-1.5">
									<span class="inline-flex items-center gap-1 rounded-[6px] bg-indigo-50 px-2 py-0.5 text-[10px] font-bold tracking-wide text-indigo-600 border border-indigo-100">
										<svg class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"/></svg>
										{triggerSection.parent ? `${triggerSection.parent.title} › ${triggerSection.title}` : triggerSection.title}
									</span>
								</div>
							{/if}

							<!-- Question select dropdown with optgroup sections -->
							<select
								class="w-full appearance-none rounded-[8px] border border-slate-200 bg-slate-50 px-2.5 py-1.5 text-xs font-medium text-slate-900 outline-none focus:border-indigo-500 focus:bg-white focus:ring-1 focus:ring-indigo-500"
								bind:value={rule.triggerQuestionId}
							>
								<option value="">— Select a Question —</option>
								{#each data.sections.filter((s: any) => s.questions.length > 0) as s}
									<optgroup label={s.parent ? `${s.parent.title} › ${s.title}` : s.title}>
										{#each s.questions as q}
											<option value={String(q.id)}>{q.text}</option>
										{/each}
									</optgroup>
								{/each}
							</select>

							<!-- Operator & Value row (only shown after question is selected) -->
							{#if rule.triggerQuestionId}
								<div class="flex items-center gap-2 border-t border-slate-100 pt-2">
									<select
										class="w-28 shrink-0 appearance-none rounded-[8px] border border-slate-200 bg-slate-50 px-2 py-1.5 text-xs font-medium text-slate-900 outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"
										bind:value={rule.operator}
									>
										<option value="eq">is exactly</option>
										<option value="neq">is not</option>
									</select>

									{#if triggerQ && triggerQ.options && triggerQ.options.length > 0}
										<select
											class="min-w-0 flex-1 appearance-none rounded-[8px] border border-slate-200 bg-slate-50 px-2 py-1.5 text-xs font-medium text-slate-900 outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"
											bind:value={rule.triggerValue}
										>
											<option value="">Select Answer...</option>
											{#each triggerQ.options as opt}
												<option value={opt.value}>{opt.label}</option>
											{/each}
										</select>
									{:else}
										<input
											type="text"
											class="min-w-0 flex-1 rounded-[8px] border border-slate-200 bg-slate-50 px-2 py-1.5 text-xs font-medium text-slate-900 outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"
											placeholder="Type value..."
											bind:value={rule.triggerValue}
										/>
									{/if}
								</div>
							{/if}
						</div>
					{/each}
					{#if editSectionRules.length === 0}
						<p class="py-1 text-xs text-slate-400 italic">Always shown (no conditions).</p>
					{/if}
				</div>
			</div>

			<div class="flex justify-end gap-3 border-t border-slate-100 bg-slate-50 px-6 py-4">
				<button
					onclick={() => (isEditingSection = false)}
					class="px-4 py-2 text-sm font-semibold text-slate-600 hover:text-slate-900">Cancel</button
				>
				<button
					onclick={saveSectionDetails}
					disabled={!editSectionTitle.trim()}
					class="rounded-[8px] bg-indigo-600 px-6 py-2 text-sm font-bold text-white transition-all hover:bg-indigo-700 disabled:bg-slate-300"
				>
					Save Changes
				</button>
			</div>
		</div>
	</div>
{/if}

{#if showQuestionSaved}
	<div
		transition:fade={{ duration: 200 }}
		class="fixed bottom-6 right-6 z-[1000] flex items-center gap-3 rounded-[12px] border border-emerald-100 bg-emerald-50 px-5 py-3.5 shadow-lg"
	>
		<div class="rounded-full bg-emerald-500 p-1 text-white">
			<svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
				<path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
			</svg>
		</div>
		<div>
			<p class="text-sm font-bold text-emerald-950">{saveMessage}</p>
		</div>
	</div>
{/if}

{#if isEmailTemplateModalOpen}
	<!-- Modal overlay -->
	<div
		transition:fade={{ duration: 150 }}
		class="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/40 p-6 backdrop-blur-sm"
	>
		<!-- Modal container -->
		<div class="flex max-h-[85vh] w-full max-w-2xl flex-col overflow-hidden rounded-[24px] bg-white shadow-2xl border border-slate-100">
			<!-- Header -->
			<div class="flex items-center justify-between border-b border-slate-100 px-8 py-5">
				<div>
					<h3 class="text-base font-black tracking-tight text-slate-900">Custom Email Template</h3>
					<p class="text-[10px] font-bold tracking-widest text-slate-400 uppercase mt-0.5">{activeSurveyCategory} Follow-up Email</p>
				</div>
				<button
					onclick={() => (isEmailTemplateModalOpen = false)}
					class="text-slate-400 hover:text-slate-600 transition-colors"
				>
					<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
						<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
					</svg>
				</button>
			</div>

			<!-- Body -->
			<div class="flex-1 overflow-y-auto p-8 space-y-6">

				<!-- Subject Line input -->
				<div class="space-y-1.5">
					<label class="text-[10px] font-black tracking-widest text-slate-400 uppercase">Email Subject</label>
					<input
						type="text"
						bind:value={emailSubject}
						placeholder="E.g., Hello, thank you for completing your wellbeing check"
						class="w-full rounded-[8px] border border-slate-200 bg-slate-50 px-4 py-2.5 text-sm font-semibold text-slate-700 transition-all focus:bg-white focus:ring-1 focus:ring-indigo-500 focus:outline-none"
					/>
				</div>

				<!-- Email Body Editor -->
				<div class="space-y-1.5">
					<label class="text-[10px] font-black tracking-widest text-slate-400 uppercase">Email Body (Rich Text)</label>
					
					<div class="rounded-[12px] border border-slate-200 bg-slate-50 p-3.5 space-y-3">
						<!-- WYSIWYG toolbar -->
						<div class="flex flex-wrap items-center gap-1.5 border-b border-slate-200/60 pb-3">
							<!-- Group 1: Text styles -->
							<button
								type="button"
								onmousedown={(e) => { e.preventDefault(); execCmd('bold'); }}
								class="inline-flex h-7 w-7 items-center justify-center rounded bg-white text-xs font-black text-slate-700 border border-slate-200/80 shadow-sm hover:bg-slate-100 transition-colors"
								title="Bold (Ctrl+B)"
							>
								B
							</button>
							<button
								type="button"
								onmousedown={(e) => { e.preventDefault(); execCmd('italic'); }}
								class="inline-flex h-7 w-7 items-center justify-center rounded bg-white text-xs italic font-bold text-slate-700 border border-slate-200/80 shadow-sm hover:bg-slate-100 transition-colors"
								title="Italic (Ctrl+I)"
							>
								I
							</button>
							<button
								type="button"
								onmousedown={(e) => { e.preventDefault(); execCmd('underline'); }}
								class="inline-flex h-7 w-7 items-center justify-center rounded bg-white text-xs underline font-bold text-slate-700 border border-slate-200/80 shadow-sm hover:bg-slate-100 transition-colors"
								title="Underline (Ctrl+U)"
							>
								U
							</button>
							<button
								type="button"
								onmousedown={(e) => { e.preventDefault(); execCmd('strikeThrough'); }}
								class="inline-flex h-7 w-7 items-center justify-center rounded bg-white text-xs line-through font-bold text-slate-700 border border-slate-200/80 shadow-sm hover:bg-slate-100 transition-colors"
								title="Strikethrough"
							>
								S
							</button>

							<div class="w-[1px] bg-slate-200 h-5 my-1 mx-1 shrink-0"></div>

							<!-- Group 2: Font Family & Font Size -->
							<select
								onchange={(e) => execCmd('fontName', e.currentTarget.value)}
								class="h-7 rounded border border-slate-200 bg-white text-xs px-2 outline-none text-slate-700 font-semibold cursor-pointer"
								title="Font Family"
							>
								<option value="">Font Family</option>
								<option value="Arial">Sans-Serif (Arial)</option>
								<option value="Georgia">Serif (Georgia)</option>
								<option value="Courier New">Monospace (Courier)</option>
								<option value="Times New Roman">Times New Roman</option>
								<option value="Verdana">Verdana</option>
							</select>

							<select
								onchange={(e) => execCmd('fontSize', e.currentTarget.value)}
								class="h-7 rounded border border-slate-200 bg-white text-xs px-2 outline-none text-slate-700 font-semibold cursor-pointer"
								title="Font Size"
							>
								<option value="">Font Size</option>
								<option value="2">Small</option>
								<option value="3">Normal</option>
								<option value="5">Large</option>
								<option value="6">Very Large</option>
								<option value="7">Extra Large</option>
							</select>

							<div class="w-[1px] bg-slate-200 h-5 my-1 mx-1 shrink-0"></div>

							<!-- Group 3: Lists -->
							<button
								type="button"
								onmousedown={(e) => { e.preventDefault(); execCmd('insertUnorderedList'); }}
								class="inline-flex h-7 px-2 items-center justify-center rounded bg-white text-xs font-bold text-slate-700 border border-slate-200/80 shadow-sm hover:bg-slate-100 transition-colors"
								title="Bullet List"
							>
								• List
							</button>
							<button
								type="button"
								onmousedown={(e) => { e.preventDefault(); execCmd('insertOrderedList'); }}
								class="inline-flex h-7 px-2 items-center justify-center rounded bg-white text-xs font-bold text-slate-700 border border-slate-200/80 shadow-sm hover:bg-slate-100 transition-colors"
								title="Numbered List"
							>
								1. List
							</button>

							<div class="w-[1px] bg-slate-200 h-5 my-1 mx-1 shrink-0"></div>

							<!-- Group 4: Alignments -->
							<button
								type="button"
								onmousedown={(e) => { e.preventDefault(); execCmd('justifyLeft'); }}
								class="inline-flex h-7 w-7 items-center justify-center rounded bg-white text-xs font-bold text-slate-700 border border-slate-200/80 shadow-sm hover:bg-slate-100 transition-colors"
								title="Align Left"
							>
								←
							</button>
							<button
								type="button"
								onmousedown={(e) => { e.preventDefault(); execCmd('justifyCenter'); }}
								class="inline-flex h-7 w-7 items-center justify-center rounded bg-white text-xs font-bold text-slate-700 border border-slate-200/80 shadow-sm hover:bg-slate-100 transition-colors"
								title="Align Center"
							>
								↔
							</button>
							<button
								type="button"
								onmousedown={(e) => { e.preventDefault(); execCmd('justifyRight'); }}
								class="inline-flex h-7 w-7 items-center justify-center rounded bg-white text-xs font-bold text-slate-700 border border-slate-200/80 shadow-sm hover:bg-slate-100 transition-colors"
								title="Align Right"
							>
								→
							</button>

							<div class="w-[1px] bg-slate-200 h-5 my-1 mx-1 shrink-0"></div>

							<!-- Group 5: Links & Images -->
							<button
								type="button"
								onmousedown={(e) => {
									e.preventDefault();
									const url = prompt('Enter website link URL:');
									if (url) execCmd('createLink', url);
								}}
								class="inline-flex h-7 px-2 items-center justify-center rounded bg-white text-xs font-bold text-slate-700 border border-slate-200/80 shadow-sm hover:bg-slate-100 transition-colors"
								title="Add Link"
							>
								Link
							</button>
							<button
								type="button"
								onmousedown={(e) => {
									e.preventDefault();
									const url = prompt('Enter hosted image URL:');
									if (url) execCmd('insertImage', url);
								}}
								class="inline-flex h-7 px-2 items-center justify-center rounded bg-white text-xs font-bold text-slate-700 border border-slate-200/80 shadow-sm hover:bg-slate-100 transition-colors"
								title="Insert Image by URL"
							>
								Image
							</button>

							<div class="w-[1px] bg-slate-200 h-5 my-1 mx-1 shrink-0"></div>

							<!-- Group 6: History -->
							<button
								type="button"
								onmousedown={(e) => { e.preventDefault(); execCmd('undo'); }}
								class="inline-flex h-7 w-7 items-center justify-center rounded bg-white text-xs font-bold text-slate-500 border border-slate-200/80 shadow-sm hover:bg-slate-100 transition-colors"
								title="Undo (Ctrl+Z)"
							>
								⟲
							</button>
							<button
								type="button"
								onmousedown={(e) => { e.preventDefault(); execCmd('redo'); }}
								class="inline-flex h-7 w-7 items-center justify-center rounded bg-white text-xs font-bold text-slate-500 border border-slate-200/80 shadow-sm hover:bg-slate-100 transition-colors"
								title="Redo (Ctrl+Y)"
							>
								⟳
							</button>

							<div class="w-[1px] bg-slate-200 h-5 my-1 mx-1 shrink-0"></div>

							<!-- Group 7: HTML Mode -->
							<button
								type="button"
								onclick={toggleCodeView}
								class="inline-flex h-7 px-2 items-center justify-center rounded border shadow-sm transition-colors text-xs font-bold
									{isCodeView 
										? 'bg-indigo-600 text-white border-indigo-700 hover:bg-indigo-700' 
										: 'bg-white text-indigo-600 border-indigo-200 hover:bg-indigo-50'}"
								title="Toggle HTML Source Code View"
							>
								{isCodeView ? 'Visual View' : 'HTML View'}
							</button>
						</div>

						<!-- WYSIWYG Editable Area / Code View Textarea -->
						{#if isCodeView}
							<textarea
								bind:value={currentHtml}
								class="w-full min-h-[220px] rounded-[8px] border border-slate-250 bg-slate-900 p-4 outline-none text-xs font-mono text-emerald-400 leading-relaxed"
								placeholder="<p>Write your raw HTML templates here...</p>"
							></textarea>
						{:else}
							<div
								bind:this={editorRef}
								contenteditable="true"
								onclick={handleEditorClick}
								class="min-h-[220px] rounded-[8px] border border-slate-150 bg-white p-4 outline-none text-sm text-slate-700 leading-relaxed font-medium prose prose-sm max-w-none email-editor-content"
							>
							</div>
						{/if}
					</div>
				</div>
			</div>

			<!-- Footer -->
			<div class="flex items-center justify-end gap-3 border-t border-slate-100 bg-slate-50 px-8 py-4 shrink-0">
				{#if showEmailTemplateSuccess}
					<span class="text-xs font-bold text-emerald-600 animate-pulse mr-2">Email template saved!</span>
				{/if}
				<button
					onclick={() => (isEmailTemplateModalOpen = false)}
					class="px-4 py-2 text-sm font-semibold text-slate-600 hover:text-slate-900 transition-colors"
				>
					Close
				</button>
				<button
					onclick={saveEmailTemplate}
					disabled={isSavingEmailTemplate}
					class="rounded-[8px] bg-indigo-600 px-6 py-2 text-sm font-bold text-white transition-all hover:bg-indigo-700 disabled:bg-slate-300"
				>
					{isSavingEmailTemplate ? 'Saving...' : 'Save Template'}
				</button>
			</div>
		</div>
	</div>
{/if}

<style>
	:global(.email-editor-content ul) {
		list-style-type: disc !important;
		padding-left: 1.5rem !important;
		margin-top: 0.5rem !important;
		margin-bottom: 0.5rem !important;
	}
	:global(.email-editor-content ol) {
		list-style-type: decimal !important;
		padding-left: 1.5rem !important;
		margin-top: 0.5rem !important;
		margin-bottom: 0.5rem !important;
	}
	:global(.email-editor-content li) {
		display: list-item !important;
	}
	:global(.email-editor-content a) {
		color: #2563eb !important;
		text-decoration: underline !important;
		font-weight: 600 !important;
		cursor: pointer !important;
	}
</style>

