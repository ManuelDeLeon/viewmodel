Template.registerHelper 'b', ViewModel.bindHelper

Blaze.Template.prototype.viewmodel = (initial) ->
  ViewModel.check 'T#viewmodel', initial
  template = this
  template.viewmodelInitial = initial
  template.onCreated ViewModel.onCreated(template)
  return

Blaze.Template.prototype.createViewModel = (context) ->
  ViewModel.check 'T#createViewModel', context
  template = this
  initial = ViewModel.getInitialObject template.viewmodelInitial, context
  viewmodel = new ViewModel(initial)
  viewmodel

