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
USE_OAUTH2_PROXY=false
OAUTH2_GOOGLE_CLIENT_ID=""
OAUTH2_GOOGLE_CLIENT_SECRET=""
OAUTH2_COOKIE_SECRET=""
OAUTH2_ALLOWED_EMAIL_DOMAIN=""
OAUTH2_ALLOWED_EMAIL=""

# Paperclip configuration (runs on port 3100)
PAPERCLIP_DOMAIN=""
PAPERCLIP_PASSWORD=""
PAPERCLIP_USE_OAUTH2_PROXY=false
PAPERCLIP_OAUTH2_GOOGLE_CLIENT_ID=""
PAPERCLIP_OAUTH2_GOOGLE_CLIENT_SECRET=""
PAPERCLIP_OAUTH2_COOKIE_SECRET=""
PAPERCLIP_OAUTH2_ALLOWED_EMAIL_DOMAIN=""
PAPERCLIP_OAUTH2_ALLOWED_EMAIL=""

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --install-caddy          Install and configure Caddy reverse proxy"
    echo "  --domain DOMAIN          Domain name for Caddy (enables auto HTTPS)"
    echo "  --username USERNAME      Username for OpenCode web server (default: opencode)"
    echo "  --password PASSWORD      Password for OpenCode web server (required with --install-caddy, unless using --oauth2-proxy)"
    echo "  --port PORT             OpenCode port (default: 4096)"
    echo "  --ip-only               Configure Caddy for IP-only access with self-signed cert"
    echo "  --behind-proxy          Configure Caddy for HTTP-only when behind a CDN/reverse proxy (prevents redirect loops)"
    echo "  --oauth2-proxy          Enable oauth2-proxy with Google login for Caddy authentication"
    echo "  --google-client-id ID   Google OAuth2 client ID (required with --oauth2-proxy)"
    echo "  --google-client-secret S Google OAuth2 client secret (required with --oauth2-proxy)"
    echo "  --cookie-secret SECRET  Cookie secret for oauth2-proxy, 16/24/32 chars (required with --oauth2-proxy)"
    echo "  --allowed-email-domain D Restrict Google login to this email domain, e.g. yourcompany.com (default: * = any)"
    echo "  --allowed-email EMAIL   Restrict Google login to a specific email address"
    echo ""
    echo "Paperclip Options (for second service on port 3100):"
    echo "  --paperclip-domain DOMAIN       Domain name for Paperclip service"
    echo "  --paperclip-password PASSWORD   Password for Paperclip web server (required with --paperclip-domain, unless using --paperclip-oauth2-proxy)"
    echo "  --paperclip-oauth2-proxy        Enable oauth2-proxy with Google login for Paperclip"
    echo "  --paperclip-google-client-id ID Google OAuth2 client ID for Paperclip"
    echo "  --paperclip-google-client-secret S Google OAuth2 client secret for Paperclip"
    echo "  --paperclip-cookie-secret SECRET Cookie secret for Paperclip oauth2-proxy"
    echo "  --paperclip-allowed-email-domain D Email domain restriction for Paperclip"
    echo "  --paperclip-allowed-email EMAIL Specific email restriction for Paperclip"
    echo "  -h, --help              Display this help message"
    echo ""
    echo "Examples:"
    echo "  # Basic setup without Caddy"
    echo "  $0"
    echo ""
    echo "  # Setup with Caddy and domain (auto HTTPS)"
    echo "  $0 --install-caddy --domain your.domain.com --password 'SecurePass123!'"
    echo ""
    echo "  # Setup with Caddy and Google OAuth2 login via oauth2-proxy"
    echo "  $0 --install-caddy --domain your.domain.com --oauth2-proxy --google-client-id YOUR_ID --google-client-secret YOUR_SECRET --cookie-secret 'YOUR16BYTESECRET'"
    echo ""
    echo "  # Setup with Caddy behind a CDN or reverse proxy (HTTP-only, no redirect loop)"
    echo "  $0 --install-caddy --domain your.domain.com --behind-proxy --password 'SecurePass123!'"
    echo ""
    echo "  # Setup with Caddy for IP-only access"
    echo "  $0 --install-caddy --ip-only --password 'SecurePass123!'"
    echo ""
    echo "  # Setup with both OpenCode and Paperclip on separate domains"
    echo "  $0 --install-caddy --domain opencode.example.com --password 'Pass1' --paperclip-domain paperclip.example.com --paperclip-password 'Pass2'"
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
        --oauth2-proxy)
            USE_OAUTH2_PROXY=true
            shift
            ;;
        --google-client-id)
            OAUTH2_GOOGLE_CLIENT_ID="$2"
            shift 2
            ;;
        --google-client-secret)
            OAUTH2_GOOGLE_CLIENT_SECRET="$2"
            shift 2
            ;;
        --cookie-secret)
            OAUTH2_COOKIE_SECRET="$2"
            shift 2
            ;;
        --allowed-email-domain)
            OAUTH2_ALLOWED_EMAIL_DOMAIN="$2"
            shift 2
            ;;
        --allowed-email)
            OAUTH2_ALLOWED_EMAIL="$2"
            shift 2
            ;;
        --paperclip-domain)
            PAPERCLIP_DOMAIN="$2"
            shift 2
            ;;
        --paperclip-password)
            PAPERCLIP_PASSWORD="$2"
            shift 2
            ;;
        --paperclip-oauth2-proxy)
            PAPERCLIP_USE_OAUTH2_PROXY=true
            shift
            ;;
        --paperclip-google-client-id)
            PAPERCLIP_OAUTH2_GOOGLE_CLIENT_ID="$2"
            shift 2
            ;;
        --paperclip-google-client-secret)
            PAPERCLIP_OAUTH2_GOOGLE_CLIENT_SECRET="$2"
            shift 2
            ;;
        --paperclip-cookie-secret)
            PAPERCLIP_OAUTH2_COOKIE_SECRET="$2"
            shift 2
            ;;
        --paperclip-allowed-email-domain)
            PAPERCLIP_OAUTH2_ALLOWED_EMAIL_DOMAIN="$2"
            shift 2
            ;;
        --paperclip-allowed-email)
            PAPERCLIP_OAUTH2_ALLOWED_EMAIL="$2"
            shift 2
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
    if [ "$USE_OAUTH2_PROXY" = false ] && [ -z "$OPENCODE_PASSWORD" ]; then
        echo "Error: --password is required when using --install-caddy (unless using --oauth2-proxy)"
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

# Validate Paperclip options
if [ -n "$PAPERCLIP_DOMAIN" ]; then
    if [ "$INSTALL_CADDY" = false ]; then
        echo "Error: --paperclip-domain requires --install-caddy"
        exit 1
    fi

    if [ "$PAPERCLIP_USE_OAUTH2_PROXY" = false ] && [ -z "$PAPERCLIP_PASSWORD" ]; then
        echo "Error: --paperclip-password is required when using --paperclip-domain (unless using --paperclip-oauth2-proxy)"
        exit 1
    fi

    if [ "$USE_IP_ONLY" = true ]; then
        echo "Error: Cannot use --paperclip-domain with --ip-only"
        exit 1
    fi
fi

# Validate Paperclip oauth2-proxy options
if [ "$PAPERCLIP_USE_OAUTH2_PROXY" = true ]; then
    if [ -z "$PAPERCLIP_DOMAIN" ]; then
        echo "Error: --paperclip-oauth2-proxy requires --paperclip-domain"
        exit 1
    fi
    if [ -z "$PAPERCLIP_OAUTH2_GOOGLE_CLIENT_ID" ]; then
        echo "Error: --paperclip-google-client-id is required when using --paperclip-oauth2-proxy"
        exit 1
    fi
    if [ -z "$PAPERCLIP_OAUTH2_GOOGLE_CLIENT_SECRET" ]; then
        echo "Error: --paperclip-google-client-secret is required when using --paperclip-oauth2-proxy"
        exit 1
    fi
    if [ -z "$PAPERCLIP_OAUTH2_COOKIE_SECRET" ]; then
        echo "Error: --paperclip-cookie-secret is required when using --paperclip-oauth2-proxy (must be 16, 24, or 32 characters)"
        exit 1
    fi
    PAPERCLIP_COOKIE_SECRET_LEN=${#PAPERCLIP_OAUTH2_COOKIE_SECRET}
    if [ "$PAPERCLIP_COOKIE_SECRET_LEN" -ne 16 ] && [ "$PAPERCLIP_COOKIE_SECRET_LEN" -ne 24 ] && [ "$PAPERCLIP_COOKIE_SECRET_LEN" -ne 32 ]; then
        echo "Error: --paperclip-cookie-secret must be exactly 16, 24, or 32 characters (got ${PAPERCLIP_COOKIE_SECRET_LEN})"
        exit 1
    fi
fi

# Validate oauth2-proxy options
if [ "$USE_OAUTH2_PROXY" = true ]; then
    if [ "$INSTALL_CADDY" = false ]; then
        echo "Error: --oauth2-proxy requires --install-caddy"
        exit 1
    fi
    if [ "$USE_IP_ONLY" = true ]; then
        echo "Error: --oauth2-proxy cannot be combined with --ip-only."
        echo "Google OAuth2 requires a domain (registered redirect URI) — raw IP addresses are not supported."
        echo "Use --domain with a valid domain name, or use --password for IP-only access."
        exit 1
    fi
    if [ -z "$OAUTH2_GOOGLE_CLIENT_ID" ]; then
        echo "Error: --google-client-id is required when using --oauth2-proxy"
        exit 1
    fi
    if [ -z "$OAUTH2_GOOGLE_CLIENT_SECRET" ]; then
        echo "Error: --google-client-secret is required when using --oauth2-proxy"
        exit 1
    fi
    if [ -z "$OAUTH2_COOKIE_SECRET" ]; then
        echo "Error: --cookie-secret is required when using --oauth2-proxy (must be 16, 24, or 32 characters)"
        exit 1
    fi
    COOKIE_SECRET_LEN=${#OAUTH2_COOKIE_SECRET}
    if [ "$COOKIE_SECRET_LEN" -ne 16 ] && [ "$COOKIE_SECRET_LEN" -ne 24 ] && [ "$COOKIE_SECRET_LEN" -ne 32 ]; then
        echo "Error: --cookie-secret must be exactly 16, 24, or 32 characters (got ${COOKIE_SECRET_LEN})"
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

# Install GO
echo "Installing Go..."
GO_ARCH="amd64"
case "$(uname -m)" in
    aarch64|arm64) GO_ARCH="arm64" ;;
esac
echo "Detected architecture: $GO_ARCH"
echo "Downloading Go 1.26.1..."
echo "URL: https://go.dev/dl/go1.26.1.linux-${GO_ARCH}.tar.gz"
curl -LO "https://go.dev/dl/go1.26.1.linux-${GO_ARCH}.tar.gz"
rm -rf /usr/local/go && tar -C /usr/local -xzf "go1.26.1.linux-${GO_ARCH}.tar.gz"
rm "go1.26.1.linux-${GO_ARCH}.tar.gz"
export PATH=$PATH:/usr/local/go/bin
echo "Verifying Go installation..."
/usr/local/go/bin/go version

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

# Step 6a: Install oauth2-proxy (if requested for either service)
if [ "$USE_OAUTH2_PROXY" = true ] || [ "$PAPERCLIP_USE_OAUTH2_PROXY" = true ]; then
    echo "Installing oauth2-proxy..."
    OAUTH2_PROXY_ARCH="amd64"
    case "$(uname -m)" in
        aarch64|arm64) OAUTH2_PROXY_ARCH="arm64" ;;
    esac
    OAUTH2_PROXY_VERSION=$(curl -s https://api.github.com/repos/oauth2-proxy/oauth2-proxy/releases/latest 2>/dev/null | grep '"tag_name"' | cut -d'"' -f4 | sed 's/^v//')
    OAUTH2_PROXY_VERSION="${OAUTH2_PROXY_VERSION:-7.8.1}"
    OAUTH2_PROXY_TGZ="/tmp/oauth2-proxy-v${OAUTH2_PROXY_VERSION}.linux-${OAUTH2_PROXY_ARCH}.tar.gz"
    OAUTH2_PROXY_URL="https://github.com/oauth2-proxy/oauth2-proxy/releases/download/v${OAUTH2_PROXY_VERSION}/oauth2-proxy-v${OAUTH2_PROXY_VERSION}.linux-${OAUTH2_PROXY_ARCH}.tar.gz"
    if ! curl -fsSL "$OAUTH2_PROXY_URL" -o "$OAUTH2_PROXY_TGZ" 2>/dev/null; then
        echo "Error: Failed to download oauth2-proxy from ${OAUTH2_PROXY_URL}. Please check your internet connection."
        exit 1
    fi
    if ! tar -xz -C /tmp -f "$OAUTH2_PROXY_TGZ" > /dev/null 2>&1; then
        echo "Error: Failed to extract oauth2-proxy archive. The download may be corrupt."
        rm -f "$OAUTH2_PROXY_TGZ"
        exit 1
    fi
    rm -f "$OAUTH2_PROXY_TGZ"
    if ! mv "/tmp/oauth2-proxy-v${OAUTH2_PROXY_VERSION}.linux-${OAUTH2_PROXY_ARCH}/oauth2-proxy" /usr/local/bin/oauth2-proxy; then
        echo "Error: Failed to install oauth2-proxy binary."
        exit 1
    fi
    chmod +x /usr/local/bin/oauth2-proxy
    rm -rf "/tmp/oauth2-proxy-v${OAUTH2_PROXY_VERSION}.linux-${OAUTH2_PROXY_ARCH}"
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
    if [ "$USE_OAUTH2_PROXY" = true ] && [ "$BEHIND_PROXY" = true ]; then
        # HTTP-only with oauth2-proxy, behind a CDN or reverse proxy that handles TLS.
        # See non-oauth2-proxy block below for a full explanation of auto_https off and
        # X-Forwarded-Proto hardcoding.  The redir target uses https:// explicitly because
        # {scheme} would be "http" (Caddy sees plain HTTP from the CDN).
        cat > /etc/caddy/Caddyfile << EOF
{
    auto_https off
}

http://${DOMAIN} {
    handle /oauth2/* {
        reverse_proxy localhost:4180 {
            header_up X-Forwarded-Proto https
        }
    }
    handle {
        forward_auth localhost:4180 {
            uri /oauth2/auth
            copy_headers X-Auth-Request-User X-Auth-Request-Email
            @oauth2_401 status 401
            handle_response @oauth2_401 {
                redir * /oauth2/sign_in?rd=https://{host}{uri}
            }
        }
        reverse_proxy localhost:${OPENCODE_PORT} {
            header_up Host {upstream_hostport}
            header_up X-Forwarded-Proto https
            flush_interval -1
        }
    }
}
EOF

        # Add Paperclip configuration if domain is specified
        if [ -n "$PAPERCLIP_DOMAIN" ]; then
            if [ "$PAPERCLIP_USE_OAUTH2_PROXY" = true ]; then
                cat >> /etc/caddy/Caddyfile << EOF

http://${PAPERCLIP_DOMAIN} {
    handle /oauth2/* {
        reverse_proxy localhost:4181 {
            header_up X-Forwarded-Proto https
        }
    }
    handle {
        forward_auth localhost:4181 {
            uri /oauth2/auth
            copy_headers X-Auth-Request-User X-Auth-Request-Email
            @oauth2_401 status 401
            handle_response @oauth2_401 {
                redir * /oauth2/sign_in?rd=https://{host}{uri}
            }
        }
        reverse_proxy localhost:3100 {
            header_up Host {upstream_hostport}
            header_up X-Forwarded-Proto https
            flush_interval -1
        }
    }
}
EOF
            else
                cat >> /etc/caddy/Caddyfile << EOF

http://${PAPERCLIP_DOMAIN} {
    reverse_proxy localhost:3100 {
        header_up Host {upstream_hostport}
        header_up X-Forwarded-Proto https
        flush_interval -1
    }
}
EOF
            fi
        fi
    elif [ "$USE_OAUTH2_PROXY" = true ]; then
        # Domain with auto HTTPS and oauth2-proxy
        cat > /etc/caddy/Caddyfile << EOF
${DOMAIN} {
    handle /oauth2/* {
        reverse_proxy localhost:4180
    }
    handle {
        forward_auth localhost:4180 {
            uri /oauth2/auth
            copy_headers X-Auth-Request-User X-Auth-Request-Email
            @oauth2_401 status 401
            handle_response @oauth2_401 {
                redir * /oauth2/sign_in?rd={scheme}://{host}{uri}
            }
        }
        reverse_proxy localhost:${OPENCODE_PORT} {
            header_up Host {upstream_hostport}
            header_up X-Forwarded-Proto {scheme}
            flush_interval -1
        }
    }
}
EOF

        # Add Paperclip configuration if domain is specified
        if [ -n "$PAPERCLIP_DOMAIN" ]; then
            if [ "$PAPERCLIP_USE_OAUTH2_PROXY" = true ]; then
                cat >> /etc/caddy/Caddyfile << EOF

${PAPERCLIP_DOMAIN} {
    handle /oauth2/* {
        reverse_proxy localhost:4181
    }
    handle {
        forward_auth localhost:4181 {
            uri /oauth2/auth
            copy_headers X-Auth-Request-User X-Auth-Request-Email
            @oauth2_401 status 401
            handle_response @oauth2_401 {
                redir * /oauth2/sign_in?rd={scheme}://{host}{uri}
            }
        }
        reverse_proxy localhost:3100 {
            header_up Host {upstream_hostport}
            header_up X-Forwarded-Proto {scheme}
            flush_interval -1
        }
    }
}
EOF
            else
                cat >> /etc/caddy/Caddyfile << EOF

${PAPERCLIP_DOMAIN} {
    reverse_proxy localhost:3100 {
        header_up Host {upstream_hostport}
        header_up X-Forwarded-Proto {scheme}
        flush_interval -1
    }
}
EOF
            fi
        fi
    elif [ "$USE_IP_ONLY" = true ]; then
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

        # Add Paperclip configuration if domain is specified
        if [ -n "$PAPERCLIP_DOMAIN" ]; then
            cat >> /etc/caddy/Caddyfile << EOF

http://${PAPERCLIP_DOMAIN} {
    reverse_proxy localhost:3100 {
        header_up Host {upstream_hostport}
        header_up X-Forwarded-Proto https
        flush_interval -1
    }
}
EOF
        fi
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

        # Add Paperclip configuration if domain is specified
        if [ -n "$PAPERCLIP_DOMAIN" ]; then
            cat >> /etc/caddy/Caddyfile << EOF

${PAPERCLIP_DOMAIN} {
    reverse_proxy localhost:3100 {
        header_up Host {upstream_hostport}
        header_up X-Forwarded-Proto {scheme}
        flush_interval -1
    }
}
EOF
        fi
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

# Step 9a: Configure oauth2-proxy (if requested)
if [ "$USE_OAUTH2_PROXY" = true ] || [ "$PAPERCLIP_USE_OAUTH2_PROXY" = true ]; then
    mkdir -p /etc/oauth2-proxy
fi

if [ "$USE_OAUTH2_PROXY" = true ]; then
    echo "Configuring oauth2-proxy for OpenCode..."

    # Determine the redirect URL (IP-only is blocked at validation; only domain modes reach here)
    OAUTH2_REDIRECT_URL="https://${DOMAIN}/oauth2/callback"

    # Build the email restriction config lines
    if [ -n "$OAUTH2_ALLOWED_EMAIL" ]; then
        # Restrict to a specific email address via an authenticated emails file
        printf '%s\n' "$OAUTH2_ALLOWED_EMAIL" > /etc/oauth2-proxy/authenticated-emails-opencode.txt
        chmod 600 /etc/oauth2-proxy/authenticated-emails-opencode.txt
        EMAIL_CONFIG="authenticated_emails_file = \"/etc/oauth2-proxy/authenticated-emails-opencode.txt\""
    elif [ -n "$OAUTH2_ALLOWED_EMAIL_DOMAIN" ]; then
        EMAIL_CONFIG="email_domains = [ \"${OAUTH2_ALLOWED_EMAIL_DOMAIN}\" ]"
    else
        EMAIL_CONFIG="email_domains = [ \"*\" ]"
    fi

    # Write the config file (credentials stored with chmod 600)
    cat > /etc/oauth2-proxy/oauth2-proxy-opencode.cfg << EOF
provider = "google"
client_id = "${OAUTH2_GOOGLE_CLIENT_ID}"
client_secret = "${OAUTH2_GOOGLE_CLIENT_SECRET}"
redirect_url = "${OAUTH2_REDIRECT_URL}"
cookie_secret = "${OAUTH2_COOKIE_SECRET}"
${EMAIL_CONFIG}
http_address = "127.0.0.1:4180"
reverse_proxy = true
skip_provider_button = true
EOF
    chmod 600 /etc/oauth2-proxy/oauth2-proxy-opencode.cfg

    # Create systemd service for oauth2-proxy
    cat > /etc/systemd/system/oauth2-proxy.service << 'SERVICE_EOF'
[Unit]
Description=oauth2-proxy for OpenCode
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/oauth2-proxy --config=/etc/oauth2-proxy/oauth2-proxy-opencode.cfg
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
SERVICE_EOF

    systemctl daemon-reload > /dev/null 2>&1
    if ! systemctl enable oauth2-proxy > /dev/null 2>&1; then
        echo "Warning: Failed to enable oauth2-proxy service for automatic startup on boot."
    fi
    if ! systemctl restart oauth2-proxy > /dev/null 2>&1; then
        echo "Error: Failed to start oauth2-proxy. Check logs with: sudo journalctl -u oauth2-proxy -n 50"
        exit 1
    fi
fi

if [ "$PAPERCLIP_USE_OAUTH2_PROXY" = true ]; then
    echo "Configuring oauth2-proxy for Paperclip..."

    # Determine the redirect URL
    PAPERCLIP_OAUTH2_REDIRECT_URL="https://${PAPERCLIP_DOMAIN}/oauth2/callback"

    # Build the email restriction config lines
    if [ -n "$PAPERCLIP_OAUTH2_ALLOWED_EMAIL" ]; then
        # Restrict to a specific email address via an authenticated emails file
        printf '%s\n' "$PAPERCLIP_OAUTH2_ALLOWED_EMAIL" > /etc/oauth2-proxy/authenticated-emails-paperclip.txt
        chmod 600 /etc/oauth2-proxy/authenticated-emails-paperclip.txt
        PAPERCLIP_EMAIL_CONFIG="authenticated_emails_file = \"/etc/oauth2-proxy/authenticated-emails-paperclip.txt\""
    elif [ -n "$PAPERCLIP_OAUTH2_ALLOWED_EMAIL_DOMAIN" ]; then
        PAPERCLIP_EMAIL_CONFIG="email_domains = [ \"${PAPERCLIP_OAUTH2_ALLOWED_EMAIL_DOMAIN}\" ]"
    else
        PAPERCLIP_EMAIL_CONFIG="email_domains = [ \"*\" ]"
    fi

    # Write the config file (credentials stored with chmod 600)
    cat > /etc/oauth2-proxy/oauth2-proxy-paperclip.cfg << EOF
provider = "google"
client_id = "${PAPERCLIP_OAUTH2_GOOGLE_CLIENT_ID}"
client_secret = "${PAPERCLIP_OAUTH2_GOOGLE_CLIENT_SECRET}"
redirect_url = "${PAPERCLIP_OAUTH2_REDIRECT_URL}"
cookie_secret = "${PAPERCLIP_OAUTH2_COOKIE_SECRET}"
${PAPERCLIP_EMAIL_CONFIG}
http_address = "127.0.0.1:4181"
reverse_proxy = true
skip_provider_button = true
EOF
    chmod 600 /etc/oauth2-proxy/oauth2-proxy-paperclip.cfg

    # Create systemd service for paperclip oauth2-proxy
    cat > /etc/systemd/system/oauth2-proxy-paperclip.service << 'SERVICE_EOF'
[Unit]
Description=oauth2-proxy for Paperclip
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/oauth2-proxy --config=/etc/oauth2-proxy/oauth2-proxy-paperclip.cfg
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
SERVICE_EOF

    systemctl daemon-reload > /dev/null 2>&1
    if ! systemctl enable oauth2-proxy-paperclip > /dev/null 2>&1; then
        echo "Warning: Failed to enable oauth2-proxy-paperclip service for automatic startup on boot."
    fi
    if ! systemctl restart oauth2-proxy-paperclip > /dev/null 2>&1; then
        echo "Error: Failed to start oauth2-proxy-paperclip. Check logs with: sudo journalctl -u oauth2-proxy-paperclip -n 50"
        exit 1
    fi
fi

# Step 10: Add aliases to bashrc
echo "Creating shortcuts..."

# Export OpenCode auth env vars to a secure file if provided
if [ -n "$OPENCODE_PASSWORD" ] || [ -n "$PAPERCLIP_PASSWORD" ]; then
    touch ~/.opencode_env
    chmod 600 ~/.opencode_env

    if [ -n "$OPENCODE_PASSWORD" ]; then
        printf 'export OPENCODE_SERVER_PASSWORD=%q\n' "$OPENCODE_PASSWORD" > ~/.opencode_env
        if [ -n "$OPENCODE_USERNAME" ]; then
            printf 'export OPENCODE_SERVER_USERNAME=%q\n' "$OPENCODE_USERNAME" >> ~/.opencode_env
        fi
    fi

    if [ -n "$PAPERCLIP_PASSWORD" ]; then
        printf 'export PAPERCLIP_SERVER_PASSWORD=%q\n' "$PAPERCLIP_PASSWORD" >> ~/.opencode_env
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

    # OpenCode configuration
    echo "OpenCode:"
    if [ "$USE_IP_ONLY" = true ]; then
        echo "  Access URL: https://<your-server-ip>"
        echo "  Note: You'll see a browser warning (self-signed certificate)"
    elif [ "$BEHIND_PROXY" = true ]; then
        echo "  Access URL: https://${DOMAIN} (via your CDN/proxy)"
        echo "  Note: Caddy is configured for HTTP-only; your CDN/proxy handles TLS"
        echo "  Note: Ensure your CDN/proxy forwards requests to this server on port 80"
    else
        echo "  Access URL: https://${DOMAIN}"
        echo "  Note: Ensure DNS for ${DOMAIN} points to this server's IP"
    fi

    if [ "$USE_OAUTH2_PROXY" = true ]; then
        echo "  Authentication: Google OAuth2 via oauth2-proxy"
    else
        echo "  Authentication: Password (username: ${OPENCODE_USERNAME:-opencode})"
    fi
    echo ""

    # Paperclip configuration
    if [ -n "$PAPERCLIP_DOMAIN" ]; then
        echo "Paperclip:"
        if [ "$BEHIND_PROXY" = true ]; then
            echo "  Access URL: https://${PAPERCLIP_DOMAIN} (via your CDN/proxy)"
        else
            echo "  Access URL: https://${PAPERCLIP_DOMAIN}"
            echo "  Note: Ensure DNS for ${PAPERCLIP_DOMAIN} points to this server's IP"
        fi

        if [ "$PAPERCLIP_USE_OAUTH2_PROXY" = true ]; then
            echo "  Authentication: Google OAuth2 via oauth2-proxy"
        else
            echo "  Authentication: Password"
        fi
        echo ""
    fi

    echo "Caddy Status:"
    systemctl status caddy --no-pager | head -5
    echo ""

    if [ "$USE_OAUTH2_PROXY" = true ]; then
        echo "oauth2-proxy (OpenCode) Status:"
        systemctl status oauth2-proxy --no-pager | head -5
        echo ""
    fi

    if [ "$PAPERCLIP_USE_OAUTH2_PROXY" = true ]; then
        echo "oauth2-proxy (Paperclip) Status:"
        systemctl status oauth2-proxy-paperclip --no-pager | head -5
        echo ""
    fi

    echo "Features:"
    echo "  ✅ HTTPS enabled"
    if [ "$USE_OAUTH2_PROXY" = true ] || [ "$PAPERCLIP_USE_OAUTH2_PROXY" = true ]; then
        echo "  ✅ Google OAuth2 login via oauth2-proxy"
    fi
    echo "  ✅ OpenCode port (${OPENCODE_PORT}) not exposed publicly"
    if [ -n "$PAPERCLIP_DOMAIN" ]; then
        echo "  ✅ Paperclip port (3100) not exposed publicly"
    fi
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
    echo "Start OpenCode web interface:"
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

if [ -n "$PAPERCLIP_DOMAIN" ]; then
    echo "Access Paperclip:"
    if [ "$BEHIND_PROXY" = true ]; then
        echo "   https://${PAPERCLIP_DOMAIN} (via your CDN/proxy)"
    else
        echo "   https://${PAPERCLIP_DOMAIN}"
    fi
    echo "   Note: Ensure Paperclip service is running on port 3100"
    echo ""
fi
