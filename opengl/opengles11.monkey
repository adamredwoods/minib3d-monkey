Import mojo
Import opengl.gles11
Import minib3d.trender
Import minib3d.opengl.tpixmapgl
Import minib3d


#If TARGET="xna"
	#Error "Need glfw, ios, android, or mingw target"
#Endif



#OPENGL_GLES20_ENABLED=False
#OPENGL_DEPTH_BUFFER_ENABLED=True
#MINIB3D_DRIVER="opengl11"
#Print "miniB3D "+MINIB3D_DRIVER

Const VBO_MIN_TRIS=1	' if USE_VBO=True and vbos are supported by hardware, then surface must also have this minimum no. of tris before vbo is used for surface (vbos work best with surfaces with high amount of tris)


'flags
Const DISABLE_MAX2D=1	' true to enable max2d/minib3d integration --not in use for now
Const DISABLE_VBO=2	' true to use vbos if supported by hardware
Const MAX_TEXTURES=8


Extern

''this is highly experimental-- won't work in opengl2.0, only in opengl1.1

#if TARGET = "glfw" Or TARGET = "mingw" Or TARGET = "ios"
	Function RestoreMojo2D() = "app->GraphicsDevice()->BeginRender();//"
#elseif TARGET = "android"
	Function RestoreMojo2D() = "MonkeyGame.app.GraphicsDevice().Flush(); MonkeyGame.app.GraphicsDevice().BeginRender( (GL10) null );//"
#end

Public



Function SetRender(flags:Int=0)

	TRender.render = New OpenglES11
	TRender.render.GraphicsInit(flags)
	
End	


Class OpenglES11 Extends TRender
	
	
	''used for optimizing the fixed-pipeline render routine
	
	Global alpha_list:SurfaceAlphaList = New SurfaceAlphaList  ''used to draw and sort alpha surfaces last
	'Global alpha_anim_list:SurfaceAlphaList = New SurfaceAlphaList  ''no need-- connected anim_surf t surf

	Global last_texture:TTexture ''used to preserve texture states
	Global last_sprite:TSurface ''used to batch sprite state switching
	Global last_tex_count:Int =8
	
	Global disable_depth:Bool = False '' used for EntityFx 64 - disable depth testing
	
	' enter gl consts here for each available light
	Global gl_light:Int[] = [GL_LIGHT0,GL_LIGHT1,GL_LIGHT2,GL_LIGHT3,GL_LIGHT4,GL_LIGHT5,GL_LIGHT6,GL_LIGHT7] ''move const to trender
	Global light_no:Int, old_no_lights:Int
	
	Field t_array:Float[16] ''temp array
	
	Method New()
		
	End
	
	
	
	Method GetVersion:Float()
		Local st:String
		
		Local s:String = glGetString(GL_VERSION)
		
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

		Return Float( st )
		
	End

	
	Method Reset:Void()
		
		''reset globals used for state caching
		last_texture = Null ''used to preserve texture states
		last_sprite = Null ''used to preserve last surface states
		TRender.alpha_pass = 0
		
	End
	
	
	Method Render:Void(ent:TEntity, cam:TCamera = Null)
		
		Local mesh:TMesh = TMesh(ent)
		
		If Not mesh Then Return
		
		Local name$=ent.EntityName()
	
		Local fog%=False
		If cam.fog_mode = True Then fog=True ' if fog enabled, we'll enable it again at end of each surf loop in case of fx flag disabling it
	
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
'Print "   alphaloop "+alphaloop+" "+" tribuffersize:"+surf.tris.Length()+", tris:"+surf.no_tris+", verts:"+surf.no_verts
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
				anim_surf2 = mesh.anim_surf[surf.surf_id] ''assign anim surface
				
				If vbo And anim_surf2
				
					' update vbo
					If anim_surf2.reset_vbo<>False
						UpdateVBO(anim_surf2)
					Else If anim_surf2.vbo_id[0]=0 ' no vbo - lost context
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
		
			
			glEnableClientState(GL_NORMAL_ARRAY)
			glEnableClientState(GL_COLOR_ARRAY)
			
			If vbo
				
				''static mesh
				glBindBuffer(GL_ARRAY_BUFFER,surf.vbo_id[0])
				If Not (mesh.anim_render Or surf.vbo_dyn)
					glEnableClientState(GL_VERTEX_ARRAY)		
					glVertexPointer(3,GL_FLOAT, VertexDataBuffer.SIZE, VertexDataBuffer.POS_OFFSET)
				Endif
				
				glNormalPointer(GL_FLOAT,VertexDataBuffer.SIZE, VertexDataBuffer.NORMAL_OFFSET)
				glColorPointer(4,GL_FLOAT,VertexDataBuffer.SIZE, VertexDataBuffer.COLOR_OFFSET)
				glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,surf.vbo_id[5])
					
				'glBindBuffer(GL_ARRAY_BUFFER,surf.vbo_id[0]) 
				'glNormalPointer(GL_FLOAT,VertexDataBuffer.NORMAL_OFFSET,0)
				
				'If(fx&2)
					'glBindBuffer(GL_ARRAY_BUFFER,surf.vbo_id[0]) 
					'glColorPointer(4,GL_FLOAT,VertexDataBuffer.COLOR_OFFSET,0)
				'Endif

			Else
		
				Print "*** Non-VBO disabled"
		'' interleaved offset doesn't work with DataBuffers, possible TODO for legacy targets
#rem		
				glBindBuffer(GL_ARRAY_BUFFER,0) ' reset - necessary for when non-vbo surf follows vbo surf
				glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,0)
			
				If mesh.anim_render
					glVertexPointer(3,GL_FLOAT,VertexDataBuffer.SIZE,anim_surf2.vert_data.buf) 'anim_surf2.vert_coords.buf)
				Else
					glVertexPointer(3,GL_FLOAT,VertexDataBuffer.SIZE,surf.vert_data.buf) 'surf.vert_coords.buf)
				Endif
				
				Local pp:Int = Int(DataBuffer(surf.vert_data.buf).ReadPointer())
				
				glNormalPointer(GL_FLOAT,VertexDataBuffer.SIZE,pp+VertexDataBuffer.NORMAL_OFFSET) 'surf.vert_norm.buf)
				glColorPointer(4,GL_FLOAT,VertexDataBuffer.SIZE,pp+VertexDataBuffer.COLOR_OFFSET) 'surf.vert_col.buf)
#end			
			Endif
			
			
			Endif ''end sprite_skip_state--------------------------------------
			
		
			''mesh animation/batch animation
			If vbo And (mesh.anim_render Or surf.vbo_dyn Or anim_surf2)
			
				''vertex animation
				If anim_surf2 And anim_surf2.vert_anim
					glEnableClientState(GL_VERTEX_ARRAY)
					glBindBuffer(GL_ARRAY_BUFFER,anim_surf2.vbo_id[4])
					glVertexPointer(3,GL_FLOAT,0,0)
				
				'' mesh animation, using animsurf2	
				Elseif mesh.anim_render
					glEnableClientState(GL_VERTEX_ARRAY)
					glBindBuffer(GL_ARRAY_BUFFER,anim_surf2.vbo_id[0])
					glVertexPointer(3,GL_FLOAT,VertexDataBuffer.SIZE,VertexDataBuffer.POS_OFFSET)
				
				'' dynamic mesh, usually batch sprites	
				Elseif surf.vbo_dyn
					glEnableClientState(GL_VERTEX_ARRAY)
					glBindBuffer(GL_ARRAY_BUFFER,surf.vbo_id[0])
					glVertexPointer(3,GL_FLOAT,VertexDataBuffer.SIZE,VertexDataBuffer.POS_OFFSET)
				
				Endif
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
			
			glColor4f(1.0,1.0,1.0, alpha)
			
				
			' textures
			Local tex_count=0	
			
			tex_count=ent.brush.no_texs
			'If surf.brush<>Null
				If surf.brush.no_texs>tex_count Then tex_count=surf.brush.no_texs
			'EndIf
			
			''disable any extra textures from last pass ''-- what is this and why do i have this here?
			If tex_count < last_tex_count 
				For Local i:Int = tex_count To MAX_TEXTURES-1
				
					'glActiveTexture(GL_TEXTURE0+i)
					'glClientActiveTexture(GL_TEXTURE0+i)
					'glDisableClientState(GL_TEXTURE_COORD_ARRAY)
					'glDisable(GL_TEXTURE_2D)
				Next

			Endif
			last_tex_count = tex_count
			
			
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
							
						glActiveTexture(GL_TEXTURE0+ix)
						glClientActiveTexture(GL_TEXTURE0+ix)
	
						
						glBindTexture(GL_TEXTURE_2D,texture.gltex[0]) ' call before glTexParameteri
	
					
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
						If tex_smooth
							glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR)
							glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST_MIPMAP_LINEAR)
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
							glBindBuffer(GL_ARRAY_BUFFER,surf.vbo_id[0]) '1
							glTexCoordPointer(2,GL_FLOAT,VertexDataBuffer.SIZE,VertexDataBuffer.TEXCOORDS_OFFSET)
						Else
							glBindBuffer(GL_ARRAY_BUFFER,surf.vbo_id[0]) '2
							glTexCoordPointer(2,GL_FLOAT,VertexDataBuffer.SIZE,VertexDataBuffer.TEXCOORDS_OFFSET+VertexDataBuffer.ELEMENT2)
						Endif
					Else
					
					''interleaved data does not work with databuffers (no adddress offset)
#rem
						If tex_coords=0
							'glBindBuffer(GL_ARRAY_BUFFER,0) 'already reset above
							glTexCoordPointer(2,GL_FLOAT,VertexDataBuffer.SIZE,surf.vert_data.buf.PeekByte(VertexDataBuffer.TEXCOORDS_OFFSET))
						Else
							'glBindBuffer(GL_ARRAY_BUFFER,0)
							glTexCoordPointer(2,GL_FLOAT,VertexDataBuffer.SIZE,surf.vert_data.buf.PeekByte(VertexDataBuffer.TEXCOORDS_OFFSET+VertexDataBuffer.ELEMENT2))
						Endif
#end
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
					If tex_u_scale<>1.0 Or tex_v_scale<>1.0
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
					glDisableClientState(GL_TEXTURE_COORD_ARRAY)
					
					'glDisable(GL_TEXTURE_CUBE_MAP)
					'glDisable(GL_TEXTURE_GEN_S)
					'glDisable(GL_TEXTURE_GEN_T)
					'glDisable(GL_TEXTURE_GEN_R)
				
				Next
				glDisable(GL_TEXTURE_2D)
				
				last_texture = Null
				
			Endif
			
				
			'' draw tris
			
			glMatrixMode(GL_MODELVIEW)

			glPushMatrix()
	
			If mesh.is_sprite=False
				ent.mat.ToArray(t_array)
				glMultMatrixf(t_array )
			Else
				TSprite(mesh).mat_sp.ToArray(t_array)
				glMultMatrixf(t_array )
			Endif
			
			If cam.draw2D
				glDisable(GL_DEPTH_TEST)
				glDisable(GL_FOG)
				glDisable(GL_LIGHTING)
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
		
		
		If cam.draw2D
			glEnable(GL_DEPTH_TEST)
			glEnable(GL_LIGHTING)
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
		glFlush()
		
	End
	
	
	Method GraphicsInit:Int(flags:Int=0)
		
		TRender.render = New OpenglES11
		
#If CONFIG="debug"		
		Print "**OPENGL VERSION:"+GetVersion()
#Endif

		TTexture.TextureFilter("",8+1) ''default texture settings: mipmap

		' get hardware info and set vbo_enabled accordingly
		'THardwareInfo.GetInfo()
		'THardwareInfo.DisplayInfo()
		
		width = DeviceWidth()
		height = DeviceHeight()
		
		''get the TPixmapManager set
		TPixmapGL.Init()
		
		
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
	
	Method ClearErrors()
		While glGetError()<>GL_NO_ERROR
		 '
		Wend
	End	
	
	
	Method UpdateVBO:Int(surf:TSurface)
	
		If surf.vbo_id[0]=0
			glGenBuffers(6,surf.vbo_id)
		Endif

		If surf.reset_vbo=-1 Then surf.reset_vbo=255


		
		''surf.vert_anim array should be null until it is set by BoneToVertexAnimation
		
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
		
		If DEBUG And GetGLError() Then Print "*vbo update"

		
		surf.reset_vbo=False
		
	End
	
	
	Method FreeVBO(surf:TSurface)
	
		If surf.vbo_id[0]<>0 
			glDeleteBuffers(6,surf.vbo_id)
			surf.vbo_id[0]=0
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
	
	Method DeleteTexture(glid:Int[])
		
		If glid[0] Then glDeleteTextures(1,glid)
		glid[0] =0
		
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

		If Not tex.gltex[0]
			glGenTextures 1,tex.gltex
		Endif
		
		glBindTexture GL_TEXTURE_2D,tex.gltex[0]
		
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT) 'GL_CLAMP_TO_EDGE)
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT) 'GL_CLAMP_TO_EDGE)
		If flags&8
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
		Else
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
		Endif
		
		Local mipmap:Int= 0, mip_level:Int=0
		Local pix:TPixmapGL = TPixmapGL(tex.pixmap)
		
		If flags&8 Then mipmap=True
			
			Repeat
				glPixelStorei GL_UNPACK_ALIGNMENT,1
				glTexImage2D GL_TEXTURE_2D,mip_level,GL_RGBA,width,height,0,GL_RGBA,GL_UNSIGNED_BYTE,pix.pixels
				
				If( glGetError()<>GL_NO_ERROR )
					Error "** out of texture memory **"
				Endif
				
				If Not mipmap Or (width=1 And height =1) Then Exit
				If width>1 width *= 0.5
				If height>1 height *= 0.5

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
	
	
	Method UpdateLight(cam:TCamera, light:TLight)
		
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
		
	End
	
	
	Method DisableLight(light:TLight)
		
		light.light_link.Remove()
		
		glDisable(gl_light[light.no_lights])
		
		light = Null	
		
	End
	
	
	
	Method UpdateCamera(cam:TCamera)
	
		' viewport
		glViewport(cam.vx,cam.vy,cam.vwidth,cam.vheight)
		glScissor(cam.vx,cam.vy,cam.vwidth,cam.vheight)
		glClearColor(cam.cls_r,cam.cls_g,cam.cls_b,1.0)
		
		''load MVP matrix
		glMatrixMode(GL_MODELVIEW)
		'glLoadIdentity()
		cam.mod_mat.ToArray(t_array)	
		glLoadMatrixf(t_array )
		
		glMatrixMode(GL_PROJECTION)
		'glLoadIdentity()
		cam.proj_mat.ToArray(t_array)
		glLoadMatrixf(t_array )
	
		

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


		'fog
		If cam.fog_mode>0
			glEnable(GL_FOG)
			glFogf(GL_FOG_MODE,GL_LINEAR)
			glFogf(GL_FOG_START,cam.fog_range_near)
			glFogf(GL_FOG_END,cam.fog_range_far)

			glFogfv(GL_FOG_COLOR,[cam.fog_r,cam.fog_g,cam.fog_b,1.0])
		Else
			glDisable(GL_FOG)
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




