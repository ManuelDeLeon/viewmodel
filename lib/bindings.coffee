isArray = (obj) -> obj instanceof Array

addBinding = ViewModel.addBinding


addBinding
  name: 'default'
  bind: (bindArg, event) ->
    ViewModel.check '$default', bindArg
    bindArg.element.on bindArg.bindName, (event) ->
      bindArg.setVmValue(event)
      return
    return

addBinding
  name: 'toggle'
  events:
    click: (bindArg) ->
      value = bindArg.getVmValue()
      bindArg.setVmValue(!value)

showHide = (reverse) ->
  (bindArg) ->
    show = bindArg.getVmValue()
    show = !show if reverse
    if show
      bindArg.element.show()
    else
      bindArg.element.hide()

addBinding
  name: 'if'
  autorun: showHide(false)

addBinding
  name: 'visible'
  autorun: showHide(false)

addBinding
  name: 'unless'
  autorun: showHide(true)

addBinding
  name: 'hide'
  autorun: showHide(true)

addBinding
  name: 'value'
  events:
    'input propertychange': (bindArg) ->
      newVal = bindArg.element.val()
      bindArg.setVmValue(newVal) if newVal isnt bindArg.getVmValue()

  autorun: (bindArg) ->
    newVal = bindArg.getVmValue()
    bindArg.element.val(newVal) if newVal isnt bindArg.element.val()

addBinding
  name: 'text'
  autorun: (bindArg) ->
    bindArg.element.text bindArg.getVmValue()
    return

addBinding
  name: 'html'
  autorun: (bindArg) ->
    bindArg.element.html bindArg.getVmValue()

changeBinding = (eb) ->
  eb.value or eb.check or eb.text or eb.html or eb.focus or eb.hover or eb.toggle or eb.if or eb.visible or eb.unless or eb.hide or eb.enable or eb.disable

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
    'keyup': (bindArg, event) ->
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

attrPremade = ['src','href','readonly']
for attr in attrPremade
  do (attr) ->
    addBinding
      name: attr
      bind: (bindArg) ->
        bindArg.autorun ->
          bindArg.element.attr attr, bindArg.getVmValue(bindArg.bindValue[attr])
        return

addBinding
  name: 'check'
  events:
    'change': (bindArg) ->
      bindArg.setVmValue bindArg.element.is(':checked')
      return

  autorun: (bindArg) ->
    vmValue = bindArg.getVmValue()
    elementCheck = bindArg.element.is(':checked')
    bindArg.element.prop 'checked', vmValue if elementCheck isnt vmValue

addBinding
  name: 'check'
  selector: 'input[type=radio]'
  events:
    'change': (bindArg) ->
      checked = bindArg.element.is(':checked')
      bindArg.setVmValue checked
      rawElement = bindArg.element[0]
      if checked and name = rawElement.name
        bindArg.templateInstance.$("input[type=radio][name=#{name}]").each ->
          $(this).trigger('change') if rawElement isnt this
      return

  autorun: (bindArg) ->
    vmValue = bindArg.getVmValue()
    elementCheck = bindArg.element.is(':checked')
    bindArg.element.prop 'checked', vmValue if elementCheck isnt vmValue

addBinding
  name: 'group'
  selector: 'input[type=checkbox]'
  events:
    'change': (bindArg) ->
      vmValue = bindArg.getVmValue()
      elementValue = bindArg.element.val()
      if bindArg.element.is(':checked')
        vmValue.push elementValue if elementValue not in vmValue
      else
        vmValue.remove elementValue

  autorun: (bindArg) ->
    vmValue = bindArg.getVmValue()
    elementCheck = bindArg.element.is(':checked')
    elementValue = bindArg.element.val()
    newValue = elementValue in vmValue
    bindArg.element.prop 'checked', newValue if elementCheck isnt newValue

addBinding
  name: 'group'
  selector: 'input[type=radio]'
  events:
    'change': (bindArg) ->
      checked = bindArg.element.is(':checked')
      if checked
        bindArg.setVmValue bindArg.element.val()
        rawElement = bindArg.element[0]
        if name = rawElement.name
          bindArg.templateInstance.$("input[type=radio][name=#{name}]").each ->
            $(this).trigger('change') if rawElement isnt this
      return

  autorun: (bindArg) ->
    vmValue = bindArg.getVmValue()
    elementValue = bindArg.element.val()
    bindArg.element.prop 'checked', vmValue is elementValue

addBinding
  name: 'class'
  bindIf: (bindArg) -> _.isString(bindArg.bindValue)
  bind: (bindArg) ->
    bindArg.prevValue = ''
  autorun: (bindArg) ->
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
  priority: 2
  bindIf: (bindArg) -> _.isString(bindArg.bindValue) and bindArg.bindValue.charAt(0) is '['
  autorun: (bindArg) ->
    itemString = bindArg.bindValue.substr(1, bindArg.bindValue.length - 2)
    items = itemString.split(',')
    for item in items
      value = bindArg.getVmValue($.trim(item))
      bindArg.element.css value
    return

addBinding
  name: 'style'
  bindIf: (bindArg) -> _.isString(bindArg.bindValue)
  autorun: (bindArg) ->
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

addBinding
  name: 'hover'
  bind: (bindArg) ->
    setBool = (val) ->
      return -> bindArg.setVmValue(val)
    bindArg.element.hover setBool(true), setBool(false)
    return

addBinding
  name: 'focus'
  events:
    focus: (bindArg) ->
      bindArg.setVmValue(true) if not bindArg.getVmValue()
      return
    blur: (bindArg) ->
      bindArg.setVmValue(false) if bindArg.getVmValue()
      return
  autorun: (bindArg) ->
    value = bindArg.getVmValue()
    if bindArg.element.is(':focus') isnt value
      if value
        bindArg.element.focus()
      else
        bindArg.element.blur()
    return

enable = (elem) ->
  if elem.is('button') or elem.is('input') or elem.is('textarea')
    elem.removeAttr('disabled')
  else
    elem.removeClass('disabled')

disable = (elem) ->
  if elem.is('button') or elem.is('input') or elem.is('textarea')
    elem.attr('disabled', 'disabled')
  else
    elem.addClass('disabled')

enableDisable = (reverse) ->
  (bindArg) ->
    isEnable = bindArg.getVmValue()
    isEnable = !isEnable if reverse
    if isEnable
      enable bindArg.element
    else
      disable bindArg.element

addBinding
  name: 'enable'
  autorun: enableDisable(false)

addBinding
  name: 'disable'
  autorun: enableDisable(true)

addBinding
  name: 'options'
  selector: 'select:not([multiple])'
  autorun: (bindArg) ->
    optionsText = bindArg.elementBind.optionsText
    optionsValue = bindArg.elementBind.optionsValue
    selection = bindArg.getVmValue(bindArg.elementBind.value)
    bindArg.element.find('option').remove()
    defaultText = bindArg.elementBind.defaultText
    defaultValue = bindArg.elementBind.defaultValue
    if defaultText? or defaultValue?
      itemText = _.escape(defaultText? and bindArg.getVmValue(defaultText) or '')
      itemValue = _.escape(defaultValue? and bindArg.getVmValue(defaultValue) or '')
      bindArg.element.append("<option selected='selected' value=\"#{itemValue}\">#{itemText}</option>")
    source = bindArg.getVmValue()
    collection = if source instanceof Mongo.Cursor then source.fetch() else source
    for item in collection
      itemText = _.escape(if optionsText then item[optionsText] else item)
      itemValue = _.escape(if optionsValue then item[optionsValue] else item)
      selected = if selection is itemValue then "selected='selected'" else ""
      bindArg.element.append("<option #{selected} value=\"#{itemValue}\">#{itemText}</option>")
    return

addBinding
  name: 'options'
  selector: 'select[multiple]'
  autorun: (bindArg) ->
    optionsText = bindArg.elementBind.optionsText
    optionsValue = bindArg.elementBind.optionsValue
    selection = bindArg.getVmValue(bindArg.elementBind.value)
    bindArg.element.find('option').remove()
    source = bindArg.getVmValue()
    collection = if source instanceof Mongo.Cursor then source.fetch() else source
    for item in collection
      itemText = _.escape(if optionsText then item[optionsText] else item)
      itemValue = _.escape(if optionsValue then item[optionsValue] else item)
      selected = if itemValue in selection then "selected='selected'" else ""
      bindArg.element.append("<option #{selected} value=\"#{itemValue}\">#{itemText}</option>")
    return

addBinding
  name: 'value'
  selector: 'select[multiple]'
  events:
    change: (bindArg) ->
      elementValues = bindArg.element.val()
      selected = bindArg.getVmValue()
      if isArray(selected)
        selected.clear()
        if isArray(elementValues)
          selected.push v for v in elementValues
      return

addBinding
  name: 'ref'
  bind: (bindArg) ->
    bindArg.viewmodel[bindArg.bindValue] = bindArg.element
    return

addBinding
  name: 'value'
  selector: 'input[type=file]:not([multiple])'
  events:
    change: (bindArg, event) ->
      file = if event.target.files?.length then event.target.files[0] else null
      bindArg.setVmValue(file)
      return

addBinding
  name: 'value'
  selector: 'input[type=file][multiple]'
  events:
    change: (bindArg, event) ->
      files = bindArg.getVmValue()
      files.clear()
      files.push(file) for file in event.target.files
