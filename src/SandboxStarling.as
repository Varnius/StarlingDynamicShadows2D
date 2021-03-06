package
{
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

    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.geom.Point;
    import flash.ui.Keyboard;
    import flash.utils.getTimer;

    import starling.core.Starling;
    import starling.display.Canvas;
    import starling.display.Image;
    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.events.Event;
    import starling.events.KeyboardEvent;
    import starling.events.Touch;
    import starling.events.TouchEvent;

    import starling.extensions.rendererPlus.Material;
    import starling.extensions.rendererPlus.debug.DebugImage;
    import starling.extensions.rendererPlus.debug.DebugImageStyle;
    import starling.extensions.rendererPlus.display.RendererPlus;
    import starling.extensions.rendererPlus.interfaces.IAreaLight;
    import starling.extensions.rendererPlus.interfaces.IShadowMappedLight;
    import starling.extensions.rendererPlus.lights.Light;
    import starling.extensions.rendererPlus.lights.PointLight;
    import starling.extensions.rendererPlus.lights.SpotLight;
    import starling.extensions.rendererPlus.lights.rendering.LightStyle;
    import starling.extensions.rendererPlus.lights.rendering.PointLightStyle;
    import starling.extensions.rendererPlus.lights.rendering.SpotLightStyle;
    import starling.textures.Texture;

    public class SandboxStarling extends Sprite
    {
        // Embedded assets

        [Embed(source="assets/floor_diffuse.jpg")]
        public static const FLOOR_DIFFUSE:Class;

        [Embed(source="assets/floor_normal.jpg")]
        public static const FLOOR_NORMAL:Class;

        [Embed(source="assets/face_diffuse.png")]
        public static const FACE_DIFFUSE:Class;

        [Embed(source="assets/face_normal.png")]
        public static const FACE_NORMAL:Class;

        [Embed(source="assets/character-with-si-logo.png")]
        public static const CHAR_DIFF:Class;

        [Embed(source="assets/character-with-si-logo_n.png")]
        public static const CHAR_NORMALS:Class;

        private var controlledLight:Light;
        private var lights:Vector.<Light> = new Vector.<Light>();
        private var lightPositions:Vector.<Point> = new Vector.<Point>();
        private var lightRadiuses:Vector.<Number> = new Vector.<Number>();
        private var lightVelocities:Vector.<Number> = new Vector.<Number>();
        private var lightAngles:Vector.<Number> = new Vector.<Number>();
        private var container:RendererPlus;
        private var material:Material;
        private var occluderMaterial:Material;

        // Occluder

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

        //        private var bloom:Bloom;
        //        private var flares:AnamorphicFlares;

        public function SandboxStarling()
        {
            if(!stage)
                addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
            else
                onAddedToStage();
        }

        private function onAddedToStage(e:Event = null):void
        {
            var image:Image;

            var diffuse:Texture = Texture.fromBitmap(new FLOOR_DIFFUSE() as Bitmap);
            var normal:Texture = Texture.fromBitmap(new FLOOR_NORMAL() as Bitmap);

            material = new Material(diffuse, normal);

            // Add layers

//            bloom = new Bloom();
//            flares = new AnamorphicFlares();
//
//            var pp:PostEffectRenderer = new PostEffectRenderer();
//            bloom.intensity = 2.12;
//            bloom.threshold = 0.19;
//            flares.intensity = 2;
//            flares.threshold = 1.0;
//            pp.effects = new <PostEffect>[bloom, flares];
//            addChild(pp);

            /*pp.*/addChild(container = new RendererPlus());
            container.addChild(image = new Image(material));

            // Add some occluders

            var mat:Material = new Material(Texture.fromEmbeddedAsset(CHAR_DIFF), Texture.fromEmbeddedAsset(CHAR_NORMALS));

            image = new Image(mat);
            container.addChild(image);
            container.addOccluder(image);
            image.x = 700;
            image.y = 300;

            var mask:Canvas = new Canvas();
            mask.drawRectangle(0, 0, 50, 30);

            diffuse = Texture.fromBitmap(new FACE_DIFFUSE() as Bitmap);
            normal = Texture.fromBitmap(new FACE_NORMAL() as Bitmap);

            occluderMaterial = new Material(diffuse, normal);
            refreshOccluderDepth(0);

            container.addChild(image = new Image(occluderMaterial));
            container.addOccluder(image);
            image.x = 200;
            image.y = 150;

            container.addChild(image = new Image(occluderMaterial));
            container.addOccluder(image);
            image.scaleX = image.scaleY = 0.5;
            image.x = 450;
            image.y = 150;

            // Generate some random moving lights and a controllable one

            var light:Light;
            var pls:PointLightStyle;
            var sls:SpotLightStyle;

            for(var i:int = 0; i < 10; i++)
            {
                if(Math.random() < 0.5)
                {
                    light = new SpotLight();

                    sls = light.style as SpotLightStyle;
                    sls.color = Math.random() * 0xFF0000 + Math.random() * 0x00FF00 + Math.random() * 0x0000FF;
                    sls.strength = Math.random() + 1;
                    sls.radius = Math.random() * 300 + 50;
                    sls.angle = Math.PI * Math.random();
                }
                else
                {
                    light = new PointLight();

                    pls = light.style as PointLightStyle;
                    pls.color = Math.random() * 0xFF0000 + Math.random() * 0x00FF00 + Math.random() * 0x0000FF;
                    pls.castsShadows = true;
                    pls.strength = Math.random() + 1;
                    pls.radius = Math.random() * 300 + 50;
                }

                light.x = Math.random() * stage.stageWidth;
                light.y = Math.random() * stage.stageHeight;
                (light.style as IAreaLight).castsShadows = true;

                lightPositions.push(new Point(light.x, light.y));
                lightRadiuses.push(Math.random() * 100 + 50);
                lightVelocities.push(Math.random() * 15 + 30);
                lightAngles.push(0);

                container.addChild(light);
                lights.push(light);
            }

            // Add controllable light

            var p:PointLight = new PointLight();

            pls = p.style as PointLightStyle;
            pls.color = 0xFFFFFF;
            pls.radius = 500;
            pls.attenuation = 1;
            pls.castsShadows = true;
            pls.attenuation = 15.0;
            container.addChild(p);
            lights.push(p);

            controlledLight = p;

            stage.addEventListener(TouchEvent.TOUCH, onTouch);
            stage.addEventListener(Event.ENTER_FRAME, onTick);

            // RT debug

            addChild(rtContainer = new Sprite());
            rtContainer.addChild(debugRT1 = new DebugImage(container.diffuseRT));
            debugRT1.width = 220;
            debugRT1.height = 130;
            rtContainer.addChild(debugRT2 = new DebugImage(container.normalsRT));
            debugRT2.width = 220;
            debugRT2.height = 130;
            rtContainer.addChild(debugRT3 = new DebugImage(container.occludersRT));
            debugRT3.width = 220;
            debugRT3.height = 130;
            (debugRT3.style as DebugImageStyle).showChannel = 0;
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

                lights[i].rotation += 0.01;
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

            var l:Light = controlledLight as Light;

            tmp.setTo(touch.globalX, touch.globalY);
            l.parent.globalToLocal(tmp, tmp);

            l.x = tmp.x;
            l.y = tmp.y;
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
            new MetalWorksMobileTheme(); // !!!

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
            layout.gap = 15;
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

            cb = new Check();
            cb.label = 'Show intermediate RTs';
            cb.isSelected = false;
            cb.addEventListener(Event.CHANGE, onRTCBChange);
            GUIContainer.addChild(cb);

            // Shadow visibility

            cb = new Check();
            cb.label = 'Enable shadows';
            cb.isSelected = true;
            cb.addEventListener(Event.CHANGE, onShadowsCBChange);
            GUIContainer.addChild(cb);

            // Specular power

            group = new LayoutGroup();
            group.layout = hLayout;
            group.addChild(getLabel('Material specular power:'));
            group.addChild(label = getLabel());
            GUIContainer.addChild(group);
            GUIContainer.addChild(slider = getSlider(0, 200, Material.DEFAULT_SPECULAR_POWER));
            bindSlider(label, slider, onSpecularPowerChange);

            // Specular intensity

            group = new LayoutGroup();
            group.layout = hLayout;
            group.addChild(getLabel('Material specular intensity:'));
            group.addChild(label = getLabel());
            GUIContainer.addChild(group);
            GUIContainer.addChild(slider = getSlider(0, 5, Material.DEFAULT_SPECULAR_INTENSITY));
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
            //            cb.isSelected = bloom.enabled;
            cb.addEventListener(Event.CHANGE, onBloomCBChange);

            // Bloom intensity

            group = new LayoutGroup();
            group.layout = hLayout;
            group.addChild(getLabel('Intensity:'));
            group.addChild(label = getLabel());
            effectGUIContainer.addChild(group);
            effectGUIContainer.addChild(slider = getSlider(0, 7, 1));
            //            bloom.intensity = 1;
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
            //            cb.isSelected = flares.enabled;
            cb.addEventListener(Event.CHANGE, onFlaresCBChange);

            group = new LayoutGroup();
            group.layout = hLayout;
            group.addChild(getLabel('Threshold:'));
            group.addChild(label = getLabel());
            effectGUIContainer.addChild(group);
            effectGUIContainer.addChild(slider = getSlider(0, 1, 0.5));
            //            flares.threshold = 0.5;
            bindSlider(label, slider, onFlaresThresholdChange);

            group = new LayoutGroup();
            group.layout = hLayout;
            group.addChild(getLabel('Intensity:'));
            group.addChild(label = getLabel());
            effectGUIContainer.addChild(group);
            effectGUIContainer.addChild(slider = getSlider(0, 7, 6));
            //            flares.intensity = 6;
            bindSlider(label, slider, onFlaresIntensityChange);
        }

        /*-----------------------------
         Helpers
         -----------------------------*/

        private function refreshOccluderDepth(depth:Number):void
        {
            if(occluderMaterial.depth)
            {
                occluderMaterial.depth.dispose();
            }

            if(occluderDepthBD)
            {
                occluderDepthBD.dispose();
            }

            occluderDepthBD = new BitmapData(16, 16, false, 0xFF000000 + 0xFFFFFF * depth);
            var depthMap:Texture = Texture.fromBitmapData(occluderDepthBD);
            occluderMaterial.depth = depthMap;
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
                    function (e:Event):void
                    {
                        label.text = (e.target as Slider).value.toFixed(2);
                    }
            );

            slider.addEventListener(Event.CHANGE, callback);
        }

        private function lightLabelFunction(o:Object):String
        {
            return 'Change properties for light: #' + lights.indexOf(o as Light);
        };

        private function rendererLightLabelFunction(o:Object):String
        {
            return 'Light #' + lights.indexOf(o as Light);
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
            material.specularPower = (e.target as Slider).value;
        }

        private function onSpecularIntensityChange(e:Event):void
        {
            material.specularIntensity = (e.target as Slider).value;
        }

        private function onRTCBChange(e:Event):void
        {
            rtContainer.visible = (e.target as Check).isSelected;
        }

        private function onShadowsCBChange(e:Event):void
        {
            var checked:Boolean = (e.target as Check).isSelected;

            for each(var l:Light in lights)
            {
                if(l is IShadowMappedLight) (l as IShadowMappedLight).castsShadows = checked;
            }

            //            debugRT3.mTexture = checked ? (controlledLight as IShadowMappedLight).shadowMap : null;
        }

        private var selectedLightStyle:IAreaLight;

        private function onSelectedLightChange(e:Event = null):void
        {
            selectedLightStyle = picker.selectedItem.style as IAreaLight;
            lightRadiusSlider.value = selectedLightStyle.radius;
            lightStrengthSlider.value = (selectedLightStyle as LightStyle).strength;
            lightAttenuationSlider.value = selectedLightStyle.attenuation;
        }

        private function onLightRadiusChange(e:Event):void
        {
            selectedLightStyle.radius = (e.target as Slider).value;
        }

        private function onLightStrengthChange(e:Event):void
        {
            (selectedLightStyle as LightStyle).strength = (e.target as Slider).value;
        }

        private function onLightAttenuationChange(e:Event):void
        {
            selectedLightStyle.attenuation = (e.target as Slider).value;
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
            //            bloom.intensity = (e.target as Slider).value;
        }

        private function onBloomBlurXChange(e:Event):void
        {
            //            bloom.blurX = (e.target as Slider).value;
        }

        private function onBloomBlurYChange(e:Event):void
        {
            //            bloom.blurY = (e.target as Slider).value;
        }

        private function onBloomThresholdChange(e:Event):void
        {
            //            bloom.threshold = (e.target as Slider).value;
        }

        private function onFlaresThresholdChange(e:Event):void
        {
            //            flares.threshold = (e.target as Slider).value;
        }

        private function onFlaresIntensityChange(e:Event):void
        {
            //            flares.intensity = (e.target as Slider).value;
        }

        private function onBloomCBChange(e:Event):void
        {
            //            bloom.enabled = (e.target as Check).isSelected;
        }

        private function onFlaresCBChange(e:Event):void
        {
            //            flares.enabled = (e.target as Check).isSelected;
        }
    }
}