#!/bin/bash
source /etc/container_environment
echo "Heartbeat script started."

echo "in dir: ${MEDIA_CONVERTER_IN_DIR}"

# LOCK_FILE="media-manager.lock"

# echo "Starting heartbeat..."

# if [ -f "$LOCK_FILE" ]; then
# 	echo "Lock file exists, another instance is running. Exiting..."
# 	exit 1
# fi


# echo $$ > "$LOCK_FILE" # Store current PID in the lock file

# sleep infinity

# echo "completed heartbeat"

# rm "$LOCK_FILE"

# exit 0
