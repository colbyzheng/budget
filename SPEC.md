# Budget — Product Spec

Personal finance web app replacing Colby's Google Sheet budget tracker (April–Nov 2026).
v1 matches and extends the sheet with manual entry. v2 adds automatic transaction sync.
Doubles as a public resume project.

## Users and access
- Single real user (Colby). Sign-in: **Google** (only his email is allowed) and **passkey**.
- **Demo user**: a read-only account seeded with fake data, reached via a "Try demo" button.
- Every table has a `user_id`, and Row Level Security makes every row visible only to its owner.

## Accounts
| Account | Kind | v1 balance source |
|---|---|---|
| Capital One Savor | credit card | computed from transactions |
| BofA Unlimited Cash Rewards | credit card | computed |
| BofA checking (debit card) | checking | computed |
| Cash | cash | computed |
| Apple Cash | wallet | computed |
| WBL (Wharton Behavioral Lab, ClinCard prepaid) | prepaid | computed |
| Pibank HYSA | savings | manual snapshots + transfers |
| Fidelity brokerage | investment | manual snapshots |
| Fidelity Roth IRA | investment | manual snapshots |
| Credit (unspecified) | legacy | historic sheet rows; reassigned by hand |

## Transactions
- Fields: date, amount (integer cents), type, account, category, subcategory, tags, description,
  `source` (manual / import / sync), `external_id` (for sync dedupe later).
- **Types**
  - `expense`: counts toward spending.
  - `income`: has a source (Job, Financial aid, Family, Other).
  - `transfer`: between your own accounts. Covers card payoff, HYSA/brokerage/Roth deposits, and moving cash around. Never counts as spending.
  - `reimbursement`: money back from someone, linked to the original expense, which reduces that expense's net amount.
- Card spending counts at the swipe. Paying the card bill is a transfer.
- Investing deposits are transfers, shown as a separate "saved/invested this month" figure.

## Categories
Food, Transport, Event/Tickets, Purchases, Fun, Subscriptions, Gifts (the old "Investing" category becomes transfers).
Editable subcategories (e.g. Food → Groceries / Dining / Boba) and free-form tags (#trip-sf).

## Features (v1)
- **Entry:** a desktop form (dropdowns + text boxes) and an editable table with multi-select bulk edit (e.g. reassigning an account). A phone quick-add screen auto-suggests the category from past descriptions. Online-only.
- **Budgets:** monthly limits per category with progress bars.
  - No rollover.
  - Reimbursements reduce spending.
  - Transfers are excluded.
- **Spending alerts:** a push notification each time total monthly spending crosses another $500 (step adjustable). Uses web push, and on iPhone the app must be installed to the Home Screen.
- **Dashboard**
  - Sheet parity: monthly totals by category and by account, total excluding investing.
  - Per-category breakdown, trends across months, charts.
  - Income vs spending and savings rate.
  - Account balances and net worth over time.
  - "Who owes me" (unpaid reimbursements).
- **History import:** one-time import of the sheet's April–Nov 2026 tabs.
  - "Credit" rows go to the legacy account.
  - Positive Zelle rows become unlinked reimbursements.
- **Export:** CSV/JSON of all data.
- **PWA:** installable on the phone.

## v2
- Automatic sync. Candidates:
  - Teller.io (free tier, CapOne + BofA)
  - Plaid trial
  - iOS Shortcuts Wallet trigger (covers Apple Cash)
  - CSV import
  - Gmail alert parsing
- Auto-mirror to the Google Sheet.
- Offline entry queue.
- Budget rollover.

## Non-goals
Multiple real users, holdings/stock-level tracking, storing bank credentials, mobile native app.
