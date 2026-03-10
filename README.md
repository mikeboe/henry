# Cloud Coding Agent Setup Script

One command to setup AI coding agents on cloud servers (Hetzner, AWS, etc.) with optional Caddy reverse proxy for secure HTTPS access.

## Features

- ✅ Automated setup of development environment (Docker, Git, Node.js, Python, etc.)
- ✅ OpenCode installation for AI-powered coding
- ✅ Optional Caddy reverse proxy with auto HTTPS
- ✅ Password-protected access with basic authentication
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
  --username admin \
  --password 'YourStrongPassword123!'
```

**One-line install (executes immediately)**
```bash
curl -fsSL https://raw.githubusercontent.com/mikeboe/henry/main/setup.sh | sudo bash -s -- \
  --install-caddy \
  --domain your.domain.com \
  --username admin \
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
  --username admin \
  --password 'YourStrongPassword123!'
```

**One-line install (executes immediately)**
```bash
curl -fsSL https://raw.githubusercontent.com/mikeboe/henry/main/setup.sh | sudo bash -s -- \
  --install-caddy \
  --ip-only \
  --username admin \
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
  --username admin \
  --password 'YourStrongPassword123!'
```

**One-line install (executes immediately)**
```bash
curl -fsSL https://raw.githubusercontent.com/mikeboe/henry/main/setup.sh | sudo bash -s -- \
  --install-caddy \
  --domain your.domain.com \
  --behind-proxy \
  --username admin \
  --password 'YourStrongPassword123!'
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
| `--username USERNAME` | Username for basic auth (default: admin) | No |
| `--password PASSWORD` | Password for basic auth | With `--install-caddy` |
| `--port PORT` | OpenCode port (default: 4096) | No |
| `--ip-only` | Configure Caddy for IP-only access with self-signed cert | No |
| `--behind-proxy` | Configure Caddy for HTTP-only mode when behind a CDN/reverse proxy (prevents redirect loops) | No |
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
  --username admin \
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
  --username myuser \
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
  --username admin \
  --password 'SecurePassword123!'
```

After setup, configure your CDN/proxy to forward HTTP traffic to this server on port 80.

### 5. Custom Port

Run OpenCode on a custom port:

```bash
./setup.sh \
  --install-caddy \
  --domain code.example.com \
  --username admin \
  --password 'SecurePassword123!' \
  --port 8080
```

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
- Basic authentication
- Reverse proxy configuration
- Firewall rules (UFW or firewalld)

## Architecture

### Without Caddy
```
Browser → http://server-ip:4096 → OpenCode
```

### With Caddy (Domain)
```
Browser → https://your.domain.com
              ↓
        [Basic Auth Prompt]
              ↓
    Caddy (443) → OpenCode (localhost:4096)
```

### With Caddy (IP-Only)
```
Browser → https://server-ip
              ↓
        [Basic Auth Prompt + Self-Signed Cert Warning]
              ↓
    Caddy (443) → OpenCode (localhost:4096)
```

### With Caddy Behind a CDN (--behind-proxy)
```
Browser → https://your.domain.com
              ↓
    Bunny CDN / Cloudflare (TLS termination)
              ↓ HTTP
    Caddy (80, auto_https off) → OpenCode (localhost:4096)
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

### Changing Password

To change the basic auth password:

1. Generate a new hashed password:
```bash
caddy hash-password --plaintext 'NewPassword123!'
```

2. Update `/etc/caddy/Caddyfile` with the new hash

3. Reload Caddy:
```bash
sudo systemctl reload caddy
```

## Security Features

When using Caddy:
- ✅ **HTTPS Encryption**: All traffic is encrypted
- ✅ **Password Protection**: Basic authentication protects access
- ✅ **Port Isolation**: OpenCode port not exposed publicly
- ✅ **Auto Certificate Renewal**: Let's Encrypt certificates auto-renew (domain mode)
- ✅ **Firewall Configuration**: Only HTTPS/HTTP ports are opened

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
  --username admin \
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
#     basicauth * { ... }
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
