#Rem

Firepaint demo:

Hold down mouse button to emit *FIRE*!

#End

#GLFW_WINDOW_TITLE="Monkey Game"
#GLFW_WINDOW_WIDTH=640
#GLFW_WINDOW_HEIGHT=480
#GLFW_WINDOW_RESIZABLE=false
#GLFW_WINDOW_FULLSCREEN=false

#XNA_WINDOW_WIDTH=1280
#XNA_WINDOW_HEIGHT=720
#XNA_WINDOW_RESIZABLE=false
#XNA_WINDOW_FULLSCREEN=False

Import minib3d
Import minib3d.util.mojo

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

		Local preloadImages:String[] = ["player.png", "bullet.png", "stars.png", 
										"spark.png","mojo_font2.png", "spacer.png","mojo_font.png"]

		If Not TPixmap.PreLoadPixmap(preloadImages)	
			Return
		Endif

		B2DInit() 
		B2DSetFont( Null )
		
		init_gl = True

		dude=B2DLoadImage( "player.png")
		dude.SetHandle(16,17)
		bull=B2DLoadImage( "bullet.png")
		stars=B2DLoadImage( "stars.png")
		sparkImg=B2DLoadImage("spark.png")

		cam = CreateCamera()
		cam.CameraClsColor(0,0,0)
		cam.PositionEntity 0,2.75,-5.5
		cam.RotateEntity(15,0,0)

		light=CreateLight(1)
		light.PositionEntity 0,3,-3
		light.TurnEntity(45,45,45)
		light.LightColor(196,196,196)

		AmbientLight( 150,150,150)
		
		old_ms=Millisecs()
			
		txt = TText.CreateText2D()	
			
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

		' calculate fps
		If Millisecs()-old_ms >= 1000
			old_ms=Millisecs()
			fps=renders
			renders=0
		Endif

		' prevent d3d11 issue
		' it seems that d3d11render needs at least one entitymesh
		txt.SetText(".")
		txt.HideEntity()
		txt.Draw(10,10)

		UpdateWorld()
	End
	

	Method OnRender()

		If ( Not init_gl) Return

		RenderWorld()

		Local t:= Millisecs 

		B2DBeginRender()' alpha blend

			B2DSetBlend(AlphaBlend)
			B2DSetColor(255,255,255)
			B2DSetAlpha(1)
			B2DDrawImage( dude,dude_x, dude_y)

			UpdateEntities bullets

		B2DEndRender()

		B2DBeginRender()' lightblend

			B2DSetBlend(AdditiveBlend)
			UpdateEntities sparks
		
			
			B2DSetColor(150,150,75)
			B2DSetAlpha(0.5)
			B2DDrawRect(0,0,200,100)

			B2DSetColor(255,0,0)
			B2DSetAlpha(1.0)
			
			B2DPushMatrix
			B2DTranslate(100,200)
			B2DRotate(Millisecs*0.1)
			B2DTranslate(-50,-25)
			B2DDrawLine(0,0,100, 0,4)
			B2DDrawLine(0,50,100, 50,4)
			B2DDrawLine(0,0,0,50,4)
			B2DDrawLine(100, 0,100,50,4)
			B2DPopMatrix()
			
			B2DSetColor(0,0,255)
			B2DDrawLine(10,110, DeviceWidth-10,110,1)
			B2DDrawLine(10,DeviceHeight-5, DeviceWidth-10,DeviceHeight-5,1)
			B2DDrawLine(10,110,10,DeviceHeight-5,1)
			B2DDrawLine(DeviceWidth-10,110,DeviceWidth-10,DeviceHeight-5,1)
		
			
			
		B2DEndRender()
		
	
		B2DBeginRender()' alphablend
		
			B2DSetBlend(AdditiveBlend)
			B2DSetColor(255,255,255)
			B2DDrawText("Fps: " + fps,0,0)
			B2DDrawText("B2D: " + blitz2dTime,0,13)
			B2DDrawText("Particles: " + TSpark.Count,0,26)
			
		B2DEndRender()
		 
		
		blitz2dTime = ( Millisecs -t )
		renders=renders+1
	End

End


Const DEPTH=32,HERTZ=60
Const GRAVITY#=.15,SPARKS_PER_FRAME=55
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



Class TColor

	Method RGBColor:TRGBColor() Abstract
	Method CMYColor:TCMYColor() Abstract
	Method HSVColor:THSVColor() Abstract

End Class

Class TRGBColor Extends TColor

	Field _red#,_grn#,_blu#

	Method RGBColor:TRGBColor()
		Return Self
	End Method

	Method CMYColor:TCMYColor()
		Return TCMYColor.CreateCMY( 1-_red,1-_grn,1-_blu )
	End Method

	Method HSVColor:THSVColor()
		Local hmin#=_red
		If _grn<hmin hmin=_grn
		If _blu<hmin hmin=_blu
		Local hmax#=_red
		If _grn>hmax hmax=_grn
		If _blu>hmax hmax=_blu
		If hmax-hmin=0 Return THSVColor.CreateHSV( 0,0,hmax )
		Local hue#,delta#=hmax-hmin
		Select hmax
		Case _red hue=(_grn-_blu)/delta
		Case _grn hue=2+(_blu-_red)/delta
		Case _blu hue=4+(_red-_grn)/delta
		End Select
		hue=hue*60
		If hue<0 hue=hue+360
		Return THSVColor.CreateHSV( hue,delta/hmax,hmax )
	End Method

	Method RED#()
		Return _red
	End Method

	Method GREEN#()
		Return _grn
	End Method

	Method BLUE#()
		Return _blu
	End Method

	Method Set(r#,g#,b#)
		_red=r
		_grn=g
		_blu=b
	End Method

	Function CreateRGB:TRGBColor( RED#,grn#,blu# )
		Local color:TRGBColor=New TRGBColor
		color._red=RED
		color._grn=grn
		color._blu=blu
		Return color
	End Function

End Class

Class TCMYColor Extends TColor

	Field _cyn#,_mag#,_yel#

	Method RGBColor:TRGBColor()
		Return TRGBColor.CreateRGB( 1-_cyn,1-_mag,1-_yel )
	End Method

	Method CMYColor:TCMYColor()
		Return Self
	End Method

	Method HSVColor:THSVColor()
		Return RGBColor().HSVColor()
	End Method

	Method CYAN#()
		Return _cyn
	End Method

	Method MAGENTA#()
		Return _mag
	End Method

	Method YELLOW#()
		Return _yel
	End Method

	Function CreateCMY:TCMYColor( cyn#,mag#,yel# )
		Local color:TCMYColor=New TCMYColor
		color._cyn=cyn
		color._mag=mag
		color._yel=yel
		Return color
	End Function

End Class

Class THSVColor Extends TColor

	Field _hue#,_sat#,_val#

	Method RGBColor:TRGBColor()
		If _sat<=0 Return TRGBColor.CreateRGB( _val,_val,_val )
		Local h#=_hue/60
		Local i#=Floor( h )
		Local f#=h-i
		Local p#=_val*(1-_sat)
		Local q#=_val*(1-(_sat*f))
		Local t#=_val*(1-(_sat*(1-f)))
		Select Int(i)
		Case 0 Return TRGBColor.CreateRGB( _val,t,p )
		Case 1 Return TRGBColor.CreateRGB( q,_val,p )
		Case 2 Return TRGBColor.CreateRGB( p,_val,t )
		Case 3 Return TRGBColor.CreateRGB( p,q,_val )
		Case 4 Return TRGBColor.CreateRGB( t,p,_val )
		Case 5 Return TRGBColor.CreateRGB( _val,p,q )
		End Select
	End Method

	Method CMYColor:TCMYColor()
		Return RGBColor().CMYColor()
	End Method

	Method HSVColor:THSVColor()
		Return Self
	End Method

	Method Hue#()
		Return _hue
	End Method

	Method Saturation#()
		Return _sat
	End Method

	Method Value#()
		Return _val
	End Method

	Function CreateHSV:THSVColor( hue#,sat#,val# )
		If hue<0 hue=hue+360
		If hue>=360 hue=hue-360
		Local color:THSVColor=New THSVColor
		color._hue=hue
		color._sat=sat
		color._val=val
		Return color
	End Function

End Class

Global RED:TColor=RGBColor( 1,0,0 )
Global GREEN:TColor=RGBColor( 0,1,0 )
Global BLUE:TColor=RGBColor( 0,0,1 )

Global ORANGE:TColor=RGBColor( 1,1,0 )

Global CYAN:TColor=CMYColor( 1,0,0 )
Global MAGENTA:TColor=CMYColor( 0,1,0 )
Global YELLOW:TColor=CMYColor( 0,0,1 )

Global BLACK:TColor=HSVColor( 0,0,0 )
Global WHITE:TColor=HSVColor( 0,0,1 )
Global GRAY:TColor=HSVColor( 0,0,.5 )
Global DARKGRAY:TColor=HSVColor( 0,0,.25 )
Global LIGHTGRAY:TColor=HSVColor( 0,0,.75 )

#Rem
bbdoc: Create a red, green, blue color
returns: A new color object
about: @red, @grn and @blu should be in the range 0 to 1.
#End 
Function RGBColor:TRGBColor( RED#,grn#,blu# )
	Return TRGBColor.CreateRGB( RED,grn,blu )
End Function

#Rem
bbdoc: Create a cyan, magenta, yellow color
returns: A new color object
about: @cyn, @mag and @yel should be in the range 0 to 1.
#End
Function CMYColor:TCMYColor( cyn#,mag#,yel# )
	Return TCMYColor.CreateCMY( cyn,mag,yel )
End Function

#Rem
bbdoc: Create a hue, saturation, value color
returns: A new color object
about: @hue should be in the range 0 to 360, @sat and @val should be in the range 0 to 1.
#End
Function HSVColor:THSVColor( hue#,sat#,val# )
	Return THSVColor.CreateHSV( hue,sat,val )
End Function

#Rem
bbdoc: Get red component of a color
returns: Red component of @color in the range 0 to 1
#End
Function ColorRed#( color:TColor )
	Return color.RGBColor().RED()
End Function

#Rem
bbdoc: Get green component of a color
returns: Green component of @color in the range 0 to 1
#End
Function ColorGreen#( color:TColor )
	Return color.RGBColor().GREEN()
End Function

#Rem
bbdoc: Get blue component of a color
returns: Blue component of @color in the range 0 to 1
#End
Function ColorBlue#( color:TColor )
	Return color.RGBColor().BLUE()
End Function

#Rem
bbdoc: Get cyan component of a color
returns: Cyan component of @color in the range 0 to 1
#End
Function ColorCyan#( color:TColor )
	Return color.CMYColor().CYAN()
End Function

#Rem
bbdoc: Get magenta component of a color
returns: Magenta component of @color in the range 0 to 1
#End
Function ColorMagenta#( color:TColor )
	Return color.CMYColor().MAGENTA()
End Function

#Rem
bbdoc: Get yellow component of a color
returns: Yellow component of @color in the range 0 to 1
#End
Function ColorYellow#( color:TColor )
	Return color.CMYColor().YELLOW()
End Function

#Rem
bbdoc: Get hue component of a color
returns: Hue component of @color in the range 0 to 360
#End
Function ColorHue#( color:TColor )
	Return color.HSVColor().Hue()
End Function

#Rem
bbdoc: Get saturation component of a color
returns: Saturation component of @color in the range 0 to 1
#End
Function ColorSaturation#( color:TColor )
	Return color.HSVColor().Saturation()
End Function

#Rem
bbdoc: Get value component of a color
returns: Value component of @color in the range 0 to 1
#End
Function ColorValue#( color:TColor )
	Return color.HSVColor().Value()
End Function