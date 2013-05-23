
import flash.display.Bitmap;
import flash.display.BitmapData;

class TPixmap {
	
	internal var pixels:BitmapData;
	internal var isLoaded:Boolean=false;
	internal var width:int;
	internal var height:int;
	
	
	private function onComplete (event:Event):void
	{
		pixels = Bitmap(LoaderInfo(event.target).content).bitmapData;
		isLoaded = true;
		width = pixels.width;
		height = pixels.height;
	}
	
	
	public static function LoadImageData(file:String):TPixmap {
		var pix:TPixmap = new TPixmap;
		
		var loader:Loader = new Loader();
		loader.contentLoaderInfo.addEventListener(Event.COMPLETE, pix.onComplete);
		loader.load(new URLRequest(file));

		return pix;
	}
	
	public static function CreatePixmap(x:int, y:int):TPixmap {
		var pix:TPixmap = new TPixmap;
		pix.pixels = new BitmapData(x, y, true, 0xffffffff);
		pix.width = x; pix.height = y;
		return pix;
	}
	
	public static function ReadPixel(pix:TPixmap, x:int, y:int):uint {
		return pix.pixels.getPixel32(x,y);
	}
	public static function WritePixel(pix:TPixmap, x:int, y:int, rgb:uint):void {
		pix.pixels.setPixel32(x,y, rgb);
	}
	
	public static function ResizePixmap(pix:TPixmap, nw:int, nh:int, smooth:Boolean):TPixmap {
		var newpix:TPixmap = new TPixmap;
		var mat:Matrix = new Matrix();
		
		mat.scale(nw/pix.pixels.width, nh/pix.pixels.height);
		newpix.pixels = new BitmapData(nw, nh, true, 0x00000000);
		newpix.pixels.draw(pix.pixels, mat, null, BlendMode.NORMAL, null, smooth);

		return newpix;
	}
	
	public static function MaskPixmap(pix:TPixmap, threshold:uint):TPixmap {
		
		var newpix:TPixmap = new TPixmap;

		newpix.pixels = new BitmapData(pix.pixels.width, pix.pixels.height, true);
		var pt:Point = new Point(0, 0);
		
		//pix.pixels.threshold(newpix.pixels, newpix.pixels.rect, pt, "==", threshold, 0x00000000, 0x00ffffff, true);
		newpix.pixels.threshold(pix.pixels, pix.pixels.rect, pt, "==", threshold, 0x00000000, 0x00ffffff, true);
		return newpix;
	}
	
	public static function GetInfo(pix:TPixmap):Array {
		return [pix.width, pix.height];
	}
	
	public static function CheckIsLoaded(pix:TPixmap):Boolean {
		return pix.isLoaded;
	}
}
