#!/bin/bash

# Kafka Protocol Produce Request Encoding Performance Benchmark Script
# Tests kpro_req_lib:produce/5 performance on current build

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if project is built
check_build() {
    print_status "Checking if project is built..."

    if [ ! -f "$PROJECT_ROOT/_build/default/lib/kafka_protocol/ebin/kpro_req_lib.beam" ]; then
        print_error "Project not built. Please run 'make' first."
        exit 1
    fi

    print_success "Project build found"
}

# Function to run benchmark on current build
run_benchmark() {
    local branch=$(git branch --show-current)
    print_status "Running benchmark on current branch: $branch"

    # Change to project root
    cd "$PROJECT_ROOT"

    # Compile the benchmark module
    print_status "Compiling benchmark module..."
    erlc "$SCRIPT_DIR/kpro_produce_req_benchmark.erl" || {
        print_error "Failed to compile benchmark module"
        exit 1
    }

    # Run the benchmark
    print_status "Executing benchmark tests..."
    erl -pa _build/default/lib/*/ebin -noshell -eval "
        Results = kpro_produce_req_benchmark:run_all_scenarios(),
        io:format(\"BENCHMARK_RESULTS:~p~n\", [Results]),
        halt(0)
    " 2>&1 | tee "benchmark_${branch}.log"

    # Extract results
    grep "BENCHMARK_RESULTS:" "benchmark_${branch}.log" | sed "s/.*BENCHMARK_RESULTS://" > "results_${branch}.txt"

    print_success "Benchmark completed for branch: $branch"
    print_status "Results saved in: benchmark_${branch}.log"
    print_status "Raw results: results_${branch}.txt"
}

# Main execution
main() {
    print_status "Starting Kafka Protocol Produce Request Encoding Performance Benchmark"
    print_status "Testing kpro_req_lib:produce/5 performance on current build"

    # Check if we're in the right directory structure
    if [ ! -f "$PROJECT_ROOT/Makefile" ] || [ ! -f "$PROJECT_ROOT/rebar.config" ]; then
        print_error "This script must be run from a directory where the parent contains Makefile and rebar.config"
        exit 1
    fi

    # Check dependencies
    for cmd in git erl; do
        if ! command -v $cmd &> /dev/null; then
            print_error "$cmd is required but not installed"
            exit 1
        fi
    done

    # Check if project is built
    check_build

    # Run benchmark on current build
    run_benchmark

    print_success "Benchmark completed successfully!"

    # Cleanup
    rm -f kpro_produce_req_benchmark.beam
}

# Run main function
main "$@"
