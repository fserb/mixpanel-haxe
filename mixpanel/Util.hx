package mixpanel;

import haxe.io.Bytes;
import openfl.errors.Error;

import haxe.crypto.Base64;

import flash.external.ExternalInterface;
import flash.system.System;
import flash.ui.Mouse;
import flash.utils.ByteArray;
import haxe.Json;

class Util {
  @:allow(mixpanel)
  private function new() {
  }

  public function browserProtocol():String {
    var ret:String = "https:";
    if (ExternalInterface.available) {
      try {
        var extProtocol:String = ExternalInterface.call("document.location.protocol.toString");
        ret = ((extProtocol != null && extProtocol.indexOf("file") == -1)) ? extProtocol:ret;
      } catch (err:Error){ };
    }
    return ret;
  }

  public function extend(obj1:Dynamic, args: Dynamic):Dynamic {
    for (param in Reflect.fields(args)){
      Reflect.setField(obj1, param, Reflect.field(args, param));
    }
    return obj1;
  }

  public function truncate(obj:Dynamic, length:Int = 255):Dynamic {
    var ret:Dynamic;
    var className:String = Type.getClassName(obj);
    var len:Int;
    var i:Int;

    if (className == "String") {
      ret = (try cast(obj, String) catch(e:Dynamic) null).substring(0, length);
    }
    else if (className == "Array") {
      ret = [];len = obj.length;
      for (i in 0...len){
        ret.push(truncate(obj[i], length));
      }
    }
    else if (className == "Object") {
      ret = { };
      for (key in Reflect.fields(obj)) {
        Reflect.setField(ret, key, truncate(Reflect.field(obj, key), length));
      }
    }
    else {
      ret = obj;
    }

    return ret;
  }

  // Char codes for 0123456789ABCDEF
  private static var ALPHA_CHAR_CODES:Array<Dynamic> =
    [48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 65, 66, 67, 68, 69, 70];

  // From http://code.google.com/p/actionscript-uuid/
  // MIT License
  public function UUID():String {
    var buff:ByteArray = new ByteArray();
    var r:Int = Std.int(Date.now().getTime());
    buff.writeUnsignedInt(System.totalMemory ^ r);
    buff.writeInt(Math.round(haxe.Timer.stamp() * 1000) ^ r);
    buff.writeDouble(Math.random() * r);

    buff.position = 0;
    var chars:Array<Dynamic> = new Array<Dynamic>();
    for (i in 0...36) {
      chars.push(0);
    }
    var index:Int = 0;
    for (i in 0...16) {
      if (i == 4 || i == 6 || i == 8 || i == 10) {
        chars[index++] = 45;
      }
      var b:Int = buff.readByte();
      chars[index++] = ALPHA_CHAR_CODES[(b & 0xF0) >>> 4];
      chars[index++] = ALPHA_CHAR_CODES[(b & 0x0F)];
    }
    var ret = "";
    for (c in chars) {
      ret += String.fromCharCode(c);
    }
    return ret;
  }
}










