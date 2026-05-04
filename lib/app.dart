import 'package:flutter/material.dart';
import 'data/settings_service.dart';
import 'screens/welcome_screen.dart';
import 'widgets/main_shell.dart';
import 'theme/app_colors.dart';

final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(
  ThemeMode.system,
);

class KoviraApp extends StatefulWidget {
  const KoviraApp({super.key});
  @override
  State<KoviraApp> createState() => _KoviraAppState();
}

class _KoviraAppState extends State<KoviraApp> {
  bool _welcomeSeen = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final mode = await SettingsService.instance.getThemeMode();
    final seen = await SettingsService.instance.hasSeenWelcome();
    if (mounted) {
      themeModeNotifier.value = mode;
      setState(() {
        _welcomeSeen = seen;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (_, mode, _) => MaterialApp(
        title: 'Kovira',
        debugShowCheckedModeBanner: false,
        themeMode: mode,
        theme: _lightTheme(),
        darkTheme: _darkTheme(),
        home: !_loaded
            ? const Scaffold(body: SizedBox.shrink())
            : !_welcomeSeen
            ? WelcomeScreen(onDone: () => setState(() => _welcomeSeen = true))
            : const MainShell(),
      ),
    );
  }

  ThemeData _lightTheme() {
    var cs = ColorScheme.fromSeed(
      seedColor: AppColorsLight.seed,
      brightness: Brightness.light,
    );

    cs = cs.copyWith(
      primary: AppColorsLight.primary,
      onPrimary: AppColorsLight.onPrimary,
      primaryContainer: AppColorsLight.primaryContainer,
      onPrimaryContainer: AppColorsLight.onPrimaryContainer,
      secondary: AppColorsLight.secondary,

      surface: AppColorsLight.cardBg,

      surfaceContainerHighest: AppColorsLight.surfaceContainerHighest,
      surfaceContainerHigh: AppColorsLight.surfaceContainerHigh,
      surfaceContainer: AppColorsLight.surfaceContainer,
      surfaceContainerLow: AppColorsLight.surfaceContainerLow,
      surfaceContainerLowest: AppColorsLight.surfaceContainerLowest,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: AppColorsLight.scaffoldBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColorsLight.scaffoldBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      extensions: const [
        KoviraColors(
          btnExpense: AppColorsLight.btnExpense,
          btnTransfer: AppColorsLight.btnTransfer,
          btnMenu: AppColorsLight.btnMenu,
        ),
      ],
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontSize: 17),
        bodyMedium: TextStyle(fontSize: 15),
        bodySmall: TextStyle(fontSize: 13),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: AppColorsLight.cardBg,
        shadowColor: const Color(0x18000000),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
      ),
    );
  }

  ThemeData _darkTheme() {
    const bg = AppColorsDark.background;
    const surface = AppColorsDark.surface;
    const surface2 = AppColorsDark.surface2;
    const onSurface = AppColorsDark.onSurface;
    const onSurface2 = AppColorsDark.onSurfaceMuted;
    const divider = AppColorsDark.divider;
    const primary = AppColorsDark.primary;
    const primaryDk = AppColorsDark.primaryDark;
    const onPrimary = AppColorsDark.onPrimary;

    const cs = ColorScheme(
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: AppColorsDark.primaryContainer,
      onPrimaryContainer: AppColorsDark.onPrimaryContainer,
      secondary: AppColorsDark.secondary,
      onSecondary: AppColorsDark.onSecondary,
      secondaryContainer: AppColorsDark.secondaryContainer,
      onSecondaryContainer: AppColorsDark.onSecondaryContainer,
      tertiary: AppColorsDark.tertiary,
      onTertiary: AppColorsDark.onTertiary,
      tertiaryContainer: AppColorsDark.tertiaryContainer,
      onTertiaryContainer: AppColorsDark.onTertiaryContainer,
      error: AppColorsDark.error,
      onError: AppColorsDark.onError,
      errorContainer: AppColorsDark.errorContainer,
      onErrorContainer: AppColorsDark.onErrorContainer,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: surface2,
      outline: divider,
      outlineVariant: AppColorsDark.outline2,
      shadow: Colors.black,
      inverseSurface: onSurface,
      onInverseSurface: bg,
      inversePrimary: primaryDk,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: bg,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      extensions: const [
        KoviraColors(
          btnExpense: AppColorsDark.btnExpense,
          btnTransfer: AppColorsDark.btnTransfer,
          btnMenu: AppColorsDark.btnMenu,
        ),
      ],
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontSize: 17, color: onSurface),
        bodyMedium: TextStyle(fontSize: 15, color: onSurface),
        bodySmall: TextStyle(fontSize: 13, color: onSurface2),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: onSurface,
        ),
        titleSmall: TextStyle(fontSize: 15, color: onSurface),
        labelLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: surface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: onSurface,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: surface2,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        contentTextStyle: TextStyle(fontSize: 16, color: onSurface),
      ),
      listTileTheme: const ListTileThemeData(
        textColor: onSurface,
        iconColor: onSurface2,
        tileColor: Colors.transparent,
      ),
      iconTheme: const IconThemeData(color: onSurface2),
      dividerColor: divider,
      dividerTheme: const DividerThemeData(color: divider),
      chipTheme: ChipThemeData(
        backgroundColor: surface2,
        labelStyle: const TextStyle(color: onSurface, fontSize: 14),
        selectedColor: primary,
        side: const BorderSide(color: divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2,
        labelStyle: const TextStyle(color: onSurface2, fontSize: 15),
        hintStyle: const TextStyle(color: onSurface2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: surface2,
        textStyle: TextStyle(color: onSurface, fontSize: 16),
      ),
      dropdownMenuTheme: const DropdownMenuThemeData(
        menuStyle: MenuStyle(backgroundColor: WidgetStatePropertyAll(surface2)),
        textStyle: TextStyle(color: onSurface),
      ),
    );
  }
}

class KoviraColors extends ThemeExtension<KoviraColors> {
  final Color btnExpense;
  final Color btnTransfer;
  final Color btnMenu;

  const KoviraColors({
    required this.btnExpense,
    required this.btnTransfer,
    required this.btnMenu,
  });

  @override
  KoviraColors copyWith({
    Color? btnExpense,
    Color? btnTransfer,
    Color? btnMenu,
  }) => KoviraColors(
    btnExpense: btnExpense ?? this.btnExpense,
    btnTransfer: btnTransfer ?? this.btnTransfer,
    btnMenu: btnMenu ?? this.btnMenu,
  );

  @override
  KoviraColors lerp(KoviraColors? other, double t) {
    if (other == null) return this;
    return KoviraColors(
      btnExpense: Color.lerp(btnExpense, other.btnExpense, t)!,
      btnTransfer: Color.lerp(btnTransfer, other.btnTransfer, t)!,
      btnMenu: Color.lerp(btnMenu, other.btnMenu, t)!,
    );
  }

  static KoviraColors of(BuildContext context) =>
      Theme.of(context).extension<KoviraColors>() ??
      const KoviraColors(
        btnExpense: Color(0xFFFFCDD2),
        btnTransfer: Color(0xFFBBDEFB),
        btnMenu: Color(0xFFE0E0E0),
      );
}
