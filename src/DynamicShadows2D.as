package
{
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.geom.Rectangle;
	
	import starling.core.Starling;
	
	[SWF(frameRate="60",width="900",height="600")]
	public class DynamicShadows2D extends Sprite
	{
		private var _starling:Starling;
		
		public function DynamicShadows2D()
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;

			var viewport:Rectangle = new Rectangle(0, 0, 900, 600);
			
			_starling = new Starling(StarlingApp, stage, viewport);			
			_starling.stage.stageWidth  = 900;
			_starling.stage.stageHeight = 600;
			_starling.showStats = true;
			_starling.start();
		}
	}
}