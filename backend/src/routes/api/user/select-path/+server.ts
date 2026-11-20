import { json } from '@sveltejs/kit';
import { prisma } from '$lib/server/prisma';
import jwt from 'jsonwebtoken';

const SECRET = process.env.JWT_SECRET || 'super-secret-key-change-me';

export async function POST({ request }) {
    try {
        const authHeader = request.headers.get('Authorization');
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return json({ error: 'Unauthorized' }, { status: 401 });
        }

        const token = authHeader.split(' ')[1];
        let decoded;
        try {
            decoded = jwt.verify(token, SECRET) as any;
        } catch (e) {
            return json({ error: 'Invalid or expired token' }, { status: 401 });
        }

        const body = await request.json();
        const categoryValue = body.surveyCategory || body.category;
        const surveyCategory = categoryValue?.toString().toUpperCase();

        if (!surveyCategory || !['ADDICTION', 'MENTAL'].includes(surveyCategory)) {
            return json({ error: 'Invalid path category' }, { status: 400 });
        }

        const user = await prisma.user.update({
            where: { id: decoded.userId },
            data: { surveyCategory }
        });

        return json({
            success: true,
            user: {
                id: user.id,
                email: user.email,
                surveyCategory: user.surveyCategory,
                isProfileComplete: user.isProfileComplete,
                hasCompletedInitialSurvey: user.hasCompletedInitialSurvey,
                hasUnlockedDetailedSurvey: user.hasUnlockedDetailedSurvey
            }
        });

    } catch (e) {
        console.error(e);
        return json({ error: 'Internal Server Error' }, { status: 500 });
    }
}
