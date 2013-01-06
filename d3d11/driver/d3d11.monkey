
''--------------------------------------------------------
'' Windows 8 MiniB3D Driver
'' (C) 2012 Sascha Schmidt
''--------------------------------------------------------

#if TARGET<>"win8"
	#Error "D3D11 is only supported on metro target."
#Else

Import brl 
Import "native/d3d11.cpp"

Extern 

Function UpdateVertexDataBufferPositions:Void(destVertexDataBuffer:DataBuffer,  floatBuffer:DataBuffer, count)
Function CreatePerspectiveMatrix:Void(mat:float[], fieldOfView#, aspectRatio#, nearZ#, farZ#)
Function Print_Monkey_Internal:Void()
Function LoadImageData:Bool(buffer:DataBuffer, path$, info:Int[]) = "BBD3D11LoadImageData"

Class IUnknown = "BBIUnknown"
	Method Release()
End 

Class D3D11DeviceChild Extends IUnknown = "BBD3D11DeviceChild"
	Method GetDevice:D3D11Device()
End 

Class D3D11Resource Extends D3D11DeviceChild = "BBD3D11Resource"
	Method GetType()
End 

Class D3D11Device Extends IUnknown = "BBD3D11Device"
	Method CheckFeatureSupport:D3D11_FEATURE_SUPPORT_DESC(d3d11_feature) 
	Method CheckFormatSupport:Int(dxgi_format)	
	Method CheckMultisampleQualityLevels:Int(gxgiFormat, sampleCount)
	Method CreateBlendState:D3D11BlendState(desc:D3D11_BLEND_DESC)
	Method CreateBuffer:D3D11Buffer(desc:D3D11_BUFFER_DESC, initialData:D3D11_SUBRESOURCE_DATA)	
	Method CreateDepthStencilState:D3D11DepthStencilState(desc:D3D11_DEPTH_STENCIL_DESC)	
	Method CreateDepthStencilView:D3D11DepthStencilView(res:D3D11Resource, desc:D3D11_DEPTH_STENCIL_VIEW_DESC)
	Method CreateInputLayout:D3D11InputLayout(desc:D3D11_INPUT_ELEMENT_DESC[], shaderByteCodeWithInputSignature:DataBuffer)	
	Method CreatePixelShader:D3D11PixelShader(shaderByteCode:DataBuffer)
	Method CreateRasterizerState:D3D11RasterizerState(desc:D3D11_RASTERIZER_DESC)
	Method CreateSamplerState:D3D11SamplerState(desc:D3D11_SAMPLER_DESC)
	Method CreateTexture2D:D3D11Texture2D(desc:D3D11_TEXTURE2D_DESC, initialData:D3D11_SUBRESOURCE_DATA[])
	Method CreateVertexShader:D3D11VertexShader(shaderByteCode:DataBuffer)
	Method CreateShaderResourceView:D3D11ShaderResourceView( tex:D3D11Texture2D, srv:D3D11_SHADER_RESOURCE_VIEW_DESC)
	Method GetCreationFlags:Int()	
	Method GetDeviceRemovedReason:Int()	
	Method GetExceptionMode:Int()
	Method GetFeatureLevel:Int()
	Method GetImmediateContext:D3D11DeviceContext()	
	Method GetBackBuffer:D3D11RenderTargetView()
End 
  
Class D3D11DeviceContext Extends D3D11DeviceChild = "BBD3D11DeviceContext"
	Method ClearState:Void()	
	Method Draw:Void(vertexCount, offset )
	Method DrawAuto:Void()	
	Method DrawIndexed:Void(indexCount, startIndexLoc, baseVertLoc )	
	Method DrawIndexedInstanced:Void(indexCountPerInst, instount, stratIndexLoc, baseVertexLoc, startInstLoc)
	Method DrawInstanced:Void(vertexCountPerInst, instCount, startVertLoc, StartInstLoc)	
	Method GetContextFlags:Int()	
	Method GetType:Int()	
	Method ClearRenderTargetView:Void(  view:D3D11RenderTargetView, r#, g#, b# )
	Method ClearDepthStancilView:Void(view:D3D11DepthStencilView, flags, depth#, stencil)
	Method OMSetRenderTargets:Void(renderTargetViews:D3D11RenderTargetView[], depthStencilView:D3D11DepthStencilView)
	Method IASetIndexBuffer:Void(indexBuffer:D3D11Buffer, format, offset)
	Method IASetInputLayout:Void( inputLayout:D3D11InputLayout)
	Method IASetPrimitiveTopology:Void(topology)
	Method IASetVertexBuffers:Void( stratSlot, numSlot, vertexBuffers:D3D11Buffer[], strides:Int[], offsets:Int[])
	Method Map:D3D11MappedResource(resource:D3D11Resource, subResource, mapType, mapFlags)
	Method OMSetBlendState:Void( blendState:D3D11BlendState ) ', blendFactor:Float[], sampleMask )
	Method OMSetDepthStencilState:Void( state:D3D11DepthStencilState, stencilRef)
	Method PSSetConstantBuffers:Void(startSlot, constantBuffers:D3D11Buffer[])
	Method PSSetSamplers:Void(startSlot, num_samplers, samplers:D3D11SamplerState[])	
	Method PSSetShader:Void( pixelShader:D3D11PixelShader)
	Method PSSetShaderResources:Void(startSlot, numViews, shaderResourceViews:D3D11ShaderResourceView[] )
	Method RSSetState:Void( resterizerState:D3D11RasterizerState )	
	Method RSSetViewports:Void( viewports:D3D11_VIEWPORT[] )
	Method Unmap:Void( resource:D3D11Resource, subResource )
	Method VSSetConstantBuffers:Void(startSlot, constantBuffers:D3D11Buffer[])
	Method VSSetSamplers:Void(startSlot, samplers:D3D11SamplerState[] )	
	Method VSSetShader:Void( vertexShader:D3D11VertexShader)
	Method GenerateMips:Void(shaderResourceView:D3D11ShaderResourceView)
	Method UpdateSubresource:Void(pDstResource:D3D11Resource,DstSubresource, x,y,width, height, data:DataBuffer, srcRowPitch, srcDepthPitch)  
End 

Class D3D11Texture2D Extends D3D11Resource = "BBD3D11Texture2D"
	Method Width:Int() Property
	Method Height:Int() Property
	Method MipLevels:Int() Property
	Method Format:Int() Property
	Method Usage:Int() Property
	Method CPUAccessFlags:Int() Property
End 

Class D3D11Buffer Extends D3D11Resource = "BBD3D11Buffer"
	Method ByteWidth:Int()  Property
	Method Usage:Int()	  Property
	Method BindFlags:Int() Property
	Method CPUAccessFlags:Int() Property
	Method MiscFlags:Int() Property
	Method StructureByteStride:Int() Property
End

Class D3D11MappedResource = "D3D11BufferData"
	Method RowPitch() Property
	Method DepthPitch() Property
	Method SetData:Void(data:DataBuffer, size)
End 

Class D3D11View  Extends D3D11DeviceChild = "BBD3D11View"
	Method GetResource:D3D11Resource()
End 

Class D3D11DepthStencilView Extends D3D11View ="BBD3D11DepthStencilView" 
	Method GetDesc:D3D11_DEPTH_STENCIL_VIEW_DESC()
End 

Class D3D11RenderTargetView Extends D3D11View = "BBD3D11RenderTargetView"
	Method GetDesc:D3D11_DEPTH_STENCIL_VIEW_DESC()
End 

Class D3D11ShaderResourceView Extends D3D11View= "BBD3D11ShaderResourceView"
	Method GetDesc:D3D11_SHADER_RESOURCE_VIEW() Property 
End 

Class D3D11BlendState Extends D3D11DeviceChild = "BBD3D11BlendState"
End

Class D3D11RasterizerState Extends D3D11DeviceChild = "BBD3D11RasterizerState"
End

Class D3D11SamplerState Extends D3D11DeviceChild = "BBD3D11SamplerState"
End

Class D3D11DepthStencilState Extends D3D11DeviceChild = "BBD3D11DepthStencilState"
End 

Class D3D11InputLayout Extends D3D11DeviceChild = "BBD3D11InputLayout"
End

Class D3D11PixelShader Extends D3D11DeviceChild = "BBD3D11PixelShader"
End 

Class D3D11VertexShader Extends D3D11DeviceChild = "BBD3D11VertexShader"
End 

Class D3D11_SHADER_RESOURCE_VIEW_DESC = "BBD3D11_SHADER_RESOURCE_VIEW_DESC"
	Method Format:Int() Property  = "GetFormat"
	Method Format:Void(value:int) Property  = "SetFormat"
	Method ViewDimension:Int() Property ="GetViewDimension"
	Method ViewDimension:Void(value:int) Property ="SetViewDimension"
	
'union{
	Method Texture2D:Void(value:D3D11_TEX2D_SRV) Property ="SetTexture2D"
	'' *** TODO ***
'}
End 

Class D3D11_TEX2D_SRV = "BBD3D11_TEX2D_SRV"
	Method MostDetailedMipMap:Int() Property = "GetMostDetailedMipMap"
	Method MipLevels:Int() Property  = "GetMipLevels"
	Method MostDetailedMipMap:Void(value) Property = "SetMostDetailedMipMap"
	Method MipLevels:Void(value) Property = "SetMipLevels"
End 	

Class D3D11_VIEWPORT = "BBD3D11_VIEWPORT"
	Method TopLeftX:Float()Property = "GetTopLeftX"
	Method TopLeftY:float()Property = "GetTopLeftY"
	Method Width:float() Property= "GetWidth"
	Method Height:Float()Property = "GetHeight"
	Method MinDepth:Float()Property = "GetMinDepth"
	Method MaxDepth:Float()Property = "GetMaxDepth"
	Method TopLeftX(value:Float)Property = "SetTopLeftX"
	Method TopLeftY(value:Float)Property = "SetTopLeftY"
	Method Width(value:float)Property = "SetWidth"
	Method Height(value:float)Property  = "SetHeight"
	Method MinDepth(value:Float)Property = "SetMinDepth"
	Method MaxDepth(value:Float)Property = "SetMaxDepth"
End 

Class D3D11_DEPTH_STENCIL_VIEW_DESC = "BBD3D11_DEPTH_STENCIL_VIEW_DESC"

	Method Format:Void(value) Property= "SetFormat"  
	Method ViewDimension:Void(value) Property= "SetViewDimension"  
	Method Texture2D_MipSlice:Void(value) Property= "SetTexture2D_MipSlice"  
	
	'' TODO -- add missing setters
	
	Method Format:Int() Property= "GetFormat"  
	Method ViewDimension:int() Property= "GetViewDimension"  
	Method Texture2D_MipSlice:Int() Property= "GetTexture2D_MipSlice"  
	
	'' TODO -- add missing getters
End 

Class D3D11_RENDER_TARGET_VIEW_DESC = "BBD3D11_RENDER_TARGET_VIEW_DESC"

	Method Format:Void(value) Property = "SetFormat"  
	Method ViewDimension:Void(value)Property = "SetViewDimension"  
	Method Flags:Void(value) Property = "SetFlags"  
	
	'' TODO -- add missing setters
	
	Method Format:Int() Property= "GetFormat"  
	Method ViewDimension:int() Property= "GetViewDimension"  
	Method Flags:Int() Property = "GetFlags"  
	
	'' TODO -- add missing getters
End 


Class D3D11_INPUT_ELEMENT_DESC = "BBD3D11_INPUT_ELEMENT_DESC"
	Method Create:D3D11_INPUT_ELEMENT_DESC(semanticName$, semanticIndex, format, inputSlot, alignedByteOffset, inputClassification,instancedDataStepRate)
End

'' Todo
Class D3D11_SUBRESOURCE_DATA = "BBD3D11_SUBRESOURCE_DATA"
	Method pSysMem(value:DataBuffer) Property = "SetpSysMem"
	Method SysMemPitch(value:int) Property = "SetSysMemPitch"
	Method SysMemSlicePitch(value:int) Property = "SetSysMemSlicePitch"
End 

' todo: getters
Class D3D11_TEXTURE2D_DESC = "BBD3D11_TEXTURE2D_DESC"
  Method Width:Void(value:Int) Property
  Method Height:Void(value:Int) Property
  Method MipLevels:Void(value:Int) Property
  Method ArraySize:Void(value:Int) Property
  Method Format:Void(value:Int) Property
  Method SampleDesc_Count:Void(value:Int) Property
  Method SampleDesc_Quality:Void(value:Int) Property
  Method Usage:Void(value:Int) Property
  Method BindFlags:Void(value:Int) Property
  Method CPUAccessFlags:Void(value:Int) Property
  Method MiscFlags:Void(value:Int) Property
End

Class D3D11_BUFFER_DESC = "BBD3D11_BUFFER_DESC"
	Method Usage:Int() Property = "GetUsage"
	Method BindFlags:Int() Property = "GetBindFlags"
	Method CPUAccessFlags:Int() Property = "GetCPUAccessFlags"
	Method MiscFlags:Int() Property = "GetMiscFlags"
	Method ByteWidth:Int() Property = "GetByteWidth"
	Method Usage:Void(value)Property = "SetUsage"
	Method BindFlags:Void(value) Property = "SetBindFlags"
	Method CPUAccessFlags:Void(value) Property = "SetCPUAccessFlags"
	Method MiscFlags:Void(value) Property = "SetMiscFlags"
	Method ByteWidth:Void(value) Property = "SetByteWidth"
End

Class D3D11_DEPTH_STENCILOP_DESC = "BBD3D11_DEPTH_STENCILOP_DESC"
	Method StencilFailOp:Int() Property = "GetStencilFailOp"
	Method StencilDepthFailOp:Int() Property = "GetStencilDepthFailOp"
	Method StencilPassOp:Int() Property = "GetStencilPassOp"
	Method StencilFunc:Int() Property = "GetStencilFunc"
	Method StencilFailOp:Void(value)Property = "SetStencilFailOp"
	Method StencilDepthFailOp:Void(value) Property = "SetStencilDepthFailOp"
	Method StencilPassOp:Void(value) Property = "SetStencilPassOp"
	Method StencilFunc:Void(value) Property = "SetStencilFunc"
End 

'' http://msdn.microsoft.com/en-us/library/windows/desktop/ff476207
Class D3D11_SAMPLER_DESC = "BBD3D11_SAMPLER_DESC"
  Method Filter:Int() = "GetFilter"
  Method AddressU:Int() = "GetAddressU"
  Method AddressV:Int() = "GetAddressV"
  Method AddressW:Int() = "GetAddressW"
  Method MipLODBias:Float() = "GetMipLODBias"
  Method MaxAnisotropy:Int() = "GetMaxAnisotropy"
  Method ComparisonFunc:Int() = "GetComparisonFunc"
  Method BorderColor:Float[]() = "GetBorderColor"
  Method MinLOD:Float() = "GetMinLOD"
  Method MaxLOD:Float() = "GetMaxLOD"
  Method Filter:Void(value:Int) = "SetFilter"
  Method AddressU:Void(value:Int) = "SetAddressU"
  Method AddressV:Void(value:Int) = "SetAddressV"
  Method AddressW:Void(value:Int) = "SetAddressW"
  Method MipLODBias:Void(value:Float) = "SetMipLODBias"
  Method MaxAnisotropy:Void(value:Int) = "SetMaxAnisotropy"
  Method ComparisonFunc:Void(value:Int) = "SetComparisonFunc"
  Method BorderColor:Void[](value:Float) = "SetBorderColor"
  Method MinLOD:Void(value:Float) = "SetMinLOD"
  Method MaxLOD:Void(value:Float) = "SetMaxLOD"
End 

'' http://msdn.microsoft.com/en-us/library/windows/desktop/ff476110
Class D3D11_DEPTH_STENCIL_DESC = "BBD3D11_DEPTH_STENCIL_DESC"
	Method DepthEnable:Int() Property = "GetDepthEnable"
	Method DepthWriteMask:Int() Property= "GetDepthWriteMask"
	Method DepthFunc:Int() Property= "GetDepthFunc"
	Method StencilEnable:Int() Property= "GetStencilEnable"
	Method StencilReadMask:Int() Property= "GetStencilReadMask"
	Method StencilWriteMask:Int() Property= "GetStencilWriteMask"
	Method DepthEnable:Void(value:int) Property= "SetDepthEnable"
	Method DepthWriteMask:Void(value:int) Property= "SetDepthWriteMask"
	Method DepthFunc:Void(value:int) Property= "SetDepthFunc"
	Method StencilEnable:Void(value:int) Property= "SetStencilEnable"
	Method StencilReadMask:Void(value:int) Property= "SetStencilReadMask"
	Method StencilWriteMask:Void(value:int) Property= "SetStencilWriteMask"
	Method FrontFace:D3D11_DEPTH_STENCILOP_DESC() Property = "GetFrontFace"
	Method BackFace:D3D11_DEPTH_STENCILOP_DESC() Property = "GetBackFace"
End

'' http://msdn.microsoft.com/en-us/library/windows/desktop/ff476087
Class D3D11_BLEND_DESC = "BBD3D11_BLEND_DESC"
	Method AlphaToCoverageEnable:int() Property= "GetAlphaToCoverageEnable"
	Method IndependentBlendEnable:int() Property= "GetIndependentBlendEnable"
	Method AlphaToCoverageEnable:Void(value)Property= "SetAlphaToCoverageEnable"
	Method IndependentBlendEnable:Void(value) Property= "SetIndependentBlendEnable"
	Method GetRenderTarget:D3D11_RENDER_TARGET_BLEND_DESC(index) Property= "GetRenderTarget"
End 

'' http://msdn.microsoft.com/en-us/library/windows/desktop/ff476198
Class D3D11_RASTERIZER_DESC = "BBD3D11_RASTERIZER_DESC"
  Method FillMode:Int() = "GetFillMode"
  Method CullMode:Int() = "GetCullMode"
  Method FrontCounterClockwise:Int() = "GetFrontCounterClockwise"
  Method DepthBias:Int() = "GetDepthBias"
  Method DepthBiasClamp:Float() = "GetDepthBiasClamp"
  Method SlopeScaledDepthBias:Float() = "GetSlopeScaledDepthBias"
  Method DepthClipEnable:Int() = "GetDepthClipEnable"
  Method ScissorEnable:Int() = "GetScissorEnable"
  Method MultisampleEnable:Int() = "GetMultisampleEnable"
  Method AntialiasedLineEnable:Int() = "GetAntialiasedLineEnable"
  Method FillMode:Void(value:int) = "SetFillMode"
  Method CullMode:Void(value:int) = "SetCullMode"
  Method FrontCounterClockwise:Void(value:int) = "SetFrontCounterClockwise"
  Method DepthBias:Void(value:int) = "SetDepthBias"
  Method DepthBiasClamp:Void(value:Float) = "SetDepthBiasClamp"
  Method SlopeScaledDepthBias:Void(value:Float) = "SetSlopeScaledDepthBias"
  Method DepthClipEnable:Void(value:int) = "SetDepthClipEnable"
  Method ScissorEnable:Void(value:int) = "SetScissorEnable"
  Method MultisampleEnable:Void(value:int) = "SetMultisampleEnable"
  Method AntialiasedLineEnable:Void(value:int) = "SetAntialiasedLineEnable"
End 

Class D3D11_RENDER_TARGET_BLEND_DESC = "BBD3D11_RENDER_TARGET_BLEND_DESC"
	Method BlendEnable:int()Property= "GetBlendEnable"
	Method SrcBlend:int() Property= "GetSrcBlend"
	Method DestBlend:int() Property= "GetDestBlend"
	Method BlendOp:int() Property= "GetBlendOp"
	Method SrcBlendAlpha:int() Property= "GetSrcBlendAlpha"
	Method DestBlendAlpha:int() Property= "GetDestBlendAlpha"
	Method BlendOpAlpha:int()Property= "GetBlendOpAlpha"
	Method RenderTargetWriteMask:int() Property= "GetRenderTargetWriteMask"
	Method BlendEnable:Void(value:int) Property= "SetBlendEnable"
	Method SrcBlend:Void(value:int) Property= "SetSrcBlend"
	Method DestBlend:Void(value:int)  Property= "SetDestBlend"
	Method BlendOp:Void(value:int)  Property= "SetBlendOp"
	Method SrcBlendAlpha:Void(value:int) Property= "SetSrcBlendAlpha"
	Method DestBlendAlpha:Void(value:int)Property= "SetDestBlendAlpha"
	Method BlendOpAlpha:Void(value:int) Property= "SetBlendOpAlpha"
	Method RenderTargetWriteMask:Void(value:int)Property= "SetRenderTargetWriteMask"
End

'' Todo: implement in c++
'' D3D11_FEATURE_SUPPORT_DESC is not part of d3d, 
Class D3D11_FEATURE_SUPPORT_DESC = "BBD3D11_FEATURE_SUPPORT_DESC"
	Method D3D11_FEATURE_THREADING:D3D11_FEATURE_DATA_THREADING()
	Method D3D11_FEATURE_DOUBLES:D3D11_FEATURE_DATA_DOUBLES()
	Method D3D11_FEATURE_FORMAT_SUPPORT:D3D11_FEATURE_DATA_FORMAT_SUPPORT()
	Method D3D11_FEATURE_FORMAT_SUPPORT2:D3D11_FEATURE_DATA_FORMAT_SUPPORT2()
	Method D3D11_FEATURE_D3D10_X_HARDWARE_OPTIONS:D3D11_FEATURE_DATA_D3D10_X_HARDWARE_OPTIONS()
	Method D3D11_FEATURE_D3D11_OPTIONS:D3D11_FEATURE_DATA_D3D11_OPTIONS()
	Method D3D11_FEATURE_ARCHITECTURE_INFO:D3D11_FEATURE_DATA_ARCHITECTURE_INFO()
	Method D3D11_FEATURE_D3D9_OPTIONS:D3D11_FEATURE_DATA_D3D9_OPTIONS()
	Method D3D11_FEATURE_SHADER_MIN_PRECISION_SUPPORT:D3D11_FEATURE_DATA_SHADER_MIN_PRECISION_SUPPORT()
	Method D3D11_FEATURE_D3D9_SHADOW_SUPPORT:D3D11_FEATURE_DATA_D3D9_SHADOW_SUPPORT()
End

Class D3D11_FEATURE_DATA_THREADING = "BBD3D11_FEATURE_DATA_THREADING"
	Method DriverConcurrentCreates?() Property
	Method DriverCommandLists?() Property
End

Class D3D11_FEATURE_DATA_DOUBLES = "BBD3D11_FEATURE_DATA_DOUBLES"
	Method DoublePrecisionFloatShaderOps?() Property 
End

'' http://msdn.microsoft.com/en-us/library/windows/desktop/ff476128
'' Describes which resources are supported by the current graphics driver for a given format.
Class D3D11_FEATURE_DATA_FORMAT_SUPPORT = "BBD3D11_FEATURE_DATA_FORMAT_SUPPORT"
	Method InFormat:Int() Property 'DXGI_FORMAT
	Method OutFormatSupport:Int() Property 
End

'' http://msdn.microsoft.com/en-us/library/windows/desktop/ff476129
'' Describes which resources are supported by the current graphics driver for a given format.
Class D3D11_FEATURE_DATA_FORMAT_SUPPORT2 = "BBD3D11_FEATURE_DATA_FORMAT_SUPPORT2"
	Method InFormat:Int() Property 'DXGI_FORMAT
	Method OutFormatSupport2:Int() Property 
End

'' http://msdn.microsoft.com/en-us/library/windows/desktop/ff476126
'' Describes compute shader and raw and structured buffer support in the current graphics driver.
Class D3D11_FEATURE_DATA_D3D10_X_HARDWARE_OPTIONS = "BBD3D11_FEATURE_DATA_D3D10_X_HARDWARE_OPTIONS"
	Method ComputeShaders_Plus_RawAndStructuredBuffers_Via_Shader_4_x?() Property 
End

'' http://msdn.microsoft.com/en-us/library/windows/desktop/hh404457
'' Describes Direct3D 11.1 feature options in the current graphics driver.
Class D3D11_FEATURE_DATA_D3D11_OPTIONS = "BBD3D11_FEATURE_DATA_D3D11_OPTIONS"
	Method OutputMergerLogicOp?() Property 
	Method UAVOnlyRenderingForcedSampleCount?() Property
	Method DiscardAPIsSeenByDriver?() Property
	Method FlagsForUpdateAndCopySeenByDriver?() Property
	Method ClearView?() Property
	Method CopyWithOverlap?() Property
	Method ConstantBufferPartialUpdate?() Property
	Method ConstantBufferOffsetting?() Property
	Method MapNoOverwriteOnDynamicConstantBuffer?() Property
	Method MapNoOverwriteOnDynamicBufferSRV?() Property
	Method MultisampleRTVWithForcedSampleCountOne?() Property
	Method SAD4ShaderInstructions?() Property
	Method ExtendedDoublesShaderInstructions?() Property
	Method ExtendedResourceSharing?() Property
End

'' http://msdn.microsoft.com/en-us/library/windows/desktop/hh404455
'' Describes information about Direct3D 11.1 adapter architecture.
Class D3D11_FEATURE_DATA_ARCHITECTURE_INFO = "BBD3D11_FEATURE_DATA_ARCHITECTURE_INFO"
	Method TileBasedDeferredRenderer?() Property 
End

'' http://msdn.microsoft.com/en-us/library/windows/desktop/hh404458
'' Describes Direct3D 9 feature options in the current graphics driver.
Class D3D11_FEATURE_DATA_D3D9_OPTIONS = "BBD3D11_FEATURE_DATA_D3D9_OPTIONS"
	Method FullNonPow2TextureSupport?() Property 
End

'' http://msdn.microsoft.com/en-us/library/windows/desktop/hh404460
'' Describes precision support options for shaders in the current graphics driver.
Class D3D11_FEATURE_DATA_SHADER_MIN_PRECISION_SUPPORT = "BBD3D11_FEATURE_DATA_SHADER_MIN_PRECISION_SUPPORT"
	Method PixelShaderMinPrecision%() Property 
	Method AllOtherShaderStagesMinPrecision%() Property 
End

'' escribes Direct3D 9 shadow support in the current graphics driver.
Class D3D11_FEATURE_DATA_D3D9_SHADOW_SUPPORT = "BBD3D11_FEATURE_DATA_D3D9_SHADOW_SUPPORT"
	Method SupportsDepthAsTextureWithLessEqualComparisonFilter?() Property 
End