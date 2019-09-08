Class TUtility

	Function UpdateValue#(current#,destination#,rate#)
	
		current=current+((destination-current)*rate)
	
		Return current
	
	End 

End 

Function Dprint(x:String, y:String="", z:String="", a:String="", b:String="", c:String="")
	Local st$ = x+" "+y+" "+z+" "+a+" "+b+" "+c
	Print st
End


Function ToHex:String(i:Int)

	''p=32-bit
	Local r%=i, s%, p%=32, n:Int[p/4+1]

	While (p>0)
		
		s = (r&$f)+48
		If s>57 Then s+=7
		
		p-=4
		n[p Shr 2] = s
		r = r Shr 4
		 
	Wend

	Return String.FromChars(n)
	
End