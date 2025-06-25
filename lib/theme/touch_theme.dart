import 'package:flutter/material.dart';

class TouchPOSTheme {
  // Touch-optimized sizing
  static const double minTouchTarget = 48.0;
  static const double preferredTouchTarget = 56.0;
  static const double largeTouchTarget = 72.0;
  static const double extraLargeTouchTarget = 88.0;

  // Touch-friendly spacing
  static const double touchPadding = 16.0;
  static const double touchMargin = 12.0;
  static const double touchSpacing = 20.0;

  static ThemeData get touchOptimizedTheme {
    return ThemeData(
      primarySwatch: Colors.orange,
      visualDensity: VisualDensity.comfortable, // More space for touch
      
      // Touch-optimized app bar
      appBarTheme: const AppBarTheme(
        toolbarHeight: 80,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),

      // Large, touch-friendly buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(preferredTouchTarget, preferredTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          shadowColor: Colors.black26,
        ),
      ),

      // Touch-friendly outlined buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(preferredTouchTarget, preferredTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(width: 2),
        ),
      ),

      // Large text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(preferredTouchTarget, preferredTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Touch-friendly icon buttons
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(preferredTouchTarget, preferredTouchTarget),
          padding: const EdgeInsets.all(12),
          iconSize: 28,
        ),
      ),

      // Larger cards with touch-friendly elevation
      cardTheme: CardTheme(
        elevation: 6,
        margin: const EdgeInsets.all(touchMargin),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Touch-optimized list tiles
      listTileTheme: const ListTileThemeData(
        minVerticalPadding: 16,
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        dense: false,
      ),

      // Large, readable text
      textTheme: const TextTheme(
        // Headlines
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        
        // Titles
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        
        // Body text
        bodyLarge: TextStyle(fontSize: 18),
        bodyMedium: TextStyle(fontSize: 16),
        bodySmall: TextStyle(fontSize: 14),
        
        // Labels
        labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),

      // Touch-friendly input decoration
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[400]!, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.orange, width: 2),
        ),
        labelStyle: const TextStyle(fontSize: 16),
        hintStyle: TextStyle(fontSize: 16, color: Colors.grey[600]),
      ),

      // Touch-friendly chips
      chipTheme: ChipThemeData(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 2,
      ),

      // Touch-optimized dialog theme
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
      ),

      // Touch-friendly bottom sheet
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        elevation: 8,
      ),

      // Touch-optimized tab bar
      tabBarTheme: const TabBarTheme(
        labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
        labelPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // Touch-friendly switches and checkboxes
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.all(Colors.orange),
        trackColor: MaterialStateProperty.all(Colors.orangeAccent),
      ),

      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        materialTapTargetSize: MaterialTapTargetSize.padded,
      ),

      // Touch-friendly sliders
      sliderTheme: const SliderThemeData(
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12),
        trackHeight: 6,
        overlayShape: RoundSliderOverlayShape(overlayRadius: 24),
      ),
    );
  }

  // Predefined button sizes for different use cases
  static ButtonStyle get primaryOrderButton => ElevatedButton.styleFrom(
    minimumSize: const Size(200, extraLargeTouchTarget),
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
    textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    backgroundColor: Colors.orange[600],
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    elevation: 6,
  );

  static ButtonStyle get secondaryButton => ElevatedButton.styleFrom(
    minimumSize: const Size(150, largeTouchTarget),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    backgroundColor: Colors.grey[100],
    foregroundColor: Colors.grey[800],
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 2,
  );

  static ButtonStyle get menuItemButton => ElevatedButton.styleFrom(
    minimumSize: const Size(double.infinity, largeTouchTarget),
    padding: const EdgeInsets.all(16),
    alignment: Alignment.centerLeft,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 2,
  );

  static ButtonStyle get numpadButton => ElevatedButton.styleFrom(
    minimumSize: const Size(extraLargeTouchTarget, extraLargeTouchTarget),
    padding: EdgeInsets.zero,
    textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 4,
  );

  // Touch-friendly spacing helpers
  static const EdgeInsets touchPaddingAll = EdgeInsets.all(touchPadding);
  static const EdgeInsets touchPaddingHorizontal = EdgeInsets.symmetric(horizontal: touchPadding);
  static const EdgeInsets touchPaddingVertical = EdgeInsets.symmetric(vertical: touchPadding);
  
  static const SizedBox touchSpacingSmall = SizedBox(height: 12, width: 12);
  static const SizedBox touchSpacingMedium = SizedBox(height: touchSpacing, width: touchSpacing);
  static const SizedBox touchSpacingLarge = SizedBox(height: 32, width: 32);

  // Touch feedback colors
  static const Color touchHighlight = Color(0x40FF9800);
  static const Color touchSplash = Color(0x60FF9800);
}