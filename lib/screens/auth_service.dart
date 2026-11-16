import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream para saber si hay sesión activa (Fase 2 y 4)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Iniciar Sesión (Sign In)
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Registrar Nuevo Usuario (Sign Up) con Firestore (Fase 3)
  Future<User?> signUp(String email, String password, String name) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      
      // Guardar datos adicionales en Cloud Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Recuperar Contraseña (Forgot Password) (Fase 4)
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Cerrar Sesión (Sign Out) (Fase 4)
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Traductor amigable de errores de Firebase
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No existe una cuenta con este correo.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'invalid-email':
        return 'El formato del correo electrónico no es válido.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta registrada con este correo.';
      case 'weak-password':
        return 'La contraseña es muy débil (mínimo 6 caracteres).';
      default:
        return 'Error de autenticación: ${e.message}';
    }
  }
}