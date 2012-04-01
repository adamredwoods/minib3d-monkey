Import minib3d

'' - obj does not need to be triangles, can handle polys
'' large polys (>4) may be triangulated poorly though...
'' - combines reused surfaces
Class TModelObj

	Const DEBUG:Int = 1
	
	Const MAXVERTS:Int = 2000
	
	Field pos:Int=0
	Field data:String
	Field length:Int
	Field stack:StringStack = New StringStack	
	
	Method ReadLine:String()
		Local s:String=""
		
		stack.Clear()
		
		While Not (data[pos] = 10 Or data[pos] = 13) ''~n ~r
		
			If pos < data.Length()
				
				If data[pos]>0
					stack.Push(String.FromChar(data[pos]))
				Endif
				
				pos += 1
				
			Else
				Exit
			Endif
		Wend
		
		pos += 1 ''get past the newline
		''check for cr+lf
		If (data[pos] = 10 Or data[pos] = 13) Then pos +=1
		
		Return stack.Join("")
	End
	
	Function LoadMesh:TMesh(url:String)
	
		Local stream:TModelObj = New TModelObj
		
		stream.data = LoadString(url)
		stream.length = stream.data.Length()
		
		Local StreamLine:Int=0
		If stream.length =0 
			Print "**TModelObj: Error file not found "+url
			Return Null 
		Endif
		
		If DEBUG Then Print"" ; Print"TModelObj: ** "+url
		
		Local matlibs:StringMap<TObjMtl> = New StringMap<TObjMtl>
		Local vertexP:TObjVertex[MAXVERTS]
		Local vertexN:TObjNormal[MAXVERTS]
		Local vertexT:TObjTexCoord[MAXVERTS]
		Local faces:TFaceData[MAXVERTS]
		
		Local gname:String = ""
		Local snumber:Int = -1
		Local curmtl:String = ""
		Local Readface:Bool = True
		Local vertsAdded:Bool = False
	
		Local VC:Int = 0
		Local VN:Int = 0
		Local VT:Int = 0
		Local FC:Int = 0
		Local TRI:Int = 0
		Local SC:Int = 0
		
		
		Local mesh:TMesh = TMesh.CreateMesh() 
		Local surface:TSurface 
		Local surfaceCache:Int[] = New Int[255]
		Local mtlCache:String[] = New String[255]
		Local currMtl:TObjMtl
		
		mesh.name = url
		
		While stream.pos < stream.length 
		
			Local Line:String = stream.ReadLine().Trim()
			
			If Line.Length() <0 Then Continue
				
			If Line[0] = "#" Then
			
				If DEBUG Then DebugLog(".Obj Comment : " + Line) 
				
			Else
				
				Local tag:String = Line[0..9].ToLower()
	
				If tag[0..2]= "v " Then
					If VC>vertexP.Length() Then vertexP = vertexP.Resize(vertexP.Length()+MAXVERTS)
					
					vertexP[VC+1] = New TObjVertex
					vertexP[VC+1].GetValues(Line[2..]) 
					VC+=1
				Endif
				
				If tag[0..3] = "vn " Then
					If VN>vertexN.Length() Then vertexN = vertexN.Resize(vertexN.Length()+MAXVERTS)
				
					vertexN[VN+1] = New TObjNormal
					vertexN[VN+1].GetValues(Line[3..]) 
					VN+=1
				Endif
				
				If tag[0..3] = "vt " Then
					If VT>vertexT.Length() Then vertexT = vertexT.Resize(vertexT.Length()+MAXVERTS)
				
					vertexT[VT+1] = New TObjTexCoord
					vertexT[VT+1].GetValues(Line[3..]) 
					VT+=1
				Endif	
				
				If tag[0..2] = "g " Then
					gname = Line[2..].ToLower()

					''g = groups, not supportted currently
				Endif 
				
				If tag[0..2] = "s " Then
					snumber = Int(Line[2..])
					''s = smoothing groups, not supprted
				Endif
				
				If tag[0..7] = "mtllib " Then
				
					If DEBUG Then Print "mtllib"
					
					Local lib:TObjMtl[] = ParseMTLLib(Line[7..]) 
					
					For Local obj:TObjMtl = Eachin lib
						If obj Then matlibs.Set(obj.name , obj) 
					Next
					
				Endif
				
				If tag[0..7] = "usemtl " Then
				
					currMtl = matlibs.Get( Line[7..].Trim() )

					If DEBUG Then Print "--"+Line[7..]
					
					Local mmtrue:Int=0
					Local surfnum:Int=0
					
					If currMtl <> Null
						
						'reuse existing surfaces						
						If currMtl.meshSurface 
							If DEBUG Then  DebugLog "--mtlmatch "+currMtl.name

						Else
							If DEBUG Then  DebugLog "--mtlnew "

							currMtl.meshSurface = mesh.CreateSurface()
							
							currMtl.meshSurface.PaintSurface(currMtl.brush) 
							If DEBUG Then  Print "--use brush " + currMtl.name
							
							SC+=1
						Endif
						
						surface = currMtl.meshSurface
						
						
						If currMtl.realvertindex.Length() < VC+1
							'' increase vertex index cache
							currMtl.realvertindex = currMtl.realvertindex.Resize(VC+1)
						Endif
						
					Endif
				Endif
				
				If tag[0..2] = "f " Then

					If surface = Null
						''no mtl, assume only one surface, no material lib
						surface = mesh.CreateSurface()
						If Not currMtl Then currMtl = New TObjMtl
						currMtl.meshSurface = surface
					Endif
					
					If surface
						
						''add verts
						'' avoiding index 0 as this is reserved for null						
						
						Local V:TFaceData[] = ParseFaces(Line[2..])
							
							''assume at least 3 verts for a triangle, start at 2(base0)	
							'' also do not use unused verticies
							'' also each surface starts at vert id =0									
							For Local i2:Int = 2 To V.Length() - 1
								
								Local v0:Int = V[0].vi
								Local v1:Int = V[i2-1].vi
								Local v2:Int = V[i2].vi
							
								''can't use 0, so offset
								If Not currMtl.realvertindex[v0]
									currMtl.realvertindex[v0] = 1+ surface.AddVertex( vertexP[v0].x , vertexP[v0].y ,-vertexP[v0].z)
								Endif
								If Not currMtl.realvertindex[v1]
									currMtl.realvertindex[v1] = 1+ surface.AddVertex( vertexP[v1].x , vertexP[v1].y ,-vertexP[v1].z)
								Endif
								If Not currMtl.realvertindex[v2]
									currMtl.realvertindex[v2] = 1+ surface.AddVertex( vertexP[v2].x , vertexP[v2].y ,-vertexP[v2].z)
								Endif
						
								''offset
								v0 = currMtl.realvertindex[v0]-1
								v1 = currMtl.realvertindex[v1]-1
								v2 = currMtl.realvertindex[v2]-1
	

								If vertexN[1] <> Null And V[0].ni <> 0
									surface.VertexNormal  v0 , vertexN[V[0].ni].nx , vertexN[V[0].ni].ny , vertexN[V[0].ni].nz
									surface.VertexNormal  v1 , vertexN[V[i2-1].ni].nx , vertexN[V[i2-1].ni].ny , vertexN[V[i2-1].ni].nz
									surface.VertexNormal  v2 , vertexN[V[i2].ni].nx , vertexN[V[i2].ni].ny , vertexN[V[i2].ni].nz
								Endif
								
								If vertexT[1] <> Null And V[0].ti <> 0
									surface.VertexTexCoords  v0 , vertexT[V[0].ti].u ,1- vertexT[V[0].ti].v
									surface.VertexTexCoords  v1 , vertexT[V[i2-1].ti].u ,1- vertexT[V[i2-1].ti].v
									surface.VertexTexCoords  v2 , vertexT[V[i2].ti].u , 1 - vertexT[V[i2].ti].v
		 						Endif
									
								surface.AddTriangle  v0, v2, v1  
								
								TRI+=1
								
							Next
							
						FC+=1
						
					Endif
				Endif	
						
			Endif

		Wend
		
		If DEBUG
			DebugLog "VertexCount : " + VC
			DebugLog "NormalsCount : " + VN
			DebugLog "TexCoordsCount : " + VT
			DebugLog "Faces : " + FC + " Tris : "+TRI
			DebugLog "Surfs : " + SC
			DebugLog "Surfs real : " + CountSurfaces(mesh) 
			
			For Local V:TObjMtl = Eachin matlibs.Values()
				DebugLog "Mtl names:"+ V.name
			Next
			
			For Local sf:TSurface = Eachin mesh.surf_list
				Print "real no_verts "+sf.no_verts+" :: no_tris "+sf.no_tris
			Next
			DebugLog "--------------------------"
		Endif
	
		

		'FlipMesh Mesh
		
		stream.data = ""
		
		''clean up buffers
		For Local surfx:TSurface = Eachin mesh.surf_list
			surfx.CropSurfaceBuffers()
			'If mesh.anim_surf[surfx.surf_id] Then mesh.anim_surf[surfx.surf_id].CropSurfaceBuffers()
		Next
		
		mesh.UpdateNormals()
		
		Return mesh
		
	End 
	
	
	Function ParseFaces:TFaceData[](data:String) 
		
		Local data1:String[] = data.Split(" ")
		
		Local s:Int = 0
		Local fdata:TFaceData[data1.Length() ]
		
		For Local i:Int = 0 To data1.Length() - 1 's to data1
			
			If data1[i]="" Then Continue
			
			fdata[s] = New TFaceData
			Local D2:String[] = CustomSplit( data1[i], "/" ) 
			'If DEBUG Then DebugLog " "+D2[0] +"/ "+D2[1]+"/ "+D2[2]
			
			fdata[s].vi = Int(D2[0])
			fdata[s].ti = Int(D2[1])
			fdata[s].ni = Int(D2[2])
	
			If fdata[s].vi <0 Then  fdata[s].vi=0
			If fdata[s].ti <0 Then  fdata[s].ti=0
			If fdata[s].ni <0 Then  fdata[s].ni=0
			
			s+=1
			
		Next
		
		fdata = fdata.Resize(s)
		
		Return fdata
		
	End 
	
	Function CustomSplit:String[](st:String, delim:String)
	
		''handles n/n/n as 3 numbers even when n//n
		Local out:String[] = New String[3]
		
		If st.Length() < 1 Then Return [""]
		
		Local n:Int=0, nn:Int=0
		Local reset:Int=1
		Local s:String
		
		For Local i:Int = 0 To st.Length() -1
			If reset
				out[n] = "0"
				reset = 0
			Endif
			If st[i] = delim[0]
				Local ii:Int = i+nn
				s = st[i..ii]
				'out[n] = s
				
				n+=1
				reset=1
				nn=0
				
			Else
				out[n] += String.FromChar(st[i])
				nn+=1
			Endif
		Next
		'Print nn
		Return out
		
	End


	Function ParseMTLLib:TObjMtl[](url:String)
		
		Local MatLib:TObjMtl[0]
		Local stream:TModelObj = New TModelObj
		
		stream.data = LoadString(url) 

		If Not stream.data 
			stream.data = LoadString(url+".txt")
			If Not stream.data 
				Print "**TModelObj: Material obj file not found"
				Return MatLib
			Endif
		Endif
		
		stream.length = stream.data.Length()
		
		Local CMI:Int = -1
		Local is_brush:Int =0
		
		While stream.pos < stream.length
		
			Local Line:String = stream.ReadLine() 
			Local tag:String = Line[0..9].ToLower
			
			'create new brush
			If tag[0..7] = "newmtl " Then
				MatLib = MatLib.Resize(MatLib.Length() + 1)
				CMI = MatLib.Length()-1
				
				MatLib[CMI] = New TObjMtl
				MatLib[CMI].name = Line[7..].Trim() 
				MatLib[CMI].brush = CreateBrush() 
				MatLib[CMI].brush.BrushFX 0 ''default, used to be 4+16
				MatLib[CMI].brush.name = MatLib[CMI].name
				is_brush = 1
				
				If DEBUG Then DebugLog("Matname : " + MatLib[CMI].name)
			Endif
			
			'Colours
			If tag[0..3] = "kd " And is_brush
				Local data:String = Line[3..].Trim()+" "
				Local f:Float[3]
				
				For Local i:Int = 0 To 2
					'Print "Before : " + Data
					Local fl:Int = data.Find(" ")
					If i < 2 Then
						f[i] = Float(data[..fl])
					Else
						f[i] = Float(data) 
					Endif
					data = data[fl+1..]
					'Print "After : " + data
				Next
				
				MatLib[CMI].brush.BrushColorFloat( f[0] , f[1], f[2]) 
				
				If DEBUG Then  DebugLog("MatColor : " +  (f[0] * 255) +","+(f[1] * 255)+","+(f[2] * 255))
			Endif
			
			If tag[0..2] = "d " And is_brush
				MatLib[CMI].brush.BrushAlpha( Float(Line[2..]) )
				If DEBUG Then  DebugLog("MatAlpha : " + Float(Line[2..]) ) 
			Endif
			
			If tag[0..3] = "tr " And is_brush
				MatLib[CMI].brush.BrushAlpha( Float(Line[2..])) 
				If DEBUG Then  DebugLog("MatAlpha : " + Float(Line[2..]) ) 
			Endif 
			
			If tag[0..7] = "map_kd " And is_brush
			
				MatLib[CMI].texture = LoadTexture(Line[7..].Trim() ) 
				If MatLib[CMI].texture.TextureHeight() > 1
				
					MatLib[CMI].brush.BrushTexture( MatLib[CMI].texture) 
					If DEBUG Then  DebugLog("MatTexture : " + Line[7..].Trim() ) 
					
				Else
					If DEBUG Then Print "**TModelObj: texture file not found"
				Endif
			Endif
			
		Wend
		
		Return MatLib
	End
	
End

	
Class TFaceData
	'Field T:Int[3]
	Field vi:Int
	Field ti:Int
	Field ni:Int
	Field its:Int
	
	#rem
	Method GetValues:String(data:String)
	
		'Print Data
		Local f:Int[3]
		For Local i:Int = 0 To 2
			'Print "Before : " + Data
			Local fl:Int = data.Find("/")
			If i < 2 Then
				T[i] = Int(data[..fl])-1
				data = data[fl+1..]
			Else
				T[i] = Int(data[..data.Find(" ")])-1
			Endif
			'Print "After : " + data
		Next
		'Print data		
		Return data[data.Find(" ")..]	
		
	End Method
	#end
	
End 


		
	
Class TObjNormal
	Field nx# , ny# , nz#
	
	Method GetValues(data:String) 
			
		Local f:Float[3]
		For Local i:Int = 0 To 2
			'Print "Before : " + Data
			Local fl:Int = data.Find(" ")
			If i < 2 Then
				f[i] = Float(data[..fl])
			Else
				f[i] = Float(data) 
			Endif
			data = data[fl+1..]
			'Print "After : " + Data
		Next
		nx = f[0]
		ny = f[1]
		nz = f[2]
		'DebugLog ("X:"+nx+" Y:"+ny + " Z:"+nz)
		
	End Method
End 

Class TObjTexCoord
	Field u# , v#
	
	Method GetValues(data:String)
	
		'DebugLog "OrigUV : " + data
		Local f:Float[2]
		For Local i:Int = 0 To 1
			'Print "Before : " + data
			Local fl:Int = data.Find(" ")
			If i < 1 Then
				f[i] = Float(data[..fl])
			Else
				f[i] = Float(data) 
			Endif
			data = data[fl+1..]
			'Print "After : " + data
		Next
		u = f[0]
		v = f[1]
		
		'DebugLog ("X:"+u+" Y:"+v)
	End Method	
	
End	

Class TObjVertex
	Field x# , y# , z#
	
	Method GetValues(data:String)
	 
			Local f:Float[3]
			For Local i:Int = 0 To 2
				'Print "Before : " + Data
				Local fl:Int = data.Find(" ")
				If i < 2 Then
					f[i] = Float(data[..fl])
				Else
					f[i] = Float(data) 
				Endif
				data = data[fl+1..]
				'Print "After : " + data
			Next
			x = f[0]
			y = f[1]
			z = f[2]
			'DebugLog ("X:"+x+" Y:"+y + " Z:"+z)
					
	End Method	
End 

Class TObjMtl

	Field name:String
	Field brush:TBrush
	Field texture:TTexture

	Field meshSurface:TSurface
	Field realvertindex:Int[1]
	
End
	
 

