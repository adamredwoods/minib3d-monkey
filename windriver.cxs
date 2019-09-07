' author: Sascha Schmidt

Import minib3d 

'' Constants

' shader parameter type
Const SHADER_PARAMETER_TYPE_VOID                  = 0
Const SHADER_PARAMETER_TYPE_BOOL                  = 1
Const SHADER_PARAMETER_TYPE_INT                   = 2
Const SHADER_PARAMETER_TYPE_FLOAT                 = 3
Const SHADER_PARAMETER_TYPE_STRING                = 4
Const SHADER_PARAMETER_TYPE_TEXTURE               = 5
Const SHADER_PARAMETER_TYPE_TEXTURE1D             = 6
Const SHADER_PARAMETER_TYPE_TEXTURE2D             = 7
Const SHADER_PARAMETER_TYPE_TEXTURE3D             = 8
Const SHADER_PARAMETER_TYPE_TEXTURECUBE           = 9

' shader parameter class
Const SHADER_PARAMETER_CLASS_SCALAR               = 0
Const SHADER_PARAMETER_CLASS_VECTOR               = ( SHADER_PARAMETER_CLASS_SCALAR + 1 )
Const SHADER_PARAMETER_CLASS_MATRIX_ROWS          = ( SHADER_PARAMETER_CLASS_VECTOR + 1 )
Const SHADER_PARAMETER_CLASS_MATRIX_COLUMNS       = ( SHADER_PARAMETER_CLASS_MATRIX_ROWS + 1 )
Const SHADER_PARAMETER_CLASS_OBJECT               = ( SHADER_PARAMETER_CLASS_MATRIX_COLUMNS + 1 )
Const SHADER_PARAMETER_CLASS_STRUCT               = ( SHADER_PARAMETER_CLASS_OBJECT + 1 )

' cull modes
Const CULL_NONE	= 1
Const CULL_FRONT = 2
Const CULL_BACK	= 3

' fill modes
Const FILL_WIREFRAME = 2
Const FILL_SOLID	= 3

' texture filtering
Const FILTER_MIN_MAG_MIP_POINT = 0
Const FILTER_MIN_MAG_POINT_MIP_LINEAR = $1
Const FILTER_MIN_POINT_MAG_LINEAR_MIP_POINT	= $4
Const FILTER_MIN_POINT_MAG_MIP_LINEAR = $5
Const FILTER_MIN_LINEAR_MAG_MIP_POINT = $10
Const FILTER_MIN_LINEAR_MAG_POINT_MIP_LINEAR = $11
Const FILTER_MIN_MAG_LINEAR_MIP_POINT = $14
Const FILTER_MIN_MAG_MIP_LINEAR	= $15
Const FILTER_ANISOTROPIC = $55

Const TEXTURE_ADDRESS_WRAP	= 1
Const TEXTURE_ADDRESS_MIRROR	= 2
Const TEXTURE_ADDRESS_CLAMP	= 3
Const TEXTURE_ADDRESS_BORDER	= 4
Const TEXTURE_ADDRESS_MIRROR_ONCE	= 5

'' Blend factors, which modulate values for the pixel shader and render target.
Const BLEND_ZERO	= 1
Const BLEND_ONE	= 2
Const BLEND_SRC_COLOR	= 3
Const BLEND_INV_SRC_COLOR	= 4
Const BLEND_SRC_ALPHA	= 5
Const BLEND_INV_SRC_ALPHA	= 6
Const BLEND_DEST_ALPHA	= 7
Const BLEND_INV_DEST_ALPHA	= 8
Const BLEND_DEST_COLOR	= 9
Const BLEND_INV_DEST_COLOR	= 10
Const BLEND_SRC_ALPHA_SAT	= 11
Const BLEND_BLEND_FACTOR	= 14
Const BLEND_INV_BLEND_FACTOR	= 15
Const BLEND_SRC1_COLOR	= 16
Const BLEND_INV_SRC1_COLOR	= 17
Const BLEND_SRC1_ALPHA	= 18
Const BLEND_INV_SRC1_ALPHA	= 19

'' RGB or alpha blending operation.
Const BLEND_OP_ADD	= 1
Const BLEND_OP_SUBTRACT	= 2
Const BLEND_OP_REV_SUBTRACT	= 3
Const BLEND_OP_MIN	= 4
Const BLEND_OP_MAX	= 5

'' Interfaces

Interface IGraphics
	Method Create(flags=0) 
	Method Dispose()
	Method Reset()
	Method GetVersion:Float() 
	Method CreateTexture:ITexture(width,height,format,flags) 
	Method CreateMesh:IMesh()
	Method CreateShader:IShader()
	Method CreateRendertarget:IRendertarget(width,height, format, flags)
	Method CreateRasterizerState:IRasterizerState(cullMode, fillMode, scissorTest?)
	Method CreateSamplerState:ISamplerState(filter, u,v, w ,maxAnisotropy,bias#)
	Method CreateDepthStencilState:IDepthStencilState(depthBufferEnable?, depthBufferWriteEnable?)
	Method CreateBlendState:IBlendState(enable, srcBlend, descBlend, blendOp, srcAlphaBlend, descAlphaBlend, blendAlphaOp)
	Method SetTexture(index, t:ITexture)
	Method SetShader(shader:IShader)
	Method SetMesh(mesh:IMesh)
	Method SetRendertarget(index,rt:IRendertarget)
	Method SetRasterizerState(rs:IRasterizerState)
	Method SetSamplerState(index,st:ISamplerState)
	Method SetDepthStencilState(ds:IDepthStencilState)
	Method SetBlendState(bs:IBlendState)
End

Interface IIRasterizerState
	Method Dispose()
End 

Interface IISamplerState
	Method Dispose()
End 

Interface IIDepthStencilState
	Method Dispose()
End 

Interface IIBlendState
	Method Dispose()
End 

Interface IMesh 
	Method Create(flags)
	Method Dispose()
	Method SetVertices()
	Method SetIndices()
End

Interface ITexture
	Method Create(width, height, format, flags)
	Method Dispose()
	Method Update(index,tex:Pixmap)
End

Interface IShader
	Method Load(filename:String)
	Method Parameters:ShaderParameterCollection() Property
	Method Name:String()
	Method Bind()
	Method Apply()
	Method Release()
	Method Update()
End

Interface IShaderParameter 

	Method Name:String() Property 
	Method ParameterType:Int() Property 
	Method ParameterClass:Int() Property 
	Method Elements:IShaderParameter[]() Property 
	Method StructureMembers:IShaderParameter[]() Property 
	Method RowCount:Int() Property 
	Method ColumnCount:Int() Property
	Method Index:Int() Property 
	Method Size:Int() Property 
	
	Method SetValue:Void(value:Int) 
	Method SetValue:Void(value:Float)
	Method SetValue:Void(value:Vector)
	Method SetValue:Void(value:Matrix)
	Method SetValue:Void(value:Int[]) 
	Method SetValue:Void(value:Float[])
	Method SetValue:Void(v0#,v1#)
	Method SetValue:Void(v0#,v1#,v2#)
	Method SetValue:Void(v0#,v1#,v2#,v3#)
	Method SetValue:Void(v0%,v1%)
	Method SetValue:Void(v0%,v1%,v2%)
	Method SetValue:Void(v0%,v1%,v2%,v3%)
	Method SetValue:Void(v0?)
	Method SetValue:Void(v0?,v1?)
	Method SetValue:Void(v0?,v1?,v2?)
	Method SetValue:Void(v0?,v1?,v2?, v3?)
End 

Interface IShaderMatrices 
	Method ProjectionMatrix(m:Matrix)
	Method ViewMatrix(m:Matrix)
	Method WorldMatrix(m:Matrix)
	Method EyePosition(x#,y#,z#)
End 

Interface IShaderFog
	Method FogEnabled(val?)
	Method FogColor(r#,g#,b#) 
	Method FogRange(near#, far#)
End

Interface IShaderColor
	Method VertexColorEnabled(val?)
	Method DiffuseColor(r#,g#,b#,a#) 
	Method AmbientColor(r#,g#,b#)
	Method Shine(val#)
	Method ShinwPower(val#)
End

Interface IShaderTexture
	Method TexturesEnabled(val?)  
	Method TextureBlend(index, blend)  
	Method TextureTransform(index, tex_u_pos#,tex_v_pos#, tex_u_scale#, tex_v_scale# , tex_ang#, coords)
	Method TextureCount(count)  
End 

Interface IShaderLights
	Method LightingEnabled(val?)
	Method AddLight(light:TLight)
	Method RemoveLight(light:TLight)
	Method ClearLights()
End


''
'' driver util
''


Class ShaderParameterCollection Extends List<IShaderParameter>

	Field _map:= New StringMap<IShaderParameter>
	
	Method Clear()
		Super.Clear()
		_map.Clear()
	End 
	
	Method AddLast:list.Node<IShaderParameter>(p:IShaderParameter)
		If Not _map.Contains(p.Name) then
			_map.Set(p.Name,p)
			Return Super.AddLast(p)
		End 
	End 
	
	Method AddFirst:list.Node<IShaderParameter>(p:IShaderParameter)
		If Not _map.Contains(p.Name) then
			_map.Set(p.Name,p)
			Return Super.AddFirst(p)
		End 
	End 
	
	Method Get:IShaderParameter(name:String)
		Local p:= _map.Get(name)
		If Not p Then 
			Error "ShaderParameterCollection: Failed to get parameter " + name
		End 
		Return p
	End 
	
	Method Contains?(p:IShaderParameter)
		Return _map.Contains(p.Name)
	End 
	
End 

Function PrintShader:Void(shader:IShader)
	Print "Shader: " + shader.Name
	Print "- Parameters:"
	For Local param:= Eachin shader.Parameters
		Print "   - Parameter "
		PrintShaderParameter(param, "~t")
	End 
End 

Function PrintShaderParameter:Void(param:IShaderParameter, tab:String)
 
	Print tab+"    - Name: " 	+ param.Name
	Print tab+"    - Columns: " + param.ColumnCount
	Print tab+"    - Rows: " 	+ param.RowCount
	Print tab+"    - Class: " 	+ ParameterClassToString(param.ParameterClass)
	Print tab+"    - Type: " 	+ ParameterTypeToString(param.ParameterType)
	
	If param.Elements.Length Then 
	
		Print tab+"    - Elements: "
		For Local p:= Eachin param.Elements
			Print tab+"   - Element: " 
			PrintShaderParameter(p, tab+"~t")
		End 
		
	ElseIf param.StructureMembers.Length Then 
		
		Print tab+"    - StructureMembers: "
		For Local p:= Eachin param.StructureMembers
			Print tab+"   - Member: " 
			PrintShaderParameter(p, tab+"~t")
		End 

	End 
		
End 

Function ParameterTypeToString:String(t:Int)

	Select t
		Case SHADER_PARAMETER_TYPE_VOID 
			Return "SHADER_PARAMETER_TYPE_VOID " 
		Case SHADER_PARAMETER_TYPE_BOOL             
			Return "SHADER_PARAMETER_TYPE_BOOL " 
		Case SHADER_PARAMETER_TYPE_FLOAT        
			Return "SHADER_PARAMETER_TYPE_FLOAT " 
		Case SHADER_PARAMETER_TYPE_STRING       
			Return "SHADER_PARAMETER_TYPE_STRING " 
		Case SHADER_PARAMETER_TYPE_TEXTURE              
			Return "SHADER_PARAMETER_TYPE_TEXTURE " 
		Case SHADER_PARAMETER_TYPE_TEXTURE2D            
			Return "SHADER_PARAMETER_TYPE_TEXTURE2D " 
		Case SHADER_PARAMETER_TYPE_TEXTURE3D    
			Return "SHADER_PARAMETER_TYPE_TEXTURE3D " 
		Case SHADER_PARAMETER_TYPE_TEXTURECUBE  
			Return "SHADER_PARAMETER_TYPE_TEXTURECUBE " 
		default 
			Return "Not implemented"
	End  
	
End 

Function ParameterClassToString:String(c:Int)

	Select c
		Case SHADER_PARAMETER_CLASS_SCALAR 
			Return "SHADER_PARAMETER_CLASS_SCALAR " 
		Case SHADER_PARAMETER_CLASS_VECTOR             
			Return "SHADER_PARAMETER_CLASS_VECTOR " 
		Case SHADER_PARAMETER_CLASS_MATRIX_ROWS        
			Return "SHADER_PARAMETER_CLASS_MATRIX_ROWS " 
		Case SHADER_PARAMETER_CLASS_MATRIX_COLUMNS       
			Return "SHADER_PARAMETER_CLASS_MATRIX_COLUMNS " 
		Case SHADER_PARAMETER_CLASS_OBJECT              
			Return "SHADER_PARAMETER_CLASS_OBJECT " 
		Case SHADER_PARAMETER_CLASS_STRUCT            
			Return "SHADER_PARAMETER_CLASS_STRUCT " 
		default 
			Return "Not implemented"
	End 
	
End 
