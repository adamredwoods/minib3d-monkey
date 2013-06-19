''
''
'' TShader
''
Import tbrush
Import minib3d

Interface IShader2D
	Method SetShader2D:Void()
End

Class BlankShader Implements IShader2D
	Method SetShader2D:Void()
	end
End


Class TShader Extends TBrush
	
	'' TBrush includes color, shininess, texture, etc.
	
	Global process_list:List<TShader> = New List<TShader>
	'Global layer_list:List<TShader> = New List<TShader>
	Field list_link:list.Node<TShader>

	
	Global g_shader:TShader ''current shader
	Global default_shader:TShader ''fixed function equivalent
	
	Field active:Int =0
	Field shader_id:Int =0
	Field fragment_id:Int =0
	Field vertex_id:Int =0
	
	Field override:Bool = False ''override all other shader brushes
	
	''all driver implementations need this
	'Method LoadShader:TShader(vp_file:String, fp_file:String) Abstract
	Method CompileShader:Int(source:String, type:Int) Abstract

	Method Copy:TBrush() Abstract


	Function LoadDefaultShader:TShader(vp_file:String, fp_file:String) 'Abstract
		''load default shader on init
		''extend me
		'default_shader = LoadShader(vp_file, fp_file)
	End
	
	Function LoadDefaultShader:Void(sh:TShader)
	
		default_shader = sh
		SetShader( default_shader )
		
	End
	
	Function LoadShader:TShader(vp_file:String, fp_file:String) 'Abstract
		''extend me
	End
	
	Method IsValid:Int()
	
		Return shader.active
		
	End
	
	Function PreProcess(cam:TCamera)
		
		For Local sh:TShader = Eachin process_list
			IShaderProcess(sh).PreProcess(cam)
		Next
		
	End
	
	Function PostProcess(cam:TCamera)
		
		For Local sh:TShader = Eachin process_list
			IShaderProcess(sh).PostProcess(cam)
		Next
		
	End
	
	''adds to TShaderProcess list in TShader
	''
	Function AddProcess(sh:TShader)
		
		If IShaderProcess(sh) <> Null
			
			sh.list_link = TShader.process_list.AddLast(sh)
			
		Endif
		
	End
	
	
	''Custom Shader methods
	''
	
	Function SetShader(sh:TShader)
		
		If g_shader Then g_shader.active = 0
		g_shader = sh
		g_shader.active = 1
					
	End
	
	Function DefaultShader:TShader()
		
		If Not (g_shader) Then Return Null
		
		g_shader.active = 0
		g_shader = default_shader
		g_shader.active = 1
		
		Return default_shader
		
	End
	
	Method Override(i:Int)
	
		If i Then override = True Else override = False
		
	End
	
	Method Update()
		
		''runs per each surface (if implemented in hardware render). ideal for setting uniforms
		
	End
	
	
	'-- helper function, can be used to bounce back to default render function
	Method RenderCamera(cam:TCamera)
		
		TRender.render.RenderCamera(cam)
		
	End
	

	''-- helper function
	''-- draws entity with g_shader instead of brush shader
	Method DrawEntity:Void(cam:TCamera, ent:TEntity)
		
		''update camera, since this routine is used in shaders
		Local temp1:Int = cam.cls_color
		Local temp2:Int = cam.cls_zbuffer
		cam.cls_color = False
		cam.cls_zbuffer = False
		
		TRender.render.UpdateCamera(cam)
		
		cam.cls_color = temp1
		cam.cls_zbuffer = temp2
		
		
		Local temp:Int = ent.shader_brush.active
		ent.shader_brush.active= 0	
		TRender.render.Render(ent,cam)
		ent.shader_brush.active= temp
		
	End
	

	
End


''
'' standard pre/post per camera
''
Interface IShaderProcess
	
	Method PreProcess:Int(cam:TCamera) ''run before all rendering (ie. clear framebuffer)
	
	Method PostProcess:Int(cam:TCamera) ''run after all rendering (ie. draw framebuffer, blur, etc)
	
End

''
''used to take control of the pipeline. could be used to implements passes (call RenderCamera() per pass)
''
Interface IShaderRender Extends IShaderProcess
	
	Method Render:Int(cam:TCamera)
	
End


''
''used to process a pre/post shader per entity (used in brushes)
''
Interface IShaderEntity Extends IShaderProcess
	
	Method RenderEntity:Void(cam:TCamera, ent:TEntity)
	
End
