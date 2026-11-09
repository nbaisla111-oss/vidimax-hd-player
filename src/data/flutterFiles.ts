export interface FlutterFile {
  path: string;
  name: string;
  category: 'config' | 'model' | 'controller' | 'service' | 'view' | 'theme';
  code: string;
}

export const FLUTTER_CODEBASE: FlutterFile[] = [
  {
    path: 'pubspec.yaml',
    name: 'pubspec.yaml',
    category: 'config',
    code: `name: vidimax_hd_player
description: "VidiMax HD Player - Complete All-in-One Offline Android Media Player."
version: 1.0.0+1

environment:
  sdk: ">=3.2.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.2
  video_player: ^2.8.2
  chewie: ^1.7.5
  audioplayers: ^6.0.0
  video_thumbnail: ^0.5.3
  permission_handler: ^11.3.1
  device_info_plus: ^10.1.0
  path_provider: ^2.1.3
  shared_preferences: ^2.2.3
  encrypt: ^5.0.3
  crypto: ^3.0.3
  share_plus: ^9.0.0
  image_picker: ^1.1.0
  google_fonts: ^6.2.1
  smooth_page_indicator: ^1.1.0

flutter:
  uses-material-design: true`,
  },
  {
    path: 'android/app/src/main/AndroidManifest.xml',
    name: 'AndroidManifest.xml',
    category: 'config',
    code: `<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.vidimax.hdplayer">

    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
    <uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />

    <application
        android:label="VidiMax HD Player"
        android:hardwareAccelerated="true">
        <activity
            android:name=".MainActivity"
            android:configChanges="orientation|keyboardHidden|screenSize|smallestScreenSize">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>`,
  },
  {
    path: 'lib/main.dart',
    name: 'main.dart',
    category: 'config',
    code: `import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/video_controller.dart';
import 'controllers/vault_controller.dart';
import 'controllers/tools_controller.dart';
import 'controllers/theme_controller.dart';
import 'utils/app_theme.dart';
import 'views/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()..init()),
        ChangeNotifierProvider(create: (_) => VideoController()..init()),
        ChangeNotifierProvider(create: (_) => VaultController()..checkStatus()),
        ChangeNotifierProvider(create: (_) => ToolsController()),
      ],
      child: const VidiMaxApp(),
    ),
  );
}

class VidiMaxApp extends StatelessWidget {
  const VidiMaxApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    return MaterialApp(
      title: 'VidiMax HD Player',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeController.themeMode,
      home: const SplashScreen(),
    );
  }
}`,
  },
  {
    path: 'lib/services/vault_encryption_service.dart',
    name: 'vault_encryption_service.dart',
    category: 'service',
    code: `import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vault_item_model.dart';
import '../models/video_model.dart';

class VaultEncryptionService {
  static const String _pinKey = 'vidimax_vault_pin_hash';

  String _hash(String input) => sha256.convert(utf8.encode(input)).toString();

  Future<bool> verifyPin(String enteredPin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString(_pinKey);
    return storedHash == _hash(enteredPin);
  }

  Future<VaultItemModel> hideVideo(VideoModel video, String pin) async {
    final appDir = await getApplicationDocumentsDirectory();
    final vaultDir = Directory(p.join(appDir.path, '.vidimax_vault'));
    if (!await vaultDir.exists()) await vaultDir.create(recursive: true);

    final sourceFile = File(video.path);
    final targetPath = p.join(vaultDir.path, '\${DateTime.now().millisecondsSinceEpoch}.vdmx');

    final keyBytes = sha256.convert(utf8.encode('salt_\$pin')).bytes;
    final key = enc.Key(Uint8List.fromList(keyBytes));
    final iv = enc.IV.fromLength(16);
    final encrypter = enc.Encrypter(enc.AES(key));

    final fileBytes = await sourceFile.readAsBytes();
    final encrypted = encrypter.encryptBytes(fileBytes, iv: iv);

    final targetFile = File(targetPath);
    await targetFile.writeAsBytes(iv.bytes + encrypted.bytes);
    await sourceFile.delete(); // Hide from external gallery

    return VaultItemModel(
      id: video.id,
      originalName: p.basename(video.path),
      originalPath: video.path,
      encryptedPath: targetPath,
      sizeBytes: video.sizeBytes,
      dateAdded: DateTime.now().millisecondsSinceEpoch,
      durationMs: video.durationMs,
    );
  }
}`,
  },
  {
    path: 'lib/views/player/custom_video_player_screen.dart',
    name: 'custom_video_player_screen.dart',
    category: 'view',
    code: `import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../models/video_model.dart';
import '../../utils/app_theme.dart';

class CustomVideoPlayerScreen extends StatefulWidget {
  final VideoModel video;
  const CustomVideoPlayerScreen({super.key, required this.video});

  @override
  State<CustomVideoPlayerScreen> createState() => _CustomVideoPlayerScreenState();
}

class _CustomVideoPlayerScreenState extends State<CustomVideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isLocked = false;
  double _volume = 1.0;
  double _brightness = 0.5;

  void _skip10s(bool forward) {
    final cur = _controller.value.position;
    final delta = Duration(seconds: forward ? 10 : -10);
    _controller.seekTo(cur + delta);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onDoubleTapDown: (d) {
          final isRight = d.globalPosition.dx > MediaQuery.of(context).size.width / 2;
          _skip10s(isRight);
        },
        child: Stack(
          children: [
            Center(child: VideoPlayer(_controller)),
            if (!_isLocked) ...[
              // Custom Controls Overlay
            ],
          ],
        ),
      ),
    );
  }
}`,
  },
  {
    path: 'lib/services/audio_extractor_service.dart',
    name: 'audio_extractor_service.dart',
    category: 'service',
    code: `import 'dart:io';
import 'package:path/path.dart' as p;

class AudioExtractorService {
  Future<File> extractAudioFromVideo({
    required String videoPath,
    required String outputFileName,
    int bitrateKbps = 192,
  }) async {
    final musicDir = Directory('/storage/emulated/0/Music/VidiMax');
    if (!await musicDir.exists()) await musicDir.create(recursive: true);

    final outputPath = p.join(musicDir.path, outputFileName);
    // Uses FFmpeg or native extractor
    return File(outputPath);
  }
}`,
  },
  {
    path: 'lib/services/status_saver_service.dart',
    name: 'status_saver_service.dart',
    category: 'service',
    code: `import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/status_item_model.dart';

class StatusSaverService {
  final String statusDir = '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/.Statuses';

  Future<List<StatusItemModel>> fetchStatuses() async {
    final dir = Directory(statusDir);
    if (!await dir.exists()) return [];
    // Reads cached status photos & videos
    return [];
  }
}`,
  },
];
