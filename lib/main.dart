import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:see_for_designs/models/design_item.dart';
import 'package:see_for_designs/services/database_service.dart';
import 'package:see_for_designs/screens/catalog_screen.dart';
import 'package:see_for_designs/screens/design_detail_screen.dart';
import 'package:see_for_designs/screens/trash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = DatabaseService();
  await db.init();
  runApp(
    ChangeNotifierProvider.value(
      value: db,
      child: const SeeForDesignsApp(),
    ),
  );
}

class SeeForDesignsApp extends StatelessWidget {
  const SeeForDesignsApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF4F6BFF);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );
    final lightColorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'See For Designs',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightColorScheme,
        scaffoldBackgroundColor: lightColorScheme.surface,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(8),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: lightColorScheme.surface,
          foregroundColor: lightColorScheme.onSurface,
          elevation: 0,
          centerTitle: true,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: lightColorScheme.primary,
          foregroundColor: lightColorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: lightColorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontFamily: 'monospace'),
          labelLarge: TextStyle(fontFamily: 'monospace'),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFF0B0F19),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(8),
          color: const Color(0xFF1E293B),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF0B0F19),
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
          centerTitle: true,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E293B),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontFamily: 'monospace'),
          labelLarge: TextStyle(fontFamily: 'monospace'),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const CatalogScreen(),
        '/detail': (context) => const DesignDetailScreen(),
        '/trash': (context) => const TrashScreen(),
      },
    );
  }
}
