#!/bin/bash

# VaultFactory Testing and Deployment Script
# Usage: ./vaultfactory-operations.sh [test|deploy|all]

set -e

FOUNDRY_DIR="/home/semyon/projects/tradepro1/packages/foundry"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

function print_header() {
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN} $1${NC}"
    echo -e "${GREEN}================================${NC}"
}

function print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

function print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

function print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

function run_tests() {
    print_header "Running VaultFactory Tests"
    
    cd "$FOUNDRY_DIR"
    
    print_info "Compiling contracts..."
    if forge build; then
        print_success "Compilation successful"
    else
        print_error "Compilation failed"
        exit 1
    fi
    
    print_info "Running VaultFactory tests..."
    if forge test --match-contract VaultFactoryTest -vv; then
        print_success "All VaultFactory tests passed!"
    else
        print_error "Some tests failed"
        exit 1
    fi
    
    print_info "Running gas report..."
    forge test --match-contract VaultFactoryTest --gas-report
}

function deploy_contract() {
    print_header "Deploying VaultFactory Contract"
    
    cd "$FOUNDRY_DIR"
    
    print_info "Deploying to local network (anvil)..."
    if forge script script/DeployVaultFactory.s.sol --fork-url http://localhost:8545 --broadcast; then
        print_success "Deployment successful!"
    else
        print_error "Deployment failed"
        exit 1
    fi
}

function check_anvil() {
    print_info "Checking if Anvil is running..."
    if curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"web3_clientVersion","params":[],"id":1}' http://localhost:8545 > /dev/null 2>&1; then
        print_success "Anvil is running"
        return 0
    else
        print_error "Anvil is not running. Please start it with: anvil"
        return 1
    fi
}

function start_anvil() {
    print_info "Starting Anvil local blockchain..."
    anvil &
    ANVIL_PID=$!
    
    # Wait for anvil to start
    sleep 3
    
    if check_anvil; then
        print_success "Anvil started successfully (PID: $ANVIL_PID)"
        return 0
    else
        print_error "Failed to start Anvil"
        kill $ANVIL_PID 2>/dev/null || true
        return 1
    fi
}

function cleanup() {
    if [ ! -z "$ANVIL_PID" ]; then
        print_info "Stopping Anvil (PID: $ANVIL_PID)..."
        kill $ANVIL_PID 2>/dev/null || true
    fi
}

# Trap to cleanup on script exit
trap cleanup EXIT

case "$1" in
    "test")
        run_tests
        ;;
    "deploy")
        if ! check_anvil; then
            start_anvil
        fi
        deploy_contract
        ;;
    "all"|"")
        run_tests
        if ! check_anvil; then
            start_anvil
        fi
        deploy_contract
        ;;
    *)
        echo "Usage: $0 [test|deploy|all]"
        echo "  test   - Run tests only"
        echo "  deploy - Deploy contract (requires Anvil running)"
        echo "  all    - Run tests then deploy (default)"
        exit 1
        ;;
esac

print_success "Operation completed successfully!"