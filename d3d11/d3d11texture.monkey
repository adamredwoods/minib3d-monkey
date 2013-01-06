
''--------------------------------------------------------
'' Windows 8 MiniB3D Driver
'' (C) 2012 Sascha Schmidt
''--------------------------------------------------------

Import minib3d
Import brl

Class D3D11Texture Implements ITexture 

	Global TextureCnt% = 0
	Global TextureMap:= New IntMap<D3D11Texture>
	
	' ---------------
	
	Field _tex:D3D11Texture2D
	Field _resourceView:D3D11ShaderResourceView
	
	' ---------------

	'' *** TODO ***
	'' - remove annoying integer handles(gltex)...

	Function AddTexture(gltex:int[], texture:D3D11Texture)
	
		If gltex[0] = 0 Then 
			TextureCnt+=1
			gltex[0] = TextureCnt
		End 
				
		'' add to texMap
		If Not TextureMap Then 
			TextureMap = New IntMap<D3D11Texture>
		End 
		TextureMap.Set( gltex[0], texture ) 
				
	End 
	
	Function RemoveTexture(id:Int)
	
		If id <> 0 Then 
			Local tex:= TextureMap.Get(id)
			If tex Then 
				tex.Release()
				TextureMap.Remove(id)
			End 
		End 
		
	End 
	
	''------------------------------
	
	Method New(tex:TTexture, mipMaps? )'= False, dynamic? = False, cubemap? = False)
	
		Local mipLevels 	= 1
		Local miscFlags 	= 0
		Local bindflags 	= D3D11_BIND_SHADER_RESOURCE'| D3D11_BIND_RENDER_TARGET
		Local resMipLevels 	= 1
		Local usage 		= 0
		Local accessFlags 	= 0
		Local arraySize 	= 1
		
		'' does this texture contains mipmaps?
		If mipMaps Then 

			mipLevels 		= 0
			miscFlags 		= D3D11_RESOURCE_MISC_GENERATE_MIPS
			bindflags 		= D3D11_BIND_SHADER_RESOURCE | D3D11_BIND_RENDER_TARGET
			resMipLevels 	= -1
			
		Endif
		
		#rem
		If dynamic Then 
		
			usage 		= D3D11_USAGE_DYNAMIC
			accessFlags = D3D11_CPU_ACCESS_WRITE
			bindflags 	= D3D11_BIND_SHADER_RESOURCE
			
		End 
		
		If cubemap Then 
			miscFlags	|= D3D11_RESOURCE_MISC_TEXTURECUBE;
			arraySize	 = 6;
		End 
		#end 
		
		'' init texture desc
		Local desc:= new D3D11_TEXTURE2D_DESC
		desc.Width = tex.width 
		desc.Height = tex.height
		desc.MipLevels = mipLevels
		desc.ArraySize = arraySize
		desc.Format = DXGI_FORMAT_R8G8B8A8_UNORM' isn't it bgra??
		desc.SampleDesc_Count = 1
		desc.SampleDesc_Quality = 0
		desc.Usage = D3D11_USAGE_DEFAULT;
		desc.BindFlags = bindflags
		desc.CPUAccessFlags = 0'D3D11_CPU_ACCESS_WRITE ;
		desc.MiscFlags = miscFlags; 
		
		'' create texture object
		_tex = D3D11.Device.CreateTexture2D( desc, [] )

		'' create shader resource
		Local rvdesc:= New D3D11_SHADER_RESOURCE_VIEW_DESC
		rvdesc.Format=DXGI_FORMAT_R8G8B8A8_UNORM'' TODO --- implement getter of D3D11_TEXTURE2D_DESC.Format
		rvdesc.ViewDimension=D3D11_SRV_DIMENSION_TEXTURE2D;
		Local srv:= New D3D11_TEX2D_SRV''TODO --- do proper implementation
		srv.MostDetailedMipMap=0;
		srv.MipLevels=resMipLevels
		rvdesc.Texture2D = srv
	
		_resourceView = D3D11.Device.CreateShaderResourceView( _tex, rvdesc)

		' generate mipmaps
		If mipMaps Then 
			D3D11.DeviceContext.GenerateMips(_resourceView);
		End 
		
		D3D11Texture.AddTexture(tex.gltex, Self)
		
	End
	
	Method Release()
		If _tex Then
			_tex.Release()
			_tex = Null 
		End 
	End 

	Method SetData(index:Int, pix:TPixmap)
	
		Local d3dPix:= D3D11Pixmap(pix)
		D3D11.DeviceContext.UpdateSubresource(_tex, index, 0,0,pix.width, pix.height, d3dPix.pixels, pix.width*4,0)
		
	End 
	
	Method Clear() 
	
		'' *** TODO ***
		
	End 
	
End 