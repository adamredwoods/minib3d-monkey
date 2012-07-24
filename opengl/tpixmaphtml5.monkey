
''
'' TPixmap
'' for monkey
''
Import minib3d
Import minib3d.monkeyutility



#If TARGET="html5"
	'' set pixels to int, 
	'' need function to resize image to nearest power of 2
	'' do i store pixels or create new variable
	''hijack load texture and load pixmap functions to load async. halt on resize. ** OR add PreloadPixmap() function.
	'' load texture + loadpixmap seems to be ok for async callback.
	
Import "tpixmap.html5.js"

Extern

	Function PreLoadTextures:Int(file$[]) = "preLoadTextures.Loader"
		
	Function LoadImageData:Int(file$, info:Int[]) = "preLoadTextures.LoadImageData"
	
	Function CreateImageData:Int(w:Int, h:Int)
	
	Function GetImagePixel:Int(x:Int, y:Int)
	
	Function HTMLResizePixmap:Int(image:Int, w:Int, h:Int, smooth:Bool)
	
	Function HTMLMaskPixmap:Int(image:Int, r:Int, g:Int, b:Int)
	
Public


Class TPixmapGL Extends TPixmap Implements TPixmapManager
	
	Const DEBUG:Int=TRender.DEBUG
	
	Field pixels:Int ''uses monkey int to hold javascript object	
	Field format:Int, pitch:Int
	
	Field tex_id:Int[1]
		
	
	Function Init()
	
		If Not manager Then manager = New TPixmapGL
	
	End
	
	
	'' asynchronous! cache files
	Function PreLoadPixmap:Int(file$[])

		If loaded And file[0] = old_file[0]
			Return 1
		Elseif file[0] <> old_file[0]
			loaded = False
		Endif
		
		'' html5
			
		loading = PreLoadTextures(file )
		
		If loading = 0
			loaded = True
			Return 1
		Endif
		
		old_file = file
		
		Return 0
		
	End
	
	
	Method LoadPixmap:TPixmap(f$)
	
		Local p:TPixmapGL = New TPixmapGL
		
		Local info:Int[3]
		p.pixels = LoadImageData( f,info ) '' will use cached files
		p.width = info[0]
		p.height = info[1]
		p.format = PF_RGBA8888
		
		'If info[1] Then p.pitch = p.pixels.Size()/4 / info[1]
		
		If Not info[0] And Not info[1] Then Dprint "**Image Not Found:"+f
		
		If DEBUG Then Dprint "..file load "+f
		
		Return p
		
	End
	
	Method CreatePixmap:TPixmap(w:Int, h:Int, format:Int=PF_RGBA8888)
		
		Local p:TPixmapGL = New TPixmapGL
		
		p.pixels= CreateImageData(w,h)
		p.width = w
		p.height = h
		p.format = format
		p.pitch = w
		
		Return p
	End
	
	Method ResizePixmap:TPixmap(neww:Int, newh:Int)
		
		Local newpix:TPixmapGL = New TPixmapGL
		newpix.pixels = HTMLResizePixmap(pixels, neww, newh, True)
		newpix.width = neww
		newpix.height = newh
		
		Return newpix
		
	End
	
	Method ResizePixmapNoSmooth:TPixmap(neww:Int, newh:Int)
		
		Local newpix:TPixmapGL = New TPixmapGL

		newpix.pixels = HTMLResizePixmap(pixels, neww, newh, False)
		newpix.width = neww
		newpix.height = newh
		
		Return newpix
		
	End

	
	Method GetPixel:Int(x:Int,y:Int,rgba:Int=0)

Return 0

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
			'Return pixels.PeekInt( (x Shl 2)+y*(width Shl 2)) '(x*4+y*width*4)
		Endif
		
		'Return pixels.PeekByte((x Shl 2)+y*(width Shl 2)+rgba) '(x*4+y*width*4+rgba)

	End
	
	Method MaskPixmap:Void(r:Int, g:Int, b:Int)

		'Local maskcolor:Int = (r|(g Shl 8)|(b Shl 16)) & $00ffffff
		
		pixels = HTMLMaskPixmap(pixels, r,g,b)
		
	End
	
	Method ApplyAlpha:TPixmap( pixmap:TPixmap )

Return
		
		For Local y:Int = 0 To height-1
			For Local x:Int = 0 To width-1
				
				''ints faster than bytes
				Local pix:Int = GetPixel(x,y,-1)
				Local c1:Int = pix & $0000ff
				Local c2:Int = pix & $00ffff
				Local c3:Int = pix & $ffffff
				
				Local newalpha:Int = (((c1+c2+c3) * 0.333333333333) & $0000ff ) Shl 24
				
				'pixels.PokeInt( x*4+y*pitch*4, pix | newalpha ) ''ARGB
	
			Next
		Next

	End
	

	
End

#Endif
