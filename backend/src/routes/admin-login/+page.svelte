<script lang="ts">
    import { enhance } from '$app/forms';
    import type { ActionData } from './$types';

    let { form } = $props<{ form: ActionData }>();
</script>

<div class="min-h-screen bg-slate-50 flex flex-col justify-center items-center py-12 px-4 sm:px-6 lg:px-8 font-sans">
    <div class="max-w-md w-full space-y-8 bg-white p-10 rounded-2xl shadow-xl border border-slate-100">
        <div>
            <div class="w-16 h-16 bg-indigo-50 text-indigo-600 rounded-2xl mx-auto flex items-center justify-center mb-6">
                <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"/></svg>
            </div>
            <h2 class="text-center text-3xl font-black text-slate-900 tracking-tight">Admin Portal</h2>
            <p class="mt-2 text-center text-sm text-slate-500 font-medium">Please enter the master password to continue</p>
        </div>
        <form class="mt-8 space-y-6" method="POST" action="?/login" use:enhance>
            {#if form?.incorrect}
                <div class="bg-red-50 text-red-600 text-sm p-3 rounded-lg text-center font-bold border border-red-100">
                    ⚠️ Incorrect password. Please try again.
                </div>
            {/if}
            <div class="space-y-2">
                <label for="password" class="block text-xs font-bold text-slate-400 uppercase tracking-widest">Master Password</label>
                <input id="password" name="password" type="password" required class="appearance-none rounded-xl block w-full px-4 py-3 border border-slate-200 placeholder-slate-400 text-slate-900 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition-all font-medium bg-slate-50 focus:bg-white" placeholder="••••••••">
            </div>

            <button type="submit" class="group relative w-full flex justify-center py-3 px-4 border border-transparent text-sm font-bold rounded-xl text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 transition-all shadow-md hover:shadow-lg">
                Authenticate Securely &rarr;
            </button>
        </form>
    </div>
</div>
