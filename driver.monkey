Import minib3d 

''
'' Constants
''

' shader parameter types
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

#rem
Interface IRender
	Method GraphicsInit:Int(flags:Int=0) 
	Method GetVersion:Float() 
	Method CreateTexture:ITexture(tex:TTexture,flags:Int) 
	Method ReleaseTexture(tex:ITexture) 
	Method CreateMesh:IMesh(surf:TSurface)
	Method ReleaseMesh(surf:TSurface)
	Method CreateShader:IShader(shader:TShader)
	Method ReleaseShader(shader:TShader)
	Method Reset() 
	Method UpdateLight(cam:TCamera, light:TLight)
	Method DisableLight(light:TLight)
	Method UpdateCamera(cam:TCamera)
	Method UpdateShader(shader:IShader)
	Method Render(ent:TEntity)
	Method RenderInstanced(ent:TEntity)
	Method Finish() 
	Method Release()
End
#end 

Interface IMesh 
	Method Bind()
	Method Render()
	Method Render( matrices:Matrix[], colors:Float[],  cnt )
	Method SetVertices()
	Method SetIndices()
End

Interface ITexture
	Method Release()
	Method Update(data:DataBuffer)
End

Interface IShader
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

'' I vote for standardize the default TBrush behavior using interfaces like these. 
'' any thoughts?


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
