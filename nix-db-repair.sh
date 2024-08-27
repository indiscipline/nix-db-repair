#!/usr/bin/env bash

# Path to the SQLite cleanup script
CLEANUP_SCRIPT="./nix-db-cleanup.sh"
# Path to the Nix store (without trailing slash!)
NIX_STORE_PATH="/nix/store"

# Check if the database path is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <database_path>"
    exit 1
fi

# Path to the SQLite database, usually "/nix/var/nix/db/db.sqlite"
DB_PATH="$1"

# Extract HASH from the error message
# Hash format: `nix32Chars`
# https://github.com/NixOS/nix/blob/master/src/libutil/hash.cc#L80
# Charset: 0123456789abcdfghijklmnpqrsvwxyz; omitted: E O U T
extract_hash() {
    local error_msg="$1"
    local hash=$(echo "$error_msg" | sed -n "s|.*$NIX_STORE_PATH/\([0-9a-fg-np-sv-z]*\)-.*|\1|p")
    echo "$hash"
}

# Main loop
while true; do
    # Run nix-store --gc and capture stderr while discarding stdout
    error_output=$(nix-store --gc 2>&1 >/dev/null)

    # Check if the error output is empty (meaning no errors occurred)
    if [ -z "$error_output" ]; then
        echo "nix-store --gc completed successfully."
        break
    fi

    # Check if the last line of the error output matches the specific error
    last_line=$(echo "$error_output" | tail -n 1)
    if [[ $last_line == "error: executing SQLite statement 'delete from ValidPaths where path = '$NIX_STORE_PATH/"*"';':"* ]]; then
        # Extract the HASH
        hash=$(extract_hash "$last_line")
        if [ -n "$hash" ]; then
            echo "Found problematic HASH: $hash"
            # Run the cleanup script
            if [ -x "$CLEANUP_SCRIPT" ]; then
                echo "Running cleanup script for $hash"
                "$CLEANUP_SCRIPT" "$DB_PATH" "$hash"
            else
                echo "Error: Cleanup script not found or not executable: $CLEANUP_SCRIPT"
                exit 1
            fi
        else
            echo "Failed to extract HASH from error message"
            exit 1
        fi
    else
        echo "Unexpected error occurred:"
        echo "$error_output"
        exit 1
    fi
done

echo "All 'nix-store --gc' operations completed."
