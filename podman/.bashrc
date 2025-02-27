#!/usr/bin/env bash
# =============================================================================
# .bashrc - Customized shell configuration for interactive sessions.
# =============================================================================

# Exit if not running interactively
[[ $- != *i* ]] && return

# -----------------------------------------------------------------------------
# Environment Setup
# -----------------------------------------------------------------------------

# Load environment variables for Python
# shellcheck disable=SC1091
[[ -f /etc/profile.d/python.sh ]] && source /etc/profile.d/python.sh

# Load aliases if they exist (fixed path)
# shellcheck disable=SC1090
[[ -f ~/.bash_aliases ]] && source ~/.bash_aliases

# -----------------------------------------------------------------------------
# Basic Shell Settings
# -----------------------------------------------------------------------------

umask 002
SHELL="/bin/bash"
TERM="xterm-256color"

# Set the prompt with colors and symbols
# shellcheck disable=SC2025
PS1='\[\e[01;35m\]❯\[\e[0m\] \[\e[01;36m\]\w\[\e[0m\] \[\e[01;34m\]\$\[\e[0m\] '

# -----------------------------------------------------------------------------
# History Settings
# -----------------------------------------------------------------------------

HISTSIZE=1000
HISTFILESIZE=2000
HISTCONTROL=erasedups:ignoredups:ignorespace
shopt -s histverify

if type git_prompt &>/dev/null; then
    PROMPT_COMMAND='history -a; PS1=$(git_prompt)'
fi

# -----------------------------------------------------------------------------
# Shell Options
# -----------------------------------------------------------------------------

shopt -s cdspell checkwinsize cmdhist histappend nocaseglob

# -----------------------------------------------------------------------------
# Environment Variables for Colors
# -----------------------------------------------------------------------------

export CLICOLOR=1
export LSCOLORS=gxBxhxDxfxhxhxhxhxcxcx

# -----------------------------------------------------------------------------
# Color Definitions
# -----------------------------------------------------------------------------

YELLOW=$'\e[33m'
CYAN=$'\e[36m'
RESET=$'\e[0m'

# =============================================================================
# Utility Functions
# =============================================================================

########################################
# print_title
# Description:
#   Prints a title with an optional color.
# Arguments:
#   $1 - The title text to print.
#   $2 - (Optional) The color to use (defaults to CYAN).
########################################
print_title() {
    local title="$1"
    local color="${2:-${CYAN}}"
    echo
    echo -e "${color}${title}${RESET}\n"
}

########################################
# print_subtitle
# Description:
#   Prints a subtitle with an optional color.
# Arguments:
#   $1 - The subtitle text to print.
#   $2 - (Optional) The color to use (defaults to YELLOW).
########################################
print_subtitle() {
    local subtitle="$1"
    local color="${2:-${YELLOW}}"
    echo -e "${color}${subtitle}${RESET}\n"
}

########################################
# print_help_section
# Description:
#   Prints a help section with a title and a list of alias commands with their
#   corresponding descriptions.
# Arguments:
#   $1 - The section title.
#   $@ - Pairs of alias and description.
########################################
print_help_section() {
    local title="$1"
    shift
    print_title "${title}"
    while [[ "$#" -gt 0 ]]; do
        local cmd="$1"
        local desc="$2"
        shift 2
        printf "  ${CYAN}➜ %-2s${RESET} - %s\n" "${cmd}" "${desc}"
    done
    echo ""
}

########################################
# prompt_next
# Description:
#   Prompts the user to press any key to view the next section or 'q' to quit.
# Returns:
#   0 if continuing, 1 if quitting.
########################################
prompt_next() {
    print_subtitle "Press any key to view the next section, or 'q' to quit"
    # shellcheck disable=SC2162
    read -n 1 -s choice
    if [[ "${choice}" == "q" ]]; then
        return 1
    fi
    clear
    return 0
}

########################################
# h
# Description:
#   Alias for invoking the help menu.
########################################
h() {
    show_help_menu
}

# =============================================================================
# Help Menu Functions
# =============================================================================

########################################
# show_help_menu
# Description:
#   Displays a help menu organized by category. Each alias follows a two-letter
#   convention: a fixed prefix denoting the tool (g, c, r, l, etc.) followed by
#   one additional mnemonic letter.
########################################
show_help_menu() {
    clear

    print_help_section "Navigation Commands 🧭" \
        "nh" "Go to home" \
        "n1" "Up one directory" \
        "n2" "Up two directories" \
        "n3" "Up three directories" \
        "n4" "Up four directories"

    prompt_next || { system_info; return; }

    print_help_section "List Commands 📁" \
        "l" "List files" \
        "la" "List all files" \
        "ld" "List directories" \
        "lf" "List files with details" \
        "ll" "Detailed file listing" \
        "lt" "List files by modified time" \
        "lr" "Reverse file listing"

    prompt_next || { system_info; return; }

    print_help_section "System Management (no prefix)" \
        "a" "Edit aliases" \
        "b" "Edit bashrc" \
        "c" "Clear screen" \
        "d" "Delete file" \
        "e" "Open editor" \
        "p" "List processes" \
        "q" "Exit shell" \
        "r" "Reload configuration" \
        "t" "Create file" \
        "v" "Open editor" \
        "x" "Exit shell"

    prompt_next || { system_info; return; }

    print_help_section "Git Commands 🌿" \
        "g" "Git" \
        "ga" "Stage all changes" \
        "gb" "Create & checkout branch" \
        "gc" "Commit changes" \
        "gd" "Delete branch locally" \
        "ge" "Delete remote branch" \
        "gg" "Display log graph" \
        "gi" "Initialize repository" \
        "gk" "Checkout branch" \
        "gl" "Clone repository" \
        "gm" "Merge main/master" \
        "gp" "Push changes" \
        "gq" "Pull changes" \
        "gr" "Rebase branch" \
        "gs" "Git status"

    prompt_next || { system_info; return; }

    print_help_section "Python Commands 🐍" \
        "pya" "Activate virtual environment" \
        "pyc" "Check for vulnerabilities with Safety" \
        "pyd" "Deactivate virtual environment" \
        "pyf" "Format code with Black" \
        "pyi" "Install package with Pip" \
        "pyl" "Lint code with Ruff" \
        "pyr" "Run script" \
        "pyt" "Run tests with pytest" \
        "pyu" "Update package with Pip" \
        "pyv" "Create virtual environment"

    prompt_next || { system_info; return; }

    print_help_section "Poetry Commands 📜" \
        "poa" "Add package" \
        "poc" "Check for vulnerabilities" \
        "poe" "Export requirements" \
        "pog" "Generate lock file" \
        "poi" "Install dependencies" \
        "pol" "List packages" \
        "pou" "Update package" \
        "pov" "Show version"

    prompt_next || { system_info; return; }

    print_help_section "isort Commands 🧹" \
        "is" "Sort imports" \
        "isr" "Sort imports recursively"

    prompt_next || { system_info; return; }

    print_help_section "flake8 Commands 🔍" \
        "fl" "Lint code" \
        "flf" "Lint code with format"

    prompt_next || { system_info; return; }

    print_help_section "ruff Commands 🔍" \
        "ru" "Lint code" \
        "ruc" "Check code"

    prompt_next || { system_info; return; }

    print_help_section "black Commands ✨" \
        "bl" "Format code"

    echo -e "\n${YELLOW}Press any key to return to system info or 'c' to clear screen${RESET}"

    # shellcheck disable=SC2162
    read -n 1 -s final_choice
    if [[ ${final_choice} == "c" ]]; then
        clear
    else
        system_info
    fi
}

########################################
# system_info
# Description:
#   Displays system information upon login and prompts for help menu access.
########################################
system_info() {
    clear
    print_title "LLAMADEV"
    print_subtitle "Press 'h' to access the Help menu"
    if [[ "${choice}" == "h" ]]; then
        show_help_menu
    fi
}

# =============================================================================
# Final Shell Configuration
# =============================================================================

# Enable auto-completion list automatically
bind "set show-all-if-ambiguous On"

# Add help alias for quick access
alias help='show_help_menu'

# **Ensure system_info runs first but does not delay the prompt**
system_info
