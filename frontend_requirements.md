# Frontend Requirements — Dental Clinic Management App (Flutter Desktop)

## 1. Project Overview

This is the **Flutter Desktop frontend** for a fully local, single-user dental clinic management app.

- The **backend is already built** (FastAPI + SQLite, running on `127.0.0.1:8000`). This document is for the **frontend only**.
- Companion document: `backend_requirements.md` — contains the full API contract (endpoints, request/response shapes, status values). Treat it as the source of truth for how to talk to the backend. Do not modify or rebuild anything backend-related.
- Target platform: Flutter **Desktop** (Windows/Linux/macOS as applicable) — not mobile, not web.
- Single user (the dentist), no login/auth screen needed in this phase.

---

## 2. Tech Stack & Key Packages

| Purpose | Package | Notes |
|---|---|---|
| State management | `get` (GetX) | Chosen based on prior developer experience with this package — familiarity outweighs the generic 2026 recommendation (Riverpod) for a solo beginner project. Also usable for routing (`Get.toNamed`) and simple dependency injection if preferred over a separate router package. |
| Routing | `get` (GetX routing) or `go_router` | Default to GetX's built-in routing for consistency with the state management choice, unless a specific need for `go_router` arises |
| HTTP client | `dio` | Centralized base URL/timeout config, interceptors for logging and error handling — much easier to debug the local API connection than the bare `http` package |
| Calendar / week view | `table_calendar` | Used for the day-based booking view (section 6.2); supports fully custom day-cell builders, needed for the capacity color-coding |
| Dental chart (Odontogram) | `teeth_selector` (starting point) or a custom `CustomPainter` widget | See section 6.3 — evaluate `teeth_selector` first; if it can't support per-tooth status coloring + tap-to-open-detail interactions cleanly, build a custom painter-based widget instead |
| Date/locale formatting | `intl` | Needed for French date/number formatting throughout the UI |
| General UI interactivity/polish | `flutter_animate` | Lightweight, chainable API for smooth micro-interactions (fade-ins, transitions, hover/tap feedback) across the app — no external design tool or asset files needed, fits a solo-developer workflow. This is a suggestion, not a hard requirement: if you identify a better-suited package for a specific interaction while building, feel free to use it instead — just note the substitution when summarizing the phase. |
| PDF export (Phase 2 only, not now) | `pdf` + `printing` | Do not implement yet — just be aware this is the likely pairing when that phase starts |

Before adding any of these, check current versions/compatibility on pub.dev, since package ecosystems evolve. **Interactivity is a stated priority for this whole project** — beyond the packages listed above, feel free to research and propose additional packages (animation, gestures, transitions, etc.) wherever they would meaningfully improve how responsive and alive the app feels, especially in the Odontogram (6.3) and Appointments (6.2) screens.

---

## 3. Recommended Project Structure

```
frontend/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── api_client.dart       # Dio instance, base URL, interceptors
│   │   └── routes.dart            # GetX route definitions
│   ├── models/                     # Dart data classes matching API responses
│   ├── controllers/                 # GetX controllers (one group per module)
│   ├── screens/
│   │   ├── patients/
│   │   ├── appointments/
│   │   ├── treatments/               # includes the odontogram widget
│   │   ├── invoices/
│   │   ├── dashboard/
│   │   └── settings/
│   └── widgets/                        # shared reusable widgets
└── pubspec.yaml
```

---

## 4. Language & Naming Conventions

- All code (variable names, class names, file names, comments) in **English**.
- All **user-facing text** (labels, buttons, messages, screen titles) in **French**, since the app is used by a French-speaking dentist.
- Data received from the backend that represents clinic content (treatment names, etc.) is already French — display as-is.
- Status values from the API stay in English internally (`"booked"`, `"completed"`, `"no_show"`, `"planned"`, `"unpaid"`, etc.) but must be **translated to French labels in the UI** (e.g. `"booked"` → `"Réservé"`, `"no_show"` → `"Absent"`). Keep this mapping centralized in one place (e.g. a single `status_labels.dart` file), not scattered across widgets.

---

## 5. API Integration

- Base URL: `http://127.0.0.1:8000` (use `127.0.0.1`, not `localhost` — avoids IPv6 resolution issues). Make this configurable (e.g. a constant or `.env`-style value), not hardcoded in multiple places.
- Refer to `backend_requirements.md` sections 5 and 6 for exact endpoint paths, request bodies, and response shapes for every module.
- Centralize all API calls in a dedicated layer (e.g. one Dart class/file per module: `patients_api.dart`, `appointments_api.dart`, etc.) that wraps the shared `dio` instance — screens/widgets should never call `dio` directly.
- Handle connection errors gracefully (e.g. backend not running yet) with a clear, friendly message rather than a raw exception — this matters because the dentist may occasionally forget to start the backend first.

---

## 6. Functional Requirements by Module (UI/UX)

### 6.1 Patients
- List screen with search bar (search by name/phone, live filtering)
- Patient detail screen: personal info, medical history (displayed prominently, e.g. in a highlighted card if allergies are present), treatment history, invoice history
- Add/edit form with validation (required fields: full name at minimum)

### 6.2 Appointments — Simplified Day-Based Booking UI

This must reflect the simplified backend model: **no time field, just a date**.

- A week view (built with `table_calendar` or a custom horizontal week strip) where **each day cell shows a color based on fill ratio** (booked_count / daily_patient_limit, fetched from `GET /appointments/capacity`):
  - Green: under 50%
  - Yellow/orange: 50–80%
  - Red: 80%+
- Tapping a day opens a simple list of patients booked that day, each with two quick-action buttons: mark **Completed** / mark **No-show**.
- Booking flow: pick a patient (search/autocomplete or "new patient" shortcut) → pick a day from the week view → confirm. **No time picker anywhere in this flow.**
- If the selected day is at/above the capacity limit, show a non-blocking confirmation dialog ("Ce jour est presque complet, continuer quand même ?") — the booking must still be allowed to proceed if the user confirms, per the backend's warning-not-block behavior.
- No queue/check-in/arrival-order UI — explicitly do not build this, it was deliberately removed from the design.

### 6.3 Treatments (Odontogram) — Highest Interactivity Priority

This is the most important screen to get right, per the project's emphasis on interactivity.

- Visual chart of 32 teeth (FDI numbering 11–48), each tooth individually tappable
- Tapping a tooth opens a small panel/dialog showing: current status, treatment history for that specific tooth, and a button to add a new treatment for it
- Each tooth should be color-coded by its latest status (e.g. healthy = default/white, planned = one color, completed = another) — pull this from the patient's treatment list (`GET /patients/{id}/treatments`)
- Treatment form: select treatment type (from `GET /treatment-types`, French labels), status, price (prefilled from the type's default price but editable), date, notes
- This screen should feel fluid and responsive — smooth taps, clear visual feedback, no jarring reloads of the whole chart after each small update if avoidable (update local state optimistically where reasonable, reconcile with the API response)

### 6.4 Invoices & Payments
- Invoice list per patient with status badges (French labels: "Non payée", "Partiellement payée", "Payée")
- Invoice detail: line items, total, paid amount, remaining balance, payment history
- "Add payment" form (amount, method, date)
- No PDF export UI in this phase — leave a clearly marked placeholder/TODO comment in the code for where that button will go later, but do not implement it

### 6.5 Dashboard
- Landing screen after launch, showing: today's booked/completed/no-show counts, today's income, count of pending (`planned`) treatments awaiting scheduling
- Should load fast — this is the first thing the dentist sees each morning

### 6.6 Settings
- Clinic info form (name, doctor name, phone, address, logo)
- **Daily patient limit**: a simple numeric input, clearly editable at any time, with a short explanatory note that it's advisory only (doesn't block bookings)
- Treatment types management: list with inline edit of name/default price, add/remove entries

---

## 7. Non-Functional / UX Requirements

- The interface must feel **fast and interactive** — this is a stated priority for this project. Favor packages and patterns that support smooth, targeted state updates (GetX's reactive `.obs` variables and `GetBuilder`/`Obx` scoping) over anything that forces full-screen rebuilds on minor changes.
- Consistent, clean desktop-appropriate layout (this is not a mobile app squeezed onto a bigger screen — use the available width sensibly, e.g. side navigation rather than a mobile-style bottom nav).
- Basic loading and error states on every screen that fetches data (spinner while loading, friendly retry option on failure).
- French throughout, including date formatting (via `intl` with a French locale).

---

## 8. Explicitly Out of Scope for This Phase

Do not build any of the following now:
- PDF invoice export (placeholder only, see 6.4)
- Any backend code or modification
- Multi-user login/authentication
- Notifications/reminders
- Inventory management
- Advanced charts/analytics beyond the basic dashboard numbers

---

## 9. Build Phases

Build incrementally, one phase at a time. After each phase, stop and wait for explicit confirmation before starting the next one.

1. **Project Setup** — folder structure (section 3), `dio` client configured against `127.0.0.1:8000`, `go_router` navigation shell with side nav, base French theme
2. **Patients module** — list, search, detail, add/edit screens
3. **Appointments module** — colored week view, booking flow, completed/no-show actions
4. **Treatments module (Odontogram)** — the interactive tooth chart and treatment forms
5. **Invoices & Payments module**
6. **Dashboard & Settings module**
7. **Final review** — consistent loading/error states across all screens, French label pass, README.md for running the frontend

Each phase should build only on what already exists from previous phases.

---

## 10. Deliverable Expectations

- A fully working Flutter Desktop app, runnable via `flutter run -d <platform>`
- Successfully connects to the already-running FastAPI backend at `127.0.0.1:8000`
- Every module from `backend_requirements.md` section 6 has a corresponding, working screen
- A short `README.md` inside `frontend/` explaining how to install dependencies and run the app (including the reminder that the backend must be started first)
