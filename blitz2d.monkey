'Author Sascha Schmidt

Import minib3d

Class Blitz2D 

Private 

	Const DEG_TO_RAD# = 0.0174532925
	
	Global _r:Float = 1, _g:Float = 1,_b:Float = 1, _a:Float = 1
	Global _sx:Float = 1, _sy:Float = 1
	Global _angle:Float = 0
	Global _hx:Float = 0, _hy:Float = 0
	Global _batch:BBSpriteBatch
	Global _tx#, _ty#
	
Public 

	Function BeginRender()
		if Not _batch Then 
			_batch = New BBSpriteBatch
		EndIf
		_batch.BeginBatch()
	End 
	
	Function SetHandle:Void(x#,y#)
		_tx = x
		_ty = y
	End
	
	Function DrawTexture(tex:TTexture, x#, y#)
		_batch.Draw(tex,x,y,_sx,_sy, _angle,_tx,_ty)
	End
	
	Function SetScale(sx#,sy#)
		_sx = sx; _sy = sy;
	End 
	
	Function SetColor(r#,g#,b#)
		_r = r / 255.0; _g = g/ 255.0; _b = b/ 255.0;
	End 
	
	Function SetAlpha(a#)
		_a = a;
	End 
	
	Function SetRotation(angle#)
		_angle = ((angle + 360 ) Mod 360) 
	End 
	
	Function EndRender()
		_batch.EndBatch()
	End
	
End 



Class SpriteInfo
	Field textrue:TTexture 
	Field r:Float = 1.0,g:Float = 1.0,b:Float = 1.0,a:Float = 1.0
	Field tx:Float, ty:Float
	Field x:Float,y:Float
	Field ix:Float,iy:Float, jx:Float, jy:Float
End 

Class BBSpriteBatch
	
	Const MAX_BATCH_SIZE = 2048
	Const MIN_BATCH_SIZE = 128
	
	Field _spriteCnt:int
	Field _mesh:TMesh 
	Field _sprites:SpriteInfo[MAX_BATCH_SIZE]
	Field _defaultBrush:TBrush 
	
	Field _ix:Float,_iy:Float, _jx:Float, _jy:Float
	Field _angle#=-999999999
	Field _sx#=-999999999
	Field _sy#=-999999999
		
	Field _begin?
	
	Method new()
	
		'' create mesh 
		
		_mesh = CreateMesh(MAX_BATCH_SIZE)

		'' create default brush
		
		_defaultBrush = CreateBrush()
		_defaultBrush.BrushFX( 1 | 2| 4 | 8 | 16 | 32 |64)
		
		' init sprite array
		For Local i = 0 until MAX_BATCH_SIZE
			_sprites[i] = new SpriteInfo 
		Next
		
		' camera
		
		TRender.camera2D.CameraViewport(0,0,TRender.width,TRender.height)
		TRender.camera2D.SetPixelCamera
		TRender.camera2D.CameraClsMode(False,True)
		TRender.camera2D.draw2D = 1
		
	End
	
	Method CreateMesh:TMesh(size)
		
		Local mesh:= new TMesh 
		mesh.is_update = True 
		mesh.ScaleEntity (1,-1,1)
		mesh.PositionEntity(0,0, 1.99999)
		
		local surf:= mesh.CreateSurface()
		surf.vert_data= CopyDataBuffer(surf.vert_data, VertexDataBuffer.Create(size*4) )
		surf.vert_array_size = size
		
		surf.tris =CopyShortBuffer(surf.tris, ShortBuffer.Create(size*2*3) )
		surf.tri_array_size = size*2*3
		
		For Local i = 0 until size
			Local v0 = i*4
			surf.AddTriangle(0+v0,1+v0,2+v0)
			surf.AddTriangle(0+v0,2+v0,3+v0)
		Next
		
		Return mesh
	End


	Method BeginBatch(brush:TBrush = Null)
	
		if _begin Then 
			Error "Cannot nest Begin calls"
		EndIf

		
		TRender.render.Reset()
		TRender.render.SetDrawShader()
		TRender.render.UpdateCamera(TRender.render.camera2D)
		
		if brush Then 
			_mesh.PaintEntityGlobal(brush)
		Else
			_mesh.PaintEntityGlobal(_defaultBrush)
		EndIf

		_mesh.Update(TRender.camera2D ) 
		
		_begin = True 
		
	End
	
	Method EndBatch()
	
		if Not _begin Then 
			Error "Begin must be called before End"
		EndIf
		
		 FlushBatch()
		 
		 TShader.DefaultShader()
		 TRender.render.Reset()
		 
		 _begin = False 
	End

	Method SetTransform(sx#,sy#, angle#)
	
		if Not(_sx = sx And sy = _sy And _angle = angle) Then 
			
			local s# = Sin(angle)
			local c# = Cos(angle)
			
			_angle = angle
			_sx = sx
			_sy = sy
			_ix = c * _sx
			_iy = -s* _sy
			_jx = s* _sx
			_jy = c* _sy
			
		EndIf
		
	End
	
	Method Draw(texture:TTexture,x:Float, y:Float)
		
		Draw(texture,x, y,  _sx, _sy, _angle)
		
	End
	
	Method Draw(texture:TTexture,x:Float, y:Float,  sx#, sy#, angle#, tx# = 0, ty#= 0)
	
		if Not _begin Then 
			Error "Begin must be called before End"
		EndIf

		SetTransform(sx,sy,angle)
		
		UpdateSpriteArray()
		
		local sprite:SpriteInfo= _sprites[_spriteCnt]
		sprite.x = x
		sprite.y = y
		sprite.tx = tx
		sprite.ty = ty
		sprite.ix = _ix
		sprite.iy = _iy
		sprite.jx = _jx
		sprite.jy = _jy
		sprite.textrue = texture 
		
		_spriteCnt+=1
	End

Private 

	Method UpdateSpriteArray()
		
		if _spriteCnt >= _sprites.Length Then 
		
				Local oldSize = _sprites.Length
				Local newSize = oldSize*2
	
				Local newSpriteArray:= new SpriteInfo[newSize]
				
				For Local i = 0 until oldSize
					newSpriteArray[i] = _sprites[i]
				End 
				
				For Local i = _spriteCnt until newSize
					newSpriteArray[i] = new SpriteInfo
				End 
				
				_sprites = newSpriteArray
		EndIf
		
	End
	
	Method FlushBatch()
		
		if Not _spriteCnt Then Return 

		local batchTexture:TTexture  = Null 
		local batchStart = 0
		Local cnt = 0
	
	
		For Local i = 0 until _spriteCnt
		
			local texture:= _sprites[i].textrue 
		
			Local count= i - batchStart
			if texture <> batchTexture Or count >= MAX_BATCH_SIZE 
			

				if i > batchStart Then 
				
				    if count < MIN_BATCH_SIZE Then 
						For Local j = batchStart until i
							RenderBatch( batchTexture  , j, j+1 )
						End 
					Else
						RenderBatch(batchTexture, batchStart, i )
					EndIf

				End 
				
				batchTexture = texture 
				batchStart  = i
				
			End 
			
		Next
	
		RenderBatch( batchTexture , batchStart, _spriteCnt )
		
		_spriteCnt = 0
		
	End

	Method RenderBatch(tex:TTexture, start, _end  )
	
		Local _surface:=_mesh.GetSurface(1)
		Local mesh:=_mesh 
	
		_surface.reset_vbo = -1
		_surface.no_tris = 0
		_surface.no_verts = 0
				
		For Local index = start until _end 
		
			Local sprite:SpriteInfo = _sprites[index]

			Local x:= sprite.x - DeviceWidth / 2
			Local y:= sprite.y - DeviceHeight / 2
			
			local x0:= - sprite.tx 
			local y0:= - sprite.ty;
			local x1:= x0 + tex.width;
			local y1:= y0 + tex.height;

			_surface.no_verts=_surface.no_verts+4

			Local vid:Int = _surface.no_verts-4
			Local v0 = vid
			
			_surface.vert_data.PokeVertCoords(vid,x0*sprite.ix+y0*sprite.iy + x,x0*sprite.jx+y0*sprite.jy + y,0)
			_surface.vert_data.PokeTexCoords(vid, 0,0,0,0)		
			_surface.vert_data.PokeColor(vid,sprite.r, sprite.g, sprite.b, sprite.a)
			
			vid+= 1
			
			_surface.vert_data.PokeVertCoords(vid,x1*sprite.ix+y0*sprite.iy + x,x1*sprite.jx+y0*sprite.jy + y,0)
			_surface.vert_data.PokeTexCoords(vid, 1,0,0,0)		
			_surface.vert_data.PokeColor(vid,sprite.r, sprite.g, sprite.b, sprite.a)
			
			vid+= 1
			
			_surface.vert_data.PokeVertCoords(vid,x1*sprite.ix+y1*sprite.iy + x,x1*sprite.jx+y1*sprite.jy + y,0)
			_surface.vert_data.PokeTexCoords(vid, 1,1,0,0)		
			_surface.vert_data.PokeColor(vid,sprite.r, sprite.g, sprite.b, sprite.a)
			
			vid+= 1
			
			_surface.vert_data.PokeVertCoords(vid,x0*sprite.ix+y1*sprite.iy + x,x0*sprite.jx+y1*sprite.jy + y,0)
			_surface.vert_data.PokeTexCoords(vid, 0,1,0,0)		
			_surface.vert_data.PokeColor(vid,sprite.r, sprite.g, sprite.b, sprite.a)
			
			_surface.no_tris+=2

		Next
		 
		mesh.EntityTexture(tex, 0,0)
		TRender.render.Render(mesh,TRender.render.camera2D)
		
	End 
	
End