import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  bool _isRegister = false;
  bool _loading    = false;
  String? _error;

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
          // Email confirmation required
          setState(() {
            _error = null;
            _loading = false;
          });
          if (mounted) {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: kSurface,
                title: const Text('Confirme seu email',
                    style: TextStyle(color: kText)),
                content: Text(
                  'Enviamos um email de confirmacao para $email.\n\n'
                  'Clique no link do email e depois faca login.',
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
        // Sessao imediata (email confirmation desativado no Supabase)
        if (res.session != null) {
          await _seedAndNavigate();
          return;
        }
      } else {
        final res = await Supabase.instance.client.auth.signInWithPassword(
            email: email, password: pass);
        if (res.session != null) {
          await _seedAndNavigate();
          return;
        }
      }
    } on AuthException catch (e) {
      String msg = e.message;
      if (msg.contains('Invalid login') || msg.contains('invalid_credentials')) {
        msg = 'Email ou senha incorretos.';
      }
      if (msg.contains('already registered') || msg.contains('already been registered')) {
        msg = 'Email ja cadastrado. Faca login.';
      }
      if (msg.contains('Email not confirmed')) {
        msg = 'Email nao confirmado. Verifique sua caixa de entrada.';
      }
      setState(() { _error = msg; });
    } catch (e) {
      setState(() { _error = 'Erro: ${e.toString().substring(0, 80)}'; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _seedAndNavigate() async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid != null) {
        await DB.seedDefaultCategories();
      }
    } catch (_) {
      // Seed falhou — nao e critico, usuario pode criar categorias depois
    }
    // Navegacao feita pelo AuthGate automaticamente
  }

  Future<void> _resetPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Digite seu email primeiro.');
      return;
    }
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email de recuperacao enviado!')));
      }
    } catch (e) {
      setState(() => _error = 'Erro ao enviar email.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
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
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: kText)),
              const SizedBox(height: 4),
              const Text('Controle financeiro com sync em nuvem',
                  style: TextStyle(fontSize: 13, color: kMuted)),
              const SizedBox(height: 40),

              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined, color: kMuted),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: Icon(Icons.lock_outlined, color: kMuted),
                ),
              ),

              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                child: _isRegister
                    ? Column(children: [
                        const SizedBox(height: 12),
                        TextField(
                          controller: _pass2Ctrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Confirmar Senha',
                            prefixIcon: Icon(Icons.lock_outline, color: kMuted),
                          ),
                        ),
                      ])
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 8),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_error!,
                      style: const TextStyle(color: kRed, fontSize: 13),
                      textAlign: TextAlign.center),
                ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(_isRegister ? 'Criar Conta' : 'Entrar',
                          style: const TextStyle(fontSize: 15)),
                ),
              ),

              const SizedBox(height: 12),

              if (!_isRegister)
                TextButton(
                  onPressed: _resetPassword,
                  child: const Text('Esqueci minha senha',
                      style: TextStyle(color: kMuted)),
                ),

              TextButton(
                onPressed: () => setState(() {
                  _isRegister = !_isRegister;
                  _error = null;
                }),
                child: Text(
                  _isRegister ? 'Ja tenho conta' : 'Criar nova conta',
                  style: const TextStyle(color: kPurple),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
