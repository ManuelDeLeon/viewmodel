addBinding = ViewModel.addBinding

addBinding
  name: 'text'
  autorun: (c, bindArg) ->
    bindArg.element.text bindArg.getVmValue()

addBinding
  name: 'default'
  bind: (bindArg) ->
    bindArg.element.on bindArg.bindName, bindArg.viewmodel[bindArg.bindValue]