Import minib3d


''
''-- also create this function if extending trender
''
'Function SetRender(flags:Int=0)
'	TRender.render = New OpenglES11
'	TRender.render.Graphicsinit(flags)
'End



Class TRender

#If CONFIG="debug"
	Const DEBUG:Int=1
#else
	Const DEBUG:Int=0
#endif

	Global render:TRender
	Global vbo_enabled:Bool=False ' this is set in GraphicsInit - will be set to true if USE_VBO is true and the hardware supports vbos
	
	Global shader_enabled:Bool = False
	
	Global width:Int,height:Int,mode:Int,depth:Int,rate:Int
	
	Global wireframe:Bool=False ''draw meshes as lines or filled
	Global disable_lighting:Bool = False ''turns off light shading, renders full color
	
	Global alpha_pass:Int = 0 ''for optimizing the TMesh render routine
	
	Global camera2D:TCamera = New TCamera '' do not add to cam_list
	Global draw_list:List<TMesh> = New List<TMesh> ''immediate mode drawing for overlay, text
	
	Private
	
	Global render_list:RenderAlphaList = New RenderAlphaList
	Global render_alpha_list:RenderAlphaList = New RenderAlphaList
	
	Global temp_shader:TShader
	
	Public
	
	
	Method GetVersion:Float() Abstract ''returns version of graphics platform being used
	
	Method Reset:Void() Abstract ''reset, called before render for each camera
	Method Finish:Void() Abstract ''finish pass for each camera
	
	Method GraphicsInit:Int(flags:Int=0) Abstract ''init during SetRender()
	
	Method Render:Void(ent:TEntity, cam:TCamera = Null) Abstract ''render per mesh
	
	Method ClearErrors:Int() Abstract

	
	Method BindTexture:TTexture(tex:TTexture,flags:Int) Abstract
	Method DeleteTexture(glid:Int[]) Abstract
	
	Method UpdateLight(cam:TCamera, light:TLight) Abstract
	Method DisableLight(light:TLight) Abstract
	
	Method UpdateCamera(cam:TCamera) Abstract
	
	Method UpdateVBO(surface:TSurface)
	End
	
	''-------------------------------------------------------
	

	
	Function ClearWorld(entities=True,brushes=True,textures=True)
		
		render_list.Clear()
		render_alpha_list.Clear()
		
		If entities
'Print TEntity.entity_list.Count()			
			For Local ent:TEntity=Eachin TEntity.entity_list
'Print ent.classname
				ent.FreeEntity()
				ent=Null
			Next
			
			'TEntity.entity_list.Clear()
			ClearCollisions()
			
			TPick.ent_list.Clear()
			TPick.picked_ent=Null
			TPick.picked_surface=0
			
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
						
					Elseif mesh.anim >=4
						
						TBone.UpdateBoneChildren( mesh)
						
						TAnimation.VertexDeform(TMesh(mesh))
						
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
							'mesh.anim_time = last
							mesh.anim_time = first + (mesh.anim_time - last)
							mesh.anim_mode=0
						Endif
					
					Endif
					
				Endif
							
			Endif
		
		Next

	End 

	
	
	
	Function  RenderWorld:Void()
		
		''process texture binds
		TRender.render.BindTextureStack()		
		
		If Not TCamera.cam_list Or render = Null Then Return
		
		For Local cam:TCamera=Eachin TCamera.cam_list

			'If cam.parent_hidden=True Or cam.hidden=True Then Continue
			If cam.Hidden()=True Then Continue
			
			TShader.PreProcess(cam)
			
			''override the default render routine for custom shader
			
			If IShaderRender(TShader.g_shader)=Null
			
				TRender.render.RenderCamera(cam)
				
			Else
			
				temp_shader = TShader.g_shader ''to keep custom shader on return
				
				IShaderRender(TShader.g_shader).Render(cam)
				
				TShader.g_shader = temp_shader
				
			Endif
			
			TShader.PostProcess(cam)
			
		Next
		
		RenderDrawList()
		
	End 
	
	
	Function RenderDrawList:Void()

		If draw_list.IsEmpty Then Return
		
		TRender.render.SetDrawShader()
		TRender.render.Reset()
		
		camera2D.CameraViewport(0,0,TRender.width,TRender.height)
		camera2D.SetPixelCamera
		camera2D.CameraClsMode(False,True)
		camera2D.draw2D = 1
		
		alpha_pass=1
		'camera2D.ExtractFrustum()
		'camera2D.CameraProjMode(3)
		
		TRender.render.UpdateCamera(camera2D)
		
		'cam = TCamera.cam_list.First()
		'cam.draw2D=1
		
		For Local mesh:TMesh = Eachin draw_list
			
			If Not mesh Then Continue
			
			If mesh.is_sprite Or mesh.is_update
				
				mesh.Update(camera2D ) ' rotate sprites with respect to current cam					
								
			Endif
			
			''auto-scaling for sprites and ttext
			Local sp:TSprite = TSprite(mesh)
			If mesh.is_sprite Then sp.mat_sp.Scale( (sp.pixel_scale[0]) , (sp.pixel_scale[1]), 1.0)

			
			If mesh.Alpha() Then mesh.alpha_order=1.0 ' test for alpha in surface
			
			TRender.render.Render(mesh,camera2D)
		Next
		
		TRender.render.Finish()
		draw_list.Clear()
		
	End
	
	
	Method RenderCamera:Void(cam:TCamera, skip:Int=0)
		
		Reset() ''reset render pass
		

		'' use skip to render without updating camera
		'' would be useful for FSAA, FBOs, or a render layer system
		If (Not skip)
		
			cam.Update(cam)
			UpdateCamera( cam ) ''update Render driver
			
		Endif
	
		
		For Local light:TLight=Eachin TLight.light_list
	
			UpdateLight(cam,light) ' EntityHidden code inside Update
			
		Next

		
		
		render_list.Clear()
		render_alpha_list.Clear()
		
		''Perform camera clipping, alpha ordering, and entity sort
		Local mesh:TMesh
		Local alpha_count:Int=0

		
		For Local ent:TEntity=Eachin TEntity.entity_list
			
			'' reject non-mesh
			mesh = TMesh( ent )
			
'Print "// ent:"+ent.classname+" : "+ent.name
			
			If mesh				
				
				'If mesh.parent_hidden=True Or mesh.hidden=True Or mesh.brush.alpha=0.0 Then Continue
				If mesh.Hidden()=True Or mesh.brush.alpha=0.0 Then Continue
				
				''cam layer mode
				If (mesh.use_cam_layer And mesh.cam_layer <> cam) Or (cam.use_cam_layer And mesh.cam_layer <> cam)  Then Continue
				
				' get new bounds
				mesh.GetBounds()
		
				' Perform frustum cull
				
				Local inview:Int =cam.EntityInFrustum(mesh)
				
'Print "// mesh "+mesh.classname+" "+inview	
'Print "// center "+mesh.center_x+" "+mesh.center_y+" "+mesh.center_z

				If inview
					
					If mesh.wireframe Or wireframe Then wireframe = True
					
					If mesh.auto_fade=True Then mesh.AutoFade(cam)
					
					If mesh.is_sprite Or mesh.is_update
				
						mesh.Update(cam ) ' rotate sprites with respect to current cam					
						
					Endif
		
					If mesh.Alpha()
						
						''alpha entities are drawn last
						
						mesh.alpha_order=cam.EntityDistanceSquared(mesh)
						render_alpha_list.AddLast(mesh)


					Else
						
						TRender.render.Render(mesh,cam)
						'mesh.alpha_order=-cam.EntityDistanceSquared(mesh)
						'render_list.AddLast(mesh)
	
					Endif
					
					wireframe = False
					
				Endif
			Endif
					
		Next
		
		
		
		'' can't draw front to back for opaque, then "entity.order" is messed up
		' Draw front to back for opaque
		'render_list.Sort()
		
				
		' Draw back to front, alpha render list
		
		render_alpha_list.Sort() ''sorting alpha_order
		'TRender.alpha_pass = 1 ''skip non-alpha surface pass ''ACTUALLY this may help hardware z-ordering
		
		For mesh = Eachin render_alpha_list
			
			If mesh.wireframe Or wireframe Then wireframe = True
			
			TRender.render.Render(mesh,cam)
			
			wireframe = False

		Next
		
		
		
		Finish() ''end render pass
		
	End
	
	
	Function Wireframe(b:Bool=True)
	
		wireframe = b
		
	End 
	
	
	
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
	
	''
	''due to openGL context begin available only guaranteed in OnRender(), use this to queue texture binds
	''
	Method BindTextureStack()
	
		For Local tex:TTexture = Eachin TTexture.tex_bind_stack
			If tex.bind_flags = -255
				''remove texture
				TRender.render.DeleteTexture(tex.gltex)	
				tex.FreeTexture_()
			Else
				TRender.render.BindTexture(tex,tex.bind_flags)
			Endif
			
			tex.bind_flags = -1
		Next
		TTexture.tex_bind_stack.Clear()
		
	End
	
	
	Function SetDrawShader:Void()
		
		'' set a fast, bright shader, used with drawing 2D, text
		
	End
	
End


''
''helper classes
''

Class RenderAlphaList Extends List<TMesh>
	
	''draw furthest (highest alpha_order) first, so sort from great to least
	Method Compare( left:TMesh,right:TMesh )
		If left.alpha_order > right.alpha_order Return -1 
		Return left.alpha_order < right.alpha_order
	End
	
End


Class SurfaceAlphaList Extends List<TSurface>
	
	Method Compare( left:TSurface,right:TSurface)
		''---- how do we compare surface alphas in the correct order to draw? leave to user to order?
		
		'If left.alpha_order < right.alpha_order Return -1
		'Return left.alpha_order > right.alpha_order
	End
	
End


''----------------------------------------------------

