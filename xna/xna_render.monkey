' XNA miniB3D target Author: Sascha Schmidt

Import mojo
Import mojo.graphicsdevice
Import xna 
Import xna_pixmap
Import minib3d.trender
Import minib3d


#rem

minib3d fix:
- fixed null reference in Quaternion.RotateVector

Notes:
------------------------------------------------------------------------------------------------------------------------
Hardare caps		-	http://msdn.microsoft.com/en-us/library/ff604995.aspx

vbos - xna must use vbo, as data is loaded in via byte buffer (yes, in xna)
lights - no point or spotlight or multiple light without HLSL

-- make sure to clear states before returning to mojo

-- per dx11 and xna 4.0, scissor has no effect on clearscreen

#end 


#XNA_PERPIXEL_LIGHNING=True


Extern
	Function MojoClear:Void() = "GraphicsDevice g = BBXnaGame.XnaGame().GetXNAGame().GraphicsDevice; g.Clear(new Color(0,0,0,0));//"
	
	Class MojoHack Extends GraphicsDevice = "gxtkGraphics"
		'Field _renderTarget:Object = "renderTarget"
		Method Flush:Void() = "Flush"
	End
	
Public

Interface IRender
	Method GetVersion:Float() 
	Method Reset:Void()  
	Method Finish:Void()  
	Method GraphicsInit:Int(flags:Int=0)  
	Method Render:Void(ent:TEntity, cam:TCamera = Null)  
	Method ClearErrors:Int() 
	Method BindTexture:TTexture(tex:TTexture,flags:Int) 
	Method DeleteTexture(glid:Int[]) 
	Method UpdateLight(cam:TCamera, light:TLight) 
	Method DisableLight(light:TLight) 
	Method UpdateCamera(cam:TCamera) 
End

Interface ITextureDriver
	Method Load(file?)
	Method Create(width, height, flags)
	Method Create(buffer:DataBuffer, flags)
	Method Free()
	Method Width()
	Method Height()
End

Interface ISurfaceDriver			
End


Class XNATextureDriver
End

Class XNASurfaceDriver
End


Function SetRender(flags:Int=0)
	
	TRender.render = New XNARender
	TRender.render.GraphicsInit(flags)
	SetMojoEmulation()
	
End



Function RestoreMojo2D()

	XNARender(TRender.render).RestoreMojo()
	
End


Class XNARender Extends TRender
	
Private

	Field _device				:XNAGraphicsDevice 
	Field _xna					:XNAController
	
	Field UP_VECTOR			:= New Vector(0,-1,0) 
	Field LIGHT_QUAD			:= New Quaternion()
	
	Global _textures:= New IntMap<XNATexture> ' Todo Resourcemanager
	Global _depthEnable:Bool = True
	
	Field _meshes:= New IntMap<XNAMesh>
	Field _lights:TLight[3]
	Field _last_texture:TTexture
	
	Field _alpha_list:= New List<TSurface> 
	Field _mesh_id%, _texture_id%, _light_no%
	
	Global _mojoClear:Int=0

Public 

		
	Method New()
		_device 	= New XNAGraphicsDevice 
		_xna		= New XNAController(_device)
	End
	
	Method ClearErrors:Int()
	End
	
	''should return shader model
	Method GetVersion:Float()
		Return GetShaderVersion()
	End

	Method ContextReady:Bool()

		If _device And _xna Then Return True
		Return False
		
	End

	Method GraphicsInit(flags:Int=0)
		
		''need to set tpixmap class
		TPixmapXNA.Init()
		
		Reset()
		
		TLight.max_lights = 3
		width = DeviceWidth
		height = DeviceHeight 
		vbo_enabled = True
		 
	End
	
	Method Reset:Void()
		
		''clear mojo state
		_xna._device.SetRenderTarget(Null)
		
		_xna._device.DepthStencilState = _xna._depthStencilDepth
		_xna._device.RasterizerState = _xna._rasterizerStates[2] ''culling
		_xna._device.BlendState = _xna._blendStates[0]
		
		TRender.alpha_pass = 0
		_xna.Reset()

	
	End
	
	'' experimental
	''
	Method RestoreMojo:Void()

		MojoHack(GetGraphicsDevice()).Flush()
		
		GetGraphicsDevice().BeginRender()

		MojoClear()
		
		'_xna._device.SetRenderTarget(Null)
		_xna._device.DepthStencilState = _xna._depthStencilNoDepth
		_xna._device.RasterizerState = _xna._rasterizerStates[0]
		_xna._device.BlendState = _xna._blendStates[0]
		
		'MojoHack(GetGraphicsDevice())._renderTarget=Null
		
	End
	
	
	
	Method Render:Void(ent:TEntity, cam:TCamera = Null)

		Local mesh:TMesh = TMesh(ent)
		If Not mesh Then Return

		'' draw surfaces with alpha last
		Local temp_list:List<TSurface> = mesh.surf_list
		_alpha_list.Clear()
	
		'' update camera, effects
		'' this must go first
		'_xna.UpdateEffect(ent, cam)
		
		If TSprite(ent)
			_xna.world_mat = (TSprite(ent).mat_sp.ToArray())
		Else
			_xna.world_mat = ent.mat.ToArray()
		Endif
					
	
		''run through surfaces twice, sort alpha surfaces for second pass
		For Local alphaloop:= alpha_pass To 1 ''if alpha_pass is on, no need to reorder alpha surfs
							
			For Local surf:TSurface =Eachin temp_list

				''draw alpha surfaces last in second loop
				''also catch surfaces with no vertex
				If surf.no_verts=0 Then Continue
				If (surf.alpha_enable And alphaloop < 1)
					_alpha_list.AddLast(surf)				
					Continue
				Endif
				
				' Update vertex & index buffers
				UpdateBuffers(surf, mesh)
				
				'' get current state flags from unified state machine
				_xna.UpdateEffectState( surf, ent, cam )
				
				' RasterizerState / DepthStencilState / BlendState
				_xna.UpdateTexture(ent, surf, cam)
				_xna.SetStates(ent, surf, cam)
					
				' set textures / blending / shading / culling / draw2D		
				_xna.UpdateEffect(ent, surf, cam)
				
''debugging
'Print mesh.classname		
'Print "effect: "+_xna.CurrentEffect()._name+"  2d:"+cam.draw2D+"  alphapass:"+alpha_pass
'Print "cam: "+cam.name
			
				Local passes:= _xna.CurrentEffect.Effect.CurrentTechnique.Passes
				For Local pass:= Eachin passes
				
					pass.Apply()
	
	
					' draw tris
					If mesh.anim
						
						Local meshx:= _meshes.Get(mesh.anim_surf[surf.surf_id].vbo_id[0])
						If Not meshx Then surf.vbo_id[0]=0; Continue
						meshx.Bind()
						meshx.Render()
					
					Else
		
						Local meshx:= _meshes.Get(surf.vbo_id[0])
						If Not meshx Then surf.vbo_id[0]=0; Continue
						meshx.Bind()
						meshx.Render()
					Endif 

			 	Next ' effect passes
		
				If Not _alpha_list Then Exit ''get out of loop, no alpha
				temp_list = _alpha_list
			
			
			
			Next '' surfaces
			
		Next	''end alpha loop
		
		
			
		temp_list = Null
		
		'' clear some states as we return to mojo, or else we'll get the clamp error
		_xna.ClearStates()
		
	End

	Method Finish:Void()
	

	End
	
	Method EnableStates:Void()
	End 

	Method UpdateVBO:Int(surf:TSurface)

		Local m:XNAMesh = Null
		
		If surf.vbo_id[0]=0
			_mesh_id+=1
			 surf.vbo_id[0] = _mesh_id
			m = _device.CreateMesh()
			_meshes.Set(_mesh_id,m)
		Endif
		
		If Not m Then 
			m = _meshes.Get (surf.vbo_id[0])
		End

		If surf.reset_vbo=-1 Then surf.reset_vbo=255
		
		''update mesh positions
		If surf.reset_vbo&1
			If surf.vert_anim
				'' vertex animation
				m.SetVerticesPosition(surf.vert_anim[surf.anim_frame].buf, surf.no_verts, 2)
			Else
				m.SetVerticesPosition(surf.vert_data.buf, surf.no_verts, surf.vbo_dyn)
			Endif
		Endif
		
		''update rest of vertex info
		If surf.reset_vbo&2 Or surf.reset_vbo&4 Or surf.reset_vbo&8
			m.SetVertices(surf.vert_data.buf, surf.no_verts, surf.vbo_dyn)
		Endif

		If surf.reset_vbo&16
			m.SetIndices(surf.tris.buf , surf.no_tris*3, surf.vbo_dyn)
		Endif

		surf.reset_vbo=False
	End
	
	Method FreeVBO(surf:TSurface)
		If surf.vbo_id[0]<>0 
			Local m := _meshes.Get(surf.vbo_id[0])
			m.Clear()
		Endif
	End 

	Method DeleteTexture(tex:TTexture)
		If _textures.Contains (tex.gltex[0]) Then 
			_textures.Remove(tex.gltex[0])
		End 
	End
	
	' Caution
	' Here is a tip for rendering objects within the Draw method of an Xbox 360 game. 
	' Do not use SetData when writing data to vertex buffers, index buffers, and textures: http://msdn.microsoft.com/en-us/library/bb198834
	Method BindTexture:TTexture(tex:TTexture,flags:Int)
	
		' if mask flag is true, mask pixmap ''**wrong, this is alpha-testing
		If flags&4
			'tex.pixmap.MaskPixmap(0,0,0)
		Endif

		' pixmap -> tex

		Local width:Int =tex.pixmap.width
		Local height:Int =tex.pixmap.height
		
		If width <1 Or height <1 Then Return tex
		
		' TODO: Check max cubemap texture size
		
		If width > 2048 Or height > 2048 Then 
			Error "Exceeded Maximum texture size of 2048: " + tex.file
		End 
		
		Local mipmap:Int= 0, mip_level:Int=0
		
		If flags&8 Then mipmap=1
		
		If Not( IsPowerOfTwo(width) Or IsPowerOfTwo(height) ) Then 
			mipmap=0
			' TODO: no wrap addressing mode and no DXT compression on nonpower of two textures.
			tex.flags |= (16|32) 'clamp u,v
		End 
		
		If tex.gltex[0] And tex.pixmap.bind Then Return tex
		
		If tex.gltex[0] = 0 Then 
			_texture_id+=1
			tex.gltex[0] = _texture_id
		End 
			
		Local t:= _device.CreateTexture(width, height, Bool(mipmap), -1 )
		
		If t Then
		
			_textures.Set( tex.gltex[0], t ) 
			If _texture_id >= _xna._texturedata.Length() Then _xna._texturedata = _xna._texturedata.Resize(_texture_id+5)
			_xna._texturedata[_texture_id] = New XNATextureData
			
		End 
		
		Local pix:TPixmapXNA = TPixmapXNA(tex.pixmap)
		
		Repeat

			t.SetData(mip_level, pix.pixels, 0, pix.pixels.Length)
			
			If Not mipmap Or (width=1 And height =1) Then Exit
			If width>1 width *= 0.5
			If height>1 height *= 0.5

			If tex.resize_smooth Then 
				pix=TPixmapXNA(pix.ResizePixmap(width,height) )
			Else 
				pix=TPixmapXNA(pix.ResizePixmapNoSmooth(width,height) )
			End
			mip_level+=1
			
		Forever
			
		tex.no_mipmaps=mip_level
		tex.pixmap.SetBind()
		
		Return tex		
		
	End
	
	Method DisableLight(light:TLight)
		For Local i = 0 Until 3
			If _lights[i] = light Then 
				_xna.SetLightEnable(i,False)
			End
		Next
	End
	
	Method UpdateLight(cam:TCamera,light:TLight)
		
		_light_no=_light_no+1
		If _light_no>light.no_lights Then _light_no=0
		_lights[_light_no] = light
		
		If light.Hidden()
			_xna.SetLightEnable(_light_no,False)
		Else
			_xna.SetLightEnable(_light_no,True)
			
			'Local dir:= LIGHT_QUAD.MatrixToQuat(light.mat).RotateVector(UP_VECTOR)'wtf
			Local dir:= New Vector(-light.mat.grid[2][0],-light.mat.grid[2][1],-light.mat.grid[2][2])
			dir = dir.Normalize()
			
			_xna.SetLight(_light_no,dir.x, dir.y, dir.z,light.red,light.green,light.blue)
			
		Endif
	End

	Method UpdateCamera(cam:TCamera)
		
		'If Not cam Or _xna Then Return

		' viewport does nothing in XNA
		'_device.Viewport(cam.vx,-(cam.vy-render.height+cam.vheight),cam.vwidth,cam.vheight)
		_device.Viewport(cam.viewport[0],TRender.height-cam.viewport[3]-cam.viewport[1],cam.viewport[2],cam.viewport[3])

		'' y is opposite corner from opengl
		_device.ScissorRectangle(cam.viewport[0],TRender.height-cam.viewport[3]-cam.viewport[1],cam.viewport[2],cam.viewport[3])
		
		' clear buffers
		' per dx11 and xna 4.0, scissor has no effect on clearscreen
		If cam.cls_color=True
			'_device.ClearScreen(cam.cls_r,cam.cls_g,cam.cls_b, cam.cls_color, cam.cls_zbuffer, False )
			DrawClearQuad(cam,cam.cls_r,cam.cls_g,cam.cls_b)
		Endif
		
		If cam.cls_zbuffer=True
			_device.ClearScreen(cam.cls_r,cam.cls_g,cam.cls_b, false, cam.cls_zbuffer, False )
		Endif
			
		_xna.proj_mat = cam.proj_mat.ToArray()
		_xna.view_mat = cam.mod_mat.ToArray()
		
	End
	
	Method ResetBrush()
		_xna.CurrentEffect().Reset()
	End
	
	Method BackBufferToTex(mipmap_no=0,frame=0)
	End 
	
	'################################################################################
	
Private 

	Global fastQuad:TMesh

	Method DrawClearQuad:Void(cam:TCamera,r:float,g:float,b:float)

		If fastQuad = Null
			fastQuad = CreateSprite()
			fastQuad.RemoveFromRenderList
			fastQuad.ScaleEntity(render.width,render.height,1.0)
			fastQuad.PositionEntity(0,0,1.99999)
			fastQuad.EntityFX(1+8+32+64)
			'fastQuad.alpha_order=1.0
			fastQuad.classname="fastQuad"
			'camera2D.SetPixelCamera
			IRenderUpdate(fastQuad).Update(camera2D)
		Endif
		
		''set the xna array
		_xna.proj_mat = camera2D.proj_mat.ToArray()
		_xna.view_mat = camera2D.mod_mat.ToArray()
		
		'TRender.render.Reset()
		_xna._device.DepthStencilState = _xna._depthStencilNoDepth
		_xna._device.RasterizerState = _xna._rasterizerStates[2] ''culling
		_xna._device.BlendState = _xna._blendStates[4]
		_xna.Reset()
		'SetShader2D()
		
		fastQuad.EntityColorFloat(r,g,b)
		
		alpha_pass=1
		Local wireframeIsEnabled:Int = wireframe
		wireframe = False
	
		'driver.SetColorMask(True,True,True,False)
		self.Render(fastQuad,camera2D)
		'driver.SetColorMask(True,True,True,True)
		wireframe = wireframeIsEnabled
		
		TRender.render.Finish()
		TRender.render.Reset()
		'cam.Update(cam)
	End
	
	
	Method IsPowerOfTwo?(x)
	    Return (x <> 0) And ((x & (x - 1)) = 0)
	End
	
	
	Method UpdateBuffers(surf:TSurface, mesh:TMesh)
		
		Local vbo:Int=False
		If vbo_enabled
			vbo=True
		Else
			' if surf no longer has required no of tris then free vbo
			If surf.vbo_id[0]<>0 
				FreeVBO(surf)
			Endif
		Endif

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

	
End







' First of all for managing different XNAEffects
' e.g. switching between XNABasicEffect, XNAEnvironmentMapEffect
' also manage state switching
Class XNAController

Private 
	
	Global _texturedata:= New XNATextureData[2] ''use texture.gltex[] index
	
	' the device
	Field _device:XNAGraphicsDevice 
	
	' states
	Field _rasterizerStates		:XNARasterizerState[6]
	Field _rasterizerWire		:XNARasterizerState
	Field _rasterizerScissor		:XNARasterizerState
	Field _depthStencil			:XNADepthStencilState
	Field _depthStencilDefault	:XNADepthStencilState
	Field _depthStencilNone		:XNADepthStencilState
	Field _depthStencilNoWrite	:XNADepthStencilState
	Field _depthStencilNoDepth	:XNADepthStencilState
	Field _depthStencilDepth	:XNADepthStencilState
	
	Field _blendStates			:XNABlendState[] 
	Field _lastSamplerState		:XNASamplerState 	
	Field _st_uvNormal 			:UVSamplerState
	Field _st_uvSmooth			:UVSamplerState
	
	' effects
	Field _lastEffect				:EffectContainer
	Field _basicEffect			:BasicEffect
	Field _enviromentEffect		:BasicEffect
	Field _draw2DEffect			:Draw2DEffect
	Field _alphaTestEffect		:AlphaTestEffect
	
	Field _lastTexture			:TTexture
	
	Field light_info:Float[8*8] ''to store light info before CurrentEffect is ready
	
	' last combined brush values
	Field _tex_count%, _red#,_green#,_blue#,_alpha#,_shine#,_blend%,_fx%, _tex_flags%, textures:TTexture[]

	Field _last_state:EffectState = New EffectState
	
Public 

	Field proj_mat:Float[]
	Field view_mat:Float[]
	Field world_mat:Float[]
	
	Field _state:EffectState = New EffectState


	Method New(device:XNAGraphicsDevice)
		_device = device
		
		' effects
		_basicEffect = New BasicEffect(device.CreateBasicEffect())
		_enviromentEffect = New BasicEffect(device.CreateBasicEffect())
		_draw2DEffect = New Draw2DEffect(device.CreateBasicEffect())
		_alphaTestEffect = New AlphaTestEffect(device.CreateAlphaTestEffect())
		
		_lastEffect = _basicEffect
		
		' states
		'_rasterizerStates 	= [XNARasterizerState.CullNone, XNARasterizerState.CullCounterClockwise,XNARasterizerState.CullClockwise ]
		
		_rasterizerWire 	= XNARasterizerState.Create()
		_rasterizerWire.CullMode = CullMode_None
		_rasterizerWire.FillMode = FillMode_WireFrame
		_rasterizerWire.ScissorTestEnable = True
		
		'_rasterizerScissor = XNARasterizerState.Create()
		_rasterizerStates[0] = XNARasterizerState.Create()
		_rasterizerStates[0].CullMode = CullMode_None
		_rasterizerStates[0].ScissorTestEnable = True
		_rasterizerStates[1] = XNARasterizerState.Create()
		_rasterizerStates[1].CullMode = CullMode_CullCounterClockwiseFace
		_rasterizerStates[1].ScissorTestEnable = True
		_rasterizerStates[2] = XNARasterizerState.Create()
		_rasterizerStates[2].CullMode = CullMode_CullClockwiseFace
		_rasterizerStates[2].ScissorTestEnable = True
		

		_depthStencilDefault = XNADepthStencilState._Default
		_depthStencilNone 	= XNADepthStencilState.None
		
		_depthStencilNoWrite	= XNADepthStencilState.Create ''may need a new state based on default
		_depthStencilNoWrite.DepthBufferEnable = True
		_depthStencilNoWrite.DepthBufferWriteEnable = False
		
		_depthStencilNoDepth	= XNADepthStencilState.Create ''is same as "none"
		_depthStencilNoDepth.DepthBufferEnable = False
		_depthStencilNoDepth.DepthBufferWriteEnable = False
		
		_depthStencilDepth	= XNADepthStencilState.Create
		_depthStencilDepth.DepthBufferEnable = True
		_depthStencilDepth.DepthBufferWriteEnable = True
		
		_blendStates 		= [XNABlendState.NonPremultiplied, XNABlendState.NonPremultiplied, MultiplyBlend(), XNABlendState.Additive, XNABlendState.Opaque]
		_st_uvNormal 		= UVSamplerState.Create( TextureFilter_Point )
		_st_uvSmooth 		= UVSamplerState.Create( TextureFilter_LinearMipPoint  )

	End

	Method Reset()
		
		ClearStates()
		
		_lastEffect = Null'_basicEffect
		_basicEffect.Reset()
		_alphaTestEffect.Reset()
		_tex_count=0
		_lastTexture = Null
		
		_last_state.SetNull() 'minib3d unified states
		
	End
	
	Method SetLightEnable(id, enable?)
		'_lastEffect.SetLightEnable(id, enable)
		light_info[id*8] = Float(Int(enable))
	End
	
	Method SetLight(id, dirX#, dirY#, dirZ#, r#, g#, b#)
		'_lastEffect.SetLight(id, dirX, dirY, dirZ, r, g, b)
		Local pos:Int=id*8
		light_info[pos+1]= dirX
		light_info[pos+2]= dirY
		light_info[pos+3]= dirZ
		light_info[pos+4]= r
		light_info[pos+5]= g
		light_info[pos+6]= b
		
    End
	
	Method CurrentEffect:Void(effect:EffectContainer) Property
		_lastEffect = effect
	End
	
	Method CurrentEffect:EffectContainer() Property
		Return _lastEffect
	End
	
	
	Method ProjectionMatrix(mat:Float[])
		_lastEffect.Effect().ProjectionMatrix(mat)
		'proj_mat = mat
	End
	
	Method ViewMatrix(mat:Float[])
		_lastEffect.Effect().ViewMatrix(mat)
		'view_mat = mat
	End
	
	Method WorldMatrix(mat:Float[])
		_lastEffect.Effect().WorldMatrix(mat)
		'world_mat = mat
	End
	
	Method Fog(near# ,far# ,r#,g#, b#, enabled?)
		If enabled
			_lastEffect.Effect().FogEnabled = True
			_lastEffect.Effect().FogStart = near
	        _lastEffect.Effect().FogEnd = far
	        _lastEffect.Effect().FogColor(r,g,b)
		Else
			_lastEffect.Effect().FogEnabled = False 
		Endif

	End
	
	
	
	Method SetStates(ent:TEntity, surf:TSurface, cam:TCamera )
		
		''for some reason, we get null textures coming through...

		Local filter:UVSamplerState, state:XNASamplerState
		
		Local tex_smooth:Bool = False, has_texture:Bool=False, i%=0

		For Local tex:TTexture = Eachin textures
			i+=1
			If tex And tex.width>0
			
				has_texture = True
				If tex.tex_smooth Then tex_smooth = True; Exit ''smooth all textures on this surface
				
				'Print tex.width+" "+tex.height
			Endif
		Next


		'' sampler states are bound and immutable afterwards, so create a separate state for all possibilities
		
		If Not tex_smooth
			filter = _st_uvNormal 'point filtering (fast, not as smooth)
		Else
			filter = _st_uvSmooth ' Linear filtering
		Endif
		 
		state = filter._cU_cV ''only use wrap with power-of-two textures
		
		If _tex_flags&16 And _tex_flags&32 Then ' clamp u clamp v flag
			state = filter._cU_cV
		Elseif _tex_flags&16 'clamp u flag
			state = filter._cU_wV
		Elseif _tex_flags&32 'clamp v flag
			state = filter._wU_cV
		Elseif _tex_count>0 And has_texture 'And (tex_flags&4)<>0			
			state = filter._wU_wV ''only use wrap with power-of-two textures 
		End
	
	
		' ' preserve sampler state
		If state <> _lastSamplerState Then 
			_device.SamplerState(0, state)
			_lastSamplerState = state
		End 
		

		If Not cam.draw2D
		
			If TRender.render.wireframe
				_device.RasterizerState = _rasterizerWire
			Else
				' fx flag 16 - disable backface culling
				If _state.use_backface_culling=0
				    _device.RasterizerState = _rasterizerStates[0] 
				Else
				    _device.RasterizerState = _rasterizerStates[2]
				Endif
			Endif
		End
 

		'' fx flag 32 - force alpha --implemented in TMesh.Alpha()
		'If _fx&32
		'	surf.alpha_enable=True
		'Endif
		
		' take into account auto fade alpha
		'_alpha=_alpha-ent.fade_alpha

		
		' if surface contains alpha info, enable blending
		''and  fx flag 64 - disable depth testing
		
		_device.DepthStencilState = _depthStencilDefault
		If _state.use_alpha_test
			'' alpha testing, use depth
			_device.DepthStencilState = _depthStencilDefault
		Elseif _state.use_depth_test=0
			_device.DepthStencilState = _depthStencilNoDepth
		Endif
		If _state.use_depth_write=0 And _state.use_depth_test=1
			_device.DepthStencilState = _depthStencilNoWrite
		Endif
		
		' blend mode
		If _state.blend>-1 Then _device.BlendState = _blendStates[_state.blend]
	
	End
	

	
	Method DisableDepth()
		_device.DepthStencilState = _depthStencilNoDepth
	End
	

	Method ClearStates()

		_device.SamplerState(0, _st_uvNormal._cU_cV )
		_lastSamplerState = _st_uvNormal._cU_cV
		_device.DepthStencilState = _depthStencilDefault
		_device.BlendState = _blendStates[0]
		_device.RasterizerState = _rasterizerStates[2]
		_tex_flags=0
		
	End
	
#rem	
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

			_red   =_red  *brushB.red
			_green =_green*brushB.green
			_blue  =_blue *brushB.blue
			_alpha =_alpha *brushB.alpha
			shine2=brushB.shine
			If _shine=0.0 Then _shine=shine2
			If _shine<>0.0 And shine2<>0.0 Then _shine=_shine*shine2
			If _blend=0 Then _blend=brushB.blend ' overwrite master brush if master brush blend=0
			_fx=_fx|brushB.fx
		
		Endif
		
		' get textures
		tex_count=brushA.no_texs
		If brushB.no_texs>tex_count Then 
			tex_count=brushB.no_texs
		End 
		
		If tex_count > 0' todo
			If brushA.tex[0]<>Null
				textures 	= brushA.tex
			Else
				textures	= brushB.tex	
			Endif
		Else
			tex_flags = 0
			textures = []
		End 
		
	End
#end	
	
	
	Method UpdateTexture( mesh:TEntity, surf:TSurface, cam:TCamera)
		''no multi-texture (we could do another pass)
		
		' get textures
		_tex_count = 0	
			
		_tex_count=mesh.brush.no_texs
		'If surf.brush<>Null
			If surf.brush.no_texs>_tex_count Then _tex_count=surf.brush.no_texs
		'EndIf
			
		If _tex_count > 0' todo
			If surf.brush.tex[0]<>Null
				textures 	= surf.brush.tex
			Else
				textures	= mesh.brush.tex	
			Endif
		Else
			_tex_flags = 0
			textures = []
		End 
		
		''if texture scale, pos, or ang changes, we need to update here since there is no texture matrix
		'Local _coordset%, _uscale#, _vscale#, _upos#, _vpos#, _angle#
		If textures.Length < 1 Or _tex_count<1 Then Return
		
		Local cur_tex:TTexture = textures[0]
		'If surf.brush.tex[0] Then cur_tex = surf.brush.tex[0]
		
		If Not cur_tex Then Return
		
		_tex_flags  = cur_tex.flags

		' preserve texture states
		If cur_tex = _lastTexture
			Return		
		Endif
		

		
		Local id:Int = cur_tex.gltex[0]
		Local set_id:Int = cur_tex.coords
		
		'If _texturedata[id].coordset<>cur_tex.coordset
			'_texturedata[id].coordset=cur_tex.coordset
		'Endif
		If (_texturedata[id].u_pos<>cur_tex.u_pos Or _texturedata[id].v_pos<>cur_tex.v_pos Or _texturedata[id].angle<>cur_tex.angle Or
				_texturedata[id].u_scale<>cur_tex.u_scale Or _texturedata[id].v_scale<>cur_tex.v_scale)
			
			If (Not _texturedata[id].orig_uv ) Then _texturedata[id].ResetUVCache(surf)
			
			_texturedata[id].u_pos=cur_tex.u_pos
			_texturedata[id].v_pos=cur_tex.v_pos
			_texturedata[id].angle=cur_tex.angle
			_texturedata[id].u_scale=cur_tex.u_scale
			_texturedata[id].v_scale=cur_tex.v_scale
			
			TransformTexCoords(surf, cur_tex.angle,cur_tex.u_pos,cur_tex.v_pos,cur_tex.u_scale,cur_tex.v_scale, _texturedata[id].orig_uv, set_id)
			
		Endif
			

		
	End
	
	
	'' make sure that the current effect is getting correct camera info
	Method UpdateEffect(ent:TEntity, surf:TSurface, cam:TCamera)

		
		''set current effect (default)
		Local e:EffectContainer = _basicEffect
		
		If cam.draw2D
			
			e= _draw2DEffect

		ElseIf _tex_flags&128<>0
		
			' if cubic environment map
			e= _enviromentEffect 
		
		Elseif _state.use_alpha_test And cam.draw2D=0
		
			e = _alphaTestEffect
			
		Endif
	
		If e <> CurrentEffect()

			CurrentEffect(e)
			e.Update(cam,ent,CurrentEffect )
			
			' set view matrix					
			ViewMatrix(view_mat)
			
			' set projection
			ProjectionMatrix(proj_mat)
	
			
			' fog
			Fog( cam.fog_range_near, cam.fog_range_far, cam.fog_r,cam.fog_g,cam.fog_b, cam.fog_mode>0)
			
		Endif
		
		'If _state.full_bright Or cam.draw2D
			'If BasicEffect(e) Then BasicEffect(e).NoLighting
		'Endif
		
		If _state.use_fog=0
			e.Fog(False)
		Else
			e.Fog(True)
		Endif
		

		''set camera matrices after effect has been set
		' entity Transform
		WorldMatrix(world_mat)
		
		''lights
		CurrentEffect.SetLight(light_info)
				
		CurrentEffect().Bind(ent, surf, _state, _tex_count, textures )	
		
	End
	
	Method UpdateEffectState( surf:TSurface, ent:TEntity, cam:TCamera )
		_state.UpdateEffect(surf,ent,cam)
	End
		
	
	Method IsPowerOfTwo?(x)
	    Return (x <> 0) And ((x & (x - 1)) = 0)
	End
	
End


''------------ update texture matrix
''
'' keeps texture data to compare to minib3d
'' if this differs, update the texcoords
Class XNATextureData

	Field coordset:Int =0
	Field u_scale# =1.0
	Field v_scale# =1.0
	Field u_pos# =0.0
	Field v_pos# =0.0
	Field angle# =0.0
	Field orig_uv:Float[] ''keeps the original uvs intact during uv rotation, scale, translation ''only allocated if used
	
	Method ResetUVCache:Void(surf:TSurface)
	
		orig_uv = New Float[surf.no_verts *2] 
		For Local i:=0 To surf.no_verts-1
			orig_uv[(i Shl 1)] = surf.VertexU(i)
			orig_uv[(i Shl 1) +1] = surf.VertexV(i)
		Next
		
	End
	
End

Function TransformTexCoords(surf:TSurface, angle#, tx#, ty#, sx#, sy#, orig_uv#[], coordset:Int=0)
	'' 0.5 = rotate in center of uv
	
	Local ca# = Cos(angle)*sx
	Local sa# = Sin(angle)*sy
	Local ox# = sx*0.5 +tx
	Local oy# = sy*0.5 +ty

	For Local i:=0 To surf.no_verts-1
		Local vx# = orig_uv[(i Shl 1)]-0.5 'surf.VertexU(i)
		Local vy# = orig_uv[(i Shl 1) +1]-0.5 'surf.VertexV(i)
		Local u# = (vx*ca-sa*vy) +ox '+ tx
		Local v# = (vx*sa+ca*vy) +oy '+ ty
		surf.VertexTexCoords(i, u,v, coordset)
	Next
	
End



Class UVSamplerState

	Field _cU_cV:XNASamplerState
	Field _wU_cV:XNASamplerState
	Field _cU_wV:XNASamplerState
	Field _wU_wV:XNASamplerState
	
	Function Create:UVSamplerState(filter:Int)
	
		Local s:UVSamplerState = New UVSamplerState
		
		s._cU_cV 		= XNASamplerState.Create( filter, TextureAddressMode_Clamp, TextureAddressMode_Clamp)
		s._wU_cV 		= XNASamplerState.Create( filter, TextureAddressMode_Wrap , TextureAddressMode_Clamp)
		s._cU_wV 		= XNASamplerState.Create( filter, TextureAddressMode_Clamp, TextureAddressMode_Wrap)
		s._wU_wV 		= XNASamplerState.Create( filter, TextureAddressMode_Wrap, TextureAddressMode_Wrap)
		
		Return s
		
	End
	
End

Function MultiplyBlend:XNABlendState()
	Local b:XNABlendState = XNABlendState.Create()
	b.ColorSourceBlend = BLEND_SourceAlpha
	b.ColorDestinationBlend = BLEND_Zero
	b.AlphaSourceBlend = BLEND_SourceAlpha
	b.AlphaDestinationBlend = BLEND_Zero
	Return b
End




Interface IEffectContainer
	Method Effect:XNAEffect() 
	Method Update(cam:TCamera, ent:TEntity, e:IEffectContainer)
	Method Bind(ent:TEntity, surf:TSurface, _state:EffectState, tex_count, textures:TTexture[] ) 
	Method Reset()
	'Method Projection(fieldOfView#, aspect#, near#, far#)
	'Method View(px#, py#, pz#, rx#, ry#, rz#, sx#, sy#, sz#) 
	'Method World(px#, py#, pz#, rx#, ry#, rz#, sx#, sy#, sz#)
	Method ProjectionMatrix:Void(mat:Float[])
	Method ViewMatrix:Void(mat:Float[])
	Method WorldMatrix:Void(mat:Float[])
	Method AlphaTestEnable:Void(value?)
	Method SetAlphaFunction:Void(value%)
	Method SetReferenceAlpha:Void(value%)
End 

Interface ILighting
	Method SetLight(id, dirX#, dirY#, dirZ#, r#, g#, b#)
	Method SetLightEnable(id, enable?)
end


Class EffectContainer Implements IEffectContainer

	Field _updateWorld? 		= True
	Field _updateView?  		= True
	Field _updateLight? 		= True
	Field _updateProjection? 	= True
	Field _effect				:XNAEffect
	Field _name					:String
	Field _disable_fog			:Bool
	Field _lastTexture			:TTexture
	
	Method Bind(ent:TEntity, surf:TSurface, _state:EffectState, tex_count, textures:TTexture[] ) Abstract
	
	Method Effect:XNAEffect() 
		Return _effect
	End
	
	Method Reset()
		_updateWorld = True
		_updateView = True
		_updateLight = True
		_updateProjection = True
		'_effect.FogEnabled = False
		_disable_fog = False
		_lastTexture = Null
	End
	
	
	Method SetLightEnable(id, enable?)
		_updateLight = False
		Select id
			Case 0
				_effect.DirectionalLight0.Enabled = enable
			Case 1
				_effect.DirectionalLight1.Enabled = enable
			Case 2
				_effect.DirectionalLight2.Enabled = enable
		End
	End

    
    Method SetLight( info:Float[] )
    	
    	If Not info Or Not ILighting(Self) Then Return
    	'' max lights = 3
    	
    	Local pos0:Int = 0, pos1:Int=8, pos2:Int = 16
    	_effect.DirectionalLight0.Enabled = Bool(Int(info[pos0+0]))
    	_effect.DirectionalLight1.Enabled = Bool(Int(info[pos1+0]))
    	_effect.DirectionalLight2.Enabled = Bool(Int(info[pos2+0]))
    		
    	If Int(info[pos0+0])
    		_effect.DirectionalLight0.Direction(info[pos0+1], info[pos0+2], info[pos0+3]) 
			_effect.DirectionalLight0.DiffuseColor(info[pos0+4], info[pos0+5], info[pos0+6])
    	Endif
    	If Int(info[pos1+0])
    		_effect.DirectionalLight1.Direction(info[pos1+1], info[pos1+2], info[pos1+3]) 
			_effect.DirectionalLight1.DiffuseColor(info[pos1+4], info[pos1+5], info[pos1+6])
    	Endif
    	If Int(info[pos2+0])
    		_effect.DirectionalLight2.Direction(info[pos2+1], info[pos2+2], info[pos2+3]) 
			_effect.DirectionalLight2.DiffuseColor(info[pos2+4], info[pos2+5], info[pos2+6])
    	Endif
    	
    	_updateLight = False
    	
    End
	
	Method ProjectionMatrix:Void(mat:Float[])
		_updateProjection = False
		_effect.ProjectionMatrix(mat)
	End
	
	Method ViewMatrix:Void(mat:Float[])
		_updateView = False
		_effect.ViewMatrix(mat)
	End
	
	Method WorldMatrix:Void(mat:Float[])
		_updateWorld = False
		_effect.WorldMatrix(mat)
	End
	
	Method Fog:Void(enable?)
		If enable Then _effect.FogEnabled = True Else _effect.FogEnabled = False
	End
	
	Method Update(cam:TCamera, ent:TEntity, e:IEffectContainer)
	
		Return 
	End

End 





Class BasicEffect Extends EffectContainer implements ILighting

	 
	
	Method New(effect:XNABasicEffect)
		_effect = effect
		
#if XNA_PERPIXEL_LIGHNING=1
		Local e:= XNABasicEffect(_effect)
		e.PreferPerPixelLighting = True
#Endif 
		
		_name = "basic"
	End 
	
	Method Reset()

		Super.Reset()
		Local effect:= XNABasicEffect(_effect)
		effect.LightingEnabled = True
		effect.TextureEnabled = False 
		
	End
	
	Method Bind(ent:TEntity, surf:TSurface, _state:EffectState, tex_count, textures:TTexture[]  )
	
		Local effect:= XNABasicEffect(_effect)
		
		' fx flag 1 - full bright ***todo*** disable all lights?
		If _state.use_full_bright Then 
			effect.AmbientLightColor(1,1,1)
			effect.LightingEnabled = False
			effect.SpecularPower(0)
			'effect.Alpha = _state.alpha
		Else 
			effect.AmbientLightColor(_state.ambient[0], _state.ambient[1], _state.ambient[2])
			effect.LightingEnabled = True
			effect.SpecularPower(_state.shine)
		End 

		' fx flag 2 - vertex colors 
		If _state.use_vertex_colors
			effect.VertexColorEnabled = True
			effect.DiffuseColor(1,1,1)			
		Else
			effect.VertexColorEnabled = False 
			effect.DiffuseColor(_state.red,_state.green,_state.blue)
			effect.Alpha = _state.alpha
			'effect.SpecularPower(_state.shine)
		Endif
		
		' fx flag 4 - flatshaded

		' fx flag 8 - disable fog
	
		
		
		If tex_count > 0
	
			' activate texture or preserve texture states
			Local cur_tex:TTexture = textures[0]
			
			If cur_tex
				effect.TextureEnabled = True
			
				If cur_tex <> _lastTexture And XNARender._textures Then
					_lastTexture = cur_tex
					effect.Texture = XNARender._textures.Get(cur_tex.gltex[0])

				Endif
				
			Endif
		Else
			
			' turn off textures if no textures
			effect.TextureEnabled = False
			'_lastTexture = Null
			
		Endif
		
	End
	
	
End


Class AlphaTestEffect Extends EffectContainer

	Method Reset()

		Super.Reset()
		'Local effect:= XNAAlphaTestEffect(_effect)
		
	End
	
	Method New(effect:XNAAlphaTestEffect)
		_effect = effect
		_name = "alphatest"

	End
	
	Method Bind(ent:TEntity, surf:TSurface, _state:EffectState, tex_count, textures:TTexture[]  )
	
		Local effect:= XNAAlphaTestEffect(_effect)
		
		' fx flag 1 - full bright '' AlphaTestEffect is always full bright?
		If _state.use_full_bright Then 
			'effect.AmbientLightColor(1,1,1)
			'effect.LightingEnabled = False
			'effect.SpecularPower(0)
			'effect.Alpha = _alpha
		Else 
			'effect.AmbientLightColor(TLight.ambient_red, TLight.ambient_green, TLight.ambient_blue)
			'effect.LightingEnabled = True
			'effect.SpecularPower(_shine)
		End 

		' fx flag 2 - vertex colors 
		If _state.use_vertex_colors=1
			effect.VertexColorEnabled = True
			effect.DiffuseColor(1,1,1)
			effect.Alpha = _state.alpha		
		Else
			effect.VertexColorEnabled = False 
			effect.DiffuseColor(_state.red,_state.green,_state.blue)
			effect.Alpha = _state.alpha
			'effect.SpecularPower(_state.shine)
		Endif
		
		' fx flag 4 - flatshaded

		' fx flag 8 - disable fog
	
	
		
		If tex_count > 0
			' activate texture or preserve texture states
			Local cur_tex:TTexture = textures[0]
			
			If cur_tex

				If cur_tex <> _lastTexture And XNARender._textures Then
					_lastTexture = cur_tex
					effect.Texture = XNARender._textures.Get(cur_tex.gltex[0])
				Endif
				
			Endif			
		Endif
		
		effect.AlphaFunction = CompareFunction_GreaterEqual
		effect.ReferenceAlpha = 127
	
	End
	

	
End


'' -- should work now
Class Draw2DEffect Extends BasicEffect

	Method Reset()

		Super.Reset()
		Local effect:= XNABasicEffect(_effect)
		effect.LightingEnabled = False
		effect.TextureEnabled = True
		
	End
	
	Method New(effect:XNABasicEffect)
		_effect = effect
		_name = "draw2d"

		Reset()
	End 
	
	Method Bind(ent:TEntity, surf:TSurface, _state:EffectState, tex_count, textures:TTexture[]  )
		
		''handle textures & flags
		Super.Bind(ent,surf,_state,tex_count,textures)
		
		Local effect:XNABasicEffect = XNABasicEffect(_effect)
		'_disable_fog = True
		effect.LightingEnabled = False
		effect.AmbientLightColor(1,1,1)
		effect.SpecularPower(0)
		'effect.EmissiveColor(1,1,1)
	
	End
	
End




Class EnvironmentMapEffect Extends EffectContainer implements ILighting
	
	Field _lastTexture:TTexture 
	Field _lastCubeTexture:TTexture 

	Method New(effect:XNAEnvironmentMapEffect)
		_effect = effect
		_name = "environment"
	End 
	
	Method Bind(ent:TEntity, surf:TSurface, _state:EffectState, tex_count, textures:TTexture[]  )
		
		Local effect:= XNAEnvironmentMapEffect(_effect)
	
		' fx flag 2 - vertex colors ***todo*** disable all lights?
		' not supported with enviromentmap
		If _state.use_vertex_colors=1			
		Else
			effect.DiffuseColor(_state.red,_state.green,_state.blue);
	        effect.Alpha = _state.alpha;
		Endif
			
		' fx flag 1 - full bright ***todo*** disable all lights?
		If _state.full_bright=1 Then 
			effect.AmbientLightColor(1,1,1) 
		Else 
			effect.AmbientLightColor(_state.ambient[0], _state.ambient[1], _state.ambient[2])
		End 
		
		' fx flag 8 - disable fog
		'If _fx&8 Then 
			'effect._disable_fog = True 
		'End 
		
		' set textures
		For Local i= 0 Until tex_count
			Local tex_flags  = textures[i].flags
			Local texture := textures[i]
	
			If tex_flags&128 Then ' this layer is cubemap
				If texture And _lastCubeTexture <> texture Then ' preserve texture states
					_lastCubeTexture = texture
					' Error : Cannot convert from XNATexture to XNATextureCube.
					'effect.EnvironmentMap = XNATextureCube(XNARender._textures.Get(texture.gltex[0]))
				End
			Else ' this layer is color map
				If texture And _lastTexture <> texture Then ' preserve texture states
					_lastTexture = texture
					' Todo: check xna.cs
		 			'effect.Texture = XNATexture(XNARender._textures.Get(texture.gltex[0]))
				End
			End 
			If i = 1 Then Exit ' The first two texture layers must contain the color and the cubemap
		Next
	End
End 
