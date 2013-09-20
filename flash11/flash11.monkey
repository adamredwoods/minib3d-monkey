Import mojo
Import minib3d
Import minib3d.trender
Import minib3d.flash11.tpixmap_flash
Import minib3d.flash11.flash11_driver
Import minib3d.flash11.tshader_flash
Import minib3d.math.arrayintmap

#rem
	
	NOTES:
	'' minib3d is -z, which is opposite flash
	'' UploadConstantsFromArray() the -1 register check is in the native code
#end



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
	SetMojoEmulation()
	
End	



Class TexData
	
	Field tex_count:Int
	Field texture:TTexture[8]
	Field tex_flags:Int[8]
	Field tex_blend:Int[8]
	Field tex_coords:Int[8]
	Field tex_u_scale:Float[8]
	Field tex_v_scale:Float[8]
	Field tex_u_pos:Float[8]
	Field tex_v_pos:Float[8]
	Field tex_ang:Float[8]
	Field tex_cube_mode:Int[8]
	Field frame:Int[8]
	Field tex_smooth:Int[8]
	
	Field uv_clamp:Int
	
	Global null_tex:TTexture
	
	Method UpdateTexture(surf:TSurface, ent:TEntity)
	
		'' textures
			tex_count=0	
			
			tex_count=ent.brush.no_texs
			'If surf.brush<>Null
				If surf.brush.no_texs>tex_count Then tex_count=surf.brush.no_texs
			'EndIf
			
			
		
			For Local ix=0 To tex_count-1			
	
				If surf.brush.tex[ix]<>Null Or ent.brush.tex[ix]<>Null
					
					'Local texture:TTexture,tex_flags,tex_blend,tex_coords,tex_u_scale#,tex_v_scale#
					'Local tex_u_pos#,tex_v_pos#,tex_ang#,tex_cube_mode,frame, tex_smooth

					' Main brush texture takes precedent over surface brush texture
					If ent.brush.tex[ix]<>Null
						If ent.brush.tex[ix].width=0 Then tex_count=0; Exit
						
						texture[ix]=ent.brush.tex[ix]
						tex_flags[ix]=ent.brush.tex[ix].flags
						tex_blend[ix]=ent.brush.tex[ix].blend
						tex_coords[ix]=ent.brush.tex[ix].coords
						tex_u_scale[ix]=ent.brush.tex[ix].u_scale
						tex_v_scale[ix]=ent.brush.tex[ix].v_scale
						tex_u_pos[ix]=ent.brush.tex[ix].u_pos
						tex_v_pos[ix]=ent.brush.tex[ix].v_pos
						tex_ang[ix]=ent.brush.tex[ix].angle
						tex_cube_mode[ix]=ent.brush.tex[ix].cube_mode
						frame[ix]=ent.brush.tex[ix].tex_frame
						tex_smooth[ix] = ent.brush.tex[ix].tex_smooth		
					Else
						If surf.brush.tex[ix].width=0 Then tex_count=ix-1; Exit
						
						texture[ix]=surf.brush.tex[ix]
						tex_flags[ix]=surf.brush.tex[ix].flags
						tex_blend[ix]=surf.brush.tex[ix].blend
						tex_coords[ix]=surf.brush.tex[ix].coords
						tex_u_scale[ix]=surf.brush.tex[ix].u_scale
						tex_v_scale[ix]=surf.brush.tex[ix].v_scale
						tex_u_pos[ix]=surf.brush.tex[ix].u_pos
						tex_v_pos[ix]=surf.brush.tex[ix].v_pos
						tex_ang[ix]=surf.brush.tex[ix].angle
						tex_cube_mode[ix]=surf.brush.tex[ix].cube_mode
						frame[ix]=surf.brush.tex[ix].tex_frame
						tex_smooth[ix] = surf.brush.tex[ix].tex_smooth		
					Endif
					
					If tex_flags[ix]&16<>0 Or tex_flags[ix]&32<>0
						uv_clamp = 1
					Else
						uv_clamp = 0
					Endif
					
					If texture[ix].width =0 Then texture[ix] = null_tex
					
				Endif
			Next
					
	End
	
End


Class FlashMiniB3D Extends TRender Implements IShader2D
	
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
	
	Field vbuf_map:ArrayIntMap<VertexBuffer3D> = New ArrayIntMap<VertexBuffer3D>
	Field ibuf_map:ArrayIntMap<IndexBuffer3D> = New ArrayIntMap<IndexBuffer3D>
	Field abuf_map:ArrayIntMap<VertexBuffer3D> = New ArrayIntMap<VertexBuffer3D>
	
	Private
	
	Field render_init:Bool = False
	
	Field shader:TShaderFlash
	Field last_shader:TShaderFlash
	Field surf_buf_id:Int =0''used to keep surface's VertexBuffer3D
	
	Field tex_map_id:Int =0
	Field tex_map:ArrayIntMap<FlashTexture> = New ArrayIntMap<FlashTexture>
	
	Field effect:EffectState = New EffectState , last_effect:EffectState = New EffectState
	Field texdata:TexData = New TexData
	'Field depth__:Bool = True
	
	Field _device:GraphicsDevice
	
	Global null_tex:TTexture
	Global lastCam:Bool = False
	Global current_cam:TCamera
	Global shader2d_:TShaderFlash
	
	Global temp_cam:Matrix = New Matrix
	Global temp_mat:Matrix = New Matrix
	
	Public
	
	Method New()
		
		shader2D = self
		
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
'If Not MojoEmulationDevice(_device) And (Not _device) Then _device = GetGraphicsDevice()	
		''need to wait until the context is ready
		If Not render_init Then EnableStates()
		

		''reset globals used for state caching
		last_texture = Null ''used to preserve texture states
		last_sprite = Null ''used to preserve last surface states
		last_shader = null
		TRender.alpha_pass = 0
		last_effect.SetNull() ''forces next state to set
		
		driver.SetDepthTest(True, DRIVER_LESS_EQUAL)
		
		TShader.DefaultShader()
		
		
	End
	
	
	
	
	Method Render:Void(ent:TEntity, cam:TCamera = Null)
		
		''for stage3d, limits the number of present calls
		current_cam = cam
		
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
			Local skip_state:Bool = False
			If last_sprite = surf
				skip_state = True
			Else
				last_sprite = surf
			Endif
			
					
'Print "***classname: "+ent.classname+" : "+name+" cam:"+cam.name		
'Print "   alphaloop "+alphaloop+" "+" tribuffersize:"+surf.tris.Length()+", tris:"+surf.no_tris+", verts:"+surf.no_verts
'Print "   surfpass "+ccc+":"+alpha_pass+" vbo:"+surf.vbo_id[0]+" dynvbo:"+Int(surf.vbo_dyn)+" skip:"+Int(skip_state)
'Print "   mesh.anim:"+mesh.anim
'Print "   vboids:"+surf.vbo_id[0]+" "+surf.vbo_id[1]+" "+surf.vbo_id[2]+" "+surf.vbo_id[3]+" "+surf.vbo_id[4]+" "+surf.vbo_id[5]+" "
		

			'If vbo_enabled
			Local vbo:Int=True
			
			''get vbuffer and ibuffer, OK if null
			Local vbuffer:VertexBuffer3D
			Local ibuffer:IndexBuffer3D
			Local abuffer:VertexBuffer3D
				
			
			' update vbuffer
			UpdateVBO(surf)
			vbuffer = vbuf_map.Get(surf.vbo_id[0])
			ibuffer = ibuf_map.Get(surf.vbo_id[0])
			abuffer = null

			If mesh.anim
				
				' get anim_surf
				anim_surf2 = mesh.GetAnimSurface(surf) ''assign anim surface
				
				If anim_surf2
				
					' update abuffer
					anim_surf2.vbo_dyn = True ''****** flaw in the system: when is this set? set too late? *******
					UpdateVBO(anim_surf2)
					abuffer = abuf_map.Get(anim_surf2.vbo_id[0])
					
				Endif
				
			Endif
	

			effect.UpdateEffect( surf, ent, cam )
			texdata.UpdateTexture( surf, ent )
			
			
			'' ENABLE CORRECT SHADER BASED ON EFFECTS
			shader = TShaderFlash(TShader.g_shader)
			If MultiShader(shader)
				If effect.use_full_bright
 					If texdata.uv_clamp
 						shader = MultiShader(shader).GetShader(0) '' no lights, scene should be dark unless otherwise noted
 					Else
 						shader = MultiShader(shader).GetShader(1) ''uv repeat
 					Endif
				Else
					If texdata.uv_clamp
 						shader = MultiShader(shader).GetShader(2)
 					Else
 						shader = MultiShader(shader).GetShader(3) ''uv repeat
 					Endif
				Endif 
			Endif
			
			shader.Update()
		
'Print ent.classname+" "+Int(effect.depth_test)+" "+Int(effect.depth_write)+" "+effect.blend	

					
			If skip_state=false
				
				'' ** depth state **
				Local write:Bool = true
				If effect.use_depth_write=0 Then write=false
				
				If effect.use_depth_test<>last_effect.use_depth_test Or effect.use_depth_write<>last_effect.use_depth_write
					If effect.use_depth_test=0 Then driver.SetDepthTest(write, DRIVER_ALWAYS) Else driver.SetDepthTest(write, DRIVER_LESS_EQUAL)
				Endif
			
				
				If effect.use_backface_culling=0
					driver.SetCulling(DRIVER_NONE) ''need to light both sides
				Else
					driver.SetCulling(DRIVER_FRONT) '' minib3d is -z, which is opposite flash
				Endif
				
				' blend modes
				Select effect.blend
						Case 0
							driver.SetBlendFactors(DRIVER_SOURCE_ALPHA, DRIVER_ONE_MINUS_SOURCE_ALPHA)
						Case 1
							driver.SetBlendFactors(DRIVER_ONE, DRIVER_ONE_MINUS_SOURCE_ALPHA) ''premultiplied
						Case 2
							'glBlendFunc(GL_DST_COLOR,GL_ZERO) ' multiply
							driver.SetBlendFactors(DRIVER_DESTINATION_COLOR, DRIVER_ZERO)
						Case 3
							'glBlendFunc(GL_SRC_ALPHA,GL_ONE) ' additive and alpha
							driver.SetBlendFactors(DRIVER_SOURCE_ALPHA, DRIVER_ONE)
						Case 4
							'glBlendFunc(GL_ONE,GL_ONE) ' blend after texture
							driver.SetBlendFactors(DRIVER_ONE, DRIVER_ONE)
						Default
							driver.SetBlendFactors( DRIVER_ONE, DRIVER_ZERO ) ''no blending
				End
	
				
				''static mesh
				If Not (mesh.anim=True Or surf.vbo_dyn=true)
					driver.SetVertexBufferAt (shader.u.vertcoords, vbuffer, VertexDataBuffer.POS_OFFSET Shr 2, DRIVER_FLOAT_3) ''position 0
				Endif
				
				If (shader.u.normals >-1) Then driver.SetVertexBufferAt (shader.u.normals, vbuffer, VertexDataBuffer.NORMAL_OFFSET Shr 2, DRIVER_FLOAT_3) ''normal 1
				If (shader.u.colors >-1) Then driver.SetVertexBufferAt (shader.u.colors , vbuffer, VertexDataBuffer.COLOR_OFFSET Shr 2, DRIVER_FLOAT_4) ''color 2

			
			Endif  ''end skip_state--------------------------------------
		
		
			'' ** mesh animation/batch animation **
			
			If abuffer And (mesh.anim Or surf.vbo_dyn Or anim_surf2)
								
				''vertex animation
				If anim_surf2.vert_anim
					
					driver.SetVertexBufferAt (shader.u.vertcoords, abuffer, 0, DRIVER_FLOAT_3) '' tightly packed
					
				Else ' If surf.vbo_dyn
					'' mesh animation, using animsurf2
					driver.SetVertexBufferAt (shader.u.vertcoords, abuffer, VertexDataBuffer.POS_OFFSET Shr 2, DRIVER_FLOAT_3) ''position 0
					
				Endif
			Endif
			
			If abuffer=Null And surf.vbo_dyn 
				abuffer = abuf_map.Get(surf.vbo_id[0])
				driver.SetVertexBufferAt (shader.u.vertcoords, abuffer, VertexDataBuffer.POS_OFFSET Shr 2, DRIVER_FLOAT_3)
			Endif
			

				
			'' ** textures **
			Local tex_count=texdata.tex_count			
		
			For Local ix=0 To tex_count-1			
	
				If texdata.texture[ix]<>Null
					
						
					''preserve texture states--------------------------------------
					If (last_texture = texdata.texture[ix])
						
						'' skip texture Bind
						
					Else
					
						''texture bind
						
						last_texture = texdata.texture[ix]
						
						If (shader.u.texcoords0 >-1) Then driver.SetTextureAt(ix, tex_map.Get(last_texture.tex_id) )
	
					
					Endif ''end preserve texture states---------------------------------

					
					
					''assuming sprites with same surfaces are identical, preserve states---------
					If Not skip_state
					
					
					'' alpha-testing, moved to effect
					'If texdata.tex_flags[ix]&4<>0
					'
					'Endif
				
					' mipmapping texture flag

					If texdata.tex_flags[ix]&8<>0
						If texdata.tex_smooth[ix]
							'glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR)
							'glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST_MIPMAP_LINEAR)
						'Else
							'glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST)
							'glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST)
						Endif
					Else
						If texdata.tex_smooth[ix]
							'glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR)
							'glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR)
						'Else
							'glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST)
							'glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST)
						Endif
					Endif
				
					' clamp u flag ' clamp v flag
					If texdata.tex_flags[ix]&16<>0 Or texdata.tex_flags[ix]&32<>0
						'glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_CLAMP_TO_EDGE)
						'driver.SetSamplerStateAt(0, DRIVER_WRAP_CLAMP, DRIVER_TEX_LINEAR, DRIVER_MIP_LINEAR)
					Else						
						'glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_REPEAT)
						'driver.SetSamplerStateAt(0, DRIVER_WRAP_REPEAT, DRIVER_TEX_LINEAR, DRIVER_MIP_LINEAR)
					Endif
					
		
					'driver.UploadConstantsFromArray(DRIVER_FRAGMENT_PROGRAM, shader.u.tex_blend[ix], tex_blend[ix])
	
					' cubic environment map texture flag
					'If tex_flags&128<>0

					''fx&1024 = normal mapping
			
					''send tex blend info to shader
					#rem
							Select tex_blend
								Case 0 repalce
								Case 1 decal
								Case 2 modulate
								Case 3 add+alpha
								Case 4 dot3 combine
								Case 5 modulate*2
								Case 6 blend
								Default modulate
							End Select
					#end
			



					If texdata.tex_coords[ix]=0 And (shader.u.texcoords0 >-1)
					
						driver.SetVertexBufferAt (shader.u.texcoords0, vbuffer, VertexDataBuffer.TEXCOORDS_OFFSET Shr 2, DRIVER_FLOAT_2) ''uv 3
					Endif
					If texdata.tex_coords[ix]=1 And (shader.u.texcoords1 >-1)
				
						driver.SetVertexBufferAt (shader.u.texcoords1, vbuffer, (VertexDataBuffer.TEXCOORDS_OFFSET+VertexDataBuffer.ELEMENT2) Shr 2, DRIVER_FLOAT_2) ''uv 3
					Endif


			
					Endif ''end preserve skip_state-------------------------------
					
					
					' texture matrix
					'' pos shares with rot
					driver.UploadConstantsFromArray(DRIVER_VERTEX_PROGRAM, shader.u.tex_position[ix], [texdata.tex_u_pos[ix],texdata.tex_v_pos[ix], Cos(texdata.tex_ang[ix]), Sin(texdata.tex_ang[ix])])
					'' *DEGREESTORAD,tex_ang*DEGREESTORAD); 					
					driver.UploadConstantsFromArray(DRIVER_VERTEX_PROGRAM, shader.u.tex_scale[ix], [texdata.tex_u_scale[ix], texdata.tex_v_scale[ix],0.0,0.0])
				#rem
					' if spheremap flag=true then flip tex
					If tex_flags&64<>0
						glScalef(1.0,-1.0,-1.0)
					Endif
				#end
					
					' if cubemap flag=true then manipulate texture matrix so that cubemap is displayed properly 
					If texdata.tex_flags[ix]&128<>0
					Endif
					
				Endif ''end if tex[ix]
			
			Next 'end texture loop
			
			
			
			'' turn off textures if no textures
			If texdata.tex_count = 0 And (shader.u.texcoords0>-1 Or shader.u.texcoords1>-1) 
			
				For Local ix:=0 To last_tex_count-1
			
					driver.SetTextureAt(ix, Null )
				
				Next
		
				last_texture = Null
				driver.SetTextureAt(0, tex_map.Get(null_tex.tex_id) )
				If shader.u.texcoords0>-1
					driver.SetVertexBufferAt (shader.u.texcoords0, vbuffer, VertexDataBuffer.TEXCOORDS_OFFSET Shr 2, DRIVER_FLOAT_2)
				Endif
				If shader.u.texcoords1>-1
					driver.SetVertexBufferAt (shader.u.texcoords1, vbuffer, VertexDataBuffer.TEXCOORDS_OFFSET Shr 2 + VertexDataBuffer.ELEMENT2, DRIVER_FLOAT_2)
				endif
			Endif
			
			
			last_tex_count = texdata.tex_count
			
				
			
			
			'' set agal program constants
			
			'' ** entity matrix **
			temp_cam.Overwrite( cam.projview_mat ) ''temp camera
			
			If mesh.is_sprite=False
				temp_cam.Multiply4(ent.mat)

				driver.UploadConstantsFromArray(DRIVER_VERTEX_PROGRAM, shader.u.m_matrix, AGALMatrix(ent.mat) )
				temp_mat.Overwrite(ent.mat)
				'' INVERSE quick ok, used for normals
				driver.UploadConstantsFromArray(DRIVER_VERTEX_PROGRAM, shader.u.n_matrix, AGALMatrix(temp_mat.Inverse().Transpose()) )
			Else
				temp_cam.Multiply4(TSprite(mesh).mat_sp)
				
				driver.UploadConstantsFromArray(DRIVER_VERTEX_PROGRAM, shader.u.m_matrix, AGALMatrix(TSprite(mesh).mat_sp) )
				temp_mat.Overwrite(TSprite(mesh).mat_sp)
				'' INVERSE quick ok, used for normals
				driver.UploadConstantsFromArray(DRIVER_VERTEX_PROGRAM, shader.u.n_matrix, AGALMatrix(temp_mat.Inverse().Transpose()) )
			Endif
			
			'' ** camera **
			'' Flash Matrixes are transposed
			driver.UploadConstantsFromArray(DRIVER_VERTEX_PROGRAM, shader.u.p_matrix, AGALMatrix(temp_cam) )
			
			
			'' ** light **
			If shader.u.light_matrix[0] >-1 And TLight.light_list.IsEmpty()=False And effect.use_full_bright =0
				Local ll:TLight = TLight.light_list.First()
				temp_mat.Overwrite(ll.mat)
				
				If ll.light_type=1
					temp_mat.grid[3][0] = 0; temp_mat.grid[3][1] = 0; temp_mat.grid[3][2] = 1
					driver.UploadConstantsFromArray(DRIVER_VERTEX_PROGRAM, shader.u.lightflag, [1.0,0.0,0.0,0.0] )
				Else					
					If ll.light_type=2 Then driver.UploadConstantsFromArray(DRIVER_VERTEX_PROGRAM, shader.u.lightflag, [0.0,1.0,0.0,0.0] )
					If ll.light_type=3 Then driver.UploadConstantsFromArray(DRIVER_VERTEX_PROGRAM, shader.u.lightflag, [0.0,0.0,1.0,0.0] )
				Endif
						
				
				''--no not yet-- to help normal calculations, we can take the inverse object matrix for the light to enter object space
				
				driver.UploadConstantsFromArray(DRIVER_VERTEX_PROGRAM, shader.u.light_matrix[0], AGALMatrix(temp_mat) )
				driver.UploadConstantsFromArray(DRIVER_VERTEX_PROGRAM, shader.u.light_color[0], [ll.red,ll.green,ll.blue,1.0] )
				driver.UploadConstantsFromArray(DRIVER_VERTEX_PROGRAM, shader.u.light_att[0], [ll.const_att,ll.lin_att,ll.quad_att, ll.actual_range] )
			Else
				driver.UploadConstantsFromArray(DRIVER_VERTEX_PROGRAM, shader.u.light_color[0], [1.0,1.0,1.0,1.0] )
			Endif
			
			'' ** set material **	

			''one-minus colorflag = 1,1,1,1 if not set or r,g,b,a if set
			driver.UploadConstantsFromArray(DRIVER_VERTEX_PROGRAM, shader.u.colorflag, [1.0-effect.use_vertex_colors,0.0,0.0,0.0] )
			driver.UploadConstantsFromArray(DRIVER_VERTEX_PROGRAM, shader.u.base_color, effect.diffuse )
			driver.UploadConstantsFromArray(DRIVER_VERTEX_PROGRAM, shader.u.ambient_color, effect.ambient )
			''flags for alpha test & fog! used on both frag and vertex
			driver.UploadConstantsFromArray(DRIVER_VERTEX_PROGRAM, shader.u.miscflag, [0.5*effect.use_alpha_test,0.0,0.0,0.0] )
			driver.UploadConstantsFromArray(DRIVER_FRAGMENT_PROGRAM, shader.u.miscflag, [0.5*effect.use_alpha_test,0.0,0.0,0.0] )
		
			'' ** draw tris **
			
			If shader<>last_shader
				driver.SetProgram( shader.program_set )
				last_shader = shader
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

				Endif
			Endif

			last_effect.Overwrite(effect)

		Next ''end non-alpha loop
		


		If Not alpha_list Then Exit ''get out of loop, no alpha
		temp_list = alpha_list
		
		Next	''end alpha loop
		
		temp_list = Null
		
		
	
	End
	
	
	
	Method Finish:Void()
	
		'driver.Present()
		
	End
	
	Method RenderWorldFinish:Void()

		driver.PresentToDevice()
		driver.Clear(0.0,0.0,0.0,0.0, 1.0, 0, DRIVER_CLEAR_ALL)

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
		null_tex = CreateTexture(1,1,2) ''do i need to make this white?
		TexData.null_tex = null_tex
		
		'If Not (flags & DISABLE_VBO)
			vbo_enabled=True
		'Endif

		
			
		TEntity.global_mat.LoadIdentity()
		
		Return 1
		
	End 
	
	'' in Flash, EnableStates runs after Init() -- called from TRenderFlash.Reset()
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
		
		TShader.LoadDefaultShader( New MultiShader )
		
		FlashMiniB3D(TRender.render).ForceFlashTransparency(GetGraphicsDevice())
		driver.Clear(0.0,0.0,0.0,0.0, 1.0, 0, DRIVER_CLEAR_ALL)
		
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
	Method UpdateVBO:Int( surf:TSurface)
		
		Local vbuffer:VertexBuffer3D, ibuffer:IndexBuffer3D, abuffer:VertexBuffer3D
		Local createFlag:Bool = False
		
		'' no need to update
		If surf.reset_vbo=0 And surf.vbo_id[0]<>0 Then Return 0
		
		'Local vbuffer:VertexBuffer3D
		Local update:Int=0
'Print "bufid:"+surf.vbo_id[0]	
		
		''upload buffer data	
		If surf.vbo_id[0]=0 'Or surf.reset_vbo = -1
			
			surf_buf_id +=1 ''never use 0
			If surf_buf_id=0 Then surf_buf_id =1 ''id overflow?
			surf.vbo_id[0] = surf_buf_id
			
'Print "create buffer "+surf.vbo_id[0]
			createFlag = true
					
			'surf.reset_vbo = -1 ''set for possible vbo_id[0] reset (lost context)
			update =1
			
		Endif
		
		''reset and renew
		If surf.reset_vbo<0 Then createFlag = True; surf.reset_vbo=255


		
		''surf.vert_anim array should be null until it is set by VertexAnimation
		
		If surf.reset_vbo&1 Or surf.reset_vbo&2 Or surf.reset_vbo&4 Or surf.reset_vbo&8
			
			''updated animation
			If surf.vbo_dyn And (surf.vert_anim.Length = 0)
				If createFlag
					If abuffer Then abuffer.Dispose()
					abuffer = driver.CreateVertexBuffer( surf.no_verts, 16 )
					abuf_map.Set(surf.vbo_id[0], abuffer)
'Print "CREATE"
					'If ibuf_map.Get(surf.vbo_id[0])=null
						'ibuffer = driver.CreateIndexBuffer(surf.no_tris*3)
						'ibuf_map.Set(surf.vbo_id[0], ibuffer)
					'endif
				Else
					abuffer = abuf_map.Get(surf.vbo_id[0])
				endif
				
				driver.UploadVertexFromDataBuffer(abuffer, surf.vert_data.buf, 0,0, surf.no_verts)
				'If abuffer Then driver.UploadVertexFromDataBuffer(abuffer, surf.vert_data.buf, 0,0, surf.no_verts) Else Print "**ANIMBUFFERERROR"+surf.vbo_id[0]
				update =1

			Endif
				
			
			''vertex animation sequence
			if surf.vbo_dyn And surf.vert_anim.Length <>0 'And surf.vert_anim[surf.anim_frame] 'surf.reset_vbo&1
				If createFlag
					If abuffer Then abuffer.Dispose()
					abuffer = driver.CreateVertexBuffer( surf.no_verts, 3) ''3v
					abuf_map.Set(surf.vbo_id[0], abuffer)


				Else
					abuffer = abuf_map.Get(surf.vbo_id[0])
				Endif
				
				driver.UploadVertexFromDataBuffer(abuffer, surf.vert_anim[surf.anim_frame].buf, 0,0, surf.no_verts)
				update =1		

				
			Else
				''normal static
				If createFlag
					'' CreateVertexBuffer.... the number of 32-bit(4-byte) data values associated with each vertex				
					If vbuffer Then vbuffer.Dispose()
					If ibuffer Then ibuffer.Dispose()
					
					vbuffer = driver.CreateVertexBuffer( surf.no_verts, 16 ) ''size/4 = number, not byte size
'Print "create vb "+surf.no_verts+" "+(VertexDataBuffer.SIZE*0.25	)
					ibuffer = driver.CreateIndexBuffer(surf.no_tris*3)
'Print "create ib "+(surf.no_tris*3)
					vbuf_map.Set(surf.vbo_id[0], vbuffer)
					ibuf_map.Set(surf.vbo_id[0], ibuffer)
				Else
					vbuffer = vbuf_map.Get(surf.vbo_id[0])
				Endif
'Print ".. "+surf.no_verts+"  "+surf.vert_data.buf.Length()
				
				driver.UploadVertexFromDataBuffer(vbuffer, surf.vert_data.buf, 0,0, surf.no_verts)
				update =1
			Endif
			
		Endif
		
		If surf.reset_vbo&16
'Print ".. "+surf.no_tris*3
			ibuffer = ibuf_map.Get(surf.vbo_id[0])
			If ibuffer Then driver.UploadIndexFromDataBuffer(ibuffer, surf.tris.buf,0,0,surf.no_tris*3)
			update =1
		Endif
		
		If DEBUG And GetFlashError() Then Print "*error: vbo update"

		
		surf.reset_vbo=0
		
		Return update
		
	End
	
	

	
	Method FreeVBO(surf:TSurface)
		
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
		
		' if mask flag is true, mask pixmap '** WONRG! this is texture alpha-test
		If flags&4
			'tex.pixmap.MaskPixmap(0,0,0)
		Endif

		
		' pixmap -> tex

		Local width=tex.pixmap.width
		Local height=tex.pixmap.height
		Local ftex:FlashTexture
		
		If tex.pixmap.bind And tex.tex_id Then Return tex
		If width=0 Or height=0 Then Return tex '' width height=0 means this wasn't loaded yet
		
		If Not tex.tex_id
			tex_map_id += 1
			tex.tex_id = tex_map_id
			ftex = driver.CreateTexture(width, height, DRIVER_BGRA, False)
			
			tex_map.Set(tex.tex_id, ftex)

		Endif
		
		
		Local mipmap:Int= 0, mip_level:Int=0
		Local pix:TPixmapFlash = TPixmapFlash(tex.pixmap)
		
		If flags&8 Then mipmap=True
			
			Repeat

				Local uploaded:Int = driver.UploadTextureData(ftex, pix.pixels, mip_level) ''cheating... beware
				
				If( Not uploaded )
					Error "** out of texture memory or no data **"
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
		tex.pixmap.SetBind()
		
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
		
		If cam.Hidden Then Return
		
		' viewport
		'TRender.height-h-y
		driver.SetScissorRectangle(cam.vx,-(cam.vy-render.height+cam.vheight),cam.vwidth,cam.vheight)
		'driver.SetScissorRectangle(cam.vx,cam.vy,cam.vwidth,cam.vheight)

		

		' clear buffers
		'' ** this clears the whole buffer in flash11
		If cam.cls_color=True And cam.cls_zbuffer=True
			
			driver.Clear(cam.cls_r,cam.cls_g,cam.cls_b,0.0, 1.0, 0, DRIVER_CLEAR_DEPTH)
			DrawClearQuad(cam,cam.cls_r,cam.cls_g,cam.cls_b) ''** clear quad will set the alpha to 1.0, which is not what we want
			
			
			
			'driver.SetDepthTest(True, DRIVER_ALWAYS)
			'driver.Clear(0.0,0.0,0.0,0.0, 1.0, 0, DRIVER_CLEAR_DEPTH)
			
		Else

			If cam.cls_color=True
				'driver.Clear(cam.cls_r,cam.cls_g,cam.cls_b,1.0, 1.0, 0, DRIVER_CLEAR_COLOR)
				DrawClearQuad(cam,cam.cls_r,cam.cls_g,cam.cls_b)
			ElseIf cam.cls_zbuffer=True
				'driver.SetDepthTest(True, driver.LESS_EQUAL)
				driver.Clear(cam.cls_r,cam.cls_g,cam.cls_b ,0.0, 1.0, 0, DRIVER_CLEAR_DEPTH)
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

Private
	Global fastQuad:TMesh

	Method DrawClearQuad:Void(cam:TCamera,r:float,g:float,b:float)

		If fastQuad = Null
			fastQuad = CreateSprite()
			fastQuad.RemoveFromRenderList
			fastQuad.ScaleEntity(render.width,render.height,1.0)
			fastQuad.PositionEntity(0,0,1.99999)
			fastQuad.EntityFX(1+8+32+64)
			'fastQuad.alpha_order=1.0
			fastQuad.classname="fastQuad"
			IRenderUpdate(fastQuad).Update(camera2D)
		Endif
		
		TRender.render.Reset()
		SetShader2D()
		fastQuad.EntityColorFloat(r,g,b)
		
		alpha_pass=1
		Local wireframeIsEnabled:Int = wireframe
		wireframe = False
		'camera2D.SetPixelCamera
		'camera2D.Update(camera2D)
		driver.SetColorMask(True,True,True,true)
		FlashMiniB3D.render.Render(fastQuad,camera2D)
		driver.SetColorMask(True,True,True,True)
		wireframe = wireframeIsEnabled
		TRender.render.Finish()
		TRender.render.Reset()
		'cam.Update(cam)
	End
Public	
	
	Method SetShader2D:Void()
		If Not shader2d_
			'shader2d_ = New FullBrightOneTexShader("clamp")
		Endif
		'TShader.SetShader(shader2d_)
		
		shader2d_ = TShaderFlash(TShader.DefaultShader())
	End
	
	Method ForceFlashTransparency:Void(g:GraphicsDevice)
		driver.ForceDeviceTransparency(g )
	End
	
End


Function AGALMatrix:Float[](m:Matrix)
		Return [
		 m.grid[0][0], m.grid[1][0], m.grid[2][0],  m.grid[3][0],
		 m.grid[0][1], m.grid[1][1], m.grid[2][1],  m.grid[3][1],
		 m.grid[0][2], m.grid[1][2], m.grid[2][2], m.grid[3][2],
		 m.grid[0][3], m.grid[1][3], m.grid[2][3], m.grid[3][3] ]

End
