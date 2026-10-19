"""Builds the static fonts Tonic needs into Tonic/Media/Fonts.

WoW loads one file per weight, cannot use variable axes and cannot enable OpenType
features, so this script:
  1. downloads the variable fonts from Google's repositories (SIL OFL 1.1),
  2. instances them (Roboto Serif 400/600, Roboto Flex 400/500, Material Symbols Rounded),
  3. bakes tabular digits into the "-Tnum" Roboto Flex files (cmap remapped through GSUB tnum),
  4. subsets Material Symbols to the codepoints Tonic uses.

Usage:  pip install fonttools  &&  python tools/fonts/build-fonts.py
"""

import argparse
import io
import sys
import urllib.request
from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "Tonic" / "Media" / "Fonts"

GOOGLE = "https://raw.githubusercontent.com/google/fonts/main/ofl/"
SOURCES = {
    "serif": GOOGLE + "robotoserif/RobotoSerif%5BGRAD,opsz,wdth,wght%5D.ttf",
    "flex": GOOGLE + "robotoflex/RobotoFlex%5BGRAD,XOPQ,XTRA,YOPQ,YTAS,YTDE,YTFI,YTLC,YTUC,opsz,slnt,wdth,wght%5D.ttf",
    "symbols": "https://raw.githubusercontent.com/google/material-design-icons/master/variablefont/"
               "MaterialSymbolsRounded%5BFILL,GRAD,opsz,wght%5D.ttf",
    "license": GOOGLE + "robotoflex/OFL.txt",
}

# Codepoints of Tonic/Primitives/Icon.lua (keep in sync).
SYMBOLS = [
    0xE145, 0xE15B, 0xE5CD, 0xE5CA, 0xE5CB, 0xE5CC, 0xE5CF, 0xE5CE, 0xE5C4, 0xE5D2, 0xE5D4, 0xE8B6,
    0xE518, 0xE51C, 0xE88E, 0xE002, 0xE8B8, 0xE40A, 0xE429, 0xE7FD, 0xE838, 0xE87D, 0xE872, 0xE3C9,
    0xE5D5, 0xE88A, 0xE8F4, 0xE14D,
]


def download(url: str) -> bytes:
    print("download", url.split("/")[-1].replace("%5B", "[").replace("%5D", "]"))
    with urllib.request.urlopen(url) as response:
        return response.read()


def instance(data: bytes, axes: dict) -> TTFont:
    font = TTFont(io.BytesIO(data))
    supported = {tag: value for tag, value in axes.items() if tag in [a.axisTag for a in font["fvar"].axes]}
    return instancer.instantiateVariableFont(font, supported, updateFontNames=True)


def freeze_tnum(font: TTFont) -> None:
    """Points the cmap of the digits to their tabular alternates (GSUB 'tnum')."""
    gsub = font["GSUB"].table
    lookups = set()
    for record in gsub.FeatureList.FeatureRecord:
        if record.FeatureTag == "tnum":
            lookups.update(record.Feature.LookupListIndex)
    mapping = {}
    for index in lookups:
        for sub in gsub.LookupList.Lookup[index].SubTable:
            sub = getattr(sub, "ExtSubTable", sub)
            mapping.update(getattr(sub, "mapping", {}) or {})
    if not mapping:
        print("  warning: no tnum substitutions found")
        return
    for table in font["cmap"].tables:
        for code, glyph in list(table.cmap.items()):
            if glyph in mapping:
                table.cmap[code] = mapping[glyph]


def save(font: TTFont, name: str) -> None:
    path = OUT / name
    font.save(path)
    print("  wrote", path.relative_to(ROOT), f"{path.stat().st_size // 1024} KB")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)

    serif = download(SOURCES["serif"])
    save(instance(serif, {"wght": 400, "opsz": 24, "wdth": 100, "GRAD": 0}), "RobotoSerif-Regular.ttf")
    save(instance(serif, {"wght": 600, "opsz": 24, "wdth": 100, "GRAD": 0}), "RobotoSerif-SemiBold.ttf")

    flex = download(SOURCES["flex"])
    for weight, name in ((400, "Regular"), (500, "Medium")):
        axes = {"wght": weight, "opsz": 14, "wdth": 100, "slnt": 0, "GRAD": 0}
        save(instance(flex, axes), f"RobotoFlex-{name}.ttf")
        tnum = instance(flex, axes)
        freeze_tnum(tnum)
        save(tnum, f"RobotoFlex-{name}-Tnum.ttf")

    symbols = instance(download(SOURCES["symbols"]), {"FILL": 0, "GRAD": 0, "opsz": 24, "wght": 400})
    options = subset.Options()
    options.layout_features = []
    subsetter = subset.Subsetter(options)
    subsetter.populate(unicodes=SYMBOLS)
    subsetter.subset(symbols)
    save(symbols, "MaterialSymbolsRounded.ttf")

    (OUT / "OFL.txt").write_bytes(download(SOURCES["license"]))
    print("done")
    return 0


if __name__ == "__main__":
    sys.exit(main())
