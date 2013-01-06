
''--------------------------------------------------------
'' Windows 8 MiniB3D Driver
'' (C) 2012 Sascha Schmidt
''--------------------------------------------------------

' **** TODO ****
' add static buffers

Import minib3d
Import minib3d.d3d11

Class D3D11Mesh Implements IMesh 

	Const VERTEX_SIZE = 64
	Global VERTEX_SIZE_ARRAY:Int[] = [64]
	Global NULL_ARRAY:Int[] = [0]

	Field _vertexBuffer:D3D11Buffer[1]
	Field _indexBuffer:D3D11Buffer
	Field _vertexCount
	Field _indexCount 
	Field _size 
	Field _dynamic?
	Field _vLength = 0
	Field _iLength = 0
	
	Method CreateIndexBuffer(size)
	
		If _indexBuffer Then 
			_indexBuffer.Release()
			_indexBuffer = Null 
		End 
			
		_iLength =  size
		
		Local index_desc:= New D3D11_BUFFER_DESC
			index_desc.Usage = D3D11_USAGE_DYNAMIC
			index_desc.BindFlags = D3D11_BIND_INDEX_BUFFER
			index_desc.CPUAccessFlags = D3D11_CPU_ACCESS_WRITE
			index_desc.MiscFlags = 0
			index_desc.ByteWidth = size
			'index_desc.StructureByteStride = 0

		_indexBuffer = D3D11.Device.CreateBuffer(index_desc, Null)
		
	End 
	
	Method CreateVertexBuffer(size)
	
		If _vertexBuffer[0] Then 
			_vertexBuffer[0].Release()
			_vertexBuffer[0] = Null
		End 
		
		_vLength = size
		_dynamic = True
		
		Local vert_desc:= New D3D11_BUFFER_DESC
		
		vert_desc.Usage = D3D11_USAGE_DYNAMIC
		vert_desc.BindFlags = D3D11_BIND_VERTEX_BUFFER
		vert_desc.CPUAccessFlags = D3D11_CPU_ACCESS_WRITE
		vert_desc.MiscFlags = 0
		vert_desc.ByteWidth = size
		'vert_desc.StructureByteStride = 0
		_vertexBuffer[0] = D3D11.Device.CreateBuffer(vert_desc, Null)
		
	End 

	Method Clear()
	
		If _vertexBuffer[0] Then 
			_vertexBuffer[0].Release()
			_vertexBuffer[0] = Null
		End 
		
		If _indexBuffer Then 
			_indexBuffer.Release()
			_indexBuffer = Null 
		End 
		
	End 

	Method SetVertices:Void(data:DataBuffer, count, length)
	
		If Not _vertexBuffer[0] Or _vLength <> length Then 
			CreateVertexBuffer(length)
		End 
		
		_vertexCount = count
		_size = VERTEX_SIZE * count
			
		D3D11.DeviceContext.Map(_vertexBuffer[0],0,D3D11_MAP_WRITE_DISCARD,0).SetData(data,_size)
		D3D11.DeviceContext.Unmap(_vertexBuffer[0],0)

	End 
	
	Method SetIndices:Void(data:DataBuffer, count, length)

		If Not _indexBuffer Or _iLength <> length Then 	
			CreateIndexBuffer(length)
		End 

		_indexCount = count
		
		D3D11.DeviceContext.Map(_indexBuffer,0,D3D11_MAP_WRITE_DISCARD,0).SetData(data,count*2)
		D3D11.DeviceContext.Unmap(_indexBuffer,0)
		
	End 
	
	Method Bind()
		D3D11.DeviceContext.IASetIndexBuffer(_indexBuffer, DXGI_FORMAT_R16_UINT, 0)
		D3D11.DeviceContext.IASetVertexBuffers(0, 1, _vertexBuffer, VERTEX_SIZE_ARRAY, NULL_ARRAY)
	End 
	
	Method Render()
		D3D11.DeviceContext.DrawIndexed(_indexCount, 0,0)
	End 
	
End
