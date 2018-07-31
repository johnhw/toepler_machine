// Electrostatic disk generator
// part of the Toepler machine project github.com/johnhw/toepler_machine
// MIT license
// John H. Williamson / 2018


// completely flat extruded sector
module flat_sector(low_rad, high_rad, sector_len, thick)
{
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
    translate([0,0,thick])
    intersection()
    {
        hull()
        {
            
            // flattened, elongated sphere
            scale([1,1,thick/low_rad])
            sphere(low_rad);                
            
            translate([sector_len,0,0])
            scale([1,1,thick/low_rad])
            sphere(high_rad);                                    
        }
     // slice off back
     cylinder(200, 200, 200);            
    }
    
}

// boss for disk
module es_disk_boss(disk_boss_length, disk_boss_radius, chamfer)
{
    translate([0,0,-disk_boss_length])
    {
        intersection()
        {
            // slice off chamfer on back, so lies perfectly flat on disk
            cylinder(disk_boss_length, disk_boss_radius, disk_boss_radius);
            translate([0,0,chamfer])
            chamferCylinder(disk_boss_length, disk_boss_radius, disk_boss_radius, chamfer); 
        }
    }    
}

// the disk, with sectors mounted on it
module es_disk(disk_thick, disk_radius, n_sectors, sector_inner_rad, sector_outer_rad, sector_lower_size, sector_upper_size, sector_thick, flat)
{    
    
    linear_extrude(disk_thick)
    {
        circle(disk_radius);
    }
    
    rotate([0,180,0])
    color("SlateGray")
    // sectors
    for(i=[0:n_sectors])
    {
        rotate([0,0,(360/n_sectors)*i])
        translate([sector_inner_rad,0,-disk_thick/2])
        {
            if(flat==1)
                flat_sector(sector_lower_size, sector_upper_size, sector_outer_rad-sector_inner_rad, sector_thick);
            else
                sector(sector_lower_size, sector_upper_size, sector_outer_rad-sector_inner_rad, sector_thick);
        }
    }        
}



// disk mask - a thin sheet, with cutouts where the sectors go
module es_disk_mask(mask_thick, disk_radius, n_sectors, sector_inner_rad, sector_outer_rad, sector_lower_size, sector_upper_size, disk_boss_radius)
{
    color("LightBlue")
    rotate([0,180,0])
    difference()
    {
        linear_extrude(mask_thick)
        {
            circle(disk_radius);
        }
                
        union()
        {
            // sectors
            for(i=[0:n_sectors])
            {
                rotate([0,0,(360/n_sectors)*i])
                translate([sector_inner_rad,0,-100])
                {
                    flat_sector(sector_lower_size+tol, sector_upper_size+tol, sector_outer_rad-sector_inner_rad, 200);
                }
            }
            // cutout for the boss
            translate([0,0,-100])
            {
                cylinder(200, disk_boss_radius+tol, disk_boss_radius+tol); 
            }
        
        }
    }        
}

/*
use <libs/Chamfer.scad>
tol = 0.2;
es_disk(disk_thick=1, disk_radius=150, n_sectors=32, sector_inner_rad=70, sector_outer_rad=130, sector_lower_size=5, sector_upper_size=8, sector_thick=2, flat=1);
es_disk_boss(20, 30, 4); 
*/