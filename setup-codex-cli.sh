#!/bin/bash

# Codex CLI Setup Script - Portable Installation
# Can be run from any directory to install Codex CLI locally

echo ""
echo "  ____          _            ____ _     ___   ____       _               "
echo " / ___|___   __| | _____  __ / ___| |   |_ _| / ___|  ___| |_ _   _ _ __  "
echo "| |   / _ \ / _\` |/ _ \ \/ /| |   | |    | |  \___ \ / _ \ __| | | | '_ \ "
echo "| |__| (_) | (_| |  __/>  < | |___| |___ | |   ___) |  __/ |_| |_| | |_) |"
echo " \____\___/ \__,_|\___/_/\_\ \____|_____|___| |____/ \___|\__|\__,_| .__/ "
echo "                                                                  |_|    "
echo ""
echo "                    AMD LLM Gateway Integration"
echo "========================================================================="

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to prompt for user input with Y/n format
prompt_user() {
    local prompt_text="$1"
    local default_value="$2"
    local response
    
    # Format the prompt based on default value
    if [[ "$default_value" == "y" ]]; then
        echo "$prompt_text (Y/n): " >&2
    elif [[ "$default_value" == "n" ]]; then
        echo "$prompt_text (y/N): " >&2
    else
        echo "$prompt_text [$default_value]: " >&2
    fi
    
    # Simple read with basic timeout
    if read -r -t 10 response 2>/dev/null; then
        # If empty response (just Enter pressed), use default
        if [[ -z "$response" ]]; then
            echo "Using default: $default_value" >&2
            response="$default_value"
        fi
    else
        # If timeout occurred, cancel (safer default)
        echo "Timeout - cancelling for safety" >&2
        response="n"
    fi
    
    # Only echo the response value, not the prompt text
    echo "$response"
}

# Confirm installation location
echo ""
echo ">>> Installation Location Check"
echo "Current directory: $(pwd)"
echo ""

# Check if running in non-interactive mode or if user wants to skip prompt
if [[ "$1" == "--yes" || "$1" == "-y" ]]; then
    echo "[OK] Auto-confirming installation in current directory (--yes flag used)"
    install_here="y"
else
    # Check if we're in an interactive terminal
    if [[ -t 0 ]]; then
        echo "[INFO] Interactive terminal detected, prompting for confirmation..."
        install_here=$(prompt_user "Install Codex CLI in this directory?" "y")
    else
        echo "[INFO] Non-interactive environment detected, using default (yes)"
        install_here="y"
    fi
fi

if [[ "$install_here" != "y" && "$install_here" != "Y" && "$install_here" != "yes" && "$install_here" != "" ]]; then
    echo "[CANCEL] Installation cancelled. Please cd to your desired installation directory and run this script again."
    echo "         Or use: $0 --yes to skip this prompt"
    exit 1
fi

echo "[OK] Installing Codex CLI in: $(pwd)"
echo ""

# Step 1: Initialize minimal module environment
echo ">>> Step 1: Setting up environment..."

# Initialize module system if available
if [[ -f /tool/pandora64/etc/modules/INIT/bash ]]; then
    echo "[OK] Loading module system..."
    source /tool/pandora64/etc/modules/INIT/bash
elif [[ -f /tool/pandora/etc/modules/INIT/bash ]]; then
    echo "[OK] Loading module system..."
    source /tool/pandora/etc/modules/INIT/bash
else
    echo "[WARN] Module system not found, checking for existing Node.js..."
fi

# Step 2: Load Node.js
echo ">>> Step 2: Loading Node.js..."

if command_exists module; then
    echo "[INFO] Loading latest Node.js via module system..."
    if module load node; then
        echo "[OK] Node.js module loaded successfully"
    else
        echo "[ERROR] Failed to load Node.js module. Checking for existing Node.js..."
    fi
else
    echo "[WARN] Module system not available, checking for existing Node.js..."
fi

# Verify Node.js and print version
if command_exists node; then
    node_version=$(node --version)
    echo "[OK] Node.js $node_version is available"
    
    # Also show npm version
    if command_exists npm; then
        npm_version=$(npm --version)
        echo "[OK] npm $npm_version is available"
    else
        echo "[ERROR] npm not found with Node.js installation"
        exit 1
    fi
else
    echo "[ERROR] Node.js not found. Please ensure Node.js is available via module system or PATH"
    exit 1
fi

echo ""

# Step 3: Configure npm for local installation
echo ">>> Step 3: Configuring npm for local installation..."

# Set npm to use local directories and avoid parent workspace
export NPM_CONFIG_PREFIX="$(pwd)/.npm-global"
export NPM_CONFIG_CACHE="$(pwd)/.npm-cache"
export NPM_CONFIG_USERCONFIG="$(pwd)/.npmrc"
mkdir -p .npm-global .npm-cache

# Create a local .npmrc to isolate from parent workspace
cat > .npmrc << 'EOF'
cache=.npm-cache
fund=false
audit=false
EOF

echo "[INFO] Note: npm prefix warnings are normal and don't affect installation"

# Initialize a new package.json to ensure clean installation
cat > package.json << 'EOF'
{
  "name": "codex-cli-local-install",
  "version": "1.0.0",
  "description": "Local installation of Codex CLI",
  "private": true
}
EOF

echo "[OK] npm configured to use local directories"
echo ""

# Step 4: Install Codex CLI
echo ">>> Step 4: Installing Codex CLI..."
echo "    This may take a few minutes..."

if npm install @openai/codex@latest; then
    echo "[OK] Codex CLI installed successfully"
else
    echo "[ERROR] Failed to install Codex CLI"
    exit 1
fi

# Verify installation
codex_bin="./node_modules/.bin/codex"
if [[ -f "$codex_bin" ]]; then
    echo "[OK] Codex binary found at: $codex_bin"
    
    # Test the installation
    if "$codex_bin" --version >/dev/null 2>&1; then
        codex_version=$("$codex_bin" --version 2>/dev/null || echo "unknown")
        echo "[OK] Codex CLI version: $codex_version"
    else
        echo "[WARN] Codex binary installed but version check failed"
    fi
else
    echo "[ERROR] Codex binary not found after installation"
    exit 1
fi

echo ""

# Step 5: Set up configuration
echo ">>> Step 5: Setting up configuration..."

# Create .codex directory in user's home
mkdir -p ~/.codex

# Create config.toml for Codex CLI (Rust version supports TOML with env vars)
config_file="$HOME/.codex/config.toml"
cat > "$config_file" << 'EOF'
# Codex CLI Configuration for AMD LLM Gateway
# Multi-profile configuration with GPT-5 Codex (high reasoning) as default

# Default model switched to GPT-5 Codex (high-reasoning preset)
model = "gpt-5-codex"
model_provider = "gpt5_gateway"
projects = { "/proj/cad_ml2/zoliu/gateway" = { trust_level = "trusted" } , "/proj/cad_ml2/zoliu/fresh_codex" = { trust_level = "trusted" }, "/proj/cad_ml2/zoliu/AMD_gateway_union" = { trust_level = "trusted" } }

[model_providers.amd_gateway]
name = "AMD LLM Gateway"
base_url = "https://llm-api.amd.com/openai/o3"
wire_api = "responses"
query_params = { api-version = "2025-04-01-preview" }
env_http_headers = { "Ocp-Apim-Subscription-Key" = "AMD_LLM_API_KEY" }

[model_providers.babel_gateway]
name = "Babel Local Gateway"
base_url = "http://localhost:5000/v1"
wire_api = "chat"

[model_providers.gpt5_gateway]
name = "AMD LLM Gateway - GPT-5"
base_url = "https://llm-api.amd.com/openai/gpt-5-codex"
wire_api = "responses"
query_params = { api-version = "2025-04-01-preview" }
env_http_headers = { "Ocp-Apim-Subscription-Key" = "AMD_LLM_API_KEY" }

# Profile for o3 (default)
[profiles.o3]
model = "o3"
model_provider = "amd_gateway"

# Profile for Babel local gateway (non-default)
[profiles.claude]
model = "Claude-Sonnet-4"
model_provider = "babel_gateway"

[profiles.gemini]
model = "gemini-2.5-pro"
model_provider = "babel_gateway"

# Profile for GPT-5 (non-default)
[profiles.gpt5]
# GPT-5 Codex high reasoning profile
model = "gpt-5-codex"
model_provider = "gpt5_gateway"
# GPT-5 specific notes:
# - No temperature parameter support (uses default 1.0)
# - Full tool/function calling support
# - Use max_tokens instead of max_completion_tokens
# - Supports system messages
EOF

echo "[OK] Configuration created at: $config_file"
echo ""

# Step 6: Set up shell aliases
echo ">>> Step 6: Setting up shell aliases..."

codex_path="$(pwd)/node_modules/.bin/codex"
alias_line="alias codex='$codex_path'"

echo "The following alias will allow you to run 'codex' from anywhere:"
echo "   $alias_line"
echo ""

# Handle alias setup - auto-confirm if --yes flag was used
if [[ "$1" == "--yes" || "$1" == "-y" ]]; then
    echo "[OK] Auto-adding shell aliases (--yes flag used)"
    add_alias="y"
else
    add_alias=$(prompt_user "Add this alias to your shell configuration files?" "y")
    # If no response (empty), default to yes
    if [[ -z "$add_alias" ]]; then
        add_alias="y"
    fi
fi

if [[ "$add_alias" == "y" || "$add_alias" == "Y" || "$add_alias" == "yes" ]]; then
    # Add to bashrc if it exists
    if [[ -f ~/.bashrc ]]; then
        if ! grep -q "alias codex=" ~/.bashrc; then
            echo "" >> ~/.bashrc
            echo "# Codex CLI alias - added by setup-codex-cli.sh" >> ~/.bashrc
            echo "$alias_line" >> ~/.bashrc
            echo "[OK] Added alias to ~/.bashrc"
        else
            # Update existing alias to point to new installation
            sed -i.bak "s|alias codex=.*|$alias_line|" ~/.bashrc
            echo "[OK] Updated existing alias in ~/.bashrc"
        fi
        
        # Check and add AMD_LLM_API_KEY if not present
        if ! grep -q "AMD_LLM_API_KEY" ~/.bashrc; then
            echo "" >> ~/.bashrc
            echo "# AMD LLM Gateway API Key - added by setup-codex-cli.sh" >> ~/.bashrc
            echo "# Please replace 'your-api-key-here' with your actual API key" >> ~/.bashrc
            echo "export AMD_LLM_API_KEY=\"your-api-key-here\"" >> ~/.bashrc
            echo "[OK] Added AMD_LLM_API_KEY placeholder to ~/.bashrc"
        else
            echo "[INFO] AMD_LLM_API_KEY already exists in ~/.bashrc"
        fi
    fi
    
    # Add to cshrc if it exists
    if [[ -f ~/.cshrc ]]; then
        csh_alias="alias codex '$codex_path'"
        if ! grep -q "alias codex" ~/.cshrc; then
            echo "" >> ~/.cshrc
            echo "# Codex CLI alias - added by setup-codex-cli.sh" >> ~/.cshrc
            echo "$csh_alias" >> ~/.cshrc
            echo "[OK] Added alias to ~/.cshrc"
        else
            # Update existing alias to point to new installation
            sed -i.bak "s|alias codex .*|$csh_alias|" ~/.cshrc
            echo "[OK] Updated existing alias in ~/.cshrc"
        fi
        
        # Check and add AMD_LLM_API_KEY if not present
        if ! grep -q "AMD_LLM_API_KEY" ~/.cshrc; then
            echo "" >> ~/.cshrc
            echo "# AMD LLM Gateway API Key - added by setup-codex-cli.sh" >> ~/.cshrc
            echo "# Please replace 'your-api-key-here' with your actual API key" >> ~/.cshrc
            echo "setenv AMD_LLM_API_KEY \"your-api-key-here\"" >> ~/.cshrc
            echo "[OK] Added AMD_LLM_API_KEY placeholder to ~/.cshrc"
        else
            echo "[INFO] AMD_LLM_API_KEY already exists in ~/.cshrc"
        fi
    fi
    
    # Add to tcshrc if it exists
    if [[ -f ~/.tcshrc ]]; then
        tcsh_alias="alias codex '$codex_path'"
        if ! grep -q "alias codex" ~/.tcshrc; then
            echo "" >> ~/.tcshrc
            echo "# Codex CLI alias - added by setup-codex-cli.sh" >> ~/.tcshrc
            echo "$tcsh_alias" >> ~/.tcshrc
            echo "[OK] Added alias to ~/.tcshrc"
        else
            # Update existing alias to point to new installation
            sed -i.bak "s|alias codex .*|$tcsh_alias|" ~/.tcshrc
            echo "[OK] Updated existing alias in ~/.tcshrc"
        fi
        
        # Check and add AMD_LLM_API_KEY if not present
        if ! grep -q "AMD_LLM_API_KEY" ~/.tcshrc; then
            echo "" >> ~/.tcshrc
            echo "# AMD LLM Gateway API Key - added by setup-codex-cli.sh" >> ~/.tcshrc
            echo "# Please replace 'your-api-key-here' with your actual API key" >> ~/.tcshrc
            echo "setenv AMD_LLM_API_KEY \"your-api-key-here\"" >> ~/.tcshrc
            echo "[OK] Added AMD_LLM_API_KEY placeholder to ~/.tcshrc"
        else
            echo "[INFO] AMD_LLM_API_KEY already exists in ~/.tcshrc"
        fi
    fi
    
    echo "[OK] Shell aliases and environment variables configured"
else
    echo "[SKIP] Skipped shell alias setup. You can run codex using: $codex_path"
fi

echo ""

# Step 7: Environment variable setup
echo ">>> Step 7: Environment variable setup..."
echo ""
if [[ "$add_alias" == "y" || "$add_alias" == "Y" || "$add_alias" == "yes" ]]; then
    echo "IMPORTANT: AMD_LLM_API_KEY placeholder has been added to your shell config files."
    echo "Please edit your shell configuration files and replace 'your-api-key-here' with your actual API key:"
    echo ""
    echo "For bash users: Edit ~/.bashrc"
    echo "For csh users:  Edit ~/.cshrc" 
    echo "For tcsh users: Edit ~/.tcshrc"
    echo ""
    echo "Look for the line:"
    echo "   export AMD_LLM_API_KEY=\"your-api-key-here\"  (bash)"
    echo "   setenv AMD_LLM_API_KEY \"your-api-key-here\"  (csh/tcsh)"
else
    echo "IMPORTANT: You need to set the AMD_LLM_API_KEY environment variable:"
    echo "   export AMD_LLM_API_KEY=\"your-api-key-here\""
    echo ""
    echo "You can add this to your shell configuration file (e.g., ~/.bashrc) or"
    echo "set it in your current session before using codex."
fi
echo ""

# Final summary
echo ""
echo "  ____       _               ____                      _      _       _ "
echo " / ___|  ___| |_ _   _ _ __  / ___|___  _ __ ___  _ __ | | ___| |_ ___| |"
echo " \___ \ / _ \ __| | | | '_ \| |   / _ \| '_ \` _ \| '_ \| |/ _ \ __/ _ \ |"
echo "  ___) |  __/ |_| |_| | |_) | |__| (_) | | | | | | |_) | |  __/ ||  __/_|"
echo " |____/ \___|\__|\__,_| .__/ \____\___/|_| |_| |_| .__/|_|\___|\__\___(_)"
echo "                     |_|                        |_|                    "
echo ""
echo "========================================================================="
echo ""
echo "Installation Summary:"
echo "  * Installation directory: $(pwd)"
echo "  * Codex binary: $codex_path"
echo "  * Configuration: $config_file"
echo "  * API Key variable: AMD_LLM_API_KEY (needs to be set)"
echo ""
echo "Available model profiles:"
echo "  * codex --profile gpt5    (default, GPT-5 Codex high reasoning, AMD Gateway, responses API)"
echo "  * codex --profile o3      (o3, AMD Gateway, responses API)"
echo "  * codex --profile claude  (Claude-Sonnet-4, Babel local gateway, chat API)"
echo "  * codex --profile gemini  (gemini-2.5-pro, Babel local gateway, chat API)"
echo "  * codex                   (uses GPT-5 Codex by default)"
echo ""
echo "Next steps:"
echo "  1. Set your AMD_LLM_API_KEY environment variable"
echo "  2. Source your shell config or start a new terminal session"
echo "  3. Test with: codex --help"
echo "  4. Optional: Start Babel gateway for local profiles (port 5001)"
echo ""
echo "Happy coding!"
