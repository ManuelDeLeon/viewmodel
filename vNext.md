# ViewModel vNext
This is a place for me to put ideas I think are worth considering if I ever get to do a version 2.0 of the ViewModel library. **These are just ideas, there is no time frame for when, or even if, I'll work on it**

Drop me a line at http://viewmodelboard.meteor.com with your questions, comments, flames?

- Use `v-` tags instead of `data-bind`. I got this from the Vue.js. I can't think of a downside for doing `<button v-click="doSomething"></button>` instead of `<button data-bind="click: doSomething"></button>`. For multiple properties it can look like this:
```
<button 
    v-click="doSomething"
    v-text="buttonText"
    v-enabled="buttonEnabled"
    v-class="btn-primary: isPrimary, btn-large: isLarge"
></button>
```
- Use ES5 properties. So instead of converting properties to functions that you can get by calling them without parameters (e.g. `vm.name()`) and setting them by passing a parameter (e.g. `vm.name('Paco')`), it would just make the property reactive and you would call and set them as regular properties (`var name = vm.name` and `vm.name = 'Paco'`)
- The `if` binding would remove the element from the DOM and `visible` would leave it on the page. Right now they're synonyms and both leave the element on the page but with the style `display: none`
