
''
'' TPixmap
'' for monkey
''
Import minib3d
Import minib3d.monkeyutility
Import minib3d.monkeybuffer
Import mojo.data

'Alias DataBuffer = databuffer.DataBuffer

#If OPENGL_GLES20_ENABLED=Int(True) Or TARGET="html5"

	Import opengl.gles20
	
#else

	Import opengl.gles11
	
#endif

#If TARGET="html5"

	Import tpixmaphtml5

#Else

''todo later.....

#rem
#If TARGET="android"
	Import "tpixmap.java"
	Extern
		Function ConvertDataToPixmap( from_:DataBuffer, to_:DataBuffer, info:Int[] ) = "TPixmapJava.DataToPixmap"
	Public
#ElseIf TARGET="ios"
	Import "tpixmap.cpp"
#Else
	Import "tpixmap.cpp"
	
	Extern

		'Function LoadImageData:DataBuffer( from_:DataBuffer, path$,info[]=[] )
		Function ConvertDataToPixmap( from_:DataBuffer, to_:DataBuffer, info:Int[] ) = "DataToPixmap"
	
	Public
#end


#end





Class TPixmapGL Extends TPixmap Implements IPixmapManager

	Field pixels:DataBuffer
	Field format:Int, pitch:Int
	
	Field tex_id:Int[1]
	
	
	Function Init()
		
		If Not manager Then manager = New TPixmapGL
		If Not preloader Then preloader = New TPixmapPreloader(New PreloadManager)
	
	End
	
	
	Method LoadPixmap:TPixmap(f$)
	
		Local p:TPixmapGL = New TPixmapGL
		
		Local info:Int[3]
	
		'p.FromDataBuffer( preloader.GetDataBuffer(f) , info )
		preloader.GetPixmapPreLoad(p, f)
		
		p.format = PF_RGBA8888
		
		If p.height Then p.pitch = GetBufferLength(p.pixels)/4.0 / p.height
		
		If Not p.width And Not p.height Then Dprint "Image Not Found: "+f

		Return p
		
	End
	

	Method CreatePixmap:TPixmap(w:Int, h:Int, format:Int=PF_RGBA8888)
		
		Local p:TPixmapGL = New TPixmapGL
		
		p.pixels= CreateDataBuffer(w*h*4)
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
	
	'Method GetImageType:String(buf:DataBuffer)
		
		'Return buf.PeekString(6,4) ''jfif = jpeg
		'Return buf.PeekString(0,4) ''png
		
	'End
End




Class PreloadManager Implements IPreloadManager
	
	Field data:DataBuffer[]
	Field w:Int[], h:Int[]
	Field total:Int
	Field preloader:TPixmapPreloader
	
	Method AllocatePreLoad:Void(size:Int)
		data = New DataBuffer[size]
		w = New Int[size]
		h = New Int[size]
		total = size
	End
	
	Method PreLoadData:Void(f$, id:Int)
		''we can do this with buffers, when available
		'' then also expand this class as the Buffer Callback
		
		If id<1 Then Return
		Local info:Int[2]

'' ugh....
#If TARGET<>"ios"		
		f = FixDataPath(f)
#Endif
		data[id-1] = LoadImageData(f, info)
		w[id-1] = info[0]
		h[id-1] = info[1]
		
		''callback
		preloader.IncLoader()
		
	End
	
	Method SetPixmapFromID:Void(pixmap:TPixmap, id:Int, f$)
		
		Local p:TPixmapGL = TPixmapGL(pixmap)
		If p
			
			If id>0
				p.pixels = data[id-1]
				p.width = w[id-1]
				p.height = h[id-1]
				''clear buffer if need be here
				
			Else
				Local info:Int[2]
'' ugh....
#If TARGET<>"ios"
				f = FixDataPath(f)
#Endif
				p.pixels = LoadImageData(f, info)
				p.width = info[0]
				p.height = info[1]
			Endif
			
		Endif
		
	End
	
	Method SetPreloader:Void(m:TPixmapPreloader)
	
		preloader = m
		
	End
	
	Method Update:Void()
		''update sync events here
	End
	
''todo later....
#rem	
	Method FromDataBuffer:Void(buf:DataBuffer, info[])
		
		If Not buf Then Return
		
		''move data from buf to pixels
		pixels = New DataBuffer(buf.Length())
		ConvertDataToPixmap( buf, pixels, info)
	
		''free it
		buf.Discard()
		
''Print "pixmapgl size "+info[0]+" "+info[1]

	End
#end
	
End



#Endif
