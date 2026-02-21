#!/bin/bash
# Cloud Coding Agent Setup Script
# One command to setup AI coding agents on Hetzner

set -e

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

# Step 6: Install OpenCode
echo "Installing OpenCode..."
curl -fsSL https://opencode.ai/install 2>/dev/null | bash > /dev/null 2>&1

# Step 7: Create projects folder
echo "Creating projects folder..."
mkdir -p ~/projects

# Step 8: Add aliases to bashrc
echo "Creating shortcuts..."
cat >> ~/.bashrc << 'EOF'

# Coding Environment aliases
alias opencode-web="opencode web --hostname 0.0.0.0 --port 4096"

# Load NVM on login
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
EOF

# Step 9: Source bashrc
source ~/.bashrc

echo ""
echo "✅ Setup Complete!"
echo ""
echo "NEXT STEPS:"
echo ""
echo "Start coding in terminal:"
echo "   cd ~/projects && opencode"
echo ""
echo "Or start web interface:"
echo "   opencode-web"
echo "   Open: http://<your-server-ip>:4096"
echo ""
