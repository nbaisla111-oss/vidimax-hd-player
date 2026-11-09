# VidiMax HD Player — Production-Ready Flutter Application

A modern, high-end "All-in-One" offline Android media player built with Flutter (Material 3), featuring custom video gesture controls, a military-grade encrypted Private Vault with 4-digit PIN, Video-to-MP3 extraction, and WhatsApp Status Saver.

---

## 📱 Features Included

1. **Splash & Onboarding Carousel**:
   - Custom animated splash screen with neon brand typography.
   - 3-step feature discovery onboarding with skip and smooth dot indicators.
2. **Home / Video List (Tab 1)**:
   - Automated local device video scanning across DCIM, Movies, Downloads, and WhatsApp folders.
   - Folders view and All Videos view with counts and total sizes.
   - Live search bar and multi-criteria sorting (Date, Name, Size, Duration).
3. **Advanced Offline Video Player**:
   - Double-tap 10-second forward/backward skip.
   - Left-swipe vertical gesture for Brightness adjustment with on-screen HUD.
   - Right-swipe vertical gesture for Volume adjustment with on-screen HUD.
   - Aspect ratio switcher (Fit, Fill, Stretch, 16:9).
   - Screen Lock mode to avoid accidental touches during video watching.
   - Playback speed toggling (0.5x, 0.75x, 1.0x, 1.25x, 1.5x, 2.0x).
4. **Encrypted Private Vault (Tab 2)**:
   - 4-digit PIN setup with confirmation and security question recovery.
   - AES-256 local file encryption. Videos are moved into internal storage and hidden from Android gallery.
   - Seamless unhide/decrypt back to gallery.
5. **Media Utilities & Tools (Tab 3)**:
   - **Video to MP3 Converter**: Extract audio with custom bitrates (128 kbps, 192 kbps, 320 kbps HD).
   - **WhatsApp Status Saver**: Browse cached photos and videos from WhatsApp and WhatsApp Business, 1-tap save to gallery, and share.
6. **Settings & Maintenance (Tab 4)**:
   - AMOLED Dark / Light theme toggle.
   - Visual storage disk usage bar.
   - 1-click thumbnail cache cleaner.
   - Playback preferences (Hardware acceleration, background playback, resume playback).
   - 100% Offline Privacy Policy guarantee.

---

## 🛠️ Project Structure (Clean Architecture)

```
flutter_vidimax_player/
├── pubspec.yaml
├── android/
│   └── app/src/main/AndroidManifest.xml
├── lib/
│   ├── main.dart
│   ├── models/
│   │   ├── video_model.dart
│   │   ├── folder_model.dart
│   │   ├── vault_item_model.dart
│   │   └── status_item_model.dart
│   ├── controllers/
│   │   ├── video_controller.dart
│   │   ├── vault_controller.dart
│   │   ├── tools_controller.dart
│   │   └── theme_controller.dart
│   ├── services/
│   │   ├── video_scanner_service.dart
│   │   ├── vault_encryption_service.dart
│   │   ├── audio_extractor_service.dart
│   │   ├── status_saver_service.dart
│   │   └── permission_service.dart
│   ├── utils/
│   │   └── app_theme.dart
│   └── views/
│       ├── splash/splash_screen.dart
│       ├── onboarding/onboarding_screen.dart
│       ├── navigation/main_nav_screen.dart
│       ├── home/home_screen.dart
│       ├── player/custom_video_player_screen.dart
│       ├── vault/vault_screen.dart
│       ├── tools/tools_screen.dart
│       └── settings/settings_screen.dart
└── README.md
```

---

## 🚀 How to Run the Flutter Project

1. Ensure Flutter 3.2.0+ is installed:
   ```bash
   flutter doctor
   ```
2. Navigate to the project directory and fetch dependencies:
   ```bash
   cd flutter_vidimax_player
   flutter pub get
   ```
3. Run on connected Android device or emulator:
   ```bash
   flutter run
   ```

---

## 📦 How to Push Code to GitHub Using Personal Access Token

When you provide your GitHub credentials and token, here are the exact git commands to push:

```bash
git init
git add .
git commit -m "feat: complete VidiMax HD Player Flutter app with Vault, Tools, and Offline Player"
git branch -M main
git remote add origin https://<YOUR_GITHUB_TOKEN>@github.com/<YOUR_USERNAME>/<YOUR_REPO_NAME>.git
git push -u origin main
```
