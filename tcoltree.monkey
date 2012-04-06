Import minib3d

''
''
'' need to rewrite mesh collider
''
'' NOTES:
'' - changed TreeCheck to CreateMeshTree() to reflect what its actually doing
''
'' - need to move createtreemesh() routine to somewhere we can init it in OnCreate() rather than during click time

Class TColTree
	
	Const ONETHIRD:Float = 1.0/3.0
	
	Field reset_col_tree=False
	Field c_col_tree:MeshCollider ''variable name or class name is misleading
	
	Method New()
	
	
	End Method
	
	Method Delete()
	
	
	End Method

	' creates a collision tree for a mesh if necessary
	Method CreateMeshTree:MeshCollider(mesh:TMesh)
	

		' if reset_col_tree flag is true clear tree
		If reset_col_tree=True

			If c_col_tree<>Null
				c_col_tree=Null
			Endif
			reset_col_tree=False
				
		Endif

		If c_col_tree=Null
			Local total_verts_count:Int=0
			Local vindex:Int=0
			Local triindex:Int =0
			
			''get total tris and verts so we don't need to resize
			Local total_tris:Int=0, total_verts:Int=0
			
			For Local surf:TSurface =Eachin mesh.surf_list
				total_tris +=surf.no_tris
				total_verts +=surf.no_verts
				
			Next
			
	
			c_col_tree =  New MeshCollider(total_verts, total_tris) ''mesh_coll
			
			''combine all surfaces and vertex into one array
			Local s:Int=0
			For Local surf:TSurface = Eachin mesh.surf_list
				
				s+=1
				
				Local no_tris:Int =surf.no_tris
				Local no_verts:Int =surf.no_verts
										
				If no_tris<>0
					
					'do vert coords first
					For Local i:=0 To no_verts-1
						
						c_col_tree.tri_verts[i+total_verts_count].x = surf.vert_coords.Peek(i*3+0)
						c_col_tree.tri_verts[i+total_verts_count].y = surf.vert_coords.Peek(i*3+1)
						c_col_tree.tri_verts[i+total_verts_count].z = -surf.vert_coords.Peek(i*3+2) ' negate z vert coords
						
					Next
				
					' inc vert index
					' per tri
					For Local i:=0 To no_tris-1

						Local v0:Int = surf.tris.Peek(i*3+0) + total_verts_count
						Local v1:Int = surf.tris.Peek(i*3+1) + total_verts_count
						Local v2:Int = surf.tris.Peek(i*3+2) + total_verts_count
						
						' reverse vert order
						Local ti:Int = triindex*3
						c_col_tree.tri_vix[ti+0]= v2
						c_col_tree.tri_vix[ti+1]= v1
						c_col_tree.tri_vix[ti+2]= v0				
					
						''Add to MeshCollider
						c_col_tree.tri_surface[triindex] = s
						c_col_tree.tri_centres[triindex].x = c_col_tree.tri_verts[v0].x+c_col_tree.tri_verts[v1].x+c_col_tree.tri_verts[v2].x
						c_col_tree.tri_centres[triindex].y = c_col_tree.tri_verts[v0].y+c_col_tree.tri_verts[v1].y+c_col_tree.tri_verts[v2].y
						c_col_tree.tri_centres[triindex].z = c_col_tree.tri_verts[v0].z+c_col_tree.tri_verts[v1].z+c_col_tree.tri_verts[v2].z
						c_col_tree.tri_centres[triindex].x = c_col_tree.tri_centres[triindex].x*ONETHIRD
						c_col_tree.tri_centres[triindex].y = c_col_tree.tri_centres[triindex].y*ONETHIRD
						c_col_tree.tri_centres[triindex].z = c_col_tree.tri_centres[triindex].z*ONETHIRD
						
						c_col_tree.tris[triindex]=i
						
						vindex += 3
						triindex += 1
						
					Next
	
										
					total_verts_count += no_verts
				
				Endif
	
			Next	
			
			''add to nodes
			c_col_tree.tree = c_col_tree.CreateNode( c_col_tree.tris )


		Endif
		
		Return c_col_tree
				
	End 	

	
End


Class AxisPair
	Field value:Int
	Field key:Float
End


Class PairList<AxisPair> Extends List<AxisPair>
	Method Compare(lh:AxisPair, rh:AxisPair)
		If lh.key < rh.key Then Return -1
		Return lh.key > rh.key
	End
End


Class Node

	Field box:Box
	Field triangles:Int[]
	Field left:Node
	Field right:Node
	
End


Class MeshCollider
	
	Public
	
	Const MAX_COLL_TRIS:Int =16
	
	''main mesh info
	Field tri_count:Int
	Field vert_count:Int
	Field tris:Int[] ''tri index  '' one to one
	Field tri_surface:Int[]
	Field tri_vix:Int[] ''vertex index, tris*3
	Field tri_verts:Vector[] ''vert = tri_verts[tri_index[tris]+0]
	Field tri_centres:Vector[]
	
	''mesh info per node
	Field tree:Node ''was global
	Field leaf_list:List<Node> = New List<Node> ''was global
	
	''to allow the ray to inverse entity scale
	Field gsx#, gsy#, gsz#
	
	Global t_tform:TransformMat ''for testing
	
	Private

	
	Public
	
	''creates list of triangle, vertices, and triangle centers, and creates tree node	
	Method New(no_verts:Int, no_tris:Int)
	
		tri_count = no_tris
		vert_count = no_verts
		tris = New Int[no_tris]
		tri_surface = New Int[no_tris]
		tri_vix = New Int[no_tris*3]
		tri_verts = New Vector[no_verts]
		tri_centres = New Vector[no_tris]
		
		For Local i:=0 To no_verts-1
			tri_verts[i] = New Vector
		Next
		
		For Local i:=0 To no_tris-1
			tri_centres[i] = New Vector
		Next

	End




	Method CreateNodeBox:Box( tris:Int[] )
		Local ti:Int = tris[0]*3
		
		Local box:Box = New Box( tri_verts[tri_vix[ti+0]], tri_verts[tri_vix[ti+1]], tri_verts[tri_vix[ti+2]] )
		
		For Local k:Int = 1 To tris.Length()-1
			ti = tris[k]*3
			box.Update( tri_verts[ tri_vix[ti+0] ])
			box.Update( tri_verts[ tri_vix[ti+1] ])
			box.Update( tri_verts[ tri_vix[ti+2] ])
		Next
		
		Return box
	End
	
	Method CreateLeaf:Node( tris:Int[] )
		
		Local c:Node = New Node()
		c.box = CreateNodeBox( tris )
		c.triangles = tris
		leaf_list.AddLast( c )
	
		Return c
		
	End

	''recursive
	'' tris = the first vindex for the tri (NOT the tri index)
	Method CreateNode:Node( tris:Int[] )
		
		If( tris.Length() <=MAX_COLL_TRIS ) Return CreateLeaf( tris )
		
		
		Local c:Node = New Node
		c.box = CreateNodeBox( tris )
		
		''find longest axis
		Local max:Float = c.box.Width()
		Local axis:Int = 0
		If( c.box.Height() >max ) Then max=c.box.Height(); axis = 1
		If( c.box.Depth() >max ) Then max=c.box.Depth(); axis = 2

	
		''sort by axis
		'' list organize from lowest key to highest key, same as c++ multimap
		'' can't use monkey map, as it will overwrite redundancies
		Local k:Int, tri:Int
		
		Local axis_map:PairList<AxisPair> = New PairList<AxisPair>
		Local num:Int = tris.Length()
		
		For k = 0 To num-1
		
			Local ap:AxisPair = New AxisPair
			
			tri = tris[k]
			If axis = 0
				ap.key= tri_centres[tri ].x; ap.value= tris[k]
			Elseif axis = 1
				ap.key= tri_centres[tri ].y; ap.value= tris[k]
			Else
				ap.key= tri_centres[tri ].z; ap.value= tris[k]
			Endif
			axis_map.AddLast( ap )

		Next
	
		axis_map.Sort() ''by float, low to high using key
		
		''left node
		Local index:Int=0
		Local newtris:Int[(num*0.5)+0.5] ''half and round up
		
		For Local ap:AxisPair = Eachin axis_map
			
			newtris[index] = ap.value
			index +=1
			If index>= Int(num*0.5) Then Exit
		Next
		
		c.left = CreateNode( newtris )
		
		''right node
		index=0
		Local newtris2:Int[(num*0.5)+1.0]
		
		For Local ap:AxisPair = Eachin axis_map.Backwards()
			
			newtris2[index] = ap.value
			index +=1
			If index>= Int(num*0.5+1.0 ) Then Exit
		Next
		
		c.right = CreateNode( newtris2 )
		
		Return c
	End



	Function TrisIntersect:Bool( a:Vector[], b:Vector[] )
		Local r1:Bool=False, r2:Bool=False
		Local p:Plane, p0:Plane,p1:Plane,p2:Plane
		Local  pb0:Bool=False, pb1:Bool=False, pb2:Bool=False
		
		p= New Plane( a[0],a[1],a[2] )
 
		For Local k:Int = 0 To 2 
			Local l:Line = New Line( b[k],b[(k+1)Mod 3]-b[k] )
			Local t:Float=p.T_Intersect( l )
			If( t<0 Or t>1 ) Continue
			Local i:Vector = l.Multiply(t)
			If( Not pb0 ) Then p0=New Plane( a[0]+p.n,a[1],a[0] );pb0=True 
			If( p0.Distance( i )<0 ) Continue
			If( Not pb1 ) Then  p1=New Plane( a[1]+p.n,a[2],a[1] );pb1=True 
			If( p1.Distance( i )<0 ) Continue
			If( Not pb2 ) Then  p2=New Plane( a[2]+p.n,a[0],a[2] );pb2=True
			If( p2.Distance( i )<0 ) Continue
			r1 = True
			Exit
		Next

		
		''swap a,b
		pb0=False; pb1=False; pb2=False
		p = New Plane( b[0],b[1],b[2] )
		p0=Null;p1=Null;p2=Null
		For Local k:Int = 0 To 2 
			Local l:Line = New Line( a[k],a[(k+1)Mod 3]-a[k] )
			Local t:Float=p.T_Intersect( l )
			If( t<0 Or t>1 ) Continue
			Local i:Vector = l.Multiply(t)
			If( Not pb0 ) Then  p0=New Plane( b[0]+p.n,b[1],b[0] );pb0=True
			If( p0.Distance( i )<0 ) Continue
			If( Not pb1 ) Then  p1=New Plane( b[1]+p.n,b[2],b[1] );pb1=True
			If( p1.Distance( i )<0 ) Continue
			If( Not pb2 ) Then  p2=New Plane( b[2]+p.n,b[0],b[2] );pb2=True
			If( p2.Distance( i )<0 ) Continue
			r2=True 
			Exit
		Next

		
		Return r1 | r2
	End



	''COLLIDE
	'' -- takes a bounding box and orients it to find the new bounding box
	''
	Method Collide:Int( li:Line, radius:Float, tf:TransformMat, coll:CollisionObject)
		
		If Not tree
			Print "TColTree: no tree"
			Return False
		Endif
		
		'' create local box
		Local local_box:Box = New Box(li) 'New Box( li.o, li.d ) 'New Box(li)
		local_box.Expand(radius)

		Local t:TransformMat = tf.Copy()
		't.m.Transpose() ''the orig c++ code uses different type of matrix
		'local_box = t.Transpose().Multiply(local_box) 'transpose = fastinverse
		'Box local_box=-t * box; ''was a full Inverse(), but opted on Transpose() since only using 3x3	<-- WRONG needs full inverse
		
		t.m.Transpose() ''the orig c++ code uses different type of matrix
		t.m.Scale( 0.5/gsx, 0.5/gsy, 0.5/gsz )
		t = t.Transpose()
		local_box = t.Multiply(local_box)

		Local line2:Line = New Line(li.o, li.d)
		line2 = t.Multiply(line2)
	
		Return Collide(local_box, line2, radius, t, coll, tree)
		
	End



	Method Collide:Int( line_box:Box, line:Line, radius:Float, tform:TransformMat, curr_coll:CollisionObject, node:Node)
	
		If (Not line_box.Overlaps(node.box)) Then Return 0

		Local hit:Int = 0

		If (node.triangles.Length() <1)
			
			If( node.left ) Then hit = hit | Collide( line_box,line,radius,tform,curr_coll,node.left )
			If( node.right ) Then hit = hit | Collide( line_box,line,radius,tform,curr_coll,node.right )
			
			Return hit
			
		Endif

	
		For Local k:Int = 0 To node.triangles.Length()-1
		
			Local tri:Int = node.triangles[k]*3

			Local v0:Vector = tri_verts[tri_vix[tri+0]]
			Local v1:Vector = tri_verts[tri_vix[tri+1]]
			Local v2:Vector = tri_verts[tri_vix[tri+2]]
		
			''tri box
			Local tri_box:Box = New Box(v0,v1,v2)
			
			If (Not tri_box.Overlaps(line_box)) Then Continue

			'tform.m.Transpose() ''the orig c++ code uses different type of matrix		
			'If( Not curr_coll.TriangleCollide( line,radius,tform.Multiply(v0),tform.Multiply(v1),tform.Multiply(v2) ) ) Then Continue

			If Not curr_coll.RayTriangle( line, v0,v1,v2 ) Then Continue
			
			curr_coll.surface=tri_surface[ node.triangles[k] ]
			curr_coll.index= node.triangles[k]
										
			hit = 1
			'Exit '' exit early for hit ok? or check all triangles
			
		Next
		
		Return hit
	
	End
	
	''Triangle-Triangle intersect
	Method Intersects:Bool( c:MeshCollider, t:Transform)

		Local a:Vector[][] = New Vector[MAX_COLL_TRIS][3]
		Local b:Vector[] = New Vector[3]
		
		If ( Not(t.Multiply(tree.box).Overlaps(c.tree.box) ) ) Then Return False
		
		For Local p:Node = Eachin leaf_list
			Local box:Box = t.Multiply(p.Box)
			Local tformed:Bool = False
			
			For Local q:Node = Eachin c.leaf_list
			
				If( Not box.Overlaps( q.box)) Then Continue
				If( Not tformed)
					For Local n:Int = 0 To p.triangles.Length()-1
						Local tri:Int = p.triangles[n]*3
						a[n][0] = t.Multiply( tri_verts[tri_vix[tri+0]] )
						a[n][1] = t.Multiply( tri_verts[tri_vix[tri+0]] )
						a[n][2] = t.Multiply( tri_verts[tri_vix[tri+0]] )
					Next
					tformed = True
				Endif
				
				For Local n:Int = 0 To q.triangles.Length()-1
					Local tri:Int = c.triangles[q.triangles[n]] *3
					
					b[0] = c.tri_verts[tri_vix[tri+0]]
					b[1] = c.tri_verts[tri_vix[tri+1]]
					b[2] = c.tri_verts[tri_vix[tri+2]]
					For Local t:Int = 0 To p.triangles.Length()-1
						If TrisIntersect(a[t],b) Then Return True
					Next
				Next
				
			Next
		Next
		
	End


	
	
	
End				





