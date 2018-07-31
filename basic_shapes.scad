

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


function torus_radius(inr, outr) = outr/2-inr/2;

// torus between the given inr diameter and the outr diameter
module torus(inr, outr)
{    
    // convert diameters to radii
    rad = torus_radius(inr, outr);
    rotate_extrude(convexity = 10)    
    translate([rad+(outr/2-rad), (rad),0])
    circle(r = rad);    
}


module ntorus(inr, outr, n)
{    
    for(i=[0:n-1])
    {
        translate([0,0,2*torus_radius(inr, outr)*i])        
        torus(inr, outr);
    }
}




module teardrop(len, start, end)
{
    cylinder_ep([0,0,0], [0,0,len], start, end);
}


module torus_ball(radius, rod_thick, left=1, right=1, up=0, down=0)
{
    sphere(radius);  
    if(left==1)
    {
        translate([radius-torus_radius(rod_thick, radius),0,0])
        rotate([0,90,0])
        ntorus(rod_thick, radius, 1);                  
    }
    if(right==1)
    {
        translate([-radius+torus_radius(rod_thick, radius),0,0])
        rotate([0,-90,0])
        ntorus(rod_thick, radius, 1);     
    }
    if(up==1)
    {
        translate([0,0,radius-torus_radius(rod_thick, radius)])
        rotate([0,0,0])
        ntorus(rod_thick, radius, 1);     
    }
    if(down==1)
    {
        translate([0,0,-radius+torus_radius(rod_thick, radius)])
        rotate([0,180,0])
        ntorus(rod_thick, radius, 1);     
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

// a cylinder which is vertically limited
module squlinder(l, r1, r2)
{
    intersection()
    {
        translate([0,0,-tol])
        cylinder(l,r1,r1);
        cube([r2*2,100,200], center=true);
    }
    
}

// a single dowel (or dowel hole)
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

// a set of evenly spaced dowels
module dowel_set(length, spacing, n, rad=5, male=1)
{
    
    for(i=[1:n])
    translate([i*spacing - ((n+1)/2)*spacing,0,0])
        dowel(length, rad, male);
}
