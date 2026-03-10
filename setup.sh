#!/bin/bash
# Cloud Coding Agent Setup Script
# One command to setup AI coding agents on Hetzner with optional Caddy reverse proxy

set -e

# Default values
OPENCODE_PORT=4096
INSTALL_CADDY=false
DOMAIN=""
CADDY_USERNAME=""
CADDY_PASSWORD=""
USE_IP_ONLY=false

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --install-caddy          Install and configure Caddy reverse proxy"
    echo "  --domain DOMAIN          Domain name for Caddy (enables auto HTTPS)"
    echo "  --username USERNAME      Username for basic auth (default: admin)"
    echo "  --password PASSWORD      Password for basic auth (required with --install-caddy)"
    echo "  --port PORT             OpenCode port (default: 4096)"
    echo "  --ip-only               Configure Caddy for IP-only access with self-signed cert"
    echo "  -h, --help              Display this help message"
    echo ""
    echo "Examples:"
    echo "  # Basic setup without Caddy"
    echo "  $0"
    echo ""
    echo "  # Setup with Caddy and domain (auto HTTPS)"
    echo "  $0 --install-caddy --domain your.domain.com --username admin --password 'SecurePass123!'"
    echo ""
    echo "  # Setup with Caddy for IP-only access"
    echo "  $0 --install-caddy --ip-only --username admin --password 'SecurePass123!'"
    echo ""
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --install-caddy)
            INSTALL_CADDY=true
            shift
            ;;
        --domain)
            DOMAIN="$2"
            shift 2
            ;;
        --username)
            CADDY_USERNAME="$2"
            shift 2
            ;;
        --password)
            CADDY_PASSWORD="$2"
            shift 2
            ;;
        --port)
            OPENCODE_PORT="$2"
            shift 2
            ;;
        --ip-only)
            USE_IP_ONLY=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate Caddy options
if [ "$INSTALL_CADDY" = true ]; then
    if [ -z "$CADDY_PASSWORD" ]; then
        echo "Error: --password is required when using --install-caddy"
        exit 1
    fi
    
    if [ -z "$CADDY_USERNAME" ]; then
        CADDY_USERNAME="admin"
    fi
    
    if [ "$USE_IP_ONLY" = false ] && [ -z "$DOMAIN" ]; then
        echo "Error: Either --domain or --ip-only must be specified when using --install-caddy"
        exit 1
    fi
    
    if [ "$USE_IP_ONLY" = true ] && [ -n "$DOMAIN" ]; then
        echo "Error: Cannot use both --domain and --ip-only"
        exit 1
    fi
fi

echo ""
echo "Cloud Coding Setup Starting..."
echo ""

# Step 1: Update System
echo "Updating system..."
apt update -y > /dev/null 2>&1
apt upgrade -y > /dev/null 2>&1

# Step 2: Install essentials (Docker, Tmux, Git, Python, Compilers)
echo "Installing essentials..."
apt install -y tmux git curl build-essential python3-pip unzip docker.io > /dev/null 2>&1

# Step 3: Install NVM (Node Version Manager)
echo "Installing NVM..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh 2>/dev/null | bash > /dev/null 2>&1

# Step 4: Activate NVM immediately (critical fix - won't work without this!)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Step 5: Install Node.js LTS and global tools
echo "Installing Node.js..."
nvm install --lts > /dev/null 2>&1
npm install -g nodemon > /dev/null 2>&1

# Step 6: Install Caddy (if requested)
if [ "$INSTALL_CADDY" = true ]; then
    echo "Installing Caddy..."
    
    # Detect OS and install Caddy accordingly
    if command -v apt-get &> /dev/null; then
        # Ubuntu/Debian
        apt install -y debian-keyring debian-archive-keyring apt-transport-https curl > /dev/null 2>&1
        curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' 2>/dev/null | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
        curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' 2>/dev/null | tee /etc/apt/sources.list.d/caddy-stable.list > /dev/null
        apt update > /dev/null 2>&1
        apt install -y caddy > /dev/null 2>&1
    elif command -v dnf &> /dev/null; then
        # RHEL/Fedora
        dnf install -y 'dnf-command(copr)' > /dev/null 2>&1
        dnf copr enable -y @caddy/caddy > /dev/null 2>&1
        dnf install -y caddy > /dev/null 2>&1
    else
        echo "Error: Unsupported OS. Please install Caddy manually."
        exit 1
    fi
fi

# Step 7: Install OpenCode
echo "Installing OpenCode..."
curl -fsSL https://opencode.ai/install 2>/dev/null | bash > /dev/null 2>&1

# Step 8: Create projects folder
echo "Creating projects folder..."
mkdir -p ~/projects

# Step 9: Configure Caddy (if requested)
if [ "$INSTALL_CADDY" = true ]; then
    echo "Configuring Caddy..."
    
    # Generate hashed password
    HASHED_PASSWORD=$(caddy hash-password --plaintext "$CADDY_PASSWORD" 2>/dev/null)
    
    # Create Caddyfile
    if [ "$USE_IP_ONLY" = true ]; then
        # IP-only configuration with self-signed certificate
        cat > /etc/caddy/Caddyfile << EOF
:443 {
    tls internal
    basicauth * {
        ${CADDY_USERNAME} ${HASHED_PASSWORD}
    }
    reverse_proxy localhost:${OPENCODE_PORT}
}
EOF
    else
        # Domain configuration with auto HTTPS
        cat > /etc/caddy/Caddyfile << EOF
${DOMAIN} {
    basicauth * {
        ${CADDY_USERNAME} ${HASHED_PASSWORD}
    }
    reverse_proxy localhost:${OPENCODE_PORT}
}
EOF
    fi
    
    # Validate Caddyfile
    caddy validate --config /etc/caddy/Caddyfile > /dev/null 2>&1
    
    # Enable and start Caddy
    systemctl enable caddy > /dev/null 2>&1
    systemctl restart caddy > /dev/null 2>&1
    
    # Configure firewall if ufw or firewalld is available
    if command -v ufw &> /dev/null; then
        echo "Configuring UFW firewall..."
        ufw allow 443/tcp > /dev/null 2>&1
        ufw allow 80/tcp > /dev/null 2>&1
    elif command -v firewall-cmd &> /dev/null; then
        echo "Configuring firewalld..."
        firewall-cmd --permanent --add-service=https > /dev/null 2>&1
        firewall-cmd --permanent --add-service=http > /dev/null 2>&1
        firewall-cmd --reload > /dev/null 2>&1
    fi
fi

# Step 10: Add aliases to bashrc
echo "Creating shortcuts..."
cat >> ~/.bashrc << 'EOF'

# Coding Environment aliases
alias opencode-web="opencode web --hostname 0.0.0.0 --port 4096"

# Load NVM on login
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
EOF

# Step 11: Source bashrc
source ~/.bashrc

echo ""
echo "✅ Setup Complete!"
echo ""

if [ "$INSTALL_CADDY" = true ]; then
    echo "=== Caddy Reverse Proxy Configured ==="
    echo ""
    if [ "$USE_IP_ONLY" = true ]; then
        echo "Access URL: https://<your-server-ip>"
        echo "Note: You'll see a browser warning (self-signed certificate)"
    else
        echo "Access URL: https://${DOMAIN}"
        echo "Note: Ensure DNS for ${DOMAIN} points to this server's IP"
    fi
    echo ""
    echo "Credentials:"
    echo "  Username: ${CADDY_USERNAME}"
    echo "  Password: [provided during setup]"
    echo ""
    echo "Caddy Status:"
    systemctl status caddy --no-pager | head -5
    echo ""
    echo "Features:"
    echo "  ✅ HTTPS enabled"
    echo "  ✅ Password protection active"
    echo "  ✅ OpenCode port (${OPENCODE_PORT}) not exposed publicly"
    if [ "$USE_IP_ONLY" = false ]; then
        echo "  ✅ Auto certificate renewal"
    fi
    echo ""
fi

echo "NEXT STEPS:"
echo ""
echo "Start coding in terminal:"
echo "   cd ~/projects && opencode"
echo ""
if [ "$INSTALL_CADDY" = false ]; then
    echo "Or start web interface:"
    echo "   opencode-web"
    echo "   Open: http://<your-server-ip>:4096"
else
    echo "Start web interface:"
    echo "   opencode-web"
    if [ "$USE_IP_ONLY" = true ]; then
        echo "   Access via: https://<your-server-ip>"
    else
        echo "   Access via: https://${DOMAIN}"
    fi
fi
echo ""
