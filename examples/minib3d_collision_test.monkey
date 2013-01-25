
''Collision example
Import mojo
Import minib3d

Function Main()
	New Game
End

Class Game Extends App

	Field width:Int=640,height:Int=480,depth:Int=0,mode:Int=2
	
	Field cam:TCamera , cam2:TCamera
	
	Field light:TLight
	Field cube:TMesh
	Field sphere1:TMesh, sphere2:TMesh, cylinder:TMesh 
	Field cone:TMesh 
	Field dot:TMesh, monkey:TMesh, dot3:TMesh
	Field testmesh:TMesh
	
	Field txt:TText
	
	' used by fps code
	Field old_ms:Int
	Field renders:Int
	Field fps:Int
	
	Field a:Float=0, dir:Int=0, oldTouchX:Int, oldTouchY:Int, touchBegin:Int

	Field dotx:Float, dotdir:Float=0.5
	
	Field whitebrush:TBrush
	Field redbrush:TBrush, greenbrush:TBrush

	Field tex1:TTexture

	Field init_gl:Bool = False
	
	Method OnCreate()
		SetUpdateRate 30
	End

	Method Init()
		
		If init_gl Then Return
		init_gl = True
		
		SetRender()
		
		cam = CreateCamera()
		cam.CameraClsColor(0,0,80)
		
		dot = CreateSphere()
		dot.ScaleEntity (0.1,0.1,0.1)
		dot.EntityColor(255,0,0)
		dot.PositionEntity(0.0,1.1,0.0)
		
		'monkey = CreateCube()
		monkey = CreateMiniB3DMonkey()
		
		'monkey.EntityColor(200,200,255)
		'monkey.ScaleEntity(0.2,0.2,0.2)
		monkey.ScaleEntity(0.2,0.2,0.2)
		monkey.PositionEntity(0.5,-0.5,0.0)

		
		dot3 = CreateSphere()
		dot3.ScaleEntity (0.1,0.1,0.1)
		dot3.EntityColor(0,200,0)
		
		light=CreateLight(1)
		
		'sphere1 = CreateSphere()
		sphere1 = CreateCube()
		'sphere1 = LoadMesh("zombie_b3d_base64.txt")
		'sphere1=CreateMesh()
		
		cylinder = CreateCylinder()
		cone = CreateCone()
	
		txt = CreateText2D()
		txt.HideEntity()
		
		light.PositionEntity 0,3,-3
		cam.PositionEntity 0.5,1,-5
		
		'PositionEntity cube,-2,0,0
		PositionEntity sphere1,-1,-0.5,0
		'sphere1.RotateEntity(145,145,0)
		ScaleEntity sphere1,0.7,0.7,0.7
		PositionEntity cylinder,2,0,5
		PositionEntity cone,4,0,0
		RotateEntity cone,-90,0,0
		
		cylinder.EntityParent(cone, True)

		
		whitebrush = New TBrush
		whitebrush.BrushColor(200,200,200)
		
		redbrush = New TBrush
		redbrush.BrushColor(200,20,20)
		
		greenbrush = New TBrush
		greenbrush.BrushColor(20,200,20)

		sphere1.PaintEntity( whitebrush)
		cylinder.PaintEntity(greenbrush)
		cylinder.EntityAlpha(0.7)

		
		'' new method CollisionSetup(group_id, collision method, size of sphere or box)
		
		cone.CollisionSetup(1, COLLISION_METHOD_POLYGON, 1.0)
		sphere1.CollisionSetup(1, COLLISION_METHOD_BOX, 1.0)
		monkey.CollisionSetup(1, COLLISION_METHOD_POLYGON)

		cylinder.CollisionSetup(1, COLLISION_METHOD_POLYGON, 2.0) '-1.0,-1.0,-1.0,2.0,2.0,2.0)
		cylinder.RotateEntity(0,0,45)
		
		Collisions(1,1,COLLISION_METHOD_POLYGON,COLLISION_RESPONSE_SLIDEXZ)
		
		sphere1.EntityFX(2)
		cone.EntityFX(2)
		
		old_ms=Millisecs()
	
		
		'Wireframe(True)
		
		Print "main: intit done"
	End
	
	Method OnUpdate()
			
		If Not init_gl Then Return
		
		' control camera
		Local lr:Float = KeyDown(KEY_LEFT)-KeyDown(KEY_RIGHT)
		Local ud:Float = KeyDown(KEY_DOWN)-KeyDown(KEY_UP)
		
		Local lr2:Float = KeyDown(KEY_H)-KeyDown(KEY_F)
		Local ud2:Float = KeyDown(KEY_T)-KeyDown(KEY_G)
		
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
	
		MoveEntity cam,lr2,0,ud2
		cam.TurnEntity ud,lr,0

		
		
		If TouchDown(0)
			Local e:TEntity = cam.CameraPick(TouchX(), TouchY() )
			
			Local surf:TSurface = PickedSurface()
			Local v0:Int, v1:Int, v2:Int
			
			'Print CollisionTriangle(sphere1,1)
			'Print "pt: "+PickedTriangle()
			
			If surf
				v0 = surf.TriangleVertex( PickedTriangle(), 0)
				v1 = surf.TriangleVertex( PickedTriangle(), 1)
				v2 = surf.TriangleVertex( PickedTriangle(), 2)
				
				'Print v0+" "+v1+" "+v2
				
				surf.VertexColor(v0,255,0,0)
				surf.VertexColor(v1,255,0,0)
				surf.VertexColor(v2,255,0,0)
				
				'surf.RemoveTri( PickedTriangle)
			Endif
			
			dot.PositionEntity(PickedX(),PickedY(),PickedZ())
			
			If Not e Then Print "null pick" Else Print e.classname
		Endif

		
		monkey.MoveEntity(camup*0.1,0,camin*0.1)

		'dot.PositionEntity(CollisionInfo.testx,CollisionInfo.testy,CollisionInfo.testz)
		If monkey.collision.impact Then dot.PositionEntity( monkey.CollisionX(), monkey.CollisionY(), monkey.CollisionZ())
		


		'txt.SetMode2D()	
		txt.SetText(fps+" fps ~nhow are you")
		txt.Draw(0,0)
		
		
		' calculate fps
		If Millisecs()-old_ms >= 1000
			old_ms=Millisecs()
			fps=renders
			renders=0
		Endif
		
		UpdateWorld()

		
	End
	
	Method OnRender()
		Init()

		RenderWorld()

		renders=renders+1
				
		
	End

End

