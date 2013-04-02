Import mojo
Import minib3d
Import minib3d.trender
Import minib3d.flash11.tpixmap_flash
Import minib3d.flash11.flash11_driver
Import minib3d.flash11.tshader_flash





#MINIB3D_DRIVER="flash11"
#Print "miniB3D "+MINIB3D_DRIVER

Const VBO_MIN_TRIS=1	' if USE_VBO=True and vbos are supported by hardware, then surface must also have this minimum no. of tris before vbo is used for surface (vbos work best with surfaces with high amount of tris)


'flags
Const DISABLE_MAX2D=1	' true to enable max2d/minib3d integration --not in use for now
Const DISABLE_VBO=2	' true to use vbos if supported by hardware
Const MAX_TEXTURES=4


Extern

	''this is highly experimental

	Function RestoreMojo2D() = ""


Public



Function SetRender(flags:Int=0)

	TRender.render = New FlashMiniB3D
	TRender.render.GraphicsInit(flags)
	
End	



Class ShaderEffect
	
	Field use_vertex_colors:Int=0
	Field use_flatshade:Int=0
	Field use_fog:Int=1
	Field ambient#[]=[1.0,1.0,1.0,1.0]

	Field no_mat#[]=[0.0,0.0,0.0,0.0]
	Field mat_ambient#[]=[1.0,1.0,1.0,1.0]
	Field mat_diffuse#[]=[1.0,1.0,1.0,1.0]
	Field mat_specular#[]=[1.0,1.0,1.0,1.0]
	Field mat_shininess#[]=[100.0] ' upto 128
	
End


Class FlashMiniB3D Extends TRender
	
	Global driver:Driver = New Driver()
	
	''used for optimizing the fixed-pipeline render routine
	
	Global alpha_list:SurfaceAlphaList = New SurfaceAlphaList  ''used to draw and sort alpha surfaces last
	'Global alpha_anim_list:SurfaceAlphaList = New SurfaceAlphaList  ''no need-- connected anim_surf t surf

	Global last_texture:TTexture ''used to preserve texture states
	Global last_sprite:TSurface ''used to batch sprite state switching
	Global last_tex_count:Int =8
	
	Global disable_depth:Bool = False '' used for EntityFx 64 - disable depth testing
	
	
	Global light_no:Int, old_no_lights:Int
	
	Field t_array:Float[16] ''temp array
	
	Field vbuf_map:IntMap<VertexBuffer3D> = New IntMap<VertexBuffer3D>
	Field ibuf_map:IntMap<IndexBuffer3D> = New IntMap<IndexBuffer3D>
	Field abuf_map:IntMap<VertexBuffer3D> = New IntMap<VertexBuffer3D>
	
	Private
	
	Field render_init:Bool = False
	
	Field surf_buf_id:Int =0''used to keep surface's VertexBuffer3D
	
	Field tex_map_id:Int =0
	Field tex_map:IntMap<FlashTexture> = New IntMap<FlashTexture>
	
	Field effect:ShaderEffect = New ShaderEffect
	
	Global null_tex:TTexture
	
	Public
	
	Method New()
		
		
		
	End
	
	
	
	Method GetVersion:Float()
		Local st:String
		
		Local s:String = driver.CheckVersion()
	
		Local num:Int=0
		
		For Local i:Int=0 To s.Length()-1
	
			If (s[i] >47 And s[i]<58)
				st=st+String.FromChar(s[i])
				If num =0 Then num=1
			Elseif (s[i]=46 Or s[i]=44)
				If num=2 Then Exit
				st=st+String.FromChar(s[i])
				num=2
			Elseif num<>0
				Exit
			Endif 
		Next

		Return Float( st )
		
	End
	
	
	Method ContextReady:Bool()

		Return driver.ContextReady()
	End
	
	Method Reset:Void()
		
		If Not render_init Then EnableStates()
		
		''reset globals used for state caching
		last_texture = Null ''used to preserve texture states
		last_sprite = Null ''used to preserve last surface states
		TRender.alpha_pass = 0
		
		driver.Clear(0,0,0)
	End
	
	
	Method Render:Void(ent:TEntity, cam:TCamera = Null)
		
		Local mesh:TMesh = TMesh(ent)
		
		If Not mesh Then Return
		
		Local name$=ent.EntityName()
	
		Local fog%=False
		If cam.fog_mode = True Then fog=True ' if fog enabled, we'll enable it again at end of each surf loop in case of fx flag disabling it


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
'Print "   alphaloop "+alphaloop+" "+" tribuffersize:"+surf.tris.Length()+", tris:"+surf.no_tris+", verts:"+surf.no_verts
'Print "   surfpass "+ccc+":"+alpha_pass+" vbo:"+surf.vbo_id[0]+" dynvbo:"+Int(surf.vbo_dyn)+" skip:"+Int(skip_sprite_state)
'Print "   mesh.anim:"+mesh.anim
'Print "   vboids:"+surf.vbo_id[0]+" "+surf.vbo_id[1]+" "+surf.vbo_id[2]+" "+surf.vbo_id[3]+" "+surf.vbo_id[4]+" "+surf.vbo_id[5]+" "
		

			'If vbo_enabled
			Local vbo:Int=True
			
			''get vbuffer and ibuffer, OK if null
			Local vbuffer:VertexBuffer3D = vbuf_map.Get(surf.vbo_id[0])
			Local ibuffer:IndexBuffer3D = ibuf_map.Get(surf.vbo_id[0])
			Local abuffer:VertexBuffer3D = Null
				
			' update surf vbo if necessary
			If vbo
				
				' update vbuffer
				UpdateBuffers(surf, vbuffer, ibuffer)
				vbuffer = vbuf_map.Get(surf.vbo_id[0])
				ibuffer = ibuf_map.Get(surf.vbo_id[0])
				
			Endif

			If mesh.anim
			
				' get anim_surf
				anim_surf2 = mesh.anim_surf[surf.surf_id] ''assign anim surface
				
				If surf.vert_anim
					abuffer = vbuf_map.Get(surf.vbo_id[0])
				Endif
				
				If vbo And anim_surf2
				
					' update vbuffer
					UpdateBuffers(anim_surf2, vbuffer, ibuffer, abuffer)
					vbuffer = vbuf_map.Get(surf.vbo_id[0])
					ibuffer = ibuf_map.Get(surf.vbo_id[0])
					abuffer = vbuf_map.Get(surf.vbo_id[0])
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
			Local enable_blend:Int=0
			If ent.alpha_order<>0.0
				
				If ent.brush.alpha<1.0
					''the entire entity
					'glEnable(GL_BLEND)
					enable_blend=1
					driver.SetDepthTest(False, DRIVER_NEVER)
				Elseif surf.alpha_enable=True
					''just one surface
					'glEnable(GL_BLEND)
					enable_blend=1
					driver.SetDepthTest(False, DRIVER_NEVER)
				Else
					''entity flagged for alpha, but not this surface
					'glDisable(GL_BLEND)
					enable_blend=0
					driver.SetDepthTest(True, DRIVER_LESS_EQUAL)
				Endif
			Else
				'glDisable(GL_BLEND)
				enable_blend=0
				driver.SetDepthTest(True, DRIVER_LESS_EQUAL)

			Endif



			' blend modes
			If enable_blend
				Select blend
					Case 0
						'glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA) ' alpha
						driver.SetBlendFactors(DRIVER_SOURCE_ALPHA, DRIVER_ONE_MINUS_SOURCE_ALPHA)
					Case 1
						'glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA) ' alpha
						driver.SetBlendFactors(DRIVER_SOURCE_ALPHA, DRIVER_ONE_MINUS_SOURCE_ALPHA)
					Case 2
						'glBlendFunc(GL_DST_COLOR,GL_ZERO) ' multiply
						driver.SetBlendFactors(DRIVER_DESTINATION_COLOR, DRIVER_ZERO)
					Case 3
						'glBlendFunc(GL_SRC_ALPHA,GL_ONE) ' additive and alpha
						driver.SetBlendFactors(DRIVER_SOURCE_ALPHA, DRIVER_ONE)
					Case 4
						'glBlendFunc(GL_ONE,GL_ONE) ' blend after texture
						driver.SetBlendFactors(DRIVER_ONE, DRIVER_ONE)
	
				End
			Endif

			
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
			effect.use_vertex_colors=0
			effect.use_flatshade=0
			effect.use_fog=1
			If fx&2
				'glColorMaterial(GL_FRONT_AND_BACK, GL_AMBIENT_AND_DIFFUSE)
				'glEnable(GL_COLOR_MATERIAL)
				effect.use_vertex_colors = 1		

			Endif
			
			' fx flag 4 - flatshaded
			If fx&4
				effect.use_flatshade=1
			'Else
				'glShadeModel(GL_SMOOTH)
			Endif

			' fx flag 8 - disable fog
			If fx&8
				'glDisable(GL_FOG)
				effect.use_fog=0
			Endif
			
			' fx flag 16 - disable backface culling
			If fx&16
				'glDisable(GL_CULL_FACE)
				driver.SetCulling(DRIVER_NONE)
			Else
				'glEnable(GL_CULL_FACE)
				driver.SetCulling(DRIVER_BACK)
			Endif
			
			'' fx flag 32 - force alpha, implemented elsewhere
			
			'' fx flag 64 - disable depth testing
			If fx&64
			
				'glDisable(GL_DEPTH_TEST)
				driver.SetDepthTest(False, DRIVER_NEVER)
				disable_depth = True
				
			Elseif disable_depth = True ''turn back on
			
				'glEnable(GL_DEPTH_TEST)
				driver.SetDepthTest(True, DRIVER_LESS_EQUAL)
				disable_depth = False
				
			Endif
		
			
			
			If vbo
				
				''static mesh
				If Not (mesh.anim Or surf.vbo_dyn)
					driver.SetVertexBufferAt (0, vbuffer, VertexDataBuffer.POS_OFFSET Shr 2, DRIVER_FLOAT_3) ''position 0
				Endif
				
				driver.SetVertexBufferAt (1, vbuffer, VertexDataBuffer.NORMAL_OFFSET Shr 2, DRIVER_FLOAT_3) ''normal 1
				driver.SetVertexBufferAt (2, vbuffer, VertexDataBuffer.COLOR_OFFSET Shr 2, DRIVER_FLOAT_4) ''color 2
				
			'Else
		
				'Print "*** Non-VBO disabled"
'' interleaved offset doesn't work with DataBuffers, possible TODO for legacy targets
			
			Endif
			
			
			Endif ''end sprite_skip_state--------------------------------------
			
		
			''mesh animation/batch animation
			If vbo And (mesh.anim Or surf.vbo_dyn Or anim_surf2)
			
				''vertex animation
				If anim_surf2.vert_anim
					driver.SetVertexBufferAt (0, abuffer, 0, DRIVER_FLOAT_3) ''position 0
				
				'' mesh animation, using animsurf2	
				Elseif surf.vbo_dyn
					driver.SetVertexBufferAt (0, vbuffer, VertexDataBuffer.POS_OFFSET Shr 2, DRIVER_FLOAT_3) ''position 0
					
				Endif
			Endif
					
					
					
			' light + material color

			effect.ambient=[ambient_red,ambient_green,ambient_blue,1.0]

			effect.mat_ambient=[red,green,blue,alpha]
			effect.mat_diffuse=[red,green,blue,alpha]
			effect.mat_specular=[shine,shine,shine,shine]
			effect.mat_shininess=[100.0] ' upto 128
			
			
				
			' textures
			Local tex_count=0	
			
			tex_count=ent.brush.no_texs
			'If surf.brush<>Null
				If surf.brush.no_texs>tex_count Then tex_count=surf.brush.no_texs
			'EndIf
			
			''disable any extra textures from last pass
			If tex_count < last_tex_count 
				'For Local i:Int = tex_count To MAX_TEXTURES-1
				
					'
				'Next

			Endif
			
			
			
			For Local ix=0 To tex_count-1			
	
				If surf.brush.tex[ix]<>Null Or ent.brush.tex[ix]<>Null
					
					Local texture:TTexture,tex_flags,tex_blend,tex_coords,tex_u_scale#,tex_v_scale#
					Local tex_u_pos#,tex_v_pos#,tex_ang#,tex_cube_mode,frame, tex_smooth


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
						frame=ent.brush.tex[ix].tex_frame
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
						frame=surf.brush.tex[ix].tex_frame
						tex_smooth = surf.brush.tex[ix].tex_smooth		
					Endif
	
	
					''preserve texture states--------------------------------------
					If (surf.brush.tex[ix] And last_texture = surf.brush.tex[ix]) Or
					    (ent.brush.tex[ix] And last_texture = ent.brush.tex[ix])
						
						'' skip texture Bind
						
					Else
					
						''texture bind
						
						If ent.brush.tex[ix] Then last_texture = ent.brush.tex[ix] Else last_texture = surf.brush.tex[ix]
						
						driver.SetTextureAt(ix, tex_map.Get(last_texture.tex_id) )
	
					
					Endif ''end preserve texture states---------------------------------

					
					
					''assuming sprites with same surfaces are identical, preserve states---------
					If Not skip_sprite_state
					
					
					' masked texture flag
					'If tex_flags&4<>0
						'glEnable(GL_ALPHA_TEST)
						'use_tex_alpha=1
					'Else
						'glDisable(GL_ALPHA_TEST)
						'use_tex_alpha=0
					'Endif
				
					' mipmapping texture flag

					If tex_flags&8<>0
						If tex_smooth
							'glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR)
							'glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST_MIPMAP_LINEAR)
						'Else
							'glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST)
							'glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST)
						Endif
					Else
						If tex_smooth
							'glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR)
							'glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR)
						'Else
							'glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST)
							'glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST)
						Endif
					Endif
				
					' clamp u flag
					If tex_flags&16<>0
						'glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_CLAMP_TO_EDGE)
					'Else						
						'glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_REPEAT)
					Endif
					
					' clamp v flag
					If tex_flags&32<>0
						'glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_CLAMP_TO_EDGE)
					'Else
						'glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_REPEAT)
					Endif
			

			#rem	
					' cubic environment map texture flag
					If tex_flags&128<>0

			#end
			
			#rem
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
			#end
			


					If vbo
						If tex_coords=0
						
							driver.SetVertexBufferAt (3, vbuffer, VertexDataBuffer.TEXCOORDS_OFFSET Shr 2, DRIVER_FLOAT_2) ''uv 3

						Else
					
							driver.SetVertexBufferAt (3, vbuffer, (VertexDataBuffer.TEXCOORDS_OFFSET+VertexDataBuffer.ELEMENT2) Shr 2, DRIVER_FLOAT_2) ''uv 3
						Endif
					Else
					
						''interleaved data does not work with databuffers (no adddress offset)

					Endif

			
					Endif ''end preserve skip_sprite_state-------------------------------
					
					
					' texture matrix
				#rem				
					If tex_u_pos<>0.0 Or tex_v_pos<>0.0
						glTranslatef(tex_u_pos,tex_v_pos,0.0)
					Endif
					If tex_ang<>0.0
						glRotatef(tex_ang,0.0,0.0,1.0)
					Endif
					If tex_u_scale<>1.0 Or tex_v_scale<>1.0
						glScalef(tex_u_scale,tex_v_scale,1.0)
					Endif
				#end
				#rem
					' if spheremap flag=true then flip tex
					If tex_flags&64<>0
						glScalef(1.0,-1.0,-1.0)
					Endif
				#end
					
					' if cubemap flag=true then manipulate texture matrix so that cubemap is displayed properly 
					If tex_flags&128<>0

						

					Endif
					
				Endif ''end if tex[ix]
			
			Next 'end texture loop
			
			
			
			'' turn off textures if no textures
			If tex_count = 0
			
				'For Local ix:=0 To last_tex_count-1
			
					'driver.SetTextureAt(ix, Null )
				
				'Next
				
				last_texture = Null
				driver.SetTextureAt(0, tex_map.Get(null_tex.tex_id) )
				'driver.SetVertexBufferAt (3, Null)
				driver.SetVertexBufferAt (3, vbuffer, VertexDataBuffer.TEXCOORDS_OFFSET Shr 2, DRIVER_FLOAT_2)
			Endif
			
			
			last_tex_count = tex_count
			
			
			
			'' set agal program constants
			
			
	
			If mesh.is_sprite=False
				ent.mat.ToArray(t_array)
				driver.UploadConstantsFromArray(DRIVER_VERTEX_PROGRAM, 4, t_array)
			Else
				TSprite(mesh).mat_sp.ToArray(t_array)
				driver.UploadConstantsFromArray(DRIVER_VERTEX_PROGRAM, 4, t_array)
			Endif
			
			'' draw tris
			
			If cam.draw2D
				'glDisable(GL_DEPTH_TEST)
				'glDisable(GL_FOG)
				'glDisable(GL_LIGHTING)
			Endif

			If TRender.render.wireframe
				
				''** needs special shader
				
			Else
				If vbo	
					
					
					Try
						driver.DrawTriangles(ibuffer, 0, surf.no_tris)
					Catch e:FlashError
						Print "**"+e.ToString()
					End
				Else

					'
					
				Endif
			Endif

			
			
	
			' enable fog again if fog was enabled at start of func
			If fog=True
				'glEnable(GL_FOG)
				effect.use_fog = True
			Endif

		Next ''end non-alpha loop
		
		
		If cam.draw2D
			'glEnable(GL_DEPTH_TEST)
			'glEnable(GL_LIGHTING)
		Endif

		If Not alpha_list Then Exit ''get out of loop, no alpha
		temp_list = alpha_list
		
		Next	''end alpha loop
		
		temp_list = Null
		
		
		
		'glBindBuffer( GL_ARRAY_BUFFER, 0 ) '' releases buffer for return to mojo buffer??? may not need
		'glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,0)
	
	
	End
	
	
	
	Method Finish:Void()
		
		''
		driver.PresentToMojoBitmap(GetGraphicsDevice() )
		'driver.Present()

	End
	
	
	Method GraphicsInit:Int(flags:Int=0)
		
		TRender.render = New FlashMiniB3D
		width = DeviceWidth()
		height = DeviceHeight()
		
		''call for a stage3d context, which takes one frame to be called
		driver.InitContext(width, height, False, 0) ''w,h,antialias,flags
		
		
		TTexture.TextureFilter("",8+1) ''default texture settings: mipmap

		' get hardware info and set vbo_enabled accordingly
		'THardwareInfo.GetInfo()
		'THardwareInfo.DisplayInfo()
		
		
		
		''get the TPixmapManager set
		TPixmapFlash.Init()
		
		'' set my error side-stepping for AGAL programs
		null_tex = CreateTexture(1,1,2)
		
		'If Not (flags & DISABLE_VBO)
			vbo_enabled=True
		'Endif

		
			
		TEntity.global_mat.LoadIdentity()
		
		Return 1
		
	End 
	
	Method EnableStates:Void()
		
		If GetVersion() < 11 Then Error "You will need at least Flash 11 for this to work."
		
Print "..Context Success"
		
		driver.EnableErrorChecking(False)
		
#If CONFIG="debug"		
		Print "..FLASH STAGE3D VERSION:"+GetVersion()
		
		driver.EnableErrorChecking(True)
#Endif

   		'glEnable(GL_DEPTH_TEST)
		driver.SetDepthTest(True, DRIVER_LESS_EQUAL)
		driver.SetCulling(DRIVER_NONE) 'BACK)
		
		TShader.LoadDefaultShader( TShaderFlash.LoadShaderString(TShaderFlash.TestVP, TShaderFlash.TestFP) )
		
		render_init = True
		
	End 
	
	Function GetFlashError:Int()
		'Local gle:Int = glGetError()
		'If gle<>GL_NO_ERROR Then Print "**vbo glerror: "+gle; Return 1
		Return 0
	End
	
	Method ClearErrors()
		'While glGetError()<>GL_NO_ERROR
		 '
		'Wend
	End	
	
	'' assign buffer id and create buffers here
	'' reset_vbo =-1 will reset buffer, used for clear surface and adding new vertices
	Method UpdateBuffers:Int( surf:TSurface, vbuffer:VertexBuffer3D, ibuffer:IndexBuffer3D, abuffer:VertexBuffer3D=Null )
		
		If surf.reset_vbo=0 And surf.vbo_id[0]<>0 Then Return 0
		
		'Local vbuffer:VertexBuffer3D
Print "xxx"		
		If surf.vbo_id[0]=0 Or surf.reset_vbo = -1
			'glGenBuffers(6,surf.vbo_id)
			
			surf_buf_id +=1 ''never use 0
			If surf_buf_id=0 Then surf_buf_id =1 ''id overflow?
			surf.vbo_id[0] = surf_buf_id
			
			'' CreateVertexBuffer.... the number of 32-bit(4-byte) data values associated with each vertex
			vbuffer = driver.CreateVertexBuffer( surf.no_verts, 16 ) ''size/4 = number, not byte size
Print "create vb "+surf.no_verts+" "+(VertexDataBuffer.SIZE*0.25	)
			ibuffer = driver.CreateIndexBuffer(surf.no_tris*3)
Print "create ib "+(surf.no_tris*3)
			vbuf_map.Set(surf.vbo_id[0], vbuffer)
			ibuf_map.Set(surf.vbo_id[0], ibuffer)
			
			If surf.vert_anim
				'abuffer = driver.CreateVertexBuffer( surf.no_verts, 3 ) ''3v
				'abuf_map.Set(surf.vbo_id[0], abuffer)
			Endif
			
			surf.reset_vbo = -1 ''set for possible vbo_id[0] reset (lost context)
			
		Else

			If Not vbuffer Or Not ibuffer Then Print "*** vbuffer/ibuffer error"; Return 0
			If surf.vert_anim And Not abuffer Then Print "** anim buffer error";Return 0
			
		Endif
		
		''reset and renew
		If surf.reset_vbo=-1 Then surf.reset_vbo=255


		
		''surf.vert_anim array should be null until it is set by VertexAnimation
		
		If surf.reset_vbo&1 Or surf.reset_vbo&2 Or surf.reset_vbo&4 Or surf.reset_vbo&8
			
			''updated animation
			If surf.vbo_dyn And Not surf.vert_anim
				'driver.UploadVertexFromDataBuffer(vbuffer, surf.vert_data.buf, 0,0, surf.no_verts)
			
			''vertex animation sequence
			Elseif surf.vbo_dyn And surf.vert_anim And surf.reset_vbo&1
				'driver.UploadVertexFromDataBuffer(abuffer, surf.vert_anim[surf.anim_frame].buf, 0,0, surf.no_verts)
				
			Else
				''normal static
	Print ".. "+surf.no_verts+"  "+surf.vert_data.buf.Length()
				driver.UploadVertexFromDataBuffer(vbuffer, surf.vert_data.buf, 0,0, surf.no_verts)
			Endif
			
		Endif
		
		If surf.reset_vbo&16
Print ".. "+surf.no_tris*3
			driver.UploadIndexFromDataBuffer(ibuffer, surf.tris.buf,0,0,surf.no_tris*3)
			
		Endif
		
		If DEBUG And GetFlashError() Then Print "*vbo update"

		
		surf.reset_vbo=0
		
	End
	
	
	Method FreeBuffers(surf:TSurface)
		
		Local vb:VertexBuffer3D = vbuf_map.Get(surf.vbo_id[0])
		Local ib:IndexBuffer3D = ibuf_map.Get(surf.vbo_id[0])
		vb.Dispose()
		ib.Dispose()
		
		If surf.vert_anim
			vb= abuf_map.Get(surf.vbo_id[0])
			vb.Dispose()
		Endif
		
		If surf.vbo_id[0]<>0 
			surf.vbo_id = [0,0,0,0,0,0]
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
	
	
	'' --- TTexture specific---
	
	Method DeleteTexture(tex:TTexture)
		
	End
	
	Method DeleteTexture_(tex:TTexture)
		
		Local ftex:FlashTexture = tex_map.Get(tex.tex_id)
		ftex.Dispose()
		tex_map.Set(tex.tex_id, Null)
		tex.tex_id=0
		
	End
	
	Method BindTexture:TTexture(tex:TTexture,flags:Int)
		''
		'' --PIXMAP MUST BE POWER OF TWO
		''
		
		TRender.render.ClearErrors()	
		
		''retrieve bind flags from stack
		'If tex.bind_flags <>-1 Then flags = tex.bind_flags Else flags = tex.flags
		
		' if mask flag is true, mask pixmap
		If flags&4
			tex.pixmap.MaskPixmap(0,0,0)
		Endif

		
		' pixmap -> tex

		Local width=tex.pixmap.width
		Local height=tex.pixmap.height
		Local ftex:FlashTexture
		
		If Not tex.tex_id
			tex_map_id += 1
			tex.tex_id = tex_map_id
			ftex = driver.CreateTexture(width, height, DRIVER_BGRA, False);
			
			tex_map.Set(tex.tex_id, ftex)

		Endif
		
		
		Local mipmap:Int= 0, mip_level:Int=0
		Local pix:TPixmapFlash = TPixmapFlash(tex.pixmap)
		
		If flags&8 Then mipmap=True
			
			Repeat

				Local uploaded:Int = driver.UploadTextureData(ftex, pix.pixels, mip_level) ''cheating... beware
				
				If( Not uploaded )
					Error "** out of texture memory **"
				Endif
				
				If Not mipmap Or (width=1 And height =1) Then Exit
				If width>1 width *= 0.5
				If height>1 height *= 0.5

				If tex.resize_smooth
					pix=TPixmapFlash(pix.ResizePixmap(width,height))
				Else
					pix=TPixmapFlash(pix.ResizePixmapNoSmooth(width,height))
				Endif
				
				mip_level+=1
				
			Forever
			
		tex.no_mipmaps=mip_level
		
		Return tex
		
	End
	
	
	Method UpdateLight(cam:TCamera, light:TLight)
Return 0

#rem
		If light.remove_light
			DisableLight(light)
			Return
		Endif
		
		light_no=light_no+1
		If light_no>light.no_lights Then light_no=1
		
		If light.Hidden()=True
			glDisable(gl_light[light_no-1])
			Return
		Else
			glEnable(gl_light[light_no-1])
		Endif

		''detect new light, one-time initialize
		If old_no_lights<light_no

			glLightfv(gl_light[light_no-1],GL_SPECULAR, [light.spec_red,light.spec_grn,light.spec_blu,light.spec_a])
			
			' if point light or spotlight then set constant attenuation to 0

			glLightfv(gl_light[light_no-1],GL_CONSTANT_ATTENUATION,[light.const_att])

			
			' if spotlight then set exponent to 10.0 (controls fall-off of spotlight - roughly matches B3D)
			If light.light_type=3
				'Local exponent#[]=[10.0]
				glLightfv(gl_light[light_no-1],GL_SPOT_EXPONENT,[light.spot_exp])
			Endif	
		
		Endif
		
		old_no_lights = light_no
		
		glMatrixMode(GL_MODELVIEW)
		glPushMatrix()

		glMultMatrixf(light.mat.ToArray() )
		
		Local z#=1.0
		Local w#=0.0
		If light.light_type>1
			z=0.0
			w=1.0
		Endif
		
		Local rgba#[]=[light.red,light.green,light.blue,1.0]
		Local pos#[]=[0.0,0.0,z,w]
		
		glLightfv(gl_light[light_no-1],GL_POSITION,pos)
		glLightfv(gl_light[light_no-1],GL_DIFFUSE,rgba)

		' point or spotlight, set attenuation
		glLightfv(gl_light[light_no-1],GL_LINEAR_ATTENUATION,[light.lin_att])


		' spotlight, set direction and range
		If light.light_type=3 
		
			Local dir#[]=[0.0,0.0,-1.0]
			Local outer#[]=[light.outer_ang]
		
			glLightfv(gl_light[light_no-1],GL_SPOT_DIRECTION,dir)
			glLightfv(gl_light[light_no-1],GL_SPOT_CUTOFF,outer)
		
		Endif
		
		glPopMatrix()
#end
		
	End
	
	
	Method DisableLight(light:TLight)
		
		light.light_link.Remove()
		
		'glDisable(gl_light[light.no_lights])
		
		light = Null	
		
	End
	
	
	
	Method UpdateCamera(cam:TCamera)
	
		' viewport
		'glViewport(cam.vx,cam.vy,cam.vwidth,cam.vheight)
		driver.SetScissorRectangle(cam.vx,cam.vy,cam.vwidth,cam.vheight)
		
		''load VP of MVP matrix

		'cam.mod_mat.ToArray(t_array)	
		'driver.UploadConstantsFromArray(driver.VERTEX_PROGRAM, 0, t_array)
		
		cam.projview_mat.ToArray(t_array)
		driver.UploadConstantsFromArray(DRIVER_VERTEX_PROGRAM, 0, t_array)
	
		

		' clear buffers
		
		
		If cam.cls_color=True And cam.cls_zbuffer=True
			'glDepthMask(True)
			'glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT)
			'driver.SetDepthTest(True, driver.LESS_EQUAL)
			driver.Clear(cam.cls_r,cam.cls_g,cam.cls_b,1.0, 1.0, 0, DRIVER_CLEAR_ALL)
		Else
			If cam.cls_color=True
				driver.Clear(cam.cls_r,cam.cls_g,cam.cls_b,1.0, 1.0, 0, DRIVER_CLEAR_COLOR)
			Else
				If cam.cls_zbuffer=True
					'driver.SetDepthTest(True, driver.LESS_EQUAL)
					driver.Clear(cam.cls_r,cam.cls_g,cam.cls_b,1.0, 1.0, 0, DRIVER_CLEAR_DEPTH)
				Endif
			Endif
		Endif


		'fog
		If cam.fog_mode>0
			'glEnable(GL_FOG)
			'glFogf(GL_FOG_MODE,GL_LINEAR)
			'glFogf(GL_FOG_START,cam.fog_range_near)
			'glFogf(GL_FOG_END,cam.fog_range_far)

			'glFogfv(GL_FOG_COLOR,[cam.fog_r,cam.fog_g,cam.fog_b,1.0])
		Else
			'glDisable(GL_FOG)
		Endif
	
	
	End
	
	
	Method BackBufferToTex(mipmap_no=0,frame=0)

		If flags&128=0 ' normal texture
	
			Local x=0,y=0
	
			glBindtexture GL_TEXTURE_2D,gltex[frame]
			glCopyTexImage2D(GL_TEXTURE_2D,mipmap_no,GL_RGBA,x,TRender.height-y-height,width,height,0)
			
		Else ' no cubemap texture (2012 gles 1.x)

			'Local x=0,y=0
	
			'glBindtexture GL_TEXTURE_CUBE_MAP_EXT,gltex[0]
			'Select cube_face
				'Case 0 glCopyTexImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_X,mipmap_no,GL_RGBA8,x,TGlobal.height-y-height,width,height,0)
				'Case 1 glCopyTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_Z,mipmap_no,GL_RGBA8,x,TGlobal.height-y-height,width,height,0)
				'Case 2 glCopyTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X,mipmap_no,GL_RGBA8,x,TGlobal.height-y-height,width,height,0)
				'Case 3 glCopyTexImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_Z,mipmap_no,GL_RGBA8,x,TGlobal.height-y-height,width,height,0)
				'Case 4 glCopyTexImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_Y,mipmap_no,GL_RGBA8,x,TGlobal.height-y-height,width,height,0)
				'Case 5 glCopyTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_Y,mipmap_no,GL_RGBA8,x,TGlobal.height-y-height,width,height,0)
			'End Select
		
		Endif

	End 

	
End




