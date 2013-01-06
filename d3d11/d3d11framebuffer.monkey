
''--------------------------------------------------------
'' Windows 8 MiniB3D Driver
'' (C) 2012 Sascha Schmidt
''--------------------------------------------------------

Import minib3d

Class D3D11FrameBuffer Extends FrameBuffer

	Field _texture:D3D11Texture2D
	Field _renderTargetView:D3D11RenderTargetView
	Field _shaderResourceView:D3D11ShaderResourceView
	
	Method New(width,height)
	
		'' Setup the render target texture description.
		
		'' Create the render target texture.
		
		'' Setup the description of the render target view.
		
		'' Create the render target view.
		
		'' Setup the description of the shader resource view.
		
		'' Create the shader resource view.
	End 
	
	Method Clear(depth:Int=0)
	End 
	
	Method Release()
	
		If _shaderResourceView
			m_shaderResourceView.Release()
			m_shaderResourceView = Null
		End 
	
		If _renderTargetView
			m_renderTargetView.Release()
			m_renderTargetView = Null
		End 
	
		If m_renderTargetTexture
			_renderTargetTexture.Release()
			_renderTargetTexture = Null
		End 
	
	End 
	
	Method Texture:D3D11Texture2D() Property
		Return _texture
	End 
	
	Method RenderTargetView:D3D11RenderTargetView() Property
		Return _renderTargetView
	End
	
	Method ShaderResourceView:D3D11ShaderResourceView() Property 
		Return _shaderResourceView
	End 

End 