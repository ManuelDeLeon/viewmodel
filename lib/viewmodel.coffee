class ViewModel2
  @bindings = {}
  @addBinding = (binding) ->
    VmCheck '@@addBinding', binding
    console.log binding
    console.log ViewModel2.bindings
    ViewModel2.bindings[binding.name] = binding