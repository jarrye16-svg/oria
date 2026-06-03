import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class AuthService {
  User? get currentUser => supabase.auth.currentUser;
  Session? get currentSession => supabase.auth.currentSession;
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await supabase.auth.signInWithPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );

    if (response.session == null || response.user == null) {
      throw const AuthException('Login nao retornou sessao. Verifique confirmacao de e-mail e credenciais.');
    }

    return response;
  }

  Future<AuthResponse> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await supabase.auth.signUp(
      email: email.trim().toLowerCase(),
      password: password,
      data: {'full_name': name.trim()},
    );

    if (response.user == null) {
      throw const AuthException('Cadastro nao retornou usuario.');
    }

    return response;
  }

  Future<void> resetPassword({
    required String email,
    required String redirectTo,
  }) async {
    await supabase.auth.resetPasswordForEmail(
      email.trim().toLowerCase(),
      redirectTo: redirectTo,
    );
  }

  Future<void> updatePassword(String password) async {
    await supabase.auth.updateUser(
      UserAttributes(password: password),
    );
  }

  Future<void> signOut() => supabase.auth.signOut();
}
