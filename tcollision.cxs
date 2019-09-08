Import minib3d
Import minib3d.math.vector
Import minib3d.math.geom
Import minib3d.math.matrix

'' NOTES:
'' -- if we scale the Entity after we set up collisions, who's job is it to update the AABB?? UpdateShape()?

''can't do an easy ray-AABB since the AABB may rotate, then what is the bounds?
'' -- instead use a sphere
''
''AABB moving box collision:
''-- use a line for motion path, find closest point to dst, then compare aabb (like sphere)

'' changed collision time to be distance squared. seems to work.

'' -- radius_y sphere is not available anymore

'' -- all collsions MUST multiply radius with scale!

Const MAX_TYPES=100

'collision methods
Const COLLISION_METHOD_SPHERE:Int=1
Const COLLISION_METHOD_POLYGON:Int=2
Const COLLISION_METHOD_BOX:Int=3
Const COLLISION_METHOD_AABB:Int=4 ''fast, gives no normals
Const COLLISION_METHOD_POLYGON_AABB:Int=5

Const COLLISION_FLAG_CONTINUOUS:Int=128

'collision actions
''-- damping (water)? -- sticking?
Const COLLISION_RESPONSE_NONE:Int=0
Const COLLISION_RESPONSE_STOP:Int=1
Const COLLISION_RESPONSE_SLIDE:Int=2
Const COLLISION_RESPONSE_SLIDEXZ:Int=3

Const COLLISION_EPSILON:Float=0.00001
Const COLLISION_INFINITY:Float = 9999999.9


Class TCollision
	
	Field type:Int
	Field no_collisions:int
	Field impact:TCollisionImpact[]
	Field flag:int
	
	''collision, pick
	Field radius_x#=0.0,radius_y#=0.0
	Field box_x#=0.0,box_y#=0.0,box_z#=0.0,box_w#=0.0,box_h#=0.0,box_d#=0.0
	Field updated_shape:Bool = false

	''divSphere
	Field old_radius:Float=1.0
	
	Private 
	
	Field old_px#, old_py#, old_pz#
	Field old_gsx#, old_gsy#, old_gsz#, old_igsx#, old_igsy#, old_igsz#
	Field old_rx#, old_ry#, old_rz#
	Field sa:Float[6], old_dst_radius#
	
	Public
	
	Method New()

	End 
	
	Method SetFlag:Void(f:Int)
		flag = f
	End
	
	Method MoveTest:Bool(ent:TEntity)
		
		
		If old_px=ent.mat.grid[3][0] And old_py=ent.mat.grid[3][1] And old_pz=-ent.mat.grid[3][2]
			
			'If type = COLLISION_METHOD_POLYGON Or type = COLLISION_METHOD_BOX
				'If old_rx = ent.rx And old_ry=ent.ry And old_rz = ent.rz
					'Return False
				'Endif
			'Else
				'Return False
			'Endif
			Return false
		Endif

		Return True
	End
	
	Method SetOldPosition:Void(ent:TEntity,x#=0,y#=0,z#=0)
		old_px=ent.mat.grid[3][0]; old_py=ent.mat.grid[3][1]; old_pz=-ent.mat.grid[3][2]
		old_rz = ent.rz; old_ry = ent.ry; old_rx = ent.rx
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
		
		cc.updated_shape = False
		
		Return cc
	End
	
	
	Method ScaleCollision:Void(x#,y#,z#)
		'' *****
		'' questionable-- do we need this? should not collision scale before checking?
		
		#rem
		x=Abs(x); y=Abs(y); z=Abs(z)
		If radius_x
			
			Local mx# = Max(Max(x,y),z)
			radius_x *= mx
			radius_y *= mx
			
		Endif
		If box_x
			box_x *= x; box_w *= x
			box_y *= y; box_h *= y
			box_z *= z; box_d *= z
		Endif
		#end
		
	End	
	
	Method ClearImpact:Void()
		
		
		no_collisions=0
		impact =New TCollisionImpact[0]
		
	End
	
	
	Method CreateImpact:Void(ent2_hit:TEntity, coll_obj:CollisionObject )
	
		no_collisions=no_collisions+1
	
		Local i=no_collisions-1
		impact=impact.Resize(i+1)
					
		impact[i]=New TCollisionImpact
		impact[i].x=coll_obj.col_coords.x 
		impact[i].y=coll_obj.col_coords.y 
		impact[i].z=coll_obj.col_coords.z 
		impact[i].nx=coll_obj.normal.x
		impact[i].ny=coll_obj.normal.y 
		impact[i].nz=coll_obj.normal.z
		impact[i].ent=ent2_hit
		
		If TMesh(ent2_hit)<>Null
			impact[i].surf=coll_obj.surface '& $0000ffff
		Else
			impact[i].surf=0
		Endif
		
		''get the real tri index (byte packed in surface) --not anymore
		impact[i].tri=coll_obj.index '((coll_obj.surface & $ffff0000) Shr 16)
	
	End
	
	Method DebugSphere:Void(ent:TEntity)
		Local sp:TMesh = CreateSphere(5,ent)
		sp.EntityAlpha(0.3)
		sp.EntityColor(200,50,50)
		Local sc:Float  =Max(Max(Abs(ent.gsx),Abs(ent.gsy)),Abs(ent.gsz))
		sp.ScaleEntity( radius_x*sc,radius_x*sc,radius_x*sc, True) ''global
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
	
	
	Method SetType:Void(ent:TEntity, type_no:Int)

		' remove from collision entity list if new type no=0 or previously added
		If ent.collision.type<>0 And type_no<>ent.collision.type

			ListRemove(ent, ent.collision.type)
			
		Endif
		
		' add to collision entity list if new type no<>0
		If type_no<>0
		
			ListAddLast(ent, type_no)
			
		Endif
		
		ent.collision.type=type_no
		ent.collision.SetOldPosition(ent) ''reset the old_px values
		
	End
	
	
	Function Collisions:Void(src_no:Int, dest_no:Int, method_no:Int, response_no:Int=0)
	
		Local col:TCollisionPair=New TCollisionPair
		
		col.src_type=src_no
		col.des_type=dest_no
		col.col_method=method_no
		col.response=response_no
		
		' check to see if same collision pair already exists, src and dst have to match
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



Class DivSphereInfo final
	
	Field num:Int =0
	Field pos:Vector[]
	Field rad:Float[]
	Field offset:Vector = New Vector()
	
	Method Clear:Void()
		offset.Overwrite(0,0,0)
		pos = New Vector[0]
		rad = New Float[0]
		num =0
	End
	
	''-- rotate the divSpheres to the world space
	Method RotateDivSpheres:Int(ent:TEntity, col_info:CollisionInfo, inverse:Bool=false)
		
		num=0
		offset.Overwrite(0,0,0)
		
		Local mesh:TMesh = TMesh(ent)
		If mesh And (mesh.col_tree.divSphere_p.Length()>1)
			
			Local quickmat:Matrix = ent.mat.Copy()
			quickmat.grid[3][0]=0.0; quickmat.grid[3][1]=0.0; quickmat.grid[3][2]=0.0
			
			If (inverse) quickmat = quickmat.Inverse()
			
			If (Not pos) Or (pos.Length() < mesh.col_tree.divSphere_p.Length())

				pos = New Vector[mesh.col_tree.divSphere_p.Length()]
				rad = New Float[mesh.col_tree.divSphere_p.Length()]

			Endif
			
			Local radmax:Float = Max(Max(ent.gsx,ent.gsy),ent.gsz)
			For Local i:Int = 0 To  mesh.col_tree.divSphere_p.Length()-1
				
				'' rotate only! don't translate as its an offset
				pos[i] = quickmat.Multiply( mesh.col_tree.divSphere_p[i] )
				rad[i] = mesh.col_tree.divSphere_r[i] * radmax

			Next
			
			''return number of spheres
			num = mesh.col_tree.divSphere_p.Length()

			Return num
			
		Endif
		
		''return number of spheres
		Return 0
		
	End
	
End





Class CollisionInfo

	Const SQRT2:Float = 1.4142135623

	Global col_info:CollisionInfo = New CollisionInfo()
	

	Field dv:Vector = New Vector
	Field sv:Vector = New Vector
	Field radii:Vector = New Vector
	Field panic:Vector = New Vector

	Field mesh_coll:MeshCollider
	'Field src_mesh_coll:MeshCollider
	Field src_radius:Float, inv_y_scale:Float, y_scale:Float
	
	
	Field n_hit:Int
	Field planes:Plane[] = [New Plane, New Plane, New Plane, New Plane]
	Field col_points:Vector[] = [New Vector, New Vector, New Vector, New Vector]
	
	Field coll_method:Int
	Field coll_line:Line = New Line()
	Field tf_line:Line = New Line()
	Field ray_dir:Vector = New Vector
	Field ray_length:Float
	Field ray_center:Vector = New Vector
	
	Field tform:TransformMat=New TransformMat
	Field y_tform:TransformMat = New TransformMat
	
	Field renew:Matrix = New Matrix
	Field renew2:Matrix = New Matrix
	Field renew3:Matrix = New Matrix
	Field tf_offset:Vector = New Vector
	Field inv_scale:Vector = New Vector
	
	''for triangle collisions
	Field tf_scale:Vector = New Vector
	Field tf_radius:Vector = New Vector ''scaled radius for sphere in local mesh space
	Field tf_box:Box = New Box()

	Field dst_entity:TEntity ''caches rotated dst_divSphere

	Field src_divSphere:DivSphereInfo = New DivSphereInfo()
	Field dst_divSphere:DivSphereInfo = New DivSphereInfo()
	Field hitDivOffset:Vector = New Vector()
	Field hitDivRadius:Float = 0.0
	
	Field td:Float
	Field td_xz:Float
	
	Field hits:Int
	
	Field dst_radius:Float
	Field dst_pos:Vector = New Vector()
	Field ax:Float
	Field ay:Float
	Field az:Float
	Field bx:Float
	Field by:Float
	Field bz:Float

	
	Field col_passes:int
	
	'' globals
	Const MAX_HITS:Int=10
	Const EPSILON:Float=COLLISION_EPSILON		'' a small value
	
	'' per update globals
	Field vec_a:Vector = New Vector(0.0,0.0,0.0)
	Field vec_b:Vector = New Vector(0.0,0.0,0.0)
	Field vec_c:Vector = New Vector(0.0,0.0,0.0)
	Field vec_v:Vector = New Vector(0.0,0.0,0.0)
	
	''temp math
	Global t_mat:Matrix
	Global t_vec:Vector = New Vector()
	Global nullVec:Vector = New Vector()
	
	''debugging
	Global test_vec:Vector = New Vector
	Global test_dot:Vector = New Vector
	Global testx:Float, testy:Float, testz:Float
	Global testx2:Float, testy2:Float, testz2:Float
	Global testline:Line = New Line()

	Global starttime:float
	
	Global trigger:Int=0
	
	Method New()
	
		t_mat = New Matrix()
		tform = New TransformMat()
		
	End

	Method Clear:Void()
		src_radius=0.0
		dst_radius=0.0
		
		planes[0].Update(0.0,0.0,0.0,  0)
		planes[1].Update(0.0,0.0,0.0,  0)
		planes[2].Update(0.0,0.0,0.0,  0)
		planes[3].Update(0.0,0.0,0.0,  0)
		col_points[0].Update(0.0,0.0,0.0)
		col_points[1].Update(0.0,0.0,0.0)
		col_points[2].Update(0.0,0.0,0.0)
		col_points[3].Update(0.0,0.0,0.0)
		
		src_divSphere.Clear()
		dst_divSphere.Clear()
		
		''clear the dst_divSphere cache
		dst_entity = null
		
	End
	
	Method UpdateRay:Int(sv2:Vector,dv2:Vector,radii2:Vector)
		
		t_mat.LoadIdentity()
		tform.m.LoadIdentity()
		
		dv.Overwrite(dv2)
		sv.Overwrite(sv2)
		panic.Overwrite(sv2)
		radii.Overwrite(radii2)
		src_radius = radii.x

		
		
	
		coll_line.Update( sv.x, sv.y, sv.z, dv.x-sv.x, dv.y-sv.y, dv.z-sv.z )
	
		'dir.Update((coll_line.d.x),(coll_line.d.y),(coll_line.d.z))
		'ray_dir = coll_line.d.Normalize()
		ray_length =coll_line.d.Length()
		If ray_length>0.00001
			ray_dir = coll_line.Multiply(1.0/ray_length)
		Else
			ray_dir = New Vector(0.0,0.0,0.0)
		Endif
		ray_center.Update(coll_line.o.x+coll_line.d.x*0.5,coll_line.o.y+coll_line.d.y*0.5,coll_line.o.z+coll_line.d.z*0.5)
		
		'tf_radius = tf_scale.Multiply(radius)
		'tf_line.Update(coll_line.o.x,coll_line.o.y,coll_line.o.z, coll_line.d.x,coll_line.d.y,coll_line.d.z)
		

		'td_xz = New Vector( coll_line.d.x,0,coll_line.d.z ).Length()
	
		''
		y_scale=1.0
		inv_y_scale=1.0
		y_tform.m.grid[1][1]=1.0 ''mat.j.y = mat.grid[1][1]
		
		''** disabled radii.y
		'If( radii.x <> radii.y )
			'y_scale=src_radius/radii.y
			'y_tform.m.grid[1][1]=src_radius/radii.y
			'inv_y_scale=1.0/y_scale
			'sv.y *= y_scale
			'dv.y *= y_scale
		'Endif
		
	End
	
	Method ClearHitPlanes:Void()
		
		planes[0].Update(0.0,0.0,0.0,  0)
		planes[1].Update(0.0,0.0,0.0,  0)
		planes[2].Update(0.0,0.0,0.0,  0)
		planes[3].Update(0.0,0.0,0.0,  0)
		col_points[0].Update(0.0,0.0,0.0)
		col_points[1].Update(0.0,0.0,0.0)
		col_points[2].Update(0.0,0.0,0.0)
		col_points[3].Update(0.0,0.0,0.0)
		
		
		
		hits=0; n_hit=0
		'dst_radius=1.0
		ax=1.0
		ay=1.0
		az=1.0
		bx=1.0
		by=1.0
		bz=1.0
	End
	
	Method UpdateDestShape (ent:TEntity)
		
		If Not ent.collision.updated_shape
		
			''auto update sphere and bounding box
			Local sc:Float  =Max(Max(Abs(ent.gsx),Abs(ent.gsy)),Abs(ent.gsz))
			If ent.collision.radius_x<>0.0
				
				dst_radius =ent.collision.radius_x*sc
				''check for ellipsoid
				'If dst_radius<ent.collision.radius_y*sc Then dst_radius = ent.collision.radius_y*sc
			Else
			
				dst_radius = ent.EntityRadius()*sc
				'ent.collision.radius_x = dst_radius*sc
	
			Endif
	
			If ent.collision.box_w=0.0
		
				ent.EntityBox()
	
			Endif
			
			ax =ent.collision.box_x*sc
			ay =ent.collision.box_y*sc
			az =ent.collision.box_z*sc
			bx =ent.collision.box_x+ent.collision.box_w*sc
			by =ent.collision.box_y+ent.collision.box_h*sc
			bz =ent.collision.box_z+ent.collision.box_d*sc	
			
			ent.collision.updated_shape = True
			ent.collision.sa = [ ax,ay,az,bx,by,bz ]
			ent.collision.old_dst_radius = dst_radius
			
		Else
		
			dst_radius =ent.collision.old_dst_radius
			ax =ent.collision.sa[0]
			ay =ent.collision.sa[1]
			az =ent.collision.sa[2]
			bx =ent.collision.sa[3]
			by =ent.collision.sa[4]
			bz =ent.collision.sa[5]
		Endif
		
		'' must do this
		dst_divSphere.offset.Overwrite(0,0,0)
		dst_pos.Update(ent.mat.grid[3][0],ent.mat.grid[3][1],-ent.mat.grid[3][2])
		
	End
	
	Method UpdateSourceSphere(ent:TEntity)
		
		If ent.collision.radius_x=0.0
			'' **WRONG by itself
			'ent.collision.radius_x = Max(Max(ent.collision.box_x+ent.collision.box_w,ent.collision.box_y+ent.collision.box_h),ent.collision.box_z+ent.collision.box_d)
			'' RIGHT!
			'ent.collision.radius_x = Sqrt(ent.collision.radius_x *ent.collision.radius_x +ent.collision.radius_x *ent.collision.radius_x )
			Local sc:Float  =Max(Max(Abs(ent.gsx),Abs(ent.gsy)),Abs(ent.gsz))
			src_radius = ent.EntityRadius()*sc

		Endif
'Print "src_rad "+src_radius		
		'src_matrix = ent.mat.Copy()
		
		src_divSphere.offset.Overwrite(0,0,0)
		hitDivOffset.Overwrite(0,0,0)
		hitDivRadius = 0.0
		
	End
	

	
	
	Function UpdateCollisions()
	
'Print "Update Collisions"
	
		Local coll_obj:CollisionObject = New CollisionObject()
		'Local col_info:CollisionInfo = New CollisionInfo()
		col_info.Clear()
		
		' loop through collision setup list, containing pairs of src entities and des entities to be check for collisions
		For Local i:Int=0 Until MAX_TYPES
		
			' if no entities exist of src_type then do not check for collisions
			If TCollisionPair.ent_lists[i]=Null Then Continue
			
			' loop through src entities
			For Local ent:TEntity=Eachin TCollisionPair.ent_lists[i]
			

				ent.collision.ClearImpact()
				
				' if src entity is hidden or it's parent is hidden then do not check for collision
				If ent.Hidden()=True Then Continue
				
				''update sphere if previously defined as box
				col_info.UpdateSourceSphere(ent)
				
				' quick check to see if entity is moving, if not, no ray
				If (ent.collision.MoveTest(ent)=False) Then Continue 'And (Not (ent.collision.flag &COLLISION_FLAG_CONTINUOUS)) Then Continue

				col_info.vec_a.Update(ent.mat.grid[3][0],ent.mat.grid[3][1],-ent.mat.grid[3][2]) ''line dest
				col_info.vec_b.Update(ent.collision.old_px,ent.collision.old_py,ent.collision.old_pz) ''line source
				Local sc:Float = Max(Max(Abs(ent.gsx),Abs(ent.gsy)),Abs(ent.gsz))

				col_info.vec_c.Update(ent.collision.radius_x*sc,ent.collision.radius_y*sc,ent.collision.radius_x*sc)
				ent.collision.SetOldPosition(ent, ent.mat.grid[3][0],ent.mat.grid[3][1],-ent.mat.grid[3][2])
	
				''make collision line
				col_info.ClearHitPlanes()
				col_info.UpdateRay(col_info.vec_b,col_info.vec_a,col_info.vec_c)
				

				If TMesh(ent)
					col_info.src_divSphere.RotateDivSpheres( ent, col_info)
				Endif

				Local response:Int
				Local obj_time:Float = COLLISION_INFINITY
				
				Local pass2:Bool = False ''caching
				Local hit:Int =0
				col_info.col_passes=0
				Local original_src_radius:Float  = col_info.src_radius
				
				''use this for proper time
				Local radvec:Vector = New Vector(col_info.src_radius,col_info.src_radius,col_info.src_radius)
				
				'' ------------------
				Repeat
				
					Local ent2_hit:TEntity=Null
					coll_obj.Clear()			


					' set a reasonable max time here
					' this helps against bouncing against multiple objects at once
					coll_obj.time = col_info.coll_line.o.DistanceSquared(radvec)*1.1 ''dist squ
					
starttime = coll_obj.time

					If ent.collision.radius_x = 0.0 Then coll_obj.time = 1.0 ''ray-triangle
					
					
					For Local col_pair:TCollisionPair=Eachin TCollisionPair.list
						
						If col_pair.src_type = i
						
							' if no entities exist of des_type then do not check for collisions
							If TCollisionPair.ent_lists[col_pair.des_type]=Null Then Continue
							
							
							' loop through entities2 that are paired with src entities
							For Local ent2:TEntity=Eachin TCollisionPair.ent_lists[col_pair.des_type]
			
								' if entity2 is hidden or it's parent is hidden then do not check for collision
								If ent2.Hidden()=True Then Continue
								' if src ent is same as entity2 then do not check for collision
								If ent=ent2 Then Continue 
								

								
								''quick test
								col_info.UpdateDestShape(ent2)
								'col_info.src_radius = original_src_radius 'ent.collision.radius_x ''***BAD!*** ''divspheres overwrites this, need a better way
								
					
								If CollisionObject.QuickBoundsTest(col_info, ent2)
									
									col_info.coll_method = col_pair.col_method
'Print ent2.classname
'Print " src_rad "+col_info.src_radius+"  dst_rad "+ col_info.dst_radius		
						
									If (col_info.src_divSphere.num <= 1)

										col_info.CollisionSetup(ent2, col_pair.col_method, coll_obj, nullVec)
										hit = col_info.CollisionDetect(coll_obj)
										
									Else
		
										hit = col_info.DivSpheresCollisionDetect( ent, ent2, col_pair.col_method, coll_obj )
																			
									Endif
								
									If hit
										col_info.RegisterHitPlane ( coll_obj.col_coords, coll_obj.normal)
'Print "hittime "+coll_obj.time
										ent2_hit=ent2
										response=col_pair.response
										'Exit
	
									Endif
									
								Endif
								
							Next
						
						Endif
						
						'If hit Then exit
						
					Next
					
					If ent2_hit<>Null
					
						

'col_info.UpdateDestShape(ent2_hit)
'CreateTestSphere( New Vector(ent2_hit.X,ent2_hit.Y,ent2_hit.Z), col_info.dst_radius)
'CreateTestSphere2( New Vector(ent.X,ent.Y,ent.Z), col_info.src_radius); Print col_info.src_radius
'CreateTestBox( coll_obj.col_box.a.Add(ent2_hit.X,ent2_hit.Y,ent2_hit.Z), coll_obj.col_box.b.Add(ent2_hit.X,ent2_hit.Y,ent2_hit.Z))
'Print "..box "+coll_obj.col_box.Width()+" "+coll_obj.col_box.Height()+" "+coll_obj.col_box.Depth()
'Print ".. "+ent2_hit.classname+" "+col_info.dst_radius
						
						ent.collision.CreateImpact(ent2_hit, coll_obj )
						Local res:int = 1
						
						''special case to make sure correct divSphere radius is set
						If (col_info.src_divSphere.num > 1)
							res = col_info.CollisionResponse(coll_obj, response, col_info.hitDivRadius)
						Else
							res = col_info.CollisionResponse(coll_obj, response, col_info.src_radius)
						endif
						''exit on no more hits
						If res=0 Then Exit
							
					Else
					
						Exit
									
					Endif
					
					'col_info.hits = 0
					
					''pass2 = True ''caching the ray rotation matrix
					col_info.col_passes+=1
					'If passes>10 Then Exit
					
				Forever
				
				''---------------

				Local hits:Int =col_info.CollisionFinal(coll_obj, response)
				
				If hits

					ent.PositionEntity(coll_obj.col_pos.x,coll_obj.col_pos.y,coll_obj.col_pos.z,True) 
					'ent.PositionEntity(coll_obj.col_pos.x+col_info.divOffset.x,coll_obj.col_pos.y+col_info.divOffset.y,coll_obj.col_pos.z+col_info.divOffset.z,True) 
					
				Endif
		
				ent.collision.SetOldPosition(ent, ent.mat.grid[3][0],ent.mat.grid[3][1],-ent.mat.grid[3][2])
	
			Next ''ent_list[type]
											
		Next ''MAX_TYPES
	
	End 
	
	


	
	''
	'' line is in world space. need to change line to local mesh space. watch out for parented global scale versus local scale
	''
	Method CollisionSetup(ent:TEntity, coll_method:Int, coll_obj:CollisionObject, offset2:Vector, pass2:Bool=False)

'Print "setup----"+ent.classname
		
		''If Not pass2 ''caching
		
		If (coll_method<>COLLISION_METHOD_SPHERE) And (coll_method<>COLLISION_METHOD_AABB) And (pass2 = False)
		
			''remove global scaling from tf matrix	
			Local ex:Float, ey:Float, ez:Float
			If ent.collision.old_gsx=ent.gsx And ent.collision.old_gsy=ent.gsy And ent.collision.old_gsz=ent.gsz
				ex=ent.collision.old_igsx; ey=ent.collision.old_igsy; ez=ent.collision.old_igsz
			Else
				ex = 1.0/ent.gsx
				ey = 1.0/ent.gsy
				ez = 1.0/ent.gsz
				ent.collision.old_gsx=ent.gsx; ent.collision.old_gsy=ent.gsy; ent.collision.old_gsz=ent.gsz
				ent.collision.old_igsx=ex; ent.collision.old_igsy=ey; ent.collision.old_igsz=ez
			Endif
			
			inv_scale.Overwrite(ex,ey,ez)
			'coll_obj.dst_matrix = ent.mat.Copy()
			'coll_obj.dst_matrix.Multiply( src_matrix.Inverse() )
		
			''rotation only! no scale, no translate
			tform.m.grid[0] = [ent.mat.grid[0][0]*ex,ent.mat.grid[1][0]*ey,-ent.mat.grid[2][0]*ez,  0.0]
			tform.m.grid[1] = [ent.mat.grid[0][1]*ex,ent.mat.grid[1][1]*ey,-ent.mat.grid[2][1]*ez,  0.0]
			tform.m.grid[2] = [-ent.mat.grid[0][2]*ex,-ent.mat.grid[1][2]*ey,ent.mat.grid[2][2]*ez,  0.0]

			'renew2 = tform.m.Inverse()
			renew2.grid[0] = [tform.m.grid[0][0],tform.m.grid[1][0],tform.m.grid[2][0],  0.0]
			renew2.grid[1] = [tform.m.grid[0][1],tform.m.grid[1][1],tform.m.grid[2][1],  0.0]
			renew2.grid[2] = [tform.m.grid[0][2],tform.m.grid[1][2],tform.m.grid[2][2],  0.0]
	
			If( y_scale<>1.0 )
	
				tform = y_tform.Multiply(tform)
	
			Endif
			
			
		
		Endif
		
		''Endif
		
		tf_scale.Overwrite(ent.gsx, ent.gsy, ent.gsz) ''scale for the triangle testing and box collision
		tf_radius.Overwrite(src_radius, src_radius, src_radius)
		
		CreateCollLine( tf_line, ent, tform.m, offset2) ''creates tf_line

		' if pick mode is sphere or box then update collision info object to include entity radius/box info
		If coll_method=COLLISION_METHOD_BOX
			
			CollisionBoxSetup(ent, src_radius, coll_obj)
			
		Elseif coll_method=COLLISION_METHOD_SPHERE
	
			CollisionSphereSetup(ent, src_radius, coll_obj)
			
		Elseif coll_method=COLLISION_METHOD_POLYGON
			
			CollisionTriangleSetup(ent, src_radius , coll_obj) 'dst_radius+src_radius? for box
		
		Elseif coll_method=COLLISION_METHOD_POLYGON_AABB
			
			CollisionTriangleSetup(ent, src_radius , coll_obj) 'dst_radius+src_radius? for box
		
		Elseif coll_method=COLLISION_METHOD_AABB  
			
			CollisionAABBSetup(ent, src_radius, coll_obj)
			
				
		Endif
		
		
	End
	
	Method CreateCollLine:Void( li:Line, ent:TEntity, mat:Matrix, offset2:Vector )
		''handle divSphere offsets
		
		'li.Update(coll_line.o.x,coll_line.o.y,coll_line.o.z, coll_line.d.x,coll_line.d.y,coll_line.d.z)
		
		If coll_method =COLLISION_METHOD_POLYGON Or coll_method = COLLISION_METHOD_BOX Or coll_method = COLLISION_METHOD_POLYGON_AABB
			tf_offset.Overwrite(-ent.mat.grid[3][0],-ent.mat.grid[3][1],ent.mat.grid[3][2] )
			'tf_offset.Overwrite(-ent.mat.grid[3][0]+src_divSphere.offset.x,-ent.mat.grid[3][1]+src_divSphere.offset.y,ent.mat.grid[3][2]-src_divSphere.offset.z )
			'coll_line.o.Add(src_divSphere.offset)
			
			li.Update( coll_line )

			'li.o = tform.m.Multiply(li.o.Add(tf_offset).Add(src_divSphere.offset))
			Vec3.Add(li.o,tf_offset,li.o) ; Vec3.Add( li.o, src_divSphere.offset, li.o)
			Vec3.Multiply( li.o, tform.m, li.o)
			'li.d = tform.m.Multiply(li.d)
			Vec3.Multiply( li.d, tform.m, li.d )
		
	
		Else

			tf_offset.Overwrite(ent.mat.grid[3][0],ent.mat.grid[3][1],-ent.mat.grid[3][2] ) ''this is ent2 center
			'li.Update( coll_line.Add(offset2) )
			'coll_line.o.Add(src_divSphere.offset)
			
			'li.o.Overwrite(coll_line.o.Add(src_divSphere.offset) )
			Vec3.Add( src_divSphere.offset, coll_line.o, li.o )
			li.d.Overwrite(coll_line.d)

			'li.o = tform.m.Multiply(li.o)
			'li.d = tform.m.Multiply(li.d)
			
		Endif
		
	End
	
	''takes info, returns box
	Method CreateCollBox:Void(box:Box, li:Line, radius:Float, scale:Vector)

		box.Clear() ''sets to infinity
		box.Update(li.o)
		
		''slight offset
		radius = (radius) *1.001 
		
		'' include the max and min radius of dest
		Local delta:Vector = t_vec
		delta.Update(li.o.x+li.d.x+radius,li.o.y+li.d.y+radius,li.o.z+li.d.z+radius)
		box.Update(delta)'.Subtract(src_divSphere.offset))
		delta.Update(li.o.x+li.d.x-radius,li.o.y+li.d.y-radius,li.o.z+li.d.z-radius)
		box.Update(delta)'.Subtract(src_divSphere.offset))

		'box.a = box.a.Multiply(inv_scale)
		box.a.x *=scale.x;box.a.y *=scale.y;box.a.z *=scale.z
		'box.b = box.b.Multiply(inv_scale) 
		box.b.x *=scale.x;box.b.y *=scale.y;box.b.z *=scale.z
				
	End
	
	
	Method CollisionSphereSetup(ent:TEntity, radius:Float, coll_obj:CollisionObject)
			
		''make sure to clear dst_entity per cycle
		If dst_entity<>ent
			dst_divSphere.RotateDivSpheres(ent, Self, True) ''need to inverse the dst matrix
		Endif
		dst_entity = ent

	End
	
	Method CollisionBoxSetup(ent:TEntity, radius:Float, coll_obj:CollisionObject)
				
		''** tf_box is the dst_box
		tf_box.Clear()
		tf_box.a.Overwrite(ent.collision.box_x,ent.collision.box_y,ent.collision.box_z)
		tf_box.Update(New Vector(ent.collision.box_x+ent.collision.box_w,ent.collision.box_y+ent.collision.box_h,ent.collision.box_z+ent.collision.box_d))
		tf_box.Scale( tf_scale ) ''ent scale
		
'CreateTestBox( tf_box.a.Add(ent.X,ent.Y,ent.Z), tf_box.b.Add(ent.X,ent.Y,ent.Z))		
'Print "tfbox whd "+tf_box.Width()+" "+tf_box.Height()+" "+tf_box.Depth()		
		'coll_obj.time = tf_line.d.Add(tf_radius).DistanceSquared()+radius
	
	End
	
	Method CollisionAABBSetup(ent:TEntity, radius:Float, coll_obj:CollisionObject)
		
		tf_line = New Line(coll_line.o,coll_line.d)
		''** tf_box is the dst_box, and offset it
		tf_box.Clear()
		Local xx:Float = ent.mat.grid[3][0]
		Local yy:Float = ent.mat.grid[3][1]
		Local zz:Float = -ent.mat.grid[3][2]
		tf_box.a.Overwrite(ent.collision.box_x,ent.collision.box_y,ent.collision.box_z)
		tf_box.Update(New Vector(ent.collision.box_x+ent.collision.box_w,ent.collision.box_y+ent.collision.box_h,ent.collision.box_z+ent.collision.box_d))
		
		tf_box.Scale( tf_scale ) ''ent scale
		tf_box.a.x += xx-radius; tf_box.a.y += yy-radius; tf_box.a.z += zz-radius
		tf_box.b.x += xx+radius; tf_box.b.y += yy+radius; tf_box.b.z += zz+radius
		'tf_box.a.x += xx; tf_box.a.y += yy; tf_box.a.z += zz
		'tf_box.b.x += xx; tf_box.b.y += yy; tf_box.b.z += zz
		
'CreateTestBox( tf_box.a.Multiply(1), tf_box.b.Multiply(1))		

	End
	
	Method CollisionTriangleSetup(ent:TEntity, radius:Float, coll_obj:CollisionObject)
		''coll_time is set in main routine to account for multiple object collisions
		
		
		Local mesh:TMesh = TMesh(ent)
		If mesh<>Null	
			mesh_coll = mesh.col_tree.CreateMeshTree(mesh) ' create collision tree for mesh if necessary
		Endif

		'' bounding box is in local ent space, setup tf_box
		CreateCollBox(tf_box, tf_line, radius, inv_scale)
		'tf_radius.Overwrite( src_radius,src_radius,src_radius)

'Local entsc:Vector = New Vector(ent.gsx, ent.gsy, ent.gsz)
'CreateTestBox(renew2.Multiply(tf_box.a.Multiply(entsc)).Subtract(tf_offset),renew2.Multiply(tf_box.b.Multiply(entsc)).Subtract(tf_offset))
'CreateTestLine(tf_line.o.Subtract(tf_offset), (tf_line.o.Add(tf_line.d)).Subtract(tf_offset))

		
		
		If radius = 0.0
		
			''setup ray for pick
			tf_radius.x = 0.0
			mesh_coll.RayBoxSetup( New Line( tf_line.o.Multiply(inv_scale) , tf_line.d.Multiply(inv_scale)) ) ''may need new line with radoffset		
			
		Endif
		

	End


	



	Method CollisionDetect:Int(coll_obj:CollisionObject)
		
		Local res:Int=0
		

		Select ( coll_method )
	
			Case COLLISION_METHOD_SPHERE
		
				If dst_divSphere.num > 1
					Local hit:Int=0
					
					''must check all hits
					For Local i:Int = 0 To dst_divSphere.num-1
					
						dst_radius = dst_divSphere.rad[i]
						hit += coll_obj.SphereCollide( tf_line,src_radius,tf_offset.Add( dst_divSphere.pos[i].x, dst_divSphere.pos[i].y, dst_divSphere.pos[i].z ),dst_divSphere.rad[i], nullVec )

'Print "dvs "+src_radius+"  "+dst_divSphere.rad[i]
					Next
					If hit>0 Then res=1
					
				Else
				
					res = coll_obj.SphereCollide( tf_line,src_radius,tf_offset,dst_radius, nullVec) 'src_divSphere.offset )
'CreateTestLine(tf_line.o,tf_line.o.Add(tf_line.d),255,200,200)
				
				Endif
				
				If res
'debug Normals
'CreateTestLine(coll_obj.col_coords, coll_obj.col_coords.Add(coll_obj.normal.Multiply(0.8)), 100,0,100 )

				Endif
				'radius = 0.0
				
				
			Case COLLISION_METHOD_POLYGON
			
				'' Local coords

'CreateTestBox(renew2.Multiply(tf_box.a).Subtract(tf_offset),renew2.Multiply(tf_box.b).Subtract(tf_offset))
				
				If mesh_coll.CollideNodeAABB( tf_box, tf_radius, coll_obj, mesh_coll.tree )
'Print "AABB collide "+tf_radius	
'CreateTestLine( renew2.Multiply(tf_line).Subtract(tf_offset).o, renew2.Multiply(tf_line).Subtract(tf_offset).o.Add( renew2.Multiply(tf_line).d ))
		
					res = mesh_coll.TriNodeCollide( tf_box, tf_line, tf_radius, coll_obj, tf_scale )
				
					''adjust normal to original ent. matrix
					If res
'Print "Tri collide "
						coll_obj.normal = renew2.Multiply(coll_obj.normal)'.Normalize()
						
						''convert col_coords back to world space
						coll_obj.col_coords = renew2.Multiply(coll_obj.col_coords ).Subtract(tf_offset)

'Print hits+" "+coll_obj.time+":"+starttime		
					Endif
				Endif
	
			Case COLLISION_METHOD_POLYGON_AABB
						
				If mesh_coll.CollideNodeAABB( tf_box, tf_radius, coll_obj, mesh_coll.tree )

					res = mesh_coll.TriNodeCollide( tf_box, tf_line, tf_radius, coll_obj, tf_scale, true )
				
					''adjust normal to original ent. matrix
					If res

						coll_obj.normal = renew2.Multiply(coll_obj.normal)'.Normalize()
						
						''convert col_coords back to world space
						coll_obj.col_coords = renew2.Multiply(coll_obj.col_coords ).Subtract(tf_offset)	
					Endif
				Endif
			
				
			Case COLLISION_METHOD_BOX
				''local coords
'CreateTestLine( renew2.Multiply(tf_line).Subtract(tf_offset).o, renew2.Multiply(tf_line).Subtract(tf_offset).o.Add( renew2.Multiply(tf_line).d ))
'Print tf_scale		
				If( coll_obj.SphereBox( tf_line, tf_radius, tf_box, tf_scale ) ) ''BoxCollide( ~t*line,radius,box )
'Print "BOX HIT "				
					coll_obj.normal=renew2.Multiply(coll_obj.normal) '.Normalize()
					'coll_obj.normal=coll_obj.normal
					res = True
					
					'coll_obj.col_coords=coll_line.Multiply(coll_obj.time)'.Subtract(tf_offset)
					coll_obj.col_coords = renew2.Multiply(coll_obj.col_coords ).Subtract(tf_offset)
					
					'RegisterHitPlane ( coll_obj.col_coords, coll_obj.normal)
			
				Endif

				'radius = 0.0
			
			
			'' *** just do a line-AABB test for now
			Case COLLISION_METHOD_AABB
				
				If tf_box.Overlaps(tf_line.o.Add(tf_line.d)) Or tf_box.Overlaps(tf_line.o)
					res = 1
					coll_obj.col_coords.Overwrite(tf_line.o.Add(tf_line.d))
					coll_obj.time = 0.1
					'Print 123
				Else
					Local midvec:Vector = tf_line.o.Add(tf_line.d.Multiply(0.5))
					If tf_box.Overlaps(midvec)
						res = 1
						coll_obj.col_coords.Overwrite(midvec)
						coll_obj.time = 0.05
						'Print 234
					endif
				Endif

				If res
					Local norm:Vector
					Local cen:Vector = tf_box.Center()
					Local nx# = Abs(tf_line.d.x)
					Local ny# = Abs(tf_line.d.y)
					Local nz# = Abs(tf_line.d.z)
					
					If nx>ny And nx>nz
						norm = New Vector(-Sgn(tf_line.d.x),0,0)
						'coll_obj.col_coords = New Vector((cen.x+tri_box.Width())*norm.x*scalef.x,line.o.y,line.o.z)
					Elseif ny>nx And ny>nz
						norm = New Vector(0,-Sgn(tf_line.d.y),0)
						'coll_obj.col_coords = New Vector(line.o.x, (cen.y+tri_box.Height())*norm.y*scalef.y,line.o.z)
					Elseif nz>nx And nz>ny
						norm = New Vector(0,0,-Sgn(tf_line.d.z))
						'coll_obj.col_coords = New Vector(line.o.x, line.o.y, (cen.z+tri_box.Depth())*norm.z*scalef.z)
					Else
						norm = New Vector(-Sgn(tf_line.d.x),-Sgn(tf_line.d.y),-Sgn(tf_line.d.z))
						'coll_obj.col_coords = line.o
					Endif
					
					coll_obj.normal= norm
					'coll_obj.col_coords=coll_line.Multiply(coll_obj.time)
				
					'RegisterHitPlane ( coll_obj.col_coords, coll_obj.normal)
					
				Endif
				'radius = 0.0
		End

''SHOW NORMALS	
'If res
'CollisionInfo.test_vec = coll_obj.col_coords.Copy()
'CreateTestLine(coll_obj.col_coords, coll_obj.col_coords.Add(coll_obj.normal.Multiply(0.2)), 100,0,100 )
'Endif
		
		Return res
	End
	
	
	
	Method DivSpheresCollisionDetect:Int( ent:TEntity, ent2:TEntity, c_method:Int, coll_obj:CollisionObject )
		
		coll_method = c_method
		
		Local mesh:TMesh = TMesh(ent)
		If (Not mesh) Then Return
		
		Local hit%=0, total:Int = src_divSphere.num
		Local skip:Bool = False
		
		Local line_o:Vector = coll_line.o.Copy()
		Local line_d:Vector = dv.Copy()
		
		Local temp_radius:Float = src_radius
		Local finalNormal:Vector = New Vector()
		Local finalCoord:Vector = New Vector()
		Local finalRad:Float = 0.0
		Local finalDiv:Vector = New Vector()
		Local finalPos:Vector = New Vector()
		Local ctime#=99999.0
		
		

		For Local i:Int = 0 To total-1
			
			
			'coll_line.o.Overwrite(line_o)
			
			Local hh:Int =0
			
			src_radius = src_divSphere.rad[i]*1.001
			src_divSphere.offset.Overwrite(src_divSphere.pos[i].x,src_divSphere.pos[i].y,src_divSphere.pos[i].z)

			
			'If CollisionObject.QuickBoundsTest2(col_info, ent2)
'Print "hittest "+i					

				CollisionSetup(ent2, c_method, coll_obj, nullVec, skip) ''dont' skip on first pass to get tform mat
				
				hh = CollisionDetect( coll_obj )
				

				If hh And (coll_obj.time < ctime)
					ctime = coll_obj.time
					
					'Print "hit "+i+" "+coll_obj.time+"  "+src_radius+"  .."+src_divSphere.offset
					
					finalNormal = coll_obj.normal.Copy()
					'finalNormal = finalNormal.Add(coll_obj.normal)
					finalCoord = coll_obj.col_coords.Copy() '.Subtract( finalDiv ) ''gives a good col_coord, but no sliding.
					finalRad = src_divSphere.rad[i]
					finalDiv = src_divSphere.offset.Copy()
					finalPos = coll_obj.col_pos.Copy()
					
					hit = 1
				Endif
				
			'Endif

			
			skip = True
			'If hit Then Exit
			
		Next
	
		
		If hit>0
		
			hit=1
			coll_obj.normal = finalNormal
			coll_obj.col_coords = finalCoord '
			'src_radius = finalRad ''old way
			hitDivRadius = finalRad
			src_divSphere.offset = finalDiv
			hitDivOffset.Overwrite(finalDiv)
			coll_obj.time = ctime

		Endif
		
		src_radius = temp_radius ''set radius back
		
		Return hit
		
	End
	
	
	
	
	
	'' Physics
	
	Method RegisterHitPlane:Void(coords:Vector, normal:Vector)
				
		hits +=1
		If hits>4 Then Return
		
		'n_hit = hits-1
		If n_hit>4 Then Return
		
		planes[n_hit] = New Plane( coords, normal)
		col_points[n_hit] = coords.Copy()
		n_hit+=1

'If n_hit>1
	'CreateTestLine(coords, coords.Add(normal.Multiply(0.2)), 100,0,100 )
'Endif
	
	End
	
	
	
	Method CollisionResponse:Int(col_obj:CollisionObject,response:Int, radius:Float)
		''notes: needed a copy for dv and sv when assigning, but not so with local vectors
		
		'' let's not worry about time here, and work only with collision point

		
		If( hits>=MAX_HITS  ) Return False
		'If (Abs(dv.x-sv.x)< EPSILON) And Abs(dv.y-sv.y)< EPSILON And Abs(dv.z-sv.z)< EPSILON Then dv.Overwrite(sv); Return False
		
		Local new_offset:Vector = col_obj.normal.Multiply(radius*1.001) ''this seems to give a far enough distance away.
		Local new_coords:Vector = col_obj.col_coords.Add(new_offset).Subtract(hitDivOffset)

'Print "n "+col_obj.normal+"  "+hits
'Print "divSphereOff "+hitDivOffset+" .."+src_radius+" time:"+coll.time
'Print "new coord:"+new_coords
'CreateTestLine(sv, dv, 255,0,0)
'CreateTestLine(new_coords, new_coords.Add(col_obj.normal.Multiply(src_radius)), 0,255,0)
		
		'If y_scale<>1.0 Then new_coords.y *= y_scale
		
		
		Local coll_plane:Plane = New Plane( new_coords,col_obj.normal )

		
'Print "coll_time "+coll.time+"  res:"+response+" colnorm:"+coll.normal.ToString+" rad:"+src_radius
		
		Local adv:Vector = dv.Copy().Add(new_offset) ''** this helped smooth collisions

	
		If ( response=COLLISION_RESPONSE_STOP )
			dv.Overwrite(sv)
			Return False 
		Endif


		
		sv.Overwrite(new_coords )

		''find nearest point on plane To dest
		Local nv:Vector =coll_plane.Nearest( adv )
		
'Print "sv "+sv+"  dv "+dv+"~n nc "+new_coords+" nv "+nv
'CreateTestLine(new_coords, nv, 200,255,200 )

		'' multiple plane hits
		
		If ( n_hit>0 And n_hit<4)


				''-- take the last plane hit and avg, this becomes the next plane hit
				''-- accumulate and average the normals
				Local pn2:Vector = coll_plane.n.Add(planes[n_hit-1].n).Multiply(0.5).Normalize()
				Local c2:Vector = col_obj.col_coords.Add(col_points[n_hit-1]).Multiply(0.5)
				Local pl2:Plane = New Plane(c2.Add(new_offset.Multiply(1.001)).Subtract(hitDivOffset),pn2)
				'pl2.d +=0.0001
				nv=pl2.Nearest(adv)
				col_obj.normal = pn2
				col_obj.col_coords = c2
				'nv=nv.Add(pn2.Multiply(0.01))
'Print ":: n_hit"+n_hit+"  "+pn2
'CreateTestLine(nv, nv.Add(pn2.Multiply(0.2)), 0,100,0 )
		Else If (n_hit>3)
				'' extend the accumulated normal
				nv = sv.Add(col_obj.normal.Multiply(0.001))
				col_obj.col_coords = col_obj.col_coords.Add(col_obj.normal.Multiply(0.001))


#rem		
			Local plane_norms# = planes[n_hit-1].n.Dot( coll_plane.n )
'Print n_hit	
			If( planes[n_hit-1].Distance(nv)> radius )
				n_hit=0
			Endif
			

			
			If( False) 'n_hit=1 )


				If plane_norms < -0.999
					''SQUISHED! planes are parallel
					hits=MAX_HITS
					dv.Overwrite(sv)
					Return False
					
				'Elseif( Abs( plane_norms  ) < 1.0-EPSILON )
				Elseif (plane_norms < 1.0-EPSILON)
					Print plane_norms
					''v-shape
					'nv=coll_plane.Intersect( planes[0] ).Nearest( dv )
					Local p2:Vector = coll_plane.n.Add(planes[0].n).Multiply(0.5)
					Local c2:Vector = coll.col_coords.Add(col_points[0]).Multiply(0.5)
					Local pl2:Plane = New Plane(c2,p2)'; pl2.d-=0.001
					nv=pl2.Nearest(dv)
					'nv=nv.Add(p2.Multiply(0.1))
'Print ":: n_hit1 "+nv	
'CreateTestLine(nv, nv.Add(p2.Multiply(0.2)), 0,100,0 )
					'n_hit=0
				Else
					n_hit=0
					
				Endif
			Elseif( n_hit=2 And plane_norms < 1.0-EPSILON)
'Print "nhit=2 "+plane_norms
				Local p2:Vector = coll_plane.n.Add(planes[1].n).Multiply(0.5)
					Local c2:Vector = coll.col_coords.Add(col_points[1]).Multiply(0.5)
					Local pl2:Plane = New Plane(c2,p2)'; pl2.d-=0.001
					nv=pl2.Nearest(dv)
					'n_hit=0
					'Return False
			Elseif( n_hit>2 And plane_norms <0.0 )
'Print "nhit>2 "+plane_norms
				nv.Overwrite(sv)
				n_hit=0
				hits=MAX_HITS

			Endif

#end
			
'test_dot.Overwrite(nv)
'Print " cv "+cv.ToString()	
'CreateTestLine(cv, cv.Add(nn), 200,0,200 )
	
	
		Endif

		

		
		Local dd:Vector = nv.Subtract(adv)

'Print "dd "+dd.ToString+"   sv "+sv.ToString+"  nv "+nv.ToString

		
		'' -- apparently, NV gives a correct response
		Local d:Float=dd.Dot(dd)
		If  d< EPSILON Then dv.Overwrite(sv); Return False
		
		If( response = COLLISION_RESPONSE_SLIDE )
	
		Elseif( response = COLLISION_RESPONSE_SLIDEXZ )

			nv.Overwrite( nv.x, coll_line.o.y, nv.z)
			sv.y = coll_line.o.y
			'adv.y = coll_line.o.y
			
		Endif
		
		'coll_line.d.Overwrite(dv.Subtract(nv).Subtract(sv))
		'' since we are going back to test more collisions, need to update the coll_line
		dv.Overwrite(nv)
		coll_line.o.Overwrite(sv)
		coll_line.d.Overwrite(dv.Subtract(sv)) '' length, from o
		
'CreateTestLine(sv, dv, 255,0,255)								
'Print "final dv :"+dv.ToString() +"   sv:"+sv.ToString()
		
	
		Return True
		
	End


	Method CollisionFinal:Bool(coll:CollisionObject, response:Int)
	
		If (response = COLLISION_RESPONSE_NONE) Then Return False

		If( hits )

			If( hits<MAX_HITS )
				dv.y *= inv_y_scale
				coll.col_pos.Overwrite(dv  )
				

			Else

				coll.col_pos.Overwrite(panic)
				
			Endif
			Return True
		Endif
		
		Return False
		
	End
	


	
End





Class CollisionObject
	
	Const ONETHIRD:Float = 1.0/3.0
	Const SQRT2:Float = 1.4142135623
	
	Global BOXQUADS:Int[]=[
			2,3,1,0,
			3,7,5,1,
			7,6,4,5,
			6,2,0,4,
			6,7,3,2,
			0,1,5,4 ]
	
	Field time:Float = 99999999.0 ''we use dst_squared
	Field normal:Vector = New Vector()
	Field surface:Int=0
	Field index:Int=0
	
		
	Field coll_u:Float ''uv coords, only polygon coll
	Field coll_v:Float
	
	Field rad2:Float


	Field tform:TransformMat
	'Field dst_matrix:Matrix ''used for dst->col trinode testing
	
	Field col_coords:Vector = New Vector()
	Field col_normal:Vector = New Vector()
	Field col_time:Int
	Field col_surface:Int
	Field col_index:Int
	Field col_pos:Vector = New Vector()
	Field col_box:Box = New Box()
	
	Field obj_time#
	
	Global test2:Vector = New Vector()
	Global test3:Vector = New Vector()
	'Global renew:Matrix
	'Global scale2:Vector = New Vector()
	'Global tf_offset:Vector = New Vector()
	Global trip:Int=0
	
Private
	
	Field int_vec:Vector = New Vector() ''temp intersection vec
	Global r_box:Box = New Box
	Global e_box:Box = New Box
	Global t_vec:Vector = New Vector()
	Global t_vec2:Vector = New Vector()
	Global t_mat:Matrix = New Matrix()
	Global t_line:Line = New Line()
	
Public
	
	Method Clear:Void()
		time = 99999999.0 ''we use dst_squared
		normal = New Vector()
		surface=0
		index=0
		obj_time=0.0
		col_coords = New Vector()
		col_normal = New Vector()
		col_time=0
		col_surface=0
		col_index=0
		col_pos = New Vector()
		col_box = New Box()
	End
	
	
	Method Update:Int( line:Line,t:Float, n:Vector, u#=0.0, v#=0.0, intersect:Vector=Null )
		
		If( t>time ) Return 0 ''need the closest intersection

		Local p:Plane

		If intersect
			
			'' define col_coords here, to manage triangle-plane collisions properly
			'' col_coords is closest point to triangle plane (in triangle space)

			'col_coords = intersect 'tplane.Nearest( line.o.Add(line.d.Multiply(t)) )
			p = New Plane(intersect,n) 'tplane

		Else
		
			p = New Plane(line.Multiply(t),n)
			If ( (p.n.Dot(line.o) + p.d ) < -COLLISION_EPSILON ) Return 0 ''starts behind plane
			
		Endif
		
			
		If( p.n.Dot( line.d )> -COLLISION_EPSILON ) Return 0 ''moving away from plane
		'If( p.Distance(line.o)< -COLLISION_EPSILON ) Return 0
		'If ( (p.n.Dot(line.o) + p.d ) < -COLLISION_EPSILON ) Return 0 ''starts behind plane
		
'Print "> UPDATE "+t

		If intersect Then col_coords.Overwrite(intersect)
		time=t
		normal.Overwrite(n)
		coll_u = u
		coll_v = v
		
		Return 1
		
	End

	'' sphere-sphere, approx 5 mults
	Function QuickBoundsTest:Bool(col:CollisionInfo, ent2:TEntity)
		
		'' radius+radius to include ray origin radius as well as dest radius
		Local ds:Float = col.ray_length*0.5+col.src_radius+col.src_radius + col.dst_radius ''cant do distsqu here, c*c+d*d != (c+d)*(c+d)

		Return (col.dst_pos.DistanceSquared(col.ray_center)<ds*ds)
		
	End
	
	'' box, may need to be scaled to work properly
	Function QuickBoundsTest2:Bool(col:CollisionInfo, ent2:TEntity)
		Local ray:Line = col.coll_line.Add( col.src_divSphere.offset )
		Local radius:Float = col.src_radius

		r_box.Clear()
		r_box.Update(ray.o)
		r_box.Update(ray.o.Add(ray.d))
		r_box.Expand(radius+radius)
		
		e_box.Clear()
		
		Local r:Float = col.dst_radius
		'If r<ent2.collision.radius_y Then r=ent2.collision.radius_y +radius
		t_vec.Update(ent2.mat.grid[3][0],ent2.mat.grid[3][1],-ent2.mat.grid[3][2])
		e_box.Update(t_vec.Add( col.dst_divSphere.offset ))
		e_box.Expand(r+r+0.001)
		't_vec.Update(r,r,r)
		'e_box.Update(t_vec)
		't_vec.Update(-r,-r,-r)
		'e_box.Update(t_vec)
		
		
		Return r_box.Overlaps(e_box)
		
	End

	'' TODO
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

	



	''
	''Line to Sphere Intersection (or Sphere Sweep)
	''
	Method SphereCollide:Int ( line:Line, s_radius:Float, dest:Vector, d_radius:Float, offset2:Vector )

'Print "rad "+s_radius+" "+d_radius+"  "+(s_radius+d_radius)
'Print (line.o.Add(line.d).Distance(dest))
'Print "line "+line.o.Add(offset2)+" ..."+line.d
'Print "dest  "+dest

		Local radius# = (s_radius+d_radius)
		
		Local dd:Vector = dest.Subtract(line.o)
		Local ld:Vector = line.d.Normalize()
		
		
		Local b:Float=ld.Dot(dd)	
'Print "!! "+b
		If b<0.0 Then Return 0
		
		
		Local c:Float = dd.Dot(dd)
		Local d:Float=b*b-c+radius*radius
		If( d<0.00001 ) Return 0
		
'Print "!!! "+c+"    "+(b)+"   d "+(d)+"  "+(radius)
		
		d = Sqrt(d)
		Local f1:Float = (-b+d)
		Local f2:Float = (-b-d)

		Local f:Float = f1
		If f2>f1 Then f=f2
		
'If f<0 Then Return 0
'Print "!!!! "+f+"  "+ld		
		'ld= ld.Normalize()
		Local i:Vector = ld.Multiply( -f ) ''intersection
		Local t# = i.DistanceSquared()
		
'Print "time "+time	+" >  "+(t)
		
		
		If t>time Then Return 0
		
'Print f+" : "+t+" "+(radius*radius)	+"  "+line.d.DistanceSquared()+"  "+(c-(ld.Multiply( -f ).DistanceSquared()))

		Local hh:Int=0
		'If i.DistanceSquared(dest) <radius*radius Then hh=1 ''inside of sphere
		If t > line.d.DistanceSquared() And hh=0  Then Return 0  ''not moving far enough



		Local nvec:Vector = i.Add(line.o).Subtract(dest).Normalize() '; nvec.x=-nvec.x; nvec.y=-nvec.y; nvec.z = -nvec.z
'Print "hit "+nvec+"   "+t+"  "+i
'Print ""		
'CreateTestLine( i,dest,0,255,0)
	
		Return Update( line,t ,nvec, 0.0,0.0, dest.Add(nvec.Multiply(d_radius)) )
		
	End
	




	
	
	Method SphereBox:Int( li:Line, s_radvec:Vector, box:Box, scale:Vector)
		''box will be scaled ahead of time
	
		Local hit:Int= 0
		
		'If Not line_box.Overlaps(box) Then Return 0 ''we've already established the AABB
		
		'box.a = box.a.Multiply(scale)
		'box.b = box.b.Multiply(scale)
				
		For Local n:Int =0 To 23 Step 4  ''6 planes

			Local v0:Vector = box.Corner( BOXQUADS[n] )'.Multiply(scale)
			Local v1:Vector = box.Corner( BOXQUADS[n+1] )'.Multiply(scale)
			Local v2:Vector = box.Corner( BOXQUADS[n+2] )'.Multiply(scale)
			Local v3:Vector = box.Corner( BOXQUADS[n+3] )'.Multiply(scale)
			
			hit = hit | SphereTriangle( li, s_radvec,  v0,v1,v2) | SphereTriangle( li, s_radvec,  v0,v2,v3)
			
		Next
		
		If hit Then col_box = box.Copy()
		
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
		
		''radius = sourse radius
		
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
'Print "li.o "+li.o+"  "+o_len
		
		i = (li.o.Subtract( n.Multiply(o_len) )) ''nearest point in plane
		Local o_radius# = i.DistanceSquared(li.o) 
		'Local o_radius# = n.Multiply(src.Dot(n)).DistanceSquared() 'n.Multiply(o_len).DistanceSquared() ''distsq from plane to li.o

		Local diff# = o_radius-n_radius

		If diff>time Then Return 0 ''**** EXPERIMENTAL SPEEDUP *****
		
'Print diff+" .. "+(-n_radius)
		If (diff<0.0) And (diff>(-n_radius-0.000001)) '(-n_radius*0.5))

			''hit plane without moving (li.o)	
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
			Local b2# = b + (Sgn(b)*nr)
			
			Local r2# = 0.0
			If b2 =0.0 Then Return 0
		
			r2 = a/b2

			If r2<0.0 Or r2>1.0 Then Return 0
			
			ix = li.o.Add(li.d.Multiply(r2))
			i = ix.Subtract( n.Multiply(ix.Subtract(v0).Dot(n)) ) ''project onto plane
			'i = li.o.Add(li.d.Multiply( a/b ))	
			'''i = li.o.Add(ix)
			
			r = li.o.DistanceSquared(ix) 'i.Subtract(li.o).DistanceSquared()	
			
		Endif	
		
			
		''exit early for distant triangles
		If r > time Then Return 0


		'' is I inside T?
				
		Local uu#, uv#, vv#, wu#, wv#, D#
		uu = u.Dot(u)
		vv = v.Dot(v)
		
		w = i.Subtract(v0)
		
		'' ** this may not be mathmatically legal **
		'' early rejection for i-extents outside of triangle

		If (w.x > 0.0) And (w.y > 0.0) And (w.z > 0.0) And
			(w.x > u.x) And (w.y > u.y) And (w.z > u.z) And
			(w.x > v.x) And (w.y > v.y) And (w.z > v.z) Then Return 0
		If (w.x < 0.0) And (w.y < 0.0) And (w.z < 0.0) And
			(w.x < u.x) And (w.y < u.y) And (w.z < u.z) And
			(w.x < v.x) And (w.y < v.y) And (w.z < v.z) Then Return 0
			
		uv = u.Dot(v)
		wu = w.Dot(u)
		wv = w.Dot(v)
		D = 1.0 / (uv * uv - uu * vv)

	
		'' get And test parametric coords ''added in radius adjustment for s/t test
		Local s#, t#, out%=0, bb:Vector
		
		s = (uv * wv - vv * wu) * D
		If (s < 0.0 Or s > 1.0)
			'' I is outside T
			out=1
		Endif


		t = (uv * wu - uu * wv) * D
		
		If (t < 0.0 Or (s + t) > 1.0 ) ''*** could have made t< -0.05 for smoother poly to poly transitions
			'' I is outside T
			out=out+1	
		Endif
	
		''edge test
	
		If out>0 And tf_radius.x 'And Not beneath


			If s+t>1.0
				bb = ix.PointOnSegment(v1,v2)
			Elseif t<0.0
				bb = ix.PointOnSegment(v0,v1)
			Else
				bb = ix.PointOnSegment(v0,v2)
			Endif

'test3 = CollisionObject.renew.Multiply(bb) '.Copy()

			Local nr# = ix.DistanceSquared(bb)*1.001 'li.o.DistanceSquared(bb)
'Print ( nr)+" .. "+(n_radius+n_radius*0.05)+"  .. time:"+time
			Local offset# = 0.0'n_radius*0.001

			If (nr > n_radius+offset) Or ( nr>time ) Then Return 0
			
	
			r = nr-offset 'ix.DistanceSquared(bb)
			
			Local ld:Vector = li.d.Multiply(0.1) '' move the normal slightly in the direction of movement
			
			n = (ix.Subtract(bb)).Normalize() ''nice for edge
			bb = bb.Subtract(n.Multiply(0.01)) ''move the i point back
			'n = li.o.Subtract(bb).Normalize()
			'i=bb.Subtract(n.Multiply(tf_radius.x*0.03)) ''softens edges
			i = bb
			
'Print "BENEATH "+Int(beneath)
'Print "*** EDGEHIT "+bb+"  i: "+i+"  r:"+r


		Elseif out>0
			
			Return 0
			
		Endif

'If beneath And out=0 Then Print "beneath "+r	
'Print "TRIHITTIME "+r+" time:"+time+" s "+s+"  t "+t		
'Print "COLCOORDSONTRI "+i.ToString()
		
		Return Update( li, r, n, s ,t, i )
		                 
	End
	
	
	Method RaySphereTest:Int(ray:Vector, dst:Vector, radius:Float)
		'' not exact
		'' -- ray must be normalized (infinite)
		'' -- dst is relative to ray origin
		'' return a INT distance squared>1 (for rough coll_time)

		Local c:Float = ray.Cross(dst).DistanceSquared()
		
'Print (radius*radius)+" .. c:"+c

		If c < radius*radius Then Return Int(c+1.0)
		Return 0
	End
	
	
	Method SpherePlane:Int(li:Line, radius:Float, v0:Vector, norm:Vector)
		
		''sphere plane/ ray plane collision
		Local r:Float, ix:Vector, a:Float, b:Float

		Local src:Vector = li.o.Subtract(v0)
		Local n_radius# = radius*radius
		
		Local o_len# = norm.Dot(src)
		
		If o_len < 0.0 Then Return 0  '' quick opposite direction check
		
		Local i:Vector = (li.o.Subtract( norm.Multiply(o_len) )) ''nearest point in plane
		Local o_radius# = i.DistanceSquared(li.o) 
		'Local o_radius# = n.Multiply(src.Dot(n)).DistanceSquared() 'n.Multiply(o_len).DistanceSquared() ''distsq from plane to li.o
		Local diff# = o_radius-n_radius
'Print "lio "+li.o+"   li.d "+li.d+"  o_rad "+o_radius+"  diff "+diff+"~n nrad "+n_radius+"   n "+n	
	

		If (diff<0.0) And (diff>(-n_radius*0.5))

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
			Local b2# = b + (Sgn(b)*nr)
			
			Local r2# = 0.0
			If b2 =0.0 Then Return 0
		
			r2 = a/b2

			If r2<0.0 Or r2>1.0 Then Return 0
			'If r2<0.0  Then Return 0
			
			ix = li.o.Add(li.d.Multiply(r2))
			i = ix.Subtract( n.Multiply(ix.Subtract(v0).Dot(n)) ) ''project onto plane
			'i = li.o.Add(li.d.Multiply( a/b ))	
			'''i = li.o.Add(ix)
			
			r = li.o.DistanceSquared(ix) 'i.Subtract(li.o).DistanceSquared()	
			
		Endif	
		
			
		''exit early for distant
		If r > time Then Return 0
		
		Return Update( li, r, norm, 0.0 ,0.0, i )
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

Global boxxxxx1:TMesh
Function CreateTestBox(s:Vector,d:Vector)
	If Not boxxxxx1 Then boxxxxx1=CreateCube();boxxxxx1.EntityAlpha(0.2);boxxxxx1.EntityColor(255,0,0);boxxxxx1.EntityFX 1+64
	Local p:Vector = d.Subtract(s)
	boxxxxx1.PositionEntity(s.x+p.x*0.5,s.y+p.y*0.5,s.z+p.z*0.5)
	boxxxxx1.ScaleEntity(Abs(p.x)*0.5,Abs(p.y)*0.5,Abs(p.z)*0.5)
	
End

Global circcc1:TMesh
Function CreateTestSphere(p:Vector,r#)
	If Not circcc1 Then circcc1=CreateSphere();circcc1.EntityAlpha(0.2);circcc1.EntityColor(255,0,0)
	circcc1.PositionEntity(p.x,p.y,p.z)
	circcc1.ScaleEntity(r,r,r)
	circcc1.EntityFX 64
End

Global circcc2:TMesh
Function CreateTestSphere2(p:Vector,r#)
	If Not circcc2 Then circcc2=CreateSphere();circcc2.EntityAlpha(0.2);circcc2.EntityColor(255,0,0)
	circcc2.PositionEntity(p.x,p.y,p.z)
	circcc2.ScaleEntity(r,r,r)
	circcc2.EntityFX 64
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