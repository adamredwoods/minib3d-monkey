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

#MINIB3D_DRIVER=""
#MINIB3D_DEBUG_MODEL=0
'#OPENGL_GLES20_ENABLED=False ''this screws up opengl20 on html5

''to choose opengles20, must specify it
#If MINIB3D_DRIVER=""
	#if TARGET="glfw" Or TARGET="ios" Or TARGET="android" Or TARGET="mingw"
		Import minib3d.opengl.opengles11
	#Elseif TARGET="html5"
		Import minib3d.opengl.opengles20
	#Elseif TARGET="xna"
		Import minib3d.xna
	#endif
#endif



'' global
Import trender


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
Import tmodelmdd

'' picking/collision
Import tcoltree
Import tpick
Import tcollision

'' geom
Import minib3d.math.vector
Import minib3d.math.matrix
'Import minib3d.math.quaternion
'Include "inc/BoxSphere.monkey"

'' misc
'Import thardwareinfo.monkey
Import tutility
Import monkeyutility
Import tpixmap

'' shaders
Import tshader

'' functions
Import functions

