# Budget — Agent Context
_Last updated: 2026-11-26_

**Read this first.** It's a short briefing for any agent working in `~/Budget`. For detail, see
`SPEC.md` (product), `PLAN.md` (milestones), and `CLAUDE.md` (rules).

## Summary
Colby is replacing his Google Sheet budget tracker with a single-user Next.js + Supabase web app
(public repo, with a read-only demo user for recruiters). v1 = manual entry + dashboard + history
import. v2 = automatic bank sync.

## Status
- **Active:** M1 scaffold: code done (branch m1-scaffold). Waiting on Supabase, Google OAuth, Vercel setup. Repo is private until M6.
- **Done:** product and plan grilling (all decisions are in SPEC.md).
- **Next:** M2 data model (ask Colby "you or me?" on the schema).
- **Open questions:** v2 sync provider (Teller / Plaid / iOS Shortcuts / CSV / Gmail); real app name before M6.

## Key decisions cheat-sheet
- Accounts: CapOne Savor, BofA Unlimited Cash (credit); BofA checking; Cash; Apple Cash; WBL
  (ClinCard prepaid); Pibank HYSA; Fidelity brokerage + Roth IRA; legacy "Credit (unspecified)".
- Transaction types: expense / income / transfer / reimbursement (linked to the original expense).
- Card payoff and investing deposits = transfers, never spending.
- Money = integer cents. `user_id` + RLS on every table. No real data or secrets in git.
- Categories: Food, Transport, Event/Tickets, Purchases, Fun, Subscriptions, Gifts, plus subcats and tags.
- Alerts: push notification each $500 of total monthly spending.

## Rules for subagents
- Colby may have claimed a piece to write himself. **Do not write or rewrite code he claimed.**
  Return findings and suggestions, not rewrites.
- Follow CLAUDE.md hard rules. Keep reports short.

## File map
- Docs: `SPEC.md`, `PLAN.md`, `CLAUDE.md`, `CONTEXT.md`, `README.md`
- `src/db/`: `index.ts` (Drizzle client), `schema.ts` (barrel), `auth-schema.ts` (Better Auth tables). Migrations in `drizzle/`.
- `src/lib/auth.ts` (Better Auth server; allowlist hook), `auth-client.ts`, `allowlist.ts` (+ test)
- `src/proxy.ts`: redirects signed-out visitors to `/sign-in` (Next 16 renamed middleware → proxy)
- `src/app/`: `page.tsx` (home; session behind Suspense), `sign-in/`, `api/auth/[...all]/`
- `.github/workflows/ci.yml`: lint, typecheck, test, build
- Next 16 note: `cacheComponents` is on, so session/DB reads must sit behind `<Suspense>`. Read `node_modules/next/dist/docs/` before writing Next code (see AGENTS.md).

## Commands
See CLAUDE.md. Env vars: `.env.example` → `.env.local`.
