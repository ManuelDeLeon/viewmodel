ViewModel.addBinding
  name: 'text'
  bind: (bindArg) ->
    bindArg.autorun ->
      bindArg.element.text bindArg.getVmValue()