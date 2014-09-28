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
	import starling.extensions.deferredShading.MaterialProperties;
	import starling.extensions.deferredShading.debug.DebugImage;
	import starling.extensions.deferredShading.display.DeferredShadingContainer;
	import starling.extensions.deferredShading.lights.PointLight;
	import starling.extensions.post.PostEffectRenderer;
	import starling.extensions.post.effects.AnamorphicFlares;
	import starling.extensions.post.effects.Bloom;
	import starling.extensions.post.effects.PostEffect;
	import starling.textures.Texture;
	
	public class SandboxStarling extends Sprite
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
		
		// GUI
		
		private var picker:PickerList;
		private var lightRadiusSlider:Slider;
		private var lightAttenuationSlider:Slider;
		private var lightStrengthSlider:Slider;
		private var GUIContainer:ScrollContainer;
		private var effectGUIContainer:ScrollContainer;
		private var paused:Boolean = false;
		
		// Effects
		
		private var bloom:Bloom;
		private var flares:AnamorphicFlares;
		
		public function SandboxStarling()
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
			
			var diffuse:Texture = Texture.fromBitmap(new FLOOR_DIFFUSE() as Bitmap);
			var normal:Texture = Texture.fromBitmap(new FLOOR_NORMAL() as Bitmap);
			
			deferredShadingProps = new MaterialProperties(normal);
			diffuse.materialProperties = deferredShadingProps;		
			
			// Add layers
			
			bloom = new Bloom();	
			flares = new AnamorphicFlares();			
			
			var pp:PostEffectRenderer = new PostEffectRenderer();
			bloom.intensity = 2.12;
			bloom.threshold = 0.19;
			flares.intensity = 2;
			flares.threshold = 1.0;
			pp.effects = new <PostEffect>[bloom, flares];
			addChild(pp);
			
			pp.addChild(container = new DeferredShadingContainer());		
			container.addChild(image = new Image(diffuse));
			
			// Add some occluders
			
			diffuse = Texture.fromBitmap(new FACE_DIFFUSE() as Bitmap);
			normal = Texture.fromBitmap(new FACE_NORMAL() as Bitmap);
			
			occluderMatProps = new MaterialProperties(normal);			
			diffuse.materialProperties = occluderMatProps;	
			refreshOccluderDepth(0);
			
			container.addChild(image = new Image(diffuse));
			container.addOccluder(image);
			image.x = 200;
			image.y = 150;
			
			container.addChild(image = new Image(diffuse));
			container.addOccluder(image);
			image.scaleX = image.scaleY = 0.5;
			image.x = 700;
			image.y = 300;
			
			// Generate some random moving lights and a controllable one
			
			var pointLight:PointLight;
			
			for(var i:int = 0; i < 10; i++)
			{
				pointLight = new PointLight(
					Math.random() * 0xFF0000 + Math.random() * 0x00FF00 + Math.random() * 0x0000FF,
					Math.random() + 1,
					Math.random() * 300 + 50
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
			
			// Add controllable light
			
			controlledLight = new PointLight(0xFFFFFF, 1.0, 500);
			controlledLight.castsShadows = true;
			container.addChild(controlledLight);
			container.addLight(controlledLight);
			controlledLight.x = 0;
			controlledLight.y = 200;
			controlledLight.attenuation = 15.0;
			lights.push(controlledLight);
			
			stage.addEventListener(TouchEvent.TOUCH, onTouch);
			stage.addEventListener(Event.ENTER_FRAME, onTick);
			
			// RT debug
			
			addChild(rtContainer = new Sprite());
			rtContainer.addChild(debugRT1 = new DebugImage(container.diffuseRT, 220, 130));
			rtContainer.addChild(debugRT2 = new DebugImage(container.normalsRT, 220, 130));
			rtContainer.addChild(debugRT3 = new DebugImage(controlledLight.shadowMap, 220, 130));
			debugRT3.showChannel = 0;
			rtContainer.visible = false;
			debugRT1.x = debugRT2.x = debugRT3.x = stage.stageWidth - 220;
			debugRT2.y = 130;			
			debugRT3.y = 260;
			
			// GUI
			
			initGUI();
			initEffectGUI();
			stage.addEventListener(KeyboardEvent.KEY_UP, handleGUIVisibility);
			effectGUIContainer.visible = false;
			GUIContainer.visible = false;
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
		
		private var tmp:Point = new Point();
		
		private function onTouch(e:TouchEvent):void
		{
			var touch:Touch = e.getTouch(this);
			
			if(!touch)
			{
				return;
			}
			
			tmp.setTo(touch.globalX, touch.globalY);
			controlledLight.parent.globalToLocal(tmp, tmp);
			
			controlledLight.x = tmp.x;
			controlledLight.y = tmp.y;
		}
		
		private function handleGUIVisibility(e:KeyboardEvent):void
		{
			if(e.keyCode == Keyboard.Q)
			{
				GUIContainer.visible = !GUIContainer.visible;
			}
			else if(e.keyCode == Keyboard.W)
			{
				effectGUIContainer.visible = !effectGUIContainer.visible;
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
			new MetalWorksMobileTheme(false);
			
			var slider:Slider;
			var label:Label;
			
			// Info text
			
			addChild(label = getLabel("Settings: 'Q' - Lights and materials, 'W' - PostFX"));
			label.x = 60; 
			label.y = 4;
			
			// Container
			
			GUIContainer = new ScrollContainer();
			GUIContainer.horizontalScrollPolicy = ScrollContainer.SCROLL_POLICY_OFF;
			GUIContainer.scrollBarDisplayMode = ScrollContainer.SCROLL_BAR_DISPLAY_MODE_FIXED;
			GUIContainer.visible = true;
			
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
			cb.isSelected = false;
			cb.addEventListener(Event.CHANGE, onRTCBChange);
			group.addChild(cb);
			GUIContainer.addChild(group);
			
			// Specular power
			
			group = new LayoutGroup();
			group.layout = hLayout;
			group.addChild(getLabel('Material specular power:'));	
			group.addChild(label = getLabel());
			GUIContainer.addChild(group);
			GUIContainer.addChild(slider = getSlider(0, 200, MaterialProperties.DEFAULT_SPECULAR_POWER));
			bindSlider(label, slider, onSpecularPowerChange);
			
			// Specular intensity
			
			group = new LayoutGroup();
			group.layout = hLayout;
			group.addChild(getLabel('Material specular intensity:'));	
			group.addChild(label = getLabel());
			GUIContainer.addChild(group);
			GUIContainer.addChild(slider = getSlider(0, 5, MaterialProperties.DEFAULT_SPECULAR_INTENSITY));
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
			
			// Occluder depth
			group = new LayoutGroup();
			group.layout = hLayout;
			group.addChild(getLabel('Occluder depth:'));	
			group.addChild(label = getLabel());
			GUIContainer.addChild(group);
			GUIContainer.addChild(slider = getSlider(0, 1.0, 0));
			bindSlider(label, slider, onOccluderDepthChange);
			
			onSelectedLightChange();
		}
		
		private function initEffectGUI():void
		{
			var slider:Slider;
			var label:Label;
			
			// Container
			
			effectGUIContainer = new ScrollContainer();
			effectGUIContainer.horizontalScrollPolicy = ScrollContainer.SCROLL_POLICY_OFF;
			effectGUIContainer.scrollBarDisplayMode = ScrollContainer.SCROLL_BAR_DISPLAY_MODE_FIXED;
			
			var layout:VerticalLayout = new VerticalLayout();
			var group:LayoutGroup;
			var hLayout:HorizontalLayout = new HorizontalLayout();
			var cb:Check;
			
			hLayout.gap = 10;
			layout.gap = 10;
			layout.padding = 10;
			effectGUIContainer.layout = layout;
			effectGUIContainer.width = 410;			
			effectGUIContainer.height = 300;
			effectGUIContainer.x = 425;
			effectGUIContainer.y = stage.stageHeight - GUIContainer.height;
			
			var quad:Quad = new Quad(effectGUIContainer.width, effectGUIContainer.height, 0x000000);
			quad.alpha = 0.85;
			
			effectGUIContainer.backgroundSkin = quad;
			addChild(effectGUIContainer);	
			
			label = new Label();
			label.text = 'Bloom settings:';
			effectGUIContainer.addChild(label);
			
			effectGUIContainer.addChild(cb = new Check());
			cb.label = 'Enable bloom';
			cb.isSelected = bloom.enabled;
			cb.addEventListener(Event.CHANGE, onBloomCBChange);
			
			// Bloom intensity
			
			group = new LayoutGroup();
			group.layout = hLayout;
			group.addChild(getLabel('Intensity:'));	
			group.addChild(label = getLabel());
			effectGUIContainer.addChild(group);
			effectGUIContainer.addChild(slider = getSlider(0, 7, 1));
			bloom.intensity = 1	;
			bindSlider(label, slider, onBloomIntensityChange);
			
			// Threshold
			
			group = new LayoutGroup();
			group.layout = hLayout;
			group.addChild(getLabel('Bloom threshold:'));	
			group.addChild(label = getLabel());
			effectGUIContainer.addChild(group);
			effectGUIContainer.addChild(slider = getSlider(0, 1, 0.15));
			bindSlider(label, slider, onBloomThresholdChange);
			
			// BlurX
			
			group = new LayoutGroup();
			group.layout = hLayout;
			group.addChild(getLabel('BlurX:'));	
			group.addChild(label = getLabel());
			effectGUIContainer.addChild(group);
			effectGUIContainer.addChild(slider = getSlider(0, 5, 1.5));
			bindSlider(label, slider, onBloomBlurXChange);	
			
			// BlurY
			
			group = new LayoutGroup();
			group.layout = hLayout;
			group.addChild(getLabel('BlurY:'));	
			group.addChild(label = getLabel());
			effectGUIContainer.addChild(group);
			effectGUIContainer.addChild(slider = getSlider(0, 5, 1.5));
			bindSlider(label, slider, onBloomBlurYChange);
			
			// Flares
			
			label = new Label();
			label.text = 'Flares settings:';
			effectGUIContainer.addChild(label);
			
			effectGUIContainer.addChild(cb = new Check());
			cb.label = 'Enable flares';
			cb.isSelected = flares.enabled;
			cb.addEventListener(Event.CHANGE, onFlaresCBChange);
			
			group = new LayoutGroup();
			group.layout = hLayout;
			group.addChild(getLabel('Threshold:'));	
			group.addChild(label = getLabel());
			effectGUIContainer.addChild(group);
			effectGUIContainer.addChild(slider = getSlider(0, 1, 0.5));
			flares.threshold = 0.5;
			bindSlider(label, slider, onFlaresThresholdChange);
			
			group = new LayoutGroup();
			group.layout = hLayout;
			group.addChild(getLabel('Intensity:'));	
			group.addChild(label = getLabel());
			effectGUIContainer.addChild(group);
			effectGUIContainer.addChild(slider = getSlider(0, 7, 6));
			flares.intensity = 6;
			bindSlider(label, slider, onFlaresIntensityChange);
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
		
		private function onOccluderDepthChange(e:Event):void
		{
			refreshOccluderDepth((e.target as Slider).value);
		}
		
		/*-----------------------------
		Effect GUI event callbacks
		-----------------------------*/
		
		private function onBloomIntensityChange(e:Event):void
		{
			bloom.intensity = (e.target as Slider).value;
		}	
		
		private function onBloomBlurXChange(e:Event):void
		{
			bloom.blurX = (e.target as Slider).value;
		}
		
		private function onBloomBlurYChange(e:Event):void
		{
			bloom.blurY = (e.target as Slider).value;
		}
		
		private function onBloomThresholdChange(e:Event):void
		{
			bloom.threshold = (e.target as Slider).value;
		}
		
		private function onFlaresThresholdChange(e:Event):void
		{
			flares.threshold = (e.target as Slider).value;
		}
		
		private function onFlaresIntensityChange(e:Event):void
		{
			flares.intensity = (e.target as Slider).value;
		}
		
		private function onBloomCBChange(e:Event):void
		{
			bloom.enabled = (e.target as Check).isSelected;
		}
		
		private function onFlaresCBChange(e:Event):void
		{
			flares.enabled = (e.target as Check).isSelected;
		}
	}
}