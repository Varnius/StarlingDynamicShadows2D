package starling.extensions.post.effects
{
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.Program3D;
	
	import starling.core.Starling;
	import starling.extensions.deferredShading.Utils;
	import starling.extensions.post.PostEffectRenderer;
	import starling.textures.Texture;

	public class PostEffect
	{
		private static const RESAMPLE:String = 'PostEffectResample';
		
		// Compiled programs
		
		private static var resampleProgram:Program3D;
	
		// Misc
		
		public var renderer:PostEffectRenderer;		
		public var prerenderTextureWidth:int;
		public var prerenderTextureHeight:int;
		
		private var dirty:Boolean = true;

		/**
		 * Effect blend mode.
		 */
		//public var blendMode:String = EffectBlendMode.ALPHA;

		public function render():void
		{		
			if(dirty) prepare();
			
			/*switch(blendMode)
			{
				case EffectBlendMode.NONE:
					overlay.blendFactorSource = Context3DBlendFactor.ONE;
					overlay.blendFactorDestination = Context3DBlendFactor.ZERO;
					break;
				case EffectBlendMode.ADD:
					overlay.blendFactorSource = Context3DBlendFactor.ONE;
					overlay.blendFactorDestination = Context3DBlendFactor.ONE;
					break;
				case EffectBlendMode.ALPHA:
					overlay.blendFactorSource = Context3DBlendFactor.SOURCE_ALPHA;
					overlay.blendFactorDestination = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
					break;
				case EffectBlendMode.MULTIPLY:
					overlay.blendFactorSource = Context3DBlendFactor.DESTINATION_COLOR;
					overlay.blendFactorDestination = Context3DBlendFactor.ZERO;
					break;
			}*/
		}
		
		public function invalidate():void
		{
			prepare();
		}
		
		public function dispose(programs:Boolean = false):void
		{
			if(programs) Starling.current.deleteProgram(RESAMPLE);
		}
		
		protected function prepare():void
		{			
			dirty = false;
			
			if(!Starling.current.getProgram(RESAMPLE))
			{
				resampleProgram = Starling.current.registerProgramFromSource(RESAMPLE, VERTEX_SHADER, FRAGMENT_SHADER, 2);
			}			
		}
		
		/*--------------------
		Resample
		--------------------*/
		
		/**
		 * Resamples source texture to target texture.
		 * For example, if target texture is smaller than source texture, downsampling occurs.
		 */
		protected function resample(source:Texture, target:Texture):void
		{
			var context:Context3D = Starling.current.context;
			
			context.setVertexBufferAt(0, renderer.overlayVertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			context.setVertexBufferAt(1, renderer.overlayVertexBuffer, 3, Context3DVertexBufferFormat.FLOAT_2);
			context.setTextureAt(0, source.base);
			context.setProgram(resampleProgram);
			context.setRenderToTexture(target.base);
			context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
			context.clear();
			
			context.drawTriangles(renderer.overlayIndexBuffer);
			
			context.setRenderToBackBuffer();
		}
		
		/*---------------------------
		Programs
		---------------------------*/		
		
		private const VERTEX_SHADER:String = 			
			Utils.joinProgramArray(
				[					
					// Move UV coords to varying-0
					"mov v0, va1",
					// Set vertex position as output
					"mov op, va0"			
				]
			);
		
		/**
		 * Combines previously rendered maps.
		 */
		private const FRAGMENT_SHADER:String =
			Utils.joinProgramArray(
				[					
					// Sample source texture	
					"tex ft0, v0, fs0 <2d,clamp,linear>",
					"mov oc, ft0",
				]
			);
	}
}