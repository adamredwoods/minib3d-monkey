Import minib3d


''
''-- also create this function if extending trender
''
'Function SetRender(flags:Int=0)
'	TRender.render = New OpenglES11
'	TRender.render.Graphicsinit(flags)
'End

''Method DeleteTexture(glid:Int[]) Abstract  '' **** DEPRECATE THIS ****** (use DeleteTexture(tx:Texture))
'' and update BindTextureStack()



'' Interface IRenderUpdate
'' -- used for sprites and sprite batching, forces TRender to call Update when in camera view.
Interface IRenderUpdate
	Method Update( cam:TCamera )
End



Class TRender

#If CONFIG="debug"
	Const DEBUG:Int=1
#else
	Const DEBUG:Int=0
#endif

	Global render:TRender
	Global vbo_enabled:Bool=False ' this is set in GraphicsInit - will be set to true if USE_VBO is true and the hardware supports vbos
	Global MAX_TEXTURES:Int = 3
	
	Global shader_enabled:Bool = False
	
	Global width:Int,height:Int,mode:Int,depth:Int,rate:Int
	
	Global wireframe:Int=False ''draw meshes as lines or filled
	Global disable_lighting:Bool = False ''turns off light shading, renders full color
	
	Global alpha_pass:Int = 0 ''for optimizing the TMesh render routine
	
	Global shader2D:IShader2D = New BlankShader
	Global camera2D:TCamera = New TCamera '' do not add to cam_list
	Global draw_list:List<TMesh> = New List<TMesh> ''immediate mode drawing for overlay, text
	
	Private
	
	Global render_list:RenderAlphaList = New RenderAlphaList
	Global render_alpha_list:RenderAlphaList = New RenderAlphaList
	
	Global temp_shader:TShader
	
	Public
	
	Method ContextReady:Bool() Abstract ''must return true when ready to render
	Method GetVersion:Float() Abstract ''returns version of graphics platform being used
	
	Method Reset:Void() Abstract ''reset, called before render for each camera
	Method Finish:Void() Abstract ''finish pass for each camera
	
	Method GraphicsInit:Int(flags:Int=0) Abstract ''init during SetRender()
	
	Method Render:Void(ent:TEntity, cam:TCamera = Null) Abstract ''render per mesh

	Method BindTexture:TTexture(tex:TTexture,flags:Int) Abstract
	'Method DeleteTexture(glid:Int[]) '' **** DEPRECATE THIS ******
	Method DeleteTexture(tex:TTexture) Abstract

	
	Method UpdateLight(cam:TCamera, light:TLight) Abstract
	Method DisableLight(light:TLight) Abstract
	
	Method UpdateCamera(cam:TCamera) Abstract
	
	Method UpdateVBO(surface:TSurface) Abstract

	Method FreeVBO(surface:TSurface) Abstract

	
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
						
					Elseif mesh.anim =4
						
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
		
		''confirm rendering context
		If TRender.render = Null Or Not TRender.render.ContextReady() Then Return
		
		''process texture binds & framebuffer binds
		If TTexture.tex_bind_stack.Length >0 Then TRender.render.BindTextureStack()		

		
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
		
		render.RenderWorldFinish()
		
	End 
	

	Function RenderDrawList:Void()

		If draw_list.IsEmpty Or Not TRender.render.ContextReady() Then Return
		
		
		TRender.render.Reset()
		shader2D.SetShader2D() ''multi-shader is automatic
		
		'camera2D.CameraClsMode(False,False) ''moved this to the end of method to allow mojo CLS
		
		
		alpha_pass=1
		Local wireframeIsEnabled:= wireframe
		wireframe = False
		'camera2D.ExtractFrustum()
		'camera2D.CameraProjMode(3)
		
		TRender.render.UpdateCamera(camera2D)

	
		For Local mesh:TMesh = Eachin draw_list
			
			If Not mesh Then Continue
		
			If IRenderUpdate( mesh )
				
				IRenderUpdate(mesh).Update(camera2D ) ' rotate sprites with respect to current cam					
								
			Endif
			
			''auto-scaling for sprites and ttext
			Local sp:TSprite = TSprite(mesh)
			If mesh.is_sprite
				sp.mat_sp.Scale( (sp.pixel_scale[0]) , (sp.pixel_scale[1]), 1.0)
				mesh.EntityFX FXFLAG_DISABLE_DEPTH ''is this needed?
			Endif
		
		
			If mesh.Alpha() Then mesh.alpha_order=1.0 ' test for alpha in surface
'If mesh Then Print mesh.no_surfs
'If mesh.GetSurface(3) And mesh.GetSurface(3).brush.tex[0] Then Print "trender "+mesh.GetSurface(3).brush.tex[0].width
		
			TRender.render.Render(mesh,camera2D)
		Next
		
		wireframe = wireframeIsEnabled
		
		TRender.render.Finish()
		draw_list.Clear()
		
		''update at end to allow mojo commands
		camera2D.CameraClsMode(False,False)
		camera2D.CameraViewport(0,0,TRender.width,TRender.height)
		camera2D.SetPixelCamera
		
	End
	
	
	Method RenderCamera:Void(cam:TCamera, skip:Int=0)
			
		TRender.render.Reset() ''reset render pass
		

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
		Local wireFrameIsEnabled:= wireframe
		
		For Local ent:TEntity=Eachin TEntity.entity_list
			
			'' reject non-mesh
			mesh = TMesh( ent )
			
			If mesh				
				
				'If mesh.parent_hidden=True Or mesh.hidden=True Or mesh.brush.alpha=0.0 Then Continue
				If mesh.Hidden()=True Or mesh.brush.alpha=0.0 Then Continue
				
				''cam layer mode
				If (mesh.use_cam_layer And mesh.cam_layer <> cam) Or (cam.use_cam_layer And mesh.cam_layer <> cam)  Then Continue
				
				
				' get new bounds
				mesh.GetBounds()
		
				' Perform frustum cull
				
				Local inview:Float =cam.EntityInFrustum(mesh)
				
'Print "// mesh "+mesh.classname+" "+inview	
'Print "// center "+mesh.center_x+" "+mesh.center_y+" "+mesh.center_z

				If inview > 0.00001
				
					wireframe = wireframe | mesh.wireframe
					
					If mesh.auto_fade=True Then mesh.AutoFade(cam)
					
					If IRenderUpdate(mesh)
				
						IRenderUpdate(mesh).Update(cam ) ' update sprites, batchsprites					
						
					Endif
		
					If mesh.Alpha()
					
						''alpha entities are drawn last, sorted, without depth test
						
						mesh.alpha_order=cam.EntityDistanceSquared(mesh)+0.000001 ''+0.000001 to keep it not zero
						render_alpha_list.AddLast(mesh)

					Else
						
						TRender.render.Render(mesh,cam)
						'mesh.alpha_order=-cam.EntityDistanceSquared(mesh)
						'render_list.AddLast(mesh)
	
					Endif
					
					wireframe = wireFrameIsEnabled

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
			
			wireframe = wireframe | mesh.wireframe
			
			TRender.render.Render(mesh,cam)
			
			wireframe = wireFrameIsEnabled

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
				TRender.render.DeleteTexture(tex)	
				tex.FreeTexture_()
			Else
				TRender.render.BindTexture(tex,tex.bind_flags)
			Endif
			
			tex.bind_flags = -1
		Next
		TTexture.tex_bind_stack.Clear()
		
	End
	
	
	
	Method ClearErrors:Int()
		Return 1
	End
	
	
	Method RenderWorldFinish:Void()
		''optional
	End
	
End



''
'' EffectState
''
'' -- unifies render behavior
Class EffectState
	
	''should be on(1)/off(0)/reset(-1) -- no bool, use int
	Field use_full_bright:Int=0
	Field use_vertex_colors:Int=0
	Field use_flatshade:Int=0
	Field use_fog:Int=1
	Field use_depth_test:int
	Field use_depth_write:int
	Field use_backface_culling:Int
	Field use_alpha_test:int
	
	Field ambient#[]=[1.0,1.0,1.0,1.0]
	Field no_mat#[]=[0.0,0.0,0.0,0.0]
	Field mat_ambient#[]=[1.0,1.0,1.0,1.0]
	Field diffuse#[]=[1.0,1.0,1.0,1.0]
	Field specular#[]=[1.0,1.0,1.0,1.0]
	Field shininess#[]=[100.0] ' upto 128
	Field shine#
	
	Field red#,green#,blue#
	Field alpha#
	Field blend:Int
	Field fx:Int
	
	Method Overwrite:Void(e:EffectState)
		use_full_bright = e.use_full_bright
		use_vertex_colors=e.use_vertex_colors
		use_flatshade=e.use_flatshade
		use_fog=e.use_fog
		ambient=[e.ambient[0],e.ambient[1],e.ambient[2],e.ambient[3]]

		'no_mat#[]=[0.0,0.0,0.0,0.0]
		'mat_ambient#[]=[1.0,1.0,1.0,1.0]
		diffuse=[e.diffuse[0],e.diffuse[1],e.diffuse[2],e.diffuse[3]]
		specular=[e.specular[0],e.specular[1],e.specular[2],e.specular[3]]
		shininess=[e.shininess[0]]
	
		use_depth_test=e.use_depth_test
		use_depth_write = e.use_depth_write
		use_backface_culling=e.use_backface_culling
		red=e.red ; green=e.green ; blue=e.blue ; alpha=e.alpha
		shine=e.shine ; blend=e.blend ; fx=e.fx
		use_alpha_test = e.use_alpha_test
	End
	
	Method SetNull:Void()
		use_full_bright = -1
		use_vertex_colors= -1
		use_flatshade= -1
		use_fog= -1
		ambient=[-1.0,-1.0,-1.0,1.0]

		'no_mat#[]=[0.0,0.0,0.0,0.0]
		'mat_ambient#[]=[1.0,1.0,1.0,1.0]
		diffuse=[-1.0,-1.0,-1.0,1.0]
		specular=[-1.0,-1.0,-1.0,1.0]
		shininess=[-1.0]
	
		use_depth_test= -1
		use_depth_write = -1
		use_backface_culling= -1
		use_alpha_test=0
		red=-1.0 ; green=-1.0 ; blue=-1.0 ; alpha=-1.0
		shine=-1.0  ; blend=99999 ; fx=99999
	End
	
	Method UpdateEffect:Void(surf:TSurface, ent:TEntity, cam:TCamera = Null)
		
		
			'Local red#,green#,blue#,alpha#,shine#,blend:Int,fx:Int
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

			use_depth_test = 1
			use_depth_write = 1
				
			' if surface contains alpha info, enable blending
			Local enable_blend:Int=0
			If ent.alpha_order<>0.0
				
				If ent.brush.alpha<1.0
					''the entire entity
					enable_blend=1
					'depth_test = 0
					use_depth_write = 0
				Elseif surf.alpha_enable=True
					''just one surface
					enable_blend=1
					'depth_test = 0
					use_depth_write = 0
				Else
					''entity flagged for alpha, but not this surface
					enable_blend=0
					use_depth_test = 1
					use_depth_write = 1
				Endif
			Else
				enable_blend=0
				
			Endif


			If enable_blend = 0 Then blend = -1

			use_vertex_colors=0
			use_flatshade=0
			use_fog=Int(cam.fog_mode >0)
			
			' fx flag 1 - full bright
			If fx&1
				ambient_red  =0.0; ambient_green=0.0; ambient_blue =0.0
				use_full_bright=1
			Else
				ambient_red  =TLight.ambient_red
				ambient_green=TLight.ambient_green
				ambient_blue =TLight.ambient_blue
				use_full_bright=0
			Endif


			' fx flag 2 - vertex colors ***todo*** disable all lights?
			If fx&2
				'glColorMaterial(GL_FRONT_AND_BACK, GL_AMBIENT_AND_DIFFUSE)
				'glEnable(GL_COLOR_MATERIAL)
				use_vertex_colors = 1		
				red=1.0; green=1.0; blue=1.0; alpha=1.0
			Endif
			
			' fx flag 4 - flatshaded
			If fx&4
				use_flatshade=1
			Endif

			' fx flag 8 - disable fog
			If fx&8
				use_fog=0
			Endif
			
			' fx flag 16 - disable backface culling
			If fx&16
				use_backface_culling = 0
				'driver.SetCulling(DRIVER_NONE)
			Else
				use_backface_culling = 1
				'driver.SetCulling(DRIVER_FRONT) '' minib3d is -z, which is opposite flash
			Endif
			
			'' fx flag 32 - force alpha, implemented TMesh.Alpha() called in TRender
			
			'' fx flag 64 - disable depth testing, overrides other settings
			If fx&64
				
				use_depth_test = 0
				use_depth_write = 0
								
			Endif
			
			use_alpha_test = 0
			If fx& FXFLAG_ALPHA_TESTING
				use_alpha_test = 1
				use_depth_test = 1
				use_depth_write = 1
			Endif
		
			' material color + specular

			ambient=[ambient_red,ambient_green,ambient_blue,1.0]

			'mat_ambient=[red,green,blue,alpha]
			diffuse=[red,green,blue,alpha]
			specular=[shine,shine,shine,1.0]
			shininess=[100.0] ' upto 128
		
			If cam.draw2D
			
				'glDisable(GL_DEPTH_TEST)
				If fx&64 = 0 Then use_depth_test = 0; use_depth_write = 0
				'glDisable(GL_FOG)
				use_fog = 0
				'glDisable(GL_LIGHTING)
				use_full_bright = 1
				
			Endif
		
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

