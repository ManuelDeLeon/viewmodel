getArgumentResult = (arg, data) ->
  if arg instanceof Function
    return arg(data)
  return arg
    
Blaze.Template.prototype.viewmodel = ->
  template = this
  args = arguments
  argTotal = args.length
  vmHelpers = []
  lastArg = args[argTotal - 1]
  if Helper.isString lastArg
    vmHelpers.push lastArg
  else if lastArg instanceof Array
    for helper in lastArg
      vmHelpers.push helper

  for helperName in vmHelpers
    do (helperName) ->
      helper = {}
      helper[helperName] = ->
        Template.instance().viewmodel[helperName]()
      template.helpers helper

  template.onCreated ->
    templateInstance = this
    argCount = 0
    vmName = null
    vmObjects = []

    for arg in args
      argCount++
      argResult = getArgumentResult(arg, templateInstance.data)
      if argCount is 1
        if Helper.isString argResult
          vmName = argResult
        else
          vmObjects.push argResult
      else if argCount is argTotal
        if not (Helper.isString(argResult) or argResult instanceof Array)
          vmObjects.push argResult
      else
        vmObjects.push argResult
    templateInstance.viewmodel = new ViewModel vmName, {}
    for obj in vmObjects
      templateInstance.viewmodel.extend obj

    if this.viewmodel.onCreated
      this.viewmodel.onCreated this

    if this.viewmodel.blaze_helpers
      template.helpers this.viewmodel.blaze_helpers()

    if this.viewmodel.blaze_events
      template.events this.viewmodel.blaze_events()

  template.onRendered ->
    if this.viewmodel.onRendered
      this.viewmodel.onRendered this
    this.viewmodel.bind this

  template.onDestroyed ->
    if this.viewmodel.onDestroyed
      this.viewmodel.onDestroyed this
    this.viewmodel.dispose()