
''--------------------------------------------------------
'' Windows 8 MiniB3D Driver
'' (C) 2012 Sascha Schmidt
''--------------------------------------------------------

Import minib3d
Import brl

#If MINIB3D_D3D11_RELEASE<>"true" Then 
 
Function GetShader:ShaderInfo(compiledShader:DataBuffer)

	Local reflector:= D3DReflect(compiledShader)
	' D3DPrintShaderReflection(reflector)
	
	'############
	
	Local desc:=reflector.GetDesc()
	Local shaderInfo:= New ShaderInfo()
	
	'' InputParameters
	
	shaderInfo.InputParameters = shaderInfo.InputParameters.Resize(desc.InputParameters)
	For Local i = 0 Until desc.InputParameters
		Local inputDesc:= reflector.GetInputParameterDesc(i)
		Local param:= New ShaderParameterInfo
			param.SemanticName = inputDesc.SemanticName
			param.SemanticIndex = inputDesc.SemanticIndex
			param.Register = inputDesc.Register
			param.SystemValueType = inputDesc.SystemValueType
			param.ComponentType = inputDesc.ComponentType
			param.Mask = inputDesc.Mask
			param.ReadWriteMask = inputDesc.ReadWriteMask
			
		shaderInfo.InputParameters[i] = param
	End
	
	'' OutputParameters
	
	shaderInfo.OutputParameters = shaderInfo.OutputParameters.Resize(desc.OutputParameters)
	For Local i = 0 Until desc.OutputParameters
		Local inputDesc:= reflector.GetOutputParameterDesc(i)
		Local param:= New ShaderParameterInfo
			param.SemanticName = inputDesc.SemanticName
			param.SemanticIndex = inputDesc.SemanticIndex
			param.Register = inputDesc.Register
			param.SystemValueType = inputDesc.SystemValueType
			param.ComponentType = inputDesc.ComponentType
			param.Mask = inputDesc.Mask
			param.ReadWriteMask = inputDesc.ReadWriteMask
			
		shaderInfo.OutputParameters[i] = param
	End
		
	'' ConstantBuffers
	
	shaderInfo.ConstantBuffers = shaderInfo.ConstantBuffers.Resize(desc.ConstantBuffers)
	For Local i = 0 Until desc.ConstantBuffers
		Local constantBuffer:= reflector.GetConstantBufferByIndex(i)
		Local bufferDesc:= constantBuffer.GetDesc()

		Local buffer:= New ShaderBufferInfo()
		buffer.Name = bufferDesc.Name
		buffer.Type = bufferDesc.Type
		buffer.uFlags = bufferDesc.uFlags
		buffer.Size = bufferDesc.Size
		buffer.Variables= buffer.Variables.Resize(bufferDesc.Variables)
		
		For Local j = 0 Until bufferDesc.Variables
			Local variable:= constantBuffer.GetVariableByIndex(j)
			buffer.Variables[j] = GetShaderVariableInfo(variable)
		End 
		
		shaderInfo.ConstantBuffers[i] = buffer

	End
	
	Return shaderInfo
End 

Function GetShaderVariableInfo:ShaderVariableInfo(variable:D3D11ShaderReflectionVariable)

	Local varDesc:= variable.GetDesc()

	Local info:= New ShaderVariableInfo()
		info.Name = varDesc.Name
		info.StartOffset = varDesc.StartOffset
		info.Size = varDesc.Size
		info.Type = GetShaderTypeInfo(variable.GetType())

	Return info 
	
End 

Function GetShaderTypeInfo:ShaderTypeInfo(type:D3D11ShaderReflectionType )

	Local typeDesc:= type.GetDesc()
	Local info:= New ShaderTypeInfo
	
	info.Class_ = typeDesc.Class_
	info.Type= typeDesc.Type
	info.Rows= typeDesc.Rows
	info.Columns= typeDesc.Columns
	info.Offset= typeDesc.Offset
	info.Members = info.Members.Resize(typeDesc.Members)
	info.Elements = typeDesc.Elements 
	
	For Local k = 0 Until info.Members.Length
		
		Local memberType:= type.GetMemberTypeByIndex(k)
		info.Members[k] = GetShaderTypeInfo(memberType)
		
	End 
	
	Return info

End 

#End 

'-----------------------------------------------------------------------

'' shader relflection data  

Class ShaderInfo

	#rem
	Field Creator:String
	Field Version:Int
	Field Flags:Int
	Field BoundResources:Int
	Field InstructionCount:Int
	Field TempRegisterCount:Int
	Field TempArrayCount:Int
	Field DefCount:Int
	Field DclCount:Int
	Field TextureNormalInstructions:Int
	Field TextureLoadInstructions:Int
	Field TextureCompInstructions:Int
	Field TextureBiasInstructions:Int
	Field TextureGradientInstructions:Int
	Field FloatInstructionCount:Int
	Field IntInstructionCount:Int
	Field UintInstructionCount:Int
	Field StaticFlowControlCount:Int
	Field DynamicFlowControlCount:Int
	Field MacroInstructionCount:Int
	Field ArrayInstructionCount:Int
	Field CutInstructionCount:Int
	Field EmitInstructionCount:Int
	Field GSOutputTopology:Int
	Field GSMaxOutputVertexCount:Int
	Field InputPrimitive:Int
	Field PatchConstantParameters:Int
	Field cGSInstanceCount:Int
	Field cControlPoints:Int
	Field HSOutputPrimitive:Int
	Field HSPartitioning:Int
	Field TessellatorDomain:Int
	Field cBarrierInstructions:Int
	Field cInterlockedInstructions:Int
	Field cTextureStoreInstructions:Int
	#end 
	
    Field InputParameters:ShaderParameterInfo[]
	Field OutputParameters:ShaderParameterInfo[]
	Field ConstantBuffers:ShaderBufferInfo[]
	
	Method New(data:Stream)
	
'TODO
' complete ShaderInfo load routine
	
		'' InputParameters
		Local inputParameters:= data.ReadInt()
		InputParameters = InputParameters.Resize(inputParameters)
		For Local i= 0 Until inputParameters
			InputParameters[i] = New ShaderParameterInfo(data)
		End 
		
		'' OutputParameters
		Local outputParameters:= data.ReadInt()
		OutputParameters = OutputParameters.Resize(inputParameters)
		For Local i= 0 Until outputParameters
			OutputParameters[i] = New ShaderParameterInfo(data)
		End 
		
		'' Buffers
		Local buffers:= data.ReadInt()
		ConstantBuffers = ConstantBuffers.Resize(buffers)
		For Local i= 0 Until buffers
			ConstantBuffers[i] = New ShaderBufferInfo(data)
		End 
		
	End 
	
	Method Save:Void(stream:Stream)

'TODO
' complete ShaderInfo save routine

		stream.WriteInt(InputParameters.Length)
		For Local i= 0 Until InputParameters.Length
			InputParameters[i].Save(stream)
		End 
		
		stream.WriteInt(OutputParameters.Length)
		For Local i= 0 Until OutputParameters.Length
			OutputParameters[i].Save(stream)
		End 

		stream.WriteInt(ConstantBuffers.Length)
		For Local i= 0 Until ConstantBuffers.Length
			ConstantBuffers[i].Save(stream)
		End 
		
	End 
End 

Class ShaderBufferInfo

	Field Name:String
	Field Type:Int 
	Field uFlags:Int 
	Field Size:Int 
	Field Variables:ShaderVariableInfo[]
	
	Method New(stream:Stream)
	
		Name = ReadString(stream)
		Type = stream.ReadInt()
		uFlags = stream.ReadInt()
		Size = stream.ReadInt()
		Variables = Variables.Resize(stream.ReadInt())

		For Local i = 0 Until Variables.Length
			Variables[i] = New ShaderVariableInfo(stream)
		End 
		
	End 
	
	Method Save:Void(stream:Stream)
	
		WriteString(stream,Name)
		stream.WriteInt(Type)
		stream.WriteInt(uFlags)
		stream.WriteInt(Size)
		stream.WriteInt(Variables.Length)
		
		For Local i = 0 Until Variables.Length
			Variables[i].Save(stream)
		End 
		
	End 
	
End 

Class ShaderParameterInfo

	Field SemanticName:String 
	Field SemanticIndex:Int 
	Field SystemValueType:Int 
	Field ComponentType:Int 
	Field Mask:Int 
	Field Register:Int 
	Field ReadWriteMask:Int 
	
	Method New(data:Stream)
	
		SemanticName = ReadString(data)
		SemanticIndex = data.ReadInt()
		SystemValueType = data.ReadInt()
		ComponentType = data.ReadInt()
		Mask = data.ReadInt()
		Register = data.ReadInt()
		ReadWriteMask = data.ReadInt()
		
	End 
	
	Method Save:Void(stream:Stream)
	
		WriteString(stream,SemanticName)
		stream.WriteInt(SemanticIndex)
		stream.WriteInt(SystemValueType)
		stream.WriteInt(ComponentType)
		stream.WriteInt(Mask)
		stream.WriteInt(Register)
		stream.WriteInt(ReadWriteMask)
		
	End 
End 

Class ShaderVariableInfo

	Field Name:String 
	Field StartOffset:Int
	Field Size:Int 
	Field DefaultValue:Int 
	Field Type:ShaderTypeInfo
	
	Method New(data:Stream)	
	
		Name = ReadString(data)
		StartOffset = data.ReadInt()
		Size = data.ReadInt()
		DefaultValue = data.ReadInt()		
		Type = New ShaderTypeInfo(data)
		
	End 
	
	Method Save:Void(stream:Stream)
	
		WriteString(stream,Name)
		stream.WriteInt(StartOffset)
		stream.WriteInt(Size)
		stream.WriteInt(DefaultValue)
		Type.Save(stream)

	End 
End 

Class ShaderTypeInfo

	Field Class_:Int 
	Field Type:Int 
	Field Rows:Int 
	Field Columns:Int 
	Field Members:ShaderTypeInfo[]
	Field Elements:Int 
	Field Offset:Int 
	
	Method New(stream:Stream)
	
		Class_ 	= stream.ReadInt()
		Type 	= stream.ReadInt()
		Rows 	= stream.ReadInt()
		Columns = stream.ReadInt()
		Members = Members.Resize(stream.ReadInt())
		Elements = stream.ReadInt()
		Offset = stream.ReadInt()

		For Local i = 0 Until Members.Length						
			Members[i] = New ShaderTypeInfo(stream)			
		End 

	End 
	
	Method Save:Void(stream:Stream)
	
		stream.WriteInt(Class_)
		stream.WriteInt(Type)
		stream.WriteInt(Rows)
		stream.WriteInt(Columns)
		stream.WriteInt(Members.Length)
		stream.WriteInt(Elements)
		stream.WriteInt(Offset)
		
		For Local i = 0 Until Members.Length			
			Members[i].Save(stream)
		End 
		
	End 
End 

'-----------------------------------------------------------------

Function ReadString:String(stream:Stream)
	Local length:= stream.ReadInt()
	Local data:= New Int[length]
	For Local i = 0 Until length
		data[i] = stream.ReadInt()
	End 
	Return String.FromChars(data)
End 

Function WriteString:Void(stream:Stream,str:String)
	Local length:= str.Length
	Local chars:= str.ToChars()
	stream.WriteInt(length)
	For Local i = 0 Until length
		stream.WriteInt(chars[i])
	End 
End 

 