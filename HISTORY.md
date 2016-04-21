## 4.0.14

* Throw an error if a bind can't be parsed.

## 4.0.13

* Allow .children to use a template name plus a function

## 4.0.12

* Check that a view model property exists before using it as a template helper.

## 4.0.11

* I don't even know what to say...

## 4.0.10

* Only process bindings once

## 4.0.9

* Don't execute onCreated/onRendered/autoruns if the template instance is destroyed

## 4.0.8

* Don't try to bind to an element if its view is destroyed 

## 4.0.7

* Use afterFlush instead of onViewReady (so it can work better with packages like jagi:astronomy and tap:i18n)

## 4.0.6

* Fix automatic state save across hot code push when using appcache package.

## 4.0.5

* Don't check if an event is supported (the code was buggy)

## 4.0.4

* Update docs url (now that *.meteor.com is going down)

## 4.0.3

* AddAttributeBinding is now case sensitive

## 4.0.2

* Make attributes case sensitive

## 4.0.1

* Fix binding conditionals when it starts with a negative

## 4.0.0

* New ViewModel.addAttributeBinding to add attribute as bindings. See https://viewmodel.org/docs/bindings#attr

### BREAKING CHANGES

* src, readonly, and href used to be default bindings which mapped to their corresponding attributes. Now they're not. If you use these bindings you now have to add them with ViewModel.addAttributeBinding( ['src','href','readonly'] )

## 3.4.10

* Fix signals with Firefox

## 3.4.9

* Events are now loaded from mixin/share/load too

## 3.4.8

* Check for parent node missing when calculating template's path.

## 3.4.7

* Fix hot code push with view models with an id property. 

## 3.4.6

* Only run defining function once.

## 3.4.5

* Change doesn't trigger on first run.

## 3.4.4

* Load context onCreated so Blaze helpers can use inherited properties.

## 3.4.3

* Style strings now accept semi-colons. 

## 3.4.2

* Fix onCreated. Delay loading data when running in a simulation

## 3.4.1

* Fix this.parent() from onRendered

## 3.4.0

* Add refGroup binding. see https://viewmodel.org/docs/bindings#refgroup

## 3.3.5

* Simplify override priority. 

## 3.3.4

* Context properties override even functions.

## 3.3.3

* Initial load order overrides even functions.

## 3.3.2

* Throw nice error when trying to access a non property in your bindings

## 3.3.1

* Allow .load to load an array of objects with hooks (like onRendered)

## 3.3.0

* Add throttle to signals.

## 3.2.0

* Add a way to transform signals. See: https://viewmodel.org/docs/viewmodels#signal

## 3.1.2

* Fix onCreated/onRendered/onDestroyed/autorun when using an array of functions

## 3.1.1

* Fix onRendered so it happens after bindings are in place.

## 3.1.0

* Add viewmodel.child method which returns the first child it finds with the given criteria. See the docs.

## 3.0.0

* Add signals to capture stream of events that happen outside the view models.
* Fix options binding on Firefox
* Set order of load priority: context props, direct props, from load, mixin, share, signal
* Return undefined when ViewModel.find and .findOne can't find the given template
* onCreated now runs when the template is created.

### BREAKING CHANGES

* onCreated now runs when the template is created. This means, by the time onCreated is called, the view model will not have properties automatically added from the markup. I don't expect this to affect many people, if at all. You should be able to upgrade without a problem. Check where you use onCreated just to make sure.
* The order of load priority is now: context props, direct props, from load, mixin, share, signal. This will only affect you if you use the same property name multiple times in the same view model. For example if you have a mixin with a property `name` and a view model that uses that mixin and also has `name` defined for itself. In those cases check that you're getting the expected result.

## 2.9.3

* Fix cleanup when a template is destroyed. It was leaving a reference to the view model on ViewModel.byTemplate
* Give a better error when trying to access a property of undefined/null in the template.

## 2.9.2

* Warn if you try to put _id on the url without specifying a vmTag property.

## 2.9.1

* Fix ViewModel.find

## 2.9.0

* Add ViewModel.find and ViewModel.findOne - They both take an optional string with the name of the template and an optional function to find a template.

## 2.8.1

* .children() uses the .parent instead of its own logic.

## 2.8.0

* You can now add an array of strings and objects to mixin and share properties. 

## 2.7.8

* onCreated/onRendered/onDestroyed/autorun now work when defining the view model with a function.

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

* mixins and shares can be scoped to a view model property. So instead of adding all share/mixin properties to the view model, you can specify under which property they should fall. See: https://viewmodel.org/docs/viewmodels#sharemixinscope

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
