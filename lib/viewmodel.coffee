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
    ViewModel.check '@onCreated', template
    # The following function returned will run when the template is created
    return ->
      templateInstance = this
      vm = template.createViewModel(templateInstance.data)
      templateInstance.viewmodel = vm
      helpers = {}
      for prop of vm when not ViewModel.reserved[prop]
        do (prop) ->
          helpers[prop] = -> vm[prop]()

      template.helpers helpers
      return

  @bindIdAttribute = 'bind-id'
  @bindHelper = (bindString) ->
    ViewModel.check '@bindHelper', bindString

    bindId = ViewModel.nextId()
    bindObject = ViewModel.parseBind bindString

    templateInstance = Template.instance()
    Blaze.currentView.onViewReady ->
      templateInstance.viewmodel.bind bindId, bindObject, templateInstance
      return

    bindIdObj = {}
    bindIdObj[ViewModel.bindIdAttribute] = bindId
    return bindIdObj

  @bindHelperName = 'b'



  ##################
  # Instance methods

  bind: (bindId, bindObject, templateInstance) ->
    console.log "bindId: #{bindId}"


  #############
  # Constructor

  _initializing = false
  constructor: ->
    if not _initializing
      throw new Error "ViewModel constructor is private. Please use ViewModel.new"

  @new = (initial) ->
    _initializing = true
    viewmodel = new ViewModel(initial)
    _initializing = false
    return viewmodel