/* ============================================================
 * 汉诺塔(0-1 岁+ 叠套玩具)· PETG 架 + 食品级硅胶盘
 * ------------------------------------------------------------
 * 结构:一体打印底座+三柱(PETG,不入口,监督使用)
 *       + 可啃硅胶盘 ×4(铂金硅胶 Shore A20,可煮沸)
 * 安全:最小盘外径 48mm(> 小零件筒 Φ31.7,断落物也不构成小件)
 *       柱连底座一体,无磁铁,无任何可拆小件,柱顶半球圆头
 * 工艺:盘用两瓣模具浇注(孔由模具中央芯柱成型,分型面在盘中面)
 *       上模偏心锥形浇口 Φ4→Φ10(避开孔芯),浇后修剪
 * 坑注:rbox 原点在角上,模具框必须 translate 居中!
 * ============================================================

/* [整体] */
// 底座长 / 宽 / 厚 mm
BASE_L = 190;
BASE_W = 70;
BASE_T = 16;
BASE_R = 8;
// 柱直径 / 露出高度 mm(顶含半球头)
POLE_D = 18;
POLE_H = 95;
// 柱间距 mm
POLE_GAP = 60;

/* [盘] */
// 四盘外径(从大到小)mm —— 红线:最小 ≥ 45
DISC_OUTERS = [90, 75, 60, 48];
// 盘厚 / 中孔直径 mm(孔 > 柱径 + 间隙)
DISC_H = 12;
HOLE_D = 24;
// 边缘倒角 mm
DISC_C = 2;

/* [视图] */
// assembled=成品塔 frame=打印架 disc/discs=硅胶盘 disc_mold_*=盘模具
VIEW = "assembled"; // [assembled, frame, disc, discs, disc_mold_bottom, disc_mold_top, disc_mold_split]
// 模具/单盘对应哪号盘(0=最大)
DISC_IDX = 0;

/* [盘模具] */
MO_WALL = 18;   // 模具壁厚
MO_BASE = 10;   // 模具底厚(单瓣)
PIN_D = 6;
PIN_CLEAR = 0.3;
PIN_H = 5;
VENT_W = 0.6;
VENT_D = 0.4;
GATE_IN = 4;
GATE_OUT = 10;
$fn = 64;

OUTER = DISC_OUTERS[DISC_IDX];
MH = DISC_H / 2 + MO_BASE;   // 单瓣高
MO = OUTER + 2 * MO_WALL;    // 模具外框边长
HALF = OUTER / 2;

/* ============ 基础 ============ */

// 圆角盒(原点在角上 —— 居中使用需自行 translate)
module rbox(sx, sy, sz, r = 6) {
    hull()
        for (x = [r, sx - r], y = [r, sy - r], z = [r, sz - r])
            translate([x, y, z]) sphere(r = r);
}

/* ============ 打印架:底座 + 三柱 ============ */

module frame() {
    translate([-BASE_L / 2, -BASE_W / 2, 0])
        rbox(BASE_L, BASE_W, BASE_T, BASE_R);
    for (px = [-POLE_GAP, 0, POLE_GAP]) {
        // 柱身 + 顶部半球圆头
        translate([px, 0, BASE_T]) cylinder(d = POLE_D, h = POLE_H - POLE_D / 2);
        translate([px, 0, BASE_T + POLE_H - POLE_D / 2]) sphere(d = POLE_D);
        // 根部过渡圆角(斜锥)
        translate([px, 0, BASE_T]) cylinder(d1 = POLE_D + 8, d2 = POLE_D, h = 6);
    }
}

/* ============ 硅胶盘 ============ */

// 盘截面:外缘倒角 + 孔口倒角
module disc_profile(o) {
    rIn = HOLE_D / 2;
    rOut = o / 2;
    c = DISC_C;
    t = DISC_H / 2;
    polygon([
        [rIn, -t + 1], [rIn + 1, -t], [rOut - c, -t], [rOut, -t + c],
        [rOut, t - c], [rOut - c, t], [rIn + 1, t], [rIn, t - 1]
    ]);
}

module disc(o) rotate_extrude() disc_profile(o);

module discs_line() {
    // 四盘平铺展示
    offs = [0, 100, 185, 255];
    for (i = [0:3]) translate([offs[i] - 130, 0, DISC_H / 2]) disc(DISC_OUTERS[i]);
}

module disc_stack() {
    // 按大小套在中柱上(成品塔)
    for (i = [0:3])
        translate([0, 0, BASE_T + i * DISC_H]) disc(DISC_OUTERS[i]);
}

module assembled() {
    frame();
    disc_stack();
}

/* ============ 盘两瓣浇注模具 ============ */

module z_neg() translate([0, 0, -100]) cube([400, 400, 200], center = true);
module z_pos() translate([0, 0, 100]) cube([400, 400, 200], center = true);

module vents()
    for (a = [0:3]) rotate([0, 0, a * 90])
        translate([HALF - 2, -VENT_W / 2, -VENT_D])
            cube([MO / 2 - HALF + 4, VENT_W, VENT_D]);

module mold_bottom() {
    intersection() {
        difference() {
            translate([-MO / 2, -MO / 2, -MH]) rbox(MO, MO, MH, 8);
            disc(OUTER);
            vents();
        }
        z_neg();
    }
    for (x = [-1, 1], y = [-1, 1])
        translate([x * (MO / 2 - 12), y * (MO / 2 - 12), 0])
            cylinder(d = PIN_D, h = PIN_H);
}

module mold_top() {
    intersection() {
        difference() {
            translate([-MO / 2, -MO / 2, 0]) rbox(MO, MO, MH, 8);
            disc(OUTER);
            for (x = [-1, 1], y = [-1, 1])
                translate([x * (MO / 2 - 12), y * (MO / 2 - 12), -0.01])
                    cylinder(d = PIN_D + PIN_CLEAR, h = PIN_H + 0.5);
            // 偏心浇口(避开中央孔芯)
            translate([HALF * 0.65, 0, DISC_H / 2])
                cylinder(d1 = GATE_IN, d2 = GATE_OUT, h = MH - DISC_H / 2 + 0.01);
        }
        z_pos();
    }
}

/* ============ 视图输出 ============ */

if (VIEW == "assembled") {
    assembled();
} else if (VIEW == "frame") {
    frame();
} else if (VIEW == "disc") {
    disc(OUTER);
} else if (VIEW == "discs") {
    discs_line();
} else if (VIEW == "disc_mold_bottom") {
    mold_bottom();
} else if (VIEW == "disc_mold_top") {
    mold_top();
} else if (VIEW == "disc_mold_split") {
    mold_bottom();
    translate([0, 0, 70]) mold_top();
}
