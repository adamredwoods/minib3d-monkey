Import minib3d.monkeybuffer
Import minib3d.monkeyutility
''
''-----------------------------------------------------------------------
''

Function DumpB3D:Void( f_name$, outf$ )
	
	Local outp$ = ""
	
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
	
	Local data:DataBuffer
	
	If f_name.EndsWith(".txt")
		Local file:Base64 = Base64.Load(f_name)
		
		If file.Size() <=1
			Print "**File not found: "+f_name
			Return 
		Endif
		data = file.data
	Else
		data = DataBuffer.Load(FixDataPath(f_name))

		If Not data Or (data And data.Length() <=1)
			Print "**File not found: "+f_name
			Return 
		Endif
	Endif

		Local file:BufferReader = BufferReader.Create(data)

		
			
		' Header info
		
		Local tag:Int
		Local prev_tag:Int
		Local new_tag:Int
		Local vno:Int
		
		tag=file.ReadTag()
		
		outp+= "TModel "+TModelB3D.PrintTag(tag)+"~n"

		vno =file.ReadInt() 'tag
		vno =file.ReadInt() 'size

		vno =file.ReadInt() 'version

		If tag<>BB3D outp+=  "Invalid b3d file~n"
		If Int(vno*0.01) >0 outp+=   "Invalid b3d file version~n"
		
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

		
		' node local vars
		Local n_name$=""
		
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
		
		
		
		Local totaltris:Int=0
	
		' Begin chunk (tag) reading
	
		Repeat
	
			new_tag=file.ReadTag()
			
			If TModelB3D.NewTag(new_tag)=True
			
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
				Local tent:TEntity
				If node_level<old_node_level
				
					tent=root_ent
					
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

					Local tab$=""
					Local info$=""
					If tag=NODE And parent_ent<>Null Then info=" (parent= "+parent_ent.name+")"
					For Local i=1 To node_level
						tab=tab+"-"
					Next
					'outp +=  tab+" "+TModelB3D.PrintTag(tag)+" "+info+"~n"

				
			Else
			
				tag=0
				
			Endif
			
			
	
			Select tag
			
				Case TEXS '"TEXS"
				
					'Local tex_no=0 ' moved to top
					outp+="TEXS~n"
					
					new_tag=file.ReadTag()
					
					While TModelB3D.NewTag(new_tag)<>True And file.Eof()<>True
					
						te_file=TModelB3D.B3DReadString(file)
						te_flags=file.ReadInt()
			
						' hidden tex coords 1 flag
						If te_flags&65536
							te_flags=te_flags-65536
							te_coords=1
						Else
							te_coords=0
						Endif
						
						outp+=  "-Load Texture "+tex_no+":"+te_file+" flags:"+te_flags+" tecoords:"+te_coords+"~n"
											
						tex_no=tex_no+1
	
						new_tag=file.ReadTag()

				
					Wend
			
				Case BRUS
						
					'Local brush_no=0 ' moved to top
					
					outp+="BRUS~n"
					
					Local b_no_texs%=file.ReadInt()
					
					new_tag=file.ReadTag()
					
					While TModelB3D.NewTag(new_tag)<>True And file.Eof()<>True
	
						Local b_name$=TModelB3D.B3DReadString(file)
						Local b_red#=file.ReadFloat()
						Local b_green#=file.ReadFloat()
						Local b_blue#=file.ReadFloat()
						Local b_alpha#=file.ReadFloat()
						Local b_shine#=file.ReadFloat()
						Local b_blend%=file.ReadInt()
						Local b_fx%=file.ReadInt()
						
				
						For Local ix=0 To b_no_texs-1
						
							Local b_tex_id%=file.ReadInt()

			
						Next
		
						brush_no=brush_no+1
						
						new_tag=file.ReadTag()
				
					Wend
					
					outp+="no tex: "+b_no_texs+" actual:"+brush_no+"~n"
					
				Case NODE
					
					outp+="NODE~n"
					
					new_tag=file.ReadTag()
					
					Local n_name$=TModelB3D.B3DReadString(file)
					Local n_px#=file.ReadFloat()
					Local n_py#=file.ReadFloat()
					Local n_pz#=-file.ReadFloat() '*-1
					Local n_sx#=file.ReadFloat()
					Local n_sy#=file.ReadFloat()
					Local n_sz#=file.ReadFloat()
					Local n_qw#=file.ReadFloat()
					Local n_qx#=file.ReadFloat()
					Local n_qy#=file.ReadFloat()
					Local n_qz#=file.ReadFloat()
					
					outp+="data: "+n_name+" "+n_px+" "+n_py+" "+n_pz+" "+n_sx+" "+n_sy+" "+n_sz+" qx:"+n_qx+" qy:"+n_qy+" qz:"+n_qz+" qw:"+n_qw+"~n"
	
					new_tag=file.ReadTag()
					
			
				Case MESH
						
					outp+="MESH~n"
					
					m_brush_id=file.ReadInt()

					outp+="brushid:"+m_brush_id+"~n"
				
	
				Case VRTS
					outp+="VRTS~n"
						
						Local no_verts:Int=0
						
					v_flags=file.ReadInt()
					v_tc_sets=file.ReadInt()
					v_tc_size=file.ReadInt()
					v_sz=12+v_tc_sets*v_tc_size*4
					If v_flags & 1 Then v_sz=v_sz+12
					If v_flags & 2 Then v_sz=v_sz+16
					
					outp+="data "+v_flags+" "+v_tc_sets+" "+v_tc_size+"~n"
					
					new_tag=file.ReadTag()
	
					While TModelB3D.NewTag(new_tag)<>True And file.Eof()<>True
				
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
						
						
						'read tex coords...
						For Local j=0 To v_tc_sets-1 ' texture coords per vertex - 1 for simple uv, 8 max
							For Local k=1 To v_tc_size ' components per set - 2 for simple uv, 4 max
								If k=1 v_u=file.ReadFloat()
								If k=2 v_v=file.ReadFloat()
								If k=3 v_w=file.ReadFloat()
							Next
						Next
						
						outp+="xyz:"+v_x+" "+v_y+" "+v_z+"  "+" nxyz:"+v_nx+" "+v_ny+" "+v_nz+" rgba:"+v_r+" "+v_g+" "+v_b+" "+v_a+" uvw:"+v_u+" "+v_v+" "+v_w+"~n"
						
						
						new_tag=file.ReadTag()
														
					Wend
					
					outp+= "no_verts:"+no_verts+"~n"

				Case TRIS
					
					Local e:Bool = False
					Local old_tr_brush_id=tr_brush_id
					tr_brush_id=file.ReadInt()
					e=file.Eof()
			
	
					tr_sz=12
						
					new_tag=file.ReadTag()
					
					
					''check for EOF in case of corrupt file
					'While NewTag(new_tag)<>True And file.Eof()<>True

					For Local j:Int=1 To (size-4) Step 12 ''4=brush numer (int)
					
						tr_vid0=file.ReadInt()
						e=file.Eof()
						tr_vid1=file.ReadInt()
						e=file.Eof()
						tr_vid2=file.ReadInt()
						
						If e Then Exit
						
						outp+="v0v1v2:"+tr_vid0+" "+tr_vid1+" "+tr_vid2+"~n"

						new_tag=file.ReadTag()
						
						totaltris+=1
					Next
					'Wend
					

					If new_tag<>TRIS

						
						outp+="- no_tris:"+totaltris+"~n"
					Endif
					
					
				Case ANIM
					
					outp+="ANIM~n"
					
					a_flags=file.ReadInt()
					a_frames=file.ReadInt()
					a_fps=file.ReadFloat()
					
					outp+="data "+a_flags+" "+a_frames+" "+a_fps
	
				Case BONE
					
					outp+="BONE~n"
					
					Local ix:Int=0
					
					new_tag=file.ReadTag()
				
					bo_bone = New TBone
					bo_no_bones=bo_no_bones+1
					
					While TModelB3D.NewTag(new_tag)<>True And file.Eof()<>True
				
						bo_vert_id=file.ReadInt()
						bo_vert_w=file.ReadFloat()
						
						outp+="id:"+bo_vert_id+" weight:"+bo_vert_w+"~n"
						
						new_tag=file.ReadTag()
							
					Wend
					

					
		
				Case KEYS
					outp+="KEYS~n"
				
					k_flags=file.ReadInt()
				
					new_tag=file.ReadTag()
	
					While TModelB3D.NewTag(new_tag)<>True And file.Eof()<>True
				
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
	
						outp+="frame:"+k_frame+" xyz:"+k_px+" "+k_py+" "+k_pz+" scxyz:"+k_sx+" "+k_sy+" "+k_sz+" qxyzw:"+k_qx+" "+k_qy+" "+k_qz+" "+k_qw+"~n"
						
						new_tag=file.ReadTag()
							
					Wend
					

					
				Default
				
					file.ReadByte()
	
			End Select
		
		Until file.Eof()

	
		os.SaveString(outp, outf)
	
End


