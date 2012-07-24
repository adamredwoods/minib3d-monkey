''NOTES
''- uses Base64 to read binary files
Import minib3d

Class TModelB3D
	
#If CONFIG="debug"
	Const DEBUGMODEL:Int =1
#else
	Const DEBUGMODEL:Int =0
#Endif
	
	Const NODE:Int = 1162104654
	Const TEXS:Int = 1398293844
	Const BRUS:Int = 1398100546
	Const MESH:Int = 1213416781
	Const VRTS:Int = 1398035030
	Const TRIS:Int = 1397314132
	Const ANIM:Int = 1296649793
	Const BONE:Int = 1162760002
	Const KEYS:Int = 1398359371
	Const BB3D:Int = 1144209986
	
	Function LoadAnimB3D:TMesh(f_name$,parent_ent_ext:TEntity=Null)
	
		' Start file reading
		
		Local file:Base64 = Base64.Load(f_name)
		
		If file.Size() <=1
			Dprint "File not found"
			Return New TMesh
		Endif
		
			
		' Header info
		
		Local tag:Int
		Local prev_tag:Int
		Local new_tag:Int
		Local vno:Int
		
		tag=file.ReadTag()
		
		If DEBUGMODEL Then Print "TModel "+PrintTag(tag)

		vno =file.ReadInt() 'tag
		vno =file.ReadInt() 'size

		vno =file.ReadInt() 'version

		If tag<>BB3D Dprint  "Invalid b3d file"; Return New TMesh
		If Int(vno*0.01) >0 Dprint  "Invalid b3d file version"; Return New TMesh
		
		' Locals
		
		Local size:Int
		Local node_level:Int=-1
		Local old_node_level:Int=-1
		Local node_pos:Int[100]
	
		' tex local vars
		Local tex_no:Int=0
		Local tex:TTexture[1]
		Local te_file$
		Local te_flags:Int
		Local te_blend:Int
		Local te_coords:Int
		Local te_u_pos#
		Local te_v_pos#
		Local te_u_scale#
		Local te_v_scale#
		Local te_angle#
		
		' brush local vars
		Local brush_no:Int
		Local brush:TBrush[1]
		Local b_no_texs:Int
		Local b_name$
		Local b_red#
		Local b_green#
		Local b_blue#
		Local b_alpha#
		Local b_shine#
		Local b_blend:Int
		Local b_fx:Int
		Local b_tex_id:Int
		
		' node local vars
		Local n_name$=""
		Local n_px#=0
		Local n_py#=0
		Local n_pz#=0
		Local n_sx#=0
		Local n_sy#=0
		Local n_sz#=0
		Local n_rx#=0
		Local n_ry#=0
		Local n_rz#=0
		Local n_qw#=0
		Local n_qx#=0
		Local n_qy#=0
		Local n_qz#=0
		
		' mesh local vars
		Local mesh:TMesh
		Local m_brush_id:Int
	
		' verts local vars
		Local v_mesh:TMesh
		Local v_surf:TSurface
		Local v_flags:Int
		Local v_tc_sets:Int
		Local v_tc_size:Int
		Local v_sz
		Local v_x#
		Local v_y#
		Local v_z#
		Local v_nx#
		Local v_ny#
		Local v_nz#
		Local v_r#
		Local v_g#
		Local v_b#
		Local v_u#
		Local v_v#
		Local v_w#
		Local v_a#	
		Local v_id
		
		' tris local vars
		Local surf:TSurface
		Local tr_brush_id:Int
		Local tr_sz:Int
		Local tr_vid:Int
		Local tr_vid0:Int
		Local tr_vid1:Int
		Local tr_vid2:Int
		Local tr_x#
		Local tr_y#
		Local tr_z#
		Local tr_nx#
		Local tr_ny#
		Local tr_nz#
		Local tr_r#
		Local tr_g#
		Local tr_b#
		Local tr_u#
		Local tr_v#
		Local tr_w#
		Local tr_a#	
		Local tr_no:Int
		
		' anim local vars
		Local a_flags:Int
		Local a_frames:Int
		Local a_fps:Int
					
		' bone local vars
		Local bo_bone:TBone
		Local bo_no_bones:Int
		Local bo_vert_id:Int
		Local bo_vert_w#
		
		' key local vars	
		Local k_flags:Int
		Local k_frame:Int
		Local k_px#
		Local k_py#
		Local k_pz#
		Local k_sx#
		Local k_sy#
		Local k_sz#
		Local k_qw#
		Local k_qx#
		Local k_qy#
		Local k_qz#
	
		Local parent_ent:TEntity=Null ' parent_ent - used to keep track of parent entitys within model, separate to parent_ent_ext paramater which is external to model
		Local root_ent:TEntity=Null
	
		Local last_ent:TEntity=Null ' last created entity, used for assigning parent ent in node code
	
		' Begin chunk (tag) reading
	
		Repeat
	
			new_tag=file.ReadTag()
			
			If NewTag(new_tag)=True
			
				prev_tag=tag
				tag=new_tag
				
				file.ReadInt() 'tag
				size=file.ReadInt() 'size
	
				' deal with nested nodes
				
				old_node_level=node_level
				If tag=NODE ' "NODE"
				
					node_level=node_level+1
			
					If node_level>0
					
						Local fd=0
						Repeat
							fd=file.Position()-node_pos[node_level-1]
							If fd>=8
							
								node_level=node_level-1
	
							Endif
		
						Until fd<8
					
					Endif
					
					node_pos[node_level]=file.Position()+size
																																																																									
				Endif
				
				' up level
				If node_level>old_node_level
				
					If node_level>0
						parent_ent=last_ent
					Else
						parent_ent=Null
					Endif
					
				Endif
				
				' down level
				If node_level<old_node_level
				
					Local tent:TEntity=root_ent
					
					' get parent entity of last entity of new node level
					If node_level>1
					
						Local cc
						For Local levs=1 To node_level-2
							cc=tent.CountChildren()
							tent=tent.GetChild(cc)
						Next
						cc=tent.CountChildren()			
						tent=tent.GetChild(cc)
						parent_ent=tent
						
					Endif
					
					If node_level=1 Then parent_ent=root_ent
					If node_level=0 Then parent_ent=Null
					
				Endif
						
				' output debug tree
				If DEBUGMODEL
					Local tab$=""
					Local info$=""
					If tag=NODE And parent_ent<>Null Then info=" (parent= "+parent_ent.name+")"
					For Local i=1 To node_level
						tab=tab+"-"
					Next
					Dprint  tab+" "+PrintTag(tag)+" "+info
				Endif
				
			Else
			
				tag=0
				
			Endif
			
			
	
			Select tag
			
				Case TEXS '"TEXS"
				
					'Local tex_no=0 ' moved to top
					
					new_tag=file.ReadTag()
					
					While NewTag(new_tag)<>True And file.Eof()<>True
					
						te_file=B3DReadString(file)
						te_flags=file.ReadInt()
						te_blend=file.ReadInt()
						te_u_pos=file.ReadFloat()
						te_v_pos=file.ReadFloat()
						te_u_scale=file.ReadFloat()
						te_v_scale=file.ReadFloat()
						te_angle=file.ReadFloat()
			'Print te_u_pos+" "+te_v_pos
			'Print "tex flag"+te_flags+" "+te_u_scale
			'Print "pos "+file.Position
			
						' hidden tex coords 1 flag
						If te_flags&65536
							te_flags=te_flags-65536
							te_coords=1
						Else
							te_coords=0
						Endif
						
						' convert tex angle from rad to deg
						te_angle=te_angle*(180.0/PI)
	
						' create texture object so we can set texture values (blend etc) before loading texture
						tex[tex_no]=New TTexture
	
						' .flags and .file set in LoadTexture
						tex[tex_no].blend=te_blend
						tex[tex_no].coords=te_coords
						tex[tex_no].u_pos=te_u_pos
						tex[tex_no].v_pos=te_v_pos
						tex[tex_no].u_scale=te_u_scale
						tex[tex_no].v_scale=te_v_scale
						tex[tex_no].angle=te_angle
									
						' load texture, providing texture we created above as parameter.
						' if a texture exists with all the same values as above (blend etc), the existing texture will be returned.
						' if not then the texture created above (supplied as param below) will be returned
						tex[tex_no]=TTexture.LoadTexture(te_file,te_flags,tex[tex_no])
						
						If tex[tex_no].gltex[0] And DEBUGMODEL Then Dprint  "-Load Texture:"+te_file
											
						tex_no=tex_no+1
						tex=tex.Resize(tex_no+1) ' resize array +1
	
						new_tag=file.ReadTag()

				
					Wend
			
				Case BRUS
						
					'Local brush_no=0 ' moved to top
					
					b_no_texs=file.ReadInt()
					
					new_tag=file.ReadTag()
					
					While NewTag(new_tag)<>True And file.Eof()<>True
	
						b_name=B3DReadString(file)
						b_red=file.ReadFloat()
						b_green=file.ReadFloat()
						b_blue=file.ReadFloat()
						b_alpha=file.ReadFloat()
						b_shine=file.ReadFloat()
						b_blend=file.ReadInt()
						b_fx=file.ReadInt()
						
						brush[brush_no]=TBrush.CreateBrush()
						brush[brush_no].no_texs=b_no_texs
						brush[brush_no].name=b_name
						brush[brush_no].red=b_red
						brush[brush_no].green=b_green
						brush[brush_no].blue=b_blue
						brush[brush_no].alpha=b_alpha
						brush[brush_no].shine=b_shine
						brush[brush_no].blend=b_blend
						brush[brush_no].fx=b_fx
				
						For Local ix=0 To b_no_texs-1
						
							b_tex_id=file.ReadInt()
			
							If b_tex_id>=0
								brush[brush_no].tex[ix]=tex[b_tex_id]
							Else
								brush[brush_no].tex[ix]=Null
							Endif
			
						Next
		
						brush_no=brush_no+1
						brush=brush.Resize(brush_no+1) ' resize array +1
						
						new_tag=file.ReadTag()
					
					Wend
					
				Case NODE
	
					new_tag=file.ReadTag()
					
					n_name=B3DReadString(file)
					n_px=file.ReadFloat()
					n_py=file.ReadFloat()
					n_pz=-file.ReadFloat() '*-1
					n_sx=file.ReadFloat()
					n_sy=file.ReadFloat()
					n_sz=file.ReadFloat()
					n_qw=file.ReadFloat()
					n_qx=file.ReadFloat()
					n_qy=file.ReadFloat()
					n_qz=file.ReadFloat()
					
					Local rot:Float[] = Quaternion.QuatToEuler(n_qx,n_qy,-n_qz,n_qw)
					Local pitch#=rot[0]
					Local yaw#=rot[1]
					Local roll#=rot[2]
					n_rx=-pitch
					n_ry=yaw
					n_rz=roll
	
					new_tag=file.ReadTag()
					
					If new_tag=NODE Or new_tag=ANIM
		
						' make 'piv' entity a mesh, not a pivot, as B3D does
						Local piv:TMesh=New TMesh
						piv.classname="Model"
			
						piv.name=n_name
						piv.px=n_px
						piv.py=n_py
						piv.pz=n_pz
						piv.sx=n_sx
						piv.sy=n_sy
						piv.sz=n_sz
						piv.rx=n_rx
						piv.ry=n_ry
						piv.rz=n_rz
						piv.qw=n_qw
						piv.qx=n_qx
						piv.qy=n_qy
						piv.qz=n_qz
								
						'piv.UpdateMat(True)
						TEntity.entity_list.EntityListAdd(piv)
						last_ent=piv
			
						' root ent?
						If root_ent=Null Then root_ent=piv
			
						' if ent is root ent, and external parent specified, add parent
						If root_ent=piv Then piv.AddParent(parent_ent_ext)
			
						' if ent nested then add parent
						If node_level>0 Then piv.AddParent(parent_ent)
						
						Quaternion.QuatToMatrix(n_qx,n_qy,n_qz,n_qw, piv.mat)
										
						piv.mat.grid[3][0]=n_px
						piv.mat.grid[3][1]=n_py
						piv.mat.grid[3][2]=n_pz
						
						piv.mat.Scale(n_sx,n_sy,n_sz)
							
						If piv.parent<>Null
							Local new_mat:Matrix=piv.parent.mat.Copy()
							new_mat.Multiply(piv.mat)
							piv.mat.Overwrite(new_mat)'.Multiply(mat)
						Endif				
				
					Endif
			
				Case MESH
						
					m_brush_id=file.ReadInt()
					
					mesh=New TMesh
					mesh.classname="Model"
					mesh.name=n_name
					mesh.px=n_px
					mesh.py=n_py
					mesh.pz=n_pz
					mesh.sx=n_sx
					mesh.sy=n_sy
					mesh.sz=n_sz
					mesh.rx=n_rx
					mesh.ry=n_ry
					mesh.rz=n_rz
					mesh.qw=n_qw
					mesh.qx=n_qx
					mesh.qy=n_qy
					mesh.qz=n_qz
					
					'TEntity.entity_list.EntityListAdd(mesh)
					last_ent=mesh
					
					' root ent?
					If root_ent=Null Then root_ent=mesh
					
					' if ent is root ent, and external parent specified, add parent
					If root_ent=mesh Then mesh.AddParent(parent_ent_ext)
					
					' if ent nested then add parent
					If node_level>0 Then mesh.AddParent(parent_ent)
					
					Quaternion.QuatToMatrix(n_qx,n_qy,n_qz,n_qw, mesh.mat)
									
					mesh.mat.grid[3][0]=n_px
					mesh.mat.grid[3][1]=n_py
					mesh.mat.grid[3][2]=n_pz
					
					mesh.mat.Scale(n_sx,n_sy,n_sz)
					
					If mesh.parent<>Null
						Local new_mat:Matrix = mesh.parent.mat.Copy()
						new_mat.Multiply(mesh.mat)
						mesh.mat.Overwrite(new_mat)'.Multiply(mat)
					Endif				
	
				Case VRTS
				
					'If v_mesh<>Null Then v_mesh=Null
					'If v_surf<>Null Then v_surf=Null
						
					v_mesh=New TMesh
					v_surf=v_mesh.CreateSurface()
					v_flags=file.ReadInt()
					v_tc_sets=file.ReadInt()
					v_tc_size=file.ReadInt()
					v_sz=12+v_tc_sets*v_tc_size*4
					If v_flags & 1 Then v_sz=v_sz+12
					If v_flags & 2 Then v_sz=v_sz+16
	
					new_tag=file.ReadTag()
	
					While NewTag(new_tag)<>True And file.Eof()<>True
				
						v_x=file.ReadFloat()
						v_y=file.ReadFloat()
						v_z=file.ReadFloat()
						
						If v_flags&1
							v_nx=file.ReadFloat()
							v_ny=file.ReadFloat()
							v_nz=file.ReadFloat()
						Endif
						
						If v_flags&2
							v_r=file.ReadFloat()*255.0 ' *255 as VertexColor requires 0-255 values
							v_g=file.ReadFloat()*255.0
							v_b=file.ReadFloat()*255.0
							v_a=file.ReadFloat()
						Endif
						
						v_id=v_surf.AddVertex(v_x,v_y,v_z)
						v_surf.VertexColor(v_id,v_r,v_g,v_b,v_a)
						v_surf.VertexNormal(v_id,v_nx,v_ny,v_nz)
						
						'read tex coords...
						For Local j=0 To v_tc_sets-1 ' texture coords per vertex - 1 for simple uv, 8 max
							For Local k=1 To v_tc_size ' components per set - 2 for simple uv, 4 max
								If k=1 v_u=file.ReadFloat()
								If k=2 v_v=file.ReadFloat()
								If k=3 v_w=file.ReadFloat()
							Next
							If j=0 Or j=1 Then v_surf.VertexTexCoords(v_id,v_u,v_v,v_w,j)
						Next
							
						new_tag=file.ReadTag()
														
					Wend

				Case TRIS
							
					Local old_tr_brush_id=tr_brush_id
					tr_brush_id=file.ReadInt()
	
					' don't create new surface if tris chunk has same brush as chunk immediately before it
					If (prev_tag<>TRIS Or tr_brush_id<>old_tr_brush_id)
					
						' no further tri data for this surf - trim verts
						If prev_tag=TRIS Then TrimVerts(surf)
					
						' new surf - copy arrays
						surf=mesh.CreateSurface()
						surf.no_verts = v_surf.no_verts
						
						surf.vert_data=CopyDataBuffer(v_surf.vert_data, VertexDataBuffer.Create(surf.no_verts))
						'surf.vert_coords=CopyFloatBuffer(v_surf.vert_coords, FloatBuffer.Create(surf.no_verts*3))
						'surf.vert_col=CopyFloatBuffer(v_surf.vert_col, FloatBuffer.Create(surf.no_verts*4))
						'surf.vert_norm=CopyFloatBuffer(v_surf.vert_norm,  FloatBuffer.Create(surf.no_verts*3))
						'surf.vert_tex_coords0=CopyFloatBuffer(v_surf.vert_tex_coords0, FloatBuffer.Create(surf.no_verts*2))
						'surf.vert_tex_coords1=CopyFloatBuffer(v_surf.vert_tex_coords1, FloatBuffer.Create(surf.no_verts*2))
					
					Endif
	
					tr_sz=12
						
					new_tag=file.ReadTag()
	
					While NewTag(new_tag)<>True And file.Eof()<>True
					
						tr_vid0=file.ReadInt()
						tr_vid1=file.ReadInt()
						tr_vid2=file.ReadInt()
				
						' Find out minimum and maximum vertex indices - used for TrimVerts func after
						' (TrimVerts used due to .b3d format not being an exact fit with Blitz3D itself)
						If tr_vid0<surf.vmin Then surf.vmin=tr_vid0
						If tr_vid1<surf.vmin Then surf.vmin=tr_vid1
						If tr_vid2<surf.vmin Then surf.vmin=tr_vid2
						
						If tr_vid0>surf.vmax Then surf.vmax=tr_vid0
						If tr_vid1>surf.vmax Then surf.vmax=tr_vid1
						If tr_vid2>surf.vmax Then surf.vmax=tr_vid2
				
						surf.AddTriangle(tr_vid0,tr_vid1,tr_vid2)
			
						new_tag=file.ReadTag()

					Wend
					
					If m_brush_id<>-1 Then mesh.PaintEntity(brush[m_brush_id])
					If tr_brush_id<>-1 Then surf.PaintSurface(brush[tr_brush_id])
					
					If v_flags&1=0 And new_tag<>TRIS Then mesh.UpdateNormals() ' if no normal data supplied and no further tri data then update normals
	
					' no further tri data for this surface - trim verts
					If new_tag<>TRIS Then TrimVerts(surf)

				Case ANIM
				
					a_flags=file.ReadInt()
					a_frames=file.ReadInt()
					a_fps=file.ReadFloat()
					
					If mesh<>Null
					
						mesh.anim=True
					
						'mesh.frames=a_frames
						mesh.anim_seqs_first[0]=0
						mesh.anim_seqs_last[0]=a_frames
						
						' create anim surfs, copy vertex coords array, add to anim_surf_list
						mesh.anim_surf = New TSurface[mesh.no_surfs]
						
						For Local surf:TSurface=Eachin mesh.surf_list
							
							'' attach reference to the surface (edit 2012)
							mesh.anim_surf[surf.surf_id] = surf.Copy()
							Local anim_surf:TSurface = mesh.anim_surf[surf.surf_id]
							
							'ListAddLast(mesh.anim_surf_list,anim_surf)

							anim_surf.no_verts=surf.no_verts
										
							'anim_surf.vert_coords=CopyFloatBuffer(surf.vert_coords, FloatBuffer.Create(surf.no_verts*3))
							anim_surf.vert_data=CopyDataBuffer(surf.vert_data, VertexDataBuffer.Create(surf.no_verts))
						
							anim_surf.vert_bone1_no=anim_surf.vert_bone1_no.Resize(surf.no_verts+1)
							anim_surf.vert_bone2_no=anim_surf.vert_bone2_no.Resize(surf.no_verts+1)
							anim_surf.vert_bone3_no=anim_surf.vert_bone3_no.Resize(surf.no_verts+1)
							anim_surf.vert_bone4_no=anim_surf.vert_bone4_no.Resize(surf.no_verts+1)
							anim_surf.vert_weight1=anim_surf.vert_weight1.Resize(surf.no_verts+1)
							anim_surf.vert_weight2=anim_surf.vert_weight2.Resize(surf.no_verts+1)
							anim_surf.vert_weight3=anim_surf.vert_weight3.Resize(surf.no_verts+1)
							anim_surf.vert_weight4=anim_surf.vert_weight4.Resize(surf.no_verts+1)
							
							' transfer vmin/vmax values for using with TrimVerts func after
							anim_surf.vmin=surf.vmin
							anim_surf.vmax=surf.vmax
						
						Next
												
					Endif
	
				Case BONE
				
					Local ix:Int=0
					
					new_tag=file.ReadTag()
				
					bo_bone = New TBone
					bo_no_bones=bo_no_bones+1
					
					While NewTag(new_tag)<>True And file.Eof()<>True
				
						bo_vert_id=file.ReadInt()
						bo_vert_w=file.ReadFloat()
						
						' assign weight values, with the strongest weight in vert_weight[1], and weakest in vert_weight[4]
									
						For Local anim_surf:TSurface=Eachin mesh.anim_surf
							
							'anim_surf = mesh.anim_surf[surf.surf_id]
							
							If bo_vert_id>=anim_surf.vmin And bo_vert_id<=anim_surf.vmax
						
								If anim_surf<>Null
								
									Local vid=bo_vert_id-anim_surf.vmin
								
									If bo_vert_w>anim_surf.vert_weight1[vid]
														
										anim_surf.vert_bone4_no[vid]=anim_surf.vert_bone3_no[vid]
										anim_surf.vert_weight4[vid]=anim_surf.vert_weight3[vid]
										
										anim_surf.vert_bone3_no[vid]=anim_surf.vert_bone2_no[vid]
										anim_surf.vert_weight3[vid]=anim_surf.vert_weight2[vid]
										
										anim_surf.vert_bone2_no[vid]=anim_surf.vert_bone1_no[vid]
										anim_surf.vert_weight2[vid]=anim_surf.vert_weight1[vid]
										
										anim_surf.vert_bone1_no[vid]=bo_no_bones
										anim_surf.vert_weight1[vid]=bo_vert_w
																
									Else If bo_vert_w>anim_surf.vert_weight2[vid]
									
										anim_surf.vert_bone4_no[vid]=anim_surf.vert_bone3_no[vid]
										anim_surf.vert_weight4[vid]=anim_surf.vert_weight3[vid]
										
										anim_surf.vert_bone3_no[vid]=anim_surf.vert_bone2_no[vid]
										anim_surf.vert_weight3[vid]=anim_surf.vert_weight2[vid]
										
										anim_surf.vert_bone2_no[vid]=bo_no_bones
										anim_surf.vert_weight2[vid]=bo_vert_w
																							
									Else If bo_vert_w>anim_surf.vert_weight3[vid]
									
										anim_surf.vert_bone4_no[vid]=anim_surf.vert_bone3_no[vid]
										anim_surf.vert_weight4[vid]=anim_surf.vert_weight3[vid]
						
										anim_surf.vert_bone3_no[vid]=bo_no_bones
										anim_surf.vert_weight3[vid]=bo_vert_w
							
									Else If bo_vert_w>anim_surf.vert_weight4[vid]
									
										anim_surf.vert_bone4_no[vid]=bo_no_bones
										anim_surf.vert_weight4[vid]=bo_vert_w
												
									Endif
													
								Endif
								
							Endif
							
						Next
						
						new_tag=file.ReadTag()
							
					Wend
					

					bo_bone.classname="Bone"
					bo_bone.name=n_name
					bo_bone.px=n_px
					bo_bone.py=n_py
					bo_bone.pz=n_pz
					bo_bone.sx=n_sx
					bo_bone.sy=n_sy
					bo_bone.sz=n_sz
					bo_bone.rx=n_rx
					bo_bone.ry=n_ry
					bo_bone.rz=n_rz
					bo_bone.qw=n_qw
					bo_bone.qx=n_qx
					bo_bone.qy=n_qy
					bo_bone.qz=n_qz
					
					bo_bone.n_px=n_px
					bo_bone.n_py=n_py
					bo_bone.n_pz=n_pz
					bo_bone.n_sx=n_sx
					bo_bone.n_sy=n_sy
					bo_bone.n_sz=n_sz
					bo_bone.n_rx=n_rx
					bo_bone.n_ry=n_ry
					bo_bone.n_rz=n_rz
					bo_bone.n_qw=n_qw
					bo_bone.n_qx=n_qx
					bo_bone.n_qy=n_qy
					bo_bone.n_qz=n_qz
				
					bo_bone.keys=New TAnimationKeys
					bo_bone.keys.frames=a_frames
					bo_bone.keys.flags=bo_bone.keys.flags.Resize(a_frames+1)
					bo_bone.keys.px=bo_bone.keys.px.Resize(a_frames+1)
					bo_bone.keys.py=bo_bone.keys.py.Resize(a_frames+1)
					bo_bone.keys.pz=bo_bone.keys.pz.Resize(a_frames+1)
					bo_bone.keys.sx=bo_bone.keys.sx.Resize(a_frames+1)
					bo_bone.keys.sy=bo_bone.keys.sy.Resize(a_frames+1)
					bo_bone.keys.sz=bo_bone.keys.sz.Resize(a_frames+1)
					bo_bone.keys.qw=bo_bone.keys.qw.Resize(a_frames+1)
					bo_bone.keys.qx=bo_bone.keys.qx.Resize(a_frames+1)
					bo_bone.keys.qy=bo_bone.keys.qy.Resize(a_frames+1)
					bo_bone.keys.qz=bo_bone.keys.qz.Resize(a_frames+1)
							
					' root ent?
					If root_ent=Null Then root_ent=bo_bone
					
					' if ent nested then add parent
					If node_level>0 Then bo_bone.AddParent(parent_ent)
					
					Quaternion.QuatToMatrix(bo_bone.n_qx,bo_bone.n_qy,bo_bone.n_qz,bo_bone.n_qw, bo_bone.mat)
					
					bo_bone.mat.grid[3][0]=bo_bone.n_px
					bo_bone.mat.grid[3][1]=bo_bone.n_py
					bo_bone.mat.grid[3][2]=bo_bone.n_pz
					

					
					If bo_bone.parent<>Null And TBone(bo_bone.parent)<>Null ' And... onwards needed to prevent inv_mat being incorrect if external parent supplied
						Local new_mat:Matrix=bo_bone.parent.mat.Copy()
						new_mat.Multiply(bo_bone.mat)
						bo_bone.mat.Overwrite(new_mat)
					Endif

					bo_bone.inv_mat=bo_bone.mat.Inverse()
				
					If new_tag<>KEYS
					
						bo_bone.entity_link = TEntity.entity_list.EntityListAdd(bo_bone)
						mesh.bones=mesh.bones.Resize(bo_no_bones)
						mesh.bones[bo_no_bones-1]=bo_bone
						last_ent=bo_bone
						mesh.no_bones = bo_no_bones
						
					Endif
		
				Case KEYS
				
					k_flags=file.ReadInt()
				
					new_tag=file.ReadTag()
	
					While NewTag(new_tag)<>True And file.Eof()<>True
				
						k_frame=file.ReadInt()
						
						If(k_flags&1) 'pos
							k_px=file.ReadFloat()
							k_py=file.ReadFloat()
							k_pz=-file.ReadFloat()
						Endif
						If(k_flags&2) 'sca
							k_sx=file.ReadFloat()
							k_sy=file.ReadFloat()
							k_sz=file.ReadFloat()
						Endif
						If(k_flags&4) 'rot
							k_qw=-file.ReadFloat()
							k_qx=file.ReadFloat()
							k_qy=file.ReadFloat()
							k_qz=-file.ReadFloat()
							
						Endif
	
						If bo_bone<>Null 'And k_frame < bo_bone.keys.frames ' check if bo_bone exists - it won't for non-boned, keyframe anims
						
							bo_bone.keys.flags[k_frame]=bo_bone.keys.flags[k_frame]+k_flags
							If(k_flags&1)
								bo_bone.keys.px[k_frame]=k_px
								bo_bone.keys.py[k_frame]=k_py
								bo_bone.keys.pz[k_frame]=k_pz
							Endif
							If(k_flags&2)
								bo_bone.keys.sx[k_frame]=k_sx
								bo_bone.keys.sy[k_frame]=k_sy
								bo_bone.keys.sz[k_frame]=k_sz
							Endif
							If(k_flags&4)
								bo_bone.keys.qw[k_frame]=k_qw
								bo_bone.keys.qx[k_frame]=k_qx
								bo_bone.keys.qy[k_frame]=k_qy
								bo_bone.keys.qz[k_frame]=k_qz
							Endif
						
						Endif
						
						new_tag=file.ReadTag()
							
					Wend
					
					If new_tag<>KEYS
					
						If bo_bone<>Null ' check if bo_bone exists - it won't for non-boned, keyframe anims
					
							bo_bone.entity_link = TEntity.entity_list.EntityListAdd(bo_bone)
							mesh.bones=mesh.bones.Resize(bo_no_bones)
							mesh.bones[bo_no_bones-1]=bo_bone
							last_ent=bo_bone
							mesh.no_bones = bo_no_bones
							
						Endif
						
					Endif
					
				Default
				
					file.ReadByte()
	
			End Select
		
		Until file.Eof()
		
		file.Free()
		
		''clean up buffers
		For Local surf:TSurface = Eachin mesh.surf_list
			surf.CropSurfaceBuffers()
			If mesh.anim_surf[surf.surf_id] Then mesh.anim_surf[surf.surf_id].CropSurfaceBuffers()
		Next
		
		Return TMesh(root_ent)
	
	End 


	''
	' Due to the .b3d format not being an exact fit with B3D, we need to slice vert arrays
	' Otherwise we duplicate all vert information per surf
	Function TrimVerts(surf:TSurface)

			
		If surf.no_tris=0 Then Return ' surf has no tri info, do not trim
				
		Local vmin=surf.vmin
		Local vmax=surf.vmax
		Local diff = vmax-vmin
		
		surf.vert_data= CopyDataBuffer(surf.vert_data, VertexDataBuffer.Create(diff+1), vmin,vmax+1)
		'surf.vert_coords=CopyFloatBuffer(surf.vert_coords, FloatBuffer.Create( diff*3+3 ), vmin*3,vmax*3+3)
		'surf.vert_col=CopyFloatBuffer(surf.vert_col, FloatBuffer.Create( diff*4+4 ), vmin*4,vmax*4+4)
		'surf.vert_norm=CopyFloatBuffer(surf.vert_norm, FloatBuffer.Create( diff*3+3 ), vmin*3,vmax*3+3)
		'surf.vert_tex_coords0= CopyFloatBuffer(surf.vert_tex_coords0, FloatBuffer.Create( diff*2+2 ), vmin*2,vmax*2+2)
		'surf.vert_tex_coords1= CopyFloatBuffer(surf.vert_tex_coords1, FloatBuffer.Create( diff*2+2 ), vmin*2,vmax*2+2)
		
		'Local temp_tris:ShortBuffer = ShortBuffer.Create((surf.no_tris*3)+3)
		
		For Local i=0 Until (surf.no_tris*3)+3
			surf.tris.Poke(i, surf.tris.Peek(i)-vmin) ' reassign vertex indices
			'surf.tris[i]=surf.tris[i]-vmin ' reassign vertex indices
		Next
		
		surf.no_verts=(vmax-vmin)+1
		
	End 

	Function B3DReadString:String(file:Base64)
		Local t$="", ch:Int
		Repeat
			ch =file.ReadByte()
			If ch=0 Exit
			t=t.Join(["",String.FromChar(ch)]) ''backwards
		Forever
		
		''strip directory
		Local str:String[] = t.Split("/")
		
		Return str[str.Length()-1]
	End 
	

	
	Function NewTag(tag:Int)
	
		Select tag
		
			Case TEXS Return True
			Case BRUS Return True
			Case NODE Return True
			Case ANIM Return True
			Case MESH Return True
			Case VRTS Return True
			Case TRIS Return True
			Case BONE Return True
			Case KEYS Return True
			Default Return False
		
		End Select
	
	End 
	
	Function PrintTag:String(tag:Int)
		Select tag
		
			Case TEXS Return "TEXS"
			Case BRUS Return "BRUS"
			Case NODE Return "NODE"
			Case ANIM Return "ANIM"
			Case MESH Return "MESH"
			Case VRTS Return "VRTS"
			Case TRIS Return "TRIS"
			Case BONE Return "BONE"
			Case KEYS Return "KEYS"
			Default Return ""
		
		End Select
	End

End 



