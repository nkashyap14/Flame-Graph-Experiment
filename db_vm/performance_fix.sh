#!/bin/bash
# Connect to the database and add the missing index
sudo -u postgres psql testdb -c "CREATE INDEX idx_customers_zip_code ON customers(zip_code);"

# Analyze the table to update statistics
sudo -u postgres psql testdb -c "ANALYZE customers;"

# Improve PostgreSQL configuration
sudo -u postgres psql -c "ALTER SYSTEM SET shared_buffers = '256MB';"
sudo -u postgres psql -c "ALTER SYSTEM SET work_mem = '16MB';"
sudo -u postgres psql -c "ALTER SYSTEM SET random_page_cost = '4';"
sudo -u postgres psql -c "ALTER SYSTEM SET effective_cache_size = '1GB';"

# Apply configuration changes
sudo systemctl restart postgresql

# Reset statistics after the fix
sudo -u postgres psql testdb -c "SELECT pg_stat_reset();"

# Generate a new flame graph for comparison
# First, wait for the load to build again
echo "Waiting for load to build..."
sleep 300

# Record performance data
sudo perf record -F 99 -e cpu-clock -a -g -- sleep 30

# Get the PostgreSQL process ID
POSTGRES_PID=$(sudo ps aux | grep "postgres" | grep -v "grep" | grep "postgres:" | head -1 | awk '{print $2}')

# Generate a flame graph
sudo perf script | ~/FlameGraph/stackcollapse-perf.pl | ~/FlameGraph/flamegraph.pl > ~/postgres_flamegraph_after.svg

echo "View the updated flame graph at http://$DB_SERVER_IP:8000/postgres_flamegraph_after.svg"