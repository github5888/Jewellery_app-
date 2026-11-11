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

*(If your local Flutter SDK uses a different native wrapper version, you can run `flutter create . --project-name smart_hospital_nurse` once before `flutter run` — it preserves `lib/` and `pubspec.yaml`.)*

### Build Release APK

```bash
flutter build apk --release
```

### Server Endpoint Configuration
- **Default Server**: `https://hospital.hrpocket.in`
- Tap the **Server Endpoint** icon at the top-right of the **Login** or **Profile** screen to switch between:
  - Production: `https://hospital.hrpocket.in`
  - Android Emulator local backend: `http://10.0.2.2:5000`
  - Custom LAN / Staging server URL
- Note for **Flutter Web** (`flutter run -d chrome`): Backend `server.ts` enforces CORS via `CORS_ORIGINS` (`http://localhost:5173` by default). Native Android/iOS builds send no browser `Origin` header and connect directly to `https://hospital.hrpocket.in` out of the box; if running in Chrome against a remote server, include your Chrome dev port in backend `CORS_ORIGINS`.
