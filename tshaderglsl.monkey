'' TShader
'' opengles 2.0

Import tshader
Import opengl.gles20

Class TShaderGLSL Extends TShader

	
	Field useFBO:Int =0
	Field useDepth:Int =0
	Field fbo:FrameBuffer
	
	'' shader variable locations
	Field texture0:Int 'uniform
	Field texture1:Int	'uniform
	Field vertcoords:Int 'attrib
	Field texcoords0:Int 'attrib
	Field texcoords1:Int 'attrib
	Field normals:Int 'attrib
	Field colors:Int 'attrib
	
	Field vp_matrix:Int 'uniform
	Field m_matrix:Int 'uniform
	Field light_pos:Int[8] 'uniform
	Field light_dir:Int[8] 'uniform
	Field light_color:Int[8] 'uniform frag
	
	Field base_color:Int
	Field ambient_color:Int
	Field specular:Int
	Field shininess:Int
	
	Field flags:Int 'uniform
	Field texflag:Int 'uniform
	Field colorflag:Int
	Field lightflag:Int
	
	Method New()
		
		''put fbo creation here and extended shaders
		
	End
	
	Function LoadShader:TShaderGLSL(vp_file:String, fp_file:String)
		
		Local shader:TShaderGLSL = New TShaderGLSL
		
		Local vs:Int = shader.CompileShader(LoadString(vp_file),GL_VERTEX_SHADER)
		Local fs:Int = shader.CompileShader(LoadString(fp_file),GL_FRAGMENT_SHADER)
		If (vs) And (fs)
			
			Print "shader success: "+vp_file+" "+fp_file
		
		Else
		
			Print "compiler error: "+vp_file+" "+vs+", "+fp_file+" "+fs

		Endif
		
		''bind shader
		shader.shader_id = glCreateProgram()
		If shader.shader_id<0 Then Print"**Shader Program not created."
		
		glAttachShader(shader.shader_id, shader.vertex_id)
		glAttachShader(shader.shader_id, shader.fragment_id)
'Print shader.shader_id+" "+shader.vertex_id+" "+shader.fragment_id

	
		glLinkProgram(shader.shader_id)

		Local result:Int[1]
		glGetProgramiv(shader.shader_id, GL_LINK_STATUS, result)
		
		If result[0] <> GL_TRUE
			DebugLog "Shader Linking Error "+result[0]
			
			Local log:String
			log = glGetShaderInfoLog(shader.shader_id)
			Print log
			
			glDeleteShader(shader.vertex_id)
			glDeleteShader(shader.fragment_id)
			glDeleteProgram(shader.shader_id)
			
			shader.vertex_id=0; shader.fragment_id=0; shader.shader_id=0
			
			Return shader
		Endif
		
		shader.active=1
		
		''create uniforms
		shader.LinkVariables()
		
		Return shader
	End
	
	'' type = GL_VERTEX_SHADER, GL_FRAGMENT_SHADER
	''
	Method CompileShader:Int(source:String, type:Int)
		
		If source.Length() <1
			Print "**Shader file not found"
			Return 0
		Endif
		
		''Create GLSL Shader
		Local id:Int = glCreateShader(type)
		If type = GL_VERTEX_SHADER Then vertex_id = id Else fragment_id = id
		
		glShaderSource(id, source )
		glCompileShader(id)	
	
		Local result:Int[1]
		glGetShaderiv(id, GL_COMPILE_STATUS, result)
		
		Local log:String
		log = glGetShaderInfoLog(id)
		Print log
			
		If result[0] <> GL_TRUE
			DebugLog "Shader Compile Error "
				
			glDeleteShader(id)
			If type = GL_VERTEX_SHADER Then vertex_id = 0 Else fragment_id = 0
			
			Return 0
		Endif
		
		Return 1
		
	End
	

	Method LinkVariables()
	
		If active
		
			texture0 = glGetUniformLocation(shader_id, "uTexture0")
			texture1 = glGetUniformLocation(shader_id, "uTexture1")				
			vertcoords = glGetAttribLocation(shader_id, "aVertcoords")	
			texcoords0 = glGetAttribLocation(shader_id, "aTexcoords0")
			texcoords1 = glGetAttribLocation(shader_id, "aTexcoords1")
			normals = glGetAttribLocation(shader_id, "aNormals")
			colors = glGetAttribLocation(shader_id, "aColors")
			
			vp_matrix = glGetUniformLocation(shader_id, "vpMatrix") 'uniform
			m_matrix = glGetUniformLocation(shader_id, "mMatrix")'uniform
			For Local i:Int = 0 To 7
				light_pos[i] = glGetUniformLocation(shader_id, "lightPos["+i+"]")
				light_dir[i] = glGetUniformLocation(shader_id, "lightDir["+i+"]")
				light_color[i] = glGetUniformLocation(shader_id, "lightColor["+i+"]")
			Next
		
			
			base_color = glGetUniformLocation(shader_id, "basecolor")
			ambient_color = glGetUniformLocation(shader_id, "ambientcolor")
			shininess = glGetUniformLocation(shader_id, "shininess")
Print vp_matrix+" "+base_color+" "+normals

			flags = glGetUniformLocation(shader_id, "flags")
			texflag = glGetUniformLocation(shader_id, "texflag")
			colorflag = glGetUniformLocation(shader_id, "colorflag")
			lightflag = glGetUniformLocation(shader_id, "lightflag")
			
			If vertcoords <0 Then active=0; Print"**Shader error: vertcoords not initialized."
			If GetGLError() Then Print "*uniform assignment"
					
		Endif
		
	End
	
	
	Function DefaultShader:Void(vp_file:String, fp_file:String) 'Abstract
		''load default shader on init

		g_shader = TShaderGLSL.LoadShader(vp_file, fp_file)
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
	
	
	Function GetGLError:Int()
		Local gle:Int = glGetError()
		If gle<>GL_NO_ERROR Then Print "*glerror: "+gle; Return 1
		Return 0
	End
	
	
End


