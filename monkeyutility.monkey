''
'' helper classes and functions for monkey conversion
''

Import monkey
Import tutility
Import minib3d
Import minib3d.monkeybuffer
Import os
Import minib3d.tmodelb3d

Alias LoadString = app.LoadString

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
		
		i2f = CreateDataBuffer(4)
		
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
	'' -- doesn't work for DataBuffers *to do*
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
		
		
		If m_length=0 Then Return CreateDataBuffer(0)
		
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
		Local buf:DataBuffer = CreateDataBuffer(length)
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
	
	''shortcut for b3d loading
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

