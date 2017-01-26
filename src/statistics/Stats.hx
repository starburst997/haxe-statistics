package statistics;

#if (!openfl && js)

// JS Fallback to perf.js
class Stats
{
	var stats:Perf;

	public function new()
	{
		stats = new Perf();

    trace("Stats!");
	}
}

#else

/**
 * stats.hx (OpenFL Version)
 * http://github.com/mrdoob/stats.as
 *
 * Released under MIT license:
 * http://www.opensource.org/licenses/mit-license.php
 *
 * How to use:
 *
 *	just call new Stats()
 *
 * Clean that mess one day...
 *
 **/

#if openfl
import openfl.Assets;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.display.Stage;
import openfl.events.Event;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.system.System;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.Lib;

#elseif flash
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.display.Stage;
import flash.events.Event;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.system.System;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.Lib;
#end

typedef DebugInfo = {
	color:Int,
	str:String,
	value:String,
	newLine:Bool
};

typedef ColorInfo = {
	format:TextFormat,
	start:Int,
	end:Int
};

class Stats extends Sprite {

	public static inline var bgColor:Int = 0x000033;
	public static inline var fpsColor:Int = 0xffff00;
	public static inline var msColor:Int = 0x00ff00;
	public static inline var memColor:Int = 0x00ffff;
	public static inline var memmaxColor:Int = 0xff0070;

	static inline var GRAPH_WIDTH : Int = 100;
	static inline var XPOS : Int = 99;//width - 1
	/*#if html5
	static inline var GRAPH_HEIGHT : Int = 30;
	static inline var TEXT_HEIGHT : Int = #if !debug 40 #else 60 #end;
	#else*/
	static inline var GRAPH_HEIGHT : Int = 50;
	static inline var TEXT_HEIGHT : Int = 90; // #if !debug 70 #else 90 #end;
	//#end

	private var text:TextField;

	private var timer : Int;
	private var fps : Int;
	private var ms : Int;
	private var ms_prev : Int;
	private var mem : Float;
	private var mem_max : Float;

	private var bitmap:Bitmap = null;
	private var graph:BitmapData = null;
	private var rectangle:Rectangle = null;

	private var fps_graph : Int;
	private var mem_graph : Int;
	private var ms_graph : Int;
	private var mem_max_graph : Int;
	private var _stage:Stage;

	public var debugInfo:Array<DebugInfo> = [];
	private var colorInfo:Array<ColorInfo> = [];
	private var textString:String = "";

	/**
	 * <b>Stats</b> FPS, MS and MEM, all in one.
	 */
	public function new() {

		super();
    
		mem_max = 0;
		fps = 0;

    #if openfl
    var fontName = font("DejaVuSans.ttf");
    #else
    var fontName = "Arial";
    #end
    
    trace("Stats", fontName);

		var format = new TextFormat( fontName, 10, 0xdbf043 );

		mouseEnabled = false;
		mouseChildren = false;

		text = new TextField();
		text.width = GRAPH_WIDTH;
		text.height = TEXT_HEIGHT;
		text.defaultTextFormat = format;
		text.selectable = false;

		text.embedFonts = fontName != "Arial";

    text.mouseEnabled = false;

		rectangle = new Rectangle(GRAPH_WIDTH - 1, 0, 1, GRAPH_HEIGHT);

		this.addEventListener(Event.ADDED_TO_STAGE, init, false, 0, true);
		this.addEventListener(Event.REMOVED_FROM_STAGE, destroy, false, 0, true);

		Lib.current.stage.addChild(this);
	}

	function font(str:String):String
	{
    #if openfl
		var f = Assets.getFont("assets/fonts/"+str);
		if (f != null)
		{
			trace("Found font:", f.fontName);
      
      var name = f.fontName;
      
      if ( (name != "") && (name != null) )
      {
        return f.fontName;
      }
		}
    #end

		return "Arial";
	}

	private function init( e:Event )
	{
		_stage = flash.Lib.current.stage;
		graphics.beginFill(bgColor, 0.75);
		graphics.drawRect(0, 0, GRAPH_WIDTH, TEXT_HEIGHT);
		graphics.endFill();

		this.addChild(text);

		graph = new BitmapData(GRAPH_WIDTH, GRAPH_HEIGHT, false, bgColor);
		//graph.fillRect( new Rectangle( 0, 0, GRAPH_WIDTH, GRAPH_HEIGHT ), bgColor );
		graph.lock();
		for ( x in 0...GRAPH_WIDTH )
		{
			for ( y in 0...GRAPH_HEIGHT )
			{
				graph.setPixel32( x, y, 0xFF000000 + bgColor );
			}
		}
		graph.unlock();

		bitmap = new Bitmap( graph );
		bitmap.y = TEXT_HEIGHT;
		bitmap.alpha = 0.75;

		this.addChild(bitmap);

		ms_prev = Lib.getTimer();

		//graphics.beginBitmapFill(graph, new Matrix(1, 0, 0, 1, 0, TEXT_HEIGHT));
		//graphics.drawRect(0, TEXT_HEIGHT, GRAPH_WIDTH, GRAPH_HEIGHT);

		trace("Init stats");

		this.addEventListener(Event.ENTER_FRAME, update);
	}

	public function clear()
	{
		destroy( null );

		this.removeEventListener(Event.ADDED_TO_STAGE, init);
		this.removeEventListener(Event.REMOVED_FROM_STAGE, destroy);
	}

	private function destroy( e:Event )
	{
		graphics.clear();

		while(numChildren > 0)
			removeChildAt(0);

		graph.dispose();

		removeEventListener(Event.ENTER_FRAME, update);
	}

	private function update( e:Event )
	{
		timer = Lib.getTimer();

		// After a second has passed
		if ( timer - 1000 > ms_prev )
		{
			var rate = _stage.frameRate;
			if ( rate > 999 ) // Fix for high frameRate hack for iOS
			{
				rate = 60;
			}

			//#if !html5
			mem = System.totalMemory * 0.000000954;
			mem_max = mem_max > mem ? mem_max : mem;
			mem_graph = GRAPH_HEIGHT - normalizeMem(mem);
			mem_max_graph = GRAPH_HEIGHT - normalizeMem(mem_max);
			//#end

			fps_graph = GRAPH_HEIGHT - Std.int( Math.min(GRAPH_HEIGHT, ( fps / rate ) * GRAPH_HEIGHT) );
			ms_graph = Std.int( GRAPH_HEIGHT - ( ( timer - ms ) >> 1 ));

			//trace("Values", fps_graph, ms_graph, mem_graph, mem_max_graph);

			graph.lock();
			//graph.scroll(-1, 0);
			graph.copyPixels( graph, new Rectangle( 1, 0, graph.width - 1, graph.height ), new Point( 0, 0 ) );
			graph.fillRect(rectangle, 0xBF000000 + bgColor);
			/*#if html5
			graph.setPixel(XPOS, fps_graph, fpsColor);
			graph.setPixel(XPOS, ms_graph, msColor);
			#else*/
			graph.setPixel(XPOS, fps_graph, fpsColor);
			graph.setPixel(XPOS, mem_graph, memColor);
			graph.setPixel(XPOS, mem_max_graph, memmaxColor);
			graph.setPixel(XPOS, ms_graph, msColor);
			//#end
			graph.unlock();
			//reset frame and time counters

			text.text = "";
			textString = "";

			// Colors
			/*#if html5
			addColor( text, fpsColor, "FPS", fps + " / " + rate );
			addColor( text, msColor, "MS", Std.string(timer - ms) );
			#else*/
			addColor( text, fpsColor, "FPS", fps + " / " + rate );
			addColor( text, memColor, "MEM", toFixed( mem, 4 ) );
			addColor( text, memmaxColor, "MAX", toFixed( mem_max, 4 ) );
			addColor( text, msColor, "MS", Std.string(timer - ms) );
			//#end

			for ( debug in debugInfo )
			{
				addColor( text, debug.color, debug.str, debug.value, debug.newLine );
			}

			// Add colors to text
			/*for ( format in colorInfo )
			{
				text.setTextFormat( format.format, format.start, format.end );
			}*/

			text.htmlText = textString;

			fps = 0;
			ms_prev = timer;
			//colorInfo = [];

			return;
		}

		// Increment number of frames which have occurred in current second
		fps++;
		ms = timer;

	}

	private function toFixed(n:Float, prec:Int){
	  n = Math.round(n * Math.pow(10, prec));
	  var str = ''+n;
	  var len = str.length;
	  if(len <= prec){
	    while(len < prec){
	      str = '0'+str;
	      len++;
	    }
	    return '0.'+str;
	  }
	  else{
	    return str.substr(0, str.length-prec) + '.'+str.substr(str.length-prec);
	  }
	}

	// Add color text
	private function addColor( text:TextField, color:Int, str:String, value:String, newLine:Bool = true ):Void
	{
		//var format = new TextFormat( "DejaVu Sans", 10, color );
		//format.color = color;

		var start = text.text.length;
		var end = start + str.length;

		textString += "<font color=\"#" + toHex(color) + "\">" + str + "</font>: " + value + (newLine ? "\n" : " ");

		//text.appendText( str + ": " + value + (newLine ? "\n" : " ") );
		//text.text += ( str + ": " + value + (newLine ? "\n" : " ") );

		//colorInfo.push( { format:format, start:start, end:end } );
		//text.setTextFormat( format, start, end );
	}

	static var _hexLUT = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"];
	public static function toHex(x:Int):String
	{
		if (x == 0) return "0";
		var s = "";
		var a = _hexLUT;
		while (x != 0)
		{
			s = a[x & 0xf] + s;
			x >>>= 4;
		}
		return s;
	}

	// Normalize
	private function normalizeMem( _mem:Float ):Int
	{
		return Std.int( Math.min( GRAPH_HEIGHT, Math.sqrt(Math.sqrt(_mem * 5000)) ) - 2);
	}
}

#end