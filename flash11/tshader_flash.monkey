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
	Field n_matrix:int
	
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
	Field miscflag:Int ''fog, etc... BOTH FRAG AND VERT
	'Field fragflag:Int ''fragment only!
	
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
		
		vertcoords = 0	
		texcoords0 = -1
		texcoords1 = -1
		normals = -1
		colors = 1
		
		p_matrix = 0
		m_matrix = -1
		'v_matrix = glGetUniformLocation(shader_id, "vMatrix")

#rem		
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
#end		
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
	
	Field program_set:Program3D ''main pointer to use
	Field vertex_assembly:AGALMiniAssembler
	Field fragment_assembly:AGALMiniAssembler
	Field vertex_code:AGALPointer
	Field fragment_code:AGALPointer
	

	
	Private 
	
	Global g_id:Int=0
	
	Public
	

	
	Method New(vp$="", fp$="")
		
		driver = FlashMiniB3D.driver
		If vp<>"" And fp<>""
			TShaderFlash.LoadShaderString(vp, fp, Self)
			
			'shader_id = default_shader.shader_id
			If shader_id
				active = 1
				'LinkVariables()
			Endif
		Endif
		
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
	
	
	Method FreeShader:Int()
		vertex_id=0; fragment_id=0; shader_id=0
	End
	
	
	Method ResetShader:Int()
		
	end
	
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
		
		Try
			program_set.Upload( vertex_code, fragment_code )
		Catch e:FlashError
			Print e.ToString()
			Error ""
		End
		
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
		verbose = False 'True ''too much data dump if enabled
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
	End
	
#rem
	Method LinkVariables()
	
		If active
		
			''use LinkVariables to specifically use default shader variables
			use_base_variables =1
			'u.Link(shader_id)
			Link(shader_id)
			active = 1 'u.Link(shader_id) ''return 0 if link error
			
			'If GetGLError() Then Dprint "** error: uniform assignment"
					
		Endif
		
	End
#end
	
	Function LoadShaderString:TShaderFlash(vp:String, fp:String, shader:TShaderFlash=null)
		
		Local fail%=1
		'Local shader:TShaderFlash
		
		If Not shader Then shader = New TShaderFlash
		
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
	

	
End



'' FLash Shaders
''
'' the thought would be to create a matrix of shaders in groups
'' - 0 to 1 textures+ 5 blends, 2-4 textures + 5 blends
'' - 0 lights, 1 light x 3 types, 2-4 lights x3types
'' - texture clamp, texture repeat
'' .... or compile on-demand, but no WP8
'' ... or.... for lighting, 0-1 lights in main shader, 2+lights in multi-pass using additive blend

Class MultiShader Extends TShaderFlash
	
	Global init:Bool = False
	
	Field shader:TShaderFlash[8]
	
	Method New()
		If init Then Return
		init = True
		
		ResetShader()
		
	End
	
	Method FreeShader()
		Super.FreeShader
		init=false
	End
	
	Method ResetShader()
		
		shader[0] = New FullBrightOneTexShader("clamp")
		shader[1] = New FullBrightOneTexShader("repeat")
		shader[2] = New OneLightOneTexShader("clamp")
		shader[3] = New OneLightOneTexShader("repeat")
		
	End
	
	
	Method GetShader:TShaderFlash(i:int)
		
		Return shader[i]
		
	End
	
End

Class OneLightOneTexShader Extends TShaderFlash
	#rem
	Global TestVP$ ="m44 op, va0, vc0~n" + '' pos to clipspace
				"mov v0, va1" '' copy color
	
	Global TestFP$ = "mov oc, v0" 
	#end

	
	Global VP:String =
			'' copy attribs into varying v0,v1, vert pos into vt1
			"m44 vt1, va0, vc0~nmov v0, va1~nmov v1, va2~n"+
			
			
			'' vert normal = vt3
			"m44 vt3, va3.xyz, vc8~nnrm vt3.xyz, vt3.xyz~n"+ ''vt3 = vert normal
			''pointlight1 into vt0
			"mov vt4.x, vc12.w~nmov vt4.y, vc13.w~nmov vt4.z, vc14.w~n"+ ''re-use vt4 for directional light
			"m44 vt0, va0, vc4~nsub vt0, vt4.xyz, vt0.xyz~n"+
			'"dp3 vt0.xyz, vt0.xyz, vt3.xyz~nabs vt0.xyz, vt0.xyz~nsat vt0.xyz, vt0.xyz~n"+ ''LdotN
			
			''directional light into vt7
			"m44 vt7, vt4.xyz, vc12~n"+
			
			'' distance = vt5
			"dp3 vt5, vt0.xyz, vt0.xyz~nsqt vt5,vt5~n"+
			''light attenuation for LdotN = vt6
			"mul vt6.x, vc27.y, vt5~nadd vt6.x, vc27.x, vt6.x~nrcp vt6.x,vt6.x~n"+ 'd = (spotlight ) / (  lightAtt[i].x + (lightAtt[i].y* dist)  )
			''set vt6.x to one if lightflag=1 (reusing vt5)
			"mov vt5.x, vc26.y~nadd vt5.x, vt5.x, vc26.z~nmul vt6.x, vt6.x, vt5.x~n"+
			''ugh... this will set vt6.x to 1 if the above is 0, but will leave vt6 alone if not
			"mov vt5.x, vc26.x~nsge vt5.x, vt5.x, vc26.y~nadd vt6.x, vt6.x, vt5.x~n"+
			
			''choose the lightflag
			"mul vt7, vt7, vc26.xxxx~n"+
			"mul vt0, vt0, vc26.yyyy~n"+
			"add vt0, vt7, vt0~n"+ ''add in the remainder
			'"nrm vt0.xyz, vt0.xyz~n"+ ''this ruins the light, not sure why
			
			''LdotN
			"dp3 vt0.xyz, vt0.xyz, vt3.xyz~n"+
			"mul vt0.xyz, vt0.xyz, vt6.xxx~n"+"sat vt0.xyz, vt0.xyz~n"+ 
			
			''ambient light
			"max vt0.xyz, vt0.xyz, vc17.xyz~n"+
			'"mov v2, vt0.xyz~n"+
			'' base color
			"max vt3, vc18.xxxx, va1.xyzw~n"+ ''vc18=one-minus colorflag = 1111 for use basecolor
			"mul vt3, vc16.xyzw, vt3.xyzw~n"+ ''vc16=base color=1111 for use vertex color
			''light color
			"mul vt3.xyz, vt3.xyz, vc22.xyz~n"+ 			
			
			''final_light+final_color
			"mul v0, vt3.xyz, vt0.xyz~n"+
			"mov v0.w, vt3.w~n"+ ''make sure proper alpha gets through
			
			"mov op, vt1~n"+
			"~n"
			
	'Global TestFP:String = "tex ft1, v2, fs0 <2d, nearest, mipnearest>~nmov oc, ft1"
	
	Global FP:String =
			"tex ft1, v1, fs0 <2d,TEXTURE_WRAP,linear>~n"+ ''texture
			"ALPHATEST"+
			"mul ft2, ft1, v0~n"+ 'color+light
			"mov oc, ft2~n"

			'"mov oc, ft1~n"
			'"mov ft2, ft1~n"
	
	Global alphaTest:String="sub ft3.x ft1.w fc25.x~nkil ft3.x~n"
	
	''this should be moved up to TShaderFlash, but keep here for now
	Method LinkVariables:Int()
		
		active=1
		
		u.vertcoords = 0	
		u.texcoords0 = 2
		u.texcoords1 = -1
		u.normals = 3
		u.colors = 1
		
		'' constants
		u.p_matrix = 0 '0,1,2,3
		u.m_matrix = 4 '4,5,6,7
		u.n_matrix = 8 '8'9'10'11
		u.light_matrix[0] = 12 '12,13,14,15
		u.base_color = 16
		u.ambient_color = 17
		u.light_color[0] = 22
		
		u.tex_position[0] = 23 'x,y, cos, sin
		u.tex_scale[0] = 24 'scalex y
		u.tex_blend[0] = 1 'frag tex_blend
		
		'' flags
		u.colorflag = 18 '' x=use basecolor
		u.miscflag = 25 '' used on BOTH frag and vertex
		u.lightflag = 26
		
		u.light_att[0] = 27 
		u.light_spot[0] = 28 
		
	end
	
	Method New(tex_clamp$, vp$=VP, fp$=FP)
		
		'' find, replace
		fp = StringReplace("TEXTURE_WRAP",tex_clamp,fp)
		fp = StringReplace("ALPHATEST",alphaTest,fp)
		
		driver = FlashMiniB3D.driver
		If vp<>"" And fp<>""
			TShaderFlash.LoadShaderString(vp, fp, Self)
			
			'shader_id = default_shader.shader_id
			If shader_id
				active = 1
				'LinkVariables()
			Endif
		Endif
		
	End

	
End

Class FullBrightOneTexShader Extends OneLightOneTexShader
	
	Global VP:String =
			'' copy attribs into varying
			"m44 vt1, va0, vc0~nmov v0, va1~nmov v1, va2~n"+
			
			
			''pointlight1
			"mov vt0, va3~n"+
			"mov vt0, vc4~n"+
			"mov vt0, vc8~n"+
			'"m44 vt3, va3.xyz, vc8~nnrm vt3.xyz, vt3.xyz~n"+
			'"mov vt0.x, vc12.w~nmov vt0.y, vc13.w~nmov vt0.z, vc14.w~nm44 vt4, va0, vc4~nsub vt0, vt0.xyz, vt4.xyz~nnrm vt0.xyz, vt0.xyz~n"+
			'"dp3 vt0.xyz, vt0.xyz, vt3.xyz~nsat vt0.xyz, vt0.xyz~nmov v2, vt0.xyz~n"+
			
			'' base color
			'"mul vt3, vc18.xxxx, va1~n"+ ''colorflag
			"max vt3, vc18.xxxx, va1.xyzw~n"+ ''vc18 = one-minus colorflag 
			'"mov vt3, va1~n"+
			"mul v0, vc16, vt3~n"+ ''vc16=base color=1111 for use vertex color
			''preserve alpha
			'"mov v0.w, vc16.w~n"+
			"mov v0.w, vt3.w~n"+ ''make sure proper alpha gets through
			
			''texture sampler adjust
			''(texcoord[0]).x = ((aTexcoords0.x + pos.x) * cosang - (aTexcoords0.y + pos.y) * sinang)*scale.x;
			"add vt0.x, vc23.x, va2.x~nmul vt0.x, vc23.z, vt0.x~n"+
			"add vt0.y, va2.y, vc23.y~nmul vt0.y, vc23.w, vt0.y~n"+
			"sub vt0.x, vt0.x, vt0.y~nmul v1.x, vc24.x, vt0.x~n"+
			''(texcoord[0]).y = ((aTexcoords0.x + pos.x) * sinang + (aTexcoords0.y + pos.y) * cosang)*scale.y;
			"add vt0.x, vc23.x, va2.x~nmul vt0.x, vc23.w, vt0.x~n"+
			"add vt0.y, va2.y, vc23.y~nmul vt0.y, vc23.z, vt0.y~n"+
			"add vt0.x, vt0.x, vt0.y~nmul v1.y, vc24.y, vt0.x~n"+
			
			
			"mov op, vt1~n"+
			"~n"
			
	
	Global FP:String =
			"tex ft1, v1, fs0 <2d,TEXTURE_WRAP,linear>~n"+ ''texture
			
			''texture blend
			 
			
			"mov ft2, v0~n"+ 'move color in for tinting
			"mul ft2, ft1, ft2~n"+
			"ALPHATEST"+
			"mov oc, ft2~n"

			'"mov oc, ft1~n"
			'"mov ft2, ft1~n"

	Global alphaTest:String="sub ft3.x ft1.w fc25.x~nkil ft3.x~n"
	
	Method LinkVariables:Int()
		Super.LinkVariables()
		u.light_matrix[0] = -1
		u.light_color[0] = -1
	End
	
	Method New(tex_clamp$, vp$=VP, fp$=FP)
	
		'' find, replace
		fp = StringReplace("TEXTURE_WRAP",tex_clamp,fp)
		fp = StringReplace("ALPHATEST",alphaTest,fp)
				
		driver = FlashMiniB3D.driver
		If vp<>"" And fp<>""
			TShaderFlash.LoadShaderString(vp, fp, Self)
			
			'shader_id = default_shader.shader_id
			If shader_id
				active = 1
				'LinkVariables()
			Endif
		Endif
	End
	
	
End

Function StringReplace:String(r$, n$, st$)
	Local a:String[] = st.Split(r)
	If a.Length=2 Then st= a[0]+n+a[1] Else Print"**Shader error: string replace"
	Return st
End
