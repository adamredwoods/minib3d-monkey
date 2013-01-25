
class TPixmapJava {
	static public void DataToPixmap( BBDataBuffer imagedata, BBDataBuffer buf, int[] info ) {
		Bitmap bitmap=null;
		try{
			//byte[] bytes = new byte[imagedata.GetByteBuffer().capacity()];
			//imagedata.GetByteBuffer().get(bytes, 0, bytes.length);
			//bitmap=BitmapFactory.decodeByteArray( bytes,0, bytes.length);
			bitmap=BitmapFactory.decodeByteArray( imagedata.GetByteBuffer().array(),0, imagedata.GetByteBuffer().array().length);
		}catch( OutOfMemoryError e ){
			throw new Error( "Out of memory error loading bitmap" );
		}
		if( bitmap==null ) return;
		
		int width=bitmap.getWidth(),height=bitmap.getHeight();

		int size=width*height;
		int[] pixels=new int[size];
		bitmap.getPixels( pixels,0,width,0,0,width,height );
		
		buf.Discard();
		boolean result = buf._New( size*4 );
		if (!result) throw new Error( "Out of memory error loading bitmap" );
		
		for( int i=0;i<size;++i ){
			int p=pixels[i];
			int a=(p>>24) & 255;
			int r=(p>>16) & 255;
			int g=(p>>8) & 255;
			int b=p & 255;
			buf.PokeInt( (i<<2),(a<<24)|(b<<16)|(g<<8)|r ); //i*4
		}
		
		if( info.length>0 ) info[0]=width;
		if( info.length>1 ) info[1]=height;
	}
}
