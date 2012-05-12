''
''
'' TShader
''
Import tbrush
Import minib3d


Class TShader Extends TBrush
	
	'' TBrush includes color, shininess, texture, etc.
	
	Global process_list:List<TShaderProcess> = New List<TShaderProcess>
	Field list_link:list.Node<TShaderProcess>
	
	Global enabled:Int =0 ''Init shaders by TRender ---NOT USED??? use active instead?
	
	Global g_shader:TShader
	
	Field active:Int =0
	Field shader_id:Int =0
	Field fragment_id:Int =0
	Field vertex_id:Int =0
	
	''all driver implementations need this
	'Method LoadShader:TShader(vp_file:String, fp_file:String) Abstract
	Method CompileShader:Int(source:String, type:Int) Abstract

	Function DefaultShader:Void(vp_file:String, fp_file:String) 'Abstract
		''load default shader on init
		''extend me
		'g_shader = LoadShader(vp_file, fp_file)
	End

	Function LoadShader:TShader(vp_file:String, fp_file:String) 'Abstract
		''extend me
	End
	
	Method IsValid:Int()
	
		Return shader.active
		
	End
	
	Function PreProcess()
		
		For Local sh:TShaderProcess = Eachin process_list
			sh.PreProcess()
		Next
		
	End
	
	Function PostProcess()
		
		For Local sh:TShaderProcess = Eachin process_list
			sh.PostProcess()
		Next
		
	End
	
End


Interface TShaderProcess
	
	Method PreProcess:Void() ''run before all rendering (ie. clear framebuffer)
	
	Method PostProcess:Void() ''run after all rendering (ie. draw framebuffer, blur, etc)
	
	Method AddProcessList:Void() ''adds to TShaderProcess list in TShader
	'self.list_link = TShader.process_list.AddLast(self)
	
End

