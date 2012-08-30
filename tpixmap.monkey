
''
'' TPixmap
'' for monkey
''
Import minib3d
Import monkeyutility




Interface TPixmapManager

	Method LoadPixmap:TPixmap(f$)
	
	Method CreatePixmap:TPixmap(w:Int, h:Int, format:Int=PF_RGBA8888)

	Method PreLoadPixmap:Int(file$[])
	
End





Class TPixmap
	
	Global manager:TPixmapManager ''Use this to Load & Create pixmaps, this is set by render driver
	
	Field width:Int, height:Int
	
	Global loading:Bool = False, loaded:Bool = False
	Global old_file:String[1]
	Global cur_file:Int=0
	Global pixmap_preload:TPixmap[]
	
	
	Function PreLoadPixmap:Int(file$[])
		
		If manager
			Return manager.PreLoadPixmap(file)
		Endif
	
	End
	
	''load files synchronously
	Function PreLoadPixmapSynch:Int(file$[])
		
		If loaded And file[0] = old_file[0]
			Return 1
		Elseif file[0] <> old_file[0]
			loaded = False
			cur_file = -1
			loading = True
			pixmap_preload = New TPixmap[file.Length()]
		Endif
		
		If loading Then cur_file +=1
		
		''run many times for other targets
		loading = True
					
		pixmap_preload[cur_file] = LoadPixmap(file[cur_file])
		
		old_file = file
		
		If cur_file = file.Length()-1
			loaded = True
			loading = False
			Return 1
		Endif
		
		Return 0
		
	End
	
	
	Function LoadPixmap:TPixmap(f$)
		Return manager.LoadPixmap(f)
	End

	
	Function CreatePixmap:TPixmap(w:Int, h:Int, format:Int=PF_RGBA8888)
		Return manager.CreatePixmap(w, h, format)
	End
	
	Method ResizePixmap:TPixmap(neww:Int, newh:Int) Abstract
	''averages pixels

	
	Method ResizePixmapNoSmooth:TPixmap(neww:Int, newh:Int) Abstract
	''no average, straight pixels better for fonts, details
	''pixelation ok


	
	Method MaskPixmap:Void(r:Int, g:Int, b:Int)
	
	End
	
	Method ApplyAlpha:Void( pixmap:TPixmap )

	End
	

	
End
