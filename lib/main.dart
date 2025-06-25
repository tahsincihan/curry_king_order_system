import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:ui';
import 'services/order_provider.dart';
import 'services/sales_provider.dart';
import 'theme/touch_theme.dart';

// Import screens
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure window for touch screen POS
  await windowManager.ensureInitialized();
  
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1920, 1080), // Full HD touch screen
    minimumSize: Size(1024, 768), // Minimum for POS
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    windowButtonVisibility: true,
    title: 'Curry King POS - Touch Screen',
    fullScreen: false, // Can be set to true for kiosk mode
  );
  
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    
    // Optional: Enable kiosk mode for dedicated POS terminal
    // await windowManager.setFullScreen(true);
    // await windowManager.setAlwaysOnTop(true);
  });
  
  // Configure system UI for touch
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.top], // Keep top bar for window controls
  );
  
  // Set preferred orientations (landscape for POS)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp, // Allow portrait for flexibility
  ]);
  
  // Initialize sales provider
  final salesProvider = SalesProvider();
  await salesProvider.initialize();
  
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
        ChangeNotifierProvider.value(value: salesProvider),
      ],
      child: MaterialApp(
        title: 'Curry King Touch POS',
        
        // Use touch-optimized theme
        theme: TouchPOSTheme.touchOptimizedTheme.copyWith(
          // Add touch-specific material behavior
          materialTapTargetSize: MaterialTapTargetSize.padded,
          splashColor: TouchPOSTheme.touchSplash,
          highlightColor: TouchPOSTheme.touchHighlight,
          
          // Ensure proper touch feedback
          platform: TargetPlatform.windows,
        ),
        
        // Touch-friendly scroll behavior
        scrollBehavior: const TouchScrollBehavior(),
        
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
        
        // Handle system navigation for touch
        builder: (context, child) {
          return TouchScreenWrapper(child: child!);
        },
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

class _TouchScreenWrapperState extends State<TouchScreenWrapper> with WidgetsBindingObserver {
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
    // Configure touch-specific settings
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // Handle screen orientation changes or resolution changes
    _handleScreenChange();
  }

  void _handleScreenChange() {
    final window = WidgetsBinding.instance.window;
    final screenSize = window.physicalSize / window.devicePixelRatio;
    
    // Log screen information for debugging
    debugPrint('Touch Screen - Size: ${screenSize.width}x${screenSize.height}');
    debugPrint('Touch Screen - DPR: ${window.devicePixelRatio}');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Handle global touch gestures if needed
      onTap: () {
        // Remove focus from any text fields when tapping elsewhere
        FocusScope.of(context).unfocus();
      },
      child: widget.child,
    );
  }
}

// Touch-friendly gesture detector for menu items
class TouchMenuItem extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enabled;
  
  const TouchMenuItem({
    Key? key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
  }) : super(key: key);

  @override
  _TouchMenuItemState createState() => _TouchMenuItemState();
}

class _TouchMenuItemState extends State<TouchMenuItem> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.enabled) return;
    
    setState(() {
      _isPressed = true;
    });
    _animationController.forward();
    
    // Haptic feedback for touch
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.enabled) return;
    
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
  }

  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.enabled ? widget.onTap : null,
      onLongPress: widget.enabled ? widget.onLongPress : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: _isPressed 
                    ? TouchPOSTheme.touchHighlight 
                    : Colors.transparent,
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

// Touch-optimized numeric keypad
class TouchNumPad extends StatelessWidget {
  final Function(String) onNumberPressed;
  final VoidCallback? onClearPressed;
  final VoidCallback? onBackspacePressed;
  
  const TouchNumPad({
    Key? key,
    required this.onNumberPressed,
    this.onClearPressed,
    this.onBackspacePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildNumPadRow(['1', '2', '3']),
          const SizedBox(height: 12),
          _buildNumPadRow(['4', '5', '6']),
          const SizedBox(height: 12),
          _buildNumPadRow(['7', '8', '9']),
          const SizedBox(height: 12),
          _buildNumPadRow(['.', '0', 'clear']),
        ],
      ),
    );
  }

  Widget _buildNumPadRow(List<String> numbers) {
    return Row(
      children: numbers.map((number) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                if (number == 'clear') {
                  onClearPressed?.call();
                } else if (number == '⌫') {
                  onBackspacePressed?.call();
                } else {
                  onNumberPressed(number);
                }
              },
              style: TouchPOSTheme.numpadButton,
              child: Text(
                number == 'clear' ? 'C' : number,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}