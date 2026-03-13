# Cloud Coding Agent Setup Script

One command to setup AI coding agents on cloud servers (Hetzner, AWS, etc.) with optional Caddy reverse proxy for secure HTTPS access.

## Features

- ✅ Automated setup of development environment (Docker, Git, Node.js, Python, etc.)
- ✅ OpenCode installation for AI-powered coding
- ✅ Optional Caddy reverse proxy with auto HTTPS
- ✅ Password-protected access via OpenCode authentication
- ✅ Google OAuth2 login via oauth2-proxy (optional, replaces password auth)
- ✅ Support for both domain-based and IP-only configurations
- ✅ Automatic firewall configuration
- ✅ Zero-downtime certificate renewal

## Quick Start

### Basic Setup (No Reverse Proxy)

**Recommended: Download and review first**
```bash
curl -fsSL https://raw.githubusercontent.com/mikeboe/henry/main/setup.sh -o setup.sh
less setup.sh  # Review the script
sudo bash setup.sh
```

**One-line install (executes immediately)**
```bash
curl -fsSL https://raw.githubusercontent.com/mikeboe/henry/main/setup.sh | sudo bash
```

### Setup with Caddy and Domain (Auto HTTPS)

**Recommended: Download and review first**
```bash
curl -fsSL https://raw.githubusercontent.com/mikeboe/henry/main/setup.sh -o setup.sh
less setup.sh  # Review the script
sudo bash setup.sh \
  --install-caddy \
  --domain your.domain.com \
  --password 'YourStrongPassword123!'
```

**One-line install (executes immediately)**
```bash
curl -fsSL https://raw.githubusercontent.com/mikeboe/henry/main/setup.sh | sudo bash -s -- \
  --install-caddy \
  --domain your.domain.com \
  --password 'YourStrongPassword123!'
```

### Setup with Caddy for IP-Only Access

**Recommended: Download and review first**
```bash
curl -fsSL https://raw.githubusercontent.com/mikeboe/henry/main/setup.sh -o setup.sh
less setup.sh  # Review the script
sudo bash setup.sh \
  --install-caddy \
  --ip-only \
  --password 'YourStrongPassword123!'
```

**One-line install (executes immediately)**
```bash
curl -fsSL https://raw.githubusercontent.com/mikeboe/henry/main/setup.sh | sudo bash -s -- \
  --install-caddy \
  --ip-only \
  --password 'YourStrongPassword123!'
```

### Setup with Caddy Behind a CDN or Reverse Proxy

Use this when a CDN (e.g., BunnyCDN, Cloudflare) or another reverse proxy sits in front of Caddy and handles TLS termination. Without this flag, Caddy's automatic HTTP→HTTPS redirect will create an infinite redirect loop because the CDN terminates HTTPS but proxies requests to the origin over HTTP.

**Recommended: Download and review first**
```bash
curl -fsSL https://raw.githubusercontent.com/mikeboe/henry/main/setup.sh -o setup.sh
less setup.sh  # Review the script
sudo bash setup.sh \
  --install-caddy \
  --domain your.domain.com \
  --behind-proxy \
  --password 'YourStrongPassword123!'
```

**One-line install (executes immediately)**
```bash
curl -fsSL https://raw.githubusercontent.com/mikeboe/henry/main/setup.sh | sudo bash -s -- \
  --install-caddy \
  --domain your.domain.com \
  --behind-proxy \
  --password 'YourStrongPassword123!'
```

### Setup with Caddy and Google OAuth2 Login

Protect OpenCode with Google login using [oauth2-proxy](https://oauth2-proxy.github.io/oauth2-proxy/). Users are redirected to Google sign-in before accessing OpenCode. **You must [create Google OAuth2 credentials](#google-cloud-console-setup) first.**

**Recommended: Download and review first**
```bash
curl -fsSL https://raw.githubusercontent.com/mikeboe/henry/main/setup.sh -o setup.sh
less setup.sh  # Review the script
sudo bash setup.sh \
  --install-caddy \
  --domain your.domain.com \
  --oauth2-proxy \
  --google-client-id 'YOUR_CLIENT_ID.apps.googleusercontent.com' \
  --google-client-secret 'YOUR_CLIENT_SECRET' \
  --cookie-secret 'YOUR16BYTESECRET' \
  --allowed-email-domain 'yourcompany.com'
```

**One-line install (executes immediately)**
```bash
curl -fsSL https://raw.githubusercontent.com/mikeboe/henry/main/setup.sh | sudo bash -s -- \
  --install-caddy \
  --domain your.domain.com \
  --oauth2-proxy \
  --google-client-id 'YOUR_CLIENT_ID.apps.googleusercontent.com' \
  --google-client-secret 'YOUR_CLIENT_SECRET' \
  --cookie-secret 'YOUR16BYTESECRET' \
  --allowed-email-domain 'yourcompany.com'
```

> **Security Note**: Always review scripts before executing them, especially with sudo privileges. The "download and review first" method is recommended for production environments.

## Usage

```bash
./setup.sh [OPTIONS]
```

### Options

| Option | Description | Required |
|--------|-------------|----------|
| `--install-caddy` | Install and configure Caddy reverse proxy | No |
| `--domain DOMAIN` | Domain name for Caddy (enables auto HTTPS) | With `--install-caddy` (or use `--ip-only`) |
| `--username USERNAME` | Username for OpenCode web server (default: `opencode`) | No |
| `--password PASSWORD` | Password for OpenCode web server | With `--install-caddy` (not needed with `--oauth2-proxy`) |
| `--port PORT` | OpenCode port (default: 4096) | No |
| `--ip-only` | Configure Caddy for IP-only access with self-signed cert | No |
| `--behind-proxy` | Configure Caddy for HTTP-only mode when behind a CDN/reverse proxy (prevents redirect loops) | No |
| `--oauth2-proxy` | Enable oauth2-proxy with Google login for Caddy authentication | No |
| `--google-client-id ID` | Google OAuth2 client ID | With `--oauth2-proxy` |
| `--google-client-secret SECRET` | Google OAuth2 client secret | With `--oauth2-proxy` |
| `--cookie-secret SECRET` | Cookie secret for oauth2-proxy (must be exactly 16, 24, or 32 characters) | With `--oauth2-proxy` |
| `--allowed-email-domain DOMAIN` | Restrict Google login to users from this email domain (default: `*` = any Google account) | No |
| `--allowed-email EMAIL` | Restrict Google login to a single specific email address | No |
| `-h, --help` | Display help message | No |

## Examples

### 1. Basic Setup Without Caddy

Perfect for development or when using a different reverse proxy:

```bash
./setup.sh
```

After setup, access OpenCode at: `http://<server-ip>:4096`

### 2. Production Setup with Domain

Best for production use with automatic HTTPS certificates:

```bash
./setup.sh \
  --install-caddy \
  --domain code.example.com \
  --password 'SecurePassword123!'
```

**Requirements:**
- DNS A record for `code.example.com` must point to your server's IP
- Port 80 and 443 must be accessible for Let's Encrypt certificate validation

After setup, access OpenCode at: `https://code.example.com`

### 3. IP-Only Setup with Self-Signed Certificate

For scenarios without a domain name:

```bash
./setup.sh \
  --install-caddy \
  --ip-only \
  --password 'MySecurePassword!'
```

After setup, access OpenCode at: `https://<server-ip>` (you'll see a browser warning about the self-signed certificate, which is expected)

### 4. Production Setup Behind a CDN or Reverse Proxy

Use when a CDN (e.g., BunnyCDN, Cloudflare) or reverse proxy handles TLS in front of Caddy. This configures Caddy for HTTP-only mode, preventing redirect loops:

```bash
./setup.sh \
  --install-caddy \
  --domain code.example.com \
  --behind-proxy \
  --password 'SecurePassword123!'
```

After setup, configure your CDN/proxy to forward HTTP traffic to this server on port 80.

### 5. Custom Port

Run OpenCode on a custom port:

```bash
./setup.sh \
  --install-caddy \
  --domain code.example.com \
  --password 'SecurePassword123!' \
  --port 8080
```

### 6. Custom Username

Override the default OpenCode username (default is `opencode`):

```bash
./setup.sh \
  --install-caddy \
  --domain code.example.com \
  --username myuser \
  --password 'SecurePassword123!'
```

### 7. Google OAuth2 Login via oauth2-proxy

Replace password authentication with Google login. Users must sign in with their Google account before accessing OpenCode:

```bash
./setup.sh \
  --install-caddy \
  --domain code.example.com \
  --oauth2-proxy \
  --google-client-id '123456789-abc.apps.googleusercontent.com' \
  --google-client-secret 'GOCSPX-...' \
  --cookie-secret 'a8f3k9s2b1n7m4q6' \
  --allowed-email-domain 'yourcompany.com'
```

Restrict to a single email address instead of a whole domain:

```bash
./setup.sh \
  --install-caddy \
  --domain code.example.com \
  --oauth2-proxy \
  --google-client-id '123456789-abc.apps.googleusercontent.com' \
  --google-client-secret 'GOCSPX-...' \
  --cookie-secret 'a8f3k9s2b1n7m4q6' \
  --allowed-email 'user@gmail.com'
```

See the [Google Cloud Console Setup](#google-cloud-console-setup) section for how to obtain your credentials.

## What Gets Installed

### Always Installed
- System updates
- Essential tools: `tmux`, `git`, `curl`, `build-essential`, `python3-pip`, `unzip`
- Docker
- NVM (Node Version Manager)
- Node.js LTS
- Global Node tools: `nodemon`
- OpenCode (AI coding agent)

### With `--install-caddy`
- Caddy web server
- Automatic HTTPS certificates (with domain) or self-signed certificates (IP-only)
- Reverse proxy configuration
- Firewall rules (UFW or firewalld)

### With `--install-caddy --oauth2-proxy`
All of the above, plus:
- oauth2-proxy binary (downloaded from GitHub releases)
- oauth2-proxy configuration at `/etc/oauth2-proxy/oauth2-proxy.cfg` (chmod 600)
- oauth2-proxy systemd service

## Architecture

### Without Caddy
```
Browser → http://server-ip:4096 → OpenCode
```

### With Caddy (Domain)
```
Browser → https://your.domain.com
              ↓
    Caddy (443) → OpenCode (localhost:4096)
                      ↓
              [OpenCode Auth Prompt]
```

### With Caddy (IP-Only)
```
Browser → https://server-ip
              ↓
    Caddy (443, self-signed) → OpenCode (localhost:4096)
                                     ↓
                             [OpenCode Auth Prompt]
```

### With Caddy Behind a CDN (--behind-proxy)
```
Browser → https://your.domain.com
              ↓
    Bunny CDN / Cloudflare (TLS termination)
              ↓ HTTP
    Caddy (80, auto_https off) → OpenCode (localhost:4096)
```

### With Caddy and oauth2-proxy (--oauth2-proxy)
```
Browser → https://your.domain.com
              ↓
    Caddy (443)
         ├── /oauth2/* → oauth2-proxy (localhost:4180)
         └── /* → forward_auth oauth2-proxy → OpenCode (localhost:4096)
                         ↓ (unauthenticated)
               [Google Login Page] → Google OAuth2 → callback
```

## Post-Installation

### Start OpenCode

**Terminal Mode:**
```bash
cd ~/projects && opencode
```

**Web Interface:**
```bash
opencode-web
```

The web interface will be accessible at:
- Without Caddy: `http://<server-ip>:4096`
- With Caddy + Domain: `https://your.domain.com`
- With Caddy + IP-only: `https://<server-ip>`

### OpenCode Authentication

When `--password` is provided during setup, the following environment variables are automatically saved to `~/.opencode_env` (with `chmod 600` for security) and sourced from `~/.bashrc`:

| Variable | Description | Required |
|----------|-------------|----------|
| `OPENCODE_SERVER_PASSWORD` | Password for the OpenCode web server | Yes (with `--install-caddy`) |
| `OPENCODE_SERVER_USERNAME` | Username for the OpenCode web server | No (defaults to `opencode`) |

These variables are picked up by OpenCode when the `opencode-web` alias is run.

### Managing oauth2-proxy

**Check Status:**
```bash
sudo systemctl status oauth2-proxy
```

**Restart oauth2-proxy:**
```bash
sudo systemctl restart oauth2-proxy
```

**View Logs:**
```bash
sudo journalctl -u oauth2-proxy -f
```

**Update Configuration:**
```bash
sudo nano /etc/oauth2-proxy/oauth2-proxy.cfg
# After editing, restart:
sudo systemctl restart oauth2-proxy
```

### Managing Caddy

**Check Status:**
```bash
sudo systemctl status caddy
```

**Restart Caddy:**
```bash
sudo systemctl restart caddy
```

**Reload Configuration:**
```bash
sudo systemctl reload caddy
```

**View Logs:**
```bash
sudo journalctl -u caddy -f
```

**Update Caddyfile:**
```bash
sudo nano /etc/caddy/Caddyfile
# After editing, validate and reload:
caddy validate --config /etc/caddy/Caddyfile
sudo systemctl reload caddy
```

### Changing OpenCode Password

To change the OpenCode web server password:

1. Edit `~/.opencode_env` and update the `OPENCODE_SERVER_PASSWORD` value:
```bash
nano ~/.opencode_env
# Update the line:
# export OPENCODE_SERVER_PASSWORD='NewPassword123!'
```

2. Re-source the file (or open a new terminal session):
```bash
source ~/.opencode_env
```

3. Restart the OpenCode web server (stop the current `opencode-web` process and start it again):
```bash
opencode-web
```

## Security Features

When using Caddy:
- ✅ **HTTPS Encryption**: All traffic is encrypted
- ✅ **Password Protection**: OpenCode authentication protects access (without `--oauth2-proxy`)
- ✅ **Google OAuth2**: Google login via oauth2-proxy (with `--oauth2-proxy`)
- ✅ **Port Isolation**: OpenCode port not exposed publicly
- ✅ **Auto Certificate Renewal**: Let's Encrypt certificates auto-renew (domain mode)
- ✅ **Firewall Configuration**: Only HTTPS/HTTP ports are opened

## Google Cloud Console Setup

Before running the setup script with `--oauth2-proxy`, you need to create OAuth2 credentials in the Google Cloud Console.

### Step 1: Create a Google Cloud Project

1. Go to [https://console.cloud.google.com/](https://console.cloud.google.com/)
2. Click **Select a project** → **New Project**
3. Enter a project name (e.g., `opencode-server`) and click **Create**

### Step 2: Configure the OAuth Consent Screen

1. In the left menu, go to **APIs & Services → OAuth consent screen**
2. Select **External** (for personal use) or **Internal** (for Google Workspace organizations)
3. Fill in the required fields:
   - **App name**: e.g., `OpenCode`
   - **User support email**: your email
   - **Developer contact email**: your email
4. Click **Save and Continue** through the remaining steps
5. On the **Test users** step (for External apps), add the Google accounts that should have access

### Step 3: Create OAuth2 Credentials

1. Go to **APIs & Services → Credentials**
2. Click **Create Credentials → OAuth client ID**
3. Set **Application type** to **Web application**
4. Enter a **Name** (e.g., `OpenCode Caddy`)
5. Under **Authorized redirect URIs**, add:
   ```
   https://your.domain.com/oauth2/callback
   ```
   Replace `your.domain.com` with your actual domain. This must exactly match the `redirect_url` configured by the setup script.
6. Click **Create**
7. Copy the **Client ID** and **Client Secret** — you will pass these to the setup script

### Step 4: Generate a Cookie Secret

The cookie secret must be exactly **16, 24, or 32 characters**. Generate one with:

```bash
python3 -c "import secrets; print(secrets.token_hex(16)[:16])"
```

Or use any random 16/24/32-character string.

### Step 5: Run the Setup Script

```bash
sudo bash setup.sh \
  --install-caddy \
  --domain your.domain.com \
  --oauth2-proxy \
  --google-client-id 'YOUR_CLIENT_ID.apps.googleusercontent.com' \
  --google-client-secret 'YOUR_CLIENT_SECRET' \
  --cookie-secret 'YOUR16BYTESECRET' \
  --allowed-email-domain 'yourcompany.com'
```

**Options for restricting access:**

| Goal | Flag |
|------|------|
| Allow any Google account | *(omit both flags)* |
| Allow only `@yourcompany.com` accounts | `--allowed-email-domain yourcompany.com` |
| Allow a single specific email | `--allowed-email user@gmail.com` |

> **Note for IP-only mode (`--ip-only --oauth2-proxy`):** Google OAuth2 does not accept raw IP addresses as redirect URIs. You must use a domain. If you need IP-only access, consider using password authentication (`--password`) instead.

## Troubleshooting

### Too Many Redirects / Redirect Loop (308)
**Error**: Browser shows "Too many redirects" or the site loops with 308 Permanent Redirect responses

**Cause**: This happens when Caddy is behind a CDN or reverse proxy (e.g., BunnyCDN, Cloudflare) that terminates TLS and forwards requests to the origin over HTTP. Caddy's automatic HTTP→HTTPS redirect creates an infinite loop: CDN → HTTP → Caddy → 308 to HTTPS → CDN follows → HTTP → Caddy → 308... and so on.

**Solution**: Re-run the setup script with `--behind-proxy` to configure Caddy for HTTP-only mode with `auto_https off`. This completely disables Caddy's TLS certificate acquisition and its HTTP→HTTPS redirect, so that the CDN/proxy can handle all TLS termination:
```bash
sudo bash setup.sh \
  --install-caddy \
  --domain your.domain.com \
  --behind-proxy \
  --password 'YourPassword'
```

Or manually update the Caddyfile to add the global `auto_https off` block and use the `http://` scheme:
```bash
sudo nano /etc/caddy/Caddyfile
# Replace with:
# {
#     auto_https off
# }
#
# http://your.domain.com {
#     reverse_proxy localhost:4096
# }
caddy validate --config /etc/caddy/Caddyfile
sudo systemctl reload caddy
```

**Bunny CDN-specific checklist:**
1. In your Bunny CDN Pull Zone settings, set the **Origin URL** to `http://your-server-ip` (plain HTTP, port 80)
2. Enable **Force HTTPS** on the Bunny CDN side (Bunny handles the TLS, not Caddy)
3. Ensure your server firewall allows port **80** from Bunny CDN edge nodes
4. Use `--behind-proxy` when running setup so Caddy runs with `auto_https off`

### DNS Not Configured
**Error**: Certificate issuance fails
**Solution**: Ensure your domain's DNS A record points to the server's IP before running the script

### Firewall Blocking
**Error**: Can't access the site
**Solution**: Check firewall rules:
```bash
# UFW
sudo ufw status
sudo ufw allow 443/tcp
sudo ufw allow 80/tcp

# firewalld
sudo firewall-cmd --list-all
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload
```

### Caddy Not Starting
**Error**: Caddy service fails
**Solution**: Check logs and configuration:
```bash
sudo journalctl -u caddy -n 50
caddy validate --config /etc/caddy/Caddyfile
```

### Port Already in Use
**Error**: Port 443 or 4096 already in use
**Solution**: Check what's using the port:
```bash
sudo lsof -i :443
sudo lsof -i :4096
```

### oauth2-proxy Not Starting
**Error**: oauth2-proxy service fails
**Solution**: Check logs for errors:
```bash
sudo journalctl -u oauth2-proxy -n 50
```

Common causes:
- Invalid `client_id` or `client_secret` — double-check the values from Google Cloud Console
- Wrong `cookie_secret` length — it must be exactly 16, 24, or 32 characters
- `redirect_url` mismatch — the URL in `/etc/oauth2-proxy/oauth2-proxy.cfg` must exactly match the **Authorized redirect URI** registered in Google Cloud Console

### Google Login Redirects to Error Page
**Error**: After Google login, redirected to an error page
**Cause**: The `redirect_url` in the oauth2-proxy config does not match the **Authorized redirect URI** in Google Cloud Console.

**Solution**:
1. Check the configured redirect URL:
   ```bash
   grep redirect_url /etc/oauth2-proxy/oauth2-proxy.cfg
   ```
2. Go to [Google Cloud Console → APIs & Services → Credentials](https://console.cloud.google.com/apis/credentials)
3. Edit your OAuth 2.0 Client ID and ensure the **Authorized redirect URIs** list contains exactly the URL from step 1.

### Access Denied After Google Login
**Error**: oauth2-proxy shows "Access Denied" or "Unauthorized" after successful Google login
**Cause**: The logged-in email does not match the configured restrictions.

**Solution**: Check the email restriction in `/etc/oauth2-proxy/oauth2-proxy.cfg`:
```bash
sudo cat /etc/oauth2-proxy/oauth2-proxy.cfg
```
- If you used `--allowed-email-domain`, ensure the user's email ends with `@thatdomain.com`
- If you used `--allowed-email`, ensure the exact email address matches
- To allow all Google accounts, remove the restriction:
  ```bash
  sudo nano /etc/oauth2-proxy/oauth2-proxy.cfg
  # Change to:  email_domains = [ "*" ]
  sudo systemctl restart oauth2-proxy
  ```

## Supported Operating Systems

- ✅ Ubuntu/Debian (apt-based)
- ✅ RHEL/Fedora/CentOS (dnf-based)

## Requirements

- Root or sudo access
- Clean server instance (recommended)
- For domain-based HTTPS: Valid domain with DNS configured
- Internet connection

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

See [LICENSE](LICENSE) file for details.

## Support

For issues or questions:
- Open an issue on GitHub
- Check the troubleshooting section above
- Review Caddy documentation: https://caddyserver.com/docs/
- Review OpenCode documentation: https://opencode.ai/docs/

## Related Resources

- [Caddy Documentation](https://caddyserver.com/docs/)
- [OpenCode Documentation](https://opencode.ai/docs/)
- [Let's Encrypt](https://letsencrypt.org/)
- [oauth2-proxy Documentation](https://oauth2-proxy.github.io/oauth2-proxy/)
- [oauth2-proxy Caddy Integration](https://oauth2-proxy.github.io/oauth2-proxy/configuration/integrations/caddy)
- [oauth2-proxy Google Provider](https://oauth2-proxy.github.io/oauth2-proxy/configuration/providers/google)
- [Google Cloud Console](https://console.cloud.google.com/)
