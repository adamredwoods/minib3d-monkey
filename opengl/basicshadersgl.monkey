Import opengl.gles20
Import tshaderglsl

''Shaders provided under minib3d license
''(C) 2012 Adam Piette


'' BlurFBO/Texture0 Shader

Class BlurShader Extends TShaderGLSL
	
	Field fbo:FrameBufferGL
	
	Const VERTP:String = "attribute vec3 aVertcoords;attribute vec2 aTexcoords0;uniform mat4 pMatrix;uniform mat4 mMatrix;varying vec2 vUv; void main(){gl_Position = (pMatrix * mMatrix) * vec4(aVertcoords, 1.0);vUv = aTexcoords0;}"
	
	Const FRAGP:String = "#ifdef GL_ES ~n precision highp float;~n #endif ~n uniform vec2 TexelSize;uniform sampler2D uTexture[1];uniform int Orientation;uniform int BlurAmount;varying vec2 vUv;float Gaussian (in float x, in float deviation){ return ((1.0 / sqrt(2.0 * 3.141592 * deviation)) * exp(-(x * x) / (2.0 * deviation)) ); }"+
	" void main(){ float halfBlur = (float(BlurAmount) * 0.5); float deviation = (float(halfBlur) * 0.5); vec4 colour = vec4(0.0,0.0,0.0,0.0);"+
	" if ( Orientation==0 ){ for (int i = 0; i < 10; ++i) {if ( i < BlurAmount ){float offset = float(i) - halfBlur*2.0; float posx = clamp(vUv.x + offset * TexelSize.x ,0.0,1.0); colour += texture2D(uTexture[0], vec2(posx, vUv.y) )/**Gaussian(offset, deviation)*/; }}}"+
	" else { for (int i = 0; i < 10; ++i){ if ( i < BlurAmount ) {float offset = float(i) - halfBlur; float posy = clamp(vUv.y + offset * TexelSize.y ,0.0,1.0); colour += texture2D(uTexture[0], vec2(vUv.x, posy) )/**Gaussian(offset, deviation)*/; }}};   gl_FragColor = (colour/float(BlurAmount));}"

	
	Field texelsize:Float[]
	Field orientation:Int =0'0=x blur, 1=y blur
	Field blur:Int = 5
	
	Field uniform:Int[5]
	
	Global init_id:Int=0		
	Global global_uniforms:ShaderUniforms
	
	Method New()
			
		name ="BlurShader"
		
		If( init_id=0 And shader_id=0 And CompileShader(VERTP,GL_VERTEX_SHADER) And CompileShader(FRAGP,GL_FRAGMENT_SHADER) )
		
			LinkShader()
			LinkVariables()
			
			init_id = shader_id
			global_uniforms = u
			Dprint "..BlurShader success"
			
		Else If init_id
		
			shader_id = init_id ''use same shader
			u = global_uniforms ''use same uniforms
			active = 1
			
		Endif
		
		uniform[0] = glGetUniformLocation(shader_id, "TexelSize")
		uniform[1] = glGetUniformLocation(shader_id, "Orientation")
		uniform[2] = glGetUniformLocation(shader_id, "BlurAmount")
		
	End
	
	Method Update()
		
		If Not texelsize[0] And fbo Then texelsize = [1.0/fbo.texture.width,1.0/fbo.texture.height]
		
		If uniform[0]<>-1 Then glUniform2fv( uniform[0], 1, texelsize )
		If uniform[1]<>-1 Then glUniform1i( uniform[1], orientation )
		If uniform[2]<>-1 Then glUniform1i( uniform[2], blur )
		
		If TRender.DEBUG And GetGLError() Then Dprint "*uniform assignment error blurshader"
		
	End
	
	Method SetFBO(fbo2:FrameBuffer)
	
		fbo=fbo2
		
	End

	
End


Class FastBrightShader Extends TShaderGLSL

	Const VERTP:String = "attribute vec3 aVertcoords;attribute vec2 aTexcoords0; attribute vec4 aColors; uniform mat4 pMatrix;uniform mat4 vMatrix;uniform mat4 mMatrix;varying vec2 texcoord[1];"+
		" uniform float colorflag; uniform vec4 basecolor; uniform vec2 texPosition[1],  texScale[1], texRotation[1]; uniform float texflag; varying vec4 vertColor; varying vec2 varTex;"+
		" void main(){ gl_Position = (pMatrix*mMatrix ) * vec4(aVertcoords, 1.0); vertColor = mix(basecolor , aColors, colorflag);"+
		" vec2 scale = texScale[0];float cosang = texRotation[0].x; float sinang = texRotation[0].y; vec2 pos = texPosition[0]/scale;"+
		" (texcoord[0]).x = ((aTexcoords0.x + pos.x) * cosang - (aTexcoords0.y + pos.y) * sinang)*scale.x; (texcoord[0]).y = ((aTexcoords0.x + pos.x) * sinang + (aTexcoords0.y + pos.y) * cosang)*scale.y;"+
		" varTex.x = step(1.0,texflag); varTex.y = step(2.0,texflag);"+
		" ~n} "
	Const FRAGP:String = "#ifdef GL_ES ~n precision mediump float; ~n #endif ~n uniform sampler2D uTexture[2]; uniform vec4 ambientcolor;"+
		" varying vec2 texcoord[1]; varying vec4 vertColor; varying vec2 varTex; const vec4 all_ones=vec4(1.0,1.0,1.0,1.0);"+
		" void main(){  gl_FragColor= vec4(ambientcolor.xyz,0.0) + mix(vertColor, vertColor * texture2D( uTexture[0],texcoord[0] ) * mix(all_ones,texture2D( uTexture[1],texcoord[0] ),varTex.y), varTex.x );"+
		" ~n} "
	'Field uniform:Int[5]
	
	Global init_id:Int=0		
	Global global_uniforms:ShaderUniforms
	
	Method New()
			
		name ="FastBrightShader"
		
		If( init_id=0 And shader_id=0 And CompileShader(VERTP,GL_VERTEX_SHADER) And CompileShader(FRAGP,GL_FRAGMENT_SHADER) )
			LinkShader()
			LinkVariables()
			global_uniforms = u
			init_id = shader_id
			Dprint "..FastBrightShader success"
			
		Else If init_id
		
			shader_id = init_id ''use same shader
			u = global_uniforms ''use same uniforms
			active = 1
			
		Endif
		
	End
	
	Method Update()
		
		'If GetGLError() Then Print "*glerror fastbrightshader"
	End
	
End



Class GlowShader Extends TShaderGLSL Implements IShaderEntity
	
	Field fbo:FrameBufferGL, fbo2:FrameBufferGL
	
	Field blurshader:BlurShader, fastbright:FastBrightShader
	Field r:Int
	
	Field draw_cache:TMesh[20]
	Field cache_total:Int=0
	
	Method New()

		AddProcess(Self)
		'SetShader(Self)
		
		blurshader = New BlurShader()
		fastbright = New FastBrightShader()
		
		fbo = FrameBufferGL.CreateFBO(CreateTexture(256,256,3))
		fbo2 = FrameBufferGL.CreateFBO(CreateTexture(256,256,3))
		blurshader.texelsize=[1.0/256,1.0/256]
		
		active = 1
		
	End
	
	Method PreProcess(cam:TCamera)
		'Print 123
		fbo.Clear(1)
		fbo2.Clear(1)
	End
	
	Method PostProcess(cam:TCamera)
		'Print 456
		
		
	End
	
	Method RenderEntity:Void(cam:TCamera, ent:TEntity)

		'blurshader.blur = 4
		
		''copy depth from mainbuffer
		
		
		fbo.BeginFBO()
		DefaultShader()
		'glClear(GL_COLOR_BUFFER_BIT)
		
				
		'SetShader(fastbright)
		''update camera, dont clear
		
		
		ent.EntityAlpha(0.999999)
		ent.classname = "test"
		
		DrawEntity(cam,ent)	
		fbo.EndFBO()
		
		fbo2.BeginFBO()
		blurshader.orientation =0
		SetShader(blurshader)
		'SetShader(fastbright)
		fbo.Draw(cam, 1.0)
		fbo2.EndFBO()
		Local dist2:Float
		Local dist# = Sqrt(cam.EntityDistanceSquared(ent)) '*2.0 / (cam.range_far - cam.range_near)
		''dist = (dist*(2.0*cam.range_far *cam.range_near) )/(cam.range_far - cam.range_near) - (dist*(cam.range_far + cam.range_near) / (cam.range_far - cam.range_near))
		''dist = -dist * ( (cam.range_far + cam.range_near) / (cam.range_far - cam.range_near) ) + dist*((2.0*cam.range_far *cam.range_near) / (cam.range_far - cam.range_near))
		''' (in_z * p_33 - 1) / (in_z * p_34)
		''dist = ((cam.range_far + cam.range_near  )/ (cam.range_far - cam.range_near)) -((2.0*cam.range_far * cam.range_near) / (dist*(cam.range_far - cam.range_near)) )
		'dist = (  ( (cam.range_far + cam.range_near  ) + (2.0*cam.range_far * cam.range_near) ) / (-dist *(cam.range_far - cam.range_near)) ) 
		'dist = (dist+1.0)*0.5
		dist2 = dist '1.0-(2.0 * dist - cam.range_near - cam.range_far) / (cam.range_far - cam.range_near);
		'dist2 = (dist - cam.range_near) / (cam.range_far - cam.range_near)  '* ( dist*(cam.range_far + cam.range_near)/(cam.range_far - cam.range_near) + (dist*(2.0*cam.range_far * cam.range_near) / (dist*(cam.range_far - cam.range_near))) )
		
		Print "dist: "+dist+" "+dist2
		
		'Print cam.CameraProject(0,0,dist).z
		
		'fbo.Clear(1)
		'fbo.BeginFBO()
		blurshader.orientation =1
		'SetShader(blurshader)
		fbo2.Draw(cam, 1.0, dist)
		'fbo.EndFBO()
		
		'SetShader(fastbright)
		'fbo.Draw(cam, 1.0, 1.0)
		
		'SetShader(fastbright)
		'fbo.Draw(cam,1.0)
		
		
		DefaultShader()
		'DrawEntity(cam,ent)
	End
	
	Method Update()
	End
	
End

