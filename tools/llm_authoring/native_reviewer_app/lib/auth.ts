import { NextRequest } from "next/server";

export function assertReviewerAuth(req: NextRequest): void {
  const token = process.env.REVIEWER_API_TOKEN?.trim();
  if (!token) return;
  const header = req.headers.get("authorization") ?? "";
  if (!header.startsWith("Bearer ") || header.slice(7).trim() !== token) {
    throw new Error("unauthorized");
  }
}
