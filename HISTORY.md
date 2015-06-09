## 1.7.8

* Add template.elementBind method to retrieve the bind on an element. Very useful for testing.

## 1.7.7

* Add toggle binding for toggling a boolean on click.

## 1.7.6

* parent is set onCreated (when possible)

## 1.7.5

* Fix enabled/disabled binding for textarea

## 1.7.4

* Add the following attributes as binds: 'src', 'href', 'readonly'

## 1.7.3

* Prevent event and helper hooks from being added twice.

## 1.7.2

* blaze_events and blaze_helpers now accept either an object or a function

## 1.7.1

* Don't throw an error when calling .parent() of a vm that doesn't have one.

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

* Use ViewModel reserved words "as is" when extending a view model.