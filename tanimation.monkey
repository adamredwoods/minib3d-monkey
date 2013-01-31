Import minib3d
Import minib3d.monkeybuffer

''
'' NOTES:
'' -- does not transform normals. TODO?


Class TVertexAnim Extends FloatBuffer
	
	Field offset:Int
	
	Function Create:TVertexAnim(i:Int=0)
	
		i2f= CreateDataBuffer(4)
	
		Local b:TVertexAnim = New TVertexAnim
		b.buf = CreateDataBuffer(i*SIZE+1)
		Return b
		
	End

End

Class TAnimation
	
	

	#If TARGET="xna"
	
		Const DONT_USE_VERT_POINTER:Int = True
	#Else
		Const DONT_USE_VERT_POINTER:Int = False
	
	#Endif
	
	Global quat:Quaternion
	
	Global new_mat:Matrix = New Matrix

	Global testi:Int=0
	
	Function AnimateMesh(ent1:TEntity,framef:Float,start_frame:Int,end_frame:Int)
		
		Local temp_vec:Vector = New Vector
		Local quat:Quaternion = New Quaternion
		
		Local mesh:TMesh = TMesh(ent1)
		
		If mesh<>Null
			
			If mesh.anim=0 Or mesh.Hidden() = True Then Return ' mesh contains no anim data
	
			mesh.anim_render=True
	
			' cap framef values
			If framef>end_frame Then framef=end_frame
			If framef<start_frame Then framef=start_frame
			
	
			For Local bent:TBone=Eachin mesh.bones
						
				If Not bent Continue
						
			
				' position
				temp_vec = bent.keys.GetPosition(framef, start_frame, end_frame)		
								
				' store current keyframe for use with transtions
				bent.kx=temp_vec.x
				bent.ky=temp_vec.y
				bent.kz=temp_vec.z
			
				' rotation
				quat = bent.keys.GetQuaternion(framef, start_frame, end_frame)
				
				
				' store current keyframe for use with transtions
				bent.kqw=quat.w
				bent.kqx=quat.x
				bent.kqy=quat.y
				bent.kqz=quat.z
		
				
				TBone(bent).Transform( temp_vec, quat, False)
								
			Next
			
			' update children when all bones are placed
			TBone.UpdateBoneChildren(mesh )
								
			' --- vertex deform ---
			VertexDeform(mesh)
		
		Endif
			
	End 
	
	' AnimateMesh2, used to animate transitions between animations, very similar to AnimateMesh except it
	' interpolates between current animation pose (via saved keyframe) and first keyframe of new animation.
	' framef:Float interpolates between 0 and 1
	
	Function AnimateMesh2(ent1:TEntity,framef:Float,start_frame,end_frame)
		
		Local temp_vec:Vector = New Vector
		
		Local mesh:TMesh = TMesh(ent1)
		
		If mesh<>Null
	
			If mesh.anim=0 Or mesh.Hidden() = True Then Return ' mesh contains no anim data
			
			mesh.anim_render=True
	
			'Local frame=framef ' float to int
			
			Local quat:Quaternion = New Quaternion
	
			For Local bent:TBone=Eachin mesh.bones
					
				Local i=0
				Local ii=0
				Local fd1:Float=framef ' fd1 always between 0 and 1 for this function
				Local fd2:Float=1.0-fd1 ' fd1+fd2 always equals 0 for this function
				Local found=False
				Local no_keys=False
				Local w1:Float
				
				' get current keyframe
				Local x1:Float=TBone(bent).kx
				Local y1:Float=TBone(bent).ky
				Local z1:Float=TBone(bent).kz
				
				Local w2:Float
				Local x2:Float
				Local y2:Float
				Local z2:Float
				
				Local flag=0
				
				' position
	
				' forwards
				'i=frame
				i=start_frame-1
				Repeat
					i=i+1
					If i>end_frame Then i=start_frame;ii=ii+1
					flag=TBone(bent).keys.flags[i]&1
					If flag
						x2=TBone(bent).keys.px[i]
						y2=TBone(bent).keys.py[i]
						z2=TBone(bent).keys.pz[i]
						'fd2=i-framef
						found=True
					Endif
				Until found=True Or ii>=2
				If found=False Then no_keys=True
				found=False
				ii=0
		
				Local px3:Float=0
				Local py3:Float=0
				Local pz3:Float=0
				If no_keys=True ' no keyframes
					px3=TBone(bent).n_px
					py3=TBone(bent).n_py
					pz3=TBone(bent).n_pz
				Else
					If fd1+fd2=0.0 ' one keyframe
						' if only one keyframe, fd1+fd2 will equal 0 resulting in division error and garbage positional values (which can affect children)
						' so we check for this, and if true then positional values equals x1,y1,z1 (same as x2,y2,z2)
						px3=x1
						py3=y1
						pz3=z1
					Else ' more than one keyframe
						Local fd_inv:Float = 1.0/(fd1+fd2)
						px3=(((x2-x1)*fd_inv)*fd1)+x1
						py3=(((y2-y1)*fd_inv)*fd1)+y1
						pz3=(((z2-z1)*fd_inv)*fd1)+z1
					Endif
				Endif
				no_keys=False
			
				' get current keyframe
				w1=TBone(bent).kqw
				x1=TBone(bent).kqx
				y1=TBone(bent).kqy
				z1=TBone(bent).kqz
					
				' rotation
	
				' forwards
				'i=frame
				i=start_frame-1
				Repeat
					i=i+1
					If i>end_frame Then i=start_frame;ii=ii+1
					flag=TBone(bent).keys.flags[i]&4
					If flag
						w2=TBone(bent).keys.qw[i]
						x2=TBone(bent).keys.qx[i]
						y2=TBone(bent).keys.qy[i]
						z2=TBone(bent).keys.qz[i]
						'fd2=i-framef
						found=True
					Endif
				Until found=True Or ii>=2
				If found=False Then no_keys=True
				found=False
				ii=0
	
				' interpolate keys
	
				Local w3:Float=0
				Local x3:Float=0
				Local y3:Float=0
				Local z3:Float=0
				If no_keys=True ' no keyframes
					w3=TBone(bent).n_qw
					x3=TBone(bent).n_qx
					y3=TBone(bent).n_qy
					z3=TBone(bent).n_qz
				Else
					If fd1+fd2=0.0 ' one keyframe
						' if only one keyframe, fd1+fd2 will equal 0 resulting in division error and garbage rotational values (which can affect children)
						' so we check for this, and if true then rotational values equals w1,x1,y1,z1 (same as w2,x2,y2,z2)
						w3=w1
						x3=x1
						y3=y1
						z3=z1
					Else ' more than one keyframe
						Local t:Float=(1.0/(fd1+fd2))*fd1
						quat = Quaternion.Slerp(x1,y1,z1,w1,x2,y2,z2,w2,t) ' interpolate between prev and next rotations
					Endif
				Endif
				no_keys=False
			
				temp_vec.Update(px3, py3, pz3)
				
				TBone(bent).Transform( temp_vec, quat)
				
		
			Next
								
			' --- vertex deform ---
			VertexDeform(mesh)
		
		Endif
			
	End 
	
	
	
	
	'' AnimateVertex()
	''
	'' -- does not handle frame interpolation for fractional frames, since VBO based
	Function AnimateVertex(ent:TEntity, frame:Float, start_frame:Int, end_frame:Int )
	
		''each key, interpolate all vert_anims
		
		Local vx:Float, vy:Float ,vz:Float, has_animation:Bool=False
		
		Local mesh:TMesh = TMesh(ent)
		If Not ent Then Return
		
		If frame>end_frame Then frame=end_frame
		If frame<start_frame Then frame=start_frame
		

		' cycle through all surfs
		Local anim_surf:TSurface
		For Local surf:TSurface=Eachin mesh.surf_list

			anim_surf = mesh.anim_surf[surf.surf_id]		
			If Not anim_surf Then Continue
			
			has_animation = True
			anim_surf.vbo_dyn = True
			
			'Local vanim:Int=0, pack:Int=0, pack_id:Int=0, get_next_pack:Int=1
			'Local va_id:Int=0		

			''point to new buffer			
			If anim_surf.vert_anim[frame]
			
				'If DONT_USE_VERT_POINTER = False
				
					anim_surf.anim_frame = frame
					anim_surf.reset_vbo = anim_surf.reset_vbo|1
					
				'Else
					
					'' --- per vertex memory copy, slow, used for XNA
					'For Local vid:Int=0 To anim_surf.no_verts-1
						'Local vv:Int = vid*3
						'anim_surf.vert_data.PokeVertCoords(vid, anim_surf.vert_anim[frame].Peek(vv), anim_surf.vert_anim[frame].Peek(vv+1), anim_surf.vert_anim[frame].Peek(vv+2))
					'Next 
					
					''update vbo
					'anim_surf.reset_vbo = anim_surf.reset_vbo|1
					
				'Endif
			
			Endif
			
		Next
		
		If has_animation Then mesh.anim_render=True
		
	End
	
	
	
	Function VertexDeform:Void(ent:TMesh)

		'Local ovx:Float,ovy:Float,ovz:Float ' original vertex positions
		Local ov:Vector = New Vector ' original vertex positions
		Local x:Float=0,y:Float=0,z:Float=0

		Local bone:TBone
		Local weight:Float
		

	
		' cycle through all surfs
		For Local surf:TSurface=Eachin ent.surf_list

			Local anim_surf:TSurface = ent.GetAnimSurface(surf)
			If Not anim_surf Then Continue
	
			' mesh shape will be changed, update reset_vbo flag (1=vertices move)
			anim_surf.reset_vbo = anim_surf.reset_vbo|1
			anim_surf.vbo_dyn = True
				
			Local vid:Int
			Local vid3:Int
			
			
			For Local vid:Int=0 To anim_surf.no_verts-1
				
				vid3=vid*3

				' BONE 1
				Local tweight:Float=0.0
				
				If anim_surf.vert_bone1_no[vid]<>0
					
					bone=ent.bones[anim_surf.vert_bone1_no[vid]-1]
					weight=anim_surf.vert_weight1[vid]
					tweight += weight
					
					If weight > 0.0
						' get original vertex position					
		
						'Local j:Int = vid3*4
						'ovx=surf.vert_data.VertexX(vid) 'surf.vert_coords.buf.PeekFloat(j+0) 'VertexX(vid)
						'ovy=surf.vert_data.VertexY(vid) 'surf.vert_coords.buf.PeekFloat(j+4) 'VertexY(vid)
						'ovz=surf.vert_data.VertexZ(vid) 'surf.vert_coords.buf.PeekFloat(j+8) 'VertexZ(vid)

						surf.vert_data.GetVertCoords(ov, vid)

						' transform vertex position with transform mat
						x= ( bone.tform_mat.grid[0][0]*ov.x + bone.tform_mat.grid[1][0]*ov.y + bone.tform_mat.grid[2][0]*ov.z + bone.tform_mat.grid[3][0] ) * weight '+ (1.0-weight)*ovx
						y= ( bone.tform_mat.grid[0][1]*ov.x + bone.tform_mat.grid[1][1]*ov.y + bone.tform_mat.grid[2][1]*ov.z + bone.tform_mat.grid[3][1] ) * weight '+ (1.0-weight)*ovy
						z= ( bone.tform_mat.grid[0][2]*ov.x + bone.tform_mat.grid[1][2]*ov.y + bone.tform_mat.grid[2][2]*ov.z + bone.tform_mat.grid[3][2] ) * weight '+ (1.0-weight)*ovz
						
					Endif
						
					' BONE 2

					If anim_surf.vert_bone2_no[vid]<>0 And anim_surf.vert_weight2[vid]>0.0
				
						bone=ent.bones[anim_surf.vert_bone2_no[vid]-1]
						weight=anim_surf.vert_weight2[vid]
						tweight += weight
						
						' transform vertex position with transform mat
						x+= ( bone.tform_mat.grid[0][0]*ov.x + bone.tform_mat.grid[1][0]*ov.y + bone.tform_mat.grid[2][0]*ov.z + bone.tform_mat.grid[3][0] ) * weight '+ (1.0-weight2-weight)*ovx
						y+= ( bone.tform_mat.grid[0][1]*ov.x + bone.tform_mat.grid[1][1]*ov.y + bone.tform_mat.grid[2][1]*ov.z + bone.tform_mat.grid[3][1] ) * weight '+ (1.0-weight2-weight)*ovy
						z+= ( bone.tform_mat.grid[0][2]*ov.x + bone.tform_mat.grid[1][2]*ov.y + bone.tform_mat.grid[2][2]*ov.z + bone.tform_mat.grid[3][2] ) * weight '+ (1.0-weight2-weight)*ovz
						
						' BONE 3
						
						If anim_surf.vert_bone3_no[vid]<>0 And anim_surf.vert_weight3[vid]>0.0

							bone=ent.bones[anim_surf.vert_bone3_no[vid]-1]
							weight=anim_surf.vert_weight3[vid]
							tweight +=weight

							' transform vertex position with transform mat
							x+= ( bone.tform_mat.grid[0][0]*ov.x + bone.tform_mat.grid[1][0]*ov.y + bone.tform_mat.grid[2][0]*ov.z + bone.tform_mat.grid[3][0] ) * weight '+ (1.0-weight3-weight2-weight)*ovx
							y+= ( bone.tform_mat.grid[0][1]*ov.x + bone.tform_mat.grid[1][1]*ov.y + bone.tform_mat.grid[2][1]*ov.z + bone.tform_mat.grid[3][1] ) * weight '+ (1.0-weight3-weight2-weight)*ovy
							z+= ( bone.tform_mat.grid[0][2]*ov.x + bone.tform_mat.grid[1][2]*ov.y + bone.tform_mat.grid[2][2]*ov.z + bone.tform_mat.grid[3][2] ) * weight '+ (1.0-weight3-weight2-weight)*ovz
										
							' BONE 4
							
							If anim_surf.vert_bone4_no[vid]<>0 And anim_surf.vert_weight4[vid]>0.0
		
								bone=ent.bones[anim_surf.vert_bone4_no[vid]-1]
								weight=anim_surf.vert_weight4[vid]
								tweight +=weight
								
								' transform vertex position with transform mat
								x+= ( bone.tform_mat.grid[0][0]*ov.x + bone.tform_mat.grid[1][0]*ov.y + bone.tform_mat.grid[2][0]*ov.z + bone.tform_mat.grid[3][0] ) * weight '+ (1.0-weight4-weight3-weight2-weight)*ovx
								y+= ( bone.tform_mat.grid[0][1]*ov.x + bone.tform_mat.grid[1][1]*ov.y + bone.tform_mat.grid[2][1]*ov.z + bone.tform_mat.grid[3][1] ) * weight '+ (1.0-weight4-weight3-weight2-weight)*ovy
								z+= ( bone.tform_mat.grid[0][2]*ov.x + bone.tform_mat.grid[1][2]*ov.y + bone.tform_mat.grid[2][2]*ov.z + bone.tform_mat.grid[3][2] ) * weight '+ (1.0-weight4-weight3-weight2-weight)*ovz
					
							Endif
					
						Endif
					
					Endif
				
					
					#rem
					'' if we need this, it can be added. try to use stock functions: TAnimation.NormaliseWeights()
					If tweight <1.0
						x+= (1.0-tweight)*ovx '*bone.n_sx
						y+= (1.0-tweight)*ovy '*bone.n_sy
						z+= (1.0-tweight)*ovz '*bone.n_sz
					Endif
					#End
					
					' update vertex position
					'anim_surf.VertexCoords(vid,x,y,z)
					
					anim_surf.vert_data.PokeVertCoords(vid,x,y,z)
					'Local j:= vid3*4
					'anim_surf.vert_coords.buf.PokeFloat(j+0,x)
					'anim_surf.vert_coords.buf.PokeFloat(j+4,y)
					'anim_surf.vert_coords.buf.PokeFloat(j+8,z)
					
				Endif

			Next
			
			
		Next
		
		
	End 
	
	' this function will normalise weights if their sum doesn't equal 1.0 (unused)
	Function NormaliseWeights(mesh:TMesh)
		
		Local anim_surf:TSurface
		
		' cycle through all surfs
		For Local surf:TSurface=Eachin mesh.surf_list
			
			anim_surf = mesh.anim_surf[surf.surf_id]
			
			If Not anim_surf Then Continue
			
				
			For Local vid=0 Until anim_surf.no_verts

				' normalise weights
		
				Local w1:Float=anim_surf.vert_weight1[vid]
				Local w2:Float=anim_surf.vert_weight2[vid]
				Local w3:Float=anim_surf.vert_weight3[vid]
				Local w4:Float=anim_surf.vert_weight4[vid]
				
					
				Local wt:Float=w1+w2+w3+w4
					
				' normalise weights if sum of them <> 1.0
																													
				If wt<0.99 Or wt>1.01
		
					Local wm:Float
					If wt<>0.0
						wm=1.0/wt
						w1=w1*wm
						w2=w2*wm
						w3=w3*wm
						w4=w4*wm
					Else
						wm=1.0
					Endif
										
				Endif
				
				If w1 < 0.001 Then w1 = 0.0
				If w1 > 0.999 Then w1 = 1.0
				If w2 < 0.001 Then w2 = 0.0
				If w2 > 0.999 Then w2 = 1.0
				If w3 < 0.001 Then w3 = 0.0
				If w3 > 0.999 Then w3 = 1.0
				If w4 < 0.001 Then w4 = 0.0
				If w4 > 0.999 Then w4 = 1.0
				
				anim_surf.vert_weight1[vid]=w1
				anim_surf.vert_weight2[vid]=w2
				anim_surf.vert_weight3[vid]=w3
				anim_surf.vert_weight4[vid]=w4
				
			Next
			
		Next
		
	End 


	'' LimitBoneWeights()
	'' --will reduce the influence of bones per vertex to n bones. n=4 has no effect
	'' --for mobile performance, use during initialization
	'' -- think about: adding a variable to mesh, that can allow immediate bone limits for LOD
	
	Function LimitBoneWeights(mesh:TMesh, no_bones:Int=1)
		
		If Not mesh Or no_bones > 3 Then Return
		
		Local anim_surf:TSurface
		
		For Local surf:TSurface=Eachin mesh.surf_list
			
			anim_surf = mesh.anim_surf[surf.surf_id]
			If Not anim_surf Then Continue
			
			For Local vid:Int =0 Until anim_surf.no_verts
			
				If no_bones < 4
					anim_surf.vert_bone4_no[vid]=0
				Endif
				If no_bones < 3
					anim_surf.vert_bone3_no[vid]=0
				Endif
				If no_bones < 2
					anim_surf.vert_bone2_no[vid]=0
				Endif
				
			Next
		Next
	
	End
	

	
	'' BoneToVertexAnim()
	''--converts bone animation to vertex animation
	''-- can get memory hungry
	Function BoneToVertexAnim:Void(mesh:TMesh)

		
		''find all keys
		'' each bone could have x number of keys
		Local maxkeys:Int=0
		For Local bone:TBone=Eachin mesh.bones
		
			If bone.keys.frames > maxkeys Then maxkeys = bone.keys.frames
			
		Next
		
		Local no_verts:Int=0
		Local surf:TSurface
		
		For surf = Eachin mesh.surf_list
			no_verts += surf.no_verts
			'surf.vert_anim = surf.vert_anim.Resize(maxkeys+1)
			
			Local anim_surf:TSurface = mesh.GetAnimSurface(surf)
			If Not anim_surf Then Continue
			
			anim_surf.vert_anim = New TVertexAnim[maxkeys+1]
		Next

		Local qx:Float, qy:Float, qz:Float, qw:Float, rot:Float[4]
		Local bPos:Vector, bQuat:Quaternion
		Local basemesh:Float[no_verts*3]
		
		
		''maxkeys is inclusive i guess (not maxkeys-1)
		For Local i:Int =0 To maxkeys
		
			For Local bone:TBone=Eachin mesh.bones			
					
				bPos= bone.keys.GetPosition(i,0,bone.keys.frames)
				bQuat= bone.keys.GetQuaternion(i,0,bone.keys.frames)
								
				bone.Transform(bPos, bQuat)
								
			Next
			
						
			''deform & store
			''mesh.anim_surf[] holds new vert info
			VertexDeform(mesh)
			
			
			Local vx:Float, vy:Float, vz:Float
			Local sid:Int
			Local ov:Vector = New Vector
						
			
			For surf = Eachin mesh.surf_list
				
				Local pack:Int=0, pack_id:Int=0
				Local no_anim_verts:Int=0
				Local org_surf:TSurface = mesh.anim_surf[surf.surf_id]
				
				If Not org_surf Then Continue
				
				'org_surf.vert_anim[i] = New TVertexAnim ''new set of anim keys per surface			
				org_surf.vert_anim[i] = TVertexAnim.Create(surf.no_verts*3)
				
				sid = surf.surf_id
		
				For Local j:Int =0 To surf.no_verts-1
					
					Local j3:Int = j*3
											
					'surf.vert_anim[i].vert_buffer.Poke(j3+0, mesh.anim_surf[sid].vert_coords.Peek(j3+0))
					'surf.vert_anim[i].vert_buffer.Poke(j3+1, mesh.anim_surf[sid].vert_coords.Peek(j3+1))
					'surf.vert_anim[i].vert_buffer.Poke(j3+2, mesh.anim_surf[sid].vert_coords.Peek(j3+2))
					org_surf.vert_data.GetVertCoords(ov, j)
					org_surf.vert_anim[i].PokeVertCoords(j,ov.x, ov.y, ov.z)
					'surf.vert_anim[i].vert_buffer[j3+0]= mesh.anim_surf[sid].vert_data.VertexX(j)
					'surf.vert_anim[i].vert_buffer[j3+1]= mesh.anim_surf[sid].vert_data.VertexY(j)
					'surf.vert_anim[i].vert_buffer[j3+2]= mesh.anim_surf[sid].vert_data.VertexZ(j)
					
				Next ''all verts

				
			Next 'all surfs
			
			
		Next 'all keys
		
		''clear bones & bone keys
		For Local e:TEntity = Eachin mesh.child_list
			e.FreeEntity()
		Next
		
		
		''set new anim=2 number for vert animation
		mesh.ActivateVertexAnim()

	End

End	
	



Class TAnimationKeys

	Field frames:Int
	Field flags:Int[1]
	Field px:Float[1]
	Field py:Float[1]
	Field pz:Float[1]
	Field sx:Float[1]
	Field sy:Float[1]
	Field sz:Float[1]
	Field qw:Float[1]
	Field qx:Float[1]
	Field qy:Float[1]
	Field qz:Float[1]
	
	Method New()
	

	
	End Method
	
	Method Delete()
	

	
	End Method
	
	Method Copy:TAnimationKeys()
	
		Local keys:TAnimationKeys=New TAnimationKeys
	
		keys.frames=frames
		keys.flags=flags[..]
		keys.px=px[..]
		keys.py=py[..]
		keys.pz=pz[..]
		keys.sx=sx[..]
		keys.sy=sy[..]
		keys.sz=sz[..]
		keys.qw=qw[..]
		keys.qx=qx[..]
		keys.qy=qy[..]
		keys.qz=qz[..]

		Return keys
	
	End Method
	
	
	'' loop is reserved for future
	Method GetPosition:Vector(frame:Float, f_start:Int, f_end:Int, loop:Bool = True)
		
		Local i:Int=0
		Local ii:Int=0
		Local fd1:Float=0 ' anim time since last key
		Local fd2:Float=0 ' anim time until next key
		Local found:Bool=False
		Local no_keys:Bool=False
		Local w1:Float
		Local x1:Float
		Local y1:Float
		Local z1:Float
		Local w2:Float
		Local x2:Float
		Local y2:Float
		Local z2:Float
		
		Local flag:Int=0
		
		' position
				
		' backwards
		i=Int(frame)+1
		
		Repeat
		
			i=i-1
			flag=flags[i]&1 'pos
			If flag
				x1=px[i]
				y1=py[i]
				z1=pz[i]
				fd1=frame-i
				found=True
			Endif
			If i<=f_start Then i=f_end+1;ii=ii+1
			
		Until found=True Or ii>=2
		
		If found=False Then no_keys=True
		found=False
		ii=0
		
		' forwards
		i=Int(frame)
		Repeat
		
			i=i+1
			If i>f_end Then i=f_start ;ii=ii+1
			flag=flags[i]&1
			If flag
				x2=px[i]
				y2=py[i]
				z2=pz[i]
				fd2=i-frame
				found=True
			Endif
			
		Until found=True Or ii>=2
		
		If found=False Then no_keys=True
		found=False
		ii=0

		Local px3:Float=0
		Local py3:Float=0
		Local pz3:Float=0
		If no_keys=True ' no keyframes
			px3=0
			py3=0
			pz3=0
		Else
			If fd1+fd2=0.0 ' one keyframe
				' if only one keyframe, fd1+fd2 will equal 0 resulting in division error and garbage positional values (which can affect children)
				' so we check for this, and if true then positional values equals x1,y1,z1 (same as x2,y2,z2)
				px3=x1
				py3=y1
				pz3=z1
			Else ' more than one keyframe
				Local fd_inv:Float = 1.0/(fd1+fd2)
				px3=(((x2-x1)*fd_inv)*fd1)+x1
				py3=(((y2-y1)*fd_inv)*fd1)+y1
				pz3=(((z2-z1)*fd_inv)*fd1)+z1
			Endif
		Endif
		no_keys=False
				
		Return New Vector(px3,py3,pz3)
	End
	
	'' loop is reserved for future
	Method GetQuaternion:Quaternion(frame:Float, f_start:Int, f_end:Int, loop:Bool = True)
	
		Local i:Int=0
		Local ii:Int=0
		Local fd1:Float=0 ' anim time since last key
		Local fd2:Float=0 ' anim time until next key
		Local found:Bool=False
		Local no_keys:Bool=False
		Local w1:Float
		Local x1:Float
		Local y1:Float
		Local z1:Float
		Local w2:Float
		Local x2:Float
		Local y2:Float
		Local z2:Float
		Local flag:Int =0
		
		Local quat:Quaternion = New Quaternion
		
		i=Int(frame)+1
		Repeat
			i=i-1
			flag=flags[i]&4
			If flag
				w1=qw[i]
				x1=qx[i]
				y1=qy[i]
				z1=qz[i]
				fd1=frame-i
				found=True
			Endif
			If i<=f_start Then i=f_end+1;ii=ii+1
		Until found=True Or ii>=2
		
		If found=False Then no_keys=True
		found=False
		ii=0
		
		' forwards
		i=Int(frame)
		
		Repeat
			i=i+1
			If i>f_end Then i=f_start;ii=ii+1
			flag=flags[i]&4
			If flag
				w2=qw[i]
				x2=qx[i]
				y2=qy[i]
				z2=qz[i]
				fd2=i-frame
				found=True
			Endif
		Until found=True Or ii>=2
		
		If found=False Then no_keys=True
		found=False
		ii=0

		' interpolate keys

		Local w3:Float=0
		Local x3:Float=0
		Local y3:Float=0
		Local z3:Float=0
		If no_keys=True ' no keyframes
			quat.w=1.0
			quat.x=0
			quat.y=0
			quat.z=0
		Else
			If fd1+fd2=0.0 ' one keyframe
				' if only one keyframe, fd1+fd2 will equal 0 resulting in division error and garbage rotational values (which can affect children)
				' so we check for this, and if true then rotational values equals w1,x1,y1,z1 (same as w2,x2,y2,z2)
				quat.w=w1
				quat.x=x1
				quat.y=y1
				quat.z=z1
			Else ' more than one keyframe
				Local t:Float=(1.0/(fd1+fd2))*fd1
				quat = Quaternion.Slerp(x1,y1,z1,w1,x2,y2,z2,w2,t) ' interpolate between prev and next rotations
			Endif
		Endif

		Return quat
	
	End
	
End 



