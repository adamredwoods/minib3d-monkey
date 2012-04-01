#rem

Module minib3d
Version: 0.10
Main Author: Simon Harrison (simonh@blitzbasic.com). Includes routines by various authors.
monkey coder: Adam Piette (awpiette@yahoo.com). Includes routines by various authors.

License:
This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable For any damages
arising from the use of this software.

Permission is granted To anyone To use this software For any purpose,
including commercial applications, And To alter it And redistribute it
freely

Please see readme.txt for more details

#End

'Strict

Import mojo


'' global
Import trender
'Import tglobal ''depricated


'' entity
Import tentity
Import tcamera
Import tlight
Import tpivot
Import tmesh
Import tsprite
Import ttext ''new in monkey minib3d

'' mesh structure
Import tsurface
Import ttexture
Import tbrush
Import tbone
Import tanimation
Import tmodelb3d
Import tmodelobj

'' picking/collision
Import tcoltree
Import tpick
Import tcollision

'' geom
Import vector
Import matrix
Import quaternion
'Include "inc/BoxSphere.monkey"

'' misc
'Import thardwareinfo.monkey
Import tutility
Import monkeyutility
Import tpixmap

'' shaders
'Import tshader

'' functions
Import functions



Const USE_MAX2D=True	' true to enable max2d/minib3d integration
Const USE_GL20 = False 	' future use for opengl 2.0 support
Const USE_VBO=True	' true to use vbos if supported by hardware
Const VBO_MIN_TRIS=10	' if USE_VBO=True and vbos are supported by hardware, then surface must also have this minimum no. of tris before vbo is used for surface (vbos work best with surfaces with high amount of tris)

