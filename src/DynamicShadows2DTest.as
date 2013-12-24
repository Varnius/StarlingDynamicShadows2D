package
{
	import flash.display.Bitmap;
	import flash.geom.Point;
	import flash.utils.getTimer;
	
	import feathers.controls.Check;
	import feathers.controls.Label;
	import feathers.controls.LayoutGroup;
	import feathers.controls.PickerList;
	import feathers.controls.ScrollContainer;
	import feathers.controls.Slider;
	import feathers.controls.renderers.DefaultListItemRenderer;
	import feathers.controls.renderers.IListItemRenderer;
	import feathers.data.ListCollection;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.VerticalLayout;
	import feathers.themes.MetalWorksMobileTheme;
	
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.extensions.defferedShading.MaterialProperties;
	import starling.extensions.defferedShading.debug.DebugImage;
	import starling.extensions.defferedShading.display.DeferredShadingContainer;
	import starling.extensions.defferedShading.lights.AmbientLight;
	import starling.extensions.defferedShading.lights.PointLight;
	import starling.textures.Texture;
	
	public class DynamicShadows2DTest extends Sprite
	{
		// Embedded assets
		
		[Embed (source="assets/floor_diffuse.jpg")]
		public static const FLOOR_DIFFUSE:Class;
		
		[Embed (source="assets/floor_normal.jpg")]
		public static const FLOOR_NORMAL:Class;
		
		[Embed (source="assets/face_diffuse.png")]
		public static const FACE_DIFFUSE:Class;
		
		[Embed (source="assets/face_normal.png")]
		public static const FACE_NORMAL:Class;
		
		private var controlledLight:PointLight;
		private var ambientLight:AmbientLight;		
		private var lights:Vector.<PointLight> = new Vector.<PointLight>();
		private var lightPositions:Vector.<Point> = new Vector.<Point>();
		private var lightRadiuses:Vector.<Number> = new Vector.<Number>();
		private var lightVelocities:Vector.<Number> = new Vector.<Number>();
		private var lightAngles:Vector.<Number> = new Vector.<Number>();
		private var container:DeferredShadingContainer;
		private var deferredShadingProps:MaterialProperties;
		
		// RTs
		
		private var rtContainer:Sprite;
		private var debugRT1:DebugImage;
		private var debugRT2:DebugImage;
		private var debugRT3:DebugImage;
		private var debugRT4:DebugImage;
		
		// GUI
		
		private var picker:PickerList;
		private var lightRadiusSlider:Slider;
		private var lightAttenuationSlider:Slider;
		private var lightStrengthSlider:Slider;
		
		public function DynamicShadows2DTest()
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
			var image:Image;
			
			// Add layers
			
			addChild(container = new DeferredShadingContainer());
			
			var diffuse:Texture = Texture.fromBitmap(new FLOOR_DIFFUSE() as Bitmap);
			var normal:Texture = Texture.fromBitmap(new FLOOR_NORMAL() as Bitmap);
			
			deferredShadingProps = new MaterialProperties(normal);
			diffuse.materialProperties = deferredShadingProps;
			
			container.addChild(image = new Image(diffuse));
			
			// RT debug
			
			addChild(rtContainer = new Sprite());
			rtContainer.addChild(debugRT1 = new DebugImage(container.diffuseRenderTarget, 200, 130));
			rtContainer.addChild(debugRT2 = new DebugImage(container.normalRenderTarget, 200, 130));
			rtContainer.addChild(debugRT3 = new DebugImage(container.depthRenderTarget, 200, 130));
			debugRT3.showChannel = 0;
			rtContainer.addChild(debugRT4 = new DebugImage(container.lightPassRenderTarget, 200, 130));
			debugRT1.x = debugRT2.x = debugRT3.x = debugRT4.x = stage.stageWidth - 200;
			debugRT2.y = 130;			
			debugRT3.y = 260;
			debugRT4.y = 390;
			
			// Add some occluders
			
			diffuse = Texture.fromBitmap(new FACE_DIFFUSE() as Bitmap);
			normal = Texture.fromBitmap(new FACE_NORMAL() as Bitmap);
			
			var pp:MaterialProperties = new MaterialProperties(normal);
			diffuse.materialProperties = pp;
			
			container.addChild(image = new Image(diffuse));	
			
			// Generate some random moving lights and a controllable one
			
			var pointLight:PointLight;
			
			for(var i:int = 0; i < 7; i++)
			{
				pointLight = new PointLight(
					Math.random() * 0xFF0000 + Math.random() * 0x00FF00 + Math.random() * 0x0000FF,
					Math.random() + 1,
					Math.random() * 500 + 100
				);
				
				pointLight.x = Math.random() * stage.stageWidth;
				pointLight.y = Math.random() * stage.stageHeight;
				
				lightPositions.push(new Point(pointLight.x, pointLight.y));
				lightRadiuses.push(Math.random() * 100 + 50);
				lightVelocities.push(Math.random() * 15 + 30);
				lightAngles.push(0);
				
				container.addChild(pointLight);
				container.addLight(pointLight);
				lights.push(pointLight);
			}
			
			// Add ambient light
			
			ambientLight = new AmbientLight(0x333333, 0.0);
			container.addChild(ambientLight);
			container.addLight(ambientLight);
			
			controlledLight = new PointLight(0xFFFFFF, 1.0, 200);
			container.addChild(controlledLight);
			container.addLight(controlledLight);
			controlledLight.x = 0;
			controlledLight.y = 200;
			lights.push(controlledLight);
			
			stage.addEventListener(TouchEvent.TOUCH, onTouch);
			stage.addEventListener(Event.ENTER_FRAME, onTick);
			
			// GUI
			
			initGUI();			
		}
		
		/*-----------------------------
		Event handlers
		-----------------------------*/
		
		private var earlier:uint;
		
		private function onTick(e:Event):void
		{
			var radians:Number;
			var now:uint = getTimer();
			var delta:Number = (now - earlier) / 1000;
			earlier = now;
			
			for(var i:int = 0; i < lights.length; i++)
			{
				if(lights[i] == controlledLight)
				{
					continue;
				}
				
				lightAngles[i] += lightVelocities[i] * delta;
				radians = (lightAngles[i] / 180) * Math.PI;
				lights[i].x = lightPositions[i].x + Math.cos(radians) * lightRadiuses[i];
				lights[i].y = lightPositions[i].y - Math.sin(radians) * lightRadiuses[i];
			}
		}
		
		private function onTouch(e:TouchEvent):void
		{
			var touch:Touch = e.getTouch(this);

			if(!touch)
			{
				return;
			}
			
			controlledLight.x = touch.globalX;
			controlledLight.y = touch.globalY;
		}
		
		/*-----------------------------
		GUI
		-----------------------------*/
		
		private function initGUI():void
		{		
			new MetalWorksMobileTheme(null, false);
			
			var slider:Slider;
			var label:Label;
			
			// Container
			
			var container:ScrollContainer = new ScrollContainer();
			container.horizontalScrollPolicy = ScrollContainer.SCROLL_POLICY_OFF;
			container.scrollBarDisplayMode = ScrollContainer.SCROLL_BAR_DISPLAY_MODE_FIXED;
			var layout:VerticalLayout = new VerticalLayout();
			var group:LayoutGroup;
			var hLayout:HorizontalLayout = new HorizontalLayout();
			var cb:Check;
			
			hLayout.gap = 10;
			layout.gap = 10;
			layout.padding = 10;
			container.layout = layout;
			container.width = 410;
			container.height = 300;
			container.y = stage.stageHeight - container.height;
			
			var quad:Quad = new Quad(container.width, container.height, 0x000000);
			quad.alpha = 0.85;
			
			container.backgroundSkin = quad;
			addChild(container);		
			
			// Map visibility
			
			group = new LayoutGroup();
			group.layout = hLayout;
			hLayout.verticalAlign = HorizontalLayout.VERTICAL_ALIGN_MIDDLE;
			cb = new Check();
			cb.label = 'Show intermediate RTs';
			cb.isSelected = true;
			cb.addEventListener(Event.CHANGE, onRTCBChange);
			group.addChild(cb);
			container.addChild(group);
			
			// Specular power
			
			group = new LayoutGroup();
			group.layout = hLayout;
			group.addChild(getLabel('Material specular power:'));	
			group.addChild(label = getLabel());
			container.addChild(group);
			container.addChild(slider = getSlider(0, 200, 15));
			bindSlider(label, slider, onSpecularPowerChange);
			
			// Specular intensity
			
			group = new LayoutGroup();
			group.layout = hLayout;
			group.addChild(getLabel('Material specular intensity:'));	
			group.addChild(label = getLabel());
			container.addChild(group);
			container.addChild(slider = getSlider(0, 5, 1));
			bindSlider(label, slider, onSpecularIntensityChange);
			
			// Light selection
			
			group = new LayoutGroup();
			group.layout = hLayout;
			picker = new PickerList();
			picker.listProperties.itemRendererFactory = lightRendererFactory;
			picker.dataProvider = new ListCollection(lights);
			picker.labelFunction = lightLabelFunction;
			picker.addEventListener(Event.CHANGE, onSelectedLightChange);
			group.addChild(picker);
			container.addChild(picker);
			
			// Light radius
			
			group = new LayoutGroup();
			group.layout = hLayout;
			group.addChild(getLabel('Selected light radius:'));	
			group.addChild(label = getLabel());
			container.addChild(group);
			container.addChild(lightRadiusSlider = getSlider(0, 500, 15));
			bindSlider(label, lightRadiusSlider, onLightRadiusChange);
			
			// Light strength
			
			group = new LayoutGroup();
			group.layout = hLayout;
			group.addChild(getLabel('Selected light strength:'));	
			group.addChild(label = getLabel());
			container.addChild(group);
			container.addChild(lightStrengthSlider = getSlider(0, 50, 5));
			bindSlider(label, lightStrengthSlider, onLightStrengthChange);
			
			// Light strength
			
			group = new LayoutGroup();
			group.layout = hLayout;
			group.addChild(getLabel('Selected light attenuation:'));	
			group.addChild(label = getLabel());
			container.addChild(group);
			container.addChild(lightAttenuationSlider = getSlider(0, 50, 5));
			bindSlider(label, lightAttenuationSlider, onLightAttenuationChange);
			
			// Set control defaults
			onSelectedLightChange();
			
			// Ambient light amount
			
			group = new LayoutGroup();
			group.layout = hLayout;
			group.addChild(getLabel('Ambient light amount:'));	
			group.addChild(label = getLabel());
			container.addChild(group);
			container.addChild(slider = getSlider(0, 1.0, ambientLight.strength));
			bindSlider(label, slider, onAmbientAmountChange);
			
			onSelectedLightChange();
		}
		
		/*-----------------------------
		GUI helpers
		-----------------------------*/
		
		private function getLabel(text:String = ''):Label
		{
			var label:Label = new Label();
			label.text = text;
			return label;
		}
		
		private function getSlider(min:Number, max:Number, value:Number):Slider
		{
			var slider:Slider = new Slider();
			slider.minimum = min;
			slider.maximum = max;
			slider.value = value;
			slider.width = 380;
			slider.height = 30;
			slider.trackScaleMode = Slider.TRACK_SCALE_MODE_EXACT_FIT;
			slider.thumbProperties.height = 30;
			slider.thumbProperties.width = 30;
			
			return slider;
		}
		
		private function bindSlider(label:Label, slider:Slider, callback:Function):void
		{
			label.text = slider.value.toFixed(2);
			
			slider.addEventListener(Event.CHANGE,
				function(e:Event):void
				{
					label.text = (e.target as Slider).value.toFixed(2);
				}
			);
			
			slider.addEventListener(Event.CHANGE, callback);
		}
		
		private function lightLabelFunction(o:Object):String
		{
			return 'Change properties for light: #' + lights.indexOf(o as PointLight);
		};
		
		private function rendererLightLabelFunction(o:Object):String
		{
			return 'Light #' + lights.indexOf(o as PointLight);
		};
		
		private function lightRendererFactory():IListItemRenderer
		{
			var renderer:DefaultListItemRenderer = new DefaultListItemRenderer();			
			renderer.labelFunction = rendererLightLabelFunction;
			return renderer;
		}
		
		/*-----------------------------
		GUI event callbacks
		-----------------------------*/
		
		private function onSpecularPowerChange(e:Event):void
		{
			deferredShadingProps.specularPower = (e.target as Slider).value;
		}
		
		private function onSpecularIntensityChange(e:Event):void
		{
			deferredShadingProps.specularIntensity = (e.target as Slider).value;
		}
		
		private function onRTCBChange(e:Event):void
		{
			rtContainer.visible = (e.target as Check).isSelected;
		}
		
		private var selectedLight:PointLight;
		
		private function onSelectedLightChange(e:Event = null):void
		{
			selectedLight = picker.selectedItem as PointLight;
			lightRadiusSlider.value = selectedLight.radius;
			lightStrengthSlider.value = selectedLight.strength;
			lightAttenuationSlider.value = selectedLight.attenuation;
		}
		
		private function onLightRadiusChange(e:Event):void
		{
			selectedLight.radius = (e.target as Slider).value;
		}
		
		private function onLightStrengthChange(e:Event):void
		{
			selectedLight.strength = (e.target as Slider).value;
		}
		
		private function onLightAttenuationChange(e:Event):void
		{
			selectedLight.attenuation = (e.target as Slider).value;
		}
		
		private function onAmbientAmountChange(e:Event):void
		{
			ambientLight.strength = (e.target as Slider).value;
		}
	}
}