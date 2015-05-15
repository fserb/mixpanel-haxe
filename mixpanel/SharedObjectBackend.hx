package mixpanel;

import openfl.errors.Error;

import flash.net.SharedObject;
import flash.system.Security;

class SharedObjectBackend implements IStorageBackend
{
    public var data(get, never) : Dynamic;

    private var name : String;
    private var sharedObject : SharedObject;

    @:allow(mixpanel)
    private function new(name : String)
    {
        this.name = name;
    }

    public function initialize() : IStorageBackend{
        return load();
    }

    private function load() : IStorageBackend{
        try{
            sharedObject = SharedObject.getLocal("mixpanel/" + name, "/");
        }        catch (e : Error){
            return null;
        }

        return this;
    }

    public function save() : Void
    {
        sharedObject.flush();
    }

    public function updateCrossDomain(crossDomainStorage : Bool) : Void{
        try{
            Security.exactSettings = !crossDomainStorage;
        }        catch (e : Error){ };

        load();
    }

    public function has(key : String) : Bool
    {
        return sharedObject.data.exists(key);
    }

    public function get(key : String) : Dynamic
    {
        return Reflect.field(sharedObject.data, key);
    }

    public function set(key : String, val : Dynamic, save : Bool = true) : Void
    {
        Reflect.setField(sharedObject.data, key, val);
        if (save) {this.save();
        }
    }

    public function del(key : String) : Void{
        save();
    }

    public function clear() : Void{
        sharedObject.clear();
        save();
    }

    private function get_Data() : Dynamic{
        return sharedObject.data;
    }
}
