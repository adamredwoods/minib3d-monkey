
class BufferHelper {
	
	static BBDataBuffer oldbuf;
	static FloatBuffer cachebuf;

	static BBDataBuffer oldbuf2;
	static ShortBuffer cachebuf2;
	static short ns_cache[] = new short[64];
	
	public static void pokeFloatArray (BBDataBuffer inBuffer, int start, float[] src, int len) {

		if (inBuffer != oldbuf) { oldbuf = inBuffer; cachebuf = inBuffer.GetByteBuffer().asFloatBuffer(); }
		cachebuf.position( start );cachebuf.put(src,0,len);
		
	}
	
	public static void pokeShortArray (BBDataBuffer inBuffer, int start, int[] src, int len) {

		if (inBuffer != oldbuf2) { oldbuf2 = inBuffer; cachebuf2 = inBuffer.GetByteBuffer().asShortBuffer(); }
		short ns[] = (len>64)? new short[len] : ns_cache;
		for (int i=0; i<len; i++) ns[i]=(short)src[i];
		cachebuf2.position( start );cachebuf2.put(ns,0,len);
		
	}

}