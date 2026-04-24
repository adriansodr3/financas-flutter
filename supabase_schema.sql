-- =============================================
-- FINANCAS PESSOAIS - Supabase Schema
-- Cole este SQL no Supabase SQL Editor e execute
-- =============================================

-- Habilitar RLS em todas as tabelas (segurança por usuario)

CREATE TABLE IF NOT EXISTS categories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  type TEXT NOT NULL CHECK(type IN ('income','expense')),
  color TEXT DEFAULT '#6366f1',
  icon TEXT DEFAULT 'attach_money',
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, name, type)
);

CREATE TABLE IF NOT EXISTS transactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  type TEXT NOT NULL CHECK(type IN ('income','expense')),
  amount NUMERIC(12,2) NOT NULL,
  description TEXT,
  date DATE NOT NULL,
  is_fixed BOOLEAN DEFAULT false,
  fixed_expense_id UUID,
  installment_id UUID,
  installment_number INTEGER,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS fixed_expenses (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  type TEXT NOT NULL CHECK(type IN ('income','expense')),
  amount NUMERIC(12,2) NOT NULL,
  description TEXT NOT NULL,
  active BOOLEAN DEFAULT true,
  valid_from DATE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS fixed_skipped (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  fixed_expense_id UUID REFERENCES fixed_expenses(id) ON DELETE CASCADE NOT NULL,
  month TEXT NOT NULL, -- formato YYYY-MM
  UNIQUE(user_id, fixed_expense_id, month)
);

CREATE TABLE IF NOT EXISTS installments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  description TEXT NOT NULL,
  total_amount NUMERIC(12,2) NOT NULL,
  installment_amount NUMERIC(12,2) NOT NULL,
  total_parcelas INTEGER NOT NULL,
  start_date DATE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- =============================================
-- RLS POLICIES (segurança: cada user ve só os seus dados)
-- =============================================

ALTER TABLE categories      ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions    ENABLE ROW LEVEL SECURITY;
ALTER TABLE fixed_expenses  ENABLE ROW LEVEL SECURITY;
ALTER TABLE fixed_skipped   ENABLE ROW LEVEL SECURITY;
ALTER TABLE installments    ENABLE ROW LEVEL SECURITY;

-- Categories
CREATE POLICY "user_own_categories" ON categories
  FOR ALL USING (auth.uid() = user_id);

-- Transactions
CREATE POLICY "user_own_transactions" ON transactions
  FOR ALL USING (auth.uid() = user_id);

-- Fixed expenses
CREATE POLICY "user_own_fixed" ON fixed_expenses
  FOR ALL USING (auth.uid() = user_id);

-- Fixed skipped
CREATE POLICY "user_own_skipped" ON fixed_skipped
  FOR ALL USING (auth.uid() = user_id);

-- Installments
CREATE POLICY "user_own_installments" ON installments
  FOR ALL USING (auth.uid() = user_id);

-- =============================================
-- INDEXES para performance
-- =============================================

CREATE INDEX IF NOT EXISTS idx_transactions_user_date
  ON transactions(user_id, date);

CREATE INDEX IF NOT EXISTS idx_transactions_fixed
  ON transactions(fixed_expense_id) WHERE is_fixed = true;

CREATE INDEX IF NOT EXISTS idx_transactions_installment
  ON transactions(installment_id) WHERE installment_id IS NOT NULL;
