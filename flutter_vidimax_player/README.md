# Rox Player — Production-Ready Flutter Application

A modern, high-end "All-in-One" offline Android media player built with Flutter (Material 3), featuring custom video gesture controls, a built-in Music Player with queue & favorites, a WhatsApp Status Saver, Video-to-MP3 extraction, and a military-grade encrypted Secret Vault with 4-digit PIN inside Tools.

---

## 📱 Features Included

1. **Splash & Onboarding Carousel**:
   - Custom animated splash screen with neon brand typography.
   - 3-step feature discovery onboarding with skip and smooth dot indicators.
2. **Videos (Tab 1)**:
   - Automated local device video scanning across DCIM, Movies, Downloads, and WhatsApp folders.
   - Folders view and All Videos view with counts, thumbnails, and total sizes.
   - Live search bar and multi-criteria sorting (Date, Name, Size, Duration).
3. **Advanced Offline Video Player**:
   - Original aspect ratio playback with orientation toggle, auto-play next toggle, and 2x long-press speed.
   - Double-tap 10-second forward/backward skip.
   - Left-swipe vertical gesture for Brightness adjustment and Right-swipe for Volume with on-screen HUD.
   - Screen Lock mode and playback speed controls (0.5x – 2.0x).
4. **Music Player (Tab 2)**:
   - Full-featured audio scanner with Tracks, Folders, and Favorites tabs, Mini Player, Now Playing screen, Previous/Next controls, and Queue sheet.
5. **Status Saver (Tab 3)**:
   - Dedicated WhatsApp & WA Business photo/video status saver with 1-tap save to gallery (`/Pictures/RoxPlayer_Status`), HD video playback, and share.
6. **Tools — Video to MP3 & Secret Vault (Tab 4)**:
   - **Video to MP3 Converter**: Extract audio with custom bitrates (128 kbps, 192 kbps, 320 kbps HD) to `/Music/RoxPlayer/`.
   - **Secret Vault**: 4-digit PIN setup with offline Recovery Key protection, AES-256 local encryption for hidden videos & audio tracks, and seamless unhide.
7. **Settings & Maintenance (Tab 5)**:
   - Full Light & Dark theme toggle with high-contrast UI across every screen.
   - Visual storage disk usage bar, 1-click thumbnail cache cleaner, playback preferences, and 100% Offline Privacy Policy guarantee.

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
git commit -m "feat: complete Rox Player Flutter app with Status Saver, Tools, Vault, and Offline Player"
git branch -M main
git remote add origin https://<YOUR_GITHUB_TOKEN>@github.com/<YOUR_USERNAME>/<YOUR_REPO_NAME>.git
git push -u origin main
```
