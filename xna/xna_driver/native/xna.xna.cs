

public class AnimUtil
{
	struct B3DVertex
	{
		float x,y,z,w;
		float nx,ny,nz,nw;
		float r,g,b,a;
		float u0,v0,u1,v1;
	};
	
	struct B3DVector
	{
		float x,y,z;
	};


	public static void UpdateVertexDataBufferPositions(BBDataBuffer destVertexDataBuffer, BBDataBuffer floatBuffer, int count)
	{
#if WINDOWS_PHONE
	
        for (int i = 0; i < count; ++i)
        {
            int vid0 = i * 64;
            int vid1 = i * 12;
            
            destVertexDataBuffer._data[vid0 + 0] = floatBuffer._data[vid1 + 0];
            destVertexDataBuffer._data[vid0 + 1] = floatBuffer._data[vid1 + 1];
            destVertexDataBuffer._data[vid0 + 2] = floatBuffer._data[vid1 + 2];
            destVertexDataBuffer._data[vid0 + 3] = floatBuffer._data[vid1 + 3];
            destVertexDataBuffer._data[vid0 + 4] = floatBuffer._data[vid1 + 4];
            destVertexDataBuffer._data[vid0 + 5] = floatBuffer._data[vid1 + 5];
            destVertexDataBuffer._data[vid0 + 6] = floatBuffer._data[vid1 + 6];
            destVertexDataBuffer._data[vid0 + 7] = floatBuffer._data[vid1 + 7];
            destVertexDataBuffer._data[vid0 + 8] = floatBuffer._data[vid1 + 8];
            destVertexDataBuffer._data[vid0 + 9] = floatBuffer._data[vid1 + 9];
            destVertexDataBuffer._data[vid0 + 10] = floatBuffer._data[vid1 + 10];
            destVertexDataBuffer._data[vid0 + 11] = floatBuffer._data[vid1 + 11];
        }

#else

		for (int i = 0; i < count; ++i)
        {
            int vid0 = i * 64;
            int vid1 = i * 12;
            
            destVertexDataBuffer._data[vid0 + 0] = floatBuffer._data[vid1 + 0];
            destVertexDataBuffer._data[vid0 + 1] = floatBuffer._data[vid1 + 1];
            destVertexDataBuffer._data[vid0 + 2] = floatBuffer._data[vid1 + 2];
            destVertexDataBuffer._data[vid0 + 3] = floatBuffer._data[vid1 + 3];
            destVertexDataBuffer._data[vid0 + 4] = floatBuffer._data[vid1 + 4];
            destVertexDataBuffer._data[vid0 + 5] = floatBuffer._data[vid1 + 5];
            destVertexDataBuffer._data[vid0 + 6] = floatBuffer._data[vid1 + 6];
            destVertexDataBuffer._data[vid0 + 7] = floatBuffer._data[vid1 + 7];
            destVertexDataBuffer._data[vid0 + 8] = floatBuffer._data[vid1 + 8];
            destVertexDataBuffer._data[vid0 + 9] = floatBuffer._data[vid1 + 9];
            destVertexDataBuffer._data[vid0 + 10] = floatBuffer._data[vid1 + 10];
            destVertexDataBuffer._data[vid0 + 11] = floatBuffer._data[vid1 + 11];
        }
        
        // Enable unsafe code for speedup
        
        /*
        unsafe
        {
            fixed (byte* pDest = &destVertexDataBuffer._data[0])
            {
                fixed (byte* pSrc = &floatBuffer._data[0])
                {
                    B3DVertex* dest = (B3DVertex*)pDest;
                    B3DVector* src = (B3DVector*)pSrc;
                    B3DVector* end = src + count;

                    do
                    {
                        *(B3DVector*)dest++ = *src++;
                    }
                    while (src != end);


                }
            }
        }
        */

#endif

    }
}

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
		_device = BBXnaGame.XnaGame().GetXNAGame().GraphicsDevice;
        _effect = new BasicEffect(_device);
        _effect.VertexColorEnabled = false;
        _effect.PreferPerPixelLighting = false;
        _effect.SpecularColor = new Vector3(1,1,1);
        _effect.FogEnabled = false;
    }

    public XNATexture LoadTexture(string fileName)
    {
        var texture = BBXnaGame.XnaGame().LoadTexture2D(fileName);
        if (texture != null) return new XNATexture(texture,fileName);
        return null;
    }
	
	public XNATexture CreateTexture(int width, int height, bool mipmap, int format)
    {
         return new XNATexture(_device, width, height, mipmap, format);
    }
	
	public XNABasicEffect CreateBasicEffect()
    {
        return new XNABasicEffect(this, new BasicEffect(_device));
    }
        
    public XNAEffect LoadEffect(string filename)
    {
        #if WINDOWS_PHONE
        #else
        var effect = BBXnaGame.XnaGame().GetXNAGame().Content.Load<Effect>("Content/monkey/" + filename);
        if (effect != null) return new XNAEffect(effect, this);
        #endif
        return null;
    }         
        
    public void SetPreferMultiSampling(bool value)
    {
    	//graphicsManager.PreferMultiSampling = value;
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

    public void GetBlendFactor(float[] arr)
	{
        var factor = _state.BlendFactor;
        arr[0] = (float)factor.R / 255.0f;
        arr[1] = (float)factor.G / 255.0f;
        arr[2] = (float)factor.B / 255.0f;
        arr[3] = (float)factor.A / 255.0f;
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
	
	public void SetBlendFactor(float r, float g, float b, float a)
	{
        _state.BlendFactor = new Color(r,g,b,a);
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

	public float GetMipMapLevelOfDetailBias()
    {
        return _state.MipMapLevelOfDetailBias;
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

    public void SetMipMapLevelOfDetailBias(float value)
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

    public override void SetWorld(float[] mat)
    {
        SetWorldMat<EnvironmentMapEffect>(_environmentEffect, mat);
    }
    public override void SetProjection(float[] mat)
    {
        SetProjMat<EnvironmentMapEffect>(_environmentEffect, mat);
    }
    public override void SetView(float[] mat)
    {
        SetViewMat<EnvironmentMapEffect>(_environmentEffect, mat);
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
	
	public override void SetWorld(float[] mat)
	{
		SetWorldMat<BasicEffect>(_basicEffect, mat);
	}
	public override void SetProjection(float[] mat)
	{
		SetProjMat<BasicEffect>(_basicEffect, mat);
	}
    public override void SetView(float[] mat)
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
	
	public virtual void SetWorld( float[] mat) {}
	public virtual void SetView( float[] mat) {}
	public virtual void SetProjection( float[] mat) {}
	
	
	// IEffectFog
	
	public virtual void SetFogColor(float r, float g, float b)	{}
	public virtual bool GetFogEnabled(){return false;}
	public virtual void SetFogEnabled(bool value){}	
	public virtual void SetFogEnd(float value){}
	public virtual void SetFogStart(float value){}
	
	
	// IEffectLights
	
	public virtual XNADirectionalLight GetDirectionalLight0(){return null;}
	public virtual XNADirectionalLight GetDirectionalLight1(){return null;}
	public virtual XNADirectionalLight GetDirectionalLight2(){return null;}
	public virtual void SetLightingEnabled(bool value){}
	public virtual void SetPreferPerPixelLighting(bool value){}
	public virtual void SetAmbientLightColor(float r, float g, float b){}
	
    // helper

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
	
	public string GetName(){return _technique.Name;}
	public XNAEffectPass[] GetPasses(){return _passes;}
}

public class XNAEffectPass
{
	public EffectPass _pass;
	
	public XNAEffectPass(EffectPass pass)
	{
		_pass = pass;
	}
	
	public string GetName(){return _pass.Name;}
	public void Apply(){_pass.Apply();}
}

public class XNAEffectParameter
{
	public EffectParameter _parameter;
	
	public XNAEffectParameter(EffectParameter parameter)
	{
		_parameter = parameter;
	}

	public int GetParameterClass() {return (int)_parameter.ParameterClass;}
	public int GetParameterType(){return (int)_parameter.ParameterType;}
	public string GetName() {return _parameter.Name;}
	public string GetSemantic(){ return _parameter.Semantic;}
	public void  SetTexture(XNATexture value){_parameter.SetValue(value._texture);}
	public void  SetBool(bool v0){ _parameter.SetValue(v0); }
	public void  SetBoolArray(bool[] value)	{_parameter.SetValue(value); }
	public void  SetInt(int v0){ _parameter.SetValue(v0); }	
	public void  SetIntArray(int[] value){_parameter.SetValue(value);}
	public void  SetFloat(float v0){ _parameter.SetValue(v0); }
	public void  SetFloatArray(float[] value){ _parameter.SetValue(value);}
}