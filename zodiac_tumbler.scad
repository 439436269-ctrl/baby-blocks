/* ============================================================
 * 12 生肖不倒翁 zodiac_tumbler.scad(9 月龄+ 单色免支撑)
 * ------------------------------------------------------------
 * 架构:共用蛋身回正内核(tumbler 同款:配重帽+上部空腔,
 *      offset 内缩保证壁厚,重心 -6mm 级,推倒回正)+ 12 款
 *      生肖顶部特征(全竖立/贴面几何,FDM 正放免支撑)。
 * 打印:正放大头朝下;**填充必须 100%**(回正前提);
 *      每板 6 个(3x2,间距 78mm),12 款 = 2 板;免 AMS 单色
 * 安全:高约 104(含特征)/ 宽 72,一体无小件;不作牙胶
 * ============================================================

/* [选择] */
// 生肖(12 选 1)
ZODIAC = "rat"; // [rat,ox,tiger,rabbit,dragon,snake,horse,goat,monkey,rooster,dog,pig]
// 视图:figure=单只成品 / plate=同板 6 只排样
VIEW = "figure"; // [figure, plate]

/* [回正内核(与 tumbler.scad 同参)] */
WALL = 3.5;
CAP_Z = -8;
EGG_RB = 36;
EGG_RT = 18;
EGG_LIFT = 28;
TEX_H = 1.5;
// 蛋顶绝对高度 = EGG_LIFT + EGG_RT = 46
TOP = EGG_LIFT + EGG_RT; // 46

$fn = 72;

/* ---------- 蛋身(母线 + 内缩空腔) ---------- */
function egg_r(z) =
    let (
        r1 = (z >= -EGG_RB && z <= EGG_RB) ? sqrt(EGG_RB * EGG_RB - z * z) : 0,
        r2 = (z >= EGG_LIFT - EGG_RT && z <= EGG_LIFT + EGG_RT)
            ? sqrt(EGG_RT * EGG_RT - (z - EGG_LIFT) * (z - EGG_LIFT)) : 0
    ) max(r1, r2);

module egg_profile() {
    z0 = -EGG_RB + 6;
    polygon(concat([[0.01, z0], [egg_r(z0) - 0.01, z0]],
                   [for (z = [z0 + 1 : 1 : TOP]) [max(0.01, egg_r(z)), z]]));
}

module trim_2d() {
    intersection() {
        translate([-5, -100]) square([110, 200]);
        translate([-5, CAP_Z]) square([110, 200]);
    }
}

module egg_cav() {
    intersection() {
        offset(r = -WALL) egg_profile();
        trim_2d();
    }
}

module egg_body() {
    difference() {
        rotate_extrude() egg_profile();
        rotate_extrude() egg_cav();
    }
    if (TEX_H > 0)
        for (z = [-14, 0, 14]) {
            rr = egg_r(z);
            if (rr > 3)
                translate([0, 0, z]) rotate_extrude() translate([rr, 0]) circle(r = TEX_H);
        }
}

/* ---------- 生肖特征工具(全部竖立/贴面,免支撑) ---------- */
// 圆耳(球,埋一半入蛋顶)
module ear(sx, sy, z, d) {
    translate([sx, sy, z]) sphere(d = d);
}
// 竖椭圆耳(扁柱,兔/马/猪/狗用)
module upright_ear(sx, sy, z, w, t, h, tilt) {
    hull() {
        translate([sx, sy, z]) sphere(d = t);
        translate([sx + tilt, sy, z + h]) sphere(d = t * 0.7);
    }
}
// 短角(向上外倾圆锥,牛/羊/龙)
module horn(sx, sy, z, h, r, lean) {
    hull() {
        translate([sx, sy, z]) sphere(d = r * 2);
        translate([sx + lean, sy, z + h]) sphere(d = r * 0.9);
    }
}
// 鼻盘(正面贴附扁圆柱,猪/狗/鼠)
module snout(y, z, d, t) {
    translate([0, y, z]) rotate([90, 0, 0]) cylinder(d = d, h = t, center = true);
}
// 竖鳍(冠/鬃,沿 X 或 Y 薄片,竖直打印)
module crest(w, t, h, z, y) {
    hull() {
        translate([-w / 2, y, z]) sphere(d = t);
        translate([w / 2, y, z]) sphere(d = t);
        translate([-w / 4, y, z + h]) sphere(d = t);
        translate([w / 4, y, z + h]) sphere(d = t);
    }
}

/* ---------- 12 生肖特征 v2(顶部轮廓 + 脸部大五官) ---------- */
// 眼:球心按比例埋入蛋面,凸出约 4mm
module eyes(z, x, d) {
    r = egg_r(z);
    yy = r * 0.82;
    for (s = [-1, 1]) translate([s * x, yy, z]) sphere(d = d);
}
// 前向圆锥鼻(根部埋入 2mm)
module nose_cone(z, d, h) {
    translate([0, egg_r(z) - 2, z]) rotate([-90, 0, 0])
        cylinder(d1 = d, d2 = 1.5, h = h);
}
// 贴脸横纹(埋入)
module cheek_bar(z, x, w) {
    for (s = [-1, 1]) translate([s * x, egg_r(z) * 0.7, z]) rotate([0, 90, 0])
        cylinder(d = 3.5, h = w, center = true);
}

module features(k) {
    z = TOP - 6;
    if (k == "rat") {           // 鼠:大眼+尖鼻+圆耳
        eyes(31, 10, 10); nose_cone(24, 7, 9);
        ear(-13, 6, z, 15); ear(13, 6, z, 15);
    } else if (k == "ox") {     // 牛:宽鼻盘+眼+上倾角
        eyes(32, 11, 10);
        translate([0, egg_r(24) + 1, 24]) rotate([-90, 0, 0]) cylinder(d = 16, h = 7, center = false);
        horn(-12, 2, z, 18, 5, -7); horn(12, 2, z, 18, 5, 7);
        ear(-16, 8, z - 4, 11); ear(16, 8, z - 4, 11);
    } else if (k == "tiger") {  // 虎:大眼+鼻球+颊纹+圆耳
        eyes(32, 11, 12); nose_cone(25, 9, 6);
        cheek_bar(28, 14, 12); cheek_bar(22, 13, 11);
        ear(-14, 4, z, 16); ear(14, 4, z, 16);
    } else if (k == "rabbit") { // 兔:小眼小鼻+招牌长耳
        eyes(31, 9, 8); nose_cone(25, 6, 6);
        upright_ear(-9, 2, z, 0, 10, 24, -3);
        upright_ear(9, 2, z, 0, 10, 24, 3);
    } else if (k == "dragon") { // 龙:眼+鼻+后倾角
        eyes(31, 10, 10); nose_cone(24, 8, 7);
        horn(-11, -4, z, 20, 5, -5); horn(11, -4, z, 20, 5, 5);
        for (i = [0:3])
            translate([0, -18 + i * 9, egg_r(-18 + i * 9) - 1])
                rotate([0, 60, 0]) cylinder(d = 6, h = 10, center = true);
    } else if (k == "snake") {  // 蛇:超大眼+兜帽鳍(无鼻)
        eyes(31, 11, 14);
        hull() {
            translate([0, -11, z]) rotate([-25, 0, 0]) cylinder(d = 9, h = 5, center = true);
            translate([0, -17, z + 15]) rotate([-25, 0, 0]) cylinder(d = 24, h = 5, center = true);
        }
        ear(-8, 8, z + 2, 8); ear(8, 8, z + 2, 8);
    } else if (k == "horse") {  // 马:眼+长鼻梁+耳鬃
        eyes(32, 10, 10);
        hull() {
            translate([0, egg_r(26) * 0.8, 26]) sphere(d = 8);
            translate([0, egg_r(34) * 0.8, 34]) sphere(d = 9);
        }
        upright_ear(-8, 0, z, 0, 9, 18, -2);
        upright_ear(8, 0, z, 0, 9, 18, 2);
        hull() {
            translate([0, -10, z + 6]) sphere(d = 5);
            translate([0, -26, egg_r(-26) + 2]) sphere(d = 5);
            translate([0, -10, z + 16]) sphere(d = 4);
        }
    } else if (k == "goat") {   // 羊:眼+鼻+卷角+须(须已埋)
        eyes(31, 10, 10); nose_cone(25, 7, 6);
        horn(-12, -2, z, 12, 4, -6); horn(12, -2, z, 12, 4, 6);
        horn(-12, -8, z + 8, 8, 3.5, -4); horn(12, -8, z + 8, 8, 3.5, 4);
        translate([0, 23, z - 14]) cylinder(d = 7, h = 16, center = true);
    } else if (k == "monkey") { // 猴:大眼+小鼻+大侧耳
        eyes(32, 11, 13); nose_cone(25, 8, 5);
        ear(-20, 0, z - 6, 15); ear(20, 0, z - 6, 15);
    } else if (k == "rooster"){// 鸡:眼+喙+肉髯+冠
        eyes(31, 9, 8);
        translate([0, egg_r(25) - 2, 25]) rotate([-90, 0, 0]) cylinder(d1 = 9, d2 = 1.5, h = 12);
        translate([0, egg_r(19) + 1, 19]) sphere(d = 7);   // 冠下肉髯
        for (i = [-1:1])
            translate([i * 8, -2 + abs(i) * -3, z + 10 - abs(i) * 3]) sphere(d = i == 0 ? 13 : 11);
        ear(-10, 4, z - 6, 9); ear(10, 4, z - 6, 9);
    } else if (k == "dog") {    // 狗:圆鼻+眼+垂耳
        eyes(31, 10, 10); snout(31, z - 6, 12, 8);
        upright_ear(-18, 4, z - 8, 0, 10, 22, -4);
        upright_ear(18, 4, z - 8, 0, 10, 22, 4);
    } else if (k == "pig") {    // 猪:大鼻盘+眼+竖耳
        snout(32, z - 6, 20, 8); eyes(32, 12, 10);
        upright_ear(-9, -2, z, 0, 11, 15, -3);
        upright_ear(9, -2, z, 0, 11, 15, 3);
    }
}
module zodiac_one(k) {
    egg_body();
    features(k);
}

/* ---------- 输出 ---------- */
// PLATE 选板:1=鼠牛虎兔龙蛇 / 2=马羊猴鸡狗猪
PLATE = 1; // [1, 2]

module zodiac_one(k) {
    egg_body();
    features(k);
}

if (VIEW == "figure") {
    zodiac_one(ZODIAC);
} else {
    // 打印排版:3x2 居中(列距78/行距84),单板 6 只,256 床两板打完 12 款
    ks = (PLATE == 1)
        ? ["rat", "ox", "tiger", "rabbit", "dragon", "snake"]
        : ["horse", "goat", "monkey", "rooster", "dog", "pig"];
    for (i = [0:5])
        translate([(i % 3 - 1) * 78, (i < 3 ? 42 : -42), 0])
            zodiac_one(ks[i]);
}