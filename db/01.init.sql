SELECT '=================Start init\n';
-- ----------------------------------------------------------------------------
-- tender_product - товары тендеров
CREATE TABLE tender_product (
  id          INTEGER          -- ID тендера
, product_id  INTEGER          -- ID позиции
, amount      NUMERIC NOT NULL -- количество
, start_price NUMERIC NOT NULL -- начальная цена
, bid_step    NUMERIC NOT NULL -- шаг цены
, CONSTRAINT  tender_product_pkey PRIMARY KEY (id, product_id)
);

-- ----------------------------------------------------------------------------
-- bid - ставки участников тендера
CREATE TABLE bid (
  id         INTEGER                     -- ID ставки
, tender_id  INTEGER                     -- ID тендера
, product_id INTEGER                     -- ID позиции
, amount     NUMERIC NOT NULL            -- количество
, price      NUMERIC NOT NULL            -- цена
, is_winner  BOOL NOT NULL DEFAULT FALSE -- ставка победила
, win_amount NUMERIC                     -- объем победы, если отличается от объема ставки
, CONSTRAINT bid_pkey PRIMARY KEY (id, product_id)
, CONSTRAINT bif_fkey_tender_product FOREIGN KEY (tender_id, product_id) REFERENCES tender_product
);

INSERT INTO tender_product (id,product_id,amount, start_price, bid_step) VALUES
  (1, 1,  10,  100,  2)
, (1, 2,  20,  300, 10)
, (2, 1, 100, 1000, 30)
, (2, 3, 300, 1000, 30)
;

INSERT INTO bid (id, tender_id, product_id, amount, price) VALUES
  (1, 1, 1,  7, 100)
, (2, 1, 1,  5, 102)
, (3, 1, 1,  4, 102)
, (4, 1, 1,  3, 104)
, (5, 1, 1,  2, 104)
, (1, 1, 2, 15, 300)
, (2, 1, 2, 10, 310)
, (6, 2, 1, 10, 1000)
;

