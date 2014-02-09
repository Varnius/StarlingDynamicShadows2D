package
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.ui.Keyboard;
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
	
	import starling.core.Starling;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.KeyboardEvent;
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
		
		// Occluder
		
		private var occluderMatProps:MaterialProperties;
		private var occluderDepthMap:BitmapData;
		private var occluderDepthBD:BitmapData;
		
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
		private var GUIContainer:ScrollContainer;
		private var paused:Boolean = false;
		
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
			
			// Add some occluders
			
			diffuse = Texture.fromBitmap(new FACE_DIFFUSE() as Bitmap);
			normal = Texture.fromBitmap(new FACE_NORMAL() as Bitmap);
					
			occluderMatProps = new MaterialProperties(normal);			
			diffuse.materialProperties = occluderMatProps;	
			refreshOccluderDepth(0.5);
			
			container.addChild(image = new Image(diffuse));
			container.addOccluder(image);
			image.x = 300;
			image.y = 150;
			image.scaleX = image.scaleY = 0.2;
			
			container.addChild(image = new Image(diffuse));
			container.addOccluder(image);
			image.x = 450;
			image.y = 250;
			image.scaleX = image.scaleY = 0.3;
			
			container.addChild(image = new Image(diffuse));
			container.addOccluder(image);
			image.x = 600;
			image.y = 400;
			image.scaleX = image.scaleY = 0.5;
			
			container.addChild(image = new Image(diffuse));
			container.addOccluder(image);
			image.x = 800;
			image.y = 50;
			image.scaleX = image.scaleY = 0.3;
			
			var qq:Quad;
			
			container.addChild(qq = new Quad(200, 1, 0xFFF000));
			container.addOccluder(qq);
			qq.x = 350;
			qq.y = 50;
			
			// Generate some random moving lights and a controllable one
			
			var pointLight:PointLight;
			
			for(var i:int = 0; i < 10; i++)
			{
				pointLight = new PointLight(
					Math.random() * 0xFF0000 + Math.random() * 0x00FF00 + Math.random() * 0x0000FF,
					Math.random() + 1,
					Math.random() * 200 + 50
				);
				
				pointLight.x = Math.random() * stage.stageWidth;
				pointLight.y = Math.random() * stage.stageHeight;
				pointLight.castsShadows = true;
				
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
			
			// Add controllable light
			
			controlledLight = new PointLight(0xFFFFFF, 1.0, 200);
			controlledLight.castsShadows = true;
			container.addChild(controlledLight);
			container.addLight(controlledLight);
			controlledLight.x = 0;
			controlledLight.y = 200;
			controlledLight.attenuation = 15.0
			lights.push(controlledLight);
			
			stage.addEventListener(TouchEvent.TOUCH, onTouch);
			stage.addEventListener(Event.ENTER_FRAME, onTick);
			
			// RT debug
			
			addChild(rtContainer = new Sprite());
			rtContainer.addChild(debugRT1 = new DebugImage(container.diffuseRT, 220, 130));
			rtContainer.addChild(debugRT2 = new DebugImage(container.occludersRT, 220, 130));
			rtContainer.addChild(debugRT3 = new DebugImage(controlledLight.shadowMap, 220, 130));
			debugRT3.showChannel = 0;
			rtContainer.addChild(debugRT4 = new DebugImage(container.lightPassRT, 220, 130));
			debugRT1.x = debugRT2.x = debugRT3.x = debugRT4.x = stage.stageWidth - 220;
			debugRT2.y = 130;			
			debugRT3.y = 260;
			debugRT4.y = 390;
			
			// GUI
			
			initGUI();
			stage.addEventListener(KeyboardEvent.KEY_UP, handleGUIVisibility);
		}
		
		/*-----------------------------
		Event handlers
		-----------------------------*/
		
		private var earlier:uint;
		
		private function onTick(e:Event):void
		{
			var now:uint = getTimer();
			var delta:Number = (now - earlier) / 1000;			
			earlier = now;
			
			if(paused)
			{
				return;
			}		
			
			var radians:Number;
			
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
		
		private function handleGUIVisibility(e:KeyboardEvent):void
		{
			if(e.keyCode == Keyboard.TAB)
			{
				GUIContainer.visible = !GUIContainer.visible;
			}
			else if(e.keyCode == Keyboard.P)
			{
				paused = !paused;
			}
			else if(e.keyCode == Keyboard.O)
			{
				Starling.current.showStats = !Starling.current.showStats; 
			}
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
			
			GUIContainer = new ScrollContainer();
			GUIContainer.horizontalScrollPolicy = ScrollContainer.SCROLL_POLICY_OFF;
			GUIContainer.scrollBarDisplayMode = ScrollContainer.SCROLL_BAR_DISPLAY_MODE_FIXED;
			var layout:VerticalLayout = new VerticalLayout();
			var group:LayoutGroup;
			var hLayout:HorizontalLayout = new HorizontalLayout();
			var cb:Check;
			
			hLayout.gap = 10;
			layout.gap = 10;
			layout.padding = 10;
			GUIContainer.layout = layout;
			GUIContainer.width = 410;
			GUIContainer.height = 300;
			GUIContainer.y = stage.stageHeight - GUIContainer.height;
			
			var quad:Quad = new Quad(GUIContainer.width, GUIContainer.height, 0x000000);
			quad.alpha = 0.85;
			
			GUIContainer.backgroundSkin = quad;
			addChild(GUIContainer);		
			
			// Map visibility
			
			group = new LayoutGroup();
			group.layout = hLayout;
			hLayout.verticalAlign = HorizontalLayout.VERTICAL_ALIGN_MIDDLE;
			cb = new Check();
			cb.label = 'Show intermediate RTs';
			cb.isSelected = true;
			cb.addEventListener(Event.CHANGE, onRTCBChange);
			group.addChild(cb);
			GUIContainer.addChild(group);
			
			// Specular power
			
			group = new LayoutGroup();
			group.layout = hLayout;
			group.addChild(getLabel('Material specular power:'));	
			group.addChild(label = getLabel());
			GUIContainer.addChild(group);
			GUIContainer.addChild(slider = getSlider(0, 200, 15));
			bindSlider(label, slider, onSpecularPowerChange);
			
			// Specular intensity
			
			group = new LayoutGroup();
			group.layout = hLayout;
			group.addChild(getLabel('Material specular intensity:'));	
			group.addChild(label = getLabel());
			GUIContainer.addChild(group);
			GUIContainer.addChild(slider = getSlider(0, 5, 1));
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
			GUIContainer.addChild(picker);
			
			// Light radius
			
			group = new LayoutGroup();
			group.layout = hLayout;
			group.addChild(getLabel('Selected light radius:'));	
			group.addChild(label = getLabel());
			GUIContainer.addChild(group);
			GUIContainer.addChild(lightRadiusSlider = getSlider(0, 500, 15));
			bindSlider(label, lightRadiusSlider, onLightRadiusChange);
			
			// Light strength
			
			group = new LayoutGroup();
			group.layout = hLayout;
			group.addChild(getLabel('Selected light strength:'));	
			group.addChild(label = getLabel());
			GUIContainer.addChild(group);
			GUIContainer.addChild(lightStrengthSlider = getSlider(0, 50, 5));
			bindSlider(label, lightStrengthSlider, onLightStrengthChange);
			
			// Light strength
			
			group = new LayoutGroup();
			group.layout = hLayout;
			group.addChild(getLabel('Selected light attenuation:'));	
			group.addChild(label = getLabel());
			GUIContainer.addChild(group);
			GUIContainer.addChild(lightAttenuationSlider = getSlider(0, 50, 5));
			bindSlider(label, lightAttenuationSlider, onLightAttenuationChange);
			
			// Set control defaults
			onSelectedLightChange();
			
			// Ambient light amount
			
			group = new LayoutGroup();
			group.layout = hLayout;
			group.addChild(getLabel('Ambient light amount:'));	
			group.addChild(label = getLabel());
			GUIContainer.addChild(group);
			GUIContainer.addChild(slider = getSlider(0, 1.0, ambientLight.strength));
			bindSlider(label, slider, onAmbientAmountChange);
			
			// Occluder depth
			group = new LayoutGroup();
			group.layout = hLayout;
			group.addChild(getLabel('Occluder depth:'));	
			group.addChild(label = getLabel());
			GUIContainer.addChild(group);
			GUIContainer.addChild(slider = getSlider(0, 1.0, 0.5));
			bindSlider(label, slider, onOccluderDepthChange);
			
			onSelectedLightChange();
		}
		
		/*-----------------------------
		Helpers
		-----------------------------*/
		
		private function refreshOccluderDepth(depth:Number):void
		{
			if(occluderMatProps.depthMap)
			{
				occluderMatProps.depthMap.dispose();
			}
			
			if(occluderDepthBD)
			{
				occluderDepthBD.dispose();
			}
			
			occluderDepthBD = new BitmapData(16, 16, false, 0xFF000000 + 0xFFFFFF * depth);			
			var depthMap:Texture = Texture.fromBitmapData(occluderDepthBD);	
			occluderMatProps.depthMap = depthMap;
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
		
		private function onOccluderDepthChange(e:Event):void
		{
			refreshOccluderDepth((e.target as Slider).value);
		}
	}
}