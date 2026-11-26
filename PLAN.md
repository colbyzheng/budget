# Budget — Plan

Soft target: full v1 by ~Dec 3, 2026 (end of month at the latest).

| Day | Milestones |
|---|---|
| 1 | M0 docs + repo · M1 scaffold |
| 2 | M2 schema · M3 entry |
| 3 | M4 sheet import · M5 dashboard queries |
| 4 | M5 charts, budgets, net worth, $500 push alerts |
| 5 | M6 passkey, demo, README, smoke test |

## M0 — Docs + repo ✅
SPEC.md, PLAN.md, CLAUDE.md, CONTEXT.md, README, .gitignore. GitHub repo `budget` (private until M6).

## M1 — Scaffold
Next.js (App Router) + TypeScript strict, Tailwind, Supabase Postgres, Drizzle ORM, Google sign-in
locked to Colby's email, GitHub Actions (lint, typecheck, Vitest), Vercel deploy.

## M2 — Data model
Tables: users, accounts, transactions, categories, subcategories, tags, transaction_tags,
reimbursement links, budgets, balance_snapshots, push_subscriptions. `user_id` + RLS on all.
Candidate pieces for Colby to write: schema, balance computation.

## M3 — Entry
Desktop form + editable table (multi-select bulk edit), phone quick-add, category auto-suggest.
Candidate for Colby: auto-suggest logic.

## M4 — Sheet import
Script that reads the exported sheet (never committed) and maps rows to transactions.
Candidate for Colby: row mapping.

## M5 — Dashboard
Sheet-parity totals, breakdown, trends, charts, income vs spending, net worth, budgets with progress,
who-owes-me, $500 spending push alerts (service worker + VAPID).
Candidates for Colby: aggregation queries, budget math, alert threshold logic.

## M6 — Polish
Passkey sign-in, read-only demo user + seed data, CSV/JSON export, README with screenshots and
architecture, Playwright smoke test (sign in → add transaction → see it on dashboard), pick real name.

## v2
Sync provider, Google Sheet mirror, Apple Cash via iOS Shortcuts, offline queue, rollover.
