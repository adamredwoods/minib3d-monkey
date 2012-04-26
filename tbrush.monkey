Import minib3d
Import ttexture

Class TBrush

	Field no_texs:Int
	Field name$
	Field red#=1.0,green#=1.0,blue#=1.0,alpha#=1.0
	Field shine#
	Field blend:Int,fx:Int
	Field tex_frame:Int
	Field u_scale#=1.0,v_scale#=1.0,u_pos#,v_pos#,angle# ''per brush animation
	Field tex:TTexture[8]
	

	Method New()
	
	End 
	
	Method Delete()

	
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
		brush.blend=blend
		brush.fx=fx
		brush.tex_frame=tex_frame
		brush.tex[0]=tex[0]
		brush.tex[1]=tex[1]
		brush.tex[2]=tex[2]
		brush.tex[3]=tex[3]
		brush.tex[4]=tex[4]
		brush.tex[5]=tex[5]
		brush.tex[6]=tex[6]
		brush.tex[7]=tex[7]
		
		brush.u_scale=u_scale
		brush.v_scale=v_scale
		brush.u_pos=u_pos
		brush.v_pos=v_pos
		brush.angle=angle
					
		Return brush

	End 
	
	Method FreeBrush()
	
	End 
		
	Function CreateBrush:TBrush(r#=255.0,g#=255.0,b#=255.0)
	
		Local brush:TBrush=New TBrush
		brush.red=r/255.0
		brush.green=g/255.0
		brush.blue=b/255.0
		
		brush.tex[0] = New TTexture
		
		Return brush
		
	End 
	
	Function LoadBrush:TBrush(file$,flags:Int=1,u_scale#=1.0,v_scale#=1.0)
	
		Local brush:TBrush=New TBrush
		brush.tex[0]=TTexture.LoadTexture(file,flags)
		brush.no_texs=1
		brush.tex[0].u_scale=u_scale
		brush.tex[0].v_scale=v_scale
		brush.tex_frame=0
		Return brush
		
	End 
	
	Function LoadAnimBrush:TBrush(file$,flags:Int=1,w:Int,h:Int,first_frame:Int=0,no_frames:Int=-1)
	
		Local brush:TBrush=New TBrush
		brush.tex[0]=TTexture.LoadAnimTexture(file,flags,w,h,first_frame,no_frames)
		brush.u_scale = brush.tex[0].u_scale
		brush.v_scale = brush.tex[0].v_scale
		brush.u_pos = brush.tex[0].u_pos 
		brush.v_pos = brush.tex[0].v_pos 
		brush.no_texs=1
		brush.tex_frame=0
		Return brush
		
	End
	
	Method BrushColor(r#,g#,b#)
	
		red=r/255.0
		green=g/255.0
		blue=b/255.0
	
	End 
	
	Method BrushColorFloat(r#,g#,b#)
	
		red=r
		green=g
		blue=b
	
	End 
	
	Method BrushAlpha(a#)
	
		alpha=a
	
	End 
	
	Method BrushShininess(s#)
	
		shine=s
	
	End 
	
	Method BrushTexture(texture:TTexture,frame=0,index=0)
	
		tex[index]=texture
		If index+1>no_texs Then no_texs=index+1
		
		If frame<0 Then frame=0
		If frame>texture.no_frames-1 Then frame=texture.no_frames-1 
		tex_frame=frame
		
		If frame>0 And texture.no_frames>1
			''move texture
			Local x:Int = frame Mod texture.frame_xstep
			Local y:Int =( frame/texture.frame_ystep) Mod texture.frame_ystep
			u_pos = x*texture.frame_ustep
			v_pos = y*texture.frame_vstep
		Endif
		
	End 
	
	Method BrushBlend(blend_no)
	
		blend=blend_no
	
	End 
	
	Method BrushFX(fx_no)
	
		fx=fx_no
	
	End 
	
	Method ScaleBrush(u_s#,v_s#)
	
		u_scale=1.0/u_s
		v_scale=1.0/v_s
	
	End 
	
	Method PositionBrush(u_p#,v_p#)
	
		u_pos=-u_p
		v_pos=-v_p
	
	End 
	
	Method RotateBrush(ang#)
	
		angle=ang
	
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
			If brush1.tex_frame<>brush2.tex_frame Then Return False ''may not want if animtextures have different start frames
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