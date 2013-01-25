''
'' TPixmap
'' for monkey
''
Import minib3d
Import minib3d.monkeyutility
Import minib3d.monkeybuffer
Import mojo.data

#If TARGET="html5"
	'' set pixels to int, 
	'' need function to resize image to nearest power of 2
	'' do i store pixels or create new variable
	''hijack load texture and load pixmap functions to load async. halt on resize. ** OR add PreloadPixmap() function.
	'' load texture + loadpixmap seems to be ok for async callback.
	
Import "tpixmap.html5.js"

Extern
	
	Class HTMLImage
	End
	
	'Function PreLoadTextures:Int(file$[]) = "_preLoadTextures.Loader"
		
	Function LoadImageDataHTML:HTMLImage(file$, id:Int) = "LoadImageData"
	
	Function CreateImageData:HTMLImage(w:Int, h:Int)
	
	Function _ReadPixel:Int(image:HTMLImage, x:Int, y:Int) = "_pixelMod.ReadPixel"
	Function _WritePixel:HTMLImage(image:HTMLImage, x:Int, y:Int, r:Int, g:Int, b:Int, a:Int) = "_pixelMod.WritePixel"
	
	Function HTMLResizePixmap:HTMLImage(image:HTMLImage, w:Int, h:Int, smooth:Bool)
	
	Function HTMLMaskPixmap:HTMLImage(image:HTMLImage, r:Int, g:Int, b:Int)
	
	Function GetHTMLImageInfo:Int[]( p:HTMLImage ) = "GetImageInfo"
	
	Function CheckIsLoaded:Bool( p:HTMLImage ) = "CheckIsLoaded"
	'Function ClearHTMLPreLoad:Void() = "Clear"
	
	''special
	Function glTexImage2D3:Void( target, level, internalformat, format, type, pixels:HTMLImage )="gl.texImage2D"
	Function glTexSubImage2D3:Void( target, level, xoffset, yoffset, format, type, pixels:HTMLImage )="gl.texSubImage2D"
	
	'' this does not work (arraybuffer->image.src) in html5 (yet)
	'Function ConvertDataToPixmapHTML:HTMLImage( from_:DataBuffer, path$ ) = "DataToPixmap"
	
	
	
Public


Class TPixmapGL Extends TPixmap Implements IPixmapManager
	
	Const DEBUG:Int=TRender.DEBUG
	
	Field pixels:HTMLImage ''used to hold javascript object	
	Field format:Int, pitch:Int
	
	Field tex_id:Int[1]
		
	
	Function Init()
	
		If Not manager Then manager = New TPixmapGL
		If Not preloader Then preloader = New TPixmapPreloader(New PreloadManager)
	
	End
	
	
	'' asynchronous only!
	Method PreLoadPixmap:Int(file$[])

		Return preloader.PreLoadBuffer(file)
		
	End
	
	
	Method LoadPixmap:TPixmap(f$)
	
		Local p:TPixmapGL = New TPixmapGL 
		
		Local info:Int[3]
		
		preloader.GetPixmapPreLoad( p, f )

		p.format = PF_RGBA8888
		
		If p.width Then p.pitch = p.width
		
		If (Not p.width And Not p.height) Or (Not p.pixels) Then Dprint "Image Not Found: "+f

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

	
	Method GetPixel:Int(x:Int,y:Int)

		Return _ReadPixel(pixels,x,y)

	End
	
	Method SetPixel:Void(x:Int,y:Int,r:Int,g:Int,b:Int,a:Int=255)

		pixels = _WritePixel(pixels,x,y,r,g,b,a)

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


Class PreloadManager Implements IPreloadManager
	
	Field data:HTMLImage[]
	Field load_complete:Bool[]
	Field w:Int[], h:Int[]
	Field total:Int
	Field preloader:TPixmapPreloader
	
		
	Method SetPreloader:Void(m:TPixmapPreloader)
	
		preloader = m
		
	End
	
	Method AllocatePreLoad:Void(size:Int)
		data = New HTMLImage[size]
		load_complete = New Bool[size]
		w = New Int[size]
		h = New Int[size]
		total = size
	End
	
	Method PreLoadData:Void(f$, id:Int)
		''we can do this with buffers, when available
		'' then also expand this class as the Buffer Callback
		
		If id<1 Then Return
		
		f = FixDataPath(f)
		f=f.Replace("monkey://","")
		data[id-1] = LoadImageDataHTML(f, id)

		
	End
	
	Method SetPixmapFromID:Void(pixmap:TPixmap, id:Int, f$)
		
		Local p:TPixmapGL = TPixmapGL(pixmap)
		If p
			
			If id>0
				p.pixels = data[id-1]
				
				Local info:Int[] = GetHTMLImageInfo(p.pixels)
				p.width = info[0]
				p.height = info[1]


				''clear buffer if need be here
			
			
			''NOT ALLOWED in HTML5, MUST PRELOAD	
			'Else
				'Local info:Int[2]
				'p.pixels = LoadImageData(f, info)
				'p.width = info[0]
				'p.height = info[1]
			Endif
			
		Endif
		
	End

	Method Update:Void()
		''update sync events here
		For Local i:Int=0 To total-1
			'If data[i] Then Print "i "+i+" :"+Int(CheckIsLoaded(data[i]))
			If data[i]
				If CheckIsLoaded(data[i])  And Not load_complete[i]
					''callback
					load_complete[i]=True
					preloader.IncLoader()
					
				Endif
			Endif
		Next	
	End
	
End



#Endif
