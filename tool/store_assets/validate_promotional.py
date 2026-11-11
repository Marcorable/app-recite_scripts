#!/usr/bin/env python3

import json
import re
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
TEMPLATE_PATH = ROOT / "store_assets/promotional/template.json"
FORBIDDEN = re.compile(
    r"([\w.+-]+@[\w.-]+\.[A-Za-z]{2,})|(01[016789][ -]?[0-9]{3,4}[ -]?[0-9]{4})|"
    r"(AKIA[0-9A-Z]{16})|(-----BEGIN [A-Z ]*PRIVATE KEY-----)|(/Users/[^/\s]+)"
)


def inspect_image(path: Path, expected: tuple[int, int]) -> None:
    if not path.exists():
        raise ValueError(f"결과물 누락: {path}")
    with Image.open(path) as image:
        image.load()
        if image.format != "PNG" or image.size != expected:
            raise ValueError(f"PNG 규격 오류: {path} ({image.width}x{image.height})")
        if image.mode != "RGB" or "transparency" in image.info:
            raise ValueError(f"24-bit RGB PNG가 아님: {path} ({image.mode})")
        if path.stat().st_size < 10_000:
            raise ValueError(f"비정상적으로 작은 결과물: {path}")


def main() -> None:
    with TEMPLATE_PATH.open(encoding="utf-8") as file:
        template = json.load(file)
    if template.get("direction") != "workflow-first":
        raise ValueError("승인된 사용 순서 중심 방향이 아닙니다.")
    screens = template.get("screens", [])
    expected_sources = [
        "01-script-list.png",
        "02-script-editor.png",
        "03-reading-setup.png",
        "04-reading-progress.png",
    ]
    if [screen.get("source") for screen in screens] != expected_sources:
        raise ValueError("승인된 네 장의 사용 순서가 변경됐습니다.")
    if FORBIDDEN.search(json.dumps(template, ensure_ascii=False)):
        raise ValueError("템플릿에서 개인정보·시크릿·로컬 경로 의심 패턴을 발견했습니다.")

    for target in template.get("targets", []):
        output_dir = ROOT / target["output"]
        if len(list(output_dir.glob("*.png"))) != 4:
            raise ValueError(f"결과물 개수 오류: {output_dir}")
        for screen in screens:
            inspect_image(output_dir / screen["output"], (target["width"], target["height"]))
        contact_sheet = ROOT / "store_assets/promotional/contact-sheets" / f'{target["name"]}.png'
        qa_sheet = ROOT / "store_assets/promotional/contact-sheets" / f'qa-large-text-{target["name"]}.png'
        for sheet in (contact_sheet, qa_sheet):
            if not sheet.exists() or sheet.stat().st_size < 10_000:
                raise ValueError(f"contact sheet 누락 또는 손상: {sheet}")
    fixture_text = (ROOT / "store_assets/fixtures/ko-KR/scripts.json").read_text(encoding="utf-8")
    if FORBIDDEN.search(fixture_text):
        raise ValueError("고정 더미 데이터에서 민감정보 의심 패턴을 발견했습니다.")
    print("홍보용 스크린샷 규격·순서·카피 템플릿·민감정보 검증 완료")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        raise SystemExit(str(error)) from error
