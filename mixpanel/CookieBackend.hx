package mixpanel;

import mixpanel.IStorageBackend;
import mixpanel.Util;
import openfl.errors.SecurityError;

import flash.external.ExternalInterface;

class CookieBackend implements IStorageBackend
{
    public var data(get, never) : Dynamic;

    private static var inserted_js : Bool = false;

    private static inline var getCookie : String = "mp_get_cookie";
    private static var functionGetCookie : String = Std.string((Xml.parse("<![CDATA[
			function () {
				if (!window.mp_get_cookie) {
					window.mp_get_cookie = function (name) {
						var nameEQ = name + \"=\";
						var ca = document.cookie.split(';');
						for(var i=0;i < ca.length;i++) {
							var c = ca[i];
							while (c.charAt(0)==' ') c = c.substring(1,c.length);
							if (c.indexOf(nameEQ) == 0) return decodeURIComponent(c.substring(nameEQ.length,c.length));
						}
						return null;
					}
				}
			}
		]]>")));

    private static inline var setCookie : String = "mp_set_cookie";
    private static var functionSetCookie : String = Std.string((Xml.parse("<![CDATA[
					function () {
						if (!window.mp_set_cookie) {
							window.mp_set_cookie = function (name, value) {
								var date = new Date();
								date.setTime(date.getTime()+(364*24*60*60*1000));
								var expires = \"; expires=\" + date.toGMTString();
								document.cookie = name+\"=\"+encodeURIComponent(value)+expires+\";\";
							}
						}
					}
				]]>")));

    private var util : Util = new Util();
    private var name : String;
    private var o : Dynamic;

    @:allow(mixpanel)
    private function new(name : String)
    {
        this.name = name;
    }

    public function initialize() : IStorageBackend{
        if (ExternalInterface.available) {
            try{
                ExternalInterface.addCallback("test_external_iface", null);
            }            catch (error : SecurityError){
                return null;
            }
        }
        else {
            return null;
        }

        if (!CookieBackend.inserted_js) {
            ExternalInterface.call(functionGetCookie);
            ExternalInterface.call(functionSetCookie);
            CookieBackend.inserted_js = true;
        }

        this.o = load();

        return this;
    }

    private function load() : Dynamic{
        var data : String = try cast(ExternalInterface.call(getCookie, name), String) catch(e:Dynamic) null;
        try{
            if (data != null) {return util.jsonDecode(data);
            }
        }        catch (err: Dynamic){
            trace(err);
            // ignore json parse errors

        }

        return { };
    }

    public function save() : Void
    {
        ExternalInterface.call(setCookie, name, util.jsonEncode(o));
    }

    public function updateCrossDomain(crossDomainStorage : Bool) : Void{
        //nop

    }

    public function has(key : String) : Bool
    {
        return o.exists(key);
    }

    public function get(key : String) : Dynamic
    {
        return Reflect.field(o, key);
    }

    public function set(key : String, val : Dynamic, save : Bool = true) : Void
    {
        Reflect.setField(o, key, val);
        if (save) {this.save();
        }
    }

    public function del(key : String) : Void{
        save();
    }

    public function clear() : Void{
        this.o = { };
        save();
    }

    private function get_Data() : Dynamic{
        return o;
    }
}
