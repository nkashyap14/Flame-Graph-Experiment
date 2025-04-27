# PostgreSQL Performance Analysis with Flame Graphs

This repository contains the code and scripts used in my article "Utilizing Flame Graphs to Tune PostgreSQL databases." The project demonstrates how to set up a distributed system with a PostgreSQL database, generate load, and use flame graphs to identify and resolve performance bottlenecks.

## Repository Structure

- `infra/`: Scripts for setting up Azure infrastructure
- `db_vm/`: Setup and monitoring scripts for the database VM
- `app_vm/`: Load generator application
- `monitoring_vm/`: Database monitoring tools

## Prerequisites

- Azure CLI
- SSH access to VMs
- Ubuntu 22.04 LTS VMs
- Basic knowledge of PostgreSQL and system administration

## Setup Instructions

1. Run the infrastructure setup script:
./infra/setup_azure_resources.sh
2. Set up the database VM:
./db_vm/setup_db.sh
3. Set up the application VM:
./app_vm/setup_app.sh
4. Follow the article instructions to generate load and analyze performance with flame graphs.
Follow instructions in ./db_vm/run_experiment.sh

## Performance Analysis

The flame graphs generated in this project help identify CPU bottlenecks in PostgreSQL queries. The example shows how to:

1. Identify inefficient sequential scans
2. Create appropriate indexes
3. Adjust PostgreSQL configuration parameters
4. Verify performance improvements

## References

- [Brendan Gregg's Flame Graph Tools](https://github.com/brendangregg/FlameGraph)
- [PostgreSQL Performance Tuning](https://www.postgresql.org/docs/current/performance-tips.html)
- [Linux perf Tools](https://perf.wiki.kernel.org/index.php/Main_Page)