package mixpanel;


import haxe.crypto.Base64;
import haxe.io.Bytes;
import haxe.Json;
import mixpanel.Storage;
import mixpanel.Util;

import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.net.URLLoader;
import flash.net.URLLoaderDataFormat;
import flash.net.URLRequest;
import flash.net.URLRequestMethod;
import flash.net.URLVariables;

/**
	 * Mixpanel Haxe API
	 * <p>Version 2.2.1</p>
	 */

class Mixpanel
{
    private var _ : Util;
    private var token : String;
    private var disableAllEvents : Bool = false;
    private var disabledEvents : Array<Dynamic> = [];

    /**
		 * @private
		 */
    @:allow(mixpanel)
    private var storage : Storage;

    /**
		 * @private
		 */
    @:allow(mixpanel)
    private var config : Dynamic;

    private var defaultConfig = {
            crossSubdomainStorage: true
        };

    /**
		 * Create an instance of the Mixpanel library
		 *
		 * @param token your Mixpanel API token
		 *
		 */
    public function new(token : String)
    {
        _ = new Util();
        var protocol : String = _.browserProtocol();

        config = _.extend({ }, defaultConfig);
        config = _.extend(config, {
                            apiHost: protocol + "//api.mixpanel.com/",
                            storageName: "mp_" + token,
                            token: token
                        });
        // config.apiHost = "http://127.0.0.1:4444/";

        storage = new Storage(config);

        // generate a distinct_id at instance creation
        // the user should override this id with identify()
        // if they want to set their own id
        this.register_once({distinct_id: _.UUID()}, "");
    }

    private function sendRequest(endpoint : String, data : Dynamic, callback : Dynamic->Void = null) : Dynamic{
        if (config.token == null) return null;
        var request : URLRequest = new URLRequest(config.apiHost + endpoint);
        request.method = URLRequestMethod.POST;
        var params : URLVariables = new URLVariables();

        var truncatedData : Dynamic = _.truncate(data, 255);
        var jsonData : String = Json.stringify(truncatedData);
        var encodedData : String = Base64.encode(Bytes.ofString(jsonData));

        params = _.extend(params, {
                            // _: Std.string(Date.now().getTime()),
                            data: encodedData,
                            ip: 1
                        });
        if (Reflect.field(config, "test")) {
            Reflect.setField(params, "test", 1);
        }
        if (Reflect.field(config, "verbose")) {
            Reflect.setField(params, "verbose", 1);
        }
        if (Reflect.field(config, "request_method")) {
            request.method = Reflect.field(config, "request_method");
        }

        request.data = params;

        var loader : URLLoader = new URLLoader();
        loader.dataFormat = URLLoaderDataFormat.TEXT;
        if (callback != null) {
            loader.addEventListener(Event.COMPLETE,
                    function(e : Event) {
                        callback(loader.data);
                    });
            loader.addEventListener(IOErrorEvent.IO_ERROR,
                    function(e : IOErrorEvent) : Void{
                        if (Reflect.field(config, "verbose")) {
                            callback("{\"status\":0,\"error\":\"" + e.text + "\"}");
                        }
                        else {
                            callback(0);
                        }
                    });
        }

        loader.load(request);

        return truncatedData;
    }


    /**
		 * Track an event.  This is the most important Mixpanel function and
		 * the one you will be using the most
		 *
		 * @param event the name of the event
		 * @param args if the first arg in args is an object, it will be used
		 * as the properties object.  The last argument is a callback function.
		 * The callback and properties arguments are both optional.
		 * @return the data sent to the server
		 *
		 */
    public function track(event : String, properties: Dynamic = null, callback: Dynamic->Dynamic = null) : Dynamic
    {
        if (Reflect.isFunction(properties)) {
            callback = properties;
            properties = null;
        }

        properties = (properties != null) ? _.extend({ }, properties) : { };

        if (!Reflect.field(properties, "token")) {properties.token = config.token;
        }
        Reflect.setField(properties, "mp_lib", "haxe");

        properties = storage.safeMerge(properties);

        var data : Dynamic = {
            "event": event,
            "properties": properties
        };

        var ret : Dynamic = null;
        if (disableAllEvents || Lambda.indexOf(disabledEvents, event) != -1) {
            if (callback != null && Reflect.field(config, "verbose")) {
                ret = callback("{\"status\":0, \"error\":\"Tracking of this event is disabled.\"}");
            }
            else if (callback != null) {
                ret = callback(0);
            }
        }
        else {
            ret = sendRequest("track", data, callback);
        }

        return ret;
    }

    /**
		 * Disable events on the Mixpanel object.  If passed no arguments,
	     * this function disables tracking of any event.  If passed an
	     * array of event names, those events will be disabled, but other
	     * events will continue to be tracked.
	     *
	     * <p>Note: this function doesn't stop regular mixpanel functions from
	     * firing such as register and name_tag.</p>
		 *
		 * @param events A array of event names to disable
		 */
    public function disable(events : Array<Dynamic> = null) : Void
    {
        if (events == null) {
            disableAllEvents = true;
        }
        else {
            disabledEvents = disabledEvents.concat(events);
        }
    }

    /**
  		 * Register a set of super properties, which are included with all
	     * events/funnels.  This will overwrite previous super property
	     * values.  It is mutable unlike register_once.
		 *
		 * @param properties Associative array of properties to store about the user
		 */
    public function register(properties : Dynamic) : Void
    {
        storage.register(properties);
    }

    /**
		 * Register a set of super properties only once.  This will not
		 * overwrite previous super property values, unlike register().
		 * It's basically immutable.
		 *
		 * @param properties Associative array of properties to store about the user
		 * @param defaultValue Value to override if already set in super properties (ex: "False")
		 *
		 */
    public function register_once(properties : Dynamic, defaultValue : Dynamic = null) : Void
    {
        storage.registerOnce(properties, defaultValue);
    }

    /**
		 * Delete a super property stored with the current user.
		 *
		 * @param property the name of the super property to remove
		 *
		 */
    public function unregister(property : String) : Void
    {
        storage.unregister(property);
    }

    /**
		 * Delete all super properties stored for the current user.
		 *
		 * <p><strong>THIS IS UNREVERSABLE!  Be careful.</strong></p>
		 *
		 */
    public function unregister_all() : Void
    {
        storage.unregister_all();
    }

    /**
		 * Get the value of a super property by the property name.
		 *
		 * @param property the name of the super property to retrieve
		 * @return the value of the super property
		 *
		 */
    public function get_property(property : String) : Dynamic
    {
        return storage.get(property);
    }

    /**
		 * Get the unique ID assigned to the user. This ID is
		 * automatically assigned unless you specify your own via
		 * identify().
		 *
		 * @return the current distinct_id
		 */
    public function get_distinct_id() : String
    {
        return try cast(get_property("distinct_id"), String) catch(e:Dynamic) null;
    }

    /**
		 * Identify a user with a unique id.  All subsequent
	     * actions caused by this user will be tied to this identity.  This
	     * property is used to track unique visitors.  If the method is
	     * never called, then unique visitors will be identified by a UUID
	     * generated the first time they visit the site.
		 *
		 * @param uniqueID A string that uniquely identifies the user
		 *
		 */
    public function identify(uniqueID : String) : Void
    {
        storage.register({
                    distinct_id : uniqueID

                });
    }

    /**
		 * Provide a string to recognize the user by.  The string passed to
	     * this method will appear in the Mixpanel Streams product rather
	     * than an automatically generated name.  Name tags do not have to
	     * be unique.
		 *
		 * @param name A human readable name for the user
		 *
		 */
    public function name_tag(name : String) : Void
    {
        storage.register({
                    mp_name_tag : name

                });
    }

    /**
		 * Set properties on a user record
		 *
		 * <p>Usage:</p>
		 *
		 * <pre>
		 * 		mixpanel.people_set('gender', 'm');
		 *
		 * 		mixpanel.people.set({
		 * 			'company': 'Acme',
		 * 			'plan': 'free'
		 * 		});
		 *
		 * 		// properties can be strings, integers or dates
		 * </pre>
		 */
    public function people_set(a: Dynamic, b: Dynamic = null, callback: Dynamic->Dynamic = null) : Dynamic
    {
        var setv = {};
        if (Std.is(a, String)) {
            Reflect.setField(setv, a, b);
        }
        else {
            setv = a;
            if (Reflect.isFunction(b)) {
                callback = b;
            }
        }


        setv = (setv != null) ? _.extend({ }, setv) : { };

        var data : Dynamic = {
            "$set": setv,
            "$token": config.token,
            "$distinct_id": storage.get("distinct_id")
        };

        return sendRequest("engage", data, callback);
    }

    /**
		 * Increment/decrement properties on a user record
		 *
		 * <p>Usage:</p>
		 *
		 * <pre>
		 * 		mixpanel.people_increment('page_views', 1);
		 *
		 * 		// or, for convienience, if you're just incrementing a counter by 1, you can
		 * 		// simply do
		 * 		mixpanel.people_increment('page_views');
		 *
		 * 		// to decrement a counter, pass a negative number
		 * 		mixpanel.people.increment('credits_left', -1);
		 *
		 * 		// like mixpanel.people_set(), you can increment multiple properties at once:
		 * 		mixpanel.people.increment({
		 * 			'counter1': '1',
		 * 			'counter2': '3'
		 * 		});
		 * </pre>
		 */
    public function people_increment(a: Dynamic, b: Dynamic=1, callback: Dynamic->Dynamic=null) : Dynamic
    {
        var props : Dynamic = {};

        if (Std.is(a, String)) {
            Reflect.setField(props, a, b);
        }
        else {
            props = a;
            if (Reflect.isFunction(b)) {
                callback = b;
            }
        }

        var addv : Dynamic = { };
        for (key in Reflect.fields(props)){
            if (Std.is(Reflect.field(props, key), Float)) {Reflect.setField(addv, key, Reflect.field(props, key));
            }
        }

        var data : Dynamic = {
            "$add": addv,
            "$token": config.token,
            "$distinct_id": storage.get("distinct_id")
        };

        return sendRequest("engage", data, callback);
    }

    /**
		 * Record that you have charged the current user a certain amount of money.
		 *
		 * <p>Usage:</p>
		 *
		 * <pre>
		 * 		// charge a user $29.99
		 * 		mixpanel.people_track_charge(29.99);
		 *
		 * 		// charge a user $10 on the 2nd of January
		 * 	    // Note: $time must be a valid ISO datetime string
		 * 		mixpanel.people_track_charge(10, { '$time': '2012-01-02T00:00:00' });
		 * </pre>
		 */
    public function people_track_charge(amount : Float, props: Dynamic = null, callback: Dynamic->Dynamic = null) : Dynamic
    {
        // get optional arguments
        if (Reflect.isFunction(props)) {
            props = {};
            callback = props;
        }

        Reflect.setField(props, "$amount", amount);

        var data : Dynamic = {
            "$append": {"$transactions": props
                    },
            "$token": config.token,
            "$distinct_id": storage.get("distinct_id")
        };

        return sendRequest("engage", data, callback);
    }

    /**
		 * Clear all the current user's transactions.
		 *
		 * <p>Usage:</p>
		 *
		 * <pre>
		 * 		mixpanel.people_clear_charges();
		 * </pre>
		 */
    public function people_clear_charges(callback: Dynamic->Dynamic = null) : Dynamic
    {
        var data : Dynamic = {
            "$set": {"$transactions": []
                    },
            "$token": config.token,
            "$distinct_id": storage.get("distinct_id")
        };

        return sendRequest("engage", data, callback);
    }

    /**
		 * delete the current user record (using current distinct_id)
		 *
		 * <p>Usage:</p>
		 *
		 * <pre>
		 * 		mixpanel.people_delete();
		 * </pre>
		 */
    public function people_delete(callback: Dynamic->Dynamic = null) : Dynamic
    {
        var data : Dynamic = {
            "$delete": storage.get("distinct_id"),
            "$token": config.token,
            "$distinct_id": storage.get("distinct_id")
        };

        return sendRequest("engage", data, callback);
    }

    /**
		 * Update the configuration of a mixpanel library instance.
		 *
		 * <p>The default config is:</p>
		 * <pre>
		 * {
		 *     // super properties span subdomains
		 *     crossSubdomainStorage: true,
		 *
		 *     // enable test in development mode
		 *     test: false,
		 *
		 * 	   // enable longer, debug-friendly api responses
		 *     verbose: false,
		 *
		 *     // Method to use when sending Mixpanel HTTP API requests,
		 *     // should be either URLRequestMethod.GET or URLRequestMethod.POST
		 *     request_method: URLRequestMethod.GET
		 * };
		 * </pre>
		 *
		 * @param config A dictionary of new configuration values to update
		 *
		 */
    public function set_config(config : Dynamic) : Void
    {
        if (Reflect.field(config, "crossSubdomainStorage") && config.crossSubdomainStorage != this.config.crossSubdomainStorage) {
            storage.updateCrossDomain(config.crossSubdomainStorage);
        }
        _.extend(this.config, config);
    }
}

