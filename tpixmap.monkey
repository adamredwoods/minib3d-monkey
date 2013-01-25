
''
'' TPixmap
'' for monkey
''
Import minib3d
Import minib3d.monkeyutility
Import mojo.data
'Import minib3d.monkeybuffer



Interface IPixmapManager

	Method LoadPixmap:TPixmap(f$)
	Method CreatePixmap:TPixmap(w:Int, h:Int, format:Int=PF_RGBA8888)
	
End

Interface IPreloadManager
		
	Method AllocatePreLoad:Void(size:Int)
	Method PreLoadData:Void(f$, id:Int)
	Method SetPixmapFromID:Void(pixmap:TPixmap, id:Int, file:String)
	Method SetPreloader:Void(preloader_class:TPixmapPreloader)
	Method Update:Void()
	
End
	

Class TPixmap
	
	Global manager:IPixmapManager ''Use this to Load & Create pixmaps, this is set by render driver
	Global preloader:TPixmapPreloader 
	
	Field width:Int, height:Int
	
	
	
	'' PreLoadPixmap(file$[])
	'' -- returns 1 for finished load from given array
	'' -- GetNumberLoaded() contains number of files loaded
	Function PreLoadPixmap:Int(file$[])
		Return preloader.PreLoad(file)
	End
	
	Function GetNumberLoaded:Int()
		Return preloader.GetNumberLoaded()
	End
		
	
	Function LoadPixmap:TPixmap(f$)
		Return manager.LoadPixmap(f)
	End

	
	Function CreatePixmap:TPixmap(w:Int, h:Int, format:Int=PF_RGBA8888)
		Return manager.CreatePixmap(w,h,format)
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
	
	Method GetPixel:Int( x:Int, y:Int)
		Return 0
	End
	
	Method SetPixel:Void(x:Int, y:Int, r:Int, g:Int, b:Int, a:Int=255)
	End

	
End





Class TPixmapPreloader
	
	Field manager:IPreloadManager
	
	Field loading:Bool = False, loaded:Int = 0, total:Int =0
	Field old_file:String[1]
	Field cur_file:Int=0
	'Field imagebuffer:IPixmapBuffer[]
	
	Method New(m:IPreloadManager)
		manager = m
		manager.SetPreloader(Self)
	End

	Method CheckAllLoaded()
		
		If loaded = total Then loading = False
		
	End
	
	
	Method GetNumberLoaded:Int()
		Return loaded
	End
	
	
	Method IncLoader:Void()
		loaded += 1
		CheckAllLoaded()
	End

	Method PreLoad:Int(file$[])
		
		If Not manager Then Error "**ERROR: no preload manager"
		
		''use for async events
		manager.Update()
		
'Print "loading "+Int(loading)+" "+old_file[0]+"="+file[0]		
		If file[0] <> old_file[0]
		
			loaded = 0
			cur_file = 0
			loading = True
			total = file.Length()
			manager.AllocatePreLoad(total) 'New IBuffer[total]
			
			old_file = file
			
		Elseif ((Not loading) And (file[0] = old_file[0]))
			Return 1
		Endif
		
		If cur_file >= total Then Return 0
		If loading Then cur_file +=1	

'Print "curfile "+cur_file		

		'imagebuffer[cur_file] = New TImageBuffer(Self)
		
		''make sure the paths are correct --do this within tpixmap drivers
		'Local new_file$ = FixDataPath()
		'If Not new_file.StartsWith("monkey://") Then new_file = "monkey://data/"+new_file
		
		'(New AsyncDataLoader(new_file, imagebuffer[cur_file])).Start()
		manager.PreLoadData(file[cur_file-1], cur_file )

		
		Return 0
	
	End
	
	Method GetPixmapPreLoad:Void(p:TPixmap, file$)
		
		Local id:Int = GetID(file)
		manager.SetPixmapFromID(p, id, file)
	
	End
	
	
	Method GetID:Int(file$)
		
		If loaded = 0
	
			Return 0
					
		Else

			For Local i:Int=0 To total-1
				If file = old_file[i] Then Return (i+1)
			Next
			
		Endif
		
		Return 0
		
	End

	
End

