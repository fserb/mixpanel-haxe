Mixpanel for Haxe
=================

This library contains the interface to Mixpanel API for Haxe/OpenFL.

Based on [mixpanel-as3](https://github.com/mixpanel/mixpanel-as3).

Differences from the AS3 version:

1. passing a `null` token to the constructor will block all sendRequest
operations. This can be useful if you want to simply disable Mixpanel but not
have tons of branch code.

2. library send POST isntead of GET requests by defaut. OpenFL legacy has a bug
where `URLLoader` ignores GET CGI data. This may be reversed in the future, but
there are no real implications for user side.

3. only `SharedObject` is supported for backend storage, and OpenFL cares about
the abstractions.

4. The library identifies itself to Mixpanel as `mp_lib=haxe`, following
Mixpanel standards.

Everything else should be the same and you can follow [AS3 usage documentation](https://mixpanel.com/help/reference/as3).
