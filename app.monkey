
Import minib3d

'' allows opengles20 on GLFW
#OPENGL_GLES20_ENABLED=0
#If OPENGL_GLES20_ENABLED=1
	Import minib3d.opengl.opengles20
#Endif

Class MiniB3DApp Extends App

	Global _resumed:Bool = False
	Global _suspend:Bool = False
	
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
		SetUpdateRate 30
		SetRender()
		PreLoad(["mojo_font.png"])
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
		
		If _resumed
			Graphics3DInit ()
			ReloadAllSurfaces ()
			'ReloadAllTextures ()
			_resumed = False
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
		If Not init
			PreLoadRender()
			Return
		Endif
		
		Render()
		
		RenderWorld	
		renders=renders+1
	End
	
	
	Method PreLoadRender()
	End
	
	Method Render()
	End
	
	Method OnSupsend()
		_suspend=True
		_resumed=false
		Suspend()
	End
	
	Method Suspend()
	End
	
	Method OnResume()
		_resumed = True
		If _suspend
			_suspend = False
			TTexture.ReloadAllTextures()
		Endif
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


