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
	
		If LOG_NEW
			DebugLog "New TCollisionPair"
		Endif
	
	End 
	
	Method Delete()
	
		If LOG_DEL
			DebugLog "Del TCollisionPair"
		Endif
	
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
	
		If LOG_NEW
			DebugLog "New TCollisionImpact"
		Endif
	
	End 
	
	Method Delete()
	
		If LOG_DEL
			DebugLog "Del TCollisionImpact"
		Endif
	
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

	Field y_tform:TransformMat = New TransformMat
	
	Field radius:Float, inv_y_scale:Float
	Field y_scale:Float

	Field n_hit:Int
	Field planes:Plane[3]

	Field coll_line:Line
	Field dir:Vector
	
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
	
	Global tform:TransformMat=New TransformMat(t_mat,vec_v)
	
	Global testx:Float, testy:Float, testz:Float
	Global testx2:Float, testy2:Float, testz2:Float
	
	
	
	Method New(dv2:Vector,sv2:Vector,radii2:Vector)
	
		dv = dv2.Copy()
		sv = sv2.Copy()
		panic = sv.Copy()
		radii = radii2.Copy()
		radius = radii.x
		
		planes[0] = New Plane(New Vector(0.0,0.0,0.0),0); planes[1] = New Plane(New Vector(0.0,0.0,0.0),0); planes[2] = New Plane(New Vector(0.0,0.0,0.0),0)
		
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
	
		coll_line=New Line( sv,dv.Subtract(sv) )
		
		dir=coll_line.d
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
	
	''
	''
	''
	
	Method Pick:Int(line:Line,radius2:Float,coll:CollisionObject,dst_tform:TransformMat,mesh_col:MeshCollider,pick_geom:Int=0)

		Local hit:Int=0
	
		If( HitTest(line,radius2,dst_tform,mesh_col,pick_geom,coll,Self ) )
			
			hit=True	
			
		Endif
	
		Return hit
	End
	

	Method CollisionDetect:Int(coll:CollisionObject,dst_tform:TransformMat,mesh_col:MeshCollider,methd:Int)
	
		Local hit:Int=0

		If( y_scale=1.0 )
			If( HitTest(Self.coll_line,radius,dst_tform,mesh_col, methd,coll,Self ) )
			
				hit=True
	
			Endif	
		Elseif( HitTest(Self.coll_line,radius,Self.y_tform.Multiply(dst_tform),mesh_col,methd,coll,Self ) )
			
				hit=True
							
		Endif
		
		Return hit
		
	End
	
	'Bool hitTest( Const Line &line,Float radius,Const Transform &tf,MeshCollider* mesh_col,Int Method,Collision* curr_coll,CollisionInfo &ci  ){
	Function HitTest:Int( line:Line, radius2:Float, tf:TransformMat, mesh_col:MeshCollider, methd:Int, coll:CollisionObject, ci:CollisionInfo  )
		
		Local res:Int  =0
		
		Select ( methd )
	
			Case COLLISION_METHOD_SPHERE
			
				res = coll.SphereCollide( line,radius2,tf.v,ci.dst_radius )
		
			Case COLLISION_METHOD_POLYGON

				res = mesh_col.Collide( line,radius2,tf,coll )
		
			Case COLLISION_METHOD_BOX
				Local t:TransformMat =tf.Copy()
				t.NormalizeMatrix3x3()
				
				Local a:Vector = New Vector(ci.ax,ci.ay,ci.az)
				Local b:Vector = New Vector(ci.bx,ci.by,ci.bz)
				Local box:Box= New Box(a,b)
				
				Local l:Line = t.Transpose().Multiply(line)
			
				If( coll.BoxCollide( l ,radius2,box ) ) ''BoxCollide( ~t*line,radius,box )
					coll.normal=t.m.Multiply(coll.normal)
					res = True
				Endif
	
		End
		
		If res
			coll.col_normal=coll.normal
			coll.col_time=coll.time
			coll.col_surface=coll.surface
			coll.col_index=coll.index	
				
			coll.col_coords=ci.coll_line.Multiply(coll.time).Subtract(coll.normal.Multiply(radius2))
			

		Endif
		
		Return res
	End
	
	
	
	Method CollisionResponse:Int(coll:CollisionObject,response:Int)
		''notes: needed a copy for dv and sv when assigning, but not so with local vectors
		
		
		'coll.col_coords=coll_line.Multiply(coll.time).Subtract(coll.normal.Multiply(radii.x) )
		coll.col_coords.y *= y_scale
		
		''register collision
		hits += 1
		If( hits>=MAX_HITS ) Return False
	
		Local coll_plane:Plane = New Plane( coll_line.Multiply(coll.time),coll.normal )
	
		coll_plane.d -= COLLISION_EPSILON
		coll.time=coll_plane.T_Intersect( coll_line )
	
		If( coll.time>0 ) '' && fabs(coll.normal.dot( coll_line.d ))>EPSILON ){
			''update source position - ONLY If AHEAD!
			sv=coll_line.Multiply(coll.time)
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
				''Exit(0);
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
		Elseif( response = COLLISION_RESPONSE_SLIDEXZ )
			Local vv:Vector=New Vector( dd.x,0,dd.z )
			Local d:Float = vv.Length()
			If( d<=EPSILON ) Then dv=sv.Copy(); Return False
			If( d>td_xz ) Then dd = dd.Multiply(td_xz/d) Else dd = New Vector(dd.x,0.0,dd.z)
		Endif
	
		coll_line.o=sv.Copy()
		coll_line.d=dd
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
						
				vec_a.Update(ent.EntityX(True),ent.EntityY(True),ent.EntityZ(True))
				vec_b.Update(ent.old_x,ent.old_y,ent.old_z)
				vec_c.Update(ent.radius_x,ent.radius_y,ent.radius_x)
	
				''make collision line
				Local col_info:CollisionInfo =New CollisionInfo(vec_a,vec_b,vec_c)	
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
			
								vec_i.Update(ent2.mat.grid[0][0],ent2.mat.grid[1][0],-ent2.mat.grid[2][0])
								vec_j.Update(ent2.mat.grid[0][1],ent2.mat.grid[1][1],-ent2.mat.grid[2][1])
								vec_k.Update(-ent2.mat.grid[0][2],-ent2.mat.grid[1][2],ent2.mat.grid[2][2])
								t_mat.Update(vec_i,vec_j,vec_k)
								
								'mat = ent.mat.Inverse()
								vec_v.Update(ent2.mat.grid[3][0],ent2.mat.grid[3][1],-ent2.mat.grid[3][2])
								tform.Update(t_mat, vec_v)
			
								' if pick mode is sphere or box then update collision info object to include entity radius/box info
								If col_pair.col_method<>COLLISION_METHOD_POLYGON
									col_info.Update(ent2.radius_x,ent2.box_x,ent2.box_y,ent2.box_z,ent2.box_x+ent2.box_w,ent2.box_y+ent2.box_h,ent2.box_z+ent2.box_d)
								Endif
					
					
								Local mesh_col:MeshCollider=Null
								Local mesh:TMesh = TMesh(ent2)
								If mesh<>Null	
									mesh_col = mesh.col_tree.CreateMeshTree(mesh) ' create collision tree for mesh if necessary
								Endif
			
			
								hit = col_info.CollisionDetect(coll_obj, tform, mesh_col, col_pair.col_method)
								
			
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
							ent.collision[i].surf=coll_obj.surface 
						Else
							ent.collision[i].surf=0
						Endif
						
						ent.collision[i].tri=coll_obj.index 
	
							
						If col_info.CollisionResponse(coll_obj, response)=False Then Exit
						
					Else
					
						Exit
									
					Endif
										
				Forever
	
	
				Local hits:Int =col_info.CollisionFinal(coll_obj, response)
				
				If hits
					
					Local x#=CollisionObject.col_pos.x
					Local y#=CollisionObject.col_pos.y
					Local z#=CollisionObject.col_pos.z
								
					ent.PositionEntity(x,y,z,True)
					
				Endif
		
				col_info = Null
				coll_obj = Null
	
				ent.old_x=ent.EntityX(True)
				ent.old_y=ent.EntityY(True)
				ent.old_z=ent.EntityZ(True)
	
			Next
											
		Next
	
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
	
	Global col_coords:Vector
	Global col_normal:Vector
	Global col_time:Int
	Global col_surface:Int
	Global col_index:Int
	Global col_pos:Vector
	
	Method Update:Int( line:Line,t:Float, n:Vector )
		
		''	If( t<0 || t>time ) Return False
		If( t>time ) Return 0
		
		Local p:Plane = New Plane(line.Multiply(t),n)
		
		If( p.n.Dot( line.d )>= 0 ) Return 0

		If( p.Distance(line.o)< -COLLISION_EPSILON ) Return 0
	
		time=t
		normal=n
		
		Return 1
		
	End

	Method SphereCollide:Int ( line:Line,radius:Float,dest:Vector,dest_radius:Float )

		radius += dest_radius
		Local l:Line = New Line( line.o.Subtract(dest) ,line.d )

	
		Local a:Float=l.d.Dot(l.d)
		If Not a Return 0
		
		Local b:Float=l.o.Dot(l.d)*2.0
		Local c:Float=l.o.Dot(l.o)-radius*radius
		Local d:Float=b*b-4.0*a*c
		

		If( d<0 ) Return 0
		
		Local sd:Float = Sqrt(d)
		Local q:Float
		If b<0 Then q = (-b-sd) * 0.5 Else q = (-b+sd)*0.5
		
		Local t1:Float=(-b+sd)/(2.0*a) 'q/a 
		Local t2:Float=(-b-sd)/(2.0*a) 'c/q 
	
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
		'Matrix tm=~Matrix( en,(v1-v0).normalized(),pn ); ''yikes a transposed matrix
		
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
		
		For Local n:Int =0 To 23 Step 4  

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

End



