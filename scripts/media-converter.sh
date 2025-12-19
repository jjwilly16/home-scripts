#!/bin/bash

source /etc/container_environment
# need a logging helper to prepend logs with [service] name and timestamp
IN_DIR="$MEDIA_CONVERTER_IN_DIR"
OUT_DIR="$MEDIA_CONVERTER_OUT_DIR"
FILES_CONVERTED=0

LOCK_FILE="/tmp/media-manager.lock"

mc_log() {
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] [media-converter] $1"
}

mc_log "Starting media converter. Looking in ${IN_DIR}..."

if [ -f "$LOCK_FILE" ]; then
	mc_log "Lock file exists, another instance is running. Exiting..."
	exit 1
fi

echo $$ > "$LOCK_FILE" # Store current PID in the lock file

is_video() {
	local FILE_EXT="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
	case $FILE_EXT in
		"mp4" | "mov" | "avi" | "mkv" | "wmv" | "flv" | "m4v")
		    return 0;;
		*)
		return 1;;
	esac
}

process_video() {
	local FILE="$1"
	local FILE_NAME=$(basename "$FILE")
	local FILE_EXT="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
	local CONVERT_VIDEOS_TO="mp4"
	mc_log "Processing video ${FILE}..."
	case $FILE_EXT in
		"mp4")
			mv "$FILE" "$OUT_DIR/$FILE_NAME"
			;;
		*)
			local FILE_NAME_NO_EXTENSION="${FILE_NAME%.*}"
			local VIDEO_NAME="$FILE_NAME_NO_EXTENSION.$CONVERT_VIDEOS_TO"
			ffmpeg -y -i "${FILE}" -loglevel quiet -metadata keyword="notag" -vcodec libx264 -acodec copy "$OUT_DIR/$VIDEO_NAME" && \
			rm -f "$FILE"
			;;
	esac
	mc_log "Done processing video ${FILE}."
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

process_photo() {
	local FILE="$1"
	local FILE_NAME=$(basename "$FILE")
	local FILE_NAME_NO_EXTENSION="${FILE_NAME%.*}"
	if [[ $FILE_NAME_NO_EXTENSION == *"HDR"* ]];
	    then
		echo "deleting HDR photo $FILE"
		rm -f "$FILE"
		return
	fi
	mc_log "Processing photo ${FILE}..."
	mv "$FILE" "$OUT_DIR/$FILE_NAME"
	mc_log "Done processing photo ${FILE}."
}

process_file () {
	local FILE="$1"
	local FILE_NAME=$(basename "$FILE")
	local FILE_EXT="${FILE_NAME##*.}"

	mc_log "Processing file ${FILE}..."

	# If file wasn't auto-uploaded to this directory, exit without moving it
	if ! [[ "$FILE_NAME" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}.[0-9]{2}.[0-9]{2}\ [0-9]{3,5}.(.*)$ ]];
		then
			mc_log "File name pattern doesn't match. Skipping..."
			return
	fi

	if is_video "$FILE_EXT"; then
		process_video "$FILE"
	elif is_photo "$FILE_EXT"; then
		process_photo "$FILE"
	else
		mc_log "Unknown file type. Skipping..."
		return
	fi
	FILES_CONVERTED=$((FILES_CONVERTED + 1))
}

for dir in $IN_DIR/*; do
	# skip directory that matches "#recycle" pattern
	[[ $dir =~ \#recycle ]] && continue
	# skip directory that matches "_" prefix pattern
	[[ $(basename "$dir") =~ ^_.* ]] && continue

	for file in $dir/*; do
		[ -f "$file" ] || continue # skip if not a file
		process_file "$file"
	done
done

rm "$LOCK_FILE"
mc_log "Media converter finished"

if [ "$FILES_CONVERTED" -gt 0 ]; then
	mc_log "Converted $FILES_CONVERTED files."
else
	mc_log "No files converted."
fi

exit 0
