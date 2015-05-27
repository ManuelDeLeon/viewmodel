// Prevent a parent's onRendered to be called after a child
// has rendered but before the child's onRendered has been called.
// The following is the order of events that we want to prevent:
//
// parent template renders html on the page
// child template renders html on the page
// Meteor triggers onRendered of parent
// Meteor triggers onRendered of child
//
Blaze.View.prototype.onViewReady = function (cb) {
  var self = this;
  var fire = function () {
    setTimeout(function () {
      if (! self.isDestroyed) {
        Blaze._withCurrentView(self, function () {
          cb.call(self);
        });
      }
    }, 0);
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