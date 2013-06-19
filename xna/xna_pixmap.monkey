
''
'' TPixmap
'' for monkey
''
Import minib3d
Import minib3d.monkeyutility
Import minib3d.monkeybuffer

Import "xna_driver/native/databuffer.cs"

Extern
	
	Function LoadImageData:Void(buffer:DataBuffer, f$, info:Int[]) = "DataBufferHelper.LoadImageData"
	
Public

Class TPixmapXNA Extends TPixmap Implements IPixmapManager

	Field pixels:DataBuffer
	Field format:Int, pitch:Int
	
	Field tex_id:Int[1]
	
	
	Function Init()
	
		If Not manager Then manager = New TPixmapXNA
		If Not preloader Then preloader = New TPixmapPreloader(New PreloadXNA)
	
	End
	
		
	
	Method LoadPixmap:TPixmap(f$)
	
		Local p:TPixmapXNA = New TPixmapXNA
		
		preloader.GetPixmapPreLoad(p, f)
		
		p.format = PF_RGBA8888
		
		If p.height Then p.pitch = GetBufferLength(p.pixels)/4.0 / p.height
		
		If Not p.width And Not p.height Then Dprint "Image Not Found: "+f
		'Dprint "Image found "+f+" "+p.width+" "+p.height
		
		Return p
		
	End
	
	Method CreatePixmap:TPixmap(w:Int, h:Int, format:Int=PF_RGBA8888)
		
		Local p:TPixmapXNA = New TPixmapXNA
		
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
	
	'bilinear
	Method ResizePixmap:TPixmap(neww:Int, newh:Int)
	
		Local enlarge:Int=0
		
		If width =0 Or height =0 Or neww=0 Or newh=0 Then Return CreatePixmap(0,0)
		
		Local ratiow:Float = width/Float(neww)
		Local ratioh:Float = height/Float(newh)
		
		
		'If ratiow<1.0 And ratioh<1.0 Then enlarge = 1
			
		Local newpix:TPixmapXNA = TPixmapXNA(CreatePixmap(neww, newh))
		If neww<1 Or newh<1 Then Return newpix
		
		Local rgb:Int[5], yi:Float=0, xx:Int, yy:Int, r:Int, g:Int, b:Int, a:Int

		For Local iy = 0 Until newh
			For Local ix = 0 Until neww
			
				Local fx# = Float(ix) * ratiow
				Local fy# = Float(iy) * ratioh
				
				Local x = Int(fx)
				Local y = Int(fy)
				
				''ints faster than bytes
				rgb[0] = GetPixel(x,y) 
				rgb[1] = GetPixel(x+1,y)
				rgb[2] = GetPixel(x,y+1)
				rgb[3] = GetPixel(x+1,y+1)
				

					Local dx% = (Int(fx - x) /16)
					Local dy% = (Int(fy - y) /16)
					
					
					Local y1 = (rgb[0]& $000000ff) + Int(dx * ((rgb[1]& $000000ff) - (rgb[0]& $000000ff))) /16
					Local y2 = (rgb[2]& $000000ff) + Int(dx * ((rgb[3]& $000000ff) - (rgb[2]& $000000ff))) /16
					r = y1 + (dy * (y2 - y1)) /16
					
					y1 = ((rgb[0] & $0000ff00)Shr 8) + Int(dx * (((rgb[1] & $0000ff00)Shr 8) - (rgb[0] & $0000ff00)Shr 8)) /16
					y2 = ((rgb[2] & $0000ff00)Shr 8) + Int(dx * (((rgb[3] & $0000ff00)Shr 8) - (rgb[2] & $0000ff00)Shr 8)) /16
					g = y1 + (dy * (y2 - y1)) /16
					
					y1 = ((rgb[0] & $00ff0000)Shr 16) + Int(dx * (((rgb[1] & $00ff0000)Shr 16) - (rgb[0] & $00ff0000)Shr 16)) /16
					y2 = ((rgb[2] & $00ff0000)Shr 16) + Int(dx * (((rgb[3] & $00ff0000)Shr 16) - (rgb[2] & $00ff0000)Shr 16)) /16
					b = y1 + (dy * (y2 - y1)) /16
					
					y1 = ((rgb[0] & $ff000000)Shr 24) + Int(dx * (((rgb[1] & $ff000000)Shr 24) - (rgb[0] & $ff000000)Shr 24)) /16
					y2 = ((rgb[2] & $ff000000)Shr 24) + Int(dx * (((rgb[3] & $ff000000)Shr 24) - (rgb[2] & $ff000000)Shr 24)) /16
					a = y1 + (dy * (y2 - y1)) /16
					
					g=g Shl 8
					b=b Shl 16
					a=a Shl 24

		
				'newpix.SetPixel(ix,iy,r,g,b,a)
				newpix.pixels.PokeInt( (ix Shl 2)+iy*(neww Shl 2), r|g|b|a )
				
			Next 
		Next 
		
		Return newpix
		
	End
	
	Method ResizePixmapNoSmooth:TPixmap(neww:Int, newh:Int)
	
		''no average, straight pixels better for fonts, details
		''pixelation ok
		Local enlarge:Int=0
		
		Local ratiow:Float = width/Float(neww)
		Local ratioh:Float = height/Float(newh)
			
		Local newpix:TPixmapXNA = TPixmapXNA(CreatePixmap(neww, newh))
		If neww<1 Or newh<1 Then Return newpix
		
		Local rgb:Int[5], yi:Float=0, xx:Int, yy:Int, red:Int, green:Int, blue:Int, alpha:Int
		
		For Local y:Int = 0 To newh-1
			Local xi:Float =0
			For Local x:Int = 0 To neww-1
				
				xx=Int(xi); yy=Int(yi)
				
				''ints faster than bytes
				rgb[0] = GetPixel(xx,yy) 
				
				newpix.pixels.PokeInt( (x Shl 2)+y*(neww Shl 2), rgb[0] ) '( x*4+y*neww*4, rgb[0] )
				
				xi = xi+ratiow
			Next
			yi = yi+ratioh
		Next
		
		Return newpix
		
	End

	
	Method GetPixel:Int(x:Int,y:Int)
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
		
		'If rgba>0
			''individual colors
			'Return pixels.PeekByte((x Shl 2)+y*(width Shl 2)+rgba-1) '(x*4+y*width*4+rgba)
		'Endif
		
		Return pixels.PeekInt( (x Shl 2)+y*(width Shl 2)) '(x*4+y*width*4)

	End
	
	Method SetPixel:Void(x:Int,y:Int,r:Int,g:Int,b:Int,a:Int=255)
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
		
		'If rgba>0
			''individual colors
			'Return pixels.PeekByte((x Shl 2)+y*(width Shl 2)+rgba-1) '(x*4+y*width*4+rgba)
		'Endif
		
		'abgr
		pixels.PokeInt( (x Shl 2)+y*(width Shl 2), (a Shl 24)|(b Shl 16)|(g Shl 8)|r) '(x*4+y*width*4)

	End
	
	Method MaskPixmap:Void(r:Int, g:Int, b:Int)
		
		Local maskcolor:Int = (r|(g Shl 8)|(b Shl 16)) & $00ffffff
		
		For Local y:Int = 0 To height-1
			For Local x:Int = 0 To width-1
				
				''ints faster than bytes
				Local pix:Int = GetPixel(x,y) & $00ffffff
				 
				If maskcolor = pix
				
					pixels.PokeInt( x*4+y*pitch*4, pix & $00ffffff ) ''ARGB
				Else
				
					pixels.PokeInt( x*4+y*pitch*4, pix | $ff000000 ) ''ARGB
				
				Endif
				
			Next
		Next
		
	End
	
	Method ApplyAlpha:TPixmap( pixmap:TPixmap )

		
		For Local y:Int = 0 To height-1
			For Local x:Int = 0 To width-1
				
				''ints faster than bytes
				Local pix:Int = GetPixel(x,y)
				Local c1:Int = pix & $0000ff
				Local c2:Int = pix & $00ffff
				Local c3:Int = pix & $ffffff
				
				Local newalpha:Int = (((c1+c2+c3) * 0.333333333333) & $0000ff ) Shl 24
				
				pixels.PokeInt( x*4+y*pitch*4, pix | newalpha ) ''ARGB
	
			Next
		Next

	End
	
		
End


Class PreloadData
	Field data:DataBuffer
	Field w:Int=0, h:Int=0
	Field id:int
End


Class PreloadXNA Implements IPreloadManager

	Field p_map:ArrayIntMap<PreloadData> = New ArrayIntMap<PreloadData>
	
	Method IsLoaded:Bool(file_id:Int)
		Local f:PreloadData = p_map.Get(file_id)
		If f Then Return (f.w<>0)
		
		Return False
	End
	
	
	Method PreLoadData:Void(f$, id:Int)
		''we can do this with buffers, when available
		'' then also expand this class as the Buffer Callback
		
		If id<1 Then Return
		Local info:Int[2]
		
		f = FixDataPath(f)

		Local d:PreloadData = New PreloadData
		d.id = id
		d.data = New DataBuffer
		LoadImageData(d.data, f, info)	
		d.w = info[0]
		d.h = info[1]
		
		If d.data Then p_map.Set(id, d)
		
	End
	
	Method SetPixmapFromID:Void(pixmap:TPixmap, id:Int, f$)
		
		Local p:TPixmapXNA = TPixmapXNA(pixmap)
		If p
			
			If id>0
				Local d:PreloadData = p_map.Get(id)
				
				If d ''load_complete moved to tpixmap
									
					''set pixels, width, height
					p.pixels = d.data
					p.width = d.w
					p.height = d.h

				endif
				''clear buffer if need be here
				
			Else
		
				'' load directly
				Local info:Int[2]
				f = FixDataPath(f)
				p.pixels =  New DataBuffer
				LoadImageData(p.pixels, f, info)	
				p.width = info[0]
				p.height = info[1]
				
			Endif
			
		Endif
		
	End
	
End


Class ArrayIntMap<T>
	
	Field data:T[]
	Field length:Int
	
	Method New()
		data = New T[32]
		length = 31
	End
	
	Method Length:Int()
		Return length+1
	End
	
	Method Clear:Void()
		data = New T[32]
		length = 31
	End

	Method Get:T(id:Int)
		If id<length Then Return data[id]
	End
	
	Method Set:Void(id:Int, obj:T)
		While id>=length
			length = length+32
			data = data.Resize(length+1)
		Wend
		data[id] = obj
	End
End
