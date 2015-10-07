Template.registerHelper 'b', ViewModel.bindHelper

getPathTo = (element) ->
  if element.tagName == 'HTML'
    return '/HTML[1]'
  if element == document.body
    return '/HTML[1]/BODY[1]'
  ix = 0
  siblings = element.parentNode.childNodes
  i = 0
  while i < siblings.length
    sibling = siblings[i]
    if sibling == element
      return getPathTo(element.parentNode) + '/' + element.tagName + '[' + (ix + 1) + ']'
    if sibling.nodeType == 1 and sibling.tagName == element.tagName
      ix++
    i++
  return

Blaze.Template.prototype.viewmodel = (initial) ->
  ViewModel.check 'T#viewmodel', arguments
  template = this
  ViewModel.wrapTemplate template
  template.viewmodelInitial = initial
  template.onCreated ViewModel.onCreated(template)

  return

Blaze.Template.prototype.createViewModel = (context) ->
  ViewModel.check 'T#createViewModel', arguments
  template = this
  initial = ViewModel.getInitialObject template.viewmodelInitial, context
  viewmodel = new ViewModel(initial)
  viewmodel

