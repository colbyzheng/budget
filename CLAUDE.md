# Budget

Personal finance web app replacing Colby's budget Google Sheet. Public resume project.
Read first: `CONTEXT.md` (current status), then `SPEC.md` (what) and `PLAN.md` (milestones).

## Stack
Next.js (App Router) + TypeScript (strict) · Tailwind · Supabase Postgres · Drizzle ORM (migrations
in repo) · Better Auth: Google (allowlist via ALLOWED_EMAILS) + passkey (M6) · Vitest · Playwright · Vercel · GitHub Actions.

## Commands
`npm run dev` · `npm run lint` · `npm run typecheck` · `npm test` · `npm run build` · `npm run db:generate` · `npm run db:migrate` (e2e added in M6)

## Hard rules
- **Never commit real financial data, `.env*`, or secrets.** The repo is public. Seed/demo data is
  generated. The sheet import reads a local export that stays out of git.
- Every table has `user_id`, and Row Level Security is on for all tables.
- Money is **integer cents** everywhere. Never use floats for amounts.
- Never store bank credentials.
- Transfers never count as spending. Reimbursements reduce the linked expense.

## Pairing protocol (Colby is learning; follow every time)
1. Before any non-boilerplate piece (schema, queries, budget math, import mapping, suggest logic,
   alerts…): explain what it does and why, give the function signature + types, and write 1–2
   failing tests.
2. Ask Colby: "you or me?"
3. If Colby writes it: review, explain any changes, and let him fix them. Never silently rewrite his code.
4. Boilerplate (config, scaffolding, UI wiring) is Claude's without asking.
5. End each milestone with a short what/why summary and wait for approval before the next.

## Conventions
- Small PRs, short commit messages, only Colby's name on commits (no Claude attribution).
- 1–2 tests per PR on the main behavior. Money logic always gets a test.
- Subagents: start every prompt with "Read ~/Budget/CONTEXT.md first." Update CONTEXT.md at the
  end of each milestone or session.
