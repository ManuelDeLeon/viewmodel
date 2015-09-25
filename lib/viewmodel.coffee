class ViewModel
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

  @onRendered = ->
    # The following function returned will run when the template is rendered
    return ->
      templateInstance = this
      templateInstance.viewmodel.bind()

  @bindIdAttribute = 'bind-id'
  @bindHelper = (bindString) ->
    bindId = ViewModel.nextId()
    templateInstance = Template.instance()

    bindIdObj = {}
    bindIdObj[ViewModel.bindIdAttribute] = bindId
    bindIdObj

  @bindHelperName = 'b'
  @registerHelper = ->
    Template.registerHelper ViewModel.bindHelperName, ViewModel.bindHelper

  @new = -> new ViewModel()

  bind: ->
