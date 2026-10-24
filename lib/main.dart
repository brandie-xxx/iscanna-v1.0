import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';
import 'services/ocr_service.dart';
import 'state/app_controller.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(IscannaApp(controller: AppController(MlKitOcrService())));
}

class IscannaApp extends StatefulWidget {
  const IscannaApp({super.key, required this.controller});

  final AppController controller;

  @override
  State<IscannaApp> createState() => _IscannaAppState();
}

class _IscannaAppState extends State<IscannaApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _applyBrightness();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.dispose();
    super.dispose();
  }

  /// Follows the phone's light/dark setting.
  @override
  void didChangePlatformBrightness() {
    _applyBrightness();
    setState(() {});
    // Colours are read during build, so rebuild every widget (state such as scroll position is kept).
    void rebuild(Element element) {
      element.markNeedsBuild();
      element.visitChildren(rebuild);
    }

    (context as Element).visitChildren(rebuild);
  }

  void _applyBrightness() {
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    AppColors.palette = brightness == Brightness.light ? AppPalette.light : AppPalette.dark;
    SystemChrome.setSystemUIOverlayStyle(systemUiStyle());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iscanna1.0',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      // Action sheets and alerts pick up the app's colours and fonts.
      builder: (context, child) => CupertinoTheme(data: buildCupertinoTheme(), child: child!),
      home: HomeScreen(controller: widget.controller),
    );
  }
}
