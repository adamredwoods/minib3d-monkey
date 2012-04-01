Import minib3d

Class TBone Extends TEntity

	Field n_px#,n_py#,n_pz#,n_sx#,n_sy#,n_sz#,n_rx#,n_ry#,n_rz#,n_qw#,n_qx#,n_qy#,n_qz#

	Field keys:TAnimationKeys
	
	' additional matrices used for animation purposes
	Field mat2:Matrix=New Matrix
	Field inv_mat:Matrix=New Matrix ' set in TModel, when loading anim mesh
	Field tform_mat:Matrix=New Matrix
	
	Global new_mat:Matrix = New Matrix ' temp use
	
	Field kx#,ky#,kz#,kqw#,kqx#,kqy#,kqz# ' used to store current keyframe in AnimateMesh, for use with transition
	
	Method New()
	
	
	End 
	
	Method Delete()
	
	
	End 
	
	''debugging method
	Method PrintXYZ(ch:Int=0)
		ch+=1
		For Local ent:TEntity=Eachin child_list
			If Not TBone(ent) Then Print "? ="; Continue
			Print ch+"= "+kqw+" "+kqy+" "+kqz+" "+kqw+" .. "+kx+" "+ky+" "+kz
			TBone(ent).PrintXYZ(ch)
		Next
	End
	
	
	
	Method CopyEntity:TEntity(parent_ent:TEntity=Null)
	
		' new bone
		Local bone:TBone=New TBone
		
		' copy contents of child list before adding parent
		For Local ent:TEntity=Eachin child_list
			ent.CopyEntity(bone)
		Next
		
		' add parent, add to list so children are at least visible
		bone.AddParent(parent_ent)
		bone.entity_link = entity_list.EntityListAdd(bone)
		
		' update matrix
		If bone.parent<>Null
			bone.mat.Overwrite(bone.parent.mat)
		Else
			bone.mat.LoadIdentity()
		Endif
		
		' copy entity info
		
		bone.mat.Multiply(mat)

		bone.px=px
		bone.py=py
		bone.pz=pz
		bone.sx=sx
		bone.sy=sy
		bone.sz=sz
		bone.rx=rx
		bone.ry=ry
		bone.rz=rz
		bone.qw=qw
		bone.qx=qx
		bone.qy=qy
		bone.qz=qz
		
		bone.name=name
		bone.classname=classname
		bone.order=order
		bone.hide=False
		
		' copy bone info
		
		bone.n_px=n_px
		bone.n_py=n_py
		bone.n_pz=n_pz
		bone.n_sx=n_sx
		bone.n_sy=n_sy
		bone.n_sz=n_sz
		bone.n_rx=n_rx
		bone.n_ry=n_ry
		bone.n_rz=n_rz
		bone.n_qw=n_qw
		bone.n_qx=n_qx
		bone.n_qy=n_qy
		bone.n_qz=n_qz
	
		bone.keys=keys.Copy()
		
		bone.kx=kx
		bone.ky=ky
		bone.kz=kz
		bone.kqw=kqw
		bone.kqx=kqx
		bone.kqy=kqy
		bone.kqz=kqz
		
		bone.mat2=mat2.Copy()
		bone.inv_mat=inv_mat.Copy()
		bone.tform_mat=tform_mat.Copy()

		Return bone
	
	End 
		
	Method FreeEntity()
	
		Super.FreeEntity() 
	
		keys=Null
	
	End 

	' Same as UpdateChildren in TEntity except it negates z value of bone matrices so that children are transformed
	' in correct z direction
	Function UpdateBoneChildren(ent_p:TEntity)
		Return
		
		#rem
		For Local ent_c:TEntity=Eachin ent_p.child_list
			
			If TBone(ent_c)=Null ' if child is not a bone
						
				Local mat:TMatrix=ent_p.mat.Copy()
			
				' if parent is a bone, negate z value of matrix
				If TBone(ent_p)<>Null
					mat.grid[3,2]=-mat.grid[3,2]
					'mat=TBone(ent_p).tform_mat
				Endif
			
				ent_c.mat.Overwrite(mat)
				ent_c.UpdateMat()
				
			Endif
			
			UpdateChildren(ent_c:TEntity)
					
		Next
		#end
	End 
	
	
	Method Transform:Void(pos:Vector, quat:Quaternion)
		
		Quaternion.QuatToMatrix(quat.x,quat.y,quat.z,quat.w, mat)
	
		mat.grid[3][0]=pos.x
		mat.grid[3][1]=pos.y
		mat.grid[3][2]=pos.z

		' store local position/rotation values. will be needed to maintain bone positions when positionentity etc is called
		'Local eul:Float[] = Quaternion.QuatToEuler(quat.x,quat.y,quat.z,quat.w)
		rx=-mat.GetYaw() '-eul[0]
		ry=mat.GetPitch() 'eul[1]
		rz=mat.GetRoll() 'eul[2]
		
		px=pos.x
		py=pos.y
		pz=pos.z			
		
		' set mat2 to equal mat
		mat2.Overwrite(mat)
		
		' set mat - includes root parent transformation
		' mat is used for store global bone positions, needed when displaying actual bone positions and attaching entities to bones
		If parent<>Null
		
			new_mat = parent.mat.Copy()
			new_mat.Multiply(mat)
			mat.Overwrite(new_mat)
			
		Endif
		
		' set mat2 - does not include root parent transformation
		' mat2 is used to store local bone positions, and is needed for vertex deform
		If TBone(Self.parent)<>Null
		
			new_mat = TBone(parent).mat2.Copy()
			new_mat.Multiply(mat2)
			mat2.Overwrite(new_mat)
			
		Endif


		' set tform mat
		' A tform mat is needed to transform vertices, and is basically the bone mat multiplied by the inverse reference pose mat
		tform_mat.Overwrite(mat2)
		tform_mat.Multiply(inv_mat)

		' update bone children
		If TBone(Self).child_list.IsEmpty()<>True Then TEntity.UpdateChildren(Self)

	
	End
	
	Method Update(cam:TCamera=Null)
	
	End 

End 
