#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# FAIR Plugin Development Setup
# ============================================================================
# This script helps set up the FAIR plugin for local development and
# contributions back to the upstream repository.
#
# NOTE: The FAIR plugin is automatically cloned when you run 'npm run dev:start'
#       This script is optional and only needed if you want to set up fork remotes
#       for contributing changes back to FAIR.
#
# Usage:
#   ./scripts/setup-fair-dev.sh [--fork YOUR_GITHUB_USERNAME]
#
# Options:
#   --fork USERNAME    Set up remotes for your fork (for contributing)
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FAIR_DIR="$PROJECT_ROOT/plugins/fair"
UPSTREAM_REPO="https://github.com/fairpm/fair-plugin.git"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# Helper Functions
# ============================================================================

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# ============================================================================
# Main Setup Functions
# ============================================================================

check_prerequisites() {
    print_header "Checking Prerequisites"

    # Check if git is installed
    if ! command -v git &> /dev/null; then
        print_error "git is not installed. Please install git first."
        exit 1
    fi
    print_success "git is installed"

    # Check if we're in the right directory
    if [[ ! -f "$PROJECT_ROOT/.wp-env.json" ]]; then
        print_error "This script must be run from the project root or scripts directory"
        exit 1
    fi
    print_success "Running in correct directory"
}

clone_fair_plugin() {
    print_header "Cloning FAIR Plugin"

    if [[ -d "$FAIR_DIR" ]]; then
        print_warning "FAIR plugin already exists at $FAIR_DIR"
        print_info "Skipping clone. Use 'cd plugins/fair && git pull' to update."
        return 0
    fi

    print_info "Cloning from $UPSTREAM_REPO..."
    mkdir -p "$PROJECT_ROOT/plugins"
    git clone "$UPSTREAM_REPO" "$FAIR_DIR"
    print_success "FAIR plugin cloned successfully"
}

configure_git_signoff() {
    print_header "Configuring Git for Code Signoff"

    cd "$FAIR_DIR"

    # Check if user.name and user.email are set
    GIT_USER_NAME=$(git config user.name || echo "")
    GIT_USER_EMAIL=$(git config user.email || echo "")

    if [[ -z "$GIT_USER_NAME" ]] || [[ -z "$GIT_USER_EMAIL" ]]; then
        print_warning "Git user information not configured for FAIR plugin"
        echo ""
        echo "FAIR requires code signoff on all commits."
        echo "Please enter your information:"
        echo ""

        if [[ -z "$GIT_USER_NAME" ]]; then
            read -p "Your full name: " input_name
            git config user.name "$input_name"
            print_success "Set user.name to '$input_name'"
        fi

        if [[ -z "$GIT_USER_EMAIL" ]]; then
            read -p "Your email: " input_email
            git config user.email "$input_email"
            print_success "Set user.email to '$input_email'"
        fi
    else
        print_success "Git user configured: $GIT_USER_NAME <$GIT_USER_EMAIL>"
    fi

    echo ""
    print_info "Remember to use 'git commit -s' to sign off your commits!"
    print_info "Or run: git config commit.gpgsign false && git config format.signOff true"
}

setup_fork_remotes() {
    local fork_username="$1"

    print_header "Setting Up Fork Remotes"

    cd "$FAIR_DIR"

    # Check if we already have the upstream remote
    if git remote get-url upstream &> /dev/null; then
        print_warning "Remote 'upstream' already exists"
        print_info "Current upstream: $(git remote get-url upstream)"
    else
        # Rename origin to upstream
        print_info "Renaming 'origin' to 'upstream'..."
        git remote rename origin upstream || true
        print_success "Remote 'origin' renamed to 'upstream'"
    fi

    # Add user's fork as origin
    local fork_url="https://github.com/$fork_username/fair-plugin.git"

    if git remote get-url origin &> /dev/null; then
        print_warning "Remote 'origin' already exists"
        print_info "Current origin: $(git remote get-url origin)"
        echo ""
        read -p "Update origin to $fork_url? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git remote set-url origin "$fork_url"
            print_success "Updated origin to $fork_url"
        fi
    else
        print_info "Adding your fork as 'origin': $fork_url"
        git remote add origin "$fork_url"
        print_success "Added origin remote"
    fi

    echo ""
    print_info "Remote configuration:"
    git remote -v
}

create_development_branch() {
    print_header "Creating Development Branch"

    cd "$FAIR_DIR"

    # Make sure we're on main
    git checkout main &> /dev/null || git checkout master &> /dev/null || true

    echo ""
    print_info "Ready to create a development branch!"
    print_info "Branch naming conventions:"
    print_info "  - feature/descriptive-name  (new features)"
    print_info "  - fix/issue-description     (bug fixes)"
    print_info "  - docs/what-changed         (documentation)"
    print_info "  - refactor/what-changed     (refactoring)"
    echo ""

    read -p "Create a new branch now? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Branch name: " branch_name
        if [[ -n "$branch_name" ]]; then
            git checkout -b "$branch_name"
            print_success "Created and checked out branch: $branch_name"
        else
            print_warning "No branch name provided, staying on main"
        fi
    else
        print_info "You can create a branch later with: cd plugins/fair && git checkout -b feature/your-feature"
    fi
}

print_next_steps() {
    print_header "Setup Complete!"

    echo -e "${GREEN}FAIR Plugin is ready for development!${NC}\n"

    echo "Next steps:"
    echo ""
    echo "1. Start WordPress to load FAIR from local source:"
    echo "   ${BLUE}npm run wp:stop && npm run wp:start${NC}"
    echo ""
    echo "2. Make changes to the FAIR plugin:"
    echo "   ${BLUE}cd plugins/fair${NC}"
    echo "   ${BLUE}# Edit files...${NC}"
    echo ""
    echo "3. Test your changes (restart WordPress after edits):"
    echo "   ${BLUE}npm run wp:stop && npm run wp:start${NC}"
    echo ""
    echo "4. Commit with signoff:"
    echo "   ${BLUE}git add .${NC}"
    echo "   ${BLUE}git commit -s -m \"Your commit message\"${NC}"
    echo ""
    echo "5. Push to your fork (if configured):"
    echo "   ${BLUE}git push origin your-branch-name${NC}"
    echo ""
    echo "6. Create a Pull Request on GitHub:"
    echo "   ${BLUE}https://github.com/fairpm/fair-plugin/compare${NC}"
    echo ""
    echo "For detailed instructions, see:"
    echo "   ${BLUE}docs/contributing-to-fair.md${NC}"
    echo ""
}

# ============================================================================
# Main Script
# ============================================================================

main() {
    local fork_username=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --fork)
                fork_username="$2"
                shift 2
                ;;
            -h|--help)
                echo "Usage: $0 [--fork YOUR_GITHUB_USERNAME]"
                echo ""
                echo "Options:"
                echo "  --fork USERNAME    Set up remotes for your fork (for contributing)"
                echo "  -h, --help         Show this help message"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done

    print_header "FAIR Plugin Development Setup"
    print_info "This script sets up the FAIR plugin for local development"

    check_prerequisites
    clone_fair_plugin
    configure_git_signoff

    if [[ -n "$fork_username" ]]; then
        setup_fork_remotes "$fork_username"
        create_development_branch
    else
        print_info "To set up fork remotes later, run:"
        print_info "  $0 --fork YOUR_GITHUB_USERNAME"
    fi

    print_next_steps
}

main "$@"
