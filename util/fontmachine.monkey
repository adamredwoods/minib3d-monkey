Import minib3d.util.mojo

'summary: This constant contains the library version
Const Version:String = "12.04.22-A"

'summary: This constant contains the library name
Const Name:String = "FontMachine"

#rem
footer:This FontMachine library is released under the MIT license:
[quote]Copyright (c) 2011 Manel Ib��ez

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
[/quote]

Additionally, this is the module changelog:
[quote]Version 12.04.22-A
[list]
[*]Fixed a bug that was ignoring last character when calculating the metrics of a string, and the last character was a SPACE character.
[*]Fixed a broke link in the FontMachine interface documentation.
[*]Added a module signature file so the module can be automatically updated from Jungle Ide.
[/list]Version 12.02.17-A
[list]
[quote]Version 12.02.20-A
[list]
[*]Fixed an small bug regarding Font interface consitency. Text width should be Float intead of Int.
[/list]Version 12.02.17-A
[list]
[*]Fixed an small aligment bug on multiline strings rendering
[/list]
Version 12.02.16-A
[list]
[*]Implemented several optimizations on text drawing routines, so they generate less garbage. (thanks to sgg for the suggestion and code samples)
[*]Implemented a new method on the BitmapFont class called Charcount and returns the number of BitMapChar objects contained available in a given font, so you can iterate throug them properly.
[*]Fixed an issue that was making the whole library to cause a crash when a GetInfo command was performed on a null BitMapChar.
[/list]
Version 12.02.15-B
[list]
[*]Implemented a Kerning property for all bitmap fonts. X and Y values will define additional horizontal and vertical font kerning
[*]Implemented a GetTxtHeight function that returns the height of a given string, in graphic units, taking into account multiline strings
[*]Improved the GetTxtWidth command in a way that it now handles properly multiline strings
[*]B Version: Fixed some small issues on text size calculation
[/list]
Version 12.01.27-A
[list]
[*]Fixed a compatibility issue with the Font interface
[/list]
Version 12.01.25-A
[list]
[*]Implemented the aligment flags on draw operations
[*]Fixed a syntax error in several GetInfo methods for the bitmapfont class
[*]Fixed an incompatibility with the latest Monkey compiler, due to abstract identifier inside the Font interface
[*]Addeed the aligment enumerator-like class
[*]Optimization of the DrawText command on Java based targets, such as Android (Thanks to SGG at [a JungleIde.com]Jungle Ide[/a] for this one!)
[/list]
Version 11.08.03-A
[list]
[*]Implemented single texture fonts support
[*]Optimized fonts loading time
[*]Reduced slightly memory used by each Font instance
[/list]
[/quote]

#end


'summary: This class represents a simple X and Y vector
Class DrawingPoint
	'summary: This field contains the X location of this point.
	Field x:Float
	'summary: This field contains the Y location of this point.
	Field y:Float
	'summary: This method returns a string with a representation of the vector contents.
	Method DebugString:String() ; Return "(" + x + ", " + y + ")" ;	End
End

#rem
	summary: This class contains the math representation of a rectangle.
#end
Class DrawingRectangle 
	'summary: This field contains the X location of this point.
	Field x:Float
	'summary: This field contains the Y location of this point.
	Field y:Float
	'summary: This is the width representation of the DrawingRectangle class
	Field width:Int
	'summary: This is the height representation of the DrawingRectangle class
	Field height:Int
	'summary: This method returns a string with a representation of the rectangle coordinates.
	Method DebugString:String() ; Return "(" + x + ", " + y + ", " + width + ", " + height +  ")" ;	End
End Class 

#rem
	summary:This is the BitmapCharMetrics class used to store character size and spacing information.
#end
Class BitMapCharMetrics
	'summary: This drawing point contains the X and Y corrdinates of the character drawing offset.
	Field drawingOffset:= new DrawingPoint
	'summary: This drawing point contains the Width and Height information of the character when it's drawn in the canvas.
	Field drawingSize:= new DrawingPoint
	'summary:This integer contains the character spacing to the next character.
	Field drawingWidth:Float
	'summary:This method returns a string representation of this class instance contents.
	Method DebugString:String()
		Return "Position " + drawingOffset.DebugString() + " Size: " + drawingSize.DebugString + " Drawing width: " + drawingWidth
	End
End 


'summary: This class is used internally to represent the rendering phase when drawing text to the graphics canvas.
Class eDrawMode abstract
	'summary: this conts indicates the font face layer
	Const FACE:Int = 0
	'summary: this conts indicates the font border layer
	Const BORDER:Int = 1
	'summary: this conts indicates the font shadow layer
	Const SHADOW:Int = 2
End

#rem
	summary: This class represents a font character.
	This class represents a font character and provides methods to load and unload the character images on dynamic fonts, and provide methods to get the location of the char in the packed texture on packed fonts.
	Any character in any font, is an instance of this class.
	Beaware that this font represent a character layer. That is, each character is a Face character, a Border character or a Shadow character.
#end
Class BitMapChar 
	'summary: This field contains the drawing metrics information of the character. That is, width, height, space to next character, etc.
	Field drawingMetrics:= new BitMapCharMetrics
	'summary: This field contains the character image on dynamic fonts.
	Field image:B2DImage
	'summary: This field contains the texture index on packed fonts. (advanced use)
	Field packedFontIndex:int
	'summary: This field contains the X and Y offset of the character in the packed texture, on non dynamic fonts.
	field packedPosition:DrawingPoint = new DrawingPoint
	'summary: This field contains the width and height offset of the character in the packed texture, on non dynamic fonts.
	Field packedSize:DrawingPoint = new DrawingPoint
	
	'summary: This method will force a dynamic font to load the character image to VRam.
	Method LoadCharImage()
		'if imageResourceName = null Then return
		if CharImageLoaded() = false then
			image = B2DLoadImage(imageResourceName)
			image.SetHandle(-self.drawingMetrics.drawingOffset.x,-self.drawingMetrics.drawingOffset.y)
			imageResourceNameBackup = imageResourceName
			imageResourceName = ""
		endif
	End Method
	#rem
		summary: This method will return true or false if the character image has been loaded to VRam on dynamic fonts.
		Notice that this method will return always FALSE for packed fonts.
	#end
	Method CharImageLoaded:Bool()
		if image = null And imageResourceName <> "" then Return False Else Return true
	End Method
	
	Method SetImageResourceName(value:String)
		imageResourceName = value
	End Method
	
	#rem
		summary: This method will force a dynamic font to unload the character image from VRam.
	#end
	Method UnloadCharImage()
		if CharImageLoaded() = True Then
			image.Discard()
			image = null
			imageResourceName = imageResourceNameBackup
			imageResourceNameBackup = ""
		EndIf 
	End Method
	Private
	Field imageResourceNameBackup:string
	Field imageResourceName:String = ""

End Class

#rem
summary:This is the base font interface. Any font should implement this interface.
This is just an interface provided for easy integration with other font libraries.
The real bitmapfont objects used by this module are defined as [b]BitmapFont[/b] class objects.
[a ../.docs/bitmapfont.monkey.html]See the documentation here.[/a]
#end
Interface Font 
	'summary: This is the method to draw text on the canvas.
	Method DrawText(text:String, x#,y#) 

	'summary: This method returns the width in pixels (or graphic units) of the given string
	Method GetTxtWidth:Float(text:String) 

	'summary: This method returns the height in pixels (or graphic units) of the given string
	Method GetFontHeight:Int() 
End Interface

Class eDrawAlign abstract
	'summary: Use this constant for left aligment of text on draw operations.
	Const LEFT:Int = 1
	'summary: Use this constant for centered aligment of text on draw operations.
	Const CENTER:Int = 2
	'summary: Use this constant for right aligment of text on draw operations.
	Const RIGHT:Int = 3
End



#rem
	summary:This class represents a BitmapFont.
	A BitmapFont is a font used to draw text on the graphics canvas.
	Usually, to load a FontMachine font in your game or application, all you have to do is:
	[code]
Global myFont:BitmapFont = BitmapFont.Load("myfont.txt")
myFont.DrawText("Hello world!",10,10)
[/code][i](Obviously, you better see the complete source code samples)[/i]
#end

Class BitmapFont implements Font
	#rem
		summary:This function creates an instance of a BitmapFont class.
		The fontName parameter indicates the name of the txt file containing the font description (generated by the FontMachine editor).
		The second parameter indicates if the font should be loaded dynamically (only valid for non packed fonts).
	#end
	Function Load:BitmapFont(fontName:String, dynamicLoad:bool)
		Local font:= new BitmapFont(fontName, dynamicLoad)
		Return font
	End
	
	#rem
		summary:This is a BitmapFont class constructor.
		The fontDescriptionFilePath parameter indicates the name of the txt file containing the font description (generated by the FontMachine editor).
		The second parameter (dynamicLoad) indicates if the font should be loaded dynamically (only valid for non packed fonts).
	#end
	Method New(fontDescriptionFilePath:String, dynamicLoad:bool)
		Local text:String = app.LoadString(fontDescriptionFilePath)
		if text = "" Then Print "FONT " + fontDescriptionFilePath + " WAS NOT FOUND!!!"
		LoadFontData(text, fontDescriptionFilePath, dynamicLoad )
	End
	
	#rem
		summary:This is a BitmapFont class constructor.
		The fontDescriptionFilePath parameter indicates the name of the txt file containing the font description (generated by the FontMachine editor).
	#end
	Method New(fontDescriptionFilePath:String)
		Local text:String = app.LoadString(fontDescriptionFilePath)
		if text = "" Then Print "FONT " + fontDescriptionFilePath + " WAS NOT FOUND!!!"
		LoadFontData(text, fontDescriptionFilePath, True )
	End method
	
	#rem
		summary:Set this property to True or False to enable the font shadow.
		If the font has been rendered without a shadow, this property has no effect.
		[a ../sample programs/sample02.monkey]Load an example in Jungle Ide.[/a]
	#end
	Method DrawShadow:Bool() property
		Return _drawShadow
	End
	
	Method DrawShadow(value:Bool) property
		_drawShadow = value
	End
	
	#rem
		summary:Set this property to True or False to enable the font border.
		If the font has been rendered without a border, this property has no effect.
		[a ../sample programs/sample02.monkey]Load an example in Jungle Ide.[/a]
	#end
	Method DrawBorder:Bool() property
		Return _drawBorder
	End
	
	Method DrawBorder(value:Bool) property
		_drawBorder = value
	End
	
	#rem
		summary:this method will return the image associated to a given char on dynamic fonts.
		If the character image has not been loaded yet, this function will load it.
	#end
	Method GetFaceImage:B2DImage(char:Int) 
		if char>=0 And char<faceChars.Length() Then
			If faceChars[char] = Null Then Return Null
			if faceChars[char].packedFontIndex >0 Then Return packedImages[faceChars[char].packedFontIndex]
			if faceChars[char].CharImageLoaded() = false then faceChars[char].LoadCharImage()
			Return faceChars[char].image
		endif
	End Method
	
	#rem
		summary:this method will return the image associated to a given char border on dynamic fonts.
		If the character border image has not been loaded yet, this function will load it.
	#end
	Method GetBorderImage:B2DImage(char:Int) 
		if char>=0 And char<borderChars.Length() Then
			If borderChars[char] = Null Then Return Null
			if borderChars[char].packedFontIndex >0 Then Return packedImages[borderChars[char].packedFontIndex]
			if borderChars[char].CharImageLoaded() = false Then borderChars[char].LoadCharImage()
			Return borderChars[char].image
		endif
	End Method

	#rem
		summary:this method will return the image associated to a given char shadow on dynamic fonts.
		If the character shadow image has not been loaded yet, this function will load it.
	#end
	Method GetShadowImage:B2DImage(char:Int) 
		if char>=0 And char<shadowChars.Length() Then
			If shadowChars[char] = Null Then Return Null
			if shadowChars[char].packedFontIndex >0 Then Return packedImages[shadowChars[char].packedFontIndex]
			If shadowChars[char].CharImageLoaded() = false Then shadowChars[char].LoadCharImage()
			Return shadowChars[char].image
		endif
	End Method
	
	#Rem
		summary: This function return the number of chars that have been created in the given bitmapfont.
		[b]Important:[/b]Notice that some chars can have null characters due them being just part of scape sequences, so be sure to check for <> null before accesing any character info by index.
	#End
	Method CharCount:Int()
		Return Self.faceChars.Length
	End
	
	#rem
		summary:This method allows you to draw a string on the graphics canvas.
		The first parameter is the string to be drawn
		The second and third parameters are the X and Y coordinates.
		The third parameter is a member of eDrawAlign and determines the aligment of the text to be drawn on the graphics canvas.
		This is a detailed example: 
		[code]
'We import the required modules:
Import mojo
Import fontmachine
 
'Start the program:
Function Main() 
	New Tutorial
End


Class Tutorial extends App

	'We create a BitmapFont variable called font. Our font will be loaded here:
	Field font:BitmapFont
	
	Method OnCreate()
	
		SetUpdateRate(60)

		'We load the sample font (called bluesky) into our variable called font.
		'The first parameter is the name (and path) of the font description file (txt file generated on the FontMachine editor) 
		'The second parameter indicates if the font glipths will be loaded dynamically (true) or statically (false).
		'If the font characters are loaded dynamically, the application will load (and download on HTML5) only required characters.
		'Otherwise, the full font will be required. For more information about dynamic or static fonts, see the documentation.

		font = New BitmapFont("bluesky/bluesky.txt", False)
		
		Print "Font loaded!"
		
	End
	Method OnRender()
		Cls(255,255,255)

		'We just draw some text:
		font.DrawText("Hello world",210,10, eDrawAlign.CENTER)
	End
	
	Method OnUpdate()
		If KeyDown(KEY_A) Then font.Kerning.x-=.4
		If KeyDown(KEY_D) Then font.Kerning.x+=.4
		If KeyDown(KEY_W) Then font.Kerning.y-=.4
		If KeyDown(KEY_S) Then font.Kerning.y+=.4
	End
End
[/code][a ../sample programs/firstsample.monkey]Load this example in Jungle Ide.[/a]
	#end
	Method DrawText(text:String, x#, y#, align:Int)
		if DrawShadow Then DrawCharsText (text,x,y,eDrawMode.SHADOW, align )
		if DrawBorder Then DrawCharsText (text,x,y,eDrawMode.BORDER, align )
		DrawCharsText (text,x,y,eDrawMode.FACE ,align)
	End
	
	#rem
		summary:This method allows you to draw a string on the graphics canvas.
		This method is a simplified version of the DrawText command that asumes left aligment of text.
	#end
	Method DrawText(text:String, x#, y#)
		Self.DrawText(text,x,y,eDrawAlign.LEFT )
	End

	#rem
		summary:This method returns the width in graphic units of the given string.
		You can see [a ../sample programs/sample03.monkey]a sample application that uses the GetTxtWidth function here.[/a]
	#end
	Method GetTxtWidth:Float(text:String)
		Return GetTxtWidth(text, 1, text.Length)
	End

	#rem
		summary:This method returns the width in graphic units of the given substring.
		This function will take fromChar and toChar parameters to calculate the substring metrics
	#end
	Method GetTxtWidth:Float(text:String, fromChar:Int, toChar:Int)

		Local twidth:Float
		Local MaxWidth:Float = 0
		Local char:Int
		Local lastchar:Int = 0
				
		For Local i:Int = fromChar To toChar
			char = text[i-1]
			If char >= 0 And char < faceChars.Length() and char<> 10 And char<>13 Then
				If faceChars[char] <> Null Then
					lastchar = char
					twidth = twidth + faceChars[char].drawingMetrics.drawingWidth + Kerning.x
				End If
			ElseIf char = 10 
				If Abs(MaxWidth)<Abs(twidth) Then MaxWidth = twidth - Kerning.x  - faceChars[lastchar].drawingMetrics.drawingWidth + faceChars[lastchar].drawingMetrics.drawingSize.x
				twidth = 0
				lastchar = char
			End If
		Next
		If lastchar >= 0 And lastchar < faceChars.Length() Then
			if lastchar = 32 then
				'Do nothing. We let the spacing at the end of the string.
			ElseIf faceChars[lastchar] <> Null Then
				twidth = twidth - faceChars[lastchar].drawingMetrics.drawingWidth 
				twidth = twidth + faceChars[lastchar].drawingMetrics.drawingSize.x 
			End If		
		End If
		If Abs(MaxWidth)<Abs(twidth ) Then MaxWidth = twidth - Kerning.x  '- faceChars[lastchar].drawingMetrics.drawingWidth + faceChars[lastchar].drawingMetrics.drawingSize.x
		Return MaxWidth 'twidth
	End Method
	
	#rem
		summary:This method returns the height in graphic units of the given string.
	#end
	Method GetTxtHeight:Float(Text:String)
		'Too agreesive as it generates an array, but it is simple in calculation:
		'return (Text.Split("~n").Length + 1) * (faceChars[32].drawingMetrics.drawingSize.y + Kerning.y) 
		
		'Alternative:
		Local count:int = 0
		For Local i=0 until Text.Length
			if Text[i] = 10 Then
				count+=1
			EndIf
		Next
		Return count * (faceChars[32].drawingMetrics.drawingSize.y + Kerning.y) + GetFontHeight()
	End
	
	#rem
		summary:This method returns the height in pixels of the font.
	#end
	Method GetFontHeight:Int() 
		If faceChars[32] = Null Then Return 0
		Return faceChars[32].drawingMetrics.drawingSize.y 
	End Method
	
	#rem
		summary:This method returns the drawing char info of the given face character.
	#end
	Method GetFaceInfo:BitMapCharMetrics(char:Int)
		if char>=0 And char<faceChars.Length() Then
			if faceChars[char] <> null Then Return faceChars[char].drawingMetrics Else Return null
		End
	End
	
	#rem
		summary:This method returns the drawing char info of the given border character.
	#end
	Method GetBorderInfo:BitMapCharMetrics(char:Int)
		if char>=0 And char<borderChars.Length() Then
			if borderChars[char] <> null Then Return borderChars[char].drawingMetrics Else Return null
		End
	End
	
	#rem
		summary:This method returns the drawing char info of the given shadow character.
	#end
	Method GetShadowInfo:BitMapCharMetrics(char:Int)
		if char>=0 And char<shadowChars.Length() Then
			if shadowChars[char] <> null Then Return shadowChars[char].drawingMetrics Else Return null
		End
	End
	
	#rem
		summary:This method returns the rectangle coordinates of the given char into the packed texture.
		This method returns phisical coordinates in the texture, in pixels.
	#end
	Method GetPackedFaceRectangle:DrawingRectangle(char:Int)
		if char>=0 And char<faceChars.Length() Then
			Local rect := new drawingrectangle.DrawingRectangle 
			if faceChars[char] = null Then Return rect
			rect.x = faceChars[char].packedPosition.x
			rect.y = faceChars[char].packedPosition.y
			rect.width = faceChars[char].packedSize.x
			rect.height = faceChars[char].packedSize.y 
			Return rect
		End		
	End Method

	#rem
		summary:This method returns the rectangle coordinates of the given char shadow into the packed texture.
		This method returns phisical coordinates in the texture, in pixels.
	#end
	Method GetPackedShadowRectangle:DrawingRectangle(char:Int)
		if char>=0 And char<shadowChars.Length() Then
			Local rect := new drawingrectangle.DrawingRectangle 
			if shadowChars[char] = null Then Return rect
			rect.x = shadowChars[char].packedPosition.x
			rect.y = shadowChars[char].packedPosition.y
			rect.width = shadowChars[char].packedSize.x
			rect.height = shadowChars[char].packedSize.y 
			Return rect
		End		
	End Method

	#rem
		summary:This method returns the rectangle coordinates of the given char border into the packed texture.
		This method returns phisical coordinates in the texture, in pixels.
	#end
	Method GetPackedBorderRectangle:DrawingRectangle(char:Int)
		if char>=0 And char<borderChars.Length() Then
			Local rect := new drawingrectangle.DrawingRectangle 
			if borderChars[char] = null Then Return rect
			rect.x = borderChars[char].packedPosition.x
			rect.y = borderChars[char].packedPosition.y
			rect.width = borderChars[char].packedSize.x
			rect.height = borderChars[char].packedSize.y 
			Return rect
		End		
	End Method

	#rem
		summary:This method returns True if the current font is a packed font. Otherwise it returns false.
	#end
	Method IsPacked:Bool()
		'if packedImages = null Then Return False
		if packedImages.Length = 0 Then Return False
		Return true
	End Method

	#rem
		summary:This method will force a dynamic font to load all the available characters.
	#end
	Method LoadFullFont()
		if faceChars.Length >0 then
			For local ch:BitMapChar = EachIn faceChars
				if ch<>null then ch.LoadCharImage()
			Next
		endif
		if borderChars.Length >0 then
			For local ch:BitMapChar = EachIn borderChars 
				if ch<>null then ch.LoadCharImage()
			Next
		endif
		if shadowChars.Length >0 then
			For local ch:BitMapChar = EachIn shadowChars
				if ch<>null then ch.LoadCharImage()
			Next
		endif
	End
	
	#rem
		summary:This method will force a dynamic font to unload all its characters.
	#end
	Method UnloadFullFont()
		if faceChars.Length >0 then
			For local ch:BitMapChar = EachIn faceChars
				if ch<>null then ch.UnloadCharImage()
			Next
		endif
		if borderChars.Length >0 then
			For local ch:BitMapChar = EachIn borderChars 
				if ch<>null then ch.UnloadCharImage()
			Next
		endif
		if shadowChars.Length >0 then
			For local ch:BitMapChar = EachIn shadowChars
				if ch<>null then ch.UnloadCharImage()
			Next
		endif
	End	
	
	#rem
		summary:This method will force a dynamic font to load all the characters required to draw the given string on the graphics canvas.
	#end
	Method LoadCharsForText(text:String)
		For Local i:Int = 1 to text.Length 
			Local char:Int = text[i-1]
			if char>=0 And char<=faceChars.Length Then
				If faceChars[char] <> null Then faceChars[char].LoadCharImage()
			EndIf
			if char>=0 And char<=borderChars.Length Then
				If borderChars[char] <> null Then borderChars[char].LoadCharImage()
			EndIf
			if char>=0 And char<=shadowChars.Length Then
				If shadowChars[char] <> null Then shadowChars[char].LoadCharImage()
			EndIf
		Next

	End
	
	#rem
		summary:This method will force a dynamic font to unload all the characters in the given string.
	#end
	Method UnloadCharsForText(text:String)
			For Local i:Int = 1 to text.Length 
			Local char:Int = text[i-1]			
			if char>=0 And char<=faceChars.Length Then 
				If faceChars[char] <> null Then faceChars[char].UnloadCharImage()
			EndIf
			if char>=0 And char<=borderChars.Length Then
				If borderChars[char] <> null Then borderChars[char].UnloadCharImage()
			EndIf
			if char>=0 And char<=shadowChars.Length Then
				If shadowChars[char] <> null Then shadowChars[char].UnloadCharImage()
			EndIf
		Next

	End
		
	Private
	
	Field _drawShadow:Bool = true
	Field _drawBorder:Bool = true
	Field borderChars:BitMapChar[]
	Field faceChars:BitMapChar[]
	Field shadowChars:BitMapChar[]
		
	Method LoadFontData(Info:String, fontName:String, dynamicLoad:bool )
		if Info.StartsWith("P1") Then
			LoadPacked(Info,fontName,dynamicLoad)				
			return
		EndIf
		Local tokenStream:String[] = Info.Split(",") 
		local index:Int = 0 
		borderChars = New BitMapChar[65536]
		faceChars = New BitMapChar[65536]
		shadowChars = New BitMapChar[65536]
		
		Local prefixName:String = fontName
		if prefixName.ToLower().EndsWith(".txt") Then prefixName = prefixName[..-4]
		
		Local char:Int = 0
		while index<tokenStream.Length
			'We get char to load:
			Local strChar:String = tokenStream[index]
			if strChar.Trim() = "" Then 
				'Print "This is going to fail..."
				index+=1
				Exit    
			endif
			char = int(strChar)
			'Print "Loading char: " + char + " at index: " + index
			index+=1
			
			Local kind:String = tokenStream[index]
			'Print "Found kind= " + kind 
			index +=1
			
			Select kind
				Case "{BR"
					index+=3 '3 control point for future use
					borderChars[char] = New BitMapChar
					borderChars[char].drawingMetrics.drawingOffset.x = Int(tokenStream[index])
					borderChars[char].drawingMetrics.drawingOffset.y = Int(tokenStream[index+1])
					borderChars[char].drawingMetrics.drawingSize.x = Int(tokenStream[index+2])
					borderChars[char].drawingMetrics.drawingSize.y = Int(tokenStream[index+3])
					borderChars[char].drawingMetrics.drawingWidth = Int(tokenStream[index+4])
					if dynamicLoad  = False then
						borderChars[char].image = B2DLoadImage(prefixName + "_BORDER_" + char + ".png")
						borderChars[char].image.SetHandle(-borderChars[char].drawingMetrics.drawingOffset.x,-borderChars[char].drawingMetrics.drawingOffset.y)
					Else
						borderChars[char].SetImageResourceName  prefixName + "_BORDER_" + char + ".png"
					endif
					index+=5
					index+=1 ' control point for future use

				Case "{SH"
					index+=3 '3 control point for future use
					shadowChars[char] = New BitMapChar
					shadowChars[char].drawingMetrics.drawingOffset.x = Int(tokenStream[index])
					shadowChars[char].drawingMetrics.drawingOffset.y = Int(tokenStream[index+1])
					shadowChars[char].drawingMetrics.drawingSize.x = Int(tokenStream[index+2])
					shadowChars[char].drawingMetrics.drawingSize.y = Int(tokenStream[index+3])
					shadowChars[char].drawingMetrics.drawingWidth = Int(tokenStream[index+4])
					Local filename:String = prefixName + "_SHADOW_" + char + ".png"
					if dynamicLoad  = False then
						shadowChars[char].image = B2DLoadImage(filename)
						shadowChars[char].image.SetHandle(-shadowChars[char].drawingMetrics.drawingOffset.x,-shadowChars[char].drawingMetrics.drawingOffset.y)
					Else
						shadowChars[char].SetImageResourceName  filename 
					endif

					
					'shadowChars[char].image = LoadImage(filename)
					'shadowChars[char].image.SetHandle(-shadowChars[char].drawingMetrics.drawingOffset.x,-shadowChars[char].drawingMetrics.drawingOffset.y)

					index+=5
					index+=1 ' control point for future use
					
				Case "{FC"
					index+=3 '3 control point for future use
					faceChars[char] = New BitMapChar
					faceChars[char].drawingMetrics.drawingOffset.x = Int(tokenStream[index])
					faceChars[char].drawingMetrics.drawingOffset.y = Int(tokenStream[index+1])
					faceChars[char].drawingMetrics.drawingSize.x = Int(tokenStream[index+2])
					faceChars[char].drawingMetrics.drawingSize.y = Int(tokenStream[index+3])
					faceChars[char].drawingMetrics.drawingWidth = Int(tokenStream[index+4])
					if dynamicLoad = False then
						faceChars[char].image = B2DLoadImage(prefixName + "_" + char + ".png")
						faceChars[char].image.SetHandle(-faceChars[char].drawingMetrics.drawingOffset.x,-faceChars[char].drawingMetrics.drawingOffset.y)
					Else
						faceChars[char].SetImageResourceName prefixName + "_" + char + ".png" 
					endif
					index+=5 
					index+=1 ' control point for future use

				Default 
				Print "Error loading font! Char = " + char
				
			End
		Wend
		borderChars = borderChars[..char+1]
		faceChars = faceChars[..char+1]
		shadowChars = shadowChars[..char+1]
	End
	
	Field packedImages:B2DImage[]
	
	Method LoadPacked(info:String, fontName:String, dynamicLoad:bool )

		Local header:String = info[.. info.Find(",")]
		
		Local separator:String
		Select header
			Case "P1"
				separator = "."
			Case "P1.01"
				separator = "_P_"
		End Select
		info = info[info.Find(",")+1..]
		borderChars = New BitMapChar[65536]
		faceChars = New BitMapChar[65536]
		shadowChars = New BitMapChar[65536]
		packedImages = New B2DImage[256]
		Local maxPacked:Int = 0
		Local maxChar:Int = 0

		Local prefixName:String = fontName
		if prefixName.ToLower().EndsWith(".txt") Then prefixName = prefixName[..-4]

		Local charList:string[] = info.Split(";")
		For local chr:String = EachIn charList

			Local chrdata:string[] = chr.Split(",")
			if chrdata.Length() <2 Then Exit 
			Local char:BitMapChar 
			Local charIndex:Int = int(chrdata[0])
			if maxChar<charIndex Then maxChar = charIndex 
			
			select chrdata[1]
				Case "B"
					borderChars[charIndex] = New BitMapChar
					char = borderChars[charIndex]
				Case "F"
					faceChars [charIndex] = New BitMapChar
					char = faceChars[charIndex]
				Case "S"
					shadowChars [charIndex] = New BitMapChar
					char = shadowChars[charIndex]
			End Select
			char.packedFontIndex = Int(chrdata[2])
			if packedImages[char.packedFontIndex] = null Then
				packedImages[char.packedFontIndex] = B2DLoadImage(prefixName + separator + char.packedFontIndex +  ".png")
				if maxPacked<char.packedFontIndex Then maxPacked = char.packedFontIndex
			endif
			char.packedPosition.x = Int(chrdata[3])
			char.packedPosition.y = Int(chrdata[4])
			char.packedSize.x = Int(chrdata[5])
			char.packedSize.y = Int(chrdata[6])
			char.drawingMetrics.drawingOffset.x = Int(chrdata[8])
			char.drawingMetrics.drawingOffset.y = Int(chrdata[9])
			char.drawingMetrics.drawingSize.x = Int(chrdata[10])
			char.drawingMetrics.drawingSize.y = Int(chrdata[11])
			char.drawingMetrics.drawingWidth = Int(chrdata[12])

		Next
		borderChars = borderChars[..maxChar+1]
		faceChars = faceChars[..maxChar+1]
		shadowChars = shadowChars[..maxChar+1]
		packedImages = packedImages[..maxPacked+1]
		
	end
	
	Method DrawCharsText(text:String,x#,y#, mode:Int = eDrawMode.FACE, align:Int)
		If mode = eDrawMode.BORDER  Then
			DrawCharsText(text, x, y, borderChars, align)
		ElseIf mode = eDrawMode.FACE  Then
			DrawCharsText(text, x, y, faceChars, align)
		Else
			DrawCharsText(text, x, y, shadowChars,align)
		EndIf
	End


	Const lineSep:String = "~n"
	
	Method DrawCharsText(text:String,x#,y#, target:BitMapChar[]  , align:Int, startPos:Int = 1)
		Local drx:Float = x, dry:Float = y
		Local oldX:Float = x
		Local xOffset:Int = 0
		'Local lineSep:String = String.FromChar(10)
		
		If align<>eDrawAlign.LEFT then
			Local lineSepPos:Int = text.Find(lineSep, startPos)
			if lineSepPos<0 Then lineSepPos = text.Length
			Select align
				Case eDrawAlign.CENTER ; xOffset = Self.GetTxtWidth(text, startPos, lineSepPos) / 2 'Forcing an INT is a good idea to prevent drawing rounding artifacts... �?
				Case eDrawAlign.RIGHT ;  xOffset = Self.GetTxtWidth(text, startPos, lineSepPos)
			End Select
		EndIf
		
		For Local i:Int = startPos to text.Length 
			Local char:Int = text[i-1]
			if char>=0 And char<=target.Length Then
				if char = 10 Then
					dry+=faceChars[32].drawingMetrics.drawingSize.y  + Kerning.y 
					Self.DrawCharsText(text, oldX , dry, target, align, i+1)
					return
				ElseIf target[char] <> null Then
					if target[char].CharImageLoaded() = false Then
						target[char].LoadCharImage()
					End
					if target[char].image <> null Then
						B2DDrawImage(target[char].image,drx-xOffset,dry)
					ElseIf target[char].packedFontIndex > 0 Then
						B2DDrawImageRect(packedImages[target[char].packedFontIndex],-xOffset+drx+target[char].drawingMetrics.drawingOffset.x,dry+target[char].drawingMetrics.drawingOffset.y,target[char].packedPosition.x,target[char].packedPosition.y,target[char].packedSize.x,target[char].packedSize.y)
					Endif
					drx+=faceChars[char].drawingMetrics.drawingWidth  + Kerning.x
				endif
			Else
			'	Print "Char " + char + " out of scope."
			EndIf
		Next
	End
				
	Private

	Field _kerning:DrawingPoint 
	Public
	#rem
		summary: This property allows you to define additional kerning on a given bitmap font.
		By using this property, you set the horizonal and vertical kerning that has to be added on any draw operation.
		This information will be expressed in the form of a DrawingPoint instance.
	#end
	Method Kerning:DrawingPoint() property
		if _kerning = null Then _kerning = New DrawingPoint
		Return _kerning
	End

	Method Kerning:void(value:DrawingPoint) property
		_kerning = value		  
			
	End
		
End

#rem
footer:This FontMachine library is released under the MIT license:
[quote]Copyright (c) 2011 Manel Ib��ez

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
[/quote]
#end
