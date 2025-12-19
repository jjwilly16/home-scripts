#!/bin/bash

source /etc/container_environment

IN_DIR="$MEDIA_MOVER_IN_DIR"
OUT_DIR="$MEDIA_MOVER_OUT_DIR"
PLEX_SERVER="192.168.1.55:32400"
FILES_MOVED=0
VIDEOS_MOVED=0
PHOTOS_MOVED=0

LOCK_FILE="/tmp/media-manager.lock"

mm_log() {
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] [media-mover] $1"
}

mm_log "Starting media mover. Looking in ${IN_DIR}..."

if [ -f "$LOCK_FILE" ]; then
	mm_log "Lock file exists, another instance is running. Exiting..."
	exit 1
fi

echo $$ > "$LOCK_FILE" # Store current PID in the lock file

get_date_path_from_media() {
	local FILE="$1"
	local FILE_NAME=$(basename "$FILE")
	local YEAR=$(echo "$FILE_NAME" | cut -d "-" -f 1)
	local MONTH=$(echo "$FILE_NAME" | cut -d "-" -f 2)
	echo "$YEAR/$MONTH"
}

is_video() {
	local FILE_EXT="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
	case $FILE_EXT in
		"mp4" | "mov" | "avi" | "mkv" | "wmv" | "flv" | "m4v")
		    return 0;;
		*)
		return 1;;
	esac
}

is_photo() {
	local FILE_EXT="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
	case $FILE_EXT in
		"jpg" | "jpeg" | "png")
		    return 0;;
		*)
		return 1;;
	esac
}

refresh_plex_library() {
	local SECTION_ID="$1"
	mm_log "refreshing plex library section $SECTION_ID"
	curl -X POST "http://${PLEX_SERVER}/library/sections/$SECTION_ID/refresh"
}

move_file () {
	local FILE="$1"
	local FILE_NAME=$(basename "$FILE")
	local FILE_EXT="${FILE_NAME##*.}"

	if is_video "$FILE_EXT"; then
		MEDIA_PATH="videos"
		VIDEOS_MOVED=$((VIDEOS_MOVED + 1))
		FILES_MOVED=$((FILES_MOVED + 1))
	elif is_photo "$FILE_EXT"; then
		MEDIA_PATH="photos"
		PHOTOS_MOVED=$((PHOTOS_MOVED + 1))
		FILES_MOVED=$((FILES_MOVED + 1))
	else
		mm_log "Unknown file type. Skipping..."
		continue
	fi

	DESTINATION="${OUT_DIR}/${MEDIA_PATH}/$(get_date_path_from_media "$FILE")"

	mm_log "Moving file ${FILE} to ${DESTINATION}"

	mkdir -p "$DESTINATION"
	mv "$FILE" "${DESTINATION}/${FILE_NAME}"
}

for file in $IN_DIR/*; do
	[ -f "$file" ] || continue # skip if not a file
	move_file "$file"
done

if [ "$PHOTOS_MOVED" -gt 0 ]; then
	refresh_plex_library "4" # photos
fi

if [ "$VIDEOS_MOVED" -gt 0 ]; then
	refresh_plex_library "5" # videos
fi

rm "$LOCK_FILE"
mm_log "Media mover finished"

if [ "$FILES_MOVED" -gt 0 ]; then
	mm_log "Moved $FILES_MOVED files."
else
	mm_log "No files moved."
fi

exit 0
