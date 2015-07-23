# ViewModel vNext
This is a place for me to put ideas I think are worth considering if I ever get to do a version 2.0 of the ViewModel library. **These are just ideas, there is no time frame for when, or even if, I'll work on it**

Drop me a line at http://viewmodelboard.meteor.com with your questions or comments.

- ~~Use `v-` tags instead of `data-bind`. I can't think of a downside for doing `<button v-click="doSomething"></button>` instead of `<button data-bind="click: doSomething"></button>`.~~
- The performance of searching for multiple `v-` tags isn't good enough, specially on mobile. It's not horrible and most apps would do just fine, but it degrades the more bindings there are on the page. We'll stay with a single tag but use `db=` by default instead.
- Allow user to change the bind tag from `db=` to anything else (e.g. stay with `data-bind=`). This could be set globally via `ViewModel.BindAttribute` and for specific view models via `vmBindAttribute`.
- ~~Use ES5 properties. So instead of converting properties to functions that you can get by calling them without parameters (e.g. `vm.name()`) and setting them by passing a parameter (e.g. `vm.name('Paco')`), it would just make the property reactive and you would call and set them as regular properties (`var name = vm.name` and `vm.name = 'Paco'`)~~
- The current system has a really nice side effect of being able to pass properties by reference. That means that a parent template can pass one of its properties to a child and now both view models share the same property.
- Reactify the whole objects instead of wrapping them in a property.
- ~~Drop IE8 and IE9 support and use vanilla JS for most things instead of relying so heavily on JQuery.~~
- Not much reason to drop IE8 support if not going to use ES5 properties.
- ~~The `if` binding would remove the element from the DOM and `visible` would leave it on the page. Right now they're synonyms and both leave the element on the page but with the style `display: none`. The same would apply to `hidden`/`unless`.~~
- Removing the elements within `if` opens up a whole can of worms so I don't think it's worth it.
- Add a `group-value` binding for checkboxes and radios. That way `checked` will bind a boolean telling whether the checkbox/radio is ticked or not, and `group-value` binds to the value of the group.
- View models will only be able to bind to Meteor templates.
- Make better use of console log/error/warn/info
- Create view models only by passing objects. If you want to name the vm then use the property `vmName`, if you want to add a helper use `vmHelpers`.
- Add a setting so ViewModel tries to save the state of the view model (for hot code pushes) if it's the only one used for that template. Settings would be `auto` (it will save the state if it's the only view model for the template or if it has a name), `named` (like right now where you have to give the view model a name for it to save the state), and `none`. You would be able to set it globally via `ViewModel.persist = 'named'` or `ViewModel.saveState = 'named'` and for individual templates via `viewmodel.vmPersist = 'none'`.
- Figure out a way to make binding definitions/extensions more human readable. The parameters aren't exactly crystal clear.
- Think of a way to add filters, converters, and validators.
- Prefix ViewModel specific methods with `vm` (e.g. `vmToJS()`, `vmParent()`, etc.)
- Remove `onRendered`, `onCreated`, and `onDestroyed` in favor of `vmBeforeBind`/`vmAfterBind`, `vmBeforeCreate`/`vmAfterCreate`, `vmBeforeDispose`/`vmAfterDispose`
- Use `vmHelpers` and `vmEvents` to add blaze helpers and events.
- Standardise bind names. Don't use `ed` (`focus` instead of `focused`, `check` instead of `checked`, etc.)
