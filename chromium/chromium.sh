#!/bin/bash
# Chromium + Gamepad-Enabled Cloud Gaming Launcher Installer

CHROOT_DIR="/storage/my-alpine-chroot"
LAUNCH_SCRIPT_DIR="/storage/roms/ports"
CHROMIUM_LAUNCHER="$LAUNCH_SCRIPT_DIR/chroot-chromium.sh"
GPTK_FILE="$LAUNCH_SCRIPT_DIR/chromium.gptk"

# Ensure Alpine chroot exists, install if missing
if [ ! -d "$CHROOT_DIR" ] || [ ! -f "$CHROOT_DIR/bin/busybox" ]; then
    echo "🟡 Alpine chroot not found. Installing..."
    curl -Ls https://github.com/trashbus99/ROCKNIX.apps/raw/main/base/alpine.sh | bash
fi

# Install Chromium and dependencies inside the chroot
echo "📦 Installing Chromium and dependencies..."
chroot "$CHROOT_DIR" /bin/sh -l <<EOF
apk update
apk add chromium mesa-dri-gallium mesa-gl glib dbus dbus-x11
EOF

mkdir -p "$LAUNCH_SCRIPT_DIR"

# -----------------------------
# 📜 Create Chromium Launcher
# -----------------------------
echo "📝 Writing Chromium launch script..."
cat <<EOF > "$CHROMIUM_LAUNCHER"
#!/bin/bash
trap 'pkill gptokeyb' EXIT

CHROOT_DIR="$CHROOT_DIR"
WAYLAND_SOCKET="/run/user/1000/wayland-0"
PULSE_DIR="/run/0-runtime-dir/pulse"
PULSE_SOCKET="\$PULSE_DIR/native"

mkdir -p "\$CHROOT_DIR/run/user/1000"
mkdir -p "\$CHROOT_DIR\$PULSE_DIR"
chmod 777 "\$CHROOT_DIR\$PULSE_DIR"

# Ensure Wayland is mounted
if [ ! -S "\$WAYLAND_SOCKET" ]; then
    echo "❌ Wayland socket not found. Exiting..."
    exit 1
fi
if ! mountpoint -q "\$CHROOT_DIR\$WAYLAND_SOCKET"; then
    mount --bind "\$WAYLAND_SOCKET" "\$CHROOT_DIR\$WAYLAND_SOCKET"
fi

# Ensure DBus is running inside chroot
if ! chroot "\$CHROOT_DIR" ps aux | grep -q '[d]bus-daemon'; then
    echo "🔄 Starting DBus in chroot..."
    chroot "\$CHROOT_DIR" /etc/init.d/dbus start
fi

# Launch Chromium with gamepad support
\gptokeyb -p "chromium" -c "$GPTK_FILE" -k chromium &
sleep 1

exec chroot "\$CHROOT_DIR" env \
    WAYLAND_DISPLAY=wayland-0 \
    PULSE_SERVER=unix:\$PULSE_SOCKET \
    /usr/bin/chromium --no-sandbox --kiosk --start-maximized \
    --disable-pinch --enable-gamepad --enable-gamepad-extensions \
    --autoplay-policy=no-user-gesture-required \
    --disable-translate --noerrdialogs
EOF
chmod +x "$CHROMIUM_LAUNCHER"

# -----------------------------
# 🎮 Create Gamepad Kill Mapping
# -----------------------------
echo "📝 Writing GPTK gamepad hotkey mapping..."
cat <<EOF > "$GPTK_FILE"
hotkey = start+select:KEY_LEFTALT+KEY_F4
EOF

# -----------------------------
# 🎮 Create Cloud Gaming Launchers
# -----------------------------
declare -A GAME_URLS=(
    ["spotify"]="https://open.spotify.com/"
    ["luna"]="https://luna.amazon.com/"
    ["parsec"]="https://parsec.app/"
    ["xbox"]="https://www.xbox.com/play"
    ["geforce_now"]="https://play.geforcenow.com/"
)

for app in "\${!GAME_URLS[@]}"; do
    LAUNCHER="$LAUNCH_SCRIPT_DIR/chroot-$app.sh"
    echo "📝 Writing $app launch script..."

    cat <<EOF > "\$LAUNCHER"
#!/bin/bash
trap 'pkill gptokeyb' EXIT

\gptokeyb -p "chromium" -c "$GPTK_FILE" -k chromium &
sleep 1

exec chroot "\$CHROOT_DIR" env \
    WAYLAND_DISPLAY=wayland-0 \
    PULSE_SERVER=unix:\$PULSE_SOCKET \
    /usr/bin/chromium --no-sandbox --start-fullscreen \
    --disable-pinch --enable-gamepad --enable-gamepad-extensions \
    --autoplay-policy=no-user-gesture-required \
    --disable-translate --noerrdialogs \
    "\${GAME_URLS[$app]}"
EOF
    chmod +x "\$LAUNCHER"
done

echo "✅ Installation complete! Launch Chromium or Cloud Gaming apps from $LAUNCH_SCRIPT_DIR."
echo "Close app with select+start"
