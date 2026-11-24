import { json } from '@sveltejs/kit';
import { prisma } from '$lib/server/prisma';
import jwt from 'jsonwebtoken';

const SECRET = process.env.JWT_SECRET || 'super-secret-key-change-me';

export async function GET({ request }) {
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

        const user = await prisma.user.findUnique({
            where: { id: decoded.userId }
        });

        if (!user) return json({ error: 'User not found' }, { status: 404 });

        return json({
            success: true,
            email: user.email,
            profile: {
                fullName: user.name,
                ageGroup: user.age,
                phoneNumber: user.phoneNumber,
                postcode: user.pinCode,
                gender: user.gender,
                occupation: user.occupation,
                maritalStatus: user.maritalStatus
            },
            user: {
                id: user.id,
                email: user.email,
                name: user.name,
                age: user.age,
                phoneNumber: user.phoneNumber,
                pinCode: user.pinCode,
                gender: user.gender,
                occupation: user.occupation,
                maritalStatus: user.maritalStatus,
                isProfileComplete: user.isProfileComplete,
                hasCompletedInitialSurvey: user.hasCompletedInitialSurvey,
                hasUnlockedDetailedSurvey: user.hasUnlockedDetailedSurvey,
                surveyCategory: user.surveyCategory
            }
        });
    } catch (e) {
        console.error(e);
        return json({ error: 'Internal Server Error' }, { status: 500 });
    }
}

export async function PUT({ request }) {
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

        const {
            fullName, name = fullName,
            ageGroup, age = ageGroup,
            postcode, pinCode = postcode,
            phoneNumber, gender, occupation, maritalStatus
        } = await request.json();

        const user = await prisma.user.update({
            where: { id: decoded.userId },
            data: {
                name,
                age,
                phoneNumber,
                pinCode,
                gender,
                occupation,
                maritalStatus,
                isProfileComplete: true
            }
        });

        return json({
            success: true,
            user: {
                id: user.id,
                email: user.email,
                name: user.name,
                isProfileComplete: user.isProfileComplete,
                hasCompletedInitialSurvey: user.hasCompletedInitialSurvey,
                hasUnlockedDetailedSurvey: user.hasUnlockedDetailedSurvey,
                surveyCategory: user.surveyCategory
            }
        });

    } catch (e) {
        console.error(e);
        return json({ error: 'Internal Server Error' }, { status: 500 });
    }
}
