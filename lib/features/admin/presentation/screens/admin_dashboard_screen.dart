import 'package:flutter/material.dart';
import '../../domain/services/auth_service.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import 'ci_list_screen.dart';
import 'dependency_list_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const DashboardScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [


          _buildAdminCard(
            context,
            icon: Icons.list_alt,
            title: 'Gérer les CIs',
            description: 'Créer, modifier ou supprimer des composants.',
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CIListScreen()));
            },
          ),
          _buildAdminCard(
            context,
            icon: Icons.hub,
            title: 'Gérer les Dépendances',
            description: 'Relier les composants entre eux.',
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DependencyListScreen()));
            },
          ),
        ]
      ),
    );
  }

  Widget _buildAdminCard(BuildContext context, {required IconData icon, required String title, required String description, required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: Colors.indigo),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
