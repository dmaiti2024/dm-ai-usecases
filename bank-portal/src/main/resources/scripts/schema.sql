-- Wells Fargo Bank Portal - PostgreSQL Schema
-- Database: bank_db
-- Run: psql bank_db -f schema.sql

-- ─── Extensions ───────────────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS vector;

-- ─── Tables ───────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS CUSTOMER (
    customer_id   BIGSERIAL PRIMARY KEY,
    username      VARCHAR(50)  UNIQUE NOT NULL,
    password      VARCHAR(100) NOT NULL,
    full_name     VARCHAR(100),
    email         VARCHAR(100),
    phone         VARCHAR(20),
    address       TEXT,
    customer_type VARCHAR(20) DEFAULT 'CUSTOMER',
    created_date  TIMESTAMP   DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS BANK_ACCOUNT (
    account_id        BIGSERIAL PRIMARY KEY,
    customer_id       BIGINT REFERENCES CUSTOMER(customer_id),
    account_number    VARCHAR(20) UNIQUE NOT NULL,
    account_type      VARCHAR(30),
    balance           DECIMAL(12,2) DEFAULT 0.00,
    available_balance DECIMAL(12,2) DEFAULT 0.00,
    account_status    VARCHAR(20) DEFAULT 'ACTIVE',
    opened_date       DATE
);

CREATE TABLE IF NOT EXISTS BANK_TRANSACTION (
    transaction_id   BIGSERIAL PRIMARY KEY,
    account_id       BIGINT REFERENCES BANK_ACCOUNT(account_id),
    transaction_date TIMESTAMP    NOT NULL,
    transaction_type VARCHAR(10)  NOT NULL,
    amount           DECIMAL(12,2) NOT NULL,
    description      VARCHAR(200),
    category         VARCHAR(50),
    merchant_name    VARCHAR(100),
    reference_no     VARCHAR(50),
    status           VARCHAR(20) DEFAULT 'COMPLETED',
    created_at       TIMESTAMP   DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS DISPUTE (
    dispute_id     BIGSERIAL PRIMARY KEY,
    transaction_id BIGINT REFERENCES BANK_TRANSACTION(transaction_id),
    customer_id    BIGINT REFERENCES CUSTOMER(customer_id),
    raised_by      VARCHAR(50),
    dispute_reason TEXT,
    dispute_status VARCHAR(20) DEFAULT 'OPEN',
    resolution     TEXT,
    raised_date    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_date  TIMESTAMP
);

CREATE TABLE IF NOT EXISTS RAG_INDEX_TRACKER (
    id                          INTEGER PRIMARY KEY,
    last_indexed_transaction_id BIGINT DEFAULT 0
);

-- ─── Seed: RAG tracker ────────────────────────────────────────────────────────
INSERT INTO RAG_INDEX_TRACKER (id, last_indexed_transaction_id)
VALUES (1, 0)
ON CONFLICT (id) DO NOTHING;

-- ─── Seed: Customers ──────────────────────────────────────────────────────────
-- password: password123
INSERT INTO CUSTOMER (username, password, full_name, email, phone, address, customer_type, created_date)
VALUES
('john.smith',    '$2b$10$GZ3l8n6GmhFm9UfyxZHoRuamUB8HEnmAkm7yty9srr6qvAV/Yy.Ty', 'John Smith',    'john.smith@email.com',    '415-555-0101', '1234 Market St, San Francisco, CA 94102', 'CUSTOMER', '2023-01-15 10:00:00'),
('sarah.johnson', '$2b$10$GZ3l8n6GmhFm9UfyxZHoRuamUB8HEnmAkm7yty9srr6qvAV/Yy.Ty', 'Sarah Johnson', 'sarah.johnson@email.com', '415-555-0202', '5678 Oak Ave, San Francisco, CA 94117',  'CUSTOMER', '2023-03-20 11:00:00'),
('helpdesk',      '$2b$10$GZ3l8n6GmhFm9UfyxZHoRuamUB8HEnmAkm7yty9srr6qvAV/Yy.Ty', 'Help Desk',     'helpdesk@wellsfargo.com', '800-555-0100', 'Wells Fargo HQ, San Francisco, CA',       'HELPDESK', '2023-01-01 09:00:00')
ON CONFLICT (username) DO NOTHING;

-- ─── Seed: Bank Accounts ──────────────────────────────────────────────────────
INSERT INTO BANK_ACCOUNT (customer_id, account_number, account_type, balance, available_balance, account_status, opened_date)
VALUES
(1, '4012001234567890', 'CHECKING', 15420.50, 15420.50, 'ACTIVE', '2023-01-15'),
(1, '4012001234567891', 'SAVINGS',  42000.00, 42000.00, 'ACTIVE', '2023-01-15'),
(2, '4012009876543210', 'CHECKING', 8750.25,  8750.25,  'ACTIVE', '2023-03-20'),
(2, '4012009876543211', 'SAVINGS',  18500.00, 18500.00, 'ACTIVE', '2023-03-20')
ON CONFLICT (account_number) DO NOTHING;

-- ─── Seed: Transactions ───────────────────────────────────────────────────────
-- John Smith (account_id=1 CHECKING, account_id=2 SAVINGS)
-- 2024 transactions
INSERT INTO BANK_TRANSACTION (account_id, transaction_date, transaction_type, amount, description, category, merchant_name, reference_no, status) VALUES
-- Jan 2024
(1,'2024-01-02 09:00:00','CREDIT', 8500.00,'Payroll Direct Deposit','',                  'Acme Corp',            'PAY202401001','COMPLETED'),
(1,'2024-01-03 11:30:00','DEBIT',  2100.00,'Mortgage Payment Jan 2024','Mortgage',       'Wells Fargo Mortgage', 'MTG202401001','COMPLETED'),
(1,'2024-01-05 09:15:00','DEBIT',   185.50,'PG&E Electric Bill',      'Utility',         'PG&E',                 'UTL202401001','COMPLETED'),
(1,'2024-01-06 13:20:00','DEBIT',   312.75,'Safeway Grocery',         'Household',         'Safeway',              'GRC202401001','COMPLETED'),
(1,'2024-01-08 19:45:00','DEBIT',    89.50,'Cheesecake Factory Dinner','Restaurant',     'Cheesecake Factory',   'RST202401001','COMPLETED'),
(1,'2024-01-10 10:00:00','DEBIT',   450.00,'Nordstrom Clothing',      'Dress',           'Nordstrom',            'DRS202401001','COMPLETED'),
(1,'2024-01-15 16:30:00','DEBIT',    45.99,'Amazon Prime Subscription','Misc',           'Amazon',               'MSC202401001','COMPLETED'),
(1,'2024-01-18 14:00:00','DEBIT',   275.00,'Whole Foods Market',      'Household',         'Whole Foods',          'GRC202401002','COMPLETED'),
(1,'2024-01-20 20:15:00','DEBIT',   125.00,'The Capital Grille Dinner','Restaurant',     'The Capital Grille',   'RST202401002','COMPLETED'),
(1,'2024-01-25 11:00:00','DEBIT',    95.00,'Comcast Internet Bill',   'Utility',         'Comcast',              'UTL202401002','COMPLETED'),
-- Feb 2024
(1,'2024-02-01 09:00:00','CREDIT', 8500.00,'Payroll Direct Deposit',  '',                'Acme Corp',            'PAY202402001','COMPLETED'),
(1,'2024-02-02 10:00:00','DEBIT',  2100.00,'Mortgage Payment Feb 2024','Mortgage',       'Wells Fargo Mortgage', 'MTG202402001','COMPLETED'),
(1,'2024-02-05 09:30:00','DEBIT',   178.25,'PG&E Electric Bill',      'Utility',         'PG&E',                 'UTL202402001','COMPLETED'),
(1,'2024-02-08 12:00:00','DEBIT',   298.50,'Safeway Grocery',         'Household',         'Safeway',              'GRC202402001','COMPLETED'),
(1,'2024-02-10 19:00:00','DEBIT',   145.00,'Nobu Restaurant',         'Restaurant',      'Nobu',                 'RST202402001','COMPLETED'),
(1,'2024-02-14 15:00:00','DEBIT',   225.00,'Bloomingdales Valentine', 'Dress',           'Bloomingdales',        'DRS202402001','COMPLETED'),
(1,'2024-02-20 11:00:00','DEBIT',   185.00,'Trader Joes',             'Household',         'Trader Joes',          'GRC202402002','COMPLETED'),
(1,'2024-02-25 09:00:00','DEBIT',    75.00,'Netflix Annual Plan',     'Misc',            'Netflix',              'MSC202402001','COMPLETED'),
-- Mar 2024
(1,'2024-03-01 09:00:00','CREDIT', 8500.00,'Payroll Direct Deposit',  '',                'Acme Corp',            'PAY202403001','COMPLETED'),
(1,'2024-03-03 10:00:00','DEBIT',  2100.00,'Mortgage Payment Mar 2024','Mortgage',       'Wells Fargo Mortgage', 'MTG202403001','COMPLETED'),
(1,'2024-03-06 09:45:00','DEBIT',   192.00,'PG&E Electric Bill',      'Utility',         'PG&E',                 'UTL202403001','COMPLETED'),
(1,'2024-03-10 13:00:00','DEBIT',   325.00,'Costco Grocery',          'Household',         'Costco',               'GRC202403001','COMPLETED'),
(1,'2024-03-15 20:00:00','DEBIT',   195.00,'Morton Steakhouse',       'Restaurant',      'Morton Steakhouse',    'RST202403001','COMPLETED'),
(1,'2024-03-20 14:00:00','DEBIT',   580.00,'Macy Spring Collection',  'Dress',           'Macys',                'DRS202403001','COMPLETED'),
(1,'2024-03-25 10:00:00','DEBIT',   110.00,'Comcast Internet + TV',   'Utility',         'Comcast',              'UTL202403002','COMPLETED'),
-- Apr 2024
(1,'2024-04-01 09:00:00','CREDIT', 8500.00,'Payroll Direct Deposit',  '',                'Acme Corp',            'PAY202404001','COMPLETED'),
(1,'2024-04-03 10:00:00','DEBIT',  2100.00,'Mortgage Payment Apr 2024','Mortgage',       'Wells Fargo Mortgage', 'MTG202404001','COMPLETED'),
(1,'2024-04-05 09:30:00','DEBIT',   165.00,'PG&E Electric Bill',      'Utility',         'PG&E',                 'UTL202404001','COMPLETED'),
(1,'2024-04-10 12:30:00','DEBIT',   280.00,'Safeway Grocery',         'Household',         'Safeway',              'GRC202404001','COMPLETED'),
(1,'2024-04-15 19:30:00','DEBIT',   115.00,'Benu Restaurant',         'Restaurant',      'Benu',                 'RST202404001','COMPLETED'),
(1,'2024-04-20 11:00:00','DEBIT',   350.00,'Gap Spring Sale',         'Dress',           'Gap',                  'DRS202404001','COMPLETED'),
-- May 2024
(1,'2024-05-01 09:00:00','CREDIT', 8500.00,'Payroll Direct Deposit',  '',                'Acme Corp',            'PAY202405001','COMPLETED'),
(1,'2024-05-03 10:00:00','DEBIT',  2100.00,'Mortgage Payment May 2024','Mortgage',       'Wells Fargo Mortgage', 'MTG202405001','COMPLETED'),
(1,'2024-05-06 09:00:00','DEBIT',   175.00,'PG&E Electric Bill',      'Utility',         'PG&E',                 'UTL202405001','COMPLETED'),
(1,'2024-05-10 13:00:00','DEBIT',   295.00,'Whole Foods Market',      'Household',         'Whole Foods',          'GRC202405001','COMPLETED'),
(1,'2024-05-15 20:30:00','DEBIT',   175.00,'Nopalito Mexican',        'Restaurant',      'Nopalito',             'RST202405001','COMPLETED'),
(1,'2024-05-20 15:00:00','DEBIT',   420.00,'Nordstrom Rack',          'Dress',           'Nordstrom Rack',       'DRS202405001','COMPLETED'),
(1,'2024-05-25 11:00:00','DEBIT',    85.00,'Amazon Prime',            'Misc',            'Amazon',               'MSC202405001','COMPLETED'),
-- Jun 2024
(1,'2024-06-03 09:00:00','CREDIT', 8500.00,'Payroll Direct Deposit',  '',                'Acme Corp',            'PAY202406001','COMPLETED'),
(1,'2024-06-04 10:00:00','DEBIT',  2100.00,'Mortgage Payment Jun 2024','Mortgage',       'Wells Fargo Mortgage', 'MTG202406001','COMPLETED'),
(1,'2024-06-05 09:30:00','DEBIT',   180.00,'PG&E Electric Bill',      'Utility',         'PG&E',                 'UTL202406001','COMPLETED'),
(1,'2024-06-10 12:00:00','DEBIT',   310.00,'Safeway Grocery',         'Household',         'Safeway',              'GRC202406001','COMPLETED'),
(1,'2024-06-15 19:00:00','DEBIT',   225.00,'State Bird Provisions',   'Restaurant',      'State Bird Provisions','RST202406001','COMPLETED'),
(1,'2024-06-20 14:00:00','DEBIT',   495.00,'Banana Republic Summer',  'Dress',           'Banana Republic',      'DRS202406001','COMPLETED'),
-- Jul 2024
(1,'2024-07-01 09:00:00','CREDIT', 8500.00,'Payroll Direct Deposit',  '',                'Acme Corp',            'PAY202407001','COMPLETED'),
(1,'2024-07-03 10:00:00','DEBIT',  2100.00,'Mortgage Payment Jul 2024','Mortgage',       'Wells Fargo Mortgage', 'MTG202407001','COMPLETED'),
(1,'2024-07-05 09:30:00','DEBIT',   210.00,'PG&E Electric Bill',      'Utility',         'PG&E',                 'UTL202407001','COMPLETED'),
(1,'2024-07-10 12:30:00','DEBIT',   265.00,'Costco Grocery',          'Household',         'Costco',               'GRC202407001','COMPLETED'),
(1,'2024-07-15 20:00:00','DEBIT',   195.00,'Atelier Crenn',           'Restaurant',      'Atelier Crenn',        'RST202407001','COMPLETED'),
(1,'2024-07-18 14:00:00','DEBIT',   125.00,'Amazon Misc Purchase',    'Misc',            'Amazon',               'MSC202407001','COMPLETED'),
-- Aug 2024
(1,'2024-08-01 09:00:00','CREDIT', 8500.00,'Payroll Direct Deposit',  '',                'Acme Corp',            'PAY202408001','COMPLETED'),
(1,'2024-08-02 10:00:00','DEBIT',  2100.00,'Mortgage Payment Aug 2024','Mortgage',       'Wells Fargo Mortgage', 'MTG202408001','COMPLETED'),
(1,'2024-08-05 09:00:00','DEBIT',   225.00,'PG&E Electric Bill',      'Utility',         'PG&E',                 'UTL202408001','COMPLETED'),
(1,'2024-08-10 12:00:00','DEBIT',   340.00,'Whole Foods Market',      'Household',         'Whole Foods',          'GRC202408001','COMPLETED'),
(1,'2024-08-15 19:30:00','DEBIT',   165.00,'Anchor and Hope',         'Restaurant',      'Anchor and Hope',      'RST202408001','COMPLETED'),
(1,'2024-08-20 15:00:00','DEBIT',   640.00,'Back to School Shopping', 'Dress',           'Macys',                'DRS202408001','COMPLETED'),
-- Sep 2024
(1,'2024-09-02 09:00:00','CREDIT', 8500.00,'Payroll Direct Deposit',  '',                'Acme Corp',            'PAY202409001','COMPLETED'),
(1,'2024-09-03 10:00:00','DEBIT',  2100.00,'Mortgage Payment Sep 2024','Mortgage',       'Wells Fargo Mortgage', 'MTG202409001','COMPLETED'),
(1,'2024-09-05 09:30:00','DEBIT',   190.00,'PG&E Electric Bill',      'Utility',         'PG&E',                 'UTL202409001','COMPLETED'),
(1,'2024-09-10 12:00:00','DEBIT',   290.00,'Safeway Grocery',         'Household',         'Safeway',              'GRC202409001','COMPLETED'),
(1,'2024-09-15 19:00:00','DEBIT',   175.00,'Cotogna Restaurant',      'Restaurant',      'Cotogna',              'RST202409001','COMPLETED'),
(1,'2024-09-20 11:00:00','DEBIT',    55.00,'Netflix Subscription',    'Misc',            'Netflix',              'MSC202409001','COMPLETED'),
-- Oct 2024
(1,'2024-10-01 09:00:00','CREDIT', 8500.00,'Payroll Direct Deposit',  '',                'Acme Corp',            'PAY202410001','COMPLETED'),
(1,'2024-10-03 10:00:00','DEBIT',  2100.00,'Mortgage Payment Oct 2024','Mortgage',       'Wells Fargo Mortgage', 'MTG202410001','COMPLETED'),
(1,'2024-10-05 09:30:00','DEBIT',   185.00,'PG&E Electric Bill',      'Utility',         'PG&E',                 'UTL202410001','COMPLETED'),
(1,'2024-10-10 12:30:00','DEBIT',   305.00,'Whole Foods Market',      'Household',         'Whole Foods',          'GRC202410001','COMPLETED'),
(1,'2024-10-15 20:00:00','DEBIT',   225.00,'Gary Danko Restaurant',   'Restaurant',      'Gary Danko',           'RST202410001','COMPLETED'),
(1,'2024-10-20 14:00:00','DEBIT',   480.00,'Fall Collection Shopping','Dress',           'Nordstrom',            'DRS202410001','COMPLETED'),
-- Nov 2024
(1,'2024-11-01 09:00:00','CREDIT', 8500.00,'Payroll Direct Deposit',  '',                'Acme Corp',            'PAY202411001','COMPLETED'),
(1,'2024-11-03 10:00:00','DEBIT',  2100.00,'Mortgage Payment Nov 2024','Mortgage',       'Wells Fargo Mortgage', 'MTG202411001','COMPLETED'),
(1,'2024-11-05 09:30:00','DEBIT',   198.00,'PG&E Electric Bill',      'Utility',         'PG&E',                 'UTL202411001','COMPLETED'),
(1,'2024-11-10 12:00:00','DEBIT',   425.00,'Costco Thanksgiving',     'Household',         'Costco',               'GRC202411001','COMPLETED'),
(1,'2024-11-15 19:30:00','DEBIT',   285.00,'Michael Mina',            'Restaurant',      'Michael Mina',         'RST202411001','COMPLETED'),
(1,'2024-11-25 14:00:00','DEBIT',   780.00,'Black Friday Nordstrom',  'Dress',           'Nordstrom',            'DRS202411001','COMPLETED'),
(1,'2024-11-28 12:00:00','DEBIT',   125.00,'Amazon Black Friday',     'Misc',            'Amazon',               'MSC202411001','COMPLETED'),
-- Dec 2024
(1,'2024-12-02 09:00:00','CREDIT', 8500.00,'Payroll Direct Deposit',  '',                'Acme Corp',            'PAY202412001','COMPLETED'),
(1,'2024-12-02 09:05:00','CREDIT', 5000.00,'Year End Bonus',          '',                'Acme Corp',            'BONUS202412','COMPLETED'),
(1,'2024-12-03 10:00:00','DEBIT',  2100.00,'Mortgage Payment Dec 2024','Mortgage',       'Wells Fargo Mortgage', 'MTG202412001','COMPLETED'),
(1,'2024-12-05 09:30:00','DEBIT',   215.00,'PG&E Electric Bill',      'Utility',         'PG&E',                 'UTL202412001','COMPLETED'),
(1,'2024-12-10 12:00:00','DEBIT',   350.00,'Whole Foods Holiday',     'Household',         'Whole Foods',          'GRC202412001','COMPLETED'),
(1,'2024-12-15 20:00:00','DEBIT',   350.00,'Acquerello Restaurant',   'Restaurant',      'Acquerello',           'RST202412001','COMPLETED'),
(1,'2024-12-20 15:00:00','DEBIT',  1250.00,'Holiday Gift Shopping',   'Dress',           'Nordstrom',            'DRS202412001','COMPLETED'),
(1,'2024-12-22 11:00:00','DEBIT',   245.00,'Amazon Holiday Gifts',    'Misc',            'Amazon',               'MSC202412001','COMPLETED'),
-- 2025 transactions John Smith
(1,'2025-01-02 09:00:00','CREDIT', 9000.00,'Payroll Direct Deposit',  '',                'Acme Corp',            'PAY202501001','COMPLETED'),
(1,'2025-01-03 10:00:00','DEBIT',  2200.00,'Mortgage Payment Jan 2025','Mortgage',       'Wells Fargo Mortgage', 'MTG202501001','COMPLETED'),
(1,'2025-01-05 09:30:00','DEBIT',   195.00,'PG&E Electric Bill',      'Utility',         'PG&E',                 'UTL202501001','COMPLETED'),
(1,'2025-01-10 12:00:00','DEBIT',   315.00,'Safeway Grocery',         'Household',         'Safeway',              'GRC202501001','COMPLETED'),
(1,'2025-01-15 19:30:00','DEBIT',   185.00,'Zuni Cafe',               'Restaurant',      'Zuni Cafe',            'RST202501001','COMPLETED'),
(1,'2025-01-20 14:00:00','DEBIT',   390.00,'Winter Sale Shopping',    'Dress',           'Macys',                'DRS202501001','COMPLETED'),
(1,'2025-02-03 09:00:00','CREDIT', 9000.00,'Payroll Direct Deposit',  '',                'Acme Corp',            'PAY202502001','COMPLETED'),
(1,'2025-02-04 10:00:00','DEBIT',  2200.00,'Mortgage Payment Feb 2025','Mortgage',       'Wells Fargo Mortgage', 'MTG202502001','COMPLETED'),
(1,'2025-02-05 09:30:00','DEBIT',   182.00,'PG&E Electric Bill',      'Utility',         'PG&E',                 'UTL202502001','COMPLETED'),
(1,'2025-02-10 12:30:00','DEBIT',   290.00,'Whole Foods Market',      'Household',         'Whole Foods',          'GRC202502001','COMPLETED'),
(1,'2025-02-14 19:00:00','DEBIT',   320.00,'Valentine Dinner Bix',    'Restaurant',      'Bix Restaurant',       'RST202502001','COMPLETED'),
(1,'2025-03-03 09:00:00','CREDIT', 9000.00,'Payroll Direct Deposit',  '',                'Acme Corp',            'PAY202503001','COMPLETED'),
(1,'2025-03-04 10:00:00','DEBIT',  2200.00,'Mortgage Payment Mar 2025','Mortgage',       'Wells Fargo Mortgage', 'MTG202503001','COMPLETED'),
(1,'2025-03-05 09:30:00','DEBIT',   188.00,'PG&E Electric Bill',      'Utility',         'PG&E',                 'UTL202503001','COMPLETED'),
(1,'2025-03-10 12:00:00','DEBIT',   335.00,'Costco Grocery',          'Household',         'Costco',               'GRC202503001','COMPLETED'),
(1,'2025-03-15 20:00:00','DEBIT',   225.00,'Quince Restaurant',       'Restaurant',      'Quince',               'RST202503001','COMPLETED'),
(1,'2025-03-20 15:00:00','DEBIT',   460.00,'Spring Collection',       'Dress',           'Banana Republic',      'DRS202503001','COMPLETED'),
(1,'2025-04-01 09:00:00','CREDIT', 9000.00,'Payroll Direct Deposit',  '',                'Acme Corp',            'PAY202504001','COMPLETED'),
(1,'2025-04-03 10:00:00','DEBIT',  2200.00,'Mortgage Payment Apr 2025','Mortgage',       'Wells Fargo Mortgage', 'MTG202504001','COMPLETED'),
(1,'2025-04-05 09:30:00','DEBIT',   172.00,'PG&E Electric Bill',      'Utility',         'PG&E',                 'UTL202504001','COMPLETED'),
(1,'2025-04-10 12:00:00','DEBIT',   285.00,'Safeway Grocery',         'Household',         'Safeway',              'GRC202504001','COMPLETED'),
(1,'2025-04-15 19:30:00','DEBIT',   155.00,'Mission Chinese',         'Restaurant',      'Mission Chinese',      'RST202504001','COMPLETED'),
(1,'2025-05-01 09:00:00','CREDIT', 9000.00,'Payroll Direct Deposit',  '',                'Acme Corp',            'PAY202505001','COMPLETED'),
(1,'2025-05-03 10:00:00','DEBIT',  2200.00,'Mortgage Payment May 2025','Mortgage',       'Wells Fargo Mortgage', 'MTG202505001','COMPLETED'),
(1,'2025-05-05 09:00:00','DEBIT',   179.00,'PG&E Electric Bill',      'Utility',         'PG&E',                 'UTL202505001','COMPLETED'),
(1,'2025-05-10 12:30:00','DEBIT',   310.00,'Whole Foods Market',      'Household',         'Whole Foods',          'GRC202505001','COMPLETED'),
(1,'2025-05-15 19:00:00','DEBIT',   195.00,'SPQR Restaurant',         'Restaurant',      'SPQR',                 'RST202505001','COMPLETED'),
(1,'2025-05-20 14:00:00','DEBIT',   520.00,'Summer Wardrobe',         'Dress',           'Nordstrom',            'DRS202505001','COMPLETED'),
(1,'2025-06-02 09:00:00','CREDIT', 9000.00,'Payroll Direct Deposit',  '',                'Acme Corp',            'PAY202506001','COMPLETED'),
(1,'2025-06-03 10:00:00','DEBIT',  2200.00,'Mortgage Payment Jun 2025','Mortgage',       'Wells Fargo Mortgage', 'MTG202506001','COMPLETED'),
(1,'2025-06-05 09:30:00','DEBIT',   183.00,'PG&E Electric Bill',      'Utility',         'PG&E',                 'UTL202506001','COMPLETED'),
(1,'2025-06-10 12:00:00','DEBIT',   295.00,'Safeway Grocery',         'Household',         'Safeway',              'GRC202506001','COMPLETED'),
(1,'2025-07-01 09:00:00','CREDIT', 9000.00,'Payroll Direct Deposit',  '',                'Acme Corp',            'PAY202507001','COMPLETED'),
(1,'2025-07-03 10:00:00','DEBIT',  2200.00,'Mortgage Payment Jul 2025','Mortgage',       'Wells Fargo Mortgage', 'MTG202507001','COMPLETED'),
(1,'2025-07-05 09:30:00','DEBIT',   218.00,'PG&E Summer Bill',        'Utility',         'PG&E',                 'UTL202507001','COMPLETED'),
(1,'2025-07-10 12:30:00','DEBIT',   270.00,'Costco Grocery',          'Household',         'Costco',               'GRC202507001','COMPLETED'),
(1,'2025-08-01 09:00:00','CREDIT', 9000.00,'Payroll Direct Deposit',  '',                'Acme Corp',            'PAY202508001','COMPLETED'),
(1,'2025-08-04 10:00:00','DEBIT',  2200.00,'Mortgage Payment Aug 2025','Mortgage',       'Wells Fargo Mortgage', 'MTG202508001','COMPLETED'),
(1,'2025-08-05 09:30:00','DEBIT',   230.00,'PG&E August Bill',        'Utility',         'PG&E',                 'UTL202508001','COMPLETED'),
(1,'2025-08-10 12:00:00','DEBIT',   345.00,'Whole Foods Market',      'Household',         'Whole Foods',          'GRC202508001','COMPLETED'),
(1,'2025-08-20 15:00:00','DEBIT',   685.00,'Back to School',          'Dress',           'Nordstrom',            'DRS202508001','COMPLETED'),
(1,'2025-09-01 09:00:00','CREDIT', 9000.00,'Payroll Direct Deposit',  '',                'Acme Corp',            'PAY202509001','COMPLETED'),
(1,'2025-09-03 10:00:00','DEBIT',  2200.00,'Mortgage Payment Sep 2025','Mortgage',       'Wells Fargo Mortgage', 'MTG202509001','COMPLETED'),
(1,'2025-09-05 09:30:00','DEBIT',   193.00,'PG&E Electric Bill',      'Utility',         'PG&E',                 'UTL202509001','COMPLETED'),
(1,'2025-09-10 12:00:00','DEBIT',   305.00,'Safeway Grocery',         'Household',         'Safeway',              'GRC202509001','COMPLETED'),
(1,'2025-10-01 09:00:00','CREDIT', 9000.00,'Payroll Direct Deposit',  '',                'Acme Corp',            'PAY202510001','COMPLETED'),
(1,'2025-10-03 10:00:00','DEBIT',  2200.00,'Mortgage Payment Oct 2025','Mortgage',       'Wells Fargo Mortgage', 'MTG202510001','COMPLETED'),
(1,'2025-10-05 09:30:00','DEBIT',   188.00,'PG&E Electric Bill',      'Utility',         'PG&E',                 'UTL202510001','COMPLETED'),
(1,'2025-10-10 12:30:00','DEBIT',   310.00,'Whole Foods Market',      'Household',         'Whole Foods',          'GRC202510001','COMPLETED'),
(1,'2025-10-15 19:30:00','DEBIT',   235.00,'Bix Restaurant',          'Restaurant',      'Bix Restaurant',       'RST202510001','COMPLETED'),
(1,'2025-10-20 14:00:00','DEBIT',   505.00,'Fall Shopping Nordstrom', 'Dress',           'Nordstrom',            'DRS202510001','COMPLETED'),
(1,'2025-11-03 09:00:00','CREDIT', 9000.00,'Payroll Direct Deposit',  '',                'Acme Corp',            'PAY202511001','COMPLETED'),
(1,'2025-11-04 10:00:00','DEBIT',  2200.00,'Mortgage Payment Nov 2025','Mortgage',       'Wells Fargo Mortgage', 'MTG202511001','COMPLETED'),
(1,'2025-11-05 09:30:00','DEBIT',   202.00,'PG&E Electric Bill',      'Utility',         'PG&E',                 'UTL202511001','COMPLETED'),
(1,'2025-11-10 12:00:00','DEBIT',   455.00,'Costco Thanksgiving',     'Household',         'Costco',               'GRC202511001','COMPLETED'),
(1,'2025-11-25 15:00:00','DEBIT',   820.00,'Black Friday Shopping',   'Dress',           'Nordstrom',            'DRS202511001','COMPLETED'),
(1,'2025-12-01 09:00:00','CREDIT', 9000.00,'Payroll Direct Deposit',  '',                'Acme Corp',            'PAY202512001','COMPLETED'),
(1,'2025-12-01 09:05:00','CREDIT', 6000.00,'Year End Bonus 2025',     '',                'Acme Corp',            'BONUS202512','COMPLETED'),
(1,'2025-12-03 10:00:00','DEBIT',  2200.00,'Mortgage Payment Dec 2025','Mortgage',       'Wells Fargo Mortgage', 'MTG202512001','COMPLETED'),
(1,'2025-12-05 09:30:00','DEBIT',   220.00,'PG&E Electric Bill',      'Utility',         'PG&E',                 'UTL202512001','COMPLETED'),
(1,'2025-12-10 12:00:00','DEBIT',   375.00,'Whole Foods Holiday',     'Household',         'Whole Foods',          'GRC202512001','COMPLETED'),
(1,'2025-12-20 15:00:00','DEBIT',  1350.00,'Holiday Gift Shopping',   'Dress',           'Nordstrom',            'DRS202512001','COMPLETED'),
-- 2026 Jan-Jun John Smith
(1,'2026-01-02 09:00:00','CREDIT', 9000.00,'Payroll Direct Deposit',  '',                'Acme Corp',            'PAY202601001','COMPLETED'),
(1,'2026-01-03 10:00:00','DEBIT',  2200.00,'Mortgage Payment Jan 2026','Mortgage',       'Wells Fargo Mortgage', 'MTG202601001','COMPLETED'),
(1,'2026-01-05 09:30:00','DEBIT',   200.00,'PG&E Electric Bill',      'Utility',         'PG&E',                 'UTL202601001','COMPLETED'),
(1,'2026-01-10 12:00:00','DEBIT',   320.00,'Safeway Grocery',         'Household',         'Safeway',              'GRC202601001','COMPLETED'),
(1,'2026-01-15 19:30:00','DEBIT',   210.00,'Nopa Restaurant',         'Restaurant',      'Nopa',                 'RST202601001','COMPLETED'),
(1,'2026-02-03 09:00:00','CREDIT', 9000.00,'Payroll Direct Deposit',  '',                'Acme Corp',            'PAY202602001','COMPLETED'),
(1,'2026-02-04 10:00:00','DEBIT',  2200.00,'Mortgage Payment Feb 2026','Mortgage',       'Wells Fargo Mortgage', 'MTG202602001','COMPLETED'),
(1,'2026-02-05 09:30:00','DEBIT',   187.00,'PG&E Electric Bill',      'Utility',         'PG&E',                 'UTL202602001','COMPLETED'),
(1,'2026-02-10 12:00:00','DEBIT',   295.00,'Whole Foods Market',      'Household',         'Whole Foods',          'GRC202602001','COMPLETED'),
(1,'2026-03-03 09:00:00','CREDIT', 9000.00,'Payroll Direct Deposit',  '',                'Acme Corp',            'PAY202603001','COMPLETED'),
(1,'2026-03-04 10:00:00','DEBIT',  2200.00,'Mortgage Payment Mar 2026','Mortgage',       'Wells Fargo Mortgage', 'MTG202603001','COMPLETED'),
(1,'2026-03-05 09:30:00','DEBIT',   191.00,'PG&E Electric Bill',      'Utility',         'PG&E',                 'UTL202603001','COMPLETED'),
(1,'2026-03-10 12:00:00','DEBIT',   340.00,'Costco Grocery',          'Household',         'Costco',               'GRC202603001','COMPLETED'),
(1,'2026-04-01 09:00:00','CREDIT', 9000.00,'Payroll Direct Deposit',  '',                'Acme Corp',            'PAY202604001','COMPLETED'),
(1,'2026-04-03 10:00:00','DEBIT',  2200.00,'Mortgage Payment Apr 2026','Mortgage',       'Wells Fargo Mortgage', 'MTG202604001','COMPLETED'),
(1,'2026-04-05 09:30:00','DEBIT',   170.00,'PG&E Electric Bill',      'Utility',         'PG&E',                 'UTL202604001','COMPLETED'),
(1,'2026-04-10 12:30:00','DEBIT',   285.00,'Safeway Grocery',         'Household',         'Safeway',              'GRC202604001','COMPLETED'),
(1,'2026-05-01 09:00:00','CREDIT', 9000.00,'Payroll Direct Deposit',  '',                'Acme Corp',            'PAY202605001','COMPLETED'),
(1,'2026-05-03 10:00:00','DEBIT',  2200.00,'Mortgage Payment May 2026','Mortgage',       'Wells Fargo Mortgage', 'MTG202605001','COMPLETED'),
(1,'2026-05-05 09:00:00','DEBIT',   181.00,'PG&E Electric Bill',      'Utility',         'PG&E',                 'UTL202605001','COMPLETED'),
(1,'2026-05-10 12:00:00','DEBIT',   305.00,'Whole Foods Market',      'Household',         'Whole Foods',          'GRC202605001','COMPLETED'),
(1,'2026-05-15 19:30:00','DEBIT',   205.00,'Hog Island Oyster Co',    'Restaurant',      'Hog Island Oyster Co', 'RST202605001','COMPLETED'),
(1,'2026-05-20 14:00:00','DEBIT',   545.00,'Spring Summer Shopping',  'Dress',           'Nordstrom',            'DRS202605001','COMPLETED'),
(1,'2026-06-02 09:00:00','CREDIT', 9000.00,'Payroll Direct Deposit',  '',                'Acme Corp',            'PAY202606001','COMPLETED'),
(1,'2026-06-03 10:00:00','DEBIT',  2200.00,'Mortgage Payment Jun 2026','Mortgage',       'Wells Fargo Mortgage', 'MTG202606001','COMPLETED'),
(1,'2026-06-05 09:30:00','DEBIT',   186.00,'PG&E Electric Bill',      'Utility',         'PG&E',                 'UTL202606001','COMPLETED'),
(1,'2026-06-10 12:00:00','DEBIT',   315.00,'Safeway Grocery',         'Household',         'Safeway',              'GRC202606001','COMPLETED');

-- Sarah Johnson (account_id=3 CHECKING, account_id=4 SAVINGS)
INSERT INTO BANK_TRANSACTION (account_id, transaction_date, transaction_type, amount, description, category, merchant_name, reference_no, status) VALUES
-- 2024 Jan Sarah
(3,'2024-01-03 09:00:00','CREDIT', 5500.00,'Payroll Direct Deposit',  '',             'TechStart Inc',        'SPAY202401001','COMPLETED'),
(3,'2024-01-05 10:00:00','DEBIT',  1450.00,'Rent Payment Jan 2024',   'Mortgage',     'SF Properties LLC',    'SRNT202401001','COMPLETED'),
(3,'2024-01-06 09:30:00','DEBIT',   145.00,'PG&E Electric Bill',      'Utility',      'PG&E',                 'SUTL202401001','COMPLETED'),
(3,'2024-01-08 12:00:00','DEBIT',   225.50,'Trader Joes Grocery',     'Household',      'Trader Joes',          'SGRC202401001','COMPLETED'),
(3,'2024-01-10 19:00:00','DEBIT',    52.00,'McDonalds',               'Restaurant',   'McDonalds',            'SRST202401001','COMPLETED'),
(3,'2024-01-12 11:00:00','DEBIT',    85.00,'Old Navy Jeans',          'Dress',        'Old Navy',             'SDRS202401001','COMPLETED'),
(3,'2024-01-15 13:00:00','DEBIT',   175.00,'Safeway Grocery',         'Household',      'Safeway',              'SGRC202401002','COMPLETED'),
(3,'2024-01-20 08:00:00','DEBIT',    65.00,'Comcast Internet',        'Utility',      'Comcast',              'SUTL202401002','COMPLETED'),
(3,'2024-01-25 19:30:00','DEBIT',    35.00,'Chipotle Mexican',        'Restaurant',   'Chipotle',             'SRST202401002','COMPLETED'),
-- Feb 2024 Sarah
(3,'2024-02-01 09:00:00','CREDIT', 5500.00,'Payroll Direct Deposit',  '',             'TechStart Inc',        'SPAY202402001','COMPLETED'),
(3,'2024-02-02 10:00:00','DEBIT',  1450.00,'Rent Payment Feb 2024',   'Mortgage',     'SF Properties LLC',    'SRNT202402001','COMPLETED'),
(3,'2024-02-05 09:30:00','DEBIT',   138.00,'PG&E Electric Bill',      'Utility',      'PG&E',                 'SUTL202402001','COMPLETED'),
(3,'2024-02-08 12:00:00','DEBIT',   198.00,'Trader Joes Grocery',     'Household',      'Trader Joes',          'SGRC202402001','COMPLETED'),
(3,'2024-02-14 19:00:00','DEBIT',    78.00,'Olive Garden Valentine',  'Restaurant',   'Olive Garden',         'SRST202402001','COMPLETED'),
(3,'2024-02-18 14:00:00','DEBIT',   120.00,'Zara Clothing',           'Dress',        'Zara',                 'SDRS202402001','COMPLETED'),
(3,'2024-02-22 12:00:00','DEBIT',   168.00,'Safeway Grocery',         'Household',      'Safeway',              'SGRC202402002','COMPLETED'),
-- Mar 2024 Sarah
(3,'2024-03-01 09:00:00','CREDIT', 5500.00,'Payroll Direct Deposit',  '',             'TechStart Inc',        'SPAY202403001','COMPLETED'),
(3,'2024-03-03 10:00:00','DEBIT',  1450.00,'Rent Payment Mar 2024',   'Mortgage',     'SF Properties LLC',    'SRNT202403001','COMPLETED'),
(3,'2024-03-05 09:30:00','DEBIT',   150.00,'PG&E Electric Bill',      'Utility',      'PG&E',                 'SUTL202403001','COMPLETED'),
(3,'2024-03-10 12:00:00','DEBIT',   215.00,'Costco Grocery',          'Household',      'Costco',               'SGRC202403001','COMPLETED'),
(3,'2024-03-15 19:30:00','DEBIT',    65.00,'Panera Bread',            'Restaurant',   'Panera Bread',         'SRST202403001','COMPLETED'),
(3,'2024-03-22 11:00:00','DEBIT',   185.00,'Trader Joes Grocery',     'Household',      'Trader Joes',          'SGRC202403002','COMPLETED'),
(3,'2024-03-28 09:00:00','DEBIT',    68.00,'Comcast Internet',        'Utility',      'Comcast',              'SUTL202403002','COMPLETED'),
-- Apr 2024 Sarah
(3,'2024-04-01 09:00:00','CREDIT', 5500.00,'Payroll Direct Deposit',  '',             'TechStart Inc',        'SPAY202404001','COMPLETED'),
(3,'2024-04-03 10:00:00','DEBIT',  1450.00,'Rent Payment Apr 2024',   'Mortgage',     'SF Properties LLC',    'SRNT202404001','COMPLETED'),
(3,'2024-04-05 09:30:00','DEBIT',   142.00,'PG&E Electric Bill',      'Utility',      'PG&E',                 'SUTL202404001','COMPLETED'),
(3,'2024-04-10 12:00:00','DEBIT',   210.00,'Safeway Grocery',         'Household',      'Safeway',              'SGRC202404001','COMPLETED'),
(3,'2024-04-12 19:00:00','DEBIT',    45.00,'Subway Lunch',            'Restaurant',   'Subway',               'SRST202404001','COMPLETED'),
(3,'2024-04-20 14:00:00','DEBIT',    95.00,'H&M Spring',              'Dress',        'H&M',                  'SDRS202404001','COMPLETED'),
-- May-Dec 2024 Sarah (condensed)
(3,'2024-05-01 09:00:00','CREDIT', 5500.00,'Payroll Direct Deposit',  '',             'TechStart Inc',        'SPAY202405001','COMPLETED'),
(3,'2024-05-03 10:00:00','DEBIT',  1450.00,'Rent Payment May 2024',   'Mortgage',     'SF Properties LLC',    'SRNT202405001','COMPLETED'),
(3,'2024-05-05 09:00:00','DEBIT',   148.00,'PG&E Electric Bill',      'Utility',      'PG&E',                 'SUTL202405001','COMPLETED'),
(3,'2024-05-10 12:00:00','DEBIT',   222.00,'Trader Joes Grocery',     'Household',      'Trader Joes',          'SGRC202405001','COMPLETED'),
(3,'2024-06-03 09:00:00','CREDIT', 5500.00,'Payroll Direct Deposit',  '',             'TechStart Inc',        'SPAY202406001','COMPLETED'),
(3,'2024-06-04 10:00:00','DEBIT',  1450.00,'Rent Payment Jun 2024',   'Mortgage',     'SF Properties LLC',    'SRNT202406001','COMPLETED'),
(3,'2024-06-05 09:30:00','DEBIT',   155.00,'PG&E Electric Bill',      'Utility',      'PG&E',                 'SUTL202406001','COMPLETED'),
(3,'2024-06-10 12:00:00','DEBIT',   195.00,'Safeway Grocery',         'Household',      'Safeway',              'SGRC202406001','COMPLETED'),
(3,'2024-07-01 09:00:00','CREDIT', 5500.00,'Payroll Direct Deposit',  '',             'TechStart Inc',        'SPAY202407001','COMPLETED'),
(3,'2024-07-03 10:00:00','DEBIT',  1450.00,'Rent Payment Jul 2024',   'Mortgage',     'SF Properties LLC',    'SRNT202407001','COMPLETED'),
(3,'2024-07-05 09:30:00','DEBIT',   168.00,'PG&E Electric Bill',      'Utility',      'PG&E',                 'SUTL202407001','COMPLETED'),
(3,'2024-07-10 12:30:00','DEBIT',   215.00,'Costco Grocery',          'Household',      'Costco',               'SGRC202407001','COMPLETED'),
(3,'2024-08-01 09:00:00','CREDIT', 5500.00,'Payroll Direct Deposit',  '',             'TechStart Inc',        'SPAY202408001','COMPLETED'),
(3,'2024-08-02 10:00:00','DEBIT',  1450.00,'Rent Payment Aug 2024',   'Mortgage',     'SF Properties LLC',    'SRNT202408001','COMPLETED'),
(3,'2024-08-05 09:30:00','DEBIT',   175.00,'PG&E August Bill',        'Utility',      'PG&E',                 'SUTL202408001','COMPLETED'),
(3,'2024-08-10 12:00:00','DEBIT',   230.00,'Trader Joes Grocery',     'Household',      'Trader Joes',          'SGRC202408001','COMPLETED'),
(3,'2024-09-02 09:00:00','CREDIT', 5500.00,'Payroll Direct Deposit',  '',             'TechStart Inc',        'SPAY202409001','COMPLETED'),
(3,'2024-09-03 10:00:00','DEBIT',  1450.00,'Rent Payment Sep 2024',   'Mortgage',     'SF Properties LLC',    'SRNT202409001','COMPLETED'),
(3,'2024-09-05 09:30:00','DEBIT',   152.00,'PG&E Electric Bill',      'Utility',      'PG&E',                 'SUTL202409001','COMPLETED'),
(3,'2024-09-10 12:00:00','DEBIT',   205.00,'Safeway Grocery',         'Household',      'Safeway',              'SGRC202409001','COMPLETED'),
(3,'2024-10-01 09:00:00','CREDIT', 5500.00,'Payroll Direct Deposit',  '',             'TechStart Inc',        'SPAY202410001','COMPLETED'),
(3,'2024-10-03 10:00:00','DEBIT',  1450.00,'Rent Payment Oct 2024',   'Mortgage',     'SF Properties LLC',    'SRNT202410001','COMPLETED'),
(3,'2024-10-05 09:30:00','DEBIT',   148.00,'PG&E Electric Bill',      'Utility',      'PG&E',                 'SUTL202410001','COMPLETED'),
(3,'2024-10-10 12:30:00','DEBIT',   225.00,'Costco Grocery',          'Household',      'Costco',               'SGRC202410001','COMPLETED'),
(3,'2024-10-15 19:30:00','DEBIT',    58.00,'Chipotle Mexican',        'Restaurant',   'Chipotle',             'SRST202410001','COMPLETED'),
(3,'2024-10-20 14:00:00','DEBIT',   135.00,'Target Fall Clothing',    'Dress',        'Target',               'SDRS202410001','COMPLETED'),
(3,'2024-11-01 09:00:00','CREDIT', 5500.00,'Payroll Direct Deposit',  '',             'TechStart Inc',        'SPAY202411001','COMPLETED'),
(3,'2024-11-03 10:00:00','DEBIT',  1450.00,'Rent Payment Nov 2024',   'Mortgage',     'SF Properties LLC',    'SRNT202411001','COMPLETED'),
(3,'2024-11-05 09:30:00','DEBIT',   162.00,'PG&E Electric Bill',      'Utility',      'PG&E',                 'SUTL202411001','COMPLETED'),
(3,'2024-11-10 12:00:00','DEBIT',   285.00,'Trader Joes Thanksgiving','Household',      'Trader Joes',          'SGRC202411001','COMPLETED'),
(3,'2024-11-25 15:00:00','DEBIT',   175.00,'Black Friday Target',     'Dress',        'Target',               'SDRS202411001','COMPLETED'),
(3,'2024-12-02 09:00:00','CREDIT', 5500.00,'Payroll Direct Deposit',  '',             'TechStart Inc',        'SPAY202412001','COMPLETED'),
(3,'2024-12-02 09:05:00','CREDIT', 1500.00,'Holiday Bonus 2024',      '',             'TechStart Inc',        'SBONUS202412','COMPLETED'),
(3,'2024-12-03 10:00:00','DEBIT',  1450.00,'Rent Payment Dec 2024',   'Mortgage',     'SF Properties LLC',    'SRNT202412001','COMPLETED'),
(3,'2024-12-05 09:30:00','DEBIT',   178.00,'PG&E Electric Bill',      'Utility',      'PG&E',                 'SUTL202412001','COMPLETED'),
(3,'2024-12-10 12:00:00','DEBIT',   255.00,'Safeway Holiday',         'Household',      'Safeway',              'SGRC202412001','COMPLETED'),
(3,'2024-12-20 15:00:00','DEBIT',   320.00,'Holiday Shopping Target', 'Dress',        'Target',               'SDRS202412001','COMPLETED'),
-- 2025 Sarah
(3,'2025-01-02 09:00:00','CREDIT', 5800.00,'Payroll Direct Deposit',  '',             'TechStart Inc',        'SPAY202501001','COMPLETED'),
(3,'2025-01-03 10:00:00','DEBIT',  1500.00,'Rent Payment Jan 2025',   'Mortgage',     'SF Properties LLC',    'SRNT202501001','COMPLETED'),
(3,'2025-01-05 09:30:00','DEBIT',   152.00,'PG&E Electric Bill',      'Utility',      'PG&E',                 'SUTL202501001','COMPLETED'),
(3,'2025-01-10 12:00:00','DEBIT',   218.00,'Trader Joes Grocery',     'Household',      'Trader Joes',          'SGRC202501001','COMPLETED'),
(3,'2025-02-03 09:00:00','CREDIT', 5800.00,'Payroll Direct Deposit',  '',             'TechStart Inc',        'SPAY202502001','COMPLETED'),
(3,'2025-02-04 10:00:00','DEBIT',  1500.00,'Rent Payment Feb 2025',   'Mortgage',     'SF Properties LLC',    'SRNT202502001','COMPLETED'),
(3,'2025-02-05 09:30:00','DEBIT',   145.00,'PG&E Electric Bill',      'Utility',      'PG&E',                 'SUTL202502001','COMPLETED'),
(3,'2025-02-10 12:30:00','DEBIT',   205.00,'Costco Grocery',          'Household',      'Costco',               'SGRC202502001','COMPLETED'),
(3,'2025-03-03 09:00:00','CREDIT', 5800.00,'Payroll Direct Deposit',  '',             'TechStart Inc',        'SPAY202503001','COMPLETED'),
(3,'2025-03-04 10:00:00','DEBIT',  1500.00,'Rent Payment Mar 2025',   'Mortgage',     'SF Properties LLC',    'SRNT202503001','COMPLETED'),
(3,'2025-03-05 09:30:00','DEBIT',   158.00,'PG&E Electric Bill',      'Utility',      'PG&E',                 'SUTL202503001','COMPLETED'),
(3,'2025-03-10 12:00:00','DEBIT',   228.00,'Trader Joes Grocery',     'Household',      'Trader Joes',          'SGRC202503001','COMPLETED'),
(3,'2025-04-01 09:00:00','CREDIT', 5800.00,'Payroll Direct Deposit',  '',             'TechStart Inc',        'SPAY202504001','COMPLETED'),
(3,'2025-04-03 10:00:00','DEBIT',  1500.00,'Rent Payment Apr 2025',   'Mortgage',     'SF Properties LLC',    'SRNT202504001','COMPLETED'),
(3,'2025-04-05 09:30:00','DEBIT',   148.00,'PG&E Electric Bill',      'Utility',      'PG&E',                 'SUTL202504001','COMPLETED'),
(3,'2025-04-10 12:00:00','DEBIT',   215.00,'Safeway Grocery',         'Household',      'Safeway',              'SGRC202504001','COMPLETED'),
(3,'2025-05-01 09:00:00','CREDIT', 5800.00,'Payroll Direct Deposit',  '',             'TechStart Inc',        'SPAY202505001','COMPLETED'),
(3,'2025-05-03 10:00:00','DEBIT',  1500.00,'Rent Payment May 2025',   'Mortgage',     'SF Properties LLC',    'SRNT202505001','COMPLETED'),
(3,'2025-05-05 09:00:00','DEBIT',   152.00,'PG&E Electric Bill',      'Utility',      'PG&E',                 'SUTL202505001','COMPLETED'),
(3,'2025-05-10 12:30:00','DEBIT',   220.00,'Costco Grocery',          'Household',      'Costco',               'SGRC202505001','COMPLETED'),
(3,'2025-06-02 09:00:00','CREDIT', 5800.00,'Payroll Direct Deposit',  '',             'TechStart Inc',        'SPAY202506001','COMPLETED'),
(3,'2025-06-03 10:00:00','DEBIT',  1500.00,'Rent Payment Jun 2025',   'Mortgage',     'SF Properties LLC',    'SRNT202506001','COMPLETED'),
(3,'2025-06-05 09:30:00','DEBIT',   160.00,'PG&E Electric Bill',      'Utility',      'PG&E',                 'SUTL202506001','COMPLETED'),
(3,'2025-06-10 12:00:00','DEBIT',   205.00,'Trader Joes Grocery',     'Household',      'Trader Joes',          'SGRC202506001','COMPLETED'),
(3,'2025-07-01 09:00:00','CREDIT', 5800.00,'Payroll Direct Deposit',  '',             'TechStart Inc',        'SPAY202507001','COMPLETED'),
(3,'2025-07-03 10:00:00','DEBIT',  1500.00,'Rent Payment Jul 2025',   'Mortgage',     'SF Properties LLC',    'SRNT202507001','COMPLETED'),
(3,'2025-07-05 09:30:00','DEBIT',   172.00,'PG&E Summer Bill',        'Utility',      'PG&E',                 'SUTL202507001','COMPLETED'),
(3,'2025-07-10 12:00:00','DEBIT',   232.00,'Safeway Grocery',         'Household',      'Safeway',              'SGRC202507001','COMPLETED'),
(3,'2025-08-01 09:00:00','CREDIT', 5800.00,'Payroll Direct Deposit',  '',             'TechStart Inc',        'SPAY202508001','COMPLETED'),
(3,'2025-08-04 10:00:00','DEBIT',  1500.00,'Rent Payment Aug 2025',   'Mortgage',     'SF Properties LLC',    'SRNT202508001','COMPLETED'),
(3,'2025-08-05 09:30:00','DEBIT',   180.00,'PG&E August Bill',        'Utility',      'PG&E',                 'SUTL202508001','COMPLETED'),
(3,'2025-08-10 12:00:00','DEBIT',   240.00,'Costco Grocery',          'Household',      'Costco',               'SGRC202508001','COMPLETED'),
(3,'2025-09-01 09:00:00','CREDIT', 5800.00,'Payroll Direct Deposit',  '',             'TechStart Inc',        'SPAY202509001','COMPLETED'),
(3,'2025-09-03 10:00:00','DEBIT',  1500.00,'Rent Payment Sep 2025',   'Mortgage',     'SF Properties LLC',    'SRNT202509001','COMPLETED'),
(3,'2025-09-05 09:30:00','DEBIT',   155.00,'PG&E Electric Bill',      'Utility',      'PG&E',                 'SUTL202509001','COMPLETED'),
(3,'2025-09-10 12:00:00','DEBIT',   215.00,'Trader Joes Grocery',     'Household',      'Trader Joes',          'SGRC202509001','COMPLETED'),
(3,'2025-10-01 09:00:00','CREDIT', 5800.00,'Payroll Direct Deposit',  '',             'TechStart Inc',        'SPAY202510001','COMPLETED'),
(3,'2025-10-03 10:00:00','DEBIT',  1500.00,'Rent Payment Oct 2025',   'Mortgage',     'SF Properties LLC',    'SRNT202510001','COMPLETED'),
(3,'2025-10-05 09:30:00','DEBIT',   150.00,'PG&E Electric Bill',      'Utility',      'PG&E',                 'SUTL202510001','COMPLETED'),
(3,'2025-10-10 12:30:00','DEBIT',   228.00,'Safeway Grocery',         'Household',      'Safeway',              'SGRC202510001','COMPLETED'),
(3,'2025-11-03 09:00:00','CREDIT', 5800.00,'Payroll Direct Deposit',  '',             'TechStart Inc',        'SPAY202511001','COMPLETED'),
(3,'2025-11-04 10:00:00','DEBIT',  1500.00,'Rent Payment Nov 2025',   'Mortgage',     'SF Properties LLC',    'SRNT202511001','COMPLETED'),
(3,'2025-11-05 09:30:00','DEBIT',   165.00,'PG&E Electric Bill',      'Utility',      'PG&E',                 'SUTL202511001','COMPLETED'),
(3,'2025-11-10 12:00:00','DEBIT',   295.00,'Costco Thanksgiving',     'Household',      'Costco',               'SGRC202511001','COMPLETED'),
(3,'2025-12-01 09:00:00','CREDIT', 5800.00,'Payroll Direct Deposit',  '',             'TechStart Inc',        'SPAY202512001','COMPLETED'),
(3,'2025-12-01 09:05:00','CREDIT', 2000.00,'Holiday Bonus 2025',      '',             'TechStart Inc',        'SBONUS202512','COMPLETED'),
(3,'2025-12-03 10:00:00','DEBIT',  1500.00,'Rent Payment Dec 2025',   'Mortgage',     'SF Properties LLC',    'SRNT202512001','COMPLETED'),
(3,'2025-12-05 09:30:00','DEBIT',   182.00,'PG&E Electric Bill',      'Utility',      'PG&E',                 'SUTL202512001','COMPLETED'),
(3,'2025-12-10 12:00:00','DEBIT',   265.00,'Trader Joes Holiday',     'Household',      'Trader Joes',          'SGRC202512001','COMPLETED'),
(3,'2025-12-20 15:00:00','DEBIT',   240.00,'Holiday Shopping',        'Dress',        'Target',               'SDRS202512001','COMPLETED'),
-- 2026 Jan-Jun Sarah
(3,'2026-01-02 09:00:00','CREDIT', 5800.00,'Payroll Direct Deposit',  '',             'TechStart Inc',        'SPAY202601001','COMPLETED'),
(3,'2026-01-03 10:00:00','DEBIT',  1500.00,'Rent Payment Jan 2026',   'Mortgage',     'SF Properties LLC',    'SRNT202601001','COMPLETED'),
(3,'2026-01-05 09:30:00','DEBIT',   158.00,'PG&E Electric Bill',      'Utility',      'PG&E',                 'SUTL202601001','COMPLETED'),
(3,'2026-01-10 12:00:00','DEBIT',   222.00,'Safeway Grocery',         'Household',      'Safeway',              'SGRC202601001','COMPLETED'),
(3,'2026-02-03 09:00:00','CREDIT', 5800.00,'Payroll Direct Deposit',  '',             'TechStart Inc',        'SPAY202602001','COMPLETED'),
(3,'2026-02-04 10:00:00','DEBIT',  1500.00,'Rent Payment Feb 2026',   'Mortgage',     'SF Properties LLC',    'SRNT202602001','COMPLETED'),
(3,'2026-02-05 09:30:00','DEBIT',   150.00,'PG&E Electric Bill',      'Utility',      'PG&E',                 'SUTL202602001','COMPLETED'),
(3,'2026-02-10 12:00:00','DEBIT',   210.00,'Trader Joes Grocery',     'Household',      'Trader Joes',          'SGRC202602001','COMPLETED'),
(3,'2026-03-03 09:00:00','CREDIT', 5800.00,'Payroll Direct Deposit',  '',             'TechStart Inc',        'SPAY202603001','COMPLETED'),
(3,'2026-03-04 10:00:00','DEBIT',  1500.00,'Rent Payment Mar 2026',   'Mortgage',     'SF Properties LLC',    'SRNT202603001','COMPLETED'),
(3,'2026-03-05 09:30:00','DEBIT',   155.00,'PG&E Electric Bill',      'Utility',      'PG&E',                 'SUTL202603001','COMPLETED'),
(3,'2026-03-10 12:00:00','DEBIT',   225.00,'Costco Grocery',          'Household',      'Costco',               'SGRC202603001','COMPLETED'),
(3,'2026-04-01 09:00:00','CREDIT', 5800.00,'Payroll Direct Deposit',  '',             'TechStart Inc',        'SPAY202604001','COMPLETED'),
(3,'2026-04-03 10:00:00','DEBIT',  1500.00,'Rent Payment Apr 2026',   'Mortgage',     'SF Properties LLC',    'SRNT202604001','COMPLETED'),
(3,'2026-04-05 09:30:00','DEBIT',   146.00,'PG&E Electric Bill',      'Utility',      'PG&E',                 'SUTL202604001','COMPLETED'),
(3,'2026-04-10 12:00:00','DEBIT',   212.00,'Safeway Grocery',         'Household',      'Safeway',              'SGRC202604001','COMPLETED'),
(3,'2026-05-01 09:00:00','CREDIT', 5800.00,'Payroll Direct Deposit',  '',             'TechStart Inc',        'SPAY202605001','COMPLETED'),
(3,'2026-05-03 10:00:00','DEBIT',  1500.00,'Rent Payment May 2026',   'Mortgage',     'SF Properties LLC',    'SRNT202605001','COMPLETED'),
(3,'2026-05-05 09:00:00','DEBIT',   154.00,'PG&E Electric Bill',      'Utility',      'PG&E',                 'SUTL202605001','COMPLETED'),
(3,'2026-05-10 12:30:00','DEBIT',   218.00,'Trader Joes Grocery',     'Household',      'Trader Joes',          'SGRC202605001','COMPLETED'),
(3,'2026-06-02 09:00:00','CREDIT', 5800.00,'Payroll Direct Deposit',  '',             'TechStart Inc',        'SPAY202606001','COMPLETED'),
(3,'2026-06-03 10:00:00','DEBIT',  1500.00,'Rent Payment Jun 2026',   'Mortgage',     'SF Properties LLC',    'SRNT202606001','COMPLETED'),
(3,'2026-06-05 09:30:00','DEBIT',   157.00,'PG&E Electric Bill',      'Utility',      'PG&E',                 'SUTL202606001','COMPLETED'),
(3,'2026-06-10 12:00:00','DEBIT',   220.00,'Safeway Grocery',         'Household',      'Safeway',              'SGRC202606001','COMPLETED');

-- ─── Indian Grocery Transactions ─────────────────────────────────────────────
INSERT INTO BANK_TRANSACTION (account_id, transaction_date, transaction_type, amount, description, category, merchant_name, reference_no, status, created_at) VALUES
-- John Smith (account_id=1)
(1,'2024-03-08 11:30:00','DEBIT',  87.45,'India Bazar Weekly Shopping',  'Indian Grocery','India Bazar',    'REF20240308IG01','COMPLETED',NOW()),
(1,'2024-05-14 10:15:00','DEBIT',  63.20,'IndoPak Grocery Run',          'Indian Grocery','IndoPak Grocery','REF20240514IG01','COMPLETED',NOW()),
(1,'2024-07-22 12:45:00','DEBIT', 112.80,'Swadeshi Indian Supermarket',  'Indian Grocery','Swadeshi Store', 'REF20240722IG01','COMPLETED',NOW()),
(1,'2024-09-05 09:30:00','DEBIT',  74.60,'India Bazar Monthly Stock',    'Indian Grocery','India Bazar',    'REF20240905IG01','COMPLETED',NOW()),
(1,'2024-11-18 11:00:00','DEBIT',  95.30,'IndoPak Spices and Produce',   'Indian Grocery','IndoPak Grocery','REF20241118IG01','COMPLETED',NOW()),
(1,'2025-01-10 10:30:00','DEBIT',  68.90,'Swadeshi Grocery Shopping',    'Indian Grocery','Swadeshi Store', 'REF20250110IG01','COMPLETED',NOW()),
(1,'2025-03-25 13:00:00','DEBIT', 102.15,'India Bazar Festival Shopping','Indian Grocery','India Bazar',    'REF20250325IG01','COMPLETED',NOW()),
(1,'2025-06-07 11:45:00','DEBIT',  58.40,'IndoPak Weekend Grocery',      'Indian Grocery','IndoPak Grocery','REF20250607IG01','COMPLETED',NOW()),
(1,'2025-09-14 10:00:00','DEBIT',  88.75,'Swadeshi Diwali Groceries',    'Indian Grocery','Swadeshi Store', 'REF20250914IG01','COMPLETED',NOW()),
(1,'2025-12-03 12:30:00','DEBIT',  79.20,'India Bazar Holiday Shopping', 'Indian Grocery','India Bazar',    'REF20251203IG01','COMPLETED',NOW()),
(1,'2026-02-20 11:15:00','DEBIT',  91.50,'IndoPak Grocery Haul',         'Indian Grocery','IndoPak Grocery','REF20260220IG01','COMPLETED',NOW()),
(1,'2026-04-10 10:45:00','DEBIT',  66.30,'Swadeshi Monthly Shopping',    'Indian Grocery','Swadeshi Store', 'REF20260410IG01','COMPLETED',NOW()),
-- Sarah Johnson (account_id=3)
(3,'2024-04-12 09:45:00','DEBIT',  54.80,'India Bazar Grocery',          'Indian Grocery','India Bazar',    'REF20240412IG02','COMPLETED',NOW()),
(3,'2024-06-28 11:30:00','DEBIT',  71.60,'IndoPak Store Run',            'Indian Grocery','IndoPak Grocery','REF20240628IG02','COMPLETED',NOW()),
(3,'2024-08-15 10:00:00','DEBIT',  83.40,'Swadeshi Weekly Groceries',    'Indian Grocery','Swadeshi Store', 'REF20240815IG02','COMPLETED',NOW()),
(3,'2024-10-22 12:15:00','DEBIT',  49.90,'India Bazar Essentials',       'Indian Grocery','India Bazar',    'REF20241022IG02','COMPLETED',NOW()),
(3,'2025-01-30 09:00:00','DEBIT',  76.25,'IndoPak Spice Shopping',       'Indian Grocery','IndoPak Grocery','REF20250130IG02','COMPLETED',NOW()),
(3,'2025-04-18 11:00:00','DEBIT',  62.70,'Swadeshi Indian Market',       'Indian Grocery','Swadeshi Store', 'REF20250418IG02','COMPLETED',NOW()),
(3,'2025-07-09 10:30:00','DEBIT',  94.15,'India Bazar Summer Stock',     'Indian Grocery','India Bazar',    'REF20250709IG02','COMPLETED',NOW()),
(3,'2025-10-05 13:00:00','DEBIT',  57.80,'IndoPak Monthly Grocery',      'Indian Grocery','IndoPak Grocery','REF20251005IG02','COMPLETED',NOW()),
(3,'2026-01-15 10:15:00','DEBIT',  85.30,'Swadeshi New Year Shopping',   'Indian Grocery','Swadeshi Store', 'REF20260115IG02','COMPLETED',NOW()),
(3,'2026-03-28 11:45:00','DEBIT',  73.90,'India Bazar Spring Groceries', 'Indian Grocery','India Bazar',    'REF20260328IG02','COMPLETED',NOW())
ON CONFLICT (reference_no) DO NOTHING;

-- ─── Sample Disputes ──────────────────────────────────────────────────────────
-- Dispute on John's Amazon charge (look up actual transaction_id dynamically)
INSERT INTO DISPUTE (transaction_id, customer_id, raised_by, dispute_reason, dispute_status, raised_date)
SELECT t.transaction_id, 1, 'john.smith',
       'I did not authorize this Amazon Prime charge. Please investigate.',
       'OPEN', '2024-01-20 10:00:00'
FROM BANK_TRANSACTION t WHERE t.reference_no = 'MSC202401001' LIMIT 1;

INSERT INTO DISPUTE (transaction_id, customer_id, raised_by, dispute_reason, dispute_status, resolution, raised_date, resolved_date)
SELECT t.transaction_id, 2, 'sarah.johnson',
       'This Chipotle charge was for $35 but I was charged $58.',
       'RESOLVED',
       'After investigation, the merchant confirmed a pricing error. A credit of $23.00 has been issued.',
       '2024-10-20 10:00:00', '2024-11-01 14:00:00'
FROM BANK_TRANSACTION t WHERE t.reference_no = 'SRST202410001' LIMIT 1;
