set SCAD_PATH="C:\Program Files\OpenSCAD"
FOR /l %%i in (0,1,20) DO %SCAD_PATH%\openscad -D part=%%i  -o "parts\part_%%i.stl" -D test_scale=0.5 toepler_exploded_uniq.scad 