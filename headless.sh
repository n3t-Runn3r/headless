# Create a new headless output
hyprctl output create headless >/dev/null

# Get the newest headless output name
HEADLESS_NAME=$(hyprctl monitors | grep -o 'HEADLESS-[0-9]*' | sort -V | tail -n1)

if [[ -z "$HEADLESS_NAME" ]]; then
  echo "❌ Failed to detect headless output."
  exit 1
fi

echo "Created $HEADLESS_NAME"

# Auto-detect primary network interface with an IP
IFACE=$(ip route | awk '/default/ {print $5; exit}')
IP=$(ip -4 addr show "$IFACE" | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n1)

if [[ -z "$IP" ]]; then
  echo "⚠️ Could not detect IP address for $IFACE"
else
  echo "Your $IFACE IP: $IP"
fi

# Start WayVNC
echo "Starting WayVNC on $HEADLESS_NAME (accessible at ${IP}:5900)"
wayvnc 0.0.0.0 --output "$HEADLESS_NAME" &
WAYVNC_PID=$!

# Wait for 'q' to quit
echo "Press 'q' then Enter to stop and remove $HEADLESS_NAME..."
while read -r -n1 key; do
  [[ $key == "q" ]] && break
done

# Stop WayVNC and remove headless
echo "Stopping WayVNC..."
kill "$WAYVNC_PID"
sleep 1
echo "Removing $HEADLESS_NAME..."
hyprctl output remove "$HEADLESS_NAME"

echo "✅ Done."
