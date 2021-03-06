include <pulleys.scad>
use <Chamfer.scad>
use <parametric_involute_gear_v5.0.scad>
use <bearing.scad>

// todo
// Add fixings (hex-head bolts) to:
//    end supports
//    insulating columns



// overall size of the board
base_l = 250;
base_d = 180;
base_thick = 10;

// global fit tolerance
tol = 0.25;


// clearance from bottom of disk the top of the board
disk_clearance = 20;

// radius of the disks
disk_radius = base_d-50;

// thickness of disks
disk_thick = 1.0;

// radius of main axle
axle_diam = 3;

// thickness of pulleys/gears
pulley_thick = 3;
// thickness of rubbed band for pulleys
band_thick = 1;

// thickness of the supports
support_thick = base_thick*2;

// offset of the disk from the back of the supports
disk_offset = 20;


// dimensions of the boss on the disk
disk_boss_radius = disk_radius * 0.125;
disk_boss_length = disk_boss_radius / 2;


//////// sector specification
sector_inner_rad = disk_radius * 0.6;
sector_outer_rad = disk_radius * 0.85;
n_sectors = 32;

// 1.0 = no space, 0.5=half space
sector_spacing = 0.4;

// scaling of upper and lower circular segments
upper_rake = 1.35;
lower_rake = 1.;

// thickness of sectors
sector_thick = 1.0;


////// spark arms
// thickness of all conductive rods
rod_thick = 3;

// spark arm
rod_angle = 40; // angle of arms
spark_gap = 0; // fixed gap
spark_gap_ball = 12; // end ball radius
spark_gap_micro_ball = 4; // discharge ball radius



// length of the pull arm
pull_arm_len = 80;

// rise of spark arm above main conductor lines
spark_rise = 40;

//////// pulleys / gears
pulleys = 1; // if 1, use pulleys, else use gears
pulleys_inside = 0; // if 1, pulleys on inside of support, else outside
pulley_ratio = 7;


bearing_thick = 15;
bearing_diameter = 51.7;



// computed constants
axle_height = disk_radius + disk_clearance + base_thick;
inner_circum = sector_inner_rad * 2 * PI;
outer_circum = sector_outer_rad * 2 * PI;
sector_lower_size = lower_rake * sector_spacing*0.5*inner_circum/n_sectors;
sector_upper_size = upper_rake * sector_spacing*0.5*outer_circum/n_sectors;







$fn = 30;


// axle
module axle(h, r)
{
    cylinder(h,r,r,$fn=6);    
}


// a cylinder the same dimensions as the bearing hull
module std_bearing_blank()
{
    cylinder(bearing_thick+tol, bearing_diameter/2+tol, bearing_diameter/2+tol);
   
}

// the bearing 
module std_bearing()
{
    gear_bearing(axle_diam*2+tol, bearing_thick, bearing_diameter);          
}


// rounded trapezoid
module support_polygon(upper, lower, height,  chamfer, rounded=1)
{
    union()
    {
               polygon(points=[
    [-lower,-chamfer], 
    [-upper, height], 
    [0, height+upper],
    [upper,height],
    [lower,-chamfer]]);
     
    if(rounded)
    {    
        // upper rounded circle   
        translate([0,height])
        circle(upper);
    }
        
    }
}

// extrude the children to the given thickness
// with a 45 degree chamfer of the given depth
module chamfer_extrude(thick, chamfer)
{
           hull()
            {
                translate([0,0,chamfer])
                linear_extrude(thick-2*chamfer)
                {                    
                    children();
                }
                
                translate([0,0,0])
                linear_extrude(chamfer)
                {              
                    offset(delta=-chamfer)
                    children();
                }
                
                translate([0,0,thick-chamfer])
                linear_extrude(chamfer)
                {              
                    offset(delta=-chamfer)
                    children();
                }                                                
            }     
}


// pulley, with dimensions in mm
module mmpulley(outer, inner, thick, belt_thick)
{
    inch = 25.4; //mm
    translate([0,0,belt_thick/2])
    {
        
        difference()
        {
        custompulley(beltB=thick/inch, beltH=belt_thick/inch, beltangle=40, definedD=outer/inch, arborD=0, key=0);//, key=.125, res=60, padding=true, screw=false);    
            
        rotate([0,0,0])
        translate([0,0,-100])
        axle(200, inner);
             
        }
    }
}

// simple pulley/gear washers
module washer(inner, outer, thick)
{
    difference()
    {
        cylinder(thick, outer, outer);
        translate([0,0,-tol])
        {
            cylinder(thick*2, inner, inner);
        }
    }
}


// create a simple brush
module brush(n_teeth, min_cut, max_cut, width, thick)
{
    tooth_width = width/n_teeth;
    translate([-width/2,0,0])
    {
    linear_extrude(thick)
    {
        union()
        {
            for (i = [0 : n_teeth])
            {        
                polygon([[i*tooth_width,0], 
                [i*tooth_width,min_cut], 
                [(i+0.5)*tooth_width,max_cut], 
                [(i+1)*tooth_width,min_cut],
                [(i+1)*tooth_width,0]]);
            }
        }
    }
}    
}

// completely flat extruded sector
module flat_sector(low_rad, high_rad, sector_len, thick)
{
    color("SlateGray")
    linear_extrude(thick)
    {
        hull()
        {
            
            circle(low_rad);
            translate([sector_len,0,0])
            circle(high_rad);
            
            
            
        }
    }
    
}

// rounded sector
module sector(low_rad, high_rad, sector_len, thick)
{
    color("SlateGray")
    
    translate([0,0,thick])
    intersection()
    {
        hull()
        {
            
            scale([1,1,thick/low_rad])
            sphere(low_rad);
                
            
            translate([sector_len,0,0])
            scale([1,1,thick/low_rad])
            sphere(high_rad);                                    
        }
      rotate([0,180,0])
     cylinder(200, 200, 200);   
         
    }
    
}




// disk



module disk()
{
    rotate([0,180,0])
        difference()
        {
            union()
            {
                linear_extrude(disk_thick)
                {
                    circle(disk_radius);
                }
                translate([0,0,-disk_boss_length])
                {
                    chamferCylinder(disk_boss_length+disk_thick, disk_boss_radius, disk_boss_radius, 1); 
                }
            }
            translate([0,0,-100])
            axle(200, axle_diam+tol);
        }
        
        // sectors
        for(i=[0:n_sectors])
        {
            rotate([0,0,(360/n_sectors)*i])
            translate([sector_inner_rad,0,-disk_thick/2])
            {
                sector(sector_lower_size, sector_upper_size, sector_outer_rad-sector_inner_rad, sector_thick);
            }
        }
    
    
    
    
    
}


// the disks


disk_x = -base_l/2+support_thick+disk_offset;

translate([500,200,0])
{
    disk();
}

translate([-500,250,0])
{
    rotate([0,0,180])
    {
        disk();
    }
}

axle_inset = 0;
axle_extend = pulley_thick * 2 ;


// main axle (hex keyed)
color("Green")
translate([0,300,0])
{
    rotate([90,0,90])
    {
        axle(base_l-support_thick-tol*2+pulley_thick*2  , axle_diam);
    }
}

/////////////////
// conductor guide that supports the cross connecting rod
conductor_guide_l = support_thick;
conductor_guide_d = support_thick*3;
conductor_guide_h = conductor_guide_l*0.75;

translate([-conductor_guide_l/2,0,base_thick])
{
    difference()
    {
       
    rotate([90,0,90])
        chamfer_extrude(conductor_guide_l, 2)
        {
            
            support_polygon(conductor_guide_d/4, conductor_guide_d/2, conductor_guide_h/2, 2);
        }
    translate([0,0,conductor_guide_h/2])
        rotate([0,90,0])
        {
            cylinder(200, rod_thick+tol, rod_thick+tol);
        }
    }
    
    
    
}
//////////////////////

// spark supports
spark_h = axle_height;
spark_radius = 4;
spark_inset = 10;
pin_radius = 2;
spark_pin = 10;
spark_ball = 8;




spark_support_centre = -base_d/2+spark_radius+spark_inset;

spark_span = spark_support_centre * -2;

// length of the arm so that the spark balls just touch
rod_arm_len = (1.0/sin(rod_angle)) * (spark_span/2 - spark_gap_ball - spark_gap_micro_ball/1.5);

// length of the spark gap pull arm


module spark_support()
{
    total_h = spark_h + spark_rise;
    cylinder(spark_h-base_thick, spark_radius, spark_radius);
    
   
    
    
        
    translate([0,0,-1])
    chamferCylinder(support_thick*0.5+1, spark_radius*2, spark_radius*2);
    chamferCylinder(support_thick*1.5, spark_radius*1.5, spark_radius*1.5);
    
    
    // central connection ball
    translate([0,0,spark_h-base_thick])
    color("SlateGray")
    difference()
    {
        sphere(spark_ball);
        rotate([0,0,0])
        {
            translate([0,0,-100])
            cylinder(200,rod_thick+tol,rod_thick+tol, center);
        }
        
    }
    
       color("SlateGray")
        translate([0,0,spark_h-base_thick])    
        cylinder(spark_rise+spark_ball*2, rod_thick, rod_thick);
     
    
}


// distance of insulating pull arm back from connection
// ball
pull_offset = 30;

module spark_arm(positive)
{
                 
        // spark arm
        //translate([0,0,total_h-base_thick+spark_ball*2]) 
        color("SlateGray")   
        sphere(spark_ball);
        color("LightBlue")
        cylinder(rod_arm_len, rod_thick, rod_thick);
        color("SlateGray")
        cylinder(rod_arm_len*0.5, rod_thick, rod_thick);
        scale_factor = positive ? 1.25 : (1.0/1.25);
        color("SlateGray")
        translate([0,0,rod_arm_len])
        {
            
            scale(scale_factor)
            sphere(spark_gap_ball);
        }
        
        if(positive)
        {
        // micro ball
        color("SlateGray")
        translate([0,0,rod_arm_len])
        {
            rotate([-(90-rod_angle),0,0])
            translate([0,0,spark_gap_ball*scale_factor+spark_gap_micro_ball*0.25])
            sphere(spark_gap_micro_ball);
        }
    }
        
        // pull arm
        rotate([-180,0,0])
        {
            color("SlateGray")
            cylinder(pull_offset, rod_thick, rod_thick);
            translate([0,0,pull_offset])
            color("Yellow")
            chamferCylinder(pull_arm_len, rod_thick*2, rod_thick*2, 2);
            translate([0,0,pull_arm_len])
            {
                //sphere(rod_thick*2);
            }
        }
        
        
    
}

translate([0,spark_support_centre,base_thick])
{
    spark_support();
    
}



    {
        
        
        translate([50,0, pull_arm_len+spark_rise])    
              
        spark_arm(0);
    }

translate([0,-spark_support_centre,base_thick])
{
    rotate([0,0,180])
    {
        spark_support();
        {
        
                
           
        }
    }
}

translate([-50,0, pull_arm_len+spark_rise])    
               
            spark_arm(1);

conductor_thick = 3;
conductor_distance = 2;
conductor_offset =  conductor_distance + conductor_thick + disk_thick;

conductor_x = disk_x + conductor_offset;

conductor_rad = disk_radius/(2.2);

inductor_thick = 0.5;
inductor_rad = conductor_rad / 2;

module cylinder_ep(p1, p2, r1, r2) {
    hull() {
        translate(p1)sphere(r=r1,center=true);
        translate(p2)sphere(r=r2,center=true);
    }
}

module cylinder_path(pts, rad)
{
    n = len(pts);
    for(i=[0:n-2])
    {
        cylinder_ep(pts[i], pts[i+1], rad, rad);
    }
    
}

   
// distance from conductor to disk
conductor_standoff = 10;

///////// Brush
// width of brush
brush_width = disk_radius/3;
// thickness of brush
brush_thick = 0.2;
// length of brush (to touch disk)
brush_extend = conductor_standoff+rod_thick+tol;
// tooth cut depth
brush_tooth_depth = 2;
// number of teeth
brush_teeth = 15;

module squlinder(l, r1, r2)
{
    intersection()
    {
        translate([0,0,-tol])
        cylinder(l,r1,r1);
        cube([r2*2,100,200], center=true);
    }
    
}


module dowel(dlen, dowel_rad=5, male=1)
{
    rad = male ? dowel_rad : dowel_rad + tol;
    length = male ? dlen : dlen + tol;
    translate([0,0,-dowel_rad*0.25])    
    if(male)        
        chamferCylinder(length, rad, rad, dowel_rad*0.25);
    else
        cylinder(length, rad, rad);
}


module dowel_set(length, spacing, n, rad=5, male=1)
{
    
    for(i=[1:n])
    translate([i*spacing - ((n+1)/2)*spacing,0,0])
        dowel(length, rad, male);
}



module conductor(induct)
{
   translate([0,0,-(conductor_thick+conductor_x)])
    rotate([0,180,0])
    {
        
        
        cylinder(-conductor_x-inductor_thick-spark_ball+1, rod_thick, rod_thick);
        
        // spark shield
        translate([0,0,-conductor_x])
        {
            cylinder(conductor_thick, conductor_rad, conductor_rad);
        }
        
        // inductor
        color("SlateGray")
        translate([0,0,-conductor_x-inductor_thick])
        {
            squlinder(inductor_thick, inductor_rad, inductor_rad*0.5);
            intersection()
            {
                difference()
                {
                    union()
                    {
                    sphere(spark_ball);
                    // horizontal connector bar
        
                    
                    }
                    translate([0,0,-rod_thick-tol])
                    
                    rotate([90,0,0])
                    translate([0,0,-rod_thick])
                    cylinder(200, rod_thick+tol, rod_thick+tol, center=false);
                }
                translate([0,0,-inductor_thick*100])
                {
                cylinder(inductor_thick*100, inductor_rad, inductor_rad);
            }
        }
        }
        
       

 
        
    }
    
}


translate([-300,200,0])
brush(brush_teeth, brush_extend-brush_tooth_depth, brush_tooth_depth, brush_width, brush_thick);
translate([-200,200,0])
brush(brush_teeth, brush_extend-brush_tooth_depth, brush_tooth_depth, brush_width, brush_thick);
translate([-100,200,0])
brush(brush_teeth, brush_extend-brush_tooth_depth, brush_tooth_depth, brush_width, brush_thick);
translate([0,200,0])
brush(brush_teeth, brush_extend-brush_tooth_depth, brush_tooth_depth, brush_width, brush_thick);


// how far conductor extends beyond spark shield
conductor_extend = 10;

conductor_outside = conductor_rad+conductor_extend;
module brush_arm()
{
    // brush arm
    rotate([0,90,0])
    {
            color("LightBlue")
            cylinder_path([
            [0,0,-conductor_x-rod_thick],
            [0,conductor_outside,-conductor_x-rod_thick],
            [0,conductor_outside,-disk_x+conductor_standoff+rod_thick],
            [0,0,-disk_x+conductor_standoff+rod_thick],
            
            
            ], rod_thick);
            
            
    }
        
}
module neutral()
{
    
   color("LightBlue")
    // neutraliser
    rotate([0,90,0])
    {
        rotate([0,0,180])
        {
            base_h = +rod_thick+base_thick+conductor_guide_h/2-rod_thick;
    cylinder_path([            
                [spark_h,0,-disk_x+conductor_standoff+rod_thick],
                [spark_h, conductor_outside,-disk_x+conductor_standoff+rod_thick],
                [base_h, conductor_outside,-disk_x+conductor_standoff+rod_thick],
                [base_h,spark_support_centre,0.5*(-disk_x+conductor_standoff+rod_thick)],                         
                [base_h,spark_support_centre,0],                         
                
                ], rod_thick);
        }
    }
    
        
}



translate([0,400,0])
rotate([45,0,180])
{
    
        
        neutral();
    
     
}

translate([100,600,0])
rotate([45,0,180])
{
    
        
        neutral();
    
     
}


translate([-100,400,0])
brush_arm();
translate([-50,400,0])
brush_arm();
translate([0,400,0])
brush_arm();
translate([50,400,0])
brush_arm();




translate([-200,-300,0])
{
    conductor(1);
   
}


    
translate([-400,-300,0])
{
    conductor(1);

}

translate([-600,-300,0])
{
    conductor(0);

}

translate([-800,-300,0])
{
    conductor(0);

}



// supports
support_above_axle = disk_clearance;
support_h = axle_height + support_above_axle;

support_w = base_d * 0.5;
support_lower_w = support_w / 1.5;
support_thin = 0.5;
//support_upper_w = support_lower_w * support_thin;

support_rim = 5;
support_upper_w = bearing_diameter/2 + support_rim;

// handle
handle_thick = 3;
handle_len = support_w*0.6666;

handle_clearance = 15;
handle_h = handle_len + handle_clearance;
handle_protrude = handle_len/3;

support_chamfer = 2;





handle_axle_insert = (pulleys_inside) ? support_thick + pulley_thick + tol  : support_thick + bearing_thick; 

// how far the handle extends into the support



module support(open)
{
    
        difference()
        {
         
            chamfer_extrude(support_thick, support_chamfer)
            {
                support_polygon(support_upper_w,
                support_lower_w, support_h, support_chamfer, 1);
            }
            
            
            translate([0,axle_height-base_thick,-tol])
            {
                std_bearing_blank();
            }
            
            // handle cut
            if(!open)
            {
                
            translate([0,handle_h-base_thick,-tol])
            {
                std_bearing_blank();
            }
                
                translate([0,axle_height-base_thick, -60])
                {
                    rotate([0,0,0])
                    {
                        cylinder(120, axle_diam+tol*2, axle_diam+tol*2, center=false);
                    }
                }
                
                // cutout for the handle axle
                translate([0,handle_h-base_thick, 60+handle_axle_insert])
                {
                    rotate([0,180,0])
                    {
                        cylinder(120, axle_diam+tol, axle_diam+tol, center=false);
                    }
                }
                
                
            }
            
        }
        
        
       
        
}

translate([800,0,support_thick])
{
    rotate([0,180,0])    
    support(1);
}

translate([600,0,support_thick])
{
    rotate([0,180,180])
    {        
        support(0);
    }
}


// the base itself
translate([-base_l/2-300, -base_d/2, 0])
{
    chamfer = 3;
    translate([-chamfer,-chamfer,0])
    {
    chamferCube(base_l+2*chamfer, base_d+2*chamfer, base_thick, chamfer);
    }
    
    translate([base_l/2,base_d/2,0])
    rotate([0,0,90])
    dowel_set(30, 30, 3, rad=3.0, male=1);
}



// handle

pulley_offset_x = (pulleys_inside) ? support_thick + pulley_thick*2 + tol  : 0;
gear_offset_x = (pulleys_inside) ? pulley_offset_x - pulley_thick : 0;

washer_thick = 1;

    
module handle()
{
    handle_offset = 2 + pulley_thick*2 + tol*2;
    // handle + spindle
    
    rotate([0,90,0])
    translate([0,0,-support_thick+handle_offset+handle_thick])
    axle(support_thick+handle_offset+handle_thick, axle_diam);
    
    cylinder_path([
    
    [-handle_offset,0,0], [-handle_offset,handle_len,0],
    [-handle_offset,handle_len,0],
    [-handle_offset-handle_protrude,handle_len]
    ], handle_thick);
    
    
    // handle grip
   
    translate([-handle_offset,handle_len,0])
    {
        
        
        rotate([0,-90,0])
        {
            
            difference()
            {
            union()
            {
                cylinder(handle_protrude, handle_thick, handle_thick*2);
                translate([0,0,handle_protrude])
                {
                    sphere(handle_thick*2);
                }
            }
            
               cylinder(handle_protrude, handle_thick+tol, handle_thick+tol);
            
        }
        }
        
    }
    
}

translate([0,100,0])
handle();

    



if(pulleys)
{
    // small axle pulley
    translate([0,-200,0])
    mmpulley(handle_len*2/pulley_ratio,axle_diam+tol,pulley_thick,band_thick);
                
    translate([0,-500,0])
    mmpulley(handle_len*2,axle_diam+tol,  
        pulley_thick,band_thick);
                
    
}




// axle bearings
translate([100,-100,0])
std_bearing();

translate([200,-100,0])
std_bearing();

translate([300,-100,0])
std_bearing();



// leyden jars
leyden_h = 70;
leyden_rad = 12;
leyden_wall = 0.25;
leyden_base = 10;
leyden_chamfer = 4;
leyden_conduct_h = leyden_h * 0.7;


module leyden_cap(base, base_rad, chamfer, leyden_h, wall_thick, terminal_h)
{
    cap_h = base;
        translate([0,0,base-cap_h+wall_thick])
        // cap
        difference()
        {
            chamferCylinder(base, base_rad, base_rad,chamfer*0.5);
            translate([0,0,-wall_thick])
            {
               cylinder(base, leyden_rad+tol, leyden_rad+tol);
            } 
            // under cut
            scale([1,1,0.55])
                sphere(base_rad*0.75);
        }
        
        // terminal
        
        translate([0,0,base-chamfer])
        {
            intersection()
            {
                scale([1,1,0.5])
                    sphere(base_rad);
                cylinder(200, base_rad, base_rad);
            }
        }
        
        translate([0,0,0])       
        color("SlateGray")    
        cylinder(terminal_h+base, rod_thick, rod_thick);
        
        
        
        // terminal ball
        color("SlateGray")
        translate([0,0,terminal_h+base])
        {
            difference()
            {
                sphere(spark_ball);
                rotate([0,90,0])
                translate([0,0,-50])
                cylinder(100, rod_thick+tol, rod_thick+tol);
            }
            
        }
}


module leyden(leyden_h, leyden_rad, wall_thick, base, terminal_h, jar=1, cap=1)
{
    
    chamfer = leyden_chamfer;
    base_rad = leyden_rad * 1.25;
    
    conduct_h = leyden_conduct_h;
    
    if(jar)
    {
        translate([0,0,-chamfer])
        chamferCylinder(base+chamfer, base_rad, base_rad, chamfer);
        translate([0,0,base])
        difference()
        {
            union()
            {
                color("White")
                cylinder(leyden_h-base, leyden_rad, leyden_rad);
                color("SlateGray")
                cylinder(conduct_h , leyden_rad+tol, leyden_rad+tol);
            }
                
            
            translate([0,0,wall_thick])
            {
                
            cylinder(leyden_h, leyden_rad-wall_thick-tol, leyden_rad-wall_thick-tol);
            color("SlateGray")    
            cylinder(conduct_h , leyden_rad-wall_thick, leyden_rad-wall_thick);
            }
        }
    }

    if(cap)
    {
        translate([-300,-300,0])
        leyden_cap(base, base_rad, chamfer, leyden_h, wall_thick, terminal_h);
        
        
    }
}

leyden_x = 50;
leyden_terminal = spark_h - (leyden_h+leyden_base+base_thick);

use_leyden = 1;
leyden_jars = 1;
leyden_caps = 1;

if(use_leyden)
{
// leyden jars

translate([0,-1000,0])
{    
translate([-leyden_x,-spark_support_centre,base_thick])
    {
        leyden(leyden_h, leyden_rad, leyden_wall, leyden_base, leyden_terminal, 
        jar=leyden_jars, cap=leyden_caps);
    }
translate([leyden_x,-spark_support_centre,base_thick])
    {
        leyden(leyden_h, leyden_rad, leyden_wall, leyden_base, leyden_terminal,
        jar=leyden_jars, cap=leyden_caps);
    }

translate([-leyden_x,spark_support_centre,base_thick])
    {
        leyden(leyden_h, leyden_rad, leyden_wall, leyden_base, leyden_terminal,
        jar=leyden_jars, cap=leyden_caps);
    }
translate([leyden_x,spark_support_centre,base_thick])
    {
        leyden(leyden_h, leyden_rad, leyden_wall, leyden_base, leyden_terminal,
        jar=leyden_jars, cap=leyden_caps);
    }
}
}

// Copyright 2011 Cliff L. Biffle.
// This file is licensed Creative Commons Attribution-ShareAlike 3.0.
// http://creativecommons.org/licenses/by-sa/3.0/

// You can get this file from http://www.thingiverse.com/thing:3575
use <parametric_involute_gear_v5.0.scad>

// Couple handy arithmetic shortcuts
function sqr(n) = pow(n, 2);
function cube(n) = pow(n, 3);

// This was derived as follows:
// In Greg Frost's original script, the outer radius of a spur
// gear can be computed as...
function gear_outer_radius(number_of_teeth, circular_pitch) =
	(sqr(number_of_teeth) * sqr(circular_pitch) + 64800)
		/ (360 * number_of_teeth * circular_pitch);

// We can fit gears to the spacing by working it backwards.
//  spacing = gear_outer_radius(teeth1, cp)
//          + gear_outer_radius(teeth2, cp);
//
// I plugged this into an algebra system, assuming that spacing,
// teeth1, and teeth2 are given.  By solving for circular pitch,
// we get this terrifying equation:
function fit_spur_gears(n1, n2, spacing) =
	(180 * spacing * n1 * n2  +  180
		* sqrt(-(2*n1*cube(n2)-(sqr(spacing)-4)*sqr(n1)*sqr(n2)+2*cube(n1)*n2)))
	/ (n1*sqr(n2) + sqr(n1)*n2);

pressure_angle = 20;
backlash =0.15;
// Here's an example.
module example_gears() {
	n1 = 9*6; n2 = 9;
	p = fit_spur_gears(n1, n2, axle_height-handle_h);
	// Simple Test:
	gear (circular_pitch=p,
    pressure_angle=pressure_angle,
		gear_thickness = pulley_thick,
        bore_diameter=handle_thick*2+tol,
		rim_thickness = pulley_thick,
		hub_thickness = pulley_thick,
	    number_of_teeth = n1,        
    backlash=backlash,
		circles=8);
	
	translate([gear_outer_radius(n1, p) + gear_outer_radius(n2, p),0,0])
	gear (circular_pitch=p,
    pressure_angle=pressure_angle,
    bore_diameter=axle_diam*2+tol,
		gear_thickness = pulley_thick,
		rim_thickness = pulley_thick,
		hub_thickness = pulley_thick,        
		circles=8,
		number_of_teeth = n2,
        backlash=backlash,
		rim_width = 2);
}

if(!pulleys)
{
    
    translate([-base_l/2+gear_offset_x,0,handle_h])
    rotate([0,-90,0])
    color("Yellow")
    example_gears();
}


