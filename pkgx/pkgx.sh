#!/bin/bash

set -e

# Config
PKGX_DIR="$HOME/pkgx"
PKGX_BIN="$PKGX_DIR/pkgx"
BIN_WRAPPER="$HOME/bin"
BASH_PROFILE="$HOME/.bash_profile"
AUTO_DIR="$HOME/.config/autostart"
AUTO_PATH_SCRIPT="$AUTO_DIR/pkgx-path.sh"

echo "📦 Installing pkgx to $PKGX_DIR"

# Create install dir
mkdir -p "$PKGX_DIR"
cd "$PKGX_DIR"

# Fetch latest aarch64 build URL
PKGX_URL=$(curl -s https://api.github.com/repos/pkgxdev/pkgx/releases/latest \
  | jq -r '.assets[] | select(.name | endswith("+linux+aarch64.tar.gz")) | .browser_download_url')

if [ -z "$PKGX_URL" ]; then
  echo "❌ Could not find pkgx aarch64 build. Exiting."
  exit 1
fi

FILENAME=$(basename "$PKGX_URL")

# Download & extract
echo "⬇️  Downloading $FILENAME..."
curl -LO "$PKGX_URL"
tar -xzf "$FILENAME"
chmod +x pkgx

# Set up ~/bin and symlink
echo "🔗 Linking pkgx to $BIN_WRAPPER"
mkdir -p "$BIN_WRAPPER"
ln -sf "$PKGX_BIN" "$BIN_WRAPPER/pkgx"

# Ensure PATH is added to ~/.bash_profile
if [ ! -f "$BASH_PROFILE" ]; then
  touch "$BASH_PROFILE"
fi

if ! grep -q 'export PATH="$HOME/bin:$PATH"' "$BASH_PROFILE"; then
  echo '' >> "$BASH_PROFILE"
  echo 'export PATH="$HOME/bin:$PATH"' >> "$BASH_PROFILE"
  echo "📄 Added PATH to $BASH_PROFILE"
fi

# Immediately export PATH in current shell
export PATH="$HOME/bin:$PATH"

# Setup autostart PATH script
mkdir -p "$AUTO_DIR"
echo "#!/bin/bash" > "$AUTO_PATH_SCRIPT"
echo 'export PATH="$HOME/bin:$PATH"' >> "$AUTO_PATH_SCRIPT"
chmod +x "$AUTO_PATH_SCRIPT"
echo "📝 Autostart PATH script created: $AUTO_PATH_SCRIPT"

# Done
echo
echo "✅ pkgx installed to: $PKGX_BIN"
echo "✅ Symlinked to: $BIN_WRAPPER/pkgx"
echo "✅ PATH exported in: current shell, .bash_profile, and autostart"
echo
echo "🚀 Try something fun: run 👉 pkgx fastfetch"
