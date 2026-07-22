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

  // Para fluxo de convite: token recebido via URL
  bool _isInvite = false;
  String? _inviteToken;

  @override
  void initState() {
    super.initState();
    _checkInviteToken();
  }

  void _checkInviteToken() {
    // Na web, verificar se há token de convite na URL
    try {
      final uri = Uri.base;
      final token = uri.queryParameters['token'] ??
                    uri.fragment.split('&').firstWhere(
                      (p) => p.startsWith('access_token='),
                      orElse: () => '').replaceFirst('access_token=', '');
      final type  = uri.queryParameters['type'] ??
                    uri.fragment.split('&').firstWhere(
                      (p) => p.startsWith('type='),
                      orElse: () => '').replaceFirst('type=', '');

      if (type == 'invite' && token.isNotEmpty) {
        setState(() { _isInvite = true; _inviteToken = token; });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _submitInvite() async {
    if (_passCtrl.text != _pass2Ctrl.text) {
      setState(() => _error = 'Senhas não coincidem.');
      return;
    }
    if (_passCtrl.text.length < 6) {
      setState(() => _error = 'Mínimo 6 caracteres.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      // Verificar o token de convite e definir nova senha
      await Supabase.instance.client.auth.verifyOTP(
        token: _inviteToken!,
        type: OtpType.invite,
      );
      // Agora definir a senha
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _passCtrl.text));
      await DB.seedDefaultCategories();
    } on AuthException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Erro: $e'; _loading = false; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
          setState(() { _error = 'Senhas não coincidem.'; _loading = false; });
          return;
        }
        if (pass.length < 6) {
          setState(() { _error = 'Mínimo 6 caracteres.'; _loading = false; });
          return;
        }
        final res = await Supabase.instance.client.auth.signUp(
            email: email, password: pass);
        if (res.session == null && res.user != null) {
          if (mounted) showDialog(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: kSurface,
              title: const Text('Confirme seu email', style: TextStyle(color: kText)),
              content: Text('Enviamos um email de confirmação para $email.\n\nClique no link e depois faça login.',
                  style: const TextStyle(color: kMuted)),
              actions: [TextButton(
                onPressed: () { Navigator.pop(context); setState(() => _isRegister = false); },
                child: const Text('OK', style: TextStyle(color: kPurple)))],
            ),
          );
          return;
        }
        if (res.session != null) await DB.seedDefaultCategories();
      } else {
        await Supabase.instance.client.auth.signInWithPassword(
            email: email, password: pass);
      }
    } on AuthException catch (e) {
      String msg = e.message;
      if (msg.contains('Invalid login') || msg.contains('invalid_credentials'))
        msg = 'Email ou senha incorretos.';
      if (msg.contains('already registered') || msg.contains('already been registered'))
        msg = 'Email já cadastrado. Faça login.';
      if (msg.contains('Email not confirmed'))
        msg = 'Email não confirmado. Verifique sua caixa de entrada.';
      setState(() => _error = msg);
    } catch (e) {
      setState(() => _error = 'Erro: ${e.toString().substring(0, 80)}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tela de definir senha (fluxo de convite)
    if (_isInvite) return _buildInviteScreen();
    return _buildLoginScreen();
  }

  Widget _buildInviteScreen() {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(children: [
            const SizedBox(height: 48),
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: kGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kGreen.withOpacity(0.4))),
              child: const Icon(Icons.lock_open_outlined, color: kGreen, size: 36)),
            const SizedBox(height: 20),
            const Text('Bem-vindo ao Finanças Pessoais!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: kText),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text('Você recebeu um convite.\nDefina sua senha para acessar o app.',
                style: TextStyle(fontSize: 13, color: kMuted),
                textAlign: TextAlign.center),
            const SizedBox(height: 40),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nova senha',
                prefixIcon: Icon(Icons.lock_outlined, color: kMuted)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pass2Ctrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmar senha',
                prefixIcon: Icon(Icons.lock_outline, color: kMuted)),
            ),
            const SizedBox(height: 8),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!,
                    style: const TextStyle(color: kRed, fontSize: 13),
                    textAlign: TextAlign.center)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submitInvite,
                style: ElevatedButton.styleFrom(backgroundColor: kGreen),
                child: _loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Definir senha e entrar', style: TextStyle(fontSize: 15)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildLoginScreen() {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(children: [
            const SizedBox(height: 48),
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: kPurple.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kPurple.withOpacity(0.4))),
              child: const Icon(Icons.account_balance_wallet_outlined, color: kPurple, size: 36)),
            const SizedBox(height: 20),
            const Text('Finanças Pessoais',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: kText)),
            const SizedBox(height: 4),
            const Text('Controle financeiro com sync em nuvem',
                style: TextStyle(fontSize: 13, color: kMuted)),
            const SizedBox(height: 40),
            AutofillGroup(child: Column(children: [
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined, color: kMuted)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: Icon(Icons.lock_outlined, color: kMuted)),
              ),
            ])),
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
                          prefixIcon: Icon(Icons.lock_outline, color: kMuted)),
                      ),
                    ])
                  : const SizedBox.shrink()),
            const SizedBox(height: 8),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!,
                    style: const TextStyle(color: kRed, fontSize: 13),
                    textAlign: TextAlign.center)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_isRegister ? 'Criar Conta' : 'Entrar',
                        style: const TextStyle(fontSize: 15)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() { _isRegister = !_isRegister; _error = null; }),
              child: Text(
                _isRegister ? 'Já tenho conta' : 'Criar nova conta',
                style: const TextStyle(color: kPurple)),
            ),
          ]),
        ),
      ),
    );
  }
}
