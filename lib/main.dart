import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telemetry_of_the_high_wind/providers/app_providers.dart';
import 'package:telemetry_of_the_high_wind/screens/add_payload_screen.dart';
import 'package:telemetry_of_the_high_wind/screens/initial_screen.dart';
import 'package:telemetry_of_the_high_wind/screens/main_navigation.dart';
import 'package:telemetry_of_the_high_wind/screens/payload_detail_screen.dart';
import 'package:telemetry_of_the_high_wind/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ProviderScope(child: TelemetryApp()));
}

class TelemetryApp extends ConsumerWidget {
  const TelemetryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Telemetry of the High Wind',
      theme: buildAppTheme(),
      home: user.firstTimeUser ? const InitialScreen() : const MainNavigation(),
      routes: {
        '/home': (_) => const MainNavigation(),
        '/initial': (_) => const InitialScreen(),
        '/add': (_) => const AddPayloadScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/detail') {
          return MaterialPageRoute(
            builder: (_) =>
                PayloadDetailScreen(id: settings.arguments! as String),
          );
        }
        return null;
      },
    );
  }
}
