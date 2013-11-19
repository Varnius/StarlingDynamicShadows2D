package starling.filters
{
	import flash.display3D.Context3D;
	
	import starling.core.RenderSupport;
	import starling.display.DisplayObject;
	import starling.textures.Texture;

	public class DynamicShadows extends FragmentFilter
	{
		public function DynamicShadows(numPasses:int=1, resolution:Number=1.0)
		{
			super(numPasses, resolution);
		}
		
		override public function dispose():void
		{
			super.dispose();
		}
		
		override public function render(object:DisplayObject, support:RenderSupport, parentAlpha:Number):void
		{
			super.render(object, support, parentAlpha);
		}
		
		override protected function activate(pass:int, context:Context3D, texture:Texture):void
		{
			
		}
		
		override protected function deactivate(pass:int, context:Context3D, texture:Texture):void
		{
			
		}
	}
}