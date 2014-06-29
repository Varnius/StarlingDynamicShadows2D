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
	public class Sandbox extends Sprite
	{
		private var _starling:Starling;
		private var	stage3D:Stage3D;
		
		public function Sandbox()
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.addEventListener(MouseEvent.RIGHT_CLICK, function(e:Event):void {});
			
			// save a reference to the stage3D instance we're using
			stage3D = stage.stage3Ds[0];
			
			var viewport:Rectangle = new Rectangle(0, 0, 1024, 600);
			
			_starling = new Starling(SandboxStarling, stage, viewport, stage3D, Context3DRenderMode.AUTO, Context3DProfile.STANDARD);	
			_starling.stage.stageWidth  = stage.stageWidth;
			_starling.stage.stageHeight = stage.stageHeight;
			_starling.enableErrorChecking = true;
			_starling.showStats = true;
			_starling.start();
		}
	}
}