addBinding = ViewModel.addBinding

addBinding
  name: 'text'
  autorun: (c, bindArg) ->
    bindArg.element.text bindArg.getVmValue()
    return

addBinding
  name: 'default'
  bind: (bindArg) ->
    ViewModel.check 'vmProp', bindArg.bindValue, bindArg.viewmodel, "method"
    bindArg.element.on bindArg.bindName, (event) -> bindArg.setVmValue(event)
    return

addBinding
  name: 'toggle'
  events:
    click: (event, bindArg) ->
      value = bindArg.getVmValue()
      bindArg.setVmValue(!value)
      return

addBinding
  name: 'if'
  autorun: (c, bindArg) ->
    if bindArg.getVmValue()
      bindArg.element.show()
    else
      bindArg.element.hide()
    return