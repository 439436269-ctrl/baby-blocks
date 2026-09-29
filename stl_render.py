"""Render an STL to PNG with PIL: painter's algorithm, smooth vertex normals.

Usage:
    python stl_render.py input.stl output.png [width] [height]

Camera: 3/4 view (yaw 35deg, pitch 55deg), auto-fit, Lambert shading with
vertex-normal smoothing (no per-triangle outlines).
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


def face_normal(a, b, c):
    ux, uy, uz = b[0] - a[0], b[1] - a[1], b[2] - a[2]
    wx, wy, wz = c[0] - a[0], c[1] - a[1], c[2] - a[2]
    nx = uy * wz - uz * wy
    ny = uz * wx - ux * wz
    nz = ux * wy - uy * wx
    ln = math.sqrt(nx * nx + ny * ny + nz * nz)
    if ln < 1e-12:
        return (0.0, 0.0, 1.0)
    return (nx / ln, ny / ln, nz / ln)


def subdivide(tris, max_edge):
    """Split long triangles so painter-sort by centroid stays coherent."""
    out = []
    stack = list(tris)
    max_sq = max_edge * max_edge
    while stack:
        a, b, c = stack.pop()
        # longest edge
        e = [(a, b, c), (b, c, a), (c, a, b)]
        best = 0
        best_len = -1.0
        for i, (p, q, r) in enumerate(e):
            d = (p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2 + (p[2] - q[2]) ** 2
            if d > best_len:
                best_len = d
                best = i
        if best_len <= max_sq:
            out.append((a, b, c))
            continue
        p, q, r = e[best]
        m = ((p[0] + q[0]) / 2, (p[1] + q[1]) / 2, (p[2] + q[2]) / 2)
        stack.append((p, m, r))
        stack.append((m, q, r))
    return out


def smooth_vertex_normals(tris):
    acc = {}
    key_of = []
    for t in tris:
        n = face_normal(*t)
        keys = []
        for p in t:
            k = (round(p[0], 4), round(p[1], 4), round(p[2], 4))
            keys.append(k)
            cur = acc.get(k, (0.0, 0.0, 0.0))
            acc[k] = (cur[0] + n[0], cur[1] + n[1], cur[2] + n[2])
        key_of.append(keys)
    norm = {}
    for k, v in acc.items():
        ln = math.sqrt(v[0] ** 2 + v[1] ** 2 + v[2] ** 2)
        norm[k] = (v[0] / ln, v[1] / ln, v[2] / ln) if ln > 1e-12 else (0.0, 0.0, 1.0)
    out = []
    for i, keys in enumerate(key_of):
        a, b, c = (norm[k] for k in keys)
        sm = (a[0] + b[0] + c[0], a[1] + b[1] + c[1], a[2] + b[2] + c[2])
        ln = math.sqrt(sm[0] ** 2 + sm[1] ** 2 + sm[2] ** 2)
        sm = (sm[0] / ln, sm[1] / ln, sm[2] / ln) if ln > 1e-12 else (0.0, 0.0, 1.0)
        out.append(sm)
    return out


def rot_view(v, cy, sy, cp, sp):
    x, y, z = v
    x1 = x * cy - y * sy
    y1 = x * sy + y * cy
    y2 = y1 * cp - z * sp
    z2 = y1 * sp + z * cp
    return (x1, y2, z2)


def render(stl_path, out_path, W=1200, H=900):
    tris = load_tris(stl_path)
    yaw = math.radians(35)
    pitch = math.radians(55)
    cy, sy = math.cos(yaw), math.sin(yaw)
    cp, sp = math.cos(pitch), math.sin(pitch)

    # bbox first to size the subdivision threshold
    xs = [p[0] for t in tris for p in t]
    ys = [p[1] for t in tris for p in t]
    span = max(max(xs) - min(xs), max(ys) - min(ys)) or 1
    tris = subdivide(tris, span / 30.0)

    view = [[rot_view(p, cy, sy, cp, sp) for p in t] for t in tris]
    vnorm_raw = smooth_vertex_normals(tris)
    vnorm = [rot_view(n, cy, sy, cp, sp) for n in vnorm_raw]

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

    order = sorted(range(len(view)), key=lambda i: sum(p[2] for p in view[i]) / 3)

    img = Image.new("RGB", (W, H), (246, 246, 246))
    draw = ImageDraw.Draw(img)
    lx, ly, lz = -0.35, -0.45, 0.82
    ll = math.sqrt(lx * lx + ly * ly + lz * lz)
    lx, ly, lz = lx / ll, ly / ll, lz / ll

    for i in order:
        v = view[i]
        nx, ny, nz = vnorm[i]
        if nz < 0:
            nx, ny, nz = -nx, -ny, -nz
        lam = max(0.0, nx * lx + ny * ly + nz * lz)
        shade = 0.40 + 0.60 * lam
        base = (74, 111, 165)
        col = tuple(min(255, int(c * shade)) for c in base)
        draw.polygon([to_px(p) for p in v], fill=col)
    # self-identifying label burned into pixels (anti cache/swap confusion)
    label = out_path.split("\\")[-1].split("/")[-1]
    draw.text((12, H - 22), label, fill=(20, 20, 20))
    img.save(out_path)
    print("%s  tris=%d" % (out_path, len(tris)))


if __name__ == "__main__":
    w = int(sys.argv[3]) if len(sys.argv) > 3 else 1200
    h = int(sys.argv[4]) if len(sys.argv) > 4 else 900
    render(sys.argv[1], sys.argv[2], w, h)
