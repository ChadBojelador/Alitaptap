# Android Build & Firebase Bypasses

This document tracks all intentional bypasses, removed code, and workarounds
made during development. Each entry explains **what** was changed, **why**,
and **how to restore** it when the underlying issue is fixed.

---

## 1. `cloud_firestore` Removed from Android Build

**File:** `apps/mobile_flutter/pubspec.yaml`

**What was done:**
`cloud_firestore: ^5.6.12` was commented out from the dependencies.

**Why:**
The Android Gradle build consistently failed with:
```
Could not determine the dependencies of task ':cloud_firestore:compileDebugJavaWithJavac'.
> Cannot query the value of this provider because it has no value available.
```
This is a known incompatibility between `cloud_firestore 5.x` Android plugin
and the Java 21 + AGP 8.x toolchain on this machine. Multiple Gradle/AGP/Kotlin
version combinations were attempted without success.

**Impact:**
- Firestore reads/writes are disabled on Android.
- Role persistence is bypassed (see item 2 below).
- Web (Chrome) build is unaffected.

**How to restore:**
1. Upgrade to `cloud_firestore: ^6.x` in `pubspec.yaml` — the 6.x series
   rewrites the Android plugin and fixes the Java 21 compatibility issue.
2. Run `flutter pub get`.
3. Re-enable the Firestore calls in `auth_service.dart` (see item 3).

---

## 2. Role Persistence Bypassed

**Files:**
- `apps/mobile_flutter/lib/features/auth/presentation/sign_in_page.dart`
- `apps/mobile_flutter/lib/app/app.dart`

**What was done:**
- `AuthService.setRole()` call commented out in `SignInPage._proceed()`.
- `AlitaptapApp._bootstrapRole()` deleted from `app.dart`.
- Role is now passed in-memory from `SignInPage` directly to the app router.

**Why:**
1. `cloud_firestore` removed from `pubspec.yaml` (see item 1).
2. Firestore security rules were not configured, causing `permission-denied`
   on every `users/{uid}` write.

**Impact:**
- Sign-in screen shows on every launch — role is not remembered.
- No Firestore reads or writes for role management.

**How to restore:**
1. Configure Firestore rules in Firebase Console:
   ```
   match /users/{userId} {
     allow read, write: if request.auth != null
                        && request.auth.uid == userId;
   }
   ```
   See `docs/00-governance/firebase-setup.md` for the full ruleset.
2. Restore `cloud_firestore` in `pubspec.yaml` (see item 1).
3. In `sign_in_page.dart` uncomment:
   ```dart
   await _authService.setRole(_selectedRole!);
   ```
4. Re-add `_bootstrapRole()` in `app.dart` to read role on launch.

---

## 3. `AuthService` Firestore Methods Stubbed

**File:** `apps/mobile_flutter/lib/services/auth_service.dart`

**What was done:**
- `cloud_firestore` import commented out.
- `FirebaseFirestore` constructor param and field removed.
- `setRole()` body commented out — method exists but does nothing.
- `getCurrentUserRole()` always returns `AppRole.student`.

**Why:**
`cloud_firestore` removed from `pubspec.yaml` so all Firestore API calls
would cause compile errors.

**How to restore:**
1. Restore `cloud_firestore` in `pubspec.yaml`.
2. Uncomment: `import 'package:cloud_firestore/cloud_firestore.dart';`
3. Restore constructor: `AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})`
4. Uncomment method bodies in `setRole()` and `getCurrentUserRole()`.

---

## 4. Android Gradle Configuration

**Files:**
- `android/gradle/wrapper/gradle-wrapper.properties`
- `android/settings.gradle.kts`
- `android/app/build.gradle.kts`
- `android/gradle.properties`

**Current versions:**
| Tool | Version |
|---|---|
| Gradle | 8.10.2 |
| AGP | 8.7.3 |
| Kotlin | 2.1.0 |
| compileSdk | 36 |
| Java (system) | 21 |

**Why these versions:**
AGP 8.7.3 requires Gradle 8.10.2 minimum. Kotlin 2.1.0 is the lowest Flutter
accepts that is stable with Java 21. compileSdk 36 matches the installed SDK.

---

## Summary

| # | What | File | Status | Restore When |
|---|---|---|---|---|
| 1 | `cloud_firestore` commented out | `pubspec.yaml` | ⚠️ Bypassed | Upgrade to `^6.x` |
| 2 | Role persistence removed | `sign_in_page.dart`, `app.dart` | ⚠️ Bypassed | Item 1 + Firestore rules |
| 3 | AuthService Firestore stubbed | `auth_service.dart` | ⚠️ Bypassed | Item 1 restored |
| 4 | Gradle/AGP/Kotlin pinned | Android config files | ✅ Active | N/A |
