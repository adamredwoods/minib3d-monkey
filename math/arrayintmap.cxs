
Class ArrayIntMap<T>
	
	Field data:T[]
	Field length:Int
	
	Method New()
		data = New T[32]
		length = 31
	End
	
	Method Length:Int()
		Return length+1
	End
	
	Method Clear:Void()
		data = New T[32]
		length = 31
	End

	Method Get:T(id:Int)
		If id<length Then Return data[id]
	End
	
	Method Set:Void(id:Int, obj:T)
		While id>=length
			length = length+32
			data = data.Resize(length+1)
		Wend
		data[id] = obj
	End
End
