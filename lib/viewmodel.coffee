class ViewModel

  #@@@@@@@@@@@@@@
  # Class methods

  _nextId = 1
  @nextId = -> _nextId++

  @reserved =
    vmId: 1

  @check = (key, args...) ->
    if not ViewModel.ignoreErrors
      Package['manuel:viewmodel-debug']?.VmCheck key, args...
    return

  @onCreated = (template) ->
    return ->
      templateInstance = this
      viewmodel = template.createViewModel(templateInstance.data)

      templateInstance.viewmodel = viewmodel
      viewmodel.templateInstance = templateInstance

      Tracker.afterFlush ->
        templateInstance.autorun ->
          viewmodel.extend Template.currentData()
        ViewModel.assignChild(viewmodel)


      helpers = {}
      for prop of viewmodel when not ViewModel.reserved[prop]
        do (prop) ->
          helpers[prop] = -> viewmodel[prop]()

      template.helpers helpers
      return

  @bindIdAttribute = 'b-id'

  @addEmptyViewModel = (templateInstance) ->
    template = templateInstance.view.template
    template.viewmodelInitial = {}
    onCreated = ViewModel.onCreated(template)
    onCreated.call templateInstance
    onRendered = ViewModel.onRendered(template)
    onRendered.call templateInstance
    onDestroyed = ViewModel.onDestroyed(template)
    templateInstance.view.onViewDestroyed ->
      onDestroyed.call templateInstance
    return

  getBindHelper = (useBindings) ->
    return (bindString) ->
      bindId = ViewModel.nextId()
      bindObject = ViewModel.parseBind bindString

      templateInstance = Template.instance()

      if not templateInstance.viewmodel
        ViewModel.addEmptyViewModel(templateInstance)

      bindings = if useBindings then ViewModel.bindings else _.pick(ViewModel.bindings, 'default')
      Blaze.currentView.onViewReady ->
        element = templateInstance.$("[#{ViewModel.bindIdAttribute}='#{bindId}']")
        bindObject.view = this
        bindObject.bindId = bindId
        templateInstance.viewmodel.bind bindObject, templateInstance, element, bindings
        return

      bindIdObj = {}
      bindIdObj[ViewModel.bindIdAttribute] = bindId
      return bindIdObj

  @bindHelper = getBindHelper(true)
  @eventHelper = getBindHelper(false)

  @getInitialObject = (initial, context) ->
    if _.isFunction(initial)
      return initial(context)
    else
      return initial

  delayed = { }
  @delay = (time, nameOrFunc, fn) ->
    func = fn || nameOrFunc
    name = nameOrFunc if fn
    d = delayed[name] if name
    Meteor.clearTimeout d if d?
    id = Meteor.setTimeout func, time
    delayed[name] = id if name

  @makeReactiveProperty = (initial) ->
    dependency = new Tracker.Dependency()
    initialValue = if _.isArray(initial) then new ReactiveArray(initial, dependency) else initial
    _value = initialValue

    funProp = (value) ->
      if arguments.length
        if _value isnt value
          changeValue = ->
            _value = value
            dependency.changed()
          if funProp.delay > 0
            ViewModel.delay funProp.delay, funProp.id, changeValue
          else
            changeValue()

      else
        dependency.depend()
      return _value;
    funProp.reset = ->
      if _value instanceof ReactiveArray
        _value = new ReactiveArray(initial, dependency)
      else
        _value = initialValue
      dependency.changed()

    funProp.depend = -> dependency.depend()
    funProp.changed = -> dependency.changed()
    funProp.delay = 0
    funProp.id = ViewModel.nextId()


    return funProp

  @bindings = {}
  @addBinding = (binding) ->
    ViewModel.check "@addBinding", binding
    binding.priority = 1 if not binding.priority
    binding.priority++ if binding.selector
    binding.priority++ if binding.bindIf

    bindings = ViewModel.bindings
    if not bindings[binding.name]
      bindings[binding.name] = []
    bindingArray = bindings[binding.name]
    bindingArray[bindingArray.length] = binding
    return

  @getBinding = (bindName, bindArg, bindings) ->
    binding = null
    bindingArray = bindings[bindName]
    if bindingArray
      if bindingArray.length is 1 and not (bindingArray[0].bindIf or bindingArray[0].selector)
        binding = bindingArray[0]
      else
        binding = _.find(_.sortBy(bindingArray, ((b)-> -b.priority)), (b) ->
          not ( (b.bindIf and not b.bindIf(bindArg)) or (b.selector and not bindArg.element.is(b.selector)) )
        )
    return binding or ViewModel.getBinding('default', bindArg, bindings)

  getDelayedSetter = (bindArg, setter) ->
    if bindArg.elementBind.throttle
      return (args...) ->
        ViewModel.delay bindArg.getVmValue(bindArg.elementBind.throttle), bindArg.elementBind.bindId, -> setter(args...)
    else if bindArg.elementBind.delay
      return (args...) ->
        ViewModel.delay bindArg.getVmValue(bindArg.elementBind.delay), -> setter(args...)
    else
      return setter

  @getBindArgument = (templateInstance, element, bindName, bindValue, bindObject, viewmodel) ->
    bindArg =
      templateInstance: templateInstance
      autorun: (f) ->
        fun = (c) -> f(bindArg, c)
        templateInstance.autorun fun
        return
      element: element
      elementBind: bindObject
      getVmValue: ViewModel.getVmValueGetter(viewmodel, bindValue, bindObject.view)
      bindName: bindName
      bindValue: bindValue
      viewmodel: viewmodel

    bindArg.setVmValue = getDelayedSetter bindArg, ViewModel.getVmValueSetter(viewmodel, bindValue, bindObject.view)
    return bindArg

  @bindSingle = (templateInstance, element, bindName, bindValue, bindObject, viewmodel, bindings) ->
    bindArg = ViewModel.getBindArgument templateInstance, element, bindName, bindValue, bindObject, viewmodel
    binding = ViewModel.getBinding(bindName, bindArg, bindings)
    return if not binding

    if binding.bind
      binding.bind bindArg

    if binding.autorun
      bindArg.autorun binding.autorun

    if binding.events
      for eventName, eventFunc of binding.events
        do (eventName, eventFunc) ->
          element.bind eventName, (e) -> eventFunc(bindArg, e)
    return

  quoted = (str) -> str.charAt(0) is '"' or str.charAt(0) is "'"
  removeQuotes = (str) -> str.substr(1, str.length - 2)
  isPrimitive = (val) ->
    val is "true" or val is "false" or val is "null" or val is "undefined" or $.isNumeric(val)

  getPrimitive = (val) ->
    switch val
      when "true" then true
      when "false" then false
      when "null" then null
      when "undefined" then undefined
      else (if $.isNumeric(val) then parseFloat(val) else val)

  tokens =
    '+': (a, b) -> a + b
    '-': (a, b) -> a - b
    '*': (a, b) -> a * b
    '/': (a, b) -> a / b
    '&&': (a, b) -> a && b
    '||': (a, b) -> a || b
    '===': (a, b) -> a is b
    '==': (a, b) -> `a == b`
    '!===': (a, b) -> a isnt b
    '!==': (a, b) -> `a !== b`
    '>': (a, b) -> a > b
    '>=': (a, b) -> a >= b
    '<': (a, b) -> a < b
    '<=': (a, b) -> a <= b

  tokenRegex = /[\+\-\*\/&\|=><]/
  dotRegex = /(\D\.)|(\.\D)/
  spaceRegex = (token) ->
    t = token.split('').join('\\')
    new RegExp("(\\S\\#{t}\\s)|(\\s\\#{t}\\S)")

  spaceRegexMem = _.memoize spaceRegex

  getToken = (str) ->
    for token of tokens
      regex = spaceRegexMem(token)
      index = str.search(regex)
      index += 1 if ~index and str.charAt(index) isnt ' '
      if ~index
        return str.substr(index, token.length + 1)
    return null

  getMatchingParenIndex = (bindValue, parenIndexStart) ->
    return -1 if !~parenIndexStart
    openParenCount = 0
    for i in [parenIndexStart + 1 .. bindValue.length]
      currentChar = bindValue.charAt(i)
      if currentChar is ')'
        if openParenCount is 0
          return i
        else
          openParenCount--
      else if currentChar is '('
        openParenCount++

    throw new Error("Unbalanced parenthesis")
    return

  currentView = null
  currentContext = ->
    Template.instance()?.data or currentView?.dataVar?.curValue

  getValue = (container, bindValue, viewmodel) ->
    negate = bindValue.charAt(0) is '!'
    bindValue = bindValue.substring 1 if negate
    token = tokenRegex.test(bindValue) and getToken(bindValue)
    if token
      i = bindValue.indexOf(token)
      left = getValue(container, bindValue.substring(0, i), viewmodel)
      right = getValue(container, bindValue.substring(i + token.length), viewmodel)
      value = tokens[token.trim()]( left, right )
      return if negate then !value else value

    if bindValue is "this"
      value = currentContext()
    else if quoted(bindValue)
      value = removeQuotes(bindValue)
    else
      dotIndex = bindValue.search(dotRegex)
      dotIndex += 1 if ~dotIndex and bindValue.charAt(dotIndex) isnt '.'
      parenIndexStart = bindValue.indexOf('(')
      parenIndexEnd = getMatchingParenIndex(bindValue, parenIndexStart)

      breakOnFirstDot = ~dotIndex and (!~parenIndexStart or dotIndex < parenIndexStart or dotIndex is (parenIndexEnd + 1))

      if breakOnFirstDot
        newContainer = getValue container, bindValue.substring(0, dotIndex), viewmodel
        newBindValue = bindValue.substring(dotIndex + 1)
        value = getValue newContainer, newBindValue, viewmodel
      else
        name = bindValue
        args = []
        if ~parenIndexStart
          parsed = ViewModel.parseBind(bindValue)
          name = Object.keys(parsed)[0]
          second = parsed[name]
          if second.length > 2
            for arg in second.substr(1, second.length - 2).split(',') #remove parenthesis
              newArg = undefined
              if arg is "this"
                newArg = currentContext()
              else if quoted(arg)
                newArg = removeQuotes(arg)
              else
                neg = arg.charAt(0) is '!'
                arg = arg.substring 1 if neg

                arg = getValue(viewmodel, arg, viewmodel)
                if viewmodel and `arg in viewmodel`
                  newArg = getValue(viewmodel, arg, viewmodel)
                else
                  newArg = getPrimitive(arg)
                newArg = !newArg if neg
              args.push newArg

        primitive = isPrimitive(name)
        if container instanceof ViewModel and not primitive
          ViewModel.check 'vmProp', name, container

        if primitive or not (`name in container`)
          value = getPrimitive(name)
        else
          if _.isFunction(container[name])
            value = container[name].apply(container, args)
          else
            value = container[name]


    return if negate then !value else value

  @getVmValueGetter = (viewmodel, bindValue, view) ->
    return  (optBindValue = bindValue) ->
      currentView = view
      getValue(viewmodel, optBindValue.toString(), viewmodel)

  setValue = (value, container, bindValue, viewmodel) ->
    if dotRegex.test(bindValue)
      i = bindValue.search(dotRegex)
      i += 1 if bindValue.charAt(i) isnt '.'
      newContainer = getValue container, bindValue.substring(0, i), viewmodel
      newBindValue = bindValue.substring(i + 1)
      setValue value, newContainer, newBindValue, viewmodel
    else
      if _.isFunction(container[bindValue]) then container[bindValue](value) else container[bindValue] = value
    return

  @getVmValueSetter = (viewmodel, bindValue, view) ->
    return (->) if not _.isString(bindValue)
    if ~bindValue.indexOf(')', bindValue.length - 1)
      return ->
        currentView = view
        getValue(viewmodel, bindValue, view)
    else
      return (value) ->
        currentView = view
        setValue(value, viewmodel, bindValue, viewmodel)


  @parentTemplate = (templateInstance) ->
    view = templateInstance.view?.parentView
    while view
      if view.name.substring(0, 9) is 'Template.' or view.name is 'body'
        return view.templateInstance()
      view = view.parentView
    return

  @assignChild = (viewmodel) ->
    parentTemplateInstance = ViewModel.parentTemplate(viewmodel.templateInstance)
    while parentTemplateInstance and not parentTemplateInstance.viewmodel
      parentTemplateInstance = ViewModel.parentTemplate(parentTemplateInstance)

    parentTemplateInstance?.viewmodel.children().push(viewmodel)
    return

  ##################
  # Instance methods

  bind: (bindObject, templateInstance, element, bindings) ->
    viewmodel = this
    for bindName, bindValue of bindObject
      ViewModel.bindSingle templateInstance, element, bindName, bindValue, bindObject, viewmodel, bindings
    return

  extend: (obj) ->
    viewmodel = this
    for key, value of obj
      if _.isFunction(value)
        # we don't care, just take the new function
        viewmodel[key] = value
      else if viewmodel[key]
        # keep the reference to the old property we already have
        viewmodel[key] value
      else
        # Create a new property
        viewmodel[key] = ViewModel.makeReactiveProperty(value);
    return

  parent: (args...) ->
    ViewModel.check "#parent", args...
    viewmodel = this
    parentTemplate = ViewModel.parentTemplate(viewmodel.templateInstance)
    return parentTemplate.viewmodel

  reset: ->
    viewmodel = this
    viewmodel[prop].reset() for prop of viewmodel when _.isFunction(viewmodel[prop].reset)


  #############
  # Constructor

  childrenProperty = ->
    array = new ReactiveArray()
    funProp = (search) ->
      array.depend()
      if arguments.length
        ViewModel.check "#children", search
        predicate = if _.isString(search) then ((vm) -> ViewModel.templateName(vm.templateInstance) is search) else search
        return _.filter array, predicate
      else
        return array

    return funProp

  constructor: (initial) ->
    viewmodel = this
    viewmodel.vmId = ViewModel.nextId()
    viewmodel.extend(initial)
    @children = childrenProperty()


  ############
  # Not Tested

  @onRendered = ->
    return ->
      templateInstance = this
      if templateInstance.viewmodel.autorun
        fun = (c) -> templateInstance.viewmodel.autorun.apply(templateInstance.viewmodel, c)
        Tracker.afterFlush -> templateInstance.autorun fun

  @onDestroyed = ->
    return ->
      templateInstance = this
      viewmodel = templateInstance.viewmodel
      parent = viewmodel.parent()
      if parent
        children = parent.children()
        indexToRemove = -1
        for child in children
          indexToRemove++
          if child.vmId is viewmodel.vmId
            children.splice(indexToRemove, 1)
            break

  @templateName = (templateInstance) ->
    name = templateInstance.view.name
    if name is 'body' then name else name.substr(name.indexOf('.') + 1)

