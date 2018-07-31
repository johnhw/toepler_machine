include <libs/pulleys.scad>
use <libs/Chamfer.scad>
use <libs/parametric_involute_gear_v5.0.scad>
use <libs/bearing.scad>
use <libs/threads_v2.scad>

include <es_disk.scad>
include <leyden.scad>
include <basic_shapes.scad>

// if 1, assemble entire machine
// if 0, just output the one part listed below
assembled = 1;

// part selector; used to output individual parts
// not used if assembled is 1
part = 6;

// scaling factor; if this is changed
// the measurements are not mm anymore!
test_scale = 1.0; 

//////// Main configuration
//////// All dimensions in mm

// global fit tolerance
tol = 0.2;

// smoothness of rounded surfaces
$fn = 12;

////////////////////////////////
// If these are defined, threads are replaced with simple cylinders
// for faster rendering/previewing

module ScrewThread(dia, len)
{
    cylinder(len, dia/2, dia/2);
}

module PositiveScrewHole(dia, len)
{
    cylinder(len, dia/2+tol, dia/2+tol);
}
//////////////////////////////

// overall size of the base board
base_l = 225;
base_d = 160;
base_thick = 10;
base_chamfer = 3;

// clearance from bottom of disk the top of the board
disk_clearance = 25;

// radius of the disks
disk_radius = base_d-70;

// thickness of disks
disk_thick = 1.0;


// thickness of disk sector mask (should be very thin)
disk_mask_thick = 0.2;

// radius of main axle
axle_diam = 3;

// thickness of pulleys/gears
pulley_thick = 3;

// thickness of rubbed band for pulleys
band_thick = 1;

// thickness of the end supports
support_thick = base_thick*2;

// minimum thickness of support (around the circumference); used to find the
// position to fit the width of the support
support_min_thick = 5;

// chamfer depth on end support
support_chamfer = 2;

// thickness of all conductive rods
rod_thick = 3;

////////////////////////////// handle
// thickness of handle
handle_thick = 3;

// length of the handle turning radius
handle_len = base_d*0.3;

// clearance of handle from bottom of surface
handle_clearance = 15;

// height of the handle from the floor level 
handle_h = handle_len + handle_clearance;

// how far the handle sticks out
handle_protrude = handle_len/3;

//////////////////////////////////////////

/////////////// Dowels for holding supports onto base
// length of dowels above surface
support_dowel_length = 19;

// spacing between dowel centres
support_dowel_spacing = 30;

// number of dowels
support_dowel_n = 3;

// radius of dowels
support_dowel_rad = 3.0;

/////////// Disk and sector specification
// offset of the disk from the back of the supports
disk_offset = 20;

// dimensions of the boss on the disk
disk_boss_radius = disk_radius * 0.125;
disk_boss_length = disk_boss_radius / 2;
disk_boss_chamfer = 1.0;

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
sector_thick = 0.6;
////////////////////////////////////////////////////////

/////////////////////////////////////////// spark arms

// spark support screw thread dimensions
spark_support_thread_dia = 5;
spark_support_thread_len = 20;

// spark arm
rod_angle = 40; // angle of arms
spark_gap = 0; // fixed gap
spark_gap_ball = 12; // end ball radius
spark_gap_micro_ball = 4; // discharge ball radius

// length of the pull arm
pull_arm_len = 80;

// rise of spark arm above main conductor lines
spark_rise = 30;

/////////////////////////////////// pulleys / gears
pulleys = 1; // if 1, use pulleys, else use gears
pulleys_inside = 0; // if 1, pulleys on inside of support, else outside
pulley_ratio = 6;

bearing_thick = 15;
bearing_diameter = 51.7;

///////////////////////////////// inductors

// thickness of insulating plate inductor sits on
conductor_thick = 3; 

// distance of inductor plate from the disk
conductor_distance = 1;

// thickness of the inductor itself
inductor_thick = 0.5;


/////////////////////////////////// brushes

// thickness of brush
brush_thick = 0.5;

// tooth cut depth
brush_tooth_depth = 2;

// number of teeth
brush_teeth = 15;

// distance from conductor to disk
brush_standoff_depth = 10;


/////////////////////////////// leyden jars
// leyden jars
// height of leyden jar
leyden_h = 70;
// radius of leyden jar
leyden_rad = 12;
// wall thickness
leyden_wall = 0.25;
// height of base
leyden_base = 10;

// chamfer size
leyden_chamfer = 4;

// height of the conductor
leyden_conduct_h = leyden_h * 0.7;

// offset of leyden jars from centre of board
leyden_centre_offset = 30;

////////////////////////////////////////// computed constants
axle_height = disk_radius + disk_clearance + base_thick;
inner_circum = sector_inner_rad * 2 * PI;
outer_circum = sector_outer_rad * 2 * PI;
sector_lower_size = lower_rake * sector_spacing*0.5*inner_circum/n_sectors;
sector_upper_size = upper_rake * sector_spacing*0.5*outer_circum/n_sectors;

///////// Brush
// width of brush
brush_width = disk_radius/3;

// length of brush (to touch disk)
brush_extend = brush_standoff_depth+rod_thick+tol;

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


// pulley, with dimensions in mm
module mmpulley(outer, inner, thick, belt_thick)
{
    inch = 25.4; //mm
    translate([0,0,belt_thick/2])
    {
        
        difference()
        {
            custompulley(beltB=thick/inch, beltH=belt_thick/inch, beltangle=40, 
                        definedD=outer/inch, arborD=0, key=0);//, key=.125, res=60, padding=true, screw=false);    
                
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





// the disks

disk_x = -base_l/2+support_thick+disk_offset;
axle_inset = 0;
axle_extend = pulley_thick * 2 ;

/////////////////
// conductor guide that supports the cross connecting rod
conductor_guide_l = support_thick;
conductor_guide_d = support_thick*3;
conductor_guide_h = conductor_guide_l*0.75;

module guide()
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
rod_arm_len = (1.0/sin(rod_angle)) * (spark_span/2 - spark_gap_ball*1.52 - spark_gap_micro_ball);

// length of the spark gap pull arm

// the spark support, from the base to the angled spark gap arms
module spark_support_wodowel()
{
    total_h = spark_h + spark_rise;
    cylinder(spark_h-base_thick, spark_radius, spark_radius);

    translate([0,0,-1])
    chamferCylinder(support_thick*0.5+1, spark_radius*2, spark_radius*2);
    chamferCylinder(support_thick*1.5, spark_radius*1.5, spark_radius*1.5);
    // central connection ball
    translate([0,0,spark_h-base_thick])
    color("SlateGray")
    torus_ball(spark_ball, rod_thick, up=1);

    color("SlateGray")
    translate([0,0,spark_h-base_thick])    
    cylinder(spark_rise+spark_ball*2, rod_thick, rod_thick);
         
}

module spark_support()
{
    difference()
    {
        spark_support_wodowel();
        
        translate([0,0,spark_h-base_thick])
        {
            rotate([0,90,0])    
            translate([0,0,-100])       
            cylinder(200,rod_thick+tol,rod_thick+tol);
        }        

        translate([0,0,-1])
        //dowel_set(31, 30, 1, rad=3.0, male=0);        
        PositiveScrewHole(spark_support_thread_dia, spark_support_thread_len);
    }
    
}

// distance of insulating pull arm back from connection
// ball
pull_offset = 30;

module discharge_ball(positive)
{
    scale_factor = positive ? 1.25 : (1.0/1.25);
    color("SlateGray")
    translate([0,0,spark_gap_ball*scale_factor])
    {
        difference()
        {
            scale(scale_factor)
            sphere(spark_gap_ball);
            rotate([0,180,0])
            cylinder(200,rod_thick+tol, rod_thick+tol);
        }

    if(positive)
    {
            // micro ball
            color("SlateGray")
            rotate([-(90-rod_angle),0,0])
            translate([0,0,spark_gap_ball*scale_factor+spark_gap_micro_ball*0.25])
            sphere(spark_gap_micro_ball);
        
        }
    }
}
        

module spark_arm_x()
{
                 
        // spark arm
        //translate([0,0,total_h-base_thick+spark_ball*2]) 
        color("SlateGray")   
        sphere(spark_ball);
        color("LightBlue")
        cylinder(rod_arm_len, rod_thick, rod_thick);
        color("SlateGray")
        cylinder(rod_arm_len*0.5, rod_thick, rod_thick);    

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

module spark_arm()
{
    difference()
    {
        spark_arm_x();
        rotate([180+rod_angle,0,0])
        cylinder(200, rod_thick+tol, rod_thick+tol);
    }
}

conductor_offset =  conductor_distance + conductor_thick + disk_thick;
conductor_x = disk_x + conductor_offset;
conductor_rad = disk_radius/(2.2);
inductor_rad =  conductor_rad / 1.5;


module conductor(induct)
{
    
    rotate([0,90,0])
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
                        rotate([0,90,90])                        
                        torus_ball(spark_ball, rod_thick, down=0, left=1, up=0);
                    }
                    // cut hole for the brush arm to come round
                    if(induct)
                    {
                        translate([0,0,-rod_thick-tol])                    
                        rotate([-90,0,0])
                        translate([0,0,-rod_thick])
                        cylinder(200, rod_thick+tol, rod_thick+tol, center=false);
                    }
                }
                translate([0,0,-inductor_thick*100])
                {
                cylinder(inductor_thick*100, inductor_rad, inductor_rad);
            }
        }
        }
    }
    
}

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
            [0,conductor_outside,-disk_x+brush_standoff_depth+rod_thick],
            [0,0,-disk_x+brush_standoff_depth+rod_thick],                        
            ], rod_thick);                        
    }
        
}
module neutral()
{
    base_h = +rod_thick+base_thick+conductor_guide_h/2-rod_thick;
   color("LightBlue")
    // neutraliser
    rotate([0,90,0])
    {
        rotate([0,0,180])
        {
            // could split this into 2 parts here...
            
            //difference()
           // {
            cylinder_path([            
                [spark_h,0,-disk_x+brush_standoff_depth+rod_thick],
                [spark_h, conductor_outside,-disk_x+brush_standoff_depth+rod_thick],
                [base_h, conductor_outside,-disk_x+brush_standoff_depth+rod_thick],
                [base_h,spark_support_centre,0.5*(-disk_x+brush_standoff_depth+rod_thick)],            [base_h,spark_support_centre,0],                                     
                ], rod_thick);
                
//             translate(base_h, spark_support_centre,0.5*(-disk_x+brush_standoff_depth+rod_thick));
            //rotate([3,0,0])
           // cube(500);
            //}
        }
        
       
        //base_h,spark_support_centre,)
    }
            
}

// supports
support_above_axle = disk_clearance;
support_h = axle_height + support_above_axle;

support_w = base_d * 0.5;
support_lower_w = support_w / 1.5;

support_upper_w = bearing_diameter/2 + support_min_thick;

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
            
            translate([0,-support_chamfer,support_thick/2])
            rotate([180,0,0])
            rotate([90,0,0])            
            dowel_set(support_dowel_length, support_dowel_spacing, support_dowel_n, rad=support_dowel_rad, male=0);
            
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



// the base itself
module base()
{

    
    translate([-base_chamfer,-base_chamfer,0])
    {
        chamferCube(base_l+2*base_chamfer, base_d+2*base_chamfer, base_thick, base_chamfer);
    }
    
    translate([0,0,base_thick])
    {
        rad = support_dowel_rad;
        translate([support_thick-rad,base_d/2,0])
        rotate([0,0,90])
        dowel_set(support_dowel_length, support_dowel_spacing, support_dowel_n, rad=support_dowel_rad, male=1);
        
        translate([base_l-support_thick+rad,base_d/2,0])
        rotate([0,0,90])
        dowel_set(support_dowel_length, support_dowel_spacing, support_dowel_n, rad=support_dowel_rad, male=0);
        
        translate([base_l/2,base_d/2+spark_support_centre,0])
        
        
        
        ScrewThread(spark_support_thread_dia, spark_support_thread_len);    
        translate([base_l/2,base_d/2-spark_support_centre,0])
        ScrewThread(spark_support_thread_dia, spark_support_thread_len);

        
        
        
        translate([base_l/2, base_d/2, 0])
        guide();
    }
    

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


leyden_terminal = spark_h - (leyden_h+leyden_base+base_thick);

use_leyden = 1;
leyden_jars = 1;
leyden_caps = 1;



module spark_supports()
{
    translate([base_l/2,base_d/2+spark_support_centre,base_thick])
    spark_support();
    translate([base_l/2,base_d/2-spark_support_centre,base_thick])    
    spark_support();
    
}

module leyden_jars()
{
    translate([-leyden_centre_offset+base_l/2,base_d/2-spark_support_centre,base_thick])
    leyden(leyden_h, leyden_rad, leyden_chamfer, leyden_conduct_h,  leyden_wall, leyden_base, leyden_terminal, rod_thick, spark_ball, 
            jar=1, cap=1, electrode=1);
    translate([leyden_centre_offset+base_l/2,base_d/2-spark_support_centre,base_thick])
    leyden(leyden_h, leyden_rad, leyden_chamfer, leyden_conduct_h, leyden_wall, leyden_base, leyden_terminal,  rod_thick, spark_ball,
            jar=1, cap=1, electrode=1);
    translate([leyden_centre_offset+base_l/2,base_d/2+spark_support_centre,base_thick])
    leyden(leyden_h, leyden_rad, leyden_chamfer, leyden_conduct_h, leyden_wall, leyden_base, leyden_terminal,  rod_thick, spark_ball,
            jar=1, cap=1, electrode=1);
    translate([-leyden_centre_offset+base_l/2,base_d/2+spark_support_centre,base_thick])
    leyden(leyden_h, leyden_rad, leyden_chamfer, leyden_conduct_h, leyden_wall, leyden_base, leyden_terminal,  rod_thick, spark_ball,
            jar=1, cap=1, electrode=1);
    
    
}

module neutralizer()
{
    translate([base_l/2,base_d/2,0])
    {
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
    }
}

module supports()
{
    translate([base_l-support_thick,base_d/2,base_thick])
    rotate([90,0,90])    
    support(1);
    
    translate([support_thick,base_d/2,base_thick])
    rotate([90,0,-90])    
    support(0);
}

module bearings()
{
    // upper bearings
    translate([support_thick+tol-bearing_thick,base_d/2,axle_height])
    rotate([0,90,0])
    std_bearing();

    translate([base_l-support_thick-tol,base_d/2,axle_height])
    rotate([0,90,0])
    std_bearing();

    // lower bearing
    translate([support_thick+tol-bearing_thick,base_d/2,handle_h])
    rotate([0,90,0])
    std_bearing();
}

module small_pulley()
{
    translate([-handle_thick,base_d/2,axle_height])
    {
        rotate([0,90,0])
        {
            translate([0,0,-tol+pulley_offset_x])
            {
            mmpulley(handle_len*2/pulley_ratio,axle_diam+tol,pulley_thick,band_thick);        
            }
        }
    }
}

module large_pulley()
{
    translate([-handle_thick,base_d/2,handle_h])
    {
        rotate([0,90,0])
        {
            translate([0,0,-tol+pulley_offset_x])
            {
            mmpulley(handle_len*2,axle_diam+tol,  pulley_thick,band_thick);
            }
        }
    }
}

module brush_fit(induct)
{
    rotate([0,90,0])
    color("SlateGray")
    translate([0,induct ? brush_width/2 : -brush_width/2,-disk_x+brush_standoff_depth+rod_thick])
    {
        rotate([-90,0,90])
        {
            brush(brush_teeth, brush_extend-brush_tooth_depth,
                    brush_tooth_depth, brush_width, brush_thick);
        }
    }
                   
}

module conductors()
{
    translate([base_l/2, base_d/2, 0])
    {
        translate([0,spark_support_centre,spark_h])
        {            
            conductor(0);    
            brush_fit(0);       
        }

        rotate([0,0,180])
        {
            translate([0,spark_support_centre,spark_h])
            {
                conductor(0);
                brush_fit(0);
            }           
        }

        translate([0,-spark_support_centre,spark_h])
        {
            conductor(1);
            brush_arm();
            brush_fit(1);
        }

        rotate([0,0,180])
        {
            translate([0,-spark_support_centre,spark_h])
            {
                conductor(1);
                brush_arm();
                brush_fit(1);
            }    
            
        }
    }
}

module spark_arms()
{
    translate([base_l/2, spark_support_centre+base_d/2, base_thick])
    {
        translate([0,0,spark_h + spark_ball + spark_rise])    
        rotate([-rod_angle,0,0])        
        {
            
            spark_arm(0);
            translate([0,0,rod_arm_len])
            {
                discharge_ball(0);
            }
        }
    }
    
    translate([base_l/2, base_d-(spark_support_centre+base_d/2), base_thick])
    {
        translate([0,0,spark_h + spark_ball + spark_rise])    
        rotate([0,0,180])
        rotate([-rod_angle,0,0])               
        {
        spark_arm(0);
            translate([0,0,rod_arm_len])
            {
                    discharge_ball(1);
            }
        }
    }
}

handle_offset = 2 + pulley_thick*2 + tol*2;

module main_axle()
{
     translate([-pulley_thick*3,base_d/2,axle_height])
    {
        rotate([90,30,90])
        {
            axle(base_l+pulley_thick, axle_diam);
        }
    }
}

module disk_mask()
{
    es_disk_mask(disk_mask_thick, disk_radius, n_sectors, sector_inner_rad, sector_outer_rad, sector_lower_size, sector_upper_size, disk_boss_radius);
}

module disk_with_boss()
{
    difference()
    {
        union()
        {
            es_disk(disk_thick, disk_radius, n_sectors, sector_inner_rad, sector_outer_rad, sector_lower_size, sector_upper_size, sector_thick, 0);
            es_disk_boss(disk_boss_length, disk_boss_radius, disk_boss_chamfer);            
        }
        translate([0,0,-100])
        axle(200, axle_diam+tol);
    }
}

module disks()
{
    disk_x = support_thick+disk_offset;

    translate([0, base_d/2, 0])
    {
        translate([disk_x,0,axle_height])
        {
            rotate([0,90,0])
            {
                disk_with_boss();
                disk_mask();
            }
        }

        translate([base_l-disk_x,0,axle_height])
        {
            rotate([0,0,0])
            {
                rotate([180,90,0])
                {
                    disk_with_boss();             
                    disk_mask();
                }
            }
        }
    }
}


module handle_grip()
{
       translate([-pulley_thick+tol*2,base_d/2,handle_h])    
    handle();
}

module assembly()
{
    if(assembled==1)
    {    
        base();        
        spark_supports();    
        leyden_jars();    
        neutralizer();    
        supports();    
        bearings();    
        small_pulley();
        large_pulley();    
        conductors();    
        spark_arms();   
        main_axle();    
        disks();       
        handle_grip();        
    }
    else
    {    

    // p1
    if(part==0)
        discharge_ball(1);

    // p2
    if(part==1)
        discharge_ball(0);

    // p3 * 2
    if(part==2)
        spark_support();
    
    

    // p4 * 4
    if(part==3)
            leyden(leyden_h, leyden_rad, leyden_wall, leyden_base, leyden_terminal, 
            jar=1, cap=0, electrode=0);

    // p5 * 4

    if(part==4)
            leyden(leyden_h, leyden_rad, leyden_wall, leyden_base, leyden_terminal, 
            jar=0, cap=1, electrode=0);

    // p6 * 2
    if(part==5)
    {                    
            neutral();                
    }

    // p7
    if(part==6)        
        support(1);

    // p8
    if(part==7)
        support(0);
     
    // p9 
    if(part==8)
        base();

    // p10 * 3
    if(part==9)
        std_bearing();

    // p11
    if(part==10)
        mmpulley(handle_len*2/pulley_ratio,axle_diam+tol,pulley_thick,band_thick);
    
    // p12
    if(part==11)
        mmpulley(handle_len*2,axle_diam+tol,  
        pulley_thick,band_thick);
                
    // p13
    if(part==12)
        conductor(0);

    // p14 * 2
    if(part==13)
        brush_arm();    

    // p15 * 4
    if(part==14)
        brush(brush_teeth, brush_extend-brush_tooth_depth, brush_tooth_depth, brush_width, brush_thick);

    // p16  * 2
    if(part==15)
        spark_arm();

    // p17
    if(part==16)
    color("Green")
    {
        rotate([90,0,90])
        {
            axle(base_l - support_thick - tol * 2 + pulley_thick * 2, axle_diam);
        }
    }

    // p18
    if(part==17)
        disk_with_boss();

    // p19
    if(part==18)
        handle();
    

    // p20 * 2
    if(part==19)
    {
        disk_mask();
    }

    // p21 * 4
    if(part==20)
            leyden(leyden_h, leyden_rad, leyden_chamfer, leyden_conduct_h, leyden_wall, leyden_base, leyden_terminal, 
            jar=0, cap=0, electrode=1);

    }
}

scale([test_scale, test_scale, test_scale])
assembly();