Import vector
Import matrix

Class Line
	Public
	
	Field o:Vector, d:Vector ''Line.d is relative to Line.o (not world space)
	
	Method New()
		o = New Vector
		d = New Vector
	End

	Method New ( oo:Vector, dd:Vector )
		o=oo.Copy()
		d=dd.Copy()
	End
	
	Method New(ox:Float,oy:Float,oz:Float,dx:Float,dy:Float,dz:Float)

		o=New Vector(ox,oy,oz)
		d=New Vector(dx,dy,dz)
	
	End
	
	Method FromPoints ( oo:Vector, dd:Vector )
		o=oo.Copy()
		d=dd.Subtract(oo)
	End
	
	Method Update(ox:Float,oy:Float,oz:Float,dx:Float,dy:Float,dz:Float)
		
		o.x = ox; o.y = oy; o.z = oz
		d.x = dx; d.y = dy; d.z = dz
		
	End
	
	Method Update(l:Line)
		
		o.x = l.o.x; o.y = l.o.y; o.z = l.o.z
		d.x = l.d.x; d.y = l.d.y; d.z = l.d.z
		
	End
	
	Method Add:Line ( q:Vector)
		Return New Line( o.Add(q), d)
	End
	'Return Line( o+q,d );

	Method Subtract:Line(q:Vector)
		Return New Line(o.Subtract(q),d)
	End
	''Return Line( o-q,d );

	Method Multiply:Vector(q:Float)
		'Return o.Add(d.Multiply(q))
		Return New Vector(o.x+(d.x*q),o.y+(d.y*q),o.z+(d.z*q))
	End
	''Return o+d*q;

	Method Nearest:Vector(q:Vector)
		Local v:Float = d.Dot(q.Subtract(o)) / d.Dot(d)
		Return o.Add(d.Multiply(v) )
	End
	
	Method Length:Float ()
		Local x:Float = o.x-d.x
		Local y:Float = o.y-d.y
		Local z:Float = o.z-d.z
		Return Sqrt(x*x + y*y + z*z)
	End
	
	Method ToString:String()
		Return o.x+" "+o.y+" "+o.z+" :: "+(o.x+d.x)+" "+(o.y+d.y)+" "+(o.z+d.z)
	End
End


Class Plane
	Public
	
	Field n:Vector = New Vector
	Field d:Float =0.0


	''normal/offset form
	Method New( nn:Vector, dd:Float)
		n=nn.Copy()
		d=dd
	End

	''point/normal form
	Method New( p:Vector, nn:Vector)
		n=nn.Copy()
		d=-n.Dot(p)
	End


	''create plane from tri
	Method New( v0:Vector, v1:Vector, v2:Vector)
		n = v1.Subtract(v0).Cross( v2.Subtract(v0)).Normalize
		d = -n.Dot(v0)
	End
	
	Method Update( nnx:Float, nny:Float, nnz:Float, dd:Float)
		n.x=nnx; n.y=nny; n.z=nnz
		d=dd
	End

	Method Negate()
		Return New Plane(n.Negate(),d.Negate() )
	End


	Method T_Intersect:Float( q:Line)
		'Return -Distance(q.o)/n.Dot(q.d)
		Return -(n.Dot(q.o) + d)/n.Dot(q.d)
	End


	Method Intersect:Vector( q:Line)
		Return q.Multiply(T_Intersect(q))
	End


	Method Intersect:Line( q:Plane )
		Local lv:Vector = n.Cross( q.n ).Normalize()
		Return New Line( q.Intersect( New Line( Nearest( n.Multiply(-d)), n.Cross(lv) ) ), lv)
	End
	
	Method IntersectNorm:Vector( q:Plane )
		Return n.Cross( q.n ).Normalize()
	End

	Method Nearest:Vector( q:Vector)
		Return q.Subtract(n.Multiply( Distance(q) ))
	End


	Method Negate()
		n=-n
		d=-d
	End
	
	Method Distance:Float( q:Vector )
		Return n.Dot(q) + d
	End

End



Class Box
	Const INFINITY:Float = 999999999.000
	
	Field a:Vector, b:Vector ''a = min corner, b= max corner
	
	Method New()
		a = New Vector(INFINITY,INFINITY,INFINITY)
		b = New Vector(-INFINITY,-INFINITY,-INFINITY)
	End
	
	Method New(q:Vector)
		a = q.Copy()
		b = q.Copy()
	End
	
	Method New(aa:Vector,bb:Vector)
		a = aa.Copy()
		b = bb.Copy()
	End
	
	Method New(aa:Vector,bb:Vector, cc:Vector)
		a = aa.Copy()
		b = aa.Copy()
		Local q:Vector = bb
		If( q.x<a.x ) Then a.x=q.x
		If( q.y<a.y ) Then a.y=q.y
		If( q.z<a.z ) Then a.z=q.z
		If( q.x>b.x ) Then b.x=q.x
		If( q.y>b.y ) Then b.y=q.y
		If( q.z>b.z ) Then b.z=q.z
		q = cc
		If( q.x<a.x ) Then a.x=q.x
		If( q.y<a.y ) Then a.y=q.y
		If( q.z<a.z ) Then a.z=q.z
		If( q.x>b.x ) Then b.x=q.x
		If( q.y>b.y ) Then b.y=q.y
		If( q.z>b.z ) Then b.z=q.z
	End
	
	Method New(l:Line)
		a = l.o.Copy()
		b = l.o.Copy()
		Update(l.o.Add(l.d))
	End

	Method Clear()
		a.x=INFINITY
		a.y=INFINITY
		a.z=INFINITY
		b.x=-INFINITY
		b.y=-INFINITY
		b.z=-INFINITY
	End
	
	Method Empty:Bool()
		Return (b.x<a.x) Or (b.y<a.y) Or (b.z<a.z)
	End
	
	Method Centre:Vector()
		Return New Vector( (a.x+b.x)*0.5,(a.y+b.y)*0.5,(a.z+b.z)*0.5 )
	End
	
	Method Corner:Vector( n:Int )
		Local q:Vector, w:Vector, e:Vector
		If n&1 Then q=b Else q=a

		If n&2 Then w=b Else w=a
		
		If n&4 Then e=b Else e=a
		
		Return New Vector( q.x,w.y,e.z )
	End
	
	Method Update( q:Vector )
		If( q.x<a.x ) Then a.x=q.x
		If( q.y<a.y ) Then a.y=q.y
		If( q.z<a.z ) Then a.z=q.z
		If( q.x>b.x ) Then b.x=q.x
		If( q.y>b.y ) Then b.y=q.y
		If( q.z>b.z ) Then b.z=q.z
	End
		
	Method Update( q:Box )
		If( q.a.x<a.x ) a.x=q.a.x
		If( q.a.y<a.y ) a.y=q.a.y
		If( q.a.z<a.z ) a.z=q.a.z
		If( q.b.x>b.x ) b.x=q.b.x
		If( q.b.y>b.y ) b.y=q.b.y
		If( q.b.z>b.z ) b.z=q.b.z
	End
	
	Method Update( l:Line )

		a.Overwrite(l.o)
		b.Overwrite(l.o)
		Update(l.o.Add(l.d))
		
	End
	
	Method Overlaps(q:Box)
		Local r1:Float, r2:Float, r3:Float, r4:Float, r5:Float, r6:Float
		If b.x<q.b.x Then r1 = b.x Else r1 = q.b.x
		If a.x>q.a.x Then r2 = a.x Else r2 = q.a.x
		
		If b.y<q.b.y Then r3 = b.y Else r3 = q.b.y
		If a.y>q.a.y Then r4 = a.y Else r4 = q.a.y
		
		If b.z<q.b.z Then r5 = b.z Else r5 = q.b.z
		If a.z>q.a.z Then r6 = a.z Else r6 = q.a.z
		
		Return ((r1>=r2) And (r3>=r4) And (r5>=r6))
		
	End
	
	Method Expand( n:Float )
		a.x-=n; a.y-=n; a.z-=n; b.x+=n; b.y+=n; b.z+=n
	End
	
	Method Expand( n:Vector )
		a.x-=n.x; a.y-=n.y; a.z-=n.z; b.x+=n.x; b.y+=n.y; b.z+=n.z
	End
	
	Method Width:Float()
		Return b.x-a.x
	End
	
	Method Height:Float()
		Return b.y-a.y
	End
	
	Method Depth:Float()
		Return b.z-a.z
	End
	
	Method Contains:Bool( q:Vector )
		Return (q.x>=a.x And q.x<=b.x And q.y>=a.y And q.y<=b.y And q.z>=a.z And q.z<=b.z)
	End
	
	Method ToString:String()
		Return a.x+" "+a.y+" "+a.z+" : "+b.x+" "+b.y+" "+b.z
	End
	
End



''
''This class was obscure, so some routines may be wrong
''
Class TransformMat

	Field m:Matrix
	Field v:Vector
	

	Method New()
		m = New Matrix
		v = New Vector
	End
	
	Method New( mm:Matrix, vv:Vector)
		v=vv.Copy()
		m=mm.Copy()
	End
	
	Method Copy:TransformMat()
		Return New TransformMat( m, v)
	End
	
	Method Inverse:TransformMat( ) ''' this may be wrong, but you probably could use Transpose() unless need scale removed
		Local t:TransformMat = Copy()
		''assuming the -m is a FULL inverse, but we are only using 3x3
		t.m.grid[3][0] = t.v.x
		t.m.grid[3][1] = t.v.y
		t.m.grid[3][2] = t.v.z
		t.m = t.m.Inverse4() ''full inverse
		t.v.x = t.m.grid[3][0]
		t.v.y = t.m.grid[3][1]
		t.v.z = t.m.grid[3][2]

		Return t
	End

	
	Method Transpose:TransformMat( )
		'' this is actually a fast inverse
		Local t:TransformMat = Self.Copy()
		t.m = t.m.Transpose()
		t.v = t.m.Multiply(t.v.Negate() )
		Return t
	End


	Method Multiply:Vector( q:Vector)
		Return m.Multiply(q).Add(v)
	End

	
	Method Multiply:Line( q:Line)
		Local t:Vector = m.Multiply(q.o).Add(v)
		Return New Line(t, m.Multiply(q.o.Add(q.d)).Add(v).Subtract(t) )
	End


	Method Multiply:Box( q:Box)
		Local b:Box = New Box(m.Multiply(q.Corner(0)).Add(v) )
		For Local k:Int=1 To 7
			b.Update( m.Multiply(q.Corner(k)).Add(v) )
		Next
		Return b
	End

	
	Method Multiply:TransformMat( q:TransformMat)
		Local t:TransformMat = New TransformMat
		t.m = m.Copy
		Local temp_m:Matrix = m.Copy
		
		t.m.Multiply( q.m)
		t.v = temp_m.Multiply(q.v).Add(v)
		Return t
	End


	Method Equals:Bool( q:TransformMat)
		If m.grid[0][0] = q.m.grid[0][0] And m.grid[1][0] = q.m.grid[1][0] And m.grid[2][0] = q.m.grid[2][0] And m.grid[3][0] = q.m.grid[3][0] And 
			m.grid[0][1] = q.m.grid[0][1] And m.grid[1][1] = q.m.grid[1][1] And m.grid[2][1] = q.m.grid[2][1] And m.grid[3][1] = q.m.grid[3][1] And 
			m.grid[0][2] = q.m.grid[0][2] And m.grid[1][2] = q.m.grid[1][2] And m.grid[2][2] = q.m.grid[2][2] And m.grid[3][2] = q.m.grid[3][2] And
			m.grid[0][3] = q.m.grid[0][3] And m.grid[1][3] = q.m.grid[1][3] And m.grid[2][3] = q.m.grid[2][3] And m.grid[3][3] = q.m.grid[3][3] And 
			v.x = q.v.x And v.y = q.v.y And v.z = q.v.z Then Return True Else Return False
	End

	
	Method Update(mm:Matrix, vv:Vector)
		m.Overwrite(mm)
		v.x=vv.x; v.y=vv.y; v.z=vv.z
	End
	
	Method NormalizeMatrix3x3()
		''internal use, used for box collisions
		''otherwise, will need orthonormalize method for Matrix class
		'' assumes: vectors are rows
		
		Local x:Float, y:Float, z:Float, d:Float
		For Local i:=0 To 2
			d = 1.0/Sqrt( m.grid[0][i]*m.grid[0][i] + m.grid[1][i]*m.grid[1][i] + m.grid[2][i]*m.grid[2][i])
			m.grid[0][i] *= d
			m.grid[1][i] *= d
			m.grid[2][i] *= d
		Next
		
	End
	
End



