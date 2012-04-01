Import minib3d

Class TLight Extends TEntity

	Global light_no:Int =0
	Global no_lights:Int =0
	Global max_lights:Int =8
	
	' enter gl consts here for each available light
	Global gl_light:Int[] = [GL_LIGHT0,GL_LIGHT1,GL_LIGHT2,GL_LIGHT3,GL_LIGHT4,GL_LIGHT5,GL_LIGHT6,GL_LIGHT7]

	Global light_list:List<TLight> = New List<TLight>
	Field light_link:list.Node<TLight>

	Field light_type:Int=0
	Field range#=1.0/1000.0
	Field red#=1.0,green#=1.0,blue#=1.0
	Field inner_ang#=0.0,outer_ang#=45.0
	
	Global ambient_red:Float=0.5,ambient_green:Float=0.5,ambient_blue:Float=0.5
	
	Method New()

		
	End 
	
	Method Delete()

	
	End 

	Method CopyEntity:TEntity(parent_ent:TEntity=Null)

		' new light 
		Local light:TLight=New TLight
		
		' copy contents of child list before adding parent
		For Local ent:TEntity=Eachin child_list
			ent.CopyEntity(light)
		Next
		
		' lists
		
		' add parent, add to list
		light.AddParent(parent_ent)
		light.entity_link = entity_list.EntityListAdd(light)
		

		' add to collision entity list
		If collision_type<>0
			TCollisionPair.ent_lists[collision_type].AddLast(light)
		Endif
		
		' add to pick entity list
		If pick_mode<>0
			light.pick_link = TPick.ent_list.AddLast(light)
		Endif


		' update matrix
		If light.parent<>Null
			light.mat.Overwrite(light.parent.mat)
		Else
			light.mat.LoadIdentity()
		Endif
		
		' copy entity info
				
		light.mat.Multiply(mat)
		
		light.px=px
		light.py=py
		light.pz=pz
		light.sx=sx
		light.sy=sy
		light.sz=sz
		light.rx=rx
		light.ry=ry
		light.rz=rz
		light.qw=qw
		light.qx=qx
		light.qy=qy
		light.qz=qz
		
		light.name=name
		light.classname=classname
		light.order=order
		light.hide=False

		light.cull_radius=cull_radius
		light.radius_x=radius_x
		light.radius_y=radius_y
		light.box_x=box_x
		light.box_y=box_y
		light.box_z=box_z
		light.box_w=box_w
		light.box_h=box_h
		light.box_d=box_d
		light.pick_mode=pick_mode
		light.obscurer=obscurer

		' copy light info
		
		light_link = light_list.AddLast(light) ' add new light to global light list
		
		light.light_type=light_type
		light.range=range
		light.red=red
		light.green=green
		light.blue=blue
		light.inner_ang=inner_ang
		light.outer_ang=outer_ang
		
		Return light
		
	End 

	Method FreeEntity()
	
		Super.FreeEntity() 
		
		light_link.Remove()
		
		If no_lights>0 Then no_lights=no_lights-1
		
		glDisable(gl_light[no_lights])
		
	End 
	
	Function CreateLight:TLight(l_type=1,parent_ent:TEntity=Null)

		Local light:TLight=New TLight
		light.light_type=l_type
		light.classname="Light"
		
		If no_lights >= max_lights Then Return ' no more lights available, return and gc will collect create light
		
		' no of lights increased, enable additional gl light
		no_lights=no_lights+1
		glEnable(gl_light[no_lights-1])
		
		Local white_light#[]=[1.0,1.0,1.0,1.0]
		glLightfv(gl_light[no_lights-1],GL_SPECULAR,white_light)
		
		' if point light or spotlight then set constant attenuation to 0
		If light.light_type>1
			Local light_range#[]=[0.0]
			glLightfv(gl_light[no_lights-1],GL_CONSTANT_ATTENUATION,light_range)
		Endif
		
		' if spotlight then set exponent to 10.0 (controls fall-off of spotlight - roughly matches B3D)
		If light.light_type=3
			Local exponent#[]=[10.0]
			glLightfv(gl_light[no_lights-1],GL_SPOT_EXPONENT,exponent)
		Endif
	
		light.light_link = light_list.AddLast(light)
		light.AddParent(parent_ent)
		entity_list.EntityListAdd(light)

		' update matrix
		If light.parent<>Null
			light.mat.Overwrite(light.parent.mat)
			light.UpdateMat()
		Else
			light.UpdateMat(True)
		Endif

		Return light

	End 

	Method LightRange(light_range#)
	
		range=1.0/light_range
		
	End 
		
	Method LightColor(r#,g#,b#)
	
		red=r/255.0
		green=g/255.0
		blue=b/255.0
		
	End 
	
	Method LightConeAngles(inner#,outer#)
	
		inner_ang=inner*0.5
		outer_ang=outer*0.5
		
	End 
	
	
	Function AmbientLight(r#,g#,b#)
	
		Local inv:Float = 1.0/255.0
		ambient_red=r*inv
		ambient_green=g*inv
		ambient_blue=b*inv
	
	End 
	
	
	Method Update(cam:TCamera)

		light_no=light_no+1
		If light_no>no_lights Then light_no=1

		If Hidden()=True
			glDisable(gl_light[light_no-1])
			Return
		Else
			glEnable(gl_light[light_no-1])
		Endif

		glPushMatrix()

		glMultMatrixf(mat.ToArray() )
		
		Local z#=1.0
		Local w#=0.0
		If light_type>1
			z=0.0
			w=1.0
		Endif
		
		Local rgba#[]=[red,green,blue,1.0]
		Local pos#[]=[0.0,0.0,z,w]
		
		glLightfv(gl_light[light_no-1],GL_POSITION,pos)
		glLightfv(gl_light[light_no-1],GL_DIFFUSE,rgba)

		' point or spotlight, set attenuation
		If light_type>1
		
			Local light_range#[]=[range]
			
			glLightfv(gl_light[light_no-1],GL_LINEAR_ATTENUATION,light_range)
		
		Endif

		' spotlight, set direction and range
		If light_type=3 
		
			Local dir#[]=[0.0,0.0,-1.0]
			Local outer#[]=[outer_ang]
		
			glLightfv(gl_light[light_no-1],GL_SPOT_DIRECTION,dir)
			glLightfv(gl_light[light_no-1],GL_SPOT_CUTOFF,outer)
		
		Endif
		
		glPopMatrix()
																	
	End 		
		
End
