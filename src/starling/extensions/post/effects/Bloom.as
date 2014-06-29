package starling.extensions.post.effects
{
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.Program3D;
	
	import starling.core.Starling;
	import starling.extensions.deferredShading.Utils;
	import starling.textures.Texture;

	public class Bloom extends BlurBase
	{
		public static const BLOOM:String = 'PostEffectBloom';
		public static const THRESHOLD:String = 'PostEffectBloomThreshold';
		
		// Cache	

		private var thresholdProgram:Program3D;
		private var bloomProgram:Program3D;
		
		private var renderTarget1:Texture;		
		private var renderTarget2:Texture;
		private var renderTarget3:Texture;
		private var renderTarget4:Texture;
		
		private var constant:Vector.<Number> = new <Number>[0, 0, 0, 0];
		
		/**
		 * Color threshold.
		 */
		public var threshold:Number = 0.3;
		
		/**
		 * Saturation of original scene.
		 */
		public var sourceSaturation:Number = 1.0;
		
		/**
		 * Saturation of bloom.
		 */
		public var bloomSaturation:Number = 1.3;
		
		/**
		 * Blend maount of original scene.
		 */
		public var sourceIntensity:Number = 1.0;
		
		/**
		 * Blend amount of bloom.
		 */
		public var intensity:Number = 1.0;
		
		/**
		 * Renders scene in half screen resolution, then downsamples to 1/4 screen resolution
		 * and applies blur, then upsamples to 1/2 screen resolution again. The result is sampled by bloom program.
		 */
		override public function render():void
		{
			super.render();
			
			var context:Context3D = Starling.current.context;
			var mostRecentRender:Texture = renderer.getMostRecentRender();
			
			/*-------------------
			Render scene with
			color threshold
			-------------------*/
			
			// Set attributes
			context.setVertexBufferAt(0, renderer.overlayVertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			context.setVertexBufferAt(1, renderer.overlayVertexBuffer, 3, Context3DVertexBufferFormat.FLOAT_2);				
			
			constant[0] = threshold;
			constant[3] = 1 - threshold;
			
			// Set constants
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, constant, 1);
			
			// Set samplers
			context.setTextureAt(0, mostRecentRender.base);
			
			// Set program
			context.setProgram(thresholdProgram);
			
			// Render
			context.setRenderToTexture(renderTarget1.base);
			context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
			context.clear();
			
			context.drawTriangles(renderer.overlayIndexBuffer);			
			context.setRenderToBackBuffer(); 
			
			/*-------------------
			Downsample scene			
			-------------------*/		
			
			resample(renderTarget1, renderTarget2);	
			
			/*-------------------
			Blur downsampled scene			
			-------------------*/
			
			blur(renderTarget2, renderTarget3, prerenderTextureWidth / 2, prerenderTextureHeight / 2);
			
			/*-------------------
			Upsample
			-------------------*/
			
			resample(renderTarget2, renderTarget1);
			
			/*-------------------
			Render final view
			-------------------*/
			
			// Set attributes
			context.setVertexBufferAt(0, renderer.overlayVertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			context.setVertexBufferAt(1, renderer.overlayVertexBuffer, 3, Context3DVertexBufferFormat.FLOAT_2);			
			
			// Set constants 			
			constant[0] = sourceIntensity;
			constant[1] = intensity;
			constant[2] = sourceSaturation;
			constant[3] = bloomSaturation;			
			
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, constant, 1);
			
			constant[0] = 0.3;
			constant[1] = 0.59;
			constant[2] = 0.11;
			constant[3] = 1.0;
			
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, constant, 1);
			
			// Set samplers
			context.setTextureAt(0, mostRecentRender.base);
			context.setTextureAt(1, renderTarget1.base);		
			
			// Set program
			context.setProgram(bloomProgram);			
			
			// Combine
			context.setRenderToTexture(renderer.getRenderTarget().base);
			context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
			context.clear();			
			context.drawTriangles(renderer.overlayIndexBuffer);				
			context.setRenderToBackBuffer();
			
			// Clean up
			context.setVertexBufferAt(0, null);
			context.setVertexBufferAt(1, null);
			context.setTextureAt(0, null);
			context.setTextureAt(1, null);
		}
		
		override public function dispose(programs:Boolean = false):void
		{
			super.dispose(programs);
			
			if(programs)
			{
				Starling.current.deleteProgram(BLOOM);
				Starling.current.deleteProgram(THRESHOLD);
			}			
			
			if(renderTarget1) renderTarget1.dispose();
			if(renderTarget2) renderTarget2.dispose();
			if(renderTarget3) renderTarget3.dispose();
			if(renderTarget4) renderTarget4.dispose();
		}
		
		override protected function prepare():void
		{		
			super.prepare();
			
			var context:Context3D = Starling.current.context;
			
			if(!Starling.current.getProgram(THRESHOLD))
			{
				thresholdProgram = Starling.current.registerProgramFromSource(THRESHOLD, THRESHOLD_VERTEX_SHADER, THRESHOLD_FRAGMENT_SHADER, 2);
			}
			
			if(!Starling.current.getProgram(BLOOM))
			{
				bloomProgram = Starling.current.registerProgramFromSource(BLOOM, BLOOM_VERTEX_SHADER, BLOOM_FRAGMENT_SHADER, 2);
			}
			
			prerenderTextureWidth = Math.round(Starling.current.nativeStage.stageWidth / 2);
			prerenderTextureHeight = Math.round(Starling.current.nativeStage.stageHeight / 2);
			
			dispose();
			
			renderTarget1 = Texture.empty(prerenderTextureWidth, prerenderTextureHeight, false, false, true, -1, Context3DTextureFormat.BGRA);
			renderTarget2 = Texture.empty(prerenderTextureWidth / 2, prerenderTextureHeight / 2, false, false, true, -1, Context3DTextureFormat.BGRA);
			renderTarget3 = Texture.empty(prerenderTextureWidth / 2, prerenderTextureHeight / 2, false, false, true, -1, Context3DTextureFormat.BGRA);
		}
		
		/*---------------------------
		Bloom program
		---------------------------*/		
		
		protected const BLOOM_VERTEX_SHADER:String = 			
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
		protected const BLOOM_FRAGMENT_SHADER:String =
			Utils.joinProgramArray(
				[					
					// Sample regular scene
					"tex ft0, v0, fs0 <2d,clamp,linear>",			
					// Sample threshold scene
					"tex ft1, v0, fs1 <2d,clamp,linear>",
					
					// Adjust regular scene color saturation
					"dp3 ft2.xyz, ft0.xyz, fc1.xyz",
					// lerp: x + s * (y - x)
					"sub ft3.xyz, ft0.xyz, ft2.xyz",
					"mul ft3.xyz, ft3.xyz, fc0.zzz",
					"add ft0.xyz, ft2.xyz, ft3.xyz",
					
					// Adjust threshold scene color saturation
					"dp3 ft2.xyz, ft1.xyz, fc1.xyz",
					// lerp: x + s * (y - x)
					"sub ft3.xyz, ft1.xyz, ft2.xyz",
					"mul ft3.xyz, ft3.xyz, fc0.www",
					"add ft1.xyz, ft2.xyz, ft3.xyz",
					
					// Adjust color intensity
					"mul ft0.xyz, ft0.xyz, fc0.x",
					"mul ft1.xyz, ft1.xyz, fc0.y",
					
					// 1 - saturate(bloomColor)
					"sat ft2.xyz, ft1.xyz",
					"sub ft2.xyz, fc1.www, ft2.xyz",			
					
					// Darken original scene where bloom is bright
					"mul ft0.xyz, ft0.xyz, ft2.xyz",
					
					// Add both samples
					"add ft0, ft0, ft1",
					"mov ft0.w, fc1.w",
					
					// Return final color
					"mov oc, ft0"
				]
			);
		
		/*---------------------------
		Threshold program
		---------------------------*/
		
		protected const THRESHOLD_VERTEX_SHADER:String = 			
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
		protected const THRESHOLD_FRAGMENT_SHADER:String =
			Utils.joinProgramArray(
				[					
					// Formula: saturate((Color – Threshold) / (1 – Threshold))			
					// Get color
					"tex ft0, v0, fs0 <2d,clamp,linear>",
					// Color - Threshold
					"sub ft0.xyz, ft0.xyz, fc0.xxx",
					// (Color – Threshold) / (1 – Threshold)
					"mul ft0.xyz, ft0.xyz, fc0.www",
					// Saturate
					"sat ft0, ft0",
					
					// Return final color
					"mov oc, ft0",
				]
			);
	}
}