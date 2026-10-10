#!/usr/bin/env python3
"""Run the SQL files in sql/ and write a small CSV for each one."""

from __future__ import annotations

import csv
import sys
from pathlib import Path

import duckdb

ROOT = Path(__file__).resolve().parents[1]
SQL_DIR = ROOT / "sql"
OUT_DIR = ROOT / "analysis" / "results"
DB_PATH = ROOT / "db" / "solbot.duckdb"


def main() -> int:
    if not DB_PATH.is_file():
        print(f"Database not found: {DB_PATH}", file=sys.stderr)
        print("Run: .venv/bin/python scripts/load_database.py", file=sys.stderr)
        return 1

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    con = duckdb.connect(str(DB_PATH), read_only=True)
    try:
        for path in sorted(SQL_DIR.glob("*.sql")):
            sql = path.read_text()
            cursor = con.execute(sql)
            columns = [item[0] for item in cursor.description]
            rows = cursor.fetchall()
            out_path = OUT_DIR / f"{path.stem}.csv"
            with out_path.open("w", newline="") as handle:
                writer = csv.writer(handle)
                writer.writerow(columns)
                writer.writerows(rows)
            print(f"\n{path.name}")
            print(" | ".join(columns))
            for row in rows:
                print(" | ".join("" if value is None else str(value) for value in row))
            print(f"wrote {out_path.relative_to(ROOT)}")
    finally:
        con.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
