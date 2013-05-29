Import "flash11.driver.as"
Import "AGALMiniAssembler.as"
Import brl.databuffer
Import minib3d.flash11.tpixmap_flash
Import mojo.graphicsdevice

#If TARGET<>"flash"
	#Error "Need flash target"
#Endif



Extern
	
	Class IndexBuffer3D = "IndexBuffer3D"
		Method Dispose:Void() = "dispose"
		'Method ToString:String() = "toString"
	End
	Class VertexBuffer3D = "VertexBuffer3D"
		Method Dispose:Void() = "dispose"
	End
	Class FlashTexture = "Texture"
		Method Dispose:Void() = "dispose"
	End
	Class CubeFlashTexture Extends FlashTexture = "CubeTexture"
		Method Dispose:Void() = "dispose"
	End
	Class AGALMiniAssembler = "AGALMiniAssembler"
		'' returns a bytearray, pass as int?
		Method Assemble:AGALPointer ( mode:String, source:String, verbose:Bool = False ) = "assemble"
	End
	Class AGALMiniAssemblerDebug Extends AGALMiniAssembler = "AGALMiniAssembler(true)"
	End
	Class AGALPointer = "ByteArray"
		Method Length:Int() = "length; //" ''use for debugging only
	End
	
	Class FlashError Extends Throwable = "Error"
		Method ToString:String() = "toString"
	End
	
	
	
	''for testing
	Class Context__ = "Context3D"
	End

	'Class DRIVER
		
				''---consts
		Global DRIVER_LESS_EQUAL:Int = "Context3DCompareMode.LESS_EQUAL"
		Global DRIVER_GREATER_EQUAL:Int = "Context3DCompareMode.GREATER_EQUAL"
		Global DRIVER_NEVER:Int = "Context3DCompareMode.NEVER"
		Global DRIVER_ALWAYS:Int = "Context3DCompareMode.ALWAYS"
		Global DRIVER_GREATER:Int = "Context3DCompareMode.GREATER"
		
		Global DRIVER_BACK:Int="Context3DTriangleFace.BACK"
		Global DRIVER_FRONT:Int="Context3DTriangleFace.FRONT"
		Global DRIVER_NONE:Int="Context3DTriangleFace.NONE"
		
		Global DRIVER_DESTINATION_ALPHA:Int = "Context3DBlendFactor.DESTINATION_ALPHA"
		Global DRIVER_DESTINATION_COLOR:Int = "Context3DBlendFactor.DESTINATION_COLOR"
		Global DRIVER_ONE:Int = "Context3DBlendFactor.ONE"
		Global DRIVER_ONE_MINUS_DESTINATION_ALPHA:Int = "Context3DBlendFactor.ONE_MINUS_DESTINATION_ALPHA"
		Global DRIVER_ONE_MINUS_SOURCE_ALPHA:Int = "Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA"
		Global DRIVER_ONE_MINUS_SOURCE_COLOR:Int = "Context3DBlendFactor.ONE_MINUS_SOURCE_COLOR"
		Global DRIVER_SOURCE_ALPHA:Int = "Context3DBlendFactor.SOURCE_ALPHA"
		Global DRIVER_SOURCE_COLOR:Int = "Context3DBlendFactor.SOURCE_COLOR"
		Global DRIVER_ZERO:Int = "Context3DBlendFactor.ZERO"
		
		Global DRIVER_FLOAT_2:Int="Context3DVertexBufferFormat.FLOAT_2"
		Global DRIVER_FLOAT_3:Int="Context3DVertexBufferFormat.FLOAT_3"
		Global DRIVER_FLOAT_4:Int="Context3DVertexBufferFormat.FLOAT_4"
		Global DRIVER_BYTES_3:Int="Context3DVertexBufferFormat.BYTES_3"
		Global DRIVER_BYTES_4:Int="Context3DVertexBufferFormat.BYTES_4"
		
		Global DRIVER_BGRA:Int = "Context3DTextureFormat.BGRA"
		
		Global DRIVER_VERTEX_PROGRAM:String = "Context3DProgramType.VERTEX"
		Global DRIVER_FRAGMENT_PROGRAM:String = "Context3DProgramType.FRAGMENT"
		
		Global DRIVER_CLEAR_ALL:Int = "Context3DClearMask.ALL"
		Global DRIVER_CLEAR_COLOR:Int = "Context3DClearMask.COLOR"
		Global DRIVER_CLEAR_DEPTH:Int = "Context3DClearMask.DEPTH"
		Global DRIVER_CLEAR_STENCIL:Int = "Context3DClearMask.STENCIL"
		
		Global DRIVER_WRAP_CLAMP:Int = "Context3DWrapMode.CLAMP"
		Global DRIVER_WRAP_REPEAT:Int = "Context3DWrapMode.REPEAT"
		
		Global DRIVER_TEX_LINEAR:Int = "Context3DTextureFilter.LINEAR"
		Global DRIVER_MIP_LINEAR:Int = "Context3DMipFilter.LINEAR"
		
		Global DRIVER_FFFFFFFF:Int = "0xffffffff"
		Global DRIVER_FF000000:Int = "0xff000000"
	'End
	
	
	Class Driver Extends Null = "Driver3D"

		
		
		''--------custom
		
		Method CheckVersion:String()
		
		Method InitContext:Void(width:Int, height:Int, antialias:Int=False, flags:Int=0) ''flags does nothin, could be used for profile baseline
		Method ContextReady:Bool()

		Method UploadTextureData:Int(tex:FlashTexture, source:FlashPixmap, miplevel:Int = 0) = "UploadTextureData" ''returns 0= failure
		
		'Method DrawToBitmapData:Void(destination:BitmapData) ="context3d.drawToBitmapData"
		
		''each register is 4 float values
		Method UploadConstantsFromArray:Void( programType:String, firstRegister:Int, data:Float[], byteArrayOffset:Int=0) = "UploadConstantsFromArray"
		Method UploadConstantsFromArray:Void( programType:String, firstRegister:Int, data:Int[], byteArrayOffset:Int=0) = "UploadConstantsFromArray"
	
		Method UploadIndexFromDataBuffer:Void(ib:IndexBuffer3D, data:DataBuffer, byteArrayOffset:Int, startVertex:Int, numVertices:Int) = "UploadIndexFromDataBuffer"
		Method UploadVertexFromDataBuffer:Void(vb:VertexBuffer3D, data:DataBuffer, byteArrayOffset:Int, startVertex:Int, numVertices:Int) = "UploadVertexFromDataBuffer"
		
		Method SetScissorRectangle:Void(x:Int,y:Int,w:Int,h:Int) = "SetScissorRectangle_"
		
		Method PresentToMojoBitmap:Void(g:GraphicsDevice) = "PresentToMojoBitmap"
		
		Method SetContext__:Void(c:Context__) = "SetContext__"
		Method GetContext__:Context__() = "GetContext__"
		
		''monkey defaults to big endian, but stage3d takes little endian
		Function DataBufferLittleEndian:Void(b:DataBuffer)
		
		''--------stock
		
		Method Clear:Void(r:Float, b:Float, g:Float, a:Float=1.0, depth:Float=1.0, stencil:Int=0, mask:Int=DRIVER_FFFFFFFF) = "context3d.clear"
		
		Method ConfigureBackBuffer:Void(width:Int, height:Int, antiAlias:Int, enableDepthAndStencil:Boolean = True, wantsBestResolution:Boolean = False) = "context3d.configureBackBuffer"
		Method CreateCubeTexture:CubeFlashTexture(size:Int, format:String, optimizeForRenderToTexture:Boolean, streamingLevels:Int = 0) = "context3d.createCubeTexture"
		Method CreateIndexBuffer:IndexBuffer3D(numIndices:Int) = "context3d.createIndexBuffer"
		Method CreateVertexBuffer:VertexBuffer3D(numVertices:Int, data32PerVertex:Int) = "context3d.createVertexBuffer"
		Method CreateProgram:Program3D() = "context3d.createProgram"
		Method CreateTexture:FlashTexture(width:Int, height:Int, format:Int, optimizeForRenderToTexture:Bool=False) = "context3d.createTexture"
		
		
		Method DrawTriangles:Void(indexBuffer:IndexBuffer3D, firstIndex:Int = 0, numTriangles:Int = -1) = "context3d.drawTriangles"		
		Method Present:Void() = "context3d.present"
		
		
		
		Method EnableErrorChecking(b:Bool) Property = "EnableErrorChecking_"
					
		Method SetBlendFactors:Void(sourceFactor:Int, destinationFactor:Int) = "context3d.setBlendFactors"
			 	
		Method SetColorMask:Void(red:Bool, green:Bool, blue:Bool, alpha:Bool) = "context3d.setColorMask"
			
		Method SetCulling:Void(triangleFaceToCull:Int) = "context3d.setCulling"
			
		Method SetDepthTest:Void(depthMask:Bool, passCompareMode:Int) = "context3d.setDepthTest"
		 	 	
		Method SetProgram:Void(program:Program3D) = "context3d.setProgram"
		 	 	
		'Method SetProgramConstantsFromByteArray:Void(programType:String, firstRegister:Int, numRegisters:Int, data:ByteArray, byteArrayOffset:Int) = "context3d.setProgramConstantsFromByteArray"
		 	 	
		'Method SetProgramConstantsFromMatrix:Void(programType:String, firstRegister:Int, matrix:Matrix3D, transposedMatrix:Bool = False) = "context3d.setProgramConstantsFromMatrix"
		 	 	
		'Method SetProgramConstantsFromVector:Void(programType:String, firstRegister:Int, data:Vector.<Number>, numRegisters:Int = -1) = "context3d.setProgramConstantsFromVector"
		 	 	
		Method SetRenderToBackBuffer:Void() = "context3d.setRenderToBackBuffer"
		 	 	
		Method SetRenderToTexture:Void(texture:TextureBase, enableDepthAndStencil:Bool = False, antiAlias:Int = 0, surfaceSelector:Int = 0) = "context3d.setRenderToTexture"
		 	 	
		 	 	
		Method SetStencilActions:Void(triangleFace:String = "frontAndBack", compareMode:String = "always", 
			actionOnBothPass:String = "keep", actionOnDepthFail:String = "keep", actionOnDepthPassStencilFail:String = "keep") = "context3d.setStencilActions"
		 	 	
		Method SetStencilReferenceValue:Void(referenceValue:Int, readMask:Int = 255, writeMask:Int = 255) = "context3d.setStencilReferenceValue"
		 	 	
		Method SetTextureAt:Void(sampler:Int, texture:FlashTexture) = "context3d.setTextureAt"
		 	 	
		Method SetVertexBufferAt:Void(index:Int, buffer:VertexBuffer3D, bufferOffset:Int = 0, format:Int = DRIVER_FLOAT_4) = "context3d.setVertexBufferAt"
		
		'Method SetSamplerStateAt:Void(sampler:Int, wrap:int, filter:int, mipfilter:int) = "context3d.setSamplerStateAt"
	End
	
	Class Program3D = "Program3D"
		Method Dispose:Void() = "dispose"
		Method Upload:Void(vertexProgram:AGALPointer, fragmentProgram:AGALPointer) = "upload"
	End
	
	

	
Public

