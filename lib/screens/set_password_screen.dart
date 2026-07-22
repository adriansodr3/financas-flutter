import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
import '../main.dart' show needsPasswordSetup;
import '../services/db.dart';

class SetPasswordScreen extends StatefulWidget {
  const SetPasswordScreen({super.key});
  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final _passCtrl  = TextEditingController();
  final _pass2Ctrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final pass = _passCtrl.text;
    if (pass.length < 6) {
      setState(() => _error = 'A senha deve ter no mínimo 6 caracteres.');
      return;
    }
    if (pass != _pass2Ctrl.text) {
      setState(() => _error = 'As senhas não coincidem.');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: pass));
      // Criar categorias padrão para o novo usuário
      await DB.seedDefaultCategories();
      // Limpar a flag de convite
      needsPasswordSetup = false;
      // O AuthGate vai detectar a mudança e navegar para o app
      if (mounted) setState(() {});
    } on AuthException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Erro: $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(children: [
            const SizedBox(height: 48),
            // Ícone
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: kGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kGreen.withOpacity(0.5), width: 2)),
              child: const Icon(Icons.lock_open_outlined, color: kGreen, size: 40)),
            const SizedBox(height: 24),
            const Text('Bem-vindo ao\nFinanças Pessoais!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: kText),
              textAlign: TextAlign.center),
            const SizedBox(height: 12),
            const Text(
              'Você recebeu um convite de acesso.\nDefina uma senha para proteger sua conta.',
              style: TextStyle(fontSize: 14, color: kMuted),
              textAlign: TextAlign.center),
            const SizedBox(height: 40),

            // Campo senha
            TextField(
              controller: _passCtrl,
              obscureText: _obscure1,
              decoration: InputDecoration(
                labelText: 'Defina sua senha',
                prefixIcon: const Icon(Icons.lock_outlined, color: kMuted),
                suffixIcon: IconButton(
                  icon: Icon(_obscure1 ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: kMuted),
                  onPressed: () => setState(() => _obscure1 = !_obscure1))),
            ),
            const SizedBox(height: 12),

            // Confirmar senha
            TextField(
              controller: _pass2Ctrl,
              obscureText: _obscure2,
              onSubmitted: (_) => _save(),
              decoration: InputDecoration(
                labelText: 'Confirme sua senha',
                prefixIcon: const Icon(Icons.lock_outline, color: kMuted),
                suffixIcon: IconButton(
                  icon: Icon(_obscure2 ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: kMuted),
                  onPressed: () => setState(() => _obscure2 = !_obscure2))),
            ),
            const SizedBox(height: 8),

            // Dica de senha forte
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kGreen.withOpacity(0.2))),
              child: const Row(children: [
                Icon(Icons.info_outline, color: kGreen, size: 16),
                SizedBox(width: 8),
                Expanded(child: Text(
                  'Use letras, números e símbolos para uma senha mais segura.',
                  style: TextStyle(fontSize: 12, color: kGreen))),
              ]),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kRed.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: kRed, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: const TextStyle(color: kRed, fontSize: 13))),
                ]),
              ),
            ],

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _loading
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Definir senha e entrar',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
