#!/usr/bin/env python3

import json
import os
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
TEMPLATE_PATH = ROOT / "store_assets/promotional/template.json"
FONT_CANDIDATES = (
    Path("/System/Library/Fonts/AppleSDGothicNeo.ttc"),
    Path("/System/Library/Fonts/Supplemental/AppleGothic.ttf"),
)


def font_path() -> Path:
    for candidate in FONT_CANDIDATES:
        if candidate.exists():
            return candidate
    raise FileNotFoundError("한국어 시스템 글꼴을 찾지 못했습니다.")


def load_font(size: int, collection_index: int) -> ImageFont.FreeTypeFont:
    path = font_path()
    index = collection_index if path.suffix.lower() in {".ttc", ".otc"} else 0
    return ImageFont.truetype(str(path), size=size, index=index)


def fit_font(draw: ImageDraw.ImageDraw, text: str, width: int, initial: int) -> ImageFont.FreeTypeFont:
    size = initial
    while size >= 24:
        font = load_font(size=size, collection_index=9)
        box = draw.textbbox((0, 0), text, font=font)
        if box[2] - box[0] <= width:
            return font
        size -= 2
    raise ValueError(f"카피가 안전 영역에 맞지 않습니다: {text}")


def rounded_screenshot(source: Image.Image, size: tuple[int, int], radius: int) -> Image.Image:
    resized = source.resize(size, Image.Resampling.LANCZOS).convert("RGBA")
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size[0], size[1]), radius=radius, fill=255)
    resized.putalpha(mask)
    return resized


def compose(source_path: Path, destination: Path, target: dict, screen: dict, template: dict) -> None:
    width, height = target["width"], target["height"]
    with Image.open(source_path) as opened:
        source = opened.convert("RGB")
    if source.size != (width, height):
        raise ValueError(f"원본 크기 오류: {source_path} ({source.width}x{source.height})")

    canvas = Image.new("RGB", (width, height), template["background"])
    draw = ImageDraw.Draw(canvas)
    horizontal = round(width * 0.072)
    header_height = round(height * 0.18)
    step_font = load_font(size=max(28, round(width * 0.034)), collection_index=7)
    headline_font = fit_font(draw, screen["headline"], width - 2 * horizontal, max(52, round(width * 0.059)))
    draw.text((horizontal, round(header_height * 0.25)), screen["step"], fill=template["stepColor"], font=step_font)
    draw.text((horizontal, round(header_height * 0.49)), screen["headline"], fill=template["headlineColor"], font=headline_font)
    headline_box = draw.textbbox(
        (horizontal, round(header_height * 0.49)),
        screen["headline"],
        font=headline_font,
    )
    if headline_box[3] > round(height * 0.2):
        raise ValueError(f"카피가 Google Play 권고 영역 20%를 넘습니다: {screen['headline']}")

    card_width = width - 2 * horizontal
    card_height = height - header_height + round(height * 0.035)
    scale = min(card_width / width, card_height / height)
    shot_size = (round(width * scale), round(height * scale))
    shot_x = (width - shot_size[0]) // 2
    shot_y = height - shot_size[1]
    radius = max(24, round(width * 0.025))
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        (shot_x, shot_y, shot_x + shot_size[0], shot_y + shot_size[1]),
        radius=radius,
        fill=(28, 25, 76, 58),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(max(10, round(width * 0.014))))
    canvas = Image.alpha_composite(canvas.convert("RGBA"), shadow)
    canvas.alpha_composite(rounded_screenshot(source, shot_size, radius), (shot_x, shot_y))

    destination.parent.mkdir(parents=True, exist_ok=True)
    temporary = destination.with_suffix(".writing.png")
    canvas.convert("RGB").save(temporary, format="PNG", optimize=True)
    os.replace(temporary, destination)


def contact_sheet(paths: list[Path], destination: Path, label: str) -> None:
    thumbs = []
    for path in paths:
        with Image.open(path) as image:
            thumb_width = 360
            thumb_height = round(image.height * thumb_width / image.width)
            thumbs.append(image.convert("RGB").resize((thumb_width, thumb_height), Image.Resampling.LANCZOS))
    gap, title_height = 32, 92
    sheet = Image.new("RGB", (gap * 5 + 360 * 4, title_height + max(i.height for i in thumbs) + gap), "#ECECF4")
    draw = ImageDraw.Draw(sheet)
    draw.text((gap, 26), label, fill="#24224A", font=ImageFont.truetype(str(font_path()), size=34, index=9))
    for index, image in enumerate(thumbs):
        sheet.paste(image, (gap + index * (360 + gap), title_height))
    destination.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(destination, format="PNG", optimize=True)


def qa_contact_sheet(default_paths: list[Path], large_paths: list[Path], destination: Path, label: str) -> None:
    rows = []
    for paths in (default_paths, large_paths):
        thumbs = []
        for path in paths:
            with Image.open(path) as image:
                thumb_width = 300
                thumb_height = round(image.height * thumb_width / image.width)
                thumbs.append(image.convert("RGB").resize((thumb_width, thumb_height), Image.Resampling.LANCZOS))
        rows.append(thumbs)
    gap, title_height, row_label_width = 28, 88, 132
    row_height = max(image.height for row in rows for image in row)
    sheet = Image.new(
        "RGB",
        (row_label_width + gap * 5 + 300 * 4, title_height + row_height * 2 + gap * 2),
        "#ECECF4",
    )
    draw = ImageDraw.Draw(sheet)
    title_font = ImageFont.truetype(str(font_path()), size=32, index=9)
    label_font = ImageFont.truetype(str(font_path()), size=26, index=9)
    draw.text((gap, 24), label, fill="#24224A", font=title_font)
    for row_index, (row_name, images) in enumerate(zip(("기본", "200%"), rows)):
        y = title_height + row_index * (row_height + gap)
        draw.text((gap, y + 8), row_name, fill="#5554D9", font=label_font)
        for index, image in enumerate(images):
            sheet.paste(image, (row_label_width + gap + index * (300 + gap), y))
    destination.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(destination, format="PNG", optimize=True)


def main() -> None:
    with TEMPLATE_PATH.open(encoding="utf-8") as file:
        template = json.load(file)
    for target in template["targets"]:
        outputs = []
        for screen in template["screens"]:
            destination = ROOT / target["output"] / screen["output"]
            compose(ROOT / target["source"] / screen["source"], destination, target, screen, template)
            outputs.append(destination)
        contact_sheet(
            outputs,
            ROOT / "store_assets/promotional/contact-sheets" / f'{target["name"]}.png',
            f'말또 · {target["name"]} · 사용 순서 중심',
        )
        if target["name"] == "ios-iphone-6.9":
            large_dir = ROOT / "store_assets/screenshots/qa-large-text/ios/ko-KR/iphone-6.9"
        elif target["name"] == "ios-ipad-13":
            large_dir = ROOT / "store_assets/screenshots/qa-large-text/ios/ko-KR/ipad-13"
        else:
            large_dir = ROOT / "store_assets/screenshots/qa-large-text/android/ko-KR"
        qa_contact_sheet(
            [ROOT / target["source"] / screen["source"] for screen in template["screens"]],
            [large_dir / screen["source"] for screen in template["screens"]],
            ROOT / "store_assets/promotional/contact-sheets" / f'qa-large-text-{target["name"]}.png',
            f'말또 · {target["name"]} · 기본/200% 큰 글씨 비교',
        )
    print("홍보용 스크린샷과 contact sheet 생성 완료")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        raise SystemExit(str(error)) from error
