
Import minib3d

''note: if your models look weird, config.h depth buffer bits=32

Function Main()
	New Game
End

Class Game Extends App
	
	Field cam:TCamera
	
	Field light:TLight
	Field cube:TMesh, ground:TMesh
	Field zombie:TMesh[1000]
	Field txt:TText
	
	' used by fps code
	Field old_ms:Int
	Field renders:Int
	Field fps:Int
	
	Field a:Float=0, dir:Int=0, oldTouchX:Int, oldTouchY:Int, touchBegin:Int, lr#, ud#
	Field anim_time:Int
	
	Field redbrush:TBrush

	Field init_gl:Bool = False
	
	Field zombie_tex:TTexture
	
	Method OnCreate()
	
		SetRender()	
		SetUpdateRate 30
		
	End

	Method Init()
		
		If init_gl Then Return
		
		If Not TPixmap.PreLoadPixmap(["Zombie.jpg","mojo_font.png"])	
			Return
		Endif
		
		
		init_gl = True

		
		cam = CreateCamera()
		cam.CameraClsColor(0,0,80)
		cam.PositionEntity 0,4,-10
		
		
		
		zombie[0]=LoadAnimMesh("zombie_b3d_base64.txt")
		TAnimation.NormaliseWeights(zombie[0])
		TAnimation.BoneToVertexAnim(zombie[0])
		
		ScaleEntity zombie[0],0.4,0.4,0.4
		Local xx:Int=1, zx:Int=0
		For Local zz:Int = 1 To 3

			zombie[zz] = TMesh(zombie[0].CopyEntity())
			zombie[zz].SetAnimTime(zz*10)
			zombie[zz].PositionEntity(xx*2,0,zx*2)
			xx = xx+1
			If xx > 9 Then xx=0; zx +=2
		Next
		
	
		anim_time=0
		
		light=CreateLight(1)
		light.PositionEntity 0,3,-3
		
		cube=CreateCube()
		cube.ScaleEntity(0.5,0.5,0.5)
		cube.name = "cube"
		PositionEntity cube,-2,2,2
				
		redbrush = New TBrush
		redbrush.BrushColor(200,20,20)	
		cube.PaintEntity( redbrush)
		
		txt = TText.CreateText2D()
		'txt.NoSmooth()
		
		ground = CreateGrid(10,10)
		ground.ScaleEntity(20,1.0,20)
		
		old_ms=Millisecs()
		
		'Wireframe(True)
		
		Print "main: init done"
	End
	
	Method OnUpdate()
		
		If Not init_gl Then Init(); Return
		
		' control camera
		Local cr:Float = KeyDown(KEY_LEFT)-KeyDown(KEY_RIGHT)
		Local cu:Float = KeyDown(KEY_DOWN)-KeyDown(KEY_UP)
		
		Local camin:Float = KeyDown(KEY_W)-KeyDown(KEY_S)
		Local camup:Float = KeyDown(KEY_D)-KeyDown(KEY_A)
		
		Local turnzx:Float = KeyDown(KEY_Z)-KeyDown(KEY_X)
		
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
		
		TurnEntity cube,turnzx*2,0,0
		MoveEntity cube,(lr)*0.2,0,ud*0.1'camup,0,camin
		
		cam.MoveEntity camup,0,camin
		cam.TurnEntity cu,cr,0

		For Local zz:Int=0 To 3
			zombie[zz].AlignToVector(cube.EntityX(1) - zombie[zz].EntityX(1), 0,cube.EntityZ(1) - zombie[zz].EntityZ(1), 3,0.10)
		Next	
	
		
		If Not zombie[0].Animating()
			Local speed# = 1.0
			For Local zz:Int=0 To 3
				zombie[zz].Animate(1,speed)
				speed -= 0.25
			Next
		Endif
		
		
		If KeyDown(187)
			anim_time += 1
		End
		If KeyDown(189)
			anim_time -= 1
		End


		txt.SetText(fps+" fps ~nhow are you")
		txt.HideEntity()
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

		RenderWorld()
		renders=renders+1
					
	End

End
