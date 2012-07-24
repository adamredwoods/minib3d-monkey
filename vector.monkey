

Class Vector

	Field x#,y#,z#
	
	Const EPSILON=.0001

	Method New(xx#=0.0,yy#=0.0,zz#=0.0)
		
		x=xx
		y=yy
		z=zz
		
	End 
	
	Method Delete()

		
	End 

	Function Create:Vector(x#,y#,z#)
	
		Local new_vec:Vector=New Vector
		vec.x=x
		vec.y=y
		vec.z=z
		
		Return vec
		
	End 
	
	Method Copy:Vector()
	
		Local vec:Vector=New Vector
	
		vec.x=x
		vec.y=y
		vec.z=z
	
		Return vec
	
	End 
	
	Method Add:Vector(vec:Vector)
		
		Return New Vector(x+vec.x, y+vec.y, z+vec.z)
	
	End
	
	Method Add:Vector(vx:Float, vy:Float, vz:Float)

		Return New Vector(x+vx, y+vy, z+vz)
	
	End
	
	Method Subtract:Vector(vec:Vector)

		Return New Vector(x-vec.x, y-vec.y, z-vec.z)
	
	End 
	
	Method Subtract:Vector(vx:Float, vy:Float, vz:Float)

		Return New Vector(x-vx, y-vy, z-vz)
	
	End
	
	Method Multiply:Vector(val#)
		
		Return New Vector(x*val,y*val,z*val)
	
	End 
	
	Method Divide:Vector(val#)
	
		Local inv:Float = 1.0/val
		Return New Vector(x*inv,y*inv,z*inv)
	
	End 
	
	Method Dot:Float(vec:Vector)
	
		Return (x*vec.x)+(y*vec.y)+(z*vec.z)
	
	End 
	
	Method Cross:Vector(vec:Vector)
		
		Return New Vector( (y*vec.z)-(z*vec.y), (z*vec.x)-(x*vec.z), (x*vec.y)-(y*vec.x) )
	
	End 
	
	Method Normalize:Vector()
	
		If x=0 And y=0 And z=0 Then Return New Vector(0,0,0)
		
		Local d#=1.0/Sqrt(x*x+y*y+z*z)
		Return New Vector(x*d,y*d,z*d)
	End 
	
	Method Normalise:Vector()
	
		If x=0 And y=0 And z=0 Then Return New Vector(0,0,0)
		
		Local d#=1.0/Sqrt(x*x+y*y+z*z)
		Return New Vector(x*d,y*d,z*d)
	End 
	
	Method Length#()
			
		Return Sqrt(x*x+y*y+z*z)

	End 
	
	Method SquaredLength#()
	
		Return x*x+y*y+z*z

	End 
	
	Method SetLength(val#)
	
		Local vec:Vector = Normalize()
		x=vec.x*val
		y=vec.y*val
		z=vec.z*val

	End 
	
	Method Compare:Int ( with:Object )
		Local q:Vector=Vector(with)
		If x-q.x>EPSILON Return 1
		If q.x-x>EPSILON Return -1
		If y-q.y>EPSILON Return 1
		If q.y-y>EPSILON Return -1
		If z-q.z>EPSILON Return 1
		If q.z-z>EPSILON Return -1
		Return 0
	End 

	' Function by patmaba
	Function VectorYaw#(vx#,vy#,vz#)

		Return ATan2(-vx,vz)
	
	End 

	' Function by patmaba
	Function VectorPitch#(vx#,vy#,vz#)

		Local ang#=ATan2(Sqrt(vx*vx+vz*vz),vy)-90.0

		If ang<=0.0001 And ang>=-0.0001 Then ang=0
	
		Return ang
	
	End 
	
	Method Distance:Float ( q:Vector)
		Local xx:Float = x-q.x
		Local yy:Float = y-q.y
		Local zz:Float = z-q.z
		Return Sqrt(xx*xx + yy*yy + zz*zz)
	End
	
	Method Negate:Vector()
		Return New Vector(-x, -y, -z)
	End
	
	Method Update( xx:Float, yy:Float, zz:Float)
		x=xx; y=yy; z=zz
	End
	
	
End 
