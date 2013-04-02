'' TShader
'' opengles 2.0

Import minib3d.flash11.flash11_driver
Import minib3d.tshader
'Import minib3d.flash11.framebuffer_flash


Alias LoadString = app.LoadString

'' NOTES:
'' -- use LinkVariables to specifically use default shader variables, otherwise it won't (FBO display)





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



Class TShaderFlash Extends TShader
	
	Const VERTEX_SHADER:Int=1
	Const FRAGMENT_SHADER:Int=2
	
	Global driver:Driver ''set via flash11.monkey
	
	Field u:ShaderUniforms
	
	''set these global according to the shader
	Field MAX_LIGHTS = 1
	Field MAX_TEXTURES =1
	
	''internal use
	
	Field use_base_variables:Int=1  ''turn off if default uniforms are not needed
	
	Field program_set:Program3D
	Field vertex_assembly:AGALMiniAssembler
	Field fragment_assembly:AGALMiniAssembler
	Field vertex_code:AGALPointer
	Field fragment_code:AGALPointer
	

	
	Private 
	
	Global g_id:Int=0
	
	Public
	
	
	Method New()
		
		driver = FlashMiniB3D.driver
		
	End
	
	
	Method Copy:TBrush()
		
		Local brush:TShaderFlash=New TShaderFlash
	
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
		TShaderFlash(brush).LinkVariables()
		brush.active = active
		
		brush.use_base_variables =use_base_variables
		
		Return brush

	End 
	
	
	Function LoadShader:TShaderFlash(vp_file:String, fp_file:String, sh:TShader=Null)
		
		Local fail:Int=0
		Local shader:TShaderFlash
		
		If sh<>Null
			shader = TShaderFlash(sh)
		Else
			shader = New TShaderFlash
		Endif
		
		Local vs:Int = shader.CompileShader(LoadString(vp_file),VERTEX_SHADER)
		Local fs:Int = shader.CompileShader(LoadString(fp_file),FRAGMENT_SHADER)
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
		program_set = driver.CreateProgram()
		
		'Try
			program_set.Upload( vertex_code, fragment_code )
		'Catch e:FlashError
			'Print e.ToString()
		'End
		
		Try
		
			driver.SetProgram( program_set )
			
		Catch e:FlashError
		
			Print e.ToString()
			
			vertex_id=0; fragment_id=0; shader_id=0

			Print"**Error: Program Link not created."; Return 0
		End

		
		active=1
		
		''create uniforms
		u = New ShaderUniforms
		LinkVariables()
		
		Return 1
	End
	
	'' type = VERTEX_SHADER, FRAGMENT_SHADER
	''
	Method CompileShader:Int(source:String, type:Int)
		
		If source.Length() <2
			Print "**Shader file not found"
			Return 0
		Endif

		Local verbose:Bool = False
		
#if CONFIG="debug"
		'verbose = True
#endif

		Local result:AGALPointer
		
		If type = VERTEX_SHADER
		
			vertex_id = g_id
			vertex_assembly = New AGALMiniAssemblerDebug() ''add true for debugging
			vertex_code = vertex_assembly.Assemble( DRIVER_VERTEX_PROGRAM, source, verbose  )
			result = vertex_code
			
		Endif
		
		If type = FRAGMENT_SHADER
		
			fragment_id = g_id
			fragment_assembly = New AGALMiniAssemblerDebug()
			fragment_code = fragment_assembly.Assemble( DRIVER_FRAGMENT_PROGRAM, source, verbose )
			result = fragment_code
			
		Endif
		
		Local ll% = result.Length
		'Print ll
		
		If Not result

			Print "**Shader Compiler Error"

			If type = VERTEX_SHADER Then vertex_id = 0 Else fragment_id = 0
			
			Return 0
		Endif
		
		g_id+=1
		
		Return 1
		
	End
	

	Method LinkVariables()
	
		If active
		
			''use LinkVariables to specifically use default shader variables
			use_base_variables =1
							
			active = 1 'u.Link(shader_id) ''return 0 if link error
			
			'If GetGLError() Then Dprint "** error: uniform assignment"
					
		Endif
		
	End
	
	Function LoadShaderString:TShaderFlash(vp:String, fp:String)
		
		Local fail%=1
		Local shader:TShaderFlash = New TShaderFlash
		
		Local vs:Int = shader.CompileShader(vp,VERTEX_SHADER)
		Local fs:Int = shader.CompileShader(fp,FRAGMENT_SHADER)
		If (vs) And (fs)
		
			If TRender.DEBUG Then Print "..shader compile success"
			
			If shader.LinkShader() Then fail=0

		Endif
		
		If Not fail
			'Print "..shader success"
		Else		
			Print "**compiler error"
		Endif

		Return shader
		
	End
	
	Function LoadDefaultShader:Void(vp_file:String, fp_file:String) 'Abstract
		''load default shader on graphics init

		default_shader = TShaderFlash.LoadShader(vp_file, fp_file)
		default_shader.name = "DefaultShader"
		SetShader( default_shader )
		
		
	End
	
	
	Function GetError:Int()
		'Local gle:Int = glGetError()
		'If gle<>GL_NO_ERROR Then Print "*glerror: "+gle; Return 1
		'Return 0
	End
	
	
	'Global TestVP:String = "m44 op, va0, vc0~nmov v0, va1"
	'va0 = pos.xyz
	'va1,v0 = norm.xyz
	'va2,v1 = color.argb
	'va3,v2 = uv.xy
	Global TestVP:String =
			'"mov vt0, vc0~nmov vt1, vc1~nmov vt2, vc2~nmov vt3, vc3~n"+
			'"mul vt0, vt0, vc4~nmul vt1, vt1, vc5~nmul vt2, vt2, vc6~nmul vt3, vt3, vc7~n"+
			'''"mul vt0, vc4, vt0~nmul vt1, vc5, vt1~nmul vt2, vc6, vt2~nmul vt3, vc7, vt3~n"+
			"m44 op, va0, vc0~nmov v0, va1~nmov v1, va2~nmov v2, va3~n"
	
	'Global TestFP:String = "tex ft1, v2, fs0 <2d, nearest, mipnearest>~nmov oc, ft1"
	Global TestFP:String =
			"tex ft1, v2, fs0 <2d,clamp,linear>~n"+
			'"mul oc, ft1, v1~n"+
			"mov oc, ft1~n"+
			"mov ft2, v0~n"
			
	'Global TestFP$ = "mov oc, v1" 
	
End



Class DefaultShader Extends TShaderFlash

	Method New()
		
		shader_id = default_shader.shader_id
		If shader_id
			active = 1
			LinkVariables()
		Endif
		
	End

	
End


