Import opengl.gles20
Import minib3d.framebuffer
Import minib3d.trender
Import minib3d.opengl.tshaderglsl
Import minib3d.opengl.opengles20

''NOTES:
''-- FBOs ONLY work with VBOs (webGL thing, although could make separate for non-vbo)
''-- note quad verts are flipped since we draw from bottom left. plus, this keeps UV coords ok.
''-- if we flip uv coords (-1.0,0.0), then clamp doesn't work properly
''-- never make an fbo have mipmapping
''-- FBOs had a problem when capturing to a texture with its UV coordinates defined (would capture to area within an area). instead,
''   set proper UVs during FBO display, keep UVs 1.0 otherwise.


Class FrameBufferGL Extends FrameBuffer

	Const MAXTEXSIZE:Int=2048
	
	Global supportFBO:Int=0
	Global framebuffer_active:FrameBufferGL = Null ''current active FBO, used for TRender
	
	Field fbufferID:Int
	Field rbufferID:Int
	Field texture:TTexture '= New TTexture
	Field depth_flag:Int
	
	''ratios for texture vs device size
	Field UVW:Float =1.0, UVH:Float = 1.0
	
	Global surf:TSurface '' quad surface to draw
	
	Global quad_buf:FloatBuffer
	Global temp_buf:FloatBuffer
	Global temp_buf_id:Int[1]
	
	Method Width:Int()
		Return texture.width
	End
	
	Method Height:Int()
		Return texture.height
	End
	
	Method TextureID:Int()
		
		Return texture.gltex[0]
		
	End
	
	Method BindTexture:Void(i:Int=0)
	
		glActiveTexture(GL_TEXTURE0+i)
		glBindTexture(GL_TEXTURE_2D, texture.gltex[0]) 
		
	End
	
	Method BeginFBO()
		
		If Not fbufferID Then Return
		
		'glBindTexture(GL_TEXTURE_2D, texture.gltex[0]) 
		glBindFramebuffer(GL_FRAMEBUFFER , fbufferID)
		glBindRenderbuffer(GL_RENDERBUFFER, rbufferID)
		
		framebuffer_active=Self
		
	End
	
	Method EndFBO()
		
		If Not fbufferID Then Return

		glBindFramebuffer(GL_FRAMEBUFFER , 0)
		glBindRenderbuffer(GL_RENDERBUFFER, 0)
		
		framebuffer_active=Null
		
	End
	
	Method FreeFBO()
		
		glDeleteFramebuffer(fbufferID)
		glDeleteRenderbuffer(rbufferID)
		texture.FreeTexture()
		
	End
	
	Function CreateFBO:FrameBufferGL(tex:TTexture=Null, depth:Bool=True)
		
		If Not supportFBO Then Return Null
		
		'temp_buf = FloatBuffer.Create(8)
		'temp_buf_id[0] =glCreateBuffer()
		
		
		Local fbo:FrameBufferGL = New FrameBufferGL
		
		If tex=Null
		
			Local texsize:Int
			If(TRender.width < TRender.height)
				texsize = TTexture.Pow2Size(TRender.height)
			Else
				texsize = TTexture.Pow2Size(TRender.width)
			Endif
			If texsize > MAXTEXSIZE Then texsize = MAXTEXSIZE
			fbo.texture = CreateTexture(texsize ,texsize ,3)

		Else
			fbo.texture = tex ''need power-of-two size
		Endif
		
		''attach texture
		fbo.fbufferID = glCreateFramebuffer()
		
		glBindTexture(GL_TEXTURE_2D, fbo.texture.gltex[0])
		
		If Not fbo.texture.tex_smooth
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
    		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
		Else
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
    		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
		Endif
		
		''auto-clamp fbos
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_CLAMP_TO_EDGE)
		glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_CLAMP_TO_EDGE)

		glBindFramebuffer(GL_FRAMEBUFFER , fbo.fbufferID)
		glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, fbo.texture.gltex[0], 0)
		
		''attach depth renderbuffer
		'' currently, rbufferID is global to minimize memory use
		'' -- may have problem with setting smaller render buffers than screen
		If (depth And Not fbo.rbufferID)
			fbo.rbufferID=glCreateRenderbuffer()
		Endif
		If (depth)
			glBindRenderbuffer(GL_RENDERBUFFER, fbo.rbufferID)
			''GL_DEPTH_COMPONENT16 for html5
			glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, fbo.texture.width,  fbo.texture.height) 
			glFramebufferRenderbuffer(GL_FRAMEBUFFER , GL_DEPTH_ATTACHMENT , GL_RENDERBUFFER , fbo.rbufferID)
		Endif
		
		Local status:Int =  glCheckFramebufferStatus(GL_FRAMEBUFFER)
		
		Select status
		   	Case GL_FRAMEBUFFER_COMPLETE
				
				Dprint "..FBO success"
			Case GL_FRAMEBUFFER_UNSUPPORTED
				Dprint "**FBO: unsupported." '' Return Null 
			Default
				Dprint "**FBO unsuccessful :"+status '' Return Null 
		End 

		
		
		'' UV ratio is the same for 1024x1024 or 512x512
		If fbo.texture.width>fbo.texture.height
			fbo.UVW =  Float(fbo.texture.height) / fbo.texture.width 
			fbo.UVH =  1.0
		Elseif fbo.texture.width<fbo.texture.height
			fbo.UVW =  1.0 
			fbo.UVH =  Float(fbo.texture.width) / fbo.texture.height
		Else
			fbo.UVW=1.0
			fbo.UVH=1.0
		Endif
	

		If fbo.texture.width < TRender.width Or fbo.texture.height < TRender.height
			If TRender.width>TRender.height
				fbo.UVH = Float(TRender.height)/TRender.width
			Else
				fbo.UVW = Float(TRender.width)/TRender.height
			Endif
		Else
			fbo.UVW = (Float(TRender.width) / fbo.texture.width)
			fbo.UVH = (Float(TRender.height) / fbo.texture.height)
		Endif
	

'Print "UVW "+fbo.UVW+" "+fbo.UVH
		
		''create quad surface
		''** note quad verts are flipped since we draw from bottom left. plus, this keeps UV coords ok.
		''** if we flip uv coords, then clamp doesn't work properly
		If Not surf
			surf = New TSurface()
			surf.AddVertex(-1,1,0, 0, 1.0)'fbo.UVH)
			surf.AddVertex(-1, -1,0, 0, 0)
			surf.AddVertex( 1, -1,0, 1.0,0.0)'fbo.UVW, 0)
			surf.AddVertex( 1,1,0, 1.0,1.0) 'fbo.UVW, fbo.UVH)
			surf.AddTriangle(1,0,2)
			surf.AddTriangle(2,0,3)
			'surf.AddTriangle(0,1,2)
			'surf.AddTriangle(0,2,3)
			
			'quad_buf = FloatBuffer.Create(18)
			'Local quad_dat:Float = [-1,-1,0.0, -1.0,-1.0,0.0, 1.0,-1.0,0.0, 1.0,1.0,0.0]
			'For Local i:Int=0 To 17
				'quad_buf.Poke(i,quad_dat[i])
			
			'Next
			
			surf.reset_vbo=-1
		Endif
		
		fbo.depth_flag = depth
		
		''clean exit
		glBindTexture(GL_TEXTURE_2D, 0)
		glBindFramebuffer(GL_FRAMEBUFFER , 0)
		glBindRenderbuffer(GL_RENDERBUFFER, 0)
		
		If DEBUG And OpenglES20.GetGLError() Then Print "**FBO Create error"
		
		Return fbo
		
	End

	
	Method Clear(depth:Int=0)
	
		glBindFramebuffer(GL_FRAMEBUFFER , fbufferID)
		glBindRenderbuffer(GL_RENDERBUFFER, rbufferID)
		
		glClearColor(0.0,0.0,0.0,0.0)
		glClearDepthf(1.0)
		
		Local bit:Int = GL_COLOR_BUFFER_BIT
		
		If depth
			glDepthMask(True)
			bit = bit | GL_DEPTH_BUFFER_BIT
		Endif
		
		glClear(bit)
		
		glBindFramebuffer(GL_FRAMEBUFFER , 0)
		glBindRenderbuffer(GL_RENDERBUFFER, 0)
	End
	
	
	Method Draw(cam:TCamera, alpha:Float=1.0, depth:Float=0.0, shader:TShaderGLSL=Null)
		''-- use TShader to chain effects
		''-- null displays normal, no altering
		
		If Not texture Or Not surf  Then Return
		
		glBindBuffer(GL_ARRAY_BUFFER,0) ' reset - necessary for when non-vbo surf follows vbo surf
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,0)
		
		''update camera, dont clear
		Local temp1:Int = cam.cls_color
		Local temp2:Int = cam.cls_zbuffer
		cam.cls_color = False; cam.cls_zbuffer = False
		
		TRender.render.UpdateCamera(cam) ''update camera viewport for smaller fbos
		
		'glViewport(0,0,640,480)
		'glScissor(cam.vx,cam.vy,cam.vwidth,cam.vheight)
		
		cam.cls_color = temp1; cam.cls_zbuffer = temp2
		
		
		If TShader(shader)
			
			''enable
			glUseProgram(shader.shader_id)
			shader.Update()
			
		Else
			
			shader = TShaderGLSL(TShader.g_shader)	
	
			If Not shader.shader_id Then Return
			
			glUseProgram(shader.shader_id)
			shader.Update()
			
		Endif
		
		If surf.reset_vbo<>0
			OpenglES20(TRender.render).UpdateVBO(surf)
		Else If surf.vbo_id[0]=0 ' no vbo - unknown reason
			surf.reset_vbo=-1
			OpenglES20(TRender.render).UpdateVBO(surf)

		Endif
		
		If shader.use_base_variables
			
			If shader.u.lightflag<>-1 Then glUniform1f( shader.u.lightflag, 0.0 )
			If shader.u.texflag<>-1 Then glUniform1f( shader.u.texflag, 1.0 )
			If shader.u.colorflag<>-1 Then glUniform1f( shader.u.colorflag, 0.0 )
			If shader.u.base_color<>-1 Then glUniform4fv( shader.u.base_color, 1, [1.0,1.0,1.0,alpha] )
			If shader.u.shininess <>-1 Then glUniform1f( shader.u.shininess, 0.0 )
	
			If shader.u.ambient_color<>-1 Then glUniform4fv( shader.u.ambient_color, 1, [0.0,0.0,0.0,0.0] )
			
			''Set UVW, UVH here, otherwise it will interfere with FBO capture
			'Local texcoords0:Float = [0.0,UVH,0.0,0.0,UVW,0.0,UVW,UVH]
			'temp_buf.Poke(0,0.0)
			'temp_buf.Poke(1,UVH)
			'temp_buf.Poke(2,0.0)
			'temp_buf.Poke(3,0.0)
			'temp_buf.Poke(4,UVW)
			'temp_buf.Poke(5,0.0)
			'temp_buf.Poke(6,UVW)
			'temp_buf.Poke(7,UVH)
			surf.VertexTexCoords(0,0.0,UVH)
			surf.VertexTexCoords(1,0.0,0.0)
			surf.VertexTexCoords(2,UVW,0.0)
			surf.VertexTexCoords(3,UVW,UVH)
				
			If shader.u.texcoords0<>-1

				glEnableVertexAttribArray(shader.u.texcoords0)
				'glBindBuffer(GL_ARRAY_BUFFER,temp_buf_id[0]) 'surf.vbo_id[1])	
				'glBufferData(GL_ARRAY_BUFFER,( 32 ),temp_buf.buf,GL_DYNAMIC_DRAW)
				glBindBuffer(GL_ARRAY_BUFFER,surf.vbo_id[0])
				glVertexAttribPointer( shader.u.texcoords0, 2, GL_FLOAT, False, VertexDataBuffer.SIZE, VertexDataBuffer.TEXCOORDS_OFFSET )

			Endif
	
			glEnableVertexAttribArray(shader.u.vertcoords)			
			glBindBuffer(GL_ARRAY_BUFFER,surf.vbo_id[0])
			glVertexAttribPointer( shader.u.vertcoords, 3, GL_FLOAT, False, VertexDataBuffer.SIZE, VertexDataBuffer.POS_OFFSET )
			
			
		
			If shader.u.normals<>-1
				glDisableVertexAttribArray(shader.u.normals)
				'glBindBuffer(GL_ARRAY_BUFFER,surf.vbo_id[3]) 'normals
				'glEnableVertexAttribArray(shader.u.normals)
				'glVertexAttribPointer( shader.u.normals, 3, GL_FLOAT, False, VertexDataBuffer.SIZE, VertexDataBuffer.NORMAL_OFFSET )
			Endif
	
			
			If shader.u.tex_position[0] <>-1 Then glUniform2f(shader.u.tex_position[0], 0.0,0.0)
			If shader.u.tex_rotation[0] <>-1 Then glUniform2f(shader.u.tex_rotation[0], 1.0,0.0) '' Cos(ang),Sin(ang)  					
			If shader.u.tex_scale[0] <>-1 Then glUniform2f(shader.u.tex_scale[0], 1.0, 1.0)
	
			If shader.u.tex_blend[0] <>-1 Then glUniform2f(shader.u.tex_blend[0], 0.0,0.0) 'tex_blend, tex_blend)
			If shader.u.texfx_normal[0] <>-1 Then glUniform1i(shader.u.texfx_normal[0], 0)
			If shader.u.texture[0] <>-1 Then glUniform1i(shader.u.texture[0], 0)
			
			If shader.u.v_matrix<>-1 glUniformMatrix4fv( shader.u.v_matrix, 1, False, [1.0,0.0,0.0,0.0, 0.0,1.0,0.0,0.0, 0.0,0.0,1.0,0.0, 0.0,0.0,0.0,1.0] )
			'If shader.u.p_matrix<>-1 glUniformMatrix4fv( shader.u.p_matrix, 1, False, [1.0,0.0,0.0,0.0, 0.0,1.0,0.0,0.0, 0.0,0.0,-(cam.range_far + cam.range_near) / (cam.range_far - cam.range_near),-1.0, 0.0,0.0,-2.0*cam.range_far*cam.range_near / (cam.range_far - cam.range_near),1.0] ) 
			If shader.u.p_matrix<>-1
				'Local mat:Float[] = cam.proj_mat.ToArray()
				'mat[0] = cam.range_near; mat[5] = cam.range_near; mat[11] = -1.0; mat[15] = 1.0
				If depth Then glUniformMatrix4fv( shader.u.p_matrix, 1, False, [cam.range_near,0.0,0.0,0.0, 0.0,cam.range_near,0.0,0.0, 0.0,0.0,cam.proj_mat.grid[2][2],-1, 0.0,0.0,cam.proj_mat.grid[2][3],1.0] )
			 	Else glUniformMatrix4fv( shader.u.p_matrix, 1, False,[1.0,0.0,0.0,0.0, 0.0,1.0,0.0,0.0, 0.0,0.0,-1.0,-1.0, 0.0,0.0,0.0,1.0])
			Endif
			'If shader.u.p_matrix<>-1 glUniformMatrix4fv( shader.u.p_matrix, 1, False, [0.5,0.0,0.0,0.0, 0.0,0.5,0.0,0.0, 0.0,0.0,-1.0,-1.0, 0.0,0.0,0.0,0.5] ) 
			If shader.u.m_matrix<>-1
				If depth Then glUniformMatrix4fv( shader.u.m_matrix, 1, False, [(1.0+depth),0.0,0.0,0.0, 0.0,(1.0+depth),0.0,0.0, 0.0,0.0,(1.0+depth),0.0, 0.0,0.0,-depth,1.0] ) 
				Else glUniformMatrix4fv( shader.u.m_matrix, 1, False, [1.0,0.0,0.0,0.0, 0.0,1.0,0.0,0.0, 0.0,0.0,1.0,0.0, 0.0,0.0,0.0,1.0] )
			Endif
			'If shader.u.m_matrix<>-1 glUniformMatrix4fv( shader.u.m_matrix, 1, False, [1.0,0.0,0.0,0.0, 0.0,1.0,0.0,0.0, 0.0,0.0,1.0,0.0, 0.0,0.0,-depth,1.0] )
					
			If DEBUG And OpenglES20.GetGLError() Then Print "*FBO Display error uniforms"
			
		Endif
		
		
		glActiveTexture(GL_TEXTURE0)
		glBindTexture(GL_TEXTURE_2D, texture.gltex[0])	
			
		glEnable(GL_DEPTH_TEST)
		glDepthMask(False)
		'glDepthFunc(GL_GREATER)
		
		''allow user to set blend
		glEnable (GL_BLEND)
		'glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
	
	
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,surf.vbo_id[5]) 'tris
		glDrawElements(GL_TRIANGLES,surf.no_tris*3,GL_UNSIGNED_SHORT, 0)
		
		If DEBUG And OpenglES20.GetGLError() Then Dprint "*FBO Display error DrawElements"
		
		glBindTexture GL_TEXTURE_2D,0
		
		
		'glEnable(GL_LIGHTING)
		'glEnable(GL_CULL_FACE)
		'glEnable(GL_DEPTH_TEST)
		'glEnable(GL_SCISSOR_TEST)
		glDepthMask(True)
		'glDepthFunc(GL_LEQUAL)
		
		If shader.u.texcoords0<>-1 Then glDisableVertexAttribArray(shader.u.texcoords0)
		
	End
End
