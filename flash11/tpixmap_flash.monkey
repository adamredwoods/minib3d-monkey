''
'' TPixmap
'' for monkey
''
Import minib3d
Import minib3d.monkeyutility
Import minib3d.monkeybuffer
Import mojo.data

#If TARGET<>"flash"
	#Error "Needs Flash Target."
#Endif

'' **FLASH BITMAPS TEXTURES ARE BGRA ?? maybe

Import "tpixmap.flash11.as"

Extern
	
	Class FlashPixmap = "TPixmap"
	End

		
	Function _LoadImageData:FlashPixmap(file$) = "TPixmap.LoadImageData"
	
	Function _CreateImageData:FlashPixmap(w:Int, h:Int) = "TPixmap.CreatePixmap"
	
	Function _ReadPixel:Int(p:FlashPixmap, x:Int, y:Int) = "TPixmap.ReadPixel"
	Function _WritePixel:FlashPixmap(p:FlashPixmap, x:Int, y:Int, r:Int, g:Int, b:Int, a:Int) = "TPixmap.WritePixel"
	
	Function _ResizePixmap:FlashPixmap(p:FlashPixmap, w:Int, h:Int, smooth:Bool=True)= "TPixmap.ResizePixmap"
	
	Function _MaskPixmap:FlashPixmap(p:FlashPixmap, hexcolor:Int)= "TPixmap.MaskPixmap"
	
	Function _GetImageInfo:Int[]( p:FlashPixmap) = "TPixmap.GetInfo"
	
	Function _CheckIsLoaded:Bool( p:FlashPixmap) = "TPixmap.CheckIsLoaded"
	'Function ClearHTMLPreLoad:Void() = "Clear"
	
	
	
Public


Class TPixmapFlash Extends TPixmap Implements IPixmapManager
	
	Const DEBUG:Int=TRender.DEBUG
	
	Field pixels:FlashPixmap ''used to hold flash object	
	Field format:Int, pitch:Int
	
	Field tex_id:Int[1]
	
	
	
	Function Init()
	
		If Not manager Then manager = New TPixmapFlash
		If Not preloader Then preloader = New TPixmapPreloader(New PreloadFlash)
	
	End
	
	
	
	'' asynchronous only!
	Method PreLoadPixmap:Int(file$[])

		Return preloader.PreLoadBuffer(file)
		
	End
	
	
	Method LoadPixmap:TPixmap(f$)
	
		Local p:TPixmapFlash = New TPixmapFlash 
		
		Local info:Int[3]
		
		preloader.GetPixmapPreLoad( p, f )

		p.format = PF_RGBA8888
		
		If p.width Then p.pitch = p.width
	
		If (p.width=0 or p.height=0) Or (Not p.pixels) Then Dprint "Image Not Preloaded: "+f

		Return p
		
	End
	
	Method CreatePixmap:TPixmap(w:Int, h:Int, format:Int=PF_RGBA8888)
		
		Local p:TPixmapFlash = New TPixmapFlash 
		
		p.pixels= _CreateImageData(w,h)
		p.width = w
		p.height = h
		p.format = format
		p.pitch = w
		
		Return p
	End
	
	Method ResizePixmap:TPixmap(neww:Int, newh:Int)
		
		Local newpix:TPixmapFlash = New TPixmapFlash
		If neww<1 Or newh<1 Then Return newpix
		
		newpix.pixels = _ResizePixmap(pixels, neww, newh)
		newpix.width = neww
		newpix.height = newh
		
		Return newpix
		
	End
	
	Method ResizePixmapNoSmooth:TPixmap(neww:Int, newh:Int)
		
		Local newpix:TPixmapFlash = New TPixmapFlash 
		If neww<1 Or newh<1 Then Return newpix
		
		newpix.pixels = _ResizePixmap(pixels, neww, newh, False)
		newpix.width = neww
		newpix.height = newh
		
		Return newpix
		
	End

	
	Method GetPixel:Int(x:Int,y:Int)

		Return _ReadPixel(pixels,x,y)

	End
	
	Method SetPixel:Void(x:Int,y:Int,r:Int,g:Int,b:Int,a:Int=255)

		pixels = _WritePixel(pixels,x,y, (a Shl 24)|(r Shl 16)|(b Shl 8)|g )

	End
	
	Method MaskPixmap:Void(r:Int, g:Int, b:Int)

		'Local maskcolor:Int = (r|(g Shl 8)|(b Shl 16)) & $00ffffff

		pixels = _MaskPixmap(pixels, DRIVER_FF000000 |(r Shl 16)|(b Shl 8)|g )
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


Class PreloadData
	Field data:FlashPixmap
	Field w:Int=0, h:Int=0
	Field id:int
End

Class PreloadFlash Implements IPreloadManager
	
	Field p_map:ArrayIntMap<PreloadData> = New ArrayIntMap<PreloadData>
	
	Method IsLoaded:Bool(file_id:int)
		
		Local f:PreloadData = p_map.Get(file_id)
		If f Then Return _CheckIsLoaded(f.data)
		
		Return False
	End
		
	
	Method PreLoadData:Void(f$, id:Int)
		''we can do this with buffers, when available
		'' then also expand this class as the Buffer Callback
		
		If id<1 Then Return
	
		f = FixDataPath(f)
		f=f.Replace("monkey://","") ''because flash loader doesn't use monkey:// prefix
		
		Local d:PreloadData = New PreloadData
		d.id = id
		d.data = _LoadImageData(f) ', id)
		
		p_map.Set( id, d )
		
	End
	
	Method SetPixmapFromID:Void(pixmap:TPixmap, id:Int, f$)
		
		Local p:TPixmapFlash = TPixmapFlash(pixmap)
		If p And id>0
			
				Local d:PreloadData = p_map.Get(id)
				
				If d ''load_complete moved to tpixmap
									
					''set pixels, width, height
					p.pixels = d.data			
					Local info:Int[] = _GetImageInfo(p.pixels)
					p.width = info[0]
					p.height = info[1]

				endif
				''clear buffer if need be here
			
			
			''NO DIRECT LOADING NOT ALLOWED in Flash, MUST PRELOAD	
			'

		Endif
		
	End


	
End

