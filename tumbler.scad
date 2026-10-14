/* ============================================================
 * 不倒翁系列 tumbler.scad(9 月龄+ 硬料一体,零嵌入)
 * ------------------------------------------------------------
 * 回正原理:底部几何实心配重 + 上部空腔,重心低于球心(实测
 *          egg 约 -10mm),推倒即回正。切片 **填充 100%**。
 * 蛋形 v3:hull of two spheres(凸包平滑,无双球相贯蘑菇头);
 *          内腔 = 外凸包球半径同减 WALL(凸包下精确平行内缩);
 *          平底 Phi12 切于大端极点(实心帽区切面自然封闭)。
 * 定位:推倒回正+滚动;不作牙胶不啃咬
 * 安全:高 90 / 直径 80,一体无小件无磁铁
 * ============================================================

/* [选择] */
PART = "egg"; // [egg, ball]

/* [壁与造型] */
WALL = 2.6;    // shell thickness mm
CAP_Z = -10;   // ball: solid cap zone below this z
TEX_H = 0;     // rings off (no overhang ledges)

/* [egg hull] */
EGG_RB = 40;   // big (bottom) sphere radius, center z=0
EGG_CT = 38;   // small (top) sphere center height
EGG_RT = 13;   // small sphere radius
EGG_PAD_Z = -39.5;  // flat pad cut plane (Phi12 contact)
CAP_EGG = -10;      // egg: solid ballast below this z

/* [ball] */
BALL_R = 35;

$fn = 96;

/* ---------- egg: 3D hull (smooth, exact offset cavity) ---------- */
module egg_outer() {
    hull() {
        sphere(r = EGG_RB);
        translate([0, 0, EGG_CT]) sphere(r = EGG_RT);
    }
}

module egg_keep() {
    translate([-60, -60, EGG_PAD_Z]) cube([120, 120, 120]); // keep z >= pad
}

module egg_cavity() {
    intersection() {
        hull() {
            sphere(r = EGG_RB - WALL);
            translate([0, 0, EGG_CT]) sphere(r = EGG_RT - WALL);
        }
        translate([-60, -60, CAP_EGG]) cube([120, 120, 140]); // only z >= CAP_EGG
    }
}

module egg() {
    difference() {
        intersection() { egg_outer(); egg_keep(); }
        egg_cavity();
    }
}

/* ---------- ball: 2D profile (unchanged) ---------- */
function ball_r(z) = sqrt(max(0, BALL_R * BALL_R - z * z));

module ball_profile() {
    a0 = asin(-34.5 / BALL_R);
    z0 = BALL_R * sin(a0);
    polygon(concat([[0.01, z0], [BALL_R * cos(a0) - 0.01, z0]],
                   [for (a = [a0 + 2 : 2 : 90])
                       [max(0.01, BALL_R * cos(a)), BALL_R * sin(a)]]));
}

module ball_trim_2d() {
    intersection() {
        translate([-5, -100]) square([110, 200]);
        translate([-5, CAP_Z]) square([110, 200]);
    }
}

module ball_cav() {
    intersection() { offset(r = -WALL) ball_profile(); ball_trim_2d(); }
}

module ball_t() {
    difference() {
        rotate_extrude() ball_profile();
        rotate_extrude() ball_cav();
    }
}

/* ---------- output ---------- */
if (PART == "egg") egg(); else ball_t();
