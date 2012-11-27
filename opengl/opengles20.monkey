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
'Const MAX_TEXTURES = 4 ''set by shader
'Const MAX_LIGHTS = 3 ''set by shader

Function SetRender(flags:Int=0)

	TRender.render = New OpenglES20
	TRender.render.GraphicsInit(flags)
	
End


Class OpenglES20 Extends TRender
	
	Const DEBUG:Int = TRender.DEBUG
	
	'Global g_shader:TShaderGLSL ''default shader
	
	''used for optimizing the fixed-pipeline render routine
	
	Global alpha_list:SurfaceAlphaList = New SurfaceAlphaList  ''used to draw and sort alpha surfaces last
	'Global alpha_anim_list:SurfaceAlphaList = New SurfaceAlphaList  ''no need-- connected anim_surf t surf

	Global last_texture:TTexture ''used to preserve texture states
	Global last_surf:TSurface ''used to batch sprite state switching
	Global last_shader:Int
	Global last_tex_count:Int =8
	
	Global disable_depth:Bool = False '' used for EntityFx 64 - disable depth testing
	
	Field cam_matrix_upload:Int=0
	
	Field light:TLight[] = New TLight[8]
	Field pmat:Matrix = New Matrix
	Field pvmat_array:Float[16], vmat_array:Float[16]
	Field vp_matrix:Matrix = New Matrix
	Field v_matrix:Matrix = New Matrix
	Field fog_flag:Int
	
	Field t_array:Float[] = New Float[16] 'temp array
	
	Global total_errors:Int=0
	
	Const DEGREESTORAD:Float = PI/180.0
	
	Method New()
		
	End
	

	
	'' returns negative value for WebGL version
	Method GetVersion:Float()
		Local webgl:String, st:String
		
		If Not CheckWebGL Then Error "** WebGL not found. Please upgrade or check browser options. ~n~n"
		If Not CheckWebGLContext Then Error "** WebGL Context not found. Please upgrade or check browser options. ~n~n"
		
		Local s:String = glGetString(GL_VERSION)
Print s	
	
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
		
		ResetLights()
		
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
		
		If Not shader.u Then Return
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
			glDisable(GL_DEPTH_TEST)
		Endif
		
		''run through surfaces twice, sort alpha surfaces for second pass
		For Local alphaloop:= alpha_pass To 1 ''if alpha_pass is on, no need to reorder alpha surfs
		
		For surf = Eachin temp_list

			'If GetGLError() Then Print "*render start"

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
		

			''enable shader and check for last_state
			
'Print " shader:"+shader.name				
			
			''SHADER ACTIVATION---------------------------------
			If shader.shader_id<>last_shader
			
				glUseProgram(shader.shader_id)
				last_shader = shader.shader_id
			
				'Print shader.name+" "+(shader.MAX_LIGHTS)
								
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
				
				
					
				If cam.fog_mode >0
					If shader.u.fogflag<> -1 Then glUniform1i( shader.u.fogflag, cam.fog_mode )
					If shader.u.fog_color<> -1 Then glUniform4fv( shader.u.fog_color, 1, [cam.fog_r,cam.fog_g,cam.fog_b,1.0])
					If shader.u.fog_range<> -1 Then glUniform2fv( shader.u.fog_range, 1, [cam.fog_range_near,cam.fog_range_far])
				Endif
				
			Endif
		
			'' Update additional uniforms for current shader
			'' needs to be after UseProgram()
			shader.Update()
			
			
			Local red#,green#,blue#,alpha#,shine#,blend:Int,fx:Int
			Local ambient_red#,ambient_green#,ambient_blue#
			Local shine_strength#

			' get main brush values
			red  =ent.brush.red
			green=ent.brush.green
			blue =ent.brush.blue
			alpha=ent.brush.alpha
			shine=ent.brush.shine
			blend =ent.brush.blend
			fx    =ent.brush.fx
			shine_strength = ent.brush.shine_strength
			
			' combine surface brush values with main brush values
			If surf.brush

				Local shine2#=0.0

				red   =red  *surf.brush.red
				green =green*surf.brush.green
				blue  =blue *surf.brush.blue
				alpha =alpha *surf.brush.alpha
				shine2=surf.brush.shine
				shine_strength = surf.brush.shine_strength
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

			
			' material
			
			' fx flag 1 - full bright 
			If fx&1
				ambient_red  =0.0
				ambient_green=0.0
				ambient_blue =0.0
				
				lightflag=0 ''disable lights
				
			Else
				ambient_red  =TLight.ambient_red
				ambient_green=TLight.ambient_green
				ambient_blue =TLight.ambient_blue
			Endif
			
			If cam.draw2D
				lightflag=0
				ambient_red  =0.0
				ambient_green=0.0
				ambient_blue =0.0
				If shader.u.fogflag<> -1 Then glUniform1i( shader.u.fogflag, 0 )
			Endif

			'Local ambient#[]=[ambient_red,ambient_green,ambient_blue,1.0]	
			Local no_mat#[]=[0.0,0.0,0.0,0.0]
			Local mat_diffuse#[]=[red,green,blue,alpha]
			Local mat_shininess#[]=[100.0] ' upto 128
			
			
			'' --------------------------------------
			If skip_sprite_state = False


			' fx flag 2 - vertex colors ***todo*** disable all lights?
			If fx&2
				'glEnable(GL_COLOR_MATERIAL)
				red=1.0; green=1.0; blue=1.0; alpha=1.0
			Else
				'glDisable(GL_COLOR_MATERIAL)
			Endif
			
			' fx flag 4 - flatshaded
			If fx&4
				'glShadeModel(GL_FLAT)
			Else
				'glShadeModel(GL_SMOOTH)
			Endif

			' fx flag 8 - disable fog
			If fx&8
				'glDisable(GL_FOG)
				If shader.u.fogflag<> -1 Then glUniform1i( shader.u.fogflag, 0 )
			Endif

			
			' fx flag 16 - disable backface culling
			If fx&16
				glDisable(GL_CULL_FACE)
			Else
				glEnable(GL_CULL_FACE)
			Endif
			
			'' fx flag 32 - force alpha
			''
			
			'' fx flag 64 - disable depth testing (new 2012)
			If fx&64
			
				glDisable(GL_DEPTH_TEST)
				glDepthMask(False)
				disable_depth = True
				
			Elseif disable_depth = True
			
				glEnable(GL_DEPTH_TEST)
				glDepthMask(True)
				disable_depth = False
				
			Endif
			
					
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
			If vbo And (mesh.anim_render Or surf.vbo_dyn Or anim_surf2)
				
				glEnableVertexAttribArray(shader.u.vertcoords)
				''vertex animation
				If anim_surf2 And anim_surf2.vert_anim
				
					glBindBuffer(GL_ARRAY_BUFFER,anim_surf2.vbo_id[4])
					glVertexAttribPointer( shader.u.vertcoords, 3, GL_FLOAT, False, 12,0 )
				
				'' mesh animation, using animsurf2
				Elseif mesh.anim_render
					glBindBuffer(GL_ARRAY_BUFFER,anim_surf2.vbo_id[0])
					glVertexAttribPointer( shader.u.vertcoords, 3, GL_FLOAT, False, VertexDataBuffer.SIZE, VertexDataBuffer.POS_OFFSET )
				
				'' dynamic mesh, usually batch sprites
				Elseif surf.vbo_dyn
					glBindBuffer(GL_ARRAY_BUFFER,surf.vbo_id[0])
					glVertexAttribPointer( shader.u.vertcoords, 3, GL_FLOAT, False, VertexDataBuffer.SIZE, VertexDataBuffer.POS_OFFSET )
				
				Endif
							
			Endif
			
			If Not vbo And DEBUG Then Print "*no vbos"
					
			If DEBUG And GetGLError() Then Print "*vbos"					
					
			


			' ***** textures *****
			
			Local tex_count:Int =ent.brush.no_texs
			
			'If surf.brush<>Null
				If surf.brush.no_texs>tex_count Then tex_count=surf.brush.no_texs
			'EndIf

			
			''disable any extra textures from last pass
			If tex_count < last_tex_count 
				For Local i:Int = tex_count To shader.MAX_TEXTURES-1
				
					glActiveTexture(GL_TEXTURE0+i)
					glBindTexture(GL_TEXTURE_2D, 0)

				Next
			Endif
			last_tex_count = tex_count


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
					If ((surf.brush.tex[ix] And last_texture = surf.brush.tex[ix]) Or
					    (ent.brush.tex[ix] And last_texture = ent.brush.tex[ix]))
						
						'' skip texture Bind
						
					Else		
						'' do texture bind
					
						If ent.brush.tex[ix] Then last_texture = ent.brush.tex[ix] Else last_texture = surf.brush.tex[ix]
						
						glActiveTexture(GL_TEXTURE0+ix)
						'glClientActiveTexture(GL_TEXTURE0+ix)
				
						glBindTexture(GL_TEXTURE_2D,texture.gltex[0]) ' call before glTexParameteri
						
						If shader.u.texture[ix] <>-1 Then glUniform1i(shader.u.texture[ix], ix)
					
					Endif ''end preserve texture states---------------------------------

					'glEnable(GL_TEXTURE_2D)
					
					
					''assuming sprites with same surfaces are identical, preserve states---------
					If Not skip_sprite_state
					
					
					' masked texture flag
					If tex_flags&2<>0
						'If shader.base_color<>-1 Then glUniform4fv( shader.base_color, 1, [red,green,blue,0.0] )			
					Else
						'
					Endif
					
					''send alpha texture test to shader----------------TOODOOO? may not need
					If tex_flags&4<>0
						'glEnable(GL_ALPHA_TEST)			
					Else
						'glDisable(GL_ALPHA_TEST)
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
					

			#rem	
					' cubic environment map texture flag
					
					glDisable(GL_TEXTURE_CUBE_MAP)
						
			#end
			
			''send tex blend info to shader
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
			
					'glEnableClientState(GL_TEXTURE_COORD_ARRAY)
					
					'glUniform1i(shader.texture0, ix)
					
					
					
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
				If shader.u.texcoords0 <>-1 Then glDisableVertexAttribArray(shader.u.texcoords0)
				If shader.u.texcoords1 <>-1 Then glDisableVertexAttribArray(shader.u.texcoords1)
				
			Endif
			
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
			
			If shader.u.flags<>-1 Then glUniform1f( shader.u.flags, fx  )
			If shader.u.colorflag<>-1 Then glUniform1f( shader.u.colorflag, Float((fx Shr 1) &1) )
			If shader.u.lightflag<>-1 Then glUniform1f( shader.u.lightflag, Float(lightflag) )

			If shader.u.ambient_color<>-1 Then glUniform4fv( shader.u.ambient_color, 1, [ambient_red,ambient_green,ambient_blue,1.0] ) ''ambient = 0 to provide fading
			If shader.u.base_color<>-1 Then glUniform4fv( shader.u.base_color, 1, [red,green,blue,alpha] )
			If shader.u.shininess<>-1 Then glUniform1f( shader.u.shininess, shine )
			
			
			
			'' turn on textures
			'If tex_count > 0 Then tex_count = 1

			If shader.u.texflag<>-1 Then glUniform1f( shader.u.texflag, Float(tex_count)  )
			
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

	
			' enable fog again if fog was enabled at start of func
			'If fog=True
				'glEnable(GL_FOG)
			'Endif

		Next ''end non-alpha loop
		
		If cam.draw2D
			glEnable(GL_DEPTH_TEST)
		Endif

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
		
		Local res:Int[1]
		glGetIntegerv(GL_SHADER_COMPILER, res)
		If res[0]=GL_FALSE Then Print "**No GLSL Compiler "+Int(res[0])
		
		''get the TPixmapManager set
		TPixmapGL.Init()
		
		FrameBufferGL.supportFBO = 1 ''***TODO: test for support, but should be available
		
		
		
		TTexture.TextureFilter("",8+1) ''default texture settings: mipmap

		' get hardware info and set vbo_enabled accordingly
		'THardwareInfo.GetInfo()
		'THardwareInfo.DisplayInfo()
		
		width = DeviceWidth()
		height = DeviceHeight()
		
		If Not (flags & DISABLE_VBO)
			vbo_enabled=True 'THardwareInfo.VBOSupport
		Endif
		
		
		EnableStates()
		
		glEnable(GL_DEPTH_TEST)
		glDepthMask(True)
		glClearDepthf(1.0)				
		glDepthFunc(GL_LEQUAL)
		'glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST) ''TODO???????????????????????????????????

		'glAlphaFunc(GL_GEQUAL,0.5)
		
		TEntity.global_mat.LoadIdentity()
		
		ClearErrors()
		
		''---load default shader here----

		TShader.LoadDefaultShader(New FullShader)	

		
		
		If glGetError()<>GL_NO_ERROR Then Return 0
		
		Return 1
		

	End 
	
	Method EnableStates:Void()
		
		'glEnable(GL_LIGHTING)
   		glEnable(GL_DEPTH_TEST)
		'glEnable(GL_FOG)
		glEnable(GL_CULL_FACE)
		glEnable(GL_SCISSOR_TEST)
		
		'glEnable(GL_RESCALE_NORMAL) '(GL_NORMALIZE) ' 'normal-lighting problems? this may be it
	
	End 
	
	
	Function GetGLError:Int()
		Local gle:Int = glGetError()
		If gle<>GL_NO_ERROR
			total_errors +=1
			If total_errors>50 Then Error "Max 50 Opengl Errors" ''kill errors for HTML5 console
			Print "*glerror: "+gle
			Return 1
		Endif
		Return 0
	End
	
	Method ClearErrors()
		Local e:Int=0
		While glGetError()<>GL_NO_ERROR
			e+=1
			If e>255 Then Exit
		Wend
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
	
		#rem
		If surf.reset_vbo&1
			glBindBuffer(GL_ARRAY_BUFFER,surf.vbo_id[0])

			If surf.vbo_dyn =False
				glBufferData(GL_ARRAY_BUFFER,(surf.no_verts*12),surf.vert_coords.buf,GL_STATIC_DRAW) '3*4=12
			Else
				If surf.reset_vbo <> 255
					glBufferSubData(GL_ARRAY_BUFFER,0,(surf.no_verts*12),surf.vert_coords.buf)
				Else
					glBufferData(GL_ARRAY_BUFFER,(surf.no_verts*12),surf.vert_coords.buf,GL_DYNAMIC_DRAW)
				Endif
			Endif
		Endif
		'If GetGLError() Then Print "vertcoords"
		
		If surf.reset_vbo&2
			glBindBuffer(GL_ARRAY_BUFFER,surf.vbo_id[1])
			glBufferData(GL_ARRAY_BUFFER,(surf.no_verts*8),surf.vert_tex_coords0.buf,GL_STATIC_DRAW) '2*4=8
	
			glBindBuffer(GL_ARRAY_BUFFER,surf.vbo_id[2])
			glBufferData(GL_ARRAY_BUFFER,(surf.no_verts*8),surf.vert_tex_coords1.buf,GL_STATIC_DRAW)	
		Endif
		'If GetGLError() Then Print "verttexcords"
		
		If surf.reset_vbo&4
			glBindBuffer(GL_ARRAY_BUFFER,surf.vbo_id[3])
			glBufferData(GL_ARRAY_BUFFER,(surf.no_verts*12),surf.vert_norm.buf,GL_STATIC_DRAW) '3*4=12
		Endif
		
		'If GetGLError() Then Print "vertnorm"
		
		If surf.reset_vbo&8
			glBindBuffer(GL_ARRAY_BUFFER,surf.vbo_id[4])
			If surf.reset_vbo <> 255
				glBufferSubData(GL_ARRAY_BUFFER,0,(surf.no_verts*16),surf.vert_col.buf) '4*4=16
			Else
				glBufferData(GL_ARRAY_BUFFER,(surf.no_verts*16),surf.vert_col.buf,GL_STATIC_DRAW)
			Endif
			
		Endif
		
		'If GetGLError() Then Print "vertcol"	
		
		If surf.reset_vbo&16
			glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,surf.vbo_id[5])
			If surf.reset_vbo <> 255
				glBufferSubData(GL_ELEMENT_ARRAY_BUFFER,0,surf.no_tris*6,surf.tris.buf) '3*2=6
			Else
				glBufferData(GL_ELEMENT_ARRAY_BUFFER,surf.no_tris*6,surf.tris.buf,GL_STATIC_DRAW)
			Endif
			
		Endif
		#end
		
		If surf.reset_vbo&1 Or surf.reset_vbo&2 Or surf.reset_vbo&4 Or surf.reset_vbo&8
			
			
			If surf.vbo_dyn And Not surf.vert_anim
			
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
					glBufferSubData(GL_ARRAY_BUFFER,0,surf.no_verts*12 ,surf.vert_anim[surf.anim_frame].vert_buffer.buf )
				Else
					glBufferData(GL_ARRAY_BUFFER,surf.no_verts*VertexDataBuffer.SIZE ,surf.vert_data.buf,GL_DYNAMIC_DRAW)
					glBufferData(GL_ARRAY_BUFFER,surf.no_verts*12 ,surf.vert_anim[surf.anim_frame].vert_buffer.buf,GL_DYNAMIC_DRAW)
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
			glDeleteBuffers(surf.vbo_id[0])
			glDeleteBuffers(surf.vbo_id[1])
			glDeleteBuffers(surf.vbo_id[2])
			glDeleteBuffers(surf.vbo_id[3])
			glDeleteBuffers(surf.vbo_id[4])
			glDeleteBuffers(surf.vbo_id[5])
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
	
	Method DeleteTexture(glid:Int[])
		
		If glid[0] Then glDeleteTexture(glid[0])
		glid[0] =0
		
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
	
		If Not tex.gltex[0]
			tex.gltex[0] = glCreateTexture()
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
			glViewport(cam.vx,cam.vy,cam.vwidth,cam.vheight)
			glScissor(cam.vx,cam.vy,cam.vwidth,cam.vheight)	
	
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
	

	''Overloading
	Function SetDrawShader:Void()
		
		SetShader(New FastBrightShader)
		
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

