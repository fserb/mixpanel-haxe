package mixpanel;

import flash.net.SharedObject;

class Storage
{
    private var name : String;
    private var backend : IStorageBackend;

    @:allow(mixpanel)
    private function new(config : Dynamic)
    {
        name = config.storageName;

        // initialize backend
        backend = new SharedObjectBackend(name).initialize();
        if (backend == null) backend = new CookieBackend(name).initialize();
        if (backend == null) backend = new NonPersistentBackend(name).initialize();

        updateCrossDomain(config.crossSubdomainStorage);
        upgrade(config.token);
    }

    public function updateCrossDomain(crossDomainStorage : Bool) : Void{
        backend.updateCrossDomain(crossDomainStorage);
    }

    private function upgrade(token : String) : Void{
        var oldStorage : SharedObject = SharedObject.getLocal("mixpanel");
        if (!Reflect.field(oldStorage.data, token)) {
            return;
        }

        var oldData : Dynamic = Reflect.field(oldStorage.data, token);

        if (Reflect.field(oldData, "all")) {register(oldData.all);
        }
        if (Reflect.field(oldData, "events")) {register(oldData.events);
        }

      oldStorage.flush();
    }

    public function has(key : String) : Bool{
        return backend.has(key);
    }

    public function get(key : String) : Dynamic{
        return backend.get(key);
    }

    public function set(key : String, value : Dynamic) : Void{
        backend.set(key, value);
    }

    public function register(obj : Dynamic) : Void{
        for (key in Reflect.fields(obj)){
            backend.set(key, Reflect.field(obj, key), false);
        }

        backend.save();
    }

    public function registerOnce(obj : Dynamic, defaultValue : Dynamic = "None") : Void{
        for (key in Reflect.fields(obj)){
            if (!backend.has(key) || backend.get(key) == defaultValue) {
                backend.set(key, Reflect.field(obj, key), false);
            }
        }

        backend.save();
    }

    public function unregister(property : String) : Void{
        backend.del(property);
    }

    public function unregister_all() : Void{
        backend.clear();
    }

    public function safeMerge(properties : Dynamic) : Dynamic{
        for (key in Reflect.fields(backend.data)){
            if (!Reflect.field(properties, key)) {Reflect.setField(properties, key, backend.get(key));
            }
        }
        return properties;
    }
}
