#MINIB3D_D3D11_RELEASE="true" 
#MINIB3D_D3D11_PER_PIXEL_LIGHTING="false"
#TEXT_FILES="*.txt|*.xml|*.json|*.obj"

Import minib3d
Import minib3d.util.blitz2d

Import color

''note: if your models look weird, config.h depth buffer bits=32

Function Main()
	New Game
End

Global WIDTH=640,HEIGHT=480

Global dude:B2DImage,dude_x=WIDTH/2,dude_y=HEIGHT-30
Global bull:B2DImage,bull_x,bull_y
Global stars:B2DImage,stars_x,stars_y
Global sparkImg:B2DImage
Global show_debug,color_rot#

Class Game Extends App
	
	Field cam:TCamera
	Field light:TLight
	Field txt:TText
	
	' used by fps code
	Field old_ms:Int
	Field renders:Int
	Field fps:Int
	Field init_gl:Bool = False
	Field blitz2dTime = 0
	
	Method OnCreate()
		SetRender()	
		SetUpdateRate 60
		WIDTH = DeviceWidth
		HEIGHT = DeviceHeight 
		dude_x=WIDTH/2
		dude_y=HEIGHT-30
	End

	Method Init()
		
		If init_gl Then Return
		
		Local preloadImages:String[] = ["player.png", "bullet.png", "stars.png", "spark.png","mojo_font.png"]
				
		If Not TPixmap.PreLoadPixmap(preloadImages)	
			Return
		Endif
		
		
		init_gl = True

		dude=B2DLoadImage( "player.png" ,1,B2DImage.MidHandle,4)
		dude.SetHandle(16,17)
		bull=B2DLoadImage( "bullet.png" ,1,B2DImage.MidHandle,4)
		stars=B2DLoadImage( "stars.png" ,1,B2DImage.MidHandle,4)
		sparkImg=B2DLoadImage("spark.png",1,B2DImage.MidHandle,4)

		cam = CreateCamera()
		cam.CameraClsColor(0,0,0)
		cam.PositionEntity 0,2.75,-5.5
		cam.RotateEntity(15,0,0)
		
		light=CreateLight(1)
		light.PositionEntity 0,3,-3
		light.TurnEntity(45,45,45)
		light.LightColor(196,196,196)
		
		AmbientLight( 150,150,150)
		
		txt = TText.CreateText2D()	
		old_ms=Millisecs()
		
		Print "main: init done"
	End

	Method OnUpdate()
		
		If Not init_gl Then Init(); Return
		
		stars_y+=1
		
		If MouseDown(MOUSE_LEFT)
			color_rot+=1.5
			color_rot= color_rot Mod 360
			 
			Local color:TRGBColor=HSVColor( color_rot,1.0,1.0 ).RGBColor()
			Local rgb[]=[Int(color.RED()*255.0),Int(color.GREEN()*255),Int(color.BLUE()*255.0)]
	
			For Local k=1 To SPARKS_PER_FRAME
				TSpark.CreateSpark MouseX(),MouseY(),rgb
			Next

		Endif
		
		If KeyDown( KEY_LEFT )
			dude_x-=5
		Else If  KeyDown( KEY_RIGHT )
			dude_x+=5
		EndIf

		If KeyHit( KEY_SPACE )
			TBullet.CreateBullet dude_x,dude_y-16,bull
		EndIf


		txt.SetText(fps+" fps ~nhow are you ~nBlitz2D: " + blitz2dTime + "~nSparks: " + TSpark.Count)
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

		If ( Not init_gl) Return

		RenderWorld()
		
		Local t:= Millisecs 

		B2DBeginRender(1)' alpha blend
			
			B2DSetColor(255,255,255)
			B2DSetAlpha(1)
			B2DDrawImage( dude,dude_x, dude_y)
			
			UpdateEntities bullets
			
		B2DEndRender()
	
			
		B2DBeginRender(3)' additive blend
		 
			UpdateEntities sparks
			
		B2DEndRender()
		
		blitz2dTime = ( Millisecs -t )
		renders=renders+1
	End
	
End


Const DEPTH=32,HERTZ=60
Const GRAVITY#=.15,SPARKS_PER_FRAME=35
Global sparks:List<TEntity2>=New List<TEntity2>
Global bullets:List<TEntity2>=New List<TEntity2>

Class TEntity2

	Field list:List<TEntity2>

	Method remove()
		list.Remove(Self)
	End Method

	Method AddLast( list:List<TEntity2> )
		Self.list = list
		list.AddLast( Self )
	End Method

	Method Update() Abstract

End 

Class TSpark Extends TEntity2

	Global Count = 0
	
	Field x#,y#,xs#,ys#
	Field color[3],rot#,rots#

	Method Update()

		ys+=GRAVITY
		x+=xs
		y+=ys

		If x<0 Or x>=WIDTH Or y>=HEIGHT
			remove
			Count-=1
			Return
		EndIf

		rot=rot+rots

		B2DSetAlpha 1.0-y/Float(HEIGHT)
		B2DSetColor color[0],color[1],color[2]
		B2DDrawImage sparkImg,x,y, rot,1,1
		

	End Method

	Function CreateSpark:TSpark( x#,y#,color[] )
		Local spark:TSpark=New TSpark
		Local an#=Rnd(360),sp#=Rnd(3,5)
		spark.x=x
		spark.y=y
		spark.xs=Cos(an)*sp
		spark.ys=Sin(an)*sp
		spark.rots=Rnd(-15,15)
		spark.color=color
		spark.AddLast sparks
		Count+=1
		Return spark
	End Function

End 

Class TBullet Extends TEntity2

	Field x#,y#,ys#
	Field rot#,img:B2DImage

	Method Update()
		ys-=.01
		y+=ys
		If y<0
			remove
			Return
		EndIf
		rot+=3
		B2DDrawImage img,x,y,rot,1,1
	End Method

	Function CreateBullet:TBullet( x#,y#,img:B2DImage )
		Local bullet:TBullet=New TBullet
		bullet.x=x
		bullet.y=y
		bullet.ys=-1 
		bullet.img=img
		bullet.AddLast bullets
		Return bullet
	End Function

End 

Function UpdateEntities( list:List<TEntity2> )
	For Local entity:TEntity2=EachIn list
		entity.Update
	Next
End Function
