#!/bin/bash
# Install PostgreSQL client and Python with psycopg2
sudo apt update
sudo apt install -y postgresql-client python3 python3-pip
pip3 install psycopg2-binary

# Create a load testing script
cat > load_test.py << 'EOF'
import psycopg2
import time
import random
import threading
from concurrent.futures import ThreadPoolExecutor

# DB Connection parameters - update with DB server's PRIVATE IP
DB_PARAMS = {
    "host": "DB_SERVER_PRIVATE_IP",  # Replace with actual DB server private IP
    "database": "testdb",
    "user": "testuser",
    "password": "password"
}

# This query deliberately forces a sequential scan rather than using an index
def run_problematic_query():
    conn = psycopg2.connect(**DB_PARAMS)
    cur = conn.cursor()
    
    # Query by zip_code which has no index
    zip_code = f"{random.randint(10000, 99999)}"
    
    query = """
    SELECT id, name, email, address
    FROM customers
    WHERE zip_code = %s
    """
    
    start = time.time()
    cur.execute(query, (zip_code,))
    results = cur.fetchall()
    duration = time.time() - start
    
    conn.close()
    return duration

def worker():
    while True:
        try:
            duration = run_problematic_query()
            print(f"Query completed in {duration:.2f} seconds")
        except Exception as e:
            print(f"Error: {e}")
        
        # Small random delay
        time.sleep(random.uniform(0.1, 0.5))

# Run multiple clients
def main():
    num_workers = 20  # Adjust based on your VM capabilities
    
    print(f"Starting {num_workers} workers...")
    
    with ThreadPoolExecutor(max_workers=num_workers) as executor:
        for _ in range(num_workers):
            executor.submit(worker)

if __name__ == "__main__":
    main()
EOF

# Update the DB_SERVER_PRIVATE_IP with the actual private IP
sed -i "s/DB_SERVER_PRIVATE_IP/10.0.0.4/" load_test.py

# Make the script executable
chmod +x load_test.py