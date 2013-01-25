''NOTES
'' needs TCollision to be ported over
Import minib3d
Import minib3d.math.geom
Import minib3d.tcollision

Class TPick

	' EntityPickMode in TEntity

	Const EPSILON=.0001
	
	Global ent_list:List<TEntity>=New List<TEntity> ' list containing pickable entities
	

	Global picked_x:Float,picked_y:Float,picked_z:Float
	Global picked_nx:Float,picked_ny:Float,picked_nz:Float
	Global picked_time:Float
	Global picked_ent:TEntity
	Global picked_surface:Int = -1
	Global picked_triangle:Int
	
	Global mat:Matrix=New Matrix
	Global tform:TransformMat = New TransformMat()
	
	Function CameraPick:TEntity(cam:TCamera,vx:Float,vy:Float)
		
		Local vec:Vector
		Local dvec:Vector
		
		vy=cam.viewport[3]-vy

		vec = cam.GluUnProject(vx,vy,0.0,cam)
		
		dvec = cam.GluUnProject(vx,vy,1.0,cam)

		Return Pick(vec.x,vec.y,-vec.z,dvec.x,dvec.y,-dvec.z,0.0)
	
	End 

	Function EntityPick:TEntity(ent:TEntity,range:Float)

		TEntity.TFormPoint(0.0,0.0,0.0,ent,Null)
		Local x:Float=TEntity.TFormedX()
		Local y:Float=TEntity.TFormedY()
		Local z:Float=TEntity.TFormedZ()
		
		TEntity.TFormPoint(0.0,0.0,range,ent,Null)
		Local x2:Float=TEntity.TFormedX()
		Local y2:Float=TEntity.TFormedY()
		Local z2:Float=TEntity.TFormedZ()
		
		Return Pick(x,y,z,x2,y2,z2)

	End 

	Function LinePick:TEntity(x:Float,y:Float,z:Float,dx:Float,dy:Float,dz:Float,radius:Float=0.0)

		Return Pick(x,y,z,x+dx,y+dy,z+dz,radius)

	End 

	Function EntityVisible(src_ent:TEntity,dest_ent:TEntity)

		' get pick values
		
		Local px:Float=picked_x
		Local py:Float=picked_y
		Local pz:Float=picked_z
		Local pnx:Float=picked_nx
		Local pny:Float=picked_ny
		Local pnz:Float=picked_nz
		Local ptime:Float=picked_time
		Local pent:TEntity=picked_ent
		Local psurf:TSurface=picked_surface
		Local ptri=picked_triangle

		' perform line pick

		Local ax:Float=src_ent.EntityX(True)
		Local ay:Float=src_ent.EntityY(True)
		Local az:Float=src_ent.EntityZ(True)
		
		Local bx:Float=dest_ent.EntityX(True)
		Local by:Float=dest_ent.EntityY(True)
		Local bz:Float=dest_ent.EntityZ(True)

		Local pick:TEntity=Pick(ax,ay,az,bx,by,bz)
		
		' if picked entity was dest ent then dest_picked flag to true
		Local dest_picked=False
		If picked_ent=dest_ent Then dest_picked=True
		
		' restore pick values
		
		picked_x=px
		picked_y=py
		picked_z=pz
		picked_nx=pnx
		picked_ny=pny
		picked_nz=pnz
		picked_time=ptime
		picked_ent=pent
		picked_surface=psurf
		picked_triangle=ptri
		
		' return false (not visible) if nothing picked, or dest ent wasn't picked
		If pick<>Null And dest_picked<>True
		
			Return False
			
		Endif
		
		Return True
		
	End 

	Function PickedX:Float()
		Return picked_x
	End 
	
	Function PickedY:Float()
		Return picked_y
	End 
	
	Function PickedZ:Float()
		Return picked_z
	End 
	
	Function PickedNX:Float()
		Return picked_nx
	End 
	
	Function PickedNY:Float()
		Return picked_ny
	End 
	
	Function PickedNZ:Float()
		Return picked_nz
	End 
	
	Function PickedTime:Float()
		Return picked_time
	End 
	
	Function PickedEntity:TEntity()
		Return picked_ent
	End 
	
	Function PickedSurface:TSurface()
		If picked_surface <0 Or Not picked_ent Then Return Null
		Return TMesh(picked_ent).GetSurface(picked_surface)
	End 
	
	Function PickedTriangle()
		Return picked_triangle
	End 


	Global vec_a:Vector =New Vector(0.0,0.0,0.0)
	Global vec_b:Vector =New Vector(0.0,0.0,0.0)
	Global vec_radius:Vector =New Vector(0.0,0.0,0.0)

	Global vec_i:Vector =New Vector(0.0,0.0,0.0)
	Global vec_j:Vector =New Vector(0.0,0.0,0.0)
	Global vec_k:Vector =New Vector(0.0,0.0,0.0)

			
	Global vec_v:Vector =New Vector(0.0,0.0,0.0)
	
	
	' requires two absolute positional values
	Function Pick:TEntity(ax:Float,ay:Float,az:Float,bx:Float,by:Float,bz:Float,radius:Float=0.0)
		
		mat.LoadIdentity()
		
		picked_ent=Null
		picked_time=1.0
		Local pick:Int =False
		
		Local col_obj:CollisionObject = New CollisionObject()
		
		Local line:Line = New Line(ax,ay,az,bx-ax,by-ay,bz-az)
		'Local ray:Vector = New Vector((line.d.x-ax),(line.d.y-ay),(line.d.z-az)).Normalize()
		Local ray:Vector = New Vector((line.d.x),(line.d.y),(line.d.z)).Normalize()	
		Local cen:Vector = New Vector(0,0,0)
		
		''coll ray info setup for pick
		Local col_info:CollisionInfo = New CollisionInfo()
		col_info.dir = ray
		col_info.coll_line = line
		col_info.radius = radius
		col_info.radii = New Vector(radius,radius,radius)
		col_info.y_scale = 1.0

	
		For Local ent:TEntity=Eachin ent_list
		
			If ent.pick_mode=0 Or ent.Hidden()=True Then Continue
			
			''early sphere rejection
			If TMesh(ent)
				''only do this for meshes with cull_radius
				Local rad:Float
				If ent.cull_radius <0 Then rad = -ent.cull_radius*ent.cull_radius + radius Else rad = radius+ent.cull_radius

				'' rad * largest entity global scale
				rad = rad*Max(Max(ent.gsx,ent.gsy),ent.gsz)
				If rad<0 Then rad=-rad
	
				cen.Update(ent.mat.grid[3][0] - ax, ent.mat.grid[3][1] - ay,-ent.mat.grid[3][2] - az)

				If Not col_obj.RaySphereTest(ray,cen, rad) Then Continue
				
				
			Endif
			
			col_info.CollisionSetup(ent, ent.pick_mode, col_obj)
			pick = col_info.CollisionDetect(col_obj)
	
			
			If pick
				picked_ent=ent
				Exit ''do we need to run through the list? yes for multiple objects, but we don't have that capability yet
			Endif
			
		Next
		


		If picked_ent<>Null

			picked_x=col_obj.col_coords.x
			picked_y=col_obj.col_coords.y
			picked_z=col_obj.col_coords.z
			
			picked_nx=col_obj.col_normal.x
			picked_ny=col_obj.col_normal.y
			picked_nz=col_obj.col_normal.z
	
			picked_time=col_obj.col_time
			
			'picked_ent=ent
			If TMesh(picked_ent)<>Null
				picked_surface=col_obj.surface '& $0000ffff
			Else
				picked_surface=-1
			Endif
			picked_triangle=col_obj.index 
	
		Endif
		
		col_obj = Null
		
		Return picked_ent

	End 

End 
