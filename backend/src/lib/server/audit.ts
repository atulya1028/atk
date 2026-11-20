import { prisma } from './prisma';

/**
 * Log an administrative action to the AuditLog database table.
 * @param action The key identifier of the action (e.g. DELETE_PARTICIPANT)
 * @param description Detailed text description of the action
 */
export async function logAdminAction(action: string, description: string) {
    try {
        await prisma.auditLog.create({
            data: {
                action,
                description
            }
        });
    } catch (error) {
        console.error(`[AUDIT_ERROR] Failed to write admin audit log:`, error);
    }
}
