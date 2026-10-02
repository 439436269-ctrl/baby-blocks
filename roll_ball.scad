/* ============================================================
 * 空心滚滚球(9 月龄爬行追逐玩具)· 纯硬料直打
 * ------------------------------------------------------------
 * 定位:闭合空腔轻质球,滚动追逐/抓握扔掷玩;**不作牙胶不啃咬**
 *       (硬料件,无嵌入配重——不倒翁回正功能主动放弃,内部留空)
 * 安全:直径 70mm(远超 45mm 红线,整吞不可能);一体无小件、无磁铁
 * 打印:PETG/PLA,球极点朝下平放,内部空腔上半倒扣逐层收口自封
 *       (收口区悬挑小、免支撑);壁 3.2mm = 0.4 嘴 8 圈,防摔裂
 * ============================================================

/* [球体] */
// 球直径 mm
BALL_D = 70;
// 壁厚 mm(建议 = 喷嘴 0.4 的整数倍)
WALL = 3.2;
// 防滑纬环条数(0 关闭)
RINGS = 3;
// 纬环凸起高 mm(管心贴球面)
TEX_H = 1.5;

$fn = 96;

R_OUT = BALL_D / 2;
R_IN = R_OUT - WALL;

module shell() {
    difference() {
        sphere(d = BALL_D);
        sphere(d = BALL_D - 2 * WALL);
    }
}

// 贴球面的纬环(一半沉入球面,一半凸出)
module ring_bump(z) {
    r_lat = sqrt(R_OUT * R_OUT - z * z);
    translate([0, 0, z]) rotate_extrude() translate([r_lat, 0]) circle(r = TEX_H);
}

module ball() {
    shell();
    if (RINGS == 3) {
        ring_bump(0);
        ring_bump(-R_OUT * 0.4);
        ring_bump(R_OUT * 0.4);
    } else if (RINGS == 1) {
        ring_bump(0);
    }
}

ball();
