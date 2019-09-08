Import minib3d
Import minib3d.monkeyutility
Import minib3d.monkeybuffer

Alias LoadString = app.LoadString


''Notes:
'' -- needs the original mesh to store reference pose in frame 0
'' -- MDD is big endien, PC2 is little endien







Class TModelMDD

#If MINIB3D_DEBUG_MODEL=1
	Const DEBUG:Int =1
#else
	Const DEBUG:Int =0
#Endif
	
	'' vertex tolerance when assigning original vertices
	Global EPSI# = 0.0001
	Global EPSI2# = -EPSI
	
	Const MAXVERTS:Int = 1024 ''will auto-increment as needed
	

	
	Global flipb:DataBuffer 
	
	Global override_texflags:Int = -1
	
	
	Function SetEPSI:Void(e:Float)
		EPSI = e
		EPSI2 = -e
		VertexSet.EPSI = e
		VertexSet.EPSI2 = -e
	End
	
	Function LoadMDD:Void(mesh:TMesh, url:String, flipz:Int=0, variance:Float = EPSI)
		
		SetEPSI(variance)
		
		Local res:Int = ParseMDD(mesh, LoadString(url),flipz)
		
		If res=0
			Print "**TModelMDD:File not found "+url
		Else
			If DEBUG Then Print"TModelMDD: "+url
		Endif
		
	End
	
	
	Function LoadPC2:Void(mesh:TMesh, url:String, flipz:Int=0, variance:Float = EPSI)
		
		SetEPSI(variance)
		
		Local res:Int = ParseMDD(mesh, LoadString(url),flipz, True)
		
		If res=0
			Print "**TModelPC2:File not found "+url
		Else
			If DEBUG Then Print"TModelPC2: "+url
		Endif
		
	End
	
	
	
	Function ParseMDD:Int(mesh:TMesh, s:String, flipz:Int=0, PC2:Bool = False)
		
		Local stream:Base64 = Base64.LoadStr(s)
		Local pc_string:String, pc_version:Int, start_frame:Float, sample_rate:Float
		Local total_points:Int, total_frames:Int
		
		Local length% = stream.Size()
		
		If length <1 
			Return 0 
		Endif
		
		flipb = CreateDataBuffer(4)
		
		If Not PC2
			'' read data for MDD
			'' read totalframes
			
			
			total_frames = FlipInt( stream.ReadInt())
			total_points = FlipInt( stream.ReadInt())
	
			'Print ToHex(total_frames)
			'Print ToHex(total_points)
			
			If DEBUG Print "LoadMDD f:"+total_frames+" p:"+total_points
			
			''read times/frame
			Local times:Float[] = New Float[total_frames]
			For Local t:Int = 0 To total_frames-1
				times[t] = FlipFloat(stream.ReadInt())
			Next
			
		Else
			
			''read POINTCACHE2 + null
			'' probably dont need to flip endian
			pc_string = stream.ReadString(12)
			
			If pc_string<>"POINTCACHE2~0" Then Print "** TModelPC2: Not a PointCache2 file"; Return
			
			pc_version = stream.ReadInt()
			total_points = stream.ReadInt()
			start_frame = stream.ReadFloat()
			sample_rate = stream.ReadFloat()
			total_frames = stream.ReadInt()
			
			If DEBUG Print "LoadPC2 f:"+total_frames+" p:"+total_points+" vers:"+pc_version+" startf:"+start_frame
			
		Endif
		
		'Local mdd_vertex:Float[] = New Float[total_points*3]
		Local no_verts:Int=0
		Local surf:TSurface
		Local vert_set:VertexSet = New VertexSet
		vert_set.ref_set = New Float[total_points*3]
		
		'' read reference points in frame0

		For Local p:Int= 0 To total_points-1
			Local v0#, v1#, v2#
			
			If Not PC2
				v0= FlipFloat( stream.ReadInt())
				v1= FlipFloat( stream.ReadInt())
				v2= FlipFloat( stream.ReadInt())
			Else
				v0= ( stream.ReadFloat())
				v1= ( stream.ReadFloat())
				v2= ( stream.ReadFloat())
			Endif
			
			If flipz Then v2=-v2
			
			Local p3:Int = p*3
			vert_set.ref_set[p3+0] = v0
			vert_set.ref_set[p3+1] = v1
			vert_set.ref_set[p3+2] = v2
			
'Print v0+" "+v1+" "+v2

		Next



		''allocate anim_surfs		
		For surf = Eachin mesh.surf_list
			no_verts += surf.no_verts
			
			mesh.anim_surf[surf.surf_id] = surf.Copy()
			Local anim_surf:TSurface = mesh.anim_surf[surf.surf_id]	
			
			
			'' create vertex buffer
			'anim_surf.vert_data=CopyDataBuffer(surf.vert_data, VertexDataBuffer.Create(surf.no_verts)) ''dont need to copy
			'anim_surf.vert_data=VertexDataBuffer.Create(surf.no_verts)
			
			'' create anim frames
			anim_surf.vert_anim = New TVertexAnim[total_frames]
			For Local frame:Int = 0 To total_frames-1
			
				'anim_surf.vert_anim[frame] = New TVertexAnim
				anim_surf.vert_anim[frame] = TVertexAnim.Create(anim_surf.no_verts*3)
				
			Next
			
			'' set points and ANIM_SURFACE relationship
			For Local v:Int=0 To surf.no_verts-1
			
				vert_set.Add(surf, anim_surf,v)
				
				''set frame0 while we're here
				anim_surf.vert_anim[0].PokeVertCoords(v, surf.VertexX(v), surf.VertexY(v), -surf.VertexZ(v) )
				
			Next
	
		Next

		

		''read in anim data
		For Local frame:Int = 1 To total_frames-1
			For Local p:Int= 0 To total_points-1
				Local v0#, v1#, v2#
				
				If Not PC2 Then
					v0= FlipFloat( stream.ReadInt())
					v1= FlipFloat( stream.ReadInt())
					v2= FlipFloat( stream.ReadInt())
				Else
					v0= ( stream.ReadFloat())
					v1= ( stream.ReadFloat())
					v2= ( stream.ReadFloat())
				Endif
				
				If flipz Then v2=-v2
				
				'' change surface verts
				vert_set.UpdateAnim(p, frame, v0,v1,-v2)
	
			Next
		Next

	

		''setup animation seq

		mesh.ActivateVertexAnim()
		mesh.anim_seqs_first[0]=0
		mesh.anim_seqs_last[0]=total_frames-1

		Return 1
	End
	
	
	Function ScaleMDD:Void(mesh:TMesh, scx:Float, scy:Float, scz:Float)
		
		
		
	End
	
	

	
	
	
	
	Function FlipFloat:Float(b:Int)
		''big endian 32bit
		flipb.PokeInt(0,FlipInt(b))
		Return flipb.PeekFloat(0)
		
	End
	
	Function FlipInt:Int(b:Int)
		''big endian 32bit
		''be careful with Shr and negative numbers
		Return ( ((b & $000000ff) Shl 24)| ((b & $0000ff00)Shl 8) | ((b & $00ff0000)Shr 8) | ((b Shr 24 )& $000000ff) )
		
	End
	
End



'' -- a helper class to associate serialized vertex order with the number of surfaces they are attached to
Class VertexSet
	
	'' vertex tolerance when assigning original vertices
	Global EPSI# = 0.0001
	Global EPSI2# = -EPSI
	
	Field ref_set:Float[]
	
	Field vert_set:VertexSurface[]
	
	'' -- search and add surface on match, or create new if unique
	'' -- i could add a tolerance offset for "closely" matching vertexes
	
	Method Add:Void(surf1:TSurface, surf2:TSurface, surfid:Int, x#=0.0, y#=0.0, z#=0.0)
		
		
		
		Local total:Int = (ref_set.Length)/3
		
		If vert_set.Length < total
			''resize
			vert_set = vert_set.Resize(total)
		Endif
		
		Local v0# = surf1.VertexX(surfid)
		Local v1# = surf1.VertexY(surfid)
		Local v2# = surf1.VertexZ(surfid)
		
		Local found:Int=0, fr:Int
		
		For Local r:Int =0 To total-1
		
			Local r3:Int=r*3
			
			'' fast rejection for n>1.0
			'' make sure to round up or int(1.0) != int(0.9999)
			If Int(ref_set[r3]+0.5)=Int(v0+0.5) And Int(ref_set[r3+1]+0.5)=Int(v1+0.5) And Int(ref_set[r3+2]+0.5)=Int(v2+0.5)
				fr = r3
				Local d0# = (ref_set[r3] - v0)
				If (d0< EPSI And d0 >EPSI2)
				'If ref_set[r3]=v0
					d0 = (ref_set[r3+1] - v1)
					If (d0< EPSI And d0 >EPSI2)
						'If ref_set[r3+1]=v1
						d0 = (ref_set[r3+2] - v2)
						If (d0< EPSI And d0 >EPSI2)
						'If ref_set[r3+2]=v2
						
							''found, add to list
							If Not vert_set[r] Then vert_set[r] = New VertexSurface
					
							vert_set[r].AddSurface(surf2,surfid)
							
							found=1
							
						Endif
					Endif
				Endif
				
			Endif
		Next
		
'If Not found Then Print "** "+surf1.surf_id+" "+surfid+" "; Print v0+" "+v1+" "+v2

	End
	
	'' update all surfaces associated with i
	Method UpdateAnim:Void(i:Int, frame:Int, x#, y#, z#)
	
		If vert_set[i]
			For Local v:VSSurface = Eachin (vert_set[i].list)
			
				v.surf.vert_anim[frame].PokeVertCoords(v.id,x, y, z)
				
			Next
		Endif
	End
	
	
	Method PrintSet()
		For Local r:Int =0 To (ref_set.Length)/3-1
			Local r3:Int=r*3
			If Not vert_set[r] Then Continue
			
			For Local v:VSSurface = Eachin (vert_set[r].list)
				Print ref_set[r3+0]+", "+ref_set[r3+1]+", "+ref_set[r3+2]+"      "+v.id
			Next
		Next
	End

End

Class VertexSurface
	
	Field num:Int =0 ''how many surfaces
	Field list:List<VSSurface> = New List<VSSurface> ''the surface & surfid
	'Field x:Float, y:Float, z:Float ''the vector to compare
	
	Method AddSurface:Void(surf2:TSurface, id2:Int)
	
		num+=1
		Local vs:VSSurface = New VSSurface
		vs.surf = surf2
		vs.id = id2
		list.AddLast(vs)
	End
	
End

Class VSSurface

	Field surf:TSurface
	Field id:Int '' the vertex id in that surface
	
End



