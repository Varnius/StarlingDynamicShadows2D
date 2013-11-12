package
{
	import starling.display.Quad;
	import starling.display.Sprite;
	
	public class StarlingApp extends Sprite
	{
		public function StarlingApp()
		{
			// Add quads
			
			var quad:Quad;
			
			quad = new Quad(100, 100, Math.random() * 0xFFFFFF);
			quad.x = quad.y = 180;
			quad.rotation = 45;
			addChild(quad);
			
			quad = new Quad(200, 100, Math.random() * 0xFFFFFF);
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