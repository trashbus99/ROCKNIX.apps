#!/bin/bash

# File paths
JEOPARDY_AUDIO="/userdata/music/jeopardy.mp3"
RICKROLL_AUDIO="/userdata/music/rickroll.mp3"
LOSER_HORN_AUDIO="/userdata/music/loserhorn.mp3"

# Your hosted GitHub MP3 URLs
JEOPARDY_URL="https://github.com/trashbus99/profork/raw/master/.dep/.ytrk/at.mp3"
RICKROLL_URL="https://github.com/trashbus99/profork/raw/master/.dep/.ytrk/ee.mp3"
LOSER_HORN_URL="https://github.com/trashbus99/profork/raw/master/.dep/.ytrk/lh.mp3"

# Ensure the directory exists
mkdir -p /userdata/music

# Download MP3s if missing
for file in "$JEOPARDY_AUDIO" "$RICKROLL_AUDIO" "$LOSER_HORN_AUDIO"; do
    case $file in
        "$JEOPARDY_AUDIO") URL="$JEOPARDY_URL" ;;
        "$RICKROLL_AUDIO") URL="$RICKROLL_URL" ;;
        "$LOSER_HORN_AUDIO") URL="$LOSER_HORN_URL" ;;
    esac

    if [ ! -f "$file" ]; then
        wget -q -O "$file" "$URL"
    fi
done

# Play Jeopardy theme quietly in background
if command -v cvlc >/dev/null 2>&1; then
    cvlc --play-and-exit --no-video "$JEOPARDY_AUDIO" >/dev/null 2>&1 &
elif command -v mpg123 >/dev/null 2>&1; then
    mpg123 -q "$JEOPARDY_AUDIO" &
fi
MUSIC_PID=$!

# Prompt for password
PASSWORD=$(dialog --nocancel --inputbox "Enter the secret password:\n\nHint: In A.D. 2101, war was beginning...\nClassic Engrish from Zero Wing." 12 60 3>&1 1>&2 2>&3)

# Stop Jeopardy music
kill "$MUSIC_PID" 2>/dev/null

# Normalize input
PASSWORD_NORM=$(echo "$PASSWORD" | tr '[:upper:]' '[:lower:]')
SECRET="all your base are belong to us"

# Check password
if [ "$PASSWORD_NORM" == "$SECRET" ]; then
    dialog --msgbox "ACCESS GRANTED." 6 40
    sleep 1

    # Play Rickroll in background
    if command -v cvlc >/dev/null 2>&1; then
        cvlc --play-and-exit --no-video "$RICKROLL_AUDIO" >/dev/null 2>&1 &
    elif command -v mpg123 >/dev/null 2>&1; then
        mpg123 -q "$RICKROLL_AUDIO" &
    fi
    RICK_PID=$!

    # Troll message
    dialog --msgbox "
Well done, retro warrior.

You cracked the code. You spoke the ancient phrase. You are now among the elite who understand that 'somebody set up us the bomb.'

Decrypting will begin shortly...
" 20 60

    # Kill Rickroll
    kill "$RICK_PID" 2>/dev/null

    # Fake terminal animation
    clear
    echo ">>> INITIALIZING SECURE DECRYPTION MODULE v3.1-beta <<<"
    sleep 1
    echo "Locating encrypted payload..."
    sleep 1
    echo "✓ Found: /userdata/roms/memes/ultrasecret.7z"
    sleep 1
    echo "Mounting virtual floppy..."
    sleep 1
    echo "Injecting quantum bitstream..."
    sleep 0.7
    echo "Bypassing BIOS jumper..."
    sleep 0.6
    echo "Cracking 1024-bit key with pizza algorithm..."
    sleep 0.9
    echo "Extracting contents..."
    for i in {1..5}; do
        echo -n "█"
        sleep 0.3
    done
    echo "  Done."
    sleep 0.5
    echo "Analyzing payload signature..."
    sleep 1
    echo "🚨 WARNING: File is not a ROM."
    sleep 1
    echo "Decryption complete. Contents: one low-res GIF of a spinning hotdog."
    sleep 1
    echo ""
    echo "Mission complete. You've been gloriously trolled."
    echo ""
    
    echo "Finalizing... Please wait."
    sleep 5  # Extends time to read the message

    clear
    echo ""
    echo "================================================="
    echo " You typed the whole thing. You legend."
    echo " Somewhere, a Myrient mirror just winked at you."
    echo " Now go outside. Or at least play a game."
    echo " THIS IS NOT RETURNING TO THE MAIN MENU."
    echo "================================================="
    sleep 7  # Extra time before script exits

else
    # Wrong password → Play the Price is Right Loser Horn
    if command -v cvlc >/dev/null 2>&1; then
        cvlc --play-and-exit --no-video "$LOSER_HORN_AUDIO" >/dev/null 2>&1 &
    elif command -v mpg123 >/dev/null 2>&1; then
        mpg123 -q "$LOSER_HORN_AUDIO" &
    fi
    HORN_PID=$!

    dialog --msgbox "ACCESS DENIED.

You have failed the sacred test of retro meme literacy.

Your failure is now being recorded for future Batocera historians.

Please reflect on your choices.

NOT returning to the main menu." 15 60

    kill "$HORN_PID" 2>/dev/null
    sleep 7  # Extra time before script exits

    echo ""
    echo "================================================="
    echo " ACCESS DENIED. SHAME DEPLOYED."
    echo " Tip: The password was not 'OpenSesame123'."
    echo " You may now return to Discord to argue about it."
    echo " THIS IS NOT RETURNING TO THE MAIN MENU."
    echo "================================================="
    sleep 7
fi

# 🔥 Auto-delete the MP3s so they always get re-downloaded!
rm -f "$JEOPARDY_AUDIO" "$RICKROLL_AUDIO" "$LOSER_HORN_AUDIO"
