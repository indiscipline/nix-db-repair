# nix-db-repair

> error: executing SQLite statement 'delete from ValidPaths where path = '/nix/store/0ab7xhlvwpyl01xp9m19ddij9rsvw0cy-hello-1.0.0.drv';':  constraint failed (in '/nix/var/nix/db/db.sqlite')

[#2218](https://github.com/NixOS/nix/issues/2218). It happened. Even though the issue's closed. You gotta fix it and reinstalling from the config is not an option.

You run `nix-store --gc`, and get the error. Easy fix, you enter `nix-shell -p sqlite` and follow the [steps](https://github.com/NixOS/nix/issues/2218#issuecomment-1209591321). You restart the GC and get the same error for another derivation... Maybe *this* will be the last one! After a while you start questioning if you chose the right career/hobby.

## Usage

Make sure `bash`, `sqlite3` and `sed` are accessibly from your environment.

`DB_PATH` is usually `/nix/car/nix/db/db.sqlite`

> [!WARNING]
> Make a backup of your database first!
> `sqlite3 DB_PATH ".backup 'nix-store-db.sqlite'"`

### nix-db-cleanup.sh

Perform database fixing operations for a single hash:

```# ./nix-db-cleanup.sh <DB_PATH> <HASH>```

### nix-db-repair.sh

Repair all `ValidPaths` errors iteratively:

```# ./nix-db-repair.sh <DB_PATH>```

This repeatedly runs the `nix-store --gc` command by default and invokes `nix-db-cleanup.sh` on errors. Change the nix command at line #21 to an operation giving you the trouble.

## Disclaimer

Shellcheck is ok with this, but think for yourself. No guarantees!

## License

nix-db-repair licensed under GNU General Public License version 3.0 or later
