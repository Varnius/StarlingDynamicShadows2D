package feathers.themes
{
	import feathers.controls.Label;
	import feathers.themes.MetalWorksMobileTheme;
	
	import starling.display.DisplayObjectContainer;
	
	/**
	 * Lumos theme.
	 * @author Varnius
	 */
	public class LumosTheme extends MetalWorksMobileTheme
	{
		// Font identifiers
		
		public static const VERA_SANS_MONO:String = "VeraSansMono";
		
		public static const ALTERNATE_NAME_MY_CUSTOM_BUTTON:String = "lelabel";
		
		[Embed(source="/assets/fonts/VeraSansMono.fnt", mimeType="application/octet-stream")]
		public static const FontXml:Class;
		
		[Embed(source = "/assets/fonts/VeraSansMono.png")]
		public static const FontTexture:Class;		
		
		public function LumosTheme(container:DisplayObjectContainer=null, scaleToDPI:Boolean=true)
		{
			super(container, scaleToDPI);
		}
		
		override protected function initialize():void
		{
			super.initialize();
			
			// Init fonts
			
			/*var texture:Texture = Texture.fromBitmap(new FontTexture());
			var xml:XML = XML(new FontXml());
			var VeraSansMono:BitmapFont = new BitmapFont(texture, xml);
			
			VeraSansMono.smoothing = TextureSmoothing.NONE;
			TextField.registerBitmapFont(VeraSansMono, VERA_SANS_MONO);
			
			this.setInitializerForClass(Label, labelInitializer, ALTERNATE_NAME_MY_CUSTOM_BUTTON);*/
		}
		
		private function labelInitializer(label:Label):void
		{			
			/*label.textRendererProperties.textFormat = new BitmapFontTextFormat(VERA_SANS_MONO, 32, 0xFF0000);
			label.textRendererFactory = 
				function():ITextRenderer
				{
					return new BitmapFontTextRenderer();
				}*/
			
			//label.textRendererProperties.textFormat = new TextFormat("SourceSansPro", 20, 0xFF0000);
			//label.textRendererProperties.embedFonts = true;
		}
	}
}