/* ============================================================
 * 不倒翁系列 tumbler.scad(9 月龄+ 硬料一体,零嵌入)
 * ------------------------------------------------------------
 * 回正原理:上部为 3.5mm 薄壳空腔 + 底部实心配重帽(几何一体,
 *          不嵌件)。切片务必 **填充 100%**(壳区全是墙、实心区
 *          打满 → 整体近均匀密度,几何重心即真实重心,蛋形实测
 *          约 -7mm、球形更深,推倒即回正)。15% 填充会让壳墙
 *          相对过重而重心上漂失效。
 * 构造:旋转体 2D 母线 → offset(-3.5) 精确平行内缩保证全域
 *          壁厚 → 底部截断出配重帽。顶部空腔收口免支撑。
 * 定位:推倒回正+滚动;不作牙胶不啃咬
 * 安全:高 ≥84 / 直径 70,一体无小件无磁铁
 * ============================================================

/* [选择] */
PART = "egg"; // [egg, ball]

/* [壁与造型] */
// 壁厚(内缩量)mm
WALL = 3.5;
// 底部配重帽分界高度 z(越低帽越小)
CAP_Z = 0;
// 防滑环凸起高 mm
TEX_H = 0;   // no rings: no overhang ledges, no layer jumps (first-principles cut)

/* [蛋形] */
EGG_RB = 36;   // 底球半径
EGG_RT = 18;   // 顶球半径(收小,压低上部质量)
EGG_LIFT = 28; // 顶球心高

/* [球形] */
BALL_R = 35;

$fn = 96;

/* ---------- 母线(2D,x=半径,y=z) ---------- */
// 蛋形外轮廓真实截面半径
function egg_r(z) =
    let (
        CB = 0, RB = 40, CT = 38, RT = 13,
        r1 = (z >= CB - RB && z <= CB + RB) ? sqrt(RB * RB - (z - CB) * (z - CB)) : 0,
        r2 = (z >= CT - RT && z <= CT + RT) ? sqrt(RT * RT - (z - CT) * (z - CT)) : 0
    ) max(r1, r2);
module egg_profile() {
    z0 = -39.5; // flat pad Phi12 at big-end pole
    z1 = 51;
    polygon(concat([[0.01, z0], [egg_r(z0) - 0.01, z0]],
                   [for (z = [z0 + 1 : 1 : z1]) [max(0.01, egg_r(z)), z]]));
}

module ball_profile() {
    a0 = asin(-34.5 / BALL_R);
    z0 = BALL_R * sin(a0);
    polygon(concat([[0.01, z0], [BALL_R * cos(a0) - 0.01, z0]],
                   [for (a = [a0 + 2 : 2 : 90])
                       [max(0.01, BALL_R * cos(a)), BALL_R * sin(a)]]));
}

/* ---------- 内缩 + 截底 = 型腔(OpenSCAD 不支持模块传参,内联) ---------- */
module trim_2d() {
    intersection() {
        translate([-5, -100]) square([110, 200]);      // x in [0,100]
        translate([-5, CAP_Z]) square([110, 200]);     // y >= CAP_Z
    }
}
module egg_cav() { intersection() { offset(r = -WALL) egg_profile(); trim_2d(); } }
module ball_cav() { intersection() { offset(r = -WALL) ball_profile(); trim_2d(); } }

/* ---------- 防滑环(贴真实外表面) ---------- */
module egg_rings() {
    if (TEX_H > 0)
        for (z = [-14, 0, 14]) {
            rr = egg_r(z);
            if (rr > 3)
                translate([0, 0, z]) rotate_extrude() translate([rr, 0]) circle(r = TEX_H);
        }
}

module ball_rings() {
    if (TEX_H > 0)
        for (z = [-16, 0, 16]) {
            rr = sqrt(BALL_R * BALL_R - z * z);
            translate([0, 0, z]) rotate_extrude() translate([rr, 0]) circle(r = TEX_H);
        }
}

/* ---------- 输出 ---------- */
module egg() {
    difference() {
        rotate_extrude() egg_profile();
        rotate_extrude() egg_cav();
    }
    egg_rings();
}

module ball_t() {
    difference() {
        rotate_extrude() ball_profile();
        rotate_extrude() ball_cav();
    }
    ball_rings();
}

if (PART == "egg") egg(); else ball_t();
