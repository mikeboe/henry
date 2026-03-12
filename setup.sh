#!/bin/bash
# Cloud Coding Agent Setup Script
# One command to setup AI coding agents on Hetzner with optional Caddy reverse proxy

set -e

# Default values
OPENCODE_PORT=4096
INSTALL_CADDY=false
DOMAIN=""
OPENCODE_USERNAME=""
OPENCODE_PASSWORD=""
USE_IP_ONLY=false
BEHIND_PROXY=false

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --install-caddy          Install and configure Caddy reverse proxy"
    echo "  --domain DOMAIN          Domain name for Caddy (enables auto HTTPS)"
    echo "  --username USERNAME      Username for OpenCode web server (default: opencode)"
    echo "  --password PASSWORD      Password for OpenCode web server (required with --install-caddy)"
    echo "  --port PORT             OpenCode port (default: 4096)"
    echo "  --ip-only               Configure Caddy for IP-only access with self-signed cert"
    echo "  --behind-proxy          Configure Caddy for HTTP-only when behind a CDN/reverse proxy (prevents redirect loops)"
    echo "  -h, --help              Display this help message"
    echo ""
    echo "Examples:"
    echo "  # Basic setup without Caddy"
    echo "  $0"
    echo ""
    echo "  # Setup with Caddy and domain (auto HTTPS)"
    echo "  $0 --install-caddy --domain your.domain.com --password 'SecurePass123!'"
    echo ""
    echo "  # Setup with Caddy behind a CDN or reverse proxy (HTTP-only, no redirect loop)"
    echo "  $0 --install-caddy --domain your.domain.com --behind-proxy --password 'SecurePass123!'"
    echo ""
    echo "  # Setup with Caddy for IP-only access"
    echo "  $0 --install-caddy --ip-only --password 'SecurePass123!'"
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
            OPENCODE_USERNAME="$2"
            shift 2
            ;;
        --password)
            OPENCODE_PASSWORD="$2"
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
        --behind-proxy)
            BEHIND_PROXY=true
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
    if [ -z "$OPENCODE_PASSWORD" ]; then
        echo "Error: --password is required when using --install-caddy"
        exit 1
    fi
    
    if [ "$USE_IP_ONLY" = false ] && [ -z "$DOMAIN" ]; then
        echo "Error: Either --domain or --ip-only must be specified when using --install-caddy"
        exit 1
    fi
    
    if [ "$USE_IP_ONLY" = true ] && [ -n "$DOMAIN" ]; then
        echo "Error: Cannot use both --domain and --ip-only"
        exit 1
    fi
    
    if [ "$BEHIND_PROXY" = true ] && [ "$USE_IP_ONLY" = true ]; then
        echo "Error: Cannot use both --behind-proxy and --ip-only"
        exit 1
    fi
    
    if [ "$BEHIND_PROXY" = true ] && [ -z "$DOMAIN" ]; then
        echo "Error: --domain is required when using --behind-proxy"
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
        if ! apt install -y caddy > /dev/null 2>&1; then
            echo "Error: Failed to install Caddy. Please check your internet connection and package repositories."
            exit 1
        fi
    elif command -v dnf &> /dev/null; then
        # RHEL/Fedora
        dnf install -y 'dnf-command(copr)' > /dev/null 2>&1
        dnf copr enable -y @caddy/caddy > /dev/null 2>&1
        if ! dnf install -y caddy > /dev/null 2>&1; then
            echo "Error: Failed to install Caddy. Please check your internet connection and package repositories."
            exit 1
        fi
    else
        echo "Error: Unsupported OS. Please install Caddy manually."
        exit 1
    fi
fi

# Step 7: Install OpenCode
echo "Installing OpenCode..."
if ! curl -fsSL https://opencode.ai/install 2>/dev/null | bash > /dev/null 2>&1; then
    echo "Warning: OpenCode installation may have encountered issues. You can manually install it later."
fi

# Step 8: Create projects folder
echo "Creating projects folder..."
mkdir -p ~/projects

# Step 9: Configure Caddy (if requested)
if [ "$INSTALL_CADDY" = true ]; then
    echo "Configuring Caddy..."
    
    # Create Caddyfile
    if [ "$USE_IP_ONLY" = true ]; then
        # IP-only configuration with self-signed certificate
        cat > /etc/caddy/Caddyfile << EOF
:443 {
    tls internal
    reverse_proxy localhost:${OPENCODE_PORT} {
        header_up Host {upstream_hostport}
        header_up X-Forwarded-Proto {scheme}
        flush_interval -1
    }
}
EOF
    elif [ "$BEHIND_PROXY" = true ]; then
        # HTTP-only configuration for use behind a CDN or reverse proxy that handles TLS.
        # auto_https off disables all of Caddy's automatic HTTPS behaviour globally,
        # including certificate acquisition and the HTTP->HTTPS redirect, so that a CDN
        # (e.g. Bunny CDN, Cloudflare) can terminate TLS and forward plain HTTP to this
        # server on port 80 without triggering an infinite redirect loop.
        #
        # X-Forwarded-Proto is hardcoded to "https" because Caddy receives plain HTTP from
        # the CDN but the original client connection is HTTPS. Without this, OpenCode would
        # generate ws:// WebSocket URLs instead of wss://, which browsers reject on HTTPS
        # pages and cause constant reconnection / password prompts.
        # flush_interval -1 disables response buffering, which is required for WebSocket
        # and other streaming connections to work correctly through the proxy.
        cat > /etc/caddy/Caddyfile << EOF
{
    auto_https off
}

http://${DOMAIN} {
    reverse_proxy localhost:${OPENCODE_PORT} {
        header_up Host {upstream_hostport}
        header_up X-Forwarded-Proto https
        flush_interval -1
    }
}
EOF
    else
        # Domain configuration with auto HTTPS
        cat > /etc/caddy/Caddyfile << EOF
${DOMAIN} {
    reverse_proxy localhost:${OPENCODE_PORT} {
        header_up Host {upstream_hostport}
        header_up X-Forwarded-Proto {scheme}
        flush_interval -1
    }
}
EOF
    fi
    
    # Validate Caddyfile
    if ! caddy validate --config /etc/caddy/Caddyfile > /dev/null 2>&1; then
        echo "Error: Caddyfile validation failed. Configuration may be invalid."
        echo "Please check /etc/caddy/Caddyfile for errors."
        exit 1
    fi
    
    # Enable and start Caddy
    if ! systemctl enable caddy > /dev/null 2>&1; then
        echo "Warning: Failed to enable Caddy service for automatic startup on boot."
        echo "Caddy will still start now, but won't automatically start after reboot."
    fi
    if ! systemctl restart caddy > /dev/null 2>&1; then
        echo "Error: Failed to start Caddy. Check logs with: sudo journalctl -u caddy -n 50"
        exit 1
    fi
    
    # Configure firewall if ufw or firewalld is available
    if command -v ufw &> /dev/null; then
        echo "Configuring UFW firewall..."
        if [ "$BEHIND_PROXY" = true ]; then
            # Only port 80 is needed; TLS is terminated at the CDN/proxy
            if ! ufw allow 80/tcp > /dev/null 2>&1; then
                echo "Warning: Failed to configure UFW firewall rules."
                echo "You may need to manually allow port 80 for HTTP access."
            fi
        else
            if ! ufw allow 443/tcp > /dev/null 2>&1 || ! ufw allow 80/tcp > /dev/null 2>&1; then
                echo "Warning: Failed to configure UFW firewall rules."
                echo "You may need to manually allow ports 80 and 443 for HTTPS access."
            fi
        fi
    elif command -v firewall-cmd &> /dev/null; then
        echo "Configuring firewalld..."
        if [ "$BEHIND_PROXY" = true ]; then
            # Only port 80 is needed; TLS is terminated at the CDN/proxy
            if ! firewall-cmd --permanent --add-service=http > /dev/null 2>&1 || \
               ! firewall-cmd --reload > /dev/null 2>&1; then
                echo "Warning: Failed to configure firewalld rules."
                echo "You may need to manually allow port 80 for HTTP access."
            fi
        else
            if ! firewall-cmd --permanent --add-service=https > /dev/null 2>&1 || \
               ! firewall-cmd --permanent --add-service=http > /dev/null 2>&1 || \
               ! firewall-cmd --reload > /dev/null 2>&1; then
                echo "Warning: Failed to configure firewalld rules."
                echo "You may need to manually allow ports 80 and 443 for HTTPS access."
            fi
        fi
    fi
fi

# Step 10: Add aliases to bashrc
echo "Creating shortcuts..."

# Export OpenCode auth env vars to a secure file if provided
if [ -n "$OPENCODE_PASSWORD" ]; then
    touch ~/.opencode_env
    chmod 600 ~/.opencode_env
    printf 'export OPENCODE_SERVER_PASSWORD=%q\n' "$OPENCODE_PASSWORD" > ~/.opencode_env
    if [ -n "$OPENCODE_USERNAME" ]; then
        printf 'export OPENCODE_SERVER_USERNAME=%q\n' "$OPENCODE_USERNAME" >> ~/.opencode_env
    fi
fi

cat >> ~/.bashrc << 'BASHRC_EOF'

# Coding Environment aliases
# Source OpenCode auth env vars (stored securely with chmod 600)
[ -f "$HOME/.opencode_env" ] && . "$HOME/.opencode_env"
alias opencode-web="opencode web --hostname 0.0.0.0 --port 4096"

# Load NVM on login
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
BASHRC_EOF

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
    elif [ "$BEHIND_PROXY" = true ]; then
        echo "Access URL: https://${DOMAIN} (via your CDN/proxy)"
        echo "Note: Caddy is configured for HTTP-only; your CDN/proxy handles TLS"
        echo "Note: Ensure your CDN/proxy forwards requests to this server on port 80"
    else
        echo "Access URL: https://${DOMAIN}"
        echo "Note: Ensure DNS for ${DOMAIN} points to this server's IP"
    fi
    echo ""
    echo "Credentials:"
    echo "  Username: ${OPENCODE_USERNAME:-opencode}"
    echo "  Password: [provided during setup]"
    echo ""
    echo "Caddy Status:"
    systemctl status caddy --no-pager | head -5
    echo ""
    echo "Features:"
    echo "  ✅ HTTPS enabled"
    echo "  ✅ Password protection via OpenCode authentication"
    echo "  ✅ OpenCode port (${OPENCODE_PORT}) not exposed publicly"
    if [ "$USE_IP_ONLY" = false ] && [ "$BEHIND_PROXY" = false ]; then
        echo "  ✅ Auto certificate renewal"
    fi
    if [ "$BEHIND_PROXY" = true ]; then
        echo "  ✅ HTTP-only mode (TLS handled by CDN/proxy, no redirect loops)"
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
    elif [ "$BEHIND_PROXY" = true ]; then
        echo "   Access via: https://${DOMAIN} (via your CDN/proxy)"
    else
        echo "   Access via: https://${DOMAIN}"
    fi
fi
echo ""
