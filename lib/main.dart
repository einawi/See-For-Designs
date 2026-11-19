import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:see_for_designs/models/design_model.dart';
import 'package:see_for_designs/providers/design_provider.dart';
import 'package:see_for_designs/screens/catalog_screen.dart';
import 'package:see_for_designs/screens/design_detail_screen.dart';
import 'package:see_for_designs/screens/trash_screen.dart';
import 'aiy_update.dart';

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF4F6BFF),
    brightness: Brightness.dark,
  ),
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF0B0F19),
  cardColor: const Color(0xFF1E293B),
  appBarTheme: AppBarTheme(
    backgroundColor: const Color(0xFF0B0F19),
    foregroundColor: const Color(0xFFE2E8F0),
    centerTitle: true,
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: const Color(0xFF1E293B),
    indicatorColor: const Color(0xFF38BDF8),
    labelTextColor: WidgetStatePropertyAll<TextStyle>(
      const TextStyle(color: Color(0xFF94A3B8)),
    ),
    iconColor: WidgetStatePropertyAll<Color>(
      const Color(0xFF38BDF8),
    ),
  ),
);

void main() {
  runApp(AiyUpdateHost(child: ChangeNotifierProvider(
      create: (_) => DesignProvider()..loadDesigns(),
      child: const SeeForDesignsApp(),
    ),));
}

class SeeForDesignsApp extends StatelessWidget {
  const SeeForDesignsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'See For Designs',
      theme: appTheme,
      themeMode: ThemeMode.dark,
      home: const CatalogScreen(),
      onGenerateRoute: (settings) {
        if (settings.name == '/design') {
          final design = settings.arguments as DesignModel;
          return MaterialPageRoute(
            builder: (_) => DesignDetailScreen(design: design),
          );
        }
        if (settings.name == '/trash') {
          return MaterialPageRoute(builder: (_) => const TrashScreen());
        }
        return null;
      },
    );
  }
}
