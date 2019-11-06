package com.mmp.air.tools
{
	import com.bit101.components.CheckBox;
	import com.bit101.components.Component;
	import com.bit101.components.HBox;
	import com.bit101.components.InputText;
	import com.bit101.components.Label;
	import com.bit101.components.NumericStepper;
	import com.bit101.components.PushButton;
	import com.bit101.components.Text;
	import com.bit101.components.VBox;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BitmapDataChannel;
	import flash.display.NativeWindow;
	import flash.display.NativeWindowInitOptions;
	import flash.display.NativeWindowSystemChrome;
	import flash.display.NativeWindowType;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	/**
	 * ...
	 * @author Essbe
	 */
	public class Main extends Sprite
	{
		private var _widthValue:InputText;
		private var _heightValue:InputText;
		private var _checkTransparent:CheckBox;
		private var _xFactor:InputText;
		private var _yFactor:InputText;
		private var _octaves:NumericStepper;
		private var _seed:InputText;
		private var _seamless:CheckBox;
		private var _fractal:CheckBox;
		private var _grayscale:CheckBox;
		private var _r:CheckBox;
		private var _g:CheckBox;
		private var _b:CheckBox;
		private var _a:CheckBox;
		private var _channelComps:Array;
		
		private var _perlinWindow:NativeWindow;
		private var _perlinDisplay:PerlinDisplay;
		private var _perlinPending:Boolean = false;
		
		public function Main()
		{
			if (stage)
			{
				init(null);
				return;
			}
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.nativeWindow.addEventListener(Event.CLOSING, onAppClose);
			
			var ui:VBox = new VBox(stage, 10, 10);
			ui.spacing = 10;
			
			var size:HBox = new HBox(ui);
			size.spacing = 0;
			
			var w:VBox = new VBox(size);
			w.spacing = 0;
			var wLabel:Label = new Label(w, 0, 0, "Width");
			wLabel.autoSize = true;
			_widthValue = new InputText(w, 0, 0, "512");
			
			var h:VBox = new VBox(size);
			h.spacing = 0;
			var hLabel:Label = new Label(h, 0, 0, "Height");
			hLabel.autoSize = true;
			_heightValue = new InputText(h, 0, 0, "512");
			
			_widthValue.width = _heightValue.width = 50;
			_widthValue.restrict = _heightValue.restrict = "0123456789";
			
			var factor:HBox = new HBox(ui);
			factor.spacing = 0;
			
			var bx:VBox = new VBox(factor);
			bx.spacing = 0;
			var baseX:Label = new Label(bx, 0, 0, "Base X");
			_xFactor = new InputText(bx, 0, 0, "1");
			
			var by:VBox = new VBox(factor);
			by.spacing = 0;
			var baseY:Label = new Label(by, 0, 0, "Base Y");
			_yFactor = new InputText(by, 0, 0, "1");
			
			_xFactor.width = _yFactor.width = 50;
			_xFactor.restrict = _yFactor.restrict = "0123456789.";
			
			var o:VBox = new VBox(ui);
			o.spacing = 0;
			var oLabel:Label = new Label(o, 0, 0, "Octaves");
			_octaves = new NumericStepper(o);
			_octaves.value = 1;
			_octaves.width = 150;
			
			var s:VBox = new VBox(ui);
			s.spacing = 0;
			var sLabel:Label = new Label(s, 0, 0, "Seed");
			_seed = new InputText(s, 0, 0, Math.floor(Math.random() * 1000).toString());
			_seed.width = 150;
			
			_checkTransparent = new CheckBox(ui, 0, 0, "Transparent");
			
			_seamless = new CheckBox(ui, 0, 0, "Seamless Noise");
			
			_fractal = new CheckBox(ui, 0, 0, "Fractal Noise");
			
			_grayscale = new CheckBox(ui, 0, 0, "Grayscale", onGrayscaleChange);
			
			var channels:VBox = new VBox(ui);
			channels.spacing = 0;
			var cLabel:Label = new Label(channels, 0, 0, "Channels");
			
			var chan:HBox = new HBox(channels);
			_r = new CheckBox(chan, 0, 0, "R");
			_g = new CheckBox(chan, 0, 0, "G");
			_b = new CheckBox(chan, 0, 0, "B");
			_a = new CheckBox(chan, 0, 0, "A");
			
			_channelComps = [cLabel, _r, _g, _b, _a];
			
			var generate:PushButton = new PushButton(ui, 0, 0, "Generate", onGenerate);
			generate.width = 150;
			
			addChild(ui);
			
			_perlinDisplay = new PerlinDisplay();
		}
		
		private function onAppClose(e:Event):void
		{
			stage.nativeWindow.removeEventListener(Event.CLOSING, onAppClose);
			if (_perlinWindow)
			{
				_perlinWindow.close()
			}
		}
		
		private function onGenerate(event:MouseEvent = null):void
		{
			var w:int = parseInt(_widthValue.text);
			var h:int = parseInt(_heightValue.text);
			
			if (_perlinWindow == null)
			{
				
				var opts:NativeWindowInitOptions = new NativeWindowInitOptions();
				opts.systemChrome = NativeWindowSystemChrome.NONE;
				opts.transparent = false;
				opts.type = NativeWindowType.LIGHTWEIGHT;
				opts.owner = stage.nativeWindow;
				
				_perlinWindow = new NativeWindow(opts);
				_perlinWindow.x = stage.nativeWindow.x + stage.nativeWindow.width + 10;
				_perlinWindow.y = stage.nativeWindow.y;
				_perlinWindow.width = w;
				_perlinWindow.height = h;
				_perlinWindow.stage.align = StageAlign.TOP_LEFT;
				_perlinWindow.stage.scaleMode = StageScaleMode.NO_SCALE;
				_perlinWindow.stage.addChild(_perlinDisplay);
				_perlinWindow.addEventListener(Event.CLOSING, onWindowClosing);
				_perlinWindow.addEventListener(Event.CLOSE, onWindowClosed);
				_perlinWindow.activate();
			}else if (_perlinWindow.width != w || _perlinWindow.height != h){
				_perlinPending = true;
				_perlinWindow.stage.removeChild(_perlinDisplay);
				_perlinDisplay = null;
				_perlinDisplay = new PerlinDisplay();
				_perlinWindow.close();
				return;
			}
			
			_perlinDisplay.updateParams(w, h, _checkTransparent.selected, parseFloat(_xFactor.text), parseFloat(_yFactor.text), _octaves.value, parseInt(_seed.text), _seamless.selected, _fractal.selected, _grayscale.selected, _r.selected, _g.selected, _b.selected, _a.selected);
		
		}
		
		private function onWindowClosing(e:Event = null):void
		{
			_perlinWindow.removeEventListener(Event.CLOSING, onWindowClosing);
			_perlinWindow.stage.removeChild(_perlinDisplay);
		}
		
		private function onWindowClosed(e:Event):void
		{
			_perlinWindow.removeEventListener(Event.CLOSE, onWindowClosed);
			_perlinWindow = null;
			if (_perlinPending){
				_perlinPending = false;
				onGenerate();
			}
			
			
		}
		
		private function onGrayscaleChange(event:MouseEvent):void
		{
			for each (var c:Component in _channelComps)
			{
				c.enabled = !_grayscale.selected;
				c.alpha = _grayscale.selected ? .5 : 1;
			}
		}
	
	}

}