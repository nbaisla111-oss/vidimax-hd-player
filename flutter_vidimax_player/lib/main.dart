import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'controllers/video_controller.dart';
import 'controllers/vault_controller.dart';
import 'controllers/tools_controller.dart';
import 'controllers/theme_controller.dart';
import 'utils/app_theme.dart';
import 'views/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style for seamless edge-to-edge dark immersive experience
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.backgroundDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

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
}
