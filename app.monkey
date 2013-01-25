
Import minib3d

Class Minib3dApp Extends App

	Global Resumed:Bool = False
	
	Field init:Int=0
	
	' used by fps code
	Field old_ms:Int
	Field renders:Int
	Field fps:Int
	Field timer:Int =0
	
	Field preload_list:StringList = New StringList
	
	Method PreLoad(f$)
		preload_list.AddLast(f)
	End
	
	Method PreLoad(f$[])
		For Local s$ = Eachin f
			preload_list.AddLast(s)
		Next
	End
	
	Method OnCreate()
		SetRender()
		SetUpdateRate 30
		PreLoad("mojo_font.png")
		Create()
		Minib3dInit()	
	End
	
	Method Create()
	End
	
	Method Minib3dInit:Void()
		If init Then Return
		If Not TPixmap.PreLoadPixmap(preload_list.ToArray()) Then Return
		init=1
		Init()
		init=2
	End
	
	Method Init()
	End
	
	Method OnUpdate()
	
		If Not init
			Minib3dInit()
			Return
		Endif
		
		If Resumed
			Graphics3DInit ()
			ReloadAllSurfaces ()
			ReloadAllTextures ()
			Resumed = False
		Endif
		
		Update()
		
		' calculate fps
		If Millisecs()-old_ms >= 1000
			old_ms=Millisecs()
			fps=renders
			renders=0
			'Print "fps "+fps
		Endif
		
	End
	
	Method Update()
	End
	
	Method OnRender()
		Render()
		RenderWorld	
		renders=renders+1
	End
	
	Method Render()
	End
	
	Method OnSupsend()
		Suspend()
	End
	
	Method Suspend()
	End
	
	Method OnResume()
		Resumed = True
		Resume()
	End
	
	Method Resume()
	End
	
End


'' TO USE
'' extend the Minib3dApp
'' and overload Methods
''
''	Method Create ()
''		SetUpdateRate 30	
''		AddPreLoad(files) here	
''	End
''  Method Init ()
''     Add camera, light, and model loading, creation, texture modifying here
''  End


