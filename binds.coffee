setProperty = (vm, prop, value) ->
  return null if not prop
  if ~prop.indexOf('.')
    funcs = prop.split('.')
    propToUse = vm[funcs[0]]()
    for i in [1..(funcs.length - 2)] by 1
      propToUse = propToUse[funcs[i]]()
    propToUse[funcs[funcs.length - 1]] value
  else
    vm[prop] value

  return

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
    negate = false
    if prop.charAt(0) is '!'
      negate = true
      prop = prop.substring 1
    ret = undefined
    if ~prop.indexOf('.')
      funcs = prop.split('.')
      propToUse = null
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
        if not _.has(vm, prop)
          if Meteor.isDev
            console.log "Property '#{prop}' not found on view model:"
            console.log vm
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
  delayTime = p.elementBind['delay'] or 0
  delayName = p.vm._vm_id + '_' + p.bindName + "_" + p.property
  isSelect = p.element.is "select"
  isMultiple = p.element.prop('multiple')
  isInput = p.element.is("input")
  p.autorun (c) ->
    newValue = getProperty p.vm, p.property
    newValue = newValue() if _.isFunction(newValue)
    if isSelect and isMultiple
      p.element.find("option").each ->
        $(this).attr "selected", this.value in newValue
    else if p.element.val() isnt newValue
      p.element.val newValue
    p.element.trigger 'changed'

    return if c.firstRun
    if isInput and not VmHelper.delayed[delayName + "X"]
      p.vm._vm_delayed[p.property] newValue if p.vm._vm_delayed[p.property]() isnt newValue

  if isInput
    p.vm._vm_addDelayedProperty p.property, getProperty(p.vm, p.property), p.vm

  p.element.bind "cut paste keyup input change", (ev) ->
    f = ->
      newValue = p.element.val()
      currentValue = getProperty(p.vm, p.property)
      if isSelect and isMultiple
        if VmHelper.isArray(currentValue) and VmHelper.isArray(newValue) and not VmHelper.arraysAreEqual(currentValue, newValue)
          VmHelper.delay 0, ->
            currentValue.pause()
            currentValue.clear()
            currentValue.push v for v in newValue
            currentValue.resume()
      else
        setProperty(p.vm, p.property, newValue) if currentValue isnt newValue

      if isInput
        VmHelper.delay 500, delayName + "X", ->
          p.vm._vm_delayed[p.property] newValue if p.vm._vm_delayed[p.property]() isnt newValue

    if delayTime
      VmHelper.delay delayTime, delayName, f
    else
      f()

    VmHelper.delay 1, ->
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
    if VmHelper.isArray value
      if not p.element.prop('multiple')
        throw new Error "Can't use an array value for single selection options."
    else
      if p.element.prop('multiple')
        throw new Error "Must use an array value for multiple selection options."

  p.autorun ->
    arr = getProperty(p.vm, p.property)
    arr = arr.fetch() if arr instanceof Mongo.Cursor
    p.element.find('option').remove()
    value = getProperty p.vm, p.elementBind['value']
    optionsText = p.elementBind['optionsText']
    optionsValue = p.elementBind['optionsValue']
    optionsCaption = p.elementBind['optionsCaption']
    if optionsCaption
      caption = ''
      if optionsCaption[0] is "'" or optionsCaption[0] is '"'
        caption = optionsCaption.substring(1, optionsCaption.length - 1)
      else
        caption = getProperty(p.vm, optionsCaption)
      p.element.append("<option value='' selected='selected'>#{_.escape(caption)}</option>")

    isMultiple = p.element.prop('multiple')
    for o in arr
      text = _.escape(if optionsText then o[optionsText] else o)
      oValue = _.escape(if optionsValue then o[optionsValue] else o)
      if isMultiple
        if value
          selected = if oValue in value then "selected='selected'" else ""
        else
          console.log "value binding is required for options binding on select multiple."
      else
        selected = if value is oValue then "selected='selected'" else ""
      p.element.append("<option #{selected} value=\"#{oValue}\">#{text}</option>")

ViewModel.addBind 'checked', (p) ->
  p.autorun ->
    val = getProperty(p.vm, p.property)
    if VmHelper.isArray val
      p.element.prop 'checked', p.element.val() in val
    else
      if p.element.attr('type') is 'checkbox'
        p.element.prop 'checked', val if p.element.is(':checked') isnt val
      else
        p.element.prop 'checked', val is p.element.val() if p.element.is(':checked') isnt  (val is p.element.val())
  p.element.bind 'changed', ->
    val = getProperty(p.vm, p.property)
    if VmHelper.isArray val
      if p.element.is(':checked')
        val.push p.element.val() if newValue not in val
      else
        val.remove p.element.val()
    else
      newValue = if p.element.attr('type') is 'checkbox' then p.element.is(':checked') else p.element.val()
      setProperty(p.vm, p.property, newValue) if val isnt newValue

ViewModel.addBind 'changed', (p) ->
  propToFunc = {}
  if _.isObject(p.elementBind.changed)
    propToFunc = p.elementBind.changed
  else
    b = p.elementBind
    propWithValue = b.value or b.checked or b.text or b.focused or b.hover
    if propWithValue
      propToFunc[propWithValue] = p.elementBind.changed

  if _.size(propToFunc)
    for prop of propToFunc
      func = propToFunc[prop]
      do (prop, func) ->
        p.autorun (c) ->
          newValue = p.vm[prop]()
          p.vm[func](newValue) if not c.firstRun
  else
    ViewModel.binds.default(p)

ViewModel.addBind 'file', (p) ->
  p.element.bind 'changed', (e) ->
    file = if e.target.files?.length then e.target.files[0] else null
    setProperty(p.vm, p.property,  file)

ViewModel.addBind 'files', (p) ->
  p.element.bind 'changed', (e) ->
    prop = getProperty(p.vm, p.property)
    prop.clear()
    prop.push(f) for f in e.target.files

ViewModel.addBind 'focused', (p) ->
  p.autorun (c) ->
    v = getProperty(p.vm, p.property)
    if p.element.is(':focus') isnt v
      if v
        p.element.focus()
      else
        p.element.blur()
  p.element.focus -> setProperty(p.vm, p.property, true) if not getProperty(p.vm, p.property)
  p.element.focusout -> setProperty(p.vm, p.property, false) if getProperty(p.vm, p.property)

ViewModel.addBind 'text', (p) ->
  p.autorun ->
    p.element.text getProperty p.vm, p.property

ViewModel.addBind 'html', (p) ->
  p.autorun -> p.element.html getProperty p.vm, p.property

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
  if VmHelper.isObject p.property
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
  if VmHelper.isObject p.property
    for style of p.property
      setStyle style, p
  else
    p.autorun ->
      style = getProperty p.vm, p.property
      style = VmHelper.parseBind(style) if not VmHelper.isObject style
      p.element.css style

setAttr = (attr, prop, vm, p) ->
  p.autorun ->
    if not _.has(vm, prop)
      if Meteor.isDev
        console.log "Property '#{prop}' not found on view model:"
        console.log vm
    else
      p.element.attr attr, vm[prop]()

ViewModel.addBind 'attr', (p) ->
  for attr of p.property
    setAttr attr, p.property[attr], p.vm, p

for attr in ['src', 'href', 'readonly']
  do (attr) ->
    ViewModel.addBind attr, (p) -> setAttr( attr, p.property, p.vm, p )

ViewModel.addBind 'toggle', (p) ->
  p.element.bind 'click', ->
    prop = getProperty(p.vm, p.property)
    setProperty(p.vm, p.property, !prop)

ViewModel.addBind 'ref', (p) ->
  p.vm[p.property] = p.element