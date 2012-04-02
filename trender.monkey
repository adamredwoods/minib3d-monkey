Import minib3d

'flags
Const DISABLE_MAX2D=1	' true to enable max2d/minib3d integration --not in use for now
Const DISABLE_VBO=2	' true to use vbos if supported by hardware
Const USE_GL20 = 4 	' future use for opengl 2.0 support

Const VBO_MIN_TRIS=10	' if USE_VBO=True and vbos are supported by hardware, then surface must also have this minimum no. of tris before vbo is used for surface (vbos work best with surfaces with high amount of tris)


Function SetRender(r:TRender, flags:Int=0)

	TRender.render = r
	
	TRender.render.GraphicsInit(flags)
	
End


Class TRender

	Global render:TRender
	Global vbo_enabled:Bool=False ' this is set in GraphicsInit - will be set to true if USE_VBO is true and the hardware supports vbos
	
	Global shader_enabled:Bool = False
	
	Global width:Int,height:Int,mode:Int,depth:Int,rate:Int
	
	Global wireframe:Bool=False ''draw meshes as lines or filled

	Private
	
	Global render_list:List<TMesh> = New List<TMesh>
	Global render_alpha_list:RenderAlphaList = New RenderAlphaList
	Global alpha_pass:Int = 0 ''for optimizing the TMesh render routine
	
	Public
	
	
	
	Method Reset:Void() Abstract ''reset for each camera
	
	Method GraphicsInit:Int(flags:Int=0) Abstract
	
	Method Render:Void(ent:TEntity, cam:TCamera = Null) Abstract
	
	
	''-------------------------------------------------------
	
	
	Function ClearWorld(entities=True,brushes=True,textures=True)
	
		If entities
			
			For Local ent:TEntity=Eachin TEntity.entity_list
				ent.FreeEntity()
				ent=Null
			Next
			
			ClearCollisions
			
			ClearList(TPick.ent_list)
			TPick.picked_ent=Null
			TPick.picked_surface=Null
			
		Endif
		
		If textures
		
			For Local tex:TTexture=Eachin TTexture.tex_list
				tex.FreeTexture()
			Next
		
		Endif
	
	End 
			
	
	Function UpdateWorld(anim_speed#=1.0)
		
		' collision
		
		CollisionInfo.UpdateCollisions()
		
		' anim
	
		Local first:Int
		Local last:Int


		For Local mesh:TEntity=Eachin TEntity.entity_list
		
			If mesh.anim And mesh.anim_update=True
			
				first=mesh.anim_seqs_first[mesh.anim_seq]
				last=mesh.anim_seqs_last[mesh.anim_seq]
		
				Local anim_start=False

				If mesh.anim_trans>0
				
					mesh.anim_trans=mesh.anim_trans-1
					If mesh.anim_trans=1 Then anim_start=True
					
				Endif
				
				If mesh.anim_trans>0
				
					Local r#=1.0-mesh.anim_time
					r=r/mesh.anim_trans
					mesh.anim_time=mesh.anim_time+r
									
					If mesh.anim = 1
					
						TAnimation.AnimateMesh2(mesh,mesh.anim_time,first,last)
						
					Elseif mesh.anim = 2
					
						TAnimation.AnimateVertex(mesh,mesh.anim_time,first,last)
						
					Endif
					
					If anim_start=True Then mesh.anim_time=first
			
				Else
				
					If mesh.anim = 1
					
						TAnimation.AnimateMesh(mesh,mesh.anim_time,first,last)
						
					Elseif mesh.anim = 2
					
						TAnimation.AnimateVertex(mesh,mesh.anim_time,first,last)
						
					Endif
					
					If mesh.anim_mode=0 ''stop animation
						
						mesh.anim_update=False ' after updating animation so that animation is in final 'stop' pose - don't update again
		
					Elseif mesh.anim_mode=1 ''loop animation (default)
			
						mesh.anim_time=mesh.anim_time+(mesh.anim_speed*anim_speed)
						If mesh.anim_time>last
							mesh.anim_time=first+(mesh.anim_time-last)
						Endif
					
					Elseif mesh.anim_mode=2 ''ping pong
					
						If mesh.anim_dir=1
							mesh.anim_time=mesh.anim_time+(mesh.anim_speed*anim_speed)
							If mesh.anim_time>last
								mesh.anim_time=mesh.anim_time-(mesh.anim_speed*anim_speed)
								mesh.anim_dir=-1
							Endif
						Endif
						
						If mesh.anim_dir=-1
							mesh.anim_time=mesh.anim_time-(mesh.anim_speed*anim_speed)
							If mesh.anim_time<first
								mesh.anim_time=mesh.anim_time+(mesh.anim_speed*anim_speed)
								mesh.anim_dir=1
							Endif
						Endif
					
					Elseif mesh.anim_mode=3 ''one-shot, hold at end
			
						mesh.anim_time=mesh.anim_time+(mesh.anim_speed*anim_speed)
						If mesh.anim_time>last
							mesh.anim_time=last
							mesh.anim_mode=0
						Endif
					
					Endif
					
				Endif
							
			Endif
		
		Next

	End 

	
	
	
	Function RenderWorld:Void()
	
		If Not TCamera.cam_list Then Return
		
		For Local cam:TCamera=Eachin TCamera.cam_list

			'If cam.parent_hidden=True Or cam.hidden=True Then Continue
			If cam.Hidden()=True Then Continue

			TRender.render.RenderCamera(cam)

		Next


	End 
	
	
	Method RenderCamera:Void(cam:TCamera, skip:Int=0)
	
		'' use skip to render without updating camera
		'' would be useful for FSAA, FBOs, or a render layer system
		If (Not skip) Then cam.Update()
	
		
		For Local light:TLight=Eachin TLight.light_list
	
			light.Update(cam) ' EntityHidden code inside Update
			
		Next

		render_list.Clear()
		render_alpha_list.Clear()
		
		''Perform camera clipping, alpha ordering, and entity sort
		Local mesh:TMesh
		Local alpha_count:Int=0

		
		Reset() ''reset render
		
		For Local ent:TEntity=Eachin TEntity.entity_list
			
			'' reject non-mesh
			mesh = TMesh( ent )
			
			If mesh				
				
				'If mesh.parent_hidden=True Or mesh.hidden=True Or mesh.brush.alpha=0.0 Then Continue
				If mesh.Hidden()=True Or mesh.brush.alpha=0.0 Then Continue
				
				''cam layer mode
				If (mesh.is_cam_layer Or cam.is_cam_layer) And mesh.cam_layer <> cam Then Continue
				
				' get new bounds
				mesh.GetBounds()
		
				' Perform frustum cull
				
				Local inview:Int =cam.EntityInFrustum(mesh)
	
				If inview
				
					If mesh.auto_fade=True Then mesh.AutoFade(cam)
					
					If mesh.is_sprite Or mesh.is_update
				
						mesh.Update(cam ) ' rotate sprites with respect to current cam					
						
					Endif
		
					If mesh.Alpha()
						
						''alpha entities are drawn last
						
						mesh.alpha_order=cam.EntityDistanceSquared(mesh)
						render_alpha_list.AddLast(mesh)


					Else
					
						mesh.alpha_order=0.0
						TRender.render.Render(mesh,cam)
						
					Endif
					
				Endif
			Endif
					
		Next

				
		' Draw everything in alpha render list
		
		render_alpha_list.Sort() ''sorting alpha_order
		TRender.alpha_pass = 1 ''skip non-alpha surface pass
		
		For mesh = Eachin render_alpha_list

			TRender.render.Render(mesh,cam)

		Next
		
	End
	
	
	Function Wireframe(enable:Bool)
	
		wireframe = enable
		
	End 
	
	Method ReloadSurfaces:Int()
		
		Return 0
	End
	
End



''----------------------------------------------------


Class OpenglES11 Extends TRender
	
	
	''used for optimizing the fixed-pipeline render routine
	
	Global alpha_list:SurfaceAlphaList = New SurfaceAlphaList  ''used to draw and sort alpha surfaces last
	'Global alpha_anim_list:SurfaceAlphaList = New SurfaceAlphaList  ''no need-- connected anim_surf t surf

	Global last_texture:TTexture ''used to preserve texture states
	Global last_sprite:TSurface ''used to batch sprite state switching

	Global disable_depth:Bool = False '' used for EntityFx 64 - disable depth testing
	
	
	
	Method New()
		
	End
	
	Method Reset:Void()
		
		''reset globals used for state caching
		last_texture = Null ''used to preserve texture states
		last_sprite = Null ''used to preserve last surface states
		TRender.alpha_pass = 0
		
		'Print "....begin render...."
		
	End
	
	Method Render:Void(ent:TEntity, cam:TCamera = Null)
		
		Local mesh:TMesh = TMesh(ent)
		
		If Not mesh Then Return
		
		Local name$=ent.EntityName()
	
		Local fog=False
		If glIsEnabled(GL_FOG)=GL_TRUE Then fog=True ' if fog enabled, we'll enable it again at end of each surf loop in case of fx flag disabling it
	
		glDisable(GL_ALPHA_TEST)


		Local anim_surf2:TSurface
		Local ccc:Int=0 ''counter for debugging
		
		'' draw surfaces with alpha last
		Local temp_list:List<TSurface> = mesh.surf_list
		alpha_list.Clear()
	
		
		''run through surfaces twice, sort alpha surfaces for second pass
		For Local alphaloop:= alpha_pass To 1 ''if alpha_pass is on, no need to reorder alpha surfs
		
		For Local surf:TSurface =Eachin temp_list
			ccc +=1


			''draw alpha surfaces last in second loop
			''also catch surfaces with no vertex
			If surf.no_verts=0 Then Continue
			If (surf.alpha_enable And alphaloop < 1)
			
				alpha_list.AddLast(surf)				
				Continue
				
			Endif
			
			''batch optimizations (sprites/meshes)
			Local skip_sprite_state:Bool = False
			If last_sprite = surf
				skip_sprite_state = True
			Else
				last_sprite = surf
			Endif
			
					
'Print "***classname: "+ent.classname+" : "+name			
'Print "   alphaloop "+alphaloop+" "+" tribuffersize:"+surf.tris.Size()+", tris:"+surf.no_tris+", verts:"+surf.no_verts
'Print "   surfpass "+ccc+":"+alpha_pass+" vbo:"+surf.vbo_id[0]+" dynvbo:"+Int(surf.vbo_dyn)+" skip:"+Int(skip_sprite_state)
'Print "   mesh.anim:"+mesh.anim
'Print "   vboids:"+surf.vbo_id[0]+" "+surf.vbo_id[1]+" "+surf.vbo_id[2]+" "+surf.vbo_id[3]+" "+surf.vbo_id[4]+" "+surf.vbo_id[5]+" "
		

			
			Local vbo:Int=False
			
			If surf.no_tris>=VBO_MIN_TRIS And vbo_enabled
				vbo=True
			Else
				' if surf no longer has required no of tris then free vbo
				If surf.vbo_id[0]<>0 
					glDeleteBuffers(6,surf.vbo_id)
				Endif
			Endif

			' update surf vbo if necessary
			If vbo
				
				' update vbo
				If surf.reset_vbo<>0
					UpdateVBO(surf)
				Else If surf.vbo_id[0]=0 ' no vbo - unknown reason
					surf.reset_vbo=-1
					UpdateVBO(surf)

				Endif
				
			Endif
	
			If mesh.anim
			
				' get anim_surf
				anim_surf2 = mesh.anim_surf[surf.surf_id] ''(edit 2012)
				
				If vbo
				
					' update vbo
					If anim_surf2.reset_vbo<>False
						UpdateVBO(anim_surf2)
					Else If anim_surf2.vbo_id[0]=0 ' no vbo - unknown reason
						anim_surf2.reset_vbo=-1
						UpdateVBO(anim_surf2)
					Endif
				
				Endif
				
			Endif
			
			Local red#,green#,blue#,alpha#,shine#,blend:Int,fx:Int
			Local ambient_red#,ambient_green#,ambient_blue#

			' get main brush values
			red  =ent.brush.red
			green=ent.brush.green
			blue =ent.brush.blue
			alpha=ent.brush.alpha
			shine=ent.brush.shine
			blend =ent.brush.blend
			fx    =ent.brush.fx
			
			' combine surface brush values with main brush values
			If surf.brush

				Local shine2#=0.0

				red   =red  *surf.brush.red
				green =green*surf.brush.green
				blue  =blue *surf.brush.blue
				alpha =alpha *surf.brush.alpha
				shine2=surf.brush.shine
				If shine=0.0 Then shine=shine2
				If shine<>0.0 And shine2<>0.0 Then shine=shine*shine2
				If blend=0 Then blend=surf.brush.blend ' overwrite master brush if master brush blend=0
				fx=fx|surf.brush.fx
			
			Endif
			
			' take into account auto fade alpha
			alpha=alpha-ent.fade_alpha

	
			' if surface contains alpha info, enable blending

			If ent.alpha_order<>0.0
				
				If ent.brush.alpha<1.0
					''the entire entity
					glEnable(GL_BLEND)
					glDepthMask(False)
				Elseif surf.alpha_enable=True
					''just one surface
					glEnable(GL_BLEND)
					glDepthMask(False)
				Else
					''entity flagged for alpha, but not this surface
					glDisable(GL_BLEND)
					glDepthMask(True)
				Endif
			Else
				glDisable(GL_BLEND)
				glDepthMask(True)

			Endif



			' blend modes
			Select blend
				Case 0
					glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA) ' alpha
				Case 1
					glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA) ' alpha
				Case 2
					glBlendFunc(GL_DST_COLOR,GL_ZERO) ' multiply
				Case 3
					glBlendFunc(GL_SRC_ALPHA,GL_ONE) ' additive and alpha
				Case 4
					glBlendFunc(GL_ONE,GL_ONE) ' blend after texture

			End Select


			
			' fx flag 1 - full bright ***todo*** disable all lights?
			If fx&1
				ambient_red  =1.0
				ambient_green=1.0
				ambient_blue =1.0
			Else
				ambient_red  =TLight.ambient_red
				ambient_green=TLight.ambient_green
				ambient_blue =TLight.ambient_blue
			Endif

			'' --------------------------------------
			If skip_sprite_state = False


			' fx flag 2 - vertex colors ***todo*** disable all lights?
			If fx&2
				'glColorMaterial(GL_FRONT_AND_BACK, GL_AMBIENT_AND_DIFFUSE)
				glEnable(GL_COLOR_MATERIAL)
							
			Else
				glDisable(GL_COLOR_MATERIAL)
			Endif
			
			' fx flag 4 - flatshaded
			If fx&4
				glShadeModel(GL_FLAT)
			Else
				glShadeModel(GL_SMOOTH)
			Endif

			' fx flag 8 - disable fog
			If fx&8
				glDisable(GL_FOG)
			Endif
			
			' fx flag 16 - disable backface culling
			If fx&16
				glDisable(GL_CULL_FACE)
			Else
				glEnable(GL_CULL_FACE)
			Endif
			
			'' fx flag 32 - force alpha
			
			'' fx flag 64 - disable depth testing (new 2012)
			If fx&64
			
				glDisable(GL_DEPTH_TEST)
				disable_depth = True
				
			Elseif disable_depth = True
			
				glEnable(GL_DEPTH_TEST)
				disable_depth = False
				
			Endif
		
	
			If vbo
			
				If mesh.anim_render
					glBindBuffer(GL_ARRAY_BUFFER,anim_surf2.vbo_id[0])
					glVertexPointer(3,GL_FLOAT,0,0)
				Else
					glBindBuffer(GL_ARRAY_BUFFER,surf.vbo_id[0])
					glVertexPointer(3,GL_FLOAT,0,0)
				Endif
							
				glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,surf.vbo_id[5])
					
				glBindBuffer(GL_ARRAY_BUFFER,surf.vbo_id[3])
				glNormalPointer(GL_FLOAT,0,0)
				
				If(fx&2)
					glBindBuffer(GL_ARRAY_BUFFER,surf.vbo_id[4])
					glColorPointer(4,GL_FLOAT,0,0)
				Endif

			Else
		
				glBindBuffer(GL_ARRAY_BUFFER,0) ' reset - necessary for when non-vbo surf follows vbo surf
				glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,0)
			
				If mesh.anim_render
					glVertexPointer(3,GL_FLOAT,0,anim_surf2.vert_coords.buf)
				Else
					glVertexPointer(3,GL_FLOAT,0,surf.vert_coords.buf)
				Endif
				
				If(fx&2) glColorPointer(4,GL_FLOAT,0,surf.vert_col.buf)
				
				glNormalPointer(GL_FLOAT,0,surf.vert_norm.buf)
			
			Endif
			
			
			Endif ''end sprite_skip_state--------------------------------------
			
			
			''single case for batch animation
			If vbo And skip_sprite_state And (mesh.anim_render Or surf.vbo_dyn)
			
					glBindBuffer(GL_ARRAY_BUFFER,anim_surf2.vbo_id[0])
					glVertexPointer(3,GL_FLOAT,0,0)

			Endif
					
					
					
			' light + material color

			Local ambient#[]=[ambient_red,ambient_green,ambient_blue,1.0]	
			glLightModelfv(GL_LIGHT_MODEL_AMBIENT,ambient)

			Local no_mat#[]=[0.0,0.0,0.0,0.0]
			Local mat_ambient#[]=[red,green,blue,alpha]
			Local mat_diffuse#[]=[red,green,blue,alpha]
			Local mat_specular#[]=[shine,shine,shine,shine]
			Local mat_shininess#[]=[100.0] ' upto 128
			
			''GL_FRONT_AND_BACK needed for opengl es 1.x
			
			glMaterialfv(GL_FRONT_AND_BACK,GL_DIFFUSE,mat_diffuse) ''combine diffuse & ambient?
			glMaterialfv(GL_FRONT_AND_BACK,GL_AMBIENT,mat_ambient)
			glMaterialfv(GL_FRONT_AND_BACK,GL_SPECULAR,mat_specular)
			glMaterialfv(GL_FRONT_AND_BACK,GL_SHININESS,mat_shininess)
			
			glColor4f(1.0,0.0,0.0, alpha)
			
				
			' textures
			Local tex_count=0	
			
			tex_count=ent.brush.no_texs
			'If surf.brush<>Null
				If surf.brush.no_texs>tex_count Then tex_count=surf.brush.no_texs
			'EndIf

			For Local ix=0 To tex_count-1			
	
				If surf.brush.tex[ix]<>Null Or ent.brush.tex[ix]<>Null
					
					Local texture:TTexture,tex_flags,tex_blend,tex_coords,tex_u_scale,tex_v_scale
					Local tex_u_pos,tex_v_pos,tex_ang,tex_cube_mode,frame, tex_smooth


					' Main brush texture takes precedent over surface brush texture
					If ent.brush.tex[ix]<>Null
						texture=ent.brush.tex[ix]
						tex_flags=ent.brush.tex[ix].flags
						tex_blend=ent.brush.tex[ix].blend
						tex_coords=ent.brush.tex[ix].coords
						tex_u_scale=ent.brush.tex[ix].u_scale
						tex_v_scale=ent.brush.tex[ix].v_scale
						tex_u_pos=ent.brush.tex[ix].u_pos
						tex_v_pos=ent.brush.tex[ix].v_pos
						tex_ang=ent.brush.tex[ix].angle
						tex_cube_mode=ent.brush.tex[ix].cube_mode
						frame=ent.brush.tex_frame
						tex_smooth = ent.brush.tex[ix].tex_smooth		
					Else
						texture=surf.brush.tex[ix]
						tex_flags=surf.brush.tex[ix].flags
						tex_blend=surf.brush.tex[ix].blend
						tex_coords=surf.brush.tex[ix].coords
						tex_u_scale=surf.brush.tex[ix].u_scale
						tex_v_scale=surf.brush.tex[ix].v_scale
						tex_u_pos=surf.brush.tex[ix].u_pos
						tex_v_pos=surf.brush.tex[ix].v_pos
						tex_ang=surf.brush.tex[ix].angle
						tex_cube_mode=surf.brush.tex[ix].cube_mode
						frame=surf.brush.tex_frame
						tex_smooth = surf.brush.tex[ix].tex_smooth		
					Endif
	
	
					''preserve texture states--------------------------------------
					If (surf.brush.tex[ix] And last_texture = surf.brush.tex[ix]) Or
					    (ent.brush.tex[ix] And last_texture = ent.brush.tex[ix])
						
						'' skip texture Bind
						
					Else
					
					''texture bind
					
					If ent.brush.tex[ix] Then last_texture = ent.brush.tex[ix] Else last_texture = surf.brush.tex[ix]
						
					glActiveTexture(GL_TEXTURE0+ix)
					glClientActiveTexture(GL_TEXTURE0+ix)

					
					glBindTexture(GL_TEXTURE_2D,texture.gltex[frame]) ' call before glTexParameteri
	
					
					Endif ''end preserve texture states---------------------------------
					
					
					glEnable(GL_TEXTURE_2D)
					
					
					''assuming sprites with same surfaces are identical, preserve states---------
					If Not skip_sprite_state
					
					
					' masked texture flag
					If tex_flags&4<>0
						glEnable(GL_ALPHA_TEST)
					Else
						glDisable(GL_ALPHA_TEST)
					Endif
				
					' mipmapping texture flag
					If tex_flags&8<>0
						glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR)
						glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_LINEAR)
					Else
						If tex_smooth
							glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR)
							glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR)
						Else
							glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST)
							glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST)
						Endif
					Endif
					
					' clamp u flag
					If tex_flags&16<>0
						glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_CLAMP_TO_EDGE)
					Else						
						glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_REPEAT)
					Endif
					
					' clamp v flag
					If tex_flags&32<>0
						glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_CLAMP_TO_EDGE)
					Else
						glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_REPEAT)
					Endif
			

			#rem	
					' cubic environment map texture flag
					If tex_flags&128<>0
		
						glEnable(GL_TEXTURE_CUBE_MAP)
						glBindTexture(GL_TEXTURE_CUBE_MAP,texture.gltex[frame]) ' call before glTexParameteri
						
						glTexParameteri(GL_TEXTURE_CUBE_MAP,GL_TEXTURE_WRAP_S,GL_CLAMP_TO_EDGE)
						glTexParameteri(GL_TEXTURE_CUBE_MAP,GL_TEXTURE_WRAP_T,GL_CLAMP_TO_EDGE)
						glTexParameteri(GL_TEXTURE_CUBE_MAP,GL_TEXTURE_WRAP_R,GL_CLAMP_TO_EDGE)
						glTexParameteri(GL_TEXTURE_CUBE_MAP,GL_TEXTURE_MIN_FILTER,GL_NEAREST)
  						glTexParameteri(GL_TEXTURE_CUBE_MAP,GL_TEXTURE_MAG_FILTER,GL_NEAREST)
						
						glEnable(GL_TEXTURE_GEN_S)
						glEnable(GL_TEXTURE_GEN_T)
						glEnable(GL_TEXTURE_GEN_R)
						'glEnable(GL_TEXTURE_GEN_Q)

						If tex_cube_mode=1
							glTexGeni(GL_S,GL_TEXTURE_GEN_MODE,GL_REFLECTION_MAP)
							glTexGeni(GL_T,GL_TEXTURE_GEN_MODE,GL_REFLECTION_MAP)
							glTexGeni(GL_R,GL_TEXTURE_GEN_MODE,GL_REFLECTION_MAP)
						Endif
						
						If tex_cube_mode=2
							glTexGeni(GL_S,GL_TEXTURE_GEN_MODE,GL_NORMAL_MAP)
							glTexGeni(GL_T,GL_TEXTURE_GEN_MODE,GL_NORMAL_MAP)
							glTexGeni(GL_R,GL_TEXTURE_GEN_MODE,GL_NORMAL_MAP)
						Endif
				
					Else
					
						glDisable(GL_TEXTURE_CUBE_MAP)
						
						' only disable tex gen s and t if sphere mapping isn't using them
						If tex_flags&64=0
							glDisable(GL_TEXTURE_GEN_S)
							glDisable(GL_TEXTURE_GEN_T)
						Endif
						
						glDisable(GL_TEXTURE_GEN_R)
						'glDisable(GL_TEXTURE_GEN_Q)
						
					Endif 
			#end
			
			
					Select tex_blend
						Case 0 'glTexEnvf(GL_TEXTURE_ENV,GL_TEXTURE_ENV_MODE,GL_MODULATE)
							glTexEnvf(GL_TEXTURE_ENV,GL_TEXTURE_ENV_MODE,GL_REPLACE)
						Case 1 'glTexEnvf(GL_TEXTURE_ENV,GL_TEXTURE_ENV_MODE,GL_BLEND)
							glTexEnvf(GL_TEXTURE_ENV,GL_TEXTURE_ENV_MODE,GL_DECAL)
						Case 2
							glTexEnvf(GL_TEXTURE_ENV,GL_TEXTURE_ENV_MODE,GL_MODULATE)
						Case 3
							glTexEnvf(GL_TEXTURE_ENV,GL_TEXTURE_ENV_MODE,GL_ADD)
						Case 4
							glTexEnvf GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE
							glTexEnvf GL_TEXTURE_ENV, GL_COMBINE_RGB, GL_DOT3_RGB
						Case 5
							glTexEnvi(GL_TEXTURE_ENV,GL_TEXTURE_ENV_MODE,GL_COMBINE)
							glTexEnvi(GL_TEXTURE_ENV,GL_COMBINE_RGB,GL_MODULATE)
							glTexEnvi(GL_TEXTURE_ENV,GL_RGB_SCALE,2.0)
						Case 6
							glTexEnvf(GL_TEXTURE_ENV,GL_TEXTURE_ENV_MODE,GL_BLEND)
						Default
							glTexEnvf(GL_TEXTURE_ENV,GL_TEXTURE_ENV_MODE,GL_MODULATE)
					End Select

					glEnableClientState(GL_TEXTURE_COORD_ARRAY)

					If vbo
						If tex_coords=0
							glBindBuffer(GL_ARRAY_BUFFER,surf.vbo_id[1])
							glTexCoordPointer(2,GL_FLOAT,0,0)
						Else
							glBindBuffer(GL_ARRAY_BUFFER,surf.vbo_id[2])
							glTexCoordPointer(2,GL_FLOAT,0,0)
						Endif
					Else
						If tex_coords=0
							'glBindBuffer(GL_ARRAY_BUFFER,0) 'already reset above
							glTexCoordPointer(2,GL_FLOAT,0,surf.vert_tex_coords0.buf)
						Else
							'glBindBuffer(GL_ARRAY_BUFFER,0)
							glTexCoordPointer(2,GL_FLOAT,0,surf.vert_tex_coords1.buf)
						Endif
					Endif

			
					Endif ''end preserve skip_sprite_state-------------------------------
					
					
					' reset texture matrix
					glMatrixMode(GL_TEXTURE)
					glLoadIdentity()
								
					If tex_u_pos<>0.0 Or tex_v_pos<>0.0
						glTranslatef(tex_u_pos,tex_v_pos,0.0)
					Endif
					If tex_ang<>0.0
						glRotatef(tex_ang,0.0,0.0,1.0)
					Endif
					If tex_u_scale<>0.0 Or tex_v_scale<>0.0
						glScalef(tex_u_scale,tex_v_scale,1.0)
					Endif
					
				#rem
					' if spheremap flag=true then flip tex
					If tex_flags&64<>0
						glScalef(1.0,-1.0,-1.0)
					Endif
				#end
					
					' if cubemap flag=true then manipulate texture matrix so that cubemap is displayed properly 
					If tex_flags&128<>0

						glScalef(1.0,-1.0,-1.0)
						
						' get current modelview matrix (set in last camera update)
						Local mod_mat:Float[16]
						glGetFloatv(GL_MODELVIEW_MATRIX,mod_mat)
	
						' get rotational inverse of current modelview matrix
						Local new_mat:Matrix=New Matrix
						new_mat.LoadIdentity()
						
						new_mat.grid[0][0] = mod_mat[0]
  						new_mat.grid[1][0] = mod_mat[1]
  						new_mat.grid[2][0] = mod_mat[2]

						new_mat.grid[0][1] = mod_mat[4]
						new_mat.grid[1][1] = mod_mat[5]
						new_mat.grid[2][1] = mod_mat[6]

						new_mat.grid[0][2] = mod_mat[8]
						new_mat.grid[1][2] = mod_mat[9]
						new_mat.grid[2][2] = mod_mat[10]
						
						glMultMatrixf(new_mat.ToArray() )

					Endif
					
				Endif ''end if tex[ix]
			
			Next 'end texture loop
			
			
			
			'' turn off textures if no textures
			If tex_count = 0
			
				For Local ix:=0 To tex_count-1
			
					glActiveTexture(GL_TEXTURE0+ix)
					glClientActiveTexture(GL_TEXTURE0+ix)
					
					' reset texture matrix
					glMatrixMode(GL_TEXTURE)
					glLoadIdentity()
	
					'glDisable(GL_TEXTURE_CUBE_MAP)
					'glDisable(GL_TEXTURE_GEN_S)
					'glDisable(GL_TEXTURE_GEN_T)
					'glDisable(GL_TEXTURE_GEN_R)
				
				Next
				glDisable(GL_TEXTURE_2D)
				glDisableClientState(GL_TEXTURE_COORD_ARRAY)
				
			Endif
			
				
			'' draw tris
			
			glMatrixMode(GL_MODELVIEW)

			glPushMatrix()
	
			If mesh.is_sprite=False
				glMultMatrixf(ent.mat.ToArray() )
			Else
				glMultMatrixf(TSprite(mesh).mat_sp.ToArray() )
			Endif
				

			If TRender.render.wireframe
				
				If Not vbo Then glDrawElements(GL_LINE_LOOP,surf.no_tris*3,GL_UNSIGNED_SHORT,surf.tris.buf)
				If vbo Then glDrawElements(GL_LINE_LOOP,surf.no_tris*3,GL_UNSIGNED_SHORT, 0)
				
			Else
				If vbo	
																																																																																																																																																																																																																																																																															
					glDrawElements(GL_TRIANGLES,surf.no_tris*3,GL_UNSIGNED_SHORT, 0)
				
				Else

					glDrawElements(GL_TRIANGLES,surf.no_tris*3,GL_UNSIGNED_SHORT,surf.tris.buf)
					
				Endif
			Endif

			glPopMatrix()
			
			

	
			' enable fog again if fog was enabled at start of func
			If fog=True
				glEnable(GL_FOG)
			Endif

		Next ''end non-alpha loop
		

		If Not alpha_list Then Exit ''get out of loop, no alpha
		temp_list = alpha_list
		
		Next	''end alpha loop
		
		'glBindBuffer( GL_ARRAY_BUFFER, 0 ) '' releases buffer for return to mojo buffer??? may not need
		'glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,0)
	
	
	End
	
	
	Method GraphicsInit:Int(flags:Int=0)

		TTexture.TextureFilter("",8+1) ''default texture settings: mipmap

		' get hardware info and set vbo_enabled accordingly
		'THardwareInfo.GetInfo()
		'THardwareInfo.DisplayInfo()
		
		width = DeviceWidth()
		height = DeviceHeight()
		
		If Not (flags & DISABLE_VBO)
			vbo_enabled=True 'THardwareInfo.VBOSupport
		Endif

		If Not (flags & DISABLE_MAX2D )

			' save the Max2D settings for later - by Oddball
			glMatrixMode GL_MODELVIEW
			glPushMatrix
			glMatrixMode GL_PROJECTION
			glPushMatrix
			glMatrixMode GL_TEXTURE
			glPushMatrix
		
		Endif
		
		EnableStates()
		
		'glLightModelf(GL_LIGHT_MODEL_LOCAL_VIEWER,GL_TRUE) ''not in gles11

		glClearDepthf(1.0)						
		glDepthFunc(GL_LEQUAL)
		glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST)

		glAlphaFunc(GL_GEQUAL,0.5)
		
		TEntity.global_mat.LoadIdentity()
		
		If glGetError()<>GL_NO_ERROR Then Return 0
		
		Return 1
		

	End 
	
	Method EnableStates:Void()
		
		glEnable(GL_LIGHTING)
   		glEnable(GL_DEPTH_TEST)
		glEnable(GL_FOG)
		glEnable(GL_CULL_FACE)
		glEnable(GL_SCISSOR_TEST)
		
		glEnable(GL_RESCALE_NORMAL) '(GL_NORMALIZE) ' 'normal-lighting problems? this may be it
		
		glLightModelfv(GL_LIGHT_MODEL_TWO_SIDE, [0.0])
		
		glEnableClientState(GL_VERTEX_ARRAY)
		glEnableClientState(GL_COLOR_ARRAY)
		glEnableClientState(GL_NORMAL_ARRAY)
	
	End 
	
	Function GetGLError:Int()
		Local gle:Int = glGetError()
		If gle<>GL_NO_ERROR Then Print "**vbo glerror: "+gle; Return 1
		Return 0
	End
	
	Function ClearGLErrors()
		While glGetError()<>GL_NO_ERROR
		 '
		Wend
	End	
	
	
	Method UpdateVBO:Int(surf:TSurface)
	
		If surf.vbo_id[0]=0
			glGenBuffers(6,surf.vbo_id)
		Endif

		If surf.reset_vbo=-1 Then surf.reset_vbo=255
	
		If surf.reset_vbo&1
			glBindBuffer(GL_ARRAY_BUFFER,surf.vbo_id[0])
			If surf.vbo_dyn =False
				glBufferData(GL_ARRAY_BUFFER,(surf.no_verts*3*4),surf.vert_coords.buf,GL_STATIC_DRAW)
			Else
				If surf.reset_vbo <> 255
					glBufferSubData(GL_ARRAY_BUFFER,0,(surf.no_verts*3*4),surf.vert_coords.buf)
				Else
					glBufferData(GL_ARRAY_BUFFER,(surf.no_verts*3*4),surf.vert_coords.buf,GL_DYNAMIC_DRAW)
				Endif
			Endif
		Endif
		'If GetGLError() Then Print "vertcoords"
		
		If surf.reset_vbo&2
			glBindBuffer(GL_ARRAY_BUFFER,surf.vbo_id[1])
			glBufferData(GL_ARRAY_BUFFER,(surf.no_verts*2*4),surf.vert_tex_coords0.buf,GL_STATIC_DRAW)
	
			glBindBuffer(GL_ARRAY_BUFFER,surf.vbo_id[2])
			glBufferData(GL_ARRAY_BUFFER,(surf.no_verts*2*4),surf.vert_tex_coords1.buf,GL_STATIC_DRAW)	
		Endif
		'If GetGLError() Then Print "verttexcords"
		
		If surf.reset_vbo&4
			glBindBuffer(GL_ARRAY_BUFFER,surf.vbo_id[3])
			glBufferData(GL_ARRAY_BUFFER,(surf.no_verts*3*4),surf.vert_norm.buf,GL_STATIC_DRAW)
		Endif
		'If GetGLError() Then Print "vertnorm"
		
		If surf.reset_vbo&8
			glBindBuffer(GL_ARRAY_BUFFER,surf.vbo_id[4])
			If surf.reset_vbo <> 255
				glBufferSubData(GL_ARRAY_BUFFER,0,(surf.no_verts*4*4),surf.vert_col.buf)
			Else
				glBufferData(GL_ARRAY_BUFFER,(surf.no_verts*4*4),surf.vert_col.buf,GL_STATIC_DRAW)
			Endif
			
		Endif
		'If GetGLError() Then Print "vertcol"	
		
		If surf.reset_vbo&16
			glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,surf.vbo_id[5])
			If surf.reset_vbo <> 255
				glBufferSubData(GL_ELEMENT_ARRAY_BUFFER,0,surf.no_tris*3*2,surf.tris.buf)
			Else
				glBufferData(GL_ELEMENT_ARRAY_BUFFER,surf.no_tris*3*2,surf.tris.buf,GL_STATIC_DRAW)
			Endif
			
		Endif
		'If GetGLError() Then Print "verttris"
		
		surf.reset_vbo=False
		
	End
	
	
	Method FreeVBO(surf:TSurface)
	
		If surf.vbo_id[0]<>0 
			glDeleteBuffers(6,surf.vbo_id)
		Endif
	
	End 
	
	''ReloadAllSurfaces()
	''-- used for resetting mobile opengl context
	''-- note: do i need to update animation surfs too??
	Method ReloadSurfaces:Int()
	
		Local mesh:TMesh
		
		For Local ent:TEntity = Eachin TMesh.entity_list
		
			mesh = TMesh(ent)
			If mesh
			
				For Local surf:TSurface=Eachin mesh.surf_list
					
					surf.vbo_id[0]=0
					surf.reset_vbo = -1
					UpdateVBO(surf)
				
				Next
				
			Endif
		
		Next
		
		Return 1
	End
	
	
End


''
''helper classes
''

Class RenderAlphaList Extends List<TMesh>
	
	''draw furthest (highest alpha_order) first, so sort from great to least
	Method Compare( left:TMesh,right:TMesh )
		If left.alpha_order < right.alpha_order Return -1
		Return left.alpha_order > right.alpha_order
	End
	
End


Class SurfaceAlphaList Extends List<TSurface>
	
	Method Compare( left:TSurface,right:TSurface)
		''---- how do we compare surface alphas in the correct order to draw? leave to user to order?
		
		'If left.alpha_order < right.alpha_order Return -1
		'Return left.alpha_order > right.alpha_order
	End
	
End

