package mixpanel;


class NonPersistentBackend implements IStorageBackend
{
    public var data(default, null) : Dynamic;

    private var o : Dynamic;

    @:allow(mixpanel)
    private function new(name : String)
    {
    }

    public function initialize() : IStorageBackend{
        o = { };

        return this;
    }

    public function save() : Void
    {
        //nop

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
    }

    public function del(key : String) : Void{
    }

    public function clear() : Void{
        this.o = { };
    }

    private function get_Data() : Dynamic{
        return o;
    }
}
