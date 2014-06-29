package starling.extensions.post
{
	import com.adobe.utils.AGALMiniAssembler;
	
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	
	import starling.core.RenderSupport;
	import starling.core.Starling;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.extensions.deferredShading.Utils;
	import starling.extensions.post.effects.PostEffect;
	import starling.textures.Texture;

	public class PostEffectRenderer extends Sprite
	{
		public var assembler:AGALMiniAssembler = new AGALMiniAssembler();
		
		// Quad
		
		public var overlayVertexBuffer:VertexBuffer3D;
		public var overlayIndexBuffer:IndexBuffer3D;
		protected var vertices:Vector.<Number> = new <Number>[-1, 1, 0, 0, 0, -1, -1, 0, 0, 1, 1,  1, 0, 1, 0, 1, -1, 0, 1, 1];
		protected var indices:Vector.<uint> = new <uint>[0,1,2,2,1,3];
		
		// RTs
		
		public var originalScene:Texture;
		
		private var tmpA:Texture;
		private var tmpB:Texture;
		
		private var mostRecentRender:Texture;
		private var renderTarget:Texture;
		
		public function getMostRecentRender():Texture
		{
			return mostRecentRender;
		}
		
		public function getRenderTarget():Texture
		{
			return renderTarget;
		}
		
		// Compiled programs
		
		private var combinedResultProgram:Program3D;
		
		// Misc		
		
		private var prepared:Boolean = false;
		
		public function PostEffectRenderer()
		{
			prepare();
			
			// Handle lost context			
			Starling.current.addEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
		}
		
		override public function render(support:RenderSupport, parentAlpha:Number):void
		{
			var context:Context3D = Starling.context;
			var prevRenderTarget:Texture = support.renderTarget;
			
			// Render scene
			
			support.setRenderTarget(originalScene);
			support.clear();
			
			super.render(support, parentAlpha);	
			
			support.setRenderTarget(prevRenderTarget);
			
			// Render effects
			
			renderTarget = tmpA;
			mostRecentRender = originalScene;
			
			for each(var e:PostEffect in _effects)
			{
				e.render();
				
				renderTarget = renderTarget == tmpA ? tmpB : tmpA;
				mostRecentRender = renderTarget == tmpA ? tmpB : tmpA;
			}
			
			// Render the result after applying effects
			
			context.setVertexBufferAt(0, overlayVertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			context.setVertexBufferAt(1, overlayVertexBuffer, 3, Context3DVertexBufferFormat.FLOAT_2);                      
			context.setTextureAt(0, mostRecentRender.base);
			
			context.setProgram(combinedResultProgram);			
			context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO); 
			support.clear();
			
			context.drawTriangles(overlayIndexBuffer);
			support.raiseDrawCount();			
			
			// Clean up
			
			context.setVertexBufferAt(0, null);
			context.setVertexBufferAt(1, null);
			context.setTextureAt(0, null);
		}
		
		private function prepare():void
		{
			var context:Context3D = Starling.context;
			var w:Number = Starling.current.nativeStage.stageWidth;
			var h:Number = Starling.current.nativeStage.stageHeight;			
			
			// Create a quad for rendering full screen passes
			
			overlayVertexBuffer = context.createVertexBuffer(4, 5);
			overlayVertexBuffer.uploadFromVector(vertices, 0, 4);
			overlayIndexBuffer = context.createIndexBuffer(6);
			overlayIndexBuffer.uploadFromVector(indices, 0, 6);
			
			// Create RTs
			
			originalScene = Texture.empty(w, h, false, false, true, -1, Context3DTextureFormat.BGRA);
			tmpA = Texture.empty(w, h, false, false, true, -1, Context3DTextureFormat.BGRA);
			tmpB = Texture.empty(w, h, false, false, true, -1, Context3DTextureFormat.BGRA);
			
			// Invalidate each effect
			
			for each(var e:PostEffect in _effects)
			{
				e.invalidate();
			}
			
			// Create programs
			
			combinedResultProgram = assembler.assemble2(context, 2, VERTEX_SHADER, FRAGMENT_SHADER);
			prepared = true;
		}
		
		override public function dispose():void
		{
			super.dispose();
			
			originalScene.dispose();
			tmpA.dispose();
			tmpB.dispose();
			overlayIndexBuffer.dispose();
			overlayVertexBuffer.dispose();
			
			for each(var e:PostEffect in _effects)
			{
				e.dispose(true);
			}
		}
		
		/*-----------------------------
		Event handlers
		-----------------------------*/
		
		private function onContextCreated(event:Event):void
		{
			prepared = false;
			prepare();
		}
		
		/*---------------------------
		Programs
		---------------------------*/		
		
		protected const VERTEX_SHADER:String = 			
			Utils.joinProgramArray(
				[
					'mov op, va0',
					'mov v0, va1'
				]
			);
		
		/**
		 * Combines previously rendered maps.
		 */
		protected const FRAGMENT_SHADER:String =
			Utils.joinProgramArray(
				[
					// Sample inputRT
					'tex oc, v0, fs0 <2d, clamp, linear, mipnone>',
				]
			);
		
		/*--------------------------
		Getters/setter		
		--------------------------*/
		
		private var _effects:Vector.<PostEffect> = new <PostEffect>[];
		
		public function get effects():Vector.<PostEffect>
		{ 
			return _effects; 
		}
		public function set effects(value:Vector.<PostEffect>):void
		{
			_effects = value;
			
			for each(var e:PostEffect in value)
			{
				e.renderer = this;
			}
		}
	}
}