#!/bin/bash
# Chromium Kiosk Launcher with Gamepad Support Injection

CHROOT_DIR="/storage/my-alpine-chroot"
WAYLAND_SOCKET="/run/user/1000/wayland-0"
PULSE_DIR="/run/0-runtime-dir/pulse"
PULSE_SOCKET="$PULSE_DIR/native"
GPTOKEYB="/usr/bin/gptokeyb"
GPTK_CONFIG="/storage/roms/ports/chromium.gptk"

mkdir -p "$CHROOT_DIR/run/user/1000"
mkdir -p "$CHROOT_DIR$PULSE_DIR"
chmod 777 "$CHROOT_DIR$PULSE_DIR"

# Mount Wayland and PulseAudio if not already mounted
if ! mountpoint -q "$CHROOT_DIR$WAYLAND_SOCKET"; then
    mount --bind "$WAYLAND_SOCKET" "$CHROOT_DIR$WAYLAND_SOCKET"
fi
if ! mountpoint -q "$CHROOT_DIR$PULSE_DIR"; then
    mount --make-private "$PULSE_DIR"
    mount --bind "$PULSE_DIR" "$CHROOT_DIR$PULSE_DIR"
fi

# Inject JavaScript to force-enable gamepads
GAMEPAD_SCRIPT="/storage/roms/ports/chromium_gamepad.js"
cat <<EOF > "$GAMEPAD_SCRIPT"
window.addEventListener("gamepadconnected", (event) => {
    console.log("Gamepad connected:", event.gamepad);
});
EOF

# Ensure gptokeyb mapping file exists (for hotkey shutdown)
cat <<EOF > "$GPTK_CONFIG"
hotkey = start+select:KEY_LEFTALT+KEY_F4
EOF

# Start gptokeyb for gamepad hotkey
trap 'pkill gptokeyb' EXIT
$GPTOKEYB -p "chromium" -c "$GPTK_CONFIG" -k chromium &

# Allow a short delay for mapping
sleep 1

# Launch Chromium in Kiosk Mode (Fullscreen) with Gamepad Injection
exec chroot "$CHROOT_DIR" env \
    WAYLAND_DISPLAY=wayland-0 \
    PULSE_SERVER=unix:$PULSE_SOCKET \
    /usr/bin/chromium --no-sandbox --kiosk --start-maximized \
    --disable-pinch --enable-gamepad --enable-gamepad-extensions \
    --autoplay-policy=no-user-gesture-required \
    --disable-translate --noerrdialogs \
    --load-extension="$GAMEPAD_SCRIPT"
