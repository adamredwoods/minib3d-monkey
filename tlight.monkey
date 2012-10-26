Import minib3d



Class TLight Extends TEntity
	
	Const INV255:Float = 1.0/255.0
	
	'Global light_no:Int =0 'moved to trender
	Global no_lights:Int =0
	Global max_lights:Int =8
	
	
	Global light_list:List<TLight> = New List<TLight>
	Field light_link:list.Node<TLight>

	Field light_type:Int=0
	Field range#=1.0/1000.0 ''inverse range to be precise
	Field actual_range#=1000.0/1.0
	Field red#=1.0,green#=1.0,blue#=1.0
	Field inner_ang#=0.0,outer_ang#=45.0
	Field spec_red#=0.0,spec_grn#=0.0,spec_blu#=0.0,spec_a#=0.0
	Field const_att#=0.0,lin_att#=1.0,quad_att#=0.0
	Field spot_exp:Float = 10.0
	
	Global ambient_red:Float=0.1,ambient_green:Float=0.1,ambient_blue:Float=0.1
	
	Field remove_light:Bool = False
	
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
		light.const_att =const_att
		light.lin_att =lin_att
		light.quad_att =quad_att
		light.spot_exp =spot_exp
		
		Return light
		
	End 

	Method FreeEntity()
	
		If no_lights>0 Then no_lights=no_lights-1
		
		remove_light = true
		
	End 
	
	Function CreateLight:TLight(l_type:Int=1,parent_ent:TEntity=Null)

		If no_lights >= max_lights Then Return ' no more lights available, return

		Local light:TLight=New TLight
		light.light_type=l_type
		light.classname="Light"	
		
		' no of lights increased, enable additional gl light
		no_lights=no_lights+1
		'glEnable(gl_light[no_lights-1])
		
		light.lin_att = 1.0 
	
		light.light_link = light_list.AddLast(light)
		light.entity_link = entity_list.EntityListAdd(light) ''for collisions
		If parent_ent Then light.AddParent(parent_ent)
		

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
	
		actual_range = light_range
		range=1.0/light_range
		
	End 
		
	Method LightColor(r#,g#,b#)
	
		red=r *INV255
		green=g *INV255
		blue=b *INV255
		
	End 
	
	Method LightConeAngles(inner#,outer#)
	
		inner_ang=inner*0.5
		outer_ang=outer*0.5
		
	End 
	
	
	Function AmbientLight(r#,g#,b#)
		
		ambient_red=r *INV255
		ambient_green=g *INV255
		ambient_blue=b *INV255
	
	End 
	
	Method LightAttenuation(val1#=0.0,val2#=1.0,val3#=0.0)
		
		const_att=val1
		lin_att=val2
		quad_att=val3

	End
	
	Method Update(cam:TCamera)

		''deprecated to trender.UpdateLight(cam,light)
																	
	End 		
		
End
