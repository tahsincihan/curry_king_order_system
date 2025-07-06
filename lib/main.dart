import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:ui';
import 'services/order_provider.dart';
import 'services/sales_provider.dart';
import 'theme/touch_theme.dart';

// Conditional imports for platform-specific code
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;

// Import window_manager types for type checking and code completion
import 'package:window_manager/window_manager.dart' show WindowOptions, TitleBarStyle;

// Import screens
import 'screens/home_screen.dart';

// Platform-specific imports with conditional loading
dynamic windowManager;
bool get isDesktop => !kIsWeb && _isDesktopPlatform();

bool _isDesktopPlatform() {
  try {
    // Only import dart:io if not on web
    if (kIsWeb) return false;
    
    // Use a safer method to detect platform
    return defaultTargetPlatform == TargetPlatform.windows ||
           defaultTargetPlatform == TargetPlatform.macOS ||
           defaultTargetPlatform == TargetPlatform.linux;
  } catch (e) {
    print('Platform detection failed: $e');
    return false;
  }
}

Future<void> _initializeWindowManager() async {
  if (!isDesktop) return;
  
  try {
    // Dynamically import window_manager only for desktop
    final windowManagerModule = await import('package:window_manager/window_manager.dart');
    windowManager = windowManagerModule.windowManager;
    final windowOptions = WindowOptions(
      size: const Size(1200, 800),
      minimumSize: const Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      windowButtonVisibility: true,
      title: 'Curry King POS - Touch Screen',
      fullScreen: false,
    );

    await windowManager?.waitUntilReadyToShow(windowOptions, () async {
      await windowManager?.show();
      await windowManager?.focus();
    });
    
    print('✓ Window manager setup successfully');
  } catch (e) {
    print('⚠ Warning: Window manager setup failed: $e');
    // Continue without window manager
  }
}

Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize with comprehensive error handling
  try {
    print('Starting Curry King POS initialization...');
    print('Platform: ${kIsWeb ? 'Web' : 'Native'}');
    print('Desktop platform: $isDesktop');

    // Load environment file (optional)
    try {
      await dotenv.load(fileName: ".env");
      print('✓ Environment file loaded successfully');
    } catch (e) {
      print('⚠ Warning: Could not load .env file: $e');
      // Continue without .env file - create empty dotenv
      dotenv.testLoad(fileInput: '');
    }

    // Initialize sales provider with error handling
    print('Initializing sales provider...');
    final salesProvider = SalesProvider();
    try {
      await salesProvider.initialize();
      print('✓ Sales provider initialized successfully');
    } catch (e) {
      print('⚠ Warning: Sales provider initialization failed: $e');
      // Continue with uninitialized provider
    }

    // Setup window manager only on desktop platforms
    if (isDesktop) {
      print('Setting up window manager for desktop...');
      await _initializeWindowManager();
    } else {
      print('Running on ${kIsWeb ? 'web' : 'mobile'} platform - skipping window manager');
    }

    // Configure system UI with error handling (only for mobile/desktop)
    if (!kIsWeb) {
      try {
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: [SystemUiOverlay.top],
        );

        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
          DeviceOrientation.portraitUp,
        ]);
        print('✓ System UI configured successfully');
      } catch (e) {
        print('⚠ Warning: Could not configure system UI: $e');
      }
    }

    print('✓ Initialization complete - Starting app...');
    runApp(MyApp(salesProvider: salesProvider));
    
  } catch (e, stackTrace) {
    print('❌ Critical error during app initialization: $e');
    print('Stack trace: $stackTrace');
    
    // Run a minimal error app
    runApp(ErrorApp(error: e.toString()));
  }
}

class MyApp extends StatelessWidget {
  final SalesProvider salesProvider;

  const MyApp({Key? key, required this.salesProvider}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => OrderProvider()),
        ChangeNotifierProvider.value(value: salesProvider),
      ],
      child: MaterialApp(
        title: 'Curry King Touch POS',
        theme: TouchPOSTheme.touchOptimizedTheme.copyWith(
          materialTapTargetSize: MaterialTapTargetSize.padded,
          splashColor: TouchPOSTheme.touchSplash,
          highlightColor: TouchPOSTheme.touchHighlight,
          platform: TargetPlatform.android, // Safe default for all platforms
        ),
        scrollBehavior: const TouchScrollBehavior(),
        home: const SafeHomeScreen(),
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          return TouchScreenWrapper(child: child!);
        },
      ),
    );
  }
}

// Safe wrapper for HomeScreen
class SafeHomeScreen extends StatefulWidget {
  const SafeHomeScreen({Key? key}) : super(key: key);

  @override
  _SafeHomeScreenState createState() => _SafeHomeScreenState();
}

class _SafeHomeScreenState extends State<SafeHomeScreen> {
  bool hasError = false;
  String errorMessage = '';

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Curry King POS - Error'),
          backgroundColor: Colors.red[600],
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Home Screen Error',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      hasError = false;
                      errorMessage = '';
                    });
                  },
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    try {
      return const HomeScreen();
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            hasError = true;
            errorMessage = 'Error loading home screen: $e';
          });
        }
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
  }
}

// Error app to show when initialization fails
class ErrorApp extends StatelessWidget {
  final String error;
  
  const ErrorApp({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Curry King POS - Error',
      home: Scaffold(
        backgroundColor: Colors.red[50],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Curry King POS',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Failed to Initialize',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: SelectableText(
                    'Error: $error',
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Please check the console for more details and try restarting the application.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Try to restart
                    if (kIsWeb) {
                      // On web, we can't close the window
                      // Instead, reload the page
                      print('Please refresh the page to restart');
                    } else {
                      SystemNavigator.pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: Text(
                    kIsWeb ? 'Refresh Page' : 'Close Application',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom scroll behavior for touch screens
class TouchScrollBehavior extends MaterialScrollBehavior {
  const TouchScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}

// Wrapper to handle touch screen specific behaviors
class TouchScreenWrapper extends StatefulWidget {
  final Widget child;

  const TouchScreenWrapper({Key? key, required this.child}) : super(key: key);

  @override
  _TouchScreenWrapperState createState() => _TouchScreenWrapperState();
}

class _TouchScreenWrapperState extends State<TouchScreenWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _configureTouchSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _configureTouchSettings() {
    if (kIsWeb) return; // Skip system UI changes on web
    
    try {
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ));
    } catch (e) {
      print('Warning: Could not configure touch settings: $e');
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _handleScreenChange();
  }

  void _handleScreenChange() {
    try {
      final window = WidgetsBinding.instance.window;
      final screenSize = window.physicalSize / window.devicePixelRatio;
      debugPrint('Touch Screen - Size: ${screenSize.width}x${screenSize.height}');
      debugPrint('Touch Screen - DPR: ${window.devicePixelRatio}');
    } catch (e) {
      print('Warning: Could not get screen metrics: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        try {
          FocusScope.of(context).unfocus();
        } catch (e) {
          print('Warning: Could not unfocus: $e');
        }
      },
      child: widget.child,
    );
  }
}

// Stub for dynamic import (this is a simplified approach)
// In a real implementation, you might use conditional imports more elegantly
dynamic import(String library) async {
  throw UnsupportedError('Dynamic imports not fully supported in this context');
}