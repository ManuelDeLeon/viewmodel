## 1.6.9

* Check the view model object before extending from it.

## 1.6.8

* Fix dispose when template doesn't have a parent.

## 1.6.7

* Add viewmodel.children() method. This is the counterpart of .parent()

* 'children' is now a reserved word, just like 'parent'.

## 1.6.6

* Add a history file! (it was about time)

* Monkey patch Blaze so Blaze.View.prototype.onViewReady uses setTimeout instead of Tracker.autoFlush. This is to avoid a situation where a parent will execute the onRendered callback before a child can do so, even though the child already rendered.

> Don't like monkey patching Meteor? 
> Tell someone at MDG to reopen the ticket to fix the way onRendered events are called. See
> https://github.com/meteor/meteor/issues/4410

* Use ViewModel reserved words "as is" when extending a view model.