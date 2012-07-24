''
'' helper classes and functions for monkey conversion
''
Import monkey
Import tutility
Import minib3d


#If TARGET="html5" Or TARGET="glfw" Or TARGET="mingw" Or TARGET="ios" Or TARGET="android"

Import opengl.databuffer

#elseif TARGET="xna"
	
Import xna.xna_driver.databuffer	

#endif


Const PF_RGBA8888:Int = 1
Const PF_RGB888:Int = 2
Const PF_A8:Int = 3



Function AllocateFloatArray:Float[][]( i:Int, j:Int)
    Local arr:Float[][] = New Float[i][]
    For Local ind = 0 Until i
        arr[ind] = New Float[j]
    Next
    Return arr		
End

Function AllocateIntArray:Int[][]( i:Int, j:Int)
    Local arr:Int[][] = New Int[i][]
    For Local ind = 0 Until i
        arr[ind] = New Int[j]
    Next
    Return arr		
End


''
'' helper databuffer classes
''


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
		Return Float(buf.Size())*INVSIZE
	End
	
	Function Create:VertexDataBuffer(i:Int=0)
		Local b:VertexDataBuffer = New VertexDataBuffer
		b.buf = DataBuffer.Create((i+1)*SIZE)
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

End





''CopyDataBuffer() overloaded

Function CopyDataBuffer:DataBuffer( src:DataBuffer, dest:DataBuffer )
	'Const SIZE:Int = 4
	If src = Null Then Return dest
	
	Local size:Int = src.Size()
	If dest.Size() < size Then size = dest.Size()
	
	For Local i:= 0 To size-1
		dest.PokeByte(i,src.PeekByte(i))	
	Next
	
	Return dest
End

Function CopyDataBuffer:VertexDataBuffer( src:VertexDataBuffer, dest:VertexDataBuffer )

	If src.buf = Null Then Return dest
	
	Local size:Int = src.buf.Size()
	If dest.buf.Size() < size Then size = dest.buf.Size()
	
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
	
	If begin=0 And bend=0 Then bend = src.buf.Size()-1
	If dest.buf.Size()-1 < bend Then bend = dest.buf.Size()-1

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
	
		i2f= DataBuffer.Create(4)
	
		Local b:FloatBuffer = New FloatBuffer
		b.buf = DataBuffer.Create(i*SIZE+1)
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
	
	Method Peek:Float(i:Int)
		'i =i*SIZE  
		'i2f.PokeInt(0, ((buf.PeekByte(i+3) & $000000ff) Shl 24) | ((buf.PeekByte(i+2) & $000000ff) Shl 16) | ((buf.PeekByte(i+1)& $000000ff) Shl 8) | (buf.PeekByte(i)& $000000ff) )
		'Return i2f.PeekFloat(0)

		Return buf.PeekFloat(i*SIZE)
	End
	
	Method Size:Int()
		Return buf.Size()*INVSIZE
	End
	
End

Class ShortBuffer

	Const SIZE:Int = 2
	Const INVSIZE:Float = 1.0/2.0
	
	Field buf:DataBuffer
	Global i2f:DataBuffer
	
	Function Create:ShortBuffer(i:Int=0)
		i2f= DataBuffer.Create(4)
	
		Local b:ShortBuffer = New ShortBuffer
		b.buf = DataBuffer.Create(i*SIZE+1)
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
	
	Method Size:Int()
		Return buf.Size()*INVSIZE
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
	
	If begin=0 And bend=0 Then bend = src.Size()-1
	If dest.Size()-1 < bend Then bend = dest.Size()-1

	For Local i:= begin To bend
		dest.Poke(i-begin,src.Peek(i))	
	Next
	
	Return dest
End

Function CopyFloatBuffer:FloatBuffer( src:FloatBuffer, dest:FloatBuffer )
	'Const SIZE:Int = 4

	If src = Null Or src.buf = Null Then Return dest
	
	Local size:Int = src.Size()
	If dest.Size() < size Then size = dest.Size()

	For Local i:= 0 To size-1
		dest.Poke(i,src.Peek(i))	
	Next
	
	Return dest
End

Function CopyShortBuffer:ShortBuffer( src:ShortBuffer, dest:ShortBuffer )
	'Const SIZE:Int = 2
	If src = Null Or src.buf = Null Then Return dest
	
	Local size:Int = src.Size()
	If dest.Size() < size Then size = dest.Size()
	
	For Local i:= 0 To size-1
		dest.Poke(i,src.Peek(i))	
	Next
	
	Return dest
End


''
'' base64 functions
''
'' -- using little-endian, ieee 32 bit single-precision float
''

Class Base64

	Global MIME$="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	Global Dime:Int[]
	
	Field data:DataBuffer
	Field pos:Int ''seek position
	Field size:Int=0
	Global realsize:Int=0
	
	Global i2f:DataBuffer
	
	Method New()
		
		i2f = DataBuffer.Create(4)
		
	End
	
	Method Free()
	
		data = Null
		pos = 0
		
	End
	
	Function Load:Base64(file$)
		
		Local bsf:Base64 = New Base64
			
		bsf.data = Decode(LoadString(file))
		bsf.pos = 0
		bsf.size = realsize-1
		
		Return bsf
		
	End
	
	''
	'' Encode() from skid
	'' -- doesn't work for databuffers *to do*
	''
	Function Encode$(bytes:Int[])
		Local n=bytes.Length	
		Local buffer$
		Local blank:String = ""
	
		For Local i=0 Until n Step 3	
			Local b0,b1,b2,b24
			Local pad$
			b0=bytes[i]
			If i+1<n
				b1=bytes[i+1]
				If i+2<n
					b2=bytes[i+2]
				Else
					pad="="
				Endif
			Else
				pad="=="
			Endif		
			b24=(b0 Shl 16) | (b1 Shl 8) | (b2)
			buffer.Join(String.FromChar( MIME[(b24 Shr 18)&63] ) ,blank )
			buffer.Join(String.FromChar( MIME[(b24 Shr 12)&63] ) ,blank  )
			buffer.Join(String.FromChar( MIME[(b24 Shr 6)&63] ) ,blank  )
			buffer.Join(String.FromChar( MIME[(b24)&63] ) ,blank  )
			If pad Then buffer.Join(pad, blank )	
		Next	
	
		Return buffer
	End
	
	''
	'' Decode() from skid
	''
	Function Decode:DataBuffer(mime$)
	
		If Not Dime
		
			Dime=New Int[256]
			For Local i=0 To 63
				Dime[MIME[i]]=i
			Next
			
		Endif
		
		'Local bytes:Int[]
		Local m_length=mime.Length
		Local pad, length
		Local i,p,i4
		
		realsize =0 
		
		
		If m_length=0 Then Return DataBuffer.Create(0)
		
		If mime[m_length-1]="="[0] 
			pad=1
			If mime[m_length-2]="="[0]
				pad=2
				If mime[m_length-3]="="[0]
					pad=3
				Endif
			Endif
		Endif	
		
		length=Int((m_length-pad)/4+0.5)*3 ''round up
		'bytes=New Int[length]
		Local buf:DataBuffer = DataBuffer.Create(length)
		Local bb:Int[4]
		
		While p<m_length-1
		
			bb = [0,0,0,0]
			
			''handle text breakups
			For Local j:Int=0 To 3
				
				If (p+j) >= m_length Then Exit
				
				bb[j] = mime[p+j]
				While (bb[j]<33)
					p+=1 
					If p>= m_length Then Exit

					bb[j] = mime[p+j]
				Wend
				If bb[j] > 255 Then bb[j] =0 ''handle odd memory errors
				bb[j]=Dime[ bb[j] ]
	
			Next

			Local b24:Int =(bb[0] Shl 18)|(bb[1] Shl 12)|(bb[2] Shl 6)|bb[3]		

			buf.PokeByte( i+0, (b24 Shr 16)&255)
			buf.PokeByte( i+1, (b24 Shr 8)&255)
			buf.PokeByte( i+2, (b24 )&255)
			p+=4
			i+=3
			
			realsize +=3 'bytes
		Wend	
		'If pad
			'bytes=bytes.Resize(length-pad)
		'Endif	
		
		Return buf
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
	
	Method ReadFloat:Float()
		pos += 4
		'i2f.PokeByte(0,data.PeekByte(pos-4))
		'i2f.PokeByte(1,data.PeekByte(pos-3))
		'i2f.PokeByte(2,data.PeekByte(pos-2))
		'i2f.PokeByte(3,data.PeekByte(pos-1))
		i2f.PokeInt(0, ((data.PeekByte(pos-1) & $000000ff) Shl 24) | ((data.PeekByte(pos-2)& $000000ff) Shl 16) | ((data.PeekByte(pos-3)& $000000ff) Shl 8) | (data.PeekByte(pos-4)& $000000ff) )
		Return i2f.PeekFloat(0)
	End
	
	#rem
	Method ReadTag:String()
		''readtag does not increment position
		If pos>size Then Return ""
		
		i2f.PokeByte(0,data.PeekByte(pos))
		i2f.PokeByte(1,data.PeekByte(pos+1))
		i2f.PokeByte(2,data.PeekByte(pos+2))
		i2f.PokeByte(3,data.PeekByte(pos+3))
		Local d:Int = i2f.PeekInt(0)
		'Local d:Int = data.PeekInt(pos)

		Return (String.FromChar((d  ) & $00ff)+String.FromChar((d Shr 8 )& $00ff)+
			String.FromChar((d Shr 16 )& $00ff)+String.FromChar((d Shr 24)& $00ff) )

	End
	#end
	
	Method ReadTag:Int()
		''readtag does not increment position
		If pos>size Then Return 0
		
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



