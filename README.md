# Financas Pessoais 2.0 — Flutter + Supabase

## Por que Flutter?
- Compilado para ARM nativo → sem lentidão com muitos dados
- ListView.builder → renderiza lazy, performance constante
- Material Design 3 embutido
- Build APK em 5 minutos (vs 40 min do Kivy)

## Por que Supabase?
- Dados sincronizados entre todos os seus dispositivos
- Login com email/senha (esquecer senha funciona!)
- PostgreSQL com Row Level Security (cada usuário vê só os seus dados)
- Free tier: 500MB banco + 1GB storage (suficiente para anos de uso)

---

## SETUP — Passo a Passo

### 1. Criar conta Supabase (gratuito)
1. Acesse **supabase.com** → Sign Up
2. Crie um novo projeto (escolha região South America - São Paulo)
3. Anote a **URL** e a **anon key** (em Settings → API)

### 2. Criar as tabelas
1. No Supabase → **SQL Editor**
2. Cole o conteúdo do arquivo `supabase_schema.sql`
3. Clique em **Run**

### 3. Configurar o app
Abra `lib/main.dart` e substitua:
```dart
const _supabaseUrl = 'https://SEU_PROJETO.supabase.co';
const _supabaseKey = 'SUA_ANON_KEY';
```

### 4. Criar repositório no GitHub
1. github.com → New repository → `financas-flutter` → Public → Create
2. Faça upload de todos estes arquivos

### 5. Gerar o APK
1. Aba **Actions** → **Build APK Flutter** → **Run workflow**
2. Aguarde **~5 minutos** (muito mais rápido que antes!)
3. Baixe o `FinancasPessoais-Flutter-APK`
4. Instale o `app-arm64-v8a-release.apk` (para aparelhos modernos)

---

## Funcionalidades

### Dashboard
- Cards: Entradas+Saldo Ant., Saídas, Saldo, Fixos, Falta Pagar
- Navegação por mês com swipe
- Lista lazy (rápida com muitos dados)
- Pull-to-refresh

### Lançamentos
- Criar, editar e excluir
- Editar fixo só no mês selecionado
- Excluir parcela individual

### Parcelamentos
- Criar com data de início livre
- Ver pago vs falta pagar
- Quitar (com undo via SnackBar)
- Cancelar tudo

### Fixos
- Materializados automaticamente todo mês
- Excluir/pular mês específico
- Desativar definitivamente

### Relatórios
- Gráfico de pizza por categoria (fl_chart)
- Barras de progresso
- Toggle despesas/entradas

### Categorias
- CRUD completo
- Grid de ícones Material Design
- Cores automáticas por tipo

### Perfil
- Email da conta
- Alterar senha
- Recuperar senha por email
- Logout (dados ficam na nuvem)

### Sync em nuvem
- Login em qualquer dispositivo → dados sincronizados
- Funciona offline (Supabase cache local)
- Sem limite de dispositivos

---

## Arquitetura

```
lib/
├── main.dart              # Entry point + auth gate + navegação
├── theme.dart             # Design tokens, cores, fontes
├── models/
│   └── models.dart        # Category, Transaction, FixedExpense, Installment
├── services/
│   └── db.dart            # Toda lógica de dados (Supabase)
├── widgets/
│   └── widgets.dart       # SummaryCard, TxTile, MonthNav, confirmSheet...
└── screens/
    ├── login_screen.dart       # Login + cadastro + recuperar senha
    ├── dashboard_screen.dart   # Dashboard principal
    ├── tx_form_sheet.dart      # Formulário criar/editar lançamento
    ├── tx_action_sheet.dart    # Ações no lançamento (editar/excluir)
    ├── other_screens.dart      # Lançamentos, Fixos, Parcelamentos
    └── extra_screens.dart      # Relatórios, Categorias, Perfil
```
