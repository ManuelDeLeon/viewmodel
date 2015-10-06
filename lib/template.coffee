Template.registerHelper 'b', ViewModel.bindHelper

wrapit = (template) ->
  BODY = "body"
  name = ViewModel.viewPrefix + if template.viewName is BODY then BODY else template.viewName.split(".")[1]
  oldRenderFunc = template.renderFunction
  template.renderFunction = -> HTML.getTag(name)(oldRenderFunc.call(this))

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

Blaze.Template.prototype.viewmodel = (args...) ->
  ViewModel.check 'T#viewmodel', args...
  template = this
  wrapit template
  initial = args[0]
  template.viewmodelInitial = initial
  template.onCreated ViewModel.onCreated(template)
  template.onRendered ->
    console.log getPathTo(this.firstNode)
  return

Blaze.Template.prototype.createViewModel = (args...) ->
  ViewModel.check 'T#createViewModel', args...
  template = this
  context = args[0]
  initial = ViewModel.getInitialObject template.viewmodelInitial, context
  viewmodel = new ViewModel(initial)
  viewmodel

