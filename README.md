# SecondLife · AI-Powered Circular Electronics Reuse Platform

A working hackathon prototype. Users record the electronics they own, or pick a project, and the app
shows what can be built, what is missing, and the estimated cost and reuse impact. Matching is
deterministic and explainable. No paid AI API is required.

## Quick start

```bash
npm install
npm run dev        # http://localhost:5173
npm run build      # type-check and production build
npm run preview
```

Requirements: Node.js 18 or newer.

**Demo login:** `demo@secondlife.local` / `demo1234`. It starts with a sample kit (Arduino Uno, 2 ultrasonic
sensors, 10 LEDs, 20 resistors, SG90 servo, jumper wires, breadboard, DHT11, 2 DC motors).
You can also register a new account, which starts empty.

## What works

| Area | Status |
|---|---|
| Home page (hero, feature cards, how-it-works, example projects, CTA) | Working |
| Register and sign in (validation, confirm password, duplicate-email check) | Working (demo mode) |
| Protected routes (dashboard, build, my projects, impact, advisor, profile) | Working |
| Build What I Have · manual entry (catalog autocomplete, custom parts, edit, delete, qty changes, merge duplicates, clear form with confirmation, save, reuse) | Working |
| Build What I Have · discarded electronics (user-confirmed recovered parts, never assumed) | Working |
| Discover What I Can Build (Build Now / Small Additions / Not Feasible, no duplicates across groups) | Working |
| What Do You Want to Build? (name search, suggestions, custom idea search, requirement vs inventory table) | Working |
| Projects catalog (search, category, difficulty, feasibility, sort by match or cost) | Working |
| Project detail (requirements, costs, warnings, instructions, safety, impact, status buttons) | Working |
| Find Components (search, category, required quantities, shopping checklist linked to a project, acquired toggle) | Working |
| My Projects (Saved, Planned, In Progress, Completed; progress slider; delete with confirmation; no duplicates) | Working |
| Impact Dashboard (charts from completed projects only; "Not enough data yet" when empty) | Working |
| Dashboard (summary cards, inventory chart, impact chart, recent items, recommendations, activity) | Working |
| AI Advisor (rule-based, labelled as such; answers only from inventory and catalog) | Working |
| Profile (edit name, clear data) | Working |
| Responsive layout (sidebar on desktop, drawer on mobile) | Working |
| Supabase database and Auth | **Not connected yet.** Schema provided in `supabase/schema.sql`. |
| Express backend | **Not included.** Matching runs in the browser, so no server is needed for this version. |
| Live prices, supplier stock, real purchasing | **Not implemented, by design.** Prices are demo estimates. |

## How matching works

Implemented in `src/lib/matching.ts`. Thresholds are in `CLASSIFICATION_THRESHOLDS`.

For each required component:

- `usable = min(owned, required)` (working units first, then units marked "Needs testing")
- `missing = max(0, required - owned)`
- Units marked "Not working" are ignored.
- A listed compatible alternative (for example ESP32 for Arduino Uno) fills a shortfall only when
  the primary part is short. It always adds a verification warning.

**Quantity-based match** = total usable units ÷ total required units × 100. This measures quantities
only. It does not measure technical compatibility or guarantee success.

**Classification**

- **Build Now:** nothing missing and no open verification item.
- **Build With Small Additions:** at most `maxMissingTypesForSmallAdditions` types and
  `maxMissingUnitsForSmallAdditions` units missing, with match at or above
  `minMatchPercentForSmallAdditions`. Also used when everything is present but a verification item
  is still open. The reason is shown on the project page.
- **Not Feasible Yet:** a critical part is missing, or the shortfall exceeds the thresholds.

**Costs.** Additional cost = Σ missing × unit price. Build cost = additional cost + consumables.
Savings vs new = comparable new-product price − build cost. This can be negative, and it is shown
as negative.

**Impact.** Only projects marked *Completed* count. E-waste = Σ usable units × configured weight
per unit. The result is labelled as an estimate.

## Project structure

```
src/
  App.tsx                  routes and auth guard
  main.tsx                 entry point
  types.ts                 shared types
  data/catalog.ts          components, projects, instructions, safety, demo prices
  lib/matching.ts          deterministic matching and cost engine
  lib/store.tsx            demo auth + localStorage persistence (AppProvider / useApp)
  lib/actions.ts           saved-project mutations (duplicate prevention)
  lib/impact.ts            impact aggregation (completed projects only)
  lib/advisor.ts           rule-based advisor
  lib/utils.ts             formatting helpers
  components/ui.tsx        design primitives
  components/Layout.tsx    sidebar + mobile navigation
  components/ProjectCard.tsx
  pages/*.tsx              one file per screen
supabase/schema.sql        planned Postgres schema with RLS policies
```

## Demo mode and security

- All data is stored in `localStorage` under `secondlife-demo-v1`. Clearing site data removes it.
- Passwords are stored in plain text in the browser. **This is demo authentication, not
  production security.** Do not reuse a real password.
- No secrets are used. `.env.example` lists the Supabase variables for the planned integration.
  The service-role key must never reach the frontend.

## Connecting Supabase (next step)

1. Create a Supabase project and run `supabase/schema.sql`.
2. Add `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` to `.env.local`.
3. Replace the `localStorage` functions in `src/lib/store.tsx` with `supabase.auth` calls and
   table queries. Keep `src/lib/matching.ts` unchanged, since it is pure and runs in the browser.

## Deployment

Any static host works (Vercel, Netlify, GitHub Pages). For client-side routing, configure a
single-page-app fallback that serves `index.html` for unknown paths.

## Limitations

- Electrical compatibility is limited to the notes in the catalog. Always verify against each
  component's datasheet before wiring.
- Reference prices are approximate INR figures for demonstration. They are not live market prices.
- Environmental figures are estimates from configured weights. They are not independently verified.
- The AI Advisor is rule-based. No AI API is connected.
