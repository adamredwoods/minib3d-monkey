' Module xna
' Version: 0.10
' Author: Sascha Schmidt

Import mojo
'Import minib3d.xna.xna_driver.databuffer
Import brl.databuffer

#if TARGET="xna"

Import "native/xna.${TARGET}.${LANG}"

' Defines classes that can be used for effect parameters or shader constants.
Const EFFECT_PARAMETER_CLASS_MATRIX 	= 0
Const EFFECT_PARAMETER_CLASS_OBJECT 	= 1
Const EFFECT_PARAMETER_CLASS_SCALAR 	= 2
Const EFFECT_PARAMETER_CLASS_STRUCT 	= 3
Const EFFECT_PARAMETER_CLASS_VECTOR 	= 4

' Defines types that can be used for effect parameters or shader constants.
Const EFFECT_PARAMETER_TYPE_BOOL 		= 0
Const EFFECT_PARAMETER_TYPE_INT32 		= 1
Const EFFECT_PARAMETER_TYPE_SINGLE 		= 2
Const EFFECT_PARAMETER_TYPE_STRING 		= 3
Const EFFECT_PARAMETER_TYPE_TEXTURE 	= 4
Const EFFECT_PARAMETER_TYPE_TEXTURE1D	= 5
Const EFFECT_PARAMETER_TYPE_TEXTURE2D	= 6
Const EFFECT_PARAMETER_TYPE_TEXTURE3D	= 7
Const EFFECT_PARAMETER_TYPE_TEXTURECUBE	= 8
Const EFFECT_PARAMETER_TYPE_VOID 		= 9

Const BLENDFUNCTION_ADD = 0
Const BLENDFUNCTION_SUBSTRACT = 1
Const BLENDFUNCTION_REVERSESUBSTRACT = 2
Const BLENDFUNCTION_MIN = 3
Const BLENDFUNCTION_MAX = 4

' Defines color blending factors.
Const BLEND_One = 0
Const BLEND_Zero = 1
Const BLEND_SourceColor = 2
Const BLEND_InverseSourceColor = 3
Const BLEND_SourceAlpha = 4
Const BLEND_InverseSourceAlpha = 5
Const BLEND_DestinationColor = 6
Const BLEND_InverseDestinationColor = 7
Const BLEND_DestinationAlpha = 8
Const BLEND_InverseDestinationAlpha = 9
Const BLEND_BlendFactor = 10
Const BLEND_InverseBlendFactor = 11
Const BLEND_SourceAlphaSaturation = 12

Const CullMode_None = 0
Const CullMode_CullClockwiseFace = 1
Const CullMode_CullCounterClockwiseFace = 2

Const FillMode_Solid = 0
Const FillMode_WireFrame = 1

Const TextureAddressMode_Wrap = 0
Const TextureAddressMode_Clamp = 1
Const TextureAddressMode_Mirror = 2

Const TextureFilter_Linear = 0
Const TextureFilter_Point = 1
Const TextureFilter_Anisotropic = 2
Const TextureFilter_LinearMipPoint = 3
Const TextureFilter_PointMipLinear = 4
Const TextureFilter_MinLinearMagPointMipLinear = 5
Const TextureFilter_MinLinearMagPointMipPoint = 6
Const TextureFilter_MinPointMagLinearMipLinear = 7
Const TextureFilter_MinPointMagLinearMipPoint = 8

' Defines stencil buffer operations.
Const StencilOperation_Keep = 0
Const StencilOperation_Zero = 1
Const StencilOperation_Replace = 2
Const StencilOperation_Increment = 3
Const StencilOperation_Decrement = 4
Const StencilOperation_IncrementSaturation = 5
Const StencilOperation_DecrementSaturation = 6
Const StencilOperation_Invert = 7

' Defines comparison functions that can be chosen for alpha, stencil, or depth-buffer tests.
Const CompareFunction_Always = 0
Const CompareFunction_Never = 1
Const CompareFunction_Less = 2
Const CompareFunction_LessEqual = 3
Const CompareFunction_Equal = 4
Const CompareFunction_GreaterEqual = 5
Const CompareFunction_Greater = 6
Const CompareFunction_NotEqual = 7

Const PlaneIntersectionType_Back = 1
Const PlaneIntersectionType_Front = 2
Const PlaneIntersectionType_Intersecting = 3

Const BUFFERUSAGE_NONE 					= 0
Const BUFFERUSAGE_WRITEONLY 			= 1

Const VERTEX_POSITION_COLOR 			= 0
Const VERTEX_POSITION_COLOR_TEXTURE 	= 1
Const VERTEX_POSITION_NORMAL_TEXTURE 	= 2
Const VERTEX_POSITION_TEXTURE 			= 3


Extern

#rem
Class IDisposable
	Method Dispose()
End


'----------------------------------------------------------------------------------------------------------
' Queries and prepares resources.
Class XNAGraphicsResource extends IDisposable 
	Method GraphicsDevice:XNAGraphicsDevice() = "GetGraphicsDevice"
	Method Name$()= "GetName"
	Method Tag:Object()= "GetTag"
	Method Name(value$)= "SetName"
	Method Tag:Object()= "SetTag"
	Method Dispose()= "Dispose"
End 


'----------------------------------------------------------------------------------------------------------
' Defines a plane.
' TODO: Needs to be implemented
Class XNAPlane = "XNAPlane"
	Method D:Vector4() Property = "GetD"
	Method Normal:Vector() Property = "GetNormal"
	Method DotNormal:Vector() Property = "GetDotNormal"
	Method DorCoordinate(v:Vector) = "DorCoordinateA"
	Method DorCoordinate(v:Vector, v2#) = "DorCoordinateB"	
	Method Equals?(p:Plane ) = "Equals"
	Method Intersects?(value:BoundingBox) = "IntersectsBox"
	Method Intersects?(value:BoundingBox, containmentType) = "IntersectsBox2"
	Method Intersects?(value:BoundingSphere) = "IntersectsSphere"
	Method Intersects?(value:BoundingSphere, containmentType) = "IntersectsSphere2"
	Method Intersects?(value:BoundingFrustum) = "IntersectsFrustum"
	Method Normalize() = "NormalizeA"
	Method Normalize(p:Plane) = "NormalizeB"
	Method Normalize(p:Plane, q:Plane) = "NormalizeC"
	
	Function Create:XNAPlane(v1#,v2#,v3#,v4#) = "XNAPlane.CreateA"
	Function Create:XNAPlane(v1:Vector, v2#) = "XNAPlane.CreateB"
	Function Create:XNAPlane(v1:Vector,v2:Vector,v3:Vector) = "XNAPlane.CreateC"
	Function Create:XNAPlane(v1:Vector4) = "XNAPlane.CreateD"
End



'----------------------------------------------------------------------------------------------------------
' Defines an axis-aligned box-shaped 3D volume.
' TODO: Needs to be implemented
Class XNABoundingBox = "XNABoundingBox"
	Method CornerCount%() Property = "GetConrnerCount"
	Method Min:Vector() Property = "GetMin"
	Method Max:Vector() Property = "GetMax"
	Method Intersects?(value:BoundingBox) = "IntersectsBox"
	Method Intersects?(value:BoundingSphere) = "IntersectsSphere"
	Method Intersects?(value:BoundingFrustum) = "IntersectsFrustum"
	Method Intersects?(value:Plane) = "IntersectsPlane"
	Method Contains?(value:BoundingBox) = "ContainsBox"
	Method Contains?(value:BoundingBox, containmentType) = "ContainsBox2"
	Method Contains?(value:BoundingSphere) = "ContainsSphere"
	Method Contains?(value:BoundingSphere, containmentType) = "ContainsSphere2"
	Method Contains?(value:BoundingFrustum) = "ContainsFrustum"
	Method Contains?(value:Vector,containmentType) = "ContainsVector"
	
	Function Create:XNABoundingBox(min:Vector,max:Vector) = "XNABoundingBox.Create"
	Function CreateFromBoundingSphere:XNABoundingBox(box:XNABoundingSphere) = "XNABoundingBox.CreateFromBoundingSphere"
	Function CreateFromFrustum:XNABoundingBox(frustum:XNABoundingFrustum) = "XNABoundingBox.CreateFromFrustum"
	Function CreateFromPoints:XNABoundingBox(points:Vector[]) = "XNABoundingBox.CreateFromPoints"
	Function CreateMerged:XNABoundingBox(a:XNABoundingBox, b:XNABoundingBox) = "XNABoundingBox.CreateMerged"
	Function Op_Equality?(a:XNABoundingBox, b:XNABoundingBox) = "XNABoundingBox.op_Equality"
	Function Op_Inequality?(a:XNABoundingBox, b:XNABoundingBox) = "XNABoundingBox.op_Inequality"
End

'----------------------------------------------------------------------------------------------------------
' Defines a sphere.
' TODO: Needs to be implemented
Class XNABoundingSphere = "XNABoundingSphere"
	Method Radius#() Property  = "GetRadius"
	Method Radius(value#) Property  = "SetRadius"
	Method Center:Vector() Property = "GetCenter"
	Method Center(value:Vector) Property = "SetCenter"
	Method Transform(mat:Matrix) = "Transform"
	Method Intersects?(value:Plane) = "IntersectsPlane"
	Method Intersects?(value:BoundingBox) = "IntersectsBox"
	Method Intersects?(value:BoundingSphere) = "IntersectsSphere"
	Method Intersects?(value:BoundingFrustum) = "IntersectsFrustum"
	Method Contains?(value:BoundingBox) = "ContainsBox"
	Method Contains?(value:BoundingBox, containmentType) = "ContainsBox2"
	Method Contains?(value:BoundingSphere) = "ContainsSphere"
	Method Contains?(value:BoundingSphere, containmentType) = "ContainsSphere2"
	Method Contains?(value:BoundingFrustum) = "ContainsFrustum"
	Method Contains?(value:Vector,containmentType) = "ContainsVector"
	
	Function Create:XNABoundingSphere(center:Vector, mat:Matrix) = "XNABoundingSphere.Create"
	Function CreateFromBoundingBox:XNABoundingSphere(box:XNABoundingBox) = "XNABoundingSphere.CreateFromBoundingBox"
	Function CreateFromFrustum:XNABoundingSphere(frustum:XNABoundingFrustum) = "XNABoundingSphere.CreateFromFrustum"
	Function CreateFromPoints:XNABoundingSphere(points:Vector[]) = "XNABoundingSphere.CreateFromPoints"
	Function CreateMerged:XNABoundingSphere(a:XNABoundingSphere, b:XNABoundingSphere) = "XNABoundingSphere.CreateMerged"
	Function Op_Equality?(a:XNABoundingSphere, b:XNABoundingSphere) = "XNABoundingSphere.op_Equality"
	Function Op_Inequality?(a:XNABoundingSphere, b:XNABoundingSphere) = "XNABoundingSphere.op_Inequality"
End

'----------------------------------------------------------------------------------------------------------
' Defines a frustum and helps determine whether forms intersect with it.
' TODO: Needs to be implemented
Class XNABoundingFrustum = "XNABoundingFrustum"
	Method ConrnerCount%() Property = "GetConrnerCount"
	Method Bottom:Plane() Property = "GetBottom"
	Method Far:Plane() Property = "GetFar"
	Method Left:Plane() Property = "GetLeft"
	Method Near:Plane() Property = "GetNear"
	Method Right:Plane() Property = "GetRight"
	Method Top:Plane() Property = "GetTop"
	Method Matrix:Matrix() Property = "GetMatrix"
	Method Matrix(value:Matrix) Property = "SetMatrix"
	Method Intersects?(value:BoundingBox) = "IntersectsBox"
	Method Intersects?(value:BoundingSphere) = "IntersectsSphere"
	Method Intersects?(value:BoundingFrustum) = "IntersectsFrustum"
	Method Intersects?(value:Plane) = "IntersectsPlane"
	Method Contains?(value:BoundingBox) = "ContainsBox"
	Method Contains?(value:BoundingBox, containmentType) = "ContainsBox2"
	Method Contains?(value:BoundingSphere) = "ContainsSphere"
	Method Contains?(value:BoundingSphere, containmentType) = "ContainsSphere2"
	Method Contains?(value:BoundingFrustum) = "ContainsFrustum"
	Method Contains?(value:Vector,containmentType) = "ContainsVector"
	
	Function Create:XNABoundingFrustum(mat:Matrix) = "XNABoundingFrustum.Create"
	Function Op_Equality?(a:XNABoundingFrustum, b:XNABoundingFrustum) = "XNABoundingFrustum.op_Equality"
	Function Op_Inequality?(a:XNABoundingFrustum, b:XNABoundingFrustum) = "XNABoundingFrustum.op_Inequality"
End


'----------------------------------------------------------------------------------------------------------
' Defines the window dimensions of a render-target surface 
' onto which a 3D volume projects.
Class XNAViewport = "XNAViewport"
	Method AspectRatio#() Property		= " getAspectRatio"
	Method X#() Property				= " getX"
	Method Y#() Property				= " getY"
	Method Width#() Property			= " getWidth"
	Method Height#() Property			= " getHeight"
	Method X(value%) Property			= " setX"
	Method Y(value%) Property			= " setY"
	Method Width(value%) Property		= " setWidth"
	Method Height(value%) Property		= " setHeight"
	Method MaxDepth#() Property			= " getMaxDepth"
	Method MinDepth#() Property			= " getMinDepth"
	Method MaxDepth(value%) Property	= " setMaxDepth"
	Method MinDepth(value%) Property	= " setMinDepth"
	
	Function Create:XNAViewport(x,y,width, height) = "XNAViewport.Create"
End
#end


'----------------------------------------------------------------------------------------------------------
' Contains blend state for the device.
Class XNABlendState = "XNABlendState"
	Method AlphaBlendFunction() Property = "GetAlphaBlendFunction"
	Method AlphaDestinationBlend() Property = "GetAlphaDestinationBlend"
	Method AlphaSourceBlend() Property = "GetAlphaSourceBlend"
	Method BlendFactor:XNAColor() Property = "GetBlendFactor"
	Method ColorBlendFunction() Property = "GetColorBlendFunction"
	Method ColorDestinationBlend() Property = "GetColorDestinationBlend"
	Method ColorSourceBlend() Property = "GetColorSourceBlend"
	Method AlphaBlendFunction:Void(value%) Property = "SetAlphaBlendFunction"
	Method AlphaDestinationBlend:Void(value%) Property = "SetAlphaDestinationBlend"
	Method AlphaSourceBlend:Void(value%) Property = "SetAlphaSourceBlend"
	Method BlendFactor:Void(value:XNAColor) Property = "SetBlendFactor"
	Method ColorBlendFunction:Void(value%) Property = "SetColorBlendFunction"
	Method ColorDestinationBlend:Void(value%) Property = "SetColorDestinationBlend"
	Method ColorSourceBlend:Void(value%) Property = "SetColorSourceBlend"
		
	Function Create:XNABlendState() = "XNABlendState.Create"
	Function Additive:XNABlendState()= "XNABlendState.Additive"
	Function AlphaBlend:XNABlendState()= "XNABlendState.AlphaBlend"
	Function Premultiplied:XNABlendState()= "XNABlendState.NonPremultiplied"
	Function Opaque:XNABlendState()= "XNABlendState.Opaque"
End

'----------------------------------------------------------------------------------------------------------
' Contains rasterizer state, which determines how to convert vector data (shapes) into raster data (pixels).
Class XNARasterizerState = "XNARasterizerState"
	Method CullMode() = "GetCullMode"
	Method DepthBias#() = "GetDepthBias"
	Method FillMode() = "GetFillMode"
	Method MultiSampleAntiAlias?()= "GetMultiSampleAntiAlias"
	Method ScissorTestEnable?()= "GetScissorTestEnable"
	Method SlopeScaleDepthBias#()= "GetSlopeScaleDepthBias"
	Method CullMode:Void(value%) = "SetCullMode"
	Method DepthBias:Void(value#) = "SetDepthBias"
	Method FillMode:Void(value%) = "SetFillMode"
	Method MultiSampleAntiAlias:Void(value?)= "SetMultiSampleAntiAlias"
	Method ScissorTestEnable:Void(value?)= "SetScissorTestEnable"
	Method SlopeScaleDepthBias:Void(value#)= "SetSlopeScaleDepthBias"
	
	Function Create:XNARasterizerState() = "XNARasterizerState.Create"
	Function CullClockwise:XNARasterizerState() = "XNARasterizerState.CullClockwise"
	Function CullCounterClockwise:XNARasterizerState() = "XNARasterizerState.CullCounterClockwise"
	Function CullNone:XNARasterizerState() = "XNARasterizerState.CullNone"
End

'----------------------------------------------------------------------------------------------------------
' Contains sampler state, which determines how to sample texture data.
Class XNASamplerState = "XNASamplerState"
	Method AddressU%()	Property = "GetAddressU"
	Method AddressV%()Property = "GetAddressV"
	Method AddressW%()Property = "GetAddressW"
	Method Filter%()Property = "GetFilter"
	Method MaxAnisotropy%()Property = "GetMaxAnisotropy"
	Method MaxMipLevel%()Property = "GetMaxMipLevel"
	Method MipMapLevelOfDetailBias%()Property = "GetMipMapLevelOfDetailBias"
	Method AddressU:Void(value%)	Property = "SetAddressU"
	Method AddressV:Void(value%)Property = "SetAddressV"
	Method AddressW:Void(value%)Property = "SetAddressW"
	Method Filter:Void(value%)Property = "SetFilter"
	Method MaxAnisotropy:Void(value%)Property = "SetMaxAnisotropy"
	Method MaxMipLevel:Void(value%)Property = "SetMaxMipLevel"
	Method MipMapLevelOfDetailBias:Void(value%)Property = "SetMipMapLevelOfDetailBias"
	Method ToString:String() = "ToString"
	
	Function Create:XNASamplerState() = "XNASamplerState.Create"
	Function Create:XNASamplerState(filter, adressU, adressV) = "XNASamplerState.Create"
	Function AnisotropicWrap:XNASamplerState() = "XNASamplerState.AnisotropicWrap"
	Function LinearClamp:XNASamplerState() = "XNASamplerState.LinearClamp"
	Function LinearWrap:XNASamplerState() = "XNASamplerState.LinearWrap"
	Function PointClamp:XNASamplerState() = "XNASamplerState.PointClamp"
	Function PointWrap:XNASamplerState() = "XNASamplerState.PointWrap"
End 

'----------------------------------------------------------------------------------------------------------
' Contains depth-stencil state for the device.
Class XNADepthStencilState = "XNADepthStencilState"
	Method CounterClockwiseStencilDepthBufferFail%() Property = "GetCounterClockwiseStencilDepthBufferFail"
	Method CounterClockwiseStencilFail%() Property = "GetCounterClockwiseStencilFail"	 
	Method CounterClockwiseStencilFunction%() Property = "GetCounterClockwiseStencilFunction"	 
	Method CounterClockwiseStencilPass%() Property = "GetCounterClockwiseStencilPass"	
	Method DepthBufferEnable?() Property = "GetDepthBufferEnable"	
	Method DepthBufferFunction%	() Property = "GetDepthBufferFunction"	
	Method DepthBufferWriteEnable?	() Property = "GetDepthBufferWriteEnable"	
	Method ReferenceStencil%() Property = "GetReferenceStencil"	
	Method StencilDepthBufferFail%() Property = "GetStencilDepthBufferFail"	
	Method StencilEnable?() Property = "GetStencilEnable"	
	Method StencilFail%() Property = "GetStencilFail"	
	Method StencilFunction%	() Property = "GetStencilFunction"	
	Method StencilMask%	() Property = "GetStencilMask"	
	Method StencilPass%	() Property = "GetStencilPass"	
	Method StencilWriteMask%() Property = "GetStencilWriteMask"	
	Method TwoSidedStencilMode?() Property = "GetTwoSidedStencilMode"	
	Method CounterClockwiseStencilDepthBufferFail:Void(value%) Property = "SetCounterClockwiseStencilDepthBufferFail"
	Method CounterClockwiseStencilFail:Void(value%) Property = "SetCounterClockwiseStencilFail"	 
	Method CounterClockwiseStencilFunction:Void(value%) Property = "SetCounterClockwiseStencilFunction"	 
	Method CounterClockwiseStencilPass:Void(value%) Property = "SetCounterClockwiseStencilPass"	
	Method DepthBufferEnable:Void(value?) Property = "SetDepthBufferEnable"	
	Method DepthBufferFunction:Void(value%) Property = "SetDepthBufferFunction"	
	Method DepthBufferWriteEnable:Void(value?) Property = "SetDepthBufferWriteEnable"	
	Method ReferenceStencil:Void(value%) Property = "SetReferenceStencil"	
	Method StencilDepthBufferFail:Void(value%) Property = "SetStencilDepthBufferFail"	
	Method StencilEnable:Void(value?) Property = "SetStencilEnable"	
	Method StencilFail:Void(value%) Property = "SetStencilFail"	
	Method StencilFunction:Void(value%) Property = "SetStencilFunction"	
	Method StencilMask:Void(value%) Property = "SetStencilMask"	
	Method StencilPass:Void(value%) Property = "SetStencilPass"	
	Method StencilWriteMask:Void(value%) Property = "SetStencilWriteMask"	
	Method TwoSidedStencilMode:Void(value?) Property = "SetTwoSidedStencilMode"	
	
	Function Create:XNADepthStencilState() = "XNADepthStencilState.Create"
	Function _Default:XNADepthStencilState() = "XNADepthStencilState.Default"	
	Function DepthRead:XNADepthStencilState() = "XNADepthStencilState.DepthRead"
	Function None:XNADepthStencilState() = "XNADepthStencilState.None"
End

'----------------------------------------------------------------------------------------------------------
Class XNATextureBase = "XNATextureBase"
    Method Format() Property =  "GetFormat"
    Method LevelCount() Property = "GetLevelCount"
End 

'----------------------------------------------------------------------------------------------------------
' Represents a 2D grid of texels.
Class XNATexture Extends XNATextureBase = "XNATexture"
	' Method Load:XNATexture(fileName$)	???
	Method Width()
	Method Height()
	Method SetData:Void(level:Int, data:DataBuffer, start, count) 
End

'----------------------------------------------------------------------------------------------------------
' Represents a set of six 2D textures, one for each face of a cube.
Class XNATextureCube Extends XNATextureBase = "XNATextureCube"
	Method Size()
	Method SetData:Void(cubeMapFace:Int, data:DataBuffer, start, count)
End 

'----------------------------------------------------------------------------------------------------------
' Encapsulates vertex- and indexbuffers
Class XNAMesh = "XNAMesh"
	Method Clear:Void()
	Method Bind:Void()
	Method Render:Void()
	Method SetVertices:Void(data:DataBuffer, count, flags)
	Method SetIndices:Void(data:DataBuffer, count, flags)
End

'----------------------------------------------------------------------------------------------------------
'Performs primitive-based rendering, creates resources, handles system-level variables  and creates shaders.
Class XNAGraphicsDevice  = "XNAGraphicsDevice"
	Method CreateTexture:XNATexture(width, height, mipmap:Bool , format)
	Method LoadTexture:XNATexture(filename$)
	Method CreateMesh:XNAMesh()
	Method CreateBasicEffect:XNABasicEffect()
	'Method LoadEffect:XNAEffect(filename$)' custom effetcts not supported in REACH profile
	Method BlendState:Void(blend:XNABlendState) Property = "SetBlend"
	Method RasterizerState:Void(state:XNARasterizerState ) Property = "SetRasterizerState"
	Method DepthStencilState:Void(state:XNADepthStencilState) Property = "SetDepthStencilState"
	Method SamplerState:Void(index, state:XNASamplerState ) = "SetSamplerState"
	Method ClearScreen:Void(r#,g#,b#, back? , depth? , stencil? )
	Method Viewport:Void(x,y,width, height)
	Method GetShaderVersion:Float()
	Method GraphicsDeviceStatus:Int()
End

'----------------------------------------------------------------------------------------------------------
' Represents a color using Red, Green, Blue, and Alpha values.
Class XNAColor = "XNAColor"
	Method R#() Property = "GetR"
	Method G#() Property = "GetG"
	Method B#() Property = "GetB"
	Method A#() Property = "GetA"
	Method R:Void(value#) Property = "SetR"
	Method G:Void(value#) Property = "SetG"
	Method B:Void(value#) Property = "SetB"
	Method A:Void(value#) Property = "SetA"
	
	Function FromArgb:XNAColor(r#,g#,b#,a#) = "XNAColor.FromARGB"
	Function Black:XNAColor() 				= "XNAColor.Black"
	Function White:XNAColor() 				= "XNAColor.White"
	Function Red:XNAColor()   				= "XNAColor.Red"
	Function Blue:XNAColor()  				= "XNAColor.Blue"
End

'----------------------------------------------------------------------------------------------------------
'Creates a DirectionalLight object.
Class XNADirectionalLight = "XNADirectionalLight"
	Method DiffuseColor:Void(r#,g#,b#) = "SetDiffuseColor"
	Method SpecularColor:Void(r#,g#,b#) = "SetSpecularColor"
	Method Direction:Void(x#,y#,z#) = "SetDirection"
	Method Enabled?() = "GetEnabled"
	Method Enabled:Void(value?) = "SetEnabled"
End

'----------------------------------------------------------------------------------------------------------
' Contains a basic rendering effect.
Class XNABasicEffect Extends XNAEffect = "XNABasicEffect"
	Method Alpha:Void(value#) Property = "SetAlpha"
	Method AmbientLightColor:Void(r#,g#,b#) Property = "SetAmbientLightColor"
	Method DiffuseColor:Void(r#,g#,b#) Property = "SetDiffuseColor"
	Method DirectionalLight0:XNADirectionalLight() Property = "GetDirectionalLight0"	
	Method DirectionalLight1:XNADirectionalLight() Property = "GetDirectionalLight1"	
	Method DirectionalLight2:XNADirectionalLight() Property = "GetDirectionalLight2"	
	Method EmissiveColor:Void(r#,g#,b#) Property = "SetEmissiveColor"
	Method FogColor:Void(r#,g#,b#) Property = "SetFogColor"
	Method FogEnabled?()  Property= "GetFogEnabled"
	Method FogEnabled:Void(value?) Property = "SetFogEnabled"
	Method FogEnd:Void(value#) Property = "SetFogEnd"
	Method FogStart:Void(value#) Property = "SetFogStart"
	Method LightingEnabled:Void(value?)  Property= "SetLightingEnabled"
	Method PreferPerPixelLighting:Void(value?)  Property= "SetPreferPerPixelLighting"
	Method SpecularColor:Void(r#,g#,b#)  Property= "SetSpecularColor"
	Method SpecularPower:Void(value#)  Property= "SetSpecularPower"
	Method Texture:Void(value:XNATexture) Property = "SetTexture"
	Method VertexColorEnabled:Void(value?) Property = "SetVertexColorEnabled"
	Method TextureEnabled:Void(value?) Property = "SetTextureEnabled"
	Method Projection:Void(fieldOfView#, aspect#, near#, far#)  = "SetProjection"
	Method View:Void(px#, py#, pz#, rx#, ry#, rz#, sx#, sy#, sz#) = "SetView"
	Method World:Void(px#, py#, pz#, rx#, ry#, rz#, sx#, sy#, sz#) = "SetWorld"
	Method ProjectionMatrix:Void(mat:Float[]) = "SetProjMat"
	Method ViewMatrix:Void(mat:Float[]) = "SetViewMat"
	Method WorldMatrix:Void(mat:Float[]) = "SetWorldMat"
End


'----------------------------------------------------------------------------------------------------------
' Contains a configurable effect that supports environment mapping.
' http://msdn.microsoft.com/en-us/library/microsoft.xna.framework.graphics.environmentmapeffect_members

Class XNAEnvironmentMapEffect Extends XNAEffect
	Method EnvironmentMap:Void(texture:XNATextureCube) = "SetEnvironmentMap"	
	Method EnvironmentMapAmount:Void(value#) = "SetEnvironmentMapAmount"	
	Method EnvironmentMapSpecular:Void(r#,g#,b#) = "SetEnvironmentMapSpecular"	
	Method FresnelFactor:Void(value#) = "SetFresnelFactor"	
	Method Alpha:Void(value#) Property = "SetAlpha"
	Method AmbientLightColor:Void(r#,g#,b#) Property = "SetAmbientLightColor"
	Method DiffuseColor:Void(r#,g#,b#) Property = "SetDiffuseColor"
	Method DirectionalLight0:XNADirectionalLight() Property = "GetDirectionalLight0"	
	Method DirectionalLight1:XNADirectionalLight() Property = "GetDirectionalLight1"	
	Method DirectionalLight2:XNADirectionalLight() Property = "GetDirectionalLight2"	
	Method EmissiveColor:Void(r#,g#,b#) Property = "SetEmissiveColor"
	Method FogColor:Void(r#,g#,b#) Property = "SetFogColor"
	Method FogEnabled?()  Property= "GetFogEnabled"
	Method FogEnabled:Void(value?) Property = "SetFogEnabled"
	Method FogEnd:Void(value#) Property = "SetFogEnd"
	Method FogStart:Void(value#) Property = "SetFogStart"
	
	' Method Texture:Void(value:XNATexture) Property = "SetTexture"
	Method Projection:Void(fieldOfView#, aspect#, near#, far#)  = "SetProjection"
	Method View:Void(px#, py#, pz#, rx#, ry#, rz#, sx#, sy#, sz#) = "SetView"
	Method World:Void(px#, py#, pz#, rx#, ry#, rz#, sx#, sy#, sz#) = "SetWorld"
End 

'----------------------------------------------------------------------------------------------------------
' Used to set and query effects, and to choose techniques.
Class XNAEffect = "XNAEffect"
	Method CurrentTechnique:XNAEffectTechnique() Property = "GetCurrentTechnique"
	Method CurrentTechnique:Void(value:XNAEffectTechnique) Property = "SetCurrentTechnique"
	Method GraphicsDevice:XNAGraphicsDevice() Property = "GetGraphicsDevice"
	Method Name$() Property = "GetName"
	Method GetParameter:XNAEffectParameter(name$) Property = "GetParameter"
	Method CountParameters() Property
	Method GetTechnique:XNAEffectTechnique(name$) Property= "GetTechnique"
	Method CountTechniques() Property
	

	' may only be used with effects that usually implements IEffectMatrices
	Method Projection:Void(fieldOfView#, aspect#, near#, far#)  = "SetProjection"
	Method View:Void(px#, py#, pz#, rx#, ry#, rz#, sx#, sy#, sz#) = "SetView"
	Method World:Void(px#, py#, pz#, rx#, ry#, rz#, sx#, sy#, sz#) = "SetWorld"
	
	Method ProjectionMatrix:Void(mat:Float[]) = "SetProjMat"
	Method ViewMatrix:Void(mat:Float[]) = "SetViewMat"
	Method WorldMatrix:Void(mat:Float[]) = "SetWorldMat"

	
	' may only be used with effects that usually implements IEffectFog
	Method FogColor:Void(r#,g#,b#) Property = "SetFogColor"
	Method FogEnabled?()  Property= "GetFogEnabled"
	Method FogEnabled:Void(value?) Property = "SetFogEnabled"
	Method FogEnd:Void(value#) Property = "SetFogEnd"
	Method FogStart:Void(value#) Property = "SetFogStart"
	
	' may only be used with effects that usually implements IEffectLights
	Method AmbientLightColor:Void(r#,g#,b#) Property = "SetAmbientLightColor"
	Method DirectionalLight0:XNADirectionalLight() Property = "GetDirectionalLight0"	
	Method DirectionalLight1:XNADirectionalLight() Property = "GetDirectionalLight1"	
	Method DirectionalLight2:XNADirectionalLight() Property = "GetDirectionalLight2"	
	Method LightingEnabled:Void(value?)  Property= "SetLightingEnabled"
	Method PreferPerPixelLighting:Void(value?)  Property= "SetPreferPerPixelLighting"
	
End

'----------------------------------------------------------------------------------------------------------
' Represents an effect technique.
' Creating and assigning a EffectTechnique instance for each technique in your Effect is significantly 
' faster than using always the Techniques 'GetTechnique' property on Effect.
Class XNAEffectTechnique = "XNAEffectTechnique"
	Method Name$() Property = "GetName"
	Method Passes:XNAEffectPass[]() = "GetPasses"
End

'----------------------------------------------------------------------------------------------------------
' Contains rendering state for drawing with an effect; an effect can contain one or more passes.
Class XNAEffectPass = "XNAEffectPass"
	Method Name$() Property = "GetName"
	Method Apply:Void()
End

'----------------------------------------------------------------------------------------------------------
' Represents an Effect parameter.
' Creating and assigning a EffectParameter instance for each technique in your Effect is significantly 
' faster than using the Parameters indexed property on Effect.
Class XNAEffectParameter  = "XNAEffectParameter"
	Method ParameterClass() Property = "GetParameterClass"
	Method ParameterType() Property = "GetParameterType"
	Method Name$() Property = "GetName"
	Method Semantic$() Property = "GetSemantic"
	Method SetValue:Void(value?)		= "SetBool"
	Method SetValue:Void(value?[])	= "SetBoolArray"
	Method SetValue:Void(value%)		= "SetInt"
	Method SetValue:Void(value%[])	= "SetIntArray"
	Method SetValue:Void(value#)	= "SetFloat"
	Method SetValue:Void(value#[])	= "SetFloatArray"
	Method SetValue:Void(value$)	= "SetString"
	Method SetValue:Void(value:XNATexture)	= "SetTexture"
	#rem
	Method SetValue(value:Matrix)	= "SetMatrix"
	Method SetValue(value:Matrix[])		= "SetMatrixArray"
	Method SetValue(value:Vector)		= "SetVector"
	#end
End

#rem
Class XNAVertexBuffer
	Method BufferUsage() Property
	Method VertexCount() Property
	Method Size() Property
	Method VertexDeclaration() Property		
	Method Dispose()
	Method GetData:#[]()
	Method SetData(data:#[], start, count)
	Method AddVertex(x#, y#, z#,nx#, ny#, nz#, s#,t#)
	Method SetVertex(id%,x#, y#, z#,nx#, ny#, nz#, s#,t#)
	Method Clear()
End


Class XNAMeshIndexBuffer
	Method BufferUsage() Property
	Method IndexCount() Property
	Method IndexElementSize() Property
	Method Dispose()
	Method GetData:int[]()
	Method SetData(data:int[], start, count)
	Method AddTriangle:int(v0, v1, v2)
	Method Clear()
End 
#end

Extern	
	'Function EndMojoRender:Void() = "gxtkApp.game.app.GraphicsDevice().EndRender"
	Function EndMojoRender:Void(target:Object = Null) = "gxtkApp.game.app.GraphicsDevice().device.SetRenderTarget"
	


#End

