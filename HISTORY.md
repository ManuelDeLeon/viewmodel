## 1.9.0

* Allow binding directly to parent properties (`data-bind="value: parent.name"`)

## 1.8.9

* Simplify input value binding

## 1.8.8

* Fix backspace on empty input for some browsers.

## 1.8.7

* Keypress disregards non-characters when updating the underlying value

## 1.8.6

* Trigger a change when the value bind changes programmatically.
* Fix select element (multiple) not maintaining selections when an element is added to the array.

## 1.8.5

* Show console messages only when in development.

## 1.8.4

* .extend now updates values if the view model already has the properties.

## 1.8.3

* value bind now passes the input value to a bound function instead of the jquery event.
* Fix keypress event on input value bind
* Fix url state save for templates with dots.

## 1.8.2

* ViewModel is now able to save the state on the URL. To do so add a `onUrl` property to your viewmodels with either a string or array of strings with the names of the properties you want on the URL. You must give the view model a unique name though.

## 1.8.1

* Prevent value bind from updating on the next JS cycle when the value doesn't have to be delayed.
* Add `beforeBind` and `afterBind` to be used instead of `onRendered` (onRendered still works but before/after bind is clearer)


## 1.8.0

* If ViewModel.byId doesn't find a view model with the given id, it will return a view model with that template (as long as there's only one).

## 1.7.9

* Put onRendered functions on the animation frame so you don't see a flicker if you define your elements with one style and then change it via the view model's default value.

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