import 'package:flutter/material.dart';
import 'package:paper_scan/screens/subjects_screen.dart'; // Adjust path if needed
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ratusvgsprfnxdlzxgwc.supabase.co',
    anonKey: 'sb_publishable_1dC63KRNv0hregEn_QJb6A_m9BYfNZ0',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.blueAccent,
        colorScheme: const ColorScheme.dark(
          primary: Colors.blueAccent,
          secondary: Colors.blue,
          surface: Colors.black,
        ),
      ),
      home: const SubjectsScreen(),
    );
  }
}
