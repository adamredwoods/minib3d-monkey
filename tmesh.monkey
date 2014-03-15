Import minib3d


''Notes

'' - anim_surf now connnect to surface with surf_id
'' -- pre-bake animations which converts bone animation to vertex animation
'' - separated update() and render()
'' -- render() now in TRender.monkey



Class TMesh Extends TEntity
	
	''mesh bounding box
	Field min_x#,min_y#,min_z#,max_x#,max_y#,max_z#

	Field no_surfs:Int=0
	Field surf_list:List<TSurface>= New List<TSurface>
	Field total_tris:Int=0
	
	Field anim_surf:TSurface[] ' contains animated vertex coords set; connected to surf by surf_id
	Field anim_surf_frame:Int[] 'vertex animation frame for specific surf_id
	
	Field no_bones=0
	Field bones:TBone[]

		
	Field col_tree:TColTree=New TColTree

	' reset flags - these are set when mesh shape is changed by various commands in TMesh
	Field reset_bounds=True
	Field center_x:Float,center_y:Float,center_z:Float
	Field bounds_radius:Float '' is this used?
	'Field reset_col_tree=True
	Field vecbounds:Vector[] = New Vector[6]
		
	Field is_sprite:Bool = False '' used for sprites
	Field culled:Bool = False ''is mesh seen by camera
	Field distance_nearplane# ''distance from camera frustum near plane (0 if culled)
	
	Field wireframe:Bool

	Private
	
	Field vec_temp:Vector = New Vector
	
	Public

	Method New()

	
	End 
	
	
	Method CopyEntity:TEntity(parent_ent:TEntity=Null)

		' new mesh
		Local mesh:TMesh=New TMesh
		
		Self.CopyBaseMeshTo(mesh, parent_ent)
		
			
		Return mesh
		
	End
	
	Method CopyBaseMeshTo:Void(mesh:TMesh, parent_ent:TEntity=Null)
		
		Self.CopyBaseEntityTo(mesh, parent_ent) ''this will add to render list


		mesh.is_sprite = is_sprite
		'mesh.is_update = is_update
		mesh.wireframe = wireframe
		
		' copy mesh info
		
		mesh.min_x=min_x
		mesh.min_y=min_y
		mesh.min_z=min_z
		mesh.max_x=max_x
		mesh.max_y=max_y
		mesh.max_z=max_z
		
		mesh.no_surfs=no_surfs
		
		' pointer to surf list
		mesh.surf_list=surf_list
		
		' copy anim surf list, except vertex animation
		If anim=2
			mesh.anim_surf = anim_surf
		Else
			mesh.anim_surf = Self.CopyAnimSurfs()
		Endif
		
		mesh.col_tree=col_tree
	
		mesh.reset_bounds=reset_bounds
		
		mesh.anim_surf_frame = anim_surf_frame[0..] ''copy
		
		mesh.bones = CopyBonesList(mesh, New List<TBone>, 0).ToArray()
		''set bones
		ResetBones()

	End 
	
	'' CopyAnimSurfs()
	'' -- full copy will keep new animation copies instead of pointer
	Method CopyAnimSurfs:TSurface[]( fullcopy:Int =0 ) 
	
		Local new_surf:TSurface[] = New TSurface[no_surfs] 'mesh.anim_surf[surf.surf_id]
		
		
		For Local surf:TSurface=Eachin surf_list
			
			Local id:Int = surf.surf_id
			Local anim_surf2:TSurface = GetAnimSurface(surf) ''original anim_surf shortcut
			If Not anim_surf2 Then Continue
			
					
			' copy vertex, full copy
			new_surf[id] = anim_surf2.Copy()
			
			new_surf[id].no_verts=anim_surf2.no_verts
			
						
			new_surf[id].vert_array_size=anim_surf2.vert_array_size
			new_surf[id].tri_array_size=anim_surf2.tri_array_size
			new_surf[id].vmin=anim_surf2.vmin
			new_surf[id].vmax=anim_surf2.vmax
			
			new_surf[id].surf_id = anim_surf2.surf_id

			new_surf[id].vbo_dyn=anim_surf2.vbo_dyn
			new_surf[id].alpha_enable=anim_surf2.alpha_enable
			
			new_surf[id].reset_vbo=-1 ' (-1 = all)
			
			'' 1=bones, 2=vertanims
			If anim=1 And fullcopy=0
			
				'mesh.anim_surf = New TSurface[no_surfs]
				'Local new_surf:TSurface=New TSurface
				'Local new_surf:TSurface = mesh.anim_surf[surf.surf_id]
				

				'' dont need below, since Copy() method does this
				'new_surf.vert_coords = CopyFloatBuffer(anim_surf2.vert_coords, FloatBuffer.Create(anim_surf2.no_verts*3) )
	
				' pointers to arrays, don't need separate copies unles fullcopy=1
				new_surf[id].tris = anim_surf2.tris
				
				new_surf[id].vert_bone1_no=anim_surf2.vert_bone1_no
				new_surf[id].vert_bone2_no=anim_surf2.vert_bone2_no
				new_surf[id].vert_bone3_no=anim_surf2.vert_bone3_no
				new_surf[id].vert_bone4_no=anim_surf2.vert_bone4_no
				new_surf[id].vert_weight1=anim_surf2.vert_weight1
				new_surf[id].vert_weight2=anim_surf2.vert_weight2
				new_surf[id].vert_weight3=anim_surf2.vert_weight3
				new_surf[id].vert_weight4=anim_surf2.vert_weight4

			
			Elseif anim=2
				
				'mesh.anim_surf = New TSurface[no_surfs]
				'Local new_surf:TSurface=New TSurface
					
				'mesh.anim_surf[surf.surf_id] = anim_surf2.Copy()
				'Local new_surf:TSurface = mesh.anim_surf[surf.surf_id]
				
				new_surf[id].vert_anim = anim_surf2.vert_anim ''pointer to shared anim data
				
			Endif
		
		Next
		
		Return new_surf
		
	End
	
	Method FreeEntity()

		''dont clear surf_list or will clear all entities
		'Print "free mesh "+classname		
		
		''dont clear anim mesh for vertex animation, as it is shared
		If anim<>2 Then anim_surf = New TSurface[0]
		
		bones = New TBone[0]
		
		Super.FreeEntity() 
		
	End 
	
	
	
	Function CreateMesh:TMesh(parent_ent:TEntity=Null)

		Local mesh:TMesh=New TMesh

		mesh.classname="Mesh"
	
		If parent_ent Then mesh.AddParent(parent_ent)
		mesh.entity_link = entity_list.EntityListAdd(mesh)

		' update matrix
		If mesh.parent<>Null
			mesh.mat.Overwrite(mesh.parent.mat)
			mesh.UpdateMat()
		Else
			mesh.UpdateMat(True)
		Endif
	
		Return mesh

	End 
	
	Function LoadMesh:TMesh(file$,parent_ent:TEntity=Null, override_texflags:Int=-1)
	
		Local xmesh:TMesh=LoadAnimMesh(file, Null, override_texflags)
		Local mesh:TMesh = CreateMesh()
		''
		xmesh.HideEntity()
		xmesh.CollapseAnimMesh(mesh)
		xmesh.FreeEntity()
		
		mesh.classname="Model"
		mesh.name = file

		mesh.AddParent(parent_ent)
		'mesh.entity_link = entity_list.EntityListAdd(mesh)

		' update matrix
		If mesh.parent<>Null
			mesh.mat.Overwrite(mesh.parent.mat)
			mesh.UpdateMat()
		Else
			mesh.UpdateMat(True)
		Endif
		
		Return TMesh(mesh)
	
	End 

	Function LoadAnimMesh:TMesh(file$,parent_ent:TEntity=Null, override_texflags:Int=-1)
	
		Local mesh:TMesh
		If file.EndsWith(".obj") Or file.EndsWith(".obj.txt")
			mesh = TModelObj.LoadMesh(file, override_texflags)
		Elseif file.EndsWith(".txt")
			mesh = TModelB3D.LoadAnimB3D(file,parent_ent, override_texflags)
		Elseif file.EndsWith(".b3d")
			mesh = TModelB3D.LoadAnimB3DBin(file,parent_ent, override_texflags)
		Else
			Print "**Error: File type not recognized (use .txt, .obj, or .b3d)"
		Endif
		
		If Not mesh Then Return TMesh.CreateCube()
		
		Return mesh

	End 


	Method CreateSurfaceID:Int()
	
		no_surfs=no_surfs+1 'putting this here may cause trouble
		Return no_surfs-1
		
	End

	Method CreateSurface:TSurface(bru:TBrush=Null)
	
		Local surf:TSurface=New TSurface
		surf_list.AddLast(surf)
		
			
		If bru<>Null
			surf.brush=bru.Copy()
		Endif
		
		'' anim surf
		surf.surf_id = CreateSurfaceID()
		anim_surf = anim_surf.Resize(no_surfs)
		anim_surf_frame = anim_surf_frame.Resize(no_surfs)
		
		' new mesh surface - update reset flags
		reset_bounds=True
		col_tree.reset_col_tree=True

		Return surf
		
	End
	
	'' AddSurface()
	'' -- helper for AddMesh()
	Method AddSurface:TSurface(surf:TSurface)

		surf_list.AddLast(surf)
		
		'' anim surf
		surf.surf_id = CreateSurfaceID()
		anim_surf = anim_surf.Resize(no_surfs)
		anim_surf_frame = anim_surf_frame.Resize(no_surfs)
		
		' new mesh surface - update reset flags
		reset_bounds=True
		col_tree.reset_col_tree=True

		Return surf
		
	End
	
	Method RemoveFromRenderList:Void()
		
		entity_link.Remove()
		entity_link=null
		
	End

	'' CreateGrid(x,y,parent)
	'' creates a plane of quads x segments by y segments each segment 1x1 unit large
	'' can create either joined grid or separate grid (for mobile textures)
	Function CreateGrid:TMesh(x_seg:Int,y_seg:Int, repeat_tex:Bool=False ,parent_ent:TEntity=Null)
	
		Local mesh:TMesh=TMesh.CreateMesh(parent_ent)
	
		Local surf:TSurface=mesh.CreateSurface()
		Local yhalf# = y_seg*0.5
		Local xhalf# = x_seg*0.5
		Local txstep# = 1.0/x_seg
		Local tystep# = -1.0/y_seg
		
		Local texx:Float = 0.0, texy:Float = 1.0
		Local v0:Int,v1:Int,v2:Int,v3:Int
		Local pv2:Int[x_seg+1]
		Local qv2:Int[x_seg+1]
		
		If Not repeat_tex
		
			For Local y:Float = -yhalf To yhalf-1.0 Step 1.0
			
				v0= surf.AddVertex( -xhalf-0.5, 0.0, y-0.5)
				v1= surf.AddVertex( -xhalf-0.5, 0.0, y+0.5)	
				
				For Local x:Float = -xhalf To xhalf-1.0 Step 1.0
	
	
					If x<>-xhalf Then v1 = v2; v0 = v3
					If y= -yhalf
						
						v3= surf.AddVertex( x+0.5, 0.0, y-0.5)
	
					Else
						v3 = pv2[xhalf + x]
										
					Endif
					
					v2= surf.AddVertex( x+0.5, 0.0, y+0.5)
					qv2[xhalf + x] = v2
					
				
					surf.VertexNormal(v0,0.0,1.0,0.0)
					surf.VertexNormal(v1,0.0,1.0,0.0)
					surf.VertexNormal(v2,0.0,1.0,0.0)
					surf.VertexNormal(v3,0.0,1.0,0.0)
					surf.VertexTexCoords(v0,texx,texy)
					surf.VertexTexCoords(v1,texx,texy+tystep)
					surf.VertexTexCoords(v2,texx+txstep,texy+tystep)
					surf.VertexTexCoords(v3,texx+txstep,texy)
					surf.AddTriangle(v0,v1,v2)
					surf.AddTriangle(v0,v2,v3)
					
					'Print "tx "+texx+" "+texy+" "+(texx+txstep)+" "+(texy+tystep)+" :: "+txstep+" "+tystep			
		
					texx += txstep
					
					If texx>1.0 Then texx=0.0
					
				Next
				
				For Local i:Int = 0 To x_seg
					pv2[i] = qv2[i]
				Next
				qv2 = New Int[x_seg+1]
				
				texx =0.0
				texy += tystep
				
				If texy<0.0 Then texy=1.0
				
			Next
		
		Else
			
			''create segmented grid, separate squares for textures
			For Local y:Float = -yhalf To yhalf-1.0 Step 1.0				
				For Local x:Float = -xhalf To xhalf-1.0 Step 1.0
								
					v0= surf.AddVertex( x-0.5, 0.0, y-0.5)
					v1= surf.AddVertex( x-0.5, 0.0, y+0.5)
					v2= surf.AddVertex( x+0.5, 0.0, y+0.5)
					v3= surf.AddVertex( x+0.5, 0.0, y-0.5)
					surf.VertexNormal(v0,0.0,1.0,0.0)
					surf.VertexNormal(v1,0.0,1.0,0.0)
					surf.VertexNormal(v2,0.0,1.0,0.0)
					surf.VertexNormal(v3,0.0,1.0,0.0)
					surf.VertexTexCoords(v0,0.0,0.0)
					surf.VertexTexCoords(v1,0.0,1.0)
					surf.VertexTexCoords(v2,1.0,1.0)
					surf.VertexTexCoords(v3,1.0,0.0)
					surf.AddTriangle(v0,v1,v2)
					surf.AddTriangle(v0,v2,v3)
				
				Next
			Next
		Endif
		
		surf.CropSurfaceBuffers()
		'mesh.UpdateNormals()
		
		mesh.classname = "MeshGrid"
		Return mesh
		
	End

	Function CreateCube:TMesh(parent_ent:TEntity=Null)
	
		Local mesh:TMesh=TMesh.CreateMesh(parent_ent)
	
		Local surf:TSurface=mesh.CreateSurface()
			
		surf.AddVertex(-1.0,-1.0,-1.0)
		surf.AddVertex(-1.0, 1.0,-1.0)
		surf.AddVertex( 1.0, 1.0,-1.0)
		surf.AddVertex( 1.0,-1.0,-1.0)
		
		surf.AddVertex(-1.0,-1.0, 1.0)
		surf.AddVertex(-1.0, 1.0, 1.0)
		surf.AddVertex( 1.0, 1.0, 1.0)
		surf.AddVertex( 1.0,-1.0, 1.0)
			
		surf.AddVertex(-1.0,-1.0, 1.0)
		surf.AddVertex(-1.0, 1.0, 1.0)
		surf.AddVertex( 1.0, 1.0, 1.0)
		surf.AddVertex( 1.0,-1.0, 1.0)
		
		surf.AddVertex(-1.0,-1.0,-1.0)
		surf.AddVertex(-1.0, 1.0,-1.0)
		surf.AddVertex( 1.0, 1.0,-1.0)
		surf.AddVertex( 1.0,-1.0,-1.0)

		surf.AddVertex(-1.0,-1.0, 1.0)
		surf.AddVertex(-1.0, 1.0, 1.0)
		surf.AddVertex( 1.0, 1.0, 1.0)
		surf.AddVertex( 1.0,-1.0, 1.0)
		
		surf.AddVertex(-1.0,-1.0,-1.0)
		surf.AddVertex(-1.0, 1.0,-1.0)
		surf.AddVertex( 1.0, 1.0,-1.0)
		surf.AddVertex( 1.0,-1.0,-1.0)

		surf.VertexNormal(0,0.0,0.0,-1.0)
		surf.VertexNormal(1,0.0,0.0,-1.0)
		surf.VertexNormal(2,0.0,0.0,-1.0)
		surf.VertexNormal(3,0.0,0.0,-1.0)
	
		surf.VertexNormal(4,0.0,0.0,1.0)
		surf.VertexNormal(5,0.0,0.0,1.0)
		surf.VertexNormal(6,0.0,0.0,1.0)
		surf.VertexNormal(7,0.0,0.0,1.0)
		
		surf.VertexNormal(8,0.0,-1.0,0.0)
		surf.VertexNormal(9,0.0,1.0,0.0)
		surf.VertexNormal(10,0.0,1.0,0.0)
		surf.VertexNormal(11,0.0,-1.0,0.0)
				
		surf.VertexNormal(12,0.0,-1.0,0.0)
		surf.VertexNormal(13,0.0,1.0,0.0)
		surf.VertexNormal(14,0.0,1.0,0.0)
		surf.VertexNormal(15,0.0,-1.0,0.0)
	
		surf.VertexNormal(16,-1.0,0.0,0.0)
		surf.VertexNormal(17,-1.0,0.0,0.0)
		surf.VertexNormal(18,1.0,0.0,0.0)
		surf.VertexNormal(19,1.0,0.0,0.0)
				
		surf.VertexNormal(20,-1.0,0.0,0.0)
		surf.VertexNormal(21,-1.0,0.0,0.0)
		surf.VertexNormal(22,1.0,0.0,0.0)
		surf.VertexNormal(23,1.0,0.0,0.0)

		surf.VertexTexCoords(0,0.0,1.0)
		surf.VertexTexCoords(1,0.0,0.0)
		surf.VertexTexCoords(2,1.0,0.0)
		surf.VertexTexCoords(3,1.0,1.0)
		
		surf.VertexTexCoords(4,1.0,1.0)
		surf.VertexTexCoords(5,1.0,0.0)
		surf.VertexTexCoords(6,0.0,0.0)
		surf.VertexTexCoords(7,0.0,1.0)
		
		surf.VertexTexCoords(8,0.0,1.0)
		surf.VertexTexCoords(9,0.0,0.0)
		surf.VertexTexCoords(10,1.0,0.0)
		surf.VertexTexCoords(11,1.0,1.0)
			
		surf.VertexTexCoords(12,0.0,0.0)
		surf.VertexTexCoords(13,0.0,1.0)
		surf.VertexTexCoords(14,1.0,1.0)
		surf.VertexTexCoords(15,1.0,0.0)
	
		surf.VertexTexCoords(16,0.0,1.0)
		surf.VertexTexCoords(17,0.0,0.0)
		surf.VertexTexCoords(18,1.0,0.0)
		surf.VertexTexCoords(19,1.0,1.0)
				
		surf.VertexTexCoords(20,1.0,1.0)
		surf.VertexTexCoords(21,1.0,0.0)
		surf.VertexTexCoords(22,0.0,0.0)
		surf.VertexTexCoords(23,0.0,1.0)

		surf.VertexTexCoords(0,0.0,1.0,0.0,1)
		surf.VertexTexCoords(1,0.0,0.0,0.0,1)
		surf.VertexTexCoords(2,1.0,0.0,0.0,1)
		surf.VertexTexCoords(3,1.0,1.0,0.0,1)
		
		surf.VertexTexCoords(4,1.0,1.0,0.0,1)
		surf.VertexTexCoords(5,1.0,0.0,0.0,1)
		surf.VertexTexCoords(6,0.0,0.0,0.0,1)
		surf.VertexTexCoords(7,0.0,1.0,0.0,1)
		
		surf.VertexTexCoords(8,0.0,1.0,0.0,1)
		surf.VertexTexCoords(9,0.0,0.0,0.0,1)
		surf.VertexTexCoords(10,1.0,0.0,0.0,1)
		surf.VertexTexCoords(11,1.0,1.0,0.0,1)
			
		surf.VertexTexCoords(12,0.0,0.0,0.0,1)
		surf.VertexTexCoords(13,0.0,1.0,0.0,1)
		surf.VertexTexCoords(14,1.0,1.0,0.0,1)
		surf.VertexTexCoords(15,1.0,0.0,0.0,1)
	
		surf.VertexTexCoords(16,0.0,1.0,0.0,1)
		surf.VertexTexCoords(17,0.0,0.0,0.0,1)
		surf.VertexTexCoords(18,1.0,0.0,0.0,1)
		surf.VertexTexCoords(19,1.0,1.0,0.0,1)
				
		surf.VertexTexCoords(20,1.0,1.0,0.0,1)
		surf.VertexTexCoords(21,1.0,0.0,0.0,1)
		surf.VertexTexCoords(22,0.0,0.0,0.0,1)
		surf.VertexTexCoords(23,0.0,1.0,0.0,1)
				
		surf.AddTriangle(0,1,2) ' front
		surf.AddTriangle(0,2,3)
		surf.AddTriangle(6,5,4) ' back
		surf.AddTriangle(7,6,4)
		surf.AddTriangle(6+8,5+8,1+8) ' top
		surf.AddTriangle(2+8,6+8,1+8)
		surf.AddTriangle(0+8,4+8,7+8) ' bottom
		surf.AddTriangle(0+8,7+8,3+8)
		surf.AddTriangle(6+16,2+16,3+16) ' right
		surf.AddTriangle(7+16,6+16,3+16)
		surf.AddTriangle(0+16,1+16,5+16) ' left
		surf.AddTriangle(0+16,5+16,4+16)

		surf.CropSurfaceBuffers()
		
		mesh.classname = "MeshCube"
		
		Return mesh
	
	End 
	
	' Function by Coyote
	Function CreateSphere:TMesh(segments:Int=8,parent_ent:TEntity=Null)

		If segments<2 Or segments>100 Then Return Null
		
		Local thissphere:TMesh=TMesh.CreateMesh(parent_ent)
		Local thissurf:TSurface=thissphere.CreateSurface()

		Local div#=Float(360.0/(segments*2))
		Local height#=1.0
		Local upos#=1.0
		Local udiv#=Float(1.0/(segments*2))
		Local vdiv#=Float(1.0/segments)
		Local RotAngle#=90	
	
		If segments=2 ' diamond shape - no center strips
		
			For Local i=1 To (segments*2)
				Local np=thissurf.AddVertex(0.0,height,0.0,upos-(udiv/2.0),0)'northpole
				Local sp=thissurf.AddVertex(0.0,-height,0.0,upos-(udiv/2.0),1)'southpole
				Local XPos#=-Cos(RotAngle)
				Local ZPos#=Sin(RotAngle)
				Local v0=thissurf.AddVertex(XPos,0,ZPos,upos,0.5)
				RotAngle=RotAngle+div
				If RotAngle>=360.0 Then RotAngle=RotAngle-360.0
				XPos=-Cos(RotAngle)
				ZPos=Sin(RotAngle)
				upos=upos-udiv
				Local v1=thissurf.AddVertex(XPos,0,ZPos,upos,0.5)
				thissurf.AddTriangle(np,v0,v1)
				thissurf.AddTriangle(v1,v0,sp)	
			Next
			
		Else ' have center strips now
		
			' poles first
			Local YPos#=Cos(div)
			
			For Local i=1 To (segments*2)
			
				Local np=thissurf.AddVertex(0.0,height,0.0,upos-(udiv/2.0),0.0)'northpole
				Local sp=thissurf.AddVertex(0.0,-height,0.0,upos-(udiv/2.0),1.0)'southpole
				
				
				
				Local XPos#=-Cos(RotAngle)*(Sin(div))
				Local ZPos#=Sin(RotAngle)*(Sin(div))
				
				Local v0t=thissurf.AddVertex(XPos,YPos,ZPos,upos,vdiv)
				Local v0b=thissurf.AddVertex(XPos,-YPos,ZPos,upos,1.0-vdiv)
	
				RotAngle=RotAngle+div
				
				XPos=-Cos(RotAngle)*(Sin(div))
				ZPos=Sin(RotAngle)*(Sin(div))
				
				upos=upos-udiv
	
				Local v1t=thissurf.AddVertex(XPos,YPos,ZPos,upos,vdiv)
				Local v1b=thissurf.AddVertex(XPos,-YPos,ZPos,upos,1.0-vdiv)
		
				thissurf.AddTriangle(np,v0t,v1t)
				thissurf.AddTriangle(v1b,v0b,sp)	
				
			Next

			' then center strips
	
			upos=1.0
			RotAngle=90
			For Local i=1 To (segments*2)
			
				Local mult#=1
				Local YPos#=Cos(div*(mult))
				Local YPos2#=Cos(div*(mult+1.0))
				Local Thisvdiv#=vdiv
				For Local j=1 To (segments-2)
	
					
					Local XPos#=-Cos(RotAngle)*(Sin(div*(mult)))
					Local ZPos#=Sin(RotAngle)*(Sin(div*(mult)))
	
					Local XPos2#=-Cos(RotAngle)*(Sin(div*(mult+1.0)))
					Local ZPos2#=Sin(RotAngle)*(Sin(div*(mult+1.0)))
								
					Local v0t=thissurf.AddVertex(XPos,YPos,ZPos,upos,Thisvdiv)
					Local v0b=thissurf.AddVertex(XPos2,YPos2,ZPos2,upos,Thisvdiv+vdiv)
				
					' 2nd tex coord set
					thissurf.VertexTexCoords(v0t,upos,Thisvdiv,0.0,1)
					thissurf.VertexTexCoords(v0b,upos,Thisvdiv+vdiv,0.0,1)
				
					Local tempRotAngle#=RotAngle+div
					
					Local sdm# = Sin(div*(mult))
					XPos=-Cos(tempRotAngle)*(sdm)
					ZPos=Sin(tempRotAngle)*(sdm)
					
					sdm = Sin(div*(mult+1.0))
					XPos2=-Cos(tempRotAngle)*(sdm)
					ZPos2=Sin(tempRotAngle)*(sdm)				
				
					Local temp_upos#=upos-udiv
	
					Local v1t=thissurf.AddVertex(XPos,YPos,ZPos,temp_upos,Thisvdiv)
					Local v1b=thissurf.AddVertex(XPos2,YPos2,ZPos2,temp_upos,Thisvdiv+vdiv)
					
					' 2nd tex coord set
					thissurf.VertexTexCoords(v1t,temp_upos,Thisvdiv,0.0,1)
					thissurf.VertexTexCoords(v1b,temp_upos,Thisvdiv+vdiv,0.0,1)
					
					thissurf.AddTriangle(v1t,v0t,v0b)
					thissurf.AddTriangle(v1b,v1t,v0b)
					
					Thisvdiv=Thisvdiv+vdiv			
					mult=mult+1
					YPos=Cos(div*(mult))
					YPos2=Cos(div*(mult+1.0))
				
				Next
				upos=upos-udiv
				RotAngle=RotAngle+div
			Next
	
		Endif
		
		thissurf.CropSurfaceBuffers()
		
			'thissphere.UpdateNormals() ''slow
		thissurf.SnapVerts()
		thissurf.UpdateNormals()
			
		' mesh state has changed - update reset flags
		thissurf.reset_vbo = thissurf.reset_vbo|4
		
		thissphere.classname = "MeshSphere"
		
		Return thissphere 

	End 

	' Function by Coyote
	Function CreateCylinder:TMesh(verticalsegments=8,solid=True,parent_ent:TEntity=Null)
	
		Local ringsegments=0 ' default?
	
		Local tr,tl,br,bl' 		side of cylinder
		Local ts0,ts1,newts' 	top side vertexs
		Local bs0,bs1,newbs' 	bottom side vertexs
		If verticalsegments<3 Or verticalsegments>100 Then Return Null
		If ringsegments<0 Or ringsegments>100 Then Return Null
		
		Local thiscylinder:TMesh=TMesh.CreateMesh(parent_ent)
		Local thissurf:TSurface=thiscylinder.CreateSurface()
		Local thissidesurf:TSurface
		If solid=True
			thissidesurf=thiscylinder.CreateSurface()
		Endif
		Local div#=Float(360.0/(verticalsegments))
	
		Local height#=1.0
		Local ringSegmentHeight#=(height*2.0)/(ringsegments+1)
		Local upos#=1.0
		Local udiv#=Float(1.0/(verticalsegments))
		Local vpos#=1.0
		Local vdiv#=Float(1.0/(ringsegments+1))
	
		Local SideRotAngle#=90
	
		' re-diminsion arrays to hold needed memory.
		' this is used just for helping to build the ring segments...
		Local tRing[verticalsegments+1]
		Local bRing[verticalsegments+1]
		
		' render end caps if solid
		If solid=True
			Local XPos#=-Cos(SideRotAngle)
			Local ZPos#=Sin(SideRotAngle)
	
			ts0=thissidesurf.AddVertex(XPos,height,ZPos,XPos/2.0+0.5,ZPos/2.0+0.5)
			bs0=thissidesurf.AddVertex(XPos,-height,ZPos,XPos/2.0+0.5,ZPos/2.0+0.5)
			
			' 2nd tex coord set
			thissidesurf.VertexTexCoords(ts0,XPos/2.0+0.5,ZPos/2.0+0.5,0.0,1)
			thissidesurf.VertexTexCoords(bs0,XPos/2.0+0.5,ZPos/2.0+0.5,0.0,1)
	
			SideRotAngle=SideRotAngle+div
	
			XPos=-Cos(SideRotAngle)
			ZPos=Sin(SideRotAngle)
			
			ts1=thissidesurf.AddVertex(XPos,height,ZPos,XPos/2.0+0.5,ZPos/2.0+0.5)
			bs1=thissidesurf.AddVertex(XPos,-height,ZPos,XPos/2.0+0.5,ZPos/2.0+0.5)
		
			' 2nd tex coord set
			thissidesurf.VertexTexCoords(ts1,XPos/2.0+0.5,ZPos/2.0+0.5,0.0,1)
			thissidesurf.VertexTexCoords(bs1,XPos/2.0+0.5,ZPos/2.0+0.5,0.0,1)
			
			For Local i=1 To (verticalsegments-2)
				SideRotAngle=SideRotAngle+div
	
				XPos=-Cos(SideRotAngle)
				ZPos=Sin(SideRotAngle)
				
				newts=thissidesurf.AddVertex(XPos,height,ZPos,XPos/2.0+0.5,ZPos/2.0+0.5)
				newbs=thissidesurf.AddVertex(XPos,-height,ZPos,XPos/2.0+0.5,ZPos/2.0+0.5)
				
				' 2nd tex coord set
				thissidesurf.VertexTexCoords(newts,XPos/2.0+0.5,ZPos/2.0+0.5,0.0,1)
				thissidesurf.VertexTexCoords(newbs,XPos/2.0+0.5,ZPos/2.0+0.5,0.0,1)
				
				thissidesurf.AddTriangle(ts0,ts1,newts)
				thissidesurf.AddTriangle(newbs,bs1,bs0)
			
				If i<(verticalsegments-2)
					ts1=newts
					bs1=newbs
				Endif
			Next
		Endif
		
		' -----------------------
		' middle part of cylinder
		Local thisHeight#=height
		
		' top ring first		
		SideRotAngle=90
		Local XPos#=-Cos(SideRotAngle)
		Local ZPos#=Sin(SideRotAngle)
		Local thisUPos#=upos
		Local thisVPos#=0
		tRing[0]=thissurf.AddVertex(XPos,thisHeight,ZPos,thisUPos,thisVPos)		
		thissurf.VertexTexCoords(tRing[0],thisUPos,thisVPos,0.0,1) ' 2nd tex coord set
		For Local i=0 To (verticalsegments-1)
			SideRotAngle=SideRotAngle+div
			XPos=-Cos(SideRotAngle)
			ZPos=Sin(SideRotAngle)
			thisUPos=thisUPos-udiv
			tRing[i+1]=thissurf.AddVertex(XPos,thisHeight,ZPos,thisUPos,thisVPos)
			thissurf.VertexTexCoords(tRing[i+1],thisUPos,thisVPos,0.0,1) ' 2nd tex coord set
		Next	
		
		For Local ring=0 To ringsegments
	
			' decrement vertical segment
			Local thisHeight=thisHeight-ringSegmentHeight
			
			' now bottom ring
			SideRotAngle=90
			XPos=-Cos(SideRotAngle)
			ZPos=Sin(SideRotAngle)
			thisUPos=upos
			thisVPos=thisVPos+vdiv
			bRing[0]=thissurf.AddVertex(XPos,thisHeight,ZPos,thisUPos,thisVPos)
			thissurf.VertexTexCoords(bRing[0],thisUPos,thisVPos,0.0,1) ' 2nd tex coord set
			For Local i=0 To (verticalsegments-1)
				SideRotAngle=SideRotAngle+div
				XPos=-Cos(SideRotAngle)
				ZPos=Sin(SideRotAngle)
				thisUPos=thisUPos-udiv
				bRing[i+1]=thissurf.AddVertex(XPos,thisHeight,ZPos,thisUPos,thisVPos)
				thissurf.VertexTexCoords(bRing[i+1],thisUPos,thisVPos,0.0,1) ' 2nd tex coord set
			Next
			
			' Fill in ring segment sides with triangles
			For Local v=1 To (verticalsegments)
				tl=tRing[v]
				tr=tRing[v-1]
				bl=bRing[v]
				br=bRing[v-1]
				
				thissurf.AddTriangle(tl,tr,br)
				thissurf.AddTriangle(bl,tl,br)
			Next
			
			' make bottom ring segmentthe top ring segment for the next loop.
			For Local v=0 To (verticalsegments)
				tRing[v]=bRing[v]
			Next		
		Next
		
		thissurf.CropSurfaceBuffers()
	
		thiscylinder.UpdateNormals()
		thiscylinder.classname = "MeshCylinder"
		
		Return thiscylinder 
		
	End 
	
	' Function by Coyote
	Function CreateCone:TMesh(segments=8,solid=True,parent_ent:TEntity=Null)
	
		Local top,br,bl' 		side of cone
		Local bs0,bs1,newbs' 	bottom side vertices
		
		If segments<3 Or segments>100 Then Return Null
		
		Local thiscone:TMesh=TMesh.CreateMesh(parent_ent)
		Local thissurf:TSurface=thiscone.CreateSurface()
		Local thissidesurf:TSurface
		If solid=True
			thissidesurf=thiscone.CreateSurface()
		Endif
		Local div#=Float(360.0/(segments))
	
		Local height#=1.0
		Local upos#=1.0
		Local udiv#=Float(1.0/(segments))
		Local RotAngle#=90	
	
		' first side
		Local XPos#=-Cos(RotAngle)
		Local ZPos#=Sin(RotAngle)
	
		top=thissurf.AddVertex(0.0,height,0.0,upos-(udiv/2.0),0)
		br=thissurf.AddVertex(XPos,-height,ZPos,upos,1)
		
		' 2nd tex coord set
		thissurf.VertexTexCoords(top,upos-(udiv/2.0),0,0.0,1)
		thissurf.VertexTexCoords(br,upos,1,0.0,1)
	
		If solid=True Then bs0=thissidesurf.AddVertex(XPos,-height,ZPos,XPos/2.0+0.5,ZPos/2.0+0.5)
		If solid=True Then thissidesurf.VertexTexCoords(bs0,XPos/2.0+0.5,ZPos/2.0+0.5,0.0,1) ' 2nd tex coord set
	
		RotAngle= RotAngle+div
	
		XPos= -Cos(RotAngle)
		ZPos= Sin(RotAngle)
					
		bl=thissurf.AddVertex(XPos,-height,ZPos,upos-udiv,1)
		thissurf.VertexTexCoords(bl,upos-udiv,1,0.0,1) ' 2nd tex coord set	
	
		If solid=True Then bs1=thissidesurf.AddVertex(XPos,-height,ZPos,XPos/2.0+0.5,ZPos/2.0+0.5)
		If solid=True Then thissidesurf.VertexTexCoords(bs1,XPos/2.0+0.5,ZPos/2.0+0.5,0.0,1) ' 2nd tex coord set
		
		thissurf.AddTriangle(bl,top,br)
	
		' rest of sides
		For Local i=1 To (segments-1)
			br=bl
			upos=upos-udiv
			top=thissurf.AddVertex(0.0,height,0.0,upos-(udiv/2.0),0)
			thissurf.VertexTexCoords(top,upos-(udiv/2.0),0,0.0,1) ' 2nd tex coord set
		
			RotAngle=RotAngle+div
	
			XPos=-Cos(RotAngle)
			ZPos=Sin(RotAngle)
			
			bl=thissurf.AddVertex(XPos,-height,ZPos,upos-udiv,1)
			thissurf.VertexTexCoords(bl,upos-udiv,1,0.0,1) ' 2nd tex coord set
	
			If solid=True Then newbs=thissidesurf.AddVertex(XPos,-height,ZPos,XPos/2.0+0.5,ZPos/2.0+0.5)
			If solid=True Then thissidesurf.VertexTexCoords(newbs,XPos/2.0+0.5,ZPos/2.0+0.5,0.0,1) ' 2nd tex coord set
		
			thissurf.AddTriangle(bl,top,br)
			
			If solid=True
				thissidesurf.AddTriangle(newbs,bs1,bs0)'AddTriangle(newbs,bs1,bs0)
			
				If i<(segments-1)
					bs1=newbs
				Endif
			Endif
		Next
		
		thissurf.CropSurfaceBuffers()
		thissidesurf.CropSurfaceBuffers()
		
		thiscone.UpdateNormals()
		thiscone.classname = "MeshCone"
		Return thiscone
		
	End 
	
	Function CreateLine:TMesh(v1:Vector, v2:Vector, thick:Float=1.0, parent_ent:TEntity=Null)
		Return CreateLine(v1.x,v1.y,v1.z,v2.x,v2.y,v2.z,thick,parent_ent)
	End
	
	Function CreateLine:TMesh(v1:Vector, v2:Vector, r:Int,g:Int,b:Int)
		Local m:TMesh = CreateLine(v1.x,v1.y,v1.z,v2.x,v2.y,v2.z)
		m.EntityColor(r,g,b)
		Return m
	End
	
	
	Function CreateLine:TMesh(x:Float, y:Float, z:Float, x2:Float, y2:Float, z2:Float, thick:Float=1.0, parent_ent:TEntity=Null)
		
		Local mesh:TMesh=TMesh.CreateMesh(parent_ent)
	
		Local surf:TSurface=mesh.CreateSurface()
		
		

		surf.AddVertex(x,y,z)
		surf.AddVertex(x2,y2,z2)
		surf.AddVertex(x,y,z)
						
		surf.AddTriangle(0,1,2)


		surf.CropSurfaceBuffers()
		
		mesh.classname = "Line"
		mesh.wireframe = True
		
		Return mesh

	End
	
	Method CopyMesh:TMesh(parent_ent:TEntity=Null)
	
		Local mesh:TMesh=New TMesh()
		mesh.classname = Self.classname
		If parent_ent Then mesh.EntityParent(parent_ent)
		
		Self.AddMesh(mesh, false) ''add self TO mesh ''**note: cannot place after CopyBaseMeshTo, otherwise infinite loop
		Local new_list:List<TSurface> = mesh.surf_list
		
		Self.CopyBaseMeshTo(mesh,parent_ent) ''this overwrites surf_list pointer with original pointer
		mesh.surf_list = new_list  ''set pointer back to proper list
		
		''remove from entity_list since it will re-add in CopyBaseMeshTo()
		'mesh.entity_link.Remove()
		'mesh.entity_link=Null
		
		
		''need a full copy of bones list, not just pointers
		If bones
	 
			mesh.bones = CopyBonesList(mesh, New List<TBone>, 0).ToArray()
		Endif
		
		' copy anim surf list
		mesh.anim_surf = CopyAnimSurfs(1) ''full copy, dont use pointers
		
		Return mesh
	
	End 
	

	
	'' AddMesh()
	'' -- add self mesh to mesh2
	'' -- confusing, consider AddMeshTo() or AddMesh(src, dest)
	Method AddMesh(mesh2:TMesh, combine_brush:Bool=True)
		
		If Not mesh2 Then Return
		
		''surf1 is source surface
		For Local surf1:TSurface=Eachin surf_list

			' if surface is empty, don't add it
			If surf1.CountVertices()=0 And surf1.CountTriangles()=0 Then Continue
				
			Local new_surf:Bool=True
			Local tri_offset:Int = 0
			Local surf2:TSurface = Null
			Local stest:TSurface
			
			If combine_brush
				For stest= Eachin mesh2.surf_list '1 To mesh2.CountSurfaces()	
					
					'compare entity brushes first
					'If (brush And mesh2.brush And (TBrush.CompareBrushes(brush,mesh2.brush)=True))
						
					
					' if brushes properties are the same, add surf1 verts and tris to surf2
					If (surf1.brush And stest.brush And TBrush.CompareBrushes(surf1.brush,stest.brush)=True)
						
						tri_offset = stest.CountVertices()
						new_surf=False
						surf2 = stest
						
						Exit
				
					Endif
					
				Next
			Endif
			
			' add new surface
			
			
			If new_surf=True
			
				'surf = mesh2.CreateSurface()
				surf2 = surf1.Copy()
				mesh2.AddSurface(surf2)
				
				
				
			Else	
				
				' add vertices to existing surface
				
				Local s1v:Int = surf1.CountVertices()		
				For Local v:Int=0 To s1v-1

					Local vt:Vertex = surf1.GetVertex(v)
						
					Local v2:Int = surf2.AddVertex(vt.x,vt.y,-vt.z)
					surf2.VertexColor(v2,vt.r,vt.g,vt.b,vt.a)
					surf2.VertexNormal(v2,vt.nx,vt.ny,-vt.nz)
					surf2.VertexTexCoords(v2,vt.u0,vt.v0,vt.w0,0)
					surf2.VertexTexCoords(v2,vt.u1,vt.v1,vt.w1,1)
	
				Next
		
				' add triangles
		
				For Local t=0 To surf1.CountTriangles()-1
	
					Local v0=surf1.TriangleVertex(t,0) + tri_offset
					Local v1=surf1.TriangleVertex(t,1) + tri_offset
					Local v2=surf1.TriangleVertex(t,2) + tri_offset
					
					surf2.AddTriangle(v0,v1,v2)
	
				Next
				
				surf2.CropSurfaceBuffers()
				
				' copy brush
			
				If surf1.brush<>Null And brush = null
				
					surf2.brush=surf1.brush.Copy()
					
				Elseif brush<>Null
					
					surf2.brush = brush.Copy()
					
				Endif
			
			Endif
			

			
			' mesh shape has changed - update reset flags
			surf2.reset_vbo=-1 ' (-1 = all)
				
			'Endif
							
		Next
		
		' mesh shape has changed - update reset flags
		mesh2.reset_bounds=True
		mesh2.col_tree.reset_col_tree=True
		
	End 
	
	Method FlipMesh()
	
		For Local surf:TSurface=Eachin surf_list
		
			' flip triangle vertex order
			For Local t=1 To surf.no_tris
			
				Local i0=t*3-3
				Local i1=t*3-2
				Local i2=t*3-1
			
				Local v0=surf.tris.Peek(i0)
				Local v1=surf.tris.Peek(i1)
				Local v2=surf.tris.Peek(i2)
		
				surf.tris.Poke(i0,v2)
				'surf.tris[i1]
				surf.tris.Poke(i2,v0)
		
			Next
			
			' flip vertex normals
			For Local v=0 To surf.no_verts-1
			
				'surf.vert_norm.Poke(v*3, -surf.vert_norm.Peek(v*3) )' x
				'surf.vert_norm.Poke((v*3)+1, -surf.vert_norm.Peek((v*3)+1) )' y
				'surf.vert_norm.Poke((v*3)+2, -surf.vert_norm.Peek((v*3)+2) )' z
				surf.vert_data.PokeNormals(v, -surf.vert_data.VertexNX(v),-surf.vert_data.VertexNY(v),-surf.vert_data.VertexNZ(v) )

				
			Next
			
			' mesh shape has changed - update reset flag
			surf.reset_vbo = surf.reset_vbo|4|16
		
		Next
		
		' mesh shape has changed - update reset flag
		col_tree.reset_col_tree=True
		
	End
	
	'' Paints each surface, versus PaintEntity() which sets master brush
	Method PaintMesh(bru:TBrush)

		For Local surf:TSurface=Eachin surf_list

			surf.brush = bru.Copy()

		Next

	End 
	
	Method FitMesh(x#,y#,z#,width#,height#,depth#,uniform=False)
	
		' if uniform=true than adjust fitmesh dimensions
		
		If uniform=True
						
			Local wr#=MeshWidth()/width
			Local hr#=MeshHeight()/height
			Local dr#=MeshDepth()/depth
		
			If wr>=hr And wr>=dr
	
				y=y+((height-(MeshHeight()/wr))/2.0)
				z=z+((depth-(MeshDepth()/wr))/2.0)
				
				height=MeshHeight()/wr
				depth=MeshDepth()/wr
			
			Else If hr>dr
			
				x=x+((width-(MeshWidth()/hr))/2.0)
				z=z+((depth-(MeshDepth()/hr))/2.0)
			
				width=MeshWidth()/hr
				depth=MeshDepth()/hr
						
			Else
			
				x=x+((width-(MeshWidth()/dr))/2.0)
				y=y+((height-(MeshHeight()/dr))/2.0)
			
				width=MeshWidth()/dr
				height=MeshHeight()/dr
								
			Endif

		Endif
		
		' old to new dimensions ratio, used to update mesh normals
		Local wr#=MeshWidth()/width
		Local hr#=MeshHeight()/height
		Local dr#=MeshDepth()/depth
		
		' find min/max dimensions
	
		Local minx#=9999999999
		Local miny#=9999999999
		Local minz#=9999999999
		Local maxx#=-9999999999
		Local maxy#=-9999999999
		Local maxz#=-9999999999
	
		For Local s=1 To CountSurfaces()
			
			Local surf:TSurface=GetSurface(s)
				
			For Local v=0 To surf.CountVertices()-1
		
				Local vx#=surf.VertexX(v)
				Local vy#=surf.VertexY(v)
				Local vz#=surf.VertexZ(v)
				
				If vx<minx Then minx=vx
				If vy<miny Then miny=vy
				If vz<minz Then minz=vz
				
				If vx>maxx Then maxx=vx
				If vy>maxy Then maxy=vy
				If vz>maxz Then maxz=vz

			Next
							
		Next
		
		For Local s=1 To CountSurfaces()
			
			Local surf:TSurface=GetSurface(s)
				
			For Local v=0 To surf.CountVertices()-1
		
				' update vertex positions
		
				Local vx#=surf.VertexX(v)
				Local vy#=surf.VertexY(v)
				Local vz#=surf.VertexZ(v)
								
				Local mx#=maxx-minx
				Local my#=maxy-miny
				Local mz#=maxz-minz
				
				Local ux#,uy#,uz#
				
				If mx<0.0001 And mx>-0.0001 Then ux=0.0 Else ux=(vx-minx)/mx ' 0-1
				If my<0.0001 And my>-0.0001 Then uy=0.0 Else uy=(vy-miny)/my ' 0-1
				If mz<0.0001 And mz>-0.0001 Then uz=0.0 Else uz=(vz-minz)/mz ' 0-1
										
				vx=x+(ux*width)
				vy=y+(uy*height)
				vz=z+(uz*depth)
				
				surf.VertexCoords(v,vx,vy,vz)
				
				' update normals
				
				Local nx#=surf.VertexNX(v)
				Local ny#=surf.VertexNY(v)
				Local nz#=surf.VertexNZ(v)
				
				nx=nx*wr
				ny=ny*hr
				nz=nz*dr
				
				surf.VertexNormal(v,nx,ny,nz)

			Next
			
			' mesh shape has changed - update reset flag
			surf.reset_vbo = surf.reset_vbo|1|4

		Next
		
		' mesh shape has changed - update reset flags
		reset_bounds=True
		col_tree.reset_col_tree=True
		
	End 
	
	Method ScaleMesh(sx#,sy#,sz#)
	
		For Local s=1 To no_surfs
	
			Local surf:TSurface=GetSurface(s)
				
			For Local v=0 To surf.no_verts-1
		
				surf.vert_data.PokeVertCoords(v, surf.vert_data.VertexX(v)*sx,surf.vert_data.VertexY(v)*sy,surf.vert_data.VertexZ(v)*sz)
				'surf.vert_data.Poke(v+1, surf.vert_data.Peek(v+1)*sy)
				'surf.vert_data.Poke(v+2, surf.vert_data.Peek(v+2)*sz) 'surf.vert_coords[v*3+2] *= sz

			Next
			
			' mesh shape has changed - update reset flag
			surf.reset_vbo = surf.reset_vbo|1
				
		Next
		
		' mesh shape has changed - update reset flags
		reset_bounds=True
		col_tree.reset_col_tree=True

	End 
	
	Method RotateMesh(pitch#,yaw#,roll#)
	
		pitch= -pitch
		
		Local mat:Matrix=New Matrix
		mat.LoadIdentity()
		mat.FastRotateScale(pitch,yaw,roll,1.0,1.0,1.0)

		For Local s=1 To no_surfs
	
			Local surf:TSurface=GetSurface(s)
				
			For Local v=0 To surf.no_verts-1
		
				Local vx#=surf.vert_data.VertexX(v)
				Local vy#=surf.vert_data.VertexY(v)
				Local vz#=surf.vert_data.VertexZ(v)
	
				Local rx# =(mat.grid[0][0]*vx + mat.grid[1][0]*vy + mat.grid[2][0]*vz )'+ mat.grid[3][0] )
				Local ry# =(mat.grid[0][1]*vx + mat.grid[1][1]*vy + mat.grid[2][1]*vz )'+ mat.grid[3][1] )
				Local rz# =(mat.grid[0][2]*vx + mat.grid[1][2]*vy + mat.grid[2][2]*vz )'+ mat.grid[3][2] )
				
				surf.vert_data.PokeVertCoords(v, rx,ry,rz)
				
				Local nx#=surf.vert_data.VertexNX(v)
				Local ny#=surf.vert_data.VertexNY(v)
				Local nz#=surf.vert_data.VertexNZ(v)
	
				rx=( mat.grid[0][0]*nx + mat.grid[1][0]*ny + mat.grid[2][0]*nz)' + mat.grid[3][0] )
				ry=( mat.grid[0][1]*nx + mat.grid[1][1]*ny + mat.grid[2][1]*nz)' + mat.grid[3][1] )
				rz=( mat.grid[0][2]*nx + mat.grid[1][2]*ny + mat.grid[2][2]*nz)' + mat.grid[3][2] )
				
				surf.vert_data.PokeNormals(v, rx,ry,rz)
			Next
			
			' mesh shape has changed - update reset flag
			surf.reset_vbo = surf.reset_vbo|1|4
							
		Next
		
		' mesh shape has changed - update reset flag
		reset_bounds=True
		col_tree.reset_col_tree=True
				
	End 
	
	Method PositionMesh(px#,py#,pz#)

		pz=-pz
	
		For Local s=1 To no_surfs
	
			Local surf:TSurface=GetSurface(s)
				
			For Local v=0 To surf.no_verts-1
		
				'surf.vert_coords.Poke(v*3, surf.vert_coords.Peek(v*3) + px )
				'surf.vert_coords.Poke(v*3+1, surf.vert_coords.Peek(v*3+1) + py )
				'surf.vert_coords.Poke(v*3+2, surf.vert_coords.Peek(v*3+2) + pz ) 'surf.vert_coords[v*3+2] += pz
				
				surf.vert_data.PokeVertCoords(v, surf.vert_data.VertexX(v)+px,surf.vert_data.VertexY(v)+py,surf.vert_data.VertexZ(v)+pz)
				
			Next
			
			' mesh shape has changed - update reset flag
			surf.reset_vbo = surf.reset_vbo|1
						
		Next
		
		' mesh shape has changed - update reset flags
		reset_bounds=True
		col_tree.reset_col_tree=True
		
	End 
	
	
	' used by LoadMesh
	Method TransformMesh(mat:Matrix)

		For Local s=1 To no_surfs
	
			Local surf:TSurface=GetSurface(s)
			
			If Not surf Then Continue
				
			For Local v=0 To surf.no_verts-1
		
				Local vx#=surf.vert_data.VertexX(v)
				Local vy#=surf.vert_data.VertexY(v)
				Local vz#=surf.vert_data.VertexZ(v)
	
				Local rx#=( mat.grid[0][0]*vx + mat.grid[1][0]*vy + mat.grid[2][0]*vz + mat.grid[3][0] )
				Local ry#=( mat.grid[0][1]*vx + mat.grid[1][1]*vy + mat.grid[2][1]*vz + mat.grid[3][1] )
				Local rz#=( mat.grid[0][2]*vx + mat.grid[1][2]*vy + mat.grid[2][2]*vz + mat.grid[3][2] )
				
				surf.vert_data.PokeVertCoords(v, rx,ry,rz)
				
				Local nx#=surf.vert_data.VertexNX(v)
				Local ny#=surf.vert_data.VertexNY(v)
				Local nz#=surf.vert_data.VertexNZ(v)
	
				rx=( mat.grid[0][0]*nx + mat.grid[1][0]*ny + mat.grid[2][0]*nz )
				ry=( mat.grid[0][1]*nx + mat.grid[1][1]*ny + mat.grid[2][1]*nz )
				rz=( mat.grid[0][2]*nx + mat.grid[1][2]*ny + mat.grid[2][2]*nz )
				
				surf.vert_data.PokeNormals(v, rx,ry,rz)

			Next
							
		Next

	End
	
	
	Method UpdateNormals(create_only:Bool=false)

		For Local s=1 To CountSurfaces()

			Local surf:TSurface=GetSurface( s )

			surf.UpdateNormals(create_only)
			
			' mesh state has changed - update reset flags
			surf.reset_vbo = surf.reset_vbo|4

		Next
	
	End 
	
	Method RemoveVerts()

		For Local s=1 To CountSurfaces()

			Local surf:TSurface=GetSurface( s )

			TSurface.RemoveVerts(surf)
			
			' mesh state has changed - update reset flags
			surf.reset_vbo = surf.reset_vbo|4

		Next
	
	End
	
	Method WeldVerts()

		For Local s=1 To CountSurfaces()

			Local surf:TSurface=GetSurface( s )
			surf.WeldVerts()
			
		Next
	
	End 
	
	Method MeshWidth#()

		GetBounds()

		Return max_x-min_x
		
	End 
	
	Method MeshHeight#()

		GetBounds()

		Return max_y-min_y
		
	End 
	
	Method MeshDepth#()

		GetBounds()

		Return max_z-min_z
		
	End 

	Method CountSurfaces()
	
		Return no_surfs
	
	End 
	
	'' starts at 1
	Method GetSurface:TSurface(surf_no_get:Int)
		
		Local surf_no=0
	
		For Local surf:TSurface=Eachin surf_list
		
			surf_no=surf_no+1
			
			If surf_no_get=surf_no Then Return surf
		
		Next
	
		Return Null
	
	End
	
	Method GetSurfaceList:List<TSurface>()
		Return surf_list
	End 
	
	Method FindSurface:TSurface(brush:TBrush)
	
		' ***note*** unlike B3D version, this will find a surface with no brush, if a null brush is supplied
	
		For Local surf:TSurface=Eachin surf_list
		
			If TBrush.CompareBrushes(brush,surf.brush)=True
				Return surf
			Endif
		
		Next
		
		Return Null
	
	End 
	
	'' starts at 0 to be consistent with Brush.GetTexture()
	Method GetTexture:TTexture(i:Int=0, s:Int=1)
		
		If brush And brush.tex[0] Then Return brush.tex[0]
		If GetSurface(s).brush And GetSurface(s).brush.tex[i] Then Return GetSurface(s).brush.tex[i]
		Return Null
		
	End
	
	' returns total no. of vertices in mesh
	Method CountVertices()
	
		Local verts=0
	
		For Local s=1 To CountSurfaces()
		
			Local surf:TSurface=GetSurface(s)	
		
			verts=verts+surf.CountVertices()
		
		Next
	
		Return verts
	
	End 
	
	' returns total no. of triangles in mesh
	Method CountTriangles()
	
		Local tris=0
	
		For Local s=1 To CountSurfaces()
		
			Local surf:TSurface=GetSurface(s)	
		
			tris=tris+surf.CountTriangles()
		
		Next
	
		Return tris
	
	End 
		
	' used by CopyEntity
	' recursive, returns bones list
	' assumes bones have already been copied via tmesh.entitycopy
	Function CopyBonesList:List<TBone>(ent:TEntity, bone_list:List<TBone>, no_bones:Int=0)
		
		Local bone:TBone
		If no_bones=0 Then Return bone_list
		
		For Local e:TEntity=Eachin ent.child_list
			bone = TBone(e)
			If bone<>Null

				bone_list.AddLast( bone )
				
			Endif
			CopyBonesList(bone,bone_list,no_bones)
		Next
		
		Return bone_list
		
	End 
	
	
	 ' used by LoadMesh
	Method CollapseAnimMesh:Void(mesh:TMesh=Null)
	
		If mesh=Null Then Return
		
		If TMesh(Self)<>Null

			Self.TransformMesh(Self.mat)
			Self.AddMesh(mesh,False) ' don't use copymesh
			
		Endif
		
		CollapseChildren(Self,mesh)


	End 
	
	' used by LoadMesh
	' has to be function as we need to use this function with all entities and not just meshes
	Function CollapseChildren:Void(ent0:TEntity, mesh:TMesh=Null)

		For Local ent:TEntity=Eachin ent0.child_list
			If TMesh(ent)<>Null

				TMesh(ent).TransformMesh(ent.mat)
				TMesh(ent).AddMesh(mesh,False) 'dont use CopyMesh
			Endif
			CollapseChildren(ent,mesh)
			
		Next

		
	End 

	 
	
	
	Method MeshesIntersect:Bool( mesh2:TMesh)
		
		If mesh2 = Null Then Return False
		
		Local tree2:MeshCollider, hit:Bool = False
		Local vec1:Vector, vec2:Vector, vec3:Vector, vec4:Vector
		
		vec1 = New Vector(mesh2.mat.grid[0][0],mesh2.mat.grid[0][1],-mesh2.mat.grid[0][2])
		vec2 = New Vector(mesh2.mat.grid[1][0],mesh2.mat.grid[1][1],-mesh2.mat.grid[1][2])
		vec3 = New Vector(-mesh2.mat.grid[2][0],-mesh2.mat.grid[2][1],mesh2.mat.grid[2][2])
		vec4 = New Vector(mesh2.mat.grid[3][0],mesh2.mat.grid[3][1],-mesh2.mat.grid[3][2])
		
		Local mat1:Matrix = New Matrix(vec1,vec2,vec3)
		Local tform:Transform = New Transform(mat1,vec4)
		
		col_tree.CreateMeshTree(Self)	
		mesh2.col_tree.CreateMeshTree(mesh2) ' create collision tree for mesh if necessary
		tree2 = mesh2.col_tree.c_col_tree

		Local coll_obj:CollisionObject = New CollisionObject()
		hit = col_info.CollisionDetect(coll_obj, tform, tree2 ,COLLISION_METHOD_POLYGON)
		
		Return hit
		
	End
	
	
	Method AutoFade(cam:TCamera)

		Local dist#=cam.EntityDistance(Self)
		
		If dist>fade_near And dist<fade_far
		
			' fade_alpha will be in the range 0 (near) to 1 (far)
			fade_alpha=(dist-fade_near)/(fade_far-fade_near)
	
		Else
		
			' if entity outside near, far range then set min/max values
			If dist<fade_near Then fade_alpha=0.0 Else fade_alpha=1.0
			
		Endif

	End
	
	
	' used by MeshWidth, MeshHeight, MeshDepth, RenderWorld
	' overloaded by TBatchSprite
	Method GetBounds(reset:Bool = False)
	
		' only get new bounds if we have to
		' mesh.reset_bounds=True for all new meshes, plus set to True by various Mesh commands
		' scaling is not done here (since it can change per frame)
		' more accurately a CullBox than CullRadius
		' -- use vecbound[] to create tighter sphere
		If reset_bounds=True Or reset=true
		
			''can i sneak this in here?
			total_tris = GetTotalTris()
			
			reset_bounds=False
	
			min_x=999999999.0
			max_x=-999999999.0
			min_y=999999999.0
			max_y=-999999999.0
			min_z=999999999.0
			max_z=-999999999.0
			Local cc:Int=0
			
			For Local surf:TSurface=Eachin surf_list
				
				cc+=1
				
				For Local v:Int=0 Until surf.no_verts
					
					surf.vert_data.GetVertCoords(vec_temp,v)

					If vec_temp.x<min_x Then min_x=vec_temp.x; vecbounds[0] = vec_temp.Copy()
					If vec_temp.x>max_x Then max_x=vec_temp.x; vecbounds[1] = vec_temp.Copy()
					
					If vec_temp.y<min_y Then min_y=vec_temp.y; vecbounds[2] = vec_temp.Copy()
					If vec_temp.y>max_y Then max_y=vec_temp.y; vecbounds[3] = vec_temp.Copy()

					If vec_temp.z<min_z Then min_z=vec_temp.z; vecbounds[4] = vec_temp.Copy()
					If vec_temp.z>max_z Then max_z=vec_temp.z; vecbounds[5] = vec_temp.Copy()
				
				Next
			
			Next
			
			
			' get mesh width, height, depth
			Local width#=max_x-min_x
			Local height#=max_y-min_y
			Local depth#=max_z-min_z
			If cc=0 Then width=0.0; height=0.0; depth=0.0
'Print classname+" "+width+" "+height+" "+depth

			' get bounding sphere (cull_radius#) from AABB
			' only get cull radius (auto cull), if cull radius hasn't been set to a negative no. by TEntity.MeshCullRadius (manual cull)
			If cull_radius>=0
			
				If width>=height And width>=depth
					cull_radius=width
				Else
					If height>=width And height>=depth
						cull_radius=height
					Else
						cull_radius=depth
					Endif
				Endif

				cull_radius=cull_radius * 0.5
				Local crs#=cull_radius*cull_radius
				cull_radius= Sqrt(crs+crs+crs) ''need the cube corners to be in the sphere
				'cull_radius= Sqrt(cull_radius+cull_radius)
				
			Endif
			
			' mesh centre
			center_x=min_x+(width)*0.5
			center_y=min_y+(height)*0.5
			center_z=min_z+(depth)*0.5
		
		Endif

	End 
	
	''helper for entityradius
	Method GetSphereBounds:Float()
		''our bounds for a tight sphere is between xmin and xmax
		If (cull_radius=0.0) Or (reset_bounds=True)
			GetBounds()
		Endif
		
		Local center:Vector = New Vector(0,0,0)
		Local ss:Float = vecbounds[0].Distance(center)

			For Local i:Int=1 To 5
				Local j# = vecbounds[i].Distance(center)
				If j > ss
					''too small	if just one is over
					ss=j
				endif
			Next

			'Print "ss "+ss+" "+av

		
		Return ss
	End

	Method GetTotalTris:Int()
		
		Local t:Int=0
		For Local s:TSurface = Eachin surf_list
			t=t+s.no_tris
		Next
		Return t
		
	End

	' returns true if mesh is to be drawn with alpha, i.e alpha<1.0.
	' this func is also used to see whether entity should be manually depth sorted (if alpha=true then yes).
	' alpha_enable true/false is also set for surfaces - this is used to sort alpha surfaces and enable/disable alpha blending 
	'
	Method Alpha:Bool()
	
		' ***note*** func doesn't taken into account fact that surf brush blend modes override master brush blend mode
		' when rendering. shouldn't be a problem, as will only incorrectly return true if master brush blend is 2 or 3,
		' while surf blend is 1. won't crop up often, and if it does, will only result in blending being enabled when it
		' shouldn't (may cause interference if surf tex is masked?).

		Local alpha:Bool=False
				
		' check master brush (check alpha value, blend value, force vertex alpha flag)
		If (brush.alpha<1.0) Or brush.blend=2 Or brush.blend=3 Or brush.fx&32
			
			alpha=True
			'Return True
			''cut out early if the whole thing is alpha?? --no, need to set surfaces
			
		Else
		
			' tex 0 alpha flag
			If brush.tex[0]<>Null
				If brush.tex[0].flags&2<>0
					alpha= True
				Endif
			Endif
			
		Endif

		' check and set surf brushes
		For Local surf:TSurface=Eachin surf_list
		
			surf.alpha_enable=False
			
			If surf.brush<>Null
			
				If surf.brush.alpha<1.0 Or surf.brush.blend=2 Or surf.brush.blend=3 Or surf.brush.fx&32
				
					alpha=True
		
				Else
				
					If surf.brush.tex[0]<>Null
						If surf.brush.tex[0].flags&2<>0
							alpha=True
						Endif
					Endif
					
				Endif
			
			Endif
			
			' entity auto fade
			If fade_alpha<>0.0
				alpha=True
			Endif
			
			' set surf alpha_enable flag to true if mesh or surface has alpha properties
			If alpha=True
				surf.alpha_enable=True
			Endif
			
		Next
		
		using_alpha = alpha
		Return alpha


	End 
	
	'' SetNormalMapping
	'' -- creates tangent normal for shaders
	'' -- stores in color channel
	Method SetNormalMapping(single_surf:TSurface=Null)
		
		For Local surf:TSurface = Eachin surf_list
			
			Local tangent:Vector = New Vector(0.0,0.0,1.0)
			Local t2:Vector = New Vector()
			
			If single_surf <> Null And surf<>single_surf Then Continue ''if we only want one surface
			
			For Local tri:Int = 0 To surf.no_tris-1
				
				Local v0:Int = surf.TriangleVertex(tri,0)
				Local v1:Int = surf.TriangleVertex(tri,1)
				Local v2:Int = surf.TriangleVertex(tri,2)
				
				Local v2v0:Vector = surf.GetVertexCoords(v0)
				Local v2v1:Vector = surf.GetVertexCoords(v1)
				Local vert2:Vector = surf.GetVertexCoords(v2)
				
				Local c2c0:Vector = New Vector(surf.VertexU(v0),surf.VertexV(v0),0.0)
				Local c2c1:Vector = New Vector(surf.VertexU(v1),surf.VertexV(v1),0.0)
				Local c2:Vector = New Vector(surf.VertexU(v2),surf.VertexV(v2),0.0)

				v2v0 = v2v0.Subtract(vert2)
				v2v1 = v2v1.Subtract(vert2)
				
				c2c0 = c2c0.Subtract(c2)
				c2c1 = c2c1.Subtract(c2)
				
				Local cp:Float = c2c0.x * c2c1.y - c2c0.y * c2c1.x
				
				If Abs(cp) > 0.00001 ''divide by 0 error
					
					Local sca:Float = 1.0/cp ''scale to uv
					
					t2 = v2v1.Multiply(c2c0.y)
					tangent = (v2v0.Multiply(c2c1.y).Add( t2 )).Multiply(sca)
      				''bitangent = (Edge1 * -Edge2uv.x + Edge2 * Edge1uv.x) * sca
					
					tangent = tangent.Normalize()
					
				Endif
				
				''may need to smooth tangent normal, but would have to use a map to accumulate each iteration then avg
				
				''set color to tangent normal, find bitangent n cross t in shader
				surf.VertexColorFloat(v0,tangent.x,tangent.y,tangent.z,0.0)
				surf.VertexColorFloat(v1,tangent.x,tangent.y,tangent.z,0.0)
				surf.VertexColorFloat(v2,tangent.x,tangent.y,tangent.z,0.0)
				
			Next
			
		Next
		
	End
	
	''
	''- internal use to get the animating surface data
	Method GetAnimSurface:TSurface(surf:TSurface)
	
		Return anim_surf[surf.surf_id]
		
	End
	
	Method GetAnimSurface:TSurface(s:Int)
		
		If s<0 Or s>anim_surf.Length Then Return Null
		Return anim_surf[s-1]
		
	End
	
	
	Method ResetBones:Void()
		
		For Local bo:TBone = Eachin bones
			If bo
				bo.UpdateMatrix(bo.rest_mat)
			Endif
		Next
		
		UpdateChildren(Self)
	End
	
	
	Method UnWeldTriangles:Int(inSurf:TSurface=Null, updatenorms:Bool=true)
		
		Local list:List<TSurface> = surf_list
		If inSurf
			list = New List<TSurface>
			list.AddLast(inSurf)
		Endif
		
		Local newlist:List<TSurface> = New List<TSurface>
		
		For Local surf:TSurface = Eachin list
			
			Local newSurf:TSurface = surf.Copy()
			newSurf.ClearSurface(True,True)
			
			Local data0:Vertex, data1:Vertex, data2:Vertex, v0:Int,v1:Int,v2:Int, norm:Vector = New Vector
		
			For Local i:Int = 0 To surf.no_tris-1
				Local a0%=surf.TriangleVertex(i,0)
				Local a1%=surf.TriangleVertex(i,1)
				Local a2%=surf.TriangleVertex(i,2)
				v0 = newSurf.AddVertex(0.0,1.0,0.0)
				v1 = newSurf.AddVertex(0.0,0.0,1.0)
				v2 = newSurf.AddVertex(0.0,1.0,1.0)
				
				data0 = surf.GetVertex(a0)
				data1 = surf.GetVertex(a1)
				data2 = surf.GetVertex(a2)
				
				If updatenorms
					Local ax#=data1.x-data0.x
					Local ay#=data1.y-data0.y
					Local az#=-data1.z+data0.z
			
					Local bx#=data2.x-data1.x
					Local by#=data2.y-data1.y
					Local bz#=-data2.z+data1.z
		
					Local nx#=(ay*bz)-(az*by)
					Local ny#=(az*bx)-(ax*bz) 
					Local nz#=-(ax*by)+(ay*bx)

					norm.Update(nx,ny,nz)
					norm = norm.Normalize()
					data0.nx = norm.x
					data0.ny = norm.y
					data0.nz = norm.z
					data1.nx = norm.x
					data1.ny = norm.y
					data1.nz = norm.z
					data2.nx = norm.x
					data2.ny = norm.y
					data2.nz = norm.z

				Endif
				
				newSurf.SetVertex(v0,data0)
				newSurf.SetVertex(v1,data1)
				newSurf.SetVertex(v2,data2)
				
				newSurf.AddTriangle(v0,v1,v2)
				
			Next
			
			newSurf.CropSurfaceBuffers()
			newlist.AddLast(newSurf)
			
			surf.ClearSurface(True,True)


		Next
		
		surf_list.Clear()
		surf_list = newlist
		
		
		Return 1
		
	End
	
	'' Adds mesh to TRender 2D DrawList, drawn after all meshes
	Method Draw(x:Float, y:Float, no_scaling:Bool = False)
		
		''immediate mode draw to screen
		TRender.draw_list.AddLast(Self)
		''position
		Local w# '= TRender.width*0.5
		Local h# '= TRender.height*0.5
		If parent<>Null Then EntityParent(Null)
		'PositionEntity((x-w), (h-y), 1.99999)
		PositionEntity(x, y, 1.99999)
					
		''auto-scaling for sprites and ttext
		Local spr:TSprite = TSprite(Self)
		If Not no_scaling And spr<>Null
			spr.pixel_scale[0] = 1.0
			spr.pixel_scale[1] = 1.0
		
			If TText(Self)
				''mojo_font scx=12
				Local scx# = Int((TText(Self).char_pixels* TText(Self).pixel_ratio)+1.5) '0.5 rounds up
				spr.pixel_scale[0] = scx
				spr.pixel_scale[1] = scx	
'Print scx	
			Else
				Local scx# = Self.brush.GetTexture(0).width * 0.5 '' a sprite is 2 units wide (-1,1)
				Local scy# = Self.brush.GetTexture(0).height * 0.5
			
				spr.pixel_scale[0] = scx
				spr.pixel_scale[1] = scy
			Endif
			
		Endif
		
		'PositionEntity(0, 0, 1.999)
		
	End
	
	
	Method Wireframe:Void(w:Bool = True)
		
		wireframe = w
		
	End
	
	Method ClearMesh:Void()
		
		For Local s:TSurface = Eachin surf_list
			s.FreeSurface()
		Next
		no_surfs=0
		surf_list.Clear()
		
	End
	
	Method FlipSurfaceOrder:Void()
		
		Local ll:List<TSurface> = New List<TSurface>
		For Local ss:TSurface = Eachin surf_list
			ll.AddFirst(ss)
		Next
		surf_list = ll
	
	end
	
	'Method Update(cam:TCamera)
		
		''legacy use: may want to call Render()
		'Print "TMesh update"
		
	'End
	
	
	Method CreateSphereTree:Void ( idiv:Int, sz:Float=1.0, thresh:int=0 )
		col_tree.CreateSphereTree( Self, idiv, sz, thresh)
	End
	
	'' alpha 0.0-1.0
	Method DebugSphereTree:Void (alpha:Float=0.1)
		col_tree.DebugSphereTree(Self,alpha)
	End
	
	''-- is mesh offscreen?
	''Needs to render at least ONCE
	Method GetCulled:Bool()
		Return culled
	End
	
	''manually set cull status, if UpdateWorld is not used
	Method SetCulled:void(n:Bool=False)
		culled=n
	End
	
	''-- update the vertex anim surface to correct frame. used to update vertex animation
	Method UpdateVertexAnimFrame:Void(surf:TSurface, orig_surf:TSurface)
		
		If Not surf Then return
		''since mesh should hold the anim frames, we need this to unify the update to the surface. used only in rendering
		surf.anim_frame = Self.anim_surf_frame[orig_surf.surf_id]
		
		'' update the buffer every frame
		surf.reset_vbo = surf.reset_vbo|1

	End
	
End


	