addBinding = ViewModel.addBinding

addBinding
  name: 'text'
  autorun: (c, bindArg) ->
    bindArg.element.text bindArg.getVmValue()

addBinding
  name: 'default'
  bind: (bindArg) ->
    bindArg.element.on bindArg.bindName, bindArg.viewmodel[bindArg.bindValue]

addBinding
  name: 'toggle'
  events:
    click: (event, bindArg) ->
      value = bindArg.getVmValue()
      bindArg.setVmValue(!value)

addBinding
  name: 'if'
  autorun: (c, bindArg) ->
    if bindArg.getVmValue()
      bindArg.element.show()
    else
      bindArg.element.hide()