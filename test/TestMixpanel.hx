// haxe -lib mixpanel -main Test -cp test -cpp bin/

import mixpanel.Mixpanel;

class TestMixpanel {
  static public function main() {
    var mixpanel:Mixpanel = new Mixpanel("fade9031457b5335cbc464007d65bd89");
    mixpanel.identify("1");
    mixpanel.people_set({});
    mixpanel.track("Solved", {id: "abc", solveTime: 200});
    mixpanel.track("Solved", {id: "aaa", solveTime: 210});
    mixpanel.track("Solved", {id: "ddd", solveTime: 250.1});
  }
}
