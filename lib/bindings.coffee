addBinding = ViewModel.addBinding

addBinding
  name: 'text'
  autorun: (c, bindArg) ->
    bindArg.element.text bindArg.getVmValue()
    return

addBinding
  name: 'default'
  bind: (bindArg) ->
    bindArg.element.on bindArg.bindName, (event) ->
      if ~bindArg.bindValue.indexOf(')', bindArg.bindValue.length - 1)
        bindArg.getVmValue()
      else
        bindArg.setVmValue(event)
      return
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

addBinding
  name: 'value'
  selector: 'input'
  events:
    'input propertychange': (event, bindArg) ->
      bindArg.setVmValue bindArg.element.val()
  autorun: (c, bindArg) ->
    bindArg.element.val bindArg.getVmValue()