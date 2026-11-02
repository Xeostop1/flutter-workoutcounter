import struct
import unittest

from validate_release import check_elf64, check_png


def png(width=1080, height=1920, color=2):
    # Header-only fixtures: pixel decoding is separately verified by the export tool.
    return (b"\x89PNG\r\n\x1a\n" + struct.pack(">I", 13) + b"IHDR"
            + struct.pack(">II5B", width, height, 8, color, 0, 0, 0) + b"\0" * 4)


def elf(alignment=16384, offset=0):
    data = bytearray(120)
    data[:6] = b"\x7fELF\x02\x01"
    struct.pack_into("<Q", data, 32, 64)
    struct.pack_into("<HH", data, 54, 56, 1)
    struct.pack_into("<I", data, 64, 1)
    struct.pack_into("<QQ", data, 72, offset, 0)
    struct.pack_into("<Q", data, 112, alignment)
    return bytes(data)


class ReleaseChecks(unittest.TestCase):
    def test_phone_rgb(self):
        self.assertTrue(check_png(png(), "phone")["technical_pass"])

    def test_phone_rgba_is_not_ready(self):
        self.assertFalse(check_png(png(color=6), "phone")["technical_pass"])

    def test_tall_iphone_export_needs_a_new_layout(self):
        self.assertFalse(check_png(png(1242, 2688), "phone")["technical_pass"])

    def test_feature_dimensions(self):
        self.assertTrue(check_png(png(1024, 500), "feature")["technical_pass"])
        self.assertFalse(check_png(png(), "feature")["technical_pass"])

    def test_elf_alignment(self):
        self.assertTrue(check_elf64(elf())["elf_alignment_pass"])
        self.assertFalse(check_elf64(elf(4096))["elf_alignment_pass"])

    def test_offset_congruence(self):
        self.assertFalse(check_elf64(elf(offset=4096))["elf_alignment_pass"])

    def test_truncated_inputs(self):
        with self.assertRaises(ValueError):
            check_elf64(elf()[:80])
        with self.assertRaises(ValueError):
            check_png(b"not a png", "phone")


if __name__ == "__main__":
    unittest.main()
