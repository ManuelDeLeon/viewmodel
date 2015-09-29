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

  @bindIdAttribute = 'bind-id'
  @bindHelper = (bindString) ->

    bindId = ViewModel.nextId()
    bindObject = ViewModel.parseBind bindString

    templateInstance = Template.instance()
    Blaze.currentView.onViewReady ->
      templateInstance.viewmodel.bind bindId, bindObject, templateInstance
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

  ##################
  # Instance methods

  bind: (bindId, bindObject, templateInstance) ->
    console.log "bindId: #{bindId}"
    console.log this


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