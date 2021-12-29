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