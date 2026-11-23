import 'package:flutter/material.dart';
import 'package:flutter_food_tracker_app/views/splash_screen_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

//--------------------------------------------------------------------
void main() async {
  //----- โค้ดติดต่อกับ Supabase โปรเจ็กต์ที่เราจะทำงานด้วย -----
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://rizdsvytwpxkpddezoqx.supabase.co',
    publishableKey: 'sb_publishable_FxLoTA_AifoWudj6C9krzw__SsfRbNW',
  );
  //----------------------------------------------------

  runApp(FlutterFoodTrackerApp());
}

//--------------------------------------------------------------------
class FlutterFoodTrackerApp extends StatefulWidget {
  const FlutterFoodTrackerApp({super.key});

  @override
  State<FlutterFoodTrackerApp> createState() => _FlutterFoodTrackerAppState();
}

class _FlutterFoodTrackerAppState extends State<FlutterFoodTrackerApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreenUI(),
      theme: ThemeData(
        textTheme: TextTheme.of(context).apply(
          fontFamily: GoogleFonts.kanit().fontFamily,
          fontFamilyFallback: GoogleFonts.kanit().fontFamilyFallback,
        ),
      ),
    );
  }
}
