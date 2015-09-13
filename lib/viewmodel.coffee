class ViewModel2
  @check = (key, args...) ->
    if not ViewModel2.ignoreErrors
      Package['manuel:viewmodel-debug']?.VmCheck key, args...

  @bindings = {}
  @addBinding = (binding) ->
    ViewModel2.check '@@addBinding', binding
    ViewModel2.bindings[binding.name] = binding

