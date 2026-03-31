#!/bin/bash
set -e

# Update and install packages
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y wget curl vim tmux tree nload zsh ripgrep neovim fd-find git bat

# Install tools
curl -sS https://starship.rs/install.sh | sh -s -- -y
curl -LsSf https://astral.sh/uv/install.sh | sh

# Setup Oh My Zsh for root
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Install Oh My Zsh plugins
ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}
[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] || git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] || git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
[ -d "$ZSH_CUSTOM/plugins/zsh-completions" ] || git clone https://github.com/zsh-users/zsh-completions.git "$ZSH_CUSTOM/plugins/zsh-completions"

# Copy .zshrc from scripts
cp .github/scripts/.zshrc "$HOME/.zshrc"

# Copy .tmux.conf from scripts
cp .github/scripts/.tmux.conf "$HOME/.tmux.conf"

# Fix zsh completion permissions
chmod go-w /usr/share/zsh 2>/dev/null || true
chmod go-w /usr/share/zsh/vendor-completions 2>/dev/null || true

# Setup Interceptors
cat > /usr/local/bin/action-shutdown << 'EOF'
#!/bin/bash
echo "Stopping GitHub Action and shutting down..."
touch /tmp/stop_runner
EOF

chmod +x /usr/local/bin/action-shutdown

# Link to common shutdown commands in /usr/local/bin (usually higher priority in PATH)
for cmd in poweroff reboot shutdown halt; do
    ln -sf /usr/local/bin/action-shutdown /usr/local/bin/$cmd
done

# If /sbin versions are being called explicitly, we try to override them
# This is risky but since this is a ephemeral runner, it's fine.
for cmd in poweroff reboot shutdown halt; do
    if [ -f "/sbin/$cmd" ]; then
        mv "/sbin/$cmd" "/sbin/$cmd.orig" 2>/dev/null || true
        ln -sf /usr/local/bin/action-shutdown "/sbin/$cmd" 2>/dev/null || true
    fi
done

# Finish, Change Shell
chsh root -s $(which zsh)
