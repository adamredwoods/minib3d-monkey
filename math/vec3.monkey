Import minib3d.math.vector
Import minib3d.math.matrix

''
''-- this vector class does not create new vectors
''
Class Vec3 Extends Vector
	
	Private
		global temp:Vector = New Vector
	Public
	
	Function Add:Void( a:Vector, b:Vector, out:Vector ) 
		out.x = a.x+b.x; out.y=a.y+b.y; out.z = a.z+b.z
	End
	
	Function Multiply:Void( a:Vector, b:Vector, out:Vector ) 
		out.x = a.x*b.x; out.y=a.y*b.y; out.z = a.z*b.z
	end
	
	Function Multiply:Void( a:Vector, b:Float, out:Vector ) 
		out.x = a.x*b; out.y=a.y*b; out.z = a.z*b
	End
	
	Function Multiply:Void( a:Vector, b:Matrix, out:Vector ) 
		'' 3x1
		temp.x = b.grid[0][0]*a.x + b.grid[1][0]*a.y + b.grid[2][0]*a.z
		temp.y = b.grid[0][1]*a.x + b.grid[1][1]*a.y + b.grid[2][1]*a.z
		temp.z = b.grid[0][2]*a.x + b.grid[1][2]*a.y + b.grid[2][2]*a.z
		out.x = temp.x
		out.y = temp.y
		out.z = temp.z
	end

End