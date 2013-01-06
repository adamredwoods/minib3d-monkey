
//--------------------------------------------------------------------------------------
// Windows8 MiniB3D driver
// (C) 2012 Sascha Schmidt
//--------------------------------------------------------------------------------------

#ifndef SAFE_RELEASE
#define SAFE_RELEASE(p)      { if (p) { (p)->Release(); (p)=NULL; } }
#endif

class BBIUnknown;
class BBD3D11DeviceChild;
class BBD3D11GraphicsResource;
class BBD3D11Device;
class BBD3D11DeviceContext;
class BBD3D11BlendState;
class BBD3D11RasterizerState;
class BBD3D11SamplerState;
class BBD3D11DepthStencilState;
class BBD3D11DepthStencilView;
class BBD3D11RenderTargetView;
class BBD3D11Texture2D;
class BBD3D11Texture;
class BBD3D11Buffer;
class BBD3D11BufferData;
class BBD3D11VertexShader;
class BBD3D11PixelShader;
class BBD3D11InputLayout;

class BBD3D11_RENDER_TARGET_BLEND_DESC;
class BBD3D11_DEPTH_STENCILOP_DESC;
class BBD3D11_DEPTH_SAMPLER_DESC;
class BBD3D11_DEPTH_STENCIL_VIEW_DESC;
class BBD3D11_RENDER_TARGET_VIEW_DESC;
class BBD3D11_BUFFER_DESC;
class BBD3D11_INPUT_ELEMENT_DESC;
class BBD3D11_BLEND_DESC;
class BBD3D11_DEPTH_STENCIL_DESC;
class BBD3D11_SAMPLER_DESC;
class BBD3D11_RASTERIZER_DESC;
class BBD3D11_VIEWPORT;
class BBD3D11_TEXTURE2D_DESC;
class BBD3D11_SUBRESOURCE_DATA;
class BBD3D11_SHADER_RESOURCE_VIEW_DESC;
class BBD3D11_TEX2D_SRV;

struct B3DVertex
{
	float x,y,z,w;
	float nx,ny,nz,nw;
	float r,g,b,a;
	float u0,v0,u1,v1;
};

struct B3DVector
{
	float x,y,z;
};

void UpdateVertexDataBufferPositions(BBDataBuffer* destVertexDataBuffer, BBDataBuffer* floatBuffer, int count)
{
	B3DVertex* dest = (B3DVertex*)destVertexDataBuffer->ReadPointer();
	B3DVector* src = (B3DVector*)floatBuffer->ReadPointer();
	B3DVector* end = src + count;

	do
	{
		*(B3DVector*)dest++ = *src++;
	}
	while(src!=end);
	
	/*
	for( int i = 0; i < count; ++i)
	{
		dest->x = src->x;
		dest->y = src->y;
		dest->z = src->z;
		dest++;
		src++;
	}
	*/
}

void Print_Monkey_Internal()
{
	auto folder=Windows::Storage::ApplicationData::Current->LocalFolder;
	Print(String( folder->Path ));
}

bool BBD3D11LoadImageData(BBDataBuffer* buffer, String path, Array<int> info)
{
	int width,height,format;
	unsigned char *data=BBWin8Game::Win8Game()->LoadImageData( path,&width,&height,&format );
	if( ! data ) 
	{
		return false;
	}

	if( format==4 ){

		buffer->_New(width*height*4);
		memcpy((void*)buffer->ReadPointer(0), (void*)data,  width*height*4 );
		free( data );

	}else{
		Print( String( "Bad image format: path=" )+path+", format="+format );
		free( data );
		return 0;
	}
	
	info[0] = width;
	info[1] = height;
	info[2] = format;

	return true;
}

//--------------------------------------------------------------------------------------

class BBIUnknown : public Object
{
public:
	virtual void Release() = 0;
};

//--------------------------------------------------------------------------------------

class BBD3D11DeviceChild : public BBIUnknown
{
public:
	BBD3D11Device* _device;

	BBD3D11DeviceChild(BBD3D11Device* device);
	BBD3D11Device* GetDevice();
};

//--------------------------------------------------------------------------------------

class BBD3D11Resource : public BBD3D11DeviceChild
{
public:
	int _resourceType;
	ID3D11Resource* _res;
	
	BBD3D11Resource(BBD3D11Device* device, ID3D11Resource* res, int type);
	int GetType();

	virtual void Release()
	{
		SAFE_RELEASE(_res);
	}
};

//--------------------------------------------------------------------------------------

class BBD3D11BlendState : public BBD3D11DeviceChild
{
public:
	ID3D11BlendState* _state;

	BBD3D11BlendState(BBD3D11Device* device, ID3D11BlendState* state);
	~BBD3D11BlendState();
	virtual void Release();
};

//---------------------------------------------------------------------------------------

class BBD3D11RasterizerState : public BBD3D11DeviceChild
{
public:
	ID3D11RasterizerState* _state;
	
	BBD3D11RasterizerState(BBD3D11Device* device,ID3D11RasterizerState* state);
	~BBD3D11RasterizerState();
	virtual void Release();
};

//--------------------------------------------------------------------------------------

class BBD3D11SamplerState : public BBD3D11DeviceChild
{
public:
	ID3D11SamplerState* _state;
	
	BBD3D11SamplerState(BBD3D11Device* device,ID3D11SamplerState* state);
	~BBD3D11SamplerState();
	virtual void Release();
};

//--------------------------------------------------------------------------------------

class BBD3D11DepthStencilState : public BBD3D11DeviceChild
{
public:
	ID3D11DepthStencilState* _state;

	BBD3D11DepthStencilState(BBD3D11Device* device, ID3D11DepthStencilState* state);
	~BBD3D11DepthStencilState();
	virtual void Release();
};

//-------------------------------------------------------------------------------------- 

class BBD3D11VertexShader : public BBD3D11DeviceChild
{
public:
	ID3D11VertexShader* _shader;
	
	BBD3D11VertexShader(BBD3D11Device* device,ID3D11VertexShader* shader );
	~BBD3D11VertexShader();
	virtual void Release();
};

//-------------------------------------------------------------------------------------- 

class BBD3D11PixelShader : public BBD3D11DeviceChild
{
public:
	ID3D11PixelShader* _shader;
	
	BBD3D11PixelShader(BBD3D11Device* device,ID3D11PixelShader* shader );
	~BBD3D11PixelShader();
	virtual void Release();
};

//-------------------------------------------------------------------------------------- 

class BBD3D11Texture2D : public BBD3D11Resource
{
public:
	ID3D11Texture2D* _texture;

	BBD3D11Texture2D(BBD3D11Device* device, ID3D11Texture2D* texture);
	~BBD3D11Texture2D();
    virtual void Release();
};

//--------------------------------------------------------------------------------------

class BBD3D11InputLayout : public BBD3D11DeviceChild
{
public:
	ID3D11InputLayout* _layout;

	BBD3D11InputLayout(BBD3D11Device* device,ID3D11InputLayout* layout) ;
	~BBD3D11InputLayout();
	virtual void Release();
};

//--------------------------------------------------------------------------------------

class BBD3D11Buffer : public BBD3D11Resource
{
public:
	ID3D11Buffer* _buffer;
	
	BBD3D11Buffer(BBD3D11Device* device,ID3D11Buffer* buffer);
	~BBD3D11Buffer();
	virtual void Release();
};

//--------------------------------------------------------------------------------------

class D3D11BufferData : public Object
{
public:
	unsigned char* _ptr;
	D3D11_MAPPED_SUBRESOURCE _mappedResource;

	int RowPitch();
	int DepthPitch();
	void SetData(BBDataBuffer* data, int size);
};

class BBD3D11View : public BBD3D11DeviceChild
{
public:
	ID3D11View* _view;

	BBD3D11View(BBD3D11Device* device,ID3D11View* view) ;
	~BBD3D11View();
	virtual void Release();
	BBD3D11Resource* GetResource();
};

//--------------------------------------------------------------------------------------

class BBD3D11DepthStencilView : public BBD3D11View
{
public:
	ID3D11DepthStencilView* _depthStencilView;

	BBD3D11DepthStencilView(BBD3D11Device* device,ID3D11DepthStencilView* view) ;
	~BBD3D11DepthStencilView();
	BBD3D11_DEPTH_STENCIL_VIEW_DESC* GetDesc();
};

//--------------------------------------------------------------------------------------

class BBD3D11RenderTargetView : public BBD3D11View
{
public:
	ID3D11RenderTargetView* _renderTargetView;

	BBD3D11RenderTargetView(BBD3D11Device* device,ID3D11RenderTargetView* view) ;
	~BBD3D11RenderTargetView();
	BBD3D11_RENDER_TARGET_VIEW_DESC* GetDesc();
};

//--------------------------------------------------------------------------------------

class BBD3D11ShaderResourceView : public BBD3D11View
{
public:
	ID3D11ShaderResourceView* _shaderResourceView;

	BBD3D11ShaderResourceView(BBD3D11Device* device,ID3D11ShaderResourceView* view);
	~BBD3D11ShaderResourceView();
	BBD3D11_SHADER_RESOURCE_VIEW_DESC* GetDesc();
}; 

//--------------------------------------------------------------------------------------

class BBD3D11Device : public BBIUnknown
{
public:
	ID3D11Device* _device;
	D3D11_SUBRESOURCE_DATA* _pInitialData[256];
	
	BBD3D11Device();
	~BBD3D11Device();
	virtual void Release();
	// TODO --- D3D11BufferData* CheckFeatureSupport(int d3d11Feature);
	BBD3D11BlendState* CreateBlendState(BBD3D11_BLEND_DESC* desc);
	BBD3D11Buffer* CreateBuffer(BBD3D11_BUFFER_DESC* desc, BBD3D11_SUBRESOURCE_DATA* initialData);	
	BBD3D11DepthStencilState* CreateDepthStencilState(BBD3D11_DEPTH_STENCIL_DESC* desc);
	BBD3D11DepthStencilView* CreateDepthStencilView(BBD3D11Resource* res, BBD3D11_DEPTH_STENCIL_VIEW_DESC* desc);
	BBD3D11InputLayout* CreateInputLayout(Array<BBD3D11_INPUT_ELEMENT_DESC*> inputElements, BBDataBuffer* shaderByteCodeWithInputSignature);
	BBD3D11PixelShader* CreatePixelShader(BBDataBuffer* shaderByteCode);
	BBD3D11RasterizerState* CreateRasterizerState(BBD3D11_RASTERIZER_DESC* desc);
	BBD3D11SamplerState* CreateSamplerState(BBD3D11_SAMPLER_DESC* desc);
	BBD3D11Texture2D* CreateTexture2D(BBD3D11_TEXTURE2D_DESC* desc, Array<BBD3D11_SUBRESOURCE_DATA*> initialData);
	BBD3D11VertexShader* CreateVertexShader(BBDataBuffer* shaderByteCode);
	BBD3D11DeviceContext* GetImmediateContext();
	BBD3D11RenderTargetView* GetBBWin8GameRenderTargetView();
	BBD3D11RenderTargetView* GetBackBuffer();
	BBD3D11ShaderResourceView* CreateShaderResourceView(BBD3D11Texture2D* tex, BBD3D11_SHADER_RESOURCE_VIEW_DESC* desc);
	int CheckFormatSupport(int dxgi_format);
	int CheckMultisampleQualityLevels(int gxgiFormat, int sampleCount);
	int GetCreationFlags();	
	int GetDeviceRemovedReason();	
	int GetExceptionMode();
	int GetFeatureLevel();
};

//---------------------------------------------------------------------------------------

class BBD3D11DeviceContext : public BBD3D11DeviceChild
{
public:
	ID3D11DeviceContext* _deviceContext;
	ID3D11RenderTargetView* _pRenderTargets[8];
	ID3D11SamplerState* _pSampelerStates[256];
	ID3D11ShaderResourceView* _pShaderResourceViews[256];
	ID3D11Buffer* _pD3D11Buffer[256];
	D3D11_VIEWPORT* _pViewports[256];
	UINT _strides[256];
	UINT _offsets[256];
	FLOAT _blendFactor[4];
	

	BBD3D11DeviceContext(BBD3D11Device* device);
	~BBD3D11DeviceContext();
	virtual void Release();
	void ClearRenderTargetView(BBD3D11RenderTargetView* view, float r,float g,float b );
	void ClearDepthStancilView(BBD3D11DepthStencilView* view, int flags, float depth, int stencil);
	void OMSetRenderTargets(Array<BBD3D11RenderTargetView*> renderTargetViews, BBD3D11DepthStencilView* depthStencilView);
	
	int GetContextFlags();	
	int GetType();	
	void ClearState();
	void Draw(int vertexCount, int offset );
	void DrawAuto();	
	void DrawIndexed(int indexCount, int startIndexLoc, int baseVertLoc );	
	// TODO -- void DrawIndexedInstanced(int indexCountPerInst, int instount, int stratIndexLoc, int baseVertexLoc, int startInstLoc);
	void DrawInstanced(int vertexCountPerInst, int instCount, int startVertLoc, int StartInstLoc);	
	void IASetIndexBuffer(BBD3D11Buffer* indexBuffer, int format, int offset);
	void IASetInputLayout( BBD3D11InputLayout* inputLayout);
	void IASetPrimitiveTopology(int topology);
	void IASetVertexBuffers( int stratSlot, int num_buffers,Array<BBD3D11Buffer*> vertexBuffers, Array<int> strides, Array<int> offsets);
	D3D11BufferData* Map(BBD3D11Resource* resource, int subResource, int mapType, int mapFlags);
	void OMSetBlendState( BBD3D11BlendState* blendState);// Array<float> blendFactor, int sampleMask );
	void OMSetDepthStencilState( BBD3D11DepthStencilState* state, int stencilRef);
	void PSSetConstantBuffers(int startSlot, Array<BBD3D11Buffer*> constantBuffers);
	void PSSetSamplers(int startSlot, int num_samplers, Array<BBD3D11SamplerState*> samplers);	
	void PSSetShader( BBD3D11PixelShader* pixelShader);
	void PSSetShaderResources(int startSlot, int numViews, Array<BBD3D11ShaderResourceView*> shaedrResourceViews );
	void RSSetState( BBD3D11RasterizerState* resterizerState );
	void RSSetViewports( Array<BBD3D11_VIEWPORT*> viewports );
	void Unmap( BBD3D11Resource* resource, int subResource );
	void VSSetConstantBuffers(int startSlot, Array<BBD3D11Buffer*> constantBuffers);
	void VSSetSamplers(int startSlot, Array<BBD3D11SamplerState*> samplers);	
	void VSSetShader( BBD3D11VertexShader* vertexShader);
	void GenerateMips(BBD3D11ShaderResourceView* resourceView);
	void UpdateSubresource( BBD3D11Resource* pDstResource, int DstSubresource, int x, int y, int width, int height, BBDataBuffer* srcData, int pitch, int depth);
}; 

//--------------------------------------------------------------------------------------

class BBD3D11_TEX2D_SRV : public Object
{
public:
	D3D11_TEX2D_SRV _srv;
	
	BBD3D11_TEX2D_SRV(){ZEROMEM( _srv );}
	int GetMostDetailedMipMap(){ return (int)_srv.MostDetailedMip;}
	int GetMipLevels(){return (int)_srv.MipLevels;}
	void SetMostDetailedMipMap(int value){_srv.MostDetailedMip = (UINT)value;}
	void SetMipLevels(int value){_srv.MipLevels = (UINT)value;}
};


//--------------------------------------------------------------------------------------

class BBD3D11_SHADER_RESOURCE_VIEW_DESC : public Object
{
public: 

	D3D11_SHADER_RESOURCE_VIEW_DESC _desc;
	
	BBD3D11_SHADER_RESOURCE_VIEW_DESC(){ZEROMEM( _desc );}
	int GetFormat(){return (int)_desc.Format;}
	void SetFormat(int value){_desc.Format = (DXGI_FORMAT)value;}
	int GetViewDimension(){return (int)_desc.ViewDimension;}
	void SetViewDimension(int value){ _desc.ViewDimension = (D3D11_SRV_DIMENSION)value;}
	void SetTexture2D(BBD3D11_TEX2D_SRV* value){ _desc.Texture2D = value->_srv;}
};

//--------------------------------------------------------------------------------------

class BBD3D11_RENDER_TARGET_VIEW_DESC : public Object
{
public:
	D3D11_RENDER_TARGET_VIEW_DESC _desc;
	
	void SetFormat(int value){_desc.Format = (DXGI_FORMAT)value;}
	void SetViewDimension(int value){_desc.ViewDimension = (D3D11_RTV_DIMENSION)value;}
	
	// TODO -- add missing setters

	int GetFormat(){ return (int)_desc.Format;}
	int GetViewDimension(){ return (int)_desc.ViewDimension;}

	// TODO -- add missing getters
};

//--------------------------------------------------------------------------------------

class BBD3D11_DEPTH_STENCIL_VIEW_DESC : public Object
{
public:
	D3D11_DEPTH_STENCIL_VIEW_DESC _desc;

	void SetFormat(int value){_desc.Format = (DXGI_FORMAT)value;}
	void SetViewDimension(int value){_desc.ViewDimension = (D3D11_DSV_DIMENSION)value;}
	void SetTexture2D_MipSlice(int value){_desc.Texture2D.MipSlice = (UINT)value;}

	// TODO -- add missing setters

	int GetFormat(){ return (int)_desc.Format;}
	int GetViewDimension(){ return (int)_desc.ViewDimension;}
	int GetTexture2D_MipSlice(){ return (int)_desc.Texture2D.MipSlice;}

	// TODO -- add missing getters

};

//---------------------------------------------------------------------------------------

class BBD3D11_RASTERIZER_DESC : public Object
{
public:

	D3D11_RASTERIZER_DESC _desc;
	
	int GetFillMode();
	int GetCullMode();
	int GetFrontCounterClockwise();
	int GetDepthBias();
	float GetDepthBiasClamp();
	float GetSlopeScaledDepthBias();
	int GetDepthClipEnable();
	int GetScissorEnable();
	int GetMultisampleEnable();
	int GetAntialiasedLineEnable();
	void SetFillMode(int value);
	void SetCullMode(int value);
	void SetFrontCounterClockwise(int value);
	void SetDepthBias(int value);
	void SetDepthBiasClamp(float value);
	void SetSlopeScaledDepthBias(float value);
	void SetDepthClipEnable(int value);
	void SetScissorEnable(int value);
	void SetMultisampleEnable(int value);
	void SetAntialiasedLineEnable(int value);
};

//---------------------------------------------------------------------------------------


class BBD3D11_SAMPLER_DESC : public Object
{
public:

	D3D11_SAMPLER_DESC _desc;
	
	BBD3D11_SAMPLER_DESC();
	int GetFilter();
	int GetAddressU();
	int GetAddressV();
	int GetAddressW();
	float GetMipLODBias();
	int GetMaxAnisotropy();
	int GetComparisonFunc();
	float GetBorderColor(int index);
	float GetMinLOD();
	float GetMaxLOD();
	void SetFilter(int value);
	void SetAddressU(int value);
	void SetAddressV(int value);
	void SetAddressW(int value);
	void SetMipLODBias(float value);
	void SetMaxAnisotropy(int value);
	void SetComparisonFunc(int value);
	void SetBorderColor(int index, float value);
	void SetMinLOD(float value);
	void SetMaxLOD(float value);
};


class BBD3D11_SUBRESOURCE_DATA : public Object
{
public:
	D3D11_SUBRESOURCE_DATA _data;

	void SetpSysMem(BBDataBuffer* data) { _data.pSysMem = (const void*) data->ReadPointer();}
	void SetSysMemPitch(int value) { _data.SysMemPitch = (UINT) value;}
	void SetSysMemSlicePitch(int value) { _data.SysMemSlicePitch = (UINT) value; }
};

//---------------------------------------------------------------------------------------

class BBD3D11_DEPTH_STENCILOP_DESC : public Object
{
public:

	D3D11_DEPTH_STENCILOP_DESC* _desc;
	
	int GetStencilFailOp();
	int GetStencilDepthFailOp();
	int GetStencilPassOp();
	int GetStencilFunc() ;
	void SetStencilFailOp(int value);
	void SetStencilDepthFailOp(int value) ;
	void SetStencilPassOp(int value) ;
	void SetStencilFunc(int value) ;
};

//---------------------------------------------------------------------------------------

class BBD3D11_DEPTH_STENCIL_DESC : public Object
{
public:

	D3D11_DEPTH_STENCIL_DESC  _desc;
	BBD3D11_DEPTH_STENCILOP_DESC _font;
	BBD3D11_DEPTH_STENCILOP_DESC _back;
	
	BBD3D11_DEPTH_STENCIL_DESC();
	
	int GetDepthEnable();
	int GetDepthWriteMask();
	int GetDepthFunc();
	int GetStencilEnable();
	int GetStencilReadMask();
	int GetStencilWriteMask();
	void SetDepthEnable(int value);
	void SetDepthWriteMask(int value);
	void SetDepthFunc(int value);
	void SetStencilEnable(int value);
	void SetStencilReadMask(int value);
	void SetStencilWriteMask(int value);
	BBD3D11_DEPTH_STENCILOP_DESC* GetFrontFace();
	BBD3D11_DEPTH_STENCILOP_DESC* GetBackFace();
};

//---------------------------------------------------------------------------------------

class BBD3D11_BLEND_DESC : public Object
{
public:

	D3D11_BLEND_DESC _desc;

	BBD3D11_BLEND_DESC();
	int GetAlphaToCoverageEnable();
	int GetIndependentBlendEnable();
	void SetAlphaToCoverageEnable(int value) ;
	void SetIndependentBlendEnable(int value) ;
	BBD3D11_RENDER_TARGET_BLEND_DESC* GetRenderTarget(int index);
};

//---------------------------------------------------------------------------------------

class BBD3D11_INPUT_ELEMENT_DESC : public Object
{
public:
	D3D11_INPUT_ELEMENT_DESC desc;

	BBD3D11_INPUT_ELEMENT_DESC* Create(String SemanticName,int  SemanticIndex,int Format,int InputSlot, 
		int AlignedByteOffset,int InputSlotClass,int InstanceDataStepRate);
};

//---------------------------------------------------------------------------------------

class BBD3D11_BUFFER_DESC : public Object
{
public:
	D3D11_BUFFER_DESC _desc;
	
	int GetByteWidth();
	int GetUsage();
	int GetBindFlags() ;
	int GetCPUAccessFlags();
	int GetMiscFlags();
	int GetStructureByteStride();
	void SetByteWidth(int value);
	void SetUsage(int value);
	void SetBindFlags(int value);
	void SetCPUAccessFlags(int value);
	void SetMiscFlags(int value);
	void SetStructureByteStride(int value);
};

//---------------------------------------------------------------------------------------

class BBD3D11_RENDER_TARGET_BLEND_DESC : public Object
{
public:
	// points to D3D11_BLEND_DESC in BBD3D11_BLEND_DESC
	D3D11_RENDER_TARGET_BLEND_DESC* _desc;

	int GetBlendEnable();
	int GetSrcBlend();
	int GetDestBlend();
	int GetBlendOp();
	int GetSrcBlendAlpha();
	int GetDestBlendAlpha();
	int GetBlendOpAlpha();
	int GetRenderTargetWriteMask();
	void SetBlendEnable(int value);
	void SetSrcBlend(int value);
	void SetDestBlend(int value);
	void SetBlendOp(int value);
	void SetSrcBlendAlpha(int value);
	void SetDestBlendAlpha(int value);
	void SetBlendOpAlpha(int value);
	void SetRenderTargetWriteMask(int value);
};

//---------------------------------------------------------------------------------------

class BBD3D11_VIEWPORT : public Object
{
public:

	D3D11_VIEWPORT _viewport;
	
	float GetTopLeftX() { return _viewport.TopLeftX; }
	float GetTopLeftY() { return _viewport.TopLeftY; }
	float GetWidth() 	{ return _viewport.Width; }
	float GetHeight() 	{ return _viewport.Height; }
	float GetMinDepth() { return _viewport.MinDepth; }
	float GetMaxDepth() { return _viewport.MaxDepth; }
	
	void SetTopLeftX(float value) { _viewport.TopLeftX = value; }
	void SetTopLeftY(float value) { _viewport.TopLeftY = value; }
	void SetWidth(float value) 	  { _viewport.Width = value; }
	void SetHeight(float value)   { _viewport.Height = value; }
	void SetMinDepth(float value) { _viewport.MinDepth = value; }
	void SetMaxDepth(float value) { _viewport.MaxDepth = value; } 
};

//---------------------------------------------------------------------------------------

class BBD3D11_TEXTURE2D_DESC : public Object 
{
public:
	D3D11_TEXTURE2D_DESC _desc;
	
	void Width(int value)	{ _desc.Width = (UINT)value;}
	void Height(int value)	{ _desc.Height = (UINT)value;}
	void MipLevels(int value){ _desc.MipLevels = (UINT)value;}
	void ArraySize(int value){ _desc.ArraySize = (UINT)value;}
	void Format(int value)	{ _desc.Format = (DXGI_FORMAT)value;}
	void SampleDesc_Count(int value) 	{ _desc.SampleDesc.Count = (UINT)value; }
	void SampleDesc_Quality(int value) 	{ _desc.SampleDesc.Quality = (UINT)value; }
	void Usage(int value) 				{ _desc.Usage = (D3D11_USAGE)value;}
	void BindFlags(int value) { _desc.BindFlags = (UINT)value; }
	void MiscFlags(int value) { _desc.MiscFlags = (UINT)value; }
	void CPUAccessFlags(int value) { _desc.CPUAccessFlags = (UINT)value; }
};

//--------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------

BBD3D11Buffer::BBD3D11Buffer(BBD3D11Device* device,ID3D11Buffer* buffer)
	: BBD3D11Resource(device, (ID3D11Resource*)buffer,0)
{
	this->_buffer = buffer;
}

BBD3D11Buffer::~BBD3D11Buffer()
{
	Release();
}

void BBD3D11Buffer::Release()
{
	SAFE_RELEASE(_buffer);
}

//--------------------------------------------------------------------------------------


BBD3D11Device::BBD3D11Device()
{
	_device = BBWin8Game::Win8Game()->GetD3dDevice();
}

BBD3D11Device::~BBD3D11Device()
{
	Release();
}

void BBD3D11Device::Release()
{
}

BBD3D11BlendState* BBD3D11Device::CreateBlendState(BBD3D11_BLEND_DESC* desc)
{
	ID3D11BlendState* state = 0;
	DXASS(_device->CreateBlendState(&(desc->_desc), &state));	
	return new BBD3D11BlendState(this, state);
}

BBD3D11Buffer* BBD3D11Device::CreateBuffer(BBD3D11_BUFFER_DESC* desc, BBD3D11_SUBRESOURCE_DATA* initialData)
{
	ID3D11Buffer* buffer = 0;
	DXASS(_device->CreateBuffer( &desc->_desc,
				initialData ? (const D3D11_SUBRESOURCE_DATA*)&initialData->_data : NULL, &buffer));
				
	return new BBD3D11Buffer(this, buffer);
}
	
BBD3D11DepthStencilState* BBD3D11Device::CreateDepthStencilState(BBD3D11_DEPTH_STENCIL_DESC* desc)
{
	ID3D11DepthStencilState* state = 0;
	DXASS(_device->CreateDepthStencilState(&desc->_desc, &state));
	return new BBD3D11DepthStencilState(this, state);
}

BBD3D11DepthStencilView* BBD3D11Device::CreateDepthStencilView(BBD3D11Resource* res, BBD3D11_DEPTH_STENCIL_VIEW_DESC* desc)
{
	ID3D11DepthStencilView* view;
	DXASS(_device->CreateDepthStencilView(res->_res, desc ? &(desc->_desc) : 0, &(view)));
	return new BBD3D11DepthStencilView(this,view);
}

BBD3D11ShaderResourceView* BBD3D11Device::CreateShaderResourceView(BBD3D11Texture2D* tex, BBD3D11_SHADER_RESOURCE_VIEW_DESC* desc)
{
	ID3D11ShaderResourceView* view;
	DXASS(_device->CreateShaderResourceView(tex->_texture, &desc->_desc , &(view)));
	return new BBD3D11ShaderResourceView(this,view);
}

BBD3D11InputLayout* BBD3D11Device::CreateInputLayout(Array<BBD3D11_INPUT_ELEMENT_DESC*> inputElements, BBDataBuffer* shaderByteCodeWithInputSignature)
{

	// Create CreateInputLayout[] 
	UINT numElements = inputElements.Length();
	
	/**** TODO ****
	 
	auto descs = new D3D11_INPUT_ELEMENT_DESC[numElements];
	for(int i = 0; i< numElements; ++i )
	{
		descs[i] = inputElements.At(i)->desc;
	}
	
	*/			
									
	const D3D11_INPUT_ELEMENT_DESC descs[] = 
	{
		{"POSITION",0,	DXGI_FORMAT_R32G32B32_FLOAT,		0,0,	D3D11_INPUT_PER_VERTEX_DATA,0 },
		{"NORMAL",0,	DXGI_FORMAT_R32G32B32_FLOAT,		0,16,	D3D11_INPUT_PER_VERTEX_DATA,0 },
		{"COLOR",0,		DXGI_FORMAT_R32G32B32A32_FLOAT,		0,32,	D3D11_INPUT_PER_VERTEX_DATA,0 },
		{"TEXCOORD",0,	DXGI_FORMAT_R32G32_FLOAT,			0,48,	D3D11_INPUT_PER_VERTEX_DATA,0 },
		{"TEXCOORD",1,	DXGI_FORMAT_R32G32_FLOAT,			0,56,	D3D11_INPUT_PER_VERTEX_DATA,0 }
	};
	
	
	// Get byteCode
	void* byteCode = (void*)shaderByteCodeWithInputSignature->ReadPointer(0);
	int length = shaderByteCodeWithInputSignature->Length();
			
	// Create internal layout
	ID3D11InputLayout* layout = 0;
	DXASS(_device->CreateInputLayout(descs, numElements,byteCode,length,&layout));
	
	//delete[] descs;
		
	return new BBD3D11InputLayout(this, layout);
}
	
BBD3D11PixelShader* BBD3D11Device::CreatePixelShader(BBDataBuffer* shaderByteCode)
{
	const void* byteCode = (const void*)shaderByteCode->ReadPointer(0);
	SIZE_T length = (SIZE_T)shaderByteCode->Length();
	
	ID3D11PixelShader* shader = 0;
	DXASS(_device->CreatePixelShader(byteCode, length, NULL, &shader));
	return new BBD3D11PixelShader(this, shader);	  
}

BBD3D11RasterizerState* BBD3D11Device::CreateRasterizerState(BBD3D11_RASTERIZER_DESC* desc)
{
	ID3D11RasterizerState* state = 0;
	DXASS(_device->CreateRasterizerState(&desc->_desc, &state));
	return new BBD3D11RasterizerState(this, state);
}

BBD3D11SamplerState* BBD3D11Device::CreateSamplerState(BBD3D11_SAMPLER_DESC* desc)
{
	ID3D11SamplerState* state = 0;
	DXASS(_device->CreateSamplerState((const D3D11_SAMPLER_DESC*)&desc->_desc, &state));
	return new BBD3D11SamplerState(this, state);
}

BBD3D11Texture2D* BBD3D11Device::CreateTexture2D(BBD3D11_TEXTURE2D_DESC* desc, Array<BBD3D11_SUBRESOURCE_DATA*> initialData)
{
	ID3D11Texture2D* tex = 0;

	D3D11_SUBRESOURCE_DATA** data = new D3D11_SUBRESOURCE_DATA*[initialData.Length()];
	for( int i = 0; i < initialData.Length(); ++i)
	{
		data[i] = &initialData[i]->_data;
	}

	DXASS(_device->CreateTexture2D( 
		(const D3D11_TEXTURE2D_DESC*)&desc->_desc, 
		(initialData.Length() > 0 ? (const D3D11_SUBRESOURCE_DATA*)data[0] : NULL), 
		&tex ));
	return new BBD3D11Texture2D(this, tex);
}

BBD3D11VertexShader* BBD3D11Device::CreateVertexShader(BBDataBuffer* shaderByteCode)
{
	const void* byteCode = (const void*)shaderByteCode->ReadPointer(0);
	SIZE_T length = (SIZE_T)shaderByteCode->Length();
	
	ID3D11VertexShader* shader = 0;
	DXASS(_device->CreateVertexShader(byteCode, length, NULL, &shader));		
	return new BBD3D11VertexShader(this, shader);	  
}

int BBD3D11Device::CheckFormatSupport(int dxgiFormat)
{
	UINT formatSupport;
	DXASS(_device->CheckFormatSupport((DXGI_FORMAT)dxgiFormat, &formatSupport));
	return (int)formatSupport;
}

int BBD3D11Device::CheckMultisampleQualityLevels(int dxgiFormat, int sampleCount)
{
	UINT numQualityLevels;
	DXASS( _device->CheckMultisampleQualityLevels((DXGI_FORMAT)dxgiFormat, (UINT)sampleCount, &numQualityLevels));
	return (int)numQualityLevels;
}

BBD3D11RenderTargetView* BBD3D11Device::GetBackBuffer()
{
	auto view = BBWin8Game::Win8Game()->GetRenderTargetView();
	return new BBD3D11RenderTargetView( this, view );
}

BBD3D11DeviceContext* BBD3D11Device::GetImmediateContext()
{
	return new BBD3D11DeviceContext(this);
}

int BBD3D11Device::GetCreationFlags()
{
	return (int)_device->GetCreationFlags();
}
	
int BBD3D11Device::GetExceptionMode()
{
	return (int)_device->GetExceptionMode();
}

int BBD3D11Device::GetFeatureLevel()
{
	return (int)_device->GetFeatureLevel();
}

//--------------------------------------------------------------------------------------

BBD3D11DeviceContext::BBD3D11DeviceContext(BBD3D11Device* device): BBD3D11DeviceChild(device)
{
	_deviceContext = BBWin8Game::Win8Game()->GetD3dContext();
}

BBD3D11DeviceContext::~BBD3D11DeviceContext()
{
	Release();
}

void BBD3D11DeviceContext::Release()
{
	// D3D11DeviceContext release is handled by BBWin8Game?
}

void BBD3D11DeviceContext::ClearRenderTargetView(BBD3D11RenderTargetView*, float r,float g,float b )
{
	float rgba[]={ r,g,b,1.0f };
	_deviceContext->ClearRenderTargetView( BBWin8Game::Win8Game()->GetRenderTargetView(),rgba );
}

void BBD3D11DeviceContext::ClearDepthStancilView(BBD3D11DepthStencilView* view, int flags, float depth, int stencil)
{
	_deviceContext->ClearDepthStencilView(view->_depthStencilView,(UINT)flags,depth, (UINT8)stencil);
}

void BBD3D11DeviceContext::OMSetRenderTargets(Array<BBD3D11RenderTargetView*> renderTargetViews, BBD3D11DepthStencilView* depthStencilView)
{
	int count = renderTargetViews.Length();
	for(int i = 0; i< count; ++i)
	{
		_pRenderTargets[i] = renderTargetViews[i]->_renderTargetView;
	}
	_deviceContext->OMSetRenderTargets( count, &_pRenderTargets[0], depthStencilView->_depthStencilView); 
}
	
int BBD3D11DeviceContext::GetContextFlags()
{
	return (int)_deviceContext->GetContextFlags();
}
	
int BBD3D11DeviceContext::GetType()
{
	return (int)_deviceContext->GetType();
}
	
void BBD3D11DeviceContext::ClearState()
{
	_deviceContext->ClearState();
}

void BBD3D11DeviceContext::Draw(int vertexCount, int offset )
{
	_deviceContext->Draw((UINT)vertexCount, (UINT)offset);
}

void BBD3D11DeviceContext::DrawAuto()
{
	_deviceContext->DrawAuto();
}

void BBD3D11DeviceContext::DrawIndexed(int indexCount, int startIndexLoc, int baseVertLoc )
{
	_deviceContext->DrawIndexed((UINT)indexCount, (UINT)startIndexLoc, baseVertLoc);
}
	
/*

TODO:

void BBD3D11DeviceContext::DrawIndexedInstanced(int indexCountPerInst, int instount, int stratIndexLoc, int baseVertexLoc, int startInstLoc);
{
	_deviceContext->DrawIndexedInstanced((UINT)indexCountPerInst, (UINT)instount, (UINT)stratIndexLoc, baseVertexLoc, (UINT)startInstLoc);
}
*/

void BBD3D11DeviceContext::DrawInstanced(int vertexCountPerInst, int instCount, int startVertLoc, int StartInstLoc)
{
	_deviceContext->DrawInstanced((UINT)vertexCountPerInst, (UINT)instCount, 
		(UINT)startVertLoc, (UINT)StartInstLoc);
}
	
void BBD3D11DeviceContext::IASetIndexBuffer(BBD3D11Buffer* indexBuffer, int format, int offset)
{
	_deviceContext->IASetIndexBuffer(indexBuffer->_buffer, DXGI_FORMAT_R16_UINT, (UINT)offset );
	// ** TODO *** 
	// format == 0 ? DXGI_FORMAT_R16_UINT : DXGI_FORMAT_R32_UINT, (UINT)offset );
}

void BBD3D11DeviceContext::IASetInputLayout( BBD3D11InputLayout* inputLayout)
{
	_deviceContext->IASetInputLayout( inputLayout->_layout);
}

void BBD3D11DeviceContext::IASetPrimitiveTopology(int topology)
{
	_deviceContext->IASetPrimitiveTopology((D3D11_PRIMITIVE_TOPOLOGY)topology);
}

void BBD3D11DeviceContext::IASetVertexBuffers( int stratSlot, int num_buffers, Array<BBD3D11Buffer*> vertexBuffers, Array<int> strides, Array<int> offsets)
{
	for( int i = 0; i< num_buffers; ++i)
	{
		_pD3D11Buffer[i] = vertexBuffers[i]->_buffer;
		_strides[i] = (UINT)strides[i];
		_offsets[i] = (UINT)offsets[i];
	}
	_deviceContext->IASetVertexBuffers( stratSlot, num_buffers, 
		(ID3D11Buffer* const* )_pD3D11Buffer, _strides, _offsets );
}

D3D11BufferData* BBD3D11DeviceContext::Map(BBD3D11Resource* resource, int subResource, int mapType, int mapFlags)
{
	auto bufferData = new D3D11BufferData();
	DXASS(_deviceContext->Map( resource->_res, (UINT)subResource, (D3D11_MAP)mapType, 
		(UINT)mapFlags, &bufferData->_mappedResource ));
	bufferData->_ptr = (unsigned char*)bufferData->_mappedResource.pData;
	return bufferData;
}

void BBD3D11DeviceContext::OMSetBlendState( BBD3D11BlendState* blendState)//, Array<float> blendFactor, int sampleMask )
{
	_deviceContext->OMSetBlendState( blendState->_state,0,~0);
}

void BBD3D11DeviceContext::OMSetDepthStencilState( BBD3D11DepthStencilState* state, int stencilRef)
{
	_deviceContext->OMSetDepthStencilState(state->_state, (UINT)stencilRef);
}

void BBD3D11DeviceContext::PSSetConstantBuffers(int startSlot, Array<BBD3D11Buffer*> constantBuffers)
{
	UINT numBuffers = (UINT)constantBuffers.Length();
	for( int i =0 ; i< numBuffers; ++i)
	{
		_pD3D11Buffer[i] = constantBuffers[i]->_buffer;
	}
	_deviceContext->PSSetConstantBuffers((UINT)startSlot, numBuffers, 
		(ID3D11Buffer *const *)_pD3D11Buffer);
}

void BBD3D11DeviceContext::PSSetSamplers(int startSlot, int num_samplers, Array<BBD3D11SamplerState*> samplers)
{
	if( num_samplers == 0) 
	{
		_deviceContext->PSSetSamplers(0,0,0);
	}
	else
	{
		for( int i = 0; i< num_samplers; ++i)
		{
			_pSampelerStates[i] = samplers[i]->_state;
		}
		_deviceContext->PSSetSamplers((UINT)startSlot, num_samplers, 
			(ID3D11SamplerState *const *)_pSampelerStates);
	}
}

void BBD3D11DeviceContext::PSSetShader( BBD3D11PixelShader* pixelShader)
{
	_deviceContext->PSSetShader(pixelShader->_shader, NULL, 0);
}


void BBD3D11DeviceContext::PSSetShaderResources(int startSlot, int numViews, Array<BBD3D11ShaderResourceView*> shaderResourceViews )
{
	if( numViews == 0 ) 
	{
		_deviceContext->PSSetShaderResources(0,0,0);
	}
	else
	{
		for( int i = startSlot; i < startSlot + numViews; ++i )
		{
			_pShaderResourceViews[i] = shaderResourceViews[i]->_shaderResourceView;
		}
		_deviceContext->PSSetShaderResources((UINT)startSlot, (UINT)numViews, 
				(ID3D11ShaderResourceView *const *)_pShaderResourceViews);
	}
}

void BBD3D11DeviceContext::GenerateMips(BBD3D11ShaderResourceView* resourceView)
{
	_deviceContext->GenerateMips(resourceView->_shaderResourceView);
}

void BBD3D11DeviceContext::RSSetState( BBD3D11RasterizerState* resterizerState )
{
	_deviceContext->RSSetState(resterizerState->_state);
}

void BBD3D11DeviceContext::RSSetViewports( Array<BBD3D11_VIEWPORT*> viewports )
{
	UINT numViewports = (UINT)viewports.Length();
	for( int i =0 ; i< numViewports; ++i)
	{
		_pViewports[i] = &viewports[i]->_viewport;
	}
	_deviceContext->RSSetViewports(numViewports,(const D3D11_VIEWPORT*)_pViewports);
}

void BBD3D11DeviceContext::Unmap( BBD3D11Resource* resource, int subResource )
{
	_deviceContext->Unmap(resource->_res, (UINT)subResource);
}

void BBD3D11DeviceContext::VSSetConstantBuffers(int startSlot, Array<BBD3D11Buffer*> constantBuffers)
{
	UINT numBuffers = constantBuffers.Length();
	for(int i= 0; i< numBuffers; ++i)
	{
		_pD3D11Buffer[i] = constantBuffers[i]->_buffer;
	}
	_deviceContext->VSSetConstantBuffers((UINT)startSlot, numBuffers, 
		(ID3D11Buffer *const *)_pD3D11Buffer);
}

void BBD3D11DeviceContext::VSSetSamplers(int startSlot, Array<BBD3D11SamplerState*> samplers )
{
	UINT numSamplers = samplers.Length();
	for( int i = 0; i< numSamplers; ++i )
	{
		_pSampelerStates[i] = samplers[i]->_state;
	}
	_deviceContext->VSSetSamplers((UINT)startSlot, numSamplers, 
		(ID3D11SamplerState *const *)_pSampelerStates);
}

void BBD3D11DeviceContext::VSSetShader( BBD3D11VertexShader* vertexShader)
{
	_deviceContext->VSSetShader(vertexShader->_shader, NULL, 0);
}
	
void BBD3D11DeviceContext::UpdateSubresource( BBD3D11Resource* pDstResource, int DstSubresource, int x, int y, int width, int height, BBDataBuffer* srcData, int pitch, int depth)
{
	D3D11_BOX destBox;
		destBox.left = x;
		destBox.right = width;
		destBox.top = y;
		destBox.bottom = height;
		destBox.front = 0;
		destBox.back = 1;

	_deviceContext->UpdateSubresource(
		pDstResource->_res,
		DstSubresource,
		&destBox,
		srcData->ReadPointer(0),
		pitch,
		depth);
}
//-------------------------------------------------------------------------------------- 

BBD3D11View::BBD3D11View(BBD3D11Device* device,ID3D11View* view)
	: BBD3D11DeviceChild(device)
{
	_view = view;
}

BBD3D11View::~BBD3D11View()
{
	Release();
}

void BBD3D11View::Release()
{
	SAFE_RELEASE(_view);
}

BBD3D11Resource* BBD3D11View::GetResource()
{
	ID3D11Resource* res; _view->GetResource(&res);
	return new BBD3D11Resource(this->GetDevice(), res, 0 );
}

//--------------------------------------------------------------------------------------


BBD3D11DepthStencilView::BBD3D11DepthStencilView(BBD3D11Device* device,ID3D11DepthStencilView* view) 
	:BBD3D11View(device,(ID3D11View*)view)
{
	_depthStencilView = view;
}

BBD3D11DepthStencilView::~BBD3D11DepthStencilView()
{
	Release();
}


BBD3D11_DEPTH_STENCIL_VIEW_DESC* BBD3D11DepthStencilView::GetDesc()
{
	D3D11_DEPTH_STENCIL_VIEW_DESC srcDesc;
	_depthStencilView->GetDesc(&srcDesc);
	auto desc = new BBD3D11_DEPTH_STENCIL_VIEW_DESC();
	desc->_desc = srcDesc;
	return desc;
}

//--------------------------------------------------------------------------------------

BBD3D11RenderTargetView::BBD3D11RenderTargetView(BBD3D11Device* device,ID3D11RenderTargetView* view) 
	:BBD3D11View(device,(ID3D11View*)view)
{
	_renderTargetView = view;
}

BBD3D11RenderTargetView::~BBD3D11RenderTargetView()
{
	Release();
}

BBD3D11_RENDER_TARGET_VIEW_DESC* BBD3D11RenderTargetView::GetDesc()
{
	BBD3D11_RENDER_TARGET_VIEW_DESC* desc = new BBD3D11_RENDER_TARGET_VIEW_DESC();
	_renderTargetView->GetDesc(&(desc->_desc));
	return desc;
};

//--------------------------------------------------------------------------------------

BBD3D11ShaderResourceView::BBD3D11ShaderResourceView(BBD3D11Device* device,ID3D11ShaderResourceView* view)
	: BBD3D11View(device, (ID3D11View*)view)
{
	_shaderResourceView = view;
}

BBD3D11ShaderResourceView::~BBD3D11ShaderResourceView()
{
	Release();
}

BBD3D11_SHADER_RESOURCE_VIEW_DESC* BBD3D11ShaderResourceView::GetDesc()
{
	auto desc = new BBD3D11_SHADER_RESOURCE_VIEW_DESC();
	_shaderResourceView->GetDesc(&(desc->_desc));
	return desc;
}

//--------------------------------------------------------------------------------------

BBD3D11DeviceChild::BBD3D11DeviceChild(BBD3D11Device* device)
{
	_device = device;
}
	
BBD3D11Device* BBD3D11DeviceChild::GetDevice()
{
	return _device;
}

//--------------------------------------------------------------------------------------

BBD3D11Resource::BBD3D11Resource(BBD3D11Device* device, ID3D11Resource* res, int type) : BBD3D11DeviceChild(device)
{
	_res = res;
	_resourceType = type;
}
	
int BBD3D11Resource::GetType()
{
	// TODO
	return 0;
}

//--------------------------------------------------------------------------------------

BBD3D11BlendState::BBD3D11BlendState(BBD3D11Device* device, ID3D11BlendState* state)
	: BBD3D11DeviceChild(device)
{
	_state = state;
}
	
BBD3D11BlendState::~BBD3D11BlendState()
{
	Release();
}
	
void BBD3D11BlendState::Release()
{
	SAFE_RELEASE(_state);
}

//--------------------------------------------------------------------------------------

BBD3D11RasterizerState::BBD3D11RasterizerState(BBD3D11Device* device,ID3D11RasterizerState* state) 
	: BBD3D11DeviceChild(device)
{
_state = state;
}
		
BBD3D11RasterizerState::~BBD3D11RasterizerState()
{
	Release();
}
	
void BBD3D11RasterizerState::Release()
{
	SAFE_RELEASE(_state);
}

//--------------------------------------------------------------------------------------

BBD3D11SamplerState::BBD3D11SamplerState(BBD3D11Device* device,ID3D11SamplerState* state)
	: BBD3D11DeviceChild(device)
{
	_state = state;
}
	
BBD3D11SamplerState::~BBD3D11SamplerState()
{
	Release();
}
	
void BBD3D11SamplerState::Release()
{
	SAFE_RELEASE(_state);
}

//--------------------------------------------------------------------------------------

BBD3D11DepthStencilState::BBD3D11DepthStencilState(BBD3D11Device* device, ID3D11DepthStencilState* state)
	: BBD3D11DeviceChild(device)
{
	_state = state;
}
	
BBD3D11DepthStencilState::~BBD3D11DepthStencilState()
{
	Release();
}
	
void BBD3D11DepthStencilState::Release()
{
	SAFE_RELEASE(_state);
}

//--------------------------------------------------------------------------------------

BBD3D11VertexShader::BBD3D11VertexShader(BBD3D11Device* device,ID3D11VertexShader* shader )
	: BBD3D11DeviceChild(device)
{
	_shader = shader;
}
	
BBD3D11VertexShader::~BBD3D11VertexShader()
{
	Release();
}
	
void BBD3D11VertexShader::Release()
{
	SAFE_RELEASE(_shader);
}

//--------------------------------------------------------------------------------------

BBD3D11PixelShader::BBD3D11PixelShader(BBD3D11Device* device,ID3D11PixelShader* shader )
	: BBD3D11DeviceChild(device)
{
	_shader = shader;
}
	
BBD3D11PixelShader::~BBD3D11PixelShader()
{
	Release();
}
	
void BBD3D11PixelShader::Release()
{
	SAFE_RELEASE(_shader);
}

//--------------------------------------------------------------------------------------

BBD3D11Texture2D::BBD3D11Texture2D(BBD3D11Device* device, ID3D11Texture2D* texture)
	: BBD3D11Resource(device, (ID3D11Resource*)texture, 0)
{
	_texture = texture;
}
	
BBD3D11Texture2D::~BBD3D11Texture2D()
{
	Release();
}
	
void BBD3D11Texture2D::Release()
{
	SAFE_RELEASE(_texture);
}

//--------------------------------------------------------------------------------------

BBD3D11InputLayout::BBD3D11InputLayout(BBD3D11Device* device,ID3D11InputLayout* layout) 
	: BBD3D11DeviceChild(device)
{
	_layout = layout;
}

BBD3D11InputLayout::~BBD3D11InputLayout()
{
	Release();
}
	
void BBD3D11InputLayout::Release()
{
	SAFE_RELEASE(_layout);
}

//---------------------------------------------------------------------------------------

int D3D11BufferData::RowPitch()
{
	return (int)_mappedResource.RowPitch;
}
	
// The depth pitch, or width, or physical size (in bytes)of the data.
int D3D11BufferData::DepthPitch()
{
	return (int)_mappedResource.DepthPitch;
}

void D3D11BufferData::SetData(BBDataBuffer* data, int size)
{
	memcpy(_ptr, data->ReadPointer(), size);
}

//---------------------------------------------------------------------------------------

int BBD3D11_RENDER_TARGET_BLEND_DESC::GetBlendEnable() { return (int)_desc->BlendEnable; }
int BBD3D11_RENDER_TARGET_BLEND_DESC::GetSrcBlend() { return (int)_desc->SrcBlend; }
int BBD3D11_RENDER_TARGET_BLEND_DESC::GetDestBlend() { return (int)_desc->DestBlend; }
int BBD3D11_RENDER_TARGET_BLEND_DESC::GetBlendOp() { return (int)_desc->BlendOp; }
int BBD3D11_RENDER_TARGET_BLEND_DESC::GetSrcBlendAlpha() { return (int)_desc->SrcBlendAlpha; }
int BBD3D11_RENDER_TARGET_BLEND_DESC::GetDestBlendAlpha() { return (int)_desc->DestBlendAlpha; }
int BBD3D11_RENDER_TARGET_BLEND_DESC::GetBlendOpAlpha() { return (int)_desc->BlendOpAlpha; }
int BBD3D11_RENDER_TARGET_BLEND_DESC::GetRenderTargetWriteMask() { return (int)_desc->RenderTargetWriteMask; }
void BBD3D11_RENDER_TARGET_BLEND_DESC::SetBlendEnable(int value) { _desc->BlendEnable = value; }
void BBD3D11_RENDER_TARGET_BLEND_DESC::SetSrcBlend(int value) { _desc->SrcBlend = (D3D11_BLEND)value; }
void BBD3D11_RENDER_TARGET_BLEND_DESC::SetDestBlend(int value) { _desc->DestBlend = (D3D11_BLEND)value; }
void BBD3D11_RENDER_TARGET_BLEND_DESC::SetBlendOp(int value) { _desc->BlendOp = (D3D11_BLEND_OP)value; }
void BBD3D11_RENDER_TARGET_BLEND_DESC::SetSrcBlendAlpha(int value) { _desc->SrcBlendAlpha = (D3D11_BLEND)value; }
void BBD3D11_RENDER_TARGET_BLEND_DESC::SetDestBlendAlpha(int value) {_desc->DestBlendAlpha = (D3D11_BLEND)value; }
void BBD3D11_RENDER_TARGET_BLEND_DESC::SetBlendOpAlpha(int value) { _desc->BlendOpAlpha = (D3D11_BLEND_OP)value; }
void BBD3D11_RENDER_TARGET_BLEND_DESC::SetRenderTargetWriteMask(int value) {_desc->RenderTargetWriteMask = value; }

//---------------------------------------------------------------------------------------

int BBD3D11_DEPTH_STENCILOP_DESC::GetStencilFailOp() { return _desc->StencilFailOp; }
int BBD3D11_DEPTH_STENCILOP_DESC::GetStencilDepthFailOp() { return _desc->StencilDepthFailOp; }
int BBD3D11_DEPTH_STENCILOP_DESC::GetStencilPassOp() { return _desc->StencilPassOp; }
int BBD3D11_DEPTH_STENCILOP_DESC::GetStencilFunc() { return _desc->StencilFunc; }
void BBD3D11_DEPTH_STENCILOP_DESC::SetStencilFailOp(int value) { _desc->StencilFailOp = (D3D11_STENCIL_OP)value; }
void BBD3D11_DEPTH_STENCILOP_DESC::SetStencilDepthFailOp(int value) { _desc->StencilDepthFailOp = (D3D11_STENCIL_OP)value; }
void BBD3D11_DEPTH_STENCILOP_DESC::SetStencilPassOp(int value) { _desc->StencilPassOp = (D3D11_STENCIL_OP)value; }
void BBD3D11_DEPTH_STENCILOP_DESC::SetStencilFunc(int value) { _desc->StencilFunc = (D3D11_COMPARISON_FUNC)value; }

//---------------------------------------------------------------------------------------

int BBD3D11_BUFFER_DESC::GetByteWidth() { return (int)_desc.ByteWidth; }
int BBD3D11_BUFFER_DESC::GetUsage() { return (int)_desc.Usage; }
int BBD3D11_BUFFER_DESC::GetBindFlags() { return( int)_desc.BindFlags; }
int BBD3D11_BUFFER_DESC::GetCPUAccessFlags() { return (int)_desc.CPUAccessFlags; }
int BBD3D11_BUFFER_DESC::GetMiscFlags() { return (int)_desc.MiscFlags; }
int BBD3D11_BUFFER_DESC::GetStructureByteStride() { return (int)_desc.StructureByteStride; }
void BBD3D11_BUFFER_DESC::SetByteWidth(int value) { _desc.ByteWidth = (UINT)value; }
void BBD3D11_BUFFER_DESC::SetUsage(int value) { _desc.Usage= (D3D11_USAGE)value; }
void BBD3D11_BUFFER_DESC::SetBindFlags(int value) { _desc.BindFlags= (UINT)value; }
void BBD3D11_BUFFER_DESC::SetCPUAccessFlags(int value) { _desc.CPUAccessFlags= (UINT)value; }
void BBD3D11_BUFFER_DESC::SetMiscFlags(int value) { _desc.MiscFlags= (UINT)value; }
void BBD3D11_BUFFER_DESC::SetStructureByteStride(int value) { _desc.StructureByteStride= (UINT)value; }

//---------------------------------------------------------------------------------------

BBD3D11_INPUT_ELEMENT_DESC* BBD3D11_INPUT_ELEMENT_DESC::Create(String SemanticName,int  SemanticIndex,int Format,int InputSlot, 
		int AlignedByteOffset,int InputSlotClass,int InstanceDataStepRate)
	{
		desc.SemanticName = (LPCSTR)SemanticName.ToCString<wchar_t>();
		desc.SemanticIndex = (UINT)SemanticIndex;
		desc.Format = (DXGI_FORMAT)Format;
		desc.InputSlot = (UINT)InputSlot;
		desc.AlignedByteOffset = (UINT)AlignedByteOffset;
		desc.InputSlotClass = (D3D11_INPUT_CLASSIFICATION)InputSlotClass;
		desc.InstanceDataStepRate = (UINT)InstanceDataStepRate;
		return this;
	}

//---------------------------------------------------------------------------------------

BBD3D11_BLEND_DESC::BBD3D11_BLEND_DESC()
{
	ZEROMEM( _desc );
}
	
int BBD3D11_BLEND_DESC::GetAlphaToCoverageEnable() { return _desc.AlphaToCoverageEnable; }
int BBD3D11_BLEND_DESC::GetIndependentBlendEnable() { return _desc.IndependentBlendEnable; }
void BBD3D11_BLEND_DESC::SetAlphaToCoverageEnable(int value) { _desc.AlphaToCoverageEnable = (BOOL)value; }
void BBD3D11_BLEND_DESC::SetIndependentBlendEnable(int value) { _desc.IndependentBlendEnable = (BOOL)value; }

BBD3D11_RENDER_TARGET_BLEND_DESC* BBD3D11_BLEND_DESC::GetRenderTarget(int index)
{ 
	auto target = new BBD3D11_RENDER_TARGET_BLEND_DESC();
	target->_desc = &_desc.RenderTarget[index];
	return target;
}

//---------------------------------------------------------------------------------------

BBD3D11_DEPTH_STENCIL_DESC::BBD3D11_DEPTH_STENCIL_DESC()
{
	ZEROMEM( _desc );
	_font._desc = &_desc.FrontFace;
	_back._desc = &_desc.BackFace;
}
	
int BBD3D11_DEPTH_STENCIL_DESC::GetDepthEnable() { return (int)_desc.DepthEnable; }
int BBD3D11_DEPTH_STENCIL_DESC::GetDepthWriteMask(){ return (int)_desc.DepthWriteMask; }
int BBD3D11_DEPTH_STENCIL_DESC::GetDepthFunc(){ return (int)_desc.DepthFunc; }
int BBD3D11_DEPTH_STENCIL_DESC::GetStencilEnable(){ return (int)_desc.StencilEnable; }
int BBD3D11_DEPTH_STENCIL_DESC::GetStencilReadMask(){ return (int)_desc.StencilReadMask; }
int BBD3D11_DEPTH_STENCIL_DESC::GetStencilWriteMask(){ return (int)_desc.StencilWriteMask; }
void BBD3D11_DEPTH_STENCIL_DESC::SetDepthEnable(int value) { _desc.DepthEnable = (BOOL)value; }
void BBD3D11_DEPTH_STENCIL_DESC::SetDepthWriteMask(int value){ _desc.DepthWriteMask = (D3D11_DEPTH_WRITE_MASK)value; }
void BBD3D11_DEPTH_STENCIL_DESC::SetDepthFunc(int value){ _desc.DepthFunc = (D3D11_COMPARISON_FUNC)value;}
void BBD3D11_DEPTH_STENCIL_DESC::SetStencilEnable(int value){_desc.StencilEnable = (BOOL)value; }
void BBD3D11_DEPTH_STENCIL_DESC::SetStencilReadMask(int value){ _desc.StencilReadMask = (UINT8)value; }
void BBD3D11_DEPTH_STENCIL_DESC::SetStencilWriteMask(int value){ _desc.StencilWriteMask = (UINT8)value; }
BBD3D11_DEPTH_STENCILOP_DESC* BBD3D11_DEPTH_STENCIL_DESC::GetFrontFace() { return &_font; }
BBD3D11_DEPTH_STENCILOP_DESC* BBD3D11_DEPTH_STENCIL_DESC::GetBackFace(){ return &_back; }

//---------------------------------------------------------------------------------------

BBD3D11_SAMPLER_DESC::BBD3D11_SAMPLER_DESC()
{
	ZEROMEM( _desc );
	_desc.MinLOD=-FLT_MAX;
	_desc.MaxLOD=+FLT_MAX;
}

int BBD3D11_SAMPLER_DESC::GetFilter(){ return (int)_desc.Filter; }
int BBD3D11_SAMPLER_DESC::GetAddressU(){ return (int)_desc.AddressU; }
int BBD3D11_SAMPLER_DESC::GetAddressV(){ return (int)_desc.AddressV; }
int BBD3D11_SAMPLER_DESC::GetAddressW(){ return (int)_desc.AddressW; }
float BBD3D11_SAMPLER_DESC::GetMipLODBias(){ return (float)_desc.MipLODBias; }
int BBD3D11_SAMPLER_DESC::GetMaxAnisotropy(){ return (int)_desc.MaxAnisotropy; }
int BBD3D11_SAMPLER_DESC::GetComparisonFunc(){ return (int)_desc.ComparisonFunc; }
float BBD3D11_SAMPLER_DESC::GetBorderColor(int index){ return (float)_desc.BorderColor[index]; }
float BBD3D11_SAMPLER_DESC::GetMinLOD(){ return (float)_desc.MinLOD; }
float BBD3D11_SAMPLER_DESC::GetMaxLOD(){ return (float)_desc.MaxLOD; }
void BBD3D11_SAMPLER_DESC::SetFilter(int value){ _desc.Filter = (D3D11_FILTER)value; }
void BBD3D11_SAMPLER_DESC::SetAddressU(int value){ _desc.AddressU = (D3D11_TEXTURE_ADDRESS_MODE)value; }
void BBD3D11_SAMPLER_DESC::SetAddressV(int value){ _desc.AddressV = (D3D11_TEXTURE_ADDRESS_MODE)value; }
void BBD3D11_SAMPLER_DESC::SetAddressW(int value){ _desc.AddressW = (D3D11_TEXTURE_ADDRESS_MODE)value; }
void BBD3D11_SAMPLER_DESC::SetMipLODBias(float value){ _desc.MipLODBias = (FLOAT)value; }
void BBD3D11_SAMPLER_DESC::SetMaxAnisotropy(int value){ _desc.MaxAnisotropy = (UINT)value; }
void BBD3D11_SAMPLER_DESC::SetComparisonFunc(int value){ _desc.ComparisonFunc = (D3D11_COMPARISON_FUNC)value; }
void BBD3D11_SAMPLER_DESC::SetBorderColor(int index, float value){ _desc.BorderColor[index] = (FLOAT)value; }
void BBD3D11_SAMPLER_DESC::SetMinLOD(float value){ _desc.MinLOD = (FLOAT)value; }
void BBD3D11_SAMPLER_DESC::SetMaxLOD(float value){ _desc.MaxLOD = (FLOAT)value; }

//---------------------------------------------------------------------------------------

int BBD3D11_RASTERIZER_DESC::GetFillMode(){ return _desc.FillMode; }
int BBD3D11_RASTERIZER_DESC::GetCullMode(){ return _desc.CullMode; }
int BBD3D11_RASTERIZER_DESC::GetFrontCounterClockwise(){ return _desc.FrontCounterClockwise; }
int BBD3D11_RASTERIZER_DESC::GetDepthBias(){ return _desc.DepthBias; }
float BBD3D11_RASTERIZER_DESC::GetDepthBiasClamp(){ return _desc.DepthBiasClamp; }
float BBD3D11_RASTERIZER_DESC::GetSlopeScaledDepthBias(){ return _desc.SlopeScaledDepthBias; }
int BBD3D11_RASTERIZER_DESC::GetDepthClipEnable(){ return _desc.DepthClipEnable; }
int BBD3D11_RASTERIZER_DESC::GetScissorEnable(){ return _desc.ScissorEnable; }
int BBD3D11_RASTERIZER_DESC::GetMultisampleEnable(){ return _desc.MultisampleEnable; }
int BBD3D11_RASTERIZER_DESC::GetAntialiasedLineEnable(){ return _desc.AntialiasedLineEnable; }
void BBD3D11_RASTERIZER_DESC::SetFillMode(int value){ _desc.FillMode = (D3D11_FILL_MODE)value; }
void BBD3D11_RASTERIZER_DESC::SetCullMode(int value){ _desc.CullMode = (D3D11_CULL_MODE)value; }
void BBD3D11_RASTERIZER_DESC::SetFrontCounterClockwise(int value){ _desc.FrontCounterClockwise = (BOOL)value; }
void BBD3D11_RASTERIZER_DESC::SetDepthBias(int value){ _desc.DepthBias = (INT)value; }
void BBD3D11_RASTERIZER_DESC::SetDepthBiasClamp(float value){ _desc.DepthBiasClamp = (FLOAT)value; }
void BBD3D11_RASTERIZER_DESC::SetSlopeScaledDepthBias(float value){ _desc.SlopeScaledDepthBias = (FLOAT)value; }
void BBD3D11_RASTERIZER_DESC::SetDepthClipEnable(int value){ _desc.DepthClipEnable = (BOOL)value; }
void BBD3D11_RASTERIZER_DESC::SetScissorEnable(int value){ _desc.ScissorEnable = (BOOL)value; }
void BBD3D11_RASTERIZER_DESC::SetMultisampleEnable(int value){ _desc.MultisampleEnable = (BOOL)value; }
void BBD3D11_RASTERIZER_DESC::SetAntialiasedLineEnable(int value){ _desc.AntialiasedLineEnable = (BOOL)value; }
