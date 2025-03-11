#!/bin/bash

# Input and output file paths
INPUT_FILE="sub-01_2022-05-04_000_session.json"
OUTPUT_FILE="sub-01_2022-05-04_000_session_bash_uuid.json"
HASH_FILE="${OUTPUT_FILE%.json}_hash.txt"

# Generate UUID
UUID=$(uuidgen)

# Add UUID field to JSON and save to new file
jq --arg uuid "$UUID" '. + {uuid: $uuid}' "$INPUT_FILE" > "$OUTPUT_FILE"

# Generate SHA-256 hash of the new JSON file
HASH=$(sha256sum "$OUTPUT_FILE" | awk '{print $1}')

# Save hash to file
echo "$HASH" > "$HASH_FILE"

echo "Created $OUTPUT_FILE with UUID: $UUID"
echo "Generated hash: $HASH"
echo "Hash saved to: $HASH_FILE"
