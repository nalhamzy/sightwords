import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/home/presentation/home_screen.dart';
import 'providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait only — Kids Category UX (SPEC §10 item 8)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Global error handler — writes to local log, no telemetry (SPEC §9)
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };

  runApp(
    const ProviderScope(
      child: SightWordsApp(),
    ),
  );
}

class SightWordsApp extends ConsumerStatefulWidget {
  const SightWordsApp({super.key});

  @override
  ConsumerState<SightWordsApp> createState() => _SightWordsAppState();
}

class _SightWordsAppState extends ConsumerState<SightWordsApp> {
  @override
  void initState() {
    super.initState();
    // Initialize IAP service on launch (silently restores purchases).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(iapServiceProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sight Words Flash Cards',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A90D9),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF9F9F9),
      ),
      home: const HomeScreen(),
    );
  }
}
