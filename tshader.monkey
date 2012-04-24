''
''
'' TShaderBrush
'' opengles 2.0
''
Import minib3d


Class TShader

	Global enabled:Int =0 ''Init shaders by TRender
	
	Field active:Int =0
	Field shader_id:Int =0
	Field fragment_id:Int =0
	Field vertex_id:Int =0
	
End

'' --load all shaders through the brush
'' --FBO Class is managed with TRender since platform specific
Class TShaderBrush Extends TBrush
	
	Global g_shader:TShaderBrush ''default shader
	Global shader_list:List<TShaderBrush> = New List<TShaderBrush>
	
	Field shader:TShader
	
	Field useFBO:Int =0
	Field useDepth:Int =0
	Field fbo:FrameBuffer


	
	Method PreProcess:Void() Abstract ''run before all rendering (clear framebuffer)
	
	Method PostProcess:Void() Abstract ''run after all rendering (draw framebuffer)
	
	
	''-------------------------
	
	Method New()
		
		''create new fbo if needed here
		
	End
	
	Method IsValid:Int()
	
		Return shader.active
		
	End
	
	Function LoadARB:TShaderBrush(vp:Object, fp:Object)
		'' returns a new shaderbrush
		If Not TShader.enabled Then Return Null
		
		Local sh:TShaderBrush = New TShaderBrush
		sh.shader = TShader.LoadARB(vp,fp)
		
		''fail
		If Not sh.IsValid()
			Return sh
		Endif
		
		DebugLog "..brush shader active"
			
		''in order for a shader to use UV coords, need to enable it within the brush by default
		sh.BrushTexture(CreateTexture(1,1,1,1),0,0)
		sh.BrushTexture(CreateTexture(1,1,1,1),0,1)
			
		Return sh
	End
	

	''-----------move to trender
	Method RenderBrush( mesh:TMesh, cam:TCamera)
		''function: per mesh being rendered

		If Not isActive Or Not initsh Or Not mesh Or Not shader Then Return

		''turn on shader
		shader.Active(1)

		''render
		mesh.Update()
		
		''turn off
		shader.Active(0)


		If useFBO

			glBindTexture(GL_TEXTURE_2D, 0)
			glBindFramebufferEXT(GL_FRAMEBUFFER_EXT , 0)
			glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, 0)
			
			TShader.DisplayFBO( TShader.mainTextureFBO )
			TShader.ClearMainFBO()
			TShader.DisplayFBO( shader.textureFBO )

		Endif

		''do next shader, iterative
		'If shader.shader_link Then shader.shader_link.Render(mesh, cam)		
	End
	


	
	Method SetFragmentLocalParam(index:Int, n1:Float, n2:Float=Null, n3:Float=Null, n4:Float=Null)		
		shader.SetFragmentLocalParam(index, n1, n2, n3, n4 )
	End
	
	Method SetVertexLocalParam(index:Int, n1:Float, n2:Float=Null, n3:Float=Null, n4:Float=Null)		
		shader.SetVertexLocalParam(index, n1, n2, n3, n4 )
	End
	
	Method SetVertexLocalParam4x4(index:Int, arr:Float[,] )
		Local x:Int=0, y:Int=0
		For Local i:Int = index To index+3
			'Local f:Float[] = [arr[x,0],arr[x,1],arr[x,2],arr[x,3]]
			shader.SetVertexLocalParam(i, arr[x,0],arr[x,1],arr[x,2],arr[x,3] )
			x:+1
		Next
	End
	
	Method SetFBO( tex:TTexture=Null, depthFlag:Int=True)
		''this will render this shader's output to a texture whenever the shader is executed
		''default depth to be ON for FBOs
		''Also: this function can take a shader, if it has not been associated with a shader-- used for extended passes
		
		
		useDepth = depthFlag
		useFBO = True
		texture = tex
		
	End
	
	Method GetFBO:TTexture()
		''returns a texture associated with this FBO
		
		If Not useFBO Then Return Null
		Return fbo.texture
		
	End

	
	Method SetShader(sh:TShader)
		shader = sh
		useFBO = sh.useFBO
		fbufferID = sh.fbufferID
		textureFBO = sh.textureFBO
	End
	
	#rem
	Method ProcessFBO(t:TTexture, alpha:Int=1.0, sh:TShaderBrush)
		'' function: a special method to draw an full-screen quad using the attached shader from a given FBO texture
		'' -- used to chain effects
		'' -- no depth is used
		'' -- is written back into the attached shader FBO, not displayed on screen
		
		TRender.render.ProcessFBO(t, alpha, sh)
		
	End
	#end
	
	Function DisplayFBO(alpha:Int=1.0, sh:TShaderBrush=Null)
		''-- use TShaderBrush to chain effects
		''-- null displays normal, no altering
		fbo.Display(alpha, sh)
	End
	
	
	Method ClearFBO(depth:Int=0)
		fbo.Clear(depth)
	End
	
	
End
