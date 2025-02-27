# shellcheck disable=SC2148

##############################
# Color Definitions
##############################
CYAN='\033[01;36m'
GREEN='\033[01;32m'
YELLOW='\033[01;33m'
RED='\033[01;31m'
RESET='\033[0m'

##############################
# Output Function
##############################
# Usage: color_out <emoji> <message> [optional-message-color]
color_out() {
    local emoji="$1"
    local message="$2"
    local msg_color="${3:-$CYAN}"
    printf "%b%s %s%b\n" "${msg_color}" "${emoji}" "${message}" "${RESET}" >&2
}

##############################
# Navigation Commands (prefix: n)
##############################
alias nh='color_out "🏠" "Going home:" && cd ~'
alias n1='color_out "📂" "Moving up one level:" && cd ..'
alias n2='color_out "📂" "Moving up two levels:" && cd ../..'
alias n3='color_out "📂" "Moving up three levels:" && cd ../../..'
alias n4='color_out "📂" "Moving up four levels:" && cd ../../../..'

##############################
# File Operations (prefix: l)
##############################
alias l='color_out "📋" "File listing:" && ls -lFh --color=auto --group-directories-first'
alias la='color_out "📋" "All files:" && ls -AlFh --color=auto --group-directories-first'
alias ld='color_out "📁" "Listing directories:" && ls -d */'
alias lf='color_out "📄" "Files only:" && ls -l --color=auto | grep -v "^d"'
alias ll='color_out "📋" "Detailed listing:" && ls -lAFh --color=auto --group-directories-first'
alias lt='color_out "⏲️" "Time-sorted:" && ls -ltrFh --color=auto'
alias lr='color_out "⏲️" "Reverse time-sorted:" && ls -ltFh --color=auto --reverse'

##############################
# System Management (no prefix)
##############################
alias a='color_out "📝" "Editing aliases..." && nvim ~/.bash_aliases && source ~/.bash_aliases && color_out "🔄" "Aliases updated"'
alias b='color_out "📝" "Editing bashrc..." && nvim ~/.bashrc && source ~/.bashrc && color_out "🔄" "Bashrc updated"'
alias c='color_out "🧹" "Clearing screen..." && clear && printf "\e[3J"'
alias d='color_out "🗑️" "Deleting file:" && rm'
alias e='color_out "📝" "Opening editor..." && nvim'
alias p='color_out "⚙️" "Process list:" && ps aux'
alias q='color_out "👋" "Exiting shell..." && exit'
alias r='color_out "🔄" "Reloading configuration..." && source ~/.bashrc && source ~/.bash_aliases && color_out "✅" "Configuration reloaded"'
t() {
    color_out "📝" "Create an empty file $1"
    touch "$1"
}
alias v='color_out "📝" "Opening editor..." && nvim'
alias x='color_out "👋" "Exiting shell..." && exit'

##############################
# Git Commands (prefix: g)
##############################
##############################
# Git Commands (prefix: g)
##############################
if command -v git >/dev/null 2>&1; then
    alias g='git'
    alias ga='color_out "📦" "Staging changes..." && git add --all && color_out "✅" "Changes staged"'
    alias gi='color_out "📦" "Initializing repository..." && git init && color_out "✅" "Repository initialized"'
    # Rename pull alias from "gpl" to "gq" as per help menu:
    alias gq='color_out "⬇️" "Pulling changes..." && git pull && color_out "✅" "Changes pulled"'
    # Rename status alias to "gs":
    alias gs='color_out "📊" "Repository status:" && git status'
    alias gp='color_out "⬆️" "Pushing changes..." && git push && color_out "✅" "Changes pushed"'
    alias gg='color_out "📊" "Git log graph:" && git log --oneline --graph --decorate --all --color'

    # Git functions—rename to match help menu:
    gc() {
        if [[ -z "$1" ]]; then
            color_out "❌" "Please provide a commit message" "$RED"
            return 1
        fi
        color_out "💾" "Committing changes..." "$YELLOW"
        if git commit -m "$*"; then
            color_out "✅" "Committed: $*" "$GREEN"
        else
            color_out "❌" "Commit failed" "$RED"
            return 1
        fi
    }
    # "gb": Create & checkout branch (was gcb)
    gb() {
        if [[ -z "$1" ]]; then
            color_out "❌" "Please provide a branch name" "$RED"
            return 1
        fi
        color_out "🌱" "Creating branch: $1" "$YELLOW"
        if git checkout -b "$1"; then
            color_out "✅" "Created and switched to: $1" "$GREEN"
        else
            color_out "❌" "Branch creation failed" "$RED"
            return 1
        fi
    }
    # "gk": Checkout branch (was gco)
    gk() {
        if [[ -z "$1" ]]; then
            color_out "❌" "Please specify a branch" "$RED"
            return 1
        fi
        color_out "🔄" "Switching to: $1" "$YELLOW"
        if git checkout "$1"; then
            color_out "✅" "Switched to: $1" "$GREEN"
        else
            color_out "❌" "Switch failed" "$RED"
            return 1
        fi
    }
    # "gd": Delete branch locally (was gbd)
    gd() {
        if [[ -z "$1" ]]; then
            color_out "❌" "Please specify a branch to delete" "$RED"
            return 1
        fi
        color_out "🗑️" "Deleting branch: $1" "$YELLOW"
        if git branch -d "$1"; then
            color_out "✅" "Deleted: $1" "$GREEN"
        else
            color_out "❌" "Deletion failed" "$RED"
            return 1
        fi
    }
    # "ge": Delete remote branch (was gbrd)
    ge() {
        if [[ -z "$1" ]]; then
            color_out "❌" "Please specify a remote branch to remove" "$RED"
            return 1
        fi
        color_out "🗑️" "Removing remote branch: $1" "$YELLOW"
        if git push origin --delete "$1"; then
            color_out "✅" "Removed remote: $1" "$GREEN"
        else
            color_out "❌" "Remote deletion failed" "$RED"
            return 1
        fi
    }
    # "gm": Merge main/master (was gcf)
    gm() {
        color_out "🔄" "Merging $(git symbolic-ref --short HEAD) with remote main/master..." "$YELLOW"
        if git checkout "$(git rev-parse --abbrev-ref HEAD)" && git pull && git merge origin/$(git rev-parse --abbrev-ref HEAD); then
            color_out "✅" "Merge complete" "$GREEN"
        else
            color_out "❌" "Merge failed" "$RED"
            return 1
        fi
    }
    # "gr": Rebase branch (was gcm)
    gr() {
        if [[ -z "$1" ]]; then
            color_out "❌" "Please specify a branch to rebase onto" "$RED"
            return 1
        fi
        color_out "🔄" "Rebasing on $1..." "$YELLOW"
        if git rebase "$1"; then
            color_out "✅" "Rebased on $1" "$GREEN"
        else
            color_out "❌" "Rebase failed" "$RED"
            return 1
        fi
    }

    # Additional Git functions (not in help menu but available)
    gpr() {
        local BRANCH
        BRANCH=$(git rev-parse --abbrev-ref HEAD)
        color_out "🔄" "Syncing ${BRANCH}..." "$YELLOW"
        if git pull --rebase origin "${BRANCH}" && git push; then
            color_out "✅" "Synced ${BRANCH}" "$GREEN"
        else
            color_out "❌" "Sync failed" "$RED"
            return 1
        fi
    }
    gpo() {
        if [[ -z "$1" ]]; then
            color_out "❌" "Please specify a branch for push" "$RED"
            return 1
        fi
        color_out "⬆️" "Pushing to $1..." "$YELLOW"
        if git push origin "$1"; then
            color_out "✅" "Pushed to $1" "$GREEN"
        else
            color_out "❌" "Push failed" "$RED"
            return 1
        fi
    }
fi

##############################
# Ollama Commands (prefix: o)
##############################

# Ollama aliases
alias o='ollama'
alias oc='ollama create'
alias osh='ollama show'
alias ol='ollama list'
alias op='ollama pull'
alias os='ollama serve'
alias or='ollama run'
alias orm='ollama remove'

##############################
# Python Commands (prefix: py)
##############################
# Create and manage virtual environments
pyv() {
    if [[ -z "$1" ]]; then
        color_out "❌" "Please provide a name for the virtual environment" "$RED"
        return 1
    fi
    color_out "🐍" "Creating virtual environment: $1" "$YELLOW"
    if python -m venv "$1"; then
        color_out "✅" "Virtual environment created: $1" "$GREEN"
    else
        color_out "❌" "Failed to create virtual environment" "$RED"
        return 1
    fi
}

# Activate virtual environment
pya() {
    if [[ -f "./venv/bin/activate" ]]; then
        color_out "🔌" "Activating virtual environment..." "$YELLOW"
        source "./venv/bin/activate"
        color_out "✅" "Virtual environment activated" "$GREEN"
    else
        color_out "❌" "No virtual environment found in ./venv" "$RED"
        return 1
    fi
}

# Deactivate virtual environment
alias pyd='color_out "🔌" "Deactivating virtual environment..." && deactivate && color_out "✅" "Virtual environment deactivated"'

# Run Python tests
alias pyt='color_out "🧪" "Running tests..." && pytest && color_out "✅" "Tests completed"'

# Format Python code
alias pyf='color_out "✨" "Formatting code..." && black . && color_out "✅" "Code formatted"'

# Lint Python code
alias pyl='color_out "🔍" "Linting code..." && ruff check . && color_out "✅" "Linting completed"'

# Install Python package
pyi() {
    if [[ -z "$1" ]]; then
        color_out "❌" "Please specify a package to install" "$RED"
        return 1
    fi
    color_out "📦" "Installing package: $1" "$YELLOW"
    if pip install "$1"; then
        color_out "✅" "Package installed: $1" "$GREEN"
    else
        color_out "❌" "Installation failed" "$RED"
        return 1
    fi
}

# Run Python script
pyr() {
    if [[ -z "$1" ]]; then
        color_out "❌" "Please specify a script to run" "$RED"
        return 1
    fi
    color_out "▶️" "Running script: $1" "$YELLOW"
    python "$1"
}

# Python aliases
alias python="python3.13"
alias python3="python3.13"

# Pip aliases
alias pip="pip3.13"
alias pip3="pip3.13"

# Upgrade all installed Python packages
alias pyu='color_out "🔄" "Upgrading installed Python packages..." && pip list --outdated | cut -d" " -f1 | xargs -n1 pip install -U && color_out "✅" "All packages upgraded"'

# Remove .pyc files
alias pyc='color_out "🧹" "Removing .pyc files..." && find . -name "*.pyc" -delete && color_out "✅" "All .pyc files removed"'

##############################
# Poetry Commands (no prefix)
##############################
if command -v poetry >/dev/null 2>&1; then
    alias poa='color_out "📦" "Adding package..." && poetry add'
    alias poc='color_out "🔍" "Checking dependencies..." && poetry check'
    alias poe='color_out "📜" "Exporting requirements..." && poetry export -f requirements.txt'
    alias pog='color_out "🔄" "Generating lock file..." && poetry lock'
    alias poi='color_out "📦" "Installing dependencies..." && poetry install'
    alias pol='color_out "📋" "Listing packages..." && poetry show'
    alias pou='color_out "📦" "Updating package..." && poetry update'
    alias pov='color_out "🔍" "Checking version..." && poetry --version'
fi

##############################
# isort Commands 🧹
##############################
alias is='color_out "🧹" "Sorting imports..." && isort . && color_out "✅" "Imports sorted"'
alias isr='color_out "🧹" "Sorting imports recursively..." && isort **/*.py && color_out "✅" "Imports sorted recursively"'

##############################
# flake8 Commands 🔍
##############################
alias fl='color_out "🔍" "Running flake8 linter..." && flake8 . && color_out "✅" "Linting completed"'
alias flf='color_out "🔍" "Running flake8 with format..." && flake8 --format=default . && color_out "✅" "Linting formatted"'

##############################
# ruff Commands 🔍
##############################
alias ru='color_out "🔍" "Running ruff linter..." && ruff check . && color_out "✅" "Linting completed"'
alias ruc='color_out "🔍" "Checking code with ruff..." && ruff check --fix . && color_out "✅" "Ruff checks completed"'

##############################
# black Commands ✨
##############################
alias bl='color_out "✨" "Formatting with black..." && black . && color_out "✅" "Code formatted"'
