Import minib3d
Import minib3d.math.quaternion

''NOTES
'' - currently does not support bone scale animation
'' - keeping bones out of entity_list

Class TBone Extends TEntity

	Field n_px#,n_py#,n_pz#,n_sx#,n_sy#,n_sz#,n_rx#,n_ry#,n_rz#
	Field n_qw#,n_qx#,n_qy#,n_qz#

	'Field baseQuat:Quaternion = New Quaternion(0,0,0,1)'' base entity quat, to which bone chain is attached to
	'Field basePos:Vector = New Vector
	'Field chainQuat:Quaternion = New Quaternion(0,0,0,1) ''bone-chain quats
	'Field chainPos:Vector = New Vector
	'Field restQuat:Quaternion = New Quaternion(0,0,0,1) ''local quats
	'Field restPos:Vector = New Vector
	
	Field keys:TAnimationKeys
	
	' additional matrices used for animation purposes
	Field mat2:Matrix=New Matrix
	Field inv_mat:Matrix=New Matrix ' set in TModel, when loading anim mesh
	Field tform_mat:Matrix=New Matrix
	'Field base_mat:Matrix
	
	Field base_ent:TEntity
	
	Field rest_mat:Matrix = New Matrix


	Field kx#,ky#,kz#,kqw#,kqx#,kqy#,kqz# ' used to store current keyframe in AnimateMesh, for use with transition

Private
	
	Global new_mat:Matrix = New Matrix ' temp use
	Global t_quat:Quaternion = New Quaternion ' temp use

Public
	

	
	Method New()
	
	
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
		
		Self.CopyBaseBoneTo(bone,parent_ent)
		
		'*** removed bones from entity_list... how will this effect things?
		'bone.entity_link = entity_list.EntityListAdd(bone)
		bone.entity_link.Remove()
		
		Return bone
	
	End 
	
	Method CopyBaseBoneTo:Void(bone:TBone, parent_ent:TEntity=Null)
		
		Self.CopyBaseEntityTo(bone, parent_ent)

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
		
		bone.loc_mat = loc_mat.Copy()
		bone.rest_mat = rest_mat.Copy()
		
		
		'bone.baseQuat = baseQuat.Copy()
		'bone.chainQuat = chainQuat.Copy()
		'bone.chainPos = chainPos.Copy()
		'bone.basePos = basePos.Copy()
		
	End
	
		
	Method FreeEntity()
	
		Super.FreeEntity() 
	
		keys=Null
	
	End 


	Method AddBone()
		'' adds bone to end of another bone
		
	End

	' negates z value of bone matrices so that children are transformed
	' in correct z direction
	Function UpdateNonBoneChild:Void(ent_p:TEntity)
		
		If TBone(ent_p)=Null ' if child is not a bone
						
			new_mat.Overwrite(ent_p.parent.mat)
		
			' if parent is a bone, negate z value of matrix
			If TBone(ent_p)<>Null
				new_mat.grid[3][2]=-new_mat.grid[3][2]
				'mat=TBone(ent_p).tform_mat
			Endif
			
			'new_mat.Multiply(ent_p.loc_mat)
			ent_p.mat.Overwrite(new_mat)
			ent_p.UpdateMat()
			
		Endif

	End 
	
	Function UpdateBoneChildren:Void(p:TEntity)
		

		For Local ent:TEntity=Eachin p.child_list
			Local bo:TBone = TBone(ent)
			
			If bo<>Null ' if child a bone
				
				bo.UpdateMatrix(bo.loc_mat)
				
			Else

				UpdateNonBoneChild(ent)
				'UpdateChildren(ent)
			
			Endif
			
			UpdateBoneChildren(ent)
					
		Next

	End 

	
	Method PositionBone(x#,y#,z#,glob=False)

		px=x; py=y; pz=z
		
		''use rest matrix
		Local t_mat:Matrix = New Matrix
		t_mat.Overwrite(rest_mat)
		t_mat.Multiply(loc_mat)
		
		t_mat.grid[3][0] = (x+rest_mat.grid[3][0]); t_mat.grid[3][1] = (y+rest_mat.grid[3][1]); t_mat.grid[3][2] = (z+rest_mat.grid[3][2]);
		
		
		'loc_mat.Overwrite(t_mat) 'retain new local mat
	
		'If Not glob Then UpdateMatrix(t_mat) Else UpdateMatrixGlobal(t_mat, 0, [x,y,z])
		UpdateMatrix(t_mat)
		
		
		If TBone(Self).child_list.IsEmpty()<>True Then UpdateBoneChildren(Self)


	End
	
	
	Method RotateBone(x#,y#,z#,glob=False)
		
		'' pitch is flipped
		rx=-x; ry=y; rz=z
		
		''use rest matrix
		Local t_mat:Matrix = New Matrix
		t_mat.Overwrite(rest_mat)
		t_mat.grid[3][0] = (px+rest_mat.grid[3][0]); t_mat.grid[3][1] = (py+rest_mat.grid[3][1]); t_mat.grid[3][2] = (pz+rest_mat.grid[3][2]);
		
		t_mat.Rotate(x,y,z)
		
		'loc_mat.Overwrite(t_mat) 'retain new local mat

		
		'If Not glob Then UpdateMatrix(t_mat) Else UpdateMatrixGlobal(t_mat, 1, t_mat.ToArray() )
		UpdateMatrix(t_mat)
		
		
		If TBone(Self).child_list.IsEmpty()<>True Then UpdateBoneChildren(Self)

	End
	
	
	Method ScaleBone(x#,y#,z#,glob=False)

		sx=x; sy=y; sz=z
		
		''use rest matrix
		Local t_mat:Matrix = New Matrix
		t_mat.Overwrite(rest_mat)
		't_mat.Multiply(loc_mat)
		
		t_mat.grid[3][0] = (px+rest_mat.grid[3][0]); t_mat.grid[3][1] = (py+rest_mat.grid[3][1]); t_mat.grid[3][2] = (pz+rest_mat.grid[3][2]);
		t_mat.Rotate(rx,ry,rz)	
		t_mat.Scale(x,y,z)	
		'loc_mat.Overwrite(t_mat) 'retain new local mat

		
		'If Not glob
			UpdateMatrix(t_mat)
		'Else
			'UpdateMatrixGlobal(t_mat, 3, [x,y,z])
		'Endif
		
		gsx=parent.gsx*sx
		gsy=parent.gsy*sy
		gsz=parent.gsz*sz
		
		If TBone(Self).child_list.IsEmpty()<>True Then UpdateBoneChildren(Self)


	End
	
	
#rem	
	''doesnt work
	
	
	Method TransformQuat:Void(pos:Vector, quat:Quaternion)
		
		''local transform
		qx = quat.x; qy = quat.y; qz = quat.z; qw = quat.w
		px = pos.x; py = pos.y; pz = pos.z
		
		
		chainQuat.Overwrite(quat)
		chainPos.Overwrite(pos)
		
		
		If TBone(parent)<>Null

			''parent bone is another bone
			baseQuat = TBone(parent).baseQuat
			basePos = TBone(parent).basePos

			chainQuat = TBone(parent).chainQuat.Multiply(quat)
			'chainQuat = quat.Multiply(TBone(parent).chainQuat)
			'chainPos.Overwrite( TBone(parent).chainPos.x +px, TBone(parent).chainPos.y +py, TBone(parent).chainPos.z +pz)
			chainPos.Overwrite(TBone(parent).chainQuat.Multiply(pos))
			chainPos.Overwrite(chainPos.x+TBone(parent).chainPos.x, chainPos.y+TBone(parent).chainPos.y, chainPos.z+TBone(parent).chainPos.z)
			'chainPos.Overwrite(chainQuat.Multiply(pos))
			
		Elseif parent<>Null
			'' otherwise, current bone is base. update the base bone chain quat
	
			Quaternion.MatrixToQuat(parent.mat, t_quat)
			baseQuat = t_quat.Normalize().Copy()
			basePos.Overwrite(parent.mat.grid[3][0],parent.mat.grid[3][1],parent.mat.grid[3][2])
			
			'chainPos.Overwrite(quat.Multiply(pos))
			
		Else
			''floating base bone in space
			chainQuat = quat.Copy()
			baseQuat = quat.Copy()
			basePos = pos.Copy()
			chainPos = pos.Copy()
		Endif
		
		If Not baseQuat Then Print "**bone no baseQuat"
		'If Not baseQuat Then baseQuat = GetBaseQuat; Print "**bone no baseQuat"
		
		''tform_mat
		
		Quaternion.QuatToMatrix(chainQuat.x, chainQuat.y, chainQuat.z, chainQuat.w, tform_mat)	
		'tform_mat.Multiply(inv_mat)
		'tform_mat.Translate(chainPos.x,chainPos.y,chainPos.z)
		tform_mat.grid[3][0] = chainPos.x; tform_mat.grid[3][1] = chainPos.y; tform_mat.grid[3][2] = chainPos.z
		'tform_mat.Scale(sx, sy, sz)
		
		
		''update children
		'If TBone(Self).child_list.IsEmpty()<>True Then TEntity.UpdateChildren(Self)
		
	End
	
	
	''get base quat if something wrong happened in the bone building or needs reset
	Method GetBaseQuat:Quaternion()
		
		Local ent:TEntity
		
		''find parent with basequat, or if not bone, grab from matrix
		
	End
	
	Method UpdateBoneMat:Void()
		
		t_quat.Overwrite(qx,qy,qz,qw)
		
		If TBone(parent)<>Null
			'baseQuat = TBone(parent).baseQuat
			'chainQuat = t_quat.Multiply(TBone(parent).chainQuat)
			chainQuat = TBone(parent).chainQuat.Multiply(t_quat)
			chainPos.Overwrite( TBone(parent).chainPos.x +px, TBone(parent).chainPos.y +py, TBone(parent).chainPos.z +pz)
		Endif
		
		Quaternion.QuatToMatrix(chainQuat.x,chainQuat.y,chainQuat.z,chainQuat.w, tform_mat)
		'tform_mat.Translate(px,py,pz)
		tform_mat.grid[3][0] = chainPos.x; tform_mat.grid[3][1] = chainPos.y; tform_mat.grid[3][2] = chainPos.z
		'tform_mat.Scale(sx, sy, sz)
	End
#end	
	
	''
	'' This transform function creates a local transform matrix, and updates bones
	'' it is used usually for ALL bones in keyframe animation, so individual bone updates are not needed but entities need to be
	''
	Method Transform:Void(pos:Vector, quat:Quaternion, update_children:Bool=True)
		
		Quaternion.QuatToMatrix(quat.x,quat.y,quat.z,quat.w, new_mat)
		
		new_mat.grid[3][0]=pos.x
		new_mat.grid[3][1]=pos.y
		new_mat.grid[3][2]=pos.z
		'new_mat.Translate(pos.x,pos.y,pos.z)
		
		px=pos.x
		py=pos.y
		pz=pos.z


		' store local position/rotation values. will be needed to maintain bone positions when positionentity etc is called
		'Local eul:Float[] = Quaternion.QuatToEuler(quat.x,quat.y,quat.z,quat.w)
		Local mx# = new_mat.grid[2][0]
		Local my# = new_mat.grid[2][1]
		Local mz# = new_mat.grid[2][2]
		rx=-ATan2( mx,mz ) '-eul[0]
		ry=-ATan2( my, Sqrt( mx*mx+mz*mz ) ) 'eul[1]
		rz=ATan2( new_mat.grid[0][1],new_mat.grid[1][1] )


		UpdateMatrix(new_mat)
		
		
		' update children
		If update_children
			If TBone(Self).child_list.IsEmpty()<>True Then TEntity.UpdateChildren(Self)
		Endif
		
	End		
	
	''
	'' mat0 needs to be a local matrix
	Method UpdateMatrix:Void(mat0:Matrix)
	
		' set mat2 to equal mat
		loc_mat.Overwrite(mat0)
		mat2.Overwrite(loc_mat)
		
		' set mat - includes root parent transformation
		' mat is used for store global bone positions, needed when displaying actual bone positions and attaching entities to bones
		If parent<>Null
		
			mat.Overwrite(parent.mat)
			mat.Multiply(loc_mat)
			

			gsx=parent.gsx*sx
			gsy=parent.gsy*sy
			gsz=parent.gsz*sz

		Endif
		
		' set mat2 - does not include root parent transformation
		' mat2 is used to store local bone positions (in the chain), and is needed for vertex deform
		If TBone(Self.parent)<>Null
		
			new_mat.Overwrite(TBone(parent).mat2)
			new_mat.Multiply(loc_mat)
			mat2.Overwrite(new_mat)	
						
		Endif


		' set tform mat
		' A tform mat is needed to transform vertices, and is basically the bone mat multiplied by the inverse reference pose mat
		tform_mat.Overwrite(mat2)
		tform_mat.Multiply(inv_mat)

	End
	

	
	Method Update(cam:TCamera=Null)
	
	End 

End 
