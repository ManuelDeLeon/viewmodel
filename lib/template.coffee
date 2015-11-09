Template.registerHelper 'b', ViewModel.bindHelper
Template.registerHelper 'on', ViewModel.eventHelper

getPathTo = (element) ->
  # use ~ and #
  if element.tagName == 'HTML' or element == document.body
    return '~'

  ix = 0
  siblings = element.parentNode.childNodes
  i = 0
  while i < siblings.length
    sibling = siblings[i]
    if sibling == element
      return getPathTo(element.parentNode) + '~' + element.tagName + '#' + (ix + 1) + '#'
    if sibling.nodeType == 1 and sibling.tagName == element.tagName
      ix++
    i++
  return

Blaze.Template.prototype.viewmodel = (initial) ->
  template = this
  ViewModel.check 'T#viewmodel', initial, template
  template.viewmodelInitial = initial
  template.onCreated ViewModel.onCreated(template)
  template.onRendered ViewModel.onRendered(template)
  template.onDestroyed ViewModel.onDestroyed(template)

  return

Blaze.Template.prototype.createViewModel = (context) ->
  template = this
  ViewModel.check 'T#createViewModel', context, template
  initial = ViewModel.getInitialObject template.viewmodelInitial, context
  viewmodel = new ViewModel(initial)
  viewmodel

