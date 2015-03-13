class ViewModel
  bindingToken = RegExp("\"(?:[^\"\\\\]|\\\\.)*\"|'(?:[^'\\\\]|\\\\.)*'|/(?:[^/\\\\]|\\\\.)*/w*|[^\\s:,/][^,\"'{}()/:[\\]]*[^\\s,\"'{}()/:[\\]]|[^\\s]","g")
  divisionLookBehind = /[\])"'A-Za-z0-9_$]+$/
  keywordRegexLookBehind =
    in: 1
    return: 1
    typeof: 1

  @all = new ReactiveArray()
  @byId = (id) ->
    for vm in @all
      return vm.vm if vm.id is id
    undefined

  @byTemplate = (template) ->
    (vm.vm for vm in @all when vm.template is template)

  parseBind = (objectLiteralString) ->
    str = $.trim(objectLiteralString)
    str = str.slice(1, -1) if str.charCodeAt(0) is 123
    result = {}
    toks = str.match(bindingToken)
    depth = 0
    key = undefined
    values = undefined
    if toks
      toks.push ','
      i = -1
      tok = undefined
      while tok = toks[++i]
        c = tok.charCodeAt(0)
        if c is 44
          if depth <= 0
            if key
              unless values
                result['unknown'] = key
              else
                v = values.join ''
                v = parseBind(v) if v.indexOf('{') is 0
                result[key] = v
            key = values = depth = 0
            continue
        else if c is 58
          unless values
            continue
        else if c is 47 and i and tok.length > 1
          match = toks[i-1].match(divisionLookBehind)
          if match and not keywordRegexLookBehind[match[0]]
            str = str.substr(str.indexOf(tok) + 1)
            toks = str.match(bindingToken)
            toks.push(',')
            i = -1
            tok = '/'
        else if c in [40, 123, 91]
          ++depth
        else if c in [41, 125, 93]
          --depth
        else if not key and not values
          key = (if (c is 34 or c is 39) then tok.slice(1, -1) else tok)
          continue

        if values
          values.push tok
        else
          values = [tok]
    result

  isObject = (obj) -> Object.prototype.toString.call(obj) is '[object Object]'
  isString = (obj) -> obj instanceof String
  isArray = (obj) -> obj instanceof Array
  isElement = (o) -> (if typeof HTMLElement is "object" then o instanceof HTMLElement else o and typeof o is "object" and o isnt null and o.nodeType is 1 and typeof o.nodeName is "string")

  delayed = { }
  delay = (time, nameOrFunc, fn) ->
    func = fn || nameOrFunc
    name = nameOrFunc if fn
    d = delayed[name] if name
    Meteor.clearTimeout d if d?
    id = Meteor.setTimeout func, time
    delayed[name] = id if name

  binds = {}
  @hasBind = (bindName) -> binds[bindName]?
  @addBind = (bindName, func) -> binds[bindName] = func

  @addBind 'default', (p) ->
    if p.property.indexOf('(') > 0
      arr = p.property.split(/[(,)]/)
      name = arr[0]
      p.element.bind p.bindName, -> p.vm[name].apply p.vm, (eval(par) for par in arr.slice(1, arr.length - 1))
    else
      p.element.bind p.bindName, (e) -> getProperty p.vm, p.property, e

  @addBind 'value', (p) ->
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
      if isInput and not delayed[delayName + "X"]
        p.vm._vm_delayed[p.property] newValue if p.vm._vm_delayed[p.property]() isnt newValue

    if isInput
      p.vm._vm_addDelayedProperty p.property, p.vm[p.property](), p.vm

    p.element.bind "cut paste keypress input change", (ev) ->
      delay delayTime, delayName, ->
        newValue = p.element.val()
        p.vm[p.property] newValue if p.vm[p.property]() isnt newValue
        if isInput
          delay 500, delayName + "X", ->
            p.vm._vm_delayed[p.property] newValue if p.vm._vm_delayed[p.property]() isnt newValue
      delay 1, ->
        if p.elementBind.returnKey and 13 in [ev.which, ev.keyCode]
          if isInput
            newValue = p.element.val()
            p.vm._vm_delayed[p.property] newValue if p.vm._vm_delayed[p.property]() isnt newValue
          p.vm[p.elementBind.returnKey]()
      if p.elementBind.returnKey and 13 in [ev.which, ev.keyCode]
        ev.preventDefault()

  @addBind 'options', (p) ->
    if not p.element.is "select"
      throw new Error "The options bind can only be used with SELECT elements."
    if p.elementBind['value']
      value = getProperty p.vm, p.elementBind['value']
      if isArray value
        if not p.element.prop('multiple')
          throw new Error "Can't use an array value for single selection options."
      else
        if p.element.prop('multiple')
          throw new Error "Must use an array value for multiple selection options."

    p.autorun ->
      arr = p.vm[p.property]().array()
      p.element.find('option').remove()
      value = getProperty p.vm, p.elementBind['value']
      for o in arr
        selected = if value is o then "selected='selected'" else ""
        p.element.append("<option #{selected} value=\"#{o.replace(/&quot;/g, "&amp;quot;").replace(/\"/g, "&quot;") }\">#{o}</option>")

  @addBind 'checked', (p) ->
    p.autorun ->
      if isArray(p.vm[p.property]())
        p.element.prop 'checked', p.element.val() in p.vm[p.property]()
      else
        if p.element.attr('type') is 'checkbox'
          p.element.prop 'checked', p.vm[p.property]() if p.element.is(':checked') isnt p.vm[p.property]()
        else
          p.element.prop 'checked', p.vm[p.property]() is p.element.val() if p.element.is(':checked') isnt  (p.vm[p.property]() is p.element.val())
    p.element.bind 'change', ->
      newValue = if p.element.attr('type') is 'checkbox' then p.element.is(':checked') else p.element.val()
      p.vm[p.property] newValue if p.vm[p.property]() isnt newValue

  @addBind 'focused', (p) ->
    p.autorun (c) ->
      v = p.vm[p.property]()
      if p.element.is(':focus') isnt v
        if p.vm[p.property]()
          p.element.focus()
        else
          p.element.blur()
    p.element.focus -> p.vm[p.property] true if not p.vm[p.property]()
    p.element.focusout -> p.vm[p.property] false if p.vm[p.property]()

  getProperty = (vm, prop, e) ->
    return null if not prop
    if prop.charAt(0) is '!'
      negate = true
      prop = prop.substring 1

    if prop.indexOf('.') >= 0
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

  @addBind 'text', (p) ->
    p.autorun ->
      p.element.text getProperty p.vm, p.property

  @addBind 'html', (p) ->
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

  @addBind 'enabled', (p) ->
    p.autorun ->
      if getProperty p.vm, p.elementBind[p.bindName]
        enable p.element
      else
        disable p.element

  @addBind 'disabled', (p) ->
    p.autorun ->
      if getProperty p.vm, p.elementBind[p.bindName]
        disable p.element
      else
        enable p.element

  @addBind 'hover', (p) ->
    p.element.hover (-> p.vm[p.elementBind[p.bindName]] true), ->
      p.vm[p.elementBind[p.bindName]] false

  ifFunc = (p) ->
    p.autorun ->
      if getProperty p.vm, p.elementBind[p.bindName]
        p.element.show()
      else
        p.element.hide()

  @addBind 'if', ifFunc
  @addBind 'visible', ifFunc

  setClass = (cssClass, p) ->
    p.autorun ->
      if getProperty p.vm, p.property[cssClass]
        p.element.addClass cssClass
      else
        p.element.removeClass cssClass

  @addBind 'class', (p) ->
    if isObject p.property
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

  @addBind 'style', (p) ->
    if isObject p.property
      for style of p.property
        setStyle style, p
    else
      p.autorun ->
        style = getProperty p.vm, p.property
        style = parseBind(style) if not isObject style
        p.element.css style

  setAttr = (attr, p) ->
    p.autorun ->
      p.element.attr attr, p.vm[p.property[attr]]()

  @addBind 'attr', (p) ->
    for attr of p.property
      setAttr attr, p

  constructor: (p1, p2) ->

    templateBound = false
    @_vm_id = ''

    disposed = false
    @dispose = ->
      Session.set @_vm_id, undefined
      disposed = true
    self = this
    if p2
      @_vm_id = '_vm_' + p1

      delay 1, ->
        if Session.get(self._vm_id)
          self.fromJS Session.get(self._vm_id), false
        else
          Session.setDefault self._vm_id, self._vm_toJS() if not Session.get(self._vm_id)?
        Tracker.autorun (c) ->
          if disposed or templateBound
            c.stop()
          else
            Session.set self._vm_id, self._vm_toJS()


    obj = p2 || p1
    dependencies = {}
    values = {}
    initialValues = {}
    @_vm_properties = []
    dependenciesDelayed = {}
    valuesDelayed = {}
    @_vm_delayed = {}
    propertiesDelayed = []

    addRawProperty = (p, value, vm, values, dependencies) ->
      dep = dependencies[p] || (dependencies[p] = new Tracker.Dependency())
      vm[p] = (e) ->
        if isArray(e)
          values[p] = new ReactiveArray(e)
          dep.changed()
        else if arguments.length
          if isObject(values[p]) or values[p] isnt e
            values[p] = e
            dep.changed()
        else
          dep.depend()

        if values[p] instanceof ReactiveArray
          values[p].list()
        else
          values[p]
      if isArray(value)
        values[p] = new ReactiveArray(value)
      else
        values[p] = value

    addProperty = (p, value, vm) ->
      if not values[p]
        vm._vm_properties.push p
        initialValues[p] = value
        addRawProperty p, value, vm, values, dependencies

    @_vm_addDelayedProperty = (p, value, vm) ->
      if not valuesDelayed[p]
        propertiesDelayed.push p
        addRawProperty p, value, vm._vm_delayed, valuesDelayed, dependenciesDelayed

    addProperties = (propObj, that) ->
      for p of propObj
        value = propObj[p]
        if value instanceof Function
          that[p] = value
        else
          addProperty p, value, that

    if isObject(obj)
      addProperties obj, @

    addParent = (vm, template) ->
      parentView = template.view.parentView
      t = null
      while parentView
        t = parentView.templateInstance() if parentView.templateInstance
        break if t
        parentView = parentView.parentView
      vm.parent = ->
        return t._vm_instance if t._vm_instance
        for p of t
          if t[p] instanceof ViewModel
            t._vm_instance = t[p]
            return t._vm_instance
        return undefined

      template._vm_instance = vm

    @bind = (template) =>
      vm = @
      db = '[data-bind]:not([data-bound])'
      [container, dataBoundElements] = if isString(template)
        if Template[template]
          addParent vm, Template[template]
          [Template[template], Template[template].$(db)]
        else
          [$(template), $(template).find(db)]
      else if isElement(template)
        [$(template), $(template).find(db)]
      else if template instanceof jQuery
        [template, template.find(db)]
      else
        addParent vm, template
        [template, template.$(db)]

      vmForAll =
        vm: @
      if @_vm_id
        vmForAll.id = @_vm_id.substring("_vm_".length)

      if template instanceof Blaze.TemplateInstance
        vmForAll.template = template.view.name.substring("Template.".length)

      ViewModel.all.push vmForAll

      if container?.autorun
        container.autorun (c) ->
          templateBound = true
          js = self._vm_toJS()
          return if c.firstRun
          if disposed
            c.stop()
          else
            Session.set self._vm_id, js

      dataBoundElements.each ->
        element = $(this)
        elementBind = parseBind element.data('bind')
        element.attr "data-bound", true
        for bindName of elementBind
          bindFunc = binds[bindName] || binds.default
          bindFunc
            vm: vm
            element: element
            elementBind: elementBind
            bindName: bindName
            property: elementBind[bindName]
            container: container
            autorun: (f) ->
              fun = (c) ->
                if disposed
                  c.stop()
                else
                  f(c)
              if container.autorun
                container.autorun fun
              else
                Tracker.autorun fun
      @

    @extend = (newObj) =>
      addProperties newObj, @
      @

    _addHelper = (name, template, that) ->
      obj = {}
      obj[name] = -> that[name]()
      if template instanceof Blaze.Template
        template.helpers obj
      else if template instanceof Blaze.TemplateInstance
        template.view.template.helpers obj
      else
        Template[template].helpers obj

    @_vm_reservedWords = ['_vm_properties', '_vm_reservedWords','bind', 'extend', 'addHelper', 'addHelpers', 'toJS', 'fromJS', '_vm_id', 'dispose', 'reset', 'parent', '_vm_addDelayedProperty', '_vm_delayed', '_vm_toJS']

    @addHelper = (helper, template) ->
      _addHelper helper, template, @
      @
    @addHelpers = (p1, p2) =>
      if p2
        helpers = p1
        template = p2
        if helpers instanceof Array
          for p in helpers when p not in @_vm_reservedWords
            _addHelper p, template, @
        else
          _addHelper helpers, template, @
      else
        template = p1
        for p of @ when p not in @_vm_reservedWords
          _addHelper p, template, @
      @

    @_vm_toJS = (includeFunctions) =>
      ret = {}
      if includeFunctions
        for p of @ when p not in @_vm_reservedWords and p not in propertiesDelayed
          ret[p] = @[p]()
      else
        for p in self._vm_properties when p not in propertiesDelayed
          value = @[p]()
          if value instanceof ReactiveArray
            ret[p] = value.array()
          else
            ret[p] = value

      for p in propertiesDelayed
        ret[p] = this._vm_delayed[p]()
      ret

    @toJS = (includeFunctions) =>
      ret = {}
      if includeFunctions
        for p of @ when p not in @_vm_reservedWords
          ret[p] = @[p]()
      else
        for p in self._vm_properties
          value = @[p]()
          if value instanceof ReactiveArray
            ret[p] = value.array()
          else
            ret[p] = value
      ret

    @fromJS = (obj) =>
      for p of values when typeof obj[p] isnt "undefined"
        value = obj[p]
        if value instanceof Array
          values[p] = new ReactiveArray(value)
        else
          values[p] = value
          valuesDelayed[p] = obj[p]

      for p of values
        dependencies[p].changed()
        dependenciesDelayed[p].changed() if dependenciesDelayed[p]
      @

    @reset = ->
      for p in self._vm_properties
        values[p] = initialValues[p]
        valuesDelayed[p] = initialValues[p]

      for p of values
        dependencies[p].changed()
        dependenciesDelayed[p].changed() if dependenciesDelayed[p]
      @