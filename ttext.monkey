''
''
'' 3d text for minib3d + monkey
Import minib3d.tsprite
Import minib3d



Class TText Extends TSprite Final
	
	Const ALIGN_LEFT:Int = 0
	Const ALIGN_CENTER:Int = 1

	
	Field cam:TCamera
	Field mode:Bool = True ''true = 2d, false = 3d
	Field text$="" , old_text$=""
	Field length:Int
	Field font_file:String
	Field orig_width:Float, orig_height:Float ''retain this info for font ratios
	
	Field char_uvwidth:Float
	Field surf:TSurface
	Field char_pixels:Float
	Field pixel_ratio:Float
	Field padding:Int
	Field char_rows:Int
	
	Field align:Int = 0
	
	Global mask_color:Int = $000000
	
	Field use3D:Bool '' is this text 2d or 3d
	
	Function CreateText3D:TText(str$ = "", font$="", num_chars:Int = 96, c_pixels:Int=9, pad:Int = 0 )
		Local tt:TText = CreateText(Null,str,font,num_chars,c_pixels,pad, False)
		Return tt
	End
	
	Function CreateText2D:TText(camx:TCamera=Null, str$ = "", font$="", num_chars:Int = 96, c_pixels:Int=9, pad:Int = 0 )
		Local tt:TText = CreateText(camx,str,font,num_chars,c_pixels,pad, True)
		Return tt
	End
	

	
	Function CreateText:TText(camx:TCamera, str$ = "", font$="", num_chars:Int = 96, c_pixels:Int=9, pad:Int = 0, mode:Bool = True )
		
		Local tt:TText = New TText
		
		tt.entity_link = entity_list.EntityListAdd(tt)
		
		tt.text = str
		tt.length = str.Length()
		tt.cam = camx
		tt.classname = "TextSprite"
		tt.is_sprite = True

		tt.char_pixels = c_pixels
		
		If font <> ""
			tt.font_file = font
			
		Else
			tt.font_file = "mojo_font.png"
				
		Endif
		
		TTexture.useGlobalResizeSmooth = False ''dont smooth on resize
		'TTexture.ClearTextureFilters() ''no mip map on fonts
		
		Local pixmap:TPixmap = TPixmap.LoadPixmap( tt.font_file)
		tt.orig_width = pixmap.width; tt.orig_height = pixmap.height
		
		If pixmap.height = 0 Then Print"Font file not found."; Return tt
		
		
		pixmap.MaskPixmap(tt.mask_color & $0000ff, (tt.mask_color & $00ff00) Shr 8 , (tt.mask_color & $ff0000) Shr 16) 
		Local tex:TTexture = TTexture.LoadTexture(pixmap,4)

		'TTexture.RestoreTextureFilters()
		TTexture.useGlobalResizeSmooth = True
		
		tex.is_font = True
		tex.flags=4 |16|32
		tex.TextureBlend(2)
		tex.NoSmooth() ''can be set by user
		
		tt.surf = tt.CreateSurface()
		tt.EntityTexture(tex)
		tt.char_rows = Ceil( (c_pixels*num_chars+(num_chars*(pad*2) )) / tt.orig_width )

		tt.pixel_ratio = Float(tex.width)/tt.orig_width
		
		Local temp_chars_per_row:Int = Floor( num_chars/tt.char_rows)
		tt.char_uvwidth = (tt.char_pixels * tt.pixel_ratio) / Float(tex.width)	
		tt.padding = tt.pixel_ratio*pad

		'Print "charuv:"+tt.char_uvwidth+" "+tt.pixel_ratio+"  "+tt.char_rows+" :: "+tex.TextureWidth(True)
		
		
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
	
	
	Method CopyEntity:TEntity(parent_ent:TEntity = Null)
		
		Local txt:TText = New TText	
		
		Self.CopyBaseSpriteTo(txt, parent_ent)
		
		txt.cam = cam
		txt.mode = mode
		txt.text = text
		txt.length = length
		txt.font_file = font_file
		txt.orig_width = orig_width
		txt.orig_height = orig_height
		
		txt.char_uvwidth = char_uvwidth
		txt.surf = surf
		txt.char_pixels = char_pixels
		txt.pixel_ratio = pixel_ratio
		txt.padding = padding
		txt.char_rows = char_rows
		
		txt.align = align
		
		Return txt
	End
	
	
	
	Method AddChar(char:Int, num:Int, x:Float=0.0, y:Float=0.0, offset:Float=0.0)
		
		Local uv:Float = (char - 32.0) * char_uvwidth + (char - 32.0) * padding
		Local uv2:Float = 0.999
		
		If char = 32 Then uv =0; uv2 = 0.001
		If uv < 0 Then uv = 0; uv2 = 0.001
		
		
		'Local kern:Float = 0.3 * x + offset
		Local kern:Float = 0.3 * x + offset
		
		surf.AddVertex( 0.0+x-kern, 0.0+y,0, uv, uv2)
		surf.AddVertex( 0.0+x-kern, 1.0+y,0, uv, 0.0)
		surf.AddVertex( 1.0+x-kern, 1.0+y,0, uv+char_uvwidth, 0.0)
		surf.AddVertex( 1.0+x-kern, 0.0+y,0, uv+char_uvwidth, uv2)
		Local v:Int = num*4
		surf.AddTriangle(0+v,1+v,2+v)
		surf.AddTriangle(0+v,2+v,3+v)
		
	End
	
	Method AdjustChar(char:Int, num:Int, x:Float=0.0, y:Float=0.0)
		
		Local uv:Float = (char - 32.0) * char_uvwidth + (char - 32.0) * padding
		Local uv2:Float = 0.999
		
		If char = 32 Then uv =0; uv2 = 0.001
		If uv < 0 Then uv = 0; uv2 = 0.001
		
		
		Local kern:Float = 0.3 * x 

		Local v:Int = num*4
		surf.VertexTexCoords(v+0,uv,uv2)
		surf.VertexTexCoords(v+1,uv,0.0)
		surf.VertexTexCoords(v+2,uv+char_uvwidth,0.0)
		surf.VertexTexCoords(v+3,uv+char_uvwidth,uv2)
		
	End
	
	Method SetMode2D()
		mode = True
		brush.fx = brush.fx |64|8 ''disable depth testing, fog
	End
	
	Method SetMode3D()
		mode = False
		brush.fx = brush.fx &(~64) &(~8) ''enable depth testing, fog
	End
	
	Method SetText(str$,x:Float=0.0, y:Float=0.0, z:Float = 0.0, align:Int=0)
		
		Local resurf:Int = 0
	
		If mode=False
		
			PositionEntity(x,y,z)
			
		Else If cam<>Null
			
			''old cam projection way
			
			Local zz:Float = (cam.range_far * cam.range_near) / (cam.range_far - cam.range_near) -0.05
			
			scale_x = cam.inv_zoom
			scale_y = cam.inv_zoom
			Local vec:Vector = cam.CameraUnProject(x-char_pixels-4,y+char_pixels+char_pixels-4, zz )'0.95 )
			PositionEntity(vec.x,vec.y,vec.z)
			'ScaleEntity(1/cam.zoom,1/cam.zoom,1.0)
			
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
		
		Local nl:Int = -1, xx:Int =0.0, total:Int=0
		
		''alignment
		Local offset:Float = 0
		If align = 1 Then offset = str.Length()*0.15 ''(0.5 times kern(0.3))
		
		For Local i:= 0 To str.Length()-1
	
			If str[i] = 13 Or str[i] = 10
				nl=nl-1
				xx=0.0
				Continue
			Endif
			
			If resurf Then AddChar( str[i], total, xx, nl, offset) Else AdjustChar( str[i], total, xx, nl)
			xx += 1
			total +=1
		Next
		
		If resurf Then surf.CropSurfaceBuffers()
		
		
	End
	
	Function SetMaskColor( c:Int)
	
		'' global, set before create text
		mask_color = c
		
	End
	
	Method ScaleText(s_x#, s_y#, s_z#=1.0)
	
		scale_x=s_x
		scale_y=s_y
	
	End 
	
	Function Pow2Size:Int( n )
		Local t:Int=1
		While t<n
			t = t Shl 1
		Wend
		Return t
	End 
	
	Method NoSmooth()
		If brush Then brush.tex[0].NoSmooth()
	End
	
	Method Smooth()
		If brush Then brush.tex[0].Smooth()
	End
	
	Method ReloadTexture()
		''used for android context stuff
		
		'TTexture.ResizeNoSmooth() ''retained within tex
		TTexture.ClearTextureFilters() ''no mip map
		 
		Local tex:TTexture = TTexture.LoadTexture(surf.brush.pixmap,4, Self)

		TTexture.RestoreTextureFilters()
		'TTexture.ResizeSmooth()
		
	End
End


