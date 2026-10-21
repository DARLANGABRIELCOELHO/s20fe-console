// S20 FE console case — revision 0 envelope study.
// Dimensions marked as estimates in README.md are not ready for a final fit.

$fn = 64;

part = "assembly"; // "assembly", "tray", "lid", or "layout"

// Enclosure envelope (mm). The 80 mm fan drives the width; depth includes
// the 30 mm heatsink, fan clearance, and the fan itself.
case_w = 90;
case_h = 180;
body_d = 79.6;
lid_t = 2.4;
wall = 2.4;
floor_t = 2.4;
corner_r = 3;

// Components from the photo survey (mm).
board_size = [63, 51, 0.8];
board_origin = [13.5, 108];
sub_size = [43, 22, 1.0];
sub_origin = [23.5, 5];
flex_size = [18, 81, 0.3];
flex_origin = [36, 27];
battery_size = [61, 73, 8]; // thickness is an estimate; measure the replacement cell
battery_origin = [14.5, 31];

// Cooling placeholders (mm).
soc_xy = [45, 133]; // approximate center from the thermal-paste mark in the photo
sink_xy = [45, 45];
sink_h = 30;
sink_base_t = 4;
fan_size = 80;
fan_t = 25;
fan_hole_pitch = 71.5; // standard 80 mm fan frame spacing
fan_cutout_d = 76;

// Main board, battery and daughterboard share the phone's portrait layout.
// The board-to-subboard gap is set to the measured 81 mm free flex length.
board_z = 13;
battery_z = 4.2;
flex_z = battery_z + battery_size[2] + 0.3;
sub_z = board_z;
fan_cx = case_w / 2;
fan_cy = soc_xy[1];
fan_z = body_d - fan_t;

module rounded_2d(w, h, r) {
    offset(r = r)
        translate([r, r])
            square([w - 2*r, h - 2*r]);
}

module rounded_prism(w, h, d, r) {
    linear_extrude(height = d)
        rounded_2d(w, h, r);
}

module tray_shell() {
    difference() {
        rounded_prism(case_w, case_h, body_d, corner_r);
        translate([wall, wall, floor_t])
            rounded_prism(case_w - 2*wall, case_h - 2*wall,
                          body_d - floor_t + 0.2, max(1, corner_r - wall));

        // Bottom USB-C opening. The subboard port is centered on the case axis.
        translate([case_w/2 - 7.5, -0.2, -0.2])
            cube([15, wall + 0.4, 9]);

        // Intake and exhaust slots at the lower and upper ends.
        for (i = [0:5]) {
            slot_x = 13 + i*12;
            translate([slot_x, -0.2, -0.2]) cube([7, wall + 0.4, body_d + 0.4]);
            translate([slot_x, case_h - wall - 0.2, -0.2])
                cube([7, wall + 0.4, body_d + 0.4]);
        }
    }

    // Front-cover screw bosses. Their locations avoid the component envelopes.
    for (x = [6, case_w - 6], y = [6, case_h - 6]) {
        difference() {
            translate([x, y, floor_t]) cylinder(d = 7, h = body_d - floor_t);
            translate([x, y, floor_t - 0.1])
                cylinder(d = 2.8, h = body_d - floor_t + 0.2);
        }
    }
}

module lid() {
    difference() {
        translate([0, 0, body_d])
            rounded_prism(case_w, case_h, lid_t, corner_r);

        // Fan opening and its standard four mounting holes.
        translate([fan_cx, fan_cy, body_d - 0.1])
            cylinder(d = fan_cutout_d, h = lid_t + 0.2);
        for (dx = [-fan_hole_pitch/2, fan_hole_pitch/2],
             dy = [-fan_hole_pitch/2, fan_hole_pitch/2]) {
            translate([fan_cx + dx, fan_cy + dy, body_d - 0.1])
                cylinder(d = 4.3, h = lid_t + 0.2);
        }

        // Lid screws at the four corners.
        for (x = [6, case_w - 6], y = [6, case_h - 6])
            translate([x, y, body_d - 0.1]) cylinder(d = 3.2, h = lid_t + 0.2);
    }

    // Simple safety grille over the fan opening.
    intersection() {
        translate([fan_cx, fan_cy, body_d])
            cylinder(d = fan_cutout_d - 2, h = lid_t);
        union() {
            for (x = [-30:10:30])
                translate([fan_cx + x - 0.8, fan_cy - 40, body_d])
                    cube([1.6, 80, lid_t]);
            for (y = [-30:10:30])
                translate([fan_cx - 40, fan_cy + y - 0.8, body_d])
                    cube([80, 1.6, lid_t]);
        }
    }
}

module board_mockup() {
    // Rectangular envelope only; the production PCB is an irregular U shape.
    translate([board_origin[0], board_origin[1], board_z]) {
        color([0.03, 0.32, 0.28]) cube(board_size);
        color([0.18, 0.19, 0.20])
            translate([8, 8, board_size[2]]) cube([46, 29, 0.8]);
    }
}

module battery_mockup() {
    color([0.8, 0.67, 0.22, 0.75])
        translate([battery_origin[0], battery_origin[1], battery_z])
            cube(battery_size);
}

module subboard_mockup() {
    color([0.03, 0.32, 0.28])
        translate([sub_origin[0], sub_origin[1], sub_z]) cube(sub_size);
    // Connector block at the lower edge, aligned with the case opening.
    color([0.68, 0.68, 0.7])
        translate([case_w/2 - 4.5, 2.4, sub_z - 1]) cube([9, 5, 4]);
}

module flex_mockup() {
    color([0.15, 0.15, 0.16])
        translate([flex_origin[0], flex_origin[1], flex_z]) cube(flex_size);
}

module heatsink_mockup() {
    color([0.72, 0.39, 0.16]) {
        translate([soc_xy[0] - sink_xy[0]/2,
                   soc_xy[1] - sink_xy[1]/2, board_z + board_size[2]])
            cube([sink_xy[0], sink_xy[1], sink_base_t]);
        for (i = [0:13])
            translate([soc_xy[0] - sink_xy[0]/2 + 1.5 + i*3.1,
                       soc_xy[1] - sink_xy[1]/2 + 2,
                       board_z + board_size[2] + sink_base_t])
                cube([1.4, sink_xy[1] - 4, sink_h - sink_base_t]);
    }
}

module fan_mockup() {
    // Simplified fan envelope, for checking the stack and overall depth.
    color([0.16, 0.17, 0.19, 0.8])
        translate([fan_cx - fan_size/2, fan_cy - fan_size/2, fan_z]) {
            difference() {
                cube([fan_size, fan_size, fan_t]);
                translate([fan_size/2, fan_size/2, -0.1])
                    cylinder(d = 74, h = fan_t + 0.2);
            }
            translate([fan_size/2, fan_size/2, 0])
                cylinder(d = 30, h = fan_t);
        }
}

module assembly() {
    color([0.28, 0.3, 0.32, 0.35]) tray_shell();
    color([0.38, 0.4, 0.42, 0.55]) lid();
    battery_mockup();
    board_mockup();
    subboard_mockup();
    flex_mockup();
    heatsink_mockup();
    fan_mockup();
}

if (part == "assembly") assembly();
if (part == "tray") tray_shell();
if (part == "lid") lid();
if (part == "layout") {
    battery_mockup();
    board_mockup();
    subboard_mockup();
    flex_mockup();
    heatsink_mockup();
    fan_mockup();
}
