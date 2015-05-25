// Don't like monkey patching Meteor?
// Tell someone at MDG to fix the way onRendered events are called.
// https://github.com/meteor/meteor/issues/4410

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