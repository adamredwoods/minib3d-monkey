
''--------------------------------------------------------
'' Windows 8 MiniB3D Driver
'' (C) 2012 Sascha Schmidt
''--------------------------------------------------------

#if TARGET<>"win8"
	#Error "d3d11compile is only supported on wind8 target."
#else

Import brl
Import minib3d.d3d11.driver.d3d11
Import minib3d.d3d11.driver.d3d11constants
Import "native/d3d11compiler.cpp"

Extern 

Function D3DInitCompilerDll:Int()= "BBInitD3DCompilerDll"
Function D3DCompileShader:Bool(shaderCode$,entryPoint$, target$,filename$, flags, out:DataBuffer) = "BBD3DCompileShader"
Function D3DReflect:D3D11ShaderReflection(comiledShader:DataBuffer) = "BBD3DReflect"

Class D3D11ShaderReflection Extends IUnknown = "BBD3D11ShaderReflection"
	Method GetDesc:D3D11_SHADER_DESC()
	Method GetInputParameterDesc:D3D11_SIGNATURE_PARAMETER_DESC(index)
	Method GetOutputParameterDesc:D3D11_SIGNATURE_PARAMETER_DESC(index)
	Method GetConstantBufferByIndex:D3D11ShaderReflectionConstantBuffer(index)
End 

Class D3D11ShaderReflectionConstantBuffer Extends IUnknown = "BBD3D11ShaderReflectionConstantBuffer"
	Method GetDesc:D3D11_SHADER_BUFFER_DESC()	
	Method GetVariableByIndex:D3D11ShaderReflectionVariable(index)
End 

Class D3D11ShaderReflectionVariable Extends IUnknown = "BBD3D11ShaderReflectionVariable"
	Method GetDesc:D3D11_SHADER_VARIABLE_DESC()
	Method GetInterfaceSlot:int()
	Method GetType:D3D11ShaderReflectionType()
End 

Class D3D11ShaderReflectionType Extends IUnknown = "BBD3D11ShaderReflectionType"
	Method GetBaseClass:D3D11ShaderReflectionVariable()
	Method GetDesc:D3D11_SHADER_TYPE_DESC()
	Method GetInterfaceByIndex:D3D11ShaderReflectionType(index)	
	Method GetMemberTypeByIndex:D3D11ShaderReflectionType(index)
	Method GetNumInterfaces:int()
	Method GetSubType:D3D11ShaderReflectionType(index)
	Method ImplementsInterface:Bool(type:D3D11ShaderReflectionType)
	Method IsEqual:Bool(type:D3D11ShaderReflectionType)		
	Method IsOfType:Bool(type:D3D11ShaderReflectionType)	
End 

Class D3D11_SHADER_DESC = "BBD3D11_SHADER_DESC"
  Method Version:Int() Property
  Method Creator:String()  Property
  Method Flags:Int() Property
  Method ConstantBuffers:Int()  Property
  Method BoundResources:Int() Property
  Method InputParameters:Int() Property
  Method OutputParameters:Int() Property
  Method InstructionCount:Int() Property
  Method TempRegisterCount:Int() Property
  Method TempArrayCount:Int()  Property
  Method DefCount:Int()  Property
  Method DclCount:Int()  Property
  Method TextureNormalInstructions:Int()  Property
  Method TextureLoadInstructions:Int()  Property
  Method TextureCompInstructions:Int()  Property
  Method TextureBiasInstructions:Int() Property
  Method TextureGradientInstructions:Int() Property
  Method FloatInstructionCount:Int() Property
  Method IntInstructionCount:Int()  Property
  Method UintInstructionCount:Int()  Property
  Method StaticFlowControlCount:Int()  Property
  Method DynamicFlowControlCount:Int()  Property
  Method MacroInstructionCount:Int()  Property
  Method ArrayInstructionCount:Int()  Property
  Method CutInstructionCount:Int()  Property
  Method EmitInstructionCount:Int()  Property
  Method GSOutputTopology:Int()  Property
  Method GSMaxOutputVertexCount:Int()  Property
  Method InputPrimitive:Int()  Property
  Method PatchConstantParameters:Int()  Property
  Method cGSInstanceCount:Int()  Property
  Method cControlPoints:Int() Property
  Method HSOutputPrimitive:Int()  Property
  Method HSPartitioning:Int()  Property
  Method TessellatorDomain:Int()  Property
  Method cBarrierInstructions:Int()  Property
  Method cInterlockedInstructions:Int()  Property
  Method cTextureStoreInstructions:Int() Property
End

Class D3D11_SIGNATURE_PARAMETER_DESC = "BBD3D11_SIGNATURE_PARAMETER_DESC"
	Method SemanticName:String() Property
	Method SemanticIndex:int() Property  
	Method Register:int() Property  
	Method SystemValueType:int() Property  
	Method ComponentType:int() Property  
	Method Mask:int() Property  
	Method ReadWriteMask:int() Property  
End
	
Class D3D11_SHADER_BUFFER_DESC = "BBD3D11_SHADER_BUFFER_DESC"
	Method Name:String() Property
	Method Type:int() Property
	Method Variables:int() Property
	Method Size:int() Property
	Method uFlags:int() Property
End 

Class D3D11_SHADER_VARIABLE_DESC = "BBD3D11_SHADER_VARIABLE_DESC"
	Method Name:String() Property
	Method StartOffset:int() Property
	Method Size:int() Property
	Method uFlags:int() Property
	'Method DefaultValue:int() Property
End
	
Class D3D11_SHADER_TYPE_DESC = "BBD3D11_SHADER_TYPE_DESC"
	Method Name:String() Property
	Method Class_:Int() Property = "Class"
	Method Type:int() Property
	Method Rows:int() Property
	Method Columns:int() Property
	Method Members:Int() Property
	Method Elements:Int() Property 
	Method Offset:int() Property
End

Public 
Function D3DPrintShaderReflection:void(reflector:D3D11ShaderReflection)

	Local desc:=reflector.GetDesc()
	
	Print "InputParametres"
	
	For Local i = 0 Until desc.InputParameters
		Local inputDesc:= reflector.GetInputParameterDesc(i)
		
		Print "- SemanticName: " 		+ inputDesc.SemanticName
		Print "  - SemanticIndex: " 	+ inputDesc.SemanticIndex
		Print "  - Register: " 			+ inputDesc.Register
		Print "  - SystemValueType: " 	+ inputDesc.SystemValueType
		Print "  - ComponentType: " 	+ inputDesc.ComponentType
		Print "  - Mask: "				+ inputDesc.Mask
		Print "  - ReadWriteMask: " 	+ inputDesc.ReadWriteMask
		
	End
	
	Print "OutputParametres"
	
	For Local i = 0 Until desc.OutputParameters
		Local inputDesc:= reflector.GetOutputParameterDesc(i)
		
		Print "- SemanticName: " 		+ inputDesc.SemanticName
		Print "  - SemanticIndex: " 	+ inputDesc.SemanticIndex
		Print "  - Register: " 			+ inputDesc.Register
		Print "  - SystemValueType: " 	+ inputDesc.SystemValueType
		Print "  - ComponentType: " 	+ inputDesc.ComponentType
		Print "  - Mask: "				+ inputDesc.Mask
		Print "  - ReadWriteMask: " 	+ inputDesc.ReadWriteMask
		
	End
	
	Print "ConstantBuffers"
	
	For Local i = 0 Until desc.ConstantBuffers
		Local constantBuffer:= reflector.GetConstantBufferByIndex(i)
		Local bufferDesc:= constantBuffer.GetDesc()
		
		Print "Buffer " + i
		Print "  - Name: " + bufferDesc.Name
		Print "  - Type: " + bufferDesc.Type
		Print "  - Variables: " + bufferDesc.Variables
		Print "  - uFlags: " + bufferDesc.uFlags

		For Local j = 0 Until bufferDesc.Variables
		
			Local variable:= constantBuffer.GetVariableByIndex(j)

			D3DPrintShaderVariableDesc(variable.GetDesc())
			D3DPrintShaderTypeDesc(variable.GetType())

		End 
	End

End

Function D3DPrintShaderVariableDesc(varDesc:D3D11_SHADER_VARIABLE_DESC)

	Print "    - Variable " 
	Print "       - Name: " + varDesc.Name
	Print "       - StartOffset: " + varDesc.StartOffset
	Print "       - Size: " + varDesc.Size
	''Print "       - DefaultValue: " + varDesc.DefaultValue
	
End 

Function D3DPrintShaderTypeDesc(type:D3D11ShaderReflectionType, tab$="")

	Local typeDesc:= type.GetDesc()
			
	Print tab+"    		- Class " 
	Select typeDesc.Class_
		Case D3D_SVC_SCALAR 
			Print tab+"    			- D3D_SVC_SCALAR " 
		Case D3D_SVC_VECTOR             
			Print tab+"    			- D3D_SVC_VECTOR " 
		Case D3D_SVC_MATRIX_ROWS        
			Print tab+"    			- D3D_SVC_MATRIX_ROWS " 
		Case D3D_SVC_MATRIX_COLUMNS       
			Print tab+"    			- D3D_SVC_MATRIX_COLUMNS " 
		Case D3D_SVC_OBJECT              
			Print tab+"    			- D3D_SVC_OBJECT " 
		Case D3D_SVC_STRUCT            
			Print tab+"    			- D3D_SVC_STRUCT " 
		Case D3D_SVC_INTERFACE_CLASS    
			Print tab+"    			- D3D_SVC_INTERFACE_CLASS " 
		Case D3D_SVC_INTERFACE_POINTER  
			Print tab+"    			- D3D_SVC_INTERFACE_POINTER " 
	End 

	Print "    		- Type " 
	Select typeDesc.Type
		Case D3D_SVT_VOID 
			Print tab+"    			- D3D_SVT_VOID " 
		Case D3D_SVT_BOOL             
			Print tab+"    			- D3D_SVT_BOOL " 
		Case D3D_SVT_FLOAT        
			Print tab+"    			- D3D_SVT_FLOAT " 
		Case D3D_SVT_STRING       
			Print tab+"    			- D3D_SVT_STRING " 
		Case D3D_SVT_TEXTURE              
			Print tab+"    			- D3D_SVT_TEXTURE " 
		Case D3D_SVT_TEXTURE2D            
			Print tab+"    			- D3D_SVT_TEXTURE2D " 
		Case D3D_SVT_TEXTURE3D    
			Print tab+"    			- D3D_SVT_TEXTURE3D " 
		Case D3D_SVT_TEXTURECUBE  
			Print tab+"    			- D3D_SVT_TEXTURECUBE " 
		Case D3D_SVT_SAMPLER 
			Print tab+"    			- D3D_SVT_SAMPLER " 
		default 
			Print tab+"    			- not implemented "
	End  
	
	Print tab+"      	 - Rows: " + typeDesc.Rows
	Print tab+"       	 - Columns: " + typeDesc.Columns
	'' Print tab+"       	 - Elements: " + typeDesc.Elements
	Print tab+"       	 - Members: " + typeDesc.Members
	Print tab+"       	 - Elements: " + typeDesc.Elements
	Print tab+"       	 - Offset: " + typeDesc.Offset
	
	Local members:= typeDesc.Members
	For Local k = 0 Until members
		Local memberType:= type.GetMemberTypeByIndex(k)
		D3DPrintShaderTypeDesc(memberType, tab + "~t")
	End 
			
End 