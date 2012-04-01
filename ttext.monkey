''
''
'' 3d text for minib3d + monkey
Import tsprite
Import minib3d
Import tsurface


Class TText Extends TSprite

	
	Field cam:TCamera
	Field mode:Bool = True ''true = 2d, false = 3d
	Field text$="" , old_text$=""
	Field length:Int
	Field font_file:String
	Field char_uvwidth:Float
	Field surf:TSurface
	Field char_pixels:Int
	Field pixel_ratio:Float
	Field padding:Int
	Field char_rows:Int
	
	Global mask_color:Int = $ffffff
	
	Field use3D:Bool '' is this text 2d or 3d
	
	Function CreateText3D:TText(camx:TCamera, str$ = "", font$="", num_chars:Int = 96, c_pixels:Int=9, pad:Int = 0 )
		Local tt:TText = CreateText(camx,str,font,num_chars,c_pixels,pad)
		tt.mode = False
		Return tt
	End
	
	Function CreateText2D:TText(camx:TCamera, str$ = "", font$="", num_chars:Int = 96, c_pixels:Int=9, pad:Int = 0 )
		Local tt:TText = CreateText(camx,str,font,num_chars,c_pixels,pad)
		tt.mode = True
		Return tt
	End
	
	Function CreateText:TText(camx:TCamera, str$ = "", font$="", num_chars:Int = 96, c_pixels:Int=9, pad:Int = 0 )
		
		Local tt:TText = New TText
		
		tt.entity_link = entity_list.EntityListAdd(tt)
		
		tt.text = str
		tt.length = str.Length()
		tt.cam = camx
		tt.classname = "TextSprite"

		tt.char_pixels = c_pixels
		
		If font <> ""
			tt.font_file = font
			
		Else
			tt.font_file = "mojo_font.png"
				
		Endif
		
		TTexture.ResizeNoSmooth() ''dont smooth on resize
		TTexture.ClearTextureFilters() ''no mip map
		
		Local pixmap:TPixmap = TPixmap.LoadPixmap( tt.font_file)
		
		pixmap.MaskPixmap(tt.mask_color & $0000ff, (tt.mask_color & $00ff00) Shr 8 , (tt.mask_color & $ff0000) Shr 16) 
		Local tex:TTexture = TTexture.LoadTexture(pixmap,4)

		TTexture.RestoreTextureFilters()
		TTexture.ResizeSmooth()
		
		tex.is_font = True
		tex.flags=4
		tex.SetBlend(1)
		tex.NoSmooth() ''can be set by user
		
		tt.EntityTexture(tex)
		tt.char_rows = Ceil( (c_pixels*num_chars+(num_chars*(pad*2) )) /Float(tex.TextureWidth(True)) )

		tt.pixel_ratio = tex.TextureWidth()/Float( tex.TextureWidth(True) )
		
		Local temp_chars_per_row:Int = Floor( num_chars/tt.char_rows)
		tt.char_uvwidth = (tt.char_pixels * tt.pixel_ratio) / Float(tex.TextureWidth())	
		tt.padding = tt.pixel_ratio*pad

		'Print "charuv:"+tt.char_uvwidth+" "+tt.pixel_ratio+"  "+tt.char_rows
		
		' update matrix
		If tt.parent<>Null
			tt.mat.Overwrite(tt.parent.mat)
			tt.UpdateMat()
		Else
			tt.UpdateMat(True)
		Endif
		
		tt.EntityFX 1+32
		
		Return tt
		
	End
	
	
	Method AddChar(char:Int, num:Int, x:Float=0.0, y:Float=0.0)
		
		Local uv:Float = (char - 32.0) * char_uvwidth + (char - 32.0) * padding
		Local uv2:Float = 0.99
		
		If char = 32 Then uv =0; uv2 = 0.001
		If uv < 0 Then uv = 0; uv2 = 0.001
		
		
		Local kern:Float = 0.3 * x
		
		surf.AddVertex( 0+x-kern, 0+y,0, uv, uv2)
		surf.AddVertex( 0+x-kern, 1+y,0, uv, 0.02)
		surf.AddVertex( 1.0+x-kern, 1+y,0, uv+char_uvwidth, 0.02)
		surf.AddVertex( 1.0+x-kern, 0+y,0, uv+char_uvwidth, uv2)
		Local v:Int = num*4
		surf.AddTriangle(0+v,1+v,2+v)
		surf.AddTriangle(0+v,2+v,3+v)
		
	End
	
	Method AdjustChar(char:Int, num:Int, x:Float=0.0, y:Float=0.0)
		
		Local uv:Float = (char - 32.0) * char_uvwidth + (char - 32.0) * padding
		Local uv2:Float = 0.99
		
		If char = 32 Then uv =0; uv2 = 0.001
		If uv < 0 Then uv = 0; uv2 = 0.001
		
		
		Local kern:Float = 0.3 * x

		Local v:Int = num*4
		surf.VertexTexCoords(v+0,uv,uv2)
		surf.VertexTexCoords(v+1,uv,0.02)
		surf.VertexTexCoords(v+2,uv+char_uvwidth,0.02)
		surf.VertexTexCoords(v+3,uv+char_uvwidth,uv2)
		
	End
	
	Method SetMode2D()
		mode = True
		brush.fx = brush.fx |64 ''disable depth testing
	End
	
	Method SetMode3D()
		mode = False
		brush.fx = brush.fx &(~64) ''enable depth testing
	End
	
	Method SetText(str$,x:Float, y:Float, z:Float = 0.0)
		
		Local resurf:Int = 0
		
		If mode=False
			PositionEntity(x,y,z)
		Else
			Local vec:Vector = cam.CameraUnProject(x-char_pixels-4,y+char_pixels+char_pixels-4, 0.95)
			PositionEntity(vec.x,vec.y,vec.z)
		Endif
		
		If str = old_text Or str = "" Then Return
		
		If str.Length() <> old_text.Length()	
			If surf
				surf.ClearSurface()
			Else
				surf=CreateSurface()
			Endif
			
			resurf=1
			
		Endif
		
		
		old_text = str
		
		Local nl:Float = 0.0, xx:Int =0, total:Int=0
		For Local i:= 0 To str.Length()-1
	
			If str[i] = 13 Or str[i] = 10
				nl=nl-1.0
				xx=0
				Continue
			Endif
			
			If resurf Then AddChar( str[i], total, 1.0+xx, nl) Else AdjustChar( str[i], total, 1.0+xx, nl)
			xx += 1
			total +=1
		Next
		
		If resurf Then surf.CropSurfaceBuffers()
		
		
	End
	
	Function SetMaskColor( c:Int)
	
		'' global, set before create text
		mask_color = c
		
	End
	
	Function Pow2Size:Int( n )
		Local t:Int=1
		While t<n
			t = t Shl 1
		Wend
		Return t
	End 
	
	Method NoSmooth()
		If surf Then surf.brush.tex[0].NoSmooth()
	End
	
	Method ReloadTexture()
		''used for android context stuff
		
		TTexture.ResizeNoSmooth()
		TTexture.ClearTextureFilters() ''no mip map
		 
		Local tex:TTexture = TTexture.LoadTexture(surf.brush.pixmap,4)

		TTexture.RestoreTextureFilters()
		TTexture.ResizeSmooth()
		
	End
End


