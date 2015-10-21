addBinding = ViewModel.addBinding



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
      newVal = bindArg.element.val()
      bindArg.setVmValue(newVal) if newVal isnt bindArg.getVmValue()
      return
  autorun: (c, bindArg) ->
    newVal = bindArg.getVmValue()
    bindArg.element.val(newVal) if newVal isnt bindArg.element.val()
    return

addBinding
  name: 'text'
  autorun: (c, bindArg) ->
    bindArg.element.text bindArg.getVmValue()
    return

addBinding
  name: 'html'
  autorun: (c, bindArg) ->
    bindArg.element.html bindArg.getVmValue()
    return