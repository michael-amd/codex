# Codex CLI Setup for AMD LLM Gateway

This repository contains an automated setup script for installing and configuring [Codex CLI](https://github.com/openai/codex) to work with AMD's LLM Gateway.

## Overview

Codex CLI is OpenAI's command-line tool for AI-assisted coding. This setup script configures it to use AMD's LLM Gateway, supporting multiple model profiles including o3, GPT-5, Claude Sonnet 4, and Gemini 2.5 Pro.

## Features

- 🚀 **Automated Installation**: Interactive setup with confirmation prompts
- 🔧 **Multi-Profile Configuration**: Support for o3, GPT-5, Claude, and Gemini models
- 📁 **Portable Installation**: Installs locally in current directory
- 🛠 **Shell Integration**: Automatic shell alias setup for bash, csh, and tcsh
- ✅ **Dependency Checking**: Validates Node.js and npm availability

## Prerequisites

- **Node.js 18+**: Required for Codex CLI
  - Install from [https://nodejs.org/en/download](https://nodejs.org/en/download)
- **npm**: Node package manager (usually included with Node.js)
- **AMD LLM API Key**: Valid API key for AMD's LLM Gateway
- **Linux/Unix Environment**: Script designed for bash shell environments

## Quick Start

1. **Clone or download this repository**
2. **Run the setup script**:
   ```bash
   ./setup-codex-cli.sh
   ```
3. **Set your API key** in your shell config file (automatically added):
   - For bash: Edit `~/.bashrc`
   - For csh: Edit `~/.cshrc`
   - For tcsh: Edit `~/.tcshrc`

   Replace `your-api-key-here` with your actual API key.

4. **Start using Codex**:
   ```bash
   codex
   ```

## Installation Options

The setup script provides:

- **Interactive Mode** (default): Prompts for confirmation before installation
- **Auto-confirm Mode**: Use `--yes` or `-y` flag to skip prompts

Both modes install Codex CLI in the current directory and create shell aliases for easy access.

## Configuration

### Model Profiles

The setup creates multiple model profiles in `~/.codex/config.toml`:

- **o3** (default): Uses AMD Gateway with responses API
- **gpt5**: GPT-5 via AMD Gateway with responses API
- **claude**: Claude Sonnet 4 via Babel local gateway
- **gemini**: Gemini 2.5 Pro via Babel local gateway

Switch profiles using:
```bash
codex --profile gpt5
codex --profile claude
codex --profile gemini
```

### Environment Variables

Set your AMD LLM API key:

**For bash users** (add to `~/.bashrc`):
```bash
export AMD_LLM_API_KEY='your-api-key-here'
```

**For csh/tcsh users** (add to `~/.cshrc` or `~/.tcshrc`):
```csh
setenv AMD_LLM_API_KEY 'your-api-key-here'
```

### Gateway Endpoints

- **AMD Gateway**: `https://llm-api.amd.com/openai/{model}`
- **Babel Local Gateway**: `http://localhost:5000/v1` (optional, for Claude/Gemini)

## Usage Examples

```bash
# Start interactive Codex session with default (o3) model
codex

# Use a specific profile
codex --profile gpt5
codex --profile claude

# Get help
codex --help

# Check version
codex --version
```

## File Structure

```
codex/
├── setup-codex-cli.sh    # Main setup script
├── .npmrc                # npm configuration (created during setup)
├── package.json          # NPM dependencies (created during setup)
└── README.md             # This file
```

## What the Setup Script Does

1. **Directory Confirmation**: Verifies installation location
2. **Environment Setup**: Loads module system (if available)
3. **Node.js Validation**: Checks for Node.js 18+ and npm
4. **npm Configuration**: Sets up local npm directories
5. **Package Installation**: Installs `@openai/codex` via npm
6. **Configuration**: Creates `~/.codex/config.toml` with multi-profile setup
7. **Shell Integration**: Adds aliases and API key placeholders to shell configs

## Troubleshooting

### Node.js Version Issues
If you get Node.js version errors, install Node.js 18+ from [nodejs.org](https://nodejs.org/) or use a version manager like [nvm](https://github.com/nvm-sh/nvm).

### API Key Issues
Verify your `AMD_LLM_API_KEY` is set correctly:
```bash
echo $AMD_LLM_API_KEY
```

### Babel Gateway for Local Models
To use Claude or Gemini profiles, ensure Babel gateway is running on `localhost:5000`.

### Module System
The script attempts to use the Pandora module system if available. If not found, it falls back to checking system PATH for Node.js.

## Model-Specific Notes

### o3 (Default)
- Uses AMD Gateway responses API
- Full tool/function calling support

### GPT-5
- No temperature parameter support (uses default 1.0)
- Use `max_tokens` instead of `max_completion_tokens`
- Full tool/function calling support

### Claude Sonnet 4
- Requires Babel local gateway
- Uses chat API format

### Gemini 2.5 Pro
- Requires Babel local gateway
- Uses chat API format
