-- ============================================================================
-- Sales Manager Cloud Schema — Supabase PostgreSQL
-- Offline-First Mirror for Drift Local DB with UUIDs & Audit Trails
-- ============================================================================

-- 1. Enable UUID Extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Products Table
CREATE TABLE IF NOT EXISTS public.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT UNIQUE,
    name TEXT NOT NULL,
    unit TEXT NOT NULL,
    current_sale_price BIGINT NOT NULL, -- بالقرش
    current_purchase_price BIGINT NOT NULL, -- بالقرش
    current_quantity NUMERIC(15, 4) NOT NULL DEFAULT 0,
    low_stock_threshold NUMERIC(15, 4),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by TEXT DEFAULT 'admin'
);

-- 3. Stakeholders (Customers & Suppliers)
CREATE TABLE IF NOT EXISTS public.customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    phone TEXT,
    address TEXT,
    notes TEXT,
    current_balance BIGINT NOT NULL DEFAULT 0, -- بالقرش
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by TEXT DEFAULT 'admin'
);

CREATE TABLE IF NOT EXISTS public.suppliers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    phone TEXT,
    address TEXT,
    notes TEXT,
    current_balance BIGINT NOT NULL DEFAULT 0, -- بالقرش
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by TEXT DEFAULT 'admin'
);

-- 4. Sales & Sale Items
CREATE TABLE IF NOT EXISTS public.sales (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_no BIGINT NOT NULL,
    invoice_code TEXT, -- e.g. "INV-POS1-001"
    customer_id UUID NOT NULL REFERENCES public.customers(id),
    sale_date TIMESTAMPTZ NOT NULL,
    total_amount BIGINT NOT NULL, -- بالقرش
    paid_amount_at_creation BIGINT NOT NULL, -- بالقرش
    status TEXT NOT NULL DEFAULT 'confirmed', -- confirmed, reversed
    note TEXT,
    device_id TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by TEXT DEFAULT 'admin'
);

CREATE TABLE IF NOT EXISTS public.sale_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sale_id UUID NOT NULL REFERENCES public.sales(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id),
    quantity NUMERIC(15, 4) NOT NULL,
    unit_price_at_sale BIGINT NOT NULL, -- Snapshot بالقرش
    line_total BIGINT NOT NULL, -- بالقرش
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 5. Purchases & Purchase Items
CREATE TABLE IF NOT EXISTS public.purchases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_no BIGINT NOT NULL,
    invoice_code TEXT,
    supplier_id UUID NOT NULL REFERENCES public.suppliers(id),
    purchase_date TIMESTAMPTZ NOT NULL,
    total_amount BIGINT NOT NULL, -- بالقرش
    paid_amount_at_creation BIGINT NOT NULL, -- بالقرش
    status TEXT NOT NULL DEFAULT 'confirmed', -- confirmed, reversed
    note TEXT,
    device_id TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by TEXT DEFAULT 'admin'
);

CREATE TABLE IF NOT EXISTS public.purchase_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    purchase_id UUID NOT NULL REFERENCES public.purchases(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id),
    quantity NUMERIC(15, 4) NOT NULL,
    unit_cost_at_purchase BIGINT NOT NULL, -- Snapshot بالقرش
    line_total BIGINT NOT NULL, -- بالقرش
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 6. Payments (Customer & Supplier)
CREATE TABLE IF NOT EXISTS public.customer_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES public.customers(id),
    amount BIGINT NOT NULL, -- بالقرش
    payment_date TIMESTAMPTZ NOT NULL,
    linked_sale_id UUID REFERENCES public.sales(id),
    note TEXT,
    device_id TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by TEXT DEFAULT 'admin'
);

CREATE TABLE IF NOT EXISTS public.supplier_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    supplier_id UUID NOT NULL REFERENCES public.suppliers(id),
    amount BIGINT NOT NULL, -- بالقرش
    payment_date TIMESTAMPTZ NOT NULL,
    linked_purchase_id UUID REFERENCES public.purchases(id),
    note TEXT,
    device_id TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by TEXT DEFAULT 'admin'
);

-- 7. Cashbox & Expenses
CREATE TABLE IF NOT EXISTS public.cashbox_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_type TEXT NOT NULL,
    amount BIGINT NOT NULL, -- بالقرش موجب دائماً
    direction TEXT NOT NULL, -- in, out
    balance_after BIGINT NOT NULL,
    reference_type TEXT,
    reference_id UUID,
    note TEXT,
    device_id TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by TEXT DEFAULT 'admin'
);

CREATE TABLE IF NOT EXISTS public.expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category TEXT NOT NULL,
    amount BIGINT NOT NULL, -- بالقرش
    expense_date TIMESTAMPTZ NOT NULL,
    note TEXT,
    device_id TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by TEXT DEFAULT 'admin'
);

-- 8. Inventory Ledger & Adjustments
CREATE TABLE IF NOT EXISTS public.inventory_movements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES public.products(id),
    movement_type TEXT NOT NULL,
    quantity_delta NUMERIC(15, 4) NOT NULL,
    balance_after NUMERIC(15, 4) NOT NULL,
    reference_type TEXT,
    reference_id UUID,
    note TEXT,
    device_id TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by TEXT DEFAULT 'admin'
);

CREATE TABLE IF NOT EXISTS public.stock_adjustments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES public.products(id),
    quantity_delta NUMERIC(15, 4) NOT NULL,
    reason TEXT NOT NULL,
    adjustment_date TIMESTAMPTZ NOT NULL,
    device_id TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by TEXT DEFAULT 'admin'
);

-- 9. Ledgers (Customer & Supplier)
CREATE TABLE IF NOT EXISTS public.customer_ledger_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES public.customers(id),
    entry_type TEXT NOT NULL,
    amount BIGINT NOT NULL,
    effect TEXT NOT NULL, -- increase, decrease
    balance_after BIGINT NOT NULL,
    reference_type TEXT,
    reference_id UUID,
    note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by TEXT DEFAULT 'admin'
);

CREATE TABLE IF NOT EXISTS public.supplier_ledger_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    supplier_id UUID NOT NULL REFERENCES public.suppliers(id),
    entry_type TEXT NOT NULL,
    amount BIGINT NOT NULL,
    effect TEXT NOT NULL, -- increase, decrease
    balance_after BIGINT NOT NULL,
    reference_type TEXT,
    reference_id UUID,
    note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by TEXT DEFAULT 'admin'
);

-- 10. Returns (Customer & Supplier)
CREATE TABLE IF NOT EXISTS public.returns_customer (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    original_sale_id UUID REFERENCES public.sales(id),
    customer_id UUID NOT NULL REFERENCES public.customers(id),
    return_date TIMESTAMPTZ NOT NULL,
    total_amount BIGINT NOT NULL, -- بالقرش
    note TEXT,
    device_id TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by TEXT DEFAULT 'admin'
);

CREATE TABLE IF NOT EXISTS public.return_customer_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    return_id UUID NOT NULL REFERENCES public.returns_customer(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id),
    quantity NUMERIC(15, 4) NOT NULL,
    unit_price BIGINT NOT NULL, -- بالقرش
    line_total BIGINT NOT NULL, -- بالقرش
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.returns_supplier (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    original_purchase_id UUID REFERENCES public.purchases(id),
    supplier_id UUID NOT NULL REFERENCES public.suppliers(id),
    return_date TIMESTAMPTZ NOT NULL,
    total_amount BIGINT NOT NULL, -- بالقرش
    note TEXT,
    device_id TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by TEXT DEFAULT 'admin'
);

CREATE TABLE IF NOT EXISTS public.return_supplier_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    return_id UUID NOT NULL REFERENCES public.returns_supplier(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id),
    quantity NUMERIC(15, 4) NOT NULL,
    unit_price BIGINT NOT NULL, -- بالقرش
    line_total BIGINT NOT NULL, -- بالقرش
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 11. Audit Log & Settings
CREATE TABLE IF NOT EXISTS public.audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type TEXT NOT NULL,
    entity_id UUID NOT NULL,
    action TEXT NOT NULL,
    payload_before JSONB,
    payload_after JSONB,
    performed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    note TEXT,
    user_id TEXT DEFAULT 'admin'
);

-- 12. Sync Batches Tracking Table
CREATE TABLE IF NOT EXISTS public.sync_batches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id TEXT NOT NULL,
    batch_size INT NOT NULL,
    synced_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    status TEXT NOT NULL DEFAULT 'completed'
);

-- 13. Automated Updated_at Trigger Function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
    t text;
BEGIN
    FOR t IN SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename IN (
        'products', 'customers', 'suppliers', 'sales', 'purchases', 
        'customer_payments', 'supplier_payments', 'cashbox_transactions', 'expenses',
        'returns_customer', 'returns_supplier'
    )
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS trg_set_updated_at ON %I;', t);
        EXECUTE format('CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();', t);
    END LOOP;
END;
$$;

-- 14. Enable Row Level Security (RLS) on all tables
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sale_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchase_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customer_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.supplier_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cashbox_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock_adjustments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customer_ledger_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.supplier_ledger_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.returns_customer ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.return_customer_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.returns_supplier ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.return_supplier_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sync_batches ENABLE ROW LEVEL SECURITY;

-- Allow anon and authenticated full access for POS client operations
DO $$
DECLARE
    t text;
BEGIN
    FOR t IN SELECT tablename FROM pg_tables WHERE schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS "Allow all for authenticated/anon" ON %I;', t);
        EXECUTE format('CREATE POLICY "Allow all for authenticated/anon" ON %I FOR ALL USING (true) WITH CHECK (true);', t);
    END LOOP;
END;
$$;
