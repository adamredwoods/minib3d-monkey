
''--------------------------------------------------------
'' Windows 8 MiniB3D Driver
'' (C) 2012 Sascha Schmidt
''--------------------------------------------------------

#rem

Notes:

	Installation:
	--------------------------------------------------------
	
	- copy D3Dcompiler_46.dll to '..\Release\MonkeyGame\AppX'
	- make sure that #MINIB3D_D3D11_RELEASE is set to "false" during development
	
	Limmitations:
	--------------------------------------------------------
	
	- Needs at least feature level 9.3 hardware capabilities for the implemented default shaders.
	- Runtime shader compilation is not supported for deployment.(handled internally)
	- No write access to 'monkey://data/' = manual shader copy before redistribution 

	Redistributing application:
	--------------------------------------------------------
	
	See build output for app specific 'monkey://internal/' path!
	
	- remove D3Dcompiler_46.Dll from '..\Release\MonkeyGame\AppX'
	- copy precompiled shaders(monkey://internal/*.bin) to 'monkey://data/'
	- copy shader reflection info(monkey://internal/*.refl.bin) to 'monkey://data/'
	- set #MINIB3D_D3D11_RELEASE to "true"
	- rebuild the monkey project

#end 

#MINIB3D_DRIVER="d3d11"
#MINIB3D_D3D11_RELEASE="false" 
#MINIB3D_D3D11_PER_PIXEL_LIGHTING="false"

#Print "miniB3D D3D11"

#If TARGET<>"win8"
	#Error "Need windows 8."
#Endif

'' d3d11

Import minib3d.d3d11.driver.d3d11
Import minib3d.d3d11.driver.d3d11constants

#If MINIB3D_D3D11_RELEASE<>"true" Then 
#Print "**** D3D11 DEVELOP MODE ****"
Import minib3d.d3d11.driver.d3d11compiler
#Else
#Print "**** D3D11 RELEASE MODE ****"
#End 

'' minib3d driver

Import minib3d.d3d11.d3d11pixmap
Import minib3d.d3d11.d3d11texture
Import minib3d.d3d11.d3d11render
Import minib3d.d3d11.d3d11mesh
Import minib3d.d3d11.d3d11shader
Import minib3d.d3d11.d3d11shader_default
Import minib3d.d3d11.d3d11shader_reflection


Class D3D11

	Global Device:D3D11Device
	Global DeviceContext:D3D11DeviceContext 
	
	Global MeshCnt% = 0
	Global MeshMap:= New IntMap<D3D11Mesh>
	
	Global TextureCnt% = 0
	Global TextureMap:= New IntMap<D3D11Texture>
	
	Function Init()
	
		Device = New D3D11Device' grabbbed from monkey internally
		DeviceContext = Device.GetImmediateContext()

		#If MINIB3D_D3D11_RELEASE<>"true" Then
	
				'' init d3dcomipler.dll
				If Not D3DInitCompilerDll() Then 
					Error "Failed to load D3Dcomiler_46.dll from ...\win8\Release\MonkeyGame\AppX"
				End 
				
				'' Here are the precompiled shaders stored...
				'' usually ..\AppData\Local\Packages\[Identity Name]\LocalState
				Print_Monkey_Internal()
		#End
		
	End 

	Function CreateD3D11Mesh:D3D11Mesh(surf:TSurface)
	
		Local m:D3D11Mesh = Null
		
		If surf.vbo_id[0]=0
			MeshCnt+=1
			surf.vbo_id[0] = MeshCnt
			m = New D3D11Mesh
			MeshMap.Set(MeshCnt,m)
		Endif
		
		If Not m Then 
			m = MeshMap.Get (surf.vbo_id[0])
		End

		Return m
		
	End 
	
	Function FreeD3D11Mesh()
	
		If surf.vbo_id[0] <> 0 Then 
			MeshMap.Remove(surf.vbo_id[0])
		End 
		
	End 
	
	Function CreateD3D11Texture:D3D11Texture(tex:TTexture, mipMaps?)
	
		Local t:D3D11Texture = Null
		
		If tex.gltex[0] = 0 Then 
			TextureCnt+=1
			tex.gltex[0] = TextureCnt
			t = New D3D11Texture(tex, mipMaps)
			TextureMap.Set( tex.gltex[0], t ) 
		End 
				
		If Not t Then 
			t = TextureMap.Get(tex.gltex[0])
		End
		
		Return t
		
	End 
	
	Function FreeD3D11Texture(id:Int)
	
		If id <> 0 Then 
			TextureMap.Remove(id)
		End 
		
	End 
	
	Function CreateD3D11DepthBuffer:D3D11Texture2D(format)
	
		'' init depth buffer desc
		Local desc:= new D3D11_TEXTURE2D_DESC
		desc.Width = DeviceWidth  
		desc.Height = DeviceHeight
		desc.MipLevels = 1
		desc.ArraySize = 1
		desc.Format = format
		desc.SampleDesc_Count = 1
		desc.SampleDesc_Quality = 0
		desc.Usage = D3D11_USAGE_DEFAULT
		desc.BindFlags = D3D11_BIND_DEPTH_STENCIL
		desc.CPUAccessFlags = 0
		desc.MiscFlags = 0; 
		
		Return Device.CreateTexture2D( desc, [] )
	End 
	
	Function CreateD3D11BlendState:D3D11BlendState(enable, srcBlend, descBlend, blendOp, srcAlphaBlend = D3D11_BLEND_ONE, descAlphaBlend = D3D11_BLEND_ZERO, blendAlphaOp = D3D11_BLEND_OP_ADD)
	
		Local desc:= New D3D11_BLEND_DESC
		desc.AlphaToCoverageEnable=FALSE;
		desc.IndependentBlendEnable=False;
	
		Local target:= desc.GetRenderTarget(0)
		target.BlendEnable = enable 
		'---------
		target.BlendOp = blendOp 
		target.DestBlend = descBlend 
		target.SrcBlend = srcBlend 
		'---------
		target.BlendOpAlpha = blendAlphaOp 
		target.SrcBlendAlpha = srcAlphaBlend
		target.DestBlendAlpha = descAlphaBlend 
		'---------
		target.RenderTargetWriteMask = D3D11_COLOR_WRITE_ENABLE_ALL 

		Return Device.CreateBlendState(desc)
		
	End

	Function CreateD3D11RasterizerState:D3D11RasterizerState(cullMode, fillMode)
		
		Local desc:= new D3D11_RASTERIZER_DESC
		desc.AntialiasedLineEnable = False 
		desc.CullMode = cullMode'D3D11_CULL_BACK
		desc.DepthBias = 0
		desc.DepthBiasClamp = 0
		desc.DepthClipEnable = False
		desc.FillMode = fillMode'D3D11_FILL_SOLID
		desc.FrontCounterClockwise = 0
		desc.MultisampleEnable = False
		desc.ScissorEnable = False 
		desc.SlopeScaledDepthBias = 0
			
		Return Device.CreateRasterizerState(desc)
			
	End
	
	Function CreateD3D11DepthStencilView:D3D11DepthStencilView(depthBuffer:D3D11Texture2D, format)
	
		Local desc:= New D3D11_DEPTH_STENCIL_VIEW_DESC'' TODO: does not work!
		desc.Format = DXGI_FORMAT_D24_UNORM_S8_UINT'format
		desc.ViewDimension = D3D11_DSV_DIMENSION_TEXTURE2D
		desc.Texture2D_MipSlice = 0
			
		Return Device.CreateDepthStencilView(depthBuffer, Null)
		
	End 
	
	Function CreateD3D11SamplerState:D3D11SamplerState(filter, u,v, w , bias#)
		
		local desc:= new D3D11_SAMPLER_DESC 
		desc.AddressU = u
		desc.AddressV = v  
		desc.AddressW = D3D11_TEXTURE_ADDRESS_CLAMP        
		desc.Filter = filter 
		desc.ComparisonFunc = D3D11_COMPARISON_NEVER
		desc.MipLODBias = bias
		
		If Device.GetFeatureLevel() > D3D_FEATURE_LEVEL_9_1 Then 
			desc.MaxAnisotropy = 16
		Else
			desc.MaxAnisotropy = 2
		End 
			
			
		Return Device.CreateSamplerState(desc)
			
	End
	
	Function CreateD3D11DepthStancilState:D3D11DepthStencilState(depthBufferEnable?, depthBufferWriteEnable?)
	
		Local writeMask = D3D11_DEPTH_WRITE_MASK_ALL
		If Not depthBufferWriteEnable Then writeMask = D3D11_DEPTH_WRITE_MASK_ZERO
		
		Local desc:= new D3D11_DEPTH_STENCIL_DESC
		desc.DepthEnable = depthBufferEnable
		desc.DepthFunc = D3D11_COMPARISON_LESS
		desc.DepthWriteMask = writeMask
		
		'' todo 

		#rem
		
		desc.StencilEnable = true;
		desc.StencilReadMask = 0xFF;
		desc.StencilWriteMask = 0xFF;
	
		// Stencil operations if pixel is front-facing.
		desc.FrontFace.StencilFailOp = D3D11_STENCIL_OP_KEEP;
		desc.FrontFace.StencilDepthFailOp = D3D11_STENCIL_OP_INCR;
		desc.FrontFace.StencilPassOp = D3D11_STENCIL_OP_KEEP;
		desc.FrontFace.StencilFunc = D3D11_COMPARISON_ALWAYS;
	
		// Stencil operations if pixel is back-facing.
		desc.BackFace.StencilFailOp = D3D11_STENCIL_OP_KEEP;
		desc.BackFace.StencilDepthFailOp = D3D11_STENCIL_OP_DECR;
		desc.BackFace.StencilPassOp = D3D11_STENCIL_OP_KEEP;
		desc.BackFace.StencilFunc = D3D11_COMPARISON_ALWAYS;
		
		#end 
			
		Return Device.CreateDepthStencilState(desc)
	End
	
End 

