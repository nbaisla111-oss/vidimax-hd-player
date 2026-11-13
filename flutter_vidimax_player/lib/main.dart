import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'controllers/video_controller.dart';
import 'controllers/vault_controller.dart';
import 'controllers/tools_controller.dart';
import 'controllers/theme_controller.dart';
import 'controllers/music_controller.dart';
import 'utils/app_theme.dart';
import 'views/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()..init()),
        ChangeNotifierProvider(create: (_) => VideoController()..init()),
        ChangeNotifierProvider(create: (_) => MusicController()..init()),
        ChangeNotifierProvider(create: (_) => VaultController()..checkStatus()),
        ChangeNotifierProvider(create: (_) => ToolsController()),
      ],
      child: const RoxPlayerApp(),
    ),
  );
}

class RoxPlayerApp extends StatelessWidget {
  const RoxPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final isDark = themeController.isDarkMode;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: MaterialApp(
        title: 'Rox Player',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeController.themeMode,
        home: const SplashScreen(),
      ),
    );
  }
}
