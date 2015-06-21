// This patch does 2 things:
//
// 1:
// Put onRendered functions on the animation frame so you don't see
// a flicker if you define your elements with one style and then
// change it via the view model's default value.
//
// 2:
// Prevent a parent's onRendered to be called after a child
// has rendered but before the child's onRendered has been called.
// The following is the order of events that we want to prevent:
//
// parent template renders html on the page
// child template renders html on the page
// Meteor triggers onRendered of parent
// Meteor triggers onRendered of child
//
var requestAnimFrame = (function(){
  return  window.requestAnimationFrame       ||
    window.webkitRequestAnimationFrame ||
    window.mozRequestAnimationFrame    ||
    function( callback ){
      window.setTimeout(callback, 0);
    };
})();

var requestTimeout = function(fn) {
  function loop(){
    fn.call();
  }

  requestAnimFrame(loop);
};


Blaze.View.prototype.onViewReady = function (cb) {
  var self = this;
  var fire = function () {
    requestTimeout(function () {
      if (! self.isDestroyed) {
        Blaze._withCurrentView(self, function () {
          cb.call(self);
        });
      }
    });
  };
  self._onViewRendered(function onViewRendered() {
    if (self.isDestroyed)
      return;
    if (! self._domrange.attached)
      self._domrange.onAttached(fire);
    else
      fire();
  });
};