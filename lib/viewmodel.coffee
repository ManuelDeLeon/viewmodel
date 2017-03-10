class ViewModel

  #@@@@@@@@@@@@@@
  # Class methods

  _nextId = 1
  @nextId = -> _nextId++
  @persist = true

  # These are view model properties the user can use
  # but they have special meaning to ViewModel
  @properties =
    autorun: 1
    events: 1
    share: 1
    mixin: 1
    signal: 1
    ref: 1
    load: 1
    onRendered: 1
    onCreated: 1
    onDestroyed: 1

  # The user can't use these properties
  # when defining a view model
  @reserved =
    vmId: 1
    vmPathToParent: 1
    vmOnCreated: 1
    vmOnRendered: 1
    vmOnDestroyed: 1
    vmAutorun: 1
    vmEvents: 1
    vmInitial: 1
    vmProp: 1
    templateInstance: 1
    templateName: 1
    parent: 1
    children: 1
    child: 1
    reset: 1
    data: 1
    b: 1


  # These are objects used as bindings but do not have
  # an implementation
  @nonBindings =
    throttle: 1
    optionsText: 1
    optionsValue: 1
    defaultText: 1
    defaultValue: 1

  # Properties which the user needs to be more explicit in what they want
  # e.g. in a bind "if: prop.valid" the assumption is that the user wants to invoke
  # "prop.valid", not "prop().valid". If 'valid' is part of the object contained in
  # the property then the user must use the parenthesis: "if: prop().valid"
  @funPropReserved =
    valid: 1
    validMessage: 1
    invalid: 1
    invalidMessage: 1
    validating: 1
    message: 1

  @bindObjects = {}

  @byId = {}
  @byTemplate = {}
  @add = (viewmodel) ->
    ViewModel.byId[viewmodel.vmId] = viewmodel
    templateName = ViewModel.templateName(viewmodel.templateInstance)
    if templateName
      if not ViewModel.byTemplate[templateName]
        ViewModel.byTemplate[templateName] = {}
      ViewModel.byTemplate[templateName][viewmodel.vmId] = viewmodel

  @remove = (viewmodel) ->
    delete ViewModel.byId[viewmodel.vmId]
    templateName = ViewModel.templateName(viewmodel.templateInstance)
    if templateName
      delete ViewModel.byTemplate[templateName][viewmodel.vmId]

  @find = (templateNameOrPredicate, predicateOrNothing) ->
    templateName = _.isString(templateNameOrPredicate) and templateNameOrPredicate
    predicate = if templateName then predicateOrNothing else _.isFunction(templateNameOrPredicate) and templateNameOrPredicate

    vmCollection = if templateName then ViewModel.byTemplate[templateName] else ViewModel.byId
    return undefined if not vmCollection
    vmCollectionValues = _.values(vmCollection)
    if predicate
      return _.filter(vmCollection, predicate)
    else
      return vmCollectionValues

  @findOne = (templateNameOrPredicate, predicateOrNothing) ->
    return _.first ViewModel.find( templateNameOrPredicate, predicateOrNothing )

  @check = (key, args...) ->
    if Meteor.isDev and not ViewModel.ignoreErrors
      Package['manuel:viewmodel-debug']?.VmCheck key, args...
    return

  @onCreated = (template) ->
    return ->
      templateInstance = this
      viewmodel = template.createViewModel(templateInstance.data)
      templateInstance.viewmodel = viewmodel
      viewmodel.templateInstance = templateInstance
      ViewModel.add viewmodel

      if templateInstance.data?.ref
        parentTemplate = ViewModel.parentTemplate(templateInstance)
        if parentTemplate
          if not parentTemplate.viewmodel
            ViewModel.addEmptyViewModel(parentTemplate)
          viewmodel.parent()[templateInstance.data.ref] = viewmodel

      loadData = ->
        ViewModel.delay 0, ->
          # Don't bother if the template
          # gets destroyed by the time it gets here (the next js cycle)
          return if templateInstance.isDestroyed

          ViewModel.assignChild(viewmodel)

          for obj in ViewModel.globals
            viewmodel.load(obj);

          vmHash = viewmodel.vmHash()
          if migrationData = Migration.get(vmHash)
            viewmodel.load(migrationData)
            ViewModel.removeMigration viewmodel, vmHash
          if viewmodel.onUrl
            ViewModel.loadUrl viewmodel
            ViewModel.saveUrl viewmodel

      autoLoadData = ->
        templateInstance.autorun ->
          viewmodel.load Template.currentData()

      # Can't use delay in a simulation.
      # By default onCreated runs in a computation
      if Tracker.currentComputation
        loadData()
        # Crap, I have no idea why I'm delaying the load
        # data from the context. I think Template.currentData()
        # blows up if it's called inside a computation ?_?
        ViewModel.delay 0, autoLoadData
      else
        # Loading the context data needs to happen immediately
        # so the Blaze helpers can work with inherited values
        autoLoadData()
        # Running in a simulation
        # setup the load data after tracker is done with the current queue
        Tracker.afterFlush ->
          loadData()

      for fun in viewmodel.vmOnCreated
        fun.call viewmodel, templateInstance

      helpers = {}
      for prop of viewmodel when not ViewModel.reserved[prop]
        do (prop) ->
          helpers[prop] = (args...) ->
            instanceVm = Template.instance().viewmodel
            # We have to check that the view model has the property
            # as they may not be present if they're inherited properties
            # See: https://github.com/ManuelDeLeon/viewmodel/issues/223
            return instanceVm[prop](args...) if instanceVm[prop]

      template.helpers helpers

      return

  @bindIdAttribute = 'b-id'

  @addEmptyViewModel = (templateInstance) ->
    template = templateInstance.view.template
    template.viewmodelInitial = {}
    onCreated = ViewModel.onCreated(template, template.viewmodelInitial)
    onCreated.call templateInstance
    onRendered = ViewModel.onRendered(template.viewmodelInitial)
    onRendered.call templateInstance
    onDestroyed = ViewModel.onDestroyed(template.viewmodelInitial)
    templateInstance.view.onViewDestroyed ->
      onDestroyed.call templateInstance
    return

  getBindHelper = (useBindings) ->
    bindIdAttribute = ViewModel.bindIdAttribute
    bindIdAttribute += "-e" if not useBindings
    return (bindString) ->
      bindId = ViewModel.nextId()
      bindObject = ViewModel.parseBind bindString
      ViewModel.bindObjects[bindId] = bindObject
      templateInstance = Template.instance()

      if not templateInstance.viewmodel
        ViewModel.addEmptyViewModel(templateInstance)

      bindings = if useBindings then ViewModel.bindings else _.pick(ViewModel.bindings, 'default')

      currentView = Blaze.currentView

      # The template on which the element is rendered might not be
      # the one where the user puts it on the html. If it sounds confusing
      # it's because it IS confusing. The only case I know of is with
      # Iron Router's contentFor blocks.
      # See https://github.com/ManuelDeLeon/viewmodel/issues/142
      currentViewInstance = currentView._templateInstance or templateInstance

      # Blaze.currentView.onViewReady fails for some packages like jagi:astronomy and tap:i18n
      Tracker.afterFlush ->
        return if currentView.isDestroyed # The element may be removed before it can even be bound/used
        element = currentViewInstance.$("[#{bindIdAttribute}='#{bindId}']")
        # Don't bind the element because of a context change
        if element.length and not element[0].vmBound
          return if not element.removeAttr
          element[0].vmBound = true
          element.removeAttr bindIdAttribute
          templateInstance.viewmodel.bind bindObject, templateInstance, element, bindings, bindId, currentView

      bindIdObj = {}
      bindIdObj[bindIdAttribute] = bindId
      return bindIdObj

  @bindHelper = getBindHelper(true)
  @eventHelper = getBindHelper(false)

  @getInitialObject = (initial, context) ->
    if _.isFunction(initial)
      return initial(context) or {}
    else
      return initial or {}

  delayed = { }
  @delay = (time, nameOrFunc, fn) ->
    func = fn || nameOrFunc
    name = nameOrFunc if fn
    d = delayed[name] if name
    Meteor.clearTimeout d if d?
    id = Meteor.setTimeout func, time
    delayed[name] = id if name

  @makeReactiveProperty = (initial, viewmodel) ->
    dependency = new Tracker.Dependency()
    initialValue = if initial instanceof ViewModel.Property
      initial.defaultValue
    else
      initial

    _value = undefined
    reset = ->
      if initialValue instanceof Array
        _value = new ReactiveArray(initialValue, dependency)
      else
        _value = initialValue

    reset()

    validator = if initial instanceof ViewModel.Property
      initial
    else
      ViewModel.Property.validator(initial)

    funProp = (value) ->
      if arguments.length
        if _value isnt value
          changeValue = ->

            if validator.beforeUpdates.length
              validator.beforeValueUpdate(_value, viewmodel);

            if value instanceof Array
              _value = new ReactiveArray(value, dependency)
            else
              _value = value

            if validator.convertIns.length
              _value = validator.convertValueIn(_value, viewmodel);

            if validator.afterUpdates.length
              validator.afterValueUpdate(_value, viewmodel);

            dependency.changed()
          if funProp.delay > 0
            ViewModel.delay funProp.delay, funProp.vmProp, changeValue
          else
            changeValue()
      else
        dependency.depend()

      if validator.convertOuts.length
        return validator.convertValueOut(_value, viewmodel);
      else
        return _value;

    funProp.reset = ->
      reset()
      dependency.changed()

    funProp.depend = -> dependency.depend()
    funProp.changed = -> dependency.changed()
    funProp.delay = 0
    funProp.vmProp = ViewModel.nextId()



    hasAsync = validator.hasAsync()
    validDependency = undefined
    validatingItems = undefined
    if hasAsync
      validDependency = new Tracker.Dependency()
      validatingItems = new ReactiveArray()

    validationAsync = {}

    getDone = if hasAsync
      (initialValue) ->
        validatingItems.push(1)
        return (result) ->
          validatingItems.pop()
          if _value is initialValue and not ((validationAsync.value is _value) or result)
            validationAsync = { value: _value }
            validDependency.changed()

    funProp.valid = (noAsync) ->
      dependency.depend()
      if hasAsync
        validDependency.depend()
      if validationAsync and validationAsync.hasOwnProperty('value') and validationAsync.value is _value
        return false
      else
        if hasAsync and !noAsync
          validator.verifyAsync(_value, getDone(_value), viewmodel)
        return validator.verify(_value, viewmodel)

    funProp.validMessage = -> validator.validMessageValue

    funProp.invalid = (noAsync) -> not this.valid(noAsync)
    funProp.invalidMessage = -> validator.invalidMessageValue

    funProp.validating = ->
      return false if not hasAsync
      validatingItems.depend()
      return !!validatingItems.length

    funProp.message = ->
      if this.valid(true)
        return validator.validMessageValue
      else
        return validator.invalidMessageValue

    # to give the feel of non reactivity
    Object.defineProperty funProp, 'value', { get: -> _value}

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

  @addAttributeBinding = (attrs) ->
    if attrs instanceof Array
      for attr in attrs
        do (attr) ->
          ViewModel.addBinding
            name: attr
            bind: (bindArg) ->
              bindArg.autorun ->
                bindArg.element[0].setAttribute attr, bindArg.getVmValue(bindArg.bindValue[attr])
              return
    else if _.isString(attrs)
      ViewModel.addBinding
        name: attrs
        bind: (bindArg) ->
          bindArg.autorun ->
            bindArg.element[0].setAttribute attrs, bindArg.getVmValue(bindArg.bindValue[attrs])
          return
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

  getDelayedSetter = (bindArg, setter, bindId) ->
    if bindArg.elementBind.throttle
      return (args...) ->
        ViewModel.delay bindArg.getVmValue(bindArg.elementBind.throttle), bindId, -> setter(args...)
    else
      return setter

  @getBindArgument = (templateInstance, element, bindName, bindValue, bindObject, viewmodel, bindId, view) ->
    bindArg =
      templateInstance: templateInstance
      autorun: (f) ->
        fun = (c) -> f(bindArg, c)
        templateInstance.autorun fun
        return
      element: element
      elementBind: bindObject
      getVmValue: ViewModel.getVmValueGetter(viewmodel, bindValue, view)
      bindName: bindName
      bindValue: bindValue
      viewmodel: viewmodel

    bindArg.setVmValue = getDelayedSetter bindArg, ViewModel.getVmValueSetter(viewmodel, bindValue, view), bindId
    return bindArg

  @bindSingle = (templateInstance, element, bindName, bindValue, bindObject, viewmodel, bindings, bindId, view) ->
    bindArg = ViewModel.getBindArgument templateInstance, element, bindName, bindValue, bindObject, viewmodel, bindId, view
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

  stringRegex = /^(?:"(?:[^"]|\\")*[^\\]"|'(?:[^']|\\')*[^\\]')$/
  quoted = (str) -> stringRegex.test(str)
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
    '**': (a, b) -> a ** b
    '*': (a, b) -> a * b
    '/': (a, b) -> a / b
    '%': (a, b) -> a % b
    '+': (a, b) -> a + b
    '-': (a, b) -> a - b
    '<': (a, b) -> a < b
    '<=': (a, b) -> a <= b
    '>': (a, b) -> a > b
    '>=': (a, b) -> a >= b
    '==': (a, b) -> `a == b`
    '!==': (a, b) -> `a !== b`
    '===': (a, b) -> a is b
    '!===': (a, b) -> a isnt b
    '&&': (a, b) -> a && b
    '||': (a, b) -> a || b

  tokenGroup = {}
  for _t of tokens
    tokenGroup[_t.length] = {} if not tokenGroup[_t.length]
    tokenGroup[_t.length][_t] = 1

  dotRegex = /(\D\.)|(\.\D)/

  firstToken = (str) ->
    tokenIndex = -1
    token = null
    inQuote = null
    parensCount = 0
    for c, i in str
      break if token
      if c is '"' or c is "'"
        if inQuote is c
          inQuote = null
        else if not inQuote
          inQuote = c
      else if not inQuote and (c is '(' or c is ')')
        if c is '('
          parensCount++
        if c is ')'
          parensCount--
      else if not inQuote and parensCount is 0 and ~"+-*/%&|><=".indexOf(c)
        tokenIndex = i
        for length in [4..1]
          if str.length > tokenIndex + length
            candidateToken = str.substr(tokenIndex, length)
            if tokenGroup[length] and tokenGroup[length][candidateToken]
              token = candidateToken
              break
    return [token, tokenIndex]

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
    if currentView
      Blaze.getData(currentView)
    else
      Template.instance()?.data

  getValue = (container, bindValue, viewmodel, funPropReserved) ->
    bindValue = bindValue.trim()
    return getPrimitive(bindValue) if isPrimitive(bindValue)
    [token, tokenIndex] = firstToken(bindValue)
    if ~tokenIndex
      left = getValue(container, bindValue.substring(0, tokenIndex), viewmodel)
      if (token is '&&' and not left) || (token is '||' and left)
        value = left
      else
        right = getValue(container, bindValue.substring(tokenIndex + token.length), viewmodel)
        value = tokens[token.trim()]( left, right )
    else if bindValue is "this"
      value = currentContext()
    else if quoted(bindValue)
      value = removeQuotes(bindValue)
    else
      negate = bindValue.charAt(0) is '!'
      bindValue = bindValue.substring 1 if negate

      dotIndex = bindValue.search(dotRegex)
      dotIndex += 1 if ~dotIndex and bindValue.charAt(dotIndex) isnt '.'
      parenIndexStart = bindValue.indexOf('(')
      parenIndexEnd = getMatchingParenIndex(bindValue, parenIndexStart)

      breakOnFirstDot = ~dotIndex and (!~parenIndexStart or dotIndex < parenIndexStart or dotIndex is (parenIndexEnd + 1))

      if breakOnFirstDot
        newBindValue = bindValue.substring(dotIndex + 1)
        newBindValueCheck = if newBindValue.endsWith('()') then newBindValue.substr(0, newBindValue.length - 2) else newBindValue
        newContainer = getValue container, bindValue.substring(0, dotIndex), viewmodel, ViewModel.funPropReserved[newBindValueCheck]
        value = getValue newContainer, newBindValue, viewmodel
      else
        if `container == null`
          value = undefined
        else
          name = bindValue
          args = []
          if ~parenIndexStart
            parsed = ViewModel.parseBind(bindValue)
            name = Object.keys(parsed)[0]
            second = parsed[name]
            if second.length > 2
              for arg in second.substr(1, second.length - 2).split(',') #remove parenthesis
                arg = $.trim(arg)
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
                    newArg = arg #getPrimitive(arg)
                  newArg = !newArg if neg
                args.push newArg

          primitive = isPrimitive(name)
          if container instanceof ViewModel and not primitive and not container[name]
            container[name] = ViewModel.makeReactiveProperty(undefined, viewmodel)

          if !primitive and not (container? and (container[name]? or _.isObject(container)))
            errorMsg = "Can't access '#{name}' of '#{container}'."
            if viewmodel
              templateName = ViewModel.templateName(viewmodel.templateInstance)
              errorMsg += " This is for template '#{templateName}'."
            console.error errorMsg
          else if primitive
            value = getPrimitive(name)
          else if not (`name in container`)
            return undefined
          else
            if !funPropReserved and _.isFunction(container[name])
              value = container[name].apply(container, args)
            else
              value = container[name]
      value = !value if negate

    return value

  @getVmValueGetter = (viewmodel, bindValue, view) ->
    return  (optBindValue = bindValue) ->
      currentView = view
      getValue(viewmodel, optBindValue.toString(), viewmodel)

  setValue = (value, container, bindValue, viewmodel) ->
    bindValue = bindValue.trim()
    return getPrimitive(bindValue) if isPrimitive(bindValue)
    [token, tokenIndex] = firstToken(bindValue)
    retValue = undefined
    if ~tokenIndex
      left = setValue(value, container, bindValue.substring(0, tokenIndex), viewmodel)
      return left if token is '&&' and not left
      return left if token is '||' and left
      right = setValue(value, container, bindValue.substring(tokenIndex + token.length), viewmodel)
      retValue = tokens[token.trim()]( left, right )
    else if ~bindValue.indexOf(')', bindValue.length - 1)
      retValue = getValue(viewmodel, bindValue, viewmodel)
    else if dotRegex.test(bindValue)
      i = bindValue.search(dotRegex)
      i += 1 if bindValue.charAt(i) isnt '.'
      newContainer = getValue container, bindValue.substring(0, i), viewmodel
      newBindValue = bindValue.substring(i + 1)
      retValue = setValue value, newContainer, newBindValue, viewmodel
    else
      if _.isFunction(container[bindValue]) 
        retValue = container[bindValue](value) 
      else 
        container[bindValue] = value
        retValue = value
    return retValue

  @getVmValueSetter = (viewmodel, bindValue, view) ->
    return (->) if not _.isString(bindValue)
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
    viewmodel.parent()?.children().push(viewmodel)
    return

  @onRendered =  ->
    return ->
      templateInstance = this
      viewmodel = templateInstance.viewmodel
      initial = viewmodel.vmInitial
      ViewModel.check "@onRendered", initial.autorun, templateInstance

      # onRendered happens before onViewReady
      # We want bindings to be in place before we run
      # the onRendered functions and autoruns
      ViewModel.delay 0, ->
        # Don't bother running onRendered or autoruns if the template
        # gets destroyed by the time it gets here (the next js cycle)
        return if templateInstance.isDestroyed
        for fun in viewmodel.vmOnRendered
          fun.call viewmodel, templateInstance

        for autorun in viewmodel.vmAutorun
          do (autorun) ->
            fun = (c) -> autorun.call(viewmodel, c)
            templateInstance.autorun fun
        return
      return

  @loadProperties = (toLoad, container) ->
    loadObj = (obj) ->
      for key, value of obj when not ViewModel.properties[key]
        if ViewModel.reserved[key]
          throw new Error "Can't use reserved word '" + key + "' as a view model property."
        else
          if _.isFunction(value)
            # we don't care, just take the new function
            container[key] = value
          else if container[key] and container[key].vmProp and _.isFunction(container[key])
            # keep the reference to the old property we already have
            container[key] value
          else
            # Create a new property
            container[key] = ViewModel.makeReactiveProperty(value, container);
      return
    if toLoad instanceof Array
      loadObj obj for obj in toLoad
    else
      loadObj toLoad
    return

  ##################
  # Instance methods

  bind: (bindObject, templateInstance, element, bindings, bindId, view) ->
    viewmodel = this
    for bindName, bindValue of bindObject when not ViewModel.nonBindings[bindName]
      if ~bindName.indexOf(' ')
        for bindNameSingle in bindName.split(' ')
          ViewModel.bindSingle templateInstance, element, bindNameSingle, bindValue, bindObject, viewmodel, bindings, bindId, view
      else
        ViewModel.bindSingle templateInstance, element, bindName, bindValue, bindObject, viewmodel, bindings, bindId, view
    return

  loadMixinShare = (toLoad, collection, viewmodel, onlyEvents) ->
    if toLoad
      if toLoad instanceof Array
        for element in toLoad
          if _.isString element
            #viewmodel.load collection[element], onlyEvents
            loadToContainer viewmodel, viewmodel, collection[element], onlyEvents
#            if viewmodel instanceof ViewModel
#              viewmodel.load collection[element], onlyEvents
#            else
#              ViewModel.loadProperties collection[element], viewmodel
          else
            loadMixinShare element, collection, viewmodel, onlyEvents
      else if _.isString toLoad
        loadToContainer viewmodel, viewmodel, collection[toLoad], onlyEvents
#        if viewmodel instanceof ViewModel
#        viewmodel.load collection[toLoad], onlyEvents
#        else
#          ViewModel.loadProperties collection[toLoad], viewmodel
      else
        for ref of toLoad
          container = {}
          mixshare = toLoad[ref]
          if mixshare instanceof Array
            for item in mixshare
#              loadMixinShare collection[item], container, onlyEvents
              loadToContainer container, viewmodel, collection[item], onlyEvents
#              ViewModel.loadProperties collection[item], container
          else
#            loadMixinShare collection[mixshare], container, onlyEvents
            loadToContainer container, viewmodel, collection[mixshare], onlyEvents
#            ViewModel.loadProperties collection[mixshare], container
          viewmodel[ref] = container
    return

  loadToContainer = (container, viewmodel, toLoad, onlyEvents) ->
    return if not toLoad

    if toLoad instanceof Array
      loadToContainer( container, viewmodel, item, onlyEvents ) for item in toLoad

    if not onlyEvents
      # Signals are loaded 1st
      signals = ViewModel.signalToLoad(toLoad.signal, container)
      for signal in signals
        loadToContainer container, viewmodel, signal, onlyEvents
        viewmodel.vmOnCreated.push signal.onCreated
        viewmodel.vmOnDestroyed.push signal.onDestroyed

    # Shared are loaded 2nd
    loadMixinShare toLoad.share, ViewModel.shared, container, onlyEvents

    # Mixins are loaded 3rd
    loadMixinShare toLoad.mixin, ViewModel.mixins, container, onlyEvents

    # Whatever is in 'load' is loaded before direct properties
    loadToContainer container, viewmodel, toLoad.load, onlyEvents

    if not onlyEvents
      # Direct properties are loaded last.
      ViewModel.loadProperties toLoad, container

    if onlyEvents
      hooks =
        events: 'vmEvents'
    else
      hooks =
        onCreated: 'vmOnCreated'
        onRendered: 'vmOnRendered'
        onDestroyed: 'vmOnDestroyed'
        autorun: 'vmAutorun'


    for hook, vmProp of hooks when toLoad[hook]
      if toLoad[hook] instanceof Array
        for item in toLoad[hook]
          viewmodel[vmProp].push item
      else
        viewmodel[vmProp].push toLoad[hook]

  load: (toLoad, onlyEvents) -> loadToContainer(this, this, toLoad, onlyEvents)

  parent: (args...) ->
    ViewModel.check "#parent", args...
    viewmodel = this
    instance = viewmodel.templateInstance
    while parentTemplate = ViewModel.parentTemplate(instance)
      if parentTemplate.viewmodel
        return parentTemplate.viewmodel
      else
        instance = parentTemplate
    return

  reset: ->
    viewmodel = this
    viewmodel[prop].reset() for prop of viewmodel when _.isFunction(viewmodel[prop]?.reset)


  data: (fields = []) ->
    viewmodel = this
    js = {}
    for prop of viewmodel when viewmodel[prop]?.vmProp and (fields.length is 0 or prop in fields)
      viewmodel[prop].depend()
      value = viewmodel[prop].value
      if value instanceof ReactiveArray
        js[prop] = value.array()
      else
        js[prop] = value
    return js

  valid: (fields = []) ->
    viewmodel = this
    for prop of viewmodel when viewmodel[prop]?.vmProp and (fields.length is 0 or prop in fields)
      return false if not viewmodel[prop].valid(true)
    return true

  validMessages: (fields = []) ->
    viewmodel = this
    messages = []
    for prop of viewmodel when viewmodel[prop]?.vmProp and (fields.length is 0 or prop in fields)
      if viewmodel[prop].valid(true)
        message = viewmodel[prop].message()
        if message
          messages.push(message)
    return messages

  invalid: (fields = []) -> not this.valid(fields)
  invalidMessages: (fields = []) ->
    viewmodel = this
    messages = []
    for prop of viewmodel when viewmodel[prop]?.vmProp and (fields.length is 0 or prop in fields)
      if not viewmodel[prop].valid(true)
        message = viewmodel[prop].message()
        if message
          messages.push(message)
    return messages

  templateName: -> ViewModel.templateName(@templateInstance)

#############
  # Constructor

  childrenProperty = ->
    array = new ReactiveArray()
    funProp = (search, predicate) ->
      array.depend()
      if arguments.length
        ViewModel.check "#children", search
        newPredicate = undefined ;
        if _.isString(search)
          first = (vm) -> ViewModel.templateName(vm.templateInstance) is search
          if predicate
            newPredicate = (vm) -> first(vm) and predicate(vm)
          else
            newPredicate = first
        else
          newPredicate = search
        return _.filter array, newPredicate
      else
        return array

    return funProp

  @getPathTo = (element) ->
    # use ~ and #
    if !element or !element.parentNode or element.tagName is 'HTML' or element is document.body
      return '/'

    ix = 0
    siblings = element.parentNode.childNodes
    i = 0
    while i < siblings.length
      sibling = siblings[i]
      if sibling is element
        return ViewModel.getPathTo(element.parentNode) + '/' + element.tagName + '[' + (ix + 1) + ']'
      if sibling.nodeType is 1 and sibling.tagName is element.tagName
        ix++
      i++
    return

  constructor: (initial) ->
    ViewModel.check "#constructor", initial
    viewmodel = this
    viewmodel.vmId = ViewModel.nextId()

    # These will be filled from load/mixin/share/initial
    @vmOnCreated = []
    @vmOnRendered = []
    @vmOnDestroyed = []
    @vmAutorun = []
    @vmEvents = []

    viewmodel.load initial

    @children = childrenProperty()

    viewmodel.vmPathToParent = ->
      viewmodelPath = ViewModel.getPathTo(viewmodel.templateInstance.firstNode)
      if not viewmodel.parent()
        return viewmodelPath
      parentPath = ViewModel.getPathTo(viewmodel.parent().templateInstance.firstNode)
      i = 0
      i++ while parentPath[i] is viewmodelPath[i] and parentPath[i]?
      difference = viewmodelPath.substr(i)
      return difference


    return

  child: (args...) ->
    children = this.children(args...)
    if children?.length
      return children[0]
    else
      return undefined

  @onDestroyed = (initial) ->
    return ->
      templateInstance = this
      initial = initial(templateInstance.data) if _.isFunction(initial)
      viewmodel = templateInstance.viewmodel

      for fun in viewmodel.vmOnDestroyed
        fun.call viewmodel, templateInstance

      parent = viewmodel.parent()
      if parent
        children = parent.children()
        indexToRemove = -1
        for child in children
          indexToRemove++
          if child.vmId is viewmodel.vmId
            children.splice(indexToRemove, 1)
            break
      ViewModel.remove viewmodel
      return

  @templateName = (templateInstance) ->
    name = templateInstance?.view?.name
    return '' if not name
    if name is 'body' then name else name.substr(name.indexOf('.') + 1)

  vmHash: ->
    viewmodel = this
    key = ViewModel.templateName(viewmodel.templateInstance)
    if viewmodel.parent()
      key += viewmodel.parent().vmHash()

    if viewmodel.vmTag
      key += viewmodel.vmTag()
    else if viewmodel._id
      key += viewmodel._id()
    else
      key += viewmodel.vmPathToParent()

    return SHA256(key).toString()

  @removeMigration = (viewmodel, vmHash) ->
    Migration.delete vmHash

  @shared = {}
  @share = (obj) ->
    for key, value of obj
      ViewModel.shared[key] = {}
      for prop, content of value
        if _.isFunction(content) or ViewModel.properties[prop]
          ViewModel.shared[key][prop] = content
        else
          ViewModel.shared[key][prop] = ViewModel.makeReactiveProperty(content)

    return

  @globals = []
  @global = (obj) ->
    ViewModel.globals.push(obj)

  @mixins = {}
  @mixin = (obj) ->
    for key, value of obj
      ViewModel.mixins[key] = value
    return

  @signals = {}
  @signal = (obj) ->
    for key, value of obj
      ViewModel.signals[key] = value
    return

  signalContainer = (containerName, container) ->
    all = []
    return all if not containerName
    signalObject = ViewModel.signals[containerName]
    for key, value of signalObject
      do (key, value) ->
        single = {}
        single[key] = {}
        transform = value.transform or (e) -> e
        boundProp = "_#{key}_Bound"
        single.onCreated = ->
          vmProp = container[key]
          func = (e) ->
            vmProp transform(e)
          funcToUse = if value.throttle then _.throttle( func, value.throttle ) else func
          container[boundProp] = funcToUse
          value.target.addEventListener value.event, funcToUse
        single.onDestroyed = ->
          value.target.removeEventListener value.event, this[boundProp]
        all.push single
    return all

  @signalToLoad = (containerName, container) ->
    if containerName instanceof Array
      _.flatten( (signalContainer(name, container) for name in containerName), true )
    else
      signalContainer containerName, container