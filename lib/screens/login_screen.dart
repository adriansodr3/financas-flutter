import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import '../services/db.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _pass2Ctrl = TextEditingController();
  bool _isRegister   = false;
  bool _loading      = false;
  bool _rememberMe   = true;
  bool _obscurePass  = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('saved_email') ?? '';
    if (saved.isNotEmpty) {
      setState(() {
        _emailCtrl.text = saved;
        _rememberMe = true;
      });
    }
  }

  Future<void> _saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('saved_email', email);
    } else {
      await prefs.remove('saved_email');
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    final email = _emailCtrl.text.trim();
    final pass  = _passCtrl.text;

    if (email.isEmpty || pass.isEmpty) {
      setState(() { _error = 'Preencha todos os campos.'; _loading = false; });
      return;
    }

    try {
      if (_isRegister) {
        if (pass != _pass2Ctrl.text) {
          setState(() { _error = 'Senhas nao coincidem.'; _loading = false; });
          return;
        }
        if (pass.length < 6) {
          setState(() { _error = 'Minimo 6 caracteres.'; _loading = false; });
          return;
        }
        final res = await Supabase.instance.client.auth.signUp(
            email: email, password: pass);

        if (res.session == null && res.user != null) {
          setState(() { _loading = false; });
          if (mounted) {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: kSurface,
                title: const Text('Confirme seu email',
                    style: TextStyle(color: kText)),
                content: Text(
                  'Enviamos um email de confirmacao para $email.\n\nClique no link e faca login.',
                  style: const TextStyle(color: kMuted)),
                actions: [TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() => _isRegister = false);
                  },
                  child: const Text('OK', style: TextStyle(color: kPurple)),
                )],
              ),
            );
          }
          return;
        }
        if (res.session != null) {
          await _saveEmail(email);
          await _seedSafe();
          return;
        }
      } else {
        await Supabase.instance.client.auth.signInWithPassword(
            email: email, password: pass);
        await _saveEmail(email);
        await _seedSafe();
        return;
      }
    } on AuthException catch (e) {
      String msg = e.message;
      if (msg.contains('Invalid login') || msg.contains('invalid_credentials')) {
        msg = 'Email ou senha incorretos.';
      }
      if (msg.contains('already registered')) msg = 'Email ja cadastrado. Faca login.';
      if (msg.contains('Email not confirmed')) msg = 'Confirme seu email antes de entrar.';
      setState(() { _error = msg; });
    } catch (e) {
      setState(() { _error = 'Erro de conexao. Tente novamente.'; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _seedSafe() async {
    try { await DB.seedDefaultCategories(); } catch (_) {}
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 48),
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: kPurple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kPurple.withOpacity(0.4)),
                ),
                child: const Icon(Icons.account_balance_wallet_outlined,
                    color: kPurple, size: 36),
              ),
              const SizedBox(height: 20),
              const Text('Financas Pessoais',
                  style: TextStyle(fontSize: 26,
                      fontWeight: FontWeight.w700, color: kText)),
              const SizedBox(height: 4),
              const Text('Controle financeiro com sync em nuvem',
                  style: TextStyle(fontSize: 13, color: kMuted)),
              const SizedBox(height: 40),

              // Email
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined, color: kMuted),
                ),
              ),
              const SizedBox(height: 12),

              // Senha
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscurePass,
                autofillHints: const [AutofillHints.password],
                decoration: InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: const Icon(Icons.lock_outlined, color: kMuted),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePass ? Icons.visibility_outlined
                                   : Icons.visibility_off_outlined,
                      color: kMuted),
                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
              ),

              // Confirmar senha (cadastro)
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                child: _isRegister
                    ? Column(children: [
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _pass2Ctrl,
                          obscureText: true,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: const InputDecoration(
                            labelText: 'Confirmar Senha',
                            prefixIcon: Icon(Icons.lock_outline, color: kMuted),
                          ),
                        ),
                      ])
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 4),

              // Lembrar email
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (v) => setState(() => _rememberMe = v ?? true),
                    activeColor: kPurple,
                    side: const BorderSide(color: kMuted),
                  ),
                  const Text('Lembrar email',
                      style: TextStyle(color: kMuted, fontSize: 13)),
                ],
              ),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_error!,
                      style: const TextStyle(color: kRed, fontSize: 13),
                      textAlign: TextAlign.center),
                ),

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(_isRegister ? 'Criar Conta' : 'Entrar',
                          style: const TextStyle(fontSize: 15)),
                ),
              ),

              const SizedBox(height: 8),

              TextButton(
                onPressed: () => setState(() {
                  _isRegister = !_isRegister; _error = null;
                }),
                child: Text(
                  _isRegister ? 'Ja tenho conta' : 'Criar nova conta',
                  style: const TextStyle(color: kPurple)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
