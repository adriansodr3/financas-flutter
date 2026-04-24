import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/other_screens.dart';
import 'screens/extra_screens.dart';
import 'screens/fixed_screen.dart';
import 'screens/investments_screen.dart';

const _supabaseUrl = 'https://cogmxnspkpqycygqlvwu.supabase.co';
const _supabaseKey = 'sb_publishable_mkGB3rnT5Lgrj8i5FEkhYQ_vRTV4r8u';

// Notifier global para tema
final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseKey);
  runApp(const FinancasApp());
}

class FinancasApp extends StatelessWidget {
  const FinancasApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) => MaterialApp(
        title: 'Financas Pessoais',
        theme: appThemeLight(),
        darkTheme: appTheme(),
        themeMode: mode,
        debugShowCheckedModeBanner: false,
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? Supabase.instance.client.auth.currentSession;
        if (session != null) return const _MainShell();
        return const LoginScreen();
      },
    );
  }
}

class _MainShell extends StatefulWidget {
  const _MainShell();
  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  int _idx = 0;

  final _dashKey   = GlobalKey<DashboardScreenState>();
  final _txKey     = GlobalKey<TransactionsScreenState>();
  final _instKey   = GlobalKey<InstallmentsScreenState>();
  final _fixedKey  = GlobalKey<FixedScreenState>();
  final _repKey    = GlobalKey<ReportsScreenState>();
  final _catKey    = GlobalKey<CategoriesScreenState>();
  final _investKey = GlobalKey<InvestmentsScreenState>();
  final _profKey   = GlobalKey<ProfileScreenState>();

  void _onTabChange(int i) {
    setState(() => _idx = i);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      switch (i) {
        case 0: _dashKey.currentState?.load(); break;
        case 1: _txKey.currentState?.load(); break;
        case 2: _instKey.currentState?.load(); break;
        case 3: _fixedKey.currentState?.load(); break;
        case 4: _repKey.currentState?.load(); break;
        case 5: _catKey.currentState?.load(); break;
        case 6: _investKey.currentState?.load(); break;
        case 7: _profKey.currentState?.refresh(); break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      DashboardScreen(key: _dashKey),
      TransactionsScreen(key: _txKey),
      InstallmentsScreen(key: _instKey),
      FixedScreen(key: _fixedKey),
      ReportsScreen(key: _repKey),
      CategoriesScreen(key: _catKey),
      InvestmentsScreen(key: _investKey),
      ProfileScreen(key: _profKey),
    ];

    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _idx, children: screens)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: _onTabChange,
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: kPurple.withOpacity(0.2),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 68,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined),        selectedIcon: Icon(Icons.home),              label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long),      label: 'Lancamentos'),
          NavigationDestination(icon: Icon(Icons.credit_card_outlined),  selectedIcon: Icon(Icons.credit_card),       label: 'Parcelas'),
          NavigationDestination(icon: Icon(Icons.push_pin_outlined),     selectedIcon: Icon(Icons.push_pin),          label: 'Fixos'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined),    selectedIcon: Icon(Icons.bar_chart),         label: 'Relatorios'),
          NavigationDestination(icon: Icon(Icons.label_outline),         selectedIcon: Icon(Icons.label),             label: 'Categorias'),
          NavigationDestination(icon: Icon(Icons.savings_outlined),      selectedIcon: Icon(Icons.savings),           label: 'Investimentos'),
          NavigationDestination(icon: Icon(Icons.person_outline),        selectedIcon: Icon(Icons.person),            label: 'Perfil'),
        ],
      ),
    );
  }
}
