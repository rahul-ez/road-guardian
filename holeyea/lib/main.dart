import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:holeyea/router.dart';
import 'package:provider/provider.dart';
Future<void> main() async {
  List<CameraDescription> cameras = <CameraDescription>[];
  try {
    WidgetsFlutterBinding.ensureInitialized();
    cameras = await availableCameras();
  } on CameraException {}

  runApp(
    MultiProvider(
      providers: [
        Provider(create: (context) => cameras),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: Colors.deepOrangeAccent,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepOrange,
            brightness: Brightness.dark,
            primary: Colors.deepOrangeAccent,
            secondary: Colors.orange,
          ),
          scaffoldBackgroundColor: const Color(0xFF121212),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrangeAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            color: const Color(0xFF1E1E1E),
          ),
        ),
        routerConfig: router
      ),
    ),
  );
} 

