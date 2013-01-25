
public class XNAGraphicsResource : IDisposable 
{
    public XNAGraphicsDevice _device;
    public bool _disposed = false;
    public string _name;
    public object _tag;

    public XNAGraphicsResource(XNAGraphicsDevice device)
    {
        _device = device;
    }

    ~XNAGraphicsResource()
    {
        Dispose(false);
    }
	
    public XNAGraphicsDevice GetGraphicsDevice()
    {
        return _device;
    }

    public string GetName()
    {
        return _name;
    }

    public void SetName(string name)
    {
        _name = name;
    }

    public object GetTag()
    {
        return _tag;
    }

    public void SetTag(object tag)
    {
        _tag = tag;
    }

    public virtual void Dispose()
    {
        Dispose(true);
    }

    public virtual void Dispose(bool disposing)
    {
        if (_disposed) return;
        _disposed = true;
    }
}

public class XNAGraphicsDevice
{
    public GraphicsDevice _device;
	public BasicEffect _effect;
	public Viewport _viewport = new Viewport();
	public Color _clsColor = Color.White;
	
    public XNAGraphicsDevice()
    {
        //_device = gxtkApp.game.app.graphics.device;
		_device = gxtkApp.game.app.GraphicsDevice().device;
        _effect = new BasicEffect(_device);
        _effect.VertexColorEnabled = false;
        _effect.PreferPerPixelLighting = false;
        _effect.SpecularColor = new Vector3(1,1,1);
        _effect.FogEnabled = false;
    }

    public XNATexture LoadTexture(string fileName)
    {
        var texture = MonkeyData.LoadTexture2D(fileName, gxtkApp.game.Content);
        if (texture != null) return new XNATexture(texture,fileName);
        return null;
    }
	
	public XNATexture CreateTexture(int width, int height, bool mipmap, int format)
    {
         return new XNATexture(_device, width, height, mipmap, format);
    }
	
	public XNABasicEffect CreateBasicEffect()
	{
		return new XNABasicEffect(this,new BasicEffect(_device));
	}
	
	public XNAEffect LoadEffect(string filename)
	{
		//var effect = gxtkApp.game.Content.Load<Effect>(filename);
		//if( effect != null ) return new XNAEffect(effect, this);
		return null;
	}	
	
	public XNAMesh CreateMesh()
	{
		return new XNAMesh(_device);
	}

	 public void SetBlend(XNABlendState blend)
    {
		_device.BlendState = blend._state;
    }
	
	public void SetRasterizerState(XNARasterizerState state)
    {
        _device.RasterizerState = state._state;
    }
	
	public void SetDepthStencilState(XNADepthStencilState state)
	{
		_device.DepthStencilState = state._state;
	}
	
	public void SetSamplerState(int index, XNASamplerState state)
	{
		_device.SamplerStates[index] = state._state;
	}

    public void ClearScreen(float r, float g, float b, bool back, bool depth, bool stencil)
    {
		int mode = 0;
        if (back) mode |= (int)ClearOptions.Target;
        if (depth) mode |= (int)ClearOptions.DepthBuffer;
        if (stencil) mode |= (int)ClearOptions.Stencil;
        _device.Clear((ClearOptions)mode, new Color(r, g, b), 1.0f, 0);
    }
	
	public void Viewport(int x,int y,int width, int height) 
	{
		_viewport.X = x;
        _viewport.Y = y;
        _viewport.Width = width;
        _viewport.Height = height;
		_viewport.MinDepth = 0.0f;
        _viewport.MaxDepth = 1.0f;
	}
	
	public float GetShaderVersion() {
		//GraphicsDeviceCapabilities caps = GraphicsDevice.GraphicsDeviceCapabilities;
		//return caps.PixelShaderVersion; //MaxPixelShaderProfile;
		if (_device.GraphicsProfile == GraphicsProfile.Reach) {return 2.0f;} else { return 3.0f; }
	}
	
	public int GraphicsDeviceStatus() {
		return Convert.ToInt32(_device.GraphicsDeviceStatus);
		//return Convert.ToInt32(_device.IsDisposed);
	}
	
};

public class XNABlendState
{
	public BlendState _state;
	
	public XNABlendState(BlendState state)
	{
		_state = state;
	}

    public static XNABlendState Create()
	{
		return new XNABlendState(new BlendState());
	}

    public static XNABlendState Additive()
	{
		return new XNABlendState(BlendState.Additive);
	}

    public static XNABlendState AlphaBlend()
	{
		return new XNABlendState(BlendState.AlphaBlend);
	}

    public static XNABlendState NonPremultiplied()
	{
		return new XNABlendState(BlendState.NonPremultiplied);
	}

    public static XNABlendState Opaque()
	{
		return new XNABlendState(BlendState.Opaque);
	}
	
	public int GetAlphaBlendFunction()
	{
		return (int)_state.AlphaBlendFunction;
	}
	
	public int GetAlphaDestinationBlend()
	{
		return (int)_state.AlphaDestinationBlend;
	}
	
	public int GetAlphaSourceBlend()
	{
		return (int)_state.AlphaSourceBlend;
	}

    public XNAColor GetBlendFactor()
	{
        return new XNAColor(_state.BlendFactor);
	}
	
	public int GetColorBlendFunction()
	{
		return (int)_state.ColorBlendFunction;
	}
	
	public int GetColorDestinationBlend()
	{
		return (int)_state.ColorDestinationBlend;
	}

    public int GetColorSourceBlend()
	{
		return (int)_state.ColorSourceBlend;
	}
	
	public void SetAlphaBlendFunction(int value)
	{
        _state.AlphaBlendFunction = (BlendFunction)value;
	}
	
	public void SetAlphaDestinationBlend(int value)
	{
        _state.AlphaDestinationBlend = (Blend)value;
	}
	
	public void SetAlphaSourceBlend(int value)
	{
        _state.AlphaSourceBlend = (Blend)value;
	}
	
	public void SetBlendFactor(XNAColor value)
	{
        _state.BlendFactor = value._color;
	}
	
	public void SetColorBlendFunction(int value)
	{
        _state.ColorBlendFunction = (BlendFunction)value;
	}
	
	public void SetColorDestinationBlend(int value)
	{
        _state.ColorDestinationBlend = (Blend)value;
	}
	
	public void SetColorSourceBlend(int value)
	{
        _state.ColorSourceBlend = (Blend)value;
	}
}

public class XNARasterizerState
{
	public RasterizerState _state;
	
	public XNARasterizerState(RasterizerState state)
	{
		_state = state;
	}

    public static XNARasterizerState Create()
	{
        return new XNARasterizerState(new RasterizerState());
	}

    public static XNARasterizerState CullClockwise()
	{
		return new XNARasterizerState(RasterizerState.CullClockwise);
	}

    public static XNARasterizerState CullCounterClockwise()
	{
		return new XNARasterizerState(RasterizerState.CullCounterClockwise);
	}

    public static XNARasterizerState CullNone()
	{
		return new XNARasterizerState(RasterizerState.CullNone);
	}
	
	public int GetCullMode()
	{
        return (int)_state.CullMode;
	}
	
	public float GetDepthBias()
	{
        return (float)_state.DepthBias;
	}
	
	public int GetFillMode()
	{
        return (int)_state.FillMode;
	}
	
	public bool GetMultiSampleAntiAlias()
	{
        return _state.MultiSampleAntiAlias;
	}

    public bool GetScissorTestEnable()
	{
        return _state.ScissorTestEnable;
	}
	
	public float GetSlopeScaleDepthBias()
	{
        return _state.SlopeScaleDepthBias;
	}
	
	public void SetCullMode(int value)
	{
        _state.CullMode = (CullMode)value;
	}

    public void SetDepthBias(float value)
	{
        _state.DepthBias = value;
	}
	
	public void SetFillMode(int value)
	{
        _state.FillMode = (FillMode)value;
	}
	
	public void SetMultiSampleAntiAlias(bool value)
	{
        _state.MultiSampleAntiAlias = value;
	}

    public void SetScissorTestEnable(bool value)
	{
        _state.ScissorTestEnable = value;
	}
	
	public void SetSlopeScaleDepthBias(float value)
	{
        _state.SlopeScaleDepthBias = value;
	}
}

public class XNASamplerState 
{
    public SamplerState _state;

    public XNASamplerState(SamplerState state)
    {
        _state = state;
    }

    public static XNASamplerState Create()
    {
        return new XNASamplerState(new SamplerState());
    }

	public static XNASamplerState Create(int filter, int adressU, int adressV)
    {
        var state = new XNASamplerState(new SamplerState());
		state.SetAddressU(adressU);
		state.SetAddressV(adressV);
		state.SetFilter(filter);
		return state;
    }

    public static XNASamplerState AnisotropicClamp()
    {
        return new XNASamplerState(SamplerState.AnisotropicClamp);
    }

    public static XNASamplerState AnisotropicWrap()
    {
        return new XNASamplerState(SamplerState.AnisotropicWrap);
    }

    public static XNASamplerState LinearClamp()
    {
        return new XNASamplerState(SamplerState.LinearClamp);
    }

    public static XNASamplerState PointClamp()
    {
        return new XNASamplerState(SamplerState.PointClamp);
    }

    public static XNASamplerState PointWrap()
    {
        return new XNASamplerState(SamplerState.PointWrap);
    }

	public int GetAddressU()
    {
        return (int)_state.AddressU;
    }

	public int GetAddressV()
    {
        return (int)_state.AddressV;
    }

	public int GetAddressW()
    {
        return (int)_state.AddressW;
    }

	public int GetFilter()
    {
        return (int)_state.Filter;
    }

	public int GetMaxAnisotropy()
    {
        return (int)_state.MaxAnisotropy;
    }

	public int GetMaxMipLevel()
    {
        return (int)_state.MaxMipLevel;
    }

	public int GetMipMapLevelOfDetailBias()
    {
        return (int)_state.MipMapLevelOfDetailBias;
    }

	public void SetAddressU(int value)
    {
        _state.AddressU = (TextureAddressMode)value;
    }

	public void SetAddressV(int value)
    {
        _state.AddressV = (TextureAddressMode)value;
    }

	public void SetAddressW(int value)
    {
        _state.AddressW = (TextureAddressMode)value;
    }

	public void SetFilter(int value)
    {
        _state.Filter = (TextureFilter)value;
    }

	public void SetMaxAnisotropy(int value)
    {
        _state.MaxAnisotropy = value;
    }

	public void SetMaxMipLevel(int value)
    {
        _state.MaxMipLevel = value;
    }

    public void SetMipMapLevelOfDetailBias(int value)
    {
        _state.MipMapLevelOfDetailBias = value;
    }
} 

public class XNADepthStencilState
{
	public DepthStencilState _state;

    public XNADepthStencilState(DepthStencilState state)
    {
        _state = state;
    }

    public static XNADepthStencilState Create()
    {
        return new XNADepthStencilState(new DepthStencilState());
    }

    public static XNADepthStencilState Default()
    {
        return new XNADepthStencilState(DepthStencilState.Default);
    }

    public static XNADepthStencilState DepthRead()
    {
        return new XNADepthStencilState(DepthStencilState.DepthRead);
    }

    public static XNADepthStencilState None()
    {
        return new XNADepthStencilState(DepthStencilState.None);
    }

	public int GetCounterClockwiseStencilDepthBufferFail()
	{
        return (int)_state.CounterClockwiseStencilDepthBufferFail;
	}

	public int GetCounterClockwiseStencilFail()
	{
        return (int)_state.CounterClockwiseStencilFail;
	}
	 
	public int GetCounterClockwiseStencilFunction()
	{
         return (int)_state.CounterClockwiseStencilFunction;
	}
	 
	public int GetCounterClockwiseStencilPass()
	{
        return (int)_state.CounterClockwiseStencilPass;
	}
	
	public bool GetDepthBufferEnable()
	{
        return _state.DepthBufferEnable;
	}
	
	public int GetDepthBufferFunction()
	{
        return (int)_state.DepthBufferFunction;
	}
	
	public bool GetDepthBufferWriteEnable()
	{
        return _state.DepthBufferWriteEnable;
	}
	
	public int GetReferenceStencil()
	{
        return _state.ReferenceStencil;
	}
	
	public int GetStencilDepthBufferFail()
	{
        return (int)_state.StencilDepthBufferFail;
	}
	
	public bool GetStencilEnable()
	{
        return _state.StencilEnable;
	}
	
	public int GetStencilFail()
	{
        return (int)_state.StencilFail;
	}
	
	public int GetStencilFunction()
	{
        return (int)_state.StencilFunction;
	}
	
	public int GetStencilMask()
	{
        return _state.StencilMask;
	}
	
	public int GetStencilPass()
	{
        return (int)_state.StencilPass;
	}
	
	public int GetStencilWriteMask()
	{
        return (int)_state.StencilWriteMask;
	}
	
	public bool GetTwoSidedStencilMode()
	{
        return _state.TwoSidedStencilMode;
	}
	
	public void SetCounterClockwiseStencilDepthBufferFail(int value)
    {
        _state.CounterClockwiseStencilDepthBufferFail = (StencilOperation)value;
    }

	public void SetCounterClockwiseStencilFail(int value)
    {
        _state.CounterClockwiseStencilFail = (StencilOperation)value;
    }
 
	public void SetCounterClockwiseStencilFunction(int value)
    {
        _state.CounterClockwiseStencilFunction = (CompareFunction)value;
    }

	public void SetCounterClockwiseStencilPass(int value)
    {
        _state.CounterClockwiseStencilPass = (StencilOperation)value;
    }

	public void SetDepthBufferEnable(bool value)
    {
        _state.DepthBufferEnable = value;
    }
	
	public void SetDepthBufferFunction(int value)
    {
        _state.DepthBufferFunction = (CompareFunction)value;
    }

    public void SetDepthBufferWriteEnable(bool value)
    {
        _state.DepthBufferWriteEnable = value;
    }
	
	public void SetReferenceStencil(int value)
    {
        _state.ReferenceStencil = value;
    }
	
	public void SetStencilDepthBufferFail(int value)
    {
        _state.StencilDepthBufferFail = (StencilOperation)value;
    }

    public void SetStencilEnable(bool value)
    {
        _state.StencilEnable = value;
    }
	
	public void SetStencilFail(int value)
    {
        _state.StencilFail = (StencilOperation)value;
    }
	
	public void SetStencilFunction(int value)
    {
        _state.StencilFunction = (CompareFunction)value;
    }
	
	public void SetStencilMask(int value)
    {
        _state.StencilMask = value;
    }
	
	public void SetStencilPass(int value)
    {
        _state.StencilPass = (StencilOperation)value;
    }
	
	public void SetStencilWriteMask(int value)
    {
        _state.StencilWriteMask = value;
    }

    public void SetTwoSidedStencilMode(bool value)
    {
        _state.TwoSidedStencilMode = value;
    }
}

public abstract class XNATextureBase
{
    public Texture _texture;
	public int _surfaceFormat = 0; // TODO: Implement enum
	
    public XNATextureBase(Texture texture)
    {
        _texture = texture;
    }

    public int GetFormat()
    {
        return (int)_texture.Format;
    }

    public int GetLevelCount()
    {
        return _texture.LevelCount;
    }
}

public class XNATextureCube : XNATextureBase
{
    public TextureCube _textureCube;

	public XNATextureCube(TextureCube tex)
        : base(tex)
    {
        _textureCube = tex;
    }

    public void SetData(int face, BBDataBuffer data, int start, int count)
    {
        _textureCube.SetData<byte>((CubeMapFace)face, data._data, start, count);
    }

    public int Size()
    {
        return _textureCube.Size;
    }
}

public class XNATexture : XNATextureBase
{
    public Texture2D _texture2d;
	
    public XNATexture(Texture2D tex, string name)
        : base(tex)
    {
        _texture2d = tex;
    }
	
    public XNATexture(GraphicsDevice device, int width, int height, bool mipmap, int format)
        : base(new Texture2D(device, width, height, mipmap, SurfaceFormat.Color))
    {
        _texture2d = (Texture2D)_texture;
    }
	
	public void SetData(int level, BBDataBuffer data, int start, int count)
    {
		int w = _texture2d.Width;
		int h = _texture2d.Height;
		
		if (level != 0) {
			w = w/1>>level;
			h = h/1>>level;
		}

        _texture2d.SetData<byte>(level, new Rectangle(0, 0, w, h), data._data, start, count);
    }

    public int Width()
    {
        return _texture2d.Width;
    }

    public int Height()
    {
        return _texture2d.Height;
    }
};

public class XNAVertexBuffer
{
}

public class XNAIndexBuffer
{
}

public class XNAMesh
{
    public struct VERTEX : IVertexType
    {
        public Vector4 Position;
        public Vector4 Normal;
        public Vector4 Color;
        public Vector2 TextureCoordinate0;
        public Vector2 TextureCoordinate1;

        public VERTEX(Vector4 pos, Vector4 norm, Vector4 color, Vector2 tex0, Vector2 tex1)
        {
            Position = pos;
            Normal = norm;
            Color = color;
            TextureCoordinate0 = tex0;
            TextureCoordinate1 = tex1;
        }
		
        public readonly static VertexDeclaration VertexDeclaration = new VertexDeclaration
        (
            new VertexElement(0, VertexElementFormat.Vector3, VertexElementUsage.Position, 0),
            new VertexElement(16, VertexElementFormat.Vector3, VertexElementUsage.Normal, 0),
            new VertexElement(32, VertexElementFormat.Vector4, VertexElementUsage.Color, 0),
            new VertexElement(48, VertexElementFormat.Vector2, VertexElementUsage.TextureCoordinate, 0),
            new VertexElement(56, VertexElementFormat.Vector2, VertexElementUsage.TextureCoordinate, 1)
        );

        VertexDeclaration IVertexType.VertexDeclaration { get { return VertexDeclaration; } }        
    };

    public const int VERTEXSIZE = 64;
    public const int INDEXSIZE = 2;

	public GraphicsDevice _device;
    public VertexBuffer _vBuffer;
    public IndexBuffer _iBuffer;
    public short[] _iData;
	public byte[] _vData;
    //public VERTEX[] _vData;
    public int _iCnt;
    public int _vCnt;
    public bool _vboEnabled;
	public bool _dynamicMesh;
	
	public XNAMesh(GraphicsDevice device)
	{
		_device = device;
	}

    public void CreateVertexBuffer(int count, int flags)
    {
        try
        {
            _vboEnabled = true;

            if (_vBuffer != null)
            {
                _vBuffer.Dispose();
            }
			if (false) { //flags==0) {
				_vBuffer = new VertexBuffer(_device, typeof(VERTEX), count, BufferUsage.WriteOnly);
			} else {
				_vBuffer = new DynamicVertexBuffer(_device, typeof(VERTEX), count, BufferUsage.WriteOnly);
				_dynamicMesh = true;
			}
        }
        catch
        {
            _vboEnabled = false;
        }
    }

    public void CreateIndexBuffer(int count, int flags)
    {
        try
        {
            if (_iBuffer != null)
            {
                _iBuffer.Dispose();
            }
			if (false) { //flags==0) {
				_iBuffer = new IndexBuffer(_device, typeof(short), count, BufferUsage.WriteOnly);
			} else {
				_iBuffer = new DynamicIndexBuffer(_device, typeof(short), count, BufferUsage.WriteOnly);
				_dynamicMesh = true;
			}
        }
        catch
        {
            _vboEnabled = false;
        }
    }
	

	
    public void SetVertices(BBDataBuffer data, int count, int flags)
    {
        _vCnt = count;
        //if (flags == 0) // Shawn Hargreaves said:  For dynamic geometry, you should use DrawUserPrimitives //or dynamicvertexbuffer
        //{
			
            if (_vBuffer == null || _vBuffer.VertexCount != count)
            {
                CreateVertexBuffer(count, flags);
            }
        //} else if (flags== 1)
		//{
			//_dynamicMesh = true;
		//}

        if (_vData == null || _vData.Length != count)
        {
            //_vData = new VERTEX[count];
			//Buffer.BlockCopy(data._data, 0, _vData, 0, count*64);

        }

        // _vBuffer.SetData<float> does not work funnily enough, so always use VERTEX[]
        // since VBOs are only used for static meshes, there's no problem
        // TEST: Converting VerteDataBuffer to VERTEX(currently based on float, makes also a second copy unnecessary )
		/*
        for (int i = 0; i < count; ++i)
        {
            _vData[i] = new VERTEX(
                new Vector4(data.VertexX(i), data.VertexY(i), data.VertexZ(i), 1),
                new Vector4(data.VertexNX(i), data.VertexNY(i), data.VertexNZ(i), 1),
                new Vector4(data.VertexR(i), data.VertexG(i), data.VertexB(i), data.VertexA(i)),
                new Vector2(data.VertexU(i, 0), data.VertexV(i, 0)),
                new Vector2(data.VertexU(i, 1), data.VertexV(i, 1)));
        }
		*/
		
		_vData = data._data;
		
        if (_vboEnabled)
        {
			if(_dynamicMesh) {
				DynamicVertexBuffer dvb = _vBuffer as DynamicVertexBuffer;
				if (dvb != null) dvb.SetData<byte>(data._data, 0, count *VERTEXSIZE, SetDataOptions.Discard); //keeps tile rendering ok
			} else {
				_vBuffer.SetData<byte>(data._data, 0, count *VERTEXSIZE);
			//_vBuffer.SetData<VERTEX>(_vData, 0, count );
			}
        }
    }

    public void SetIndices(BBDataBuffer data, int count, int flags)
    {
        // use short[] istead of DataBuffer in miniB3d, 
		// then data is not needed to be copied
        _iCnt = count;
        if (_iData == null || _iData.Length != count)
        {
           // _iData = new short[count];
			
        }
		
		/*
        for( int i = 0; i< count; ++i)
        {
            _iData[i] = (short)data.PeekShort(i*2);
        }
		*/
        
		//_iData = Array.ConvertAll(data._data, b => (short)b);
		
		_iData = new short[count];
		Buffer.BlockCopy(data._data, 0, _iData, 0, count*2);
		
        if (_vboEnabled)
        {
            if (_iBuffer == null || _iBuffer.IndexCount != count)
            {
                CreateIndexBuffer(count, flags);
            }

            //_iBuffer.SetData<byte>(data._data, 0, count * INDEXSIZE);
			if(_dynamicMesh) {
				DynamicIndexBuffer dvi = _iBuffer as DynamicIndexBuffer;
				if (dvi != null) dvi.SetData<short>(_iData, 0, count, SetDataOptions.Discard );
			} else {
				_iBuffer.SetData<short>(_iData, 0, count); 
			}
        }
    }

	public void Clear()
	{
        _vData = null;
        _iData = null;
		
		if( _vBuffer != null ) 
		{
			_vBuffer.Dispose();
			_vBuffer = null;
		}
		
		if( _iBuffer != null ) 
		{
			_iBuffer.Dispose();
			_iBuffer = null;
		}
	}
	    
    public void Bind()
    {
        if (_vboEnabled)
        {
            _device.Indices = _iBuffer;
            _device.SetVertexBuffer(_vBuffer);
        }
    }

    public void Render()
    {
        if (_vboEnabled) // && !_dynamicMesh) // Render from vertexbuffer object
        {
            _device.DrawIndexedPrimitives(PrimitiveType.TriangleList, 0, 0, _vCnt , 0, _iCnt / 3);
        }
        else // Render from arrays 
        {
            _device.DrawUserIndexedPrimitives<byte>(PrimitiveType.TriangleList, _vData, 0, _vCnt  , _iData, 0, _iCnt / 3, VERTEX.VertexDeclaration);
        }
    }
};

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public class Utility
{
    public static double RAD_TO_DEG = 57.2957795130823208767981548141052;
    public static double DEG_TO_RAD = 0.0174532925199432957692369076848861;

    public static void MatrixTranslate(ref Matrix mat, Vector3 vec)
    {
        mat.M41 += mat.M11 * vec.X + mat.M21 * vec.Y + mat.M31 * vec.Z;
        mat.M42 += mat.M12 * vec.X + mat.M22 * vec.Y + mat.M32 * vec.Z;
        mat.M43 += mat.M13 * vec.X + mat.M23 * vec.Y + mat.M33 * vec.Z;
    }

    public static void MatrixRotate(ref Matrix mat, Vector3 vec)
    {
  // yaw

        float cos_ang = (float)Cos((double)vec.Y);
        float sin_ang = (float)Sin((double)vec.Y);
	
		float m11 = mat.M11 * cos_ang + mat.M31 * -sin_ang;
		float m12 = mat.M12 * cos_ang + mat.M32 * -sin_ang;
		float m13 = mat.M13 * cos_ang + mat.M33 * -sin_ang;
		
		mat.M31 = mat.M11 * sin_ang + mat.M31 * cos_ang;
		mat.M32 = mat.M12 * sin_ang + mat.M32 * cos_ang;
		mat.M33 = mat.M13 * sin_ang + mat.M33 * cos_ang;

        mat.M11 = m11;
        mat.M12 = m12;
        mat.M13 = m13;
		
  // pitch

        cos_ang = (float)Cos((double)vec.X);
        sin_ang = (float)Sin((double)vec.X);
	
        float m21 = mat.M21 * cos_ang + mat.M31 * sin_ang;
		float m22 = mat.M22 * cos_ang + mat.M32 * sin_ang;
		float m23 = mat.M23 * cos_ang + mat.M33 * sin_ang;
        
        mat.M31 = mat.M21 * -sin_ang + mat.M31 * cos_ang;
		mat.M32 = mat.M22 * -sin_ang + mat.M32 * cos_ang;
		mat.M33 = mat.M23 * -sin_ang + mat.M33 * cos_ang;
		
		mat.M21=m21;
		mat.M22=m22;
		mat.M23=m23;
		
  // roll

        cos_ang = (float)Cos((double)vec.Z);
        sin_ang = (float)Sin((double)vec.Z);

		m11 = mat.M11 * cos_ang + mat.M21 * sin_ang;
		m12 = mat.M12 * cos_ang + mat.M22 * sin_ang;
		m13 = mat.M13 * cos_ang + mat.M23 * sin_ang;
		
		mat.M21 = mat.M11 * -sin_ang + mat.M21 * cos_ang;
		mat.M22 = mat.M12 * -sin_ang + mat.M22 * cos_ang;
		mat.M23 = mat.M13 * -sin_ang + mat.M23 * cos_ang;
		
		mat.M11 = m11;
		mat.M12 = m12;
        mat.M13 = m13;
    }

    public static void MatrixScale(ref Matrix mat, Vector3 vec)
    {
        mat.M11 *= vec.X;
        mat.M12 *= vec.X;
        mat.M13 *= vec.X;

        mat.M21 *= vec.Y;
        mat.M22 *= vec.Y;
        mat.M23 *= vec.Y;

        mat.M31 *= vec.Z;
        mat.M32 *= vec.Z;
        mat.M33 *= vec.Z;
    }

    public static Matrix MatrixCopy(Matrix m)
    {
        return new Matrix(m.M11, m.M12, m.M13, m.M14,
                            m.M21, m.M22, m.M23, m.M24,
                            m.M31, m.M32, m.M33, m.M34,
                            m.M41, m.M42, m.M43, m.M44);

    }

    public static void MatrixOverride(ref Matrix dest, Matrix src)
    {
        dest.M11 = src.M11;
        dest.M12 = src.M12;
        dest.M13 = src.M13;
        dest.M14 = src.M14;
        dest.M21 = src.M21;
        dest.M22 = src.M22;
        dest.M23 = src.M23;
        dest.M24 = src.M24;
        dest.M31 = src.M31;
        dest.M32 = src.M32;
        dest.M33 = src.M33;
        dest.M34 = src.M34;
        dest.M41 = src.M41;
        dest.M42 = src.M42;
        dest.M43 = src.M43;
        dest.M44 = src.M44;

    }

    public static double Cos(double x)
    {
        return Math.Cos(x * DEG_TO_RAD);
    }

    public static double tan(double x)
    {
        return Math.Tan(x * DEG_TO_RAD);
    }

    public static double Sin(double x)
    {
        return Math.Sin(x * DEG_TO_RAD);
    }

    public static double ASin(double x)
    {
        return Math.Asin(x) * RAD_TO_DEG;
    }

    public static double ACos(double x)
    {
        return Math.Acos(x) * RAD_TO_DEG;
    }

    public static double ATan(double x)
    {
        return Math.Atan(x) * RAD_TO_DEG;
    }

    public static double ATan2(double y, double x)
    {
        return Math.Atan2(y, x) * RAD_TO_DEG;
    }
};


public class XNAVector
{
	public Vector3 _vector;
	
	public XNAVector(float x,float y,float z)
	{
		_vector = new Vector3(x,y,z);
	}
	
	public static XNAVector CreateVector(float x,float y,float z)
	{
		return new XNAVector(x,y,z);
	}
	
	public float X() 
	{
		return _vector.X;
	}
	
	public float Y() 
	{
		return _vector.Y;
	}
	
	public float Z() 
	{
		return _vector.Z;
	}
	
	/*
	Method Set(x#,y#,z#)
		_x = x
		_y = y
		_z = z
		_w = 3
	End
	
	Method Add(vec:Vector)
		_x+=vec._x
		_y+=vec._y
		_z+=vec._z
	End 
	
	Method Subtract(vec:Vector)
		_x-=vec._x
		_y-=vec._y
		_z-=vec._z
	End 
	
	Method Multiply(value#)
		_x*=value
		_y*=value
		_z*=value
	End 
	
	Method Divide(val#)
		_x/=val
		_y/=val
		_z/=val
	End 
	
	Method Dot:Float(vec:Vector)
		Return (_x*vec._x)+(_y*vec._y)+(_z*vec._z)
	End 
	
	Method Cross:Vector0(vec:Vector)
		Return new Vector0((_y*vec._z)-(_z*vec._y),(_z*vec._x)-(_x*vec._z),(_x*vec._y)-(_y*vec._x))
	End 
	
	Method Normalize()
		Local d#=1.0/Sqr(_x*_x+_y*_y+_z*_z)
		_x*=d
		_y*=d
		_z*=d
	End 
	
	Method Length#()	
		Return Sqr(_x*_x+_y*_y+_z*_z)
	End 
	
	Method SquaredLength#()
		Return _x*_x+_y*_y+_z*_z
	End Method
	
	Method SetLength(value#)
		Normalize()
		_x*=value
		_y*=value
		_z*=value
	End Method
	
	Method Compare( q:Vector )
		If _x-q._x>EPSILON Return 1
		If _q.x-_x>EPSILON Return -1
		If _y-q._y>EPSILON Return 1
		If _q.y-_y>EPSILON Return -1
		If _z-q._z>EPSILON Return 1
		If q._z-_z>EPSILON Return -1
		Return 0
	End 
	*/
}

public class XNADirectionalLight 
{
	public DirectionalLight _light;
	
	public XNADirectionalLight(DirectionalLight light)
	{
		_light = light;
	}
	
	public void SetDiffuseColor(float r, float g, float b) 
	{
		_light.DiffuseColor = new Vector3(r,g,b);
	}
	
	public void SetDirection(float x, float y, float z)
	{
		_light.Direction = new Vector3(x,y,z);
	}
	
	public bool GetEnabled() 
	{
		return _light.Enabled;
	}
	
	public void SetEnabled(bool value)
	{
		_light.Enabled = value;
	}

	public void SetSpecularColor(float r, float g, float b) 
	{
		_light.SpecularColor = new Vector3(r,g,b);
	}
}



public class XNAEnvironmentMapEffect : XNAEffect
{
    public EnvironmentMapEffect _environmentEffect;
    public XNADirectionalLight _light0;
    public XNADirectionalLight _light1;
    public XNADirectionalLight _light2;

    public XNAEnvironmentMapEffect(XNAGraphicsDevice device, EnvironmentMapEffect effect)
        : base(effect, device)
    {
        _environmentEffect = effect;
        _light0 = new XNADirectionalLight(effect.DirectionalLight0);
        _light1 = new XNADirectionalLight(effect.DirectionalLight1);
        _light2 = new XNADirectionalLight(effect.DirectionalLight2);
    }

    public void SetEnvironmentMap(XNATextureCube texture)
    {
        _environmentEffect.EnvironmentMap = texture._textureCube;
    }

    public void SetEnvironmentMapAmount (float value)
    {
        _environmentEffect.EnvironmentMapAmount = value;
    }

    public void SetEnvironmentMapSpecular (float x, float y, float z)
    {
        _environmentEffect.EnvironmentMapSpecular = new Vector3(x, y, z);
    }

    public void SetFresnelFactor(float value)
    {
        _environmentEffect.FresnelFactor = value;
    }

    public void SetAlpha(float alpha)
    {
        _environmentEffect.Alpha = alpha;
    }

    public void SetDiffuseColor(float r, float g, float b)
    {
        _environmentEffect.DiffuseColor = new Vector3(r, g, b);
    }

    public void SetEmissiveColor(float r, float g, float b)
    {
        _environmentEffect.EmissiveColor = new Vector3(r, g, b);
    }


    // IEffectLights - dont get it...impl. of IEffectLights seems incomplete

    public override void SetAmbientLightColor(float r, float g, float b)
    {
        _environmentEffect.AmbientLightColor = new Vector3(r, g, b);
    }

    public override XNADirectionalLight GetDirectionalLight0()
    {
        return _light0;
    }

    public override XNADirectionalLight GetDirectionalLight1()
    {
        return _light1;
    }

    public override XNADirectionalLight GetDirectionalLight2()
    {
        return _light2;
    }

	
    // IEffectFog

    public override void SetFogColor(float r, float g, float b)
    {
        _environmentEffect.FogColor = new Vector3(r, g, b);
    }

    public override bool GetFogEnabled()
    {
        return _environmentEffect.FogEnabled;
    }

    public override void SetFogEnabled(bool value)
    {
        _environmentEffect.FogEnabled = value;
    }

    public override void SetFogEnd(float value)
    {
        _environmentEffect.FogEnd = value;
    }

    public override void SetFogStart(float value)
    {
        _environmentEffect.FogStart = value;
    }


    // IEffectMatrices

    public override void SetProjection(float fieldOfView, float aspectRatio, float near, float far)
    {
        SetProjection<EnvironmentMapEffect>(_environmentEffect, fieldOfView, aspectRatio, near, far);
    }

    public override void SetView(float px, float py, float pz, float rx, float ry, float rz, float sx, float sy, float sz)
    {
        SetView<EnvironmentMapEffect>(_environmentEffect, px, py, pz, rx, ry, rz, sx, sy, sz);
    }

    public override void SetWorld(float px, float py, float pz, float rx, float ry, float rz, float sx, float sy, float sz)
    {
        SetWorld<EnvironmentMapEffect>(_environmentEffect, px, py, pz, rx, ry, rz, sx, sy, sz);
    }
}


public class XNABasicEffect : XNAEffect
{
	public BasicEffect _basicEffect;
	public XNADirectionalLight _light0;
	public XNADirectionalLight _light1;
	public XNADirectionalLight _light2;
	
	public XNABasicEffect(XNAGraphicsDevice device, BasicEffect effect) 
		: base(effect,device)
	{
		_basicEffect = effect;
		_light0 = new XNADirectionalLight(effect.DirectionalLight0);
		_light1 = new XNADirectionalLight(effect.DirectionalLight1);
		_light2 = new XNADirectionalLight(effect.DirectionalLight2);
	}
	
	public void SetAlpha(float alpha)
	{
		_basicEffect.Alpha = alpha;
	}

    public override void SetAmbientLightColor(float r, float g, float b)	
	{
		_basicEffect.AmbientLightColor = new Vector3(r,g,b);
	}
		
	public void SetDiffuseColor(float r, float g, float b)	
	{
		_basicEffect.DiffuseColor  = new Vector3(r,g,b);
	}

    public override XNADirectionalLight GetDirectionalLight0()	
	{
		return _light0;
	}

    public override XNADirectionalLight GetDirectionalLight1()	
	{
		return _light1;
	}

    public override XNADirectionalLight GetDirectionalLight2()	
	{
		return _light2;
	}
		
	public void SetEmissiveColor(float r, float g, float b)	
	{
		_basicEffect.EmissiveColor  = new Vector3(r,g,b);
	}
	
	public override void SetFogColor(float r, float g, float b)	
	{
		_basicEffect.FogColor  = new Vector3(r,g,b);
	}

	public override bool GetFogEnabled()
	{
		return _basicEffect.FogEnabled;
	}
	
	public override void SetFogEnabled(bool value)	
	{
		_basicEffect.FogEnabled = value;
	}
		
	public override void SetFogEnd(float value)	
	{
		_basicEffect.FogEnd = value;
	}
	
	public override void SetFogStart(float value)	
	{
		_basicEffect.FogStart = value;
	}

    public override void SetLightingEnabled(bool value)	
	{
		_basicEffect.LightingEnabled = value;
	}

    public override void SetPreferPerPixelLighting(bool value)	
	{
		_basicEffect.PreferPerPixelLighting = value;
	}

	public void SetSpecularColor(float r, float g, float b)	
	{
		_basicEffect.SpecularColor  = new Vector3(r,g,b);
	}

	public void SetSpecularPower(float value)	
	{
		_basicEffect.SpecularPower = value;
	}
	
	public void SetTexture(XNATexture value)	
	{
		_basicEffect.Texture = value._texture2d;
	}
		
	public void SetTextureEnabled(bool value)		
	{
		_basicEffect.TextureEnabled = value;
	}
	
	public void SetVertexColorEnabled(bool value)		
	{
		_basicEffect.VertexColorEnabled = value;
	}
	
	public override void SetProjection(float fieldOfView, float aspectRatio, float near, float far) 
	{
	    SetProjection<BasicEffect>(_basicEffect, fieldOfView, aspectRatio, near, far );
    }
	
	public override void SetView(float px, float py, float pz, float rx, float ry, float rz, float sx, float sy, float sz)
	{
        SetView<BasicEffect>(_basicEffect, px, py, pz, rx, ry, rz, sx, sy, sz);
	}
	
	public override void SetWorld(float px, float py, float pz, float rx, float ry, float rz, float sx, float sy, float sz)
	{
        SetWorld<BasicEffect>(_basicEffect, px, py, pz, rx, ry, rz, sx, sy, sz);
	}
	
	public override void SetWorldMat(float[] mat)
	{
		SetWorldMat<BasicEffect>(_basicEffect, mat);
	}
	public override void SetProjMat(float[] mat)
	{
		SetProjMat<BasicEffect>(_basicEffect, mat);
	}
	public override void SetViewMat(float[] mat)
	{
		SetViewMat<BasicEffect>(_basicEffect, mat);
	}
};

public class XNAEffect
{
	public Effect _effect;
	public XNAGraphicsDevice _device;
	
	public XNAEffectTechnique _curentTechnique;
	public Dictionary<string,XNAEffectTechnique> _techniques = new Dictionary<string,XNAEffectTechnique>();
	public Dictionary<string,XNAEffectParameter> _parameters = new Dictionary<string,XNAEffectParameter>();
	
	public XNAEffect(Effect effect,XNAGraphicsDevice device)
	{
		_effect = effect;
		_device = device;
		
		foreach(var technique in _effect.Techniques)
        {
			_techniques.Add(  technique.Name ,new XNAEffectTechnique(technique) );
        }
		
		foreach(var parameter in _effect.Parameters)
        {
			_parameters.Add(  parameter.Name ,new XNAEffectParameter(parameter) );
        }
		
		SetCurrentTechnique(_techniques[_effect.CurrentTechnique.Name]);
	}
		
	public XNAEffectTechnique GetCurrentTechnique()
	{
		return _curentTechnique;
	}
	
	public void SetCurrentTechnique(XNAEffectTechnique technique)
	{
		_curentTechnique = technique;
		_effect.CurrentTechnique = technique._technique;
	}
	
	public XNAGraphicsDevice GetGraphicsDevice()
	{
		return this._device;
	}
	
	public string GetName()
	{
		return _effect.Name;
	}
	
	public XNAEffectParameter GetParameter(string name) 
	{
		return _parameters[name];
	}
	
	public int CountParameters() 
	{
		return _parameters.Count;
	}
	
	public XNAEffectTechnique GetTechnique(string name) 
	{
		return _techniques[name];
	}
	
	public int CountTechniques() 
	{
		return _techniques.Count;
	}	
	
	// IEffectMatrices
	
	public virtual void SetProjection(float fieldOfView, float aspectRatio, float near, float far) 
	{
	}
	
	public virtual void SetView(float px, float py, float pz, float rx, float ry, float rz, float sx, float sy, float sz)
	{
	}
	
	public virtual void SetWorld(float px, float py, float pz, float rx, float ry, float rz, float sx, float sy, float sz)
	{
	}
	
	public virtual void SetWorldMat( float[] mat) {}
	public virtual void SetViewMat( float[] mat) {}
	public virtual void SetProjMat( float[] mat) {}
	
	
	// IEffectFog
	
	public virtual void SetFogColor(float r, float g, float b)	
	{
	}

	public virtual bool GetFogEnabled()
	{
		return false;
	}
	
	public virtual void SetFogEnabled(bool value)	
	{
	}
		
	public virtual void SetFogEnd(float value)	
	{
	}
	
	public virtual void SetFogStart(float value)	
	{
	}
	
	
	// IEffectLights
	
	public virtual XNADirectionalLight GetDirectionalLight0()	
	{
		return null;
	}
		
	public virtual XNADirectionalLight GetDirectionalLight1()	
	{
		return null;
	}
	
	public virtual XNADirectionalLight GetDirectionalLight2()	
	{
		return null;
	}

	public virtual void SetLightingEnabled(bool value)	
	{
	}
	
	public virtual void SetPreferPerPixelLighting(bool value)	
	{
	}
	
	public virtual void SetAmbientLightColor(float r, float g, float b)	
	{
	}
	
    // helper

    public static void SetProjection<T>(T effect, float fieldOfView, float aspectRatio, float near, float far)
        where T : IEffectMatrices 
    {
        float fov = Math.Min((float)Math.PI - 0.00001f, Math.Max(0.00001f, (float)Utility.DEG_TO_RAD * fieldOfView));
        effect.Projection = Matrix.CreatePerspectiveFieldOfView(fov, aspectRatio, near, far);
    }

    public static void SetView<T>(T effect, float px, float py, float pz, float rx, float ry, float rz, float sx, float sy, float sz)
        where T : IEffectMatrices 

    {
        var _mat = Matrix.Identity;

        Utility.MatrixTranslate(ref _mat, new Vector3(px, py, -pz));
        Utility.MatrixRotate(ref _mat, new Vector3(-rx, ry, rz));
        Utility.MatrixScale(ref _mat, new Vector3(sx, sy, sz));

        // only rotation
        Matrix mCam = new Matrix(_mat.M11, _mat.M12, _mat.M13, _mat.M14,
                                 _mat.M21, _mat.M22, _mat.M23, _mat.M24,
                                 _mat.M31, _mat.M32, _mat.M33, _mat.M34,
                                 _mat.M41, _mat.M42, _mat.M43, _mat.M44);

        mCam.M41 = 0.0f;
        mCam.M42 = 0.0f;
        mCam.M43 = 0.0f;

        // Calculate Lookat
        Vector3 vWorldLook = Vector3.TransformNormal(Vector3.Forward, mCam);
        Vector3 vUp = Vector3.TransformNormal(Vector3.Up, mCam);
        Vector3 vPos = new Vector3(_mat.M41, _mat.M42, _mat.M43);
        Vector3 vLookAt = vPos + vWorldLook;

        effect.View = Matrix.CreateLookAt(vPos, vLookAt, vUp * 1);
    }

    public static void SetWorld<T>(T effect, float px, float py, float pz, float rx, float ry, float rz, float sx, float sy, float sz)
        where T : IEffectMatrices
    {
        var _mat = Matrix.Identity;

        Utility.MatrixTranslate(ref _mat, new Vector3(px, py, -pz));
        Utility.MatrixRotate(ref _mat, new Vector3(rx, ry, rz));
        Utility.MatrixScale(ref _mat, new Vector3(sx, sy, sz));

        effect.World = _mat;
    }
	
	public static void SetWorldMat<T>(T effect, float[] mat)
		where T : IEffectMatrices
	{
		effect.World = new Matrix(mat[0],mat[1],mat[2],mat[3],mat[4],mat[5],mat[6],mat[7],mat[8],mat[9],mat[10],mat[11],mat[12],mat[13],mat[14],mat[15]);
	}
	
	public static void SetProjMat<T>(T effect, float[] mat)
		where T : IEffectMatrices
	{
		effect.Projection = new Matrix(mat[0],mat[1],mat[2],mat[3],mat[4],mat[5],mat[6],mat[7],mat[8],mat[9],mat[10],mat[11],mat[12],mat[13],mat[14],mat[15]);
	}
	
	public static void SetViewMat<T>(T effect, float[] mat)
		where T : IEffectMatrices
	{
		effect.View = new Matrix(mat[0],mat[1],mat[2],mat[3],mat[4],mat[5],mat[6],mat[7],mat[8],mat[9],mat[10],mat[11],mat[12],mat[13],mat[14],mat[15]);
	}
};


public class XNAEffectTechnique
{
	public EffectTechnique _technique;
	public XNAEffectPass[] _passes;
	
	public XNAEffectTechnique(EffectTechnique technique) 
	{
		_technique = technique;
		_passes = new XNAEffectPass[_technique.Passes.Count];
		for( int i = 0; i< _technique.Passes.Count; ++i)
		{
			_passes[i] = new XNAEffectPass(_technique.Passes[i]);
		}
	}
	
	public string GetName()
	{
		return _technique.Name;
	}
	
	public XNAEffectPass[] GetPasses()
	{
		return _passes;
	}
}

public class XNAEffectPass
{
	public EffectPass _pass;
	
	public XNAEffectPass(EffectPass pass)
	{
		_pass = pass;
	}
	
	public string GetName()
	{
		return _pass.Name;
	}
	
	public void Apply()
	{
		_pass.Apply();
	}
}

public class XNAEffectParameter
{
	public EffectParameter _parameter;
	
	public XNAEffectParameter(EffectParameter parameter)
	{
		_parameter = parameter;
	}
	
	public int GetParameterClass() 
	{
		return (int)_parameter.ParameterClass;
	}
	
	public int GetParameterType() 
	{
		return (int)_parameter.ParameterType;
	}
	
	public string GetName() 	
	{
		return _parameter.Name;
	}
	
	public string GetSemantic() 	
	{
	    return _parameter.Semantic;
	}
	
	public void  SetBool(bool value)	
	{
		_parameter.SetValue(value);
	}
	
	public void  SetBoolArray(bool[] value)		
	{
		_parameter.SetValue(value);
	}
	
	public void  SetInt(int value)	
	{
		_parameter.SetValue(value);
	}
		
	public void  SetIntArray(int[] value)	
	{
		_parameter.SetValue(value);
	}
	
	public void  SetFloat(float value)	
	{
		_parameter.SetValue(value);
	}
	
	public void  SetFloatArray(float[] value)	
	{
		_parameter.SetValue(value);
	}
	
	public void  SetString(string value)	
	{
		_parameter.SetValue(value);
	}
	
	public void  SetTexture(XNATexture value)	
	{
		_parameter.SetValue(value._texture);
	}
	
	/*
	public void  SetValue(Matrix value)	
	{
		_parameter.SetValue(value);
	}
	
	public void  SetValue(Matrix[] value)	
	{
		_parameter.SetValue(value);
	}
		
	public void  SetValue(Quaternion value)	
	{
		_parameter.SetValue(value);
	}
	
	public void  SetValue(Quaternion[] value)		
	{
		_parameter.SetValue(value);
	}
	
	public void  SetValue(Vector value)	
	{
		_parameter.SetValue(value);
	}
	*/
}

public class XNAColor
{
	public Color _color;
	
	public static XNAColor White()
	{
		return new XNAColor(1,1,1,1);
	}
	
	public static XNAColor Black()
	{
		return new XNAColor(0,0,0,1);
	}
	
	public static XNAColor Red()
	{
		return new XNAColor(1,0,0,1);
	}
	
	public static XNAColor Blue()
	{
		return new XNAColor(0,0,1,1);
	}
	
	public static XNAColor FromARGB(float r, float g, float b, float a)
	{
		return new XNAColor(r,g,b,a);
	}
	
	public XNAColor(float r, float g, float b, float a)
	{
		_color = new Color(r,g,b,a);
	}
	
	public XNAColor(Color color)
	{
		_color = color;
	}
	
	public float GetR()
	{
		return (float)_color.R / 255.0f;
	}
	
	public float GetG()
	{
		return (float)_color.G/ 255.0f;
	}
	
	public float GetB()
	{
		return (float)_color.B/ 255.0f;
	}
	
	public float GetA()
	{
		return (float)_color.A/ 255.0f;
	}
	
	public void SetR(float value)
	{
		_color.R = (byte)(value*255.0f);
	}
	
	public void SetG(float value)
	{
		_color.G = (byte)(value*255.0f);
	}
	
	public void SetB(float value)
	{
		_color.B = (byte)(value*255.0f);
	}
	
	public void SetA(float value)
	{
		_color.A = (byte)(value*255.0f);
	}
}

class XNAMatrix
{
	public Matrix mat;
	
	public XNAMatrix()
	{
		mat = new Matrix();
	}
	
	public static XNAMatrix MatrixIdentity()
	{
		var matrix = new XNAMatrix();
		matrix.mat = Matrix.Identity;
		return matrix;
	}
	
	public static XNAMatrix CreateMatrixA()
	{
		var matrix = new XNAMatrix();
		matrix.mat = new Matrix();
		return matrix;
	}
	
	public static XNAMatrix CreateMatrixB(XNAMatrix mat)
	{
		return null;// Todo
	}
	
	public float GetM11(){return mat.M11;}
	public float GetM12(){return mat.M12;}
	public float GetM13(){return mat.M13;}
	public float GetM14(){return mat.M14;}
	public float GetM21(){return mat.M21;}
	public float GetM22(){return mat.M22;}
	public float GetM23(){return mat.M23;}
	public float GetM24(){return mat.M24;}
	public float GetM31(){return mat.M31;}
	public float GetM32(){return mat.M32;}
	public float GetM33(){return mat.M33;}
	public float GetM34(){return mat.M34;}
	public float GetM41(){return mat.M41;}
	public float GetM42(){return mat.M42;}
	public float GetM43(){return mat.M43;}
	public float GetM44(){return mat.M44;}
	
	public void SetM11(float value){mat.M11 = value;}
	public void SetM12(float value){mat.M12 = value;}
	public void SetM13(float value){mat.M13 = value;}
	public void SetM14(float value){mat.M14 = value;}
	public void SetM21(float value){mat.M21 = value;}
	public void SetM22(float value){mat.M22 = value;}
	public void SetM23(float value){mat.M23 = value;}
	public void SetM24(float value){mat.M24 = value;}
	public void SetM31(float value){mat.M31 = value;}
	public void SetM32(float value){mat.M32 = value;}
	public void SetM33(float value){mat.M33 = value;}
	public void SetM34(float value){mat.M34 = value;}
	public void SetM41(float value){mat.M41 = value;}
	public void SetM42(float value){mat.M42 = value;}
	public void SetM43(float value){mat.M43 = value;}
	public void SetM44(float value){mat.M44 = value;}
	
	public static XNAMatrix CreateMatrixC(XNAMatrix mat)
	{
		var matrix = new XNAMatrix();
		matrix.mat = new Matrix(mat.mat.M11, mat.mat.M12, mat.mat.M13, mat.mat.M14,
                   mat.mat.M21, mat.mat.M22, mat.mat.M23, mat.mat.M24,
                   mat.mat.M31, mat.mat.M32, mat.mat.M33, mat.mat.M34,
                   mat.mat.M41, mat.mat.M42, mat.mat.M43, mat.mat.M44);
		return matrix;
	}
	
	public void Overwrite(XNAMatrix matrix)
	{
		mat.M11 = matrix.mat.M11;
        mat.M12 = matrix.mat.M12;
        mat.M13 = matrix.mat.M13;
        mat.M14 = matrix.mat.M14;
        mat.M21 = matrix.mat.M21;
        mat.M22 = matrix.mat.M22;
        mat.M23 = matrix.mat.M23;
        mat.M24 = matrix.mat.M24;
        mat.M31 = matrix.mat.M31;
        mat.M32 = matrix.mat.M32;
        mat.M33 = matrix.mat.M33;
        mat.M34 = matrix.mat.M34;
        mat.M41 = matrix.mat.M41;
        mat.M42 = matrix.mat.M42;
        mat.M43 = matrix.mat.M43;
        mat.M44 = matrix.mat.M44;
	}
	
	public XNAMatrix Inverse()
	{
		var m = new XNAMatrix();
		m.mat = Matrix.Invert(mat);
		return m;
	}
	
	public XNAMatrix Multiply(XNAMatrix matrix)
	{
		var m = new XNAMatrix();
		m.mat = Matrix.Multiply(mat,matrix.mat);
		return m;
	}
	
	public void Translate(float x,float y,float z)
	{
		mat.M41 += mat.M11 * x + mat.M21 * y + mat.M31 * z;
        mat.M42 += mat.M12 * x + mat.M22 * y + mat.M32 * z;
        mat.M43 += mat.M13 * x + mat.M23 * y + mat.M33 * z;
	}
	
	public void Scale(float x,float y,float z)
	{
		mat.M11 *= x;
        mat.M12 *= x;
        mat.M13 *= x;

        mat.M21 *= y;
        mat.M22 *= y;
        mat.M23 *= y;

        mat.M31 *= z;
        mat.M32 *= z;
        mat.M33 *= z;
	}
	
	public void Rotate(float x,float y,float z)
	{
		 // yaw

        float cos_ang = (float)Utility.Cos((double)y);
        float sin_ang = (float)Utility.Sin((double)y);
	
		float m11 = mat.M11 * cos_ang + mat.M31 * -sin_ang;
		float m12 = mat.M12 * cos_ang + mat.M32 * -sin_ang;
		float m13 = mat.M13 * cos_ang + mat.M33 * -sin_ang;
		
		mat.M31 = mat.M11 * sin_ang + mat.M31 * cos_ang;
		mat.M32 = mat.M12 * sin_ang + mat.M32 * cos_ang;
		mat.M33 = mat.M13 * sin_ang + mat.M33 * cos_ang;

        mat.M11 = m11;
        mat.M12 = m12;
        mat.M13 = m13;
		
  		// pitch

        cos_ang = (float)Utility.Cos((double)x);
        sin_ang = (float)Utility.Sin((double)x);
	
        float m21 = mat.M21 * cos_ang + mat.M31 * sin_ang;
		float m22 = mat.M22 * cos_ang + mat.M32 * sin_ang;
		float m23 = mat.M23 * cos_ang + mat.M33 * sin_ang;
        
        mat.M31 = mat.M21 * -sin_ang + mat.M31 * cos_ang;
		mat.M32 = mat.M22 * -sin_ang + mat.M32 * cos_ang;
		mat.M33 = mat.M23 * -sin_ang + mat.M33 * cos_ang;
		
		mat.M21=m21;
		mat.M22=m22;
		mat.M23=m23;
		
  		// roll

        cos_ang = (float)Utility.Cos((double)z);
        sin_ang = (float)Utility.Sin((double)z);

		m11 = mat.M11 * cos_ang + mat.M21 * sin_ang;
		m12 = mat.M12 * cos_ang + mat.M22 * sin_ang;
		m13 = mat.M13 * cos_ang + mat.M23 * sin_ang;
		
		mat.M21 = mat.M11 * -sin_ang + mat.M21 * cos_ang;
		mat.M22 = mat.M12 * -sin_ang + mat.M22 * cos_ang;
		mat.M23 = mat.M13 * -sin_ang + mat.M23 * cos_ang;
		
		mat.M11 = m11;
		mat.M12 = m12;
        mat.M13 = m13;
	}
	
	public void RotatePitch(float ang)
	{
		float cos_ang = (float)Utility.Cos((double)ang);
        float sin_ang = (float)Utility.Sin((double)ang);
	
        float m21 = mat.M21 * cos_ang + mat.M31 * sin_ang;
		float m22 = mat.M22 * cos_ang + mat.M32 * sin_ang;
		float m23 = mat.M23 * cos_ang + mat.M33 * sin_ang;
        
        mat.M31 = mat.M21 * -sin_ang + mat.M31 * cos_ang;
		mat.M32 = mat.M22 * -sin_ang + mat.M32 * cos_ang;
		mat.M33 = mat.M23 * -sin_ang + mat.M33 * cos_ang;
		
		mat.M21=m21;
		mat.M22=m22;
		mat.M23=m23;
	}
	
	public void RotateYaw(float ang)
	{
		float cos_ang = (float)Utility.Cos((double)ang);
        float sin_ang = (float)Utility.Sin((double)ang);
	
		float m11 = mat.M11 * cos_ang + mat.M31 * -sin_ang;
		float m12 = mat.M12 * cos_ang + mat.M32 * -sin_ang;
		float m13 = mat.M13 * cos_ang + mat.M33 * -sin_ang;
		
		mat.M31 = mat.M11 * sin_ang + mat.M31 * cos_ang;
		mat.M32 = mat.M12 * sin_ang + mat.M32 * cos_ang;
		mat.M33 = mat.M13 * sin_ang + mat.M33 * cos_ang;

        mat.M11 = m11;
        mat.M12 = m12;
        mat.M13 = m13;
	}
	
	public void RotateRoll(float ang) 
	{
		float cos_ang = (float)Utility.Cos((double)ang);
        float sin_ang = (float)Utility.Sin((double)ang);

		float m11 = mat.M11 * cos_ang + mat.M21 * sin_ang;
		float m12 = mat.M12 * cos_ang + mat.M22 * sin_ang;
		float m13 = mat.M13 * cos_ang + mat.M23 * sin_ang;
		
		mat.M21 = mat.M11 * -sin_ang + mat.M21 * cos_ang;
		mat.M22 = mat.M12 * -sin_ang + mat.M22 * cos_ang;
		mat.M23 = mat.M13 * -sin_ang + mat.M23 * cos_ang;
		
		mat.M11 = m11;
		mat.M12 = m12;
        mat.M13 = m13;
	}
}

public class XNAViewport
{
    public Viewport _viewport;

    public XNAViewport(int x, int y, int width, int height)
    {
        _viewport = new Viewport(x, y, width, height);
    }

    public static XNAViewport Create(int x, int y, int width, int height)
    {
        return new XNAViewport(x, y, width, height);
    }

    public float getAspectRatio()
    {
        return _viewport.AspectRatio;
    }

    public int getX()
    {
        return _viewport.X;
    }

    public int getY()
    {
        return _viewport.Y;
    }

    public int getWidth()
    {
        return _viewport.Width;
    }

    public int getHeight()
    {
        return _viewport.Height;
    }

    public void setX(int value)
    {
        _viewport.X = value;
    }

    public void setY(int value)
    {
        _viewport.Y = value;
    }

    public void setWidth(int value)
    {
        _viewport.Width = value;
    }

    public void setHeight(int value)
    {
        _viewport.Height = value;
    }

    public float getMaxDepth()
    {
        return _viewport.MaxDepth;
    }

    public float getMinDepth()
    {
        return _viewport.MaxDepth;
    }

    public void setMaxDepth(float value)
    {
        _viewport.MaxDepth = value;
    }

    public void setMinDepth(float value)
    {
        _viewport.MinDepth = value;
    }
}


