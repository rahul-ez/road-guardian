import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/detection_service.dart';
import 'services/permission_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform
  // );

  await Supabase.initialize(
    url: 'https://hzyjidjxuvqwxnqaopqi.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh6eWppZGp4dXZxd3hucWFvcHFpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU2MTQ2OTksImV4cCI6MjA2MTE5MDY5OX0.IVuXa7vpRwTtK5nlSRGpJlCPtOXNuj4ynkMU7NH0AJo',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DetectionService()),
        Provider(create: (_) => PermissionService()),
      ],
      child: const PotholeDetectorApp(),
    ),
  );
}

class PotholeDetectorApp extends StatefulWidget {
  const PotholeDetectorApp({super.key});

  @override
  State<PotholeDetectorApp> createState() => _PotholeDetectorAppState();
}

class _PotholeDetectorAppState extends State<PotholeDetectorApp> {
  @override
  void initState() {
    super.initState();
    // Initialize the detection service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DetectionService>(context, listen: false).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Road Guardian',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(elevation: 0, centerTitle: true),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(elevation: 0, centerTitle: true),
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
