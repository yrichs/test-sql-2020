CREATE OR REPLACE FUNCTION bid_winner_set(a_id INTEGER) RETURNS VOID LANGUAGE sql AS
$_$
-- a_id: ID тендера
-- функция рассчитывает победителей заданного тендера
-- и заполняет поля bid.is_winner и bid.win_amount

UPDATE bid SET 
	is_winner = CASE WHEN res.remains_before > 0 THEN true ELSE false END, 
	win_amount = CASE WHEN NOT res.remains_before >= res.amount AND res.remains_before > 0 THEN res.remains_before ELSE null END
FROM (
	SELECT 
		bid.product_id, bid.id, bid.amount,
		tender_product.amount - sum(bid.amount) OVER (PARTITION BY bid.product_id ORDER BY bid.price DESC, bid.amount DESC) as remains_after,
		tender_product.amount - sum(bid.amount) OVER (PARTITION BY bid.product_id ORDER BY bid.price DESC, bid.amount DESC)+bid.amount as remains_before
	FROM bid
		INNER JOIN tender_product ON (bid.tender_id = tender_product.id AND bid.product_id = tender_product.product_id)
	WHERE tender_id = a_id
	ORDER BY bid.tender_id, bid.product_id, bid.price DESC, bid.amount DESC
) as res
WHERE bid.tender_id  = a_id AND bid.product_id = res.product_id AND bid.id = res.id;
$_$;

SELECT bid_winner_set(1);
SELECT bid_winner_set(2);
SELECT * FROM bid;
UPDATE bid SET is_winner = false, win_amount = null;






ROLLBACK;
BEGIN;
CREATE TEMP SEQUENCE bet_order_seq;

CREATE TEMP TABLE bid_on_tender_w_order -- Нет порядковых номеров ставок, сделаем их 
ON COMMIT DROP
AS 
SELECT nextval('bet_order_seq') AS bet_order, id, tender_id, product_id, amount, price, is_winner, win_amount 
FROM bid
WHERE tender_id = 1;

SELECT bet_order, id, tender_id, product_id, amount, price, is_winner, win_amount 
FROM bid_on_tender_w_order 
ORDER BY product_id, price DESC, bet_order DESC, amount DESC;

DROP SEQUENCE bet_order_seq;
COMMIT;


ROLLBACK;
BEGIN;

SELECT id, tender_id, product_id, amount, price, 
	sum(amount) OVER (ORDER BY tender_id, product_id, price DESC, amount DESC) as product_amount
	--CASE WHEN is_winner, win_amount 
FROM bid 
WHERE tender_id = 1
ORDER BY tender_id, product_id, price DESC, amount DESC;

COMMIT;


ROLLBACK;
BEGIN;
CREATE TEMP TABLE bid_on_tender -- Нет порядковых номеров ставок, сделаем их 
ON COMMIT DROP
AS
SELECT bid.id, bid.tender_id, bid.product_id, bid.amount, bid.price,
	tender_product.amount AS amount_product,
	sum(bid.amount) OVER (PARTITION BY bid.product_id ORDER BY bid.price DESC, bid.amount DESC) as saled,
	tender_product.amount - sum(bid.amount) OVER (PARTITION BY bid.product_id ORDER BY bid.price DESC, bid.amount DESC) as remains
	--CASE WHEN is_winner, win_amount 
FROM bid
	INNER JOIN tender_product ON (bid.tender_id = tender_product.id AND bid.product_id = tender_product.product_id)
WHERE tender_id = 1
ORDER BY tender_id, product_id, price DESC, amount DESC;

SELECT id, tender_id, product_id, amount, price,
	amount_product, saled, remains,
	--CASE WHEN amount_product-saled >= 0 THEN true ELSE false END AS is_winner
	CASE WHEN amount_product-saled+amount >= 0 THEN true ELSE false END AS is_winner,
	amount_product-saled+amount,
	CASE WHEN amount_product-saled >= 0 THEN true ELSE false END AS win_amount
FROM bid_on_tender;
COMMIT;




ROLLBACK;
BEGIN;
CREATE TEMP TABLE bid_on_tender -- Нет порядковых номеров ставок, сделаем их 
ON COMMIT DROP
AS
SELECT bid.id, bid.tender_id, bid.product_id, bid.amount, bid.price,
	tender_product.amount AS amount_product,
	sum(bid.amount) OVER (PARTITION BY bid.product_id ORDER BY bid.price DESC, bid.amount DESC) as saled_amount,
	tender_product.amount - sum(bid.amount) OVER (PARTITION BY bid.product_id ORDER BY bid.price DESC, bid.amount DESC) as remains_after,
	tender_product.amount - sum(bid.amount) OVER (PARTITION BY bid.product_id ORDER BY bid.price DESC, bid.amount DESC)+bid.amount as remains_before,
	
	CASE WHEN tender_product.amount - sum(bid.amount) OVER (PARTITION BY bid.product_id ORDER BY bid.price DESC, bid.amount DESC) > 0 
		THEN tender_product.amount - sum(bid.amount) OVER (PARTITION BY bid.product_id ORDER BY bid.price DESC, bid.amount DESC)  ElSE 0 END as remains_truly
		,
	CASE WHEN tender_product.amount - sum(bid.amount) OVER (PARTITION BY bid.product_id ORDER BY bid.price DESC, bid.amount DESC) > 0 
		THEN bid.amount ELSE sum(bid.amount) OVER (PARTITION BY bid.product_id ORDER BY bid.price DESC, bid.amount DESC) - bid.amount END as selled_bet
	--CASE WHEN is_winner, win_amount 
FROM bid
	INNER JOIN tender_product ON (bid.tender_id = tender_product.id AND bid.product_id = tender_product.product_id)
WHERE tender_id = 1
ORDER BY tender_id, product_id, price DESC, amount DESC;

SELECT id, tender_id, product_id, amount, price,
	amount_product, saled, remains,
	--CASE WHEN amount_product-saled >= 0 THEN true ELSE false END AS is_winner
	CASE WHEN amount_product-saled+amount >= 0 THEN true ELSE false END AS is_winner,
	amount_product-saled+amount,
	CASE WHEN amount_product-saled >= 0 THEN true ELSE false END AS win_amount
FROM bid_on_tender;
COMMIT;




CREATE TEMP TABLE bid_on_tender 
ON COMMIT DROP
AS
SELECT bid.id, bid.tender_id, bid.product_id, bid.amount, bid.price,
	tender_product.amount AS amount_product,
	--sum(bid.amount) OVER (PARTITION BY bid.product_id ORDER BY bid.price DESC, bid.amount DESC) as saled_amount,
	tender_product.amount - sum(bid.amount) OVER (PARTITION BY bid.product_id ORDER BY bid.price DESC, bid.amount DESC) as remains_after,
	tender_product.amount - sum(bid.amount) OVER (PARTITION BY bid.product_id ORDER BY bid.price DESC, bid.amount DESC)+bid.amount as remains_before
FROM bid
	INNER JOIN tender_product ON (bid.tender_id = tender_product.id AND bid.product_id = tender_product.product_id)
WHERE tender_id = 1
ORDER BY tender_id, product_id, price DESC, amount DESC;

SELECT id, tender_id, product_id, amount, price,
	amount_product, remains_after, remains_before,
	CASE WHEN remains_before > 0 THEN true ELSE false END AS is_winner,
	--CASE WHEN remains_before >= amount THEN null ELSE remains_before END AS win_amount
	--CASE WHEN remains_before > 0 AND remains_before >= amount THEN null ELSE remains_before END AS win_amount
	CASE WHEN NOT remains_before >= amount AND remains_before > 0 THEN remains_before ELSE null END AS win_amount
FROM bid_on_tender;
COMMIT;





CREATE TEMP TABLE bid_on_tender 
ON COMMIT DROP
AS
SELECT bid.id, bid.tender_id, bid.product_id, bid.amount, bid.price,
	tender_product.amount AS amount_product,
	--sum(bid.amount) OVER (PARTITION BY bid.product_id ORDER BY bid.price DESC, bid.amount DESC) as saled_amount,
	tender_product.amount - sum(bid.amount) OVER (PARTITION BY bid.product_id ORDER BY bid.price DESC, bid.amount DESC) as remains_after,
	tender_product.amount - sum(bid.amount) OVER (PARTITION BY bid.product_id ORDER BY bid.price DESC, bid.amount DESC)+bid.amount as remains_before
FROM bid
	INNER JOIN tender_product ON (bid.tender_id = tender_product.id AND bid.product_id = tender_product.product_id)
WHERE tender_id = 1
ORDER BY tender_id, product_id, price DESC, amount DESC;

SELECT id, tender_id, product_id, amount, price,
	amount_product, remains_after, remains_before,
	CASE WHEN remains_before > 0 THEN true ELSE false END AS is_winner,
	--CASE WHEN remains_before >= amount THEN null ELSE remains_before END AS win_amount
	--CASE WHEN remains_before > 0 AND remains_before >= amount THEN null ELSE remains_before END AS win_amount
	CASE WHEN NOT remains_before >= amount AND remains_before > 0 THEN remains_before ELSE null END AS win_amount
FROM bid_on_tender;
COMMIT;


UPDATE bid SET 
	is_winner = CASE WHEN res.remains_before > 0 THEN true ELSE false END, 
	win_amount = CASE WHEN NOT res.remains_before >= res.amount AND res.remains_before > 0 THEN res.remains_before ELSE null END
FROM (
	SELECT 
		bid.product_id, bid.id, bid.amount,
		tender_product.amount - sum(bid.amount) OVER (PARTITION BY bid.product_id ORDER BY bid.price DESC, bid.amount DESC) as remains_after,
		tender_product.amount - sum(bid.amount) OVER (PARTITION BY bid.product_id ORDER BY bid.price DESC, bid.amount DESC)+bid.amount as remains_before
	FROM bid
		INNER JOIN tender_product ON (bid.tender_id = tender_product.id AND bid.product_id = tender_product.product_id)
	WHERE tender_id = 1
	ORDER BY bid.tender_id, bid.product_id, bid.price DESC, bid.amount DESC
) as res
WHERE bid.tender_id  = 1 AND bid.product_id = res.product_id AND bid.id = res.id;




UPDATE client_diagnoses SET is_fixed = cure_result.is_fixed FROM cure_result WHERE client_diagnoses.client_diagnoses_id  = cure_result.client_diagnoses_id






















