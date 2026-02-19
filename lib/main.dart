import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/main_menu_screen.dart';
import 'screens/splash_screen.dart';
import 'data/game_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await GameStorage.init();
  runApp(const SpaceEscaperApp());
}

class SpaceEscaperApp extends StatelessWidget {
  const SpaceEscaperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Space Escaper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A1929),
        textTheme: GoogleFonts.orbitronTextTheme(
          ThemeData.dark().textTheme,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
