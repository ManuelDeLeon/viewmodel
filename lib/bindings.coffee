addBinding = ViewModel.addBinding

addBinding
  name: 'default'
  bind: (bindArg) ->
    bindArg.element.on bindArg.bindName, (event) ->
      bindArg.setVmValue(event)

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


addBinding
  name: 'value'
  events:
    'input propertychange': (event, bindArg) ->
      newVal = bindArg.element.val()
      bindArg.setVmValue(newVal) if newVal isnt bindArg.getVmValue()

  autorun: (c, bindArg) ->
    newVal = bindArg.getVmValue()
    bindArg.element.val(newVal) if newVal isnt bindArg.element.val()

addBinding
  name: 'text'
  autorun: (c, bindArg) ->
    bindArg.element.text bindArg.getVmValue()

addBinding
  name: 'html'
  autorun: (c, bindArg) ->
    bindArg.element.html bindArg.getVmValue()

changeBinding = (eb) ->
  eb.value or eb.check or eb.text or eb.focus or eb.hover or eb.if or eb.toggle

addBinding
  name: 'change'
  bind: (bindArg)->
    bindValue = changeBinding(bindArg.elementBind)
    bindArg.autorun (c) ->
      newValue = bindArg.getVmValue(bindValue)
      bindArg.setVmValue newValue if not c.firstRun

  bindIf: (bindArg)-> changeBinding(bindArg.elementBind)

addBinding
  name: 'enter'
  events:
    'keyup': (event, bindArg) ->
      if event.which is 13 or event.keyCode is 13
        bindArg.setVmValue(event)

addBinding
  name: 'attr'
  bind: (bindArg) ->
    for attr of bindArg.bindValue
      do (attr) ->
        bindArg.autorun ->
          bindArg.element.attr attr, bindArg.getVmValue(bindArg.bindValue[attr])
    return

addBinding
  name: 'check'
  events:
    'change': (event, bindArg) ->
      bindArg.setVmValue bindArg.element.is(':checked')

  autorun: (c, bindArg) ->
    vmValue = bindArg.getVmValue()
    elementCheck = bindArg.element.is(':checked')
    bindArg.element.prop 'checked', vmValue if elementCheck isnt vmValue

addBinding
  name: 'group'
  selector: 'input[type=checkbox]'
  events:
    'change': (event, bindArg) ->
      vmValue = bindArg.getVmValue()
      elementValue = bindArg.element.val()
      if bindArg.element.is(':checked')
        vmValue.push elementValue if elementValue not in vmValue
      else
        vmValue.remove elementValue

  autorun: (c, bindArg) ->
    vmValue = bindArg.getVmValue()
    elementCheck = bindArg.element.is(':checked')
    elementValue = bindArg.element.val()
    newValue = elementValue in vmValue
    bindArg.element.prop 'checked', newValue if elementCheck isnt newValue

addBinding
  name: 'group'
  selector: 'input[type=radio]'
  events:
    'change': (event, bindArg) ->
      bindArg.setVmValue bindArg.element.val()

  autorun: (c, bindArg) ->
    vmValue = bindArg.getVmValue()
    elementValue = bindArg.element.val()
    bindArg.element.prop 'checked', vmValue is elementValue

addBinding
  name: 'class'
  bindIf: (bindArg) -> _.isString(bindArg.bindValue)
  bind: (bindArg) ->
    bindArg.prevValue = ''
  autorun: (c, bindArg) ->
    newValue = bindArg.getVmValue()
    bindArg.element.removeClass bindArg.prevValue
    bindArg.element.addClass newValue
    bindArg.prevValue = newValue

addBinding
  name: 'class'
  bindIf: (bindArg) -> not _.isString(bindArg.bindValue)
  bind: (bindArg) ->
    for cssClass of bindArg.bindValue
      do (cssClass) ->
        bindArg.autorun ->
          if bindArg.getVmValue(bindArg.bindValue[cssClass])
            bindArg.element.addClass cssClass
          else
            bindArg.element.removeClass cssClass
          return
    return

addBinding
  name: 'style'
  bindIf: (bindArg) -> _.isString(bindArg.bindValue)
  autorun: (c, bindArg) ->
    newValue = bindArg.getVmValue()
    if _.isString(newValue)
      newValue = ViewModel.parseBind(newValue)
    bindArg.element.css newValue

addBinding
  name: 'style'
  bindIf: (bindArg) -> not _.isString(bindArg.bindValue)
  bind: (bindArg) ->
    for style of bindArg.bindValue
      do (style) ->
        bindArg.autorun ->
          bindArg.element.css style, bindArg.getVmValue(bindArg.bindValue[style])
          return
    return
