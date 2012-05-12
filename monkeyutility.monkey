''
'' helper classes and functions for monkey conversion
''
Import monkey
Import opengl.databuffer
Import tutility
Import minib3d


Const PF_RGBA8888:Int = 1
Const PF_RGB888:Int = 2
Const PF_A8:Int = 3



Extern

#if TARGET = "glfw" Or TARGET = "mingw" Or TARGET = "ios"
	Function RestoreMojo2D() = "app->GraphicsDevice()->BeginRender();//"
#elseif TARGET = "android"
	Function RestoreMojo2D() = "MonkeyGame.app.GraphicsDevice().Flush(); MonkeyGame.app.GraphicsDevice().BeginRender( (GL10) null );//"
#end

Public


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

Function CopyDataBuffer:DataBuffer( src:DataBuffer, dest:DataBuffer )
	'Const SIZE:Int = 4
	If src = Null Then Return DataBuffer.Create(0)
	
	Local size:Int = src.Size()
	If dest.Size() < size Then size = dest.Size()
	
	For Local i:= 0 To size-1
		dest.PokeByte(i,src.PeekByte(i))	
	Next
	
	Return dest
End

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



