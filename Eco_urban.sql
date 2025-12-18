/*FINAL PROJECT*/

CREATE SCHEMA eco_urban;

USE eco_urban;

-- Create user access for M604
CREATE USER 'urbaneco_user'@'localhost'
IDENTIFIED BY 'strong_password';

GRANT ALL PRIVILEGES ON eco_urban.* TO 'urbaneco_user'@'localhost';

FLUSH PRIVILEGES;

-- Drop tables in reverse dependency order if recreating
DROP TABLE IF EXISTS eco_urban.inventory_snapshots;
DROP TABLE IF EXISTS eco_urban.order_items;
DROP TABLE IF EXISTS eco_urban.orders;
DROP TABLE IF EXISTS eco_urban.promotions;
DROP TABLE IF EXISTS eco_urban.stores;
DROP TABLE IF EXISTS eco_urban.customers;
DROP TABLE IF EXISTS eco_urban.products;
DROP TABLE IF EXISTS eco_urban.product_categories;

-- Create tables
-- 1. Product Categories
CREATE TABLE IF NOT EXISTS product_categories (
    category_id   CHAR(36) PRIMARY KEY,
    name          VARCHAR(100) NOT NULL UNIQUE,
    description   VARCHAR(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. Products
CREATE TABLE IF NOT EXISTS products (
    product_id    CHAR(36) PRIMARY KEY,
    category_id   CHAR(36) NOT NULL,
    sku           VARCHAR(50) NOT NULL UNIQUE,
    name          VARCHAR(150) NOT NULL,
    description   TEXT,
    unit_price    DECIMAL(10,2) NOT NULL,
    is_active     BOOLEAN DEFAULT TRUE,
    created_at    TIMESTAMP NOT NULL,
    updated_at    TIMESTAMP NULL,
    CONSTRAINT fk_products_category
        FOREIGN KEY (category_id)
        REFERENCES eco_urban.product_categories (category_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_products_category_id ON products(category_id);
CREATE INDEX idx_products_name ON products(name);

-- 3. Customers
CREATE TABLE IF NOT EXISTS customers (
    customer_id   CHAR(36) PRIMARY KEY,
    email         VARCHAR(150) NOT NULL UNIQUE,
    first_name    VARCHAR(100),
    last_name     VARCHAR(100),
    city          VARCHAR(100),
    country       VARCHAR(100),
    created_at    TIMESTAMP NOT NULL,
    is_active     BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_customers_city ON customers(city);

-- 4. Stores
CREATE TABLE IF NOT EXISTS stores (
    store_id      CHAR(36) PRIMARY KEY,
    name          VARCHAR(100) NOT NULL,
    city          VARCHAR(100) NOT NULL,
    country       VARCHAR(100) NOT NULL,
    address       VARCHAR(255),
    created_at    DATE,
    is_active     BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_stores_city ON stores(city);

-- 5. Promotions
CREATE TABLE IF NOT EXISTS promotions (
    promotion_id  CHAR(36) PRIMARY KEY,
    name          VARCHAR(100) NOT NULL,
    description   VARCHAR(255),
    discount_type VARCHAR(20) NOT NULL,      -- 'PERCENTAGE', 'FIXED'
    discount_value DECIMAL(10,2) NOT NULL,
    budget        DECIMAL(12,2) NOT NULL,
    start_date    DATE NOT NULL,
    end_date      DATE NOT NULL,
    is_active     BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 6. Orders
CREATE TABLE IF NOT EXISTS orders (
    order_id      CHAR(36) PRIMARY KEY,
    store_id      CHAR(36) NOT NULL,
    customer_id   CHAR(36) NOT NULL,
    order_date    TIMESTAMP NOT NULL,
    status        VARCHAR(30) NOT NULL,
    total_amount  DECIMAL(12,2) NOT NULL,
    promotion_id  CHAR(36) NULL,
    CONSTRAINT fk_orders_store
        FOREIGN KEY (store_id) REFERENCES eco_urban.stores (store_id),
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id) REFERENCES eco_urban.customers (customer_id),
    CONSTRAINT fk_orders_promotion
        FOREIGN KEY (promotion_id) REFERENCES eco_urban.promotions (promotion_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_orders_store_date
    ON orders(store_id, order_date); -- MySQL does not support 'IF NOT EXISTS' for indexes

CREATE INDEX idx_orders_customer_date
    ON orders(customer_id, order_date);

-- 7. Order Items
CREATE TABLE IF NOT EXISTS order_items (
    order_item_id CHAR(36) PRIMARY KEY,
    product_id    CHAR(36) NOT NULL,
    order_id      CHAR(36) NOT NULL,
    quantity      INT NOT NULL,
    unit_price    DECIMAL(10,2) NOT NULL,
    line_total    DECIMAL(12,2) NOT NULL,
    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id) REFERENCES eco_urban.orders (order_id),
    CONSTRAINT fk_order_items_product
        FOREIGN KEY (product_id) REFERENCES eco_urban.products (product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_order_items_order_id
    ON order_items(order_id);

CREATE INDEX idx_order_items_product_id
    ON order_items(product_id);

-- 8. Inventory Snapshots
CREATE TABLE IF NOT EXISTS inventory_snapshots (
    snapshot_id    CHAR(36) PRIMARY KEY,
    product_id     CHAR(36) NOT NULL,
    store_id       CHAR(36) NOT NULL,
    snapshot_date  DATE NOT NULL,
    stock_quantity INT NOT NULL,
    reorder_level  INT NOT NULL,
    CONSTRAINT fk_inventory_product
        FOREIGN KEY (product_id) REFERENCES eco_urban.products (product_id),
    CONSTRAINT fk_inventory_store
        FOREIGN KEY (store_id) REFERENCES eco_urban.stores (store_id),
    CONSTRAINT uq_inventory_store_product_date
        UNIQUE (store_id, product_id, snapshot_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_inventory_store_product_date
    ON inventory_snapshots(store_id, product_id, snapshot_date);

/*Insert Data*/

-- Seed
-- Product Categories
INSERT INTO eco_urban.product_categories (category_id, name, description) VALUES
  (UUID(), 'Organic Groceries', 'Certified organic pantry items and dry goods'),
  (UUID(), 'Fresh Products',      'Locally sourced fruits and vegetables'),
  (UUID(), 'Dairy & Alternatives','Milk, yogurt and plant-based alternatives'),
  (UUID(), 'Household & Cleaning','Eco-friendly cleaning and household supplies'),
  (UUID(), 'Personal Care',      'Natural personal care and hygiene products');

-- Products
INSERT INTO eco_urban.products (product_id, category_id, sku, name, description, unit_price, is_active, created_at, updated_at)
  VALUES
    (UUID(),(SELECT category_id FROM eco_urban.product_categories WHERE name = 'Organic Groceries'),
    'OAT-001', 'Organic Oatmeal 1kg',
    'Whole grain organic rolled oats in recyclable packaging.',
    3.49, TRUE, '2025-10-01 09:00:00', NULL),

    (UUID(),(SELECT category_id FROM eco_urban.product_categories WHERE name = 'Organic Groceries'),
    'PST-002', 'Wholewheat Pasta 500g',
    'Organic wholewheat penne pasta, high in fiber.',
    2.19, TRUE, '2025-10-01 09:10:00', NULL),

    (UUID(),(SELECT category_id FROM eco_urban.product_categories WHERE name = 'Fresh Products'),
    'APL-101', 'Red Apples 1kg',
    'Crisp red apples from local farms.',
    2.99, TRUE, '2025-10-01 09:20:00', NULL),

    (UUID(),(SELECT category_id FROM eco_urban.product_categories WHERE name = 'Fresh Products'),
    'CAR-102', 'Carrots 1kg',
    'Organic carrots, ideal for cooking and snacking.',
    1.79, TRUE, '2025-10-01 09:25:00', NULL),

    (UUID(),(SELECT category_id FROM eco_urban.product_categories WHERE name = 'Dairy & Alternatives'),
    'OMK-201', 'Oat Milk 1L',
    'Barista-style organic oat drink, no added sugar.',
    2.49, TRUE, '2025-10-01 09:30:00', NULL),

    (UUID(),(SELECT category_id FROM eco_urban.product_categories WHERE name = 'Dairy & Alternatives'),
    'YGT-202', 'Greek Yogurt 500g',
    'Natural Greek yogurt, high in protein.',
    2.89, TRUE, '2025-10-01 09:35:00', NULL),

    (UUID(),(SELECT category_id FROM eco_urban.product_categories WHERE name = 'Household & Cleaning'),
    'DSH-301', 'Eco Dishwashing Liquid 500ml',
    'Plant-based dish soap, biodegradable formula.',
    3.29, TRUE, '2025-10-01 09:40:00', NULL),

    (UUID(),(SELECT category_id FROM eco_urban.product_categories WHERE name = 'Household & Cleaning'),
    'SPG-302', 'All-Purpose Cleaning Spray 750ml',
    'Multi-surface cleaning spray with citrus scent.',
    4.49, TRUE, '2025-10-01 09:45:00', NULL),

    (UUID(),(SELECT category_id FROM eco_urban.product_categories WHERE name = 'Personal Care'),
    'SHM-401', 'Natural Shampoo 250ml',
    'Sulfate-free shampoo with aloe vera.',
    5.99, TRUE, '2025-10-01 09:50:00', NULL),

    (UUID(),(SELECT category_id FROM eco_urban.product_categories WHERE name = 'Personal Care'),
    'TPS-402', 'Bamboo Toothbrush',
    'Medium-bristle bamboo toothbrush in compostable packaging.',
    3.19, TRUE, '2025-10-01 09:55:00', NULL);
  
-- Stores
INSERT INTO eco_urban.stores (store_id ,name, city, country, address, created_at, is_active) VALUES
  (UUID(),'UrbanEco Berlin Mitte',   'Berlin',  'Germany', 'Friedrichstrasse 21',  '2023-04-01', TRUE),
  (UUID(),'UrbanEco Hamburg Altona', 'Hamburg', 'Germany', 'Max-Brauer-Allee 75', '2023-06-15', TRUE),
  (UUID(),'UrbanEco Munich Westend', 'Munich',  'Germany', 'Schwanthalerstr. 180','2024-02-10', TRUE),
  (UUID(),'UrbanEco Cologne City',   'Cologne', 'Germany', 'Hohe Strasse 102',    '2024-05-20', TRUE);
  
-- Customers
INSERT INTO eco_urban.customers (customer_id, email, first_name, last_name, city, country, created_at, is_active) VALUES
  (UUID(),'lena.schmidt@example.com',  'Lena',    'Schmidt',    'Berlin',  'Germany','2024-10-01 10:00:00', TRUE),
  (UUID(),'max.mueller@example.com',   'Max',     'Müller',     'Hamburg', 'Germany','2024-10-03 15:12:00', TRUE),
  (UUID(),'sara.klein@example.com',    'Sara',    'Klein',      'Munich',  'Germany','2024-10-05 09:22:00', TRUE),
  (UUID(),'jonas.weber@example.com',   'Jonas',   'Weber',      'Cologne', 'Germany','2024-10-06 18:45:00', TRUE),
  (UUID(),'marie.hoffmann@example.com','Marie',   'Hoffmann',   'Berlin',  'Germany','2024-10-07 11:30:00', FALSE),
  (UUID(),'paul.wagner@example.com',   'Paul',    'Wagner',     'Hamburg', 'Germany','2024-10-08 16:50:00', TRUE),
  (UUID(),'anna.fischer@example.com',  'Anna',    'Fischer',    'Munich',  'Germany','2024-10-09 08:40:00', TRUE),
  (UUID(),'tim.becker@example.com',    'Tim',     'Becker',     'Cologne', 'Germany','2024-10-10 13:05:00', FALSE),
  (UUID(),'laura.schulz@example.com',  'Laura',   'Schulz',     'Berlin',  'Germany','2024-10-11 19:25:00', TRUE),
  (UUID(),'felix.koch@example.com',    'Felix',   'Koch',       'Hamburg', 'Germany','2024-10-12 12:10:00', FALSE),
  (UUID(),'astrid.schmidt@example.com',  'Astrid',   'Schmidt', 'Munich',  'Germany','2024-10-11 19:25:00', TRUE),
  (UUID(),'andy.walter@example.com',    'Andy',   'Walter',     'Cologne', 'Germany','2024-10-12 12:10:00', TRUE);
  
-- Promotions
INSERT INTO eco_urban.promotions (promotion_id, name, description, discount_type, discount_value, budget, start_date, end_date, is_active) VALUES
  (UUID(),'Autumn Organics Week',
   '10% off selected organic groceries.',
   'PERCENTAGE', 10.00, 5000.00, '2025-10-15', '2025-10-22', TRUE),

  (UUID(),'Fresh Fridays',
   'Fixed €2 discount on fresh produce baskets over €15.',
   'FIXED', 2.00, 3000.00, '2025-10-01', '2025-12-31', TRUE),

  (UUID(),'Green Home Starter Pack',
   '15% off household cleaning bundles.',
   'PERCENTAGE', 15.00, 4000.00, '2025-11-01', '2025-11-30', TRUE);

-- Orders
INSERT INTO eco_urban.orders (order_id, store_id, customer_id, order_date, status, total_amount, promotion_id) VALUES
  (
    UUID(),(SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Berlin Mitte'),
    (SELECT customer_id FROM eco_urban.customers WHERE email='lena.schmidt@example.com'),
    '2025-10-20 10:15:00', 'PAID', 0,
    NULL
  ),
  (
    UUID(),(SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Berlin Mitte'),
    (SELECT customer_id FROM eco_urban.customers WHERE email='laura.schulz@example.com'),
    '2025-10-20 18:40:00', 'PAID', 0,
    NULL
  ),
  (
    UUID(),(SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Berlin Mitte'),
    (SELECT customer_id FROM eco_urban.customers WHERE email='marie.hoffmann@example.com'),
    '2025-10-20 16:40:00', 'CANCELLED', 0,
    NULL
  ),
  (
    UUID(),(SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Hamburg Altona'),
    (SELECT customer_id FROM eco_urban.customers WHERE email='max.mueller@example.com'),
    '2025-10-20 11:05:00', 'PAID', 0,
    NULL
  ),
  (
    UUID(),(SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Hamburg Altona'),
    (SELECT customer_id FROM eco_urban.customers WHERE email='paul.wagner@example.com'),
    '2025-10-21 16:30:00', 'PAID', 0,
    NULL
  ),
  (
    UUID(),(SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Munich Westend'),
    (SELECT customer_id FROM eco_urban.customers WHERE email='sara.klein@example.com'),
    '2025-10-21 16:30:00', 'PAID', 0,
    NULL
  ),
  (
    UUID(),(SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Munich Westend'),
    (SELECT customer_id FROM eco_urban.customers WHERE email='anna.fischer@example.com'),
    '2025-10-21 16:30:00', 'PAID', 0,
    NULL
  ),
  (
    UUID(),(SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Munich Westend'),
    (SELECT customer_id FROM eco_urban.customers WHERE email='astrid.schmidt@example.com'),
    '2025-10-21 16:30:00', 'PAID', 0,
    NULL
  ),
  (
    UUID(),(SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Cologne City'),
    (SELECT customer_id FROM eco_urban.customers WHERE email='jonas.weber@example.com'),
    '2025-10-21 16:30:00', 'PAID', 0,
    NULL
  ),
  (
    UUID(),(SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Cologne City'),
    (SELECT customer_id FROM eco_urban.customers WHERE email='andy.walter@example.com'),
    '2025-10-21 16:30:00', 'PAID', 0,
    NULL
  );

-- Helper: order items for all sample orders
INSERT INTO eco_urban.order_items (order_item_id, product_id, order_id, quantity, unit_price, line_total) VALUES
  -- Lena Schmidt, Berlin Mitte, 2025-10-20 10:15
  (
    UUID(), (SELECT product_id FROM eco_urban.products WHERE sku='OAT-001'),
    (SELECT o.order_id
     FROM eco_urban.orders o
     JOIN eco_urban.customers c ON o.customer_id = c.customer_id
     WHERE c.email='lena.schmidt@example.com'
       AND o.order_date='2025-10-20 10:15:00'),
    2,
    (SELECT unit_price FROM eco_urban.products WHERE sku='OAT-001'),
    (SELECT unit_price FROM eco_urban.products WHERE sku='OAT-001') * 2
  ),
  (
    UUID(), (SELECT product_id FROM eco_urban.products WHERE sku='OMK-201'),
    (SELECT o.order_id
     FROM eco_urban.orders o
     JOIN eco_urban.customers c ON o.customer_id = c.customer_id
     WHERE c.email='lena.schmidt@example.com'
       AND o.order_date='2025-10-20 10:15:00'),
    1,
    (SELECT unit_price FROM eco_urban.products WHERE sku='OMK-201'),
    (SELECT unit_price FROM eco_urban.products WHERE sku='OMK-201') * 1
  ),
  (
    UUID(), (SELECT product_id FROM eco_urban.products WHERE sku='APL-101'),
    (SELECT o.order_id
     FROM eco_urban.orders o
     JOIN eco_urban.customers c ON o.customer_id = c.customer_id
     WHERE c.email='lena.schmidt@example.com'
       AND o.order_date='2025-10-20 10:15:00'),
    3,
    (SELECT unit_price FROM eco_urban.products WHERE sku='APL-101'),
    (SELECT unit_price FROM eco_urban.products WHERE sku='APL-101') * 3
  ),

  -- Laura Schulz, Berlin Mitte, 2025-10-20 18:40
  (
    UUID(), (SELECT product_id FROM eco_urban.products WHERE sku='CAR-102'),
    (SELECT o.order_id
     FROM eco_urban.orders o
     JOIN eco_urban.customers c ON o.customer_id = c.customer_id
     WHERE c.email='laura.schulz@example.com'
       AND o.order_date='2025-10-20 18:40:00'),
    2,
    (SELECT unit_price FROM eco_urban.products WHERE sku='CAR-102'),
    (SELECT unit_price FROM eco_urban.products WHERE sku='CAR-102') * 2
  ),
  (
    UUID(), (SELECT product_id FROM eco_urban.products WHERE sku='YGT-202'),
    (SELECT o.order_id
     FROM eco_urban.orders o
     JOIN eco_urban.customers c ON o.customer_id = c.customer_id
     WHERE c.email='laura.schulz@example.com'
       AND o.order_date='2025-10-20 18:40:00'),
    1,
    (SELECT unit_price FROM eco_urban.products WHERE sku='YGT-202'),
    (SELECT unit_price FROM eco_urban.products WHERE sku='YGT-202') * 1
  ),

  -- Marie Hoffmann, Berlin Mitte, 2025-10-20 16:40 (CANCELLED but still has items)
  (
    UUID(), (SELECT product_id FROM eco_urban.products WHERE sku='SPG-302'),
    (SELECT o.order_id
     FROM eco_urban.orders o
     JOIN eco_urban.customers c ON o.customer_id = c.customer_id
     WHERE c.email='marie.hoffmann@example.com'
       AND o.order_date='2025-10-20 16:40:00'),
    1,
    (SELECT unit_price FROM eco_urban.products WHERE sku='SPG-302'),
    (SELECT unit_price FROM eco_urban.products WHERE sku='SPG-302') * 1
  ),
  (
    UUID(), (SELECT product_id FROM eco_urban.products WHERE sku='SHM-401'),
    (SELECT o.order_id
     FROM eco_urban.orders o
     JOIN eco_urban.customers c ON o.customer_id = c.customer_id
     WHERE c.email='marie.hoffmann@example.com'
       AND o.order_date='2025-10-20 16:40:00'),
    2,
    (SELECT unit_price FROM eco_urban.products WHERE sku='SHM-401'),
    (SELECT unit_price FROM eco_urban.products WHERE sku='SHM-401') * 2
  ),

  -- Max Müller, Hamburg Altona, 2025-10-20 11:05
  (
    UUID(), (SELECT product_id FROM eco_urban.products WHERE sku='OAT-001'),
    (SELECT o.order_id
     FROM eco_urban.orders o
     JOIN eco_urban.customers c ON o.customer_id = c.customer_id
     WHERE c.email='max.mueller@example.com'
       AND o.order_date='2025-10-20 11:05:00'),
    1,
    (SELECT unit_price FROM eco_urban.products WHERE sku='OAT-001'),
    (SELECT unit_price FROM eco_urban.products WHERE sku='OAT-001') * 1
  ),
  (
    UUID(), (SELECT product_id FROM eco_urban.products WHERE sku='PST-002'),
    (SELECT o.order_id
     FROM eco_urban.orders o
     JOIN eco_urban.customers c ON o.customer_id = c.customer_id
     WHERE c.email='max.mueller@example.com'
       AND o.order_date='2025-10-20 11:05:00'),
    4,
    (SELECT unit_price FROM eco_urban.products WHERE sku='PST-002'),
    (SELECT unit_price FROM eco_urban.products WHERE sku='PST-002') * 4
  ),

  -- Paul Wagner, Hamburg Altona, 2025-10-21 16:30
  (
    UUID(), (SELECT product_id FROM eco_urban.products WHERE sku='APL-101'),
    (SELECT o.order_id
     FROM eco_urban.orders o
     JOIN eco_urban.customers c ON o.customer_id = c.customer_id
     WHERE c.email='paul.wagner@example.com'
       AND o.order_date='2025-10-21 16:30:00'),
    2,
    (SELECT unit_price FROM eco_urban.products WHERE sku='APL-101'),
    (SELECT unit_price FROM eco_urban.products WHERE sku='APL-101') * 2
  ),
  (
    UUID(), (SELECT product_id FROM eco_urban.products WHERE sku='YGT-202'),
    (SELECT o.order_id
     FROM eco_urban.orders o
     JOIN eco_urban.customers c ON o.customer_id = c.customer_id
     WHERE c.email='paul.wagner@example.com'
       AND o.order_date='2025-10-21 16:30:00'),
    3,
    (SELECT unit_price FROM eco_urban.products WHERE sku='YGT-202'),
    (SELECT unit_price FROM eco_urban.products WHERE sku='YGT-202') * 3
  ),

  -- Sara Klein, Munich Westend, 2025-10-21 16:30
  (
    UUID(), (SELECT product_id FROM eco_urban.products WHERE sku='OMK-201'),
    (SELECT o.order_id
     FROM eco_urban.orders o
     JOIN eco_urban.customers c ON o.customer_id = c.customer_id
     WHERE c.email='sara.klein@example.com'
       AND o.order_date='2025-10-21 16:30:00'),
    2,
    (SELECT unit_price FROM eco_urban.products WHERE sku='OMK-201'),
    (SELECT unit_price FROM eco_urban.products WHERE sku='OMK-201') * 2
  ),
  (
    UUID(), (SELECT product_id FROM eco_urban.products WHERE sku='CAR-102'),
    (SELECT o.order_id
     FROM eco_urban.orders o
     JOIN eco_urban.customers c ON o.customer_id = c.customer_id
     WHERE c.email='sara.klein@example.com'
       AND o.order_date='2025-10-21 16:30:00'),
    1,
    (SELECT unit_price FROM eco_urban.products WHERE sku='CAR-102'),
    (SELECT unit_price FROM eco_urban.products WHERE sku='CAR-102') * 1
  ),

  -- Anna Fischer, Munich Westend, 2025-10-21 16:30
  (
    UUID(), (SELECT product_id FROM eco_urban.products WHERE sku='OAT-001'),
    (SELECT o.order_id
     FROM eco_urban.orders o
     JOIN eco_urban.customers c ON o.customer_id = c.customer_id
     WHERE c.email='anna.fischer@example.com'
       AND o.order_date='2025-10-21 16:30:00'),
    3,
    (SELECT unit_price FROM eco_urban.products WHERE sku='OAT-001'),
    (SELECT unit_price FROM eco_urban.products WHERE sku='OAT-001') * 3
  ),
  (
    UUID(), (SELECT product_id FROM eco_urban.products WHERE sku='DSH-301'),
    (SELECT o.order_id
     FROM eco_urban.orders o
     JOIN eco_urban.customers c ON o.customer_id = c.customer_id
     WHERE c.email='anna.fischer@example.com'
       AND o.order_date='2025-10-21 16:30:00'),
    1,
    (SELECT unit_price FROM eco_urban.products WHERE sku='DSH-301'),
    (SELECT unit_price FROM eco_urban.products WHERE sku='DSH-301') * 1
  ),

  -- Astrid Schmidt, Munich Westend, 2025-10-21 16:30
  (
    UUID(), (SELECT product_id FROM eco_urban.products WHERE sku='TPS-402'),
    (SELECT o.order_id
     FROM eco_urban.orders o
     JOIN eco_urban.customers c ON o.customer_id = c.customer_id
     WHERE c.email='astrid.schmidt@example.com'
       AND o.order_date='2025-10-21 16:30:00'),
    2,
    (SELECT unit_price FROM eco_urban.products WHERE sku='TPS-402'),
    (SELECT unit_price FROM eco_urban.products WHERE sku='TPS-402') * 2
  ),
  (
    UUID(), (SELECT product_id FROM eco_urban.products WHERE sku='SPG-302'),
    (SELECT o.order_id
     FROM eco_urban.orders o
     JOIN eco_urban.customers c ON o.customer_id = c.customer_id
     WHERE c.email='astrid.schmidt@example.com'
       AND o.order_date='2025-10-21 16:30:00'),
    1,
    (SELECT unit_price FROM eco_urban.products WHERE sku='SPG-302'),
    (SELECT unit_price FROM eco_urban.products WHERE sku='SPG-302') * 1
  ),

  -- Jonas Weber, Cologne City, 2025-10-21 16:30
  (
    UUID(), (SELECT product_id FROM eco_urban.products WHERE sku='APL-101'),
    (SELECT o.order_id
     FROM eco_urban.orders o
     JOIN eco_urban.customers c ON o.customer_id = c.customer_id
     WHERE c.email='jonas.weber@example.com'
       AND o.order_date='2025-10-21 16:30:00'),
    2,
    (SELECT unit_price FROM eco_urban.products WHERE sku='APL-101'),
    (SELECT unit_price FROM eco_urban.products WHERE sku='APL-101') * 2
  ),
  (
    UUID(), (SELECT product_id FROM eco_urban.products WHERE sku='OMK-201'),
    (SELECT o.order_id
     FROM eco_urban.orders o
     JOIN eco_urban.customers c ON o.customer_id = c.customer_id
     WHERE c.email='jonas.weber@example.com'
       AND o.order_date='2025-10-21 16:30:00'),
    1,
    (SELECT unit_price FROM eco_urban.products WHERE sku='OMK-201'),
    (SELECT unit_price FROM eco_urban.products WHERE sku='OMK-201') * 1
  ),

  -- Andy Walter, Cologne City, 2025-10-21 16:30
  (
    UUID(), (SELECT product_id FROM eco_urban.products WHERE sku='PST-002'),
    (SELECT o.order_id
     FROM eco_urban.orders o
     JOIN eco_urban.customers c ON o.customer_id = c.customer_id
     WHERE c.email='andy.walter@example.com'
       AND o.order_date='2025-10-21 16:30:00'),
    2,
    (SELECT unit_price FROM eco_urban.products WHERE sku='PST-002'),
    (SELECT unit_price FROM eco_urban.products WHERE sku='PST-002') * 2
  ),
  (
    UUID(), (SELECT product_id FROM eco_urban.products WHERE sku='YGT-202'),
    (SELECT o.order_id
     FROM eco_urban.orders o
     JOIN eco_urban.customers c ON o.customer_id = c.customer_id
     WHERE c.email='andy.walter@example.com'
       AND o.order_date='2025-10-21 16:30:00'),
    1,
    (SELECT unit_price FROM eco_urban.products WHERE sku='YGT-202'),
    (SELECT unit_price FROM eco_urban.products WHERE sku='YGT-202') * 1
  );

-- Inventory Snapshots
INSERT INTO eco_urban.inventory_snapshots (snapshot_id, product_id, store_id, snapshot_date, stock_quantity, reorder_level) VALUES
  -- Berlin Mitte
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='OAT-001'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Berlin Mitte'),
   '2025-10-20', 80, 20),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='PST-002'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Berlin Mitte'),
   '2025-10-20', 60, 15),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='APL-101'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Berlin Mitte'),
   '2025-10-20', 40, 10),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='OMK-201'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Berlin Mitte'),
   '2025-10-20', 50, 15),
   (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='CAR-102'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Berlin Mitte'),
   '2025-10-20', 80, 20),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='YGT-202'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Berlin Mitte'),
   '2025-10-20', 60, 15),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='DSH-301'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Berlin Mitte'),
   '2025-10-20', 40, 10),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='SPG-302'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Berlin Mitte'),
   '2025-10-20', 50, 15),
   (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='SHM-401'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Berlin Mitte'),
   '2025-10-20', 40, 10),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='TPS-402'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Berlin Mitte'),
   '2025-10-20', 50, 15),

  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='OAT-001'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Berlin Mitte'),
   '2025-10-21', 79, 20),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='PST-002'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Berlin Mitte'),
   '2025-10-21', 60, 15),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='APL-101'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Berlin Mitte'),
   '2025-10-21', 39, 10),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='OMK-201'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Berlin Mitte'),
   '2025-10-21', 49, 15),
   (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='CAR-102'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Berlin Mitte'),
   '2025-10-21', 79, 20),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='YGT-202'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Berlin Mitte'),
   '2025-10-21', 59, 15),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='DSH-301'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Berlin Mitte'),
   '2025-10-21', 40, 10),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='SPG-302'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Berlin Mitte'),
   '2025-10-21', 49, 15),
   (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='SHM-401'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Berlin Mitte'),
   '2025-10-21', 39, 10),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='TPS-402'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Berlin Mitte'),
   '2025-10-21', 50, 15),

  -- Hamburg Altona
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='OAT-001'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Hamburg Altona'),
   '2025-10-20', 70, 18),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='APL-101'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Hamburg Altona'),
   '2025-10-20', 50, 12),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='CAR-102'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Hamburg Altona'),
   '2025-10-20', 65, 18),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='YGT-202'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Hamburg Altona'),
   '2025-10-20', 40, 10),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='PST-002'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Hamburg Altona'),
   '2025-10-20', 60, 15),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='OMK-201'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Hamburg Altona'),
   '2025-10-20', 50, 15),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='DSH-301'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Hamburg Altona'),
   '2025-10-20', 40, 10),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='SPG-302'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Hamburg Altona'),
   '2025-10-20', 50, 15),
   (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='SHM-401'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Hamburg Altona'),
   '2025-10-20', 40, 10),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='TPS-402'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Hamburg Altona'),
   '2025-10-20', 50, 15),

   (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='OAT-001'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Hamburg Altona'),
   '2025-10-21', 69, 18),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='APL-101'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Hamburg Altona'),
   '2025-10-21', 49, 12),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='CAR-102'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Hamburg Altona'),
   '2025-10-21', 65, 18),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='YGT-202'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Hamburg Altona'),
   '2025-10-21', 39, 10),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='PST-002'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Hamburg Altona'),
   '2025-10-21', 59, 15),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='OMK-201'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Hamburg Altona'),
   '2025-10-21', 50, 15),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='DSH-301'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Hamburg Altona'),
   '2025-10-21', 40, 10),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='SPG-302'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Hamburg Altona'),
   '2025-10-21', 50, 15),
   (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='SHM-401'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Hamburg Altona'),
   '2025-10-21', 40, 10),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='TPS-402'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Hamburg Altona'),
   '2025-10-21', 50, 15),

   -- Munich Westend
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='OAT-001'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Munich Westend'),
   '2025-10-20', 70, 18),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='APL-101'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Munich Westend'),
   '2025-10-20', 50, 12),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='CAR-102'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Munich Westend'),
   '2025-10-20', 65, 18),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='YGT-202'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Munich Westend'),
   '2025-10-20', 40, 10),
   (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='PST-002'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Munich Westend'),
   '2025-10-20', 60, 15),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='OMK-201'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Munich Westend'),
   '2025-10-20', 50, 15),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='DSH-301'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Munich Westend'),
   '2025-10-20', 40, 10),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='SPG-302'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Munich Westend'),
   '2025-10-20', 50, 15),
   (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='SHM-401'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Munich Westend'),
   '2025-10-20', 40, 10),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='TPS-402'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Munich Westend'),
   '2025-10-20', 50, 15),

   (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='OAT-001'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Munich Westend'),
   '2025-10-21', 69, 18),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='APL-101'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Munich Westend'),
   '2025-10-21', 50, 12),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='CAR-102'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Munich Westend'),
   '2025-10-21', 4, 18),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='YGT-202'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Munich Westend'),
   '2025-10-21', 40, 10),
   (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='PST-002'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Munich Westend'),
   '2025-10-21', 60, 15),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='OMK-201'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Munich Westend'),
   '2025-10-21', 49, 15),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='DSH-301'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Munich Westend'),
   '2025-10-21', 39, 10),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='SPG-302'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Munich Westend'),
   '2025-10-21', 49, 15),
   (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='SHM-401'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Munich Westend'),
   '2025-10-21', 40, 10),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='TPS-402'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Munich Westend'),
   '2025-10-21', 49, 15),

   -- Cologne City
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='OAT-001'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Cologne City'),
   '2025-10-20', 70, 18),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='APL-101'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Cologne City'),
   '2025-10-20', 50, 12),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='CAR-102'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Cologne City'),
   '2025-10-20', 65, 18),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='YGT-202'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Cologne City'),
   '2025-10-20', 40, 10),
   (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='PST-002'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Cologne City'),
   '2025-10-20', 60, 15),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='OMK-201'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Cologne City'),
   '2025-10-20', 50, 15),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='DSH-301'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Cologne City'),
   '2025-10-20', 40, 10),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='SPG-302'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Cologne City'),
   '2025-10-20', 50, 15),
   (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='SHM-401'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Cologne City'),
   '2025-10-20', 40, 10),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='TPS-402'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Cologne City'),
   '2025-10-20', 50, 15),
   
   (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='OAT-001'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Cologne City'),
   '2025-10-21', 70, 18),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='APL-101'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Cologne City'),
   '2025-10-21', 49, 12),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='CAR-102'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Cologne City'),
   '2025-10-21', 65, 18),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='YGT-202'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Cologne City'),
   '2025-10-21', 39, 10),
   (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='PST-002'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Cologne City'),
   '2025-10-21', 59, 15),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='OMK-201'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Cologne City'),
   '2025-10-21', 49, 15),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='DSH-301'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Cologne City'),
   '2025-10-21', 39, 10),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='SPG-302'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Cologne City'),
   '2025-10-21', 59, 15),
   (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='SHM-401'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Cologne City'),
   '2025-10-21', 49, 10),
  (UUID(),(SELECT product_id FROM eco_urban.products WHERE sku='TPS-402'),
   (SELECT store_id FROM eco_urban.stores WHERE name='UrbanEco Cologne City'),
   '2025-10-21', 59, 15);


/* BULK DATA */

-- Helper numbers table 1..100 for this session
DROP TEMPORARY TABLE IF EXISTS tmp_seq;

CREATE TEMPORARY TABLE tmp_seq (n INT PRIMARY KEY);

INSERT INTO tmp_seq (n)
SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL
SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL
SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL
SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20 UNION ALL
SELECT 21 UNION ALL SELECT 22 UNION ALL SELECT 23 UNION ALL SELECT 24 UNION ALL SELECT 25 UNION ALL
SELECT 26 UNION ALL SELECT 27 UNION ALL SELECT 28 UNION ALL SELECT 29 UNION ALL SELECT 30 UNION ALL
SELECT 31 UNION ALL SELECT 32 UNION ALL SELECT 33 UNION ALL SELECT 34 UNION ALL SELECT 35 UNION ALL
SELECT 36 UNION ALL SELECT 37 UNION ALL SELECT 38 UNION ALL SELECT 39 UNION ALL SELECT 40 UNION ALL
SELECT 41 UNION ALL SELECT 42 UNION ALL SELECT 43 UNION ALL SELECT 44 UNION ALL SELECT 45 UNION ALL
SELECT 46 UNION ALL SELECT 47 UNION ALL SELECT 48 UNION ALL SELECT 49 UNION ALL SELECT 50 UNION ALL
SELECT 51 UNION ALL SELECT 52 UNION ALL SELECT 53 UNION ALL SELECT 54 UNION ALL SELECT 55 UNION ALL
SELECT 56 UNION ALL SELECT 57 UNION ALL SELECT 58 UNION ALL SELECT 59 UNION ALL SELECT 60 UNION ALL
SELECT 61 UNION ALL SELECT 62 UNION ALL SELECT 63 UNION ALL SELECT 64 UNION ALL SELECT 65 UNION ALL
SELECT 66 UNION ALL SELECT 67 UNION ALL SELECT 68 UNION ALL SELECT 69 UNION ALL SELECT 70 UNION ALL
SELECT 71 UNION ALL SELECT 72 UNION ALL SELECT 73 UNION ALL SELECT 74 UNION ALL SELECT 75 UNION ALL
SELECT 76 UNION ALL SELECT 77 UNION ALL SELECT 78 UNION ALL SELECT 79 UNION ALL SELECT 80 UNION ALL
SELECT 81 UNION ALL SELECT 82 UNION ALL SELECT 83 UNION ALL SELECT 84 UNION ALL SELECT 85 UNION ALL
SELECT 86 UNION ALL SELECT 87 UNION ALL SELECT 88 UNION ALL SELECT 89 UNION ALL SELECT 90 UNION ALL
SELECT 91 UNION ALL SELECT 92 UNION ALL SELECT 93 UNION ALL SELECT 94 UNION ALL SELECT 95 UNION ALL
SELECT 96 UNION ALL SELECT 97 UNION ALL SELECT 98 UNION ALL SELECT 99 UNION ALL SELECT 100;

-- More product categories with plausible names
INSERT INTO eco_urban.product_categories (category_id, name, description)
SELECT
  UUID(),
  CONCAT('Grocery Collection ', LPAD(n, 3, '0')),
  CONCAT('Additional grocery assortment number ', n)
FROM tmp_seq;

-- More products with plausible names/SKUs
INSERT INTO eco_urban.products (
  product_id, category_id, sku, name, description,
  unit_price, is_active, created_at, updated_at
)
SELECT
  UUID(),
  (SELECT category_id
     FROM eco_urban.product_categories
     ORDER BY RAND()
     LIMIT 1),
  CONCAT('PRD-', LPAD(n, 4, '0')),
  CONCAT('UrbanEco Product ', LPAD(n, 3, '0')),
  CONCAT('Everyday item from the extended UrbanEco range (ID ', n, ').'),
  ROUND(1 + (n * 0.15), 2),
  TRUE,
  TIMESTAMP(DATE('2025-11-01') + INTERVAL n DAY, '09:00:00'),
  NULL
FROM tmp_seq;

-- More customers
INSERT INTO eco_urban.customers (
  customer_id, email, first_name, last_name,
  city, country, created_at, is_active
)
SELECT
  UUID(),
  CONCAT('customer.', LPAD(n, 3, '0'), '@example.com'),
  CONCAT('DemoFirst', n),
  CONCAT('DemoLast', n),
  CASE
    WHEN MOD(n, 4) = 0 THEN 'Berlin'
    WHEN MOD(n, 4) = 1 THEN 'Hamburg'
    WHEN MOD(n, 4) = 2 THEN 'Munich'
    ELSE 'Cologne'
  END,
  'Germany',
  TIMESTAMP(DATE('2025-10-01') + INTERVAL n DAY, '10:00:00'),
  (MOD(n, 10) <> 0)
FROM tmp_seq;

-- More stores
INSERT INTO eco_urban.stores (
  store_id, name, city, country, address, created_at, is_active
)
SELECT
  UUID(),
  CONCAT('UrbanEco Outlet ', LPAD(n, 3, '0')),
  CASE
    WHEN MOD(n, 4) = 0 THEN 'Berlin'
    WHEN MOD(n, 4) = 1 THEN 'Hamburg'
    WHEN MOD(n, 4) = 2 THEN 'Munich'
    ELSE 'Cologne'
  END,
  'Germany',
  CONCAT('Sample Strasse ', n),
  DATE('2024-01-01') + INTERVAL n DAY,
  TRUE
FROM tmp_seq;

-- More promotions
INSERT INTO eco_urban.promotions (
  promotion_id, name, description,
  discount_type, discount_value, budget,
  start_date, end_date, is_active
)
SELECT
  UUID(),
  CONCAT('Seasonal Offer ', LPAD(n, 3, '0')),
  CONCAT('UrbanEco seasonal price incentive number ', n),
  CASE
    WHEN MOD(n, 2) = 0 THEN 'PERCENTAGE'
    ELSE 'FIXED'
  END,
  CASE
    WHEN MOD(n, 2) = 0 THEN 5.00 + MOD(n, 10)  -- 5–14 %
    ELSE 1.00 + MOD(n, 5)                      -- €1–€5
  END,
  1000.00 + (n * 10),
  DATE('2025-11-01') + INTERVAL n DAY,
  DATE('2025-11-01') + INTERVAL n DAY + INTERVAL 7 DAY,
  TRUE
FROM tmp_seq;

-- More orders (totals will be recalculated later)
INSERT INTO eco_urban.orders (
  order_id, store_id, customer_id,
  order_date, status, total_amount, promotion_id
)
SELECT
  UUID(),
  (SELECT store_id FROM eco_urban.stores ORDER BY RAND() LIMIT 1),
  (SELECT customer_id FROM eco_urban.customers ORDER BY RAND() LIMIT 1),
  TIMESTAMP(
    DATE('2025-11-01') + INTERVAL MOD(n, 30) DAY,
    MAKETIME(8 + MOD(n, 10), MOD(n, 60), 0)
  ),
  'PAID',
  0,
  NULL
FROM tmp_seq;

-- More order_items (random products & orders)
INSERT INTO eco_urban.order_items (
  order_item_id, product_id, order_id,
  quantity, unit_price, line_total
)
SELECT
  UUID(),
  (SELECT product_id FROM eco_urban.products ORDER BY RAND() LIMIT 1),
  (SELECT order_id   FROM eco_urban.orders   ORDER BY RAND() LIMIT 1),
  q.qty,
  p.unit_price,
  ROUND(p.unit_price * q.qty, 2)
FROM tmp_seq s
JOIN (
  SELECT 1 AS qty UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
) q
JOIN eco_urban.products p
  ON p.product_id = (SELECT product_id FROM eco_urban.products ORDER BY RAND() LIMIT 1)
LIMIT 100;

-- More inventory snapshots distributed across stores/products
CREATE TEMPORARY TABLE tmp_stores AS
SELECT @rn_s := @rn_s + 1 AS rn, s.store_id
FROM eco_urban.stores s
CROSS JOIN (SELECT @rn_s := 0) AS init_s;

CREATE TEMPORARY TABLE tmp_products AS
SELECT @rn_p := @rn_p + 1 AS rn, p.product_id
FROM eco_urban.products p
CROSS JOIN (SELECT @rn_p := 0) AS init_p;

SET @store_cnt := (SELECT COUNT(*) FROM tmp_stores);
SET @prod_cnt  := (SELECT COUNT(*) FROM tmp_products);

INSERT INTO eco_urban.inventory_snapshots (
  snapshot_id, product_id, store_id,
  snapshot_date, stock_quantity, reorder_level
)
SELECT
  UUID(),
  p.product_id,
  s.store_id,
  DATE('2025-11-01') + INTERVAL n DAY,
  20 + MOD(n, 80),
  10 + MOD(n, 20)
FROM tmp_seq t
JOIN tmp_stores s
  ON s.rn = MOD(t.n - 1, @store_cnt) + 1
JOIN tmp_products p
  ON p.rn = MOD(t.n - 1, @prod_cnt) + 1;

DROP TEMPORARY TABLE tmp_stores;
DROP TEMPORARY TABLE tmp_products;
DROP TEMPORARY TABLE tmp_seq;

/*CHECKING SANITY AND COMPLETENESS*/

/* Ensure each customer has at least one order */
-- Create a basic order for customers without any orders
INSERT INTO eco_urban.orders (
  order_id, store_id, customer_id,
  order_date, status, total_amount, promotion_id
)
SELECT
  UUID() AS order_id,
  (SELECT store_id
   FROM eco_urban.stores
   ORDER BY RAND()
   LIMIT 1) AS store_id,
  c.customer_id,
  TIMESTAMP(
    DATE('2025-11-15') + INTERVAL MOD(ROW_NUMBER() OVER (), 10) DAY,
    MAKETIME(10 + MOD(ROW_NUMBER() OVER (), 6), 0, 0)
  ) AS order_date,
  'PAID' AS status,
  0 AS total_amount,
  NULL AS promotion_id
FROM eco_urban.customers c
LEFT JOIN eco_urban.orders o
  ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL;

-- Add one line item to each newly created order for those customers
INSERT INTO eco_urban.order_items (
  order_item_id, product_id, order_id,
  quantity, unit_price, line_total
)
SELECT
  UUID(),
  p.product_id,
  o.order_id,
  q.qty,
  p.unit_price,
  ROUND(p.unit_price * q.qty, 2)
FROM eco_urban.orders o
JOIN eco_urban.customers c
  ON c.customer_id = o.customer_id
LEFT JOIN eco_urban.order_items oi
  ON oi.order_id = o.order_id
JOIN (
  SELECT product_id, unit_price
  FROM eco_urban.products
  ORDER BY RAND()
) p ON 1 = 1
JOIN (
  SELECT 1 AS qty UNION ALL SELECT 2 UNION ALL SELECT 3
) q ON 1 = 1
WHERE oi.order_id IS NULL       -- only orders that still have no items
GROUP BY o.order_id, p.product_id, q.qty;

-- Add at least one product per product category
INSERT INTO eco_urban.products (
  product_id, category_id, sku, name, description,
  unit_price, is_active, created_at, updated_at
)
SELECT
  UUID(),
  pc.category_id,
  CONCAT('CAT-', LEFT(REPLACE(pc.category_id, '-', ''), 8)),
  CONCAT(pc.name, ' Sample Item'),
  CONCAT('Sample product for category ', pc.name),
  4.99,
  TRUE,
  TIMESTAMP('2025-11-30 10:00:00'),
  NULL
FROM eco_urban.product_categories pc
LEFT JOIN eco_urban.products p
  ON p.category_id = pc.category_id
WHERE p.product_id IS NULL;

-- Categories with no products
SELECT pc.*
FROM eco_urban.product_categories pc
LEFT JOIN eco_urban.products p
  ON p.category_id = pc.category_id
WHERE p.product_id IS NULL;

-- Products never ordered
SELECT p.*
FROM eco_urban.products p
LEFT JOIN eco_urban.order_items oi
  ON oi.product_id = p.product_id
WHERE oi.order_item_id IS NULL;

-- Products without inventory snapshots
SELECT p.*
FROM eco_urban.products p
LEFT JOIN eco_urban.inventory_snapshots s
  ON s.product_id = p.product_id
WHERE s.snapshot_id IS NULL;

-- Stores with no orders
SELECT s.*
FROM eco_urban.stores s
LEFT JOIN eco_urban.orders o
  ON o.store_id = s.store_id
WHERE o.order_id IS NULL;

-- Stores without inventory snapshots
SELECT s.*
FROM eco_urban.stores s
LEFT JOIN eco_urban.inventory_snapshots inv
  ON inv.store_id = s.store_id
WHERE inv.snapshot_id IS NULL;

-- Customers with no orders
SELECT c.*
FROM eco_urban.customers c
LEFT JOIN eco_urban.orders o
  ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL;

-- Promotions never used
SELECT pr.*
FROM eco_urban.promotions pr
LEFT JOIN eco_urban.orders o
  ON o.promotion_id = pr.promotion_id
WHERE o.order_id IS NULL;
-- Several promotions -> Not an issue

-- Orders without order items
SELECT o.*
FROM eco_urban.orders o
LEFT JOIN eco_urban.order_items oi
  ON oi.order_id = o.order_id
WHERE oi.order_item_id IS NULL;

-- Orders whose totals don’t match item sum (sanity)
SELECT
  o.order_id,
  o.total_amount,
  SUM(oi.line_total) AS calc_total
FROM eco_urban.orders o
LEFT JOIN eco_urban.order_items oi
  ON oi.order_id = o.order_id
GROUP BY o.order_id, o.total_amount
HAVING ABS(o.total_amount - IFNULL(SUM(oi.line_total), 0)) > 0.01;
-- 5 orders


-- Apply promotions to orders
UPDATE eco_urban.orders o
  JOIN (
    SELECT DISTINCT o2.order_id
    FROM eco_urban.orders o2
    JOIN eco_urban.order_items oi
      ON oi.order_id = o2.order_id
    JOIN eco_urban.products p
      ON p.product_id = oi.product_id
    JOIN eco_urban.product_categories pc
      ON pc.category_id = p.category_id
    WHERE pc.name = 'Organic Groceries'
      AND DATE(o2.order_date) BETWEEN '2025-10-15' AND '2025-10-22'
  ) elig
    ON elig.order_id = o.order_id
  SET o.promotion_id = (
    SELECT promotion_id
    FROM eco_urban.promotions
    WHERE name = 'Autumn Organics Week'
    LIMIT 1
  );

-- Recompute orders
UPDATE eco_urban.orders o
JOIN (
  SELECT
    o.order_id,
    COALESCE(SUM(oi.line_total), 0)    AS base_total,
    COALESCE(p.discount_type, 'NONE')  AS discount_type,
    COALESCE(p.discount_value, 0)      AS discount_value
  FROM eco_urban.orders o
  LEFT JOIN eco_urban.order_items oi
    ON oi.order_id = o.order_id
  LEFT JOIN eco_urban.promotions p
    ON p.promotion_id = o.promotion_id
  GROUP BY o.order_id, p.discount_type, p.discount_value
) x ON x.order_id = o.order_id
SET o.total_amount = GREATEST(
  0,
  ROUND(
    x.base_total
      - CASE x.discount_type
          WHEN 'PERCENTAGE' THEN x.base_total * (x.discount_value / 100.0)
          WHEN 'FIXED'      THEN x.discount_value
          ELSE 0
        END,
    2
  )
);

-- Re-check
SELECT
  o.order_id,
  o.order_date,
  o.status,
  o.total_amount,
  COALESCE(SUM(oi.line_total), 0) AS calc_total,
  COALESCE(p.name, '(no promo)') AS promo_name,
  p.discount_type,
  p.discount_value
FROM eco_urban.orders o
LEFT JOIN eco_urban.order_items oi
  ON oi.order_id = o.order_id
LEFT JOIN eco_urban.promotions p
  ON p.promotion_id = o.promotion_id
GROUP BY
  o.order_id, o.order_date, o.status,
  o.total_amount, p.name, p.discount_type, p.discount_value
HAVING ABS(o.total_amount - calc_total) > 0.01;
-- 4 orders

/* FUNCTIONAL QUERIES */

-- Read
-- Orders by client
SELECT
  o.order_id,
  o.order_date,
  o.status,
  c.first_name,
  c.last_name,
  s.name         AS store_name,
  p.sku,
  p.name         AS product_name,
  pc.name        AS category_name,
  oi.quantity,
  oi.unit_price,
  oi.line_total
FROM eco_urban.orders o
JOIN eco_urban.customers c          ON c.customer_id = o.customer_id
JOIN eco_urban.stores s             ON s.store_id    = o.store_id
JOIN eco_urban.order_items oi       ON oi.order_id   = o.order_id
JOIN eco_urban.products p           ON p.product_id  = oi.product_id
JOIN eco_urban.product_categories pc ON pc.category_id = p.category_id
WHERE c.email = 'lena.schmidt@example.com'
ORDER BY o.order_date DESC;

-- Order details
SELECT p.sku, p.name , COUNT(p.sku) as total_ordered , o.order_id , o.order_date , s.name 
FROM eco_urban.order_items oi 
LEFT JOIN eco_urban.products p 
	ON oi.product_id = p.product_id
LEFT JOIN eco_urban.orders o 
	ON o.order_id = oi.order_id 
LEFT JOIN eco_urban.stores s 
	ON o.store_id = s.store_id 
GROUP BY s.name ,p.sku, o.order_id , o.order_date;

-- Select customer_id to populate MongoDB
SELECT customer_id FROM eco_urban.customers c 
LIMIT 17;

-- Select product_id to populate MongoDB
SELECT p.product_id, p.name FROM eco_urban.products p 
ORDER BY p.product_id DESC
LIMIT 17;

-- Update bulk inserted products names and descriptions
UPDATE eco_urban.products p 
SET description = CASE
    WHEN RAND() < 0.25 THEN 'Sustainably sourced personal body care product.'
    WHEN RAND() < 0.50 THEN 'High-quality household item made with environmentally friendly materials.'
    WHEN RAND() < 0.75 THEN 'Reliable daily-use product produced with sustainability standards in mind.'
    ELSE 'Eco-friendly groceries by local producers.'
END
WHERE description LIKE 'Sample product for category Grocery Collection%';

UPDATE eco_urban.products p 
SET description = CASE
    WHEN RAND() < 0.25 THEN 'Sustainably sourced personal body care product.'
    WHEN RAND() < 0.50 THEN 'High-quality household item made with environmentally friendly materials.'
    WHEN RAND() < 0.75 THEN 'Reliable daily-use product produced with sustainability standards in mind.'
    ELSE 'Eco-friendly groceries by local producers.'
END
WHERE description LIKE 'Everyday item from the extended UrbanEco range%';

UPDATE eco_urban.products p 
SET name = CASE
    WHEN RAND() < 0.25 THEN 'Body liquid soap'
    WHEN RAND() < 0.50 THEN 'Body bar soap'
    WHEN RAND() < 0.75 THEN 'Moisturizing shampoo'
    ELSE 'Tooth paste'
END
WHERE description LIKE 'Sustainably sourced personal body care product%';

UPDATE eco_urban.products p 
SET name = CASE
    WHEN RAND() < 0.25 THEN 'Broom'
    WHEN RAND() < 0.50 THEN 'Feather pillow'
    WHEN RAND() < 0.75 THEN 'Thermal bag for women'
    ELSE 'Eco cuttlery'
END
WHERE description LIKE 'High-quality household item made with environmentally friendly materials.';

UPDATE eco_urban.products p 
SET name = CASE
    WHEN RAND() < 0.25 THEN 'Dishes soap'
    WHEN RAND() < 0.50 THEN 'WC cleaner'
    WHEN RAND() < 0.75 THEN 'Glass reiniger'
    ELSE 'Aromatic candles'
END
WHERE description LIKE 'Reliable daily-use product produced with sustainability standards in mind.';

UPDATE eco_urban.products p 
SET name = CASE
    WHEN RAND() < 0.25 THEN 'Local strawberries'
    WHEN RAND() < 0.50 THEN 'Green mountain apples'
    WHEN RAND() < 0.75 THEN 'Eco imported bananas'
    ELSE 'Corn flour'
END
WHERE description LIKE 'Eco-friendly groceries by local producers.';

-- Delete customer by customer_id
DELETE FROM eco_urban.customers
WHERE customer_id IN ('2fd77048-d802-11f0-a768-633afb3a3350');

-- Create new store
INSERT INTO eco_urban.stores (store_id ,name, city, country, address, created_at, is_active) VALUES
  (UUID(),'UrbanEco New Location',   'City',  'Germany', 'Strasse 12',  '2023-04-01', TRUE);

-- Create order With Transaction
START TRANSACTION;

INSERT INTO eco_urban.orders  (
  order_id, store_id, customer_id,
  order_date, status, total_amount, promotion_id
) VALUES (
  @order_id := UUID(),
  (SELECT store_id FROM eco_urban.stores
   WHERE name = 'UrbanEco Berlin Mitte'
   LIMIT 1),
  (SELECT customer_id FROM eco_urban.customers
   WHERE email = 'lena.schmidt@example.com'
   LIMIT 1),
  NOW(),
  'PAID',
  0,
  NULL
);

INSERT INTO eco_urban.order_items (
  order_item_id, product_id, order_id,
  quantity, unit_price, line_total
)
SELECT
  UUID(),
  p.product_id,
  @order_id,
  2 AS quantity,
  p.unit_price,
  p.unit_price * 2
FROM eco_urban.products p
WHERE p.sku = 'OAT-001';

COMMIT;


/* ANALYTICS */
-- Daily revenue per store
SELECT
  s.name                     AS store_name,
  DATE(o.order_date)         AS order_day,
  SUM(o.total_amount)        AS daily_revenue,
  COUNT(DISTINCT o.order_id) AS orders_count
FROM eco_urban.orders o
JOIN eco_urban.stores s ON s.store_id = o.store_id
GROUP BY s.name, DATE(o.order_date)
ORDER BY order_day, store_name;

-- Top 10 products by revenue
SELECT
  p.sku,
  p.name              AS product_name,
  SUM(oi.line_total)  AS total_revenue,
  SUM(oi.quantity)    AS total_units
FROM eco_urban.order_items oi
JOIN eco_urban.products p ON p.product_id = oi.product_id
GROUP BY p.product_id, p.sku, p.name
ORDER BY total_revenue DESC
LIMIT 10;

-- Revenue by category and month
SELECT
  pc.name                            AS category_name,
  DATE_FORMAT(o.order_date, '%Y-%m') AS date,
  SUM(oi.line_total)                 AS category_revenue
FROM eco_urban.order_items oi
JOIN eco_urban.orders o           ON o.order_id    = oi.order_id
JOIN eco_urban.products p         ON p.product_id  = oi.product_id
JOIN eco_urban.product_categories pc ON pc.category_id = p.category_id
GROUP BY pc.name, DATE_FORMAT(o.order_date, '%Y-%m')
ORDER BY date, category_name;