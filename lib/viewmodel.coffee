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
    # The following function returned will run when the template is created
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
  @bindHelper = (bindString) ->

    bindId = ViewModel.nextId()
    bindObject = ViewModel.parseBind bindString

    templateInstance = Template.instance()
    bindings = ViewModel.bindings
    Blaze.currentView.onViewReady ->
      element = templateInstance.$("[#{ViewModel.bindIdAttribute}='#{bindId}']")
      templateInstance.viewmodel.bind bindObject, templateInstance, element, bindings
      return

    bindIdObj = {}
    bindIdObj[ViewModel.bindIdAttribute] = bindId
    return bindIdObj

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
  @addBinding = (args...) ->
    ViewModel.check "@addBinding", args...
    binding = args[0]
    binding.priority = 1
    binding.priority++ if binding.selector
    binding.priority++ if binding.bindIf

    if not @bindings[binding.name]
      @bindings[binding.name] = []
    bindingArray = @bindings[binding.name]
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

  getToken = (str) ->
    for token of tokens
      return token if ~str.indexOf(token)
    return null

  getValue = (container, bindValue, viewmodel) ->
    negate = bindValue.charAt(0) is '!'
    bindValue = bindValue.substring 1 if negate
    token = getToken(bindValue)
    if token
      i = bindValue.indexOf(token)
      left = getValue(container, bindValue.substring(0, i), viewmodel)
      right = getValue(container, bindValue.substring(i + token.length), viewmodel)
      value = tokens[token]( left, right )
    else if ~bindValue.indexOf('.')
      i = bindValue.indexOf('.')
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
            if quoted(arg)
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
      value = if _.isFunction(container[name]) then container[name].apply(undefined, args) else container[name]
    return if negate then !value else value

  @getVmValueGetter = (viewmodel, bindValue) ->
    return  -> getValue(viewmodel, bindValue, viewmodel)

  # !!!!!!!!!!!!!!!!!!!!!!!!!!!!
  # Untested

  @getVmValueSetter = ->

  @wrapTemplate = (template) ->
    viewName = template.viewName
    return if viewName is "body"
    name = ViewModel.viewPrefix + viewName.substr(viewName.indexOf('.') + 1)
    oldRenderFunc = template.renderFunction
    template.renderFunction = -> HTML.getTag(name)(oldRenderFunc.call(this))

  ##################
  # Instance methods

  bind: (bindObject, templateInstance, element, bindings) ->
    ViewModel.check '#bind', arguments
    viewmodel = this
    for bindName, bindValue of bindObject
      ViewModel.bindSingle templateInstance, element, bindName, bindValue, bindObject, viewmodel, bindings
    return

  #############
  # Constructor

  constructor: (initial) ->
    viewmodel = this
    for key, value of initial
      if _.isFunction(value)
        viewmodel[key] = value
      else
        viewmodel[key] = ViewModel.makeReactiveProperty(value);
    return