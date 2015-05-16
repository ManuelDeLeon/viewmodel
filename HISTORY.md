## 1.6.6

* Add a history file!

* Monkey patch Blaze so Blaze.View.prototype.onViewReady uses setTimeout instead of Tracker.autoFlush. This is to avoid a situation where a parent will execute the onRendered callback before a child can do so, even though the child already rendered.

* Use ViewModel reserved words "as is" when extending a view model.