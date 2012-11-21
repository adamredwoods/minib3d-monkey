Import matrix

Class Quaternion

	Field w#,x#,y#,z#

	Method New()
	
	
	End 
	
	Method New(xx#,yy#,zz#,ww#)
	
		x=xx; y=yy; z=zz; w=ww
	End
	
	Method Copy:Quaternion()
		Return New Quaternion(x,y,z,w)
	End
	
	Method Overwrite:Void(q:Quaternion)
		x = q.x; y=q.y; z=q.z; w=q.w
	End
	
	Method Overwrite:Void(xx,yy,zz,ww)
		x = xx; y=yy; z=zz; w=ww
	End
	
	Method Update(xx:Float, yy:Float, zz:Float, ww:Float)	
		x=xx; y=xx; z=zz; w=ww	
	End
		
	Method AxisAngleToQuat:Quaternion(ax:Float,ay:Float,az:Float,an:Float)
		'' only good for orthogonal
		Local s:Float
		
		s = Sin(an*0.5)
		x = ax * s
		y = ay * s
		z = az * s
		w = Cos(an*0.5)
		
		Return Self
	End
	
	Method QuatToAxisAngle:Float[](q1:Quaternion)
		Local r:Float[4]
		
		If (q1.w > 1) Then q1.Normalize()
		r[3] = 2.0 * ACos(q1.w)
		Local s:Float = Sqrt(1.0-q1.w*q1.w)
		If (s < 0.001)
			r[0] = q1.x
			r[1] = q1.y
			r[2] = q1.z
		Else
			s = 1.0/s
			r[0] = q1.x * s
			r[1] = q1.y * s
			r[2] = q1.z * s
		Endif
		
		Return r
	End
	
	Function MatrixToQuat:Void(mat:Matrix, q:Quaternion)
		'' only good for orthogonal
		Local wt:Float, w4:Float
		
		
		w4 = mat.grid[0][0] + mat.grid[1][1] + mat.grid[2][2]

		If (w4 > 0)  
		  w4 = 1.0/(Sqrt(w4+1.0) * 2) '' S=4*qw 
		  q.w = 0.25 / w4
		  q.x = (mat.grid[2][1] - mat.grid[1][2]) *w4
		  q.y = (mat.grid[0][2] - mat.grid[2][0]) *w4 
		  q.z = (mat.grid[1][0] - mat.grid[0][1]) *w4 
		Elseif ((mat.grid[0][0] > mat.grid[1][1]) And (mat.grid[0][0] > mat.grid[2][2]))
		  w4 = 1.0/(Sqrt(1.0 + mat.grid[0][0] - mat.grid[1][1] - mat.grid[2][2]) * 2) '' S=4*qx 
		  q.w = (mat.grid[2][1] - mat.grid[1][2]) *w4
		  q.x = 0.25 / w4
		  q.y = (mat.grid[0][1] + mat.grid[1][0]) *w4
		  q.z = (mat.grid[0][2] + mat.grid[2][0]) *w4
		Elseif (mat.grid[1][1] > mat.grid[2][2])
		  w4 = 1.0/(Sqrt(1.0 + mat.grid[1][1] - mat.grid[0][0] - mat.grid[2][2]) * 2) '' S=4*qy
		  q.w = (mat.grid[0][2] - mat.grid[2][0]) *w4
		  q.x = (mat.grid[0][1] + mat.grid[1][0]) *w4 
		  q.y = 0.25 / w4
		  q.z = (mat.grid[1][2] + mat.grid[2][1]) *w4 
		Else 
		  w4 = 1.0/(Sqrt(1.0 + mat.grid[2][2] - mat.grid[0][0] - mat.grid[1][1]) * 2) '' S=4*qz
		  q.w = (mat.grid[1][0] - mat.grid[0][1]) *w4
		  q.x = (mat.grid[0][2] + mat.grid[2][0]) *w4
		  q.y = (mat.grid[1][2] + mat.grid[2][1]) *w4
		  q.z = 0.25 / w4
		Endif
		
		
	End
	



	
	Function QuatToMatrix2:Matrix(x#,y#,z#,w#,mat:Matrix)
		
		
		'Local mat:Matrix = New Matrix
		Local q:Float[] = New Float[4]
		q[0]=w
		q[1]=x
		q[2]=y
		q[3]=z
		
		Local xx#=q[1]*q[1]
		Local yy#=q[2]*q[2]
		Local zz#=q[3]*q[3]
		Local xy#=q[1]*q[2]
		Local xz#=q[1]*q[3]
		Local yz#=q[2]*q[3]
		Local wx#=q[0]*q[1]
		Local wy#=q[0]*q[2]
		Local wz#=q[0]*q[3]
	
		'mat.grid[0][0]=1-((yy+zz)+(yy+zz))
		'mat.grid[1][0]=  (xy-wz)+(xy-wz)
		'mat.grid[2][0]=  (xz+wy)+(xz+wy)
		
		'mat.grid[0][1]=  (xy+wz)+(xy+wz)
		'mat.grid[1][1]=1-((xx+zz)+(xx+zz))
		'mat.grid[2][1]=  (yz-wx)+(yz-wx)
		
		'mat.grid[0][2]=  (xz-wy)+(xz-wy)
		'mat.grid[1][2]=  (yz+wx)+(yz+wx)
		'mat.grid[2][2]=1-((xx+yy)+(xx+yy))
		'mat.grid[3][3]=1

		mat.grid[0][0]=1-((yy+zz)+(yy+zz))
		mat.grid[0][1]=  (xy-wz)+(xy-wz)
		mat.grid[0][2]=  (xz+wy)+(xz+wy)
		
		mat.grid[1][0]=  (xy+wz)+(xy+wz)
		mat.grid[1][1]=1-((xx+zz)+(xx+zz))
		mat.grid[1][2]=  (yz-wx)+(yz-wx)
		
		mat.grid[2][0]=  (xz-wy)+(xz-wy)
		mat.grid[2][1]=  (yz+wx)+(yz+wx)
		mat.grid[2][2]=1-((xx+yy)+(xx+yy))
		
		mat.grid[3][3]=1
		
		
		Return mat
				
	End 
	
	'' unit quats only
	Function QuatToMatrix:Void(x#,y#,z#,w#,mat:Matrix)
		Local x2#, xx2#, xy2#, xz2#, xw2#, y2#, yy2#, yz2#, yw2#, z2#, zz2#, zw2#
		
		x2  = x+ x
		xx2 = x2   * x
		xy2 = x2   * y
		xz2 = x2   * z
		xw2 = x2   * w
	
		y2  = y+ y
		yy2 = y2   * y
		yz2 = y2   * z
		yw2 = y2   * w
		
		z2  = z+ z
		zz2 = z2   * z
		zw2 = z2   * w
		
		mat.grid[0][0] = 1.0 - yy2 - zz2
		mat.grid[0][1] = xy2  - zw2
		mat.grid[0][2] = xz2  + yw2
	
		mat.grid[1][0] = xy2  + zw2
		mat.grid[1][1] = 1.0 - xx2 - zz2
		mat.grid[1][2] = yz2  - xw2
	
		mat.grid[2][0] = xz2  - yw2
		mat.grid[2][1] = yz2  + xw2
		mat.grid[2][2] = 1.0 - xx2 - yy2
	
		'matrix.f14 = matrix.f24 = matrix.f34 = matrix.f14 = matrix.f42 = matrix.f43 = 0.0
		mat.grid[3][0] = 0.0; mat.grid[3][1] = 0.0; mat.grid[3][2] = 0.0
		mat.grid[0][3] = 0.0; mat.grid[1][3] = 0.0; mat.grid[2][3] = 0.0
		mat.grid[3][3] = 1.0
		
		
	
	End
	
	
	
	Method QuatToEuler:Float[]()
		'' return pitch[0], roll[1], yaw[2]
		
		Local ret_var:Float[3]
	
		Local mat:Matrix = New Matrix
		QuatToMatrix(x,y,z,w,mat)

		'ret_var[0]=ATan2( mat.grid[2][1],Sqrt( mat.grid[2][0]*mat.grid[2][0]+mat.grid[2][2]*mat.grid[2][2] ) )
		'ret_var[2]=ATan2(mat.grid[2][0],mat.grid[2][2])
		'ret_var[1]=ATan2(mat.grid[0][1],mat.grid[1][1])
		ret_var[0]=ATan2( mat.grid[1][2],Sqrt( mat.grid[0][2]*mat.grid[0][2]+mat.grid[2][2]*mat.grid[2][2] ) )
		ret_var[2]=ATan2( mat.grid[0][2],mat.grid[2][2])
		ret_var[1]=ATan2( mat.grid[1][0],mat.grid[1][1])
				
		
		Return ret_var
	End
	
	Function QuatToEuler:Float[](xx#,yy#,zz#,ww#)
		'' return pitch[0], roll[1], yaw[2]
		
		Local ret_var:Float[3]

		Local mat:Matrix = New Matrix
		QuatToMatrix(xx,yy,zz,ww,mat)

	
		'ret_var[0]=ATan2( mat.grid[2][1],Sqrt( mat.grid[2][0]*mat.grid[2][0]+mat.grid[2][2]*mat.grid[2][2] ) )
		'ret_var[2]=ATan2(mat.grid[2][0],mat.grid[2][2])
		'ret_var[1]=ATan2(mat.grid[0][1],mat.grid[1][1])
		ret_var[0]=ATan2( mat.grid[1][2],Sqrt( mat.grid[0][2]*mat.grid[0][2]+mat.grid[2][2]*mat.grid[2][2] ) )
		ret_var[2]=ATan2(mat.grid[0][2],mat.grid[2][2])
		ret_var[1]=ATan2(mat.grid[1][0],mat.grid[1][1])
				
		
		Return ret_var
	End 
	
	Function EulerToQuat:Quaternion(rx#,ry#,rz#) ''*****double-check to make sure correct******
		
		Local q:Quaternion = New Quaternion
		
		Local p = rx * 0.5
		Local y = ry * 0.5
		Local r = rz * 0.5
	 
		Local sinp = Sin(p)
		Local siny = Sin(y)
		Local sinr = Sin(r)
		Local cosp = Cos(p)
		Local cosy = Cos(y)
		Local cosr = Cos(r)
	 
		q.x = sinr * cosp * cosy - cosr * sinp * siny
		q.y = cosr * sinp * cosy + sinr * cosp * siny
		q.z = cosr * cosp * siny - sinr * sinp * cosy
		q.w = cosr * cosp * cosy + sinr * sinp * siny
	 
		q.Normalize()
		
		Return q
	End
		
	Function Slerp:Quaternion(ax#,ay#,az#,aw#,bx#,by#,bz#,bw#, t#)
		
		Local var:Quaternion = New Quaternion ''cx, cy, cz, cw
		
		If Abs(ax-bx)<0.001 And Abs(ay-by)<0.001 And Abs(az-bz)<0.001 And Abs(aw-bw)<0.001
			var.x=bx
			var.y=by
			var.z=bz
			var.w=bw
			Return var
		Endif
		
		Local cosineom#=ax*bx+ay*by+az*bz+aw*bw
		Local scaler_w#
		Local scaler_x#
		Local scaler_y#
		Local scaler_z#
		
		If cosineom <= 0.0
			cosineom=-cosineom
			scaler_w=-bw
			scaler_x=-bx
			scaler_y=-by
			scaler_z=-bz
		Else
			scaler_w=bw
			scaler_x=bx
			scaler_y=by
			scaler_z=bz

		Endif
		
		Local scale0#
		Local scale1#
		
		'Local sinomega# = Sqrt(1.0 - cosineom*cosineom)

		If (1.0-cosineom)>0.0001
			Local omega#=ACos(cosineom)
			Local sineom#=1.0 / Sin(omega)
			'sinomega = 1.0/sinomega
			scale0=Sin((1.0-t)*omega)*sineom
			scale1=Sin(t*omega)*sineom
			
		Else
			scale0=1.0-t
			scale1=t
		Endif
	
		var.w=scale0*aw+scale1*scaler_w
		var.x=scale0*ax+scale1*scaler_x
		var.y=scale0*ay+scale1*scaler_y
		var.z=scale0*az+scale1*scaler_z
		'var.Normalize()
		
		Return var
	End 


	
	Method RotateVector:Vector(vec:Vector)

		Local ax#,ay#,az#,aw#, vec2:Vector = New Vector
	
		ax = -(x * vec.x) - (y * vec.y) - (z * vec.z)
		ay =  (w * vec.x) + (y * vec.z) - (z * vec.y)
		az =  (w * vec.y) - (x * vec.z) + (z * vec.x)
		aw =  (w * vec.z) + (x * vec.y) - (y * vec.x)
	
		vec2.x = (az * vec.y) - (aw * vec.x) - (ay * vec.z)
		vec2.y = (ax * vec.z) - (aw * vec.y) - (az * vec.x)
		vec2.z = (ay * vec.x) - (aw * vec.z) - (ax * vec.y)
		
		Return vec2
	End
	
	Method Inverse:Quaternion()
		Return New Quaternion( -Self.x, -Self.y, -Self.z, Self.w)
	End
	
	Method Normalize:Quaternion()
		Local l# = x * x + y * y + z * z + w * w

		If ( l = 0 )
			x = 0
			y = 0
			z = 0
			w = 0
		Else
			l = 1.0 / Sqrt(l)
			x = x * l
			y = y * l
			z = z * l
			w = w * l
		End
		
		Return Self
	End
	
	Method Multiply:Quaternion(q2:Quaternion)
		Local q:Quaternion = New Quaternion
		q.x =  x * q2.w + y * q2.z - z * q2.y + w * q2.x
		q.y = -x * q2.z + y * q2.w + z * q2.x + w * q2.y
		q.z =  x * q2.y - y * q2.x + z * q2.w + w * q2.z
		q.w = -x * q2.x - y * q2.y - z * q2.z + w * q2.w
		Return q
	End
	
	Method Multiply:Quaternion(q2x#, q2y#, q2z#, q2w#)
		Local q:Quaternion = New Quaternion
		q.x =  x * q2w + y * q2z - z * q2y + w * q2x
		q.y = -x * q2z + y * q2w + z * q2x + w * q2y
		q.z =  x * q2y - y * q2x + z * q2w + w * q2z
		q.w = -x * q2x - y * q2y - z * q2z + w * q2w
		Return q
	End

	Method Multiply:Vector( v:Vector)

		Local ix# =  w * v.x + y * v.z - z * v.y
		Local iy# =  w * v.y + z * v.x - x * v.z
		Local iz# =  w * v.z + x * v.y - y * v.x
		Local iw# = -x * v.x - y * v.y - z * v.z

		' inverse quat

		Local xx# = ix * w + iw * -x + iy * -z - iz * -y
		Local yy# = iy * w + iw * -y + iz * -x - ix * -z
		Local zz# = iz * w + iw * -z + ix * -y - iy * -x

		Return New Vector(xx,yy,zz)	
	End
	
End 

