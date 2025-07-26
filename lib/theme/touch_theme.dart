import 'package:flutter/material.dart';

class TouchPOSTheme {
  // Modern color palette
  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color primaryOrangeLight = Color(0xFFFF8A5B);
  static const Color primaryOrangeDark = Color(0xFFE85A2B);
  static const Color accentBlue = Color(0xFF2E86AB);
  static const Color accentBlueDark = Color(0xFF1A5F7A);
  static const Color successGreen = Color(0xFF39B54A);
  static const Color warningAmber = Color(0xFFFFC107);
  static const Color errorRed = Color(0xFFE53E3E);

  // Neutral colors
  static const Color surfaceWhite = Color(0xFFFAFAFA);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF2D3748);
  static const Color textMedium = Color(0xFF4A5568);
  static const Color textLight = Color(0xFF718096);
  static const Color borderGray = Color(0xFFE2E8F0);
  static const Color backgroundGray = Color(0xFFF7FAFC);

  // Touch-optimized sizing
  static const double minTouchTarget = 48.0;
  static const double preferredTouchTarget = 56.0;
  static const double largeTouchTarget = 72.0;
  static const double extraLargeTouchTarget = 88.0;

  // Modern spacing system
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space48 = 48.0;

  // Border radius system
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;

  static ThemeData get touchOptimizedTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryOrange,
        brightness: Brightness.light,
        primary: primaryOrange,
        primaryContainer: primaryOrangeLight,
        secondary: accentBlue,
        secondaryContainer: accentBlueDark,
        surface: surfaceWhite,
        background: backgroundGray,
        error: errorRed,
      ),

      // Enhanced app bar theme
      appBarTheme: AppBarTheme(
        toolbarHeight: 90,
        elevation: 0,
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
          size: 28,
        ),
        actionsIconTheme: const IconThemeData(
          color: Colors.white,
          size: 26,
        ),
        shadowColor: primaryOrange.withOpacity(0.3),
      ),

      // Modern elevated buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 3,
          shadowColor: Colors.black26,
          minimumSize:
              const Size(preferredTouchTarget, preferredTouchTarget + 8),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ).copyWith(
          backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.pressed)) {
              return primaryOrangeDark;
            }
            if (states.contains(MaterialState.hovered)) {
              return primaryOrangeLight;
            }
            if (states.contains(MaterialState.disabled)) {
              return Colors.grey[300]!;
            }
            return primaryOrange;
          }),
          foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.disabled)) {
              return Colors.grey[500]!;
            }
            return Colors.white;
          }),
          overlayColor:
              MaterialStateProperty.all(Colors.white.withOpacity(0.1)),
        ),
      ),

      // Modern outlined buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize:
              const Size(preferredTouchTarget, preferredTouchTarget + 8),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          side: const BorderSide(color: primaryOrange, width: 2),
        ).copyWith(
          foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.pressed)) {
              return Colors.white;
            }
            if (states.contains(MaterialState.disabled)) {
              return Colors.grey[400]!;
            }
            return primaryOrange;
          }),
          backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.pressed)) {
              return primaryOrange;
            }
            if (states.contains(MaterialState.hovered)) {
              return primaryOrange.withOpacity(0.04);
            }
            return Colors.transparent;
          }),
          side: MaterialStateProperty.resolveWith<BorderSide>((states) {
            if (states.contains(MaterialState.disabled)) {
              return BorderSide(color: Colors.grey[300]!, width: 2);
            }
            return const BorderSide(color: primaryOrange, width: 2);
          }),
        ),
      ),

      // Enhanced text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize:
              const Size(preferredTouchTarget, preferredTouchTarget + 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          foregroundColor: primaryOrange,
        ),
      ),

      // Modern icon buttons
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(preferredTouchTarget, preferredTouchTarget),
          padding: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          backgroundColor: Colors.transparent,
        ).copyWith(
          backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.pressed)) {
              return primaryOrange.withOpacity(0.12);
            }
            if (states.contains(MaterialState.hovered)) {
              return primaryOrange.withOpacity(0.04);
            }
            return Colors.transparent;
          }),
        ),
      ),

      // Enhanced card theme
      cardTheme: CardTheme(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.08),
        margin: const EdgeInsets.all(space8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        color: cardWhite,
        surfaceTintColor: Colors.transparent,
      ),

      // Modern list tile theme
      listTileTheme: const ListTileThemeData(
        minVerticalPadding: 16,
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        dense: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusMedium)),
        ),
      ),

      // Enhanced typography
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          letterSpacing: -1.0,
          color: textDark,
        ),
        displayMedium: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.8,
          color: textDark,
        ),
        displaySmall: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.6,
          color: textDark,
        ),
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.4,
          color: textDark,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: textDark,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.0,
          color: textDark,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: textDark,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: textMedium,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          letterSpacing: 0.1,
          color: textDark,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          letterSpacing: 0.2,
          color: textMedium,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          letterSpacing: 0.3,
          color: textLight,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: textDark,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: textMedium,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: textLight,
        ),
      ),

      // Modern input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardWhite,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: borderGray, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: borderGray, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: primaryOrange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: errorRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: errorRed, width: 2),
        ),
        labelStyle: const TextStyle(
          fontSize: 16,
          color: textMedium,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: const TextStyle(
          fontSize: 16,
          color: textLight,
        ),
        suffixIconColor: primaryOrange,
        prefixIconColor: textMedium,
      ),

      // Enhanced chip theme
      chipTheme: ChipThemeData(
        backgroundColor: backgroundGray,
        selectedColor: primaryOrange,
        secondarySelectedColor: primaryOrangeLight,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textDark,
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        elevation: 1,
        pressElevation: 2,
      ),

      // Modern dialog theme
      dialogTheme: DialogTheme(
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXLarge),
        ),
        backgroundColor: cardWhite,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textDark,
          letterSpacing: -0.2,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 16,
          color: textMedium,
          height: 1.5,
        ),
      ),

      // Enhanced bottom sheet
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.15),
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(radiusXLarge)),
        ),
        backgroundColor: cardWhite,
      ),

      // Modern tab bar
      tabBarTheme: const TabBarTheme(
        labelStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        labelColor: primaryOrange,
        unselectedLabelColor: textMedium,
        indicatorColor: primaryOrange,
        indicatorSize: TabBarIndicatorSize.tab,
        labelPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // Enhanced switch theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryOrange;
          }
          return Colors.white;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryOrangeLight;
          }
          return borderGray;
        }),
        overlayColor:
            MaterialStateProperty.all(primaryOrange.withOpacity(0.12)),
      ),

      // Enhanced checkbox theme
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryOrange;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        materialTapTargetSize: MaterialTapTargetSize.padded,
      ),

      // Enhanced slider theme
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryOrange,
        inactiveTrackColor: borderGray,
        thumbColor: primaryOrange,
        overlayColor: primaryOrange.withOpacity(0.12),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
        trackHeight: 6,
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
      ),

      // Enhanced floating action button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 6,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusLarge)),
        ),
      ),
    );
  }

  // Custom button styles
  static ButtonStyle get primaryLargeButton => ElevatedButton.styleFrom(
        minimumSize: const Size(200, extraLargeTouchTarget),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.1,
        ),
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        elevation: 4,
        shadowColor: primaryOrange.withOpacity(0.3),
      );

  static ButtonStyle get successButton => ElevatedButton.styleFrom(
        backgroundColor: successGreen,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        elevation: 2,
        shadowColor: successGreen.withOpacity(0.3),
      );

  static ButtonStyle get warningButton => ElevatedButton.styleFrom(
        backgroundColor: warningAmber,
        foregroundColor: textDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        elevation: 2,
        shadowColor: warningAmber.withOpacity(0.3),
      );

  static ButtonStyle get dangerButton => ElevatedButton.styleFrom(
        backgroundColor: errorRed,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        elevation: 2,
        shadowColor: errorRed.withOpacity(0.3),
      );

  static ButtonStyle get connectButton => ElevatedButton.styleFrom(
        minimumSize: const Size(100, 40),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        backgroundColor: accentBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        elevation: 2,
        shadowColor: accentBlue.withOpacity(0.3),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      );

  static ButtonStyle get menuItemButton => ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, largeTouchTarget + 8),
        padding: const EdgeInsets.all(16),
        alignment: Alignment.centerLeft,
        backgroundColor: cardWhite,
        foregroundColor: textDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
      );

  // Custom container styles
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration get primaryGradientDecoration => BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryOrange, primaryOrangeLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: [
          BoxShadow(
            color: primaryOrange.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration get statusCardDecoration => BoxDecoration(
        color: successGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(radiusMedium),
        border: Border.all(
          color: successGreen.withOpacity(0.3),
          width: 1,
        ),
      );

  // Touch feedback colors
  static const Color touchHighlight = Color(0x20FF6B35);
  static const Color touchSplash = Color(0x40FF6B35);

  // Helper methods for spacing
  static EdgeInsets get paddingAll16 => const EdgeInsets.all(space16);
  static EdgeInsets get paddingAll20 => const EdgeInsets.all(space20);
  static EdgeInsets get paddingAll24 => const EdgeInsets.all(space24);

  static EdgeInsets get paddingH16 =>
      const EdgeInsets.symmetric(horizontal: space16);
  static EdgeInsets get paddingH20 =>
      const EdgeInsets.symmetric(horizontal: space20);
  static EdgeInsets get paddingH24 =>
      const EdgeInsets.symmetric(horizontal: space24);

  static EdgeInsets get paddingV16 =>
      const EdgeInsets.symmetric(vertical: space16);
  static EdgeInsets get paddingV20 =>
      const EdgeInsets.symmetric(vertical: space20);
  static EdgeInsets get paddingV24 =>
      const EdgeInsets.symmetric(vertical: space24);

  // Helper methods for spacing widgets
  static Widget get verticalSpace8 => const SizedBox(height: space8);
  static Widget get verticalSpace12 => const SizedBox(height: space12);
  static Widget get verticalSpace16 => const SizedBox(height: space16);
  static Widget get verticalSpace20 => const SizedBox(height: space20);
  static Widget get verticalSpace24 => const SizedBox(height: space24);
  static Widget get verticalSpace32 => const SizedBox(height: space32);

  static Widget get horizontalSpace8 => const SizedBox(width: space8);
  static Widget get horizontalSpace12 => const SizedBox(width: space12);
  static Widget get horizontalSpace16 => const SizedBox(width: space16);
  static Widget get horizontalSpace20 => const SizedBox(width: space20);
  static Widget get horizontalSpace24 => const SizedBox(width: space24);
}
