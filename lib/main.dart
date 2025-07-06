import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:ui';
import 'services/order_provider.dart';
import 'services/sales_provider.dart';
import 'theme/touch_theme.dart';

// Import screens
import 'screens/home_screen.dart';

Future<void> main() async {
  // Change main to be async
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env"); // Load the .env file

  // Configure window for touch screen POS
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1920, 1080), // Full HD touch screen
    minimumSize: Size(1024, 768), // Minimum for POS
    center: true,
    backgroundColor: Colors.white,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    windowButtonVisibility: true,
    title: 'Curry King POS - Touch Screen',
    fullScreen: false, // Can be set to true for kiosk mode
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // Configure system UI for touch
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.top], // Keep top bar for window controls
  );

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
  ]);
  
  // Create the SalesProvider instance without initializing it here
  final salesProvider = SalesProvider();

  runApp(MyApp(salesProvider: salesProvider));
}

class MyApp extends StatelessWidget {
  final SalesProvider salesProvider;

  const MyApp({Key? key, required this.salesProvider}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => OrderProvider()),
        // Use the instance of SalesProvider passed from main()
        ChangeNotifierProvider.value(value: salesProvider),
      ],
      child: MaterialApp(
        title: 'Curry King Touch POS',
        theme: TouchPOSTheme.touchOptimizedTheme,
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}