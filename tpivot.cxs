Import tentity

Class TPivot Extends TEntity

	Method New()

	
	End Method
	

	Method CopyEntity:TEntity(parent_ent:TEntity=Null)

		' new piv
		Local piv:TPivot=New TPivot
		
		Self.CopyBaseEntityTo(piv,parent_ent)
		
		Return piv

	End Method
	
	Method FreeEntity()
	
		Super.FreeEntity() 
			
	End Method
	
	Function CreatePivot:TPivot(parent_ent:TEntity=Null)

		Local piv:TPivot=New TPivot
		piv.classname="Pivot"
		
		piv.AddParent(parent_ent)
		piv.entity_link = entity_list.EntityListAdd(piv)

		' update matrix
		If piv.parent<>Null
			piv.mat.Overwrite(piv.parent.mat)
			piv.UpdateMat()
		Else
			piv.UpdateMat(True)
		Endif

		Return piv

	End 
		
	Method Update(cam:TCamera)

	End 

End 
