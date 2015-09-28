Template.registerHelper ViewModel.bindHelperName, ViewModel.bindHelper

Blaze.Template.prototype.viewmodel = (initial) ->
  ViewModel.check 'T#viewmodel', initial
  template = this
  template.viewmodelInitial = initial
  template.onCreated ViewModel.onCreated(template)
  return

Blaze.Template.prototype.createViewModel = (context) ->
  ViewModel.check 'T#createViewModel', context
  template = this
  initial = null
  if _.isFunction(template.viewmodelInitial)
    initial = template.viewmodelInitial(context)
  else
    initial = context

  viewmodel = ViewModel.new(initial)
  viewmodel.vmId = ViewModel.nextId()
  viewmodel
