#!/bin/bash

#
# This bash script is designed to run in a WSL2 environment on Windows.
# It ensures that the required tools and dependencies are installed,
# 

set -e  # Exit on error
set -o pipefail  # Catch errors in pipes

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

load_dotenv() {
    if [ -f ".env" ]; then
        if [ -r ".env" ]; then
            log_info "Loading environment variables from .env file..."
            while IFS='=' read -r key value || [ -n "$key" ]; do
                # Skip comments and empty lines
                [[ $key =~ ^[[:space:]]*# ]] && continue
                [[ -z "$key" ]] && continue
                # Trim leading/trailing whitespace
                key=$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                # Export only if key is valid (non-empty and no spaces)
                if [[ -n "$key" && ! "$key" =~ [[:space:]] ]]; then
                    export "$key=$value"
                else
                    log_warn "Skipping invalid line in .env: $key=$value"
                fi
            done < ".env"
            return 0
        else
            log_error ".env file exists but is not readable."
            return 1
        fi
    else
        log_warn ".env file not found. Skipping environment variable loading."
        return 0
    fi
}

check_env_has_groq() {
    if [ -z "$GROQ_API_KEY" ]; then
        log_error "GROQ_API_KEY is not set in the environment. Please set it in the .env file and try again."
        log_warn "Open https://console.groq.com/keys to create an API key, it's free and no credit card is required."
        return 1
    elif [ ${#GROQ_API_KEY} -lt 10 ]; then
        log_error "GROQ_API_KEY seems too short. Please check your .env file and try again."
        log_warn "Open https://console.groq.com/keys to create an API key, it's free and no credit card is required."
        return 1
    else
        log_info "GROQ_API_KEY is set."
    fi
    return 0
}

# Check if running in WSL
check_run_in_wsl() {
    if ! grep -iq "microsoft\|wsl" /proc/version 2>/dev/null; then
        log_error "This script is designed EXCLUSIVELY for Windows Subsystem for Linux (WSL)!"
        log_warn "Do not run on a pure Linux VM (e.g., VirtualBox, VMware, or native Ubuntu)."
        log_info "It uses 'winget.exe' and 'cmd.exe', which only work in WSL with a Windows host."
        log_info "Install WSL on Windows and run again."
        return 1
    fi

    # need wsl2 has config .wslconfig with networkingMode=mirrored and firewall=true
    windows_user_folder=$(cd /mnt/c && cmd.exe /c "echo %USERPROFILE%" | tr -d '\r')
    equivalent_linux_path=$(wslpath "$(echo "$windows_user_folder" | tr -d '\r')")
    if [ ! -f "$equivalent_linux_path/.wslconfig" ]; then
        log_error "Could not find the .wslconfig file in WSL. Ensure WSL2 is properly configured."
        return 1
    fi
    # verify if wsl2 has networkingMode=mirrored and firewall=true
    if ! grep -q "networkingMode=mirrored" "$equivalent_linux_path/.wslconfig" || ! grep -q "firewall=true" "$equivalent_linux_path/.wslconfig"; then
        log_error "WSL2 is not properly configured. Please ensure the following settings are in .wslconfig:"
        log_error "  [wsl2]"
        log_error "  networkingMode=mirrored"
        log_error "  firewall=true"
        echo
        log_warn "After updating .wslconfig, restart WSL with 'wsl --shutdown' and try again."
        return 1
    fi
    return 0
}

# Check if Volta is installed and install if not
check_volta() {
    log_info "Checking for Volta..."
    if command -v volta &> /dev/null; then
        log_info "Volta is already installed: $(volta --version)"
        return 0
    else
        log_warn "Volta not found. Installing Volta..."
        if curl https://get.volta.sh | bash; then
            log_info "Volta installed successfully."
            export VOLTA_HOME="$HOME/.volta"
            export PATH="$VOLTA_HOME/bin:$PATH"
            return 0
        else
            log_error "Failed to install Volta."
            return 1
        fi
    fi
}

# Check Node.js version and install if needed
check_node_version() {
    log_info "Checking Node.js version..."
    
    if ! command -v node &> /dev/null; then
        log_warn "Node.js not found. Installing Node.js 22.20.0 via Volta..."
        if volta install node@22.20.0; then
            log_info "Node.js 22.20.0 installed successfully via Volta."
        else
            log_error "Failed to install Node.js via Volta."
            return 1
        fi
    else
        NODE_VERSION=$(node -v)
        log_info "Current Node.js version: $NODE_VERSION"
        
        if [ "$NODE_VERSION" != "v22.20.0" ]; then
            log_warn "Node.js version 22.20.0 is required. Current version is $NODE_VERSION"
            log_info "Installing Node.js 22.20.0 via Volta..."
            if volta install node@22.20.0; then
                log_info "Node.js 22.20.0 installed successfully via Volta."
            else
                log_error "Failed to install Node.js 22.20.0."
                return 1
            fi
        else
            log_info "Node.js version 22.20.0 is already installed."
        fi
    fi
    
    return 0
}

# Check and install chrome-devtools-mcp
check_chrome_devtools_mcp() {
    log_info "Checking chrome-devtools-mcp..."
    if npx -y chrome-devtools-mcp@latest --version &> /dev/null; then
        log_info "chrome-devtools-mcp is available."
    else
        log_warn "chrome-devtools-mcp not found. It will be installed on first use."
    fi
    return 0
}

check_winget() {
    log_info "Checking for winget.exe..."
    if ! command -v winget.exe &> /dev/null; then
        log_error "winget.exe not found. This script requires Windows with winget to install packages."
        return 1
    fi
    log_info "winget.exe is available."
    return 0
}

# Check Chrome installation
check_chrome() {
    log_info "Checking Google Chrome installation..."
    if winget.exe list | grep -i chrome &> /dev/null; then
        log_info "Google Chrome is already installed."
    else
        log_warn "Google Chrome is not installed. Installing..."
        if winget.exe install Google.Chrome.EXE; then
            log_info "Google Chrome installed successfully."
        else
            log_error "Failed to install Google Chrome."
            return 1
        fi
    fi
    return 0
}

# Check and install uv
check_uv() {
    log_info "Checking for uv..."
    if command -v uv &> /dev/null; then
        log_info "uv is already installed: $(uv --version)"
    else
        log_warn "uv not found. Installing..."
        if curl -LsSf https://astral.sh/uv/install.sh | sh; then
            log_info "uv installed successfully."
        else
            log_error "Failed to install uv."
            return 1
        fi
    fi
    return 0
}

# Check and create virtual environment
check_venv() {
    log_info "Checking virtual environment..."
    if [ ! -d ".venv" ]; then
        log_warn "Virtual environment not found. Creating..."
        if uv sync; then
            log_info "Virtual environment created successfully."
        else
            log_error "Failed to create virtual environment."
            return 1
        fi
    else
        log_info "Virtual environment already exists."
    fi
    return 0
}

# Start Chrome with remote debugging
start_chrome_debugging() {
    log_info "Checking Chrome remote debugging (max 5 seconds)..."
    if nc -w 5 -z localhost 9222 2>/dev/null; then
        log_info "Chrome is already running with remote debugging on port 9222."
    else
        log_warn "Starting Chrome with remote debugging on port 9222..."
        cmd.exe /c "C:\Program Files\Google\Chrome\Application\chrome.exe" \
            --remote-debugging-port=9222 \
            --user-data-dir=%TEMP%\\chrome-debug \
            --no-first-run \
            --no-default-browser-check \
            --disable-extensions &> /dev/null &
        
        # Wait for Chrome to start
        log_info "Waiting for Chrome to start remote debugging..."
        timeout 5 bash -c 'until nc -z localhost 9222; do sleep 1; done' || {
            log_error "Chrome failed to start remote debugging within 5 seconds."
            return 1
        }
    fi
    return 0
}

# Run the Python agent
run_agent() {
    log_info "Running Python agent..."
    if uv run python agents/chrome_task.py; then
        log_info "Agent execution completed successfully."
    else
        log_error "Agent execution failed."
        return 1
    fi
    return 0
}

# Main execution
main() {
    log_info "Starting setup and execution..."
    
    check_run_in_wsl || exit 1
    check_winget || exit 1
    check_volta || exit 1
    check_node_version || exit 1
    check_chrome_devtools_mcp || exit 1
    check_chrome || exit 1
    check_uv || exit 1
    check_venv || exit 1
    load_dotenv || exit 1
    check_env_has_groq || exit 1
    start_chrome_debugging || exit 1
    run_agent || exit 1
    
    log_info "All tasks completed successfully!"
}

# Run main function
main
