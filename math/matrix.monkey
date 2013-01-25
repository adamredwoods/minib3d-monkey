Import monkey.math
Import minib3d.monkeyutility
Import minib3d.math.vector
Import minib3d.math.geom

'' opengl is column-major order m[column][row]
''m0 m4 m8 m12
''m1 m5 m9 m13
''m2 m6 m10 m14
''m3 m7 m11 m15
''

''matrix methods act on themselves, to speed up garbage collection
''this is different than vector, line, plane

Class Matrix

	Field grid:Float[4][]''4x4
	
	Method New()
		
		'grid = AllocateFloatArray(4,4)
		grid = [[0.0,0.0,0.0,0.0],[0.0,0.0,0.0,0.0],[0.0,0.0,0.0,0.0],[0.0,0.0,0.0,0.0]]

		
	End
	
	Method New( a:Vector, b:Vector, c:Vector)

		grid[0] = [a.x,a.y,a.z,0.0]
		grid[1] = [b.x,b.y,b.z,0.0]
		grid[2] = [c.x,c.y,c.z,0.0]
		grid[3] = [0.0,0.0,0.0,1.0]
		
	End
	
	
	Method LoadIdentity:Void()
	
		grid[0][0] = 1.0; grid[0][1] = 0.0; grid[0][2] = 0.0; grid[0][3] = 0.0
		grid[1][0] = 0.0; grid[1][1] = 1.0; grid[1][2] = 0.0; grid[1][3] = 0.0
		grid[2][0] = 0.0; grid[2][1] = 0.0; grid[2][2] = 1.0; grid[2][3] = 0.0
		grid[3][0] = 0.0; grid[3][1] = 0.0; grid[3][2] = 0.0; grid[3][3] = 1.0
	
	End
	
	' copy - create new copy and returns it
	
	Method Copy:Matrix()
	
		Local mat:Matrix=New Matrix
	
		mat.grid[0][0]=grid[0][0]
		mat.grid[1][0]=grid[1][0]
		mat.grid[2][0]=grid[2][0]
		mat.grid[3][0]=grid[3][0]
		
		mat.grid[0][1]=grid[0][1]
		mat.grid[1][1]=grid[1][1]
		mat.grid[2][1]=grid[2][1]
		mat.grid[3][1]=grid[3][1]
		
		mat.grid[0][2]=grid[0][2]
		mat.grid[1][2]=grid[1][2]
		mat.grid[2][2]=grid[2][2]
		mat.grid[3][2]=grid[3][2]
		
		mat.grid[0][3]=grid[0][3]
		mat.grid[1][3]=grid[1][3]
		mat.grid[2][3]=grid[2][3]
		mat.grid[3][3]=grid[3][3]

		Return mat
	
	End
	
	' overwrite - overwrites self with matrix passed as parameter
	
	Method Overwrite:Void(mat:Matrix)
	
		grid[0][0]=mat.grid[0][0]
		grid[1][0]=mat.grid[1][0]
		grid[2][0]=mat.grid[2][0]
		grid[3][0]=mat.grid[3][0]
		grid[0][1]=mat.grid[0][1]
		grid[1][1]=mat.grid[1][1]
		grid[2][1]=mat.grid[2][1]
		grid[3][1]=mat.grid[3][1]
		grid[0][2]=mat.grid[0][2]
		grid[1][2]=mat.grid[1][2]
		grid[2][2]=mat.grid[2][2]
		grid[3][2]=mat.grid[3][2]
		
		grid[0][3]=mat.grid[0][3]
		grid[1][3]=mat.grid[1][3]
		grid[2][3]=mat.grid[2][3]
		grid[3][3]=mat.grid[3][3]
		
	End
	
	Method Inverse:Matrix()
		'' only good for orthogonal matrixes
		'' (ie. no scaling)
		'' if there are problems, need to use the determinate-style inverse (many calculations)
		
		Local mat:Matrix=New Matrix
	
		Local tx#=0
		Local ty#=0
		Local tz#=0
	
	  	' The rotational part of the matrix is simply the transpose of the
	  	' original matrix.
	  	mat.grid[0][0] = grid[0][0]
	  	mat.grid[1][0] = grid[0][1]
	  	mat.grid[2][0] = grid[0][2]
	
		mat.grid[0][1] = grid[1][0]
		mat.grid[1][1] = grid[1][1]
		mat.grid[2][1] = grid[1][2]
	
		mat.grid[0][2] = grid[2][0]
		mat.grid[1][2] = grid[2][1]
		mat.grid[2][2] = grid[2][2]
	
		' The right column vector of the matrix should always be [ 0 0 0 1 ]
		' in most cases. . . you don't need this column at all because it'll 
		' never be used in the program, but since this code is used with GL
		' and it does consider this column, it is here.
		mat.grid[0][3] = 0 
		mat.grid[1][3] = 0
		mat.grid[2][3] = 0
		mat.grid[3][3] = 1
	
		' The translation components of the original matrix.
		tx = grid[3][0]
		ty = grid[3][1]
		tz = grid[3][2]
	
		' Result = -(Tm * Rm) To get the translation part of the inverse
		mat.grid[3][0] = -( (grid[0][0] * tx) + (grid[0][1] * ty) + (grid[0][2] * tz) )
		mat.grid[3][1] = -( (grid[1][0] * tx) + (grid[1][1] * ty) + (grid[1][2] * tz) )
		mat.grid[3][2] = -( (grid[2][0] * tx) + (grid[2][1] * ty) + (grid[2][2] * tz) )
	
		Return mat

	End 

	Method Inverse4:Matrix()
		
		Local matrix:Matrix=New Matrix
		Local d:Float ''determinant
		
		Local m10_00# = grid[1][0]*grid[0][0]
		Local m10_01# = grid[1][0]*grid[0][1]
		Local m10_02# = grid[1][0]*grid[0][2]
		Local m10_03# = grid[1][0]*grid[0][3]
		Local m11_00# = grid[1][1]*grid[0][0]
		Local m11_01# = grid[1][1]*grid[0][1]
		Local m11_02# = grid[1][1]*grid[0][2]
		Local m11_03# = grid[1][1]*grid[0][3]
		Local m12_00# = grid[1][2]*grid[0][0]
		Local m12_01# = grid[1][2]*grid[0][1]
		Local m12_02# = grid[1][2]*grid[0][2]
		Local m12_03# = grid[1][2]*grid[0][3]
		Local m13_00# = grid[1][3]*grid[0][0]
		Local m13_01# = grid[1][3]*grid[0][1]
		Local m13_02# = grid[1][3]*grid[0][2]
		Local m13_03# = grid[1][3]*grid[0][3]
		
		matrix.grid[0][0] = (grid[1][1]*grid[2][2]*grid[3][3] + grid[1][2]*grid[2][3]*grid[3][1] + grid[1][3]*grid[2][1]*grid[3][2] - grid[1][1]*grid[2][3]*grid[3][2] - grid[1][2]*grid[2][1]*grid[3][3] - grid[1][3]*grid[2][2]*grid[3][1])'*d
		matrix.grid[1][0] = (grid[1][0]*grid[2][3]*grid[3][2] + grid[1][2]*grid[2][0]*grid[3][3] + grid[1][3]*grid[2][2]*grid[3][0] - grid[1][0]*grid[2][2]*grid[3][3] - grid[1][2]*grid[2][3]*grid[3][0] - grid[1][3]*grid[2][0]*grid[3][2])'*d
		matrix.grid[2][0] = (grid[1][0]*grid[2][1]*grid[3][3] + grid[1][1]*grid[2][3]*grid[3][0] + grid[1][3]*grid[2][0]*grid[3][1] - grid[1][0]*grid[2][3]*grid[3][1] - grid[1][1]*grid[2][0]*grid[3][3] - grid[1][3]*grid[2][1]*grid[3][0])'*d
		matrix.grid[3][0] = (grid[1][0]*grid[2][2]*grid[3][1] + grid[1][1]*grid[2][0]*grid[3][2] + grid[1][2]*grid[2][1]*grid[3][0] - grid[1][0]*grid[2][1]*grid[3][2] - grid[1][1]*grid[2][2]*grid[3][0] - grid[1][2]*grid[2][0]*grid[3][1])'*d
		
		''determinate & check
		d = grid[0][0]*matrix.grid[0][0] + grid[0][1]*matrix.grid[1][0] + grid[0][2]*matrix.grid[2][0] + grid[0][3]*matrix.grid[3][0]
		
		If d = 0
			matrix.grid[0][0]=0.0; matrix.grid[1][0]=0.0; matrix.grid[2][0]=0.0; matrix.grid[3][0]=0.0
			Return matrix
		Endif
		d = 1.0/d
		
		matrix.grid[0][0] *= d
		matrix.grid[1][0] *= d
		matrix.grid[2][0] *= d
		matrix.grid[3][0] *= d
		matrix.grid[0][1] = (grid[0][1]*grid[2][3]*grid[3][2] + grid[0][2]*grid[2][1]*grid[3][3] + grid[0][3]*grid[2][2]*grid[3][1] - grid[0][1]*grid[2][2]*grid[3][3] - grid[0][2]*grid[2][3]*grid[3][1] - grid[0][3]*grid[2][1]*grid[3][2])*d
		matrix.grid[0][2] = (m12_01               *grid[3][3] + m13_02               *grid[3][1] + m11_03               *grid[3][2] - m13_01               *grid[3][2] - m11_02               *grid[3][3] - m12_03               *grid[3][1])*d
		matrix.grid[0][3] = (m13_01               *grid[2][2] + m11_02               *grid[2][3] + m12_03               *grid[2][1] - m12_01               *grid[2][3] - m13_02               *grid[2][1] - m11_03               *grid[2][2])*d
		matrix.grid[1][1] = (grid[0][0]*grid[2][2]*grid[3][3] + grid[0][2]*grid[2][3]*grid[3][0] + grid[0][3]*grid[2][0]*grid[3][2] - grid[0][0]*grid[2][3]*grid[3][2] - grid[0][2]*grid[2][0]*grid[3][3] - grid[0][3]*grid[2][2]*grid[3][0])*d
		matrix.grid[1][2] = (m13_00               *grid[3][2] + m10_02               *grid[3][3] + m12_03               *grid[3][0] - m12_00               *grid[3][3] - m13_02               *grid[3][0] - m10_03               *grid[3][2])*d
		matrix.grid[1][3] = (m12_00               *grid[2][3] + m13_02               *grid[2][0] + m10_03               *grid[2][2] - m13_00               *grid[2][2] - m10_02               *grid[2][3] - m12_03               *grid[2][0])*d
		matrix.grid[2][1] = (grid[0][0]*grid[2][3]*grid[3][1] + grid[0][1]*grid[2][0]*grid[3][3] + grid[0][3]*grid[2][1]*grid[3][0] - grid[0][0]*grid[2][1]*grid[3][3] - grid[0][1]*grid[2][3]*grid[3][0] - grid[0][3]*grid[2][0]*grid[3][1])*d
		matrix.grid[2][2] = (m11_00               *grid[3][3] + m13_01               *grid[3][0] + m10_03               *grid[3][1] - m13_00               *grid[3][1] - m10_01               *grid[3][3] - m11_03               *grid[3][0])*d
		matrix.grid[2][3] = (m13_00               *grid[2][1] + m10_01               *grid[2][3] + m11_03               *grid[2][0] - m11_00               *grid[2][3] - m13_01               *grid[2][0] - m10_03               *grid[2][1])*d
		matrix.grid[3][1] = (grid[0][0]*grid[2][1]*grid[3][2] + grid[0][1]*grid[2][2]*grid[3][0] + grid[0][2]*grid[2][0]*grid[3][1] - grid[0][0]*grid[2][2]*grid[3][1] - grid[0][1]*grid[2][0]*grid[3][2] - grid[0][2]*grid[2][1]*grid[3][0])*d
		matrix.grid[3][2] = (m12_00               *grid[3][1] + m10_01               *grid[3][2] + m11_02               *grid[3][0] - m11_00               *grid[3][2] - m12_01               *grid[3][0] - m10_02               *grid[3][1])*d
		matrix.grid[3][3] = (m11_00               *grid[2][2] + m12_01               *grid[2][0] + m10_02               *grid[2][1] - m12_00               *grid[2][1] - m10_01               *grid[2][2] - m11_02               *grid[2][0])*d

		Return matrix
		
	End

	Method Multiply:Void(mat:Matrix)
		'' 3x4 multiply
		''consider Strassen's algorithm?
	
		Local m00# = grid[0][0]*mat.grid[0][0] + grid[1][0]*mat.grid[0][1] + grid[2][0]*mat.grid[0][2] + grid[3][0]*mat.grid[0][3]
		Local m01# = grid[0][1]*mat.grid[0][0] + grid[1][1]*mat.grid[0][1] + grid[2][1]*mat.grid[0][2] + grid[3][1]*mat.grid[0][3]
		Local m02# = grid[0][2]*mat.grid[0][0] + grid[1][2]*mat.grid[0][1] + grid[2][2]*mat.grid[0][2] + grid[3][2]*mat.grid[0][3]
		'Local m03# = grid[0][3]*mat.grid[0][0] + grid[1][3]*mat.grid[0][1] + grid[2][3]*mat.grid[0][2] + grid[3][3]*mat.grid[0][3]
		Local m10# = grid[0][0]*mat.grid[1][0] + grid[1][0]*mat.grid[1][1] + grid[2][0]*mat.grid[1][2] + grid[3][0]*mat.grid[1][3]
		Local m11# = grid[0][1]*mat.grid[1][0] + grid[1][1]*mat.grid[1][1] + grid[2][1]*mat.grid[1][2] + grid[3][1]*mat.grid[1][3]
		Local m12# = grid[0][2]*mat.grid[1][0] + grid[1][2]*mat.grid[1][1] + grid[2][2]*mat.grid[1][2] + grid[3][2]*mat.grid[1][3]
		'Local m13# = grid[0][3]*mat.grid[1][0] + grid[1][3]*mat.grid[1][1] + grid[2][3]*mat.grid[1][2] + grid[3][3]*mat.grid[1][3]
		Local m20# = grid[0][0]*mat.grid[2][0] + grid[1][0]*mat.grid[2][1] + grid[2][0]*mat.grid[2][2] + grid[3][0]*mat.grid[2][3]
		Local m21# = grid[0][1]*mat.grid[2][0] + grid[1][1]*mat.grid[2][1] + grid[2][1]*mat.grid[2][2] + grid[3][1]*mat.grid[2][3]
		Local m22# = grid[0][2]*mat.grid[2][0] + grid[1][2]*mat.grid[2][1] + grid[2][2]*mat.grid[2][2] + grid[3][2]*mat.grid[2][3]
		'Local m23# = grid[0][3]*mat.grid[2][0] + grid[1][3]*mat.grid[2][1] + grid[2][3]*mat.grid[2][2] + grid[3][3]*mat.grid[2][3]
		Local m30# = grid[0][0]*mat.grid[3][0] + grid[1][0]*mat.grid[3][1] + grid[2][0]*mat.grid[3][2] + grid[3][0]*mat.grid[3][3]
		Local m31# = grid[0][1]*mat.grid[3][0] + grid[1][1]*mat.grid[3][1] + grid[2][1]*mat.grid[3][2] + grid[3][1]*mat.grid[3][3]
		Local m32# = grid[0][2]*mat.grid[3][0] + grid[1][2]*mat.grid[3][1] + grid[2][2]*mat.grid[3][2] + grid[3][2]*mat.grid[3][3]
		'Local m33# = grid[0][3]*mat.grid[3][0] + grid[1][3]*mat.grid[3][1] + grid[2][3]*mat.grid[3][2] + grid[3][3]*mat.grid[3][3]
		
		grid[0][0]=m00
		grid[0][1]=m01
		grid[0][2]=m02
		'grid[0][3]=m03
		grid[1][0]=m10
		grid[1][1]=m11
		grid[1][2]=m12
		'grid[1][3]=m13
		grid[2][0]=m20
		grid[2][1]=m21
		grid[2][2]=m22
		'grid[2][3]=m23
		grid[3][0]=m30
		grid[3][1]=m31
		grid[3][2]=m32
		'grid[3][3]=m33
		
	End

	Method Multiply4:Void(mat:Matrix)
		'' 4x4 multiply
		''consider Strassen's algorithm?
	
		Local m00# = grid[0][0]*mat.grid[0][0] + grid[1][0]*mat.grid[0][1] + grid[2][0]*mat.grid[0][2] + grid[3][0]*mat.grid[0][3]
		Local m01# = grid[0][1]*mat.grid[0][0] + grid[1][1]*mat.grid[0][1] + grid[2][1]*mat.grid[0][2] + grid[3][1]*mat.grid[0][3]
		Local m02# = grid[0][2]*mat.grid[0][0] + grid[1][2]*mat.grid[0][1] + grid[2][2]*mat.grid[0][2] + grid[3][2]*mat.grid[0][3]
		Local m03# = grid[0][3]*mat.grid[0][0] + grid[1][3]*mat.grid[0][1] + grid[2][3]*mat.grid[0][2] + grid[3][3]*mat.grid[0][3]
		Local m10# = grid[0][0]*mat.grid[1][0] + grid[1][0]*mat.grid[1][1] + grid[2][0]*mat.grid[1][2] + grid[3][0]*mat.grid[1][3]
		Local m11# = grid[0][1]*mat.grid[1][0] + grid[1][1]*mat.grid[1][1] + grid[2][1]*mat.grid[1][2] + grid[3][1]*mat.grid[1][3]
		Local m12# = grid[0][2]*mat.grid[1][0] + grid[1][2]*mat.grid[1][1] + grid[2][2]*mat.grid[1][2] + grid[3][2]*mat.grid[1][3]
		Local m13# = grid[0][3]*mat.grid[1][0] + grid[1][3]*mat.grid[1][1] + grid[2][3]*mat.grid[1][2] + grid[3][3]*mat.grid[1][3]
		Local m20# = grid[0][0]*mat.grid[2][0] + grid[1][0]*mat.grid[2][1] + grid[2][0]*mat.grid[2][2] + grid[3][0]*mat.grid[2][3]
		Local m21# = grid[0][1]*mat.grid[2][0] + grid[1][1]*mat.grid[2][1] + grid[2][1]*mat.grid[2][2] + grid[3][1]*mat.grid[2][3]
		Local m22# = grid[0][2]*mat.grid[2][0] + grid[1][2]*mat.grid[2][1] + grid[2][2]*mat.grid[2][2] + grid[3][2]*mat.grid[2][3]
		Local m23# = grid[0][3]*mat.grid[2][0] + grid[1][3]*mat.grid[2][1] + grid[2][3]*mat.grid[2][2] + grid[3][3]*mat.grid[2][3]
		Local m30# = grid[0][0]*mat.grid[3][0] + grid[1][0]*mat.grid[3][1] + grid[2][0]*mat.grid[3][2] + grid[3][0]*mat.grid[3][3]
		Local m31# = grid[0][1]*mat.grid[3][0] + grid[1][1]*mat.grid[3][1] + grid[2][1]*mat.grid[3][2] + grid[3][1]*mat.grid[3][3]
		Local m32# = grid[0][2]*mat.grid[3][0] + grid[1][2]*mat.grid[3][1] + grid[2][2]*mat.grid[3][2] + grid[3][2]*mat.grid[3][3]
		Local m33# = grid[0][3]*mat.grid[3][0] + grid[1][3]*mat.grid[3][1] + grid[2][3]*mat.grid[3][2] + grid[3][3]*mat.grid[3][3]
		
		grid[0][0]=m00
		grid[0][1]=m01
		grid[0][2]=m02
		grid[0][3]=m03
		grid[1][0]=m10
		grid[1][1]=m11
		grid[1][2]=m12
		grid[1][3]=m13
		grid[2][0]=m20
		grid[2][1]=m21
		grid[2][2]=m22
		grid[2][3]=m23
		grid[3][0]=m30
		grid[3][1]=m31
		grid[3][2]=m32
		grid[3][3]=m33
		
	End

	Method Multiply:Vector(v1:Vector)
		'' 3x3 only
		Local v2:Vector = New Vector
		
		v2.x = grid[0][0]*v1.x + grid[1][0]*v1.y + grid[2][0]*v1.z
		v2.y = grid[0][1]*v1.x + grid[1][1]*v1.y + grid[2][1]*v1.z
		v2.z = grid[0][2]*v1.x + grid[1][2]*v1.y + grid[2][2]*v1.z
		
		Return v2
	End

	Method Translate:Void(x:Float,y:Float,z:Float)
	
		grid[3][0] = grid[0][0]*x + grid[1][0]*y + grid[2][0]*z + grid[3][0]
		grid[3][1] = grid[0][1]*x + grid[1][1]*y + grid[2][1]*z + grid[3][1]
		grid[3][2] = grid[0][2]*x + grid[1][2]*y + grid[2][2]*z + grid[3][2]

	End 
	
	Method Translate4:Void(x#,y#,z#,w#=1.0)
	
		grid[3][0] = grid[0][0]*x + grid[1][0]*y + grid[2][0]*z + grid[3][0]*w
		grid[3][1] = grid[0][1]*x + grid[1][1]*y + grid[2][1]*z + grid[3][1]*w
		grid[3][2] = grid[0][2]*x + grid[1][2]*y + grid[2][2]*z + grid[3][2]*w
		grid[3][3] = grid[0][3]*x + grid[1][3]*y + grid[2][3]*z + grid[3][3]*w
		
	End Method
	
	Method Transpose:Matrix()
	
		Local mat:Matrix = Self.Copy()
		
		grid[0][0]=mat.grid[0][0]
		grid[1][0]=mat.grid[0][1]
		grid[2][0]=mat.grid[0][2]
		grid[3][0]=mat.grid[0][3]
		
		grid[0][1]=mat.grid[1][0]
		grid[1][1]=mat.grid[1][1]
		grid[2][1]=mat.grid[1][2]
		grid[3][1]=mat.grid[1][3]
		
		grid[0][2]=mat.grid[2][0]
		grid[1][2]=mat.grid[2][1]
		grid[2][2]=mat.grid[2][2]
		grid[3][2]=mat.grid[2][3]
		
		grid[0][3]=mat.grid[3][0]
		grid[1][3]=mat.grid[3][1]
		grid[2][3]=mat.grid[3][2]
		grid[3][3]=mat.grid[3][3]
		
		Return Self
	End
		
	Method Scale:Void(sx:Float,sy:Float,sz:Float)
		
		If sx=1.0 And sy=1.0 And sz=1.0 Then Return
		
		grid[0][0] = grid[0][0]*sx
		grid[0][1] = grid[0][1]*sx
		grid[0][2] = grid[0][2]*sx

		grid[1][0] = grid[1][0]*sy
		grid[1][1] = grid[1][1]*sy
		grid[1][2] = grid[1][2]*sy

		grid[2][0] = grid[2][0]*sz
		grid[2][1] = grid[2][1]*sz
		grid[2][2] = grid[2][2]*sz
		
	End 
	
	''special function to remove global scale after a 3x3 inverse
	Method InverseScale:Void(sx#, sy#, sz#)
		If sx=1.0 And sy=1.0 And sz=1.0 Then Return
		
		sx = 1.0/(sx*sx); sy = 1.0/(sy*sy); sz = 1.0/(sz*sz)
		
		''3x4
		grid[0][0] = grid[0][0]*sx
		grid[0][1] = grid[0][1]*sx
		grid[0][2] = grid[0][2]*sx

		grid[1][0] = grid[1][0]*sy
		grid[1][1] = grid[1][1]*sy
		grid[1][2] = grid[1][2]*sy

		grid[2][0] = grid[2][0]*sz
		grid[2][1] = grid[2][1]*sz
		grid[2][2] = grid[2][2]*sz
		
		grid[3][0] = grid[3][0]*sx
		grid[3][1] = grid[3][1]*sy
		grid[3][2] = grid[3][2]*sz
		
	End
	
	Method FastRotateScale:Void(rx:Float,ry:Float,rz:Float,scx:Float,scy:Float,scz:Float)
		''this function will overwrite current matrix
		
		Local sx:Float, sy:Float, sz:Float, cx:Float, cy:Float, cz:Float, theta:Float
		
		'' rotation angle about X-axis (pitch)
		theta = rx 
		sx = Sin(theta)
		cx = Cos(theta)
		
		'' rotation angle about Y-axis (yaw)
		theta = ry 
		sy = Sin(theta)
		cy = Cos(theta)
		
		'' rotation angle about Z-axis (roll)
		theta = rz 
		sz = Sin(theta)
		cz = Cos(theta)
		
		Local sycz:Float = sy*cz
		Local cysz:Float = cy*sz
		Local sysz:Float = sy*sz
		Local cycz:Float = cy*cz
		
		'' determine left axis
		grid[0][0] = (cycz+sysz*sx) *scx
		grid[0][1] = (cx*sz) *scx
		grid[0][2] = (-sycz+cysz*sx) *scx
		
		'' determine up axis
		grid[1][0] = (-cysz+sycz*sx) *scy
		grid[1][1] = (cx*cz) *scy
		grid[1][2] = (sysz+cycz*sx) *scy
		
		'' determine forward axis
		grid[2][0] = (sy*cx) *scz
		grid[2][1] = (-sx) *scz
		grid[2][2] = (cx*cy) *scz

		
	End
	
	Method Rotate:Void(rx:Float,ry:Float,rz:Float)
		'' yaw-pitch-roll = y-x-z
			
		Local cos_ang#,sin_ang#, m20#,m21#,m22#,m00#,m01#,m02#,r1#,r2#,r3#
	
		' yaw
	
		cos_ang=Cos(ry)
		sin_ang=Sin(ry)
	
		m00 = grid[0][0]*cos_ang + grid[2][0]*-sin_ang
		m01 = grid[0][1]*cos_ang + grid[2][1]*-sin_ang
		m02 = grid[0][2]*cos_ang + grid[2][2]*-sin_ang
	
		m20 = grid[0][0]*sin_ang + grid[2][0]*cos_ang
		m21 = grid[0][1]*sin_ang + grid[2][1]*cos_ang
		m22 = grid[0][2]*sin_ang + grid[2][2]*cos_ang
		
		' pitch
		
		cos_ang=Cos(rx)
		sin_ang=Sin(rx)
	
		Local m10# = grid[1][0]*cos_ang + m20*sin_ang
		Local m11# = grid[1][1]*cos_ang + m21*sin_ang
		Local m12# = grid[1][2]*cos_ang + m22*sin_ang
	
		grid[2][0] = grid[1][0]*-sin_ang + m20*cos_ang
		grid[2][1] = grid[1][1]*-sin_ang + m21*cos_ang
		grid[2][2] = grid[1][2]*-sin_ang + m22*cos_ang
		
		' roll
		
		cos_ang=Cos(rz)
		sin_ang=Sin(rz)
	
		grid[0][0] = m00*cos_ang + m10*sin_ang
		grid[0][1] = m01*cos_ang + m11*sin_ang
		grid[0][2] = m02*cos_ang + m12*sin_ang
	
		grid[1][0] = m00*-sin_ang + m10*cos_ang
		grid[1][1] = m01*-sin_ang + m11*cos_ang
		grid[1][2] = m02*-sin_ang + m12*cos_ang
	


	End 
	
	Method RotatePitch:Void(ang:Float)
	
		Local cos_ang#=Cos(ang)
		Local sin_ang#=Sin(ang)
	
		Local m10# = grid[1][0]*cos_ang + grid[2][0]*sin_ang
		Local m11# = grid[1][1]*cos_ang + grid[2][1]*sin_ang
		Local m12# = grid[1][2]*cos_ang + grid[2][2]*sin_ang

		grid[2][0] = grid[1][0]*-sin_ang + grid[2][0]*cos_ang
		grid[2][1] = grid[1][1]*-sin_ang + grid[2][1]*cos_ang
		grid[2][2] = grid[1][2]*-sin_ang + grid[2][2]*cos_ang

		grid[1][0]=m10
		grid[1][1]=m11
		grid[1][2]=m12

	End 
	
	Method RotateYaw:Void(ang:Float)
	
		Local cos_ang#=Cos(ang)
		Local sin_ang#=Sin(ang)
	
		Local m00# = grid[0][0]*cos_ang + grid[2][0]*-sin_ang
		Local m01# = grid[0][1]*cos_ang + grid[2][1]*-sin_ang
		Local m02# = grid[0][2]*cos_ang + grid[2][2]*-sin_ang

		grid[2][0] = grid[0][0]*sin_ang + grid[2][0]*cos_ang
		grid[2][1] = grid[0][1]*sin_ang + grid[2][1]*cos_ang
		grid[2][2] = grid[0][2]*sin_ang + grid[2][2]*cos_ang

		grid[0][0]=m00
		grid[0][1]=m01
		grid[0][2]=m02

	End 
	
	Method RotateRoll:Void(ang:Float)
	
		Local cos_ang#=Cos(ang)
		Local sin_ang#=Sin(ang)

		Local m00# = grid[0][0]*cos_ang + grid[1][0]*sin_ang
		Local m01# = grid[0][1]*cos_ang + grid[1][1]*sin_ang
		Local m02# = grid[0][2]*cos_ang + grid[1][2]*sin_ang

		grid[1][0] = grid[0][0]*-sin_ang + grid[1][0]*cos_ang
		grid[1][1] = grid[0][1]*-sin_ang + grid[1][1]*cos_ang
		grid[1][2] = grid[0][2]*-sin_ang + grid[1][2]*cos_ang

		grid[0][0]=m00
		grid[0][1]=m01
		grid[0][2]=m02

	End 
		

	'' bbdoc: Gets the current pitch of the matrix
	''
	Method GetPitch:Float()

		Local x# = grid[2][0]
		Local y# = grid[2][1]
		Local z# = grid[2][2]
		Return -ATan2( y, Sqrt( x*x+z*z ) )
		
	End 

	'' bbdoc: Gets the current yaw of the matrix
	''
	Method GetYaw:Float()
	
		Local x# = grid[2][0]
		Local z# = grid[2][2]	
		Return ATan2( x,z )
		
	End 
	
	'' bbdoc: Gets the current roll of the matrix
	''
	Method GetRoll:Float()
	
		Local iy# = grid[0][1]
		Local jy# = grid[1][1]
		Return ATan2( iy, jy )
	
	End 
	
	''
	'' new functions for monkey 2012
	''
	
	''bbdoc: Transforms a point through the matrix, returns a float array
	''bbdoc: may need to negate z... p[2] = -p[2]
	Method TransformPoint:Float[](x:Float, y:Float, z:Float, w:Float=1.0)
		
		Local p0:Float,p1:Float,p2:Float,p3:Float
		
		'' -z, opengl
		
		p0 = grid[0][0]*x + grid[1][0]*y + grid[2][0]*z + grid[3][0] *w
		p1 = grid[0][1]*x + grid[1][1]*y + grid[2][1]*z + grid[3][1] *w
		p2 = grid[0][2]*x + grid[1][2]*y + grid[2][2]*z + grid[3][2] *w

		
		Return [p0,p1,p2]
	End


	Method Multiply:Line( q:Line)
		Local t:Vector = Self.Multiply(q.o)
		Return New Line(t, Self.Multiply(q.o.Add(q.d)).Subtract(t) )
	End



	
	''bbdoc: returns a matrix class from an float array [16]
	''bbdoc: usually used for tranferring OpenGL data
	
	Method FromArray:Void( arr:Float[] )
	
		grid[0][0] = arr[0];  grid[0][1] = arr[1];  grid[0][2] = arr[2];  grid[0][3] = arr[3]
		grid[1][0] = arr[4];  grid[1][1] = arr[5];  grid[1][2] = arr[6];  grid[1][3] = arr[7]
		grid[2][0] = arr[8];  grid[2][1] = arr[9];  grid[2][2] = arr[10]; grid[2][3] = arr[11]
		grid[3][0] = arr[12]; grid[3][1] = arr[13]; grid[3][2] = arr[14]; grid[3][3] = arr[15]

	End
	

	
	Method ToArray:Float[]()
	
		Local arr:Float[16]
		
		arr[0] = grid[0][0]; arr[1]= grid[0][1]; arr[2]= grid[0][2]; arr[3]= grid[0][3]
		arr[4] = grid[1][0]; arr[5]= grid[1][1]; arr[6]= grid[1][2]; arr[7]= grid[1][3]
		arr[8] = grid[2][0]; arr[9]= grid[2][1]; arr[10]= grid[2][2]; arr[11]= grid[2][3]
		arr[12] = grid[3][0]; arr[13]= grid[3][1]; arr[14]= grid[3][2]; arr[15]= grid[3][3]

		Return arr
	End
	
	
	Method ToArray:Void(arr:Float[])
		
		arr[0] = grid[0][0]; arr[1]= grid[0][1]; arr[2]= grid[0][2]; arr[3]= grid[0][3]
		arr[4] = grid[1][0]; arr[5]= grid[1][1]; arr[6]= grid[1][2]; arr[7]= grid[1][3]
		arr[8] = grid[2][0]; arr[9]= grid[2][1]; arr[10]= grid[2][2]; arr[11]= grid[2][3]
		arr[12] = grid[3][0]; arr[13]= grid[3][1]; arr[14]= grid[3][2]; arr[15]= grid[3][3]

	End

	
	Method Update:Void( a:Vector, b:Vector, c:Vector)

		grid[0][0] = a.x; grid[0][1] = a.y; grid[0][2] = a.z
		grid[1][0] = b.x; grid[1][1] = b.y; grid[1][2] = b.z
		grid[2][0] = c.x; grid[2][1] = c.y; grid[2][2] = c.z

	End

		
End 

Function PrintMatrix:Void(mat:Matrix)
	
	Print mat.grid[0][0]+":"+mat.grid[1][0]+":"+mat.grid[2][0]+":"+mat.grid[3][0]
	Print mat.grid[0][1]+":"+mat.grid[1][1]+":"+mat.grid[2][1]+":"+mat.grid[3][1]
	Print mat.grid[0][2]+":"+mat.grid[1][2]+":"+mat.grid[2][2]+":"+mat.grid[3][2]	
	Print mat.grid[0][3]+":"+mat.grid[1][3]+":"+mat.grid[2][3]+":"+mat.grid[3][3]
	
End

