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


Class FullShader Extends TShaderGLSL
	
	Global init_id:Int=0		
	Global global_uniforms:ShaderUniforms
	Global shader:TShaderGLSL[10]
	Global fastbrightshader:TShaderGLSL
	
	Method New()
	
		MAX_TEXTURES = 4
		MAX_LIGHTS = 1
		
		name ="FullShader"
		
		If( init_id=0 And shader_id=0)
			
			shader[0] = New MultiShader(0,1,0)
			shader[1] = New MultiShader(1,1,0)
			shader[2] = New MultiShader(0,1,1)
			shader[3] = New MultiShader(1,1,1)
			shader[4] = New MultiShader(0,1,2)
			shader[5] = New MultiShader(1,1,2)
			shader[6] = New MultiShader(0,1,3)
			shader[7] = New MultiShader(1,1,3)
			shader[8] = New MultiShader(0,1,4)
			shader[9] = New MultiShader(1,1,4)
			
			init_id = shader[0].shader_id
			shader_id = shader[0].shader_id
			
			If shader[0].active Then Dprint "..FullShader success"
			active = shader[0].active
			
		Else If init_id
		
			shader_id = init_id ''use same shader
			u = global_uniforms ''use same uniforms
			active = 1
			
		Endif
		
		fastbrightshader = New FastBrightShader()
		
	End
	
	Function GetShader:TShaderGLSL(ppl:Int=0, num_lights:Int=1, num_texs:Int=0)
		Return shader[2*num_texs+ppl]
	End
	
	Method Update()
		
		'If GetGLError() Then Print "*glerror fastbrightshader"
	End
End



Class MultiShader Extends TShaderGLSL
	
	''notes:
	''LOWP, MEDP are causing matrix problems on android
	
	Global LightVars$ = "uniform vec4 lightColor[2];uniform vec4 lightAtt[2];const vec3 LIGHTUNIT = vec3(0.0,0.0,-1.0);uniform float shininess;"
	
	
	Global VERTP0:String = "/*generic opengl 2.0 shader*/ ~n"+
	"#ifdef GL_ES ~n precision highp float; ~n#endif ~n"+
	"attribute vec2 aTexcoords0, aTexcoords1;attribute vec3 aVertcoords;attribute vec3 aNormals;attribute vec4 aColors;uniform mat4 pMatrix, vMatrix, mMatrix;"+
	"/*light*/ uniform float lightType[2];uniform mat4 lightMatrix[2];uniform vec3 lightSpot[2]; /*x=outercutoff,y=innercutoff,z=spot exponent*/ "+
	"/*color*/ uniform vec4 basecolor; uniform float colorflag, lightflag; "+
	"/*texture*/ uniform vec2 texPosition[5],  texScale[5]; uniform vec2 texRotation[5]; uniform float texflag; uniform float texfxNormal[2];"+
	"uniform vec3 scaleInv; uniform int fogflag; uniform vec2 fogRange; uniform float vertCoordSet[5];"+
	"varying vec2 texcoord[4]; varying vec4 normal; varying vec4 vertcolor;"+
	"varying vec4 lightVec, halfVec; varying float fogBlend; varying vec3 nmLight;"+
	"const vec4 all_zeros = vec4(0.0,0.0,0.0,0.0);const vec4 all_ones = vec4(1.0,1.0,1.0,1.0);const float LOG2 = 1.442695;const vec2 one_zero = vec2(1.0,0.0); ~n"
	
	Global VERTP1:String = "void main() {"+
	"vec4 lightPos[5]; vec4 vertVec = all_ones; lightPos[0] = vec4(lightMatrix[0][3][0],lightMatrix[0][3][1],lightMatrix[0][3][2],1.0); vec4 specular = all_zeros;"+
	"/*****IMPORTANT: I'm WORKING in WORLD SPACE******* and pMatrix = p*v */"+
	"vertVec = mMatrix * vec4(aVertcoords, 1.0);normal = mMatrix * vec4(aNormals,0.0);"+
	"normal = normalize(normal); float light = lightType[0] * (lightflag>0.0?1.0:0.0); float d = 0.0;float spotlight = 1.0;lightVec = all_ones; /*IMPORTANT! for android, divide by 0 in normalization error*/"+
	"mat3 lightmat = mat3(lightMatrix[0][0].xyz, lightMatrix[0][1].xyz, lightMatrix[0][2].xyz);"+
	"/*halfvec specular*/ halfVec = vec4(normalize((lightPos[0].xyz- vertVec.xyz) + -( vMatrix[3].xyz - vertVec.xyz )) , 0.0);"+
    "if (light == 1.0 ) {lightVec.xyz = lightmat * vec3(0.0,0.0,-1.0); nmLight = normalize(-lightVec.xyz);"+
	"} else if (light == 2.0 ) { lightVec.xyz = vertVec.xyz; nmLight = normalize(lightPos[0].xyz - vertVec.xyz);	"+
	"} else if (light == 3.0 ) { vec3 lightDir = normalize(lightmat * vec3(0.0,0.0,1.0));lightVec.xyz = vertVec.xyz; nmLight = normalize(lightPos[0].xyz - vertVec.xyz);}"+
	"~n"
	
	Global VERTP2:String = ""
	
	#rem
		"/*NORMAL MAPPING ROTATION*/"+
		"/*-- tangent in aColors, cross to find bitangent*/"+
		"if ((texflag > 0.0) && (texfxNormal[0] > 0)) {	vec3 tangent = normalize(mMatrix*aColors).xyz;	vec3 bitangent = normalize( cross(  normal.xyz, tangent.xyz ));	mat3 nmMat = mat3( tangent.x, bitangent.x, normal.x,tangent.y, bitangent.y, normal.y,tangent.z, bitangent.z, normal.z);"+
		"	nmLight = nmMat * nmLight;	}"
	"int j=0; texcoord[0].xy = aTexcoords0.xy; if (texflag>0.0) {"+
		"vec2 scale = texScale[0];float cosang = texRotation[0].x;float sinang = texRotation[0].y;vec2 pos = texPosition[0]/scale;"+
		"(texcoord[0]).x = ((aTexcoords0.x + pos.x) * cosang - (aTexcoords0.y + pos.y) * sinang)*scale.x;(texcoord[0]).y = ((aTexcoords0.x + pos.x) * sinang + (aTexcoords0.y + pos.y) * cosang)*scale.y;"+
		"j++; if (texflag >1.0) {	scale = texScale[1];cosang = texRotation[1].x;sinang = texRotation[1].y;pos = texPosition[1]/scale;"+
			"(texcoord[1]).x = ((aTexcoords0.x + pos.x) * cosang - (aTexcoords0.y + pos.y) * sinang)*scale.x;"+
			"(texcoord[1]).y = ((aTexcoords0.x + pos.x) * sinang + (aTexcoords0.y + pos.y) * cosang)*scale.y;j++; }"+
		"if (texflag >2.0) {vec2 scale = texScale[2];	float cosang = texRotation[2].x;float sinang = texRotation[2].y;vec2 pos = texPosition[2]/scale;"+
			"(texcoord[2]).x = ((aTexcoords0.x + pos.x) * cosang - (aTexcoords0.y + pos.y) * sinang)*scale.x;(texcoord[2]).y = ((aTexcoords0.x + pos.x) * sinang + (aTexcoords0.y + pos.y) * cosang)*scale.y;"+
			"j++;}"+
		"if (texflag >3.0) {scale = texScale[3];cosang = texRotation[3].x;sinang = texRotation[3].y;pos = texPosition[3]/scale;"+
			"(texcoord[3]).x = ((aTexcoords0.x + pos.x) * cosang - (aTexcoords0.y + pos.y) * sinang)*scale.x;(texcoord[3]).y = ((aTexcoords0.x + pos.x) * sinang + (aTexcoords0.y + pos.y) * cosang)*scale.y;"+
			"j++;}}"+
	#end
	
	Method Vert_Texture:String( i:Int)
		
		If i=0 Return "texcoord[0].xy = all_zeros.xy; "
		
		Local str$ = "vec2 scale; float cosang; float sinang; vec2 pos;"
		str += "/*NORMAL MAPPING ROTATION*/"+
		"/*-- tangent in aColors, cross to find bitangent*/"+
		"if ((texflag > 0.0) && (texfxNormal[0] > 0.0)) {	vec3 tangent = normalize(mMatrix*aColors).xyz;	vec3 bitangent = normalize( cross(  normal.xyz, tangent.xyz ));	mat3 nmMat = mat3( tangent.x, bitangent.x, normal.x,tangent.y, bitangent.y, normal.y,tangent.z, bitangent.z, normal.z);"+
		"	nmLight = nmMat * nmLight;	}"
				
		For Local j:Int = 0 To i-1
			str += "texcoord["+j+"].xy = mix(aTexcoords0.xy, aTexcoords1.xy, vertCoordSet["+j+"]);"
			str += "scale = texScale["+j+"]; cosang = texRotation["+j+"].x; sinang = texRotation["+j+"].y; pos = texPosition["+j+"]/scale.xy;"+
			"(texcoord["+j+"]).x = ((texcoord["+j+"].x + pos.x) * cosang - (texcoord["+j+"].y + pos.y) * sinang)*scale.x;"+
			"(texcoord["+j+"]).y = ((texcoord["+j+"].x + pos.x) * sinang + (texcoord["+j+"].y + pos.y) * cosang)*scale.y;"
		
		next
			
		Return str
	End
			
	Global VERTP3:String = "vertcolor = mix (basecolor, aColors, colorflag); vec4 vertpos = pMatrix * vertVec; gl_Position = vertpos; fogBlend = 0.0;"+
	"if (fogflag == 1) {	float fogz = length(vertpos.xyz);fogBlend = (fogz- fogRange.x) / (fogRange.y - fogRange.x);	fogBlend = clamp(fogBlend, 0.0, 1.0);"+
	"}else if (fogflag == 2) {	float fogz = length(vertpos.xyz); float dens = 1.0/ (fogRange.y - fogRange.x);	fogBlend = 1.0-exp2( -dens*(fogz- fogRange.x)* LOG2 );"+
		"fogBlend = clamp(fogBlend, 0.0, 1.0);}else if (fogflag == 3) {	float fogz = length(vertpos.xyz);float ff = (fogz- fogRange.x);	float dens = 1.0/ (fogRange.y - fogRange.x);"+
		"fogBlend = 1.0-exp2( -dens * ff * ff * sign(ff) * LOG2 );fogBlend = clamp(fogBlend, 0.0, 1.0);}"
	
	'' re-using lightVec, beware of order
	Global Vert_Lighting0$ = "lightVec = LightFunction0( all_ones, normal.xyz, specular );"
		
	
	''''''''''''''''''''''
	''''''''''''''''''''''
	'' fragment shader
	
	
	Global FRAGP0:String = "#ifdef GL_ES ~nprecision highp float; ~n~n#endif ~n"+
	"varying vec2 texcoord[4]; varying vec4 normal;varying vec4 vertcolor;varying vec4 lightVec, halfVec; /*using z component for light att  ;spotlight coefficient packed into halfvec.w*/"+
	"varying float fogBlend;varying vec3 nmLight;uniform mat4 mMatrix;"+
	"/*texture*/ uniform float texflag; uniform sampler2D uTexture[5];uniform vec2 texBlend[5];uniform float texfxNormal[2];"+
	"/*light*/uniform float lightflag;"
	
	
	Global FRAGP1:String = "/*material*/"+
	"uniform vec4 ambientcolor;uniform float flags;uniform float alphaflag; uniform vec4 fogColor;"+
	"const vec2 one_zero = vec2(1.0,0.0);const vec4 all_zeros = vec4(0.0,0.0,0.0,0.0);"+
	
	"vec4 BlendFunction(const float blend, const vec4 texture, const vec4 finalcolor, const vec4 vertcolorx) {"+
	"vec4 color = one_zero.yyyy;	"+
	"if (blend ==1.0) {color.xyz = mix(finalcolor.xyz, texture.xyz, texture.w );color.w = vertcolorx.a;	return color;"+
	"} else if (blend ==2.0) { color = (vertcolorx * texture * finalcolor); 	return color;"+
	"} else if(blend==3.0) {	color = (vertcolorx * texture); return finalcolor+color;"+
	"} else if(blend==4.0) {	color = (vertcolorx * texture); return finalcolor+color;"+
	"} return (texture);}"
#rem	
	"vec4 BlendFunction(const float blend, const vec4 texture, const vec4 finalcolor, const vec4 vertcolorx) {"+
	"vec4 color = one_zero.yyyy;	vec4 mod = (vertcolorx * texture);"+
	" color = mix( mix(vec4(finalcolor.xyz,vertcolorx.w), vec4(texture.xyz,vertcolorx.w), texture.w ), (mod * finalcolor), blend-1.0);"+
	"  color = mix( color, mod+finalcolor, blend-2.0);"+
	'"} return color;}"
	" return color; } "
#end
	
	Global FRAGP2:String = "void main () {"+
	" vec4 finalcolor = one_zero.xxxx;vec4 ambient = vec4(ambientcolor.xyz,0.0);vec4 light = one_zero.xxxx;vec4 specular = one_zero.yyyy;"+
	"bool usenormalmap = (texflag > 0.0) && (texfxNormal[0] > 0.0); /*fixes webgl angle bug*/~n"+
	"vec3 N = (( usenormalmap  ) ? (texture2D(uTexture[0],(texcoord[0]).xy).xyz * 2.0 - 1.0) : (normal.xyz));"+
	"light = lightflag>0.0 ? LightFunction0( light, N, specular ) : one_zero.xxxx ; vec4 texture = one_zero.xxxx;"+
	"~n"'+" if (!gl_FrontFacing) { light = light * clamp(dot(lightVec,-normal),0.0,1.0); }~n" ''double-sided poly lighting
	
	#rem
	"if (texflag<1.0) {	finalcolor = vec4(vertcolor.xyz, vertcolor.w);	} else {"+
		"if (texflag >0.0 && !usenormalmap ) {texture = texture2D(uTexture[0], (texcoord[0]).xy); if(texture.a<alphaflag) {discard;};"+
		"finalcolor = BlendFunction(texBlend[0].x, texture, finalcolor, vertcolor);"+
		"}if (texflag >1.0 ) {texture = texture2D(uTexture[1], (texcoord[1]).xy); /* .zw is bad on powerVR, causes dependent texture read*/"+
			"finalcolor = BlendFunction(texBlend[1].x, texture, finalcolor, all_ones);"+
		"}if (texflag >2.0 ) {texture = texture2D(uTexture[2], (texcoord[2]).xy);"+
			"finalcolor = BlendFunction(texBlend[2].x, texture, finalcolor, all_ones);"+
		"}if (texflag >3.0 ) {texture = texture2D(uTexture[3], (texcoord[3]).xy);"+
			"finalcolor = BlendFunction(texBlend[3].x, texture, finalcolor, all_ones);}}"
	#end
	
	Method Frag_Texture:String(i:Int)
		Local str$, clr$
		
		If i=0 Then str= "finalcolor = vertcolor;"
		
		If i>0
		
			str = "if (!usenormalmap) { texture = texture2D(uTexture[0], (texcoord[0]).xy); "+
			"finalcolor = BlendFunction(texBlend[0].x, texture, finalcolor, vertcolor); }"+
			" if(!usenormalmap && (texture.a<alphaflag)) {discard;} /* fix for tegra3 */"
			
			For Local j:Int = 1 To i-1
				str += "texture = texture2D(uTexture["+j+"], (texcoord["+j+"]).xy);"
				str += " finalcolor = BlendFunction(texBlend["+j+"].x, texture, finalcolor, vec4(1,1,1, vertcolor.w) ); "
			Next
		endif
		
		Return str
	End
			
	Global FRAGP3:String = "gl_FragColor = vec4(  mix( ((finalcolor.xyz * light.xyz +specular.xyz) + (finalcolor.xyz * ambient.xyz) ), fogColor.xyz, fogBlend), finalcolor.w );"+	
	"}"
	'Field uniform:Int[5]
	
	
	Global LightingEquation0$ = "vec4 LightFunction0 ( const vec4 lightcolor, const vec3 norm, inout vec4 specular ) {"+
	"const int i=0; /*do per light, webgl restriction*/"+
	"float lambertTerm = 0.0; vec4 shine4 = vec4(shininess,shininess,shininess,shininess);vec3 lightPos= lightMatrix[i][3].xyz;"+
	"float spotlight = 1.0;float dist = 0.0;float d=1.0;"+
	"if (lightType[i] == 1.0) {lightPos= one_zero.yyy; dist = lightAtt[i].w-0.0001;	"+	
		"} else if (lightType[i] == 2.0) {dist = distance(lightPos.xyz , lightVec.xyz);"+
		"} else if (lightType[i] ==3.0) {dist = distance(lightPos.xyz , lightVec.xyz);"+
			"mat3 lightmat = mat3(lightMatrix[i][0].xyz, lightMatrix[i][1].xyz, lightMatrix[i][2].xyz);vec3 lightDir = normalize(lightmat * LIGHTUNIT ).xyz;"+
			"vec3 lightV = lightPos.xyz - lightVec.xyz; spotlight = max(-dot(normalize(lightV), lightDir), 0.0);"+
			"float spotlightFade = clamp((lightSpot[i].x - spotlight) / (lightSpot[i].x - lightSpot[i].y), 0.0, 1.0);spotlight = pow(spotlight * spotlightFade, lightSpot[i].z);};	"+	
	"vec3 L = ( (texflag > 0.0) && (texfxNormal[0] > 0.0) ) ? nmLight : normalize(lightPos.xyz - lightVec.xyz); vec3 N = normalize(norm); float NdotL = clamp(dot(N,L),0.0,1.0);"+
	"if (NdotL > 0.0) {	if (dist > 0.0 && dist < lightAtt[i].w*10.0) {"+
	"if (lightType[i] >1.0) {d = (spotlight ) / (  lightAtt[i].x + (lightAtt[i].y* dist)  ) ;}"+	
	"lambertTerm = clamp(NdotL * d  , 0.0, 1.0) ;"+
	"if (shininess > 0.0) {	specular = pow( max(dot(halfVec.xyz, N) , 0.0), 100.0  ) *  d * shine4;	}}}"+
	"return (lightColor[i] * lambertTerm  );}"
	
	Global Frag_VertexLighting0$ = "vec4 LightFunction0 (const vec4 lightcolor, const vec3 norm, const vec4 specular ) {return lightVec;} "
	Global Frag_LightVars$ = "uniform mat4 lightMatrix[2];uniform float lightType[2];uniform vec3 lightSpot[2];"
	

	'Global init_id:Int=0		
	Global global_uniforms:ShaderUniforms
	
	Method New(ppl:Int, num_lights:Int=1, num_texs:Int=0, debug:Bool=false)
	
		MAX_TEXTURES = 4
		MAX_LIGHTS = 1
		
		name ="FullShader"
		
		Local VP:String, FP:String
		
		If ppl=0
			'' no per pixel lighting
			VP = VERTP0+LightVars+LightingEquation0+VERTP1+VERTP2+Vert_Texture(num_texs)+VERTP3+Vert_Lighting0+"}~n"
			FP = FRAGP0+FRAGP1+Frag_VertexLighting0+FRAGP2+Frag_Texture(num_texs)+FRAGP3
		Else ''per pixel lighting
			VP = VERTP0+VERTP1+VERTP2+Vert_Texture(num_texs)+VERTP3+"}~n"
			FP = FRAGP0+LightVars+Frag_LightVars+FRAGP1+LightingEquation0+FRAGP2+Frag_Texture(num_texs)+FRAGP3
		Endif
		
		If debug Then Print VP+"~n"+FP
		
		If( shader_id=0 And CompileShader(VP,GL_VERTEX_SHADER) And CompileShader(FP,GL_FRAGMENT_SHADER) )
			LinkShader()
			LinkVariables()
			global_uniforms = u
			'init_id = shader_id
			'If active Then Dprint "..FullShader success"
			
		Else If shader_id
		
			'shader_id = init_id ''use same shader
			u = global_uniforms ''use same uniforms
			active = 1
			
		Endif
		
	End
	
	Method Update()
		
		'If GetGLError() Then Print "*glerror fastbrightshader"
	End
	
	
End


Class FastBrightShader Extends TShaderGLSL
	
	''no texture blending
	
	Const VERTP:String = "attribute vec3 aVertcoords;attribute vec2 aTexcoords0; attribute vec4 aColors; uniform mat4 pMatrix;uniform mat4 vMatrix;uniform mat4 mMatrix;varying vec2 texcoord[1];"+
		" uniform float colorflag; uniform vec4 basecolor; uniform vec2 texPosition[1],  texScale[1], texRotation[1]; uniform float texflag; varying vec4 vertColor; varying vec2 varTex;"+
		" void main(){ gl_Position = (pMatrix*mMatrix ) * vec4(aVertcoords, 1.0); vertColor = mix(basecolor , aColors, colorflag);"+
		" vec2 scale = texScale[0];float cosang = texRotation[0].x; float sinang = texRotation[0].y; vec2 pos = texPosition[0]/scale;"+
		" (texcoord[0]).x = ((aTexcoords0.x + pos.x) * cosang - (aTexcoords0.y + pos.y) * sinang)*scale.x; (texcoord[0]).y = ((aTexcoords0.x + pos.x) * sinang + (aTexcoords0.y + pos.y) * cosang)*scale.y;"+
		" varTex.x = step(1.0,texflag); varTex.y = step(2.0,texflag);"+
		" ~n} "
	Const FRAGP:String = "#ifdef GL_ES ~n precision highp float; ~n #endif ~n uniform sampler2D uTexture[1]; uniform vec4 ambientcolor; uniform float alphaflag;"+
		" varying vec2 texcoord[1]; varying vec4 vertColor; varying vec2 varTex; const vec4 all_ones=vec4(1.0,1.0,1.0,1.0);"+
		" void main(){  "+
		" vec4 tex = texture2D( uTexture[0],texcoord[0] ); if (tex.w>=alphaflag) {"+
		"gl_FragColor= vec4(ambientcolor.xyz,0.0) + mix(vertColor, vertColor * tex * 1.0, varTex.x );"+
		" ~n} ~n}"
#rem
	'' two textures
	Const VERTP:String = "attribute vec3 aVertcoords;attribute vec2 aTexcoords0; attribute vec4 aColors; uniform mat4 pMatrix;uniform mat4 vMatrix;uniform mat4 mMatrix;varying vec2 texcoord[1];"+
		" uniform float colorflag; uniform vec4 basecolor; uniform vec2 texPosition[1],  texScale[1], texRotation[1]; uniform float texflag; varying vec4 vertColor; varying vec2 varTex;"+
		" void main(){ gl_Position = (pMatrix*mMatrix ) * vec4(aVertcoords, 1.0); vertColor = mix(basecolor , aColors, colorflag);"+
		" vec2 scale = texScale[0];float cosang = texRotation[0].x; float sinang = texRotation[0].y; vec2 pos = texPosition[0]/scale;"+
		" (texcoord[0]).x = ((aTexcoords0.x + pos.x) * cosang - (aTexcoords0.y + pos.y) * sinang)*scale.x; (texcoord[0]).y = ((aTexcoords0.x + pos.x) * sinang + (aTexcoords0.y + pos.y) * cosang)*scale.y;"+
		" varTex.x = step(1.0,texflag); varTex.y = step(2.0,texflag);"+
		" ~n} "
	Const FRAGP:String = "#ifdef GL_ES ~n precision mediump float; ~n #endif ~n uniform sampler2D uTexture[2]; uniform vec4 ambientcolor; uniform float alphaflag;"+
		" varying vec2 texcoord[1]; varying vec4 vertColor; varying vec2 varTex; const vec4 all_ones=vec4(1.0,1.0,1.0,1.0);"+
		" void main(){  "+
		" vec4 tex = texture2D( uTexture[0],texcoord[0] ); if (tex.w>=alphaflag) {"+
		"gl_FragColor= vec4(ambientcolor.xyz,0.0) + mix(vertColor, vertColor * tex * mix(all_ones,texture2D( uTexture[1],texcoord[0] ),varTex.y), varTex.x );"+
		" ~n} ~n}"
#end
	'Field uniform:Int[5]
	
	Global init_id:Int=0		
	Global global_uniforms:ShaderUniforms
	
	Method New()
		
		MAX_TEXTURES = 2
		MAX_LIGHTS = 0
		
		name ="FastBrightShader"
		
		If( init_id=0 And shader_id=0 And CompileShader(VERTP,GL_VERTEX_SHADER) And CompileShader(FRAGP,GL_FRAGMENT_SHADER) )
			LinkShader()
			LinkVariables()
			global_uniforms = u
			init_id = shader_id
			If active Then Dprint "..FastBrightShader success"
			
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


'' DOES NOT WORK
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
		
		'' dist = the hypotenuse. we need the distance of the other side of the triangle, or the distance to the plane.

		'fbo.Clear(1)
		'fbo.BeginFBO()
		blurshader.orientation =1
		'SetShader(blurshader)
		fbo2.Draw(cam, 1.0, dist)
		'fbo.EndFBO()

		
		
		DefaultShader()
		'DrawEntity(cam,ent)
	End
	
	Method Update()
	End
	
End

