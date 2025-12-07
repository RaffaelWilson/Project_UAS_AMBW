-- ============================================
-- SETUP DATABASE SUPABASE
-- Sparepart Motor Application
-- ============================================

-- 1. BUAT TABEL SPAREPARTS
CREATE TABLE IF NOT EXISTS spareparts (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  price NUMERIC NOT NULL,
  stock INTEGER NOT NULL DEFAULT 0,
  image_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. BUAT TABEL ORDERS
CREATE TABLE IF NOT EXISTS orders (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  total NUMERIC NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'shipped', 'completed', 'cancelled')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. BUAT TABEL ORDER_ITEMS
CREATE TABLE IF NOT EXISTS order_items (
  id BIGSERIAL PRIMARY KEY,
  order_id BIGINT REFERENCES orders(id) ON DELETE CASCADE,
  sparepart_id BIGINT REFERENCES spareparts(id),
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. ENABLE ROW LEVEL SECURITY
ALTER TABLE spareparts ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

-- 5. POLICIES UNTUK SPAREPARTS
-- Semua orang bisa melihat spareparts
CREATE POLICY "Spareparts are viewable by everyone" 
ON spareparts FOR SELECT 
USING (true);

-- Hanya authenticated users yang bisa insert
CREATE POLICY "Authenticated users can insert spareparts" 
ON spareparts FOR INSERT 
WITH CHECK (auth.role() = 'authenticated');

-- Hanya authenticated users yang bisa update
CREATE POLICY "Authenticated users can update spareparts" 
ON spareparts FOR UPDATE 
USING (auth.role() = 'authenticated');

-- Hanya authenticated users yang bisa delete
CREATE POLICY "Authenticated users can delete spareparts" 
ON spareparts FOR DELETE 
USING (auth.role() = 'authenticated');

-- 6. POLICIES UNTUK ORDERS
-- User hanya bisa melihat order mereka sendiri
CREATE POLICY "Users can view their own orders" 
ON orders FOR SELECT 
USING (auth.uid() = user_id);

-- User hanya bisa membuat order untuk diri sendiri
CREATE POLICY "Users can insert their own orders" 
ON orders FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- User bisa update order mereka sendiri
CREATE POLICY "Users can update their own orders" 
ON orders FOR UPDATE 
USING (auth.uid() = user_id);

-- 7. POLICIES UNTUK ORDER_ITEMS
-- Semua authenticated users bisa melihat order items
CREATE POLICY "Authenticated users can view order items" 
ON order_items FOR SELECT 
USING (auth.role() = 'authenticated');

-- Authenticated users bisa insert order items
CREATE POLICY "Authenticated users can insert order items" 
ON order_items FOR INSERT 
WITH CHECK (auth.role() = 'authenticated');

-- 8. CREATE INDEXES UNTUK PERFORMA
CREATE INDEX IF NOT EXISTS idx_spareparts_name ON spareparts(name);
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_sparepart_id ON order_items(sparepart_id);

-- 9. INSERT DATA SAMPLE (OPSIONAL)
INSERT INTO spareparts (name, description, price, stock, image_url) VALUES
('Oli Mesin Yamalube 1L', 'Oli mesin berkualitas tinggi untuk motor Yamaha, melindungi mesin dari keausan', 45000, 50, null),
('Ban Depan IRC 80/90-17', 'Ban depan ukuran standar untuk motor bebek dan sport, grip maksimal', 250000, 20, null),
('Kampas Rem Depan', 'Kampas rem depan original, daya cengkram kuat dan tahan lama', 75000, 30, null),
('Busi NGK Iridium', 'Busi NGK iridium untuk performa mesin optimal dan hemat bahan bakar', 35000, 100, null),
('Filter Udara Racing', 'Filter udara racing untuk meningkatkan performa mesin', 85000, 25, null),
('Rantai RK 428', 'Rantai motor RK 428 kualitas premium, tahan lama', 180000, 15, null),
('Gear Set Depan Belakang', 'Gear set depan belakang untuk akselerasi lebih responsif', 120000, 40, null),
('Kampas Kopling', 'Kampas kopling original untuk transmisi halus', 95000, 35, null),
('Shockbreaker Belakang', 'Shockbreaker belakang untuk kenyamanan berkendara', 450000, 10, null),
('Lampu LED Headlight', 'Lampu LED headlight super terang, hemat energi', 150000, 25, null);

-- 10. CREATE FUNCTION UNTUK UPDATE STOCK OTOMATIS
CREATE OR REPLACE FUNCTION update_stock_after_order()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE spareparts 
  SET stock = stock - NEW.quantity 
  WHERE id = NEW.sparepart_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 11. CREATE TRIGGER
CREATE TRIGGER trigger_update_stock
AFTER INSERT ON order_items
FOR EACH ROW
EXECUTE FUNCTION update_stock_after_order();

-- ============================================
-- STORAGE SETUP (Jalankan di Storage Policies)
-- ============================================

-- Policy untuk public access (SELECT)
-- CREATE POLICY "Public Access"
-- ON storage.objects FOR SELECT
-- USING ( bucket_id = 'spareparts' );

-- Policy untuk authenticated users upload
-- CREATE POLICY "Authenticated users can upload"
-- ON storage.objects FOR INSERT
-- WITH CHECK ( bucket_id = 'spareparts' AND auth.role() = 'authenticated' );

-- Policy untuk authenticated users delete
-- CREATE POLICY "Authenticated users can delete"
-- ON storage.objects FOR DELETE
-- USING ( bucket_id = 'spareparts' AND auth.role() = 'authenticated' );

-- ============================================
-- SELESAI
-- ============================================
