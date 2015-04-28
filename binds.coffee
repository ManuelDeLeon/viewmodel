getProperty = (vm, prop, e) ->
  return null if not prop

  if ~prop.indexOf(" && ")
    props = prop.split(' && ')
    for nProp in props
      return false if !getProperty(vm, nProp, e)
    return true
  else if ~prop.indexOf(" || ")
    props = prop.split(' || ')
    for nProp in props
      return true if getProperty(vm, nProp, e)
    return false
  else
    if prop.charAt(0) is '!'
      negate = true
      prop = prop.substring 1

    if ~prop.indexOf('.')
      funcs = prop.split('.')
      if e
        propToUse = vm[funcs[0]](e)
      else
        propToUse = vm[funcs[0]]()
      if propToUse
        gotIt = true
        for i in [1..(funcs.length - 2)] by 1
          gotIt = false
          break if not propToUse[funcs[i]]
          if e
            propToUse = propToUse[funcs[i]](e)
          else
          propToUse = propToUse[funcs[i]]()
          gotIt = true
        ret = propToUse[funcs[funcs.length - 1]] if gotIt
      else
        ret = undefined
    else
      if prop.indexOf('(') > 0
        arr = prop.split(/[(,)]/)
        name = arr[0]
        ret = vm[name].apply vm, (eval(par) for par in arr.slice(1, arr.length - 1))
      else
        if e
          ret = vm[prop](e)
        else
          ret = vm[prop]()

    if negate then not ret else ret

ViewModel.addBind 'default', (p) ->
  if p.property.indexOf('(') > 0
    arr = p.property.split(/[(,)]/)
    name = arr[0]
    p.element.bind p.bindName, -> p.vm[name].apply p.vm, (eval(par) for par in arr.slice(1, arr.length - 1))
  else
    p.element.bind p.bindName, (e) -> getProperty p.vm, p.property, e

ViewModel.addBind 'value', (p) ->
  delayTime = p.elementBind['delay'] or 1
  delayName = p.vm._vm_id + '_' + p.bindName + "_" + p.property
  isSelect = p.element.is "select"
  isMultiple = p.element.prop('multiple')
  isInput = p.element.is("input")
  p.autorun (c) ->
    newValue = getProperty p.vm, p.property
    if isSelect and isMultiple
      p.element.find("option").each ->
        $(this).attr "selected", this.value in newValue
    else if p.element.val() isnt newValue
      p.element.val newValue

    return if c.firstRun
    if isInput and not Helper.delayed[delayName + "X"]
      p.vm._vm_delayed[p.property] newValue if p.vm._vm_delayed[p.property]() isnt newValue

  if isInput
    p.vm._vm_addDelayedProperty p.property, getProperty(p.vm, p.property), p.vm

  p.element.bind "cut paste keypress input change", (ev) ->
    Helper.delay delayTime, delayName, ->
      newValue = p.element.val()
      p.vm[p.property] newValue if getProperty(p.vm, p.property, ev) isnt newValue
      if isInput
        Helper.delay 500, delayName + "X", ->
          p.vm._vm_delayed[p.property] newValue if p.vm._vm_delayed[p.property]() isnt newValue
    Helper.delay 1, ->
      if p.elementBind.returnKey and 13 in [ev.which, ev.keyCode]
        if isInput
          newValue = p.element.val()
          p.vm._vm_delayed[p.property] newValue if p.vm._vm_delayed[p.property]() isnt newValue
        p.vm[p.elementBind.returnKey]()
    if p.elementBind.returnKey and 13 in [ev.which, ev.keyCode]
      ev.preventDefault()

ViewModel.addBind 'options', (p) ->
  if not p.element.is "select"
    throw new Error "The options bind can only be used with SELECT elements."
  if p.elementBind['value']
    value = getProperty p.vm, p.elementBind['value']
    if Helper.isArray value
      if not p.element.prop('multiple')
        throw new Error "Can't use an array value for single selection options."
    else
      if p.element.prop('multiple')
        throw new Error "Must use an array value for multiple selection options."

  p.autorun ->
    arr = getProperty(p.vm, p.property).array()
    p.element.find('option').remove()
    value = getProperty p.vm, p.elementBind['value']
    for o in arr
      selected = if value is o then "selected='selected'" else ""
      p.element.append("<option #{selected} value=\"#{o.replace(/&quot;/g, "&amp;quot;").replace(/\"/g, "&quot;") }\">#{o}</option>")

ViewModel.addBind 'checked', (p) ->
  p.autorun ->
    val = getProperty(p.vm, p.property)
    if Helper.isArray val
      p.element.prop 'checked', p.element.val() in val
    else
      if p.element.attr('type') is 'checkbox'
        p.element.prop 'checked', val if p.element.is(':checked') isnt val
      else
        p.element.prop 'checked', val is p.element.val() if p.element.is(':checked') isnt  (val is p.element.val())
  p.element.bind 'change', ->
    val = getProperty(p.vm, p.property)
    if Helper.isArray val
      if p.element.is(':checked')
        val.push p.element.val() if newValue not in val
      else
        val.remove p.element.val()
    else
      newValue = if p.element.attr('type') is 'checkbox' then p.element.is(':checked') else p.element.val()
      p.vm[p.property] newValue if val isnt newValue

ViewModel.addBind 'change', (p) ->
  propWithValue = p.elementBind.value or p.elementBind.checked or p.elementBind.text or p.elementBind.focused
  if propWithValue
    p.autorun (c) ->
      p.vm[propWithValue]()
      p.vm[p.elementBind.change]() if not c.firstRun

ViewModel.addBind 'focused', (p) ->
  p.autorun (c) ->
    v = getProperty(p.vm, p.property)
    if p.element.is(':focus') isnt v
      if v
        p.element.focus()
      else
        p.element.blur()
  p.element.focus -> p.vm[p.property] true if not getProperty(p.vm, p.property)
  p.element.focusout -> p.vm[p.property] false if getProperty(p.vm, p.property)

ViewModel.addBind 'text', (p) ->
  p.autorun ->
    p.element.text getProperty p.vm, p.property

ViewModel.addBind 'html', (p) ->
  p.autorun -> p.element.html getProperty p.vm, p.property

enable = (elem) ->
  if elem.is('button') or elem.is('input')
    elem.removeAttr('disabled')
  else
    elem.removeClass('disabled')

disable = (elem) ->
  if elem.is('button') or elem.is('input')
    elem.attr('disabled', 'disabled')
  else
    elem.addClass('disabled')

ViewModel.addBind 'enabled', (p) ->
  p.autorun ->
    if getProperty p.vm, p.elementBind[p.bindName]
      enable p.element
    else
      disable p.element

ViewModel.addBind 'disabled', (p) ->
  p.autorun ->
    if getProperty p.vm, p.elementBind[p.bindName]
      disable p.element
    else
      enable p.element

ViewModel.addBind 'hover', (p) ->
  p.element.hover (-> p.vm[p.elementBind[p.bindName]] true), ->
    p.vm[p.elementBind[p.bindName]] false

ifFunc = (p) ->
  p.autorun ->
    if getProperty p.vm, p.elementBind[p.bindName]
      p.element.show()
    else
      p.element.hide()

ViewModel.addBind 'if', ifFunc
ViewModel.addBind 'visible', ifFunc

unlessFunc = (p) ->
  p.autorun ->
    if getProperty p.vm, p.elementBind[p.bindName]
      p.element.hide()
    else
      p.element.show()
ViewModel.addBind 'unless', unlessFunc
ViewModel.addBind 'hidden', unlessFunc

setClass = (cssClass, p) ->
  p.autorun ->
    if getProperty p.vm, p.property[cssClass]
      p.element.addClass cssClass
    else
      p.element.removeClass cssClass

ViewModel.addBind 'class', (p) ->
  if Helper.isObject p.property
    for cssClass of p.property
      setClass cssClass, p
  else
    prevValue = ''
    p.autorun ->
      cssClass = getProperty p.vm, p.property
      p.element.removeClass prevValue
      p.element.addClass cssClass
      prevValue = cssClass

setStyle = (style, p) ->
  p.autorun ->
    p.element.css style, p.vm[p.property[style]]()

ViewModel.addBind 'style', (p) ->
  if Helper.isObject p.property
    for style of p.property
      setStyle style, p
  else
    p.autorun ->
      style = getProperty p.vm, p.property
      style = Helper.parseBind(style) if not Helper.isObject style
      p.element.css style

setAttr = (attr, p) ->
  p.autorun ->
    p.element.attr attr, p.vm[p.property[attr]]()

ViewModel.addBind 'attr', (p) ->
  for attr of p.property
    setAttr attr, p
