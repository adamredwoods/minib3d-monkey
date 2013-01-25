
public class DataBufferHelper
{
	/*
    public byte[] _data;
    int _length;

    public DataBuffer(int length)
    {
        _data = new byte[length+4];
        _length = length;
    }
	
	public DataBuffer(byte[] data)
    {
        _data = data;
        _length = data.Length;
    }
	
    public int Size()
    {
        return _length;
    }

    public void Discard()
    {
        if (_data != null)
        {
            _data = null;
            _length = 0;
        }
    }

    public void PokeByte(int addr, int value)
    {
        _data[addr] = (byte)value;
    }

    public void PokeShort(int addr, int value)
    {
        Array.Copy(System.BitConverter.GetBytes((short)value), 0, _data, addr, 2);
    }

    public void PokeInt(int addr, int value)
    {
        Array.Copy(System.BitConverter.GetBytes(value), 0, _data, addr, 4);
    }

    public void PokeFloat(int addr, float value)
    {
        Array.Copy(System.BitConverter.GetBytes(value), 0, _data, addr, 4);
    }

    public int PeekByte(int addr)
    {
        return (int)_data[addr];
    }

    public int PeekShort(int addr)
    {
        return (int)System.BitConverter.ToInt16(_data, addr);
    }

    public int PeekInt(int addr)
    {
        return System.BitConverter.ToInt32(_data, addr);
    }

    public float PeekFloat(int addr)
    {
        return (float)System.BitConverter.ToSingle(_data, addr);
    }

    public static DataBuffer Create(int length)
    {
        return new DataBuffer(length);
    }
	*/
	
	
	public static void LoadImageData(BBDataBuffer buffer, string path, int[] info)
	{
		var texture = MonkeyData.LoadTexture2D(path, gxtkApp.game.Content);
		if (texture==null) {info[0]=0; return; } //new BBDataBuffer(0);}
		
		int bytes = 4;
		Console.WriteLine("textureformat "+texture.Format.ToString()+" "+path);
		
		if (texture.Format != SurfaceFormat.Color) {
			
			bytes = 3;
		}
		
        int size = texture.Width * texture.Height * bytes;

		info[0] = texture.Width;
		info[1] = texture.Height;
		
		//** assume new buffer since it a cast instance
		//buffer = new BBDataBuffer();
		buffer._New(size);
        texture.GetData<byte>(buffer._data, 0, size);


	}
}

