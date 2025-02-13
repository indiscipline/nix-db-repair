#!/usr/bin/env bash

set -uo pipefail

# Check for root privileges
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

# Check if both arguments are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <database_path> <HASH>"
    exit 1
fi

if ! command -v sqlite3 2>&1 >/dev/null; then
    echo "Error: sqlite3 not in PATH"
    exit 1
fi

if ! command -v sed 2>&1 >/dev/null; then
    echo "Error: sed not in PATH"
    exit 1
fi

# Path to the SQLite database, usually "/nix/var/nix/db/db.sqlite"
DB_PATH="$1"
HASH="$2"

# Check if the provided argument matches the pattern
if [[ ! $HASH =~ ^[0-9a-fg-np-sv-z]{32}$ ]]; then
    echo "Error: Hash is invalid"
    exit 1
fi

# Check if the database file exists
if [ ! -f "$DB_PATH" ]; then
    echo "Error: Database file not found: $DB_PATH"
    exit 1
fi

# Execute SQLite commands
sqlite3 "$DB_PATH" << EOF
-- Start a transaction
BEGIN TRANSACTION;

-- Get ids from ValidPaths
CREATE TEMPORARY TABLE valid_path_ids AS
SELECT id FROM ValidPaths WHERE path LIKE '%$HASH%';

-- Get ids from DerivationOutputs
CREATE TEMPORARY TABLE derivation_output_ids AS
SELECT id FROM DerivationOutputs WHERE path LIKE '%$HASH%';

-- Delete from Refs using ids from ValidPaths
DELETE FROM Refs WHERE referrer IN (SELECT id FROM valid_path_ids);

-- Delete from Refs using ids from DerivationOutputs
DELETE FROM Refs WHERE referrer IN (SELECT id FROM derivation_output_ids);

-- Delete from ValidPaths
DELETE FROM ValidPaths WHERE path LIKE '%$HASH%';

-- Delete from DerivationOutputs
DELETE FROM DerivationOutputs WHERE path LIKE '%$HASH%';

-- Clean up temporary tables
DROP TABLE valid_path_ids;
DROP TABLE derivation_output_ids;

-- Commit the transaction
COMMIT;
EOF

exit_code=$?

if [ $exit_code -ne 0 ]; then
    echo "SQLite error: Failed to update database, exit code $exit_code."
    exit $exit_code
fi

echo "SQLite commands executed successfully."
