'' TShader
'' opengles 2.0

Import opengl.gles20
Import minib3d.tshader
Import minib3d.opengl.framebuffergl


Alias LoadString = app.LoadString

'' NOTES:
'' -- use LinkVariables to specifically use default shader variables, otherwise it won't (FBO display)


Extern

	'' to debug webGL angle shader translastions (needs priveldged code extension activated)
	Function Get_HLSL:String(sh:Int) = "gl.getExtension(~qWEBGL_debug_shaders~q).getTranslatedShaderSource"

Public




Class ShaderUniforms
	
	'' shader variable locations
	
	Field vertcoords:Int 'attrib
	Field texcoords0:Int 'attrib
	Field texcoords1:Int 'attrib
	Field normals:Int 'attrib
	Field colors:Int 'attrib
	
	'' uniforms
	
	Field p_matrix:Int
	Field m_matrix:Int
	Field v_matrix:Int
	
	Field light_type:Int[9]
	Field light_matrix:Int[9]
	Field light_dir:Int[9]
	Field light_color:Int[9]
	Field light_att:Int[9]
	Field light_spot:Int[9]
	
	Field base_color:Int
	Field ambient_color:Int
	Field specular:Int
	Field shininess:Int
	Field fog_color:Int
	Field fog_range:Int
	
	Field flags:Int
	Field texflag:Int
	Field colorflag:Int
	Field lightflag:Int
	Field fogflag:Int
	Field alphaflag:int
	
	
	Field lightpMatrix:Int
	Field lightvMatrix:Int
	Field scaleInv:Int
	
	Field texture:Int[9]
	Field tex_position:Int[9]
	Field tex_scale:Int[9]
	Field tex_rotation:Int[9]
	Field tex_blend:Int[9]
	Field texfx_normal:Int[9]
	
	
	Method Link:Int(shader_id:Int)
		
		vertcoords = glGetAttribLocation(shader_id, "aVertcoords")	
		texcoords0 = glGetAttribLocation(shader_id, "aTexcoords0")
		texcoords1 = glGetAttribLocation(shader_id, "aTexcoords1")
		normals = glGetAttribLocation(shader_id, "aNormals")
		colors = glGetAttribLocation(shader_id, "aColors")
		
		p_matrix = glGetUniformLocation(shader_id, "pMatrix")
		m_matrix = glGetUniformLocation(shader_id, "mMatrix")
		v_matrix = glGetUniformLocation(shader_id, "vMatrix")
		
		For Local i:Int = 0 To 7
			light_type[i] = glGetUniformLocation(shader_id, "lightType["+i+"]")
			light_matrix[i] = glGetUniformLocation(shader_id, "lightMatrix["+i+"]")
			light_color[i] = glGetUniformLocation(shader_id, "lightColor["+i+"]")
			light_att[i] = glGetUniformLocation(shader_id, "lightAtt["+i+"]") ''vec4 = const_att,lin_att,quad_att,range
			light_spot[i] = glGetUniformLocation(shader_id, "lightSpot["+i+"]")
		Next
	
		
		base_color = glGetUniformLocation(shader_id, "basecolor")
		ambient_color = glGetUniformLocation(shader_id, "ambientcolor")
		shininess = glGetUniformLocation(shader_id, "shininess")
		fog_color = glGetUniformLocation(shader_id, "fogColor")
		fog_range = glGetUniformLocation(shader_id, "fogRange")
		
'Print vp_matrix+" "+base_color+" "+normals

		flags = glGetUniformLocation(shader_id, "flags")
		texflag = glGetUniformLocation(shader_id, "texflag")
		colorflag = glGetUniformLocation(shader_id, "colorflag")
		lightflag = glGetUniformLocation(shader_id, "lightflag")
		fogflag = glGetUniformLocation(shader_id, "fogflag")
		alphaflag = glGetUniformLocation(shader_id, "alphaflag")
		
		''shadows.... todo
		
		lightpMatrix = glGetUniformLocation(shader_id, "lightpMatrix")
		lightvMatrix = glGetUniformLocation(shader_id, "lightvMatrix")
		scaleInv = glGetUniformLocation(shader_id, "scaleInv")
		
		For Local i:Int = 0 To 7
			texture[i] = glGetUniformLocation(shader_id, "uTexture["+i+"]")
			tex_position[i] = glGetUniformLocation(shader_id, "texPosition["+i+"]")
			tex_scale[i] = glGetUniformLocation(shader_id, "texScale["+i+"]")
			tex_rotation[i] = glGetUniformLocation(shader_id, "texRotation["+i+"]")
			tex_blend[i] = glGetUniformLocation(shader_id, "texBlend["+i+"]")
			''texfx_normal[i] = glGetUniformLocation(shader_id, "texfxNormal["+i+"]")
		Next
		texfx_normal[0] = glGetUniformLocation(shader_id, "texfxNormal[0]")
		texfx_normal[1] = glGetUniformLocation(shader_id, "texfxNormal[1]")
		
		If vertcoords <0
			Dprint "**uniform assignment error: vertcoords does not exist"
			Return 0
		Endif
		
		Return 1
		
	End
End



Class TShaderGLSL Extends TShader

	Field u:ShaderUniforms
	
	''set these global according to the shader
	Field MAX_LIGHTS = 1
	Field MAX_TEXTURES =1
	
	''internal use
	
	Field use_base_variables:Int=1  ''turn off if default uniforms are not needed
	
	
	Private 
	
	'Global default_shader_id:Int
	Field webgl_shader:Int
	
	Public
	
	
	Method New()
		
		
	End
	
	
	Method Copy:TBrush()
		
		Local brush:TShaderGLSL =New TShaderGLSL
	
		brush.no_texs=no_texs
		brush.name=name
		brush.red=red
		brush.green=green
		brush.blue=blue
		brush.alpha=alpha
		brush.shine=shine
		brush.blend=blend
		brush.fx=fx
		brush.tex[0]=tex[0]
		brush.tex[1]=tex[1]
		brush.tex[2]=tex[2]
		brush.tex[3]=tex[3]
		brush.tex[4]=tex[4]
		brush.tex[5]=tex[5]
		brush.tex[6]=tex[6]
		brush.tex[7]=tex[7]
						
		brush.shader_id = shader_id
		brush.fragment_id = fragment_id
		brush.vertex_id = vertex_id
		brush.u = u
		brush.override = override
		
		brush.active = 1
		TShaderGLSL(brush).LinkVariables()
		brush.active = active
		
		brush.use_base_variables =use_base_variables
		
		Return brush

	End 
	
	
	Function LoadShader:TShaderGLSL(vp_file:String, fp_file:String, sh:TShader=Null)
		
		Local fail:Int=0
		Local shader:TShaderGLSL
		
		If sh<>Null
			shader = TShaderGLSL(sh)
		Else
			shader = New TShaderGLSL
		Endif
		
		Local vs:Int = shader.CompileShader(LoadString(vp_file),GL_VERTEX_SHADER)
		Local fs:Int = shader.CompileShader(LoadString(fp_file),GL_FRAGMENT_SHADER)
		If (vs) And (fs)

			If Not shader.LinkShader() Then fail=1
			
		Else
			fail = 1
		Endif
		
		If Not fail
			Print "..shader success: "+vp_file+" "+fp_file
		Else		
			Print "**compiler error: "+vp_file+" "+vs+", "+fp_file+" "+fs
		Endif

		Return shader
	End
	
	Method LinkShader:Int()
		
		''bind shader
		shader_id = glCreateProgram()
		If shader_id<0 Then Print"**Shader Program not created."
		
		glAttachShader(shader_id, vertex_id)
		glAttachShader(shader_id, fragment_id)
'Print shader.shader_id+" "+shader.vertex_id+" "+shader.fragment_id
	
		glLinkProgram(shader_id)

		Local result:Int[1]
		glGetProgramiv(shader_id, GL_LINK_STATUS, result)
		
		Local log:String
		log = glGetProgramInfoLog(shader_id)
		If TRender.DEBUG Then Print log
		
		
			'log = glGetShaderSource(webgl_shader)
			'If TRender.DEBUG Then Print log
		
		If result[0] <> GL_TRUE
			Print "**Shader Linking Error "
			
			log = glGetProgramInfoLog(shader_id)
			If TRender.DEBUG Then Print log
			
			glDeleteShader(vertex_id)
			glDeleteShader(fragment_id)
			glDeleteProgram(shader_id)

			
			vertex_id=0; fragment_id=0; shader_id=0

			Return 0
		Endif
		
		active=1
		
		''create uniforms
		u = New ShaderUniforms
		LinkVariables()
		
		Return 1
	End
	
	'' type = GL_VERTEX_SHADER, GL_FRAGMENT_SHADER
	''
	Method CompileShader:Int(source:String, type:Int)
		
		If source.Length() <2
			Print "**Shader file not found"
			Return 0
		Endif
		
		''Create GLSL Shader
		''WebGL returns a shader obj
		Local id:Int = glCreateShader(type)
		webgl_shader = id

		If type = GL_VERTEX_SHADER Then vertex_id = id
		If type = GL_FRAGMENT_SHADER Then fragment_id = id
		
		glShaderSource(id, source )
		glCompileShader(id)	
	
		Local result:Int[1]
		glGetShaderiv(id, GL_COMPILE_STATUS, result)
		
		''for debugging webgl angle hlsl transalations, must have the priveledged extensions flag on
		'Local ss:String = Get_HLSL(id)
		'Print "---- HLSL ---- ~n"+ss
	
		If result[0] <> GL_TRUE
			Local log:String
			log = glGetShaderInfoLog(id)
			Print log
			Print "**Shader Compile Error "+result[0]
				
			'glGetShaderiv(id, GL_INFO_LOG_LENGTH, result)	
			'Print "log length "+result[0]
				
			glDeleteShader(id)
			If type = GL_VERTEX_SHADER Then vertex_id = 0 Else fragment_id = 0
			
			Return 0
		Endif
		
		Return 1
		
	End
	

	Method LinkVariables()
	
		If active
		
			''use LinkVariables to specifically use default shader variables
			use_base_variables =1
							
			active = u.Link(shader_id) ''return 0 if link error
			
			If GetGLError() Then Dprint "** uniform assignment"
					
		Endif
		
	End
	
	
	Function LoadDefaultShader:Void(vp_file:String, fp_file:String) 'Abstract
		''load default shader on graphics init

		default_shader = TShaderGLSL.LoadShader(vp_file, fp_file)
		default_shader.name = "DefaultShader"
		SetShader( default_shader )
		
		
	End
	
	
	Function GetGLError:Int()
		Local gle:Int = glGetError()
		If gle<>GL_NO_ERROR Then Print "*glerror: "+gle; Return 1
		Return 0
	End
	
	
End



Class DefaultShader Extends TShaderGLSL

	Method New()
		
		shader_id = default_shader.shader_id
		If shader_id
			active = 1
			LinkVariables()
		Endif
		
	End

	
End


