#!/usr/bin/env python3
import json
import uuid
import hashlib
import os

# Input and output file paths
INPUT_FILE = "sub-01_2022-05-04_000_session.json"
OUTPUT_FILE = "sub-01_2022-05-04_000_session_python_uuid.json"
HASH_FILE = OUTPUT_FILE.replace(".json", "_hash.txt")

def main():
    # Read the input JSON file
    with open(INPUT_FILE, 'r') as f:
        data = json.load(f)
    
    # Generate UUID and add it to the JSON
    data['uuid'] = str(uuid.uuid4()).upper()
    
    # Write the modified JSON to the output file
    with open(OUTPUT_FILE, 'w') as f:
        json.dump(data, f, indent=2)
    
    # Generate SHA-256 hash of the new JSON file
    with open(OUTPUT_FILE, 'rb') as f:
        file_hash = hashlib.sha256(f.read()).hexdigest()
    
    # Save hash to file
    with open(HASH_FILE, 'w') as f:
        f.write(file_hash)
    
    print(f"Created {OUTPUT_FILE} with UUID: {data['uuid']}")
    print(f"Generated hash: {file_hash}")
    print(f"Hash saved to: {HASH_FILE}")

if __name__ == "__main__":
    main()
