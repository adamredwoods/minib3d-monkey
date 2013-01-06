Import minib3d 

#rem
Interface IRender
	Method GraphicsInit:Int(flags:Int=0) 
	Method GetVersion:Float() 
	Method CreateTexture:ITexture(tex:TTexture,flags:Int) 
	Method ReleaseTexture(tex:ITexture) 
	Method CreateMesh:IMesh(surf:TSurface)
	Method ReleaseMesh(surf:TSurface)
	Method CreateShader:IShader(shader:TShader)
	Method CreateDefaultShader:IShader(shader:TShader)
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

Interface IShaderMatrices 
	Method ProjectionMatrix(m:Matrix)
	Method ViewMatrix(m:Matrix)
	Method WorldMatrix(m:Matrix)
	Method EyePosition(x#,y#,z#)
End 

'' I vote for standardize the default TBrush behavior using interfaces like these. 
'' any thoughts?

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