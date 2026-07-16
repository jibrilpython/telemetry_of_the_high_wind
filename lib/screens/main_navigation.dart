import 'package:flutter/material.dart';
import 'package:telemetry_of_the_high_wind/screens/archive_screen.dart';
import 'package:telemetry_of_the_high_wind/screens/ascension_grid_screen.dart';
import 'package:telemetry_of_the_high_wind/screens/logbook_screen.dart';
import 'package:telemetry_of_the_high_wind/screens/pressure_calculator_screen.dart';
import 'package:telemetry_of_the_high_wind/theme/app_theme.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int index = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(
          index: index,
          children: [
            const ArchiveScreen(),
            TickerMode(
              enabled: index == 1,
              child: const AscensionGridScreen(),
            ),
            const LogbookScreen(),
            const PressureCalculatorScreen(),
          ],
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: outline)),
          ),
          child: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (value) => setState(() => index = value),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2, color: radarGreen),
                label: 'Archive',
              ),
              NavigationDestination(
                icon: Icon(Icons.vertical_align_top_outlined),
                selectedIcon:
                    Icon(Icons.vertical_align_top, color: radarGreen),
                label: 'Ascension',
              ),
              NavigationDestination(
                icon: Icon(Icons.query_stats_outlined),
                selectedIcon: Icon(Icons.query_stats, color: radarGreen),
                label: 'Logbook',
              ),
              NavigationDestination(
                icon: Icon(Icons.calculate_outlined),
                selectedIcon: Icon(Icons.calculate, color: radarGreen),
                label: 'Calculator',
              ),
            ],
          ),
        ),
      );
}
