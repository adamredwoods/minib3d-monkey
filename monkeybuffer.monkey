''
'' monkey buffer loading and helper functions
''

Import mojo.data
Import minib3d.math.vector

#If TARGET="html5" Or TARGET="glfw" Or TARGET="mingw" Or TARGET="ios" Or TARGET="android"

	'Import brl.databuffer
	Import opengl.databuffer

	Function CreateDataBuffer:DataBuffer(i:Int)
		Return DataBuffer.Create(i)
	End
	Function GetBufferLength:Int(buf:DataBuffer)
		Return buf.Size()
	End
#rem	
	Class DataBuffer Extends DataBuffer

		Function Create:DataBuffer(i:Int)
			Return DataBuffer(DataBuffer.Create(i))
		End
		Method Length:Int()
			Return Size()
		End
	End
#end

#elseif TARGET="xna"
	
	'Import xna.xna_driver.databuffer	
	Import brl.databuffer
	
	Function CreateDataBuffer:DataBuffer(i:Int)
		Return New DataBuffer(i)
	End
	Function GetBufferLength:Int(buf:DataBuffer)
		Return buf.Length()
	End
	
#endif




''
'' helper databuffer classes
''

Class Vertex
	
	Field x#, y#, z#
	Field r#,g#,b#,a#
	Field nx#,ny#,nz#
	Field u0#,v0#,u1#,v1#
	Field w0#=0.0, w1#=0.0
	
	Method GetVertex:Void(vid:Int, src:VertexDataBuffer)

		Local data:Float[] = src.GetFloatArray(vid)
		x = data[0]; y=data[1]; z=data[2] 'data[3]=null
		nx=data[4];ny=data[5];nz=data[6] 'data[7]=null
		r=data[8];g=data[9];b=data[10];a=data[11]
		u0=data[12];v0=data[13];u1=data[14];v1=data[15]
		
	End

End


Function GetVertex:Vertex(vid:Int, src:VertexDataBuffer)
	Local v:Vertex = New Vertex
	v.GetVertex(vid,src)
	Return v
End


Class VertexDataBuffer
	
	Const SIZE:Int			= 64
	Const INVSIZE:Float		= 1.0/64.0
	
	Const POS_OFFSET:Int 		= 0
	Const NORMAL_OFFSET:Int 	= 16
	Const COLOR_OFFSET:Int 		= 32
	Const TEXCOORDS_OFFSET:Int 	= 48

	Const ELEMENT0:Int = 0
	Const ELEMENT1:Int = 4
	Const ELEMENT2:Int = 8
	Const ELEMENT3:Int = 12
	
	Field buf:DataBuffer
	
	Method Size:Int()
		Return Float(GetBufferLength(buf))*INVSIZE
	End
	
	Function Create:VertexDataBuffer(i:Int=0)
		Local b:VertexDataBuffer = New VertexDataBuffer
		b.buf = CreateDataBuffer((i+1)*SIZE)
		Return b
	End
	
	Method PokeVertCoords(i:Int,x#,y#,z#)
		Local index = i*SIZE+POS_OFFSET
		buf.PokeFloat(index,x )
		buf.PokeFloat(index+ELEMENT1,y )
		buf.PokeFloat(index+ELEMENT2,z )
	End
	
	Method PokeNormals(i:Int,x#,y#,z#)
		Local index = i*SIZE+NORMAL_OFFSET
		buf.PokeFloat(index,x )
		buf.PokeFloat(index+ELEMENT1,y )
		buf.PokeFloat(index+ELEMENT2,z )
	End
	
	Method PokeTexCoords(i:Int,s0#,t0#, s1#, t1#)
		Local index = i*SIZE+TEXCOORDS_OFFSET
		buf.PokeFloat(index,s0 )
		buf.PokeFloat(index+ELEMENT1,t0 )
		buf.PokeFloat(index+ELEMENT2,s1 )
		buf.PokeFloat(index+ELEMENT3,t1 )
	End
	
	Method PokeTexCoords0(i:Int,s0#,t0#)
		Local index = i*SIZE+TEXCOORDS_OFFSET
		buf.PokeFloat(index,s0 )
		buf.PokeFloat(index+ELEMENT1,t0 )
	End
	
	Method PokeTexCoords1(i:Int,s1#, t1#)
		Local index = i*SIZE+TEXCOORDS_OFFSET
		buf.PokeFloat(index+ELEMENT2,s1 )
		buf.PokeFloat(index+ELEMENT3,t1 )
	End
	
	Method PokeColor(i:Int, r#,g#,b#, a#)
		Local index = i*SIZE+COLOR_OFFSET
		buf.PokeFloat(index,r)
		buf.PokeFloat(index+ELEMENT1,g)
		buf.PokeFloat(index+ELEMENT2,b)
		buf.PokeFloat(index+ELEMENT3,a)
	End
	
	Method VertexX#(vid:Int)
		Return buf.PeekFloat(vid*SIZE+POS_OFFSET + ELEMENT0 )
	End 

	Method VertexY#(vid:Int)
		Return buf.PeekFloat(vid*SIZE+POS_OFFSET + ELEMENT1 )
	End 
	
	Method VertexZ#(vid:Int)
		Return buf.PeekFloat(vid*SIZE+POS_OFFSET + ELEMENT2 )
	End 
	
	Method PeekVertCoords:Vector(vid:Int)
		Local v:Int = vid*SIZE+POS_OFFSET
		Return New Vector(buf.PeekFloat(v + ELEMENT0 ),buf.PeekFloat(v + ELEMENT1 ),buf.PeekFloat(v + ELEMENT2 ))
	End
	
	Method GetVertCoords:Void(vec:Vector, vid:Int)
		Local v:Int = vid*SIZE+POS_OFFSET
		vec.x = buf.PeekFloat(v + ELEMENT0 ); vec.y = buf.PeekFloat(v + ELEMENT1 ); vec.z = buf.PeekFloat(v + ELEMENT2 )
	End
	
	Method VertexRed#(vid:Int)
		Return buf.PeekFloat(vid*SIZE+COLOR_OFFSET + ELEMENT0 )
	End
	
	Method VertexGreen#(vid:Int)
		Return buf.PeekFloat(vid*SIZE+COLOR_OFFSET + ELEMENT1 )
	End 
	
	Method VertexBlue#(vid:Int)
		Return buf.PeekFloat(vid*SIZE+COLOR_OFFSET + ELEMENT2 )
	End Method
	
	Method VertexAlpha#(vid:Int)
		Return buf.PeekFloat(vid*SIZE+COLOR_OFFSET + ELEMENT3 )
	End 
	
	Method VertexNX#(vid:Int)
		Return buf.PeekFloat(vid*SIZE+NORMAL_OFFSET + ELEMENT0 )
	End 
	
	Method VertexNY#(vid:Int)
		Return buf.PeekFloat(vid*SIZE+NORMAL_OFFSET + ELEMENT1 )
	End 
	
	Method VertexNZ#(vid:Int)
		Return buf.PeekFloat(vid*SIZE+NORMAL_OFFSET + ELEMENT2 )
	End 
	
	Method VertexU#(vid:Int ,coord_set=0)
		If coord_set=0 Then Return buf.PeekFloat(vid*SIZE+TEXCOORDS_OFFSET + ELEMENT0 )
		If coord_set=1 Then Return buf.PeekFloat(vid*SIZE+TEXCOORDS_OFFSET + ELEMENT2 )
	End 
	
	Method VertexV#(vid:Int,coord_set=0)
		If coord_set=0 Then Return buf.PeekFloat(vid*SIZE+TEXCOORDS_OFFSET + ELEMENT1 )
		If coord_set=1 Then Return buf.PeekFloat(vid*SIZE+TEXCOORDS_OFFSET + ELEMENT3 )
	End 
	
	Method GetFloatArray:Float[](vid:Int)
	
		Local data:Float[Int(SIZE/4)], j:Int=0
		For Local i:Int=0 To SIZE-1 Step 4
			data[j] = buf.PeekFloat(vid*SIZE+i)
			j+=1
		Next
		
		Return data
	End
	
End





''CopyDataBuffer() overloaded

Function CopyDataBuffer:DataBuffer( src:DataBuffer, dest:DataBuffer )
	'Const SIZE:Int = 4
	If src = Null Then Return dest
	
	Local size:Int = GetBufferLength(src)
	If GetBufferLength(dest) < size Then size = GetBufferLength(dest)
	
	For Local i:= 0 To size-1
		dest.PokeByte(i,src.PeekByte(i))	
	Next
	
	Return dest
End

Function CopyDataBuffer:VertexDataBuffer( src:VertexDataBuffer, dest:VertexDataBuffer )

	If src.buf = Null Then Return dest
	
	Local size:Int = GetBufferLength(src.buf)
	If GetBufferLength(dest.buf) < size Then size = GetBufferLength(dest.buf)
	
	'' step 4 (2 times) is ok since VertexDataBuffer is always multiple of 4
	For Local i:= 0 To size-1 Step 8
		dest.buf.PokeInt(i,src.buf.PeekInt(i))
		dest.buf.PokeInt(i+4,src.buf.PeekInt(i+4))	
	Next
	
	Return dest
End

Function CopyDataBuffer:VertexDataBuffer( src:VertexDataBuffer, dest:VertexDataBuffer, begin:Int=0, bend:Int=0 )
	
	If src.buf = Null Then Return dest
	
	begin *= VertexDataBuffer.SIZE
	bend *= VertexDataBuffer.SIZE
	
	If begin=0 And bend=0 Then bend = GetBufferLength(src.buf)-1
	If GetBufferLength(dest.buf)-1 < bend Then bend = GetBufferLength(dest.buf)-1

	For Local i:= begin To bend Step 4
		'dest.buf.PokeByte(i,src.buf.PeekByte(i))
		dest.buf.PokeInt(i,src.buf.PeekInt(i))	
	Next
	
	Return dest
End





Class FloatBuffer

	Const SIZE:Int = 4
	Const INVSIZE:Float = 1.0/4.0
	
	Field buf:DataBuffer
	Global i2f:DataBuffer
	
	Function Create:FloatBuffer(i:Int=0)
	
		i2f= CreateDataBuffer(4)
	
		Local b:FloatBuffer = New FloatBuffer
		b.buf = CreateDataBuffer(i*SIZE+1)
		Return b
		
	End
	
	Method Poke:Void(i:Int,v:Float)
		'i =i*SIZE
		'i2f.PokeFloat(0,v)
		'buf.PokeByte(i+0,(i2f.PeekByte(0) & $000000ff))
		'buf.PokeByte(i+1,(i2f.PeekByte(1) & $000000ff) )
		'buf.PokeByte(i+2,(i2f.PeekByte(2) & $000000ff) )
		'buf.PokeByte(i+3,(i2f.PeekByte(3) & $000000ff) )
		
		buf.PokeFloat(i*SIZE,v)
	End
	
	Method PokeVertCoords:Void(i:Int,v0:Float, v1:Float, v2:Float)
		
		buf.PokeFloat(i*12,v0)
		buf.PokeFloat((i)*12+4,v1)
		buf.PokeFloat((i)*12+8,v2)
		
	End
	
	Method PeekVertCoords:Vector(i:Int)
		
		Return New Vector(buf.PeekFloat(i*12), buf.PeekFloat((i)*12+4), buf.PeekFloat((i)*12+8))
		
	End
	
	Method Peek:Float(i:Int)
		'i =i*SIZE  
		'i2f.PokeInt(0, ((buf.PeekByte(i+3) & $000000ff) Shl 24) | ((buf.PeekByte(i+2) & $000000ff) Shl 16) | ((buf.PeekByte(i+1)& $000000ff) Shl 8) | (buf.PeekByte(i)& $000000ff) )
		'Return i2f.PeekFloat(0)

		Return buf.PeekFloat(i*SIZE)
	End
	
	Method Length:Int()
		Return buf.Length()*INVSIZE
	End
	
End

Class ShortBuffer

	Const SIZE:Int = 2
	Const INVSIZE:Float = 1.0/2.0
	
	Field buf:DataBuffer
	Global i2f:DataBuffer
	
	Function Create:ShortBuffer(i:Int=0)
		i2f= CreateDataBuffer(4)
	
		Local b:ShortBuffer = New ShortBuffer
		b.buf = CreateDataBuffer(i*SIZE+1)
		Return b
	End
	
	Method Poke:Void(i:Int,v:Int)
		'i =i*SIZE
		'i2f.PokeShort(0,v)
		'buf.PokeByte(i+0,(i2f.PeekByte(0) & $000000ff))
		'buf.PokeByte(i+1,(i2f.PeekByte(1) & $000000ff) )
		
		buf.PokeShort(i*SIZE,v)
	End
	
	Method Peek:Int(i:Int)
		'i =i*SIZE  
		'i2f.PokeShort(0, ( ((buf.PeekByte(i+1)& $000000ff) Shl 8) | (buf.PeekByte(i)& $000000ff) ))
		'Return i2f.PeekShort(0)
	
		Return buf.PeekShort(i*SIZE)
	End
	
	Method Length:Int()
		Return GetBufferLength(buf)*INVSIZE
	End
	
End




''
'' helper databuffer functions: copy a buffer and return the destination buffer
''

''copies limited area of a buffer
'' begin, end, are in byte offsets
Function CopyFloatBuffer:FloatBuffer( src:FloatBuffer, dest:FloatBuffer, begin:Int=0, bend:Int=0 )
	'Const SIZE:Int = 4
	If src = Null Then Return dest
	
	If begin=0 And bend=0 Then bend = src.Length()-1
	If dest.Length()-1 < bend Then bend = dest.Length()-1

	For Local i:= begin To bend
		dest.Poke(i-begin,src.Peek(i))	
	Next
	
	Return dest
End

Function CopyFloatBuffer:FloatBuffer( src:FloatBuffer, dest:FloatBuffer )
	'Const SIZE:Int = 4

	If src = Null Or src.buf = Null Then Return dest
	
	Local size:Int = src.Length()
	If dest.Length() < size Then size = dest.Length()

	For Local i:= 0 To size-1
		dest.Poke(i,src.Peek(i))	
	Next
	
	Return dest
End

Function CopyShortBuffer:ShortBuffer( src:ShortBuffer, dest:ShortBuffer )
	'Const SIZE:Int = 2
	If src = Null Or src.buf = Null Then Return dest
	
	Local size:Int = src.Length()
	If dest.Length() < size Then size = dest.Length()
	
	For Local i:= 0 To size-1
		dest.Poke(i,src.Peek(i))	
	Next
	
	Return dest
End





Class BufferReader
	
	Field data:DataBuffer
	Field pos:Int ''seek position
	Field size:Int=0
	
	Global i2f:DataBuffer

	Method New()

		i2f = CreateDataBuffer(4)

	End
	
	Function Create:BufferReader( d:DataBuffer )
	
		Local br:BufferReader = New BufferReader
		br.data = d
		br.size = GetBufferLength(d)-1
		br.pos = 0
		Return br
		
	End
	
	Method Size:Int()
		Return size
	End

	Method ReadByte:Int()
		pos += 1
		Return data.PeekByte(pos-1)
	End

	''Endianness is different for targets, so use PeekInt()
	Method ReadInt:Int()
		pos += 4
		'i2f.PokeByte(0,data.PeekByte(pos-4))
		'i2f.PokeByte(1,data.PeekByte(pos-3))
		'i2f.PokeByte(2,data.PeekByte(pos-2))
		'i2f.PokeByte(3,data.PeekByte(pos-1))
		Return ((data.PeekByte(pos-1) & $000000ff) Shl 24) | ((data.PeekByte(pos-2)& $000000ff) Shl 16) | ((data.PeekByte(pos-3)& $000000ff) Shl 8) | (data.PeekByte(pos-4)& $000000ff)
		'i2f.PokeInt(0, v)
		'Return i2f.PeekInt(0)
	End
	
	''reads across 4-byte alignment, important!
	Method ReadFloat:Float()
		pos += 4
		'i2f.PokeByte(0,data.PeekByte(pos-4))
		'i2f.PokeByte(1,data.PeekByte(pos-3))
		'i2f.PokeByte(2,data.PeekByte(pos-2))
		'i2f.PokeByte(3,data.PeekByte(pos-1))
		i2f.PokeInt(0, ((data.PeekByte(pos-1) & $000000ff) Shl 24) | ((data.PeekByte(pos-2)& $000000ff) Shl 16) | ((data.PeekByte(pos-3)& $000000ff) Shl 8) | (data.PeekByte(pos-4)& $000000ff) )
		Return i2f.PeekFloat(0)
	End

	''shortcut for b3d, loads a 4-byte "tag", does not increment position
	Method ReadTag:Int()

		If pos+3>size Then Return 0
		Return ((data.PeekByte(pos+3) Shl 24) | (data.PeekByte(pos+2) Shl 16) | (data.PeekByte(pos+1) Shl 8) | (data.PeekByte(pos)))

	End

	Method Position:Int()
		Return pos
	End

	Method SetPosition(p:Int)
		pos = p
	End


	Method Eof:Bool()
		If pos >= size Then Return True Else Return False
	End

End





#rem

''
''
'' ***** Buffer Loaders ******
''
''

Class TLoadCounter Implements IOnLoadDataComplete
	Field preloader:TBufferPreloader
	Field buffer_preload:DataBuffer
	
	Method New(m:TBufferPreloader)
		preloader = m
	End
	
	Method OnLoadDataComplete:Void(data:DataBuffer, path:String, source:IAsyncEventSource)
		
		preloader.loaded += 1
		buffer_preload = data

'Print "async complete "+manager.loaded	
		preloader.CheckAllLoaded()
		If data=Null Then Print"** AsyncLoad not found: "+path
		
	End
	
	Method SetBuffer:Void(data:DataBuffer)
		preloader.loaded += 1
		preloader.CheckAllLoaded()
		buffer_preload = data
		
		If data=Null Then Print"** AsyncLoad Buffer Null"
		
	End
End



Class TBufferPreloader 
	
	Field loading:Bool = False, loaded:Int = 0, total:Int =0
	Field old_file:String[1]
	Field cur_file:Int=0
	'Field pixmap_preload:DataBuffer[]
	Field async_counter:TLoadCounter[]
	

	Method CheckEnd()
		
		If loaded = total Then loading = False
		
	End
	
	Method GetBufferFromIndex:DataBuffer(id:Int)
		Return async_counter[id].buffer_preload
	End

	Method PreLoadBuffer:Int(file$[])
		
		'' update async routines
		UpdateAsyncEvents()
'Print "loading "+Int(loading)+" "+old_file[0]+"="+file[0]		
		If file[0] <> old_file[0]
		
			loaded = 0
			cur_file = -1
			loading = True
			total = file.Length()
			async_counter = New TLoadCounter[total]
			
			old_file = file
			
		Elseif ((Not loading) And (file[0] = old_file[0]))
			Return 1
		Endif
		
		If cur_file >= total-1 Then Return 0
		If loading Then cur_file +=1	

'Print "curfile "+cur_file		

		async_counter[cur_file] = New TLoadCounter(Self)
		
		''make sure the paths are correct
		Local new_file$ = FixDataPath(file[cur_file])
		'If Not new_file.StartsWith("monkey://") Then new_file = "monkey://data/"+new_file
		
		(New AsyncDataLoader(new_file, async_counter[cur_file])).Start()

		
		Return 0
	
	End
	
	'' GetDataBuffer(file)
	'' -- takes a fiile string, returns a DataBuffer if one found from async preloader, otherwise loads immediately
	Method GetDataBuffer:DataBuffer(file$)
		
		Local buf:DataBuffer
		
		If loaded = 0
	
			'LoadImageData( p.pixels, file,info )
			buf = DataBuffer.Load(FixDataPath(file))
					
		Else

			For Local i:Int=0 To total-1
				If file = old_file[i] Then buf = GetBufferFromIndex(i) ; Print "yes preload"
			Next

			If Not buf
				buf = DataBuffer.Load(FixDataPath(file))
				'p.pixels = New DataBuffer()
				'LoadImageData(p.pixels,FixDataPath(file),info) 'DataBuffer.Load(FixDataPath(file)); Print "no preload"
				'xx=1
			Endif
			
		Endif
		
		Return buf
		
	End
	
End

#end

