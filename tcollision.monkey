Import minib3d
Import vector
Import geom


'' will need to port over a collision library specifically for monkey xplatform

Const MAX_TYPES=100

'collision methods
Const COLLISION_METHOD_SPHERE:Int=1
Const COLLISION_METHOD_POLYGON:Int=2
Const COLLISION_METHOD_BOX:Int=3

'collision actions
''-- damping (water)? -- sticking?
Const COLLISION_RESPONSE_NONE:Int=0
Const COLLISION_RESPONSE_STOP:Int=1
Const COLLISION_RESPONSE_SLIDE:Int=2
Const COLLISION_RESPONSE_SLIDEXZ:Int=3

Const COLLISION_EPSILON:Float=0.001


Class TCollisionPair

	Global list:List<TCollisionPair> =New List<TCollisionPair>
	Global ent_lists:List<TEntity>[MAX_TYPES]

	
	Field src_type:Int
	Field des_type:Int
	Field col_method=0
	Field response=0
	
	Method New()

	
	End 
	
	Method Delete()

	
	End 

	'' a better way to create tcollision lists
	Method ListAddLast(ent:TEntity, type_no:Int)
		
		If ent_lists[type_no]=Null Then ent_lists[type_no] = New List<TEntity> ' create new list is one doesn't exist
			
		ent_lists[type_no].AddLast(ent)
	
	End
	
	Method ListRemove(ent:TEntity, type_no:Int)
		
		ent_lists[type_no].RemoveEach(ent)
		
	End

	Function Collisions(src_no:Int, dest_no:Int, method_no:Int, response_no:Int=0)
	
		Local col:TCollisionPair=New TCollisionPair
		
		col.src_type=src_no
		col.des_type=dest_no
		col.col_method=method_no
		col.response=response_no
		
		' check to see if same collision pair already exists
		For Local col2:TCollisionPair=Eachin list
			If col2.src_type=col.src_type
				If col2.des_type=col.des_type
					
					' overwrite old method and response values
					col2.col_method=col.col_method
					col2.response=col.response

					Return

				Endif
			Endif
		Next
	
		list.AddLast(col)
	
	End 
	
	Function Clear()
	
		list.Clear()
		
	End
	
End 

Class TCollisionImpact

	Method New()

	
	End 
	
	Method Delete()
	
	
	End 


	Field x#,y#,z#
	Field nx#,ny#,nz#
	Field time#
	Field ent:TEntity
	Field surf:Int
	Field tri:Int

End 







Class CollisionInfo

	Field dv:Vector
	Field sv:Vector
	Field radii:Vector
	Field panic:Vector

	Field mesh_coll:MeshCollider
	Field radius:Float, inv_y_scale:Float, y_scale:Float

	Field n_hit:Int
	Field planes:Plane[3]

	Field coll_method:Int
	Field coll_line:Line
	Field dir:Vector
	Field tform:TransformMat=New TransformMat(New Matrix,New Vector)
	Field y_tform:TransformMat = New TransformMat

	
	Field td:Float
	Field td_xz:Float
	
	Field hits:Int
	
	Field dst_radius:Float
	Field ax:Float
	Field ay:Float
	Field az:Float
	Field bx:Float
	Field by:Float
	Field bz:Float
	
	'' globals
	Const MAX_HITS:Int=10
	Const EPSILON=0.000001		'' a small value
	
	'' per update globals
	Global vec_a:Vector = New Vector(0.0,0.0,0.0)
	Global vec_b:Vector = New Vector(0.0,0.0,0.0)
	Global vec_c:Vector = New Vector(0.0,0.0,0.0)
	'Local vec_radius:Vector = New Vector(0.0,0.0,0.0)
						
	Global vec_i:Vector = New Vector(0.0,0.0,0.0)
	Global vec_j:Vector = New Vector(0.0,0.0,0.0)
	Global vec_k:Vector = New Vector(0.0,0.0,0.0)

	Global t_mat:Matrix = New Matrix(vec_i,vec_j,vec_k)
				
	Global vec_v:Vector = New Vector(0.0,0.0,0.0)
	
	
	
	Global testx:Float, testy:Float, testz:Float
	Global testx2:Float, testy2:Float, testz2:Float
	
	
	
	Method New(sv2:Vector,dv2:Vector,radii2:Vector)
	
		dv = dv2.Copy()
		sv = sv2.Copy()
		panic = sv.Copy()
		radii = radii2.Copy()
		radius = radii.x
		
		planes[0] = New Plane(New Vector(0.0,0.0,0.0),0)
		planes[1] = New Plane(New Vector(0.0,0.0,0.0),0)
		planes[2] = New Plane(New Vector(0.0,0.0,0.0),0)
		
		y_scale=1.0
		inv_y_scale=1.0
		y_tform.m.grid[1][1]=1.0 ''mat.j.y = mat.grid[1][1]
	
		If( radii.x <> radii.y )
			y_scale=radius/radii.y
			y_tform.m.grid[1][1]=radius/radii.y
			inv_y_scale=1.0/y_scale
			sv.y *= y_scale
			dv.y *= y_scale
		Endif
	
		coll_line=New Line( sv.x, sv.y, sv.z, dv.x-sv.x, dv.y-sv.y, dv.z-sv.z )
		
		dir=New Vector((coll_line.d.x),(coll_line.d.y),(coll_line.d.z)).Normalize()
		td=coll_line.d.Length()
		
		Local tempvec:Vector =New Vector( coll_line.d.x,0,coll_line.d.z )
		td_xz = tempvec.Length()
	
		''
		
		hits=0
		dst_radius=1.0
		ax=1.0
		ay=1.0
		az=1.0
		bx=1.0
		by=1.0
		bz=1.0

	End
	
	Method Update (dst_radius2:Float,ax2:Float,ay2:Float,az2:Float,bx2:Float,by2:Float,bz2:Float)

		dst_radius=dst_radius2
		ax=ax2
		ay=ay2
		az=az2
		bx=bx2
		by=by2
		bz=bz2
	End
	
	
	
	
	Function UpdateCollisions()
	
		'DebugLog "Update Collisions"
	
		Local coll_obj:CollisionObject
		
		' loop through collision setup list, containing pairs of src entities and des entities to be check for collisions
		For Local i:Int=0 Until MAX_TYPES
		
			' if no entities exist of src_type then do not check for collisions
			If TCollisionPair.ent_lists[i]=Null Then Continue
	
			' loop through src entities
			For Local ent:TEntity=Eachin TCollisionPair.ent_lists[i]
	
				ent.no_collisions=0
				ent.collision=ent.collision.Resize(0)
		
				' if src entity is hidden or it's parent is hidden then do not check for collision
				If ent.Hidden()=True Then Continue
						
				vec_a.Update(ent.EntityX(True),ent.EntityY(True),ent.EntityZ(True)) ''line dest
				vec_b.Update(ent.old_x,ent.old_y,ent.old_z) ''line source
				vec_c.Update(ent.radius_x,ent.radius_y,ent.radius_x)
	
				''make collision line
				Local col_info:CollisionInfo =New CollisionInfo(vec_b,vec_a,vec_c)	
				Local response:Int
				
				Repeat
	
					Local hit:Int =0
					Local ent2_hit:TEntity=Null
					coll_obj=New CollisionObject			
					
					For Local col_pair:TCollisionPair=Eachin TCollisionPair.list
					
						If col_pair.src_type = i
						
							' if no entities exist of des_type then do not check for collisions
							If TCollisionPair.ent_lists[col_pair.des_type]=Null Then Continue
						
							' loop through entities2 that are paired with src entities
							For Local ent2:TEntity=Eachin TCollisionPair.ent_lists[col_pair.des_type]
			
								' if entity2 is hidden or it's parent is hidden then do not check for collision
								If ent2.Hidden()=True Then Continue
				
								If ent=ent2 Then Continue ' if src ent is same as entity2 then do not check for collision
								
								If QuickCheck(ent,ent2)=False Then Continue ' quick check to see if entities are colliding
			
			
								col_info.CollisionSetup(ent2, col_pair.col_method)
								hit = col_info.CollisionDetect(coll_obj)
								
			
								If hit

									ent2_hit=ent2
									response=col_pair.response
								
								Endif
							
							Next
						
						Endif
					
					Next
					
					If ent2_hit<>Null
	
						ent.no_collisions=ent.no_collisions+1
	
						Local i=ent.no_collisions-1
						ent.collision=ent.collision.Resize(i+1)
									
						ent.collision[i]=New TCollisionImpact
						ent.collision[i].x=coll_obj.col_coords.x 
						ent.collision[i].y=coll_obj.col_coords.y 
						ent.collision[i].z=coll_obj.col_coords.z 
						ent.collision[i].nx=coll_obj.col_normal.x
						ent.collision[i].ny=coll_obj.col_normal.y 
						ent.collision[i].nz=coll_obj.col_normal.z
						ent.collision[i].ent=ent2_hit
						
						If TMesh(ent2_hit)<>Null
							ent.collision[i].surf=coll_obj.surface & $0000ffff
						Else
							ent.collision[i].surf=0
						Endif
						
						''get the real tri index (byte packed in surface)
						ent.collision[i].tri=((coll_obj.surface & $ffff0000) Shr 16) 
	
							
						If col_info.CollisionResponse(coll_obj, response)=False Then Exit
						
					Else
					
						Exit
									
					Endif
										
				Forever
	

				Local hits:Int =col_info.CollisionFinal(coll_obj, response)
				
				If hits
								
					ent.PositionEntity(coll_obj.col_pos.x,coll_obj.col_pos.y,coll_obj.col_pos.z,True)
					
				Endif
		
				col_info = Null
				coll_obj = Null
	
				ent.old_x=ent.EntityX(True)
				ent.old_y=ent.EntityY(True)
				ent.old_z=ent.EntityZ(True)
	
			Next
											
		Next
	
	End 

	
	
	
	''
	''
	''
	Method CollisionSetup(ent:TEntity, col_method:Int)
	
		coll_method = col_method
		
		vec_i.Update(ent.mat.grid[0][0],ent.mat.grid[1][0],-ent.mat.grid[2][0])
		vec_j.Update(ent.mat.grid[0][1],ent.mat.grid[1][1],-ent.mat.grid[2][1])
		vec_k.Update(-ent.mat.grid[0][2],-ent.mat.grid[1][2],ent.mat.grid[2][2])
		t_mat.Update(vec_i,vec_j,vec_k)
		
		'mat = ent.mat.Inverse()
		''remove global scaling from matrix
		t_mat.Scale(1/(ent.gsx*ent.gsx),1/(ent.gsy*ent.gsy),1/(ent.gsz*ent.gsz)) 
		vec_v.Update(ent.mat.grid[3][0],ent.mat.grid[3][1],-ent.mat.grid[3][2])
		
	
		tform.Update(t_mat, vec_v)

		' if pick mode is sphere or box then update collision info object to include entity radius/box info
		If col_method<>COLLISION_METHOD_POLYGON
			Update(ent.radius_x,ent.box_x,ent.box_y,ent.box_z,ent.box_x+ent.box_w,ent.box_y+ent.box_h,ent.box_z+ent.box_d)
		Endif

		Local mesh:TMesh = TMesh(ent)
		If mesh<>Null	
			mesh_coll = mesh.col_tree.CreateMeshTree(mesh) ' create collision tree for mesh if necessary
		Endif
		

	
	End
	
	''--- Pick() depricated
	'Method Pick:Int(coll_obj:CollisionObject)

		'Local hit:Int=0
	
		'If( HitTest(coll_line, radius, tform, mesh_coll, coll_method, coll_obj, Self ) )
			
			'hit=True	
			
		'Endif
	
		'Return hit
	'End
	
	
	
	''
	''--deprecated HitTest()
	Method CollisionDetect:Int(coll_obj:CollisionObject)
		
		Local res:Int=0
		Local tf:TransformMat = tform
		
		If( y_scale<>1.0 )
		
			'Return HitTest(Self.coll_line, radius, Self.y_tform.Multiply(tform), mesh_coll, coll_method, coll_obj,Self )
			tf = y_tform.Multiply(tform)
			
		Endif
			
		'Return HitTest(Self.coll_line, radius, tform, mesh_coll, coll_method, coll_obj, Self )
		'Function HitTest:Int( line:Line, radius2:Float, tf:TransformMat, mesh_col:MeshCollider, methd:Int, coll_obj:CollisionObject, ci:CollisionInfo  )
		
		Select ( coll_method )
	
			Case COLLISION_METHOD_SPHERE
			
				res = coll_obj.SphereCollide( coll_line,radius,tf.v,dst_radius )
		
			Case COLLISION_METHOD_POLYGON
			
				res = mesh_coll.Collide( coll_line,radius,tf,coll_obj )

				''adjust normal

				coll_obj.normal = tf.m.Transpose().Multiply(coll_obj.normal).Normalize()
				
				'Local t:TransformMat =tf.Copy()
				't.NormalizeMatrix3x3()
				'coll_obj.normal=tf.m.Multiply(coll_obj.normal).Normalize()

				'coll_line = t.Transpose.Multiply(coll_line)
				
			Case COLLISION_METHOD_BOX
			
				Local t:TransformMat =tf.Copy()
				t.NormalizeMatrix3x3() ''------is this done in collisionsetup()?
				
				Local a:Vector = New Vector(ax,ay,az)
				Local b:Vector = New Vector(bx,by,bz)
				Local box:Box= New Box(a,b)
				
				Local l:Line = t.Transpose().Multiply(coll_line)
			
				If( coll_obj.BoxCollide( l ,radius,box ) ) ''BoxCollide( ~t*line,radius,box )
					coll_obj.normal=t.m.Multiply(coll_obj.normal)
					'coll_obj.normal.Normalize()
					res = True
				Endif
	
		End
		
		If res
		
			coll_obj.col_normal=coll_obj.normal
			coll_obj.col_time=coll_obj.time
			coll_obj.col_surface=coll_obj.surface
			coll_obj.col_index=coll_obj.index	
	
			coll_obj.col_coords=coll_line.d.Multiply(coll_obj.time).Add(coll_line.o) '.Subtract(coll_obj.normal.Multiply(radius))
			
			'coll_obj.col_coords=coll_line.d.Subtract(coll_line.o).Multiply(coll_obj.time).Add(coll_line.o).Subtract(coll_obj.normal.Multiply(radius))
			'coll_obj.col_coords=coll_line.Multiply(coll_obj.time).Subtract(coll_obj.normal.Multiply(radius))
	
		Endif
		
		Return res
	End
	
	
	
	Method CollisionResponse:Int(coll:CollisionObject,response:Int)
		''notes: needed a copy for dv and sv when assigning, but not so with local vectors
		
		
		'coll.col_coords=coll_line.Multiply(coll.time).Subtract(coll.normal.Multiply(radii.x) )
		
		
		''register collision
		hits += 1
		If( hits>=MAX_HITS ) Return False
	
		'Local impact:Vector = coll_line.Multiply(coll.time)
		'impact.y *= y_scale
PrintVector coll.normal
		'coll.col_coords=coll.col_coords.Add(coll.normal.Multiply(radii.x) )
		coll.col_coords.y *= y_scale
		
		Local coll_plane:Plane = New Plane( coll.col_coords,coll.normal )
		coll_plane.d -= COLLISION_EPSILON
		coll.time=coll_plane.T_Intersect( coll_line )
		
		
		
Dprint "coll_time "+coll.time
		If( coll.time>0.0 ) '' && fabs(coll.normal.dot( coll_line.d ))>EPSILON ){
			''update source position - ONLY If AHEAD!
			sv=coll.col_coords.Copy() 'coll_line.Multiply(coll.time) 'impact
			'sv = coll_line.Multiply(coll.time)
			td *=1.0-coll.time
			td_xz *=1.0-coll.time
		Endif
	
		If( response=COLLISION_RESPONSE_STOP )
			dv=sv.Copy()
			Return False 
		Endif
		

		''find nearest point on plane To dest
		Local nv:Vector =coll_plane.Nearest( dv )
	
		If( n_hit=0 )
			dv=nv
		Elseif( n_hit=1 )
			If( planes[0].Distance(nv)>=0 )
				dv=nv
				n_hit=0
			Elseif( Abs( planes[0].n.Dot( coll_plane.n ) )< 1.0-EPSILON )
				dv=coll_plane.Intersect( planes[0] ).Nearest( dv )
			Else
				''SQUISHED!
				hits=MAX_HITS
				Return False
			Endif
		Elseif( planes[0].Distance(nv)>=0 And planes[1].Distance(nv)>=0 )
			dv=nv
			n_hit=0
		Else
			dv=sv.Copy()
			Return False
		Endif
	PrintVector sv
	PrintVector dv
		'Local dd:Vector = sv.Subtract(dv)
		Local dd:Vector = dv.Subtract(sv)
		
		''going behind initial direction? really necessary?
		If( dd.Dot( dir )<=0 )
			dv=sv.Copy()
			Return False
		Endif

		If( response = COLLISION_RESPONSE_SLIDE )
			
			Local d:Float=dd.Length()
			If( d<=EPSILON ) dv=sv.Copy(); Return False
			If( d>td ) dd = dd.Multiply(td/d)
Dprint d+" :: "+td			
		Elseif( response = COLLISION_RESPONSE_SLIDEXZ )
		
			Local vv:Vector=New Vector( dd.x,0,dd.z )
			Local d:Float = vv.Length()
			If( d<=EPSILON ) Then dv=sv.Copy(); Return False
			If( d>td_xz ) Then dd = dd.Multiply(td_xz/d) Else dd = New Vector(dd.x,0.0,dd.z)
Print d+" :: "+td_xz		
		Endif
	
		'coll_line.o=sv.Copy()
		'coll_line.d=dd
		dv=sv.Add(dd)
		n_hit += 1
		planes[n_hit]=coll_plane
		
		Return True
		
	End


	Method CollisionFinal:Bool(coll:CollisionObject, response:Int)
	
		If (response = COLLISION_RESPONSE_NONE) Then Return False

		If( hits )
			If( hits<MAX_HITS )
				dv.y *= inv_y_scale
				coll.col_pos=dv.Copy()
			Else
				coll.col_pos=panic.Copy()
			Endif
			Return True
		Endif
		
		Return False
		
	End
	

	' perform quick check to see whether it is possible that ent and ent 2 are intersecting
	Function QuickCheck:Bool(ent:TEntity,ent2:TEntity)
	
		' check to see if src ent has moved since last update - if not, no intersection
		If ent.old_x=ent.EntityX(True) And ent.old_y=ent.EntityY(True) And ent.old_z=ent.EntityZ(True)
			Return False
		Endif
	
		Return True
	
	End 
End





Class CollisionObject
	
	Const ONETHIRD:Float = 1.0/3.0
	
	''collision methods
	Const COLLISION_METHOD_SPHERE:Int=1
	Const COLLISION_METHOD_POLYGON:Int=2
	Const COLLISION_METHOD_BOX:Int=3

	''collision actions
	Const COLLISION_RESPONSE_NONE:Int=0
	Const COLLISION_RESPONSE_STOP:Int=1
	Const COLLISION_RESPONSE_SLIDE:Int=2
	Const COLLISION_RESPONSE_SLIDEXZ:Int=3
	
	Field time:Float = 1.0
	Field normal:Vector = New Vector()
	Field surface:Int=0
	Field index:Int=0
	
		
	Field coll_u:Float ''uv coords, only polygon coll
	Field coll_v:Float
	
	Global tform:TransformMat
	
	Global col_coords:Vector
	Global col_normal:Vector
	Global col_time:Int
	Global col_surface:Int
	Global col_index:Int
	Global col_pos:Vector
	
	Global test2x:Float, test2y:Float, test2z:Float
	
	Method Update:Int( line:Line,t:Float, n:Vector, u#=0.0, v#=0.0 )
		
		''	If( t<0 || t>time ) Return False
		If( t>time ) Return 0
		
		Local p:Plane = New Plane(line.Multiply(t),n)
	
		If( p.n.Dot( line.d )>= 0.0 ) Return 0

		If( p.Distance(line.o)< -COLLISION_EPSILON ) Return 0
	
		time=t
		normal=n
		coll_u = u
		coll_v = v
		
		Return 1
		
	End

	Method SphereCollide:Int ( line:Line,radius:Float,dest:Vector,dest_radius:Float )

		radius += dest_radius
		Local l:Line = New Line( line.o.Subtract(dest) ,line.d )

		Local a:Float=l.d.Dot(l.d)
		If Not a Then Return 0
		
		Local b:Float=l.o.Dot(l.d)*2.0
		Local c:Float=l.o.Dot(l.o)-radius*radius
		Local d:Float=b*b-4.0*a*c
		

		If( d<0 ) Return 0
		
		Local sd:Float = Sqrt(d)
		'Local q:Float
		'If b<0 Then q = (-b-sd) * 0.5 Else q = (-b+sd)*0.5
		Local inva:Float = 1.0/a
		
		Local t1:Float=(-b+sd)*0.5*inva '(-b+sd)/(2.0*a) 'q/a 
		Local t2:Float=(-b-sd)*0.5*inva '(-b-sd)/(2.0*a) 'c/q 
	
		Local t:Float
		If t1<t2 Then t=t1 Else t=t2

		If( t>time ) Return 0

		Return Update( line,t,(l.Multiply(t).Normalize()) )
	
	End

	''v0,v1 = edge verts
	''pn = poly normal
	''en = edge normal
	Function EdgeTest:Int ( v0:Vector,v1:Vector,pn:Vector,en:Vector,line:Line,radius:Float, curr_coll:CollisionObject )
		
		''this first part may be wrong, depends on vector->matrix (columns or rows?) The easy fix is to not use transpose
		Local tm:Matrix = New Matrix( en, v1.Subtract(v0).Normalize(), pn)
		tm.Transpose()
		'Matrix tm=~Matrix( en,(v1-v0).normalized(),pn ); ''a transposed matrix
		
		Local sv:Vector = tm.Multiply(line.o.Subtract(v0))
		Local dv:Vector = tm.Multiply(line.o.Add(line.d.Subtract(v0))) 
		Local l:Line = New Line( sv,dv.Subtract(sv) )
		
		''do cylinder test...
		Local a#,b#,c#,d#,t1#,t2#,t#
		a=(l.d.x*l.d.x+l.d.z*l.d.z)
		If( Not a ) Return False					''ray parallel To cylinder
		b=(l.o.x*l.d.x+l.o.z*l.d.z)*2.0
		c=(l.o.x*l.o.x+l.o.z*l.o.z)-radius*radius
		d=b*b-4.0*a*c
		If( d<0 ) Return False					''ray misses cylinder
		t1=(-b+Sqrt(d))/(2.0*a)
		t2=(-b-Sqrt(d))/(2.0*a)
		If t1<t2 Then t=t1 Else t=t2 
		If( t>curr_coll.time ) Return False	''intersects too far away
		
		Local i:Vector = l.Multiply(t)
		Local p:Vector = New Vector(0.0,0.0,0.0) 
		If( i.y>v0.Distance(v1) ) Return False	''intersection above cylinder
		If( i.y>=0 )
			p.y=i.y
		Else
			''below bottom of cylinder...do sphere test...
			a=l.d.Dot(l.d)
			If( Not a ) Return False				''ray parallel To sphere
			b=l.o.Dot(l.d)*2.0
			c=l.o.Dot(l.o)-radius*radius
			d=b*b-4.0*a*c
			If( d<0 ) Return False				''ray misses sphere
			t1=(-b+Sqrt(d))/(2.0*a)
			t2=(-b-Sqrt(d))/(2.0*a)
			If t1<t2 Then t=t1 Else t=t2
			If( t>curr_coll.time ) Return False
			i=l.Multiply(t)
		Endif
		
		tm.Transpose()
		i = tm.Multiply(i.Subtract(p))
		
		Return curr_coll.Update( line,t,i.Normalize() )
	End


	Method TriangleCollide:Int ( line:Line, radius:Float, v0:Vector, v1:Vector, v2:Vector )

		''triangle plane
		Local p:Plane = New Plane( v0,v1,v2 )
		If( p.n.Dot( line.d )>=0 ) Return False
	
		''move plane out
		p.d -= radius

		Local t:Float=p.T_Intersect( line )
		If( t>time ) Return False

		''edge planes
		Local p0:Plane = New Plane( v0.Add(p.n),v1,v0 )
		Local p1:Plane = New Plane( v1.Add(p.n),v2,v1 )
		Local p2:Plane = New Plane( v2.Add(p.n),v0,v2 )
	
		''intersects triangle?
		Local i:Vector =line.Multiply(t)

		If( p0.Distance(i)>=0 And p1.Distance(i)>=0 And p2.Distance(i)>=0 )
			time = t
			normal = p.n
			Return Update( line,t,p.n )
		Endif
	
		If( radius<=0 ) Return False
	
		If EdgeTest( v0,v1,p.n,p0.n,line,radius,Self ) Then Return True
		If EdgeTest( v1,v2,p.n,p1.n,line,radius,Self ) Then Return True
		If EdgeTest( v2,v0,p.n,p2.n,line,radius,Self ) Then Return True
		Return False
		
	End



	Method BoxCollide:Int( line:Line, radius:Float, box:Box )

		Local quads:Int[]=[
			2,3,1,0,
			3,7,5,1,
			7,6,4,5,
			6,2,0,4,
			6,7,3,2,
			0,1,5,4 ]
	
		Local hit:Int=False
		Local p0:Plane, p1:Plane, p2:Plane, p3:Plane
		
		For Local n:Int =0 To 23 Step 4  ''6 planes

			Local v0:Vector = box.Corner( quads[n] )
			Local v1:Vector = box.Corner( quads[n+1] )
			Local v2:Vector = box.Corner( quads[n+2] )
			Local v3:Vector = box.Corner( quads[n+3] )
	
			''quad plane
			Local p:Plane = New Plane( v0,v1,v2 )
			If( p.n.Dot( line.d )>=0 ) Then Continue
			
			''move plane out
			p.d -= radius
			Local t:Float =p.T_Intersect( line )
			If( t>time ) Return False
	
			''edge planes
			p0=New Plane( v0.Add(p.n),v1,v0 )
			p1=New Plane( v1.Add(p.n),v2,v1 )
			p2=New Plane( v2.Add(p.n),v3,v2 )
			p3=New Plane( v3.Add(p.n),v0,v3 )
	
			''intersects triangle?
			Local i:Vector =line.Multiply(t)
			If( p0.Distance(i)>=0 And p1.Distance(i)>=0 And p2.Distance(i)>=0 And p3.Distance(i)>=0 )
				hit = hit | Update( line,t,p.n )
				Continue
			Endif
	
			If( radius<=0 ) Continue
	
			hit = hit|
			EdgeTest( v0,v1,p.n,p0.n,line,radius,Self )|
			EdgeTest( v1,v2,p.n,p1.n,line,radius,Self )|
			EdgeTest( v2,v3,p.n,p2.n,line,radius,Self )|
			EdgeTest( v3,v0,p.n,p3.n,line,radius,Self )
		Next
		
		Return hit
	End
	
	
	Method RayTriangle:Int(li:Line, radius:Float, v0:Vector, v1:Vector, v2:Vector)
	
		Local u:Vector, v:Vector, n:Vector             '' triangle vectors
		Local dst:Vector, w0:Vector, w:Vector          '' ray vectors
		Local r#, a#, b#             '' params To calc ray-plane intersect
		Local ru#=  0.0, rv#=0.0
		
		'' get triangle edge vectors And plane normal
		u = v1.Subtract(v0)
		v = v2.Subtract(v0)
		n = u.Cross(v)'.Normalize         '' cross product
		If (n.x=0 And n.y=0 And n.z=0) Then Return 0           

		a = li.o.Subtract(v0).Dot(n) 
		b = -li.d.Dot(n) '' dest vector
	
		If radius
			''returns r along li.d
			r = SpherePlaneTest(li.o, li.o.Add(li.d), radius, v0, n ) 'vec 0 = v0???
			'r = SpherePlaneTest(li.o, li.o.Add(li.d), radius, New Vector(0.0,0.0,0.0), n )
			
			If r<0.0 Then Return 0
			
		Else

			If (b < 0.00001 )'And b>-0.00001)     '' ray is parallel To triangle plane or points away from ray
			    If (a = 0.0) Then Return 1 '(return li.o) ''ray lies in triangle plane
			    Return 0             '' ray disjoint from plane
			Endif
			
			'' get intersect point of ray with triangle plane
			r = a/b
			'If (r < 0.0) Then Return 0     '' ray goes away from triangle (negative b test)
			If (r > 1.0) Then Return 0'' For a segment, also test If (r > 1.0) then no intersect
		
		Endif
		
		''exit early for distant triangle
		If r > time Then Return 0
	
Print "* "+(u.Cross(v).y)	
		'*I = R.P0 + r * dir           '' intersect point of ray And plane
		Local i:Vector = li.o.Add( New Vector(li.d.x*r, li.d.y*r, li.d.z*r) )
	
		'' is I inside T?
		Local uu#, uv#, vv#, wu#, wv#, D#
		uu = u.Dot(u)
		uv = u.Dot(v)
		vv = v.Dot(v)
		w = i.Subtract(v0)
		wu = w.Dot(u)
		wv = w.Dot(v)
		D = uv * uv - uu * vv
		
		'' get And test parametric coords ''added in radius adjustment for s/t test
		Local s#, t#
		s = (uv * wv - vv * wu) / D
		If (s < (0.0-radius) Or s > (1.0+radius)) Then Return 0       '' I is outside T
		'If (s < (0.0) Or s > (1.0)) Then Return 0       '' I is outside T
		
		t = (uv * wu - uu * wv) / D
		'' does s+t need to be Abs(s)?
		If (t < (0.0-radius) Or (s + t) > (1.0+radius+radius) ) Then Return 0 '' I is outside T

		
		'normal = n.Normalize()
		'time = r
		'coll_u = s
		'coll_v = t
	
		Return Update( li, r, n.Normalize(),s ,t )
		                 
	End
	
	
	Method RaySphereTest:Int(ray:Vector, center:Vector, radius:Float)
		'' -- ray must be normalized
		'' -- center is relative to ray origin
		
		'Local l:Float = ray.Dot(center)
		Local l:Float = (ray.x*center.x + ray.y*center.y + ray.z*center.z)
		'Local c:Float = center.Dot(center)
		Local r:Float= l*l - (center.x*center.x + center.y*center.y + center.z*center.z) + radius*radius
			
		Return 1-(r<0)
	
	End
	
	Method SpherePlaneTest:Float(c0:Vector, c1:Vector, radius:Float, v0:Vector, norm:Vector)
		'' -- needs plane normal, triangle center
		'' c0 = non-normalized origin, c1 = destination
		
		''get plane sphere equations
		Local d0:Float = norm.Dot(c0.Subtract(v0)) '+ pd
		Local d1:Float = norm.Dot(c1.Subtract(v0)) '+ pd
		'Print "d0 "+(d0)+" "+(d1)+" r:"+radius+" " '+pd			
		
		If (d0 > 0.0 And d0 < radius) Then Return 0.0 ''original hitting the position
		If (d1 > radius) Then Return -1.0 ''too far from plane
		If d1=0.0 Then Return 1.0 'hit center
		If d0=d1 Then Return -1.0 ''does not move
			
		Local t:Float = (d0 - radius)/(d0-d1)
		
		'Local cx:Vector = c0.Multiply(1.0-t).Add( c1.Multiply(t) )''center on plane
		
		Return t
		
	End

End

''debugging
Function PrintVector(v:Vector)
	Print v.x+" "+v.y+" "+v.z
End

