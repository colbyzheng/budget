# Budget — Agent Context
_Last updated: 2026-11-26_

**Read this first.** It's a short briefing for any agent working in `~/Budget`. For detail, see
`SPEC.md` (product), `PLAN.md` (milestones), and `CLAUDE.md` (rules).

## Summary
Colby is replacing his Google Sheet budget tracker with a single-user Next.js + Supabase web app
(public repo, with a read-only demo user for recruiters). v1 = manual entry + dashboard + history
import. v2 = automatic bank sync.

## Status
- **Active:** M0 docs + repo.
- **Done:** product and plan grilling (all decisions are in SPEC.md).
- **Next:** M1 scaffold (Next.js, Supabase, Drizzle, Google auth, CI, Vercel).
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
_(fill in as code appears)_
- `SPEC.md`, `PLAN.md`, `CLAUDE.md`, `CONTEXT.md`, `README.md`

## Commands
_(added in M1)_
