"""Read-only technical checks; not a Play policy, signing, UI, or runtime approval."""
from __future__ import annotations

import argparse
import json
import struct
import zipfile
from pathlib import Path


def png_info(data: bytes) -> dict:
    if len(data) < 33 or data[:8] != b"\x89PNG\r\n\x1a\n" or data[12:16] != b"IHDR":
        raise ValueError("Invalid PNG header")
    width, height = struct.unpack_from(">II", data, 16)
    if not width or not height:
        raise ValueError("Invalid dimensions")
    return {"width": width, "height": height, "bit_depth": data[24], "color_type": data[25]}


def check_png(data: bytes, role: str) -> dict:
    info = png_info(data)
    width, height = info["width"], info["height"]
    errors = []
    if info["bit_depth"] != 8 or info["color_type"] != 2:
        errors.append("Requires 8-bit truecolor RGB PNG without an alpha channel")
    if role == "feature" and (width, height) != (1024, 500):
        errors.append("Feature graphic must be 1024x500")
    if role == "phone" and not (320 <= min(width, height) and max(width, height) <= 3840
                                 and max(width, height) <= 2 * min(width, height)):
        errors.append("Phone screenshot dimensions/aspect ratio are outside the checked limits")
    return {**info, "check_scope": "header_dimensions_and_color_type",
            "technical_pass": not errors, "errors": errors}


def check_elf64(data: bytes) -> dict:
    if len(data) < 64 or data[:4] != b"\x7fELF" or data[4] != 2 or data[5] not in (1, 2):
        raise ValueError("Expected an ELF64 library")
    endian = "<" if data[5] == 1 else ">"
    offset = struct.unpack_from(endian + "Q", data, 32)[0]
    size, count = struct.unpack_from(endian + "HH", data, 54)
    if size < 56 or not count or count > 4096 or offset + size * count > len(data):
        raise ValueError("Invalid ELF program header table")
    loads = []
    for index in range(count):
        entry = offset + size * index
        if struct.unpack_from(endian + "I", data, entry)[0] != 1:
            continue
        file_offset, address = struct.unpack_from(endian + "QQ", data, entry + 8)
        alignment = struct.unpack_from(endian + "Q", data, entry + 48)[0]
        valid = (alignment >= 16384 and not alignment & (alignment - 1)
                 and file_offset % 16384 == address % 16384)
        loads.append({"alignment": alignment, "aligned_16k": valid})
    return {"load_segments": loads, "elf_alignment_pass": bool(loads) and all(
        item["aligned_16k"] for item in loads)}


def audit_bundle(path: Path) -> dict:
    libraries = []
    with zipfile.ZipFile(path) as archive:
        for entry in archive.infolist():
            if not entry.filename.endswith(".so") or not any(
                f"/{abi}/" in entry.filename for abi in ("arm64-v8a", "x86_64")
            ):
                continue
            if entry.file_size > 256 * 1024 * 1024:
                raise ValueError("Library too large for this diagnostic tool")
            try:
                result = check_elf64(archive.read(entry))
            except ValueError as error:
                result = {"elf_alignment_pass": False, "error": str(error)}
            libraries.append({"path": entry.filename, **result})
    return {"libraries": libraries, "elf_alignment_pass": bool(libraries) and all(
        item["elf_alignment_pass"] for item in libraries),
        "not_checked": ["targetSdk/manifest", "signing certificate", "AAB/installed APK ZIP alignment",
                        "native 16KB runtime behavior", "Play Console acceptance"]}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--assets", type=Path, help="The exports directory, not originals")
    parser.add_argument("--aab", type=Path)
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()
    if not args.assets and not args.aab:
        parser.error("Supply --assets and/or --aab")
    report = {"scope": "technical_checks_only", "asset_results": [],
              "not_checked": ["full PNG decoding/CRC (export tool separately decodes and compares pixels)",
                              "actual Android screenshot accuracy", "metadata/legal declarations",
                              "live account and guest data behavior"]}
    passed = True
    if args.assets:
        images = sorted(args.assets.rglob("*.png"))
        if not images:
            raise ValueError("No PNG exports found")
        for path in images:
            role = "feature" if path.parent.name == "feature-graphic" else "phone"
            result = check_png(path.read_bytes(), role)
            report["asset_results"].append({"path": str(path), "role": role, **result})
            passed = passed and result["technical_pass"]
    if args.aab:
        report["bundle"] = audit_bundle(args.aab)
        passed = passed and report["bundle"]["elf_alignment_pass"]
    report["selected_technical_checks_pass"] = passed
    text = json.dumps(report, ensure_ascii=False, indent=2)
    if args.report:
        if args.report.exists():
            raise FileExistsError("Report exists; choose a new filename")
        args.report.write_text(text + "\n", encoding="utf-8")
    print(text)
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
