
''
'' TPixmap
'' for monkey
''
Import minib3d
Import minib3d.monkeyutility


#If OPENGL_GLES20_ENABLED="true" Or TARGET="html5"

	Import opengl.gles20
	
#else

	Import opengl.gles11
	
#endif

#If TARGET="html5"

	Import tpixmaphtml5

#Else
	
	
Import opengl.databuffer

'Extern
	'Function LoadImageData:DataBuffer( path$,info[]=[] )
'Public



Class TPixmapGL Extends TPixmap Implements TPixmapManager

	Field pixels:DataBuffer
	Field format:Int, pitch:Int
	
	Field tex_id:Int[1]
	
	
	Function Init()
	
		If Not manager Then manager = New TPixmapGL
	
	End
	
	Method LoadPixmap:TPixmap(f$)
	
		Local p:TPixmapGL = New TPixmapGL
		
		Local info:Int[3]
		
		If loaded = False
	
			p.pixels = LoadImageData( f,info )
			
		Elseif loaded=True

			For Local i:Int=0 To old_file.Length()-1
				If f = old_file[i] Then Return pixmap_preload[i]
			Next
			p.pixels = LoadImageData( f,info )
			
		Endif
		
		p.width = info[0]
		p.height = info[1]
		p.format = PF_RGBA8888
		
		If info[1] Then p.pitch = p.pixels.Size()/4 / info[1]
		
		If Not info[0] And Not info[1] Then Dprint "Image Not Found: "+f

		Return p
		
	End
	
	Method CreatePixmap:TPixmap(w:Int, h:Int, format:Int=PF_RGBA8888)
		
		Local p:TPixmapGL = New TPixmapGL
		
		p.pixels= DataBuffer.Create(w*h*4)
		p.width = w
		p.height = h
		p.format = format
		p.pitch = w
		
		For Local y:Int = 0 To h-1
			For Local x:Int = 0 To w-1
				
				p.pixels.PokeInt( (x Shl 2)+y*(w Shl 2), $ffffffff ) ''ARGB
	
			Next
		Next
		
		Return p
	End
	
	Method ResizePixmap:TPixmap(neww:Int, newh:Int)
	
		''simple average 4pixel
		''softer
		Local enlarge:Int=0
		
		Local ratiow:Float = width/Float(neww)
		Local ratioh:Float = height/Float(newh)
		
		If ratiow<1.0 And ratioh<1.0 Then enlarge = 1
			
		Local newpix:TPixmapGL = TPixmapGL(CreatePixmap(neww, newh))
		
		Local rgb:Int[5], yi:Float=0, xx:Int, yy:Int, red:Int, green:Int, blue:Int, alpha:Int
		
		For Local y:Int = 0 To newh-1
			Local xi:Float =0
			For Local x:Int = 0 To neww-1
				
				xx=Int(xi); yy=Int(yi)
				
				''ints faster than bytes
				rgb[0] = GetPixel(xx-1,yy,-1) 
				rgb[1] = GetPixel(xx+1,yy,-1)
				rgb[2] = GetPixel(xx,yy-1,-1)
				rgb[3] = GetPixel(xx,yy+1,-1)
				
				red = (((rgb[0] & $000000ff) + (rgb[1] & $000000ff) +(rgb[2] & $000000ff) +(rgb[3] & $000000ff) )Shr 2) & $000000ff
				green = (((rgb[0] & $0000ff00) + (rgb[1] & $0000ff00) +(rgb[2] & $0000ff00) +(rgb[3] & $0000ff00) )Shr 2) & $0000ff00 
				blue = (((rgb[0] & $00ff0000) + (rgb[1] & $00ff0000) +(rgb[2] & $00ff0000) +(rgb[3] & $00ff0000) )Shr 2) & $00ff0000
				alpha = (((((rgb[0] & $ff000000) Shr 24) + ((rgb[1] & $ff000000) Shr 24) +((rgb[2] & $ff000000)Shr 24)  +((rgb[3] & $ff000000)Shr 24) )Shr 2) Shl 24) & $ff000000
				
				'' extra weight gives better results for enlarge
				If enlarge
					rgb[4] = GetPixel(xx,yy,-1)
					red = ((red+(rgb[4]&$000000ff))Shr 1) & $000000ff
					green = ((green+(rgb[4]&$0000ff00))Shr 1) & $0000ff00
					blue = ((blue+(rgb[4]&$00ff0000))Shr 1) & $00ff0000
					alpha = ((((alpha Shr 24)+((rgb[4]&$ff000000)Shr 24) )Shr 1) Shl 24) & $ff000000
				Endif
				
				newpix.pixels.PokeInt( (x Shl 2)+y*(neww Shl 2), red|green|blue|alpha )
				
				xi = xi+ratiow
			Next
			yi = yi+ratioh
		Next
		
		Return newpix
		
	End
	
	Method ResizePixmapNoSmooth:TPixmap(neww:Int, newh:Int)
	
		''no average, straight pixels better for fonts, details
		''pixelation ok
		Local enlarge:Int=0
		
		Local ratiow:Float = width/Float(neww)
		Local ratioh:Float = height/Float(newh)
			
		Local newpix:TPixmapGL = TPixmapGL(CreatePixmap(neww, newh))
		
		Local rgb:Int[5], yi:Float=0, xx:Int, yy:Int, red:Int, green:Int, blue:Int, alpha:Int
		
		For Local y:Int = 0 To newh-1
			Local xi:Float =0
			For Local x:Int = 0 To neww-1
				
				xx=Int(xi); yy=Int(yi)
				
				''ints faster than bytes
				rgb[0] = GetPixel(xx,yy,-1) 
				
				newpix.pixels.PokeInt( (x Shl 2)+y*(neww Shl 2), rgb[0] ) '( x*4+y*neww*4, rgb[0] )
				
				xi = xi+ratiow
			Next
			yi = yi+ratioh
		Next
		
		Return newpix
		
	End

	
	Method GetPixel:Int(x:Int,y:Int,rgba:Int=0)
		''will repeat edge pixels
		
		If x<0
			x=0
		Elseif x>width-1
			x=width-1
		Endif
		If y<0
			y=0
		Elseif y>height-1
			y=height-1
		Endif
		
		If rgba<0
			Return pixels.PeekInt( (x Shl 2)+y*(width Shl 2)) '(x*4+y*width*4)
		Endif
		
		Return pixels.PeekByte((x Shl 2)+y*(width Shl 2)+rgba) '(x*4+y*width*4+rgba)

	End
	
	Method MaskPixmap:Void(r:Int, g:Int, b:Int)
		
		Local maskcolor:Int = (r|(g Shl 8)|(b Shl 16)) & $00ffffff
		
		For Local y:Int = 0 To height-1
			For Local x:Int = 0 To width-1
				
				''ints faster than bytes
				Local pix:Int = GetPixel(x,y,-1) & $00ffffff
				 
				If maskcolor = pix
				
					pixels.PokeInt( x*4+y*pitch*4, pix & $00ffffff ) ''ARGB
				Else
				
					pixels.PokeInt( x*4+y*pitch*4, pix | $ff000000 ) ''ARGB
				
				Endif
				
			Next
		Next
		
	End
	
	Method ApplyAlpha:Void( pixmap:TPixmapGL )

		
		For Local y:Int = 0 To height-1
			For Local x:Int = 0 To width-1
				
				''ints faster than bytes
				Local pix:Int = GetPixel(x,y,-1)
				Local c1:Int = pix & $0000ff
				Local c2:Int = pix & $00ffff
				Local c3:Int = pix & $ffffff
				
				Local newalpha:Int = (((c1+c2+c3) * 0.333333333333) & $0000ff ) Shl 24
				
				pixels.PokeInt( x*4+y*pitch*4, pix | newalpha ) ''ARGB
	
			Next
		Next

	End
	

	
End



#Endif