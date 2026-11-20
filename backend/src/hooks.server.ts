import type { Handle } from '@sveltejs/kit';

export const handle: Handle = async ({ event, resolve }) => {

    if (event.url.pathname.startsWith('/api')) {

        if (event.request.method === 'OPTIONS') {
            return new Response(null, {
                headers: {
                    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, PATCH, OPTIONS',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Headers': '*',
                }
            });
        }
    }

    // Protect Admin Routes
    if (event.url.pathname.startsWith('/admin') && !event.url.pathname.startsWith('/admin-login')) {
        const authCookie = event.cookies.get('admin_session');
        if (authCookie !== 'authenticated') {
            return new Response(null, {
                status: 303,
                headers: { location: '/admin-login' }
            });
        }
    }

    const response = await resolve(event);

    if (event.url.pathname.startsWith('/api')) {
        response.headers.set('Access-Control-Allow-Origin', '*');
        response.headers.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, PATCH, OPTIONS');
        response.headers.set('Access-Control-Allow-Headers', '*');
    }

    return response;
};
