// Only emails listed in ALLOWED_EMAILS (comma-separated) may create an account.
export function isAllowedEmail(email: string, allowed: string | undefined): boolean {
  if (!allowed) return false;
  const list = allowed.split(",").map((e) => e.trim().toLowerCase()).filter(Boolean);
  return list.includes(email.trim().toLowerCase());
}
