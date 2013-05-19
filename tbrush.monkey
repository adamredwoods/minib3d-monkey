Import minib3d
Import ttexture

#rem
NOTES:
-- why would tex_frames go into the texture? because different textures, different anim frames

#end

Class TBrush
	Const INV_255:Float = 1.0/255.0
	
	Field no_texs:Int
	Field name$
	Field red#=1.0,green#=1.0,blue#=1.0,alpha#=1.0
	Field shine#=0.05, shine_strength#=100.0

'' because html5 defaults to premultiplied canvas, this helps
#If TARGET="html5"
	Field blend:Int=0
#Else
	Field blend:Int=1
#Endif

	Field fx:Int
	
	Field u_scale#=1.0,v_scale#=1.0,u_pos#,v_pos#,angle#
	Field tex_frame:Int=0
	
	Field tex:TTexture[8]
	
	Const MAX_TEXS:Int = 8

	Method New()
	
	End 
	
	Method New(hexcolor:Int)
	
		red=((hexcolor& $00ff0000) Shr 16)*INV_255
		green= ((hexcolor& $00ff00) Shr 8)*INV_255 
		blue= (hexcolor& $0000ff)*INV_255
		tex[0] = New TTexture
		
	End
	
	Method New(r%,g%,b%)
	
		red= r*INV_255
		green= g*INV_255
		blue= b*INV_255
		tex[0] = New TTexture
		
	End
	
	Method New(texture:TTexture)
		BrushTexture(texture)
	End 
	
	Method Copy:TBrush()
		
		Local brush:TBrush=New TBrush
	
		brush.no_texs=no_texs
		brush.name=name
		brush.red=red
		brush.green=green
		brush.blue=blue
		brush.alpha=alpha
		brush.shine=shine
		brush.shine_strength=shine_strength
		brush.blend=blend
		brush.fx=fx
		
		#rem
		brush.u_scale=u_scale
		brush.v_scale=v_scale
		brush.u_pos=u_pos
		brush.v_pos=v_pos
		brush.angle=angle
		brush.tex_frame=tex_frame
		#end
		
		If tex[0] brush.tex[0]=tex[0]
		If tex[1] brush.tex[1]=tex[1]
		If tex[2] brush.tex[2]=tex[2]
		If tex[3] brush.tex[3]=tex[3]
		If tex[4] brush.tex[4]=tex[4]
		If tex[5] brush.tex[5]=tex[5]
		If tex[6] brush.tex[6]=tex[6]
		If tex[7] brush.tex[7]=tex[7]
					
		Return brush

	End 
	
	Method FreeBrush()
	
	End 
		
	Function CreateBrush:TBrush(r#=255.0,g#=255.0,b#=255.0)
	
		Local brush:TBrush=New TBrush(r,g,b)
		Return brush
		
	End 
	
	Function LoadBrush:TBrush(file$,flags:Int=1,u_scale#=1.0,v_scale#=1.0)
	
		Local brush:TBrush=New TBrush
		brush.no_texs = 1
		Local i:Int = brush.no_texs-1
		brush.tex[i]=TTexture.LoadTexture(file,flags)
		
		brush.tex[i].u_scale=u_scale
		brush.tex[i].v_scale=v_scale
		brush.tex[i].tex_frame=0
		Return brush
		
	End 
	
	Function LoadAnimBrush:TBrush(file$,flags:Int=1,w:Int,h:Int,first_frame:Int=0,no_frames:Int=-1)
	
		Local brush:TBrush=New TBrush
		
		brush.no_texs = 1
		Local i:Int = brush.no_texs-1
		
		brush.tex[i]=TTexture.LoadAnimTexture(file,flags,w,h,first_frame,no_frames)
		'brush.u_scale = brush.tex[i].u_scale
		'brush.v_scale = brush.tex[i].v_scale
		'brush.u_pos = brush.tex[i].u_pos 
		'brush.v_pos = brush.tex[i].v_pos 
		brush.tex[i].tex_frame=0
		Return brush
		
	End
	
	''LoadTexture()
	'' -- a method to load a texture into an existing brush. used for multiple textures
	Method LoadTexture:TTexture(file$,flags:Int=1,u_scale#=1.0,v_scale#=1.0)

		no_texs += 1
		If no_texs>MAX_TEXS Then Return Null
		
		Local i:Int = no_texs-1
		tex[i]=TTexture.LoadTexture(file,flags)
		
		tex[i].u_scale=u_scale
		tex[i].v_scale=v_scale
		tex[i].tex_frame=0
		
		Return tex[i]
		
	End
	
	''LoadAnimTexture()
	'' -- a method to load an animated texture into an existing brush. used for multiple textures
	Method LoadAnimTexture:TTexture(file$,flags:Int=1,w:Int,h:Int,first_frame:Int=0,no_frames:Int=-1)
		
		no_texs += 1
		If no_texs>MAX_TEXS Then Return Null
		Local i:Int = no_texs-1
		
		tex[i]=TTexture.LoadAnimTexture(file,flags,w,h,first_frame,no_frames) 
		tex_frame=0
		
		Return brush
		
	End
	
	Method BrushColor(r#,g#,b#, a#=-1.0)
	
		red=r*INV_255
		green=g*INV_255
		blue=b*INV_255
		If a>=0.0 Then alpha = a
	
	End 
	
	Method BrushColorFloat(r#,g#,b#, a#=-1.0)
	
		red=r
		green=g
		blue=b
		If a>=0.0 Then alpha = a
		
	End 
	
	Method BrushAlpha(a#)
	
		alpha=a
	
	End 
	
	Method BrushShininess:Void(s#)
	
		shine=s
	
	End 
	
	Method BrushTexture:void(texture:TTexture,frame=0,index=0)
	
		tex[index]=texture
		If index+1>no_texs Then no_texs=index+1
		
		If frame<0 Then frame=0
		If frame>texture.no_frames-1 Then frame=texture.no_frames-1 
		texture.tex_frame=frame
		
		If frame>0 And texture.no_frames>1
			''move texture
			Local x:Int = frame Mod texture.frame_xstep
			Local y:Int =( frame/texture.frame_ystep) Mod texture.frame_ystep
			texture.u_pos = x*texture.frame_ustep
			texture.v_pos = y*texture.frame_vstep
		Endif
		
	End
	
	Method GetTexture:TTexture(index:Int=0)
		
		Return tex[index]
		
	End
	
	Method BrushBlend(blend_no)
	
		blend=blend_no
	
	End 
	
	Method BrushFX(fx_no)
	
		fx=fx_no
	
	End 
	
	Method ScaleBrush(u_s#,v_s#,i:Int=0)
		
		If tex[i]
			tex[i].u_scale=1.0/u_s
			tex[i].v_scale=1.0/v_s
		Endif
	End 
	
	Method PositionBrush(u_p#,v_p#,i:Int=0)
		
		If tex[i]
			tex[i].u_pos=-u_p
			tex[i].v_pos=-v_p
		Endif
	End 
	
	Method RotateBrush(ang#,i:Int=0)
	
		If tex[i]
			tex[i].angle=ang
		Endif
		
	End 
	
	
	Function GetEntityBrush:TBrush(ent:TEntity)
	
		Return ent.brush.Copy()
		
	End 
	
	Function GetSurfaceBrush:TBrush(surf:TSurface)
	
		Return surf.brush.Copy()

	End 
	
	Function CompareBrushes(brush1:TBrush,brush2:TBrush)
	
		' returns true if specified brush1 has same properties as brush2
		' return true for both null

		If brush1=Null And brush2<>Null Then Return False
		If brush1<>Null And brush2=Null Then Return False
		If brush1<>Null And brush2<>Null
			If brush1.no_texs<>brush2.no_texs Then Return False
			If brush1.red<>brush2.red Then Return False
			If brush1.green<>brush2.green Then Return False
			If brush1.blue<>brush2.blue Then Return False
			If brush1.alpha<>brush2.alpha Then Return False
			If brush1.shine<>brush2.shine Then Return False
			If brush1.blend<>brush2.blend Then Return False
			If brush1.fx<>brush2.fx Then Return False
			For Local i=0 To 7
				If brush1.tex[i]=Null And brush2.tex[i]<>Null Then Return False
				If brush1.tex[i]<>Null And brush2.tex[i]=Null Then Return False
				If brush1.tex[i]<>Null And brush2.tex[i]<>Null
					If brush1.tex[i].gltex[0]<>brush2.tex[i].gltex[0] Then Return False
					If brush1.tex[i].blend<>brush2.tex[i].blend Then Return False
					If brush1.tex[i].coords<>brush2.tex[i].coords Then Return False
				Endif
			Next
		Endif
	
		Return True
	
	End 

	
End 