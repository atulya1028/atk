import jwt from 'jsonwebtoken';

const SECRET = process.env.JWT_SECRET || 'super-secret-key-change-me';

export function getUserFromRequest(request: Request) {
    const authHeader = request.headers.get('Authorization');
    if (!authHeader) return null;

    const token = authHeader.split(' ')[1];
    if (!token) return null;

    try {
        const decoded = jwt.verify(token, SECRET);
        return decoded as { userId: number, email: string };
    } catch (e) {
        return null;
    }
}
