package mixpanel;


interface IStorageBackend
{


    var data(default, null) : Dynamic;

    // @:allow(com.mixpanel)
    // private function new(name : String);

    function initialize() : IStorageBackend;
    function save() : Void;

    function updateCrossDomain(crossDomainStorage : Bool) : Void;

    function has(key : String) : Bool;
    function get(key : String) : Dynamic;
    function set(key : String, val : Dynamic, save : Bool = true) : Void;
    function del(key : String) : Void;
    function clear() : Void;
}
