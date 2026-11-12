# Smart Super Speciality Hospital — Nurse Portal (Flutter App)

Production-ready **Flutter Nurse Care System & Bedside Clinical Ward Portal** integrated **100% live** with the Smart Hospital TypeScript MERN Backend (`https://hospital.hrpocket.in`) and Real-Time Socket.IO server — **zero dummy, mock, or hardcoded patient data**.

---

## Key Highlights

- **100% Live API & Real-Time Socket.IO Integration** — Every count, patient card, bedside chart, vital sign trend graph, prescription (MAR), nursing note, bed occupancy ring, OPD triage queue, duty shift, lab/radiology report, blood bank stock, and holiday calendar record comes directly from the live backend.
- **Exact Nurse Portal UI Design** — Built to match the 9-screen Nurse Portal mobile design system:
  1. **Splash Screen** (`Nurse Care System` + live `/api/health` & session bootstrap)
  2. **Nurse Portal Login** (`POST /api/auth/login` + `GET /api/auth/me` + configurable Server Endpoint)
  3. **Nurse Home Dashboard** (`GET /api/dashboard` — My Patients, Vitals Due, Medications KPI cards, 6 Quick Actions, animated Ward Bed Occupancy circular gauge, Today's Schedule, Currently Admitted Ward Census, Recent Clinical Activity stream)
  4. **My Patients** (`All`, `In Ward`, `Consultation`, `Discharged` + live search & Allergy badges)
  5. **Bedside Patient Digital Chart** (`GET /api/ipd/:id` — Overview, Medical History / Doctor Rounds / Shift Notes, Prescriptions, Vitals Trend Graph)
  6. **Record Vitals** (`POST /api/ipd/:id/vitals` & `POST /api/opd/:id/vitals` — Heart Rate, Temperature, Blood Pressure, SpO2, Respiratory Rate, Weight, Height, Clinical Remarks)
  7. **Medications (MAR)** (`POST /api/ipd/:id/prescriptions/:prescriptionId/administer` — `Active` / `Given` / `Pending` filters, `Given` / `Held` / `Refused` / `Missed` logging)
  8. **Nursing Tasks** (Live clinical tasks synthesized from pending ward vitals, MAR doses, OPD triage queue, and doctor round instructions)
  9. **Clinical Reports & Authenticated Viewer** (`GET /api/pathology`, `GET /api/radiology`, IPD investigations, and authenticated `/api/files/pathology_report/*` & `/api/files/radiology_report/*` bearer-token download matching `server.ts`)
- **Complete Hospital Nurse Modules**:
  - **Shift Nursing Care Notes** (`POST /api/ipd/:id/nurse-notes`)
  - **Bed Transfer / Ward Shifting** (`GET /api/beds?is_occupied=false` + `POST /api/ipd/:id/transfer-bed`)
  - **Pre-Discharge Nursing Checklist** (`PUT /api/ipd/:id/discharge-checklist` — all 9 clinical verification switches + remarks)
  - **Nursing Procedures / Charge Log** (`GET /api/charges` + `POST /api/ipd/:id/charges`)
  - **Bed Status & Ward Occupancy** (`GET /api/beds`, `GET /api/beds/groups`)
  - **OPD Triage Queue** (`GET /api/opd`, `POST /api/opd/:id/vitals`)
  - **Staff Duty Roster & My Shifts** (`GET /api/dutyroster` / `/api/duty-rosters/assignments`)
  - **Patient Directory** (`GET /api/patients` with Gender, Blood Group & ABHA search)
  - **Blood Bank Stock** (`GET /api/blood-bank`) & **Annual Holiday Calendar** (`GET /api/holidays`)
  - **Live Socket.IO Alerts** (`ipd:new_admission`, `ipd:vitals_recorded`, `ipd:medication_administered`)

---

## Getting Started

### Prerequisites
- Flutter SDK `>= 3.19.0` (Dart `>= 3.2.0`)
- Android Studio / VS Code with Flutter extension

### Run on Android / iOS Device or Emulator

```bash
flutter pub get
flutter run
```

### Run in Chrome on Windows / Desktop (with Automatic Live CORS Bridge)

Production `server.ts` on `https://hospital.hrpocket.in` blocks cross-origin browser `Origin: http://localhost:*` requests via CORS. Use the included single-command launcher (which starts a local Dart CORS bridge on `127.0.0.1:8787` and opens Chrome in a crisp mobile viewport):

```bash
dart run tool/run_web.dart
```

*(On Windows, you can also double-click `run_chrome.bat`.)*

### Build Release APK

```bash
flutter build apk --release
```

### Server Endpoint Configuration
- **Default Server**: `https://hospital.hrpocket.in`
- Centralized full-URL registry: [`lib/core/config/api_endpoints.dart`](lib/core/config/api_endpoints.dart) + live in-app endpoint verifier screen (**Profile → Full Live API Links & Status**).

---

## Complete Linked Full API Endpoints (`https://hospital.hrpocket.in`)

| Module | Method | Full Live API URL |
|---|---|---|
| Server Health | `GET` | `https://hospital.hrpocket.in/api/health` |
| Hospital Branding | `GET` | `https://hospital.hrpocket.in/api/settings/public` |
| Nurse Login | `POST` | `https://hospital.hrpocket.in/api/auth/login` |
| Nurse Profile & Role | `GET` | `https://hospital.hrpocket.in/api/auth/me` |
| Change Password | `PUT` | `https://hospital.hrpocket.in/api/auth/change-password` |
| Nurse Logout | `POST` | `https://hospital.hrpocket.in/api/auth/logout` |
| Nurse Home Census Dashboard | `GET` | `https://hospital.hrpocket.in/api/dashboard` |
| Admitted IPD Ward Patients | `GET` | `https://hospital.hrpocket.in/api/ipd?discharge_status=admitted` |
| Bedside Digital Patient Chart | `GET` | `https://hospital.hrpocket.in/api/ipd/:id` |
| Record IPD Bedside Vitals | `POST` | `https://hospital.hrpocket.in/api/ipd/:id/vitals` |
| Daily Shift Nurse Progress Note | `POST` | `https://hospital.hrpocket.in/api/ipd/:id/nurse-notes` |
| Medication Administration (MAR) | `POST` | `https://hospital.hrpocket.in/api/ipd/:id/prescriptions/:prescriptionId/administer` |
| Patient Bed Transfer / Shift | `POST` | `https://hospital.hrpocket.in/api/ipd/:id/transfer-bed` |
| Pre-Discharge Nursing Checklist | `PUT` | `https://hospital.hrpocket.in/api/ipd/:id/discharge-checklist` |
| Nursing Procedures / Charge Log | `POST` | `https://hospital.hrpocket.in/api/ipd/:id/charges` |
| All Hospital Beds | `GET` | `https://hospital.hrpocket.in/api/beds` |
| Vacant Beds Filter | `GET` | `https://hospital.hrpocket.in/api/beds?is_occupied=false` |
| Wards / Bed Groups | `GET` | `https://hospital.hrpocket.in/api/beds/groups` |
| OPD Waiting Triage Queue | `GET` | `https://hospital.hrpocket.in/api/opd` |
| OPD Consultation Detail | `GET` | `https://hospital.hrpocket.in/api/opd/:id` |
| Record OPD Triage Vitals | `POST` | `https://hospital.hrpocket.in/api/opd/:id/vitals` |
| Nurse Duty Roster & Shifts | `GET` | `https://hospital.hrpocket.in/api/dutyroster` (`/assignments`) |
| Patient Master Directory | `GET` | `https://hospital.hrpocket.in/api/patients` |
| Pathology Lab Reports | `GET` | `https://hospital.hrpocket.in/api/pathology` |
| Radiology Scan Reports | `GET` | `https://hospital.hrpocket.in/api/radiology` |
| Protected Lab/Radiology Files | `GET` | `https://hospital.hrpocket.in/api/files/pathology_report/:file` & `/api/files/radiology_report/:file` |
| Appointments Schedule | `GET` | `https://hospital.hrpocket.in/api/appointments` |
| Doctors & Staff Directory | `GET` | `https://hospital.hrpocket.in/api/staff` |
| Pharmacy Medicines Stock | `GET` | `https://hospital.hrpocket.in/api/pharmacy/medicines` (`/api/pharmacy`) |
| Ward Consumables Inventory | `GET` | `https://hospital.hrpocket.in/api/inventory` (`/api/itemstock`) |
| Blood Bank Status | `GET` | `https://hospital.hrpocket.in/api/blood-bank` |
| Annual Holiday Calendar | `GET` | `https://hospital.hrpocket.in/api/holidays` |
| Hospital Charge Master | `GET` | `https://hospital.hrpocket.in/api/charges` |
| Notifications & Ward Alerts | `GET` / `PUT` | `https://hospital.hrpocket.in/api/notifications` (`/:id/read`) |
| Clinical Attachment Upload | `POST` | `https://hospital.hrpocket.in/api/uploads` |
| Real-Time Ward Socket.IO | `WS` | `wss://hospital.hrpocket.in/socket.io/` (`join_hospital`, `ipd:new_admission`, `ipd:vitals_recorded`, `ipd:medication_administered`) |

