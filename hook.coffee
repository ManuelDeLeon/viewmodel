isString = (obj) -> Object.prototype.toString.call(obj) is '[object String]'

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
  if isString lastArg
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

  this.onCreated ->
    templateInstance = this
    argCount = 0
    vmName = null
    vmObjects = []

    for arg in args
      argCount++
      argResult = getArgumentResult(arg, templateInstance.data)
      if argCount is 1
        if isString argResult
          vmName = argResult
        else
          vmObjects.push argResult
      else if argCount is argTotal
        if not (isString(argResult) or argResult instanceof Array)
          vmObjects.push argResult
      else
        vmObjects.push argResult
    templateInstance.viewmodel = new ViewModel vmName, {}
    for obj in vmObjects
      templateInstance.viewmodel.extend obj

  this.onRendered ->
    this.viewmodel.bind this

  this.onDestroyed ->
    this.viewmodel.dispose()