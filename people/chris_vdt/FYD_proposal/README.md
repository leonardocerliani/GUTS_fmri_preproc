# JSON UUID and Hash Generator

This project contains two scripts that perform the same task: adding a unique identifier (UUID) to a JSON file and generating a unique hash based on the file's content.

## What These Scripts Do

These scripts take a JSON file (in this case, `sub-01_2022-05-04_000_session.json`) and:

1. Add a unique identifier (UUID) to the file
2. Save this modified file with a new name
3. Create a unique "fingerprint" (hash) of the file
4. Save this fingerprint to a separate text file

### Why This Is Useful

- **Unique Identification**: The UUID ensures each file has a unique identifier, even if other content is identical
- **Content Verification**: The hash acts like a fingerprint - if any part of the file changes, the hash will be completely different
- **Data Integrity**: You can use the hash to verify if a file has been modified or corrupted

## How to Use

### Bash Script (process_json_bash.sh)

1. Make sure the script is executable:
   ```
   chmod +x process_json_bash.sh
   ```

2. Run the script:
   ```
   ./process_json_bash.sh
   ```

3. The script will create:
   - `sub-01_2022-05-04_000_session_bash_uuid.json` (JSON with UUID added)
   - `sub-01_2022-05-04_000_session_bash_uuid_hash.txt` (Hash file)

### Python Script (process_json_python.py)

1. Make sure the script is executable:
   ```
   chmod +x process_json_python.py
   ```

2. Run the script:
   ```
   ./process_json_python.py
   ```

3. The script will create:
   - `sub-01_2022-05-04_000_session_python_uuid.json` (JSON with UUID added)
   - `sub-01_2022-05-04_000_session_python_uuid_hash.txt` (Hash file)

## Requirements

### For the Bash Script
- `jq` (JSON processor)
- `uuidgen` (UUID generator)
- `sha256sum` (Hash generator)
- `awk` (Text processing tool)

### For the Python Script
- Python 3
- Standard Python libraries (json, uuid, hashlib)

---

## Technical Details

### UUID Generation

Both scripts generate a Version 4 UUID, which is a randomly generated UUID. This ensures that each time the script runs, a different UUID is created, making each processed file unique.

### Hash Generation

The scripts use the SHA-256 (Secure Hash Algorithm 256-bit) cryptographic hash function. This algorithm:
- Always produces a 64-character hexadecimal string
- Creates a completely different hash even if only one character in the file changes
- Is deterministic (the same input always produces the same output)
- Is collision-resistant (it's computationally infeasible to find two different inputs that produce the same hash)

### Implementation Details

#### Bash Script
```bash
# Generate UUID
UUID=$(uuidgen)

# Add UUID to JSON using jq
jq --arg uuid "$UUID" '. + {uuid: $uuid}' "$INPUT_FILE" > "$OUTPUT_FILE"

# Generate SHA-256 hash
HASH=$(sha256sum "$OUTPUT_FILE" | awk '{print $1}')
```

#### Python Script
```python
# Generate UUID
data['uuid'] = str(uuid.uuid4()).upper()

# Write modified JSON
with open(OUTPUT_FILE, 'w') as f:
    json.dump(data, f, indent=2)

# Generate SHA-256 hash
with open(OUTPUT_FILE, 'rb') as f:
    file_hash = hashlib.sha256(f.read()).hexdigest()
```

## Bonus: Probability of Two Identical UUIDs?

The chances of `uuidgen` (or any UUID version 4 generator) producing two identical UUIDs are astronomically small, making it practically impossible in real-world scenarios.

A UUID version 4 has 128 bits of randomness, which means there are 2^128 (approximately 3.4 × 10^38) possible unique values. To put this in perspective:

- That's 340 undecillion (10^36) possible unique values
- It's more than the number of stars in the observable universe (estimated at 10^24)
- It's more than the number of grains of sand on Earth (estimated at 10^20)

The probability of generating a duplicate UUID can be estimated using the "birthday paradox" probability:

- After generating 2.7 × 10^19 UUIDs, there's about a 50% chance of finding a single collision
- This means you'd need to generate about 1 billion UUIDs per second for 1 billion years to have a 50% chance of a single duplicate

In practical terms:
- Even in large-scale systems generating millions of UUIDs, the probability of a collision is negligible
- The UUID standard was specifically designed to be used without a central coordination mechanism, allowing distributed systems to generate identifiers independently with virtually no risk of collision

This is why UUIDs are widely used in distributed systems, databases, and any application where globally unique identifiers are needed without centralized coordination.

The SHA-256 hash we're generating adds an additional layer of uniqueness, as it's based on the entire content of the file including the UUID. This means that even in the virtually impossible case of a UUID collision, the hash would still be different if any other part of the file differs.
