' Procedural Interfaces

Import minib3d


#rem
bbdoc: Minib3d Only
about:
This command is included as MiniB3D currently does Not have the same buffer commands as Blitz3D.

Use this command To copy a region of the backbuffer To a texture.

The region copied from the backbuffer will start at (0,0), And End at the texture's width and height.

Therefore If you want To copy the whole of a 3D scene To a texture, you must first resize the camera viewport To the size of 
the texture, use RenderWorld To render the camera, Then use this command To copy the backbuffer To the texture.

Note that If a texture has the mipmap flag enabled (by Default it does), Then this command must be called For each mipmap,
otherwise the texture will appear To fade into a different, non-matching mipmap as you move away from it. A routine similar To
the one below will copy the backbuffer To each mipmap, making sure the camera viewport is the same size as the mipmap.

For i=0 Until tex.CountMipmaps()
	CameraViewport 0,0,tex.MipmapWidth(),tex.MipmapHeight()
	Renderworld
	BackBufferToTex(tex,i)
Next

It may be easier To disable the mipmap flag For the texture. To do so, use ClearTextureFilters after calling Graphics3D 
(the mipmap flag is a Default filter).

If you are using this command To copy To a cubemap texture, use SetCubeFace To first Select which portion of the texture you
will be copying To. Note that in MiniB3D mipmaps are Not used by cubemaps, so ignore the information about mipmaps For normal 
textures above.

See the cubemap.bmx example included with MiniB3D To learn more about cubemapping.
#End
Function BackBufferToTex(tex:TTexture,mipmap_no=0,frame=0)
	tex.BackBufferToTex(mipmap_no,frame)
End

#rem
bbdoc: Minib3d Only
about:
This command is the equivalent of Blitz3D's MeshCullBox command.

It is used To set the radius of a mesh's 'cull sphere' - if the 'cull sphere' is not inside the viewing area, the mesh will not 
be rendered.

A mesh's cull radius is set automatically, therefore in most cases you will not have to use this command.

One time you may have To use it is For animated meshes where the Default cull radius may Not take into account all animation 
positions, resulting in the mesh being wrongly culled at extreme positions.
#End
Function MeshCullRadius(ent:TEntity,radius#)
	ent.MeshCullRadius(radius)
End 

' Blitz3D functions, A-Z

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=AddMesh">Online Help</a>
#End
Function AddMesh:TMesh(mesh1:TMesh,mesh2:TMesh)
	mesh1.AddMesh(mesh2)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=AddTriangle">Online Help</a>
#End
Function AddTriangle:Int(surf:TSurface,v0,v1,v2)
	Return surf.AddTriangle(v0,v1,v2)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=AddVertex">Online Help</a>
#End 
Function AddVertex:Int(surf:TSurface,x#,y#,z#,u#=0.0,v#=0.0,w#=0.0)
	Return surf.AddVertex(x,y,z,u,v,w)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=AlignToVector">Online Help</a>
#End
Function AlignToVector(ent:TEntity, vx:Float,vy:Float,vz:Float,axis:Int,rate:Float=1.0)
	ent.AlignToVector(vx,vy,vz,axis,rate)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=AmbientLight">Online Help</a>
#End 
Function AmbientLight(r#,g#,b#)
	TLight.AmbientLight(r,g,b)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=AntiAlias">Online Help</a>
#End 
Function AntiAlias(samples)
	TRender.AntiAlias(samples)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=Animate">Online Help</a>
#End 
Function Animate(ent:TEntity,mode=1,speed#=1.0,seq%=0,trans%=0)
	ent.Animate(mode,speed,seq,trans)
End 

Function AnimateTexture(ent:TEntity, frame:Int, loop:Bool=False, i:Int=0)
	ent.AnimateTexture(frame, loop, i)
End

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=Animating">Online Help</a>
#End 
Function Animating(ent:TEntity)
	Return ent.Animating()
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=AnimLength">Online Help</a>
#End 
Function AnimLength(ent:TEntity)
	Return ent.AnimLength()
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=AnimSeq">Online Help</a>
#End 
Function AnimSeq(ent:TEntity)
	Return ent.AnimSeq()
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=AnimTime">Online Help</a>
#End 
Function AnimTime#(ent:TEntity)
	Return ent.AnimTime()
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=BrushAlpha">Online Help</a>
#End 
Function BrushAlpha(brush:TBrush,a#)
	brush.BrushAlpha(a)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=BrushBlend">Online Help</a>
#End 
Function BrushBlend(brush:TBrush,blend)
	brush.BrushBlend(blend)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=BrushColor">Online Help</a>
#End 
Function BrushColor(brush:TBrush,r#,g#,b#)
	brush.BrushColor(r,g,b)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=BrushFX">Online Help</a>
#End 
Function BrushFX(brush:TBrush,fx)
	brush.BrushFX(fx)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=BrushShininess">Online Help</a>
#End 
Function BrushShininess(brush:TBrush,s#)
	brush.BrushShininess(s)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=BrushTexture">Online Help</a>
#End 
Function BrushTexture(brush:TBrush,tex:TTexture,frame:Int=0,index:Int=0)
	brush.BrushTexture(tex,frame,index)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=CameraClsColor">Online Help</a>
#End 
Function CameraClsColor(cam:TCamera,r#,g#,b#)
	cam.CameraClsColor(r,g,b)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=CameraClsMode">Online Help</a>
#End 
Function CameraClsMode(cam:TCamera,cls_depth,cls_zbuffer)
	cam.CameraClsMode(cls_depth,cls_zbuffer)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=CameraFogColor">Online Help</a>
#End 
Function CameraFogColor(cam:TCamera,r#,g#,b#)
	cam.CameraFogColor(r,g,b)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=CameraFogMode">Online Help</a>
#End 
Function CameraFogMode(cam:TCamera,mode)
	cam.CameraFogMode(mode)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=CameraFogRange">Online Help</a>
#End 
Function CameraFogRange(cam:TCamera,near#,far#)
	cam.CameraFogRange(near,far)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=CameraPick">Online Help</a>
#End 
Function CameraPick:TEntity(cam:TCamera,x#,y#)
	Return TPick.CameraPick(cam,x,y)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=CameraProject">Online Help</a>
#End 
Function CameraProject(cam:TCamera,x#,y#,z#)
	cam.CameraProject(x,y,z)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=CameraProjMode">Online Help</a>
#End 
Function CameraProjMode(cam:TCamera,mode)
	cam.CameraProjMode(mode)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=CameraRange">Online Help</a>
#End 
Function CameraRange(cam:TCamera,near#,far#)
	cam.CameraRange(near,far)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=CameraViewport">Online Help</a>
#End 
Function CameraViewport(cam:TCamera,x,y,width,height)
	cam.CameraViewport(x,y,width,height)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=CameraZoom">Online Help</a>
#End 
Function CameraZoom(cam:TCamera,zoom#)
	cam.CameraZoom(zoom)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=ClearCollisions">Online Help</a>
#End 
Function ClearCollisions()
	TCollisionPair.Clear()
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=ClearSurface">Online Help</a>
#End 
Function ClearSurface(surf:TSurface,clear_verts=True,clear_tris=True)
	surf.ClearSurface(clear_verts,clear_tris)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=ClearTextureFilters">Online Help</a>
#End 
Function ClearTextureFilters()
	TTexture.ClearTextureFilters()
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=ClearWorld">Online Help</a>
#End 
Function ClearWorld(entities=True,brushes=True,textures=True)
	TRender.ClearWorld(entities,brushes,textures)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=CollisionEntity">Online Help</a>
#End 
Function CollisionEntity:TEntity(ent:TEntity,index)
	Return ent.CollisionEntity(index)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=Collisions">Online Help</a>
#End 
Function Collisions(src_no,dest_no,method_no,response_no:Int=0)
	TCollisionPair.Collisions(src_no,dest_no,method_no,response_no)
End 
	
#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=CollisionNX">Online Help</a>
#End 
Function CollisionNX#(ent:TEntity,index)
	Return ent.CollisionNX(index)
End 
	
#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=CollisionNY">Online Help</a>
#End 
Function CollisionNY#(ent:TEntity,index)
	Return ent.CollisionNY(index)
End 
	
#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=CollisionNZ">Online Help</a>
#End 
Function CollisionNZ#(ent:TEntity,index)
	Return ent.CollisionNZ(index)
End 
	
#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=CollisionSurface">Online Help</a>
#End 
Function CollisionSurface:TSurface(ent:TEntity,index)
	Return ent.CollisionSurface(index)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=CollisionTime">Online Help</a>
#End 
Function CollisionTime#(ent:TEntity,index)
	Return ent.CollisionTime(index)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=CollisionTriangle">Online Help</a>
#End 	
Function CollisionTriangle(ent:TEntity,index)
	Return ent.CollisionTriangle(index)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=CollisionX">Online Help</a>
#End 
Function CollisionX#(ent:TEntity,index)
	Return ent.CollisionX(index)
End 
	
#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=CollisionY">Online Help</a>
#End 
Function CollisionY#(ent:TEntity,index)
	Return ent.CollisionY(index)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=CollisionZ">Online Help</a>
#End 
Function CollisionZ#(ent:TEntity,index)
	Return ent.CollisionZ(index)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=CountChildren">Online Help</a>
#End 
Function CountChildren(ent:TEntity)
	Return ent.CountChildren()
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=CountCollisions">Online Help</a>
#End 
Function CountCollisions(ent:TEntity)
	Return ent.CountCollisions()
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=CopyEntity">Online Help</a>
#End 
Function CopyEntity:TEntity(ent:TEntity,parent:TEntity=Null)
	Return ent.CopyEntity(parent)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=CopyMesh">Online Help</a>
#End 
Function CopyMesh:TMesh(mesh:TMesh,parent:TEntity=Null)
	Return mesh.CopyMesh(parent)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=CountSurfaces">Online Help</a>
#End 
Function CountSurfaces(mesh:TMesh)
	Return mesh.CountSurfaces()
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=CountTriangles">Online Help</a>
#End 
Function CountTriangles(surf:TSurface)
	Return surf.CountTriangles()
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=CountVertices">Online Help</a>
#end 
Function CountVertices(surf:TSurface)
	Return surf.CountVertices()
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=CreateBrush">Online Help</a>
#end 
Function CreateBrush:TBrush(r#=255.0,g#=255.0,b#=255.0)
	Return TBrush.CreateBrush(r,g,b)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=CreateCamera">Online Help</a>
#end 
Function CreateCamera:TCamera(parent:TEntity=Null)
	Return TCamera.CreateCamera(parent)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=CreateCone">Online Help</a>
#End 
Function CreateCone:TMesh(segments=8,solid=True,parent:TEntity=Null)
	Return TMesh.CreateCone(segments,solid,parent)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=CreateCylinder">Online Help</a>
#End 
Function CreateCylinder:TMesh(segments=8,solid=True,parent:TEntity=Null)
	Return TMesh.CreateCylinder(segments,solid,parent)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=CreateCube">Online Help</a>
#End 
Function CreateCube:TMesh(parent:TEntity=Null)
	Return TMesh.CreateCube(parent)
End 


Function CreateGrid:TMesh(x_seg:Int, y_seg:Int, repeat_tex:Bool=False , parent:TEntity=Null)
	Return TMesh.CreateGrid(x_seg, y_seg, repeat_tex, parent)
End

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=CreateMesh">Online Help</a>
#End 
Function CreateMesh:TMesh(parent:TEntity=Null)
	Return TMesh.CreateMesh(parent)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=CreateLight">Online Help</a>
#End 
Function CreateLight:TLight(light_type=1,parent:TEntity=Null)
	Return TLight.CreateLight(light_type,parent)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=CreatePivot">Online Help</a>
#End 
Function CreatePivot:TPivot(parent:TEntity=Null)
	Return TPivot.CreatePivot(parent)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=CreateSphere">Online Help</a>
#End 
Function CreateSphere:TMesh(segments=8,parent:TEntity=Null)
	Return TMesh.CreateSphere(segments,parent)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=CreateSprite">Online Help</a>
#End 
' Sprite
Function CreateSprite:TSprite(parent:TEntity=Null)
	Return TSprite.CreateSprite(parent)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=CreateSurface">Online Help</a>
#End 
Function CreateSurface:TSurface(mesh:TMesh,brush:TBrush=Null)
	Return mesh.CreateSurface(brush)
End 

Function CreateText3D:TText(str$ = "", font$="", num_chars:Int = 96, c_pixels:Int=9, pad:Int = 0 )
	Local tt:TText = TText.CreateText(Null, str,font,num_chars,c_pixels,pad, False)
	Return tt
End

Function CreateText2D:TText(camx:TCamera, str$ = "", font$="", num_chars:Int = 96, c_pixels:Int=9, pad:Int = 0 )
	Local tt:TText = TText.CreateText(camx,str,font,num_chars,c_pixels,pad, True)
	Return tt
End

Function CreateText2D:TText(str$ = "", font$="", num_chars:Int = 96, c_pixels:Int=9, pad:Int = 0 )
	Local tt:TText = TText.CreateText(Null,str,font,num_chars,c_pixels,pad, True)
	Return tt
End

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=CreateTexture">Online Help</a>
#End 
Function CreateTexture:TTexture(width,height,flags=1,frames=1)
	Return TTexture.CreateTexture(width,height,flags,frames)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=DeltaPitch">Online Help</a>
#End 
Function DeltaPitch#(ent1:TEntity,ent2:TEntity)
	Return ent1.DeltaPitch(ent2)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=DeltaYaw">Online Help</a>
#End 
Function DeltaYaw#(ent1:TEntity,ent2:TEntity)
	Return ent1.DeltaYaw(ent2)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=EntityAlpha">Online Help</a>
#End 
Function EntityAlpha(ent:TEntity,alpha#)
	ent.EntityAlpha(alpha)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=EntityAutoFade">Online Help</a>
#End 
Function EntityAutoFade(ent:TEntity,near#,far#)
	ent.EntityAutoFade(near,far)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=EntityBlend">Online Help</a>
#End 
Function EntityBlend(ent:TEntity,blend)
	ent.EntityBlend(blend)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=EntityBox">Online Help</a>
#End 
Function EntityBox(ent:TEntity,x#,y#,z#,w#,h#,d#)
	ent.EntityBox(x,y,z,w,h,d)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=EntityClass">Online Help</a>
#End 
Function EntityClass$(ent:TEntity)
	Return ent.EntityClass()
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=EntityCollided">Online Help</a>
#End 
Function EntityCollided:TEntity(ent:TEntity,type_no)
	Return ent.EntityCollided(type_no)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=EntityColor">Online Help</a>
#End 
Function EntityColor(ent:TEntity,red#,green#,blue#)
	ent.EntityColor(red,green,blue)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=EntityDistance">Online Help</a>
#End 
Function EntityDistance#(ent1:TEntity,ent2:TEntity)
	Return ent1.EntityDistance(ent2)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=EntityFX">Online Help</a>
#End 
Function EntityFX(ent:TEntity,fx)
	ent.EntityFX(fx)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=EntityInView">Online Help</a>
#End 
Function EntityInView(ent:TEntity,cam:TCamera)
	Return cam.EntityInView(ent)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=EntityName">Online Help</a>
#End 
Function EntityName$(ent:TEntity)
	Return ent.EntityName()
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=EntityOrder">Online Help</a>
#End 
Function EntityOrder(ent:TEntity,order%)
	ent.EntityOrder(order)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=EntityParent">Online Help</a>
#End 
Function EntityParent(ent:TEntity,parent_ent:TEntity,glob:Bool=True)
	ent.EntityParent(parent_ent,glob)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=EntityPick">Online Help</a>
#End 
Function EntityPick:TEntity(ent:TEntity,range#)
	Return TPick.EntityPick(ent,range)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=EntityPickMode">Online Help</a>
#End 
Function EntityPickMode(ent:TEntity,pick_mode%,obscurer?=True)
	ent.EntityPickMode(pick_mode,obscurer)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=EntityPitch">Online Help</a>
#End 
Function EntityPitch#(ent:TEntity,glob?=False)
	Return ent.EntityPitch(glob)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=EntityRadius">Online Help</a>
#End 
Function EntityRadius(ent:TEntity,radius_x#,radius_y#=0.0)
	ent.EntityRadius(radius_x,radius_y)
End 
	
#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=EntityRoll">Online Help</a>
#End 
Function EntityRoll#(ent:TEntity,glob?=False)
	Return ent.EntityRoll(glob)
End 

Function EntityScaleX:Float(ent:TEntity,glob?=False)
	Return ent.EntityScaleX(glob)
End 

Function EntityScaleY:Float(ent:TEntity,glob?=False)
	Return ent.EntityScaleY(glob)
End 

Function EntityScaleZ:Float(ent:TEntity,glob?=False)
	Return ent.EntityScaleZ(glob)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=EntityShininess">Online Help</a>
#End 
Function EntityShininess(ent:TEntity,shine#)
	ent.EntityShininess(shine)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=EntityTexture">Online Help</a>
#End 
Function EntityTexture(ent:TEntity,tex:TTexture,frame%=0,index%=0)
	TMesh(ent).EntityTexture(tex,frame,index)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=EntityType">Online Help</a>
#End 
Function EntityType(ent:TEntity,type_no%,recursive?=False)
	ent.EntityType(type_no,recursive)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=EntityVisible">Online Help</a>
#End 
Function EntityVisible(src_ent:TEntity,dest_ent:TEntity)
	Return TPick.EntityVisible(src_ent,dest_ent)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=EntityX">Online Help</a>
#End 
Function EntityX#(ent:TEntity,glob?=False)
	Return ent.EntityX(glob)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=EntityY">Online Help</a>
#End 
Function EntityY#(ent:TEntity,glob?=False)
	Return ent.EntityY(glob)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=EntityYaw">Online Help</a>
#End 
Function EntityYaw#(ent:TEntity,glob?=False)
	Return ent.EntityYaw(glob)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=EntityZ">Online Help</a>
#End 
Function EntityZ#(ent:TEntity,glob?=False)
	Return ent.EntityZ(glob)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=ExtractAnimSeq">Online Help</a>
#End 
Function ExtractAnimSeq(ent:TEntity,first_frame%,last_frame%,seq%=0)
	Return ent.ExtractAnimSeq(first_frame,last_frame,seq)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=FindChild">Online Help</a>
#End 
Function FindChild:TEntity(ent:TEntity,child_name$)
	Return ent.FindChild(child_name)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=FindSurface">Online Help</a>
#End 
Function FindSurface:TSurface(mesh:TMesh,brush:TBrush)
	Return mesh.FindSurface(brush)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=FitMesh">Online Help</a><p>
#End 
Function FitMesh:TMesh(mesh:TMesh,x#,y#,z#,width#,height#,depth#,uniform%=False)
	mesh.FitMesh(x,y,z,width,height,depth,uniform)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=FlipMesh">Online Help</a>
#End 
Function FlipMesh:TMesh(mesh:TMesh)
	mesh.FlipMesh()
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=FreeBrush">Online Help</a>
#End 
Function FreeBrush(brush:TBrush)
	brush.FreeBrush()
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=FreeEntity">Online Help</a>
#End 
Function FreeEntity(ent:TEntity)
	ent.FreeEntity()
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=FreeTexture">Online Help</a>
#End 
Function FreeTexture:TTexture(tex:TTexture)
	tex.FreeTexture()
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=GetBrushTexture">Online Help</a>
#End 
Function GetBrushTexture:TTexture(brush:TBrush,index%=0)
	Return TTexture.GetBrushTexture(brush,index)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=GetChild">Online Help</a>
#End 
Function GetChild:TEntity(ent:TEntity,child_no)
	Return ent.GetChild(child_no)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=GetEntityBrush">Online Help</a>
#End 
Function GetEntityBrush:TBrush(ent:TEntity)
	TBrush.GetEntityBrush(ent)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=GetEntityType">Online Help</a>
#End 	
Function GetEntityType(ent:TEntity)
	Return ent.GetEntityType()
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=ResetEntity">Online Help</a>
#End 
Function GetMatElement#(ent:TEntity,row,col)
	ent.GetMatElement(row,col)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=GetParent">Online Help</a>
#End 
Function GetParent:TEntity(ent:TEntity)
	Return ent.GetParent()
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=GetSurface">Online Help</a>
#End 
Function GetSurface:TSurface(mesh:TMesh,surf_no)
	Return mesh.GetSurface(surf_no)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=GetSurfaceBrush">Online Help</a>
#End 
Function GetSurfaceBrush:TBrush(surf:TSurface)
	Return TBrush.GetSurfaceBrush(surf)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=Graphics3DInit">Online Help</a>
#End 
Function Graphics3DInit()
	TRender.render.GraphicsInit()
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=HandleSprite">Online Help</a>
#End 	
Function HandleSprite(sprite:TSprite,h_x#,h_y#)
	sprite.HandleSprite(h_x,h_y)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=HideEntity">Online Help</a>
#End 
Function HideEntity(ent:TEntity)
	ent.HideEntity()
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=LightColor">Online Help</a>
#End 
Function LightColor(light:TLight,red#,green#,blue#)
	light.LightColor(red,green,blue)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=LightConeAngles">Online Help</a>
#End 
Function LightConeAngles(light:TLight,inner_ang#,outer_ang#)
	light.LightConeAngles(inner_ang,outer_ang)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=LightRange">Online Help</a>
#End 
Function LightRange(light:TLight,range#)
	light.LightRange(range)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=LinePick">Online Help</a>
#End 
Function LinePick:TEntity(x#,y#,z#,dx#,dy#,dz#,radius#=0.0)
	Return TPick.LinePick(x,y,z,dx,dy,dz,radius)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=LoadAnimMesh">Online Help</a>
#End 
Function LoadAnimMesh:TMesh(file$,parent:TEntity=Null, override_texflags:Int=-1)
	Return TMesh.LoadAnimMesh(file,parent, override_texflags)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=LoadAnimTexture">Online Help</a>
#End 
Function LoadAnimTexture:TTexture(file$,flags,frame_width,frame_height,first_frame%=0,frame_count%=-1)
	Return TTexture.LoadAnimTexture(file,flags,frame_width,frame_height,first_frame,frame_count)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=LoadBrush">Online Help</a>
#End 
Function LoadBrush:TBrush(file$,flags=1,u_scale#=1.0,v_scale#=1.0)
	Return TBrush.LoadBrush(file,flags,u_scale,v_scale)
End 

Function LoadAnimBrush:TBrush(file$,flags=1,frame_width,frame_height,first_frame%=0,frame_count%=-1)
	Return TBrush.LoadAnimBrush(file,flags,frame_width,frame_height,first_frame,frame_count)
End

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=LoadMesh">Online Help</a>
#End 
Function LoadMesh:TMesh(file$,parent:TEntity=Null, override_texflags:Int=-1)
	Return TMesh.LoadMesh(file,parent, override_texflags)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=LoadTexture">Online Help</a>
#End 
Function LoadTexture:TTexture(file$,flags%=1)
	Return TTexture.LoadTexture(file,flags)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=LoadSprite">Online Help</a>
#End 
Function LoadSprite:TSprite(tex_file$,tex_flag%=1,parent:TEntity=Null)
	Return TSprite.LoadSprite(tex_file,tex_flag,parent)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=MeshDepth">Online Help</a>
#End 
Function MeshDepth#(mesh:TMesh)
	Return mesh.MeshDepth()
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=MeshHeight">Online Help</a>
#End 
Function MeshHeight#(mesh:TMesh)
	Return mesh.MeshHeight()
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=MeshWidth">Online Help</a>
#End 
Function MeshWidth#(mesh:TMesh)
	Return mesh.MeshWidth()
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=MeshesIntersect">Online Help</a>
#End
Function MeshesIntersect:Bool(mesh1:TMesh,mesh2:TMesh)
	Return mesh1.MeshesIntersect(mesh2)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=MoveEntity">Online Help</a>
#End 
Function MoveEntity(ent:TEntity,x#,y#,z#)
	ent.MoveEntity(x,y,z)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=NameEntity">Online Help</a>
#End 
Function NameEntity(ent:TEntity,name$)
	ent.NameEntity(name)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=PaintEntity">Online Help</a>
#End 
Function PaintEntity(ent:TEntity,brush:TBrush)
	TMesh(ent).PaintEntity(brush)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=PaintMesh">Online Help</a>
#End 
Function PaintMesh:TMesh(mesh:TMesh,brush:TBrush)
	mesh.PaintMesh(brush)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=PaintSurface">Online Help</a>
#End 
Function PaintSurface(surf:TSurface,brush:TBrush)
	Return surf.PaintSurface(brush)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=PickedEntity">Online Help</a>
#End 
Function PickedEntity:TEntity()
	Return TPick.PickedEntity()
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=PickedNX">Online Help</a>
#End 
Function PickedNX#()
	Return TPick.PickedNX()
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=PickedNY">Online Help</a>
#End 
Function PickedNY#()
	Return TPick.PickedNY()
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=PickedNZ">Online Help</a>
#End 
Function PickedNZ#()
	Return TPick.PickedNZ()
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=PickedSurface">Online Help</a>
#End 
Function PickedSurface:TSurface()
	Return TPick.PickedSurface()
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=PickedTime">Online Help</a>
#End 
Function PickedTime#()
	Return TPick.PickedTime()
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=PickedTriangle">Online Help</a>
#End 
Function PickedTriangle()
	Return TPick.PickedTriangle()
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=PickedX">Online Help</a>
#End 
Function PickedX#()
	Return TPick.PickedX()
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=PickedY">Online Help</a>
#End 
Function PickedY#()
	Return TPick.PickedY()
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=PickedZ">Online Help</a>
#End 
Function PickedZ#()
	Return TPick.PickedZ()
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=PointEntity">Online Help</a>
#End 
Function PointEntity(ent:TEntity,target_ent:TEntity,roll#=0)
	ent.PointEntity(target_ent,roll)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=PositionEntity">Online Help</a>
#End 
Function PositionEntity(ent:TEntity,x#,y#,z#,glob=False)
	ent.PositionEntity(x,y,z,glob)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=PositionMesh">Online Help</a>
#End 
Function PositionMesh:TMesh(mesh:TMesh,px#,py#,pz#)
	mesh.PositionMesh(px,py,pz)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=PositionTexture">Online Help</a>
#End 
Function PositionTexture(tex:TTexture,u_pos#,v_pos#)
	tex.PositionTexture(u_pos,v_pos)
End 

Function PreLoadPixmap:Int(fs:String[])
	Return TPixmap.PreLoadPixmap(fs)
End

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=ProjectedX">Online Help</a>
#End 
Function ProjectedX#()
    Return TCamera.projected_x
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=ProjectedY">Online Help</a>
#End 
Function ProjectedY#()
    Return TCamera.projected_y
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=ProjectedZ">Online Help</a>
#End 
Function ProjectedZ#()
    Return TCamera.projected_z
End 

Function ReloadAllSurfaces:Void()
	TRender.render.ReloadSurfaces()
End

Function ReloadAllTextures:Void()
	TTexture.ReloadAllTextures()
End

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=RenderWorld">Online Help</a>
#End 
Function RenderWorld()
	TRender.RenderWorld()
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=ResetEntity">Online Help</a>
#End 
Function ResetEntity(ent:TEntity)
	ent.ResetEntity()
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=RotateEntity">Online Help</a>
#End 
Function RotateEntity(ent:TEntity,x#,y#,z#,glob%=False)
	ent.RotateEntity(x,y,z,glob)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=RotateMesh">Online Help</a>
#End 
Function RotateMesh:TMesh(mesh:TMesh,pitch#,yaw#,roll#)
	mesh.RotateMesh(pitch,yaw,roll)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=RotateSprite">Online Help</a>
#End 
Function RotateSprite(sprite:TSprite,ang#)
	sprite.RotateSprite(ang)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=RotateTexture">Online Help</a>
#End 	
Function RotateTexture(tex:TTexture,ang#)
	tex.RotateTexture(ang)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=ScaleEntity">Online Help</a>
#End 
Function ScaleEntity(ent:TEntity,x#,y#,z#,glob%=False)
	ent.ScaleEntity(x,y,z,glob)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=ScaleMesh">Online Help</a>
#End 
Function ScaleMesh:TMesh(mesh:TMesh,sx#,sy#,sz#)
	mesh.ScaleMesh(sx,sy,sz)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=ScaleSprite">Online Help</a>
#End 	
Function ScaleSprite(sprite:TSprite,s_x#,s_y#)
	sprite.ScaleSprite(s_x,s_y)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=ScaleTexture">Online Help</a>
#End 
Function ScaleTexture(tex:TTexture,u_scale#,v_scale#)	
	tex.ScaleTexture(u_scale,v_scale)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=SetAnimTime">Online Help</a>
#End 
Function SetAnimTime(ent:TEntity,time#,seq=0)
	ent.SetAnimTime(time,seq)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=SetCubeFace">Online Help</a>
#End 
Function SetCubeFace(tex:TTexture,face)
	tex.SetCubeFace(face)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=SetCubeMode">Online Help</a>
#End 
Function SetCubeMode(tex:TTexture,mode)
	tex.SetCubeMode(mode)
End 

'Function SetRender(r:TRender)

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=ShowEntity">Online Help</a>
#End 
Function ShowEntity(ent:TEntity)
	ent.ShowEntity()
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=SpriteViewMode">Online Help</a>
#End 	
Function SpriteViewMode(sprite:TSprite,mode)
	sprite.SpriteViewMode(mode)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=TextureBlend">Online Help</a>
#End 
Function TextureBlend(tex:TTexture,blend)
	tex.TextureBlend(blend)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=TextureCoords">Online Help</a>
#End 
Function TextureCoords(tex:TTexture,coords)
	tex.TextureCoords(coords)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=TextureHeight">Online Help</a>
#End 	
Function TextureHeight(tex:TTexture)
	Return tex.TextureHeight()
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=TextureFilter">Online Help</a>
#End 
Function TextureFilter(match_text$,flags)
	TTexture.TextureFilter(match_text,flags)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=TextureName">Online Help</a>
#End 	
Function TextureName$(tex:TTexture)
	Return tex.TextureName()
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=TextureWidth">Online Help</a>
#End 	
Function TextureWidth(tex:TTexture)
	Return tex.TextureWidth()
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=TFormedX">Online Help</a>
#End 
Function TFormedX#()
	Return TEntity.TFormedX()
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=TFormedY">Online Help</a>
#End 
Function TFormedY#()
	Return TEntity.TFormedY()
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=TFormedZ">Online Help</a>
#End 
Function TFormedZ#()
	Return TEntity.TFormedZ()
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=TFormNormal">Online Help</a>
#End 
Function TFormNormal(x#,y#,z#,src_ent:TEntity,dest_ent:TEntity)
	TEntity.TFormNormal(x,y,z,src_ent,dest_ent)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=TFormPoint">Online Help</a>
#End 
Function TFormPoint(x#,y#,z#,src_ent:TEntity,dest_ent:TEntity)
	TEntity.TFormPoint(x,y,z,src_ent,dest_ent)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=TFormVector">Online Help</a>
#End 
Function TFormVector(x#,y#,z#,src_ent:TEntity,dest_ent:TEntity)
	TEntity.TFormVector(x,y,z,src_ent,dest_ent)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=TranslateEntity">Online Help</a>
#End 
Function TranslateEntity(ent:TEntity,x#,y#,z#,glob=False)
	ent.TranslateEntity(x,y,z,glob)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=TriangleVertex">Online Help</a>
#End 
Function TriangleVertex(surf:TSurface,tri_no,corner)
	Return surf.TriangleVertex(tri_no,corner)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=TurnEntity">Online Help</a>
#End 
Function TurnEntity(ent:TEntity,x#,y#,z#,glob=False)
	ent.TurnEntity(x,y,z,glob)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=UpdateNormals">Online Help</a>
#End 
Function UpdateNormals(mesh:TMesh)
	mesh.UpdateNormals()
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=UpdateWorld">Online Help</a>
#End 
Function UpdateWorld(anim_speed#=1.0)
	TRender.UpdateWorld(anim_speed)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=VectorPitch">Online Help</a>
#End 	
Function VectorPitch#(vx#,vy#,vz#)
	Return Vector.VectorPitch(vx,vy,vz)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=VectorYaw">Online Help</a>
#End 	
Function VectorYaw#(vx#,vy#,vz#)
	Return Vector.VectorYaw(vx,vy,vz)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=VertexAlpha">Online Help</a>
#End 
Function VertexAlpha#(surf:TSurface,vid)
	Return surf.VertexAlpha(vid)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=VertexBlue">Online Help</a>
#End 
Function VertexBlue#(surf:TSurface,vid)
	Return surf.VertexBlue(vid)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=VertexColor">Online Help</a>
#End 
Function VertexColor(surf:TSurface,vid,r#,g#,b#,a#=1.0)
	Return surf.VertexColor(vid,r,g,b,a)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=VertexCoords">Online Help</a>
#End 
Function VertexCoords(surf:TSurface,vid,x#,y#,z#)
	Return surf.VertexCoords(vid,x,y,z)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=VertexGreen">Online Help</a>
#End 
Function VertexGreen#(surf:TSurface,vid)
	Return surf.VertexGreen(vid)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=VertexNormal">Online Help</a>
#End 
Function VertexNormal(surf:TSurface,vid,nx#,ny#,nz#)
	Return surf.VertexNormal(vid,nx,ny,nz)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=VertexNX">Online Help</a>
#End 
Function VertexNX#(surf:TSurface,vid)
	Return surf.VertexNX(vid)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=VertexNY">Online Help</a>
#End 
Function VertexNY#(surf:TSurface,vid)
	Return surf.VertexNY(vid)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=VertexNZ">Online Help</a>
#End 
Function VertexNZ#(surf:TSurface,vid)
	Return surf.VertexNZ(vid)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=VertexRed">Online Help</a>
#End 
Function VertexRed#(surf:TSurface,vid)
	Return surf.VertexRed(vid)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=VertexTexCoords">Online Help</a>
#End 
Function VertexTexCoords(surf:TSurface,vid,u#,v#,w#=0.0,coord_set%=0)
	Return surf.VertexTexCoords(vid,u,v,w,coord_set)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=VertexU">Online Help</a>
#End 
Function VertexU#(surf:TSurface,vid,coord_set%=0)
	Return surf.VertexU(vid,coord_set)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=VertexV">Online Help</a>
#End 
Function VertexV#(surf:TSurface,vid,coord_set%=0)
	Return surf.VertexV(vid,coord_set)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=VertexW">Online Help</a>
#End 
Function VertexW#(surf:TSurface,vid,coord_set%=0)
	Return surf.VertexW(vid,coord_set)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=VertexX">Online Help</a>
#End 
Function VertexX#(surf:TSurface,vid)
	Return surf.VertexX(vid)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=VertexY">Online Help</a>
#End 
Function VertexY#(surf:TSurface,vid)
	Return surf.VertexY(vid)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=VertexZ">Online Help</a>
#End 
Function VertexZ#(surf:TSurface,vid)
	Return surf.VertexZ(vid)
End 

#rem
bbdoc: <a href="http://www.blitzbasic.com/b3ddocs/command.php?name=Wireframe">Online Help</a>
#End 
Function Wireframe(enable:Bool)
	TRender.Wireframe(enable)
End 



' Blitz2D Depricated ------------------------------

Function Text(x,y,str$)
	'' use TText.Create()
	'TBlitz2D.Text(x,y,str)
End 

Function BeginMax2D()
	'' Use Flat Camera and CameraLayers()
	'TBlitz2D.BeginMax2D()
End 

Function EndMax2D()
	'TBlitz2D.EndMax2D()
End 


' ***todo***

Function LightMesh(mesh:TMesh,red#,green#,blue#,range#=0,light_x#=0,light_y#=0,light_z#=0)
End 

Function CreatePlane(sub_divs=1,parent:TEntity=Null)
End 

Function LoadAnimSeq(ent:TEntity,filename$)
End 
Function SetAnimKey(ent:TEntity,frame,pos_key=True,rot_key=True,scale_key=True)
End 
Function AddAnimSeq(ent:TEntity,length)
End 
