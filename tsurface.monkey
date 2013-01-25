Import minib3d
Import minib3d.monkeybuffer
Import minib3d.monkeyutility
Import minib3d.tanimation

'' NOTES
''
'' - future plans: multiple surfaces = one big shared vert_data (move to tmesh), but multiple tris indexes

Class TSurface

	Const inverse_255:Float = 1.0/255.0
	

	' no of vertices and triangles in surface

	Field no_verts:Int=0
	Field no_tris:Int=0
	
	' arrays containing vertex and triangle info
	
	Field tris:ShortBuffer = New ShortBuffer
	Field vert_data:VertexDataBuffer = New VertexDataBuffer 'interleaved
	
	'Field vert_coords:FloatBuffer = New FloatBuffer
	'Field vert_tex_coords0:FloatBuffer = New FloatBuffer
	'Field vert_tex_coords1:FloatBuffer = New FloatBuffer
	'Field vert_norm:FloatBuffer = New FloatBuffer
	'Field vert_col:FloatBuffer = New FloatBuffer
	
	' arrays containing vertex bone no and weights info - used by animated meshes only
	
	Field vert_bone1_no:Int[] ' stores bone no - bone no used to reference bones[] array belonging to TMesh
	Field vert_bone2_no:Int[]
	Field vert_bone3_no:Int[]
	Field vert_bone4_no:Int[]
	Field vert_weight1:Float[]
	Field vert_weight2:Float[]
	Field vert_weight3:Float[]
	Field vert_weight4:Float[]

	' animated surf attached to this surface (edit 2012)
	Field surf_id:Int ''used to link anim_surf and surface


	' vertex animation coords per frame
	' not copied in tsurface, but in tmesh
	Field vert_anim:TVertexAnim[] ''surf.vert_anim array should be null until it is set by BoneToVertexAnimation
	Field anim_frame:Int=0 ''current frame array index

	' brush applied to surface

	Field brush:TBrush=New TBrush
	
	' vbo
	
	Field vbo_id:Int[] = [0,0,0,0,0,0,0]
	
	' misc vars
	
	Field vert_array_size:Int=1
	Field tri_array_size:Int=1
	Field vmin:Int=1000000 ' used for trimming verts from b3d files
	Field vmax:Int=0 ' used for trimming verts from b3d files

	' reset flag - this is set when mesh shape is changed in TSurface and TMesh
	Field reset_vbo:Int =-1 ' (-1 = all)
	Field vbo_dyn:Bool = False 'store vbo as dynamic or static (anim meshes or batch sprites)
	
	' used by Compare to sort array, and TMesh.Update to enable/disable alpha blending
	Field alpha_enable:Bool =False
	
	
	''properties
	Method Brush:TBrush() Property
		Return brush
	End
	'Method Brush:Void(br:TBrush) Property
		'' read-only for now
	'End
	Method Texture:TTexture() Property
		If brush.tex Then Return brush.tex[0]
	End
	'Method Texture:Void(tx:TTexture) Property
		'' read-only for now
	'End
	
	
	
	Method New()
		
	
	End 
	
	Method FreeSurface()
	
		TRender.render.FreeVBO(Self)
		no_verts=0; no_tris=0
		tris=Null; vert_data=null
			
	End 
	

	' used to sort surfaces into alpha order. used by TMesh.Update
	Method Compare(other:Object)
	
		If TSurface(other)
		
			If alpha_enable>TSurface(other).alpha_enable Then Return 1
			If alpha_enable<TSurface(other).alpha_enable Then Return -1
	
		Endif
		
		Return 0
	
	End 
						
	Method Copy:TSurface()
	
		Local surf:TSurface=New TSurface
		
		surf.no_verts=no_verts
		surf.no_tris=no_tris
		
		surf.tris=CopyShortBuffer(tris, ShortBuffer.Create(no_tris*3) )
		surf.vert_data=CopyDataBuffer(vert_data, VertexDataBuffer.Create(no_verts) )
		'surf.vert_coords=CopyFloatBuffer(vert_coords, FloatBuffer.Create(no_verts*3) )
		'surf.vert_tex_coords0=CopyFloatBuffer(vert_tex_coords0, FloatBuffer.Create(no_verts*2) )
		'surf.vert_tex_coords1=CopyFloatBuffer(vert_tex_coords1, FloatBuffer.Create(no_verts*2) )
		'surf.vert_norm=CopyFloatBuffer(vert_norm, FloatBuffer.Create(no_verts*3) )
		'surf.vert_col=CopyFloatBuffer(vert_col, FloatBuffer.Create(no_verts*4) )
		
		surf.vert_bone1_no=vert_bone1_no[..]
		surf.vert_bone2_no=vert_bone2_no[..]
		surf.vert_bone3_no=vert_bone3_no[..]
		surf.vert_bone4_no=vert_bone4_no[..]
		surf.vert_weight1=vert_weight1[..]
		surf.vert_weight2=vert_weight2[..]
		surf.vert_weight3=vert_weight3[..]
		surf.vert_weight4=vert_weight4[..]
		
		If brush<>Null
			surf.brush=brush.Copy()
			brush = brush.Copy()
		Endif

		surf.vert_array_size=vert_array_size
		surf.tri_array_size=tri_array_size
		surf.vmin=vmin
		surf.vmax=vmax
		surf.surf_id = surf_id
		
		surf.reset_vbo=-1
		surf.vbo_dyn=vbo_dyn
		'surf.vert_anim = vert_anim ''move this to tmesh, since may take up a lot of space, decide how to copy via CopyMesh/CopyEnt

		surf.alpha_enable=alpha_enable
		
		
		Return surf
	
	End 
	
	Method PaintSurface(bru:TBrush)

		If brush=Null Then brush=New TBrush
		
		brush.no_texs=bru.no_texs
		brush.name=bru.name
		brush.red=bru.red
		brush.green=bru.green
		brush.blue=bru.blue
		brush.alpha=bru.alpha
		brush.shine=bru.shine
		brush.blend=bru.blend
		brush.fx=bru.fx
		
		For Local i=0 To 7
			brush.tex[i]=bru.tex[i]
		Next
	
	End 
	
	Method ClearSurface(clear_verts:Bool=True,clear_tris:Bool=True)
	
		If clear_verts
		
			no_verts=0
			
			vert_data=VertexDataBuffer.Create(0)
			'vert_coords=FloatBuffer.Create(0)
			'vert_tex_coords0=FloatBuffer.Create(0)
			'vert_tex_coords1=FloatBuffer.Create(0)
			'vert_norm=FloatBuffer.Create(0)
			'vert_col=FloatBuffer.Create(0)
			
			vert_array_size=1
		
		Endif
		
		If clear_tris
		
			no_tris=0
			
			tris=ShortBuffer.Create(0)

			tri_array_size=1
		
		Endif
		
		' mesh shape has changed - update reset flag
		reset_vbo=-1 ' (-1 = all)
	
	End 
	
	''CropSurfaceBuffers()
	''-- a method to shorten the memory buffers use to optimal size after mesh has been created
	''
	Method CropSurfaceBuffers()

		If no_verts<1 And no_tris<1 Then Return
	
		vert_data= CopyDataBuffer(vert_data, VertexDataBuffer.Create(no_verts) )
		'vert_coords= CopyFloatBuffer(vert_coords, FloatBuffer.Create(no_verts*3) )
		'vert_tex_coords0= CopyFloatBuffer(vert_tex_coords0, FloatBuffer.Create(no_verts*2) )
		'vert_tex_coords1= CopyFloatBuffer(vert_tex_coords1, FloatBuffer.Create(no_verts*2) )
		'vert_norm= CopyFloatBuffer(vert_norm, FloatBuffer.Create(no_verts*3) )
		'vert_col= CopyFloatBuffer(vert_col, FloatBuffer.Create(no_verts*4) )
		tris=CopyShortBuffer(tris, ShortBuffer.Create(no_tris*3) )
		
		vert_array_size = no_verts
		tri_array_size = no_tris
		
	End
	
	''AddVertex
	''-- because we are using quite a bit of buffer space (for speed), try to use CropSurfaceBuffers when done
	''
	Method AddVertex:Int(x#,y#,z#,u#=0.0,v#=0.0,w#=0.0)
		
		no_verts=no_verts+1

		' resize arrays/databuffers	
		If no_verts>=vert_array_size

			Repeat
				vert_array_size=vert_array_size +512
			Until vert_array_size>no_verts
			
			Local vas=vert_array_size
		
			vert_data= CopyDataBuffer(vert_data, VertexDataBuffer.Create(vas) )
			'vert_coords= CopyFloatBuffer(vert_coords, FloatBuffer.Create(vas*3) )
			'vert_tex_coords0= CopyFloatBuffer(vert_tex_coords0, FloatBuffer.Create(vas*2) )
			'vert_tex_coords1= CopyFloatBuffer(vert_tex_coords1, FloatBuffer.Create(vas*2) )
			'vert_norm= CopyFloatBuffer(vert_norm, FloatBuffer.Create(vas*3) )
			'vert_col= CopyFloatBuffer(vert_col, FloatBuffer.Create(vas*4) )
	
		Endif


		
		Local vid:Int = no_verts-1
		
		'vert_coords
		vert_data.PokeVertCoords(vid,x,y,-z)
		
		vert_data.PokeTexCoords(vid,u,v,u,v)		
		
		' default vertex colours
		vert_data.PokeColor(vid,1.0,1.0,1.0,1.0)
		
		vert_data.PokeNormals(vid,0.0,0.0,1.0)		
		
		Return vid
	
	End 
	
	Method AddTriangle(v0,v1,v2)
	
		no_tris=no_tris+1
		
		' resize array
		
		If no_tris>=tri_array_size
		
			Repeat
				tri_array_size=tri_array_size +512 ''because we're copying buffers, this may be faster, and use CropBuffers()
			Until tri_array_size>no_tris
		
			Local tas=tri_array_size
		
			tris=CopyShortBuffer(tris, ShortBuffer.Create(tas*3) )
		
		Endif
		
		Local v0i=(no_tris*3)-3
		Local v1i=(no_tris*3)-2
		Local v2i=(no_tris*3)-1	
	
		tris.Poke(v0i,v2)
		tris.Poke(v1i,v1)
		tris.Poke(v2i,v0)

		' mesh shape has changed - update reset flag
		reset_vbo = reset_vbo|1|2|16
		
		Return no_tris
	
	End 
	

	Method CountVertices:Int()
	
		Return no_verts
	
	End 
	
	Method CountTriangles:Int()
	
		Return no_tris
	
	End 
	
	Method VertexCoords(vid,x#,y#,z#)

		vert_data.PokeVertCoords(vid,x,y,-z)

		
		' mesh shape has changed - update reset flag
		reset_vbo = reset_vbo|1
	
	End 
			
	Method VertexColor(vid,r#,g#,b#,a#=1.0)
	
		'vid=vid*4
		vert_data.PokeColor(vid,r* inverse_255,g* inverse_255,b* inverse_255,a)
		'vert_col.Poke(vid,r * inverse_255)
		'vert_col.Poke(vid+1,g * inverse_255)
		'vert_col.Poke(vid+2,b * inverse_255)
		'vert_col.Poke(vid+3,a)
		
		' mesh state has changed - update reset flags
		reset_vbo = reset_vbo|8

	End 
	
	Method VertexColorFloat(vid,r#,g#,b#,a#=1.0)
	
		'vid=vid*4
		vert_data.PokeColor(vid,r,g,b,a)
		'vert_col.Poke(vid,r)
		'vert_col.Poke(vid+1,g)
		'vert_col.Poke(vid+2,b)
		'vert_col.Poke(vid+3,a)
		
		' mesh state has changed - update reset flags
		reset_vbo = reset_vbo|8

	End
	
	Method VertexNormal(vid,nx#,ny#,nz#)
	
		'vid=vid*3
		vert_data.PokeNormals(vid,nx,ny,-nz)
		'vert_norm.Poke(vid,nx)
		'vert_norm.Poke(vid+1,ny)
		'vert_norm.Poke(vid+2,-nz) ' ***ogl***
		
		' mesh state has changed - update reset flags
		reset_vbo = reset_vbo|4

	End 
	
	Method VertexTexCoords(vid,u#,v#,w#=0.0,coord_set=0)
	
		'vid=vid*2
		
		If coord_set=0
			
			vert_data.PokeTexCoords0(vid,u,v)
			'vert_tex_coords0.Poke(vid,u)
			'vert_tex_coords0.Poke(vid+1,v)

		Elseif coord_set=1
			
			vert_data.PokeTexCoords1(vid,u,v)
			'vert_tex_coords1.Poke(vid,u)
			'vert_tex_coords1.Poke(vid+1,v)
		
		Endif
		
		' mesh state has changed - update reset flags
		reset_vbo = reset_vbo|2


	End 
		
	Method VertexX#(vid)
		
		Return vert_data.VertexX(vid)
		'Return vert_coords.Peek(vid*3)

	End 

	Method VertexY#(vid)
		
		Return vert_data.VertexY(vid)
		'Return vert_coords.Peek((vid*3)+1)

	End 
	
	Method VertexZ#(vid)
		
		Return -vert_data.VertexZ(vid)
		'Return -vert_coords.Peek((vid*3)+2) ' ***ogl***

	End 
	
	Method VertexRed#(vid)
		
		Return vert_data.VertexRed(vid)*255.0
		'Return vert_col.Peek(vid*4)*255.0

	End 
	
	Method VertexGreen#(vid)
		
		Return vert_data.VertexGreen(vid)*255.0
		'Return vert_col.Peek((vid*4)+1)*255.0

	End 
	
	Method VertexBlue#(vid)
		
		Return vert_data.VertexBlue(vid)*255.0
		'Return vert_col.Peek((vid*4)+2)*255.0

	End Method
	
	Method VertexAlpha#(vid)
		
		Return vert_data.VertexAlpha(vid)*255.0
		'Return vert_col.Peek((vid*4)+3)

	End 
	
	Method VertexNX#(vid)
		
		Return vert_data.VertexNX(vid)
		'Return vert_norm.Peek(vid*3)

	End 
	
	Method VertexNY#(vid)
		
		Return vert_data.VertexNY(vid)
		'Return vert_norm.Peek((vid*3)+1)

	End 
	
	Method VertexNZ#(vid)
		
		Return -vert_data.VertexNZ(vid)
		'Return -vert_norm.Peek((vid*3)+2) ' ***ogl***

	End 
	
	Method VertexU#(vid:Int ,coord_set=0)
		
		Return vert_data.VertexU(vid,coord_set)
		'If coord_set=0 Then Return vert_tex_coords0.Peek(vid*2)
		'If coord_set=1 Then Return vert_tex_coords1.Peek(vid*2)

	End 
	
	Method VertexV#(vid,coord_set=0)
		
		Return vert_data.VertexV(vid,coord_set)
		'If coord_set=0 Then Return vert_tex_coords0.Peek((vid*2)+1)
		'If coord_set=1 Then Return vert_tex_coords1.Peek((vid*2)+1)

	End 
	
	Method VertexW#(vid,coord_set=0)
	
		Return 0.0

	End 
	
	''TriangleVertex()
	'' -- takes corner (0-2)
	'' --returns vertex id
	Method TriangleVertex:Int(tri_no:Int,corner:Int)
		
		'Local vid:Int[3]
		
		'tri_no=(tri_no+1)*3
		'vid[0]=tris.Peek(tri_no-1)
		'vid[1]=tris.Peek(tri_no-2)
		'vid[2]=tris.Peek(tri_no-3)
			
		'Return vid[corner]
		
		Return tris.Peek( tri_no*3+(2-corner) )
	End
	
	Method GetVertexCoords:Vector(vert_no:Int)
		
		'Local vx# = vert_data.VertexX(vert_no) 'vert_coords.Peek(vert_no*3+0)
		'Local vy# = vert_data.VertexY(vert_no) 'vert_coords.Peek(vert_no*3+1)
		'Local vz# = -vert_data.VertexZ(vert_no) '-vert_coords.Peek(vert_no*3+2)
		
		'Return New Vector(vx, vy, vz)
		Return vert_data.PeekVertCoords(vert_no)
	End
		
	Method UpdateNormals()

		Local norm_map:NormMap<Vector> = New NormMap<Vector>
		
		For Local t:=0 To no_tris-1

			Local tri_no:Int =(t+1)*3

			Local v0:Int=tris.Peek(tri_no-3) '*3
			Local v1:Int=tris.Peek(tri_no-2) '*3
			Local v2:Int=tris.Peek(tri_no-1) '*3
	
			Local ax#=vert_data.VertexX(v1)-vert_data.VertexX(v0) 'vert_coords.Peek(v1+0)-vert_coords.Peek(v0+0)
			Local ay#=vert_data.VertexY(v1)-vert_data.VertexY(v0) 'vert_coords.Peek(v1+1)-vert_coords.Peek(v0+1)
			Local az#=vert_data.VertexZ(v1)-vert_data.VertexZ(v0) 'vert_coords.Peek(v1+2)-vert_coords.Peek(v0+2)
	
			Local bx#=vert_data.VertexX(v2)-vert_data.VertexX(v1) 'vert_coords.Peek(v2+0)-vert_coords.Peek(v1+0)
			Local by#=vert_data.VertexY(v2)-vert_data.VertexY(v1) 'vert_coords.Peek(v2+1)-vert_coords.Peek(v1+1)
			Local bz#=vert_data.VertexZ(v2)-vert_data.VertexZ(v1) 'vert_coords.Peek(v2+2)-vert_coords.Peek(v1+2)
	
			Local nx#=(ay*bz)-(az*by) '' surf.TriangleNX#(t)
			Local ny#=(az*bx)-(ax*bz) '' surf.TriangleNX#(t)
			Local nz#=(ax*by)-(ay*bx) '' surf.TriangleNX#(t)
			
			Local norm:Vector = New Vector(nx,ny,nz)
			Local vnorm:Vector, vx:Vector, new_norm:Vector
			
			For Local c:=0 To 2
	
				Local v:Int = TriangleVertex(t,c) '*3
				
				vx = vert_data.PeekVertCoords(v) 'New Vector( vert_coords.Peek(v+0), vert_coords.Peek(v+1), vert_coords.Peek(v+2))
				
				vnorm = norm_map.Get(vx)
				If Not vnorm

					vnorm = New Vector(0.0,0.0,0.0)

				Endif
				
				''don't disrupt the norm for other verts 
				norm_map.Set(vx, norm.Add(vnorm) ) ' norm = (norm+vnorm)/2
		
			Next
			
			
		Next

		
		For Local v:=0 To no_verts-1
			Local vx:Vector = vert_data.PeekVertCoords(v) 'New Vector( vert_coords.Peek(v*3+0), vert_coords.Peek(v*3+1), vert_coords.Peek(v*3+2))

			Local norm:Vector = norm_map.Get(vx)
			
			If norm
				norm = norm.Normalize()
				
				vert_data.PokeNormals(v,norm.x,norm.y,norm.z)
				'vert_norm.Poke(v*3+0,norm.x)
				'vert_norm.Poke(v*3+1,norm.y)
				'vert_norm.Poke(v*3+2,norm.z)
			Endif
			
		Next
	
		reset_vbo = reset_vbo|4
	End 
		
		
	
	
	Method TriangleNX#(tri_no)

		Local v0=TriangleVertex(tri_no,0)
		Local v1=TriangleVertex(tri_no,1)
		Local v2=TriangleVertex(tri_no,2)
	
		'Local ax#=VertexX#(v1)-VertexX#(v0)
		Local ay#=VertexY(v1)-VertexY(v0)
		Local az#=VertexZ(v1)-VertexZ(v0)
		
		'Local bx#=VertexX#(v2)-VertexX#(v1)
		Local by#=VertexY(v2)-VertexY(v1)
		Local bz#=VertexZ(v2)-VertexZ(v1)
		
		Return (ay*bz)-(az*by)
		
	End 

	Method TriangleNY#(tri_no)
	
		Local v0=TriangleVertex(tri_no,0)
		Local v1=TriangleVertex(tri_no,1)
		Local v2=TriangleVertex(tri_no,2)

		Local ax#=VertexX(v1)-VertexX(v0)
		'Local ay#=VertexY(v1)-VertexY(v0)
		Local az#=VertexZ(v1)-VertexZ(v0)
		
		Local bx#=VertexX(v2)-VertexX(v1)
		'Local by#=VertexY(v2)-VertexY(v1)
		Local bz#=VertexZ(v2)-VertexZ(v1)
	
		Return (az*bx)-(ax*bz)
			
	End 

	Method TriangleNZ#(tri_no)
	
		Local v0=TriangleVertex(tri_no,0)
		Local v1=TriangleVertex(tri_no,1)
		Local v2=TriangleVertex(tri_no,2)
		
		Local ax#=VertexX(v1)-VertexX(v0)
		Local ay#=VertexY(v1)-VertexY(v0)
		'Local az#=VertexZ#(v1)-VertexZ#(v0)
		
		Local bx=VertexX(v2)-VertexX(v1)
		Local by=VertexY(v2)-VertexY(v1)
		'Local bz#=VertexZ#(v2)-VertexZ#(v1)
		
		Return (ax*by)-(ay*bx)
		
	End 
	
	Method UpdateVBO() ''--deprecated
		
		'OpenglES11.render.UpdateVBO(Self)
		
	End 
	
	Method FreeVBO() ''--deprecated
		
		'OpenglES11.render.FreeVBO(Self)
	
	End 
	
	' removes a tri from a surface
	Method RemoveTri(tri)
	
		'Local no_tris=CountTriangles(surf)
		Local temp_num:Int = no_tris
		Local tris:Vector[] = New Vector[temp_num]
		
		For Local t=0 To temp_num-1
			tris[t] = New Vector
			
			tris[t].x=TriangleVertex(t,0)
			tris[t].y=TriangleVertex(t,1)	
			tris[t].z=TriangleVertex(t,2)		
				
		Next
		
		ClearSurface False,True
	
		For Local t=0 To temp_num-1
		
			If t<>tri Then AddTriangle(tris[t].x,tris[t].y,tris[t].z)
			
		Next
		
		'UpdateNormals()
		
	End 
	
	Method WeldVerts(diff:Float = 0.001)
		''
		''does not work for texture UVs
		''
		
		Local va:VertArray[] = VertArray.AllocateArray(no_tris*3)
		Local total:Int =0, vx#, vy#, vz#
		Local dup:Bool, same:Int
		'Local vec:Vector = New Vector()
		
		Local new_surf:TSurface = New TSurface
	
		For Local t:=0 To no_tris-1

			Local new_tri:Int[3]
			
			For Local c:=0 To 2
	
				Local v:Int =TriangleVertex(t,c)
				vx = vert_data.VertexX(v) 'vert_coords.Peek(v*3+0)
				vy = vert_data.VertexY(v) 'vert_coords.Peek(v*3+1)
				vz = -vert_data.VertexZ(v) '-vert_coords.Peek(v*3+2)

				dup = False
				
				For Local j:= 0 To total
					
					If Abs(vx - va[j].x) < diff And Abs(vy - va[j].y) < diff And Abs(vz - va[j].z) < diff 
						'If VertexU(v,0) = VertexU(j,0) And VertexV(v,0) = VertexV(j,0)
						'If Abs(VertexU(v,0) - VertexU(j,0)) < 0.9 And Abs(VertexV(v,0) - VertexV(j,0)) < 0.9
							''weld duplicate vertex
							
							new_tri[c] = j
							dup = True
							same += 1
				
							Exit
						'Endif
					Endif
					
				Next

				
				If Not dup
				
					''save vertex to list
					va[total].x = vx; va[total].y = vy; va[total].z = vz; va[total].tri_no = t
						
					''add new vert
					new_tri[c] = total
					new_surf.AddVertex( vx, vy, vz, VertexU(v, 0), VertexV(v, 0), VertexW(v, 0)) ''includes tex_coords0
					new_surf.VertexTexCoords( total, VertexU(v, 1), VertexV(v, 1), VertexW(v, 1) )
					new_surf.VertexColor( total, VertexRed(v), VertexGreen(v), VertexBlue(v), VertexAlpha(v))
					new_surf.VertexNormal( total, VertexNX(v), VertexNY(v), VertexNZ(v))
					
					total += 1
					
				Endif
				
			Next
			
			''add new triangle
			new_surf.AddTriangle(new_tri[0], new_tri[1], new_tri[2])
			
		Next
	
		'Dprint  "Tsurface weld:" +no_verts+":"+total
	
		''replace surface
		tris = new_surf.tris
		vert_data = new_surf.vert_data
		'vert_coords = new_surf.vert_coords
		'vert_tex_coords0 = new_surf.vert_tex_coords0
		'vert_tex_coords1 = new_surf.vert_tex_coords1
		'vert_norm = new_surf.vert_norm
		'vert_col = new_surf.vert_col
		
		vert_array_size = new_surf.vert_array_size
		no_verts = total
		'anim surface?
		
		' mesh state has changed - update reset flags
		reset_vbo = reset_vbo|4
		
	End
	
	Method SnapVerts(diff:Float = 0.001)
		''
		'' function: takes all verts with a distance of diff or less and makes them equal
		'' helps remove seams from meshes
		''
		
		Local va:VertArray[] = VertArray.AllocateArray(no_tris*3)
		Local total:Int =0, vx#, vy#, vz#
		Local dup:Bool, same:Int

		'For Local v:=0 To (no_verts-1)*3 Step 3
		For Local v:=0 To (no_verts-1)

			vx = vert_data.VertexX(v) 'vert_coords.Peek(v+0)
			vy = vert_data.VertexY(v) 'vert_coords.Peek(v+1)
			vz = -vert_data.VertexZ(v) '-vert_coords.Peek(v+2)

			dup = False
			
			For Local j:= 0 To total
				
				If Int(vx)=Int(va[j].x) And Int(vy)=Int(va[j].y) And Int(vz)=Int(va[j].z) ''fast rejection
				
					If Abs(vx - va[j].x) < diff And Abs(vy - va[j].y) < diff And Abs(vz - va[j].z) < diff 
							
						'vert_coords.Poke( v+0, va[j].x)
						'vert_coords.Poke( v+1, va[j].y)
						'vert_coords.Poke( v+2,-va[j].z)
						vert_data.PokeVertCoords(v,va[j].x,va[j].y,-va[j].z)
						dup = True
						same += 1
			
						Exit
	
					Endif
				Endif
				
			Next

				
			If Not dup
				''save vertex to list
				va[total].x = vx; va[total].y = vy; va[total].z = vz 
				total += 1	
			Endif
	
			
		Next
	
		' mesh state has changed - update reset flags
		reset_vbo = reset_vbo|4
		
	End

	
	
	' removes redundent verts (non-working)
	Function RemoveVerts(surf:TSurface)
	
		Local no_tris:Int = surf.CountTriangles()
		Local tris:Int[][] = AllocateIntArray(no_tris,3)
		
		Local no_verts:Int = surf.CountVertices()
		
		Local vert_used:Int[no_verts]
		Local vert_info:Float[][] = AllocateFloatArray(no_verts,15)
		Local new_vert_index:Int[no_verts]
		
		For Local t=0 To no_tris-1
	
			For Local i=0 To 2
	
				tris[t][i]=surf.TriangleVertex(t,i)
				
				Local tt:Int = tris[t][i]
				
				vert_used[tt]=True
			
				vert_info[tt][0]=surf.VertexX(i)
				vert_info[tt][1]=surf.VertexY(i)
				vert_info[tt][2]=surf.VertexZ(i)
				vert_info[tt][3]=surf.VertexNX(i)
				vert_info[tt][4]=surf.VertexNY(i)
				vert_info[tt][5]=surf.VertexNZ(i)
				vert_info[tt][6]=surf.VertexRed(i)
				vert_info[tt][7]=surf.VertexGreen(i)
				vert_info[tt][8]=surf.VertexBlue(i)
				vert_info[tt][9]=surf.VertexU(i,0)
				vert_info[tt][10]=surf.VertexV(i,0)
				vert_info[tt][11]=surf.VertexW(i,0)
				vert_info[tt][12]=surf.VertexU(i,1)
				vert_info[tt][13]=surf.VertexV(i,1)
				vert_info[tt][14]=surf.VertexW(i,1)
					
			Next
					
		Next
		
		surf.ClearSurface (True,True)
	
		For Local v=0 To no_verts-1
		
			If vert_used[v]=True
		
				Local new_index=surf.AddVertex(vert_info[v][0],vert_info[v][1],vert_info[v][2] )
				surf.VertexNormal (new_index,vert_info[v][3],vert_info[v][4],vert_info[v][5] )
				surf.VertexColor (new_index,vert_info[v][6],vert_info[v][7],vert_info[v][8] )
				surf.VertexTexCoords (new_index,vert_info[v][9],vert_info[v][10],vert_info[v][11],0 )
				surf.VertexTexCoords (new_index,vert_info[v][12],vert_info[v][13],vert_info[v][14],1 )
				new_vert_index[v]=new_index
		
			Endif
			
		Next
		
		For Local t=0 To no_tris-1
	
			Local v0=new_vert_index[tris[t][0]]
			Local v1=new_vert_index[tris[t][1]]
			Local v2=new_vert_index[tris[t][2]]
			
			surf.AddTriangle(v0,v1,v2)
			
		Next
		
	End 
	
	Method GetVertex:Vertex(vid:Int)
	
		Local v:Vertex = New Vertex
		v.GetVertex(vid,vert_data)
		Return v
		
	End
	
	Method ToString$()
		For Local i:Int=0 To no_verts-1
			Print "v:"+i+" "+GetVertexCoords(i)
		Next
	End
	
End 


''
'' helper classes
''




Class VertArray

	Field tri_no:Int
	Field x:Float, y:Float, z:Float
	
	Function AllocateArray:VertArray[](i:Int=0)
		Local o:VertArray[i]
		For Local j:= 0 To i-1
			o[j] = New VertArray
		Next
		Return o
	End
	
End


Class NormMap <V> Extends Map<Vector, V>
	Method Compare:Int( lhs:Vector,rhs:Vector )
		If lhs.x<rhs.x Return -1
		If lhs.x>rhs.x Return 1
		If lhs.y<rhs.y Return -1
		If lhs.y>rhs.y Return 1
		If lhs.z<rhs.z Return -1
		Return lhs.z>rhs.z
	End
End


