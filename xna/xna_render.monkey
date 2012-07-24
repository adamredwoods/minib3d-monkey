' XNA miniB3D target Author: Sascha Schmidt

Import mojo
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
lights - no point or spotlight without HLSL

#end 

#MINIB3D_DRIVER="xna"
#PREFER_PERPIXEL_LIGHNING="true"

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
	
End



Class XNARender Extends TRender
	
Private

	Field _device				:XNAGraphicsDevice 
	Field _xna					:XNAController
	
	Field UP_VECTOR				:= New Vector(0,-1,0) 
	Field LIGHT_QUAD			:= New Quaternion()
	
	Global _textures:= New IntMap<XNATexture> ' Todo Resourcemanager
	Global _texturedata:= New XNATextureData[2] ''use texture.gltex[] index
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
	
	Method ClearErrors:Int()
	End
	
	''should return shader model
	Method GetVersion:Float()
		Return GetShaderVersion()
	End

	Method GraphicsInit(flags:Int=0)
	
		TPixmapXNA.Init()
		
		Reset()
		
		TLight.max_lights = 3
		width = DeviceWidth
		height = DeviceHeight 
		vbo_enabled = True
		 
	End
	
	Method Reset:Void()
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
				UpdateSurface(surf, mesh)
				
				' set textures / blending / shading / culling
				_xna.Update(ent, surf, cam)

				' draw tris
				Local passes:= _xna.CurrentEffect.Effect.CurrentTechnique.Passes
				For Local pass:= Eachin passes
					pass.Apply()
					
					' draw tris
					If mesh.anim
						
						Local mesh:= _meshes.Get(mesh.anim_surf[surf.surf_id].vbo_id[0])
						mesh.Bind()
						mesh.Render()
					
					Else
						Local mesh:= _meshes.Get(surf.vbo_id[0])
						mesh.Bind()
						mesh.Render()
					End
				End 

			Next 
		
			If Not _alpha_list Then Exit ''get out of loop, no alpha
			temp_list = _alpha_list
			
		Next	''end alpha loop
			
		temp_list = Null	
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
		If tex.flags&4
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
		If tex.flags&8 Then mipmap=True
		If Not( IsPowerOfTwo(width) Or IsPowerOfTwo(height) ) Then 
			mipmap=False
			' TODO: no wrap addressing mode and no DXT compression on nonpower of two textures.
		End 
		
		If tex.gltex[0] = 0 Then 
			_texture_id+=1
			tex.gltex[0] = _texture_id
		End 
			
		Local t:= _device.CreateTexture(tex.pixmap.width, tex.pixmap.height, Bool(mipmap), -1 )
		
		If t Then
		
			_textures.Set( tex.gltex[0], t ) 
			If _texture_id >= _texturedata.Length() Then _texturedata = _texturedata.Resize(_texture_id+5)
			_texturedata[_texture_id] = New XNATextureData
			
		End 
		
		Local pix:TPixmapXNA = TPixmapXNA(tex.pixmap)
		
		Repeat

			t.SetData(mip_level, pix.pixels, 0, pix.pixels.Size)
			
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
	
		' viewport
		_device.Viewport(cam.vx,cam.vy,cam.vwidth,cam.vheight)
		
		' clear buffers
		_device.ClearScreen(cam.cls_r,cam.cls_g,cam.cls_b, cam.cls_color=True, cam.cls_zbuffer=True, False )
		
		' set view matrix
		'_xna.View (	cam.EntityX(True), 		cam.EntityY(True), 		cam.EntityZ(True), 
					'cam.EntityPitch(True), 	cam.EntityYaw(True), 	cam.EntityRoll(True), 
					'cam.EntityScaleX(True), cam.EntityScaleY(True), cam.EntityScaleZ(True))
					
		_xna.ViewMatrix( cam.mod_mat.ToArray())
		
		' set projection
		'_xna.Projection(cam.fov_y, cam.aspect, cam.range_near , cam.range_far)
		_xna.ProjectionMatrix(cam.proj_mat.ToArray())
		
		' fog
		_xna.Fog( cam.fog_range_near, cam.fog_range_far, cam.fog_r,cam.fog_g,cam.fog_b, cam.fog_mode>0)		
	End
	
	Method ResetBrush()
		_xna.CurrentEffect().Reset()
	End
	
	Method BackBufferToTex(mipmap_no=0,frame=0)
	End 
	
	'################################################################################
	
Private 
	
	Method IsPowerOfTwo?(x)
	    Return (x <> 0) And ((x & (x - 1)) = 0)
	End
	
	Method UpdateSurface(surf:TSurface, mesh:TMesh)
		
		''if texture scale, pos, or ang changes, we need to update here since there is no texture matrix
		'Local _coordset%, _uscale#, _vscale#, _upos#, _vpos#, _angle#
		
		Local cur_tex:TTexture = mesh.brush.tex[0]
		If surf.brush.tex[0] Then cur_tex = surf.brush.tex[0]
		
		If cur_tex
			
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
			
		Endif
		
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
			
			If vbo
			
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







' First of all for managing different XNAEffects
' e.g. switching between XNABasicEffect, XNAEnvironmentMapEffect
' also manage state switching
Class XNAController

Private 

	' the device
	Field _device:XNAGraphicsDevice 
	
	' states
	Field _rasterizerStates		:XNARasterizerState[]
	Field _depthStencilDefault	:XNADepthStencilState
	Field _depthStencilNone		:XNADepthStencilState
	Field _depthStencilNoWrite	:XNADepthStencilState
	Field _blendStates			:XNABlendState[] 
	Field _lastSamplerState		:XNASamplerState 	
	Field _st_cU_cV				:XNASamplerState
	Field _st_wU_cV				:XNASamplerState
	Field _st_cU_wV				:XNASamplerState
	
	' effects
	Field _lastEffect			:IEffectContainer
	Field _basicEffect			:BasicEffect
	Field _enviromentEffect		:BasicEffect 
	
	' last combined brush values
	Field tex_count%, _red#,_green#,_blue#,_alpha#,_shine#,_blend%,_fx%, tex_flags%, textures:TTexture[]



Public 

	Method New(device:XNAGraphicsDevice)
		_device = device
		
		' effects
		_basicEffect = New BasicEffect(device.CreateBasicEffect())
		_enviromentEffect = New BasicEffect(device.CreateBasicEffect())

		_lastEffect = _basicEffect
		
		' states
		_rasterizerStates 	= [XNARasterizerState.CullNone, XNARasterizerState.CullCounterClockwise,XNARasterizerState.CullClockwise ]
		_depthStencilDefault = XNADepthStencilState._Default
		_depthStencilNone 	= XNADepthStencilState.None
		_depthStencilNoWrite	= XNADepthStencilState.Create ''may need a new state based on default
		_depthStencilNoWrite.DepthBufferWriteEnable = False
		
		_blendStates 		= [XNABlendState.AlphaBlend, XNABlendState.AlphaBlend, XNABlendState.Premultiplied, XNABlendState.Additive, XNABlendState.Opaque]
		_st_cU_cV 		= XNASamplerState.Create( TextureFilter_Linear, TextureAddressMode_Clamp, TextureAddressMode_Clamp)
		_st_wU_cV 		= XNASamplerState.Create( TextureFilter_Linear, TextureAddressMode_Wrap , TextureAddressMode_Clamp)
		_st_cU_wV 		= XNASamplerState.Create( TextureFilter_Linear, TextureAddressMode_Clamp, TextureAddressMode_Wrap)
	End

	Method Reset()
		_lastSamplerState = Null
		_device.DepthStencilState = _depthStencilDefault	
		_lastEffect.Reset()
	End
	
	Method SetLightEnable(id, enable?)
		_lastEffect.SetLightEnable(id, enable)
	End
	
	Method SetLight(id, dirX#, dirY#, dirZ#, r#, g#, b#)
		_lastEffect.SetLight(id, dirX, dirY, dirZ, r, g, b)
    End
	
	Method CurrentEffect:IEffectContainer() Property
		Return _lastEffect
	End
	
	Method Projection(fieldOfView#, aspect#, near#, far#)
		_lastEffect.Projection(fieldOfView, aspect, near, far)
	End
	
	Method View(px#, py#, pz#, rx#, ry#, rz#, sx#, sy#, sz#) 
		_lastEffect.View(px, py, pz, rx, ry, rz, sx, sy, sz)
	End
	
	Method World(px#, py#, pz#, rx#, ry#, rz#, sx#, sy#, sz#)
		_lastEffect.World(px, py, pz, rx, ry, rz, sx, sy, sz)
	End
	
	Method ProjectionMatrix(mat:Float[])
		_lastEffect.ProjectionMatrix(mat)
	End
	
	Method ViewMatrix(mat:Float[])
		_lastEffect.ViewMatrix(mat)
	End
	
	Method WorldMatrix(mat:Float[])
		_lastEffect.WorldMatrix(mat)
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
	
	Method SetStates(ent:TEntity, surf:TSurface )
		
		Local new_sampler_state:XNASamplerState 
		
		If tex_flags&16<>0 Then ' clamp u flag
			If tex_flags&32<>0' clamp v flag
				new_sampler_state = _st_cU_cV
			Else
				new_sampler_state = _st_cU_wV
			End 
		Else If tex_flags&32<>0' clamp v flag
			If tex_flags&16<>0' clamp u flag
				new_sampler_state = _st_cU_cV
			Else						
				new_sampler_state = _st_wU_cV 
			Endif
		End
		
		' ' preserve sampler state
		If new_sampler_state <> _lastSamplerState Then 
			_device.SamplerState(0, new_sampler_state)
			_lastSamplerState = new_sampler_state
		End 
		
		'----------------
		
		' fx flag 16 - disable backface culling
		If _fx&16 Then 
			_device.RasterizerState = _rasterizerStates[0] 
		Else 
			_device.RasterizerState = _rasterizerStates[2]
		End 
		

		'' fx flag 32 - force alpha
		If _fx&32
			surf.alpha_enable=True
		Endif
		
		'' fx flag 64 - disable depth testing (new 2012)
		If _fx&64 Then 
			_device.DepthStencilState = _depthStencilNone 
		Else
			_device.DepthStencilState = _depthStencilDefault
		End 

		' take into account auto fade alpha
		_alpha=_alpha-ent.fade_alpha

		
		' if surface contains alpha info, enable blending
		If ent.alpha_order<>0.0 Or surf.alpha_enable=True
			_device.DepthStencilState = _depthStencilNoWrite 
		Else
			_device.DepthStencilState = _depthStencilDefault
		Endif	
		
		' blend mode
		_device.BlendState = _blendStates[_blend]
		
	End 
	
	Method CombineBrushes(brushA:TBrush,brushB:TBrush )

		' get main brush values
		_red   = brushA.red
		_green = brushA.green
		_blue  = brushA.blue
		_alpha = brushA.alpha
		_shine = brushA.shine
		_blend = brushA.blend
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
		End 
		
	End
	
	Method Update(ent:TEntity, surf:TSurface, cam:TCamera)
	
		' combine surface brush values with main brush values
		CombineBrushes(ent.brush,surf.brush)	
		
		' if cubic environment map
		If tex_flags&128<>0

			If _enviromentEffect <> _lastEffect Then 
				_enviromentEffect.Update(cam,ent,_lastEffect)
				_lastEffect = _enviromentEffect
			End
		
			_enviromentEffect.Bind(ent, surf, _red,_green,_blue, _alpha, _shine, _fx, tex_count, textures )
		Else

			If _basicEffect <> _lastEffect Then 
				_basicEffect.Update(cam,ent,_lastEffect)
				_lastEffect = _basicEffect
			End
			
			_basicEffect.Bind(ent, surf, _red,_green,_blue, _alpha, _shine, _fx, tex_count, textures )
		End 

		' RasterizerState / DepthStencilState / BlendState
		SetStates(ent, surf)
	End 
	
End



Interface IEffectContainer
	Method Effect:XNAEffect() 
	Method Update(cam:TCamera, ent:TEntity, e:IEffectContainer)
	Method Bind(ent:TEntity, surf:TSurface, _red#,_green#,_blue#, _alpha#, _shine#, _fx, tex_count, textures:TTexture[] ) 
	Method Reset()
	Method SetLight(id, dirX#, dirY#, dirZ#, r#, g#, b#)
	Method SetLightEnable(id, enable?)
	Method Projection(fieldOfView#, aspect#, near#, far#)
	Method View(px#, py#, pz#, rx#, ry#, rz#, sx#, sy#, sz#) 
	Method World(px#, py#, pz#, rx#, ry#, rz#, sx#, sy#, sz#)
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
	
	Method Bind(ent:TEntity, surf:TSurface, 
		_red#,_green#,_blue#, _alpha#, _shine#, _fx#, tex_count, textures:TTexture[] ) Abstract
	
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
	
	Method Bind(ent:TEntity, surf:TSurface, _red#,_green#,_blue#, _alpha#, _shine#, _fx, tex_count, textures:TTexture[] ) 
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
	
	Method Projection(fieldOfView#, aspect#, near#, far#)
		_effect.Projection(fieldOfView, aspect, near, far)
	End
	
	Method View(px#, py#, pz#, rx#, ry#, rz#, sx#, sy#, sz#) 
		_updateView = False
		_effect.View(px, py, pz, rx, ry, rz, sx, sy, sz)
	End
	
	Method World(px#, py#, pz#, rx#, ry#, rz#, sx#, sy#, sz#)
		_updateWorld = False
		_effect.World(px, py, pz, rx, ry, rz, sx, sy, sz)
	End
	
	Method ProjectionMatrix:Void(mat:Float[])
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
		#rem
		If Not _updateLight Then
			_updateLight = True
			
			_effect.DirectionalLight0.Enabled = e.Effect().DirectionalLight0.Enabled
			_effect.DirectionalLight0.Direction(0,-1,-1) ' todo: implement getter in xna
			_effect.DirectionalLight0.DiffuseColor(1,1,1);
			
			_effect.DirectionalLight1.Enabled = e.Effect().DirectionalLight1.Enabled
			_effect.DirectionalLight1.Direction(0,-1,-1) ' todo: implement getter in xna
			_effect.DirectionalLight1.DiffuseColor(1,1,1);
			
			_effect.DirectionalLight2.Enabled = e.Effect().DirectionalLight2.Enabled
			_effect.DirectionalLight2.Direction(0,-1,-1) ' todo: implement getter in xna
			_effect.DirectionalLight2.DiffuseColor(1,1,1);
		End
		
		If ent And _updateWorld Then 
		
			_updateWorld = False
			
			' entity Transform
			'_effect.World(
					'ent.EntityX(True), ent.EntityY(True), ent.EntityZ(True), 
					'ent.EntityPitch(True), ent.EntityYaw(True), ent.EntityRoll(True),
					'ent.EntityScaleX(True), ent.EntityScaleY(True), ent.EntityScaleZ(True))
			
			_effect.WorldMatrix(ent.mat.ToArray())
		End 
		
		If cam And _updateView Then 
		
			_updateView = False
			
			' set view matrix
			'_effect.View(
				'cam.EntityX(True), cam.EntityY(True), cam.EntityZ(True), 
				'cam.EntityPitch(True), cam.EntityYaw(True), cam.EntityRoll(True), 
				'cam.EntityScaleX(True), cam.EntityScaleY(True), -cam.EntityScaleZ(True))
				
			_effect.ViewMatrix(cam.mod_mat.ToArray())
			
			' set projection
			'_effect.Projection(cam.fov_y, cam.aspect, cam.range_near , cam.range_far)
			_effect.ProjectionMatrix(cam.proj_mat.ToArray())
		
			'fog
			If cam.fog_mode>0
				_effect.FogEnabled = True
				_effect.FogStart = cam.fog_range_near
		        _effect.FogEnd = cam.fog_range_far
		        _effect.FogColor(cam.fog_r,cam.fog_g,cam.fog_b)
			Else
				_effect.FogEnabled = False 
			Endif
			
		End 
		#end
	End
End 





Class BasicEffect Extends EffectContainer

	Field _lastTexture:TTexture 
	
	Method New(effect:XNABasicEffect)
		_effect = effect
		
#if PREFER_PERPIXEL_LIGHNING="true"
		Local e:= XNABasicEffect(_effect)
		e.PreferPerPixelLighting = True
#End 

	End 
	
	Method Reset()
		Super.Reset()
		Local effect:= XNABasicEffect(_effect)
		effect.LightingEnabled = True
		effect.TextureEnabled = True 
	End
	
	Method Bind(ent:TEntity, surf:TSurface, _red#,_green#,_blue#, _alpha#, _shine#, _fx#, tex_count, textures:TTexture[]  )
	
		Local effect:= XNABasicEffect(_effect)
		
		' fx flag 1 - full bright ***todo*** disable all lights?
		If _fx&1 Then 
			effect.AmbientLightColor(1,1,1)
			effect.LightingEnabled = False
			effect.SpecularPower(0)
			'effect.Alpha = _alpha
		Else 
			effect.AmbientLightColor(TLight.ambient_red, TLight.ambient_green, TLight.ambient_blue)
			effect.LightingEnabled = True
			effect.SpecularPower(_shine)
		End 

		' fx flag 2 - vertex colors 
		If _fx&2
			effect.VertexColorEnabled = True 			
		Else
			effect.VertexColorEnabled = False 
			effect.DiffuseColor(_red,_green,_blue)
	        effect.Alpha = _alpha
			effect.SpecularPower(_shine)
		Endif
		
		' fx flag 4 - flatshaded

		' fx flag 8 - disable fog
		If _fx&8 Then 
			effect.FogEnabled = False 
		End 
		
		' turn off textures if no textures
		If tex_count = 0
			effect.TextureEnabled = False
		Else
			effect.TextureEnabled = True
			Local texture:= textures[0]
			' preserve texture states
			If texture And texture <> _lastTexture And XNARender._textures Then
				_lastTexture = texture
			 	effect.Texture = XNARender._textures.Get(texture.gltex[0])
				
			Endif 
		End
		
	End
End




Class EnvironmentMapEffect Extends EffectContainer
	
	Field _lastTexture:TTexture 
	Field _lastCubeTexture:TTexture 

	Method New(effect:XNAEnvironmentMapEffect)
		_effect = effect
	End 
	
	Method Bind(ent:TEntity, surf:TSurface, _red#,_green#,_blue#, _alpha#, _shine#, _fx#, tex_count, textures:TTexture[]  )
	
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
			Local tex_flags  = textures[0].flags
			Local texture := textures[0]
			
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
