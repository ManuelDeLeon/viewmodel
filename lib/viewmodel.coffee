class ViewModel
  @check = (key, args...) ->
    console.log "X"

  @onCreated = ->

#    if not ViewModel2.ignoreErrors
#      Package['manuel:viewmodel-debug']?.VmCheck key, args...
#    return
#
#  @bindings = {}
#  @addBinding = (binding) ->
#    ViewModel2.check '@@addBinding', binding
#    ViewModel2.bindings[binding.name] = binding
#    return
#
#  @onCreated = (template) ->
#    return ->
#      templateInstance = this
#      templateInstance.vm = template.createViewModel(this.data)
#
