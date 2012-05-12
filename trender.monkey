Import minib3d
Import opengl.databuffer


#If MINIB3D_DRIVER="default"
	Import minib3d.opengles11
#endif

#Print "MINIB3D_DRIVER="+MINIB3D_DRIVER






Function SetRender(r:TRender, flags:Int=0)

	TRender.render = r
	
	TRender.render.GraphicsInit(flags)
	
End


Class TRender

	Global render:TRender
	Global vbo_enabled:Bool=False ' this is set in GraphicsInit - will be set to true if USE_VBO is true and the hardware supports vbos
	
	Global shader_enabled:Bool = False
	
	Global width:Int,height:Int,mode:Int,depth:Int,rate:Int
	
	Global wireframe:Bool=False ''draw meshes as lines or filled

	Global alpha_pass:Int = 0 ''for optimizing the TMesh render routine
	
	Private
	
	Global render_list:List<TMesh> = New List<TMesh>
	Global render_alpha_list:RenderAlphaList = New RenderAlphaList
	
	
	Public
	
	
	Method GetVersion:Float() Abstract ''returns version of graphics platform being used
	
	Method Reset:Void() Abstract ''reset for each camera
	Method Finish:Void() Abstract ''finish pass for each camera
	
	Method GraphicsInit:Int(flags:Int=0) Abstract ''init during SetRender()
	
	Method Render:Void(ent:TEntity, cam:TCamera = Null) Abstract ''render per mesh
	
	Method ClearErrors:Int() Abstract

	
	Method BindTexture:TTexture(tex:TTexture,flags:Int) Abstract
	Method DeleteTexture(glid:Int[]) Abstract
	
	Method UpdateLight(cam:TCamera, light:TLight) Abstract
	Method DisableLight(light:TLight) Abstract
	
	Method UpdateCamera(cam:TCamera) Abstract
	
	
	''-------------------------------------------------------
	
	
	Function ClearWorld(entities=True,brushes=True,textures=True)
		
		render_list.Clear()
		render_alpha_list.Clear()
		
		If entities
Print TEntity.entity_list.Count()			
			For Local ent:TEntity=Eachin TEntity.entity_list
Print ent.classname
				ent.FreeEntity()
				ent=Null
			Next
			
			'TEntity.entity_list.Clear()
			ClearCollisions()
			
			TPick.ent_list.Clear()
			TPick.picked_ent=Null
			TPick.picked_surface=0
			
		Endif
		
		If textures
		
			For Local tex:TTexture=Eachin TTexture.tex_list
				tex.FreeTexture()
			Next
		
		Endif
	
	End 
			
	
	Function UpdateWorld(anim_speed#=1.0)
		
		' collision
		
		CollisionInfo.UpdateCollisions()
		
		' anim
	
		Local first:Int
		Local last:Int


		For Local mesh:TEntity=Eachin TEntity.entity_list
		
			If mesh.anim And mesh.anim_update=True
			
				first=mesh.anim_seqs_first[mesh.anim_seq]
				last=mesh.anim_seqs_last[mesh.anim_seq]
		
				Local anim_start=False

				If mesh.anim_trans>0
				
					mesh.anim_trans=mesh.anim_trans-1
					If mesh.anim_trans=1 Then anim_start=True
					
				Endif
				
				If mesh.anim_trans>0
				
					Local r#=1.0-mesh.anim_time
					r=r/mesh.anim_trans
					mesh.anim_time=mesh.anim_time+r
									
					If mesh.anim = 1
					
						TAnimation.AnimateMesh2(mesh,mesh.anim_time,first,last)
						
					Elseif mesh.anim = 2
					
						TAnimation.AnimateVertex(mesh,mesh.anim_time,first,last)
						
					Endif
					
					If anim_start=True Then mesh.anim_time=first
			
				Else
				
					If mesh.anim = 1
					
						TAnimation.AnimateMesh(mesh,mesh.anim_time,first,last)
						
					Elseif mesh.anim = 2
					
						TAnimation.AnimateVertex(mesh,mesh.anim_time,first,last)
						
					Endif
					
					If mesh.anim_mode=0 ''stop animation
						
						mesh.anim_update=False ' after updating animation so that animation is in final 'stop' pose - don't update again
		
					Elseif mesh.anim_mode=1 ''loop animation (default)
			
						mesh.anim_time=mesh.anim_time+(mesh.anim_speed*anim_speed)
						If mesh.anim_time>last
							mesh.anim_time=first+(mesh.anim_time-last)
						Endif
					
					Elseif mesh.anim_mode=2 ''ping pong
					
						If mesh.anim_dir=1
							mesh.anim_time=mesh.anim_time+(mesh.anim_speed*anim_speed)
							If mesh.anim_time>last
								mesh.anim_time=mesh.anim_time-(mesh.anim_speed*anim_speed)
								mesh.anim_dir=-1
							Endif
						Endif
						
						If mesh.anim_dir=-1
							mesh.anim_time=mesh.anim_time-(mesh.anim_speed*anim_speed)
							If mesh.anim_time<first
								mesh.anim_time=mesh.anim_time+(mesh.anim_speed*anim_speed)
								mesh.anim_dir=1
							Endif
						Endif
					
					Elseif mesh.anim_mode=3 ''one-shot, hold at end
			
						mesh.anim_time=mesh.anim_time+(mesh.anim_speed*anim_speed)
						If mesh.anim_time>last
							mesh.anim_time=last
							mesh.anim_mode=0
						Endif
					
					Endif
					
				Endif
							
			Endif
		
		Next

	End 

	
	
	
	Function  RenderWorld:Void()
	
		If Not TCamera.cam_list Or render = Null Then Return
		
		For Local cam:TCamera=Eachin TCamera.cam_list

			'If cam.parent_hidden=True Or cam.hidden=True Then Continue
			If cam.Hidden()=True Then Continue

			TRender.render.RenderCamera(cam)

		Next


	End 
	
	
	Method RenderCamera:Void(cam:TCamera, skip:Int=0)
	
		'' use skip to render without updating camera
		'' would be useful for FSAA, FBOs, or a render layer system
		If (Not skip)
		
			cam.Update(cam)
			UpdateCamera( cam ) ''update Render
			
		Endif
	
		
		For Local light:TLight=Eachin TLight.light_list
	
			UpdateLight(cam,light) ' EntityHidden code inside Update
			
		Next

		render_list.Clear()
		render_alpha_list.Clear()
		
		''Perform camera clipping, alpha ordering, and entity sort
		Local mesh:TMesh
		Local alpha_count:Int=0

		
		Reset() ''reset render pass
		
		For Local ent:TEntity=Eachin TEntity.entity_list
			
			'' reject non-mesh
			mesh = TMesh( ent )
			
			If mesh				
				
				'If mesh.parent_hidden=True Or mesh.hidden=True Or mesh.brush.alpha=0.0 Then Continue
				If mesh.Hidden()=True Or mesh.brush.alpha=0.0 Then Continue
				
				''cam layer mode
				If (mesh.is_cam_layer Or cam.is_cam_layer) And mesh.cam_layer <> cam Then Continue
				
				' get new bounds
				mesh.GetBounds()
		
				' Perform frustum cull
				
				Local inview:Int =cam.EntityInFrustum(mesh)
	
				If inview
				
					If mesh.auto_fade=True Then mesh.AutoFade(cam)
					
					If mesh.is_sprite Or mesh.is_update
				
						mesh.Update(cam ) ' rotate sprites with respect to current cam					
						
					Endif
		
					If mesh.Alpha()
						
						''alpha entities are drawn last
						
						mesh.alpha_order=cam.EntityDistanceSquared(mesh)
						render_alpha_list.AddLast(mesh)


					Else
					
						mesh.alpha_order=0.0
						TRender.render.Render(mesh,cam)
						
					Endif
					
				Endif
			Endif
					
		Next

				
		' Draw everything in alpha render list
		
		render_alpha_list.Sort() ''sorting alpha_order
		TRender.alpha_pass = 1 ''skip non-alpha surface pass
		
		For mesh = Eachin render_alpha_list

			TRender.render.Render(mesh,cam)

		Next
		
		Finish() ''end render pass
		
	End
	
	
	Function Wireframe(enable:Bool)
	
		wireframe = enable
		
	End 
	
	Method ReloadSurfaces:Int()
		
		Return 0
	End
	
End


''
''helper classes
''

Class RenderAlphaList Extends List<TMesh>
	
	''draw furthest (highest alpha_order) first, so sort from great to least
	Method Compare( left:TMesh,right:TMesh )
		If left.alpha_order > right.alpha_order Return -1 ''double check, i flipped these
		Return left.alpha_order < right.alpha_order
	End
	
End


Class SurfaceAlphaList Extends List<TSurface>
	
	Method Compare( left:TSurface,right:TSurface)
		''---- how do we compare surface alphas in the correct order to draw? leave to user to order?
		
		'If left.alpha_order < right.alpha_order Return -1
		'Return left.alpha_order > right.alpha_order
	End
	
End


''----------------------------------------------------

