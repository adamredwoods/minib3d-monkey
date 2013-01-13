
''--------------------------------------------------------
'' Windows 8 MiniB3D Driver
'' (C) 2012 Sascha Schmidt
''--------------------------------------------------------

Import minib3d

#If MINIB3D_D3D11_RELEASE="true" 
	Import "shader\compiled\fastshader.ps.bin"
	Import "shader\compiled\fastshader.vs.bin"
	Import "shader\compiled\fastshader.ps.refl.bin"
	Import "shader\compiled\fastshader.vs.refl.bin"
#Else
	Import "shader\fastshader.txt"
#End 

Class D3D11FastShader Extends D3D11Shader Implements   IShaderTexture, IShaderMatrices,  IShaderColor

Private 

	Const SHADER_FILENAME$ = "fastshader.txt"

	'' IShaderMatrices
	Field _pView:IShaderParameter
	Field _pProj:IShaderParameter
	Field _pWorld:IShaderParameter
	Field _pDiffuseColor:IShaderParameter
	
Public 

	Method New()
		Super.Load(SHADER_FILENAME,SHADER_FILENAME)

		'' IShaderMatrices
	  	_pView = Parameters.Get("view")
		_pProj = Parameters.Get("projection")
		_pWorld = Parameters.Get("world")		
		_pDiffuseColor =  Parameters.Get("color")
		
	End
	
	'' IShaderMatrices
	Method ProjectionMatrix(m:Matrix)
		_pProj.SetValue(m)
	End 

	Method ViewMatrix(m:Matrix)
		_pView.SetValue(m)
	End 
	
	Method WorldMatrix(m:Matrix)
		_pWorld.SetValue(m)
	End 

	Method EyePosition(x#,y#,z#)
	End 
	
	'' -- ok. these emty methods suck... 
	'' => more interfaces or different approach!
	
	'' IShaderColor
	
	Method VertexColorEnabled(val?)
	End 
	
	Method DiffuseColor(r#,g#,b#,a#) 
		_pDiffuseColor.SetValue(r,g,b,a)
	End 
	
	Method AmbientColor(r#,g#,b#)
	End 
	
	Method Shine(val#)
	End 
	
	Method ShinwPower(val#)
	End 
	
	'' IShaderTexture
	
	Method TexturesEnabled(val?) 
	End 
	 
	Method TextureBlend(index, blend)  
	End 	

	Method TextureCount(count)  
	End 
	
	Method TextureTransform(index, tex_u_pos#,tex_v_pos#, tex_u_scale#, tex_v_scale# , tex_ang#, coords)
	End 

	'' TShader
	
	Method Update()
	End 
	
End