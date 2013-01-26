
''--------------------------------------------------------
'' Windows 8 MiniB3D Driver
'' (C) 2012 Sascha Schmidt
''--------------------------------------------------------


'' *** Notes *** 
''
'' -- cbuffer needs to be 64 bit aligned !!!
'' -- parameters are cached(d3d11buffer is updated through D3D11Shader.Apply)
'' -- buffers with identical names are automatically shared to VS and PS
''
''


Import brl
Import minib3d

''---------------

Class D3D11Shader extends TShader implements IShader 

Private 

	Const HLSL_VS_ENTRY_POINT$="vs_main"
	Const HLSL_PS_ENTRY_POINT$="ps_main"
	Const HLSL_VS_SHADER_PROFILE$="vs_4_0_level_9_3"
	Const HLSL_PS_SHADER_PROFILE$="ps_4_0_level_9_3"
	Const VERTEX_SHADER = 0
	Const PIXEL_SHADER = 1
	
	''---------------
	
	Global SHADER_ID = 0
	Global _inputLayout:D3D11InputLayout
	
	''---------------

	'' internal shader objects
	Field _vertexShader:D3D11VertexShader 
	Field _pixelShader:D3D11PixelShader 
	
	'' compiled shader bytecode
	Field _vsByteCode:DataBuffer
	Field _psByteCode:DataBuffer
	
	Field _name:String
	Field _variables:= New ShaderParameterCollection' from all _buffers
	Field _buffers:= new List<D3D11ConstantBuffer> 
	Field _vsBuffers:D3D11Buffer[]
	Field _psBuffers:D3D11Buffer[]
	
	
Public 
	
	Method New()
		SHADER_ID+=1
		shader_id = SHADER_ID
	End 
	
	Method Load( vp_file:String, fp_file:String)
	
		Release()
		
		_name = vp_file+"/"+fp_file

		'' use precompiled shader in distributed apps 
		#If MINIB3D_D3D11_RELEASE="true" 
		
			Local fp_bin_file:= fp_file.Replace("txt", "ps.txt")
			Local vp_bin_file:= vp_file.Replace("txt", "vs.txt")
			
			_vsByteCode = LoadCompiledShader(vp_bin_file)
			_psByteCode = LoadCompiledShader(fp_bin_file)
			
			Local vsShaderInfo:= LoadShaderReflection(vp_bin_file)
			Local psShaderInfo:= LoadShaderReflection(fp_bin_file)
		
		'' runtime shader compilation during developing
		#Else
		
			'' compile shaders & save bytecode
			Local vs:= CompileShader(LoadString(vp_file), VERTEX_SHADER )
			Local ps:= CompileShader(LoadString(fp_file), PIXEL_SHADER )
			If Not(vs And ps) Then 
				Error "**compiler error: "+vp_file+" "+vs+", "+fp_file+" "+ps
			End
			Print "..shader success: "+vp_file+" "+fp_file
			
			Local fp_bin_file:= fp_file.Replace("txt", "ps.txt")
			Local vp_bin_file:= vp_file.Replace("txt", "vs.txt")
			
			' save compiled shaders to local storage
			SaveCompiledShader(_psByteCode, fp_bin_file)
			SaveCompiledShader(_vsByteCode, vp_bin_file)
			
			' reflect shaders
			Local vsShaderInfo:= GetShader(_vsByteCode)
			Local psShaderInfo:= GetShader(_psByteCode)
			
			' save reflection info to local storage
			SaveShaderReflection(vsShaderInfo, vp_bin_file)
			SaveShaderReflection(psShaderInfo, fp_bin_file)
				
		#End 

		' create shaders from buffers
		_vertexShader 	= D3D11.Device.CreateVertexShader(_vsByteCode)
		_pixelShader 	= D3D11.Device.CreatePixelShader(_psByteCode)
		
		' init variables from shader reflection info
		InitVariables( vsShaderInfo.ConstantBuffers, psShaderInfo.ConstantBuffers )	
		
		' init global vertex fomat description if necessary
		' *** TODO *** --- See BBD3D11InputLayout* BBD3D11Device::CreateInputLayout in d3d11.cpp
		If Not _inputLayout Then 
			
			Local e0:= New D3D11_INPUT_ELEMENT_DESC().Create("POSITION",  0, DXGI_FORMAT_R32G32B32_FLOAT, 0, 0,  D3D11_INPUT_PER_VERTEX_DATA,0)
			Local e1:= New D3D11_INPUT_ELEMENT_DESC().Create("NORMAL",	  0, DXGI_FORMAT_R32G32B32_FLOAT, 0, 16, D3D11_INPUT_PER_VERTEX_DATA,0)
			Local e2:= New D3D11_INPUT_ELEMENT_DESC().Create("COLOR",	  0, DXGI_FORMAT_R32G32B32_FLOAT, 0, 32, D3D11_INPUT_PER_VERTEX_DATA,0)
			Local e3:= New D3D11_INPUT_ELEMENT_DESC().Create("TEXCOORD",  0, DXGI_FORMAT_R32G32_FLOAT, 	  0, 48, D3D11_INPUT_PER_VERTEX_DATA,0)
			Local e4:= New D3D11_INPUT_ELEMENT_DESC().Create("TEXCOORD",  1, DXGI_FORMAT_R32G32_FLOAT, 	  0, 56, D3D11_INPUT_PER_VERTEX_DATA,0)					
			
			_inputLayout= D3D11.Device.CreateInputLayout([e0,e1,e2,e3,e4],_vsByteCode)
			
		End 
		
		' bytecode not longer needed
		_vsByteCode.Discard()
		_psByteCode.Discard()
		
		''PrintShader(Self)
	End 
	
	Method InputLayout:D3D11InputLayout() Property 
		Return _inputLayout
	End 
	
	''
	'' TShader
	''

	Function LoadDefaultShader:Void(vp_file:String, fp_file:String) 'Abstract
		''load default shader on graphics init
		default_shader = D3D11Shader.LoadShader(vp_file, fp_file)
		default_shader.name = "DefaultShader"
		SetShader( default_shader )
	End
	
	#rem -- TODO
	Function LoadShader:D3D11Shader(vp_file:String, fp_file:String, sh:TShader = null) 

		Local shader:D3D11Shader
		
		If sh<>Null
			shader = D3D11Shader(sh)
		Else
			shader = D3D11Shader(D3D11Render(TRender.render).CreateShader(Self, vp_file, fp_file))
		Endif

		shader.Load(vp_file, fp_file)
		
		Return shader
	End
	#end 
	
	
	' needs to be protected
	Method CompileShader:Int(source:String, type:Int) 
		#If MINIB3D_D3D11_RELEASE="true"
			Error "D3D11Render.CompileShader is only supported during development"
			Return 0
		#else
			Local result = 0
			
			If type = 0 Then 
				_vsByteCode = New DataBuffer()
				result = D3DCompileShader(source, HLSL_VS_ENTRY_POINT, HLSL_VS_SHADER_PROFILE,"",0,_vsByteCode)
				
			Elseif type = 1
				_psByteCode = New DataBuffer()
				result = D3DCompileShader(source, HLSL_PS_ENTRY_POINT, HLSL_PS_SHADER_PROFILE,"",0,_psByteCode)
			End 
			
			Return result
		#End 
	End 
	
	Method Copy:TBrush()
		
		Local brush:D3D11Shader =New D3D11Shader
	
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
						
		'' **** TODO ****
		
		Return brush

	End 
	
	''
	'' IShader
	''
	
	Method Parameters:ShaderParameterCollection() Property
	
		Return _variables
		
	End 
	
	Method Apply()
	
		'' update internal constants
		For Local b:= eachin _buffers
			b.Update()
		End 

	End 
	
	
	Method Bind()
	
		D3D11.DeviceContext.IASetInputLayout( _inputLayout)
		D3D11.DeviceContext.PSSetConstantBuffers( 0, _psBuffers)
		D3D11.DeviceContext.VSSetConstantBuffers( 0, _vsBuffers)
		D3D11.DeviceContext.VSSetShader( _vertexShader)
		D3D11.DeviceContext.PSSetShader( _pixelShader)
		
	End 
	
	Method Release()
	
		if _vertexShader Then 
			_vertexShader.Release()
			_vertexShader = null
		Endif
		
		If _pixelShader Then 
			_pixelShader.Release()
			_pixelShader = Null 
		End 
		
		For Local i:= 0 Until _psBuffers.Length
			If _psBuffers[i] Then 
				_psBuffers[i].Release()
				_psBuffers[i] = Null 
			End 
		End 
		
		For Local i:= 0 Until _vsBuffers.Length
			If _vsBuffers[i] Then 
				_vsBuffers[i].Release()
				_vsBuffers[i] = Null 
			End 
		End 
		
	End 
	
	Method Name:String()
	
		Return _name
		
	End 
	
Private 

	''
	'' internal 
	''
	
	Method LoadCompiledShader:DataBuffer(file$)
	
		Local stream:= New FileStream("monkey://data/" +file.Replace(".txt", ".bin"), "r")
		Local length:= stream.ReadInt()
		Local buffer:= New DataBuffer(length)

		For Local i= 0 Until length
			buffer.PokeByte(i,stream.ReadByte())
		End 
		
		stream.Close()
		
		Return buffer
	End
	 
	Method SaveCompiledShader(dataBuffer:DataBuffer, file$)
	
		Local stream:= New FileStream("monkey://internal/" + file.Replace(".txt", ".bin"), "w")
		
		Local length = dataBuffer.Length
		
		stream.WriteInt(length)
		
		For Local i= 0 Until length
			stream.WriteByte( dataBuffer.PeekByte(i) )
		End 
		
		stream.Close()
		
	End 
	
	Method LoadShaderReflection:ShaderInfo(file$)
		
		Local stream:= New FileStream("monkey://data/" +file.Replace(".txt", ".refl.bin"), "r")
		Local info:= New ShaderInfo(stream) 
		stream.Close()
		
		Return info
		
	End 
	
	Method SaveShaderReflection:Void(info:ShaderInfo, file$)
	
		Local stream:= New FileStream("monkey://internal/" +file.Replace(".txt", ".refl.bin"), "w")
		info.Save( stream)
		stream.Close()
		
	End 
	
	Method InitVariables:Void(vs_infos:ShaderBufferInfo[], ps_infos:ShaderBufferInfo[])
		
		_variables.Clear()
		_vsBuffers = _vsBuffers.Resize(vs_infos.Length)
		_psBuffers = _psBuffers.Resize(ps_infos.Length)
		
		Local tmp:= New Object 
		Local nameDict:= New StringMap<D3D11ConstantBuffer>
		
		Local _vsBufferCount = 0
		For Local info:= Eachin vs_infos
		
			Local b:= AddBuffer(info)
			_vsBuffers[_vsBufferCount] = b._buffer
			nameDict.Set( info.Name, b)
			_vsBufferCount+=1
			
		End 
		
		Local _psBufferCount = 0
		For Local info:= Eachin ps_infos
		
			Local b:= nameDict.Get(info.Name)
			If Not b Then '' buffers with the same name are shared
				b = AddBuffer(info)
			End 
			
			_psBuffers[_psBufferCount] = b._buffer
			_psBufferCount+=1
		End 

	End 
	
	Method AddBuffer:D3D11ConstantBuffer( buffer:ShaderBufferInfo )
	
		Local constBuffer:= New D3D11ConstantBuffer( buffer.Name, buffer.Size)

		For Local i = 0 until buffer.Variables.Length
			Local pInfo:= buffer.Variables[i]
			_variables.AddLast(CreateParameter(pInfo,pInfo.Type, pInfo.StartOffset, constBuffer) )
		End 
		
		_buffers.AddLast(constBuffer)
		
		Return constBuffer
				
	End 

	Method CreateParameter:D3D11ShaderParameter(info:ShaderVariableInfo, type:ShaderTypeInfo, offset:Int, buffer:D3D11ConstantBuffer)

		Local param:=  New D3D11ShaderParameter
		
		If info Then 
			param._name = info.Name 
			param._size = info.Size
		End 
		
		param._parameterType = type.Type 
		param._parameterClass = type.Class_
		param._rowCount = type.Rows
		param._columnCount = type.Columns
		param._index = offset + type.Offset
		param._buffer = buffer
		param._dataBuffer = buffer._data
		param._elements = param._elements.Resize(type.Elements)
		Local elements = type.Elements
		Local members:= type.Members
		 
		If elements Then 
			
			Local typeSize:= param._rowCount*param._columnCount*4' -- 32bit per element???
			type.Elements = 0'prevent array of array
			
			For Local i= 0 Until elements
				param._elements[i]  = CreateParameter(Null, type,  offset + i*typeSize, buffer)
			End 
			
		Else
			Select param._parameterClass
				Case D3D_SVC_STRUCT
				
					param._structureMembers = param._structureMembers.Resize( members.Length )
					For Local j = 0 Until members.Length
						param._structureMembers[j] = CreateParameter(Null, members[j], offset, buffer )
					End 
			End 
		End 
		
		Return param
	End 	
End 

 '----------------------------------------------------------

Class D3D11ShaderParameter implements IShaderParameter 
Private 

	Field _name:String 
	Field _parameterType:Int 
	Field _parameterClass:Int 
	Field _rowCount:Int 
	Field _columnCount:int
	Field _elements:IShaderParameter[]
	Field _structureMembers:IShaderParameter[]
	
	Field _buffer:D3D11ConstantBuffer ' associated buffer
	Field _dataBuffer:DataBuffer' memory copy of _buffer
	Field _index:Int = 0' index of this variable in _buffer
	Field _size = 0

Public 

	Method Name:String() Property 
		Return _name
	End 
	
	Method Index:Int()
		Return _index
	End 
	
	Method Size:Int()
		Return _size
	End
	 
	Method ParameterType:Int() Property 
		Return _parameterType
	End 
	
	Method ParameterClass:Int() Property 
		Return _parameterClass
	End 

	Method Elements:IShaderParameter[]() Property 
		Return _elements
	End 
	
	Method StructureMembers:IShaderParameter[]() Property 
		Return _structureMembers
	End 
	
	Method RowCount:Int() Property 
		Return _rowCount
	End 
	
	Method ColumnCount() Property
		Return _columnCount
	End 
	
	Method SetValue:Void(value:Vector) 
		_dataBuffer.PokeFloat(_index, value.x)
		_dataBuffer.PokeFloat(_index+4, value.y)
		_dataBuffer.PokeFloat(_index+8, value.z)
		_buffer._needUpdate = True 
	End 
	
	Method SetValue:Void(value:Matrix) 
	
		'' *** TODO ***
		'' Specify D3DXSHADER_PACKMATRIX_COLUMMAJOR per default
		
		For Local row:= 0 Until _rowCount
			For Local column:= 0 Until _columnCount 
				_dataBuffer.PokeFloat(_index+(column * _rowCount + row)*4, value.grid[row][column])
			End 
		End 
	
		_buffer._needUpdate = True 
		
	End 
	
	Method SetValue:Void(value:Int[]) 
		Local length=value.Length
		For Local i = 0 Until length
			_dataBuffer.PokeInt(_index+i*4, value[i])
		End  
		_buffer._needUpdate = True 
	End 
	
	Method SetValue:Void(value:Float[]) 
		Local length=value.Length
		For Local i = 0 Until length
			_dataBuffer.PokeFloat(_index+i*4, value[i])
		End  
		_buffer._needUpdate = True 
	End 
	 
	Method SetValue:Void(v0#) 
		_dataBuffer.PokeFloat(_index, v0)
		_buffer._needUpdate = True 
	End 
	
	Method SetValue:Void(v0#,v1#) 
		_dataBuffer.PokeFloat(_index, v0)
		_dataBuffer.PokeFloat(_index+4,v1)
		_buffer._needUpdate = True 
	End 
	 
	Method SetValue:Void(v0#,v1#,v2#) 
		_dataBuffer.PokeFloat(_index, v0)
		_dataBuffer.PokeFloat(_index+4,v1)
		_dataBuffer.PokeFloat(_index+8, v2)
		_buffer._needUpdate = True 
	End 
	
	Method SetValue:Void(v0#,v1#,v2#,v3#) 
		_dataBuffer.PokeFloat(_index, v0)
		_dataBuffer.PokeFloat(_index+4,v1)
		_dataBuffer.PokeFloat(_index+8, v2)
		_dataBuffer.PokeFloat(_index+12, v3)
		_buffer._needUpdate = True 
	End 
	
	Method SetValue:Void(v0%) 
		_dataBuffer.PokeInt(_index, v0)
		_buffer._needUpdate = True 
	End 
	
	Method SetValue:Void(v0%,v1%) 
		_dataBuffer.PokeInt(_index, v0)
		_dataBuffer.PokeInt(_index+4,v1)
		_buffer._needUpdate = True 
	End 
	 
	Method SetValue:Void(v0%,v1%,v2%) 
		_dataBuffer.PokeInt(_index, v0)
		_dataBuffer.PokeInt(_index+4,v1)
		_dataBuffer.PokeInt(_index+8, v2)
		_buffer._needUpdate = True 
	End 
	
	Method SetValue:Void(v0%,v1%,v2%,v3%) 
		_dataBuffer.PokeInt(_index, v0)
		_dataBuffer.PokeInt(_index+4,v1)
		_dataBuffer.PokeInt(_index+8, v2)
		_dataBuffer.PokeInt(_index+12, v3)
		_buffer._needUpdate = True 
	End 
	
	Method SetValue:Void(v0?)
		_dataBuffer.PokeInt(_index, v0)
		_buffer._needUpdate = True 
	End 
	
	Method SetValue:Void(v0?,v1?)
		_dataBuffer.PokeInt(_index, v0)
		_dataBuffer.PokeInt(_index+4,v1)
		_buffer._needUpdate = True 
	End 
	
	Method SetValue:Void(v0?,v1?,v2?)
		_dataBuffer.PokeInt(_index, v0)
		_dataBuffer.PokeInt(_index+4,v1)
		_dataBuffer.PokeInt(_index+8, v2)
		_buffer._needUpdate = True 
	End 
	
	Method SetValue:Void(v0?,v1?,v2?, v3?)
		_dataBuffer.PokeInt(_index, v0)
		_dataBuffer.PokeInt(_index+4,v1)
		_dataBuffer.PokeInt(_index+8, v2)
		_dataBuffer.PokeInt(_index+12, v3)
		_buffer._needUpdate = True 
	End 
	
End

'------------------------------------------------------------------------------------

'' wrapper around D3D constant buffer

Class D3D11ConstantBuffer

	Field _buffer:D3D11Buffer 
	Field _data:DataBuffer ' memory copy
	Field _needUpdate? ' indicates if any of the buffer's variables have been changed
	Field _name:String 
	Field _register:Int 
	Field _size:Int 
	
	Method New( name:String, bufferSize)
	
		local desc:= new D3D11_BUFFER_DESC
			desc.Usage = D3D11_USAGE_DYNAMIC;
			desc.BindFlags = D3D11_BIND_CONSTANT_BUFFER;
			desc.CPUAccessFlags = D3D11_CPU_ACCESS_WRITE;
			desc.MiscFlags = 0;
			desc.ByteWidth = bufferSize

		_buffer = D3D11.Device.CreateBuffer(desc, Null)
		_data = New DataBuffer(bufferSize);
		_size = bufferSize
		_name = name
	End 
	
	Method Update()
		if _needUpdate Then 
			_needUpdate = False 
			D3D11.DeviceContext.Map(_buffer,0,D3D11_MAP_WRITE_DISCARD,0).SetData(_data,_size)
			D3D11.DeviceContext.Unmap(_buffer,0)
		Endif
	End
	
End