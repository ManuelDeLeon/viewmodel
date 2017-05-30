Template.registerHelper 'b', ViewModel.bindHelper
Template.registerHelper 'on', ViewModel.eventHelper

Blaze.Template.prototype.viewmodel = (initial) ->
  template = this
  ViewModel.check 'T#viewmodel', initial, template
  ViewModel.check 'T#viewmodelArgs', template, arguments
  template.viewmodelInitial = initial
  template.onCreated ViewModel.onCreated(template, initial)
  template.onRendered ViewModel.onRendered(initial)
  template.onDestroyed ViewModel.onDestroyed(initial)
  initialObject = ViewModel.getInitialObject initial
  viewmodel = new ViewModel()
  viewmodel.load initialObject, true
  for eventGroup in viewmodel.vmEvents
    for event, eventFunction of eventGroup
      do (event, eventFunction) ->
        eventObj = {}
        eventObj[event] = (e, t) ->
          templateInstance = Template.instance()
          viewmodel = templateInstance.viewmodel
          eventFunction.call viewmodel, e, t
        template.events eventObj
  return

Blaze.Template.prototype.createViewModel = (context) ->
  template = this
  initial = ViewModel.getInitialObject template.viewmodelInitial, context
  viewmodel = new ViewModel(initial)
  viewmodel.vmInitial = initial
  viewmodel

htmls = { }
Blaze.Template.prototype.elementBind = (selector, data) ->
  name = this.viewName
  html = null
  if data
    html = $("<div></div>").append($(Blaze.toHTMLWithData(this, data)))
  else if htmls[name]
    html = htmls[name]
  else
    html = $("<div></div>").append($(Blaze.toHTML(this)))
    htmls[name] = html

  bindId = html.find(selector).attr("b-id")
  bindOject = ViewModel.bindObjects[bindId]
  return bindOject

Template.registerHelper 'vmRef', (prop) ->
  instance = Template.instance()
  return () ->
    return instance.viewmodel[prop]