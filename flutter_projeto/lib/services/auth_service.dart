// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String keyIsLoggedIn = 'isLoggedIn';

  User? get currentUser => _auth.currentUser;

  // Realiza o cadastro via Firebase Auth e grava a chave no SharedPreferences
  Future<UserCredential> registrar(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _setSessionState(true);
    return credential;
  }

  // Autentica o utilizador e atualiza o estado da sessão local
  Future<UserCredential> login(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _setSessionState(true);
    return credential;
  }

  // Encerra a sessão no serviço de autenticação e remove a flag local no SharedPreferences
  Future<void> logout() async {
    await _auth.signOut();
    await _setSessionState(false);
  }

  // Altera o estado booleano de persistência no SharedPreferences
  Future<void> _setSessionState(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyIsLoggedIn, value);
  }

  // Verifica o estado da sessão gravado no SharedPreferences
  Future<bool> checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyIsLoggedIn) ?? false;
  }
}