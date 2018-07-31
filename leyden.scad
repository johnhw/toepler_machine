

// the cap of a leyden jar
module leyden_cap(base, base_rad, chamfer, leyden_h, wall_thick, terminal_h, rod_thick, leyden_rad)
{
    cap_h = base;
    translate([0,0,base-cap_h])
    // cap
    difference()
    {
        union()
        {
            difference()
            {
                chamferCylinder(base, base_rad, base_rad, chamfer*0.5);
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
        }
        translate([0,0,0])       
        {
            cylinder(terminal_h+base, rod_thick+tol, rod_thick+tol);
        }
    }        
}


// electrode sticking up from cap (slots through)
module leyden_electrode(base, terminal_h, rod_thick, spark_ball, wall_thick, base_rad)
{
    
    color("SlateGray")          
    difference()
    {
        union()
            {
                cylinder(terminal_h+base, rod_thick, rod_thick);            
                translate([0,0,terminal_h+base])
                {

                        //sphere(spark_ball);  
                        torus_ball(spark_ball, rod_thick);
                                               
                }
            }
        rotate([0,90,0])
        translate([-terminal_h-base,0,-50])
        cylinder(100, rod_thick+tol, rod_thick+tol);
                    
    }

    //stopper 
    translate([0,0,base+wall_thick+tol+base_rad/4])
    color("SlateGray")    
    
    ntorus(rod_thick, spark_ball, 1);
    
}

module leyden_jar(chamfer, base, base_rad, leyden_h, leyden_rad, conduct_h, wall_thick)
{
    translate([0,0,-chamfer])
        chamferCylinder(base+chamfer, base_rad, base_rad, chamfer);
    translate([0,0,base])
    difference()
    {
        union()
        {
            // insulator
            color("White")
            cylinder(leyden_h-base, leyden_rad, leyden_rad);
            // exterior conductor
            color("SlateGray")
            cylinder(conduct_h , leyden_rad+tol, leyden_rad+tol);
        }            
        
        translate([0,0,wall_thick])
        {            
            // interior conductor
            cylinder(leyden_h, leyden_rad-wall_thick-tol, leyden_rad-wall_thick-tol);
            color("SlateGray")    
            cylinder(conduct_h , leyden_rad-wall_thick, leyden_rad-wall_thick);
        }
    }
}

module leyden(leyden_h, leyden_rad, leyden_chamfer, leyden_conduct_h, wall_thick, base, terminal_h, rod_thick, rod_connector_rad, jar=1, cap=1, electrode=1)
{
    
    chamfer = leyden_chamfer;
    base_rad = leyden_rad * 1.25;
    
    conduct_h = leyden_conduct_h;
    
    if(jar)
    {
        leyden_jar(chamfer, base, base_rad, leyden_h, leyden_rad, conduct_h, wall_thick);
    }

    if(cap)
    {
        translate([0,0,leyden_h])
        leyden_cap(base, base_rad, chamfer, leyden_h, wall_thick, terminal_h, rod_thick, leyden_rad);
       
        
    }
    if(electrode)
    {
       translate([0,0,leyden_h])
       leyden_electrode(base, terminal_h, rod_thick, rod_connector_rad, wall_thick, base_rad);
    }
     
}

// demo
 
use <libs/Chamfer.scad>
use <basic_shapes.scad>
tol = 0.2;
leyden(200, 40, 5, 100, 5, 50, 100, 4, 16, 0, 0, 1);
