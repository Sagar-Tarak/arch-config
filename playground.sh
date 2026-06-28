#!/usr/bin/env bash

source lib/colors.sh
source lib/logger.sh
source lib/command.sh

logger::info "Starting integration test"

command::run echo "Hello from Arch Config"

logger::success "Integration test passed"