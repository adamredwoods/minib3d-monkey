Import minib3d
Import minib3d.math.vector
Import minib3d.math.geom
Import minib3d.math.matrix

'' will need to port over a collision library specifically for monkey xplatform

Const MAX_TYPES=100

'collision methods
Const COLLISION_METHOD_SPHERE:Int=1
Const COLLISION_METHOD_POLYGON:Int=2
Const COLLISION_METHOD_BOX:Int=3
Const COLLISION_METHOD_AABB:Int=4

'collision actions
''-- damping (water)? -- sticking?
Const COLLISION_RESPONSE_NONE:Int=0
Const COLLISION_RESPONSE_STOP:Int=1
Const COLLISION_RESPONSE_SLIDE:Int=2
Const COLLISION_RESPONSE_SLIDEXZ:Int=3

Const COLLISION_EPSILON:Float=0.001



Class TCollision
	
	Field type:Int
	Field impact:TCollisionImpact[]
	
	''collision, pick
	Field radius_x#=1.0,radius_y#=1.0
	Field box_x#=-1.0,box_y#=-1.0,box_z#=-1.0,box_w#=2.0,box_h#=2.0,box_d#=2.0
	
	
	
	Method New()

	End 
	
	
	Method Copy:TCollision()
		Local cc:TCollision = New TCollision
		
		cc.type = type
		cc.radius_x = radius_x
		cc.radius_y = radius_y
		cc.box_x = box_x
		cc.box_y = box_y
		cc.box_z = box_z
		cc.box_w = box_w
		cc.box_h = box_h
		cc.box_d = box_d
		
		Return cc
	End

End 


Class TCollisionImpact

	Field x#,y#,z#
	Field nx#,ny#,nz#
	Field time#
	Field ent:TEntity
	Field surf:Int
	Field tri:Int
	
End


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









Class CollisionInfo

	Field dv:Vector = New Vector
	Field sv:Vector = New Vector
	Field radii:Vector = New Vector
	Field panic:Vector = New Vector

	Field mesh_coll:MeshCollider
	Field radius:Float, inv_y_scale:Float, y_scale:Float
	
	

	Field  n_hit:Int
	Field planes:Plane[] = [New Plane, New Plane, New Plane, New Plane]
	Field col_points:Vector[] = [New Vector, New Vector, New Vector, New Vector]
	
	Field coll_method:Int
	Field coll_line:Line = New Line()
	Field tf_line:Line = New Line()
	Field dir:Vector = New Vector
	Field tform:TransformMat=New TransformMat
	Field y_tform:TransformMat = New TransformMat
	'Field oform:TransformMat=New TransformMat ''original ent mat
	Field renew:Matrix = New Matrix
	Field renew2:Matrix = New Matrix
	Field renew3:Matrix = New Matrix
	Field tf_offset:Vector = New Vector
	Field inv_scale:Vector = New Vector
	
	''for triangle collisions
	Field tf_scale:Vector = New Vector
	Field tf_radius:Vector = New Vector ''scaled radius for sphere in local mesh space
	Field tf_box:Box = New Box()


	
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

	Global t_mat:Matrix
				
	Global vec_v:Vector = New Vector(0.0,0.0,0.0)
	
	
	Global test_vec:Vector = New Vector
	Global test_dot:Vector = New Vector
	Global testx:Float, testy:Float, testz:Float
	Global testx2:Float, testy2:Float, testz2:Float
	Global testline:Line = New Line()

	
	Global trigger:Int=0
	
	Method New()
	
		t_mat = New Matrix()
		tform = New TransformMat()
		
	End

	
	Method UpdateRay:Int(sv2:Vector,dv2:Vector,radii2:Vector)
		
		t_mat = New Matrix()
		tform = New TransformMat()
		
		dv.Overwrite(dv2)
		sv.Overwrite(sv2)
		panic.Overwrite(sv2)
		radii.Overwrite(radii2)
		radius = radii.x

		
		planes[0].Update(0.0,0.0,0.0,  0)
		planes[1].Update(0.0,0.0,0.0,  0)
		planes[2].Update(0.0,0.0,0.0,  0)
		planes[3].Update(0.0,0.0,0.0,  0)
		col_points[0].Update(0.0,0.0,0.0)
		col_points[1].Update(0.0,0.0,0.0)
		col_points[2].Update(0.0,0.0,0.0)
		col_points[3].Update(0.0,0.0,0.0)
		
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
	
		coll_line.Update( sv.x, sv.y, sv.z, dv.x-sv.x, dv.y-sv.y, dv.z-sv.z )
		
		dir.Update((coll_line.d.x),(coll_line.d.y),(coll_line.d.z))
		dir = dir.Normalize()
		td=coll_line.d.Length()
		
		tf_radius = tf_scale.Multiply(radius)
		tf_line.Update(coll_line.o.x,coll_line.o.y,coll_line.o.z, coll_line.d.x,coll_line.d.y,coll_line.d.z)
		

		td_xz = New Vector( coll_line.d.x,0,coll_line.d.z ).Length()
	
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
	
	Method UpdateShape (ent:TEntity)

		dst_radius =ent.collision.radius_x
		ax =ent.collision.box_x
		ay =ent.collision.box_y
		az =ent.collision.box_z
		bx =ent.collision.box_x+ent.collision.box_w
		by =ent.collision.box_y+ent.collision.box_h
		bz =ent.collision.box_z+ent.collision.box_d
		
	End
	
	
	
	
	Function UpdateCollisions()
	
		'DebugLog "Update Collisions"
	
		Local coll_obj:CollisionObject
		Local col_info:CollisionInfo= New CollisionInfo()
		
		' loop through collision setup list, containing pairs of src entities and des entities to be check for collisions
		For Local i:Int=0 Until MAX_TYPES
		
			' if no entities exist of src_type then do not check for collisions
			If TCollisionPair.ent_lists[i]=Null Then Continue

			
			' loop through src entities
			For Local ent:TEntity=Eachin TCollisionPair.ent_lists[i]
				
				ent.no_collisions=0
				
				' if src entity is hidden or it's parent is hidden then do not check for collision
				If ent.Hidden()=True Then Continue
						
				
				ent.collision.impact =New TCollisionImpact[0]		
				
				vec_a.Update(ent.mat.grid[3][0],ent.mat.grid[3][1],-ent.mat.grid[3][2]) ''line dest
				vec_b.Update(ent.old_x,ent.old_y,ent.old_z) ''line source
				vec_c.Update(ent.collision.radius_x,ent.collision.radius_y,ent.collision.radius_x)

				''make collision line
				col_info.UpdateRay(vec_b,vec_a,vec_c)	
				Local response:Int
				
				Repeat
	
					Local hit:Int =0
					Local ent2_hit:TEntity=Null
					coll_obj = New CollisionObject			

				
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
			

								col_info.CollisionSetup(ent2, col_pair.col_method, coll_obj)
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
						ent.collision.impact=ent.collision.impact.Resize(i+1)
									
						ent.collision.impact[i]=New TCollisionImpact
						ent.collision.impact[i].x=coll_obj.col_coords.x 
						ent.collision.impact[i].y=coll_obj.col_coords.y 
						ent.collision.impact[i].z=coll_obj.col_coords.z 
						ent.collision.impact[i].nx=coll_obj.normal.x
						ent.collision.impact[i].ny=coll_obj.normal.y 
						ent.collision.impact[i].nz=coll_obj.normal.z
						ent.collision.impact[i].ent=ent2_hit
						
						If TMesh(ent2_hit)<>Null
							ent.collision.impact[i].surf=coll_obj.surface '& $0000ffff
						Else
							ent.collision.impact[i].surf=0
						Endif
						
						''get the real tri index (byte packed in surface) --not anymore
						ent.collision.impact[i].tri=coll_obj.index '((coll_obj.surface & $ffff0000) Shr 16) 
	
						''exit on no hits
						If col_info.CollisionResponse(coll_obj, response)=False Then Exit
						
					Else
					
						Exit
									
					Endif
										
				Forever


				Local hits:Int =col_info.CollisionFinal(coll_obj, response)
				
				If hits
						
					ent.PositionEntity(coll_obj.col_pos.x,coll_obj.col_pos.y,coll_obj.col_pos.z,True) 
					
				Endif
		
	
				ent.old_x=ent.mat.grid[3][0]
				ent.old_y=ent.mat.grid[3][1]
				ent.old_z=-ent.mat.grid[3][2]
	
			Next
											
		Next
	
	End 

	
	''
	'' line is in world space. need to change line to local mesh space. watch out for parented global scale versus local scale
	''
	Method CollisionSetup(ent:TEntity, c_method:Int, coll_obj:CollisionObject)

'Print "setup----"+ent.classname
	
		coll_method = c_method


		''remove global scaling from matrix	

		Local ex:Float = 1.0/ent.gsx'*ent.gsx)
		Local ey:Float = 1.0/ent.gsy'*ent.gsy)
		Local ez:Float = 1.0/ent.gsz'*ent.gsz)
		inv_scale.Overwrite(ex,ey,ez)


		tform.m.grid[0] = [ent.mat.grid[0][0]*ex,ent.mat.grid[1][0]*ey,-ent.mat.grid[2][0]*ez,  0.0]
		tform.m.grid[1] = [ent.mat.grid[0][1]*ex,ent.mat.grid[1][1]*ey,-ent.mat.grid[2][1]*ez,  0.0]
		tform.m.grid[2] = [-ent.mat.grid[0][2]*ex,-ent.mat.grid[1][2]*ey,ent.mat.grid[2][2]*ez,  0.0]

		renew2 = tform.m.Inverse()
		

		If( y_scale<>1.0 )

			tform = y_tform.Multiply(tform)

		Endif
		

		' if pick mode is sphere or box then update collision info object to include entity radius/box info
		If coll_method=COLLISION_METHOD_BOX
			
			CollisionBoxSetup(ent, radius, coll_obj)
			
			
		Elseif If coll_method=COLLISION_METHOD_SPHERE
			
			CollisionSphereSetup(ent, radius, coll_obj)
			
			
		Elseif coll_method=COLLISION_METHOD_POLYGON
			
			
			CollisionTriangleSetup(ent, radius, coll_obj)
			
		Elseif coll_method=COLLISION_METHOD_AABB
			
			
			CollisionAABBSetup(ent, radius, coll_obj)
			
				
		Endif
		
	End
	
	
	Method CollisionSphereSetup(ent:TEntity, radius:Float, coll_obj:CollisionObject)
		
		tf_offset = New Vector(ent.mat.grid[3][0],ent.mat.grid[3][1],-ent.mat.grid[3][2] )
		
		UpdateShape(ent)
		coll_obj.time = 1.0
		
	End
	
	Method CollisionBoxSetup(ent:TEntity, radius:Float, coll_obj:CollisionObject)
		
		tf_offset.Overwrite(-ent.mat.grid[3][0],-ent.mat.grid[3][1],ent.mat.grid[3][2] )
		tf_line = tform.m.Multiply(coll_line.Add(tf_offset) )
		tf_scale.Overwrite(ent.gsx, ent.gsy, ent.gsz)
		
		UpdateShape(ent)
		
		coll_obj.time = tf_line.d.Add(tf_radius).DistanceSquared()+radius
	
	End
	
	Method CollisionAABBSetup(ent:TEntity, radius:Float, coll_obj:CollisionObject)
		
		tf_line = New Line(coll_line.o,coll_line.d)
		UpdateShape(ent)
		
		coll_obj.time = tf_line.d.Add(tf_radius).DistanceSquared()+radius
	
	End
	
	Method CollisionTriangleSetup(ent:TEntity, radius:Float, coll_obj:CollisionObject)
	
		tf_offset.Overwrite(-ent.mat.grid[3][0],-ent.mat.grid[3][1],ent.mat.grid[3][2] )
		tf_line = tform.m.Multiply(coll_line.Add(tf_offset) )

		'tf_scale.Overwrite(1.0/ent.gsx, 1.0/ent.gsy, 1.0/ent.gsz)
		tf_scale.Overwrite(ent.gsx, ent.gsy, ent.gsz)
		tf_radius.Overwrite(radius, radius, radius)
		
		
		Local mesh:TMesh = TMesh(ent)
		If mesh<>Null	
			mesh_coll = mesh.col_tree.CreateMeshTree(mesh) ' create collision tree for mesh if necessary
		Endif

		
		
		'tf_scale = tform.m.Multiply(tf_scale)
		mesh_coll.tf_scale = tf_scale
		
		'Local radoffset:Vector = tf_line.d.Normalize().Multiply(radius+0.001) ''MUST HAVE r+r??


		tf_box.Update(tf_line.o)
		tf_box.Update(tf_line.d)'.Add(radoffset))
		tf_box.Expand(radius) 'tf_radius)
		'Local ex# = 1.0/ent.gsx
		'Local ey# = 1.0/ent.gsy
		'Local ez# = 1.0/ent.gsz
		tf_box.a.Multiply(inv_scale); tf_box.b.Multiply(inv_scale)
		
		If radius = 0.0
		
			''setup ray for pick
			tf_radius.x = 0.0
			mesh_coll.RayBoxSetup( New Line( tf_line.o.Multiply(inv_scale) , tf_line.d.Multiply(inv_scale)) ) ''may need new line with radoffset		
			
		Endif
		
		coll_obj.time = tf_line.d.Add(tf_radius).DistanceSquared()+radius ''dist squ
		If radius = 0.0 Then coll_obj.time = 1.0 ''raytriangle
	End



	Method CollisionDetect:Int(coll_obj:CollisionObject)
		
		Local res:Int=0
		

		Select ( coll_method )
	
			Case COLLISION_METHOD_SPHERE
				
				res = coll_obj.SphereCollide( coll_line,radius,tf_offset,dst_radius )
				
				If res
					coll_obj.col_coords=coll_line.Multiply(coll_obj.time)
				
					RegisterHitPlane ( coll_obj.col_coords, coll_obj.normal)
					
				Endif
				radius = 0.0
				
				
			Case COLLISION_METHOD_POLYGON

				
				If mesh_coll.CollideAABB( tf_box, tf_radius, coll_obj, mesh_coll.tree )
					
					res = mesh_coll.TriNodeCollide( tf_box, tf_line, tf_radius, coll_obj, tf_scale )
					
					''adjust normal to original ent. matrix
					If res 'And coll_obj.time < 99999.0

						coll_obj.normal = renew2.Multiply(coll_obj.normal).Normalize()
						
						''convert col_coords back to world space
						coll_obj.col_coords = renew2.Multiply(coll_obj.col_coords ).Subtract(tf_offset)
					
						RegisterHitPlane ( coll_obj.col_coords, coll_obj.normal)
						
					Endif
				Endif
	
	
				
			Case COLLISION_METHOD_BOX

				Local box:Box= New Box(New Vector(ax,ay,az), New Vector(bx,by,bz))
	
				
				If( coll_obj.SphereBox( tf_line, radius, box, tf_scale ) ) ''BoxCollide( ~t*line,radius,box )
				
					coll_obj.normal=renew2.Multiply(coll_obj.normal) '.Normalize()
					'coll_obj.normal=coll_obj.normal
					res = True
					
					'coll_obj.col_coords=coll_line.Multiply(coll_obj.time)'.Subtract(tf_offset)
					coll_obj.col_coords = renew2.Multiply(coll_obj.col_coords ).Subtract(tf_offset)
					
					RegisterHitPlane ( coll_obj.col_coords, coll_obj.normal)
			
				Endif

				'radius = 0.0
			
			
			'' *** TO DO ***
			Case COLLISION_METHOD_AABB
			
				Local box_target:Box= New Box(New Vector(ax,ay,az), New Vector(bx,by,bz))
				'Local box:Box= New Box(New Vector(-radius,-radius,-radius), New Vector(radius,radius,radius))
				
				Local line_box:Box = New Box(tf_line)
				line_box.Expand(radius+radius)

				res= coll_obj.AABBCollide(tf_line, line_box, box_target)

				If res
					'coll_obj.normal= 
					'coll_obj.col_coords=coll_line.Multiply(coll_obj.time)
				
					RegisterHitPlane ( coll_obj.col_coords, coll_obj.normal)
					
				Endif
				radius = 0.0
		End
		
'If res
'CollisionInfo.test_vec = coll_obj.col_coords.Copy()
'CreateTestLine(coll_obj.col_coords, coll_obj.col_coords.Add(coll_obj.normal.Multiply(1.0)), 100,0,100 )
'Endif
		
		Return res
	End
	
	
	'' Physics
	
	Method RegisterHitPlane(coords:Vector, norm:Vector)
		
		hits +=1
		If hits>3 Or hits<1 Then Return
		
		n_hit = hits-1
		planes[n_hit] = New Plane( coords, norm)
		col_points[n_hit] = coords.Copy()
		
	End
	
	
	
	Method CollisionResponse:Int(coll:CollisionObject,response:Int)
		''notes: needed a copy for dv and sv when assigning, but not so with local vectors
		
		'' let's not worry about time here, and work only with collision point


		If( hits>=MAX_HITS  ) Return False

	
		Local new_coords:Vector

		''create correct normal response
		If ( response = COLLISION_RESPONSE_SLIDEXZ )
			coll.normal.y = 0.0'-coll_line.o.y
			coll.normal = coll.normal.Normalize()
		Endif
		
		new_coords=coll.col_coords.Add(coll.normal.Multiply(radius))
		'new_coords = coll.col_coords.Copy() 'coll_line.o.Add(coll_line.d.Multiply(coll.time))
		
		
		new_coords.y *= y_scale
		'coll.col_coords=new_coords
		
		Local coll_plane:Plane = New Plane( new_coords,coll.normal )	
		coll_plane.d -= COLLISION_EPSILON

		
'Print "coll_time "+coll.time+"  res:"+response+" colnorm:"+coll.normal.ToString+" rad:"+radius

		
		sv.Overwrite(new_coords)
	
		If ( response=COLLISION_RESPONSE_STOP )
			dv.Overwrite(sv)
			Return False 
		Endif
		


		''find nearest point on plane To dest
		Local nv:Vector =coll_plane.Nearest( dv )

'CreateTestLine(new_coords, nv, 200,255,200 )


		'' multiple plane hits
		
		If( n_hit>0 )
			
			If( n_hit=1 )
	'Print ""
	'Print ""
'Print ":: n_hit "+n_hit+"  "+planes[0].Distance(nv)+"  "+Abs( planes[0].n.Dot( coll_plane.n ))
				
				Local plane_norms# = planes[0].n.Dot( coll_plane.n )
				
				If( planes[0].Distance(nv)> radius )
					n_hit=0
					
				Elseif plane_norms < -0.999
					''SQUISHED! planes are parallel
					hits=MAX_HITS
					dv.Overwrite(sv)
					Return False
					
				Elseif( Abs( plane_norms  ) < 1.0-EPSILON )
					nv=coll_plane.Intersect( planes[0] ).Nearest( dv )
'Print ":: n_hit1 "+nv	
'CreateTestLine(nv, nv.Add(pn.Multiply(1.0)), 0,100,0 )

				Endif
			Else
				If( planes[0].Distance(nv)> radius And planes[1].Distance(nv)> radius )
'Print ":: n_hit2 "+n_hit
					'dv=nv
					n_hit=0
				Else
					dv.Overwrite(sv)
					Return False
				Endif
			Endif


			n_hit =0
			
'test_dot.Overwrite(nv)
'Print " cv "+cv.ToString()	
'CreateTestLine(cv, cv.Add(nn), 200,0,200 )
	
	
	Endif

'CollisionInfo.trigger+=1


		Local dd:Vector = nv.Subtract(sv)

'Print "dd "+dd.ToString+"   sv "+sv.ToString+"  nv "+nv.ToString

		''going behind initial direction? really necessary?
		'If( dd.Dot( dir )<=0 )
			'Print "***** behind"
			'dv.Overwrite(sv)
			'Return False
		'Endif
		
		'' -- apparently, NV gives a correct response
		Local d:Float=dd.Dot(dd)
		If  d< EPSILON Then dv.Overwrite(sv); Return False
		
		If( response = COLLISION_RESPONSE_SLIDE )
	
		Elseif( response = COLLISION_RESPONSE_SLIDEXZ )

			nv.Overwrite( nv.x, coll_line.o.y, nv.z)
	
		Endif
	
		'' since we are going back to test more collisions, need to update the coll_line
		dv=nv
		coll_line.o.Overwrite(sv)
		coll_line.d.Overwrite(dv.Subtract(sv))'dd) '' length, from o
		
'Print "final dv :"+dv.ToString() '+"   dd:"+dd.ToString()
		
	
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
	
	Global BOXQUADS:Int[]=[
			2,3,1,0,
			3,7,5,1,
			7,6,4,5,
			6,2,0,4,
			6,7,3,2,
			0,1,5,4 ]
	
	Field time:Float = 2.0
	Field normal:Vector = New Vector()
	Field surface:Int=0
	Field index:Int=0
	
		
	Field coll_u:Float ''uv coords, only polygon coll
	Field coll_v:Float
	
	Field rad2:Float



	Field tform:TransformMat
	
	Field col_coords:Vector = New Vector()
	Field col_normal:Vector = New Vector()
	Field col_time:Int
	Field col_surface:Int
	Field col_index:Int
	Field col_pos:Vector = New Vector()
	
	Global test2:Vector = New Vector()
	Global test3:Vector = New Vector()
	Global renew:Matrix
	Global scale2:Vector = New Vector()
	Global tf_offset:Vector = New Vector()
	Global trip:Int=0
	
Private
	
	Field int_vec:Vector = New Vector() ''temp intersection vec

Public
	
	
	
	Method Update:Int( line:Line,t:Float, n:Vector, u#=0.0, v#=0.0, intersect:Vector=Null )
	
		''	If( t<0 || t>time ) Return False ''--need to keep negative time
		
		If( t>time ) Return 0 ''need the closest intersection
		
		Local p:Plane
		
		
		If intersect
			
			'' define col_coords here, to manage triangle-plane collisions properly
			'' col_coords is closest point to triangle plane (in triangle space)

			col_coords = intersect 'tplane.Nearest( line.o.Add(line.d.Multiply(t)) )
			p = New Plane(col_coords,n) 'tplane

		Else
		
			p = New Plane(line.Multiply(t),n)
			If ( (p.n.Dot(line.o) + p.d ) < -COLLISION_EPSILON ) Return 0 ''starts behind plane
			
		Endif
		
			
		If( p.n.Dot( line.d )> -COLLISION_EPSILON ) Return 0 ''moving away from plane
		'If( p.Distance(line.o)< -COLLISION_EPSILON ) Return 0
		'If ( (p.n.Dot(line.o) + p.d ) < -COLLISION_EPSILON ) Return 0 ''starts behind plane
		
'Print "< UPDATE "+t
	
		time=t
		normal=n
		coll_u = u
		coll_v = v
		
		Return 1
		
	End

	Method AABBCollide:Int( li:Line, box:Box, target:Box)
		Local n:Vector = New Vector()
		
		Local r1:Float, r2:Float, r3:Float, r4:Float, r5:Float, r6:Float, t:Float
		If box.b.x<target.b.x Then r1 = box.b.x Else r1 = target.b.x
		If box.a.x>target.a.x Then r2 = box.a.x Else r2 = target.a.x
		
		If box.b.y<target.b.y Then r3 = box.b.y Else r3 = target.b.y
		If box.a.y>target.a.y Then r4 = box.a.y Else r4 = target.a.y
		
		If box.b.z<target.b.z Then r5 = box.b.z Else r5 = target.b.z
		If box.a.z>target.a.z Then r6 = box.a.z Else r6 = target.a.z
		
		If Not ((r1>=r2) And (r3>=r4) And (r5>=r6)) Return 0
		
		Local target_center:Vector = New Vector( (target.a.x+target.b.x)*0.5, (target.a.y+target.b.y)*0.5, (target.a.z+target.b.z)*0.5)
		t = li.o.DistanceSquared( target_center)
		
		Return Update( li,t, n )
	
	End


	Method SphereCollide:Int ( line:Line,radius:Float,dest:Vector,dest_radius:Float )

		radius += dest_radius
		Local l:Line = New Line( line.o.Subtract(dest) ,line.d )

		Local a:Float=l.d.Dot(l.d)
		If a<0.001 Then Return 0
		
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
	Method EdgeTest:Int ( v0:Vector,v1:Vector,pn:Vector,en:Vector,line:Line,radius:Float, curr_coll:CollisionObject )
		
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

		
	
		Local hit:Int=False
		Local p0:Plane, p1:Plane, p2:Plane, p3:Plane
		
		For Local n:Int =0 To 23 Step 4  ''6 planes

			Local v0:Vector = box.Corner( BOXQUADS[n] )
			Local v1:Vector = box.Corner( BOXQUADS[n+1] )
			Local v2:Vector = box.Corner( BOXQUADS[n+2] )
			Local v3:Vector = box.Corner( BOXQUADS[n+3] )
	
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
	
	
	Method SphereBox:Int( li:Line, radius:Float, box:Box, scale:Vector)
		
		Local hit:Int= 0
		Local line_box:Box = New Box(li)
		line_box.Expand(radius+radius)
		Local rad_vec:Vector = New Vector(radius,radius,radius)
		
		If Not line_box.Overlaps(box) Then Return 0
		
		For Local n:Int =0 To 23 Step 4  ''6 planes

			Local v0:Vector = box.Corner( BOXQUADS[n] )'.Multiply(scale)
			Local v1:Vector = box.Corner( BOXQUADS[n+1] )'.Multiply(scale)
			Local v2:Vector = box.Corner( BOXQUADS[n+2] )'.Multiply(scale)
			Local v3:Vector = box.Corner( BOXQUADS[n+3] )'.Multiply(scale)
			
			hit = hit | SphereTriangle( li, rad_vec,  v0,v1,v2) | SphereTriangle( li, rad_vec,  v0,v2,v3)
			
		Next
		
		Return hit
		
	End
	
	
	
	'' infinte ray, no radius
	Method RayTriangle:Int(li:Line, v0:Vector, v1:Vector, v2:Vector )
		
		Local u:Vector, v:Vector, n:Vector             '' triangle vectors
		Local w:Vector
		Local i:Vector = New Vector() 		'' interesection point
		Local r#, a#, b#, radius#             '' params To calc ray-plane intersect
		
		
		'' get triangle plane normal
		u = v1.Subtract(v0)'.Multiply(scale_vec)
		v = v2.Subtract(v0)'.Multiply(scale_vec)
		n = u.Cross(v)'.Normalize        '' cross product
		If (n.x=0 And n.y=0 And n.z=0) Then Return 0           

		''sphere plane/ ray plane collision
		
		a = li.o.Subtract(v0).Dot(n)
		b = -li.d.Dot(n)


		'' infinte ray, no radius
		
		If (b =0.0) '< 0.00001 And b>-0.00001)     '' ray is parallel To triangle plane or points away from ray
		    If (a = 0.0)
				r=0.0 '(return li.o) ''ray lies in triangle plane
			Else    
				Return 0             '' ray disjoint from plane
			Endif
		Else
			
			'' get intersect point of ray with triangle plane
			r = a/b	
			i.Overwrite(li.o.x+li.d.x*r, li.o.y+li.d.y*r, li.o.z+li.d.z*r)
		Endif
		

		''exit early for distant triangles
		If r > time Then Return 0

		'' is I inside T?
				
		Local uu#, uv#, vv#, wu#, wv#, D#
		uu = u.Dot(u)
		vv = v.Dot(v)
		
		w = i.Subtract(v0)
		
		Local ids# = w.DistanceSquared()
		If ids > uu And ids > vv Then Return 0 ''quick squared distance check
		
		uv = u.Dot(v)
		wu = w.Dot(u)
		wv = w.Dot(v)
		D = 1.0 / (uv * uv - uu * vv)
	
		'' get And test parametric coords
		Local s#, t#, out%, diff#=0.0
		s = (uv * wv - vv * wu) * D
		If (s < 0.0 Or s > 1.0)
			Return 0
		Endif

		t = (uv * wu - uu * wv) * D
		'' does s+t need to be Abs(s)?
		If (t < (0.0) Or (s + t) > (1.0) )
			Return 0
		Endif

'Print "TRIHITTIME "+r+" s "+s+"  t "+t		
'Print "COLCOORDSONTRI "+i.ToString()

		Return Update( li, r, n, s ,t, i.Copy() )

		
	End
	
	
	
	Method SphereTriangle:Int(li:Line, tf_radius:Vector, v0:Vector, v1:Vector, v2:Vector )
		
		''Notes:
		'' for this to work, don't use time, use dist squared
		'' Must return distsq for closest point on TRIANGLE plane
		
		'' to get ellipsoid radius to normal: sqrt(xrad.dot(n)^2 + yrad.dot(n)^2 + zrad.dot(n)^2)
		'' so it's either 9 mults or 12 mults + sqrt,  per triangle
		
		Local u:Vector, v:Vector, n:Vector             '' triangle vectors
		Local dst:Vector, w0:Vector, w:Vector          '' ray vectors
		Local i:Vector = New Vector() 		'' interesection point
		Local ix:Vector = New Vector()		'' sphere center at intersection
		Local r#=-1.0 , a#, b#=0.0, dotradius#             '' params To calc ray-plane intersect
		Local ru#=  0.0, rv#=0.0
		Local beneath:Bool = False

		
		'' get triangle plane normal
		u = v1.Subtract(v0)'.Multiply(scale_vec)
		v = v2.Subtract(v0)'.Multiply(scale_vec)
		n = u.Cross(v)        '' cross product
		If (n.x=0.0 And n.y=0.0 And n.z=0.0) Then Return 0           
		n = n.Normalize()
		
		''sphere plane/ ray plane collision


		Local src:Vector = li.o.Subtract(v0)
		Local n_radius# = tf_radius.x*tf_radius.x
		
		Local o_len# = n.Dot(src)
		
		If o_len < 0.0 Then Return 0  '' quick opposite direction check
		
		i = (li.o.Subtract( n.Multiply(o_len) )) ''nearest point in plane
		Local o_radius# = i.DistanceSquared(li.o) 
		'Local o_radius# = n.Multiply(src.Dot(n)).DistanceSquared() 'n.Multiply(o_len).DistanceSquared() ''distsq from plane to li.o
		Local diff# = o_radius-n_radius
'Print "lio "+li.o+"   li.d "+li.d+"  o_rad "+o_radius+"  diff "+diff+"~n nrad "+n_radius+"   n "+n	
	

		If diff<0.0 And diff>-n_radius*0.5

			''hit plane without moving		
			beneath = True
			
			r = o_radius
			'r = i.DistanceSquared(li.o) ''same as o_radius
			
			'ix = i.Add(n.Multiply(tf_radius.x))
			ix = li.o '.Add(n.Multiply(Sqrt(o_radius)-Sqrt(n_radius) ))
			
		Else
			
			'' find moving hit on plane
			Local nr# = tf_radius.x 'Dot(n)
			a = o_len 'li.o.Subtract(v0).Dot(n)
			b = -li.d.Dot(n)
			b = b + (Sgn(b)*nr)
			
			Local r2# = 0.0
			If b =0.0 Then Return 0
		
			r2 = a/b

			If r2<0.0 Or r2>1.0 Then Return 0
			'If r2<0.0  Then Return 0
			
			ix = li.o.Add(li.d.Multiply(r2))
			''i = li.o.Subtract( n.Multiply(src.Dot(n)) ) ''i=i
			i = ix.Subtract( n.Multiply(ix.Subtract(v0).Dot(n)) )	
			'i = li.o.Add(ix)
			
			r = i.Subtract(ix).DistanceSquared() 'i.Subtract(li.o).DistanceSquared()	
			
		Endif	
		
			
		''exit early for distant triangles
		If r > time Then Return 0


		'' is I inside T?
				
		Local uu#, uv#, vv#, wu#, wv#, D#
		uu = u.Dot(u)
		vv = v.Dot(v)
		
		w = i.Subtract(v0)

		Local ids# = (w.DistanceSquared())*0.5 ''super large radius may fail here
		If ids > uu And ids > vv Then Return 0 ''quick squared distance check
	

		uv = u.Dot(v)
		wu = w.Dot(u)
		wv = w.Dot(v)
		D = 1.0 / (uv * uv - uu * vv)

	
		'' get And test parametric coords ''added in radius adjustment for s/t test
		Local s#, t#, out%=0, bb:Vector
		
		s = (uv * wv - vv * wu) * D
		If (s < 0.0 Or s > 1.0)
			'' I is outside T
			'Return 0
			out=1
		Endif

		t = (uv * wu - uu * wv) * D
		'' does s+t need to be Abs(s)?
		If (t < 0.0 Or (s + t) > 1.0 ) ''*** made t< -0.05 for smoother poly to poly transitions
			'' I is outside T
			'Return 0
			out=out+1	
		Endif
		
		''edge test
		
		If out>0 And tf_radius.x 'And Not beneath


			If s+t>1.0
				bb = i.PointOnSegment(v1,v2)
			Elseif t<0.0
				bb = i.PointOnSegment(v0,v1)
			Else
				bb = i.PointOnSegment(v0,v2)
			Endif

			'Local bb:Vector = New Vector(v0.x+(v2.x-v0.x)*t+(v1.x-v0.x)*s, v0.y+(v2.y-v0.y)*t+(v1.y-v0.y)*s, v0.z+(v2.z-v0.z)*t+(v1.z-v0.z)*s)

'test3 = CollisionObject.renew.Multiply(bb) '.Copy()

			Local nr#
			nr = ix.DistanceSquared(bb) 'li.o.DistanceSquared(bb)

			If (nr > n_radius) Or nr>time  Then Return 0
			
			'' ...control the poly time

			'r = nr+n_radius'*0.1
			r = li.o.DistanceSquared(bb)+n_radius

			'i=bb
			i = bb.Add(n.Multiply(tf_radius.x*0.01)) ''softens edges

			n = (ix.Subtract(bb)).Normalize() ''nice
			'n = li.o.Subtract(bb).Normalize()


'Print "BENEATH "+Int(beneath)
'Print "*** OFFFFFFF "+bb+"  i "+i+"  "+r
'Print "EDGEHIT"

		Elseif out>0
			
			Return 0
			
		Endif

'Print "TRIHITTIME "+r+" s "+s+"  t "+t		
'Print "COLCOORDSONTRI "+i.ToString()
		
		Return Update( li, r, n, s ,t, i.Copy() )
		                 
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

Function CreateTestLine(s:Vector, d:Vector, r%=100, g%=0, b%=100)
	Local ee1:TMesh = TMesh.CreateLine(s, d, r,g,b )
	ee1.EntityFX 1+64
End

#rem			
			''ok, now check triangle edges
			'' -- if we have point on plane, so break it into axis checks or point on segment
			Local edge:Vector = New Vector(0,0,0)
			If radius
			
				Local ed1:Vector = i.PointOnSegment(v0,v1)
				Local ed2:Vector = i.PointOnSegment(v1,v2)
				Local ed3:Vector = i.PointOnSegment(v0,v2)
				Local rsq:Float = radius*radius
				
				If i.Subtract(ed1).DistanceSquared() <=rsq
					edge=ed1 '; Print 123
				Elseif i.Subtract(ed2).DistanceSquared() <=rsq
					edge=ed2 '; Print 234
				Elseif i.Subtract(ed3).DistanceSquared() <=rsq
					edge=ed3 '; Print 456
				Endif
				
			Endif
#end	
