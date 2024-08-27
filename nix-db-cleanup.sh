#!/usr/bin/env bash

# Check if both arguments are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <database_path> <HASH>"
    exit 1
fi

# Path to the SQLite database, usually "/nix/var/nix/db/db.sqlite"
DB_PATH="$1"
HASH="$2"

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

echo "SQLite commands executed successfully."
