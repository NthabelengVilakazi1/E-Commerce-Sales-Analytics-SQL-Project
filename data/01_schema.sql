-- 01_schema.sql
BEGIN;

CREATE TABLE dim_customer (
  customer_key    BIGSERIAL PRIMARY KEY,
  name            VARCHAR(255) NOT NULL,
  contact_no      VARCHAR(50),
  nid             VARCHAR(100) UNIQUE
);

CREATE TABLE dim_item (
  item_key     BIGSERIAL PRIMARY KEY,
  item_name    VARCHAR(255) NOT NULL,
  description  TEXT,
  unit_price   NUMERIC(12,2) NOT NULL,
  man_country  VARCHAR(100),
  supplier     VARCHAR(255),
  unit         VARCHAR(50)
);

CREATE TABLE dim_store (
  store_key  BIGSERIAL PRIMARY KEY,
  store_name VARCHAR(255),
  division   VARCHAR(100),
  district   VARCHAR(100),
  upazila    VARCHAR(100)
);

CREATE TABLE dim_payment (
  payment_key BIGSERIAL PRIMARY KEY,
  trans_type  VARCHAR(50),
  bank_name   VARCHAR(100)
);

CREATE TABLE dim_time (
  time_key BIGSERIAL PRIMARY KEY,
  date     DATE NOT NULL,
  hour     SMALLINT,
  day      VARCHAR(10),
  week     SMALLINT,
  month    SMALLINT,
  quarter  SMALLINT,
  year     SMALLINT,
  UNIQUE (date, hour)  -- prevents duplicate time rows for same date/hour
);

CREATE TABLE fact_sales (
  sales_key    BIGSERIAL PRIMARY KEY,
  payment_key  BIGINT  NOT NULL,
  customer_key BIGINT  NOT NULL,
  time_key     BIGINT  NOT NULL,
  item_key     BIGINT  NOT NULL,
  store_key    BIGINT  NOT NULL,
  quantity     INTEGER NOT NULL CHECK (quantity >= 0),
  unit         VARCHAR(50) NOT NULL,
  unit_price   NUMERIC(12,2) NOT NULL,
  total_price  NUMERIC(14,2) NOT NULL CHECK (total_price = quantity * unit_price),

  CONSTRAINT fk_payment  FOREIGN KEY (payment_key)  REFERENCES dim_payment(payment_key),
  CONSTRAINT fk_customer FOREIGN KEY (customer_key) REFERENCES dim_customer(customer_key),
  CONSTRAINT fk_time     FOREIGN KEY (time_key)     REFERENCES dim_time(time_key),
  CONSTRAINT fk_item     FOREIGN KEY (item_key)     REFERENCES dim_item(item_key),
  CONSTRAINT fk_store    FOREIGN KEY (store_key)    REFERENCES dim_store(store_key)
);

COMMIT;
