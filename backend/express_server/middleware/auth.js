import crypto from "node:crypto";
import jwt from "jsonwebtoken";

export const hashToken = (token) =>
  crypto.createHash("sha256").update(token).digest("hex");

export const asyncRoute = (fn) => (req, res, next) =>
  Promise.resolve(fn(req, res, next)).catch(next);

export async function authenticate(req, res, next) {
  const token = req.headers.authorization?.match(/^Bearer (.+)$/)?.[1];
  if (!token) return res.status(401).json({ error: "Sign in to continue." });
  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET, {
      issuer: "atk-api",
      audience: "atk-app",
    });
    next();
  } catch {
    res
      .status(401)
      .json({ error: "Your session has expired. Please sign in again." });
  }
}

export async function authenticateAdmin(req, res, next) {
  const token = req.headers.authorization?.match(/^Bearer (.+)$/)?.[1];
  if (!token) {
    return res.status(401).json({ error: "Admin authorization required." });
  }
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET, {
      issuer: "atk-api",
      audience: "atk-app",
    });
    if (payload.role !== "admin") {
      return res
        .status(403)
        .json({ error: "Access denied: Administrator privileges required." });
    }
    req.user = payload;
    next();
  } catch {
    res
      .status(401)
      .json({ error: "Your session has expired. Please sign in again." });
  }
}
