' XNA miniB3D target Author: Sascha Schmidt

Import mojo
Import xna 

Import minib3d.trender
Import minib3d

Import xna_pixmap
Import xna_common

#rem

Notes:
 
 http://msdn.microsoft.com/en-us/library/ff604995.aspx

vbos - xna must use vbo, as data is loaded in via byte buffer (yes, in xna)
lights - no point or spotlight or multiple light without HLSL

-- make sure to clear states before returning to mojo

#end 

Class XNARender Extends TRender
	
Private

	Field _device				:XNAGraphicsDevice 
	Field _xna					:XNAController
	
	Field UP_VECTOR				:= New Vector(0,-1,0) 
	Field LIGHT_QUAD			:= New Quaternion()
	
	Global _textures:= New IntMap<XNATexture> ' Todo Resourcemanager
	Global _depthEnable:Bool = True
	
	Field _meshes:= New IntMap<XNAMesh>
	Field _lights:TLight[3]
	Field _last_texture:TTexture
	
	Field _alpha_list:= New List<TSurface> 
	Field _mesh_id, _texture_id, _light_no

Public 
		
	Method New()
		_device 	= New XNAGraphicsDevice 
		_xna		= New XNAController(_device)
	End
	
	Method GetTexture:XNATexture(tex:TTexture)
		Return _textures.Get( tex.gltex[0] )
	End
	

	Method ClearErrors:Int()
	End
	
	''should return shader model
	Method GetVersion:Float()
		Return GetShaderVersion()
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
		EndMojoRender()
		
		TRender.alpha_pass = 0
		_xna.Reset()
		
	End
	
	Method Render:Void(ent:TEntity, cam:TCamera = Null)
	
		Local mesh:TMesh = TMesh(ent)
		If Not mesh Then Return
		

		'' draw surfaces with alpha last
		Local temp_list:List<TSurface> = mesh.surf_list
		_alpha_list.Clear()
	
		' entity Transform
		If TSprite(ent)
			_xna.WorldMatrix(TSprite(ent).mat_sp.ToArray())
		Else
			_xna.WorldMatrix(ent.mat.ToArray())
		Endif

		'' update camera, effects
		_xna.UpdateEffect(ent, cam)
					
		' one effect per mesh
		Local passes:= _xna.CurrentEffect.Effect.CurrentTechnique.Passes
						
		For Local pass:= Eachin passes

''debugging
'Print mesh.classname		
'Print "effect: "+_xna.CurrentEffect()._name+"  2d:"+cam.draw2D+"  alphapass:"+alpha_pass
'Print "cam: "+cam.name
			
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
					
					' set textures / blending / shading / culling / draw2D
					_xna.UpdateSurface(ent, surf, cam)		
			
				
					pass.Apply()
	
	
					' draw tris
					If mesh.anim
						
						Local meshx:= _meshes.Get(mesh.anim_surf[surf.surf_id].vbo_id[0])
						meshx.Bind()
						meshx.Render()
					
					Else
		
						Local meshx:= _meshes.Get(surf.vbo_id[0])
						meshx.Bind()
						meshx.Render()
					Endif 
	
				 
			
				If Not _alpha_list Then Exit ''get out of loop, no alpha
				temp_list = _alpha_list
				
				Next '' surfaces
				
			Next	''end alpha loop
		
		Next ' effect passes
			
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
			
		If surf.reset_vbo&1 Or surf.reset_vbo&2 Or surf.reset_vbo&4 Or surf.reset_vbo&8
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

	Method DeleteTexture(glid:Int[])
		If _textures.Contains (glid[0]) Then 
			_textures.Remove(glid[0])
		End 
	End
	
	' Caution
	' Here is a tip for rendering objects within the Draw method of an Xbox 360 game. 
	' Do not use SetData when writing data to vertex buffers, index buffers, and textures: http://msdn.microsoft.com/en-us/library/bb198834
	Method BindTexture:TTexture(tex:TTexture,flags:Int)

		' if mask flag is true, mask pixmap
		If flags&4
			tex.pixmap.MaskPixmap(0,0,0)
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
		
		'If (_device)
			' viewport
			_device.Viewport(cam.vx,cam.vy,cam.vwidth,cam.vheight)
		
			' clear buffers
			_device.ClearScreen(cam.cls_r,cam.cls_g,cam.cls_b, cam.cls_color, cam.cls_zbuffer, False )
		
		'Endif
		
		' set view matrix					
		_xna.ViewMatrix( cam.mod_mat.ToArray())
		
		' set projection
		_xna.ProjectionMatrix(cam.proj_mat.ToArray())
		
		' fog
		_xna.Fog( cam.fog_range_near, cam.fog_range_far, cam.fog_r,cam.fog_g,cam.fog_b, cam.fog_mode>0)		
	End
	
	Method ResetBrush()
		_xna.CurrentEffect().Reset()
	End
	
	Method BackBufferToTex(mipmap_no=0,frame=0)
	End 
	
	'''
	
	Field _spriteBatch:XNASpriteBatch
	Field _xnaTex:XNATexture
	Field _lastTex:TTexture 
	
	Method Begin2D()
		if Not _spriteBatch Then 
			_spriteBatch = New XNASpriteBatch	
		End 
		_spriteBatch.BeginRender()
	End
	
	Method DrawTexture(tex:TTexture,x#,y#, _r#,_g#,_b#,_a#, _angle#, _hx#, _hy#, _sx#,_sy#)
	
		if tex <> _lastTex Then 
		
			_lastTex = tex
			_xnaTex = GetTexture(tex)
			
			_spriteBatch.EndRender()
			_spriteBatch.BeginRender()
		
		EndIf
			
		 _spriteBatch.Draw(_xnaTex,x,y, _r,_g,_b,_a, _angle, _hx, _hy, _sx,_sy)
		 
	End
	
	Method End2D()
		_spriteBatch.EndRender()
		Self.Reset()
	End
	
Private 
	
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
	Field _rasterizerStates		:XNARasterizerState[]
	Field _rasterizerWire		:XNARasterizerState
	Field _depthStencil			:XNADepthStencilState
	Field _depthStencilDefault	:XNADepthStencilState
	Field _depthStencilNone		:XNADepthStencilState
	Field _depthStencilNoWrite	:XNADepthStencilState
	Field _depthStencilNoDepth	:XNADepthStencilState
	
	Field _blendStates			:XNABlendState[] 
	Field _lastSamplerState		:XNASamplerState 	
	Field _st_uvNormal 			:UVSamplerState
	Field _st_uvSmooth			:UVSamplerState
	
	' effects
	Field _lastEffect			:EffectContainer
	Field _basicEffect			:BasicEffect
	Field _enviromentEffect		:BasicEffect
	Field _draw2DEffect			:Draw2DEffect
	
	Field _lastTexture			:TTexture
	
	' last combined brush values
	Field tex_count%, _red#,_green#,_blue#,_alpha#,_shine#,_blend%,_fx%, tex_flags%, textures:TTexture[]



Public 

	Method New(device:XNAGraphicsDevice)
		_device = device
		
		' effects
		_basicEffect = New BasicEffect(device.CreateBasicEffect())
		_enviromentEffect = New BasicEffect(device.CreateBasicEffect())
		_draw2DEffect = New Draw2DEffect(device.CreateBasicEffect())
		
		_lastEffect = _basicEffect
		
		' states
		_rasterizerStates 	= [XNARasterizerState.CullNone, XNARasterizerState.CullCounterClockwise,XNARasterizerState.CullClockwise ]
		
		_rasterizerWire 	= XNARasterizerState.Create()
		_rasterizerWire.CullMode = CullMode_None
		_rasterizerWire.FillMode = FillMode_WireFrame
		
		_depthStencilDefault = XNADepthStencilState._Default
		_depthStencilNone 	= XNADepthStencilState.None
		
		_depthStencilNoWrite	= XNADepthStencilState.Create ''may need a new state based on default
		_depthStencilNoWrite.DepthBufferEnable = True
		_depthStencilNoWrite.DepthBufferWriteEnable = False
		
		_depthStencilNoDepth	= XNADepthStencilState.Create ''is same as "none"
		_depthStencilNoDepth.DepthBufferEnable = False
		_depthStencilNoDepth.DepthBufferWriteEnable = False

		_blendStates =[XNABlendState.Premultiplied, XNABlendState.Premultiplied, XNABlendState.AlphaBlend, XNABlendState.Additive, XNABlendState.Opaque]

		#if XNA_MIPMAP_QUALITY=0 then 
			Local bias:Float = 0.5
		#else if XNA_MIPMAP_QUALITY=1 then 
			Local bias:Float = 0
		#else if XNA_MIPMAP_QUALITY=2 then 
			Local bias:Float = -0.5
			Print bias
		#End 
		
		_st_uvNormal = UVSamplerState.Create(TextureFilter_Point, bias)
		
		#if XNA_MIPMAP_FILTER=1 then
			_st_uvSmooth = UVSamplerState.Create(TextureFilter_Linear, bias)
		#else
			_st_uvSmooth = UVSamplerState.Create(TextureFilter_LinearMipPoint, bias)
		#End 
		
	End

	Field _cam:TCamera
	
	Method Reset()

		ClearStates()
		
		_device.RasterizerState = XNARasterizerState.CullClockwise;
        _device.DepthStencilState = XNADepthStencilState.None;

		_lastEffect = _basicEffect
		_basicEffect.Reset()
		_lastTexture = Null
		tex_count=0
	End
	
	Method SetLightEnable(id, enable?)
		_lastEffect.SetLightEnable(id, enable)
	End
	
	Method SetLight(id, dirX#, dirY#, dirZ#, r#, g#, b#)
		_lastEffect.SetLight(id, dirX, dirY, dirZ, r, g, b)
    End
	
	Method CurrentEffect:Void(effect:EffectContainer) Property
		_lastEffect = effect
	End
	
	Method CurrentEffect:EffectContainer() Property
		Return _lastEffect
	End
	
	'Method Projection(fieldOfView#, aspect#, near#, far#)
		'_lastEffect.Projection(fieldOfView, aspect, near, far)
	'End
	
	Method View(px#, py#, pz#, rx#, ry#, rz#, sx#, sy#, sz#) 
		_lastEffect.View(px, py, pz, rx, ry, rz, sx, sy, sz)
	End
	
	Method World(px#, py#, pz#, rx#, ry#, rz#, sx#, sy#, sz#)
		_lastEffect.World(px, py, pz, rx, ry, rz, sx, sy, sz)
	End
	
	Method ProjectionMatrix(mat:Float[])
		_lastEffect.Effect().ProjectionMatrix(mat)
	End
	
	Method ViewMatrix(mat:Float[])
		_lastEffect.Effect().ViewMatrix(mat)
	End
	
	Method WorldMatrix(mat:Float[])
		_lastEffect.Effect().WorldMatrix(mat)
	End
	
	Method Fog(near# ,far# ,r#,g#, b#, enabled?)
		If enabled>0
			_lastEffect.Effect().FogEnabled = True
			_lastEffect.Effect().FogStart = near
	        _lastEffect.Effect().FogEnd = far
	        _lastEffect.Effect().FogColor(r,g,b)
		Else
			_lastEffect.Effect().FogEnabled = False 
		Endif
	End
	
	
	
	Method SetStates(ent:TEntity, surf:TSurface, cam:TCamera )
		
		_cam = cam
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
		
		If tex_flags&16 And tex_flags&32 Then ' clamp u clamp v flag
			state = filter._cU_cV
		Elseif tex_flags&16 'clamp u flag
			state = filter._cU_wV
		Elseif tex_flags&32 'clamp v flag
			state = filter._wU_cV
		Elseif tex_count>0 And has_texture				
			state = filter._wU_wV ''only use wrap with power-of-two textures 
		End

		' ' preserve sampler state
		If state <> _lastSamplerState Then 
			_device.SamplerState(0, state)
			_lastSamplerState = state
		End 

		'----------------
		
		' fx flag 16 - disable backface culling
		If _fx&16 Then 
			_device.RasterizerState = _rasterizerStates[0] 
		Else 
			_device.RasterizerState = _rasterizerStates[2]
		End 
		
		''global wireframe rendering
		If TRender.render.wireframe
			_device.RasterizerState = _rasterizerWire
		Endif

		' take into account auto fade alpha
		_alpha=_alpha-ent.fade_alpha
		
		' if surface contains alpha info, enable blending
		''and  fx flag 64 - disable depth testing
		
		If _fx&64 Or cam.draw2D
			_device.DepthStencilState = _depthStencilNoDepth
			
		Elseif (ent.alpha_order<>0.0 Or surf.alpha_enable=True)
			_device.DepthStencilState = _depthStencilNoWrite
			
		Else
			_device.DepthStencilState = _depthStencilDefault
		Endif	
		
		' blend mode
		_device.BlendState = _blendStates[_blend]
		
	End 
	
	Method DisableDepth()
		_device.DepthStencilState = _depthStencilNoDepth
	End
	
	''if we decide to return to monkey.mojo
	Method ClearStates()
		
		 _device.SamplerState(0, _st_uvNormal._cU_cV )
		_lastSamplerState = _st_uvNormal._cU_cV
		_device.DepthStencilState = _depthStencilDefault
		_device.BlendState = _blendStates[0]
		
		If _cam And _basicEffect
			_basicEffect.Effect().FogEnabled = _cam.fog_mode > 0
		End 
			
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
	
	
	Method UpdateTexture( mesh:TEntity, surf:TSurface, cam:TCamera)
		''no multi-texture (we could do another pass, use fast scissor AABB function)
		
		''if texture scale, pos, or ang changes, we need to update here since there is no texture matrix
		'Local _coordset%, _uscale#, _vscale#, _upos#, _vpos#, _angle#
		If textures.Length < 1 Or tex_count<1 Then Return
		
		Local cur_tex:TTexture = textures[0]
		'If surf.brush.tex[0] Then cur_tex = surf.brush.tex[0]
		
		If Not cur_tex Then Return
		
		tex_flags  = cur_tex.flags

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
	Method UpdateEffect(ent:TEntity, cam:TCamera)
		
		''set current effect (default)
		Local e:EffectContainer = _basicEffect
		
		If cam.draw2D
			
			'e= _draw2DEffect   '''********* DOES NOT WORK! Cam problem ************

		Else
		
			' if cubic environment map
			If tex_flags&128<>0
			
				e= _enviromentEffect
				
			Endif 
		
		Endif
	
		If e <> CurrentEffect()

			CurrentEffect(e)
			TRender.render.UpdateCamera(cam)
			e.Update(cam,ent,CurrentEffect )
			
		Endif
		
		If cam.draw2D
			If BasicEffect(e) Then BasicEffect(e).NoLighting
		Endif
		
	End
	
	
	Method UpdateSurface(ent:TEntity, surf:TSurface, cam:TCamera)
	
		' combine surface brush values with main brush values
		CombineBrushes(ent.brush,surf.brush)	
		
		UpdateTexture(ent, surf, cam)
		
		' RasterizerState / DepthStencilState / BlendState
		SetStates(ent, surf, cam)

		CurrentEffect().Bind(ent, surf, _red,_green,_blue, _alpha, _shine, _fx, tex_count, textures )
		
		
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

Interface IEffectContainer
	Method Effect:XNAEffect() 
	Method Update(cam:TCamera, ent:TEntity, e:IEffectContainer)
	Method Bind(ent:TEntity, surf:TSurface, _red#,_green#,_blue#, _alpha#, _shine#, _fx%, tex_count, textures:TTexture[] ) 
	Method Reset()
	Method SetLight(id, dirX#, dirY#, dirZ#, r#, g#, b#)
	Method SetLightEnable(id, enable?)
	'Method Projection(fieldOfView#, aspect#, near#, far#)
	'Method View(px#, py#, pz#, rx#, ry#, rz#, sx#, sy#, sz#) 
	'Method World(px#, py#, pz#, rx#, ry#, rz#, sx#, sy#, sz#)
	Method ProjectionMatrix:Void(mat:Float[])
	Method ViewMatrix:Void(mat:Float[])
	Method WorldMatrix:Void(mat:Float[])
End 



Class EffectContainer Implements IEffectContainer

	Field _updateWorld? 		= True
	Field _updateView?  		= True
	Field _updateLight? 		= True
	Field _updateProjection? 	= True
	Field _effect				:XNAEffect
	Field _name					:String
	
	Method Bind(ent:TEntity, surf:TSurface, 
		_red#,_green#,_blue#, _alpha#, _shine#, _fx%, tex_count, textures:TTexture[] ) Abstract
	
	Method Effect:XNAEffect() 
		Return _effect
	End
	
	Method Reset()
		_updateWorld = True
		_updateView = True
		_updateLight = True
		_updateProjection = True
		_effect.FogEnabled = False
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
	
	Method SetLight(id, dirX#, dirY#, dirZ#, r#, g#, b#)
		_updateLight = False
		
		Select id
			Case 0

				_effect.DirectionalLight0.Direction(dirX, dirY, dirZ) 
				_effect.DirectionalLight0.DiffuseColor(r,g,b);
			Case 1

				_effect.DirectionalLight1.Direction(dirX, dirY, dirZ) 
				_effect.DirectionalLight1.DiffuseColor(r,g,b);
			Case 2

				_effect.DirectionalLight2.Direction(dirX, dirY, dirZ) 
				_effect.DirectionalLight2.DiffuseColor(r,g,b);
		End
    End
	
	'Method Projection(fieldOfView#, aspect#, near#, far#)
		'_effect.Projection(fieldOfView, aspect, near, far)
	'End
	
	'Method View(px#, py#, pz#, rx#, ry#, rz#, sx#, sy#, sz#) 
		'_updateView = False
		'_effect.View(px, py, pz, rx, ry, rz, sx, sy, sz)
	'End
	
	'Method World(px#, py#, pz#, rx#, ry#, rz#, sx#, sy#, sz#)
		'_updateWorld = False
		'_effect.World(px, py, pz, rx, ry, rz, sx, sy, sz)
	'End
	
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
	
	Method Update(cam:TCamera, ent:TEntity, e:IEffectContainer)
	
		Return 
	End
End 





Class BasicEffect Extends EffectContainer

	Field _lastTexture:TTexture 
	
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
		_lastTexture = Null
		
	End
	
	Method Bind(ent:TEntity, surf:TSurface, _red#,_green#,_blue#, _alpha#, _shine#, _fx%, tex_count, textures:TTexture[]  )
	
		Local effect:= XNABasicEffect(_effect)
		
		' fx flag 1 - full bright ***todo*** disable all lights?
		If _fx&1 Then 
			effect.AmbientLightColor(1,1,1)
			effect.LightingEnabled = False
			effect.SpecularPower(0)
			effect.Alpha = 1.0
		Else 
			effect.AmbientLightColor(TLight.ambient_red, TLight.ambient_green, TLight.ambient_blue)
			effect.LightingEnabled = True
			effect.SpecularPower(_shine)
		End 

		' fx flag 2 - vertex colors 
		If _fx&2
			effect.VertexColorEnabled = True
			effect.DiffuseColor(1,1,1)			
		Else
			effect.VertexColorEnabled = False 
			effect.DiffuseColor(_red,_green,_blue)
	        effect.Alpha = _alpha
		Endif
		
		' fx flag 4 - flatshaded

		' fx flag 8 - disable fog
		If _fx&8 Then 
			effect.FogEnabled = False 
		End 
		
		
		
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
	
	Method NoLighting:Void()
		
		Local effect:XNABasicEffect = XNABasicEffect(_effect)
		effect.FogEnabled = False
		effect.LightingEnabled = False
		effect.AmbientLightColor(1,1,1)
		effect.SpecularPower(0)
		
	End
End


'' *** does not work
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

#if XNA_PERPIXEL_LIGHNING=1
		Local e:= XNABasicEffect(_effect)
		e.PreferPerPixelLighting = True
#Endif		
		
		Reset()
	End 
	
	Method Bind(ent:TEntity, surf:TSurface, _red#,_green#,_blue#, _alpha#, _shine#, _fx%, tex_count, textures:TTexture[]  )
		
		''handle textures & flags
		Super.Bind(ent,surf,_red,_green,_blue,_alpha,_shine,_fx,tex_count,textures)
		
		Local effect:XNABasicEffect = XNABasicEffect(_effect)
		effect.FogEnabled = False
		effect.LightingEnabled = False
		effect.AmbientLightColor(1,1,1)
		effect.SpecularPower(0)
		'effect.EmissiveColor(1,1,1)
	
	End
	
End




Class EnvironmentMapEffect Extends EffectContainer
	
	Field _lastTexture:TTexture 
	Field _lastCubeTexture:TTexture 

	Method New(effect:XNAEnvironmentMapEffect)
		_effect = effect
		_name = "environment"
	End 
	
	Method Bind(ent:TEntity, surf:TSurface, _red#,_green#,_blue#, _alpha#, _shine#, _fx%, tex_count, textures:TTexture[]  )
		
		Local effect:= XNAEnvironmentMapEffect(_effect)
	
		' fx flag 2 - vertex colors ***todo*** disable all lights?
		' not supported with enviromentmap
		If _fx&2			
		Else
			effect.DiffuseColor(_red,_green,_blue);
	        effect.Alpha = _alpha;
		Endif
			
		' fx flag 1 - full bright ***todo*** disable all lights?
		If _fx&1 Then 
			effect.AmbientLightColor(1,1,1) 
		Else 
			effect.AmbientLightColor(TLight.ambient_red, TLight.ambient_green, TLight.ambient_blue)
		End 
		
		' fx flag 8 - disable fog
		If _fx&8 Then 
			effect.FogEnabled = False 
		End 
		
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
