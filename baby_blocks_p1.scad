/* ============================================================
 * P1 咬咬积木 · 食品级硅胶浇注参数化设计(0-1 岁,家庭自制)
 * ------------------------------------------------------------
 * 用途:OpenSCAD 生成积木本体(母模验证)与两瓣式硅胶浇注模具
 * 安全红线:任一部件最小尺寸 >= 45mm(小零件试验器 Φ31.7)
 *          无小件 / 无磁铁 / 无封闭积水腔 / 圆角 R10 无锐边
 *
 * 模具打印(PLA):层高 0.10-0.12mm,壁 4 圈,分型面朝上平放,
 *          打印后洗洁精清洗晾干,严禁光敏树脂模具(铂金硅胶会中毒)
 * 硅胶浇注:食品级铂金(加成型)硅胶,A:B=1:1,脱泡后细流沿壁浇入
 *          顶部浇口,常温 4-6h 固化,成品修剪浇口后煮洗
 *
 * 浇口说明:上模顶部中央锥形浇口(Φ10 → Φ4),成品顶面留 Φ4
 *          圆凸台,精修剪平。因此 dice 的 1 点面 / dots、rings
 *          的顶面均省去中心凸点,浇口痕即中心点。
 * ============================================================ */

/* [全局] */
// 积木边长 mm(红线 >= 45)
BLOCK = 48;
// 圆角半径 mm(防锐角 + 好抓握)
R_CORNER = 10;
// 表面浮雕凸起高度 mm
TEX_H = 1.5;
// 曲面精度
$fn = 64;

/* [款式] */
// 积木款式
PART = "dice"; // [dice, dots, rings, weave, ball]

/* [视图] */
// 显示内容:block=积木本体, mold_bottom/mold_top=模具单瓣, mold_split=合模分解
VIEW = "block"; // [block, mold_bottom, mold_top, mold_split]

/* [模具] */
// 模具壁厚 mm
WALL = 20;
// 单瓣模高 mm(积木半高 24 + 底厚 8)
MH = 32;
// 顶部浇口外径 / 入腔直径 mm
GATE_D_OUT = 10;
GATE_D_IN = 4;
// 定位销直径 / 间隙 / 高度 mm
PIN_D = 6;
PIN_CLEAR = 0.3;
PIN_H = 5;
// 分型面排气缝:宽 x 深 mm
VENT_W = 0.6;
VENT_D = 0.4;

MO = BLOCK + 2 * WALL; // 模具外框边长
HALF = BLOCK / 2;

/* ============================================================
 * 基础几何
 * ============================================================ */

// 圆角长方体(角部球 hull),原点在角上
module rbox(sx, sy, sz, r = 6) {
    hull()
        for (x = [r, sx - r], y = [r, sy - r], z = [r, sz - r])
            translate([x, y, z]) sphere(r = r);
}

// 居中圆角积木本体
module cblock()
    translate([-HALF, -HALF, -HALF]) rbox(BLOCK, BLOCK, BLOCK, R_CORNER);

// 球冠凸点:顶端凸出 h,球体沉入表面
module dot(d = 8, h = TEX_H) {
    r = d / 2;
    translate([0, 0, h - r]) sphere(r = r);
}

// 圆环(管心在半径 ro 处)
module ring(ro, ri = 1.5) {
    rotate_extrude() translate([ro, 0]) circle(r = ri);
}

// 凸起圆环:一半沉入表面
module ring_bump(ro, ri = 1.5, h = TEX_H)
    translate([0, 0, h - ri]) ring(ro, ri);

// 沿 X 的圆头凸条
module bar_x(l = 26, r = 1.5, h = TEX_H) {
    hull()
        for (x = [-l / 2 + r, l / 2 - r])
            translate([x, 0, h - r]) sphere(r = r);
}

// 把子对象贴到积木表面:局部 +Z 即面法向
module put(rot) rotate(rot) translate([0, 0, HALF]) children();

/* ============================================================
 * 五款纹理面(均以局部原点为中心,平面区半径上限 14mm)
 * ============================================================ */

// 标准骰子布点(pitch 11)
function dice_pts(n) =
    n == 1 ? [[0, 0]]
  : n == 2 ? [[-1, 1], [1, -1]]
  : n == 3 ? [[-1, 1], [0, 0], [1, -1]]
  : n == 4 ? [[-1, -1], [-1, 1], [1, -1], [1, 1]]
  : n == 5 ? [[-1, -1], [-1, 1], [0, 0], [1, -1], [1, 1]]
  :          [[-1, -1], [-1, 0], [-1, 1], [1, -1], [1, 0], [1, 1]];

module face_dice(n) {
    for (pt = dice_pts(n)) translate([pt[0] * 10, pt[1] * 10, 0]) dot(7);
}

// 3x3 点阵(pitch 10);顶面 center=false 去中心点让位浇口
module face_dots(center = true)
    for (i = [-1:1], j = [-1:1])
        if (center || i != 0 || j != 0)
            translate([i * 10, j * 10, 0]) dot(7);

// 同心环:中心点 + 两圈;顶面 center=false
module face_rings(center = true) {
    if (center) dot(8);
    for (ro = [7, 12.5]) ring_bump(ro);
}

// 编织纹:3 横 3 竖圆头条(交叉点即中心,浇口痕落在交叉处)
module face_weave()
    for (i = [-1:1]) {
        translate([0, i * 10, 0]) bar_x(24);
        translate([i * 10, 0, 0]) rotate([0, 0, 90]) bar_x(24);
    }

/* ============================================================
 * 积木本体
 * ============================================================ */

module block() {
    if (PART == "ball") {
        // 48mm 球 + 三条纬线凸环(管心贴球面,凸出 TEX_H)
        sphere(r = HALF);
        for (z = [-12, 0, 12])
            translate([0, 0, z]) ring(sqrt(HALF * HALF - z * z));
    } else {
        cblock();
        if (PART == "dice") {
            // +Z 为浇口面:1 点由浇口凸台修剪后充当,不放纹理
            put([180, 0, 0]) face_dice(6);
            put([0, 90, 0])  face_dice(2);
            put([0, -90, 0]) face_dice(5);
            put([-90, 0, 0]) face_dice(3);
            put([90, 0, 0])  face_dice(4);
        } else if (PART == "dots") {
            put([0, 0, 0])   face_dots(false);
            put([180, 0, 0]) face_dots();
            put([0, 90, 0])  face_dots();
            put([0, -90, 0]) face_dots();
            put([-90, 0, 0]) face_dots();
            put([90, 0, 0])  face_dots();
        } else if (PART == "rings") {
            put([0, 0, 0])   face_rings(false);
            put([180, 0, 0]) face_rings();
            put([0, 90, 0])  face_rings();
            put([0, -90, 0]) face_rings();
            put([-90, 0, 0]) face_rings();
            put([90, 0, 0])  face_rings();
        } else if (PART == "weave") {
            put([0, 0, 0])   face_weave();
            put([180, 0, 0]) face_weave();
            put([0, 90, 0])  face_weave();
            put([0, -90, 0]) face_weave();
            put([-90, 0, 0]) face_weave();
            put([90, 0, 0])  face_weave();
        }
    }
}

/* ============================================================
 * 两瓣式硅胶浇注模具
 * ============================================================ */

module z_neg() translate([0, 0, -100]) cube([400, 400, 200], center = true);
module z_pos() translate([0, 0, 100]) cube([400, 400, 200], center = true);

// 分型面排气缝(刻进下模顶面 VENT_D 深,合模后形成 0.4mm 排气缝)
module vents()
    for (a = [0:3]) rotate([0, 0, a * 90])
        translate([HALF - 2, -VENT_W / 2, -VENT_D])
            cube([MO / 2 - HALF + 4, VENT_W, VENT_D]);

// 下模:框体减整块积木后保留下半 + 4 定位凸销 + 排气缝
// (先减整块再交半空间,等价于减半块,但布尔序列对 CGAL 更稳)
module mold_bottom() {
    intersection() {
        difference() {
            translate([-MO / 2, -MO / 2, -MH]) rbox(MO, MO, MH, 8);
            block();
            vents();
        }
        z_neg();
    }
    for (x = [-1, 1], y = [-1, 1])
        translate([x * (MO / 2 - 12), y * (MO / 2 - 12), 0])
            cylinder(d = PIN_D, h = PIN_H);
}

// 上模:框体减整块积木后保留上半 + 4 定位销孔 + 顶部锥形浇口
module mold_top() {
    intersection() {
        difference() {
            translate([-MO / 2, -MO / 2, 0]) rbox(MO, MO, MH, 8);
            block();
            for (x = [-1, 1], y = [-1, 1])
                translate([x * (MO / 2 - 12), y * (MO / 2 - 12), -0.01])
                    cylinder(d = PIN_D + PIN_CLEAR, h = PIN_H + 0.5);
            translate([0, 0, HALF])
                cylinder(d1 = GATE_D_IN, d2 = GATE_D_OUT, h = MH - HALF + 0.01);
        }
        z_pos();
    }
}

/* ============================================================
 * 视图输出
 * ============================================================ */

if (VIEW == "block") {
    block();
} else if (VIEW == "mold_bottom") {
    mold_bottom();
} else if (VIEW == "mold_top") {
    mold_top();
} else if (VIEW == "mold_split") {
    mold_bottom();
    translate([0, 0, 70]) mold_top();
} else if (VIEW == "cavity_lower") {
    intersection() { block(); z_neg(); }
} else if (VIEW == "cavity_upper") {
    intersection() { block(); z_pos(); }
} else if (VIEW == "test_diff") {
    difference() {
        translate([0, 0, -MH]) rbox(MO, MO, MH, 8);
        intersection() { block(); z_neg(); }
    }
} else if (VIEW == "test_box") {
    translate([0, 0, -MH]) rbox(MO, MO, MH, 8);
}
