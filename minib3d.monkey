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


''to choose opengles20, must specify it
#If MINIB3D_DRIVER=""
	#if TARGET="glfw" Or TARGET="ios" Or TARGET="android" Or TARGET="mingw"
		Import minib3d.opengl.opengles11
	#Elseif TARGET="html5"
		Import minib3d.opengl.opengles20
	#Elseif TARGET="xna"
		Import minib3d.xna
	#ElseIf TARGET="win8"
		Import minib3d.d3d11
	#endif
#endif



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
Import tshader

'' functions
Import functions

