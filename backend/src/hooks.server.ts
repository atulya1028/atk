import type { Handle } from '@sveltejs/kit';

export const handle: Handle = async ({ event, resolve }) => {

    const path = event.url.pathname;
    const isApiRoute = ['/api', '/auth', '/user'].some(
        (prefix) => path === prefix || path.startsWith(prefix + '/')
    );
    const corsHeaders = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, PATCH, OPTIONS',
        'Access-Control-Allow-Headers': '*, Authorization'
    };

    if (isApiRoute && event.request.method === 'OPTIONS') {
        return new Response(null, { headers: corsHeaders });
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

    if (isApiRoute) {
        for (const [name, value] of Object.entries(corsHeaders)) {
            response.headers.set(name, value);
        }
    }

    return response;
};
