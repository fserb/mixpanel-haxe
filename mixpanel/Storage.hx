package mixpanel;

import openfl.errors.Error;

import flash.net.SharedObject;
import flash.system.Security;

class Storage {
  private var name : String;
  private var shared: SharedObject;

  @:allow(mixpanel)
  private function new(config:Dynamic) {
    name = config.storageName;

    updateCrossDomain(config.crossSubdomainStorage);
  }

  public function updateCrossDomain(crossDomainStorage:Bool) {
    Security.exactSettings = !crossDomainStorage;
    shared = SharedObject.getLocal("mixpanel/" + name, "/");
  }

  public function has(key:String):Bool {
    return Reflect.hasField(shared.data, key);
  }

  public function get(key : String):Dynamic {
    return Reflect.field(shared.data, key);
  }

  public function set(key:String, value:Dynamic) {
    Reflect.setField(shared.data, key, value);
    shared.flush();
  }

  public function register(obj:Dynamic) {
    for (key in Reflect.fields(obj)) {
      Reflect.setField(shared.data, key, Reflect.field(obj, key));
    }
    shared.flush();
  }

  public function registerOnce(obj:Dynamic, defaultValue:Dynamic="None") {
    for (key in Reflect.fields(obj)) {
      if (!has(key) || get(key) == defaultValue) {
        Reflect.setField(shared.data, key, Reflect.field(obj, key));
      }
    }
    shared.flush();
  }

  public function unregister(property:String) {
    Reflect.deleteField(shared.data, property);
    shared.flush();
  }

  public function unregister_all() {
    shared.clear();
    for (f in Reflect.fields(shared.data)) {
      Reflect.deleteField(shared.data, f);
    }
    shared.flush();
  }

  public function safeMerge(properties:Dynamic): Dynamic {
    for (key in Reflect.fields(shared.data)) {
      if (!Reflect.field(properties, key)) {
        Reflect.setField(properties, key, get(key));
      }
    }
    return properties;
  }
}
