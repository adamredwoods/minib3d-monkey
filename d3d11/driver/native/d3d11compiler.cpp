
//--------------------------------------------------------------------------------------
// Windows8 MiniB3D driver
// (C) 2012 Sascha Schmidt
//--------------------------------------------------------------------------------------

#ifndef SAFE_RELEASE
#define SAFE_RELEASE(p)      { if (p) { (p)->Release(); (p)=NULL; } }
#endif

#include "d3dcompiler.h"

typedef HRESULT (WINAPI *D3DCompile_ptr)
    (LPCVOID                         pSrcData,
     SIZE_T                          SrcDataSize,
     LPCSTR                          pFileName,
     CONST D3D_SHADER_MACRO*         pDefines,
     void*/*ID3DInclude* */          pInclude,
     LPCSTR                          pEntrypoint,
     LPCSTR                          pTarget,
     UINT                            Flags1,
     UINT                            Flags2,
     ID3DBlob**                      ppCode,
     ID3DBlob**                      ppErrorMsgs);


typedef HRESULT (WINAPI *D3DReflect_ptr)
    (LPCVOID        pSrcData,
     SIZE_T         SrcDataSize,
	 REFIID			pInterface,
     void**			ppReflector);


HINSTANCE D3DCompile_lib; 
D3DCompile_ptr D3D11CompileFromMemory;
D3DReflect_ptr D3D11ReflectShader;

int BBInitD3DCompilerDll()
{
	UINT error = 0;
	
	D3DCompile_lib = LoadPackagedLibrary(L"D3DCompiler_46.dll",0);
	error |= GetLastError();
	 
	D3D11CompileFromMemory = (D3DCompile_ptr)GetProcAddress(D3DCompile_lib, "D3DCompile" );
	error |= GetLastError();
	
	D3D11ReflectShader = (D3DReflect_ptr)GetProcAddress(D3DCompile_lib, "D3DReflect" );
	error |= GetLastError();
	
	return 1-(int)error;
}

class BBD3D_SHADER_MACRO : public Object
{
public:
	D3D_SHADER_MACRO _macro;
	
	String GetName(){ return String(_macro.Name);};
	void SetName(String value) { _macro.Name = (LPCSTR)value.ToCString<wchar_t>();}
	String GetDefinition(){ return (String)_macro.Definition;};
	void SetDefinition(String value) { _macro.Definition = (LPCSTR)value.ToCString<wchar_t>();}
};

class BBD3D11_SHADER_DESC : public Object 
{
public:
	D3D11_SHADER_DESC  _desc;
	
	int Version() { return (int)_desc.Version; }
	String Creator() { return String(_desc.Creator); }
	int Flags() { return (int)_desc.Flags; }
	int ConstantBuffers() { return (int)_desc.ConstantBuffers; }
	int BoundResources() { return (int)_desc.BoundResources; }
	int InputParameters() { return (int)_desc.InputParameters; }
	int OutputParameters() { return (int)_desc.OutputParameters; }
	int InstructionCount() { return (int)_desc.InstructionCount; }
	int TempRegisterCount() { return (int)_desc.TempRegisterCount; }
	int TempArrayCount() { return (int)_desc.TempArrayCount; }
	int DefCount() { return (int)_desc.DefCount; }
	int DclCount() { return (int)_desc.DclCount; }
	int TextureNormalInstructions() { return (int)_desc.TextureNormalInstructions; }
	int TextureLoadInstructions() { return (int)_desc.TextureLoadInstructions; }
	int TextureCompInstructions() { return (int)_desc.TextureCompInstructions; }
	int TextureBiasInstructions() { return (int)_desc.TextureBiasInstructions; }
	int TextureGradientInstructions() { return (int)_desc.TextureGradientInstructions; }
	int FloatInstructionCount() { return (int)_desc.FloatInstructionCount; }
	int IntInstructionCount() { return (int)_desc.IntInstructionCount; }
	int UintInstructionCount() { return (int)_desc.UintInstructionCount; }
	int StaticFlowControlCount() { return (int)_desc.StaticFlowControlCount; }
	int DynamicFlowControlCount() { return (int)_desc.DynamicFlowControlCount; }
	int MacroInstructionCount() { return (int)_desc.MacroInstructionCount; }
	int ArrayInstructionCount() { return (int)_desc.ArrayInstructionCount; }
	int CutInstructionCount() { return (int)_desc.CutInstructionCount; }
	int EmitInstructionCount() { return (int)_desc.EmitInstructionCount; }
	int GSOutputTopology() { return (int)_desc.GSOutputTopology; }
	int GSMaxOutputVertexCount() { return (int)_desc.GSMaxOutputVertexCount; }
	int InputPrimitive() { return (int)_desc.InputPrimitive; }
	int PatchConstantParameters() { return (int)_desc.PatchConstantParameters; }
	int cGSInstanceCount() { return (int)_desc.cGSInstanceCount; }
	int cControlPoints() { return (int)_desc.cControlPoints; }
	int HSOutputPrimitive() { return (int)_desc.HSOutputPrimitive; }
	int HSPartitioning() { return (int)_desc.HSPartitioning; }
	int TessellatorDomain() { return (int)_desc.TessellatorDomain; }
	int cBarrierInstructions() { return (int)_desc.cBarrierInstructions; }
	int cInterlockedInstructions() { return (int)_desc.cInterlockedInstructions; }
	int cTextureStoreInstructions() { return (int)_desc.cTextureStoreInstructions; }
};

class BBD3D11_SIGNATURE_PARAMETER_DESC : public Object
{
public:
	D3D11_SIGNATURE_PARAMETER_DESC _desc;
	
	String SemanticName() { return String(_desc.SemanticName); }
	int SemanticIndex() { return (int)_desc.SemanticIndex; }
	int Register() { return (int)_desc.Register; }
	int SystemValueType() { return (int)_desc.SystemValueType; }
	int ComponentType() { return (int)_desc.ComponentType; }
	int Mask() { return (int)_desc.Mask; }
	int ReadWriteMask() { return (int)_desc.ReadWriteMask; }
};

class BBD3D11_SHADER_BUFFER_DESC : public Object 
{
public:
	D3D11_SHADER_BUFFER_DESC _desc;
	
	String Name() { return String(_desc.Name); }
	int Type() { return (int)_desc.Type; }
	int Variables() { return (int)_desc.Variables; }
	int Size() { return (int)_desc.Size; }
	int uFlags() { return (int)_desc.uFlags; }
};

class BBD3D11_SHADER_VARIABLE_DESC : public Object 
{
public:
	D3D11_SHADER_VARIABLE_DESC _desc;
	
	String Name() { return String(_desc.Name); }
	int StartOffset() { return (int)_desc.StartOffset; }
	int Size() { return (int)_desc.Size; }
	int uFlags() { return (int)_desc.uFlags; }
	//LPVOID DefaultValue;
};


class BBD3D11_SHADER_TYPE_DESC : public Object
{
public:
	D3D11_SHADER_TYPE_DESC _desc;


	int Class() { return (int)_desc.Class;}
	int Type() { return (int)_desc.Type;}
	int Rows() { return (int)_desc.Rows;}
	int Columns() { return (int)_desc.Columns;}
	int Elements() { return (int)_desc.Elements;}
	int Members() { return (int)_desc.Members;}
	int Offset() { return (int)_desc.Offset;}
	String Name() { return String(_desc.Name);}

};

//--------------------------------------------------------------------------------------

BBDataBuffer* BBD3DCompileShaderFromFile(
		String filename, String entryPoint, String target, int flags)							
{
	BBDataBuffer* buffer = 0;
/*
	ID3DBlob* compiledShader = NULL;
	ID3DBlob* errorMessages = NULL;
	LPCWSTR pFilename = (LPCWSTR)filename.ToCString<wchar_t>();
	LPCSTR pEntryPoint = (LPCSTR)entryPoint.ToCString<wchar_t>();
	LPCSTR pTarget = (LPCSTR)target.ToCString<wchar_t>();

	// compile shader from file
	HRESULT hr = D3DCompileFromFile(
			pFilename,			// shader file name
			NULL,				// macro
			NULL,				// include
			pEntryPoint,		// shader entrypoint
			pTarget,			// shader profile
			flags,				// Shader compile flags
			0,					// Effect compile flags
			&compiledShader, &errorMessages);

	// check for errors
	if ( FAILED(hr))
	{
		if ( errorMessages != 0 )
		{
			char* pCompileErrors = (char*) errorMessages->GetBufferPointer();
			int length = errorMessages->GetBufferSize();
			Print(String(pCompileErrors ,length ));
		}
	}
	else
	{
		// create databuffer
		int length = compiledShader->GetBufferSize();
		buffer = new BBDataBuffer();
		buffer->_New(length);

		// copy shader to databuffer
		auto dest = (void*)buffer->ReadPointer();
		auto src = (void*)compiledShader->GetBufferPointer();
		memcpy(dest, src, length);
	}

	SAFE_RELEASE(compiledShader);
	SAFE_RELEASE(errorMessages);
	delete[] pFilename;
	delete[] pEntryPoint;
	delete[] pTarget;
*/

	return buffer;
}

//--------------------------------------------------------------------------------------

bool BBD3DCompileShader(String shader,
		String entryPoint,			//name of the shader entry point function 
		String target,				//string that specifies the shader target or set of shader features
		String filename,			// string used in error messages..
		int flags, BBDataBuffer* outBuffer)					//combination of shader compile options
{

	bool result = true;
	
	// .ToCString works only with CHAR instead of wchar_t
	// when converting to LPCSTR here ??

	void* pSrcData = (void*)shader.ToCString<CHAR>();
	SIZE_T length = (SIZE_T)shader.Length();
	LPCSTR pEntryPoint = entryPoint.ToCString<CHAR>();
	LPCSTR pTarget = target.ToCString<CHAR>();
	LPCSTR pFilename = filename.ToCString<CHAR>();

	ID3DBlob* compiledShader = NULL;
	ID3DBlob* errorMessages = NULL;

	// compile shader 
	HRESULT hr = D3D11CompileFromMemory(pSrcData, length, pFilename, NULL, NULL,
					pEntryPoint, pTarget, flags, 0, &compiledShader, &errorMessages);

	// check for errors
	if ( FAILED(hr))
	{
		result = false;
	}
	else
	{
		// create databuffer
		int length = compiledShader->GetBufferSize();
		outBuffer->_New(length);

		// copy shader to databuffer
		auto dest = (void*)outBuffer->ReadPointer();
		auto src = (void*)compiledShader->GetBufferPointer();
		memcpy(dest, src, length);
	}
	
	if ( errorMessages != 0 )
		{
			char* pCompileErrors = (char*) errorMessages->GetBufferPointer();
			int length = errorMessages->GetBufferSize();
			Print(String(pCompileErrors ,length ));
		}
		

	SAFE_RELEASE(compiledShader);
	SAFE_RELEASE(errorMessages);
	delete[] pEntryPoint;
	delete[] pTarget;
	delete[] pFilename;
	
	return result;
}

//--------------------------------------------------------------------------------------

class BBD3D11ShaderReflectionType : public Object 
{
public:

	ID3D11ShaderReflectionType* _type;
	
	BBD3D11ShaderReflectionType(ID3D11ShaderReflectionType* type)
	{
		_type = type;
	}
	
	~BBD3D11ShaderReflectionType() 
	{
		Release();
	}
	
	virtual void Release()
	{
		// no release?
		//SAFE_RELEASE(_type);
	}

	BBD3D11_SHADER_TYPE_DESC* GetDesc()
	{
		auto desc = new BBD3D11_SHADER_TYPE_DESC();
		return FAILED(_type->GetDesc(&desc->_desc)) ? 0 : desc;
	}
	
	BBD3D11ShaderReflectionType* GetBaseClass()
	{
		auto base = _type->GetBaseClass();
		return base ? new BBD3D11ShaderReflectionType(base) : 0;
	}
		
	BBD3D11ShaderReflectionType* GetInterfaceByIndex(int index)
	{
		auto itf = _type->GetInterfaceByIndex(index);
		return itf ? new BBD3D11ShaderReflectionType(itf) : 0;
	}
		
	BBD3D11ShaderReflectionType* GetMemberTypeByIndex(int index)
	{
		auto type = _type->GetMemberTypeByIndex(index);
		return type ? new BBD3D11ShaderReflectionType(type) : 0;
	}
	
	BBD3D11ShaderReflectionType* GetSubType()
	{
		auto type = _type->GetSubType();
		return type ? new BBD3D11ShaderReflectionType(type) : 0;
	}
	
	int GetNumInterfaces()
	{
		return (int)_type->GetNumInterfaces();
	}
	
	bool ImplementsInterface(BBD3D11ShaderReflectionType* type)
	{
		return S_OK == _type->ImplementsInterface(type->_type) ? true : false;
	}
	
	bool IsEqual(BBD3D11ShaderReflectionType* type)
	{
		return S_OK == _type->IsEqual(type->_type) ? true : false;
	}
			
	bool IsOfType(BBD3D11ShaderReflectionType* type)
	{
		return S_OK == _type->IsOfType(type->_type) ? true : false;
	}		
};

class BBD3D11ShaderReflectionVariable : public BBIUnknown
{
public:

	ID3D11ShaderReflectionVariable* _var;
	
	BBD3D11ShaderReflectionVariable(ID3D11ShaderReflectionVariable* var)
	{
		_var = var;
	}
	
	~BBD3D11ShaderReflectionVariable() 
	{
		Release();
	}
	
	virtual void Release()
	{
		// no release?
		//SAFE_RELEASE(_var);
	}
	
	BBD3D11_SHADER_VARIABLE_DESC* GetDesc()
	{
		auto desc = new BBD3D11_SHADER_VARIABLE_DESC();
		return FAILED(_var->GetDesc(&desc->_desc)) ? 0 : desc;
	}
		
	int GetInterfaceSlot(int uArrayIndex)
	{
		return _var->GetInterfaceSlot((UINT) uArrayIndex );
	}
		
	BBD3D11ShaderReflectionType* GetType()
	{
		auto type = _var->GetType();
		return type ? new BBD3D11ShaderReflectionType(type) : 0;
	}
};

//--------------------------------------------------------------------------------------

class BBD3D11ShaderReflectionConstantBuffer  : public BBIUnknown
{
public:
	ID3D11ShaderReflectionConstantBuffer* _buffer;

	BBD3D11ShaderReflectionConstantBuffer(ID3D11ShaderReflectionConstantBuffer* buffer)
	{
		_buffer = buffer;
	}
	
	~BBD3D11ShaderReflectionConstantBuffer() 
	{
		Release();
	}
	
	virtual void Release()
	{
		// no release?
		// SAFE_RELEASE(_buffer);
	}
	
	BBD3D11_SHADER_BUFFER_DESC* GetDesc()
	{
		auto desc = new BBD3D11_SHADER_BUFFER_DESC();
		
		DXASS(_buffer->GetDesc(&(desc->_desc)));
			
		return desc;
	}
		
	BBD3D11ShaderReflectionVariable* GetVariableByIndex(int index)
	{
		auto var = _buffer->GetVariableByIndex(index);
		return var ? new BBD3D11ShaderReflectionVariable(var) : 0;
	}	
};

//--------------------------------------------------------------------------------------

class BBD3D11ShaderReflection: public BBIUnknown
{
public:
	ID3D11ShaderReflection* _reflector;

	BBD3D11ShaderReflection(ID3D11ShaderReflection* reflector)
	{
		_reflector = reflector;
	}

	~BBD3D11ShaderReflection() 
	{
		Release();
	}
	
	virtual void Release()
	{
		SAFE_RELEASE(_reflector);
	}
	
	BBD3D11_SHADER_DESC* GetDesc()
	{
		auto desc = new BBD3D11_SHADER_DESC();
		DXASS(_reflector->GetDesc(&(desc->_desc)));
		return desc;
	}
	
	BBD3D11_SIGNATURE_PARAMETER_DESC* GetInputParameterDesc(int index)
	{
		auto desc = new BBD3D11_SIGNATURE_PARAMETER_DESC();
		
		DXASS(
			_reflector->GetInputParameterDesc(index, &desc->_desc));
		
		return desc;
	}
	
	BBD3D11_SIGNATURE_PARAMETER_DESC* GetOutputParameterDesc(int index)
	{
		auto desc = new BBD3D11_SIGNATURE_PARAMETER_DESC();
		
		DXASS(
			_reflector->GetOutputParameterDesc(index, &desc->_desc));
		
		return desc;
	}
	
	BBD3D11ShaderReflectionConstantBuffer* GetConstantBufferByIndex(int index)
	{
		auto buffer = _reflector->GetConstantBufferByIndex( index );
		
		if(buffer)
		{
			return new BBD3D11ShaderReflectionConstantBuffer(buffer);
		}
		
		return 0;
	};	
};

//--------------------------------------------------------------------------------------

BBD3D11ShaderReflection* BBD3DReflect(BBDataBuffer* comiledShader)
{
	ID3D11ShaderReflection* pReflector = NULL;

	void* ptr = (void*)comiledShader->ReadPointer();
	int length = comiledShader->Length();
	DXASS(D3D11ReflectShader(ptr, length, IID_ID3D11ShaderReflection, (void**)&pReflector));	

	return new BBD3D11ShaderReflection(pReflector);
}


