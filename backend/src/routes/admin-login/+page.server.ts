import { fail, redirect } from '@sveltejs/kit';
import type { Actions } from './$types';
import { env } from '$env/dynamic/private';

export const actions: Actions = {
    login: async ({ request, cookies }) => {
        const data = await request.formData();
        const password = String(data.get('password') || '');

        // Use the ADMIN_PASSWORD environment variable, fallback to the one in .pw file
        const correctPassword = env.ADMIN_PASSWORD || 'NovTekATK@1989#22';

        if (password === correctPassword) {
            cookies.set('admin_session', 'authenticated', {
                path: '/',
                httpOnly: true,
                sameSite: 'strict',
                secure: process.env.NODE_ENV === 'production',
                maxAge: 60 * 60 * 24 * 7 // 1 week
            });
            throw redirect(303, '/admin');
        }

        return fail(401, { incorrect: true });
    },

    logout: async ({ cookies }) => {
        cookies.delete('admin_session', { path: '/' });
        throw redirect(303, '/admin-login');
    }
};
