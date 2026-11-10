#!/usr/bin/env python3

import os
import sys
from pathlib import Path

from PIL import Image


def load(path: Path) -> Image.Image:
    image = Image.open(path)
    image.load()
    if image.width <= 0 or image.height <= 0:
        raise ValueError(f"PNG 크기가 올바르지 않습니다: {path}")
    return image


def has_alpha(image: Image.Image) -> bool:
    return image.mode in {"LA", "PA", "RGBA"} or "transparency" in image.info


def inspect(path: Path) -> None:
    with load(path) as image:
        alpha = "yes" if has_alpha(image) else "no"
        print(f"{image.width} {image.height} {alpha}")


def flatten(source_path: Path, output_path: Path) -> None:
    with load(source_path) as source:
        if has_alpha(source):
            rgba = source.convert("RGBA")
            destination = Image.new("RGB", rgba.size, "white")
            destination.paste(rgba, mask=rgba.getchannel("A"))
        else:
            destination = source.convert("RGB")

        temporary_path = output_path.with_name(f"{output_path.name}.writing")
        destination.save(temporary_path, format="PNG")
        with load(temporary_path) as verification:
            if has_alpha(verification):
                raise ValueError(f"RGB PNG 변환에 실패했습니다: {output_path}")
        os.replace(temporary_path, output_path)


def main() -> None:
    arguments = sys.argv[1:]
    if len(arguments) == 2 and arguments[0] == "inspect":
        inspect(Path(arguments[1]))
        return
    if len(arguments) == 3 and arguments[0] == "flatten":
        flatten(Path(arguments[1]), Path(arguments[2]))
        return
    raise SystemExit(
        "usage: png_tool.py inspect <input> | png_tool.py flatten <input> <output>"
    )


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        raise SystemExit(str(error)) from error
