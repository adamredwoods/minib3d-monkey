
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
		
	Method PreLoadData:Void(f$, file_id:Int)
	Method SetPixmapFromID:Void(pixmap:TPixmap, file_id:Int, file:String)
	Method IsLoaded:Bool(file_id:Int)
	'Method IsLoaded:Bool(file$) ''this is implemented in base class
	
End
	

Class TPixmap
	
	Global manager:IPixmapManager ''Use this to Load & Create pixmaps, this is set by render driver
	Global preloader:TPixmapPreloader 
	
	Field width:Int, height:Int
	Field bind:Int =0
	
	'' slow copy
	Method Copy:TPixmap()
		Return ResizePixmapNoSmooth(width, height)
	End
	
	'' PreLoadPixmap(file$[])
	'' -- returns 1 for finished load from given array, 0 for Unloaded
	'' -- GetNumberLoaded() contains number of files loaded
	Function PreLoadPixmap:Int(file$[]=[""])
		Return preloader.PreLoad(file)
	End
	
	Function GetNumberLoaded:Int()
		Return preloader.GetNumberLoaded()
	End
	
	Function IsLoaded:Bool( p$ )
		Return preloader.IsLoaded( p )
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

	''bind for hardware binding, to avoid duplicating binds for same image
	Method SetBind:Void()
		bind=1
	End
	
	Method ClearBind:Void()
		bind=0
	End
End




Class TPixmapPreloader
	
	Field manager:IPreloadManager
	
	Field loading:Bool = False
	Field total:Int =0 ''using total for ids
	
	Field old_file:String[1]

	Field start_stack:Stack<PixmapStack> = New Stack<PixmapStack>
	Field finish_stack:Stack<PixmapStack> = New Stack<PixmapStack>
	'Field imagebuffer:IPixmapBuffer[]
	
	Method New(m:IPreloadManager)
		manager = m
	End
	
	Method IsLoaded:Bool(f$)
		
		Local id:Int = GetID(f)
		If id=0 Then Return False
		
		Return manager.IsLoaded(id)
	End
	
	Method CheckAllLoaded:int()
		
		'If loaded = total Then loading = False; Return 1
		If start_stack.IsEmpty Then loading = False; Return 1
		Return 0
		
	End
	
	
	Method GetNumberLoaded:Int()
	
		'Return loaded
		Return finish_stack.Length()
		
	End


	'' returns 1 when finished
	Method PreLoad:Int(file$[])
		
		If Not manager Then Error "**ERROR: no preload manager"
		
		''use for async events -- dont need anymore
		'manager.Update()
		
		'' check for new files to add to stack against
		If (file[0] <> old_file[0]) Or (file[file.Length()-1] <> old_file[old_file.Length()-1])
		
			'' add to stack
			For Local f:String = Eachin file
'Print "add "+f
				If f="" Then continue
				
				''check each file if it already exists in start/finish stack
				Local skip:Bool = false
				For Local ss:PixmapStack = Eachin start_stack
					If ss.file = f Then skip = True; Exit
				Next
				For Local ss:PixmapStack = Eachin finish_stack
					If ss.file = f Then skip = True; Exit
				Next
				
				If skip<>True
					total+=1 ''dont use 0
					start_stack.Insert( 0, New PixmapStack(f, FixDataPath(f), total) )
				Endif
				
			Next
			
			old_file = file
		
		Endif
		
			
		'' Main update	
		If Not start_stack.IsEmpty
			
			loading = True
			
			'' load files and pop them when loaded
			Local f:PixmapStack
			
			For f = Eachin start_stack.Backwards() ''FIFO
				
				If f.loading = False '' file is not loading
'Print "start "+f.file+" "+f.id
					manager.PreLoadData( f.file, f.id )
					f.loading = True
					Exit ''one at a time
				Else
'Print "loaded? "+f.id+" "+Int(manager.IsLoaded( f.id ))
					If manager.IsLoaded( f.id ) '' is file loaded? if not, nothing is done
'Print "finish "+f.file+" "+f.id
						start_stack.RemoveEach(f)
						finish_stack.Push(f)

					Endif
				Endif
				
			Next

		Endif

		

		Return CheckAllLoaded()
	
	End
	
	Method GetPixmapPreLoad:Void(p:TPixmap, file$)
	
		Local id:Int = GetID(file)
		manager.SetPixmapFromID(p, id, file)
	
	End
	
	
	Method GetID:Int(file$)
		
		If Not finish_stack.IsEmpty

			For Local i:PixmapStack = Eachin finish_stack

				If i.file = file Or i.new_file = file Then Return i.id

			Next
			
		Endif
		
		Return 0
		
	End

	
End

Class PixmapStack
	
	Field file$, new_file$
	Field id:Int
	Field loading:Bool = false
	
	Method New( f$, nf$, i:Int)
		file=f; new_file = nf; id=i
	End
	
End