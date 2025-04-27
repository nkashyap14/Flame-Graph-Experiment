#!/bin/bash
# This script provides the step-by-step process to run the experiment
# and analyze PostgreSQL performance using flame graphs

echo "Step 1: Starting initial monitoring"
# Reset PostgreSQL statistics to get a clean baseline
sudo -u postgres psql testdb -c "SELECT pg_stat_reset();"

echo "Step 2: Starting database load test (run this on the app VM)"
echo "On app VM, run: python3 load_test.py"
echo "Let this run in a separate terminal"

echo "Step 3: Monitor query performance before optimization"
# Check database statistics after load has been running for a minute
echo "Waiting for load to build (60 seconds)..."
sleep 60

# Check statistics on sequential scans
sudo -u postgres psql testdb -c "SELECT relname, seq_scan, seq_tup_read, idx_scan, idx_tup_fetch FROM pg_stat_user_tables WHERE relname = 'customers';"

# Check active connections
sudo -u postgres psql testdb -c "SELECT count(*) FROM pg_stat_activity WHERE state = 'active';"

# Check system load
echo "System load:"
uptime
echo "CPU usage (top output):"
top -b -n 1 | head -15

echo "Step 4: Generating flame graph before optimization"
# Get PostgreSQL process ID
POSTGRES_PID=$(sudo ps aux | grep "postgres" | grep -v "grep" | grep "postgres:" | head -1 | awk '{print $2}')
echo "Recording performance data for PostgreSQL (PID: $POSTGRES_PID) for 30 seconds..."

# Record performance data
sudo perf record -F 99 -p $POSTGRES_PID -g -- sleep 30

# Generate flame graph
echo "Generating flame graph..."
sudo perf script | ~/FlameGraph/stackcollapse-perf.pl | ~/FlameGraph/flamegraph.pl > ~/postgres_flamegraph_before.svg

# Set up HTTP server to view the flame graph if not already running
if ! pgrep -f "python3 -m http.server 8000" > /dev/null; then
    cd ~
    python3 -m http.server 8000 &
fi

DB_SERVER_IP=$(curl -s http://ipinfo.io/ip)
echo "View the flame graph at http://$DB_SERVER_IP:8000/postgres_flamegraph_before.svg"
echo "Analyze the flame graph to identify performance bottlenecks"
echo "Note: Look for wide plateaus in the graph, especially in the ExecScan function"

echo "Step 5: Apply performance fixes"
echo "Running performance fixes..."
# Add missing index
sudo -u postgres psql testdb -c "CREATE INDEX idx_customers_zip_code ON customers(zip_code);"

# Analyze the table to update statistics
sudo -u postgres psql testdb -c "ANALYZE customers;"

# Improve PostgreSQL configuration
sudo -u postgres psql -c "ALTER SYSTEM SET shared_buffers = '256MB';"
sudo -u postgres psql -c "ALTER SYSTEM SET work_mem = '16MB';"
sudo -u postgres psql -c "ALTER SYSTEM SET random_page_cost = '4';"
sudo -u postgres psql -c "ALTER SYSTEM SET effective_cache_size = '1GB';"

# Apply configuration changes
echo "Restarting PostgreSQL to apply new configuration..."
sudo systemctl restart postgresql

# Reset statistics after the fix
sudo -u postgres psql testdb -c "SELECT pg_stat_reset();"

echo "Step 6: Monitor query performance after optimization"
# Wait for some load to build up again
echo "Waiting for load to build again (60 seconds)..."
sleep 60

# Check statistics on sequential scans vs index scans
sudo -u postgres psql testdb -c "SELECT relname, seq_scan, seq_tup_read, idx_scan, idx_tup_fetch FROM pg_stat_user_tables WHERE relname = 'customers';"

# Check system load after optimization
echo "System load after optimization:"
uptime
echo "CPU usage after optimization (top output):"
top -b -n 1 | head -15

echo "Step 7: Generating flame graph after optimization"
# Get PostgreSQL process ID (may have changed after restart)
POSTGRES_PID=$(sudo ps aux | grep "postgres" | grep -v "grep" | grep "postgres:" | head -1 | awk '{print $2}')
echo "Recording performance data for PostgreSQL (PID: $POSTGRES_PID) for 30 seconds..."

# Record performance data
sudo perf record -F 99 -p $POSTGRES_PID -g -- sleep 30

# Generate flame graph
echo "Generating flame graph..."
sudo perf script | ~/FlameGraph/stackcollapse-perf.pl | ~/FlameGraph/flamegraph.pl > ~/postgres_flamegraph_after.svg

echo "View the updated flame graph at http://$DB_SERVER_IP:8000/postgres_flamegraph_after.svg"
echo "Compare both flame graphs to see the improvement in performance"
echo "Note: The ExecScan function should now occupy a smaller portion of the flame graph"

echo "Step 8: Performance comparison"
echo "You can now compare the query execution times shown in the app VM's output"
echo "On the app VM, you should see significantly faster query execution times"