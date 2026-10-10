#!/usr/bin/env python3
"""Run the SQL in sql/ and write one CSV per query to analysis/results/.

The database is local and gitignored. Build it first with load_database.py.

    PYTHONPATH=.vendor python3 scripts/run_analysis.py
"""

from __future__ import annotations

import csv
import sys
from pathlib import Path

import duckdb

ROOT = Path(__file__).resolve().parents[1]
DB_PATH = ROOT / "db" / "solbot.duckdb"
SQL_DIR = ROOT / "sql"
OUT_DIR = ROOT / "analysis" / "results"


def main() -> int:
    if not DB_PATH.is_file():
        print(f"Database not found: {DB_PATH}", file=sys.stderr)
        print("Run scripts/load_database.py first.", file=sys.stderr)
        return 1

    queries = sorted(SQL_DIR.glob("*.sql"))
    if not queries:
        print(f"No SQL files in {SQL_DIR}", file=sys.stderr)
        return 1

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    con = duckdb.connect(str(DB_PATH), read_only=True)
    try:
        for path in queries:
            sql = path.read_text()
            cursor = con.execute(sql)
            rows = cursor.fetchall()
            columns = [desc[0] for desc in cursor.description]
            out_path = OUT_DIR / f"{path.stem}.csv"
            with out_path.open("w", newline="") as handle:
                writer = csv.writer(handle)
                writer.writerow(columns)
                writer.writerows(rows)
            print(f"{path.name}: {len(rows)} rows -> {out_path.relative_to(ROOT)}")
    finally:
        con.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
