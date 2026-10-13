#!/usr/bin/env python3
"""Chart the SQL findings.

Reads the result tables written by scripts/run_sql.py and saves figures to
analysis/figures/. Rebuild the CSVs first if the database has changed:

    .venv/bin/python scripts/run_sql.py
    .venv/bin/python scripts/analyze.py
"""

from __future__ import annotations

import csv
import sys
from pathlib import Path

import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parents[1]
RESULTS = ROOT / "analysis" / "results"
FIGURES = ROOT / "analysis" / "figures"

INK = "#1c2430"
MUTED = "#5c6b7a"
BLUE = "#1f4e79"
RED = "#b23a48"
TEAL = "#1d6a5a"
SAND = "#d8c7a1"
GRID = "#e6e8eb"


def read_csv(name: str) -> list[dict[str, str]]:
    path = RESULTS / name
    if not path.is_file():
        print(f"Missing {path}", file=sys.stderr)
        print("Run scripts/run_sql.py first.", file=sys.stderr)
        raise SystemExit(1)
    with path.open(newline="") as handle:
        return list(csv.DictReader(handle))


def num(value: str) -> float:
    if value is None or value == "":
        return 0.0
    return float(value)


def style_ax(ax: plt.Axes) -> None:
    ax.set_facecolor("white")
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    ax.spines["left"].set_color(GRID)
    ax.spines["bottom"].set_color(GRID)
    ax.tick_params(colors=MUTED, labelsize=10)
    ax.grid(axis="y", color=GRID, linewidth=0.8)
    ax.set_axisbelow(True)


def save(fig: plt.Figure, name: str) -> None:
    FIGURES.mkdir(parents=True, exist_ok=True)
    path = FIGURES / name
    fig.savefig(path, dpi=160, bbox_inches="tight", facecolor="white")
    plt.close(fig)
    print(path.relative_to(ROOT))


def chart_fees(rows: list[dict[str, str]]) -> None:
    labels = ["PumpSwap" if row["venue"] == "pump_swap" else "Bonding curve" for row in rows]
    round_trip = [num(row["approx_round_trip_pct"]) for row in rows]
    fees = [num(row["fees_sol"]) for row in rows]

    fig, ax = plt.subplots(figsize=(8.2, 4.6))
    style_ax(ax)
    bars = ax.bar(labels, round_trip, color=[BLUE, RED], width=0.62)
    ax.set_ylabel("Approximate round-trip fee (%)", color=INK)
    ax.set_title("A bot has to beat this fee before it has an edge", color=INK, loc="left", pad=12)
    for bar, fee, rate in zip(bars, fees, round_trip):
        ax.text(
            bar.get_x() + bar.get_width() / 2,
            bar.get_height() + 0.06,
            f"{rate:.2f}%\n{fee:,.0f} SOL in fees",
            ha="center",
            va="bottom",
            color=INK,
            fontsize=10,
        )
    ax.set_ylim(0, max(round_trip) * 1.35)
    fig.text(0.01, -0.02, "Round trip is twice the average fee rate on SOL-priced trades. Jito tips are extra.", color=MUTED, fontsize=9)
    save(fig, "01_round_trip_fee.png")


def chart_pnl(rows: list[dict[str, str]]) -> None:
    row = rows[0]
    gross = num(row["gross_pnl_sol"])
    fees = -num(row["fees_and_tips_sol"])
    net = num(row["net_pnl_sol"])
    labels = ["Profit before fees", "Venue fees and tips", "Profit after fees"]
    values = [gross, fees, net]
    colors = [RED, RED, RED]

    fig, ax = plt.subplots(figsize=(8.4, 4.8))
    style_ax(ax)
    bars = ax.bar(labels, values, color=colors, width=0.66)
    ax.axhline(0, color=INK, linewidth=0.8)
    ax.set_ylabel("SOL", color=INK)
    ax.set_title("Closed positions lost money, and fees more than doubled the loss", color=INK, loc="left", pad=12)
    for bar, value in zip(bars, values):
        ax.text(
            bar.get_x() + bar.get_width() / 2,
            value - 1800,
            f"{value:,.0f}",
            ha="center",
            va="top",
            color=INK,
            fontsize=11,
        )
    ax.set_ylim(min(values) * 1.18, 4000)
    win_pct = num(row["wallets_in_profit_pct"])
    fig.text(
        0.01,
        -0.04,
        f"1,064,196 closed positions, 261,814 wallets. {win_pct:.1f}% of wallets were profitable after fees.",
        color=MUTED,
        fontsize=9,
    )
    save(fig, "02_closed_position_pnl.png")


def chart_concentration(rows: list[dict[str, str]]) -> None:
    order = {"pump_curve": "Bonding curve", "pump_swap": "PumpSwap"}
    rows = sorted(rows, key=lambda row: 0 if row["venue"] == "pump_curve" else 1)
    labels = [order[row["venue"]] for row in rows]
    top = [num(row["top_1pct_net_sol"]) for row in rows]
    rest = [num(row["everyone_else_net_sol"]) for row in rows]

    fig, axes = plt.subplots(1, 2, figsize=(9.4, 4.8))
    fig.suptitle("The top 1% of wallets took the gains. Everyone else lost.", color=INK, x=0.06, ha="left", fontsize=13)
    for ax, label, top_value, rest_value in zip(axes, labels, top, rest):
        style_ax(ax)
        ax.bar(["Top 1% of wallets", "Everyone else"], [top_value, rest_value], color=[TEAL, RED], width=0.62)
        ax.axhline(0, color=INK, linewidth=0.8)
        ax.set_title(label, color=MUTED, loc="left", fontsize=11)
        for x, value in enumerate((top_value, rest_value)):
            offset = abs(top_value) * 0.06 if value >= 0 else -abs(rest_value) * 0.08
            if offset == 0:
                offset = 800 if value >= 0 else -800
            valign = "bottom" if value >= 0 else "top"
            ax.text(x, value + offset, f"{value:,.0f}", ha="center", va=valign, color=INK, fontsize=10)
        span = max(abs(top_value), abs(rest_value), 1)
        ax.set_ylim(-span * 1.35, span * 1.28)
    axes[0].set_ylabel("Net SOL after fees", color=INK)
    fig.subplots_adjust(wspace=0.35, top=0.82)
    save(fig, "03_profit_concentration.png")


def chart_launches(rows: list[dict[str, str]]) -> None:
    labels = ["Normal launches" if row["launch_type"] == "normal" else "Mayhem launches" for row in rows]
    rates = [num(row["graduation_pct"]) for row in rows]

    fig, ax = plt.subplots(figsize=(8.2, 4.8))
    style_ax(ax)
    bars = ax.bar(labels, rates, color=[BLUE, SAND], width=0.62)
    ax.set_ylabel("Share of launches that graduated (%)", color=INK)
    ax.set_title("Almost every new token dies on the bonding curve", color=INK, loc="left", pad=12)
    for bar, row in zip(bars, rows):
        ax.text(
            bar.get_x() + bar.get_width() / 2,
            bar.get_height() + 0.08,
            f"{num(row['graduation_pct']):.2f}%\n{num(row['graduated']):,.0f} of {num(row['launches']):,.0f}",
            ha="center",
            va="bottom",
            color=INK,
            fontsize=10,
        )
    normal = next(row for row in rows if row["launch_type"] == "normal")
    ax.set_ylim(0, max(rates) * 1.55)
    fig.text(
        0.01,
        -0.02,
        f"{num(normal['instant_graduations']):,.0f} of the {num(normal['graduated']):,.0f} normal graduations happened in the launch block.",
        color=MUTED,
        fontsize=9,
    )
    save(fig, "04_graduation.png")


def chart_early_returns(rows: list[dict[str, str]]) -> None:
    wanted = [row for row in rows if row["setup"] in {"all_early_buys", "scalper_signature"}]
    labels = ["All early buys" if row["setup"] == "all_early_buys" else "Scalper-style buys" for row in wanted]
    ret_24 = [num(row["median_return_24s_pct"]) for row in wanted]
    ret_60 = [num(row["median_return_60s_pct"]) for row in wanted]
    x = range(len(labels))
    width = 0.36

    fig, ax = plt.subplots(figsize=(8.4, 4.8))
    style_ax(ax)
    ax.bar([i - width / 2 for i in x], ret_24, width=width, color=BLUE, label="Median return after 24 seconds")
    ax.bar([i + width / 2 for i in x], ret_60, width=width, color=RED, label="Median return after 60 seconds")
    ax.axhline(2.5, color=TEAL, linestyle="--", linewidth=1.2, label="2.5% round-trip fee to break even")
    ax.axhline(0, color=INK, linewidth=0.8)
    ax.set_xticks(list(x), labels)
    ax.set_ylabel("Price change before fees (%)", color=INK)
    ax.set_title("Early curve buys are down before the bot can pay its fees", color=INK, loc="left", pad=12)
    ax.set_ylim(min(ret_60) * 1.18, 6)
    ax.legend(
        frameon=False,
        labelcolor=INK,
        loc="upper center",
        bbox_to_anchor=(0.5, -0.16),
        ncol=1,
        borderaxespad=0,
    )
    fig.subplots_adjust(bottom=0.28)
    save(fig, "05_early_curve_returns.png")


def chart_drains(rows: list[dict[str, str]]) -> None:
    top = sorted(rows, key=lambda row: num(row["sol_out"]), reverse=True)[:12]
    top.reverse()
    values = [num(row["sol_out"]) for row in top]
    labels = [f"{row['symbol']}   {num(row['sol_out']):,.0f}" for row in top]

    fig, ax = plt.subplots(figsize=(8.6, 5.8))
    style_ax(ax)
    ax.grid(axis="x", color=GRID, linewidth=0.8)
    ax.grid(axis="y", visible=False)
    ax.barh(labels, values, color=RED, height=0.68)
    ax.set_xlabel("SOL sold by wallets dumping about 1% each", color=INK)
    ax.set_title("A few tokens were emptied by coordinated dumps", color=INK, loc="left", pad=14)
    ax.set_xlim(0, max(values) * 1.04)
    save(fig, "06_largest_drains.png")


def main() -> int:
    plt.rcParams.update(
        {
            "font.family": "sans-serif",
            "font.size": 11,
            "text.color": INK,
            "axes.titleweight": "medium",
            "figure.facecolor": "white",
        }
    )
    chart_fees(read_csv("01_fee_by_venue.csv"))
    chart_pnl(read_csv("03_closed_round_trips.csv"))
    chart_concentration(read_csv("05_profit_is_concentrated.csv"))
    chart_launches(read_csv("06_launch_outcomes.csv"))
    chart_early_returns(read_csv("08_early_curve_forward_returns.csv"))
    chart_drains(read_csv("10_largest_drains.csv"))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
