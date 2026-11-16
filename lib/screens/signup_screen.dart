import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController(); // Opcional para el nombre (Fase 3)
  bool _isLoading = false;

  Future<void> _signUp() async {
    setState(() => _isLoading = true);
    try {
      // 1. Crear el usuario en Firebase Auth
      UserCredential credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      print('Usuario creado en Auth con ID: ${credential.user!.uid}');

      // 2. Intentar guardar en Firestore (con manejo de errores independiente)
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .set({
          'name': _nameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        print('Datos guardados en Firestore');
      } catch (firestoreError) {
        print(
            ' Error al guardar en Firestore (Auth sí funcionó): $firestoreError');
      }

      if (!mounted) return;
      Navigator.pop(context); // Regresa al login al registrarse con éxito
    } catch (e) {
      print('Error general de registro: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de Usuario')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre')),
            const SizedBox(height: 10),
            TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Correo')),
            const SizedBox(height: 10),
            TextField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Contraseña (mínimo 6 caracteres)')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _signUp,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text('Registrarse'),
            ),
          ],
        ),
      ),
    );
  }
}
