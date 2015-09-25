ViewModel.registerHelper()

Blaze.Template.prototype.viewmodel = (initial) ->
  ViewModel.check 'T@viewmodel', initial
  template = this
  template.viewmodelInitial = initial
  template.onCreated ViewModel.onCreated(template)
  template.onRendered ViewModel.onRendered()

Blaze.Template.prototype.createViewModel = (context) ->
  ViewModel.check 'T@createViewModel', context
  template = this
  initial = null
  if _.isFunction(template.viewmodelInitial)
    initial = template.viewmodelInitial(context)
  else
    initial = context

#  templateName = template.view.name.substring(9) # "Template.".length
#  if not initial.vmId
#    initial.vmId = templateName + ' ' + ViewModel.nextId(templateName)

  viewmodel = ViewModel.new initial

  viewmodel

#Blaze.Template.prototype.createViewModel = ->
#  ViewModel2.create template,
#
#Blaze.Template.prototype.viewmodel = (initial) ->
#  ViewModel2.check 'T@viewmodel', initial
#  this.vmInitial = initial
#  this.onCreated ViewModel2.onCreated(this)
#
#  return