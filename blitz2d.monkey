'Author Sascha Schmidt

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

	Field _ix:Float,_iy:Float, _jx:Float, _jy:Float
	Field _angle#=0
	Field _sx#=1
	Field _sy#=1
	Field _tx#= 0, _ty# = 0
	Field _r# = 1, _g# = 1, _b# = 1, _a# = 1
	Field _begin?
	Field w,h
	
	Field _mesh:TMesh 
	Field _dummy:TSprite
	
	Method New()
	
		' init transform
		UpdateTransform()
		w = TRender.width*0.5
		h = TRender.height*0.5

		' init mesh
		_dummy = CreateSptite()
		_mesh = CreateMesh(MAX_BATCH_SIZE)
		_mesh.name ="blitz2d"
		
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

	Method SetScale:Void(x#,y#)
		_sx = x; _sy = y
		UpdateTransform()
	End 
	
	Method SetRotation:Void(angle#)
		_angle = angle
		UpdateTransform()
	End 
	
	Method SetColor:Void(r#,g#,b#)
		_r = r
		_g = g
		_b = b
	End 
	
	Method SetAlpha:Void(a#)
		_a = a
	End 
	
	Method SetHandle:Void(x#,y#)
		_tx = x
		_ty = y
	End 
	
	Method Draw:Void(texture:TTexture,x:Float, y:Float)
		Draw(texture,x, y, texture.width, texture.height, _ix,_iy,_jx,_jy,0,0,1,1)
	End
	
	Method Draw:Void( texture:TTexture,x#,y#,srcX#,srcY#,srcWidth#,srcHeight#)
	
		Local u0# = srcX / Float(texture.width)
		Local v0# = srcY / Float(texture.height)
		Local u1# = u0 + srcWidth / Float(texture.width)
		Local v1# = v0 + srcHeight / Float(texture.height)
	
		Draw(texture,x, y,srcWidth, srcHeight, _ix,_iy,_jx,_jy ,u0,v0,u1,v1)
		
	End 
	
	Method Draw:Void( texture:TTexture,x#,y#,srcX#,srcY#,srcWidth#,srcHeight#,sx#, sy#, angle#)
	
		Local u0# = srcX / Float(texture.width)
		Local v0# = srcY / Float(texture.height)
		Local u1# = u0 + srcWidth / Float(texture.width)
		Local v1# = v0 + srcHeight / Float(texture.height)
	
		Local s# = Sin(angle)
		Local c# = Cos(angle)
		
		' push angle
		Local tmp = _angle
		_angle = angle
		
		Draw(texture,x, y,srcWidth, srcHeight, c * sx,-s * sy,s * sx,c * sy ,u0,v0,u1,v1)
		
		' pop angle
		_angle = tmp
		
	End 
	
	Method Draw:Void(texture:TTexture,x:Float, y:Float,  sx#, sy#, angle#)
		Local s# = Sin(angle)
		Local c# = Cos(angle)
		
		' push angle
		Local tmp = _angle
		_angle = angle
		
		Draw(texture,x, y, texture.width, texture.height, c * sx,-s * sy,s * sx,c * sy,0,0,1,1)
		
		' pop angle
		_angle = tmp
	End
	
	Method Draw:Void(texture:TTexture,x#, y#,width#,height#, ix#,iy#,jx#,jy#, u0# , v0#, u1# , v1# )

		'' check if spritearray is big enough
		UpdateSpriteArray()

		'' store sprite
		local sprite:SpriteInfo= _sprites[_spriteCnt]
		sprite.x = x
		sprite.y = y
		sprite.tx = _tx
		sprite.ty = _ty
		sprite.ix =  ix
		sprite.iy =  iy
		sprite.jx =  jx
		sprite.jy =  jy
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
	
	Method UpdateTransform:Void()
		local s# = Sin(_angle)
		local c# = Cos(_angle)
		_ix =  c * _sx
		_iy = -s * _sy
		_jx =  s * _sx
		_jy =  c * _sy
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
			RenderBatch(tex, index, _end )
		Endif
	End 
	
	Method RenderDummy:Void(tex:TTexture, index)
	
		Local sprite:= _sprites[index]

		Local tx# = sprite.width * 0.5 *  sprite.sx
		Local ty# = sprite.height * 0.5 * sprite.sy
		
		_dummy.EntityTexture(tex)
		_dummy.PositionEntity((sprite.x-w), (h-sprite.y), 1.99999)
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

			Local x:= sprite.x - DeviceWidth / 2
			Local y:= sprite.y - DeviceHeight / 2
			
			local x0:= - sprite.tx 
			local y0:= - sprite.ty;
			local x1:= x0 + sprite.width;
			local y1:= y0 + sprite.height;

			_surface.no_verts=_surface.no_verts+4

			Local vid:Int = _surface.no_verts-4
			Local v0 = vid
			
			_surface.vert_data.PokeVertCoords(vid,x0*sprite.ix+y0*sprite.iy + x,x0*sprite.jx+y0*sprite.jy + y,0)
			_surface.vert_data.PokeTexCoords(vid, sprite.u0,sprite.v0,0,0)		
			_surface.vert_data.PokeColor(vid,sprite.r, sprite.g, sprite.b, sprite.a)
			
			vid+= 1
			
			_surface.vert_data.PokeVertCoords(vid,x1*sprite.ix+y0*sprite.iy + x,x1*sprite.jx+y0*sprite.jy + y,0)
			_surface.vert_data.PokeTexCoords(vid, sprite.u1,sprite.v0,0,0)		
			_surface.vert_data.PokeColor(vid,sprite.r, sprite.g, sprite.b, sprite.a)
			
			vid+= 1
			
			_surface.vert_data.PokeVertCoords(vid,x1*sprite.ix+y1*sprite.iy + x,x1*sprite.jx+y1*sprite.jy + y,0)
			_surface.vert_data.PokeTexCoords(vid, sprite.u1,sprite.v1,0,0)		
			_surface.vert_data.PokeColor(vid,sprite.r, sprite.g, sprite.b, sprite.a)
			
			vid+= 1
			
			_surface.vert_data.PokeVertCoords(vid,x0*sprite.ix+y1*sprite.iy + x,x0*sprite.jx+y1*sprite.jy + y,0)
			_surface.vert_data.PokeTexCoords(vid, sprite.u0,sprite.v1,0,0)		
			_surface.vert_data.PokeColor(vid,sprite.r, sprite.g, sprite.b, sprite.a)
			
			_surface.no_tris+=2

		Next
		
		mesh.EntityTexture(tex)  
		TRender.camera2D.draw2D = 1
		TRender.render.Render(mesh,TRender.render.camera2D)
	End 
	
End


Global Batch:BBSpriteBatch

Function B2DBeginRender(blend = 1)
	if Not Batch Then 
		Batch = New BBSpriteBatch
	EndIf
	Batch.BeginRender(blend)
End 

Function B2DSetHandle:Void(x#,y#)
	Batch.SetHandle(x,y)
End

Function B2DDrawTexture( texture:TTexture,x#,y#,srcX,srcY,srcWidth,srcHeight)
	Batch.Draw( texture,x,y,srcX,srcY,srcWidth,srcHeight)
End 

Function B2DDrawTextureRect( image:TTexture,x#,y#,srcX,srcY,srcWidth,srcHeight,rotation#,scaleX#,scaleY#)
	Batch.Draw( texture,x,y,srcX,srcY,srcWidth,srcHeight, angle,sx, sy)
End 

Function B2DDrawTexture(tex:TTexture, x#, y#)
	Batch.Draw(tex,x,y)
End

Function B2DDrawTexture(tex:TTexture, x#, y#, rotation#,scaleX#,scaleY#)
	Batch.Draw(tex, x,y, scaleX, scaleY, rotation)
End 

Function B2DSetScale(sx#,sy#)
	Batch.SetScale(sx,sy)
End 

Function B2DSetColor(r#,g#,b#)
	Batch.SetColor( r / 255.0,  g/ 255.0, b/ 255.0)
End 

Function B2DSetAlpha(a#)
	Batch.SetAlpha(a)
End 

Function B2DSetRotation(angle#)
	Batch.SetRotation((angle + 360 ) Mod 360)
End 

Function B2DEndRender()
	Batch.EndRender()
End

#rem
Global b2dfont:TTexture

Function SetFont( font:Image,firstChar=32 )
	If Not b2dfont
		b2dfont=LoadTexture( "mojo_font.png",96,Image.XPadding )
		firstChar=32
	Endif
	context.font=font
	context.firstChar=firstChar
End

Function GetFont:Image()
	Return context.font
End

Function TextWidth#( text$ )
	If b2dfont Return text.Length * context.font.Width
End

Function TextHeight#()
	If context.font Return context.font.Height
End

Function FontHeight#()
	If context.font Return context.font.Height
End

Function DrawText( text$,x#,y#,xalign#=0,yalign#=0 )
#If CONFIG="debug"
	DebugRenderDevice
#End
	If Not context.font Return
	
	Local w=context.font.Width
	Local h=context.font.Height
	
	x-=Floor( w * text.Length * xalign )
	y-=Floor( h * yalign )
	
	For Local i=0 Until text.Length
		Local ch=text[i]-context.firstChar
		If ch>=0 And ch<context.font.Frames
			DrawImage context.font,x+i*w,y,ch
		Endif
	Next

End
#end 
