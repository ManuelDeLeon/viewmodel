Blaze.Template.prototype.createViewModel = ->
  ViewModel2.create template,


Blaze.Template.prototype.viewmodel = (initial) ->
  ViewModel2.check 'T@viewmodel', initial