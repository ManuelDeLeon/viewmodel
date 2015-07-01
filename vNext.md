# ViewModel vNext
This is a place for me to put ideas I think are worth considering if I ever get to do a version 2.0 of the ViewModel library. **These are just ideas, there is no time frame for when, or even if, I'll work on it**

Drop me a line at http://viewmodelboard.meteor.com with your questions or comments.

- Use `v-` tags instead of `data-bind`. I can't think of a downside for doing `<button v-click="doSomething"></button>` instead of `<button data-bind="click: doSomething"></button>`. For multiple properties it can look like this:
```
<button 
    v-click="doSomething"
    v-text="buttonText"
    v-enabled="buttonEnabled"
    v-class="btn-primary: isPrimary, btn-large: isLarge"
></button>
```
- Drop IE8 and IE9 support and use vanilla JS for most things instead of relying so heavily on JQuery.
- Use ES5 properties. So instead of converting properties to functions that you can get by calling them without parameters (e.g. `vm.name()`) and setting them by passing a parameter (e.g. `vm.name('Paco')`), it would just make the property reactive and you would call and set them as regular properties (`var name = vm.name` and `vm.name = 'Paco'`)
- The `if` binding would remove the element from the DOM and `visible` would leave it on the page. Right now they're synonyms and both leave the element on the page but with the style `display: none`. The same would apply to `hidden`/`unless`.
- Add a `v-group-value` binding for checkboxes and radios. That way `v-checked` will bind a boolean telling whether the checkbox/radio is ticked or not, and `v-group-value` binds to the value of the group.
- View models will only be able to bind to Meteor templates and you must give a template instance when creating them.
- Show a console warning when you use a reserved word in your view models.
- Add a setting so ViewModel tries to save the state of the view model (for hot code pushes) if it's the only one used for that template. Settings would be `auto` (it will save the state if it's the only view model for the template or if it has a name), `named` (like right now where you have to give the view model a name for it to save the state), and `none`. You would be able to set it globally via `ViewModel.persist = 'named'` or `ViewModel.saveState = 'named'` and for individual templates via `viewmodel.vmPersist = 'none'`.
- Figure out a way to make binding definitions/extensions more human readable. The parameters aren't exactly crystal clear.
- Add a `viewmodel.children()` method.
- Think of a way to add filters, converters, and validators.
- Remove `onRendered` and `onCreated` in favor of `beforeRendered`/`afterRendered` and `beforeCreated`/`afterCreated`
- Remove `text` bind and just use `value` for everything. One thing less to remember.
