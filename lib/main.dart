import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/admin/data/repositories/mock_ci_repository.dart';
import 'features/admin/domain/repositories/ci_repository.dart';
import 'features/dashboard/presentation/providers/status_provider.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';

/// Point d'entrée de l'application
/// Analogie AS/400 : Le CL de démarrage (SBMJOB ou CALL PGM).
void main() {
  // 1. Initialisation des dépendances (Les Fichiers/DA)
  final CIRepository repository = MockCIRepository();

  runApp(
    // 2. Injection des données dans l'arbre (LDA - Local Data Area)
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StatusProvider(repository: repository)),
      ],
      child: const BusinessStatusApp(),
    ),
  );
}

class BusinessStatusApp extends StatelessWidget {
  const BusinessStatusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Business Status Page',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        fontFamily: 'Roboto', // Police plus moderne
      ),
      // 3. Lancement du premier écran (DSPF)
      home: const DashboardScreen(),
    );
  }
}
