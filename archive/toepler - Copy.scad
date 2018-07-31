include <pulleys.scad>
use <Chamfer.scad>
use <parametric_involute_gear_v5.0.scad>
use <bearing.scad>

translate([200,0,0])
gear_bearing();



// overall size of the board
base_l = 250;
base_d = 150;
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


// dimensions of the boss on the disk
disk_boss_radius = disk_radius * 0.15;
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
rod_angle = 25; // angle of arms
spark_gap = 0; // fixed gap
spark_gap_ball = 12; // end ball radius
spark_gap_micro_ball = 4; // discharge ball radius



// computed constants
axle_height = disk_radius + disk_clearance + base_thick;
inner_circum = sector_inner_rad * 2 * PI;
outer_circum = sector_outer_rad * 2 * PI;
sector_lower_size = lower_rake * sector_spacing*0.5*inner_circum/n_sectors;
sector_upper_size = upper_rake * sector_spacing*0.5*outer_circum/n_sectors;


$fn = 30;
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



// the base itself
translate([-base_l/2, -base_d/2, 0])
{
    chamfer = 3;
    translate([-chamfer,-chamfer,0])
    {
    chamferCube(base_l+2*chamfer, base_d+2*chamfer, base_thick, chamfer);
    }
}


// disk



module disk()
{
    rotate([90,0,90])
    {
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
            cylinder(200, r1=axle_diam+tol, r2=axle_diam+tol, center=true);
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
    
    
    
    
}




support_thick = base_thick*1.5;
disk_offset = 30;

disk_x = -base_l/2+base_thick+disk_offset;

translate([disk_x,0,axle_height])
{
    disk();
}

translate([-disk_x,0,axle_height])
{
    rotate([0,0,180])
    {
        disk();
    }
}

axle_inset = support_thick / 2;
axle_extend = pulley_thick * 2 ;

// axle
module axle(h, r)
{
    cylinder(h,r,r,$fn=6);    
}

// main axle (hex keyed)
color("Green")
translate([-axle_extend-base_l/2,0,axle_height])
{
    rotate([90,0,90])
    {
        axle(base_l - axle_inset + axle_extend , axle_diam);
    }
}

/////////////////
// conductor guide that supports the cross connecting rod
conductor_guide_l = support_thick*1.5;
conductor_guide_d = support_thick*3;
conductor_guide_h = conductor_guide_l*0.75;

translate([-conductor_guide_l/2,-conductor_guide_d/2,base_thick])
{
    difference()
    {
        chamferCube(conductor_guide_l, conductor_guide_d, conductor_guide_h);
        //[base_h,spark_support_centre,0],  

    translate([-tol,conductor_guide_d/2,conductor_guide_h/2])
        rotate([0,90,0])
        {
            cylinder(200, rod_thick+tol, rod_thick+tol);
        }
    }
    
    
    translate([-conductor_guide_l*0.05, -conductor_guide_d*0.05, 0])
    {
            cube([conductor_guide_l*1.1, conductor_guide_d*1.1, conductor_guide_h*0.25]);
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
pull_arm_len = 70;

module spark_support()
{
     
    cylinder(spark_h, spark_radius, spark_radius);
    cylinder(spark_h + spark_pin, pin_radius, pin_radius);
    translate([0,0,-1])
    chamferCylinder(support_thick*0.5+1, spark_radius*2, spark_radius*2);
    chamferCylinder(support_thick*1.5, spark_radius*1.5, spark_radius*1.5);
    
  
    
    translate([0,0,spark_h + spark_ball])
    {
        // ball
        color("SlateGray")
        difference()
        {
            sphere(spark_ball);
            translate([0,0,-spark_ball-tol])
            {
                cylinder(spark_pin+tol, pin_radius+tol, pin_radius+tol*0.5);
            }
            
           
            
        }
    }
}

module spark_arm(positive)
{
                 
        // spark arm
     
        color("LightBlue")
        cylinder(rod_arm_len, rod_thick, rod_thick);
        color("SlateGray")
        cylinder(rod_arm_len*0.5, spark_ball, rod_thick);
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
            color("Yellow")
            cylinder(pull_arm_len, rod_thick*2, rod_thick*2);
            translate([0,0,pull_arm_len])
            {
                sphere(rod_thick*2);
            }
        }
        
        
    
}

translate([0,spark_support_centre,base_thick])
{
    spark_support();
    translate([0,0,spark_h + spark_ball])    
    rotate([-rod_angle,0,0])        
    spark_arm(0);
}

translate([0,-spark_support_centre,base_thick])
{
    rotate([0,0,180])
    {
        spark_support();
        translate([0,0,spark_h + spark_ball])
        rotate([-rod_angle,0,0])       
        spark_arm(1);
    }
}



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

   
conductor_standoff = 10;
brush_width = disk_radius/3;
brush_thick = 0.2;
brush_extend = conductor_standoff+rod_thick+tol;
brush_tooth_depth = 2;
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

module conductor(induct)
{
   
    rotate([0,90,0])
    {
        // horizontal connector bar
        color("LightBlue")
        cylinder(-conductor_x, rod_thick, rod_thick);
        
        // central connection ball
        color("SlateGray")
        difference()
        {
            sphere(spark_ball);
            rotate([0,0,0])
            {
                translate([0,0,-100])
                cylinder(200,rod_thick+tol,rod_thick+tol);
            }
        }
        
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
                sphere(conductor_thick*1.5);
                translate([0,0,-inductor_thick*100])
                {
                cylinder(inductor_thick*100, inductor_rad, inductor_rad);
            }
        }
        }
        
        // brush
        color("SlateGray")
        translate([0,induct ? brush_width/2 : -brush_width/2,-disk_x+conductor_standoff+rod_thick])
        {
            rotate([-90,0,90])
            {
                brush(brush_teeth, brush_extend-brush_tooth_depth, brush_tooth_depth, brush_width, brush_thick);
            }
        }

 
        
    }
    
}


module brush_arm()
{
    // brush arm
    rotate([0,90,0])
    {
            color("LightBlue")
            cylinder_path([
            [0,0,-conductor_x-rod_thick],
            [0,base_d/2,-conductor_x-rod_thick],
            [0,base_d/2,-disk_x+conductor_standoff+rod_thick],
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
                [spark_h,base_d/2,-disk_x+conductor_standoff+rod_thick],
                [base_h,base_d/2,-disk_x+conductor_standoff+rod_thick],
                [base_h,spark_support_centre,0.5*(-disk_x+conductor_standoff+rod_thick)],                         
                [base_h,spark_support_centre,0],                         
                
                ], rod_thick);
        }
    }
    
        
}

translate([0,spark_support_centre,0])
{
    neutral();
}
rotate([0,0,180])
{
    translate([0,spark_support_centre,0])
    {
        
        neutral();
    }
     
}



translate([0,spark_support_centre,spark_h])
{
    
    conductor(0);
    
}


rotate([0,0,180])
{
    translate([0,spark_support_centre,spark_h])
    {
        conductor(0);
        
    }
    
}


translate([0,-spark_support_centre,spark_h])
{
    conductor(1);
    brush_arm();
}

rotate([0,0,180])
{
    translate([0,-spark_support_centre,spark_h])
    {
        conductor(1);
        brush_arm();
    }
    
}



// supports
support_above_axle = disk_clearance;
support_h = axle_height + support_above_axle;

support_w = base_d * 0.5;
support_lower_w = support_w / 2.0;
support_thin = 0.5;
support_upper_w = support_lower_w * support_thin;

// handle
handle_thick = 3;
handle_len = support_w*0.6666;

handle_clearance = 15;
handle_h = handle_len + handle_clearance;
handle_protrude = handle_len/3;

support_chamfer = 2;
module support_polygon()
{
    union()
    {
               polygon(points=[
    [-support_lower_w,-support_chamfer], 
    [-support_upper_w, support_h], 
    [0, support_h+10],
    [support_upper_w,support_h],
    [support_lower_w,-support_chamfer]]);
     
    // upper rounded circle   
    translate([0,support_h])
    circle(support_upper_w);
        
    }
}

pulleys = 1; // if 1, use pulleys, else use gears
pulleys_inside = 1; // if 1, pulleys on inside of support, else outside
pulley_ratio = 7;

handle_axle_insert = (pulleys_inside) ? support_thick + pulley_thick + tol + 8: 8; 

// how far the handle extends into the support


module support(open)
{
    
        difference()
        {
            hull()
            {
                translate([0,0,support_chamfer])
                linear_extrude(support_thick-2*support_chamfer)
                {                    
                    support_polygon();
                }
                
                translate([0,0,0])
                linear_extrude(support_chamfer)
                {              
                    offset(delta=-support_chamfer)
                    support_polygon();
                }
                
                translate([0,0,support_thick-support_chamfer])
                linear_extrude(support_chamfer)
                {              
                    offset(delta=-support_chamfer)
                    support_polygon();
                }
                
                
                
            }
            
            translate([0,axle_height-base_thick,open ? axle_inset : 100])
            {
                rotate([0,180,0])
                {
                    cylinder(200, axle_diam+tol, axle_diam+tol, center=false);
                }
            }
            
            if(!open)
            {
                // cutout for the handle axle
                translate([0,handle_h-base_thick, 120+handle_axle_insert])
                {
                    rotate([0,180,0])
                    {
                        cylinder(120, handle_thick+tol, handle_thick+tol, center=false);
                    }
                }
                
                
            }
            
        }
        
        
    
    
        
}

translate([base_l/2-support_thick,0,base_thick])
{
    rotate([90,0,90])    
    support(1);
}

translate([-base_l/2+support_thick,0,base_thick])
{
    rotate([0,0,180])
    {
        rotate([90,0,90])
        support(0);
    }
}

// handle


module mmpulley(outer, inner, thick, belt_thick)
{
    inch = 25.4; //mm
    translate([0,0,belt_thick/2])
    {
        custompulley(beltB=thick/inch, beltH=belt_thick/inch, beltangle=40, definedD=outer/inch, arborD=inner/inch, key=0);//, key=.125, res=60, padding=true, screw=false);    
    }
}

// pulley/gear washers
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

pulley_offset_x = (pulleys_inside) ? support_thick + pulley_thick*2 + tol : 0;
gear_offset_x = (pulleys_inside) ? pulley_offset_x - pulley_thick : 0;

washer_thick = 1;

translate([-base_l/2-handle_thick,0,handle_h])
{
    
    handle_offset = 2 + pulley_thick*2 + tol*2;
    // handle + spindle
    color("Orange")
    
    rotate([0,90,0])
    translate([0,0,-handle_offset])
    axle(handle_axle_insert+handle_offset, axle_diam);
    
    cylinder_path([
    
    [-handle_offset,0,0], [-handle_offset,handle_len,0],
    [-handle_offset,handle_len,0],
    [-handle_offset-handle_protrude,handle_len]
    ], handle_thick);
    
    
    // handle grip
    color("DarkRed")
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
    
    if(pulleys)
    {
        color("Goldenrod")
        // large pulley
        rotate([0,90,0])
        {
           
            translate([0,0,-tol+pulley_offset_x])
            {
                mmpulley(handle_len*2,handle_thick*2+tol,  
                pulley_thick,band_thick);
                
                
               
            }
        }
    }

    
  
}



if(pulleys)
{
    // small axle pulley
    color("Goldenrod")
    translate([-base_l/2-handle_thick,0,axle_height])
    {
        rotate([0,90,0])
        {
            translate([0,0,-tol+pulley_offset_x])
            {
                mmpulley(handle_len*2/pulley_ratio,axle_diam+tol*2,pulley_thick,band_thick);
                
                
                
            }
            
        }
    }
}




// leyden jars
leyden_h = 70;
leyden_rad = 12;
leyden_wall = 0.25;
leyden_base = 10;
leyden_chamfer = 4;
leyden_conduct_h = leyden_h * 0.7;



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
                cylinder(leyden_h, leyden_rad, leyden_rad);
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
        cap_h = base;
        translate([0,0,base+leyden_h-cap_h+wall_thick])
        // cap
        difference()
        {
            chamferCylinder(base, base_rad, base_rad,chamfer);
            translate([0,0,-wall_thick])
            {
               cylinder(base, leyden_rad+tol, leyden_rad+tol);
            } 
            // under cut
            scale([1,1,0.55])
                sphere(base_rad*0.75);
        }
        
        // terminal
        color("SlateGray")
        translate([0,0,base+leyden_h-chamfer])
        {
            intersection()
            {
                scale([1,1,0.5])
                    sphere(base_rad);
                cylinder(200, base_rad, base_rad);
            }
            
            cylinder(terminal_h, rod_thick, rod_thick);
        }
        
        
        
        
        // terminal ball
        color("SlateGray")
        translate([0,0,terminal_h+leyden_h+base])
        {
            sphere(spark_ball);
        }
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


// washers for pulleys/gears
 translate([-base_l/2+pulley_offset_x + tol,0,handle_h])
                {
                    rotate([0,90,0])
                    washer(handle_thick+tol, handle_thick*2, washer_thick);
                }
                    
 translate([-base_l/2+pulley_offset_x + tol,0,axle_height])
                {
                    rotate([0,90,0])
                    washer(handle_thick+tol, handle_thick*2, washer_thick);
                }
                
/*
translate([0,0,pulley_thick+tol])
                {
                    washer(axle_diam+tol, axle_diam*2, washer_thick);
                }
    */