#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0
"""Recompute the unsigned AVB hash footer after repacking a boot image.

Usage:
  python3 recompute_avb.py <template-boot.img> <new-boot.img> [output.img]

The template must contain a valid AVB footer and one hash descriptor for the
boot partition. The script keeps the template vbmeta block, updates the
descriptor image size and SHA-256 digest, and rewrites the AVB footer. It does
not create a new RSA signature; the dandelion bootloader accepts this layout
with the unlocked/AVB-disabled image used by this project.
"""
import argparse
import hashlib
import struct
from pathlib import Path

PAGE = 0x800
AVB_FOOTER_SIZE = 64


def align_up(value, page):
    return ((value + page - 1) // page) * page


def image_size_from_header(data, page):
    hdr_ver = struct.unpack_from("<I", data, 40)[0]
    kernel = struct.unpack_from("<I", data, 8)[0]
    ramdisk = struct.unpack_from("<I", data, 16)[0]
    second = struct.unpack_from("<I", data, 24)[0]
    end = page + align_up(kernel, page) + align_up(ramdisk, page)
    end += align_up(second, page)
    if hdr_ver >= 2 and len(data) > 1648:
        end += align_up(struct.unpack_from("<I", data, 1648)[0], page)
    return end


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("template")
    ap.add_argument("new_boot")
    ap.add_argument("output", nargs="?")
    args = ap.parse_args()

    template = Path(args.template).read_bytes()
    new = Path(args.new_boot).read_bytes()
    if len(template) < AVB_FOOTER_SIZE or len(new) < PAGE:
        raise SystemExit("invalid boot image")
    magic, vmaj, vmin, orig, vboff, vbsize, _ = struct.unpack(
        ">4sIIQQQ28s", template[-AVB_FOOTER_SIZE:]
    )
    if magic != b"AVBf" or vboff + vbsize > len(template):
        raise SystemExit("template has no valid AVB footer")

    page = struct.unpack_from("<I", new, 36)[0]
    image_size = image_size_from_header(new, page)
    vb = bytearray(template[vboff:vboff + vbsize])

    pos = 256 + struct.unpack_from(">Q", vb, 12)[0]
    end = pos + struct.unpack_from(">Q", vb, 104)[0]
    hash_desc = None
    while pos + 16 <= end:
        tag, length = struct.unpack_from(">QQ", vb, pos)
        if tag == 2:
            hash_desc = pos
            break
        pos += 16 + length
        pos += (-pos) % 8
    if hash_desc is None:
        raise SystemExit("no hash descriptor in template vbmeta")

    data = hash_desc + 16
    old_size = struct.unpack_from(">Q", vb, data)[0]
    algo = bytes(vb[data + 8:data + 40]).split(b"\0", 1)[0].decode()
    name_len, salt_len, digest_len = struct.unpack_from(">III", vb, data + 40)
    salt_off = data + 116 + name_len
    digest_off = salt_off + salt_len
    salt = bytes(vb[salt_off:salt_off + salt_len])
    digest = hashlib.new(algo, salt)
    digest.update(new[:image_size])

    struct.pack_into(">Q", vb, data, image_size)
    vb[digest_off:digest_off + digest_len] = digest.digest()

    # Keep the template's one-page gap between image data and vbmeta.
    vbmeta_offset = align_up(image_size, page) + page
    buf = bytearray(new[:image_size])
    buf += b"\0" * (vbmeta_offset - len(buf))
    buf += vb
    buf += b"\0" * (len(template) - len(buf))

    # AVB footer: magic/version, original_image_size, vbmeta_offset, vbmeta_size
    struct.pack_into(">Q", buf, len(buf) - 64 + 12, image_size)
    struct.pack_into(">Q", buf, len(buf) - 64 + 20, vbmeta_offset)
    struct.pack_into(">Q", buf, len(buf) - 64 + 28, len(vb))

    out = Path(args.output or (Path(args.new_boot).with_name(
        Path(args.new_boot).stem + "-avb.img"
    )))
    out.write_bytes(buf)
    print(f"image_size=0x{image_size:x} vbmeta=0x{vbmeta_offset:x}")
    print(f"old_image_size=0x{old_size:x} digest={digest.hexdigest()}")
    print(f"wrote {out} ({len(buf)} bytes)")


if __name__ == "__main__":
    main()
