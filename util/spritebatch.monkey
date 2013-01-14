' Author Sascha Schmidt

Import minib3d 

Private 

Class SpriteInfo
	Field textrue:TTexture 
	Field r:Float = 1.0,g:Float = 1.0,b:Float = 1.0,a:Float = 1.0
	Field tx:Float, ty:Float
	Field x:Float,y:Float
	Field ix:Float,iy:Float, jx:Float, jy:Float
	Field angle#, sx#,sy#
	Field u0#, v0#, u1#, v1#
	Field width, height
End 

Public 

Class BBSpriteBatch
	
	Const MAX_BATCH_SIZE = 2048
	Const MIN_BATCH_SIZE = 16
	
	Field _spriteCnt:Int
	Field _sprites:SpriteInfo[MAX_BATCH_SIZE]

	Field _ix# = 1,_iy#, _jx#, _jy# = 1
	Field _angle#=0
	Field _sx#=1
	Field _sy#=1
	Field _tx#= 0, _ty# = 0
	Field _r# = 1, _g# = 1, _b# = 1, _a# = 1
	Field _begin?
	Field _w,_h
	
	Field _mesh:TMesh 
	Field _dummy:TSprite
	
	Field matrixStack:=New Float[6*32],matrixSp
	Field IsTransformed?
	Field matDirty
	
	Method New()
	
		' init transform
		_w = TRender.width*0.5
		_h = TRender.height*0.5

		' init mesh
		_dummy = CreateSptite()
		_mesh = CreateMesh(MAX_BATCH_SIZE)
		_mesh.name ="spritebatch"
		
		' init sprite array
		For Local i = 0 until MAX_BATCH_SIZE
			_sprites[i] = new SpriteInfo 
		Next
		
		' init camera
		TRender.camera2D.CameraViewport(0,0,TRender.width,TRender.height)
		TRender.camera2D.SetPixelCamera
		TRender.camera2D.CameraClsMode(False,True)
		
	End
	
	Method BeginRender:Void(blend = 1)

		_dummy.brush.blend = blend
		_mesh.brush.blend = blend
		
		TRender.render.Reset()
		TRender.render.SetDrawShader()
		TRender.render.UpdateCamera(TRender.render.camera2D)
		TRender.alpha_pass = 1
		
		_mesh.Update(TRender.camera2D ) 
		
		_begin = True 
		_spriteCnt = 0
		
	End
	
	Method EndRender:Void()
	
		 FlushBatch()
		 
		 TShader.DefaultShader()
		 TRender.render.Reset()
		 
		 _begin = False 
	End
	
	
	Method RenderBatch(blend = 1)
	
		_dummy.brush.blend = blend
		_mesh.brush.blend = blend
		_mesh.Update(TRender.camera2D ) 
		
		TRender.render.Reset()
		TRender.render.SetDrawShader()
		TRender.render.UpdateCamera(TRender.render.camera2D)
		TRender.alpha_pass = 1

		TRender.camera2D.draw2D = 1
		TRender.render.Render(_mesh,TRender.render.camera2D)
	 
		TShader.DefaultShader()
		TRender.render.Reset()
		 
	End 
	
	Method SetColor:Void(r#,g#,b#)
		_r = r
		_g = g
		_b = b
	End 
	
	Method SetAlpha:Void(a#)
		_a = a
	End 
	
	Method PushMatrix()
		Local sp=matrixSp
		matrixStack[sp+0]=_ix
		matrixStack[sp+1]=_iy
		matrixStack[sp+2]=_jx
		matrixStack[sp+3]=_jy
		matrixStack[sp+4]=_tx
		matrixStack[sp+5]=_ty
		matrixSp=sp+6
	End 
	
	Method PopMatrix()
		Local sp=matrixSp-6
		SetMatrix matrixStack[sp+0],matrixStack[sp+1],matrixStack[sp+2],matrixStack[sp+3],matrixStack[sp+4],matrixStack[sp+5]
		matrixSp=sp
	End 
	
	Method SetMatrix(ix#,iy#,jx#,jy#,tx#,ty#)
		_ix = ix
		_iy = iy
		_jx = jx
		_jy = jy
		_tx = tx
		_ty = ty
		IsTransformed=(ix<>1 Or iy<>0 Or jx<>0 Or jy<>1 Or tx<>0 Or ty<>0)
	End 
	
	Method Transform(ix#,iy#,jx#,jy#,tx#,ty# )
		Local ix2#=ix*_ix+iy*_jx
		Local iy2#=ix*_iy+iy*_jy
		Local jx2#=jx*_ix+jy*_jx
		Local jy2#=jx*_iy+jy*_jy
		Local tx2#=tx*_ix+ty*_jx+_tx
		Local ty2#=tx*_iy+ty*_jy+_ty
		SetMatrix ix2,iy2,jx2,jy2,tx2,ty2
	End 
	
	Method Draw:Void(texture:TTexture,x:Float, y:Float)

		Draw2(texture,x, y, texture.width, texture.height, 0,0,1,1 )
	
	End
	
	Method Draw:Void( texture:TTexture,x#,y#,srcX#,srcY#,srcWidth#,srcHeight#)
	
		Draw(texture,x, y,texture.width, texture.height,srcX,srcY,srcWidth,srcHeight)
		
	End 
	
	Method Draw:Void( texture:TTexture,x#,y#,width#, height#,srcX#,srcY#,srcWidth#,srcHeight#)
	
		Local u0# = srcX / Float(texture.width)
		Local v0# = srcY / Float(texture.height)
		Local u1# = u0 + srcWidth / Float(texture.width)
		Local v1# = v0 + srcHeight / Float(texture.height)
		
		Draw2(texture,x, y,width, height, u0,v0,u1,v1)
		
	End 
	
	Method Draw2:Void(texture:TTexture,x#, y#,width#,height#, u0# , v0#, u1# , v1# )
	
		'' check if spritearray is big enough
		UpdateSpriteArray()

		'' store sprite
		local sprite:SpriteInfo= _sprites[_spriteCnt]
		sprite.x = x
		sprite.y = y
		sprite.tx = _tx
		sprite.ty = _ty
		sprite.ix = _ix
		sprite.iy = _iy
		sprite.jx = _jx
		sprite.jy = _jy
		sprite.textrue = texture 
		sprite.angle = _angle
		sprite.r = _r
		sprite.g = _g
		sprite.b = _b
		sprite.a = _a
		sprite.sx = _sx
		sprite.sy = _sy
		sprite.u0 = u0
		sprite.v0 = v0
		sprite.u1 = u1
		sprite.v1 = v1
		sprite.width = width
		sprite.height = height
		
		_spriteCnt+=1
	End 
	
Private 

	Method CreateMesh:TMesh(size)
		
		Local mesh:= New TMesh
		mesh.is_update = True 
		mesh.ScaleEntity (1,-1,1)
		mesh.PositionEntity(0,0, 1.99999)
		mesh.EntityFX( 1+2+8+16+32+64)
		mesh.EntityBlend(1)
	
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

		If mesh.Alpha() Then mesh.alpha_order = 1
		
		Return mesh
	End
	
	Method CreateSptite:TSprite()
	
		Local sprite:= New TSprite 
		sprite.UpdateMat(True)
		sprite.EntityFX( 1+4+8+16+32+64)
		sprite.EntityBlend(1 )

		Local surf:=sprite.CreateSurface()
		surf.vert_data=VertexDataBuffer.Create(4)		
		surf.vert_array_size=5
		surf.tris=ShortBuffer.Create(12)
		surf.tri_array_size=5
		surf.AddVertex(-1,-1,0, 0,1)
		surf.AddVertex(-1, 1,0, 0,0)
		surf.AddVertex( 1, 1,0, 1,0)
		surf.AddVertex( 1,-1,0, 1,1)
		surf.AddTriangle(0,1,2)
		surf.AddTriangle(0,2,3)
		
		If sprite.Alpha() Then sprite.alpha_order = 1
		
		Return sprite
	End 
	
	Method UpdateSpriteArray:Void()
		
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
	
	Method FlushBatch:Void()
		
		if Not _spriteCnt Then Return 

		local batchTexture:TTexture  = Null 
		local batchStart = 0
		Local cnt = 0
		Local count=0
		
		For Local i = 0 until _spriteCnt
		
			local texture:= _sprites[i].textrue 
		
			count= i - batchStart
			if texture <> batchTexture Or count >= MAX_BATCH_SIZE 
			
				if i > batchStart Then 
				
					Render( batchTexture, batchStart, i, count )
					
				End 
				
				batchTexture = texture 
				batchStart  = i
			End 
			
		Next

		Render( batchTexture, batchStart, _spriteCnt, count )

	End

	Method Render( tex:TTexture, index, _end , count)

		#rem
		If count < MIN_BATCH_SIZE Then 
			
			For Local j = index Until _end
				Local sprite:= _sprites[j]
				
				'' uv scaling makes no sense, since not supported in xna.
				'' so batch or maybe internal xna.SpriteBatch if TARGET="xna" is better.
				If sprite.u0 <> 0 Or sprite.v0 <> 0 Or sprite.u1 <> 1 Or sprite.u1 <> 1 Then 
					RenderBatch(tex, j, _end )
					Exit 
				else 
					RenderDummy(tex, j )
				End 
				
			End 
		Else
		#end
			RenderBatch(tex, index, _end )
		'Endif
	End 
	
	Method RenderDummy:Void(tex:TTexture, index)
	
		Local sprite:= _sprites[index]

		Local tx# = sprite.width * 0.5 *  sprite.sx
		Local ty# = sprite.height * 0.5 * sprite.sy
		
		_dummy.EntityTexture(tex)
		_dummy.PositionEntity((sprite.x-_w), (_h-sprite.y), 1.99999)
		_dummy.angle = sprite.angle
		_dummy.Update(TRender.camera2D )
		_dummy.brush.red = sprite.r
		_dummy.brush.green = sprite.g
		_dummy.brush.blue = sprite.b
		_dummy.brush.alpha = sprite.a
		_dummy.mat_sp.Translate(tx-sprite.tx,sprite.ty-ty,0 )
		_dummy.mat_sp.Scale( tx, ty, 1.0)
 
 		TRender.camera2D.draw2D = 0
		TRender.render.Render(_dummy,TRender.camera2D)	
	End 
	
	Method RenderBatch:Void(tex:TTexture, start, _end  )
	
		Local _surface:=_mesh.GetSurface(1)
		Local mesh:=_mesh 
	
		_surface.reset_vbo = -1
		_surface.no_tris = 0
		_surface.no_verts = 0
				
			 
			
		For Local index = start until _end 
		
			Local sprite:SpriteInfo = _sprites[index]

			Local x:= sprite.x 
			Local y:= sprite.y 
			
			Local w# = sprite.width
			Local h# = sprite.height
			Local x0#=x,x1#=x+w,x2#=x+w,x3#=x;
			Local y0#=y,y1#=y,y2#=y+h,y3#=y+h;
			
			
			Local tx0#=x0,tx1#=x1,tx2#=x2,tx3#=x3;
			x0=tx0 * sprite.ix + y0 * sprite.jx + sprite.tx-_w;
			y0=tx0 * sprite.iy + y0 * sprite.jy + sprite.ty-_h;
			x1=tx1 * sprite.ix + y1 * sprite.jx + sprite.tx-_w;
			y1=tx1 * sprite.iy + y1 * sprite.jy + sprite.ty-_h;
			x2=tx2 * sprite.ix + y2 * sprite.jx + sprite.tx-_w;
			y2=tx2 * sprite.iy + y2 * sprite.jy + sprite.ty-_h;
			x3=tx3 * sprite.ix + y3 * sprite.jx + sprite.tx-_w;
			y3=tx3 * sprite.iy + y3 * sprite.jy + sprite.ty-_h;
			
			_surface.no_verts=_surface.no_verts+4

			Local vid:Int = _surface.no_verts-4
			Local v0 = vid
			
			_surface.vert_data.PokeVertCoords(vid,x0,y0,0)
			_surface.vert_data.PokeTexCoords(vid, sprite.u0,sprite.v0,0,0)		
			_surface.vert_data.PokeColor(vid,sprite.r, sprite.g, sprite.b, sprite.a)
			
			vid+= 1
			
			_surface.vert_data.PokeVertCoords(vid,x1,y1,0)
			_surface.vert_data.PokeTexCoords(vid, sprite.u1,sprite.v0,0,0)		
			_surface.vert_data.PokeColor(vid,sprite.r, sprite.g, sprite.b, sprite.a)
			
			vid+= 1
			
			_surface.vert_data.PokeVertCoords(vid,x2,y2,0)
			_surface.vert_data.PokeTexCoords(vid, sprite.u1,sprite.v1,0,0)		
			_surface.vert_data.PokeColor(vid,sprite.r, sprite.g, sprite.b, sprite.a)
			
			vid+= 1
			
			_surface.vert_data.PokeVertCoords(vid,x3,y3,0)
			_surface.vert_data.PokeTexCoords(vid, sprite.u0,sprite.v1,0,0)		
			_surface.vert_data.PokeColor(vid,sprite.r, sprite.g, sprite.b, sprite.a)
			
			_surface.no_tris+=2

		Next
		
		mesh.EntityTexture(tex)  
		TRender.camera2D.draw2D = 1
		TRender.render.Render(mesh,TRender.render.camera2D)
	End 
	
End