#!/bin/bash
# Execute a sample query
sudo -u postgres psql testdb -c "SELECT * FROM customers WHERE zip_code='12345';" &

# Record performance data for all processes
sudo perf record -F 99 -e cpu-clock -a -g -- sleep 30

# Get the PostgreSQL process ID
POSTGRES_PID=$(sudo ps aux | grep "postgres" | grep -v "grep" | grep "postgres:" | head -1 | awk '{print $2}')

# Record performance data for 60 seconds
sudo perf record -F 99 -p $POSTGRES_PID -g -- sleep 60

# Generate a flame graph
sudo perf script | ~/FlameGraph/stackcollapse-perf.pl | ~/FlameGraph/flamegraph.pl > ~/postgres_flamegraph_before.svg

# Set up a simple HTTP server to view the flame graph
cd ~
python3 -m http.server 8000 &
echo "View the flame graph at http://$DB_SERVER_IP:8000/postgres_flamegraph_before.svg"