import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'products_screen.dart'; // pantalla de productos de Spring Boot
import 'signup_screen.dart'; // pantalla de registro
import 'dart:async';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscure = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _isToggleAnimating = false; // Bandera específica para el anti-spam del toggle

  StateMachineController? _controller;

  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;

  SMINumber? _numLook;

  Timer? _typingDebounce;

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  String? _emailError;
  String? _passError;

  bool isValidEmail(String email) {
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(email);
  }

  bool isValidPassword(String pass) {
    final re = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',
    );
    return re.hasMatch(pass);
  }

  Future<void> _onLogin() async {
    if (_isLoading) return;

    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;

    final eError = isValidEmail(email) ? null : 'Invalid Email';
    final pError = isValidPassword(password)
        ? null
        : 'Invalid Password (mín. 8 caracteres, A-Z, a-z, 0-9 y símbolo)';

    FocusScope.of(context).unfocus();
    _typingDebounce?.cancel();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    setState(() {
      _emailError = eError;
      _passError = pError;
    });

    _isChecking?.change(false);
    _isHandsUp?.change(false);
    _numLook?.value = 50.0;

    // 4.9 Si hay errores locales de formato (regex), lanzar fallo y detener aquí
    if (eError != null || pError != null) {
      _trigFail?.fire();
      return;
    }

    // 5.4 Activar el CircularProgressIndicator
    setState(() {
      _isLoading = true;
    });

    try {
      // 5.5 Autenticar usuario en Firebase
      await Future.delayed(const Duration(seconds: 2));
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 5.6 Apagar loading, disparar éxito del osito y esperar su animación
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _trigSuccess?.fire();
      await Future.delayed(const Duration(seconds: 2));

      // 5.7 Navegar a la pantalla de productos de Spring Boot
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProductsScreen()),
      );
    } on FirebaseAuthException catch (_) {
      // 5.8 Credenciales no válidas sin mostrar error en un campo específico
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _emailError = null;
        _passError = null;
      });
      _trigFail?.fire();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Credenciales no válidas'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 5),
          ),
        );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _emailError = null;
        _passError = null;
      });
      _trigFail?.fire();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Credenciales no válidas'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 5),
          ),
        );
    }
  }

  void _showForgotPasswordDialog() {
    final resetCtrl = TextEditingController(text: _emailCtrl.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recuperar Contraseña'),
        content: TextField(
          controller: resetCtrl,
          decoration: const InputDecoration(
            hintText: 'Ingresa tu correo electrónico',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              try {
                // Método para recuperar contraseña con Firebase
                await FirebaseAuth.instance.sendPasswordResetEmail(
                  email: resetCtrl.text.trim(),
                );
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        '¡Correo de recuperación enviado con éxito! Revisa tu bandeja.'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Enviar'),
          )
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _emailFocus.addListener(() {
      if (_isHandsUp != null) {
        _isHandsUp?.change(false);
        _numLook?.value = 50.0;
      }
    });

    _passwordFocus.addListener(() {
      _isHandsUp?.change(_passwordFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _typingDebounce?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                SizedBox(
                  width: size.width,
                  height: 200,
                  child: RiveAnimation.asset(
                    'assets/login-bear.riv',
                    stateMachines: const ['Login Machine'],
                    onInit: (artboard) {
                      _controller = StateMachineController.fromArtboard(
                        artboard,
                        'Login Machine',
                      );

                      if (_controller == null) return;

                      artboard.addController(_controller!);

                      _isChecking = _controller!.findSMI('isChecking');
                      _isHandsUp = _controller!.findSMI('isHandsUp');
                      _trigSuccess = _controller!.findSMI('trigSuccess');
                      _trigFail = _controller!.findSMI('trigFail');
                      _numLook = _controller!.findSMI('numLook');
                    },
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _emailCtrl,
                  focusNode: _emailFocus,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isLoading,
                  onChanged: (value) {
                    if (_isChecking != null) {
                      _isChecking!.change(true);
                      final look =
                          (value.length / 80.0 * 100.0).clamp(0.0, 100.0);
                      _numLook?.value = look;
                      _typingDebounce?.cancel();
                      _typingDebounce = Timer(const Duration(seconds: 3), () {
                        if (!mounted) return;
                        _isChecking?.change(false);
                      });
                    }

                    if (_isHandsUp != null) {
                      _isHandsUp!.change(false);
                    }
                  },
                  decoration: InputDecoration(
                    errorText: _emailError,
                    hintText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _passCtrl,
                  focusNode: _passwordFocus,
                  obscureText: _obscure,
                  enabled: !_isLoading,
                  onChanged: (value) {
                    if (_isHandsUp != null) {
                      _isHandsUp!.change(true);
                    }

                    if (_isChecking != null) {
                      _isChecking!.change(false);
                    }
                  },
                  decoration: InputDecoration(
                    errorText: _passError,
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscure = !_obscure;
                          if (_isHandsUp != null) {
                            _isHandsUp!.change(_obscure);
                          }
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          activeColor: Colors.deepPurple,
                          onChanged: (_isLoading || _isToggleAnimating)
                              ? null
                              : (value) async {
                                  setState(() {
                                    _isToggleAnimating = true;
                                    _rememberMe = value ?? false;
                                  });

                                  await Future.delayed(
                                      const Duration(milliseconds: 300));

                                  if (mounted) {
                                    setState(() {
                                      _isToggleAnimating = false;
                                    });
                                  }
                                },
                        ),
                        const Text('Remember me'),
                      ],
                    ),
                    InkWell(
                      onTap: _isLoading ? null : _showForgotPasswordDialog,
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                MaterialButton(
                  minWidth: size.width,
                  height: 50,
                  color: Colors.deepPurple,
                  disabledColor: Colors.deepPurple.shade200,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onPressed: _isLoading ? null : _onLogin,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: size.width,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      // correctamente con la navegación a SignUpScreen
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SignUpScreen(),
                                  ),
                                );
                              },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Colors.black,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}