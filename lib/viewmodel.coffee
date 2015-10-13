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
    # The following function will run when the template is created
    return ->
      templateInstance = this
      vm = template.createViewModel(templateInstance.data)
      templateInstance.viewmodel = vm
      vm.templateInstance = templateInstance
      helpers = {}
      for prop of vm when not ViewModel.reserved[prop]
        do (prop) ->
          helpers[prop] = -> vm[prop]()

      template.helpers helpers
      return

  @bindIdAttribute = 'b-id'
  @viewPrefix = 't-'

  @addEmptyViewModel = (templateInstance) ->
    template = templateInstance.view.template
    template.viewmodel({})
    onCreated = ViewModel.onCreated(template)
    onCreated.call templateInstance
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

  @makeReactiveProperty = (initial) ->
    dependency = new Tracker.Dependency()
    initialValue = if _.isArray(initial) then new ReactiveArray(initial, dependency) else initial
    _value = initialValue
    funProp = (value) ->
      if arguments.length
        if _value isnt value
          _value = value
          dependency.changed()
      else
        dependency.depend()
      return _value;
    funProp.reset = ->
      if _value instanceof ReactiveArray
        _value = new ReactiveArray(initial, dependency)
      else
        _value = initialValue
    funProp.depend = -> dependency.depend()
    funProp.changed = -> dependency.changed()
    return funProp

  @bindings = {}
  @addBinding = (binding) ->
    ViewModel.check "@addBinding", binding
    binding.priority = 1
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
      if bindingArray.length is 1
        binding = bindingArray[0]
      else
        binding = _.find(_.sortBy(bindingArray, ((b)-> -b.priority)), (b) ->
          not ( (b.bindIf and not b.bindIf(bindArg)) or (b.selector and not bindArg.element.is(b.selector)) )
        )
    return binding or ViewModel.getBinding('default', bindArg, bindings)

  @getBindArgument = (templateInstance, element, bindName, bindValue, bindObject, viewmodel) ->
    bindArg =
      templateInstance: templateInstance
      autorun: (f) ->
        fun = (c) -> f(c, bindArg)
        templateInstance.autorun fun
        return
      element: element
      elementBind: bindObject
      getVmValue: ViewModel.getVmValueGetter(viewmodel, bindValue)
      setVmValue: ViewModel.getVmValueSetter(viewmodel, bindValue)
      bindName: bindName
      bindValue: bindValue
      viewmodel: viewmodel
    return bindArg

  @bindSingle = (templateInstance, element, bindName, bindValue, bindObject, viewmodel, bindings) ->
    bindArg = ViewModel.getBindArgument templateInstance, element, bindName, bindValue, bindObject, viewmodel
    binding = ViewModel.getBinding(bindName, bindArg, bindings)
    return if not binding

    if binding.autorun
      bindArg.autorun binding.autorun

    if binding.bind
      binding.bind bindArg

    if binding.events
      for eventName, eventFunc of binding.events
        element.bind eventName, (e) -> eventFunc(e, bindArg)
    return

  quoted = (str) -> str.charAt(0) is '"' or str.charAt(0) is "'"
  removeQuotes = (str) -> str.substr(1, str.length - 2)
  getPrimitive = (val) ->
    switch val
      when "true" then true
      when "false" then false
      when "null" then null
      when "undefined" then undefined
      else (if $.isNumeric(val) then parseFloat(val) else val)

  tokens =
    ' + ': (a, b) -> a + b
    ' - ': (a, b) -> a - b
    ' * ': (a, b) -> a * b
    ' / ': (a, b) -> a / b
    ' && ': (a, b) -> a && b
    ' || ': (a, b) -> a || b
    ' == ': (a, b) -> `a == b`
    ' === ': (a, b) -> a is b
    ' !== ': (a, b) -> `a !== b`
    ' !=== ': (a, b) -> a isnt b
    ' > ': (a, b) -> a > b
    ' >= ': (a, b) -> a >= b
    ' < ': (a, b) -> a < b
    ' <= ': (a, b) -> a <= b

  tokenRegex = /[\+\-\*\/&\|=><]/
  dotRegex = /(\D\.)|(\.\D)/

  getToken = (str) ->
    for token of tokens
      return token if ~str.indexOf(token)
    return null

  getValue = (container, bindValue, viewmodel) ->
    negate = bindValue.charAt(0) is '!'
    bindValue = bindValue.substring 1 if negate
    token = tokenRegex.test(bindValue) and getToken(bindValue)
    if token
      i = bindValue.indexOf(token)
      left = getValue(container, bindValue.substring(0, i), viewmodel)
      right = getValue(container, bindValue.substring(i + token.length), viewmodel)
      value = tokens[token]( left, right )
    else if dotRegex.test(bindValue)
      i = bindValue.search(dotRegex)
      i += 1 if bindValue.charAt(i) isnt '.'
      newContainer = getValue container, bindValue.substring(0, i), viewmodel
      newBindValue = bindValue.substring(i + 1)
      value = getValue newContainer, newBindValue, viewmodel
    else
      name = bindValue
      args = []
      if ~bindValue.indexOf('(')
        parsed = ViewModel.parseBind(bindValue)
        name = Object.keys(parsed)[0]
        if parsed[name].length > 2
          for arg in parsed[name].substr(1, parsed[name].length - 2).split(',') #remove parenthesis
            newArg = undefined
            if arg is "this"
              newArg = Template.instance().data
            else if quoted(arg)
              newArg = removeQuotes(arg)
            else
              neg = arg.charAt(0) is '!'
              arg = arg.substring 1 if neg
              if viewmodel[arg]
                newArg = getValue(viewmodel, arg, viewmodel)
              else
                newArg = getPrimitive(arg)
              newArg = !newArg if neg
            args.push newArg

      if _.isFunction(container[name])
        value = container[name].apply(undefined, args)
      else
        if container is viewmodel
          ViewModel.check 'vmProp', name, viewmodel
        value = container[name]

    return if negate then !value else value

  @getVmValueGetter = (viewmodel, bindValue) ->
    return  -> getValue(viewmodel, bindValue, viewmodel)

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

  @getVmValueSetter = (viewmodel, bindValue) ->
    return  (value) -> setValue(value, viewmodel, bindValue, viewmodel)



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

  #############
  # Constructor

  constructor: (initial) ->
    viewmodel = this
    viewmodel.extend(initial)

  ############
  # Not Tested

  @onRendered = ->
    # The following function will run when the template is rendered
    return ->
      templateInstance = this
      ViewModel.check 'T#onRendered', templateInstance
