
#1. Pedidos por mês

SELECT DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS mes,
       COUNT(*) AS pedidos
FROM orders
GROUP BY mes
ORDER BY mes;


#2. Nota média das avaliações

SELECT ROUND(AVG(review_score), 2) AS nota_media,
       COUNT(*) AS avaliacoes
FROM order_reviews;

#3. Pedidos entregues com atraso

SELECT COUNT(*) AS entregues,
       SUM(order_delivered_customer_date > order_estimated_delivery_date) AS atrasados,
       ROUND(100 * SUM(order_delivered_customer_date > order_estimated_delivery_date) / COUNT(*), 2) AS pct_atraso
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;


#4. A pergunta central do projeto: atraso x nota

SELECT CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN 'Atrasado' ELSE 'No prazo' END AS entrega,
       COUNT(*) AS pedidos,
       ROUND(AVG(r.review_score), 2) AS nota_media
FROM orders o
JOIN order_reviews r ON r.order_id = o.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY entrega;




