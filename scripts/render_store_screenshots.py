#!/usr/bin/env python3
"""Генерация PNG для App Store / Google Play без debug banner."""

from __future__ import annotations

import json
import os
import subprocess
import textwrap
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RAW_IPHONE = ROOT / "store_assets/screenshots/_raw/iphone"
RAW_IPAD = ROOT / "store_assets/screenshots/_raw/ipad"
PLACEHOLDER = ROOT / "test/fixtures/placeholder.png"
FONT = "/System/Library/Fonts/Supplemental/Arial.ttf"
FONT_BOLD = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"

BLUE = "#4D5EFF"
VIOLET = "#4600CD"
WHITE = "#FFFFFF"
TEXT = "#323232"
GREEN = "#649D5A"
LIGHT = "#F4F6FF"
BORDER = "#E3E6F5"


def magick(args: list[str]) -> None:
    cmd = ["magick", *args]
    subprocess.run(cmd, check=True)


def draw_screen(
    out: Path,
    width: int,
    height: int,
    title: str,
    hero: str,
    tabs: list[str],
    active_tab: int,
    body_type: str,
) -> None:
    out.parent.mkdir(parents=True, exist_ok=True)
    tmp = out.with_suffix(".tmp.png")

    magick(
        [
            "-size",
            f"{width}x{height}",
            f"xc:{WHITE}",
            "-fill",
            BLUE,
            "-draw",
            f"rectangle 0,0 {width},180",
            "-fill",
            WHITE,
            "-font",
            FONT_BOLD,
            "-pointsize",
            "52",
            "-annotate",
            f"+60+58",
            title,
            "-fill",
            BLUE,
            "-draw",
            f"roundrectangle 48,220 {width - 48},430 36,36",
            "-fill",
            WHITE,
            "-font",
            FONT_BOLD,
            "-pointsize",
            "42",
            "-annotate",
            "+90+290",
            textwrap.fill(hero, width=24),
            tmp.as_posix(),
        ]
    )

    if body_type == "catalog":
        cols = 3 if width >= 1800 else 2
        card_w = (width - 48 * 2 - 24 * (cols - 1)) // cols
        card_h = int(card_w * 0.95)
        y = 470
        labels = [
            "Мини-погрузчики",
            "Экскаваторы",
            "Грузоперевозки",
            "Грузчики",
            "Манипуляторы",
            "Самосвалы",
        ]
        for i, label in enumerate(labels[: cols * 2]):
            row = i // cols
            col = i % cols
            x = 48 + col * (card_w + 24)
            cy = y + row * (card_h + 24)
            card = out.with_suffix(f".card{i}.png")
            magick(
                [
                    "-size",
                    f"{card_w}x{card_h}",
                    f"xc:{WHITE}",
                    "(",
                    PLACEHOLDER.as_posix(),
                    "-resize",
                    f"{card_w - 24}x{int(card_h * 0.62)}",
                    ")",
                    "-gravity",
                    "north",
                    "-geometry",
                    f"+0+12",
                    "-composite",
                    "-fill",
                    TEXT,
                    "-font",
                    FONT_BOLD,
                    "-pointsize",
                    "28",
                    "-gravity",
                    "south",
                    "-annotate",
                    f"+0+24",
                    label,
                    card.as_posix(),
                ]
            )
            magick(
                [
                    tmp.as_posix(),
                    "(",
                    card.as_posix(),
                    ")",
                    "-geometry",
                    f"+{x}+{cy}",
                    "-composite",
                    tmp.as_posix(),
                ]
            )
            card.unlink(missing_ok=True)
    else:
        fields = [
            ("Город", "Тюмень"),
            ("Услуга", "Мини-погрузчики"),
            ("Бюджет", "до 5 000 ₽"),
        ]
        magick(
            [
                tmp.as_posix(),
                "-fill",
                LIGHT,
                "-draw",
                f"roundrectangle 48,470 {width - 48},760 28,28",
                tmp.as_posix(),
            ]
        )
        fy = 520
        for label, value in fields:
            magick(
                [
                    tmp.as_posix(),
                    "-fill",
                    "#666666",
                    "-font",
                    FONT_BOLD,
                    "-pointsize",
                    "28",
                    "-annotate",
                    f"+90+{fy}",
                    label,
                    "-fill",
                    WHITE,
                    "-draw",
                    f"roundrectangle 250,{fy - 10} {width - 90},{fy + 54} 18,18",
                    "-fill",
                    TEXT,
                    "-font",
                    FONT,
                    "-pointsize",
                    "32",
                    "-annotate",
                    f"+280+{fy + 8}",
                    value,
                    tmp.as_posix(),
                ]
            )
            fy += 84

        offers = [
            ("Мини-погрузчик Bobcat", "Тюмень • сегодня • 4 500 ₽", "Быстрый выезд"),
            ("Грузчики 2–4 человека", "Винзили • сегодня • от 600 ₽/час", "Проверенный исполнитель"),
            ("Манипулятор 5 тонн", "Тюмень • завтра • 8 000 ₽", "Фото техники"),
        ]
        oy = 820
        for title_text, subtitle, badge in offers:
            magick(
                [
                    tmp.as_posix(),
                    "-fill",
                    WHITE,
                    "-stroke",
                    BORDER,
                    "-strokewidth",
                    "2",
                    "-draw",
                    f"roundrectangle 48,{oy} {width - 48},{oy + 180} 24,24",
                    "-fill",
                    TEXT,
                    "-font",
                    FONT_BOLD,
                    "-pointsize",
                    "34",
                    "-annotate",
                    f"+90+{oy + 36}",
                    title_text,
                    "-fill",
                    "#666666",
                    "-font",
                    FONT,
                    "-pointsize",
                    "28",
                    "-annotate",
                    f"+90+{oy + 88}",
                    subtitle,
                    "-fill",
                    GREEN,
                    "-font",
                    FONT_BOLD,
                    "-pointsize",
                    "24",
                    "-annotate",
                    f"+90+{oy + 132}",
                    badge,
                    tmp.as_posix(),
                ]
            )
            oy += 200

    nav_y = height - 140
    tab_w = width // len(tabs)
    for i, tab in enumerate(tabs):
        color = VIOLET if i == active_tab else "#9AA0B5"
        magick(
            [
                tmp.as_posix(),
                "-fill",
                color,
                "-font",
                FONT_BOLD,
                "-pointsize",
                "28",
                "-annotate",
                f"+{48 + i * tab_w}+{nav_y + 70}",
                tab,
                tmp.as_posix(),
            ]
        )

    magick(
        [
            tmp.as_posix(),
            "-fill",
            "#ECEEF8",
            "-draw",
            f"rectangle 0,{height - 150} {width},{height}",
            tmp.as_posix(),
        ]
    )
    tmp.replace(out)


def main() -> None:
    screens = [
        ("01_customer_services", "Услуги", "Техника, перевозки и грузчики в одном приложении", ["Услуги", "Заказы", "Профиль"], 0, "catalog"),
        ("02_customer_search", "Заказы", "Найдите исполнителя в Тюмени за пару касаний", ["Услуги", "Заказы", "Профиль"], 1, "search"),
        ("03_performer_listings", "Услуги", "Размещайте объявления и получайте заявки", ["Объявления", "Заявки", "Профиль"], 0, "catalog"),
        ("04_performer_search", "Заявки", "Смотрите актуальные заказы без посредников", ["Объявления", "Заявки", "Профиль"], 1, "search"),
    ]

    for name, title, hero, tabs, active, body in screens:
        draw_screen(RAW_IPHONE / f"{name}.png", 1320, 2868, title, hero, tabs, active, body)

    draw_screen(
        RAW_IPAD / "01_customer_services.png",
        2048,
        2732,
        "Услуги",
        "Техника, перевозки и грузчики в одном приложении",
        ["Услуги", "Заказы", "Профиль"],
        0,
        "catalog",
    )
    draw_screen(
        RAW_IPAD / "03_performer_listings.png",
        2048,
        2732,
        "Заявки",
        "Смотрите актуальные заказы без посредников",
        ["Объявления", "Заявки", "Профиль"],
        1,
        "search",
    )

    print(json.dumps({"generated": len(screens) + 2, "iphone_dir": str(RAW_IPHONE)}, ensure_ascii=False))


if __name__ == "__main__":
    main()
