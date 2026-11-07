#!/usr/bin/env python3
"""Create a CPC "Data format" .dsk (40 tracks, 9 sectors, 178K usable).

    mkdsk.py OUT.dsk [--bin NAME=PATH:LOAD:ENTRY] [--text NAME=PATH] ...

--bin   binary file with an AMSDOS header; LOAD and ENTRY are hex addresses
--text  ASCII BASIC without a header; BASIC tokenises it when it is loaded
        (LF line ends become CRLF, and the Ctrl-Z end-of-file mark is added)
"""
import argparse
import pathlib
import struct

TRACKS = 40
SECTORS = 9
SECTOR_SIZE = 512
BLOCK_SIZE = 1024
DIR_BLOCKS = 2                      # 64 directory entries
DIR_ENTRIES = 64
RECORD = 128
EXTENT_RECORDS = 128                # 16K per directory entry
FIRST_SECTOR = 0xC1
INTERLEAVE = [0xC1, 0xC6, 0xC2, 0xC7, 0xC3, 0xC8, 0xC4, 0xC9, 0xC5]


def split_name(name):
    base, _, ext = name.upper().partition('.')
    if not 1 <= len(base) <= 8 or len(ext) > 3:
        raise SystemExit(f'not an 8.3 name: {name}')
    return base.ljust(8).encode(), ext.ljust(3).encode()


def amsdos_header(name, data, load, entry):
    """128-byte header: file type 2 (binary), then a checksum of bytes 0-66."""
    base, ext = split_name(name)
    h = bytearray(RECORD)
    h[1:9] = base
    h[9:12] = ext
    h[18] = 2
    struct.pack_into('<H', h, 21, load)
    struct.pack_into('<H', h, 24, len(data))
    struct.pack_into('<H', h, 26, entry)
    h[64:67] = len(data).to_bytes(3, 'little')
    struct.pack_into('<H', h, 67, sum(h[:67]))
    return bytes(h)


def build_image(files):
    """Lay the files out in a flat image of the disk's sectors, in logical order."""
    image = bytearray(b'\xE5' * (TRACKS * SECTORS * SECTOR_SIZE))
    total_blocks = len(image) // BLOCK_SIZE
    next_block = DIR_BLOCKS
    entry = 0
    for name, content in files:
        base, ext = split_name(name)
        count = (len(content) + BLOCK_SIZE - 1) // BLOCK_SIZE
        if next_block + count > total_blocks:
            raise SystemExit('disk full')
        blocks = list(range(next_block, next_block + count))
        offset = next_block * BLOCK_SIZE
        image[offset:offset + len(content)] = content
        next_block += count

        records = (len(content) + RECORD - 1) // RECORD
        extent = 0
        while True:
            if entry == DIR_ENTRIES:
                raise SystemExit('directory full')
            here = min(records, EXTENT_RECORDS)
            used = blocks[:16]
            blocks = blocks[16:]
            d = bytes([0]) + base + ext + bytes([extent, 0, 0, here])
            d += bytes(used).ljust(16, b'\0')
            image[entry * 32:entry * 32 + 32] = d
            entry += 1
            records -= here
            extent += 1
            if records == 0:
                break
    return image


def write_dsk(path, image):
    """Wrap the flat image in the standard (non-extended) CPCEMU container."""
    track_size = 256 + SECTORS * SECTOR_SIZE
    head = bytearray(256)
    head[:34] = b'MV - CPCEMU Disk-File\r\nDisk-Info\r\n'
    head[34:48] = b'democpc2'.ljust(14)
    head[48] = TRACKS
    head[49] = 1
    struct.pack_into('<H', head, 50, track_size)
    out = bytearray(head)
    for t in range(TRACKS):
        info = bytearray(256)
        info[:13] = b'Track-Info\r\n\0'
        info[16] = t
        info[20] = 2                # sector size code: 512 bytes
        info[21] = SECTORS
        info[22] = 0x4E             # GAP3
        info[23] = 0xE5             # filler
        for i, sid in enumerate(INTERLEAVE):
            info[24 + i * 8:28 + i * 8] = bytes([t, 0, sid, 2])
        out += info
        base = t * SECTORS * SECTOR_SIZE
        for sid in INTERLEAVE:
            at = base + (sid - FIRST_SECTOR) * SECTOR_SIZE
            out += image[at:at + SECTOR_SIZE]
    pathlib.Path(path).write_bytes(out)


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('out')
    ap.add_argument('--bin', action='append', default=[])
    ap.add_argument('--text', action='append', default=[])
    a = ap.parse_args()
    files = []
    for spec in a.text:
        name, path = spec.split('=', 1)
        text = pathlib.Path(path).read_bytes().replace(b'\r\n', b'\n').replace(b'\n', b'\r\n')
        files.append((name, text + b'\x1a'))
    for spec in a.bin:
        name, rest = spec.split('=', 1)
        path, load, entry = rest.rsplit(':', 2)
        data = pathlib.Path(path).read_bytes()
        files.append((name, amsdos_header(name, data, int(load, 16), int(entry, 16)) + data))
    write_dsk(a.out, build_image(files))


if __name__ == '__main__':
    main()
