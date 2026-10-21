-- 02_modelagem.sql
-- Cria índices, a dimensão de produtos e a tabela de fatos de entrega.

-- 1. Índices
CREATE INDEX idx_orders_id ON orders (order_id);
CREATE INDEX idx_orders_customer ON orders (customer_id);
CREATE INDEX idx_items_order ON order_items (order_id);
CREATE INDEX idx_items_product ON order_items (product_id);
CREATE INDEX idx_items_seller ON order_items (seller_id);
CREATE INDEX idx_reviews_order ON order_reviews (order_id);
CREATE INDEX idx_payments_order ON order_payments (order_id);
CREATE INDEX idx_customers_id ON customers (customer_id);
CREATE INDEX idx_products_id ON products (product_id);
CREATE INDEX idx_sellers_id ON sellers (seller_id);

-- 2. Dimensão de produtos
CREATE OR REPLACE VIEW dim_produto AS
SELECT p.product_id,
       COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS categoria,
       p.product_weight_g AS peso_g
FROM products p
LEFT JOIN category_translation t
       ON t.product_category_name = p.product_category_name;

-- 3. Fato de entrega (uma linha por pedido entregue)
CREATE OR REPLACE VIEW fato_entrega AS
SELECT o.order_id,
       o.customer_id,
       c.customer_state AS estado,
       DATE(o.order_purchase_timestamp) AS data_compra,
       DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS ano_mes,
       DATEDIFF(o.order_estimated_delivery_date, o.order_purchase_timestamp) AS prazo_prometido_dias,
       DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp) AS prazo_real_dias,
       DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) AS dias_atraso,
       (o.order_delivered_customer_date > o.order_estimated_delivery_date) AS atrasou,
       i.valor_itens,
       i.frete,
       i.qtd_itens,
       r.nota
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
JOIN (SELECT order_id,
             SUM(price) AS valor_itens,
             SUM(freight_value) AS frete,
             COUNT(*) AS qtd_itens
      FROM order_items
      GROUP BY order_id) i ON i.order_id = o.order_id
LEFT JOIN (SELECT order_id, AVG(review_score) AS nota
           FROM order_reviews
           GROUP BY order_id) r ON r.order_id = o.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL;