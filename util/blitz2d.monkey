' Author Sascha Schmidt
' From mojo.graphics Copyright 2011 Mark Sibly, all rights reserved.

#rem

issues:

- d3d11 does only work if at one point an 'entity' was rendered by renderworld

#end 

Import minib3d
Import minib3d.util.spritebatch

Private

Global Batch:BBSpriteBatch
Global textureContainer:B2DImage

Function DebugRenderDevice()
	If Not Batch Error "Rendering operations can only be performed within B2DBeginRender and B2DEndRender"
End

Class B2DFrame

	Field x,y

	Method New( x,y )
		Self.x=x
		Self.y=y
	End

End

Class GraphicsContext

	'Field color_r#,color_g#,color_b#
	'Field alpha#
	'Field blend
	'Field ix#=1,iy#,jx#,jy#=1,tx#,ty#,tformed,matDirty
	'Field scissor_x#,scissor_y#,scissor_width#,scissor_height#
	'Field matrixStack:=New Float[6*32],matrixSp
	
	Field font:B2DImage,firstChar,defaultFont:B2DImage

#rem
	Method Validate()
		If matDirty
			renderDevice.SetMatrix context.ix,context.iy,context.jx,context.jy,context.tx,context.ty
			matDirty=0
		Endif
	End
#end 

End

'Global device:GraphicsDevice
'Global renderDevice:GraphicsDevice

Global context:GraphicsContext=New GraphicsContext

Public 

Class B2DImage

	Const MidHandle=1

	Const XPadding=2
	Const YPadding=4
	Const XYPadding=XPadding|YPadding

	Global DefaultFlags

	Method Width()
		Return width
	End

	Method Height()
		Return height
	End

	Method Frames()
		Return frames.Length
	End

	Method Flags()
		Return flags
	End

	Method HandleX#()
		Return tx
	End

	Method HandleY#()
		Return ty
	End

	Method GrabImage:B2DImage( x,y,width,height,frames=1,flags=DefaultFlags )
		If Self.frames.Length<>1 Return
		Return (New B2DImage).Grab( x,y,width,height,frames,flags,Self )
	End

	Method SetHandle( tx#,ty# )
		Self.tx=tx
		Self.ty=ty
		Self.flags=Self.flags & ~MidHandle
	End

	Method Discard()
		If surface And Not source
			surface.FreeTexture()
			surface=Null
		Endif
	End


Private

	Const FullFrame=65536	'$10000

	Field source:B2DImage
	Field surface:TTexture
	Field width,height,flags
	Field frames:B2DFrame[]
	Field tx#,ty#

	Method Init:B2DImage( surf:TTexture,nframes,iflags )

		surface = surf
		width=surface.width/nframes
		height=surface.height
		
		frames=New B2DFrame[nframes]
		For Local i=0 Until nframes
			frames[i]=New B2DFrame( i*width,0 )
		Next

		ApplyFlags iflags
		Return Self
	End

	Method Grab:B2DImage( x,y,iwidth,iheight,nframes,iflags,source:B2DImage )
		Self.source=source
		Self.surface=source.surface

		width=iwidth
		height=iheight

		frames=New B2DFrame[nframes]

		Local ix:=x,iy:=y

		For Local i=0 Until nframes
			If ix+width>source.width
				ix=0
				iy+=height
			Endif
			If ix+width>source.width Or iy+height>source.height
				Error "Image frame outside surface"
			Endif
			frames[i]=New B2DFrame( ix+source.frames[0].x,iy+source.frames[0].y )
			ix+=width
		Next

		ApplyFlags iflags
		Return Self
	End

	Method ApplyFlags( iflags )
		flags=iflags

		If flags & XPadding
			For Local f:=Eachin frames
				f.x+=1
			Next
			width-=2
		Endif

		If flags & YPadding
			For Local f:=Eachin frames
				f.y+=1
			Next
			height-=2
		Endif

		If flags & Image.MidHandle
			SetHandle width/2.0,height/2.0
		Endif

		If frames.Length=1 And frames[0].x=0 And frames[0].y=0 And width=surface.width And height=surface.height
			flags|=FullFrame
		Endif
	End

End	

Function B2DLoadImage:B2DImage( path$,frameCount=1,flags=B2DImage.DefaultFlags)
	Local surf:= LoadTexture(path, 2 | 16 | 32 | TTexture.PRESERVE_SIZE)
	If surf Then Return New B2DImage().Init(surf,frameCount,flags )
End

Function B2DLoadImage:B2DImage( path$,frameWidth,frameHeight,frameCount,flags= B2DImage.DefaultFlags)
	Local atlas:=B2DLoadImage( path,1,flags )
	If atlas Return atlas.GrabImage( 0,0,frameWidth,frameHeight,frameCount)
End

Function B2DInit()
	if Not Batch Then 
		Batch = New BBSpriteBatch
		textureContainer = New B2DImage
		textureContainer.flags|=B2DImage.FullFrame
		textureContainer.frames = New B2DFrame[1]
		textureContainer.frames[0] = New B2DFrame
		textureContainer.frames[0].x = 0
		textureContainer.frames[0].y = 0
	EndIf
End 

Function B2DEnd()
	Batch = Null
End 

Function B2DBeginRender(blend = 1)
	Batch.BeginRender(blend)
End 


Function B2DDrawImage( image:B2DImage,x#,y#,frame=0 )

#If CONFIG="debug"
	DebugRenderDevice
	If frame<0 Or frame>=image.frames.Length Error "Invalid image frame"
#End

	Local f:=image.frames[frame]

	If Batch.tformed Then 

		B2DPushMatrix
		B2DTranslate x-image.tx,y-image.ty

		If image.flags & B2DImage.FullFrame
			Batch.Draw image.surface,0,0
		Else
			Batch.Draw image.surface,0,0,image.width, image.height,f.x,f.y,image.width,image.height
		Endif

		B2DPopMatrix

	Else

		If image.flags & B2DImage.FullFrame
			Batch.Draw image.surface,x-image.tx,y-image.ty
		Else
			Batch.Draw image.surface,x-image.tx,y-image.ty,image.width, image.height,f.x,f.y,image.width,image.height
		Endif

	Endif

End

Function B2DDrawImage( image:B2DImage,x#,y#,rotation#,scaleX#,scaleY#,frame=0 )

#If CONFIG="debug"
	DebugRenderDevice
	If frame<0 Or frame>=image.frames.Length Error "Invalid image frame"
#End


	Local f:=image.frames[frame]

	B2DPushMatrix

	B2DTranslate x,y
	B2DRotate rotation
	B2DScale scaleX, scaleY
	B2DTranslate -image.tx,-image.ty

	If image.flags & B2DImage.FullFrame
		Batch.Draw(image.surface, 0,0)
	Else
		Batch.Draw( image.surface,0,0,image.width, image.height,f.x,f.y,image.width,image.height)
	Endif

	B2DPopMatrix

End

Function B2DDrawImageRect( image:B2DImage,x#,y#,srcX,srcY,srcWidth,srcHeight,frame=0 )

#If CONFIG="debug"
	DebugRenderDevice
	If frame<0 Or frame>=image.frames.Length Error "Invalid image frame"
	If srcX<0 Or srcY<0 Or srcX+srcWidth>image.width Or srcY+srcHeight>image.height Error "Invalid image rectangle"
#End

	Local f:=image.frames[frame]

	If Batch.tformed Then 
		B2DPushMatrix

		B2DTranslate -image.tx+x,-image.ty+y

		Batch.Draw image.surface,0,0,srcX+f.x,srcY+f.y,srcWidth,srcHeight

		B2DPopMatrix
	Else

		Batch.Draw image.surface,-image.tx+x,-image.ty+y,srcX+f.x,srcY+f.y,srcWidth,srcHeight
	Endif

End

Function B2DDrawImageRect( image:B2DImage,x#,y#,srcX,srcY,srcWidth,srcHeight,rotation#,scaleX#,scaleY#,frame=0 )

#If CONFIG="debug"
	DebugRenderDevice
	If frame<0 Or frame>=image.frames.Length Error "Invalid image frame"
	If srcX<0 Or srcY<0 Or srcX+srcWidth>image.width Or srcY+srcHeight>image.height Error "Invalid image rectangle"
#End


	Local f:=image.frames[frame]

	If Batch.tformed Then 

		B2DPushMatrix
		B2DTranslate -image.tx+x,-image.ty+y

		Batch.Drawimage image.surface,0,0,srcX+f.x,srcY+f.y,srcWidth,srcHeight

		B2DPopMatrix

	Else

		Batch.Draw image.surface,-image.tx+x,-image.ty+y,srcX+f.x,srcY+f.y,srcWidth,srcHeight

	End 

End

Function B2DDrawTextureRect( texture:TTexture,x#,y#,srcX,srcY,srcWidth,srcHeight)

#If CONFIG="debug"
	DebugRenderDevice
#End

	textureContainer.surface = texture
	textureContainer.width = texture.width
	textureContainer.height = texture.height
	B2DDrawImage(textureContainer,x,y,srcX, srcY, srcWidth, srcHeight)
End 

Function B2DDrawTextureRect( texture:TTexture,x#,y#,srcX,srcY,srcWidth,srcHeight,rotation#,scaleX#,scaleY#)

#If CONFIG="debug"
	DebugRenderDevice
#End

	textureContainer.surface = texture
	textureContainer.width = texture.width
	textureContainer.height = texture.height
	B2DDrawImage(textureContainer,x,y,srcX,srcY,srcWidth,srcHeight,rotation,scaleX,scaleY)
End 

Function B2DDrawTexture(texture:TTexture, x#, y#)

#If CONFIG="debug"
	DebugRenderDevice
#End
	textureContainer.surface = texture
	textureContainer.width = texture.width
	textureContainer.height = texture.height
	B2DDrawImage(textureContainer,x,y)
End

Function B2DDrawTexture(texture:TTexture, x#, y#, rotation#,scaleX#,scaleY#)

#If CONFIG="debug"
	DebugRenderDevice
#End
	textureContainer.surface = texture
	textureContainer.width = texture.width
	textureContainer.height = texture.height
	B2DDrawImage(textureContainer,x,y,rotation,scaleX,scaleY)
End 

Function B2DDrawRect(x#,y#,width#,height#)

#If CONFIG="debug"
	DebugRenderDevice
#End

	Batch.Draw2(Null,x, y,width,height, 0,0,1,1 )
End 

Function B2DDrawLine(x0#,y0#,x1#,y1#, linewidth# = 1 )

#If CONFIG="debug"
	DebugRenderDevice
#End

	Batch.DrawLine(x0,y0,x1,y1,linewidth)

End 

Function B2DDrawOval(x#,y#,w#,h#)

#If CONFIG="debug"
	DebugRenderDevice
#End

	Batch.DrawOval(x,y,w,h)
	
End 


Function B2DDrawCircle( x#,y#,r# )
#If CONFIG="debug"
	DebugRenderDevice
#End

	Batch.DrawOval(x-r,y-r,r*2,r*2)
	
End

Function B2DPushMatrix()
	Batch.PushMatrix
End

Function B2DPopMatrix()
	Batch.PopMatrix
End

Function B2DTranslate:Void(x#,y#)
	Batch.Transform 1,0,0,1,x,y
End

Function B2DScale(sx#,sy#)
	Batch.Transform sx,0,0,sy,0,0
End

Function B2DRotate(angle#)
	Local s#= Sin(angle)
	Local c#= Cos(angle)
	Batch.Transform c,-s,s,c,0,0
End 

Function B2DSetColor(r#,g#,b#)
	Batch.SetColor( r / 255.0,  g/ 255.0, b/ 255.0)
End 

Function B2DSetAlpha(a#)
	Batch.SetAlpha(a)
End 

Function B2DEndRender()
	Batch.EndRender()
End

Function B2DTransform( ix#,iy#,jx#,jy#,tx#,ty# )
	Batch.Transform ix,iy,jx,jy,tx,ty
End

Function B2DSetFont( font:B2DImage,firstChar=32 )
	If Not font
		If Not context.defaultFont
			context.defaultFont=B2DLoadImage( "mojo_font2.png",96,Image.XPadding )
		Endif
		font=context.defaultFont
		font.surface.NoSmooth()
		firstChar=32
	Endif
	context.font=font
	context.firstChar=firstChar
End

Function B2DGetFont:Image()
	Return context.font
End

Function B2DTextWidth#( text$ )
	If context.font Return text.Length * context.font.Width
End

Function B2DTextHeight#()
	If context.font Return context.font.Height
End

Function B2DFontHeight#()
	If context.font Return context.font.Height
End

Function B2DDrawText( text$,x#,y#,xalign#=0,yalign#=0 )
#If CONFIG="debug"
	DebugRenderDevice
#End
	If Not context.font Return
	
	Local w=context.font.Width
	Local h=context.font.Height
	
	x-=Floor( w * text.Length * xalign )
	y-=Floor( h * yalign )
	
	For Local i=0 Until text.Length
		Local ch=text[i]-context.firstChar
		If ch>=0 And ch<context.font.Frames
			B2DDrawImage context.font,x+i*w,y,ch
		Endif
	Next

End