''
''
'' TShader
''
Import tbrush
Import minib3d


Class TShader Extends TBrush
	
	'' TBrush includes color, shininess, texture, etc.
	
	Global process_list:List<TShader> = New List<TShader>
	'Global layer_list:List<TShader> = New List<TShader>
	Field list_link:list.Node<TShader>
	
	'Global enabled:Int =0 ''Init shaders by TRender ---NOT USED??? use active instead?
	
	Global g_shader:TShader ''current shader
	Global default_shader:TShader ''fixed function equivalent
	
	Field active:Int =0
	Field shader_id:Int =0
	Field fragment_id:Int =0
	Field vertex_id:Int =0
	
	Field override:Bool = False ''override shader brushes
	
	''all driver implementations need this
	'Method LoadShader:TShader(vp_file:String, fp_file:String) Abstract
	Method CompileShader:Int(source:String, type:Int) Abstract


	Function LoadDefaultShader:TShader(vp_file:String, fp_file:String) 'Abstract
		''load default shader on init
		''extend me
		'default_shader = LoadShader(vp_file, fp_file)
	End

	Function LoadShader:TShader(vp_file:String, fp_file:String) 'Abstract
		''extend me
	End
	
	Method IsValid:Int()
	
		Return shader.active
		
	End
	
	Function PreProcess()
		
		For Local sh:TShader = Eachin process_list
			TShaderProcess(sh).PreProcess()
		Next
		
	End
	
	Function PostProcess()
		
		For Local sh:TShader = Eachin process_list
			TShaderProcess(sh).PostProcess()
		Next
		
	End
	
	''adds to TShaderProcess list in TShader
	''
	Function AddProcess(sh:TShader)
		
		If TShaderProcess(sh) <> Null
			
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
	
	Function DefaultShader()
		
		g_shader.active = 0
		g_shader = default_shader
		g_shader.active = 1
		
	End
	
	Method Override(i:Int)
	
		If i Then override = True Else override = False
		
	End
	
	Method RenderCamera(cam:TCamera)
		
		TRender.render.RenderCamera(cam)
		
	End
	
	Method Update()
		
		''runs after each mesh (if implemented in hardware render). ideal for setting uniforms
		
	End
	
End



Interface TShaderProcess
	
	Method PreProcess:Int() ''run before all rendering (ie. clear framebuffer)
	
	Method PostProcess:Int() ''run after all rendering (ie. draw framebuffer, blur, etc)
	
End

Interface TShaderRender Extends TShaderProcess
	
	Method Render:Int(cam:TCamera)
	
	'Method PreProcess:Int() ''run before all rendering (ie. clear framebuffer)
	
	'Method PostProcess:Int() ''run after all rendering (ie. draw framebuffer, blur, etc)
	
End
