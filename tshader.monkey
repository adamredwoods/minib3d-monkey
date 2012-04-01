''
''
'' TShader
'' opengles 2.0
'' is for global shaders that replace the fixed pipeline
''
''-----------------------TO DO----------------------------------



Class TShader
	Global initsh:Int=0
	
	Global activeShader:Int =0
	
	Global totalID:Int =0
	Field internalID:Int =0 ''not used by opengl, used internally for a successful, active compile
	
	Field vshaderID:Int =0
	Field fshaderID:Int =0
	
	Field useFBO:Int=0
	Field textureFBO:TTexture
	Field rbufferID:Int
	Field fBufferID:Int
	Global supportFBO:Int=0
	
	
	Function Init:Int()
		''
		'' check for shader support, return false if none
		If initsh Then Return True
		If Not IsSupported() Return False
		
		GlewInit() ''The gl Extention calls
		
		initsh = 1
		TShaderBrush.initsh = 1
		
		Return True
	End
	
	Method IsValid:Int()
		''used to check if shader has been compiled successfully
		Return internalID
	End
	
	Function IsSupported:Int()
		''
		Local Extensions:String = String.FromCString(Byte Ptr(glGetString(GL_EXTENSIONS)))
		Local VPSupport:Int = Extensions.Find("GL_ARB_vertex_program") > -1
		Local FPSupport:Int = Extensions.Find("GL_ARB_fragment_program") > -1
		supportFBO = Extensions.Find("GL_EXT_framebuffer_object") > -1
		
		If Not supportFBO
			DebugLog "**No FrameBufferObject support."
		Endif
		
		If Not(VPSupport)
			DebugLog "**No ARB Vertex Program support."
			Return False
		Endif
		
		If Not(FPSupport)
			DebugLog "**No ARB Fragment Program support."
			Return False 
		Endif
		
		Return True
	End


	Function LoadARB:TShader(vp:Object, fp:Object)
		''input path or stream for vertex arb shaders
		''vp or fp can be null, but not both
		'' arb Opengl 1.5 probability
		Local sh:TShader = New TShader
		
		If Not initsh DebugLog "**Shader error: not init()"; Return sh
		
		While glGetError() <> GL_NO_ERROR ''clear out any existing openGL errors
		Wend
		
		
		''Prepare Vertex program
		If vp <> Null
			''Read File
			Local vpData:TStream =  ReadStream(vp)
			If Not vpData Then DebugLog "**Shader error: no stream"; Return sh
			
			Local vpAssembly:String = Null
			While Not Eof(vpData)
				vpAssembly = vpAssembly + ReadLine(vpData).Trim()+ "~n"
			Wend
			CloseStream(vpData)
	
	
			glGenProgramsARB( 1, Varptr sh.vshaderID )
			glBindProgramARB(GL_VERTEX_PROGRAM_ARB, sh.vshaderID)
			
			'' Compile shader string
			glProgramStringARB(GL_VERTEX_PROGRAM_ARB, GL_PROGRAM_FORMAT_ASCII_ARB, vpAssembly.length, vpAssembly.ToCString() )
				
			If ( glGetError() <> GL_NO_ERROR )
				Print "**Shader Error: Vertex program"
				Local error_out:String = String.FromCString(glGetString(GL_PROGRAM_ERROR_STRING_ARB))
				DebugLog( error_out )
	
				Return sh
			End If
		Endif
		
		
		''Prepare Fragment Program
		If fp <> Null
			Local fpData:TStream =  ReadStream(fp)
			If Not fpData Then DebugLog "**Shader error: no stream"; Return sh
			
			Local fpAssembly:String = Null
			While Not Eof(fpData)
				fpAssembly = fpAssembly + ReadLine(fpData).Trim()+ "~n"
			Wend
			CloseStream(fpData)
			
			
			glGenProgramsARB( 1, Varptr sh.fshaderID )
			glBindProgramARB( GL_FRAGMENT_PROGRAM_ARB, sh.fshaderID)
			
			'' Compile shader string
			glProgramStringARB( GL_FRAGMENT_PROGRAM_ARB, GL_PROGRAM_FORMAT_ASCII_ARB, fpAssembly.length, fpAssembly.ToCString() )
			
			If ( glGetError() <> GL_NO_ERROR )
				Print "**Shader Error: Fragment program"
				Local error_out:String = String.FromCString(glGetString(GL_PROGRAM_ERROR_STRING_ARB))
				DebugLog( error_out )
	
				Return sh 
			Endif
		Endif
		
		If sh.vshaderID Or sh.fshaderID
			totalID :+1
			sh.internalID = totalID ''validate compiling of shader
			
			DebugLog "Shader success: "+sh.internalID
		Endif
		
		Return sh
		
	End
	
	Function LoadGLSL:TShader(vp$, fp$)
		Local sh:TShader = New TShader
		If Not initsh DebugLog "**Shader error: not init()"; Return sh
		
		
		'' glsl OpenGL 2.0+
		Return sh
		
	End
	
	Method Active:Int(on:Int=1)
		'' 0 to turn off and return to fixed pipeline
		If Not initsh Then Return False
		'DebugLog "..shader active"
		If on And internalID
			If vshaderID
				glEnable(GL_VERTEX_PROGRAM_ARB)
				glBindProgramARB(GL_VERTEX_PROGRAM_ARB, vshaderID)
			Endif
			
			If fshaderID
				glEnable(GL_FRAGMENT_PROGRAM_ARB)
				glBindProgramARB(GL_FRAGMENT_PROGRAM_ARB, fshaderID)
				
				If useFBO
					glBindFramebufferEXT(GL_FRAMEBUFFER_EXT , fbufferID)
				Endif
				
			Endif
			
		Else
			glDisable(GL_VERTEX_PROGRAM_ARB)
			glDisable(GL_FRAGMENT_PROGRAM_ARB)
			
			If useFBO
				glBindFramebufferEXT(GL_FRAMEBUFFER_EXT , 0)
			Endif
			
		Endif
		
		Return True
		
	End
	
	
	Method SetFragmentLocalParam(index:Int, arr:Float[])
		glProgramLocalParameter4fvARB( GL_FRAGMENT_PROGRAM_ARB,index, arr )
	End
	
	Method SetVertexLocalParam(index:Int, arr:Float[] )
		glProgramLocalParameter4fvARB( GL_VERTEX_PROGRAM_ARB,index, arr )
	End
	

	
	Method SetFBO:Int(tex:TTexture=Null)
		''this will render this shader's output to a texture whenever the shader is executed
		''may fall back to the FFP render to texture if fbo isn't available
		If Not supportFBO Then Return False
		
		If tex=Null
		
			Local texsize:Int = TTexture.Pow2Size(TGlobal.height*2)
			If(TGlobal.width > TGlobal.height) texsize = TTexture.Pow2Size(TGlobal.width*2)
			textureFBO = CreateTexture(texsize ,texsize ,1,1)
		Else
			textureFBO = tex
		Endif
		
		glGenFramebuffersEXT(1, Varptr fbufferID )
		
		''attach texture
		'glGenTextures(1, textureFBO.gltex)
		glBindTexture(GL_TEXTURE_2D, textureFBO.gltex[0])
		glBindFramebufferEXT(GL_FRAMEBUFFER_EXT , fbufferID)
		glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_2D, textureFBO.gltex[0], 0)
		
		''attach depth renderbuffer
		'glGenRenderbuffersEXT(1 , Varptr rbufferID)
		'glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, textureFBO.width, textureFBO.height, 0, GL_RGB, GL_UNSIGNED_BYTE, Null)
		'glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR )
		'glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR )
		'glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, rbufferID)
		'glRenderbufferStorageEXT(GL_RENDERBUFFER_EXT, GL_DEPTH_COMPONENT24, textureFBO.width,  textureFBO.height)
		'glFramebufferRenderbufferEXT(GL_FRAMEBUFFER_EXT , GL_DEPTH_ATTACHMENT_EXT , GL_RENDERBUFFER_EXT , rbufferID)
		
		Local status:Int =  glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT)
		
		Select status
		   	Case GL_FRAMEBUFFER_COMPLETE_EXT
				useFBO = 1
				DebugLog "..FBO success: " + Status
			Case GL_FRAMEBUFFER_UNSUPPORTED_EXT
				DebugLog "**FBO: unsupported. choose different formats"; Return False 
			Default
				DebugLog "**FBO unsuccessful"; Return False 
		EndSelect 
		
		
		
		Return True
	End
	
	Method ClearFBO()
		useFBO =0
		glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_2D, 0, 0)
		glBindFramebufferEXT(GL_FRAMEBUFFER_EXT , 0)
	End
	
	
	
	Function Render(mesh:TMesh)
		If Not initsh Or Not mesh Then Return
		''called from TGlobal.bmx RenderWorld()
		
		
		mesh.shader_brush.RenderOn()
		
		'' vbo
		
		mesh.shader_brush.RenderOff()
		
	End
	
	Function ForceOff()
		If Not initsh Then Return False

			glDisable(GL_VERTEX_PROGRAM_ARB)
			glDisable(GL_FRAGMENT_PROGRAM_ARB)
	End
End

'' Global functions
''
Function InitShaders:Int()
	Return TShader.Init() ''keep this the only function for compatibility
End

''
'' shaders for individual entities
''
Class TShaderBrush Extends TBrush
	''used for PaintMesh, entity, etc.
	''** you must use InitShaders() or TShader.Init() to begin
	
	Global initsh:Int =0 ''Init by TShader
	
	Field isActive:Int =0 ''also used to disable opengl FFP
	Field shader:TShader 
	
	Method IsValid:Int()
		Return shader.IsValid()
	End
	
	Function LoadARB:TShaderBrush(vp:Object, fp:Object)
		'' returns a new shaderbrush
		If Not initsh Then Return Null
		
		Local sh:TShaderBrush = New TShaderBrush
		sh.shader = TShader.LoadARB(vp,fp)
		
		''fail
		If Not sh.IsValid()
			Return sh
		Endif
		
		sh.isActive = True ''make active immediately
		DebugLog "..brush shader active"
			
		''in order for a shader to use UV coords, need to enable it within the brush by default
		sh.BrushTexture(CreateTexture(1,1,1,1),0,0)
		sh.BrushTexture(CreateTexture(1,1,1,1),0,1)
			
		Return sh
	End
	
	Method Active(a:Int=1)
		''on 1 /off 0
		If Not initsh Then Return False
		
		If a
			isActive = True
			DebugLog "..brush shader active"
		Else
			isActive = False
		Endif
	End
	
	Method RenderOn()
		'' internal use by TMesh
		If Not isActive Or Not initsh Then Return
		
		''turn on shader
		shader.Active(1)

	End
	
	Method RenderOff()
		''internal use by TMesh
		If Not isActive Or Not initsh Then Return

		''turn off shader
		shader.Active(0)

	End
	
	Method SetFragmentLocalParam(index:Int, arr:Float[])
		shader.SetFragmentLocalParam(index, arr )
	End
	Method SetVertexLocalParam(index:Int, arr:Float[] )
		shader.SetVertexLocalParam(index, arr )
	End
	Method SetVertexLocalParam4x4(index:Int, arr:Float[,] )
		Local x:Int=0, y:Int=0
		For Local i:Int = index To index+3
			Local f:Float[] = [arr[x,0],arr[x,1],arr[x,2],arr[x,3]]
			shader.SetVertexLocalParam(i, f )
			x:+1
		Next
	End
	
	Method SetFBO(tex:TTexture=Null)
		''this will render this shader's output to a texture whenever the shader is executed
		shader.SetFBO(tex)
	End
	
	Method SetPostShader(sh:TShader)
		''use this to add post-effects shaders to effect the FBO
		'' also allows one to chain shader commands
		''
		
	End
	
	''perhaps render to texture instructions
	
	
End
