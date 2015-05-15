package mixpanel;

import openfl.errors.Error;

import flash.net.SharedObject;
import flash.system.Security;

class SharedObjectBackend implements IStorageBackend
{
    public var data(default, null) : Dynamic;

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

        data = sharedObject.data;

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
        return Reflect.hasField(sharedObject.data, key);
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
        Reflect.deleteField(sharedObject.data, key);
        save();
    }

    public function clear() : Void{
        sharedObject.clear();
        for (f in Reflect.fields(sharedObject.data)) {
            del(f);
        }
        sharedObject.flush();
    }

    private function get_Data() : Dynamic{
        return sharedObject.data;
    }
}
