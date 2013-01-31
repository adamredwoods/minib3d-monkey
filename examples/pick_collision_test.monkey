
Import minib3d


Function Main()
	New Game
End

Class Game Extends App

	Field cam:TCamera, cam2:TCamera 
	
	Field light:TLight
	Field sphere1:TMesh
	Field dot:TMesh

	Field txt:TText
	
	' used by fps code
	Field old_ms:Int
	Field renders:Int
	Field fps:Int
	
	Field a:Float=0, dir:Int=0, oldTouchX:Int, oldTouchY:Int, touchBegin:Int

	Field whitebrush:TBrush

	Field nodesprite:TMesh[5000]

	Field init_gl:Bool = False
	
	Field cz:Float, pm:Int
	
	Method OnCreate()
	
		SetUpdateRate 30
		SetRender()
		
	End

	Method Init()
		
		If init_gl Then Return
		init_gl = True
		
		
		cam = CreateCamera()
		cam.CameraClsColor(0,0,80)

		cam2 = CreateCamera
		cam2.CameraViewport 0,0,200,200
		cam2.CameraClsMode(False,True)
		cam2.PositionEntity(0,0,5)

		
		light=CreateLight(1)
		
		dot = CreateSphere(5)
		dot.ScaleEntity(0.2,0.2,0.2)
		dot.EntityColor(0,255,0)

		
		sphere1 = CreateSphere(20)

		
		txt = TText.CreateText(cam)
		txt.NoSmooth()
		txt.HideEntity()
		
		light.PositionEntity 0,3,-3
		cam.PositionEntity 0.5,1,-5

		

		
		whitebrush = New TBrush
		whitebrush.BrushColor(200,200,200)
		sphere1.PaintEntity( whitebrush)

		sphere1.CollisionSetup(1, COLLISION_METHOD_POLYGON, 1.0)		
		sphere1.EntityFX(2)
		sphere1.RotateEntity(145,145,0)
		sphere1.ScaleEntity(2.0,2.0,2.0)
		'sphere1.PositionEntity(2.5,4.2,-4.0)


		
		old_ms=Millisecs()

		
		Print "main: intit done"
	End
	
	Method OnUpdate()	
		Init()
		
		If KeyDown(187)
			'anim_time += 1
			cz +=0.1
			cam.CameraZoom(cz)
		End
		If KeyDown(189)
			'anim_time -= 1
			cz -=0.1
			cam.CameraZoom(cz)
		End

		If KeyHit(KEY_SPACE)
			pm=1-pm
			If pm = 1 Then cam.CameraProjMode(2); cam.CameraZoom(cz) Else cam.CameraProjMode(1)
		Endif
		
		
		
		' control camera
		Local lr:Float = KeyDown(KEY_LEFT)-KeyDown(KEY_RIGHT)
		Local ud:Float = KeyDown(KEY_DOWN)-KeyDown(KEY_UP)
		
		Local camin:Float = KeyDown(KEY_W)-KeyDown(KEY_S)
		Local camup:Float = KeyDown(KEY_D)-KeyDown(KEY_A)
		
		If TouchDown(0) And Not TouchDown(1)
			If Not touchBegin
				oldTouchX = TouchX()
				oldTouchY = TouchY()
				touchBegin = 1
			Endif
			lr = (TouchX() - oldTouchX) * 0.5
			ud = (-TouchY() + oldTouchY) *0.5
			oldTouchX = TouchX()
			oldTouchY = TouchY()
		Elseif TouchDown(1)
			If Not touchBegin
				oldTouchX = TouchX()
				oldTouchY = TouchY()
				touchBegin = 1
			Endif
			camup = (-TouchX() + oldTouchX) * 0.1
			camin = (-TouchY() + oldTouchY) *0.1
			oldTouchX = TouchX()
			oldTouchY = TouchY()
		Else
			touchBegin = 0
		Endif
	
		MoveEntity cam,camup,0,camin
		'sphere1.TurnEntity(ud*2,lr*2,0)
		cam.TurnEntity ud,lr,0

	
'Print PickedX()+" "+PickedY()+" "+PickedZ()

	
		If TouchDown(0)
			Local e:TEntity = cam.CameraPick(TouchX(), TouchY() )
			
			Local surf:TSurface = PickedSurface()
			Local v0:Int, v1:Int, v2:Int
			
			dot.PositionEntity(PickedX(), PickedY(), PickedZ() )
			
			If surf
				v0 = surf.TriangleVertex( PickedTriangle(), 0)
				v1 = surf.TriangleVertex( PickedTriangle(), 1)
				v2 = surf.TriangleVertex( PickedTriangle(), 2)
				
				'Print "*** "+v0+" "+v1+" "+v2
				
				surf.VertexColor(v0,255,0,0)
				surf.VertexColor(v1,255,0,0)
				surf.VertexColor(v2,255,0,0)
				
				'surf.RemoveTri( PickedTriangle)
			Endif
			
			If Not e Then Print "null pick" Else Print e.classname
		Endif

		txt.SetMode2D()	
		txt.SetText(fps+" fps ~nhow are you")
		txt.Draw(0,0)
		
		' calculate fps
		If Millisecs()-old_ms >= 1000
			old_ms=Millisecs()
			fps=renders
			renders=0
		Endif
		
		
		If KeyDown(KEY_ESCAPE)
			Print "clear"
          	ClearWorld()
		End
		
		'UpdateWorld()
		
	End
	
	Method OnRender()
		
		
		RenderWorld()
		renders=renders+1				
		
	End

End

