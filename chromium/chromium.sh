#!/bin/bash

# Check if Alpine chroot exists, install if missing
CHROOT_DIR="/storage/my-alpine-chroot"

if [ ! -d "$CHROOT_DIR" ] || [ ! -f "$CHROOT_DIR/bin/busybox" ]; then
    echo "⚠️ Alpine chroot not found! Installing now..."
    curl -Ls https://github.com/trashbus99/ROCKNIX.apps/raw/main/base/alpine.sh | bash
fi

# Ensure installation succeeded
if [ ! -d "$CHROOT_DIR" ] || [ ! -f "$CHROOT_DIR/bin/busybox" ]; then
    echo "❌ Alpine chroot installation failed!"
    exit 1
fi

echo "✅ Alpine chroot detected!"

# Define Directories and Executables
LAUNCH_SCRIPT_DIR="/storage/roms/ports"
CHROMIUM_EXEC="/usr/bin/chromium --no-sandbox --new-window"
GPTOKEYB="/usr/bin/gptokeyb"
GPTK_CONFIG_DIR="/storage/roms/ports"

mkdir -p "$LAUNCH_SCRIPT_DIR"
mkdir -p "$GPTK_CONFIG_DIR"

# Install Chromium inside chroot
echo "📦 Installing Chromium..."
chroot "$CHROOT_DIR" /bin/bash -l <<EOF
apk update
apk add chromium
EOF

generate_launcher() {
    local name="$1"
    local url="$2"
    local script_path="$LAUNCH_SCRIPT_DIR/chroot-${name}.sh"
    local gptk_file="$GPTK_CONFIG_DIR/${name}.gptk"

    echo "🎮 Generating $name launcher..."

    # Create the GPTK mapping file (Only Hotkey: SELECT + START -> ALT+F4)
    cat <<EOF > "$gptk_file"
hotkey = start+select:KEY_LEFTALT+KEY_F4
EOF

    # Create the launcher script
    cat <<EOF > "$script_path"
#!/bin/bash
trap 'pkill gptokeyb' EXIT

# Launch gptokeyb for the hotkey to kill Chromium
\gptokeyb -p "chromium" -c "$gptk_file" -k chromium &

# Allow a short delay for gptokeyb to load
sleep 1

CHROOT_DIR="$CHROOT_DIR"
WAYLAND_SOCKET="/run/user/1000/wayland-0"
PULSE_DIR="/run/0-runtime-dir/pulse"
PULSE_SOCKET="\$PULSE_DIR/native"

mkdir -p "\$CHROOT_DIR/run/user/1000"
mkdir -p "\$CHROOT_DIR\$PULSE_DIR"
chmod 777 "\$CHROOT_DIR\$PULSE_DIR"

if ! mountpoint -q "\$CHROOT_DIR\$WAYLAND_SOCKET"; then
    mount --bind "\$WAYLAND_SOCKET" "\$CHROOT_DIR\$WAYLAND_SOCKET"
fi
if ! mountpoint -q "\$CHROOT_DIR\$PULSE_DIR"; then
    mount --make-private "\$PULSE_DIR"
    mount --bind "\$PULSE_DIR" "\$CHROOT_DIR\$PULSE_DIR"
fi

exec chroot "\$CHROOT_DIR" env \\
    WAYLAND_DISPLAY=wayland-0 \\
    PULSE_SERVER=unix:\$PULSE_SOCKET \\
    $CHROMIUM_EXEC "$url"
EOF

    chmod +x "$script_path"
}

# Generate launchers for each web app
generate_launcher "spotify" "https://open.spotify.com"
generate_launcher "luna" "https://www.amazon.com/luna"
generate_launcher "parsec" "https://parsec.app"
generate_launcher "xbox-cloud" "https://www.xbox.com/play"
generate_launcher "geforce-now" "https://play.geforcenow.com"

echo "✅ All launchers created!"
echo "🎮 Press SELECT + START to kill Chromium."
