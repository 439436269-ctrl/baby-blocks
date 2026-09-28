"""Render an STL to PNG with PIL: painter's algorithm, Lambert shading.

Usage:
    python stl_render.py input.stl output.png [width] [height]

Camera: 3/4 view (yaw 35deg, pitch 55deg), auto-fit, light gray background.
"""
import math
import struct
import sys

from PIL import Image, ImageDraw


def load_tris(path):
    with open(path, "rb") as f:
        data = f.read()
    tris = []
    if b"facet" in data:
        verts = []
        for line in data.decode("ascii", errors="ignore").splitlines():
            p = line.strip().split()
            if len(p) == 4 and p[0] == "vertex":
                verts.append((float(p[1]), float(p[2]), float(p[3])))
        tris = [(verts[i], verts[i + 1], verts[i + 2]) for i in range(0, len(verts) - 2, 3)]
    else:
        n = struct.unpack("<I", data[80:84])[0]
        off = 84
        for _ in range(n):
            v = struct.unpack("<12f", data[off:off + 48])
            tris.append((v[3:6], v[6:9], v[9:12]))
            off += 50
    return tris


def rot_view(v, cy, sy, cp, sp):
    # yaw about Z then pitch about X
    x, y, z = v
    x1 = x * cy - y * sy
    y1 = x * sy + y * cy
    z1 = z
    y2 = y1 * cp - z1 * sp
    z2 = y1 * sp + z1 * cp
    return (x1, y2, z2)


def render(stl_path, out_path, W=1200, H=900):
    tris = load_tris(stl_path)
    yaw = math.radians(35)
    pitch = math.radians(55)
    cy, sy = math.cos(yaw), math.sin(yaw)
    cp, sp = math.cos(pitch), math.sin(pitch)

    view = []
    for t in tris:
        v = [rot_view(p, cy, sy, cp, sp) for p in t]
        view.append(v)
    xs = [p[0] for v in view for p in v]
    ys = [p[1] for v in view for p in v]
    minx, maxx = min(xs), max(xs)
    miny, maxy = min(ys), max(ys)
    span = max(maxx - minx, maxy - miny) or 1
    s = (min(W, H) * 0.86) / span
    cx = (minx + maxx) / 2
    cyy = (miny + maxy) / 2

    def to_px(p):
        return ((p[0] - cx) * s + W / 2, (p[1] - cyy) * s + H / 2)

    # depth = view z (larger = closer to camera after pitch transform)
    order = sorted(range(len(view)), key=lambda i: sum(p[2] for p in view[i]) / 3)

    img = Image.new("RGB", (W, H), (244, 244, 244))
    draw = ImageDraw.Draw(img)
    lx, ly, lz = -0.35, -0.45, 0.82
    ll = math.sqrt(lx * lx + ly * ly + lz * lz)
    lx, ly, lz = lx / ll, ly / ll, lz / ll

    for i in order:
        v = view[i]
        (x1, y1, z1), (x2, y2, z2), (x3, y3, z3) = v
        ux, uy, uz = x2 - x1, y2 - y1, z2 - z1
        wx, wy, wz = x3 - x1, y3 - y1, z3 - z1
        nx = uy * wz - uz * wy
        ny = uz * wx - ux * wz
        nz = ux * wy - uy * wx
        nl = math.sqrt(nx * nx + ny * ny + nz * nz)
        if nl > 1e-12:
            nx, ny, nz = nx / nl, ny / nl, nz / nl
        else:
            nx, ny, nz = 0, 0, 1
        # face camera if backfacing
        if nz < 0:
            nx, ny, nz = -nx, -ny, -nz
        lam = max(0.0, nx * lx + ny * ly + nz * lz)
        shade = 0.42 + 0.58 * lam
        base = (74, 111, 165)  # steel blue
        col = tuple(min(255, int(c * shade)) for c in base)
        pts = [to_px(p) for p in v]
        draw.polygon(pts, fill=col, outline=(52, 78, 115))
    img.save(out_path)
    print("%s  tris=%d" % (out_path, len(tris)))


if __name__ == "__main__":
    w = int(sys.argv[3]) if len(sys.argv) > 3 else 1200
    h = int(sys.argv[4]) if len(sys.argv) > 4 else 900
    render(sys.argv[1], sys.argv[2], w, h)
