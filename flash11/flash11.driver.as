
import flash.display.Stage3D;
import flash.display3D.*;
import flash.display3D.textures.Texture;
import flash.system.Capabilities;
//import com.adobe.utils.AGALMiniAssembler;

class Driver3D
{
	protected var game:BBFlashGame;
	protected var stage:Stage;
	
	public var context3d:Context3D;
	//protected var program:Program3D;
	protected var vertexbuffer:VertexBuffer3D;
	protected var indexbuffer:IndexBuffer3D;
	
	protected var width:int, height:int, alias:int;
	protected var contextReady:Boolean = false;
	
	private static var mojo_clear:Boolean = false;
	
	public function SetContext__(c:Context3D):void {
		context3d = c;
	}
	
	public function CheckVersion():String
	{
		return Capabilities.version;
	}
	
	public function EnableErrorChecking_(b:Boolean):void {
		context3d.enableErrorChecking = b;
	}
	
	public function InitContext(w:int, h:int, al:int, flags:int):void {
		width = w; height = h; alias = al;
		
		game=BBFlashGame.FlashGame();
		stage=game.GetDisplayObjectContainer().stage;

		stage.stage3Ds[0].addEventListener( Event.CONTEXT3D_CREATE, Init3D );
		stage.stage3Ds[0].addEventListener( ErrorEvent.ERROR, contextCreationError );
		stage.stage3Ds[0].requestContext3D(); //auto, profile=baseline
		
		
	}
	
	public function Init3D(e:Event):void {
		//print("**************");
		context3d = stage.stage3Ds[0].context3D;			
		context3d.configureBackBuffer(width, height, alias, true);
		contextReady = true;
	}
	
	public function ContextReady():Boolean {
		return contextReady;
	}
	
	private function contextCreationError( error:ErrorEvent ):void
	{
		trace( error.errorID + ": " + error.text );
	}
	
	
	public  function UploadTextureData(tex:Texture, pix:TPixmap, miplevel:uint):int {
		try {
			tex.uploadFromBitmapData(pix.pixels, miplevel);
		} catch (e:Error) {
			//ran out of memory or pixels are gone
			return 0;
		}
		return 1;
	}
	

	public  function UploadConstantsFromArray( programType:String, firstRegister:int, data:Array, byteArrayOffset:uint):void {
			
		var num_regs:int = data.length >> 3; //why 8?
		var byteArray:ByteArray = new ByteArray();
		byteArray.endian = Endian.LITTLE_ENDIAN;
        byteArray.writeObject(data);
		context3d.setProgramConstantsFromByteArray(programType, firstRegister, num_regs, byteArray, byteArrayOffset);
			
	}
	
	public  function UploadIndexFromDataBuffer(ib:IndexBuffer3D, data:BBDataBuffer, byteArrayOffset:int, startVertex:int, numVertices:int):void {
print("indexlen");
	print(String(data._data.length));
print(data.Length().toString());	
		var d:ByteArray = data.GetByteArray();
		//d.endian = Endian.LITTLE_ENDIAN;
		ib.uploadFromByteArray(d , byteArrayOffset, startVertex, numVertices);
		
	}
	
	public  function UploadVertexFromDataBuffer(vb:VertexBuffer3D, data:BBDataBuffer, byteArrayOffset:int, startVertex:int, numVertices:int):void {
print("vblen");
	print(String(data._data.length));
print(data.Length().toString());
		var d:ByteArray = data.GetByteArray();
		//d.endian = Endian.LITTLE_ENDIAN;	
		vb.uploadFromByteArray(d , byteArrayOffset, startVertex, numVertices);
		
	}
	
	public  function SetScissorRectangle_(x:int,y:int,w:int,h:int):void {
		context3d.setScissorRectangle( new Rectangle(x,y,w,h) );
	}
	
	public function Present():void {
		context3d.present();
	}
	
	public function PresentToMojoBitmap(g:gxtkGraphics):void {
		// ugh.... may break if mojo changes
		//context3d.drawToBitmapData( app.graphics.bitmapData );
		if (!mojo_clear) {
			g.bitmap.bitmapData=new BitmapData( stage.stageWidth,stage.stageHeight,true,0x005050ff );
			mojo_clear = true;
		}
		context3d.present();
	}

	public static function DataBufferLittleEndian(b:BBDataBuffer):void {
		b.GetByteArray().endian = Endian.LITTLE_ENDIAN;
	}

}