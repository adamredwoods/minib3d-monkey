' Original firepaint3d.bb program by Mark Sibly

'Import minib3d.opengl.opengles20
Import minib3d


Function Main()
	New Game
End

Class Frag
	Field ys#,alpha#
	Field entity:TBatchSprite ''change to TEntity for using a Sprite or Mesh
	Field fraglink:list.Node<Frag>
	
	Field active:Int =0
	Global total:Int =0
	
	Function Inc()
		total +=1
		If total>MAX Then total=0
	End
End

Class Game Extends App
	
	Const grav#=-.02,intensity=5
	
	Field fraglist:List<Frag> = New List<Frag>
	Field pivot:TPivot, camera:TCamera, camera2:TCamera, cursor:TMesh, sky:TMesh, tex:TTexture, spark:TMesh
	Field light:TLight, txt:TText
	Field bspark:TBatchSprite

	
	Field time:Int, old_ms:Int, renders:Int, fps:Int
	Field x_speed#,y_speed#, num, dt, elapsed

	
	Global reload_all:Bool=False
	Global init_global:Int = 0
	
	Method OnResume()
		reload_all = True
		
	End
	
	Method Init:Int()
		
		If init_global Then Return 1
		
		''use to preload images for html5
		
		If Not TPixmap.PreLoadPixmap(["blitzlogo.png","stars.png","bluspark.png","mojo_font.png"])	
			Return 0
		Endif
		
		init_global = 1
		
		''--- try this other shader for faster mobile performance (opengles2.0 only)		
		'TShaderGLSL.LoadDefaultShader(New FastBrightShader)

		
		
		AmbientLight 0,0,0
		
		pivot=CreatePivot()
		
		camera=CreateCamera(pivot)
		
		camera.CameraFogMode(0)
		
		
		'create blitzlogo 'cursor'
		cursor=CreateSphere(8,camera)
		EntityTexture cursor,LoadTexture("blitzlogo.png")
		MoveEntity cursor,0,0,25
		EntityBlend cursor,3
		EntityFX cursor,1

	
		txt = CreateText3D()
		txt.EntityParent(cursor,False)
		
		'create sky sphere
		sky=CreateSphere()
		tex=LoadTexture( "stars.png" )
		ScaleTexture tex,.125,.25
		EntityTexture sky,tex
		ScaleEntity sky,500,500,500
		EntityFX sky,1
		FlipMesh sky
		sky.EntityOrder(1) ''render first
		
		TBatchSprite.LoadBatchTexture("bluspark.png")
		TBatchSprite.BatchSpriteParent(1, cursor, True) ''SpriteBatch cannot be same place as camera
		
		spark = LoadSprite("bluspark.png")
		'spark = CreateSphere(4)

		time=Millisecs()

		' used by fps code
		old_ms=Millisecs()
		
	End
	
	Method OnCreate()
		
		SetRender()
		SetUpdateRate 30

	End

	Method OnUpdate()
		
		If Not Init() Then Return
		
		If reload_all
			Graphics3DInit()
			ReloadAllSurfaces()
			ReloadAllTextures()
			Print "....reload complete...."
			reload_all = False
		Endif

		If KeyDown(KEY_ESCAPE) Then Error ""

		elapsed=Millisecs()-time	
		time=time+elapsed
		dt=elapsed*60.0/1000.0
		
	
		x_speed=(MouseX()-DeviceWidth*0.5 )/2
		y_speed=(MouseY()-DeviceHeight*0.5 )/2
	
		RotateEntity pivot,0,-x_speed,0	'turn player Left/Right
		RotateEntity camera,-y_speed,0,0	'tilt camera
		TurnEntity cursor,0,dt*5.0,0

	
		If MouseDown()
			For Local t:=1 To intensity'*3
				
				Local f:Frag=New Frag
				'f.entity = spark.CopyEntity( )
				f.entity = TBatchSprite.CreateSprite( )
				
				f.ys=0
				f.alpha=Rnd(2,3)

				f.entity.PositionEntity (cursor.EntityX(1), cursor.EntityY(1),cursor.EntityZ(1))
				
				ShowEntity f.entity
				
				f.entity.EntityColor Rnd(255),Rnd(255),Rnd(255)
				f.entity.RotateEntity Rnd(360),Rnd(360),Rnd(360)
				num=num+1
				f.fraglink = fraglist.AddLast(f)
			Next
		Endif
		
		
		
		Local n_parts=0
		Local n_surfs=0
		For Local f:Frag=Eachin fraglist
			
			f.alpha=f.alpha-dt*.02
			If f.alpha>0
				Local al#=f.alpha
				If al>1.0 Then al=1.0
				f.entity.EntityAlpha (al)
				f.entity.MoveEntity (0,0,dt * 0.4 )
				Local ys#=f.ys+grav*dt
				Local dy#=f.ys*dt
				f.ys=ys
				f.entity.TranslateEntity(0,dy,0)
			Else
								
				f.fraglink.Remove()
				FreeEntity f.entity
				num=num-1
			Endif
		Next
		
	
		txt.SetText("" ,3,2,0)
		If renders=1 Then txt.SetText(fps+" fps"+"~n "+num,3,2,0) ''update only so often
	
	End
	
	Method OnRender()
		
		If Not Init() Then Return
		
		RenderWorld
		renders=renders+1

		' calculate fps
		If Millisecs()-old_ms>=1000
			old_ms=Millisecs()
			fps=renders
			renders=0
		Endif
		
	End
End
