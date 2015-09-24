Blaze.Template.prototype.viewmodel = (initial) ->
  ViewModel.check 'T@viewmodel', initial
  this.vmInitial = initial
  this.onCreated ViewModel.onCreated(this)

#Blaze.Template.prototype.createViewModel = ->
#  ViewModel2.create template,
#
#Blaze.Template.prototype.viewmodel = (initial) ->
#  ViewModel2.check 'T@viewmodel', initial
#  this.vmInitial = initial
#  this.onCreated ViewModel2.onCreated(this)
#
#  return