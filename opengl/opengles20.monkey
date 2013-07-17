''OPENGL2.0 minib3d engine
''
''NOTES:
'' -- problems with FireFox if we do not send color vertex info (and shader has uniform for it)

Import mojo
Import opengl.gles20


#OPENGL_GLES20_ENABLED=True
#OPENGL_DEPTH_BUFFER_ENABLED=True
#MINIB3D_DRIVER="opengl20"
#ANDROID_NATIVE_GL_ENABLED=True ''*************************PROBLEMATIC? only used on Android 2.2*****************************


Import minib3d.trender
Import minib3d.opengl.tshaderglsl
Import minib3d.opengl.tpixmapgl
Import minib3d.opengl.basicshadersgl
Import minib3d.monkeyutility

Import minib3d.opengl.framebuffergl

#If TARGET="xna"
	#Error "Need glfw, ios, android, or mingw target"
#Endif

#Print "miniB3D OpenglES20"


#If TARGET="html5"
	Extern
		'Function glTexImage2D2( target:Int,level:Int,internalformat:Int,width:Int,height:Int,border:Int,format:Int,type:Int,pixels:Int )="_glTexImage2D2"
		Global CheckWebGL:Int = "window.WebGLRenderingContext"
		Global CheckWebGLContext:Int = "CheckWebGLContext()" ''placed function in tpixmaphtml5.js
	Public
#Else
	Global CheckWebGL:Int =1
	Global CheckWebGLContext:Int = 1
#Endif



' if USE_VBO=True and vbos are supported by hardware, then surface must also have this minimum no. of tris before vbo is used for surface (vbos work best with surfaces with high amount of tris)
Const VBO_MIN_TRIS=1
	

'flags
Const DISABLE_MAX2D=1	' true to enable max2d/minib3d integration --not in use for now
Const DISABLE_VBO=2	' true to use vbos if supported by hardware
Const USE_GL20 = 4 	' future use for opengl 2.0 support


Function SetRender(flags:Int=0)

	TRender.render = New OpenglES20
	TRender.render.GraphicsInit(flags)
	SetMojoEmulation()
	
End



''beware, no Mojo in opengl2.0
Function RestoreMojo2D()

	OpenglES20._useMojo=True
	GetGraphicsDevice().BeginRender()
	
End


Class OpenglES20 Extends TRender Implements IShader2D
	
	Const DEBUG:Int = TRender.DEBUG
	Const DEGREESTORAD:Float = PI/180.0
	
	'Global g_shader:TShaderGLSL ''default shader
	
	''used for optimizing the fixed-pipeline render routine
	
	Global alpha_list:SurfaceAlphaList = New SurfaceAlphaList  ''used to draw and sort alpha surfaces last
	'Global alpha_anim_list:SurfaceAlphaList = New SurfaceAlphaList  ''no need-- connected anim_surf t surf

	Global last_texture:TTexture ''used to preserve texture states
	Global last_surf:TSurface ''used to batch sprite state switching
	Global last_shader:Int
	Global last_tex_count:Int =8
	
	Global disable_depth:Bool = False '' used for EntityFx 64 - disable depth testing
	Global effect:EffectState = New EffectState
	Global last_effect:EffectState = New EffectState
	
	Field cam_matrix_upload:Int=0
	
	Field light:TLight[] = New TLight[8]
	Field pmat:Matrix = New Matrix
	Field pvmat_array:Float[16], vmat_array:Float[16]
	Field vp_matrix:Matrix = New Matrix
	Field v_matrix:Matrix = New Matrix
	Field fog_flag:Int
	
	Field t_array:Float[] = New Float[16] 'temp array
	
	Global total_errors:Int=0
	
	Private
	
	Global _useMojo:Bool = False
	Global _usePerPixelLighting:Int = 0
	
	Public
	
	Method New()
		
		shader2D = self
		
	End
	
	
	Method ContextReady:Bool()

		Return True
	End
	
	'' returns negative value for WebGL version
	Method GetVersion:Float()
		Local webgl:String, st:String
		
		If Not CheckWebGL Then Error "** WebGL not found. Please upgrade or check browser options. ~n~n"
		If Not CheckWebGLContext Then Error "** WebGL Context not found. Please upgrade or check browser options. ~n~n"
		
		Local s:String = glGetString(GL_VERSION)
		If DEBUG Then Print s	
	
		webgl = s.Split(" ")[0]
		
		Local num:Int=0
		
		For Local i:Int=0 To s.Length()-1

			If (s[i] >47 And s[i]<58)
				st=st+String.FromChar(s[i])
				If num =0 Then num=1
			Elseif s[i]=46
				If num=2 Then Exit
				st=st+String.FromChar(s[i])
				num=2
			Elseif num<>0
				Exit
			Endif 
		Next

		Local sn:Float=1.0

		If webgl.ToLower().Trim() = "webgl" Then sn=-1.0
		Return Float( st )*sn
		
	End
	
	Method Reset:Void()
		
		''reset globals used for state caching
		last_texture = Null ''used to preserve texture states
		last_surf = Null ''used to preserve last surface states
		TRender.alpha_pass = 0
		last_shader = -1
		cam_matrix_upload=0
		last_tex_count= -1
		
		ResetLights()
		last_effect.SetNull() ''forces next state to set
		TShader.DefaultShader()

		'Print "....begin render...."
		
	End
	
	Method ResetLights:Void()
		
		light = New TLight[8]
		
		Local i:Int=0
		For Local li:TLight = Eachin TLight.light_list
			light[i] = li
			i+=1
			If i>8 Then Exit
		Next
		For Local j:Int = i To 8-1
			light[j] = Null
		Next
		
	End
	
	Method Finish:Void()
		
		glFlush()
		
	End
	
	Method Render:Void(ent:TEntity, cam:TCamera = Null)
		
		Local mesh:TMesh = TMesh(ent)
		If Not mesh Then Return
		
		Local name$=ent.EntityName()

	
		'glDisable(GL_ALPHA_TEST)


		''assign shader
		Local shader:TShaderGLSL
		shader = TShaderGLSL(TShader.g_shader)
		
		
		
		If Not shader.active Then Return '' a brush shader can be deactive, but a global shader cannot
		
		''set shader brush if one
		If TShaderGLSL(ent.shader_brush) And (Not shader.override) And ent.shader_brush.active

			shader = TShaderGLSL(ent.shader_brush)
			
			If IShaderEntity(shader) ''if we are using a brush with a dedicated render routine
				
				''call entity render routine
				IShaderEntity(shader).RenderEntity(cam, ent)
				
				If shader.shader_id<>last_shader Then last_shader = shader.shader_id ''make sure to catch this
				
				Return
				
			Endif
			
		Endif
		
		
		
		Local anim_surf2:TSurface
		Local surf:TSurface
		Local ccc:Int=0 ''counter for debugging
		Local lightflag:Int=1 ''for opengl2.0 shader
		
		'' draw surfaces with alpha last
		Local temp_list:List<TSurface> = mesh.surf_list
		alpha_list.Clear()
	
		''re-enable at end
		If cam.draw2D
			effect.use_depth_test = False
			'glDisable(GL_DEPTH_TEST)
		Endif
		
		''run through surfaces twice, sort alpha surfaces for second pass
		For Local alphaloop:= alpha_pass To 1 ''if alpha_pass is on, no need to reorder alpha surfs
		
		For surf = Eachin temp_list

			'If GetGLError() Then Print "*render start"
			ccc+=1
			
			''draw alpha surfaces last in second loop
			''also catch surfaces with no vertex
			If surf.no_verts=0 Then Continue
			If (surf.alpha_enable And alphaloop < 1)
			
				alpha_list.AddLast(surf)				
				Continue
				
			Endif
			
			
			Local vbo:Int=True
			
			''ALWAYS use VBOs for opengl20, unless android api8
			If Not vbo_enabled
				vbo=False
				
				' if surf no longer has required no of tris then free vbo
				If surf.vbo_id[0]<>0 
					glDeleteBuffer(surf.vbo_id[0])
					glDeleteBuffer(surf.vbo_id[1])
					glDeleteBuffer(surf.vbo_id[2])
					glDeleteBuffer(surf.vbo_id[3])
					glDeleteBuffer(surf.vbo_id[4])
					glDeleteBuffer(surf.vbo_id[5])
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
				anim_surf2 = mesh.anim_surf[surf.surf_id]
				
				If vbo And anim_surf2
				
					' update vbo
					If anim_surf2.reset_vbo<>False
						UpdateVBO(anim_surf2)
					Else If anim_surf2.vbo_id[0]=0 ' no vbo - unknown reason
						anim_surf2.reset_vbo=-1
						UpdateVBO(anim_surf2)
					Endif
				
				Endif
				
			Endif
			


			''batch optimizations (sprites/meshes)
			Local skip_sprite_state:Bool = False
			If last_surf = surf And shader.shader_id = last_shader
				skip_sprite_state = True
			Else
				last_surf = surf
			Endif

'Print "***classname: "+ent.classname+" : "+name		
'Print "   alphaloop "+alphaloop+" "+" tribuffersize:"+surf.tris.Length()+", tris:"+surf.no_tris+", verts:"+surf.no_verts
'Print "   surfpass "+ccc+":"+alpha_pass+" vbo:"+surf.vbo_id[0]+" dynvbo:"+Int(surf.vbo_dyn)+" skip:"+Int(skip_sprite_state)
'Print "   mesh.anim:"+mesh.anim
'Print "   vboids:"+surf.vbo_id[0]+" "+surf.vbo_id[1]+" "+surf.vbo_id[2]+" "+surf.vbo_id[3]+" "+surf.vbo_id[4]+" "+surf.vbo_id[5]+" "
		
'Print " shader:"+shader.name
			''enable shader and check for last_state
			
			effect.UpdateEffect( surf, ent, cam )
			
			'' need to get tex count to set shader
			Local tex_count:Int =ent.brush.no_texs
			If surf.brush.no_texs>tex_count Then tex_count=surf.brush.no_texs
			If tex_count > shader.MAX_TEXTURES-1 Then tex_count = shader.MAX_TEXTURES-1
			
			''SHADER ACTIVATION---------------------------------
			If FullShader(shader) <> Null
				shader = FullShader.GetShader(_usePerPixelLighting, 1, tex_count)
			Endif
			
			If Not shader.u Then Continue
			
			If shader.shader_id<>last_shader
			
				glUseProgram(shader.shader_id)
				last_shader = shader.shader_id
			
				'Print shader.name+" "+(shader.MAX_LIGHTS)
								
			Endif
		
			'' Update additional uniforms for current shader
			'' needs to be after UseProgram()
			shader.Update()
			
			
			
			
		
			'' *** update buffers ***
			'' --------------------------------------
			If skip_sprite_state = False
			
					
			If DEBUG And GetGLError() Then Print "*pre vbos"
			
			
			If vbo
				
				Local bind:Bool=False
				
				If Not (mesh.anim_render Or surf.vbo_dyn)
					glEnableVertexAttribArray(shader.u.vertcoords)
					glBindBuffer(GL_ARRAY_BUFFER,surf.vbo_id[0])
					glVertexAttribPointer( shader.u.vertcoords, 3, GL_FLOAT, False, VertexDataBuffer.SIZE, VertexDataBuffer.POS_OFFSET )
					bind=True
				Endif

				If shader.u.normals<>-1
					glEnableVertexAttribArray(shader.u.normals)					
					If Not bind Then glBindBuffer(GL_ARRAY_BUFFER,surf.vbo_id[0]) 'normals
					glVertexAttribPointer( shader.u.normals, 3, GL_FLOAT, False, VertexDataBuffer.SIZE, VertexDataBuffer.NORMAL_OFFSET )
					bind=True
				Endif
			
				If(shader.u.colors<>-1 ) '' ** causes problems on FireFox if we do not send color info
					glEnableVertexAttribArray(shader.u.colors)
					If Not bind Then glBindBuffer(GL_ARRAY_BUFFER,surf.vbo_id[0]) 'color
					glVertexAttribPointer( shader.u.colors, 4, GL_FLOAT, False, VertexDataBuffer.SIZE, VertexDataBuffer.COLOR_OFFSET )
					bind=True
				Endif

				glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,surf.vbo_id[5]) 'tris
				
			Else
				'' ONLY FOR ANDROID API 8
				
				glBindBuffer(GL_ARRAY_BUFFER,0) ' reset - necessary for when non-vbo surf follows vbo surf
				glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,0)
				
				Print "*** Non-VBO disabled"
#rem				
				glEnableVertexAttribArray(shader.vertcoords)
				
				If mesh.anim_render
					glBindBuffer(GL_ARRAY_BUFFER,anim_surf2.vbo_id[0])
					'glVertexPointer(3,GL_FLOAT,0,0)
					glVertexAttribPointer( shader.vertcoords, 3, GL_FLOAT, False, VertexDataBuffer.SIZE, anim_surf2.vert_data.buf )
				Else
					glBindBuffer(GL_ARRAY_BUFFER,surf.vbo_id[0])
					'glVertexPointer(3,GL_FLOAT,0,0)
					glVertexAttribPointer( shader.vertcoords, 3, GL_FLOAT, False, VertexDataBuffer.SIZE, surf.vert_data.buf )
				Endif
				
				If shader.normals<>-1
					glEnableVertexAttribArray(shader.normals)					
					glBindBuffer(GL_ARRAY_BUFFER,surf.vbo_id[0]) 'normals
					glVertexAttribPointer( shader.normals, 3, GL_FLOAT, False, VertexDataBuffer.SIZE, surf.vert_data.buf  )
				Endif
			
				If(shader.colors<>-1 ) '' ** causes problems on FireFox if we do not send color info
					glEnableVertexAttribArray(shader.colors)
					glBindBuffer(GL_ARRAY_BUFFER,surf.vbo_id[0]) 'color
					glVertexAttribPointer( shader.colors, 4, GL_FLOAT, False, VertexDataBuffer.SIZE, surf.vert_data.buf  )
				Endif
				
				glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,surf.vbo_id[5]) 'tris
				
#end
			
			Endif
			
			
			Endif ''end sprite_skip_state--------------------------------------
			
			
			''mesh animation/batch animation
			'' ANDROID API 8 --doesn't work without VBO
			If (mesh.anim_render Or surf.vbo_dyn Or anim_surf2)
				
				glEnableVertexAttribArray(shader.u.vertcoords)
				''vertex animation
				If anim_surf2 And anim_surf2.vert_anim
				
					glBindBuffer(GL_ARRAY_BUFFER,anim_surf2.vbo_id[4])
					glVertexAttribPointer( shader.u.vertcoords, 3, GL_FLOAT, False, 12,0 )
				
				'' mesh animation, using animsurf2
				Elseif mesh.anim_render And anim_surf2
					glBindBuffer(GL_ARRAY_BUFFER,anim_surf2.vbo_id[0])
					glVertexAttribPointer( shader.u.vertcoords, 3, GL_FLOAT, False, VertexDataBuffer.SIZE, VertexDataBuffer.POS_OFFSET )
				
				'' dynamic mesh, usually batch sprites
				Elseif surf.vbo_dyn
					glBindBuffer(GL_ARRAY_BUFFER,surf.vbo_id[0])
					glVertexAttribPointer( shader.u.vertcoords, 3, GL_FLOAT, False, VertexDataBuffer.SIZE, VertexDataBuffer.POS_OFFSET )
				
				Endif
							
			Endif
					
			If DEBUG And GetGLError() Then Print "*vbos"					
					
			
			
			'' *** set GL effects ***
			''
			
			If shader.u.flags<>-1 Then glUniform1f( shader.u.flags, effect.fx  )
			
			If effect.use_vertex_colors<0 Then effect.use_vertex_colors=0
			If shader.u.colorflag<>-1 Then glUniform1f( shader.u.colorflag, Float(effect.use_vertex_colors) )
			
			If effect.use_full_bright<0 Then effect.use_full_bright=0
			If shader.u.lightflag<>-1 Then glUniform1f( shader.u.lightflag, Float(1.0-effect.use_full_bright) )

			If shader.u.ambient_color<>-1 Then glUniform4fv( shader.u.ambient_color, 1, effect.ambient ) ''ambient = 0 to provide fading
			If shader.u.base_color<>-1 Then glUniform4fv( shader.u.base_color, 1, effect.diffuse )
			If shader.u.shininess<>-1 Then glUniform1f( shader.u.shininess, effect.shine )
			
			If Not skip_sprite_state
				
				If effect.use_flatshade
					'glShadeModel(GL_FLAT)
				Else
					'glShadeModel(GL_SMOOTH)
				Endif
	
				If effect.use_backface_culling <> last_effect.use_backface_culling
					If effect.use_backface_culling =0
						glDisable(GL_CULL_FACE)
					Else
						glEnable(GL_CULL_FACE)
					Endif
				endif
				
	
				
				' blend modes
				If effect.blend>-1
					Select effect.blend
						Case 0
							'glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA) ' alpha
		   					glBlendFuncSeparate(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, GL_ONE, GL_ONE_MINUS_SRC_ALPHA) ' premultiply				
						Case 1
							glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA) ' alpha
						Case 2
							glBlendFunc(GL_DST_COLOR,GL_ZERO) ' multiply
						Case 3
							glBlendFunc(GL_SRC_ALPHA,GL_ONE) ' additive and alpha
						Case 4
							glBlendFunc(GL_ONE,GL_ONE) ' blend after texture
		
					End Select
				Endif
				
				If effect.blend<>last_effect.blend
					If effect.blend>-1 Then glEnable(GL_BLEND) Else glDisable(GL_BLEND)
				Endif
			
				If effect.use_depth_test<>last_effect.use_depth_test
					If effect.use_depth_test=0 Then glDisable(GL_DEPTH_TEST) Else glEnable(GL_DEPTH_TEST)

				Endif
				If effect.use_depth_write<>last_effect.use_depth_write
					If effect.use_depth_write=0 Then glDepthMask(False) Else glDepthMask(True)

				Endif
				If effect.use_alpha_test>0
					If shader.u.alphaflag<>-1 Then glUniform1f( shader.u.alphaflag, 0.5 )		
				Else
					If shader.u.alphaflag<>-1 Then glUniform1f( shader.u.alphaflag, 0.0 )
				Endif
				
				
				
				''shader light info, for all lights
				For Local li:Int = 0 To shader.MAX_LIGHTS-1
					If light[li]
						If shader.u.light_type[li]<>-1 Then glUniform1f( shader.u.light_type[li], light[li].light_type )
						light[li].mat.ToArray(t_array)
						If shader.u.light_matrix[li]<>-1 Then glUniformMatrix4fv( shader.u.light_matrix[li], 1, False, t_array  )
						If shader.u.light_att[li]<>-1 Then glUniform4fv( shader.u.light_att[li], 1,[ light[li].const_att,light[li].lin_att,light[li].quad_att,light[li].actual_range ]  )
						If shader.u.light_color[li]<>-1 Then glUniform4fv( shader.u.light_color[li], 1,[ light[li].red, light[li].green, light[li].blue, 1.0 ]  )
						If shader.u.light_spot[li]<>-1 Then glUniform3fv( shader.u.light_spot[li], 1,[ Cos(light[li].outer_ang), Cos(light[li].inner_ang), light[li].spot_exp ]  )
					Else
						''nullify other lights
						If shader.u.light_type[li]<>-1 Then glUniform1f( shader.u.light_type[li], 0.0 )
						If shader.u.light_color[li]<>-1 Then glUniform4fv( shader.u.light_color[li], 1,[ 0.0, 0.0, 0.0, 1.0 ]  )
					Endif	
				Next
				
				
					
				If cam.fog_mode >0 And effect.use_fog
					If shader.u.fogflag<> -1 Then glUniform1i( shader.u.fogflag, cam.fog_mode )
					If shader.u.fog_color<> -1 Then glUniform4fv( shader.u.fog_color, 1, [cam.fog_r,cam.fog_g,cam.fog_b,1.0])
					If shader.u.fog_range<> -1 Then glUniform2fv( shader.u.fog_range, 1, [cam.fog_range_near,cam.fog_range_far])
				Else
					If shader.u.fogflag<> -1 Then glUniform1i( shader.u.fogflag, 0 )
				Endif
				
				
				''If DEBUG And GetGLError() Then Print "*effects"
				
			Endif ''end skip state---
			


			' ***** textures *****
			
			'Local tex_count:Int =ent.brush.no_texs
			
			'If surf.brush<>Null
				If surf.brush.no_texs>tex_count Then tex_count=surf.brush.no_texs
			'EndIf

			If tex_count > shader.MAX_TEXTURES-1 Then tex_count = shader.MAX_TEXTURES-1
			
			'' -- we are always sending over a texture in opengl2.0 basic shader
			If tex_count<>0 And (last_tex_count=0 Or last_tex_count=-1)
				'glEnable(GL_TEXTURE_2D)
			Elseif tex_count=0 And (last_tex_count>0 Or last_tex_count=-1)
				'glDisable(GL_TEXTURE_2D)
			Endif
			
			
			''disable any extra textures from last pass
			If tex_count < last_tex_count 
				For Local i:Int = tex_count To shader.MAX_TEXTURES-1
					glActiveTexture(GL_TEXTURE0+i)
					glBindTexture(GL_TEXTURE_2D, 0)
				Next
			Endif
	
	

			For Local ix=0 To tex_count-1			
				
				Local texture:TTexture,tex_flags,tex_blend,tex_coords,tex_u_scale#,tex_v_scale#
				Local tex_u_pos#,tex_v_pos#,tex_ang#,tex_cube_mode,frame, tex_smooth
				
				If surf.brush.tex[ix]<>Null Or ent.brush.tex[ix]<>Null

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
					''if two texture layers use the same texture, don't skip (checking ix=0 first texture layer)
					'If ((surf.brush.tex[ix] And last_texture = surf.brush.tex[ix]) Or
					 '   (ent.brush.tex[ix] And last_texture = ent.brush.tex[ix])) And ix=0
					If (texture = last_texture) And ix=0
						
						'' skip texture Bind
			
					Else
						'' do texture bind
					
						'If surf.brush.tex[ix] Then last_texture = surf.brush.tex[ix] Else last_texture = ent.brush.tex[ix]
						last_texture = texture
						
						glActiveTexture(GL_TEXTURE0+ix)
						'glClientActiveTexture(GL_TEXTURE0+ix)				
						glBindTexture(GL_TEXTURE_2D,texture.gltex[0]) ' call before glTexParameteri
				
						If shader.u.texture[ix] <>-1 Then glUniform1i(shader.u.texture[ix], ix)
					
					Endif ''end preserve texture states---------------------------------

					
					
					''assuming sprites with same surfaces are identical, preserve states---------
					If (Not skip_sprite_state) And texture.width <>0
					
					
					' 
					If tex_flags&2<>0
						'If shader.u.base_color<>-1 Then glUniform4fv( shader.u.base_color, 1, [1.0,1.0,1.0,1.0] )			
					Else
						'
					Endif
					
					''mask texture with color (0,0,0)
					If tex_flags&4<>0
									
					Else
						
					Endif
				
					' mipmapping texture flag
					If tex_flags&8<>0
						If tex_smooth
							glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR)
							glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR)
						Else
							glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST)
							glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST)
						Endif
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
			

					
					If shader.u.texcoords0<>-1 Then glEnableVertexAttribArray(shader.u.texcoords0)
					If shader.u.texcoords1<>-1 Then glEnableVertexAttribArray(shader.u.texcoords1)
					
					If vbo
						If tex_coords=0 And shader.u.texcoords0<>-1
							glBindBuffer(GL_ARRAY_BUFFER,surf.vbo_id[0])
							'glTexCoordPointer(2,GL_FLOAT,0,0)
							glVertexAttribPointer( shader.u.texcoords0, 2, GL_FLOAT, False, VertexDataBuffer.SIZE, VertexDataBuffer.TEXCOORDS_OFFSET )
						Elseif shader.u.texcoords1<>-1
							glBindBuffer(GL_ARRAY_BUFFER,surf.vbo_id[0])
							'glTexCoordPointer(2,GL_FLOAT,0,0)
							glVertexAttribPointer( shader.u.texcoords1, 2, GL_FLOAT, False, VertexDataBuffer.SIZE, VertexDataBuffer.TEXCOORDS_OFFSET )
						Endif
					Else
						''for android api 8
#rem
						If tex_coords=0 And shader.texcoords0<>-1
							glBindBuffer(GL_ARRAY_BUFFER,surf.vbo_id[0])
							'glTexCoordPointer(2,GL_FLOAT,0,0)
							glVertexAttribPointer( shader.texcoords0, 2, GL_FLOAT, False, VertexDataBuffer.SIZE, surf.vert_data.buf )
						Elseif shader.texcoords1<>-1
							glBindBuffer(GL_ARRAY_BUFFER,surf.vbo_id[0])
							'glTexCoordPointer(2,GL_FLOAT,0,0)
							glVertexAttribPointer( shader.texcoords1, 2, GL_FLOAT, False, VertexDataBuffer.SIZE, surf.vert_data.buf )
						Endif
#end
					Endif

			
					Endif ''end preserve skip_sprite_state-------------------------------
			
					
					
					'' reset texture matrix
					'' always bring in values, for animation
					If shader.u.tex_position[ix] <>-1 Then glUniform2f(shader.u.tex_position[ix], tex_u_pos,tex_v_pos)
					If shader.u.tex_rotation[ix] <>-1 Then glUniform2f(shader.u.tex_rotation[ix], Cos(tex_ang), Sin(tex_ang)) '' *DEGREESTORAD,tex_ang*DEGREESTORAD); 					
					If shader.u.tex_scale[ix] <>-1 Then glUniform2f(shader.u.tex_scale[ix], tex_u_scale, tex_v_scale)
					If shader.u.tex_blend[ix] <>-1 Then glUniform2f(shader.u.tex_blend[ix], tex_blend, tex_blend)
					If shader.u.texfx_normal[ix] <>-1 Then glUniform1i(shader.u.texfx_normal[ix], (tex_flags & 1024))
			
					If DEBUG And GetGLError() Then Print "*tex"					
			
					
				Endif ''end if tex[ix]
			
			Next 'end texture loop
			
			
			
			'' turn off textures if no textures
			If tex_count = 0
				
				last_texture = Null
				
				'glDisable(GL_TEXTURE_2D)
				
				glActiveTexture(GL_TEXTURE0)
				'glBindTexture(GL_TEXTURE_2D, 0)			
				If shader.u.texcoords0 <>-1 Then glDisableVertexAttribArray(shader.u.texcoords0)
				If shader.u.texcoords1 <>-1 Then glDisableVertexAttribArray(shader.u.texcoords1)
				
				'fx = fx|2 ''turn on vertex colors if no texture ''--no, users need to select this
				
			Endif

			last_tex_count = tex_count
			
			'' turn on textures
			If shader.u.texflag<>-1 Then glUniform1f( shader.u.texflag, Float(tex_count)  )
			
			If DEBUG And GetGLError() Then Print "*tex2"			
			
			
			
			
			
			''matrices
			
			If mesh.is_sprite=False
				mesh.mat.ToArray(t_array)
				If shader.u.m_matrix <>-1 Then glUniformMatrix4fv( shader.u.m_matrix, 1, False, t_array )
				'vp_matrix.Multiply4(mesh.mat)
			Else
				TSprite(mesh).mat_sp.ToArray(t_array)
				If shader.u.m_matrix <>-1 Then glUniformMatrix4fv( shader.u.m_matrix, 1, False, t_array )
				'vp_matrix.Multiply4(TSprite(mesh).mat_sp)
			Endif
		

			''camera matrices
			''view matrix
			If shader.u.v_matrix<>-1 glUniformMatrix4fv( shader.u.v_matrix, 1, False, vmat_array )
			
			''projection-view matrix
			If shader.u.p_matrix<>-1 glUniformMatrix4fv( shader.u.p_matrix, 1, False, pvmat_array )
			
			''inverse global scale
			If shader.u.scaleInv<>-1 Then glUniform3fv( shader.u.scaleInv, 1, [1.0/mesh.gsx,1.0/mesh.gsy,1.0/mesh.gsz] )
			
			If DEBUG And GetGLError() Then Print "*mats flags"
			
			

			'' draw tris

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

			'glPopMatrix()

			If DEBUG And GetGLError() Then Print "*glDrawElements"		

	
			'' *** cleanup ***
			
			last_effect.Overwrite(effect)
			

		Next ''end non-alpha loop
		
		'If cam.draw2D
			'glEnable(GL_DEPTH_TEST)
			'effect.use_depth_test = 0
		'Endif

		If Not alpha_list Then Exit ''get out of loop, no alpha
		temp_list = alpha_list
		
		Next	''end alpha loop
		
		temp_list = Null
		
		
		'glBindBuffer( GL_ARRAY_BUFFER, 0 ) '' releases buffer for return to mojo buffer??? may not need
		'glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,0)

		ClearErrors()
	
	End
	
	
	Method GraphicsInit:Int(flags:Int=0)
		
		Local version:Int = GetVersion()
		
		If version >0.0 Then Print "**OPENGL "+version Else Print "**WEBGL "+(-version)
		
		''negative values are webgl 1.0, which are == opengles2.0
		If version <1.999 And version >0.0 Then Error("Requires OpenGL 2.0 or higher")
		
		
		
		''get the TPixmapManager set
		TPixmapGL.Init()
		
		FrameBufferGL.supportFBO = 1 ''***TODO: test for support, but should be available
		
		
		
		TTexture.TextureFilter("",8+1) ''default texture settings: mipmap

		' get hardware info and set vbo_enabled accordingly
		'THardwareInfo.GetInfo()
		'THardwareInfo.DisplayInfo()
		
		width = DeviceWidth()
		height = DeviceHeight()
		
		If Not (flags & RENDERFLAG_DISABLEVBO)
			vbo_enabled=True 'THardwareInfo.VBOSupport
		Endif
		
		_usePerPixelLighting = ((flags & RENDERFLAG_PERPIXELLIGHTING) > 0)
		
		
		EnableStates()
		
		'glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST) ''TODO???????????????????????????????????

		'glAlphaFunc(GL_GEQUAL,0.5)
		
		TEntity.global_mat.LoadIdentity()
		
		ClearErrors()
		
		''---load default shader here----

		TShader.LoadDefaultShader(New FullShader)	

		
		
		If glGetError()<>GL_NO_ERROR Then Return 0
		
		Return 1
		

	End 
	
	Method EnableHardwareInfo:Int()
		
		''set MAX_TEXTURES
		Local data:Int[2]
		glGetIntegerv(GL_MAX_TEXTURE_UNITS, data)
		MAX_TEXTURES = data[0]-1
		If DEBUG Then Print "..max textures:"+MAX_TEXTURES+1
		
		Local res:Int[1]
		glGetIntegerv(GL_SHADER_COMPILER, res)
		If res[0]=GL_FALSE Then Print "**No GLSL Compiler "+Int(res[0])
		
		Return 1
	End
	
	
	Method EnableStates:Void()
		
		'glEnable(GL_LIGHTING)
   		glEnable(GL_DEPTH_TEST)
   		glDepthMask(True)
		glClearDepthf(1.0)				
		glDepthFunc(GL_LEQUAL)
		'glEnable(GL_FOG)
		glEnable(GL_CULL_FACE)
		glEnable(GL_SCISSOR_TEST)
		glEnable(GL_BLEND)
		
		'glEnable(GL_RESCALE_NORMAL) '(GL_NORMALIZE) ' 'normal-lighting problems? this may be it
	
	End 
	
	''eats up a lot of time on html5
	Function GetGLError:Int()
		If DEBUG
			Local gle:Int = glGetError()
			If gle<>GL_NO_ERROR
				total_errors +=1
				If total_errors>50 Then Error "Max 50 Opengl Errors" ''kill errors for HTML5 console
				Print "*glerror: "+gle
				Return 1
			Endif
		Endif
		Return 0
	End
	
	''eats up a lot of time on html5
	Method ClearErrors()
		If DEBUG
			Local e:Int=0
			While glGetError()<>GL_NO_ERROR
				e+=1
				If e>255 Then Exit
			Wend
		Endif
	End	
	
	
	Method UpdateVBO:Int(surf:TSurface)
	
		If surf.vbo_id[0]=0
			surf.vbo_id[0]=glCreateBuffer()
			surf.vbo_id[1]=glCreateBuffer()
			surf.vbo_id[2]=glCreateBuffer()
			surf.vbo_id[3]=glCreateBuffer()
			surf.vbo_id[4]=glCreateBuffer()
			surf.vbo_id[5]=glCreateBuffer()
		Endif
		


		If surf.reset_vbo=-1 Then surf.reset_vbo=255
	
		
		If surf.reset_vbo&1 Or surf.reset_vbo&2 Or surf.reset_vbo&4 Or surf.reset_vbo&8
			
			
			If surf.vbo_dyn And (Not surf.vert_anim)
			
				glBindBuffer(GL_ARRAY_BUFFER,surf.vbo_id[0])
				If surf.reset_vbo <> 255
					glBufferSubData(GL_ARRAY_BUFFER,0,surf.no_verts*VertexDataBuffer.SIZE ,surf.vert_data.buf)
				Else
					glBufferData(GL_ARRAY_BUFFER,surf.no_verts*VertexDataBuffer.SIZE ,surf.vert_data.buf,GL_DYNAMIC_DRAW)
				Endif
				
			Elseif surf.vbo_dyn And surf.vert_anim And surf.reset_vbo&1
				
				glBindBuffer(GL_ARRAY_BUFFER,surf.vbo_id[4])
				If surf.reset_vbo <> 255
					''update just anim data
					glBufferSubData(GL_ARRAY_BUFFER,0,surf.no_verts*12 ,surf.vert_anim[surf.anim_frame].buf )
				Else
					'glBindBuffer(GL_ARRAY_BUFFER,surf.vbo_id[0])
					'glBufferData(GL_ARRAY_BUFFER,surf.no_verts*VertexDataBuffer.SIZE ,surf.vert_data.buf,GL_DYNAMIC_DRAW)
					'glBindBuffer(GL_ARRAY_BUFFER,surf.vbo_id[4])
					glBufferData(GL_ARRAY_BUFFER,surf.no_verts*12 ,surf.vert_anim[surf.anim_frame].buf,GL_DYNAMIC_DRAW)
				Endif
				
			Else
				glBindBuffer(GL_ARRAY_BUFFER,surf.vbo_id[0])
				glBufferData(GL_ARRAY_BUFFER,surf.no_verts*VertexDataBuffer.SIZE ,surf.vert_data.buf,GL_STATIC_DRAW)
			Endif
			
		Endif
		
		If surf.reset_vbo&16
			glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,surf.vbo_id[5])
			If surf.reset_vbo <> 255
				glBufferSubData(GL_ELEMENT_ARRAY_BUFFER,0,surf.no_tris*6,surf.tris.buf)
			Else
				glBufferData(GL_ELEMENT_ARRAY_BUFFER,surf.no_tris*6,surf.tris.buf,GL_STATIC_DRAW)
			Endif
			
		Endif
		
		If GetGLError() Then Print "vbo error"
		
		surf.reset_vbo=False
		
	End
	
	
	Method FreeVBO(surf:TSurface)
	
		If surf.vbo_id[0]<>0 
			glDeleteBuffer(surf.vbo_id[0])
			glDeleteBuffer(surf.vbo_id[1])
			glDeleteBuffer(surf.vbo_id[2])
			glDeleteBuffer(surf.vbo_id[3])
			glDeleteBuffer(surf.vbo_id[4])
			glDeleteBuffer(surf.vbo_id[5])
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
	
	
	''-- TTexture specific --
	
	Method DeleteTexture(tex:TTexture)
		
		If tex.gltex[0] Then glDeleteTexture(tex.gltex[0])
		tex.gltex[0] =0
		
	End
	
	Method BindTexture:TTexture(tex:TTexture,flags:Int)
		''
		'' --PIXMAP MUST BE POWER OF TWO
		''
		
		TRender.render.ClearErrors()	
		
		' if mask flag is true, mask pixmap
		If flags&4
			tex.pixmap.MaskPixmap(0,0,0)
		Endif

		
		' pixmap -> tex

		Local width=tex.pixmap.width
		Local height=tex.pixmap.height
	
		If width=0 Or height=0 Then Return tex
		
		If Not tex.gltex[0]
			tex.gltex[0] = glCreateTexture()
		Elseif tex.pixmap.bind
			Return tex
		Endif
	
		glBindTexture GL_TEXTURE_2D,tex.gltex[0]


		' set flags for empty textures
		If flags&8<>0
			glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR)
			glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR) ''GL_LINEAR_MIPMAP_NEAREST
		Else
			glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST) 
			glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST)

		Endif
		
		' clamp u flag
		If flags&16<>0
			glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_CLAMP_TO_EDGE)
		Else						
			glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_REPEAT)
		Endif
		
		' clamp v flag
		If flags&32<>0
			glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_CLAMP_TO_EDGE)
		Else
			glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_REPEAT)
		Endif
		
		
		Local mipmap:Int= 0, mip_level:Int=0
		If flags&8 Then mipmap=True
	
		Local pix:TPixmapGL = TPixmapGL(tex.pixmap)
		
			Repeat
				glPixelStorei GL_UNPACK_ALIGNMENT,1
#If TARGET<>"html5"
				glTexImage2D (GL_TEXTURE_2D,mip_level,GL_RGBA,width,height,0,GL_RGBA,GL_UNSIGNED_BYTE,pix.pixels)
#Else
				glTexImage2D3 (GL_TEXTURE_2D, mip_level, GL_RGBA, GL_RGBA, GL_UNSIGNED_BYTE, pix.pixels)
#Endif

				Local err:Int = glGetError()
				If( err<>GL_NO_ERROR )
					Error "** out of texture memory ** "+err
				Endif
				
				If Not mipmap Or (width=1 Or height =1) Then Exit
				If width>1 width *= 0.5
				If height>1 height *= 0.5

				''please note the resulting pixmap is 1x1, thus removing image from memory
				If tex.resize_smooth
					pix=TPixmapGL(pix.ResizePixmap(width,height))
				Else
					pix=TPixmapGL(pix.ResizePixmapNoSmooth(width,height))
				Endif
				
				mip_level+=1
				
			Forever
			
		tex.no_mipmaps=mip_level
		tex.pixmap.SetBind()
		
		Return tex
		
	End	
	
	''overloading for framebuffers...
	Method BindTextureStack()
		
		Super.BindTextureStack()
		
		For Local fbo:FrameBuffer = Eachin FrameBufferGL.fboStack
			FrameBufferGL.BindFBO(FrameBufferGL(fbo))
		Next
		
		FrameBufferGL.fboStack.Clear()
		
	End
	
	Method UpdateLight(cam:TCamera, light:TLight)
		
		
		
	End
	
	Method DisableLight(light:TLight)
	
	End
	
	
	Method UpdateCamera(cam:TCamera)
		
		'' set viewport for FBO cropping
		If FrameBufferGL.framebuffer_active And FrameBufferGL.framebuffer_active.texture.width >0
		
			Local fw:Float = FrameBufferGL.framebuffer_active.texture.width
			Local fh:Float = FrameBufferGL.framebuffer_active.texture.height
			
			Local scalew:Float = 1.0, scaleh:Float = 1.0
			
			'If cam.vwidth>cam.vheight Then scaleh= Float(cam.vheight)/cam.vwidth Else scalew= Float(cam.vwidth)/cam.vheight
			If cam.vwidth>cam.vheight Then scaleh= FrameBufferGL.framebuffer_active.UVH Else scalew= FrameBufferGL.framebuffer_active.UVW
			
'Print fw+" "+fh+" :: "+cam.vwidth+" "+cam.vheight
			
			If fw<cam.vwidth Or fh<cam.vheight

				glViewport(cam.vx,cam.vy,fw*scalew,fh*scaleh)
				glScissor(cam.vx,cam.vy,fw*scalew,fh*scaleh)

			Else

				glViewport(cam.vx,cam.vy,cam.vwidth,cam.vheight)
				glScissor(cam.vx,cam.vy,cam.vwidth,cam.vheight)
			
			Endif
			
		Else
		
			' viewport
	        If cam.draw2D
	            glViewport(0,0,DeviceWidth, DeviceHeight)
	        Else
	            glViewport(cam.vx,cam.vy,cam.vwidth,cam.vheight)
	        End 
	
	        '' must be turned on again somewhere 
	        glEnable(GL_SCISSOR_TEST)
			'glViewport(cam.vx,cam.vy,cam.vwidth,cam.vheight)
			glScissor(cam.viewport[0],cam.viewport[1],cam.viewport[2],cam.viewport[3])	
	
		Endif
		
		glClearColor(cam.cls_r,cam.cls_g,cam.cls_b,1.0)

		' clear buffers
		If cam.cls_color=True And cam.cls_zbuffer=True
			glDepthMask(True)
			glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT)
		Else
			If cam.cls_color=True
				glClear(GL_COLOR_BUFFER_BIT)
			Else
				If cam.cls_zbuffer=True
					glDepthMask(True)
					glClear(GL_DEPTH_BUFFER_BIT)
				Endif
			Endif
		Endif
		
		'v_matrix.Overwrite(cam.mod_mat) '' inverse is called in cam.Update()
		vmat_array = cam.mod_mat.ToArray() '' inverse is called in cam.Update()
		
		'pmat.Overwrite(cam.proj_mat ) 'Copy()
		'pmat.Multiply4(cam.mod_mat)
		pvmat_array = cam.projview_mat.ToArray()

		
		
		'glUniformMatrix4fv( g_shader.vp_matrix, 1, False, pmat.ToArray() )
		
		If DEBUG And GetGLError() Then Print "*cam err"
		
	End
	
	
	Method BackBufferToTex(mipmap_no=0,frame=0)
		
		''***TODO*** switch to fbo
		If flags&128=0 ' normal texture
	
			Local x=0,y=0
	
			glBindtexture GL_TEXTURE_2D,gltex[frame]
			glCopyTexImage2D(GL_TEXTURE_2D,mipmap_no,GL_RGBA,x,TRender.height-y-height,width,height,0)
			
		Else 

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
	

	''Interface
	Method SetShader2D:Void()

		TShader.SetShader(New FastBrightShader)
		
	End

	
End







''
''helper classes
''

Class RenderAlphaList Extends List<TMesh>
	
	''draw furthest (highest alpha_order) first, so sort from great to least
	Method Compare( left:TMesh,right:TMesh )
		If left.alpha_order > right.alpha_order Return -1 ''double check, i flipped these
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

