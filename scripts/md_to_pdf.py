#!/usr/bin/env python3
"""Convert docs/search_logic_ru.md to PDF (requires fpdf2 + system TTF with Cyrillic)."""
from __future__ import annotations

import re
import sys
import textwrap
from pathlib import Path

from fpdf import FPDF

ROOT = Path(__file__).resolve().parents[1]
MD_PATH = ROOT / "docs" / "search_logic_ru.md"
PDF_PATH = ROOT / "docs" / "search_logic_ru.pdf"

FONT_CANDIDATES = [
    "/System/Library/Fonts/Supplemental/Arial Unicode.ttf",
    "/System/Library/Fonts/Supplemental/Arial.ttf",
    "/Library/Fonts/Arial Unicode.ttf",
]


def find_font() -> str:
    for path in FONT_CANDIDATES:
        if Path(path).exists():
            return path
    raise SystemExit("Cyrillic TTF font not found")


def sanitize(line: str) -> str:
    line = line.replace("→", "->").replace("—", "-").replace("–", "-")
    line = line.replace("☐", "[ ]").replace("•", "-")
    line = re.sub(r"[^\S\n\t\x20-\x7E\u0400-\u04FF]", " ", line)
    return line.strip()


def wrap_line(line: str, width: int = 95) -> list[str]:
    if len(line) <= width:
        return [line] if line else []
    return textwrap.wrap(line, width=width, break_long_words=True, break_on_hyphens=False)


class DocPDF(FPDF):
    def footer(self):
        self.set_y(-12)
        self.set_font("DocFont", size=8)
        self.set_text_color(120, 120, 120)
        self.cell(
            0,
            8,
            f"CRG Transp 72 | Логика поиска услуг | стр. {self.page_no()}",
            align="C",
        )


def write_lines(pdf: DocPDF, lines: list[str], size: float, bold: bool = False) -> None:
    pdf.set_font("DocFont", "B" if bold else "", size)
    pdf.set_text_color(30, 30, 30)
    line_h = max(4.5, size * 0.45)
    for part in lines:
        for wrapped in wrap_line(part):
            if pdf.get_y() > pdf.h - pdf.b_margin - line_h:
                pdf.add_page()
            pdf.multi_cell(pdf.epw, line_h, wrapped)
        pdf.ln(0.2)


def main() -> None:
    md_path = Path(sys.argv[1]) if len(sys.argv) > 1 else MD_PATH
    pdf_path = Path(sys.argv[2]) if len(sys.argv) > 2 else PDF_PATH

    text = md_path.read_text(encoding="utf-8")
    font_path = find_font()

    pdf = DocPDF(orientation="P", unit="mm", format="A4")
    pdf.set_auto_page_break(auto=True, margin=18)
    pdf.add_font("DocFont", "", font_path)
    pdf.add_font("DocFont", "B", font_path)
    pdf.add_page()
    pdf.set_margins(18, 18, 18)

    in_code = False
    for raw_line in text.splitlines():
        line = sanitize(raw_line)
        if line.startswith("```"):
            in_code = not in_code
            continue

        if in_code:
            pdf.set_font("DocFont", size=8)
            pdf.set_text_color(40, 40, 40)
            pdf.set_fill_color(245, 245, 245)
            for wrapped in wrap_line(line, width=100) or [""]:
                if pdf.get_y() > pdf.h - pdf.b_margin - 5:
                    pdf.add_page()
                pdf.multi_cell(pdf.epw, 4.2, wrapped, fill=True)
            continue

        if line.startswith("# "):
            pdf.ln(3)
            if pdf.get_y() > pdf.h - pdf.b_margin - 12:
                pdf.add_page()
            pdf.set_font("DocFont", "B", 16)
            pdf.set_text_color(20, 60, 120)
            pdf.multi_cell(pdf.epw, 8, line[2:].strip())
            pdf.ln(1)
        elif line.startswith("## "):
            pdf.ln(2)
            if pdf.get_y() > pdf.h - pdf.b_margin - 10:
                pdf.add_page()
            pdf.set_font("DocFont", "B", 13)
            pdf.set_text_color(30, 80, 140)
            pdf.multi_cell(pdf.epw, 7, line[3:].strip())
            pdf.ln(0.5)
        elif line.startswith("### "):
            pdf.ln(1.5)
            if pdf.get_y() > pdf.h - pdf.b_margin - 8:
                pdf.add_page()
            pdf.set_font("DocFont", "B", 11)
            pdf.set_text_color(50, 50, 50)
            pdf.multi_cell(pdf.epw, 6, line[4:].strip())
            pdf.ln(0.3)
        elif line.startswith("---"):
            pdf.ln(2)
            y = pdf.get_y()
            pdf.set_draw_color(200, 200, 200)
            pdf.line(18, y, 192, y)
            pdf.ln(3)
        elif line.startswith("|") and "|" in line[1:]:
            cells = [c.strip() for c in line.strip("|").split("|")]
            if all(set(c) <= set("-:") for c in cells):
                continue
            write_lines(pdf, ["  |  ".join(cells)], 9)
        elif line.startswith("- [ ]") or line.startswith("- "):
            write_lines(pdf, [line], 10)
        elif line == "":
            pdf.ln(2)
        else:
            clean = re.sub(r"\*\*(.+?)\*\*", r"\1", line)
            clean = re.sub(r"`(.+?)`", r"\1", clean)
            write_lines(pdf, [clean], 10)

    pdf.output(str(pdf_path))
    print(f"Created {pdf_path} ({pdf_path.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
