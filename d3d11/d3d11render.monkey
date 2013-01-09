
''--------------------------------------------------------
'' Windows 8 MiniB3D Driver
'' (C) 2012 Sascha Schmidt
''--------------------------------------------------------

Import minib3d
Import minib3d.d3d11


Const D3D11_MIPMAP_BIAS# = -0.5

Function SetRender(flags:Int=0)
	TRender.render = New D3D11Graphics
	TRender.render.GraphicsInit(flags)
End 

Class D3D11Graphics Extends TRender' Implements IRender

Private 

	Field _featureLevel:Int 
	Field _caps:D3DHardwareCaps
	Field _device:D3D11Device
	Field _deviceContext:D3D11DeviceContext
	Field _depthBuffer:D3D11Texture2D
	Field _depthStencilView:D3D11DepthStencilView
	Field _backBufferView:D3D11RenderTargetView
	Field _inputLayout:D3D11InputLayout
	
	'' renderstates
	Field _rasterizerStates:D3D11RasterizerState[]
	Field _rasterizerWire:D3D11RasterizerState
	Field _depthStencil:D3D11DepthStencilState
	Field _depthStencilDefault:D3D11DepthStencilState
	Field _depthStencilNone:D3D11DepthStencilState
	Field _depthStencilNoWrite:D3D11DepthStencilState
	Field _depthStencilNoDepth:D3D11DepthStencilState 
	Field _blendStates:D3D11BlendState[] 
	Field _samplerState:D3D11SamplerState 	
	Field _st_uvNormal:UVSamplerState
	Field _st_uvSmooth:UVSamplerState 	
	
	'' default shader interfaces
	Field _shaderFog:IShaderFog
	Field _shaderColor:IShaderColor
	Field _shaderTexture:IShaderTexture
	Field _shaderLights:IShaderLights
	Field _shaderMatrices:IShaderMatrices
	
	'' last combined brush values
	Field _tex_count%
	Field _red#,_green#,_blue#,_alpha#
	Field _shine#,_blend%,_fx%
	Field _tex_flags%, _textures:TTexture[]
	Field _lastMesh:D3D11Mesh 
	Field _tex_count2%
	Field _red2#,_green2#,_blue2#,_alpha2#
	Field _shine2#,_blend2%,_fx2%
	Field _tex_flags2%, _textures2:TTexture[]
	Field _ambient_red, _ambient_green, _ambient_blue 
	Field _lightEnabled?, _depthBufferEnabled?, _fogEnabled?, _disableDepth?
	Field _lightIsEnabled? = False
	
	'' util
	Field _lights:= New List<TLight>' lights per frame/camera
	Field _initializedShader:= New IntMap<TShader>
	Field _shader:D3D11Shader 'currently selected shader
	Field _lastSurf:TSurface ''used to batch sprite state switching
	Field _lastTexture:TTexture
	Field _sampleStates:D3D11SamplerState[8]
	Field _d3d11Textures:D3D11ShaderResourceView[8]
	Field _cam:TCamera
	Field _alpha_list:= New List<TSurface>
	
Public 

	Method GraphicsInit(flags:Int)
		D3D11.Init()
		D3D11Pixmap.Init()
		
		width = DeviceWidth
		height = DeviceHeight 
		
		' get device
		_device = D3D11.Device
		_deviceContext = D3D11.DeviceContext
		
		' get device feature level & caps
		_featureLevel = _device.GetFeatureLevel()
		_caps = New D3DHardwareCaps(_featureLevel)
		
		'' get back&depth buffers
		_backBufferView = _device.GetBackBuffer()
		_depthBuffer = D3D11.CreateD3D11DepthBuffer(DXGI_FORMAT_D24_UNORM_S8_UINT)
		_depthStencilView = D3D11.CreateD3D11DepthStencilView(_depthBuffer, DXGI_FORMAT_D24_UNORM_S8_UINT)
		
		'' check for level 9.3 hardware capabilities 
		'' and try to load the default shader
		Select _featureLevel
			Case D3D_FEATURE_LEVEL_9_1, D3D_FEATURE_LEVEL_9_2
				Error "Win8 miniB3D default shader needs at least D3D_FEATURE_LEVEL_9_3."
			Default
				TShader.LoadDefaultShader(New D3D11DefaultShader())	
		End 
		

		'' states
		_rasterizerStates = [ 
			D3D11.CreateD3D11RasterizerState(D3D11_CULL_NONE, D3D11_FILL_SOLID),
			D3D11.CreateD3D11RasterizerState(D3D11_CULL_BACK, D3D11_FILL_SOLID),
			D3D11.CreateD3D11RasterizerState(D3D11_CULL_FRONT, D3D11_FILL_SOLID)]
			
		_rasterizerWire = 
			D3D11.CreateD3D11RasterizerState(D3D11_CULL_NONE, D3D11_FILL_WIREFRAME)
			
		_depthStencilDefault 	= D3D11.CreateD3D11DepthStancilState(True, True)
		_depthStencilNone 		= D3D11.CreateD3D11DepthStancilState(False, False)
		_depthStencilNoWrite 	= D3D11.CreateD3D11DepthStancilState(True, False)
		_depthStencilNoDepth 	= D3D11.CreateD3D11DepthStancilState(False, True)
		_depthStencil = _depthStencilDefault
		
		'' Todo
		'' minib3d blend states
		_blendStates = [
			D3D11.CreateD3D11BlendState(1,D3D11_BLEND_SRC_ALPHA, D3D11_BLEND_INV_SRC_ALPHA, D3D11_BLEND_OP_ADD),
			D3D11.CreateD3D11BlendState(1,D3D11_BLEND_SRC_ALPHA, D3D11_BLEND_INV_SRC_ALPHA, D3D11_BLEND_OP_ADD),
			D3D11.CreateD3D11BlendState(1,D3D11_BLEND_ZERO, D3D11_BLEND_SRC_COLOR, D3D11_BLEND_OP_ADD),
			D3D11.CreateD3D11BlendState(1,D3D11_BLEND_ONE, D3D11_BLEND_ONE, D3D11_BLEND_OP_ADD),
			D3D11.CreateD3D11BlendState(0,D3D11_BLEND_ONE, D3D11_BLEND_ZERO, D3D11_BLEND_OP_ADD)]
		
		'' point filter uv sampler states
		_st_uvNormal = New UVSamplerState( D3D11_FILTER_MIN_MAG_MIP_POINT,D3D11_MIPMAP_BIAS )
		
		'' linear filter uv sampler states		
		_st_uvSmooth = New UVSamplerState( D3D11_FILTER_MIN_MAG_MIP_LINEAR,D3D11_MIPMAP_BIAS )
		
		 
		'' prevent shader EXECUTION WARNING #352: DEVICE_DRAW_SAMPLER_NOT_SET
		'' ??
		For Local i= 0 Until 8; _sampleStates[i] = _st_uvSmooth._wU_wV; End 
		_deviceContext.PSSetSamplers(0,8, _sampleStates)
		D3D11.DeviceContext.IASetPrimitiveTopology(D3D_PRIMITIVE_TOPOLOGY_TRIANGLELIST)
	End
	
	Method Reset:Void()
		_lights.Clear()
		_initializedShader.Clear()
		UpdateShader(Null)'' force per frame constants update
	End 
	
	Method Finish:Void() 
	End 
	
	Method Render:Void(ent:TEntity, cam:TCamera = Null) 	

		Local mesh:TMesh = TMesh(ent)
		If Not mesh Then Return
		Local shader:= D3D11Shader(TShader.g_shader)
		Local shaderSwitch? = False
		
		'' - not target specific
		If D3D11Shader(ent.shader_brush) And (Not shader.override) And ent.shader_brush.active

			shader = D3D11Shader(ent.shader_brush)

			'' if we are using a brush with a dedicated render routine
			If IShaderEntity(shader)'' call entity render routine
				IShaderEntity(shader).RenderEntity(cam, ent)
				Return
			Else
				'' assign brush shader
				shaderSwitch = UpdateShader(shader)
			End
			
		Else 
			
			'' assign global shader
			shaderSwitch = UpdateShader(shader)
			
		End
		
		'' update per object constants
		If _shaderMatrices Then 
		
			If TSprite(ent) Then 
				_shaderMatrices.WorldMatrix(TSprite(ent).mat_sp)
			Else
				_shaderMatrices.WorldMatrix(ent.mat)
			End 
			

			_shaderMatrices.EyePosition( _cam.mat.grid[3][0],
										 _cam.mat.grid[3][1],
										 _cam.mat.grid[3][2]) 

		End
		
		''--------------------------
		
		'' draw surfaces with alpha last
		Local temp_list:List<TSurface> = mesh.surf_list
		_alpha_list.Clear()
		
		''run through surfaces twice, sort alpha surfaces for second pass
		For Local alphaloop:= alpha_pass To 1 ''if alpha_pass is on, no need to reorder alpha surfs
			For Local surf:=  Eachin temp_list

				''draw alpha surfaces last in second loop
				''also catch surfaces with no vertex
				If surf.no_verts=0 Then Continue
				If (surf.alpha_enable And alphaloop < 1)
					_alpha_list.AddLast(surf)				
					Continue
				Endif

				' Update vertex & index buffers
				UpdateBuffers(surf, mesh)
				
				' skip per material constants update if nothing changed
				CombineBrushes(ent.brush, surf.brush)
				If Not CompareBrushes() Then 
				
					_red2   = _red
					_green2 = _green
					_blue2  = _blue
					_alpha2 = _alpha
					_shine2 = _shine
					_blend2 = _blend
					_fx2    = _fx
					_textures2 = _textures
					_tex_count2 = _tex_count
					
					''batch optimizations (sprites/meshes)
					Local skip_sprite_state? = False
					If _lastSurf = surf And Not shaderSwitch
						skip_sprite_state = True
					Else
						_lastSurf = surf
					Endif

					If Not skip_sprite_state Then 
					
						SetPerObjRenderStates(ent, surf)
						SetPerObjConstants()
						
					End 

					SetTextures(surf, ent, skip_sprite_state)
				End 
				
				shader.Update()
				shader.Apply()

				Local d3d11Mesh:D3D11Mesh
				If mesh.anim
					d3d11Mesh = D3D11.MeshMap.Get(mesh.anim_surf[surf.surf_id].vbo_id[0])
				Else
					d3d11Mesh = D3D11.MeshMap.Get(surf.vbo_id[0])
				End

				' bind mesh
				If _lastMesh <>  d3d11Mesh Then 
					_lastMesh = d3d11Mesh
					d3d11Mesh.Bind()
				End 
				
				d3d11Mesh.Render()				
				
			End 
		End 
	End 
	
	Method CompareBrushes()
	
			If _tex_count <>_tex_count2 Then Return False
			If _red<>_red2 Then Return False
			If _green<>_green2 Then Return False
			If _blue<>_blue2 Then Return False
			If _alpha<>_alpha2 Then Return False
			If _shine<>_shine2 Then Return False
			If _blend<>_blend2 Then Return False
			If _fx<>_fx2 Then Return False
			
			For Local i=0 until _tex_count
				If _textures[i]<>_textures2[i] Then Return False
			Next
	
	
		Return True
	
	End 
	
	Method SetTextures(surf:TSurface, ent:TEntity, skip_sprite_state?)
	
		Local tex_count:Int =ent.brush.no_texs
		If surf.brush.no_texs>tex_count Then tex_count=surf.brush.no_texs
			
		If _shaderTexture Then 
		
			If tex_count = 0 Then 
				
				'' clear samplers 
				_deviceContext.PSSetSamplers(0,0,[])
				_deviceContext.PSSetShaderResources(0,0,[])
				
				'' disable textures in shader
				_shaderTexture.TexturesEnabled(False)
					
			Else
	
				Local updateTextures? = False
				
				For Local ix=0 To tex_count-1			
					
					Local texture:TTexture,tex_flags,tex_blend,tex_coords,tex_u_scale#,tex_v_scale#
					Local tex_u_pos#,tex_v_pos#,tex_ang#,tex_cube_mode,frame, tex_smooth
					
					If surf.brush.tex[ix]<>Null Or ent.brush.tex[ix]<>Null
		
						' Main brush texture takes precedent over surface brush texture
						If ent.brush.tex[ix]<>Null
							texture=ent.brush.tex[ix]
							tex_flags=ent.brush.tex[ix].flags
							tex_blend=ent.brush.tex[ix].blend
							tex_coords=ent.brush.tex[ix].coords
							tex_u_scale=ent.brush.tex[ix].u_scale
							tex_v_scale=ent.brush.tex[ix].v_scale
							tex_u_pos=ent.brush.tex[ix].u_pos
							tex_v_pos=ent.brush.tex[ix].v_pos
							tex_ang=ent.brush.tex[ix].angle
							tex_cube_mode=ent.brush.tex[ix].cube_mode
							frame=ent.brush.tex[ix].tex_frame
							tex_smooth = ent.brush.tex[ix].tex_smooth	
		
						Else
							texture=surf.brush.tex[ix]
							tex_flags=surf.brush.tex[ix].flags
							tex_blend=surf.brush.tex[ix].blend
							tex_coords=surf.brush.tex[ix].coords
							tex_u_scale=surf.brush.tex[ix].u_scale
							tex_v_scale=surf.brush.tex[ix].v_scale
							tex_u_pos=surf.brush.tex[ix].u_pos
							tex_v_pos=surf.brush.tex[ix].v_pos
							tex_ang=surf.brush.tex[ix].angle
							tex_cube_mode=surf.brush.tex[ix].cube_mode
							frame=surf.brush.tex[ix].tex_frame
							tex_smooth = surf.brush.tex[ix].tex_smooth		
						Endif
		
										 
						Local d3d11Tex:= D3D11.TextureMap.Get(texture.gltex[0])
						
						If _d3d11Textures[ix]<> d3d11Tex._resourceView Then 
							updateTextures = True 
							_d3d11Textures[ix] = d3d11Tex._resourceView
						End 

						''assuming sprites with same surfaces are identical, preserve states---------
						If Not skip_sprite_state
						
							' filter
							Local filter:UVSamplerState 
							If tex_smooth
								filter = _st_uvSmooth
							Else
								filter = _st_uvNormal
							Endif
							
							Local state:D3D11SamplerState
							If tex_flags&16 And tex_flags&32 Then ' clamp u clamp v flag
								_sampleStates[ix] = filter._cU_cV
							Elseif tex_flags&16 'clamp u flag
								_sampleStates[ix] = filter._cU_wV
							Elseif tex_flags&32 'clamp v flag
								_sampleStates[ix] = filter._wU_cV
							Elseif tex_count>0 
								_sampleStates[ix] = filter._wU_wV ''only use wrap with power-of-two textures 							
							End

						Endif ''end preserve skip_sprite_state-------------------------------
		
						_shaderTexture.TextureBlend(ix, tex_blend)
						_shaderTexture.TextureTransform(ix, tex_u_pos,tex_v_pos, tex_u_scale, tex_v_scale , Cos(tex_ang),tex_coords)
		
					Endif ''end if tex[ix]
				
				Next 'end texture loop
	
				_shaderTexture.TexturesEnabled(True)
				_shaderTexture.TextureCount(tex_count)
				
				If Not skip_sprite_state Then 
					_deviceContext.PSSetSamplers(0,tex_count, _sampleStates)
				End 
				
				If updateTextures Then 
					_deviceContext.PSSetShaderResources(0,tex_count, _d3d11Textures)
				End 
				
			End 
		End 
		
	End 
	
	Method FreeVBO(surf:TSurface)
		D3D11Mesh.RemoveMesh(surf)
	End 
	 
	Method BindTexture:TTexture(tex:TTexture,flags:Int)
	
		' if mask flag is true, mask pixmap
		If flags&4
			tex.pixmap.MaskPixmap(0,0,0)
		Endif

		' size
		Local width:Int =tex.pixmap.width
		Local height:Int =tex.pixmap.height
		If width <1 Or height <1 Then Return tex
		If width > _caps.MaxTextureSize Or height > _caps.MaxTextureSize Then 
			Error "Exceeded Maximum texture size of "+ _caps.MaxTextureSize + ": " + tex.file
		End 
		
		' mipmap
		Local mipmap:Int= 0, mip_level:Int=0
		If flags&8 Then mipmap=1
		If Not( IsPowerOfTwo(width) Or IsPowerOfTwo(height) ) Then 
			mipmap=0' no mipmap
			tex.flags |= (16|32) 'clamp u,v
		End 

		Local pix:= D3D11Pixmap(tex.pixmap)
		Local d3dTex:= D3D11.CreateD3D11Texture(tex, Bool(mipmap))
		
		' generate mipmaps
		Repeat

			d3dTex.SetData(mip_level,pix)
			
			If Not mipmap Or (width=1 And height =1) Then Exit
			If width>1 width *= 0.5
			If height>1 height *= 0.5
			
			If tex.resize_smooth Then 
				pix=D3D11Pixmap(pix.ResizePixmap(width,height) )
			Else 
				pix=D3D11Pixmap(pix.ResizePixmapNoSmooth(width,height) )
			End
			mip_level+=1
			
		Forever
		
		tex.no_mipmaps=mip_level
		
		Return tex		 
	End
	            

	Method DeleteTexture(glid:Int[]) 
		D3D11.FreeD3D11Texture(glid[0])
	End 
	
	Method UpdateLight(cam:TCamera, light:TLight) 
		_lights.AddLast(light)
	End 
	
	Method DisableLight(light:TLight) '' is this used somewhere??
		Error "D3D11Render -> DisableLight not implemented..."
	End
		
	Method UpdateCamera(cam:TCamera) 

		'' set the viewport
		Local viewport:= New D3D11_VIEWPORT
			viewport.Width = cam.vwidth
			viewport.Height = cam.vheight
			viewport.MinDepth = 0
			viewport.MaxDepth = 1
			viewport.TopLeftX = cam.vx
			viewport.TopLeftY = cam.vy
	
		'' *** TODO ***
		'' _deviceContext.RSSetViewports([viewport])
		
		_deviceContext.OMSetRenderTargets([_backBufferView], _depthStencilView);
	
		'' Clear depth stencil buffers
		If cam.cls_zbuffer Then 

			_deviceContext.ClearDepthStancilView(_depthStencilView,D3D11_CLEAR_DEPTH, 1.0, 0)

		End 
		
		'' clear backbuffer
		If cam.cls_color Then
		 
			_deviceContext.ClearRenderTargetView(_backBufferView,cam.cls_r,cam.cls_g, cam.cls_b)
			
		End
		 
		'' store settings 		
		_cam = cam
		If cam.draw2D
			_fogEnabled = False
			_lightEnabled = False
			If _shaderColor Then 
				_shaderColor.AmbientColor(1,1,1)
			End 
		Else
			_fogEnabled = cam.fog_mode>0
			_lightEnabled = true
		End
		
	End 

	Method CreateShader:TShader(vs_file$, ps_file$)
		Return New D3D11Shader(_deviceContext, vs_file, ps_file )
	End 

Private 

	''
	'' internal
	''

	Method UpdateBuffers(surf:TSurface, mesh:TMesh)
		
		Local vbo:Int=True
		
		' update surf vbo if necessary
		If vbo
			
			' update vbo
			If surf.reset_vbo<>0
				UpdateVBO(surf)
			Else If surf.vbo_id[0]=0 ' no vbo - unknown reason
				surf.reset_vbo=-1
				UpdateVBO(surf)
			Endif
			
		Endif
		
		If mesh.anim
	
			' get anim_surf
			Local anim_surf2:= mesh.anim_surf[surf.surf_id] 
			
			If vbo And anim_surf2
			
				' update vbo
				If anim_surf2.reset_vbo<>0
					UpdateVBO(anim_surf2)
				Else If anim_surf2.vbo_id[0]=0 ' no vbo - unknown reason
					anim_surf2.reset_vbo=-1
					UpdateVBO(anim_surf2)
				Endif
			
			Endif
			
		Endif
	End
	
	Method IsPowerOfTwo?(x)
	    Return (x <> 0) And ((x & (x - 1)) = 0)
	End
	
	Method SetPerObjRenderStates(ent:TEntity, surf:TSurface)
	
		' fx flag 16 - disable backface culling
		If _fx&16 Then 
			_deviceContext.RSSetState(_rasterizerStates[0] ) 
		Else 
			_deviceContext.RSSetState( _rasterizerStates[2] )
		End 
		
		''global wireframe rendering
		If TRender.render.wireframe
			_deviceContext.RSSetState( _rasterizerWire )
		Endif

		'' fx flag 32 - force alpha
		If _fx&32
			surf.alpha_enable=True
		Endif
		
		' take into account auto fade alpha
		_alpha=_alpha-ent.fade_alpha

		
		' if surface contains alpha info, enable blending
		''and  fx flag 64 - disable depth testing
		If _fx&64 Or _cam.draw2D
		
			_deviceContext.OMSetDepthStencilState(_depthStencilNoDepth,0)
			
		Elseif (ent.alpha_order<>0.0 Or surf.alpha_enable=True)
		
			_deviceContext.OMSetDepthStencilState(_depthStencilNoWrite,0)
			
		Else
		
			_deviceContext.OMSetDepthStencilState(_depthStencilDefault,0)
			
		Endif	
		
		' blend mode
		_deviceContext.OMSetBlendState(_blendStates[_blend])', [], 0 )
					
	End 
	
	Method SetPerObjConstants()
		
		'' shader lighting interface
		If _shaderLights Then 
			If Not _lightEnabled Or _fx&1 Then 
				_shaderLights.LightingEnabled(False)
				_lightIsEnabled = False
			Else
				_shaderLights.LightingEnabled(True)
				_lightIsEnabled = true
			End 
		End 
				
		'' shader color interface
		If _shaderColor Then 
		
			' fx flag 2 - vertexcolor 
			If _fx&2
				_shaderColor.VertexColorEnabled(True)
			Else
				_shaderColor.VertexColorEnabled(False)
				_shaderColor.DiffuseColor(_red, _green, _blue, _alpha)
			Endif

			' fx flag 1 - full bright 
			If Not _cam.draw2D Then 
				If _fx&1 
					_shaderColor.AmbientColor(1,1,1)
				Else
					_shaderColor.AmbientColor(TLight.ambient_red ,TLight.ambient_green,TLight.ambient_blue )
				Endif
			Endif
			
			_shaderColor.Shine(_shine)
			
		End 
		
		'' shader fog interface
		If _shaderFog Then 
		
			' fx flag 8 - disable fog
			If  Not _fogEnabled Or (_cam.fog_mode And _fx&8)
				_shaderFog.FogEnabled(False)
			Else If _cam.fog_mode
				_shaderFog.FogEnabled(True)
			Endif
		
		End 

	End 
	
	Field _fogIsEnabled? = False
	
	Method SetPerFrameConstants()
	
		If _shaderMatrices Then 
			_shaderMatrices.ViewMatrix(_cam.mod_mat)	
			_shaderMatrices.ProjectionMatrix(_cam.proj_mat)
		End 
		
		If _shaderFog Then 
			_shaderFog.FogEnabled(_cam.fog_mode>0)
			_shaderFog.FogRange(_cam.fog_range_near, _cam.fog_range_far)
			_shaderFog.FogColor( _cam.fog_r,_cam.fog_g,_cam.fog_b)
		End 
		
		If _shaderLights Then 

			_shaderLights.ClearLights()

			For Local light:= Eachin _lights
				_shaderLights.AddLight(light)
			End 
		End 
		
	End
	
	'' Switches the used shader and 
	'' initializes the constants of the new shader, if necessary.
	Method UpdateShader?(shader:TShader)
	
		If shader <> _shader Then 
			
			_shader 		= D3D11Shader(shader)
			_shaderFog 		= IShaderFog(_shader)
			_shaderColor 	= IShaderColor(_shader)
			_shaderTexture 	= IShaderTexture(_shader)
			_shaderLights 	= IShaderLights(_shader)
			_shaderMatrices = IShaderMatrices(_shader)
			
			' init constants if necessary
			If _shader Then 
			
				_shader.Bind()
			
				If Not _initializedShader.Contains(shader.shader_id) Then 
			
					_initializedShader.Set(shader.shader_id,shader)
					
					SetPerFrameConstants()

				End 
				
			End 

			Return True 
		End 
		
		Return False
	End
	
	Method UpdateVBO:Int(surf:TSurface)

		If surf.reset_vbo = - 1 Then surf.reset_vbo = 255
		
		Local mesh:= D3D11.CreateD3D11Mesh(surf)
		
		If surf.reset_vbo&1 or surf.reset_vbo&2 or surf.reset_vbo&4 or surf.reset_vbo&8
			mesh.SetVertices(surf.vert_data.buf, surf.no_verts,surf.vert_data.buf.Length )
		Endif

		If surf.reset_vbo&16
			mesh.SetIndices(surf.tris.buf , surf.no_tris*3,surf.tris.buf.Length)
		Endif

		surf.reset_vbo=0
		
	End
	
	Method CombineBrushes(brushA:TBrush,brushB:TBrush )

		' get main brush values
		_red   = brushA.red
		_green = brushA.green
		_blue  = brushA.blue
		_alpha = brushA.alpha
		_shine = brushA.shine
		_blend = brushA.blend 'entity blending, not multi-texture
		_fx    = brushA.fx

		' combine surface brush values with main brush values
		If brushB

			Local shine2#=0.0

			_red   = _red   * brushB.red
			_green = _green * brushB.green
			_blue  = _blue  * brushB.blue
			_alpha = _alpha * brushB.alpha
			shine2 = brushB.shine
			If _shine=0.0 Then _shine=shine2
			If _shine<>0.0 And shine2<>0.0 Then _shine=_shine*shine2
			If _blend=0 Then _blend=brushB.blend ' overwrite master brush if master brush blend=0
			_fx=_fx|brushB.fx

		Endif

		' get textures
		_tex_count=brushA.no_texs
		If brushB.no_texs>_tex_count Then 
			_tex_count=brushB.no_texs
		End 

		If _tex_count > 0' todo
			If brushA.tex[0]<>Null
				_textures 	= brushA.tex
			Else
				_textures	= brushB.tex	
			Endif
		Else
			_tex_flags = 0
			_textures = []
		End 

	End

End 

Class UVSamplerState

	Field _cU_cV:D3D11SamplerState
	Field _wU_cV:D3D11SamplerState
	Field _cU_wV:D3D11SamplerState
	Field _wU_wV:D3D11SamplerState	

	Method New(filter:Int,bias#)
	
		_cU_cV = D3D11.CreateD3D11SamplerState( filter, D3D11_TEXTURE_ADDRESS_CLAMP ,D3D11_TEXTURE_ADDRESS_CLAMP,D3D11_TEXTURE_ADDRESS_CLAMP,bias)
		_wU_wV = D3D11.CreateD3D11SamplerState( filter, D3D11_TEXTURE_ADDRESS_WRAP ,D3D11_TEXTURE_ADDRESS_WRAP,D3D11_TEXTURE_ADDRESS_CLAMP,bias)
		_wU_cV = D3D11.CreateD3D11SamplerState( filter, D3D11_TEXTURE_ADDRESS_WRAP ,D3D11_TEXTURE_ADDRESS_CLAMP,D3D11_TEXTURE_ADDRESS_CLAMP,bias)
		_cU_wV = D3D11.CreateD3D11SamplerState( filter, D3D11_TEXTURE_ADDRESS_CLAMP ,D3D11_TEXTURE_ADDRESS_WRAP,D3D11_TEXTURE_ADDRESS_CLAMP,bias)
		
	End
	
End

Class D3DHardwareCaps

	Field MaxTextureSize:Int
	Field MaxCubeMap:Int 
	Field Instancing:Bool 
	Field MultipleRenderTargets:Int
	Field PixelShdaderVersion:String 
	Field VertexShaderVersion:String 
	
	Method New(featureLevel)
		Select featureLevel
			Case D3D_FEATURE_LEVEL_9_1,D3D_FEATURE_LEVEL_9_2
				MaxTextureSize = 2048
				MaxCubeMap = 512
				MultipleRenderTargets = 1
				
			Case D3D_FEATURE_LEVEL_9_3
				MaxTextureSize = 4096
				MaxCubeMap = 4096
				MultipleRenderTargets = 4
			Case D3D_FEATURE_LEVEL_10_0, D3D_FEATURE_LEVEL_10_1
				MaxTextureSize = 8192
				MaxCubeMap = 8192
				MultipleRenderTargets = 8
			Case D3D_FEATURE_LEVEL_11_0,D3D_FEATURE_LEVEL_11_1
				MaxTextureSize = 16384
				MaxCubeMap = 16384
				MultipleRenderTargets = 8
		End
	End 
End 