-- ==========================================================
-- PROJECT: E-Commerce Performance & User Behavior Analysis
-- DESCRIPTION: User Segmentation (Dropshipper/Reseller) & Trends
-- DATABASE: MySQL (DQLab Store Dataset)
-- ==========================================================

-- ----------------------------------------------------------
-- 1. Store Performance & Trends
-- ----------------------------------------------------------

-- A. Monthly Sales Trend (2020)
-- Objective: Calculate monthly transaction volume and gross revenue growth for H1 2020.
SELECT 
    EXTRACT(YEAR_MONTH FROM created_at) as tahun_bulan, 
    count(1) as jumlah_transaksi, 
    sum(total) as total_nilai_transaksi
FROM orders
WHERE created_at >= '2020-01-01'
GROUP BY 1
ORDER BY 1;

-- B. Peak Season Anomaly (Dec 2019)
-- Objective: Identify high-value transactions (> 20 Million IDR) during the year-end period.
SELECT 
    u.nama_user AS nama_pembeli, 
    o.total AS nilai_transaksi, 
    o.created_at AS tanggal_transaksi
FROM orders o
JOIN users u ON o.buyer_id = u.user_id
WHERE o.created_at BETWEEN '2019-12-01' AND '2019-12-31'
AND o.total >= 20000000
ORDER BY 1 ASC;

-- C. Top Performing Categories (2020)
-- Objective: Rank the top 5 product categories by sales volume for delivered orders.
SELECT 
    category, 
    sum(quantity) as total_quantity, 
    sum(quantity*price) as total_price
FROM orders
INNER JOIN order_details using(order_id)
INNER JOIN products using(product_id)
WHERE created_at >= '2020-01-01'
AND delivery_at IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;


-- ----------------------------------------------------------
-- 2. User Ecosystem & Segmentation
-- ----------------------------------------------------------

-- A. Identifying Dropshippers (Pattern Detection)
-- Objective: Find users whose transaction count equals their distinct shipping address count (1:1 Ratio).
SELECT
    nama_user as nama_pembeli,
    count(1) as jumlah_transaksi, 
    count(distinct orders.kodepos) as distinct_kodepos,
    sum(total) as total_nilai_transaksi, 
    avg(total) as avg_nilai_transaksi
FROM orders 
INNER JOIN users ON buyer_id = user_id 
GROUP BY user_id, nama_user
HAVING count(1) >= 10 
AND count(1) = count(distinct orders.kodepos)
ORDER BY 2 DESC;

-- B. Identifying Offline Resellers (Inventory Stocking)
-- Objective: Find users with high volume, bulk quantity, and consistent shipping addresses.
SELECT
    nama_user as nama_pembeli,
    count(1) as jumlah_transaksi, 
    sum(total) as total_nilai_transaksi, 
    avg(total) as avg_nilai_transaksi,
    avg(total_quantity) as avg_quantity_per_transaksi
FROM orders 
INNER JOIN users ON buyer_id = user_id 
INNER JOIN (
    SELECT order_id, sum(quantity) as total_quantity 
    FROM order_details 
    GROUP BY 1
) as summary_order USING(order_id)
WHERE orders.kodepos = users.kodepos
GROUP BY user_id, nama_user
HAVING count(1) >= 8 
AND avg(total_quantity) > 10
ORDER BY 3 DESC;

-- C. Hybrid User Analysis (Buyer-Seller Ecosystem)
-- Objective: Identify 'Power Sellers' who also actively participate as buyers (Min. 7 purchases).
SELECT
    nama_user as nama_pengguna,
    jumlah_transaksi_beli,
    jumlah_transaksi_jual
FROM users 
INNER JOIN (
    SELECT buyer_id, count(1) as jumlah_transaksi_beli
    FROM orders group by 1
) as buyer ON buyer_id = user_id
INNER JOIN (
    SELECT seller_id, count(1) as jumlah_transaksi_jual
    FROM orders group by 1
) as seller ON seller_id = user_id
WHERE jumlah_transaksi_beli >= 7
ORDER BY 1;

-- D. High-Value Customer Segmentation (VIPs)
-- Objective: Filter for loyalists with >5 transactions where EVERY transaction exceeds 2 Million IDR.
SELECT
    nama_user as nama_pembeli,
    count(1) as jumlah_transaksi, 
    sum(total) as total_nilai_transaksi, 
    min(total) as min_nilai_transaksi
FROM orders 
INNER JOIN users ON buyer_id = user_id 
GROUP BY user_id, nama_user
HAVING count(1) > 5 
AND min(total) > 2000000
ORDER BY 3 DESC;

-- E. Seasonal High-Rollers (Jan 2020)
-- Objective: List top spenders who showed consistent purchasing power (Min. 2 tx) in Jan 2020.
SELECT 
    buyer_id, 
    count(1) as jumlah_transaksi, 
    avg(total) as avg_nilai_transaksi
FROM orders
WHERE created_at >= '2020-01-01' AND created_at < '2020-02-01'
GROUP BY 1
HAVING count(1) >= 2
ORDER BY 3 DESC
LIMIT 10;


-- ----------------------------------------------------------
-- 3. Operational & Behavioral Deep Dive
-- ----------------------------------------------------------

-- A. Payment Settlement Latency
-- Objective: Calculate average time lag (days) between order creation and payment confirmation.
SELECT
    EXTRACT(YEAR_MONTH from created_at) as tahun_bulan,
    count(1) as jumlah_transaksi,
    avg(datediff(paid_at, created_at)) as avg_lama_dibayar,
    min(datediff(paid_at, created_at)) as min_lama_dibayar,
    max(datediff(paid_at, created_at)) as max_lama_dibayar
FROM orders 
WHERE paid_at IS NOT NULL 
GROUP BY 1 
ORDER BY 1;

-- B. Single-User Deep Dive (User 12476)
-- Objective: Analyze transaction history of a specific high-value user to spot seasonal spikes.
SELECT 
    seller_id, 
    buyer_id, 
    total as nilai_transaksi, 
    created_at as tanggal_transaksi
FROM orders
WHERE buyer_id = 12476
ORDER BY 3 DESC
LIMIT 10;
