# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

UpasthitiX is a Flutter-based attendance system that uses Bluetooth Low Energy (BLE) for proximity-based attendance verification. Teachers broadcast session codes via BLE peripherals; students scan for nearby sessions and mark attendance when within range. Backend is Supabase (PostgreSQL + Auth + Realtime).

**Three user roles:** Student, Teacher, Admin

## Commands

```bash
# Install dependencies
flutter pub get

# Run app (debug)
flutter run

# Build for production
flutter build apk --release          # Android
flutter build ios --release           # iOS (requires Mac or Codemagic)

# Analyze code
flutter analyze

# Run tests
flutter test

# Run a single test
flutter test test/path/to_test.dart

# iOS setup (after podfile changes)
cd ios && pod install && cd ..
```

## Architecture

```
lib/
├── core/app_export.dart        # Barrel file - export this in screens instead of individual imports
├── main.dart                   # Entry point - Supabase init, portrait lock, custom error widget
├── models/                     # Data models (User, Session, Attendance, Class, Subject)
├── presentation/               # Feature-based UI screens
│   ├── sign_up_login_screen/  # Login only (admin creates users)
│   ├── student_attendance_screen/  # BLE scan + code entry + history
│   ├── teacher_session_screen/     # Create session, BLE broadcast, view attendance
│   └── admin_dashboard_screen/     # Tab-based: Teachers/Classes/Subjects/Assignments/Enrollment/Reports
├── routes/app_routes.dart      # Static route definitions
├── services/
│   ├── supabase_service.dart   # All Supabase operations (auth, CRUD, realtime)
│   └── ble_service.dart       # BLE advertising (teacher) and scanning (student)
├── theme/app_theme.dart       # Dark theme only, neumorphic/glassmorphism effects
└── widgets/                   # Reusable UI components (glass cards, form fields, etc.)
```

## Critical Rules (DO NOT MODIFY)

**pubspec.yaml:**
- Never remove/modify the `flutter` SDK dependency or `flutter_test` dev dependency
- Never add local fonts - this project uses Google Fonts (`plusJakartaSans`)
- Only use `assets/` and `assets/images/` directories - do not create new asset directories
- Never remove `sizer`, `flutter_svg`, `google_fonts`, `shared_preferences` (core UI)

**main.dart:**
- Never remove the custom `ErrorWidget.builder` (line 20-32) - shows `CustomErrorWidget`
- Never remove `SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])` - app is portrait-only
- Never modify the `MediaQuery` textScaler override in `MaterialApp.builder`

**app_theme.dart:**
- `lightTheme` redirects to `darkTheme` - this app is dark-theme only

## Key Patterns

**Responsive Design:** Uses `sizer` package - dimensions use `.w` (width %), `.h` (height %), `.sp` (font size)

**Imports:** Most files import `core/app_export.dart` which exports Flutter, Sizer, Google Fonts, theme, services, models, and common widgets

**BLE Flow:**
- Teacher creates session → `BleService.startAdvertising(sessionId)` (uses `flutter_ble_peripheral`)
- Student scans → `BleService.scanForSession()` (uses `flutter_blue_plus`)
- Session matching: compares first 8 chars of session ID against BLE manufacturerData/serviceData
- iOS uses serviceData; Android uses manufacturerData (handled in `ble_service.dart`)

**Supabase:**
- URL and anon key are hardcoded in `lib/services/supabase_service.dart` (lines 8-10)
- Realtime subscriptions via `subscribeToSessionAttendance()` for live attendance updates
- RLS policies needed: run `supabase_rls_policies.sql` in Supabase Dashboard

**Admin Creates Users:** Uses `signUp()` not `auth.admin.createUser()` (anon key compatible)

## iOS-Specific Notes

- Podfile platform set to iOS 13.0 (matches Xcode project)
- Info.plist is portrait-only (matches app orientation lock)
- BLE advertising: iOS uses `serviceUuid` + `serviceData`; Android uses `manufacturerId` + `manufacturerData`
- `Permission.bluetoothAdvertise` is skipped on iOS (not supported by permission_handler)
- Build iOS via Codemagic or Mac: `flutter clean && flutter pub get && cd ios && pod install`

## Database Tables

`users` (id, name, email, role, class_id) | `classes` | `subjects` | `teacher_assignments` | `sessions` | `attendance` | `attendance_logs`

Key relationships: teacher_assignments links teachers to class+subject; attendance links student to session
