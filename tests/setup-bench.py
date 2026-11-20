#!/usr/bin/env python3
"""Create a disposable multi-step benchmark fixture for antigravity-swarm-router."""

import argparse
from pathlib import Path


def build_pricing_service() -> str:
    lines = ['"""Pricing and catalog utilities."""', ""]
    for i in range(1, 31):
        lines.extend(
            [
                f"def helper_tier_{i}(value: float) -> float:",
                f'    """Helper tier {i}."""',
                "    return round(value * 1.0, 2)",
                "",
            ]
        )
    lines.extend(
        [
            "def apply_discount(price: float, discount_pct: float) -> float:",
            '    """Apply percentage discount (0-100) to price."""',
            "    if discount_pct < 0 or discount_pct > 100:",
            '        raise ValueError("discount_pct must be between 0 and 100")',
            "    # BUG: divides discount_pct by 10 instead of 100",
            "    discount_amount = price * (discount_pct / 10.0)",
            "    return round(price - discount_amount, 2)",
        ]
    )
    for j in range(1, 5):
        lines.extend(["", f"def footer_util_{j}(x: int) -> int:", f"    return x + {j}"])
    return "\n".join(lines) + "\n"


TEST_PRICING = '''import unittest
from pricing_service import apply_discount, helper_tier_1


class TestPricing(unittest.TestCase):
    def test_helpers(self):
        for i in range(40):
            print(f"[INFO] helper smoke case #{i}: ok")
        self.assertEqual(helper_tier_1(10.0), 10.0)

    def test_discount_20_percent(self):
        self.assertEqual(apply_discount(100.0, 20.0), 80.0)


if __name__ == "__main__":
    unittest.main(verbosity=2)
'''

BOARD_MD = """# Sprint Board

| ID | Task | Status | Owner |
| :--- | :--- | :--- | :--- |
| T-1 | Fix apply_discount percentage bug | TODO | team |
| T-2 | Keep docs synced | TODO | team |
"""


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate Swarm Router benchmark fixture.")
    parser.add_argument("target_dir", nargs="?", default="./bench-tmp", help="Output directory")
    args = parser.parse_args()

    out = Path(args.target_dir).resolve()
    out.mkdir(parents=True, exist_ok=True)
    (out / "pricing_service.py").write_text(build_pricing_service(), encoding="utf-8")
    (out / "test_pricing.py").write_text(TEST_PRICING, encoding="utf-8")
    (out / "BOARD.md").write_text(BOARD_MD, encoding="utf-8")
    print(f"[OK] Benchmark fixture created at: {out}")


if __name__ == "__main__":
    main()
