package com.mmp.air.tools
{
	import com.adobe.images.PNGEncoder;
	import com.bit101.components.HBox;
	import com.bit101.components.PushButton;
	import flash.desktop.Clipboard;
	import flash.desktop.ClipboardFormats;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BitmapDataChannel;
	import flash.display.PNGEncoderOptions;
	import flash.display.PixelSnapping;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	
	/**
	 * ...
	 * @author Essbe
	 */
	public class PerlinDisplay extends Sprite
	{
		private var _bd:BitmapData;
		private var _bm:Bitmap;
		
		private var _transparent:Boolean;
		private var _baseX:Number;
		private var _baseY:Number;
		private var _octaves:int;
		private var _seed:int;
		private var _stitch:Boolean;
		private var _fractal:Boolean;
		private var _grayscale:Boolean;
		private var _channels:int;
		private var _w:int;
		private var _h:int;
		
		private var _perlinHolder:Sprite;
		private var _uiHolder:Sprite;
		private var _saveFile:File;
		
		public function PerlinDisplay()
		{
			super();
			if (stage)
			{
				init(null);
				return;
			}
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event):void
		{
			trace("perlin display init");
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			stage.addEventListener(MouseEvent.RIGHT_CLICK, closeTrigger);
			stage.addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
			stage.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
			
			if (!_perlinHolder)
			{
				_perlinHolder = Sprite(addChild(new Sprite()));
				_perlinHolder.mouseChildren = false;
				_perlinHolder.mouseEnabled = false;
			}
			
			if (!_uiHolder)
			{
				_uiHolder = Sprite(addChild(new Sprite()));
				
				var buttonContainer:HBox = new HBox(_uiHolder,10,10);
				var button:PushButton = new PushButton(buttonContainer, 0, 0, "Save", onSave);
				button.width = 50;
				button = new PushButton(buttonContainer, 0, 0, "Copy", onCopy);
				button.width = 50
				
				var close:PushButton = new PushButton(_uiHolder, 0, 10, "Close", closeTrigger);
				close.width = 50;
				close.x = stage.stageWidth - close.width - 10;
			}
			
			drawPerlin();
		}
		
		
		private function onMouseOut(e:MouseEvent):void 
		{
			if (_uiHolder){
				_uiHolder.visible = false;
			}
		}
		
		private function onMouseOver(e:MouseEvent):void 
		{
			if (_uiHolder){
				_uiHolder.visible = true;
			}
		}
		
		private function onCopy(event:MouseEvent):void 
		{	
			var clipboard:Clipboard = Clipboard.generalClipboard;
			clipboard.clear();
			clipboard.setData(ClipboardFormats.BITMAP_FORMAT, _bd);
		}
		
		private function onSave(event:MouseEvent):void 
		{
			_saveFile = new File();
			_saveFile.addEventListener(Event.SELECT, onSaveLocationSelected);
			_saveFile.addEventListener(Event.CANCEL, onSaveCancel);
			_saveFile.browseForSave("Save to...");
		}
		
		private function onSaveCancel(e:Event):void 
		{
			_saveFile.removeEventListener(Event.SELECT, onSaveLocationSelected);
			_saveFile.removeEventListener(Event.CANCEL, onSaveCancel);
		}
		
		private function onSaveLocationSelected(e:Event):void 
		{
			_saveFile.removeEventListener(Event.SELECT, onSaveLocationSelected);
			if (_saveFile.extension == null || _saveFile.extension != "png"){
				_saveFile = new File(_saveFile.nativePath +".png");
			}
			
			var imgBytes:ByteArray = PNGEncoder.encode(_bd);
			
			var stream:FileStream = new FileStream();
			stream.open(_saveFile, FileMode.WRITE);
			stream.writeBytes(imgBytes);
			stream.close();
			
		}
		
		private function closeTrigger(e:MouseEvent):void
		{
			stage.removeEventListener(MouseEvent.DOUBLE_CLICK, closeTrigger);
			stage.removeEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
			stage.removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
			addEventListener(Event.ADDED_TO_STAGE, init);
			stage.nativeWindow.close();
		}
		
		private function invalidate():void
		{
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		private function onEnterFrame(e:Event):void
		{
			removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			drawPerlin();
		}
		
		private function drawPerlin():void
		{
			if (_bd == null)
			{
				return;
			}
			
			_bd.perlinNoise(_bd.width * _baseX, _bd.height * _baseY, _octaves, _seed, _stitch, _fractal, _channels, _grayscale);
		}
		
		public function updateParams(w:int, h:int, transparent:Boolean = false, baseX:Number = 1, baseY:Number = 1, octaves:int = 1, seed:int = 0, stitch:Boolean = true, fractal:Boolean = false, grayscale:Boolean = false, r:Boolean = false, g:Boolean = false, b:Boolean = false, a:Boolean = false):void
		{
			var inv:Boolean = false;
			
			if (grayscale != _grayscale)
			{
				_grayscale = grayscale;
				inv = true;
			}
			
			if (fractal != _fractal)
			{
				_fractal = fractal;
				inv = true;
			}
			
			if (stitch != _stitch)
			{
				_stitch = stitch;
				inv = true;
			}
			
			if (seed == 0)
			{
				seed = Math.floor(Math.random() * 1000);
			}
			if (seed != _seed)
			{
				_seed = seed;
				inv = true;
			}
			
			if (octaves != _octaves)
			{
				_octaves = octaves;
				inv = true;
			}
			
			if (baseX != _baseX)
			{
				_baseX = 1 / baseX;
				inv = true;
			}
			
			if (baseY != _baseY)
			{
				
				_baseY = 1 / baseY;
				inv = true;
			}
			
			if (transparent != _transparent)
			{
				_transparent = transparent;
				inv = true;
			}
			
			var channels:int = 0;
			if (r)
			{
				channels |= BitmapDataChannel.RED;
			}
			if (g)
			{
				channels |= BitmapDataChannel.GREEN;
			}
			if (b)
			{
				channels |= BitmapDataChannel.BLUE;
			}
			if (a)
			{
				channels |= BitmapDataChannel.ALPHA;
			}
			
			if (channels == 0)
			{
				channels = 7;
			}
			if (channels != _channels)
			{
				_channels = channels;
				inv = true;
			}
			
			if (!_bd || _bd.width != w || _bd.height != h)
			{
				_w = w;
				_h = h;
				createBitmapdata();
				inv = true;
			}
			
			if (inv)
			{
				invalidate();
			}
		}
		
		private function createBitmapdata():void
		{
			if (_bd)
			{
				_perlinHolder.removeChild(_bm);
				_bm = null;
				
				_bd.dispose();
				_bd = null;
			}
			_bd = new BitmapData(_w, _h, _transparent, _transparent ? 0xffffffff : 0xffffff);
			_bm = new Bitmap(_bd, PixelSnapping.AUTO, true);
			_perlinHolder.addChild(_bm);
		}
	
	}

}