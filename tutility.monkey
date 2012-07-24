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