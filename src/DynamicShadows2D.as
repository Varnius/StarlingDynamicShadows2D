package
{
	import flash.display.Sprite;
	import flash.display.Stage3D;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.display3D.Context3DProfile;
	import flash.display3D.Context3DRenderMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	import starling.core.Starling;
	
	[SWF(frameRate="60",width="1024",height="600")]
	public class DynamicShadows2D extends Sprite
	{
		private var _starling:Starling;
		private var	stage3D:Stage3D;
		
		public function DynamicShadows2D()
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.addEventListener(MouseEvent.RIGHT_CLICK, function(e:Event):void {});
			
			// save a reference to the stage3D instance we're using
			stage3D = stage.stage3Ds[0];
			
			// create the 3D context
			stage3D.addEventListener(Event.CONTEXT3D_CREATE, onContextCreated, false, 0, true);
			stage3D.requestContext3D(Context3DRenderMode.AUTO, Context3DProfile.BASELINE_EXTENDED);
		}
		
		private function onContextCreated(event:Event):void
		{
			stage3D.context3D.enableErrorChecking = true;
			stage3D.context3D.configureBackBuffer(stage.stageWidth, stage.stageHeight, 0, false);
			
			var viewport:Rectangle = new Rectangle(0, 0, 1024, 600);
			
			_starling = new Starling(DynamicShadows2DTest, stage, viewport, stage3D, Context3DRenderMode.AUTO, Context3DProfile.BASELINE_EXTENDED);			
			_starling.stage.stageWidth  = stage.stageWidth;
			_starling.stage.stageHeight = stage.stageHeight;
			_starling.enableErrorChecking = true;
			_starling.showStats = true;
			_starling.start();
			
			addEventListener(Event.ENTER_FRAME, tick, false, 0, true);
		}
		
		private function tick(e:Event):void
		{
			stage3D.context3D.clear();
			
			_starling.nextFrame();
			
			stage3D.context3D.present();
		}
	}
}