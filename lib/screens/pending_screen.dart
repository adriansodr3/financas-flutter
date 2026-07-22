import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  color: kOrange.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: kOrange.withOpacity(0.4), width: 2)),
                child: const Icon(Icons.hourglass_top_outlined, color: kOrange, size: 44)),
              const SizedBox(height: 28),
              const Text('Aguardando aprovação',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: kText),
                textAlign: TextAlign.center),
              const SizedBox(height: 12),
              const Text(
                'Seu cadastro está em análise.\n\nO administrador será notificado e liberará seu acesso em breve.',
                style: TextStyle(fontSize: 14, color: kMuted, height: 1.5),
                textAlign: TextAlign.center),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBorder)),
                child: const Row(children: [
                  Icon(Icons.info_outline, color: kMuted, size: 18),
                  SizedBox(width: 10),
                  Expanded(child: Text(
                    'Você receberá acesso assim que o administrador aprovar seu cadastro.',
                    style: TextStyle(fontSize: 12, color: kMuted))),
                ])),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                },
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Sair'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: kMuted),
                  foregroundColor: kMuted,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12))),
            ],
          ),
        ),
      ),
    );
  }
}
