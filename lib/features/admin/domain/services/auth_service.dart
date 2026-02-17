import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  // Stream de changement d'état d'auth
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  // Utilisateur courant
  User? get currentUser => _client.auth.currentUser;

  // Connexion email/password
  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Déconnexion
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Vérifie si l'utilisateur est admin (Pour l'instant, tout utilisateur connecté est admin)
  bool get isAdmin => currentUser != null;
}
