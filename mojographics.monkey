Import mojo.graphicsdevice
Import mojo.graphics
Import mojo.data
Import minib3d


Extern

#If TARGET="html5" Or TARGET="flash" Or TARGET = "win8"
	'' YIKES! is this a hack or what? this empty class is tucked in TPixmaphtml5 native code
	Class Surface_ Extends Surface = "EmptyNullClass"
	End
#Else
	Class Surface_ Extends Surface = "gxtkSurface"
	End
#Endif

	'Function FlashFix:MojoSurface(s:Surface) = "gxtkSurface"
#If TARGET="flash"
	Class FlashFix Extends MojoSurface = "gxtkSurface"
	End
#Else
	Function FlashFix:MojoSurface(s:Surface_) = ""
#Endif

Public


Function SetMojoEmulation:Void()
	MojoEmulationDevice.SetDevice()
End

Function SetMojoFont:Void()
	MojoEmulationDevice._device.InitFont()
End

Class MojoEmulationDevice Extends GraphicsDevice

	Const MAXLAYERS:Int=512
	
	Global _device:MojoEmulationDevice
	Global _olddevice:GraphicsDevice
	Global _quadCache:QuadCache
	
	Field mesh:TMesh
	Field solid:TSurface[MAXLAYERS] ''512 blend layers available
	Field layer:Int ''current layer for grouping blends
	Field zdepth:Float = 1.99999 ''zdepth for layering images
	Field colorr:Int, colorg:Int, colorb:Int, colora:Float=1.0
	Field mat:Matrix = New Matrix
	
	'Field img_layer:List<TSurface> = New List<TSurface>

	
Private
	
	Const inverse_255:Float = 1.0/255.0
	
	Field vert0:Vertex = New Vertex
	Field vert1:Vertex = New Vertex
	Field vert2:Vertex = New Vertex
	Field vert3:Vertex = New Vertex
	
	Field lastSurface:MojoSurface
	Field lastBlend:Int=-1
	Field fontImage:Image
	Field fontFile:String = "mojo_font.png"
	
	Global firstTimeRun:Bool = false

	Function SetDevice:Void()
		
		If Not _device
		
			_olddevice = GetGraphicsDevice() ''trick to get flash to work
			_device = New MojoEmulationDevice
			_quadCache = New QuadCache()
			
#If TARGET="flash"
			FlashMiniB3D(TRender.render).ForceFlashTransparency(_olddevice)
			FlashMiniB3D(TRender.render).ForceFlashTransparency(_device)
#Endif

		endif
		
		_device.Reset
		SetGraphicsDevice( _device )
		mojo.graphics.BeginRender() ''trick to get html5 to work
		''GetGraphicsDevice() ''trick for xna to work

		If firstTimeRun
			_device.InitFont() ''don't load font first time, to avoid the file not found error.	
		Else
			PreLoadPixmap(_device.fontFile)
		Endif
		firstTimeRun = true
		
	End
	
	Method InitFont:Void()

		If fontImage And fontImage.Width()>0 Then Return
		
		'' consider embedding font as base64?
		
		fontImage = LoadImage( fontFile,96,Image.XPadding )
		
		If fontImage And fontImage.Width()>0
			SetFont(fontImage)
		endif

	End
	
	
Public

	Function CheckDevice:Int()
		Return (MojoEmulationDevice(GetGraphicsDevice())<>Null)
	End


	Method New()
		'
	End
	
	
	Method NewLayer:Void()
		
		If mesh = Null Then Return
		
		layer+=1
		If layer>MAXLAYERS Then layer=0
		If Not solid[layer] Then solid[layer] = mesh.CreateSurface() Else mesh.AddSurface(solid[layer])
		
		'solid[layer].ClearSurface() ''gives a 8 frame speedup
		solid[layer].no_verts =0
		solid[layer].no_tris =0
		solid[layer].vbo_dyn=true
		solid[layer].brush.fx = FXFLAG_FORCE_ALPHA| FXFLAG_FULLBRIGHT | FXFLAG_VERTEXCOLORS
		mesh.brush.blend = 0

	End
	
	Method Reset()
		
		If Not mesh
			mesh = CreateMesh()
			mesh.entity_link.Remove()
			mesh.EntityFX FXFLAG_DISABLE_DEPTH | FXFLAG_FULLBRIGHT | FXFLAG_VERTEXCOLORS
			
			layer=-1
			NewLayer() 
		Endif
		
		'For Local i:Int = 0 To layer
			'TRender.render.DeleteVBO(solid[i])
			'solid[i]=Null
			'solid[i].ClearSurface()
		'Next
		
		''careful here, we're not releasing the hardware buffers
		mesh.no_surfs=1
		mesh.surf_list.Clear()
		mesh.surf_list.AddLast(solid[0])
		'solid[0].ClearSurface()
		solid[0].no_verts =0
		solid[0].no_tris =0
		
		layer=0
		lastBlend=0
		lastSurface=Null
		
		TRender.draw_list.AddLast(mesh)

		mat.LoadIdentity()
		
	End
	
	Method Check(s:MojoSurface)
			
		If s <> lastSurface
			NewLayer()
			lastSurface=s
		Endif
		
	End
	
	'Can be used outside of OnRender
	Method Width%()
		'' get devicewidth and height before replacing graphicsdevice
		Return TRender.render.width
	End
	
	Method Height%()
		Return TRender.render.height
	End
	
	Method LoadSurface:Surface( path$ )
	
		Local msurf:MojoSurface = MojoSurface.PreLoad(path, mesh, _device)

		Return FlashFix(msurf)
	End
	
	Method CreateSurface:Surface( width,height )
		Local msurf:MojoSurface = MojoSurface.Create()
		
		Return FlashFix(msurf)
	End
	
	Method WritePixels2( surface:Surface,pixels[],x,y,width,height,offset,pitch )
	End

#rem
	'Begin/end rendering, never called	
	Method BeginRender:Int()	'0=gl, 1=mojo, 2=loading

	End
	
	Method EndRender:Void()

	End
#end

	Function FlushMojo:Void()
'Print _device.surf.no_tris
		'_device.mesh.Draw(0,0)
		'_device.Reset
	end

	'' -- flash does not like
	'Method DiscardGraphics:Void()
	'	
	'End


	'Render only ops - can only be used during OnRender
	Method Cls( r#,g#,b# )
		TRender.render.camera2D.CameraClsColor(r,g,b)
		TRender.render.camera2D.CameraClsMode(True,False)
	End
	  
	Method SetAlpha( alpha# )
		colora=alpha
	End
	
	Method SetColor( r#,g#,b# )
		colorr=r;colorg=g;colorb=b
	End
	
	Method SetMatrix( ix#,iy#,jx#,jy#,tx#,ty# )
		mat.grid[0][0] = ix
		mat.grid[1][0] = iy
		mat.grid[0][1] = jx
		mat.grid[1][1] = jy
		mat.grid[3][0] = tx
		mat.grid[3][1] = -ty
	End
	
	Method SetScissor( x,y,width,height )
		TRender.render.camera2D.CameraScissor(x,y,width,height)
	End
	
	Method SetBlend( blend )
		
		If blend<>lastBlend Then NewLayer()

		If blend = AdditiveBlend
			solid[layer].brush.blend = 3
		Elseif blend = LightenBlend
			solid[layer].brush.blend = 4 ''minib3d doesnt really have a lighten blend 
		Else
			solid[layer].brush.blend = 1 ''dont premultiply
#If TARGET="html5"
			solid[layer].brush.blend = 0 ''ugh....html5 is all premultiplied
#Endif
		Endif
		
		lastBlend = blend
	End
	
	Method DrawPoint( x#,y# )
	
		Check(Null)
		AddQuad(solid[layer], x,y,1.0,1.0)
		
	End
	
	Method DrawRect( x#,y#,w#,h# )
	
		Check(Null)
		AddQuad(solid[layer], x,y,w,h)
			
	End
	
	Method DrawLine( x1#,y1#,x2#,y2# )
	
		Check(Null)

		Local p0:Float[]
		p0 = Transform2D(mat,x1,-y1,zdepth)
		x1=p0[0]; y1=p0[1]		
		p0 = Transform2D(mat,x2,-y2,zdepth)
		x2=p0[0]; y2=p0[1]	
		
		Local px# = (y1-y2)
		Local py# = -(x1-x2)
		Local d# = 1.0/Sqrt(px*px + py*py)

		px=px*d ''offsets, not exacts
		py=py*d

		Local v0%=solid[layer].AddVertex( x2,y2,zdepth, 0, 1) ''v0
		Local v1%=solid[layer].AddVertex( x1,y1,zdepth, 0, 0)
		Local v2%=solid[layer].AddVertex( x1+px,y1+py,zdepth, 1, 0)
		solid[layer].AddTriangle(v0,v1,v2)

		Local v3%=solid[layer].AddVertex( x2+px,y2+py ,zdepth, 1, 0)	
		solid[layer].AddTriangle(v0,v2,v3)
		
		solid[layer].VertexColor(v0, colorr,colorg,colorb,colora)
		solid[layer].VertexColor(v1, colorr,colorg,colorb,colora)
		solid[layer].VertexColor(v2, colorr,colorg,colorb,colora)
		solid[layer].VertexColor(v3, colorr,colorg,colorb,colora)
		
		''since vbo expands, make sure to reset
		solid[layer].reset_vbo=-1
		
	End
	
	Method DrawOval( x#,y#,w#,h# )
	
		Check(Null)
		
		If w<0.0 Then w=-w
		If h<0.0 Then h=-h
		Local seg:Int = (w+h)*0.2
		If seg<14 Then seg=14
		
		Local deg#=0.0, deginc# = 360.0/seg
		Local verts#[seg*6+1]
		
		For Local i:Int=0 To verts.Length-7 Step 6

			verts[i+0] = x
			verts[i+1] = y
			verts[i+2] = x+w*Cos(deg)
			verts[i+3] = y+h*Sin(deg)
			verts[i+4] = x+w*Cos(deg+deginc)
			verts[i+5] = y+h*Sin(deg+deginc)
			
			deg+=deginc
			'Print verts[i+2]+":"+verts[i+3]+"   "+verts[i+4]+":"+verts[i+5]
		Next
		
		DrawPoly( verts )
		
	End
	
	
	'' implemented drastic android optimizations....
	'' delete code after commit
	Global v_cache:Float[]
	
	Method DrawPoly( verts#[] )
	
		Check(Null)
		
		Local p0:Float[], p1:Float[], p2:Float[], p3:Float[]
		Local r#, g#, b#
		
		Local tris:Int[(verts.Length()-7)*6*3]
		local t:Int=0, vt:Int = solid[layer].no_verts
		'v_cache= New Float[(verts.Length()-7)*6*48]
		'local t_array:Float[48]
		
		r=colorr* inverse_255
		g=colorg* inverse_255
		b=colorb* inverse_255
		
		For Local i:Int=0 To verts.Length-7 Step 6
			p0 = Transform2D(mat,verts[i+0],-verts[i+1],zdepth)		
			p1 = Transform2D(mat,verts[i+2],-verts[i+3],zdepth)		
			p2 = Transform2D(mat,verts[i+4],-verts[i+5],zdepth)	
			
			'v_cache = v_cache.Resize(v_cache.Length()+48)
			vt=vt+3
			'Local j:Int = (vt-3)*16

			't_array = [ p0[0],p0[1],-p0[2],0.0, 1.0,1.0,1.0,0.0, colorr* inverse_255,colorg* inverse_255,colorb* inverse_255,colora, 0.0, 0.0, 0.0, 0.0,
			 			'p1[0],p1[1],-p1[2],0.0, 1.0,1.0,1.0,0.0, colorr* inverse_255,colorg* inverse_255,colorb* inverse_255,colora, 0.0, 0.0, 0.0, 0.0,
			 			'p2[0],p2[1],-p2[2],0.0, 1.0,1.0,1.0,0.0, colorr* inverse_255,colorg* inverse_255,colorb* inverse_255,colora, 0.0, 0.0, 0.0, 0.0 ]
			'v_cache[j+0] = p0[0]; v_cache[j+1] = p0[1]; v_cache[j+2] = -p0[2];   v_cache[j+4] = 1.0; v_cache[j+5] = 1.0; v_cache[j+6] = 1.0;   v_cache[j+8] = r; v_cache[j+9] = g; v_cache[j+10] = b; v_cache[j+11] = colora;
			'v_cache[j+16] = p1[0]; v_cache[j+17] = p1[1]; v_cache[j+18] = -p1[2];   v_cache[j+20] = 1.0; v_cache[j+21] = 1.0; v_cache[j+22] = 1.0;   v_cache[j+24] = r; v_cache[j+25] = g; v_cache[j+26] = b; v_cache[j+27] = colora;
			'v_cache[j+32] = p2[0]; v_cache[j+33] = p2[1]; v_cache[j+34] = -p2[2];   v_cache[j+36] = 1.0; v_cache[j+37] = 1.0; v_cache[j+38] = 1.0;   v_cache[j+40] = r; v_cache[j+41] = g; v_cache[j+42] = b; v_cache[j+43] = colora;
			
			'For Local i:Int=0 To 47
				'v_cache[(vt-3)*16+i] = t_array[i]
			'Next
			
			solid[layer].AddVertex([ p0[0],p0[1],-p0[2],0.0, 1.0,1.0,1.0,0.0, colorr* inverse_255,colorg* inverse_255,colorb* inverse_255,colora, 0.0, 0.0, 0.0, 0.0,
			 			p1[0],p1[1],-p1[2],0.0, 1.0,1.0,1.0,0.0, colorr* inverse_255,colorg* inverse_255,colorb* inverse_255,colora, 0.0, 0.0, 0.0, 0.0,
			 			p2[0],p2[1],-p2[2],0.0, 1.0,1.0,1.0,0.0, colorr* inverse_255,colorg* inverse_255,colorb* inverse_255,colora, 0.0, 0.0, 0.0, 0.0 ])
			
			'solid[layer].AddTriangle(v2-2,v2-1,v2)
			
			''cache triangles
			'tris=tris.Resize(t+3)
			tris[t] = vt-3; tris[t+1] = vt-2; tris[t+2] = vt-1
			t=t+3; 
			
			
		Next
		
		'solid[layer].AddVertex(v_cache)
		solid[layer].AddTriangle(tris)
		
	End
	
	Method DrawSurface( surface:Surface,x#,y# )
		DrawSurface2(surface, x,y,0,0,surface.Width(),surface.Height())
	End
	
	''need to order these layers
	Method DrawSurface2( surface:Surface,x#,y#,srcx%,srcy%,srcw%,srch% )
		
		Local s:MojoSurface = MojoSurface(surface)
		If Not s Then Return
		
		Check(s)

		If s.tex Then solid[layer].PaintSurface(s.tex)

		
		Local xstep# = s.xstep
		Local ystep# = s.ystep
		Local upos# = srcx*xstep
		Local vpos# = srcy*ystep

		AddQuad(solid[layer], x,y,srcw,srch, upos, vpos, upos+xstep*srcw, vpos+ystep*srch)
		'Local v:Int[] = AddQuad(solid[layer], x,y,srcw,srch, 0.0, 0.0, 1.0,1.0)
		
		
	End
	
	Method ReadPixels( pixels[],x,y,width,height,offset,pitch )
	End
	
	'INTERNAL - subject to change etc.
	Method LoadSurface__UNSAFE__:Surface( surface:Surface,path$ )
		'Local sprite:MojoSurface = New MojoSurface
		'Local ms:MojoSurface= MojoSurface(surface)
		'If ms Then ms.sprite = LoadSprite(path)
	End

	

	Method AddQuad:Void(s:TSurface, x#,y#,w#,h#, u#=0.0, v#=0.0, uw#=1.0, vh#=1.0)
		
		Local p0:Float[], p1:Float[], p2:Float[], p3:Float[]
		Local r#,g#,b#
		
		p0 = Transform2D(mat,x,-h-y,zdepth)		
		p1 = Transform2D(mat,x,-y,zdepth)		
		p2 = Transform2D(mat,x+w,-y,zdepth)		
		p3 = Transform2D(mat,x+w,-h-y,zdepth)
		r=colorr* inverse_255
		g=colorg* inverse_255
		b=colorb* inverse_255
				
		'Local v4%=s.AddVertex([p0[0],p0[1],-p0[2],0.0, 1.0,1.0,1.0,0.0, r,g,b,colora, u, vh, u, vh,
		_quadCache.AddCache(s, [p0[0],p0[1],-p0[2],0.0, 1.0,1.0,1.0,0.0, r,g,b,colora, u, vh, u, vh,
								 p1[0],p1[1],-p1[2],0.0, 1.0,1.0,1.0,0.0, r,g,b,colora, u, v, u, v,
								 p2[0],p2[1],-p2[2],0.0, 1.0,1.0,1.0,0.0, r,g,b,colora, uw, v, uw, v,
								 p3[0],p3[1],-p3[2],0.0, 1.0,1.0,1.0,0.0, r,g,b,colora, uw, vh, uw, vh ] )
		's.AddTriangle([v4-3,v4-2,v4-1])
		's.AddTriangle([v4-3,v4-1,v4])
		's.AddTriangle([v4-3,v4-2,v4-1, v4-3,v4-1,v4])
		

		'' make sure to reset
		s.reset_vbo=-1
		
	End
	

	
	
End

Function Transform2D:Float[](mat:Matrix, x#, y#, z#)
	Return [ mat.grid[0][0]*x + mat.grid[1][0]*y + mat.grid[3][0], mat.grid[0][1]*x + mat.grid[1][1]*y + mat.grid[3][1], z ]
End


Class MojoSurface Extends Surface_
	
	'Field sprite:TSprite
	
	Field tex:TTexture
	'Field surf:TSurface
	Field xstep#, ystep#
	Field path:String 'debugging
	Field loaded:Int=0
	
	Global isLoading:Bool = False
	Global list:String[0]
	Global surfmap:StringMap<MojoSurface> = New StringMap<MojoSurface>
	
	Method New()

	End
	
	Function Create:MojoSurface(path$="")
		Local s:MojoSurface = New MojoSurface
		s.tex = CreateTexture(0,0)
		If path <> ""
			s.path = path
			'surfmap.Set(path,s)
		Endif
		Return s
	End
	
	Function PreLoad:MojoSurface(path$, mesh:TMesh, device:MojoEmulationDevice)
	
		Local s:MojoSurface = Create(path)

		Local sz% = list.Length()
		list = list.Resize(sz+1)
		list[sz] = path
		'surfmap.Set(path, s)
		
		isLoading = True
		
		''** MUST PRELOAD MANUALLY for mojo			
		s.LoadTexture(path, mesh, device)

		
		Return s
		
	End

	
	
	Method LoadTexture:Bool(path$, mesh:TMesh, device:MojoEmulationDevice)

		tex.ResizeNoSmooth
		'tex.NoSmooth
		tex.pixmap.ClearBind() ''Re-bind the texture
		TTexture.LoadAnimTexture(path,TEXFLAG_COLOR|TEXFLAG_ALPHA,0,0,0,1,tex, True) ''force new (true) will keep trying to load again

		'If tex.width = 0 Then Print "**ERROR: MojoLoad: file not found "+path 'Else Print tex.width
		
		loaded = 1
	
		'Print path+" "+tex.orig_width
	
		xstep = 1.0/Float(Width())
		ystep = 1.0/Float(Height())

		Return (tex<>Null)
	End

	
	Method Discard()
		If tex Then tex.FreeTexture()
		'surf.FreeSurface()
		tex=Null
		'surf=Null
	End

	Method Width() Property
		'Return sprite.brush.tex[0].width
		Return tex.orig_width
	End
	Method Height() Property
		'Return sprite.brush.tex[0].height
		Return tex.orig_height
	End
	Method Loaded() Property
		Return loaded
	End

	'INTERNAL - subject to change etc.
	Method OnUnsafeLoadComplete:Bool()
		Return true
	End

End

Class QuadCache

	'' 64 floats per quad, 6 per tri
	Const Q_CACHEMAX:Int=20
	field q_cache:Float[1280] ''0-9
	field q_tri:int[128]
	field q_num:Int=0 ''number of verts
	field q_surf:TSurface
	
	Method AddCache:Void( s:TSurface, v:Float[] )
		
		If (s<>q_surf) Or (q_num>Q_CACHEMAX-1)
			
			FlushCache()
			
		Endif
		q_surf = s
		
		Local offset:Int = q_num*64
		For Local i:Int=0 To 63
			q_cache[offset+i] = v[i]
		Next
		
		q_num+=1
		
	End
	
	Method FlushCache:Void()
		
		If q_num=0 Then Return
		
		Local n:Int = q_num
		Local v4% = q_surf.AddVertex( q_cache, q_num*64 )

		v4 = (v4+1)-(q_num*4)

		
		Local k:Int=0
		For Local j:Int =0  To n-1
			q_tri[k+0] = v4; q_tri[k+1] = v4+1; q_tri[k+2] = v4+2; 
			q_tri[k+3] = v4; q_tri[k+4] = v4+2; q_tri[k+5] = v4+3; 

			k=k+6
			v4=v4+4
		Next
		q_surf.AddTriangle (q_tri, q_num*6)
		
		q_num =0
		q_surf=null
		
	End
	
End