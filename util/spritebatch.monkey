Import minib3d

Public 

Class BBSpriteBatch

	Const MAX_BATCH_SIZE = 2048
	Const MIN_BATCH_SIZE = 16

	Field _spriteCnt:Int
	Field _sprites:SpriteInfo[MAX_BATCH_SIZE]

	Field _ix# = 1,_iy#, _jx#, _jy# = 1,_tx#= 0, _ty# = 0
	Field _r# = 1, _g# = 1, _b# = 1, _a# = 1
	Field _begin?
	Field _mesh:TMesh 
	Field _surface:TSurface

	Field matrixStack:=New Float[6*32],matrixSp
	Field tformed?
	Field matDirty
	Field primTex:TTexture 
	
	Method New()
	
		' init mesh
		_mesh = CreateMesh(MAX_BATCH_SIZE)
		_surface = _mesh.GetSurface(1)
		_mesh.name ="spritebatch"
		
		' init camera
		TRender.camera2D.CameraViewport(0,0,TRender.width,TRender.height)
		TRender.camera2D.SetPixelCamera
		TRender.camera2D.CameraClsMode(False,True)
		TRender.camera2D.draw2D = 1
		
	End
	
	Method BeginRender:Void(blend = 1)

		TRender.render.Reset()
		TRender.render.SetDrawShader()
		TRender.render.UpdateCamera(TRender.render.camera2D)
		TRender.alpha_pass = 1
		
		_mesh.brush.blend = blend
		_mesh.Update(TRender.camera2D ) 

		_begin = True 
		
		ClearBatch()
		
	End

	Method EndRender:Void()

		RenderBatch(primTex)
		
		TShader.DefaultShader()
		TRender.render.Reset()

		_begin = False 
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
		tformed=(ix<>1 Or iy<>0 Or jx<>0 Or jy<>1 Or tx<>0 Or ty<>0)
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

		If primTex <> texture Or _spriteCnt = MAX_BATCH_SIZE Then 
		
			RenderBatch(primTex)
			ClearBatch()
			primTex = texture
			
		End 

		Local w# = width
		Local h# = height
		Local x0#=x,x1#=x+w,x2#=x+w,x3#=x
		Local y0#=y,y1#=y,y2#=y+h,y3#=y+h
		Local tx0#=x0,tx1#=x1,tx2#=x2,tx3#=x3
		
		If tformed Then 
			x0=tx0 * _ix + y0 * _jx + _tx
			y0=tx0 * _iy + y0 * _jy + _ty
			x1=tx1 * _ix + y1 * _jx + _tx
			y1=tx1 * _iy + y1 * _jy + _ty
			x2=tx2 * _ix + y2 * _jx + _tx
			y2=tx2 * _iy + y2 * _jy + _ty
			x3=tx3 * _ix + y3 * _jx + _tx
			y3=tx3 * _iy + y3 * _jy + _ty
		End 

		Local vid:Int = _surface.no_verts
		
		_surface.vert_data.PokeVertCoords(vid,x0,y0,0)
		_surface.vert_data.PokeTexCoords(vid, u0,v0,0,0)		
		_surface.vert_data.PokeColor(vid,_r, _g, _b, _a)

		vid+= 1

		_surface.vert_data.PokeVertCoords(vid,x1,y1,0)
		_surface.vert_data.PokeTexCoords(vid, u1,v0,0,0)		
		_surface.vert_data.PokeColor(vid, _r, _g, _b, _a)

		vid+= 1

		_surface.vert_data.PokeVertCoords(vid,x2,y2,0)
		_surface.vert_data.PokeTexCoords(vid, u1,v1,0,0)		
		_surface.vert_data.PokeColor(vid, _r, _g, _b, _a)

		vid+= 1

		_surface.vert_data.PokeVertCoords(vid,x3,y3,0)
		_surface.vert_data.PokeTexCoords(vid, u0,v1,0,0)		
		_surface.vert_data.PokeColor(vid, _r, _g, _b, _a)

		_surface.no_verts+=4
		_surface.no_tris+=2
		_spriteCnt+=1

	End 
	
	Method DrawLine:Void(x0#, y0#, x1#, y1#, linewidth# = 1)
	
		If primTex <> Null Or _spriteCnt = MAX_BATCH_SIZE Then 
		
			RenderBatch(primTex)
			ClearBatch()
			primTex = Null
			
		End

		Local dx# = (x1-x0)
		Local dy# = (y1-y0)
		Local length# = Sqrt(dx*dx+dy*dy)
		Local angle# = (ATan2(dy, dx) + 360.0) Mod 360.0
		local s# = Sin(angle)
		Local c# = Cos(angle)
		
		Local w# = length
		Local h# = linewidth
		Local x# = 0
		Local y# = 0
		Local tx# = x0
		Local ty# = y0
		
		x0=x;x1=x+w;y0=y;y1=y
		Local x2#=x+w,x3#=x
		Local y2#=y+h,y3#=y+h
		Local tx0#=x0,tx1#=x1,tx2#=x2,tx3#=x3
		
		x0=tx0 * c + y0 * -s + tx
		y0=tx0 * s + y0 * c + ty
		x1=tx1 * c + y1 * -s + tx 
		y1=tx1 * s + y1 * c + ty 
		x2=tx2 * c + y2 * -s + tx
		y2=tx2 * s + y2 * c + ty 
		x3=tx3 * c + y3 * -s + tx
		y3=tx3 * s + y3 * c + ty 
	
		If tformed Then 
		
			tx0=x0;tx1=x1;tx2=x2;tx3=x3
			
			x0=tx0 * _ix + y0 * _jx + _tx
			y0=tx0 * _iy + y0 * _jy + _ty
			x1=tx1 * _ix + y1 * _jx + _tx
			y1=tx1 * _iy + y1 * _jy + _ty
			x2=tx2 * _ix + y2 * _jx + _tx
			y2=tx2 * _iy + y2 * _jy + _ty
			x3=tx3 * _ix + y3 * _jx + _tx
			y3=tx3 * _iy + y3 * _jy + _ty
			
		End 

		Local vid:Int = _surface.no_verts
		
		_surface.vert_data.PokeVertCoords(vid,x0,y0,0)	
		_surface.vert_data.PokeColor(vid,_r, _g, _b, _a); vid+= 1
		_surface.vert_data.PokeVertCoords(vid,x1,y1,0)		
		_surface.vert_data.PokeColor(vid, _r, _g, _b, _a); vid+= 1
		_surface.vert_data.PokeVertCoords(vid,x2,y2,0)		
		_surface.vert_data.PokeColor(vid, _r, _g, _b, _a);vid+= 1
		_surface.vert_data.PokeVertCoords(vid,x3,y3,0)
		_surface.vert_data.PokeColor(vid, _r, _g, _b, _a)

		_surface.no_verts+=4
		_surface.no_tris+=2
		_spriteCnt+=1
		
	End 
	
	Method DrawOval(x#,y#,w#,h#)
	
		Local xr#=w/2.0
		Local yr#=h/2.0
	
		local segs;
		If tformed Then
			Local dx_x#=xr * _ix
			Local dx_y#=xr * _iy
			Local dx#=Sqrt( dx_x*dx_x+dx_y*dx_y )
			Local dy_x#=yr * _jx
			Local dy_y#=yr * _jy
			Local dy#=Sqrt( dy_x*dy_x+dy_y*dy_y )
			segs=int( dx+dy )
		else
			segs=int( Abs( xr )+Abs( yr ) );
		End 
		
		if segs<12 then
			segs=12
		else if segs>MAX_BATCH_SIZE then
			segs=MAX_BATCH_SIZE
		else
			segs&=~3;
		End 
		
		x+=xr;
		y+=yr;

		RenderBatch(primTex)
		ClearBatch()
		
		For Local i=0 Until segs

			Local sq# = 360.0 / segs
			
			Local x0#=x
			Local y0#=y
					
			Local th#=i * sq;
			Local x1#=x+Cos( th ) * xr;
			Local y1#=y-Sin( th ) * yr;
			
			th=(i+1) * sq;
			Local x2#=x+Cos( th ) * xr;
			Local y2#=y-Sin( th) * yr;
			
			th=(i+2) * sq;
			Local x3#=x+Cos( th ) * xr;
			Local y3#=y-Sin( th) * yr;
			
			Local tx0#=x0,tx1#=x1,tx2#=x2,tx3#=x3;
			
			If tformed 
				x0=tx0 * _ix + y0 * _jx + _tx;
				y0=tx0 * _iy + y0 * _jy + _ty;
				x1=tx1 * _ix + y1 * _jx + _tx;
				y1=tx1 * _iy + y1 * _jy + _ty;
				x2=tx2 * _ix + y2 * _jx + _tx;
				y2=tx2 * _iy + y2 * _jy + _ty;
				x3=tx3 * _ix + y3 * _jx + _tx;
				y3=tx3 * _iy + y3 * _jy + _ty;
			End  

			_surface.vert_data.PokeVertCoords(_surface.no_verts,x0,y0,0)	
			_surface.vert_data.PokeColor(_surface.no_verts,_r, _g, _b, 1)
			_surface.no_verts+=1
			
			_surface.vert_data.PokeVertCoords(_surface.no_verts,x1,y1,0)	
			_surface.vert_data.PokeColor(_surface.no_verts,_r, _g, _b, 1)
			_surface.no_verts+=1
			
			_surface.vert_data.PokeVertCoords(_surface.no_verts,x2,y2,0)	
			_surface.vert_data.PokeColor(_surface.no_verts,_r, _g, _b, 1)
			_surface.no_verts+=1
			
			_surface.vert_data.PokeVertCoords(_surface.no_verts,x3,y3,0)	
			_surface.vert_data.PokeColor(_surface.no_verts,_r, _g, _b, 1)
			_surface.no_verts+=1
			
			_surface.no_tris+=2
		End 
		
		'' set texture
		_mesh.brush.tex[0]=null
		_mesh.brush.no_texs=0
		
		' render
		TRender.camera2D.draw2D = 1
		TRender.render.Render(_mesh,TRender.render.camera2D)
		
		ClearBatch()
	End 
Private 

	Method CreateMesh:TMesh(size)

		Local mesh:= New TMesh
		mesh.is_update = True 
		mesh.ScaleEntity (1,-1,1)
		mesh.PositionEntity(- TRender.width*0.5,TRender.height*0.5, 1.99999)
		mesh.EntityFX( 1+2+8+16+32+64)
		mesh.EntityBlend(1)
	
		local surf:= mesh.CreateSurface()
		surf.vert_data= CopyDataBuffer(surf.vert_data, VertexDataBuffer.Create(size*4) )
		surf.vert_array_size = size
		surf.no_verts = 0
			
		surf.tris =CopyShortBuffer(surf.tris, ShortBuffer.Create(size*2*3) )
		surf.tri_array_size = size*2*3
		surf.no_tris = 0
	
		For Local i = 0 until size
			Local v0 = i*4
			surf.AddTriangle(0+v0,1+v0,2+v0)
			surf.AddTriangle(0+v0,2+v0,3+v0)
		Next
		surf.no_tris = 0
		
		' Alpha() needs to be called after .CreateSurface!
		If mesh.Alpha() Then mesh.alpha_order = 1

		Return mesh
	End

	Method ClearBatch:Void()
		_surface.reset_vbo = -1
		_surface.no_tris = 0
		_surface.no_verts = 0
		_spriteCnt = 0
	End
	
	Method RenderBatch:Void(tex:TTexture)

		If _spriteCnt = 0 Then Return 
		
		'' set texture
		_mesh.brush.tex[0]=tex
		If tex Then 
			_mesh.brush.no_texs=1
		Else
			_mesh.brush.no_texs=0
		End 
		
		' render
		TRender.camera2D.draw2D = 1
		TRender.render.Render(_mesh,TRender.render.camera2D)
	End 

End


