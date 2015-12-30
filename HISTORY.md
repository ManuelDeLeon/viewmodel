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
