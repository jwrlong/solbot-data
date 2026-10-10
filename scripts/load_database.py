#!/usr/bin/env python3
"""Load the Parquet tables in data/ into a local DuckDB database.

The database file is gitignored. Place the Parquet files in data/, then run:

    python3 scripts/load_database.py
"""

from __future__ import annotations

import sys
from pathlib import Path

import duckdb

ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "data"
DB_PATH = ROOT / "db" / "solbot.duckdb"

# Row counts from the dataset README. A mismatch means a table is incomplete.
EXPECTED_ROWS = {
    "trades": 15_508_459,
    "launches": 30_901,
    "graduations": 777,
    "pools": 2_636,
    "liquidity": 2_209,
    "sol_transfers": 37_043,
    "wallets": 35_822,
    "slots": 208_261,
    "wallet_positions": 3_083_140,
    "early_curve_buys": 668_412,
}


def main() -> int:
    missing = [name for name in EXPECTED_ROWS if not (DATA_DIR / f"{name}.parquet").is_file()]
    if missing:
        print("Missing Parquet files in data/:", ", ".join(missing), file=sys.stderr)
        return 1

    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    if DB_PATH.exists():
        DB_PATH.unlink()
    wal = DB_PATH.with_suffix(".duckdb.wal")
    if wal.exists():
        wal.unlink()

    con = duckdb.connect(str(DB_PATH))
    try:
        for name in EXPECTED_ROWS:
            path = DATA_DIR / f"{name}.parquet"
            print(f"loading {name}...", file=sys.stderr)
            con.execute(
                f"CREATE TABLE {name} AS SELECT * FROM read_parquet(?)",
                [str(path)],
            )
            rows = con.execute(f"SELECT count(*) FROM {name}").fetchone()[0]
            expected = EXPECTED_ROWS[name]
            if rows != expected:
                print(
                    f"{name}: loaded {rows:,} rows, expected {expected:,}",
                    file=sys.stderr,
                )
                return 1
            print(f"  {name}: {rows:,} rows", file=sys.stderr)
    finally:
        con.close()

    print(f"database: {DB_PATH}")
    print(f"tables: {len(EXPECTED_ROWS)}")
    print(f"rows: {sum(EXPECTED_ROWS.values()):,}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
