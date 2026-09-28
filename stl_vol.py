import sys


def ascii_stl_volume(path):
    vol = 0.0
    tris = 0
    verts = []
    with open(path, "r", errors="ignore") as f:
        for line in f:
            parts = line.strip().split()
            if len(parts) == 4 and parts[0] == "vertex":
                verts.append([float(x) for x in parts[1:]])
                if len(verts) == 3:
                    p1, p2, p3 = verts
                    vol += (
                        p1[0] * (p2[1] * p3[2] - p2[2] * p3[1])
                        - p1[1] * (p2[0] * p3[2] - p2[2] * p3[0])
                        + p1[2] * (p2[0] * p3[1] - p2[1] * p3[0])
                    ) / 6.0
                    tris += 1
                    verts = []
    return vol, tris


if __name__ == "__main__":
    for p in sys.argv[1:]:
        vol, tris = ascii_stl_volume(p)
        print("%s  triangles=%d  volume=%.0f mm^3" % (p, tris, vol))
