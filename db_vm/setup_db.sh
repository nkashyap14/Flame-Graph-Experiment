#!/bin/bash
# Install PostgreSQL
sudo apt update
sudo apt install -y postgresql postgresql-contrib

# Install perf and flame graph tools
sudo apt install -y linux-tools-common linux-tools-generic linux-tools-$(uname -r)
sudo apt install -y git
git clone https://github.com/brendangregg/FlameGraph ~/FlameGraph

# Configure PostgreSQL with deliberately poor settings
sudo -u postgres psql -c "ALTER SYSTEM SET shared_buffers = '8MB';"  # Very small buffer
sudo -u postgres psql -c "ALTER SYSTEM SET work_mem = '1MB';"  # Small work memory
sudo -u postgres psql -c "ALTER SYSTEM SET max_connections = '200';"  # High connections
sudo -u postgres psql -c "ALTER SYSTEM SET random_page_cost = '10';"  # Discourage index scans
sudo -u postgres psql -c "ALTER SYSTEM SET effective_cache_size = '10MB';"  # Small cache estimate

# Apply configuration changes
sudo systemctl restart postgresql

# Create test database and user
sudo -u postgres psql -c "CREATE USER testuser WITH PASSWORD 'password';"
sudo -u postgres psql -c "CREATE DATABASE testdb OWNER testuser;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE testdb TO testuser;"

# Allow remote connections (edit PostgreSQL config)
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/*/main/postgresql.conf
echo "host all all 0.0.0.0/0 md5" | sudo tee -a /etc/postgresql/*/main/pg_hba.conf
sudo systemctl restart postgresql

# Create test table and deliberately problematic schema
sudo -u postgres psql testdb << EOF
CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100),
    address TEXT,
    zip_code VARCHAR(20),
    registration_date TIMESTAMP,
    last_login TIMESTAMP,
    profile JSON,
    notes TEXT
);

-- Create an index, but not on the column we'll query most
CREATE INDEX idx_customers_name ON customers(name);
CREATE INDEX idx_customers_registration_date ON customers(registration_date);
-- Deliberately NOT creating an index on zip_code which we'll query

-- Generate test data (1 million rows)
INSERT INTO customers (name, email, address, zip_code, registration_date, last_login, profile, notes)
SELECT 
    'Customer ' || i,
    'customer' || i || '@example.com',
    'Address ' || i,
    LPAD((random() * 99999)::INTEGER::TEXT, 5, '0'),
    NOW() - (random() * 1000)::INTEGER * INTERVAL '1 day',
    NOW() - (random() * 100)::INTEGER * INTERVAL '1 day',
    '{"preferences": {"theme": "dark", "notifications": true}}',
    'Notes for customer ' || i
FROM generate_series(1, 1000000) i;

ANALYZE;
EOF