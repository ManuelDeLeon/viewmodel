Template.registerHelper 'b', ViewModel.bindHelper

Blaze.Template.prototype.viewmodel = (args...) ->
  ViewModel.check 'T#viewmodel', args...
  template = this
  initial = args[0]
  template.viewmodelInitial = initial
  template.onCreated ViewModel.onCreated(template)
  return

Blaze.Template.prototype.createViewModel = (args...) ->
  ViewModel.check 'T#createViewModel', args...
  template = this
  context = args[0]
  initial = ViewModel.getInitialObject template.viewmodelInitial, context
  viewmodel = new ViewModel(initial)
  viewmodel

