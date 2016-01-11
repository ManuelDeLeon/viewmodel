## 2.7.7

* .parent() now searches for the first view model up the chain. Not just the parent template.

## 2.7.6

* Using viewmodel-debug@2.5.1

## 2.7.5

* Missed underscore 1.0.3 

## 2.7.4

* Reduce version requirements so it works with Meteor 1.1 

## 2.7.3

* options binding now works with mongo collections 

## 2.7.2

* Order of events are now correct: onCreated -> onRendered -> autorun

## 2.7.1

* View model methods used as template helpers now receive the parameters from the template.

## 2.7.0

* mixins and shares can be scoped to a view model property. So instead of adding all share/mixin properties to the view model, you can specify under which property they should fall. See: https://viewmodel.meteor.com/docs/viewmodels#sharemixinscope

## 2.6.0

* .load now accepts an array of objects
* You can now load multiple objects when you define a view model( .viewmodel({ load: objOrArray }) )
* Loaded objects can have their own autorun/onCreated/onRendered/onDestroyed properties.

## 2.5.5

* Fix to the fix

## 2.5.4

* Fix issue when using Iron Router's contentFor blocks

## 2.5.3

* Fix issue with blaze helpers not being wired up correctly when using nested #each blocks.

## 2.5.2

* autoruns now receive a computation parameter (as they should).

## 2.5.1

* Trim parameters used when using functions declared in bindings

## 2.5.0

* Properties are automatically added to the view models when used in the markup. This alleviates the problem of inheriting from Mongo documents where one might be missing a field.

## 2.4.2

* Update readme

## 2.4.1

* Make `this` reactive when used in a binding inside an `#each` block

## 2.4.0

* Add error messages when the bind/event doesn't exist.
* Add href, src, readonly bindings.
* Check .viewmodel args

## 2.3.2

* Fix inherited contexts

## 2.3.1

* Fix autorun when given an array of functions

## 2.3.0

* Add ViewModel.elementBind for testing

## 2.2.2

* Fix setVmValue when the value to set is taken from the view model

## 2.2.1

* Add events

## 2.1.1

* Fix issue when using {{b and {{on at the same time

## 2.1.0

* Add persist option for individual view models

## 2.0.0

* Hello World!
