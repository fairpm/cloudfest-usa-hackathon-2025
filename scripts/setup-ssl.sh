#!/usr/bin/env bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Detect OS
OS="unknown"
if [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == "linux-musl"* ]]; then
    OS="linux"
    # Check if running in WSL
    if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null ; then
        OS="wsl2"
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
fi

echo -e "${GREEN}CloudFest Hackathon - SSL Certificate Setup${NC}"
echo "================================================"
echo ""
echo "Detected OS: $OS"
echo ""

# Function to check if mkcert is installed
check_mkcert() {
    if command -v mkcert &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to install mkcert
install_mkcert() {
    echo -e "${YELLOW}Installing mkcert...${NC}"

    case $OS in
        "macos")
            if command -v brew &> /dev/null; then
                brew install mkcert
                brew install nss # for Firefox
            else
                echo -e "${RED}Error: Homebrew is required. Install it from https://brew.sh${NC}"
                exit 1
            fi
            ;;
        "linux"|"wsl2")
            # Check if running as root (not recommended)
            if [[ $EUID -eq 0 ]]; then
                echo -e "${YELLOW}Warning: Running as root. This is not recommended.${NC}"
            fi

            # Try to download and install mkcert
            MKCERT_VERSION="v1.4.4"
            MKCERT_BINARY="mkcert-${MKCERT_VERSION}-linux-amd64"

            echo "Downloading mkcert ${MKCERT_VERSION}..."
            curl -L "https://github.com/FiloSottile/mkcert/releases/download/${MKCERT_VERSION}/${MKCERT_BINARY}" -o /tmp/mkcert
            chmod +x /tmp/mkcert

            # Try to install to /usr/local/bin, fallback to ~/bin
            if sudo mv /tmp/mkcert /usr/local/bin/mkcert 2>/dev/null; then
                echo -e "${GREEN}Installed mkcert to /usr/local/bin${NC}"
            else
                mkdir -p "$HOME/bin"
                mv /tmp/mkcert "$HOME/bin/mkcert"
                echo -e "${YELLOW}Installed mkcert to ~/bin (add to PATH if needed)${NC}"
                export PATH="$HOME/bin:$PATH"
            fi

            # Install dependencies for NSS (Firefox, Chrome)
            if command -v apt-get &> /dev/null; then
                echo "Installing NSS tools..."
                sudo apt-get update -qq
                sudo apt-get install -y libnss3-tools
            elif command -v yum &> /dev/null; then
                sudo yum install -y nss-tools
            fi
            ;;
        *)
            echo -e "${RED}Error: Unsupported operating system${NC}"
            exit 1
            ;;
    esac
}

# Check and install mkcert if needed
if ! check_mkcert; then
    echo -e "${YELLOW}mkcert is not installed.${NC}"
    read -p "Would you like to install mkcert now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_mkcert
    else
        echo -e "${RED}Error: mkcert is required. Please install it manually.${NC}"
        echo "Visit: https://github.com/FiloSottile/mkcert"
        exit 1
    fi
fi

# Install local CA
echo -e "${YELLOW}Installing local Certificate Authority...${NC}"
mkcert -install

# Create certs directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CERTS_DIR="$PROJECT_DIR/traefik/certs"

mkdir -p "$CERTS_DIR"

# Generate certificates
echo -e "${YELLOW}Generating SSL certificates...${NC}"
cd "$CERTS_DIR"

# Generate wildcard certificate for *.aspiredev.local
mkcert \
    -cert-file aspiredev.local.pem \
    -key-file aspiredev.local-key.pem \
    "*.aspiredev.local" \
    "aspiredev.local" \
    "localhost" \
    "127.0.0.1" \
    "::1"

echo ""
echo -e "${GREEN}SSL certificates generated successfully!${NC}"
echo ""

# Update /etc/hosts
echo -e "${YELLOW}Updating /etc/hosts...${NC}"

HOSTS_ENTRIES=(
    "127.0.0.1 api.aspiredev.local"
    "127.0.0.1 mail.aspiredev.local"
    "127.0.0.1 db.aspiredev.local"
    "127.0.0.1 aspiredev.local"
)

HOSTS_FILE="/etc/hosts"
NEEDS_UPDATE=false

for entry in "${HOSTS_ENTRIES[@]}"; do
    if ! grep -q "$entry" "$HOSTS_FILE" 2>/dev/null; then
        NEEDS_UPDATE=true
        break
    fi
done

if [ "$NEEDS_UPDATE" = true ]; then
    echo "The following entries need to be added to /etc/hosts:"
    for entry in "${HOSTS_ENTRIES[@]}"; do
        echo "  $entry"
    done
    echo ""

    # Try to add automatically (requires sudo)
    if [[ $OS == "wsl2" ]]; then
        echo -e "${YELLOW}WSL2 detected. You may need to update both WSL and Windows hosts files.${NC}"
        echo "Windows hosts file location: C:\\Windows\\System32\\drivers\\etc\\hosts"
        echo ""
    fi

    read -p "Would you like to add these entries now? (requires sudo) (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        for entry in "${HOSTS_ENTRIES[@]}"; do
            if ! grep -q "$entry" "$HOSTS_FILE" 2>/dev/null; then
                echo "$entry" | sudo tee -a "$HOSTS_FILE" > /dev/null
            fi
        done
        echo -e "${GREEN}/etc/hosts updated successfully!${NC}"
    else
        echo -e "${YELLOW}Please add the entries manually to /etc/hosts${NC}"
    fi
else
    echo -e "${GREEN}/etc/hosts already configured!${NC}"
fi

echo ""
echo -e "${GREEN}Setup complete!${NC}"
echo ""
echo "You can now start the services with:"
echo "  npm run dev:start"
echo ""
echo "Access the services at:"
echo "  - AspireCloud API: https://api.aspiredev.local"
echo "  - Mailhog UI: https://mail.aspiredev.local"
echo "  - Adminer (DB): https://db.aspiredev.local"
echo "  - WordPress: http://localhost:8888"
echo "  - Traefik Dashboard: http://localhost:8090"
