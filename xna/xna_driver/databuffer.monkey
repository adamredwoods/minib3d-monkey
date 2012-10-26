Import "native/databuffer.${LANG}"

Extern

' minib3d compatibility
' -- now using brl.databuffer (v66)

#rem
Class DataBuffer

	Method Size()

	Method Discard:Void()
	
	Method PokeByte:Void( addr,value )
	Method PokeShort:Void( addr,value )
	Method PokeInt:Void( addr,value )
	Method PokeFloat:Void( addr,value# )
	
	Method PeekByte:Int( addr )
	Method PeekShort:Int( addr )
	Method PeekInt:Int( addr )
	Method PeekFloat:Float( addr )

	Function Create:DataBuffer( size )="DataBuffer.Create"
End
#end

Function LoadImageData:DataBuffer( path$,info[]=[] )="DataBuffer.LoadImageData"

Public
