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
    ref: 1
    load: 1
    onRendered: 1
    onCreated: 1
    onDestroyed: 1

  # The user can't use these properties
  # when defining a view model
  @reserved =
    vmId: 1
    parent: 1
    children: 1
    reset: 1
    data: 1


  # These are objects used as bindings but do not have
  # an implementation
  @nonBindings =
    throttle: 1
    optionsText: 1
    optionsValue: 1
    defaultText: 1
    defaultValue: 1

  @bindObjects = {}
  @byId = {}
  @add = (viewmodel) ->
    ViewModel.byId[viewmodel.vmId] = viewmodel
  @remove = (viewmodel) ->
    delete ViewModel.byId[viewmodel.vmId]

  @check = (key, args...) ->
    if Meteor.isDev and not ViewModel.ignoreErrors
      Package['manuel:viewmodel-debug']?.VmCheck key, args...
    return

  @onCreated = (template, initial) ->
    return ->
      currentDataAutorunSet = false
      templateInstance = this
      viewmodel = template.createViewModel(templateInstance.data)
      ViewModel.add viewmodel
      templateInstance.viewmodel = viewmodel
      viewmodel.templateInstance = templateInstance
      if templateInstance.data?.ref
        parentTemplate = ViewModel.parentTemplate(templateInstance)
        if parentTemplate
          if not parentTemplate.viewmodel
            ViewModel.addEmptyViewModel(parentTemplate)
          viewmodel.parent()[templateInstance.data.ref] = viewmodel
      Tracker.afterFlush ->
        if not currentDataAutorunSet
          currentDataAutorunSet = true
          templateInstance.autorun ->
            viewmodel.load Template.currentData()
            return
        ViewModel.assignChild(viewmodel)
        ViewModel.delay 0, ->
          vmHash = viewmodel.vmHash()
          if migrationData = Migration.get(vmHash)
            viewmodel.load(migrationData)
            ViewModel.removeMigration viewmodel, vmHash
          if viewmodel.onUrl
            ViewModel.loadUrl viewmodel
            ViewModel.saveUrl viewmodel

          if _.isFunction initial?.onCreated
            initial.onCreated.call viewmodel, templateInstance
    
          if initial?.load
            if initial.load instanceof Array
              for obj in initial.load when _.isFunction obj.onCreated
                obj.onCreated.call viewmodel, templateInstance
            else if _.isFunction initial.load.onCreated
              initial.load.onCreated.call viewmodel, templateInstance

      if not Tracker.currentComputation
        currentDataAutorunSet = true
        templateInstance.autorun ->
          viewmodel.load Template.currentData()

      helpers = {}
      for prop of viewmodel when not ViewModel.reserved[prop]
        do (prop) ->
          helpers[prop] = -> Template.instance().viewmodel[prop]()

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

      # The template on which the element is rendered might not be
      # the one where the user puts it on the html. If it sounds confusing
      # it's because it IS confusing. The only case I know of is with
      # Iron Router's contentFor blocks.
      # See https://github.com/ManuelDeLeon/viewmodel/issues/142
      currentViewInstance = Blaze.currentView._templateInstance or templateInstance
      Blaze.currentView.onViewReady ->
        element = currentViewInstance.$("[#{bindIdAttribute}='#{bindId}']")
        templateInstance.viewmodel.bind bindObject, templateInstance, element, bindings, bindId, this
        return

      bindIdObj = {}
      bindIdObj[bindIdAttribute] = bindId
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
    isArray = _.isArray(initial)
    initialValue = if isArray then new ReactiveArray(initial, dependency) else initial
    _value = initialValue

    funProp = (value) ->
      if arguments.length
        if _value isnt value
          changeValue = ->
            if value instanceof Array
              _value = new ReactiveArray(value, dependency)
            else
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
    new RegExp("(\\s\\#{t}\\s)")
#    new RegExp("(\\S\\#{t}\\s)|(\\s\\#{t}\\S)")

  spaceRegexMem = _.memoize spaceRegex

  getToken = (str) ->
    for token of tokens
      regex = spaceRegexMem(token)
      index = str.search(regex)
#      index += 1 if ~index and str.charAt(index) isnt ' '
      if ~index
        return str.substr(index, token.length + 2)
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
    if currentView
      Blaze.getData(currentView)
    else
      Template.instance()?.data

  getValue = (container, bindValue, viewmodel) ->
    negate = bindValue.charAt(0) is '!'
    bindValue = bindValue.substring 1 if negate

    if bindValue is "this"
      value = currentContext()
    else if quoted(bindValue)
      value = removeQuotes(bindValue)
    else if (token = tokenRegex.test(bindValue) and getToken(bindValue))
      i = bindValue.indexOf(token)
      left = getValue(container, bindValue.substring(0, i), viewmodel)
      right = getValue(container, bindValue.substring(i + token.length), viewmodel)
      value = tokens[token.trim()]( left, right )
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
                  newArg = getPrimitive(arg)
                newArg = !newArg if neg
              args.push newArg

        primitive = isPrimitive(name)
        if container instanceof ViewModel and not primitive and not container[name]
          container[name] = ViewModel.makeReactiveProperty(undefined)

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
        getValue(viewmodel, bindValue, viewmodel)
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

  @onRendered = (initial) ->
    return ->
      templateInstance = this
      viewmodel = templateInstance.viewmodel

      ViewModel.check "@onRendered", initial.autorun, templateInstance

      loadAutorun = (initialAutorun) ->
        if _.isFunction initialAutorun
          fun = (c) -> initialAutorun.call(viewmodel, c)
          Tracker.afterFlush -> templateInstance.autorun fun
        else if initialAutorun instanceof Array
          for autorun in initialAutorun
            do (autorun) ->
              fun = (c) -> autorun.call(viewmodel, c)
              do (fun) ->
                Tracker.afterFlush -> templateInstance.autorun fun
        return

      loadAutorun initial.autorun
      if initial.load
        if initial.load instanceof Array
          for obj in initial.load
            ViewModel.check "@onRendered", obj.autorun, templateInstance
            loadAutorun obj.autorun
        else
          loadAutorun initial.load.autorun

      if _.isFunction initial?.onRendered
        Tracker.afterFlush ->
          initial.onRendered.call viewmodel, templateInstance

      if initial?.load
        Tracker.afterFlush ->
          if initial.load instanceof Array
            for obj in initial.load when _.isFunction obj.onRendered
              do (obj) ->
                obj.onRendered.call viewmodel, templateInstance
          else if _.isFunction initial.load.onRendered
            initial.load.onRendered.call viewmodel, templateInstance
          
      return

  @loadProperties = (toLoad, container) ->
    loadObj = (obj) ->
      for key, value of obj when not ViewModel.properties[key]
        if _.isFunction(value)
# we don't care, just take the new function
          container[key] = value
        else if container[key]
# keep the reference to the old property we already have
          container[key] value
        else
# Create a new property
          container[key] = ViewModel.makeReactiveProperty(value);
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
      ViewModel.bindSingle templateInstance, element, bindName, bindValue, bindObject, viewmodel, bindings, bindId, view
    return

  load: (toLoad) ->
    viewmodel = this
    ViewModel.loadProperties toLoad, viewmodel

  parent: (args...) ->
    ViewModel.check "#parent", args...
    viewmodel = this
    parentTemplate = ViewModel.parentTemplate(viewmodel.templateInstance)
    return parentTemplate?.viewmodel

  reset: ->
    viewmodel = this
    viewmodel[prop].reset() for prop of viewmodel when _.isFunction(viewmodel[prop]?.reset)


  data: (fields = []) ->
    viewmodel = this
    js = {}
    for prop of viewmodel when viewmodel[prop]?.id and (fields.length is 0 or prop in fields)
      value = viewmodel[prop]()
      if value instanceof ReactiveArray
        js[prop] = value.array()
      else
        js[prop] = value
    return js



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

  @getPathTo = (element) ->
    # use ~ and #
    if !element or element.tagName == 'HTML' or element == document.body
      return '/'

    ix = 0
    siblings = element.parentNode.childNodes
    i = 0
    while i < siblings.length
      sibling = siblings[i]
      if sibling == element
        return ViewModel.getPathTo(element.parentNode) + '/' + element.tagName + '[' + (ix + 1) + ']'
      if sibling.nodeType == 1 and sibling.tagName == element.tagName
        ix++
      i++
    return

  loadObj = (toLoad, collection, viewmodel) ->
    if toLoad
      if toLoad instanceof Array
        for element in toLoad
          viewmodel.load collection[element]
      else if _.isString toLoad
        viewmodel.load collection[toLoad]
      else
        for ref of toLoad
          container = {}
          mixshare = toLoad[ref]
          if mixshare instanceof Array
            for item in mixshare
              ViewModel.loadProperties collection[item], container
          else
            ViewModel.loadProperties collection[mixshare], container
          viewmodel[ref] = container
    return

  constructor: (initial) ->
    ViewModel.check "#constructor", initial
    viewmodel = this
    viewmodel.vmId = ViewModel.nextId()
    viewmodel.vmHashCache = null
    if initial
      viewmodel.load initial
      viewmodel.load initial.load
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
    if initial
      loadObj initial.share, ViewModel.shared, viewmodel
      loadObj initial.mixin, ViewModel.mixins, viewmodel

    return


  ############
  # Not Tested



  @onDestroyed = (initial) ->
    return ->
      templateInstance = this
      viewmodel = templateInstance.viewmodel
      
      if _.isFunction initial?.onDestroyed
        initial.onDestroyed.call viewmodel, templateInstance

      if initial?.load
        if initial.load instanceof Array
          for obj in initial.load when _.isFunction obj.onDestroyed
            obj.onDestroyed.call viewmodel, templateInstance
        else if _.isFunction initial.load.onDestroyed
          initial.load.onDestroyed.call viewmodel, templateInstance

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
    name = templateInstance.view.name
    if name is 'body' then name else name.substr(name.indexOf('.') + 1)

  vmHash: ->
    viewmodel = this
    key = ViewModel.templateName(viewmodel.templateInstance)
    if viewmodel.parent()
      key += viewmodel.parent().vmHash()

    if viewmodel.vmTag
      key += viewmodel.vmTag()

    if viewmodel._id
      key += viewmodel._id()
    else
      key += viewmodel.vmPathToParent()

    viewmodel.vmHashCache = SHA256(key).toString()
    viewmodel.vmHashCache

  @removeMigration = (viewmodel, vmHash) ->
    Migration.delete vmHash

  @shared = {}
  @share = (obj) ->
    for key, value of obj
      ViewModel.shared[key] = {}
      for prop, content of value
        if _.isFunction(content)
          ViewModel.shared[key][prop] = content
        else
          ViewModel.shared[key][prop] = ViewModel.makeReactiveProperty(content)

    return

  @mixins = {}
  @mixin = (obj) ->
    for key, value of obj
      ViewModel.mixins[key] = value
    return