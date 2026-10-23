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
  SystemChrome.setSystemUIOverlayStyle(kSystemUiStyle);
  runApp(IscannaApp(controller: AppController(MlKitOcrService())));
}

class IscannaApp extends StatefulWidget {
  const IscannaApp({super.key, required this.controller});

  final AppController controller;

  @override
  State<IscannaApp> createState() => _IscannaAppState();
}

class _IscannaAppState extends State<IscannaApp> {
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iscanna1.0',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      // Large-title nav bars, action sheets and alerts pick up the app's colours and fonts.
      builder: (context, child) => CupertinoTheme(data: kCupertinoTheme, child: child!),
      home: HomeScreen(controller: widget.controller),
    );
  }
}
