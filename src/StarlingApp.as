package
{
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	
	public class StarlingApp extends Sprite
	{
		public function StarlingApp()
		{
			if(!stage)
			{
				addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			}
			else
			{
				onAddedToStage();
			}
		}
		
		private function onAddedToStage(e:Event = null):void
		{
			var quad:Quad;
			
			// Add BG
			
			addChild(new Quad(stage.stageWidth, stage.stageHeight, 0xCCCCCC));
			
			// Add quads that should cast shadows		
			
			quad = new Quad(70, 70, Math.random() * 0xFFFFFF);
			quad.x = quad.y = 180;
			quad.rotation = 45;
			addChild(quad);
			
			quad = new Quad(100, 50, Math.random() * 0xFFFFFF);
			quad.x = 600;
			quad.y = 50;
			quad.rotation = 0;
			addChild(quad);
			
			quad = new Quad(300, 50, Math.random() * 0xFFFFFF);
			quad.alignPivot();
			quad.x = 600;
			quad.y = 450;
			quad.rotation = -0.5;
			addChild(quad);
		}
	}
}