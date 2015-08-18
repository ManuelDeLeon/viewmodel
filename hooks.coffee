getArgumentResult = (arg, data) ->
  if arg instanceof Function
    return arg(data)
  return arg

((history) ->
  pushState = history.pushState
  replaceState = history.replaceState

  history.pushState = (state, title, url) ->
    if typeof history.onstatechange is 'function'
      history.onstatechange state, title, url
    pushState.apply history, arguments
  history.replaceState = (state) ->
    if typeof history.onstatechange is 'function'
      history.onstatechange state, title, url
    replaceState.apply history, arguments
  return
) window.history

Blaze.Template.prototype.createViewModel = (data) ->
  template = this
  argCount = 0
  vmName = null
  vmObjects = []
  for arg in template.viewmodelArgs
    argCount++
    argResult = getArgumentResult(arg, data)
    if argCount is 1
      if VmHelper.isString argResult
        vmName = argResult
      else
        vmObjects.push argResult
    else if argCount is template.viewmodelArgs.length
      if not (VmHelper.isString(argResult) or argResult instanceof Array)
        vmObjects.push argResult
    else
      vmObjects.push argResult
  viewmodel = new ViewModel vmName, {}
  for obj in vmObjects when obj
    viewmodel.extend obj
  viewmodel._vm_autoruns = (obj.autorun for obj in vmObjects when obj?.autorun)
  viewmodel

Blaze.Template.prototype.viewmodel = ->
  template = this
  args = arguments
  template.viewmodelArgs = args
  argTotal = args.length
  vmHelpers = []
  lastArg = args[argTotal - 1]
  if VmHelper.isString lastArg
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

  created = false
  template.onCreated ->
    this.viewmodel = template.createViewModel(this.data)
    this.viewmodel.templateInstance = this;
    this.viewmodel._vm_addParent this.viewmodel, this
    if this.viewmodel.onCreated
      this.viewmodel.onCreated this

    if onUrl = this.viewmodel.onUrl
      that = this
      if not that.viewmodel._vm_hasId
        if Meteor.isDev
          console.log "Cannot save state on the URL for a view model without a name"
      else
        props = if _.isArray(onUrl) then onUrl else [onUrl]
        tName = that.viewmodel._vm_id.substring("_vm_".length)
        tName = encodeURI(tName)
        tName = tName.split('.').join("%2E") if ~tName.indexOf(".")
        # Update URL from view model
        this.autorun (c) ->
          url = window.location.href
          for prop in props
            if that.viewmodel[prop]
              value = that.viewmodel[prop]() or ""
              url = VmHelper.updateQueryString( tName + "." + encodeURI(prop), value.toString(), url)
            else
              if Meteor.isDev
                console.log "View model '#{that.viewmodel._vm_id}' doesn't have property '#{prop}'"
          window.history.pushState(null, null, url) if not c.firstRun and document.URL isnt url

        # Update view model from URL
        updateFromUrl = (state, title, url = document.URL) ->
          for key, value of VmHelper.url(url).queryKey when ~key.indexOf(".")
            [template, property] = key.split(".")
            property = decodeURI(property)
            if property in props
              if template is tName
                that.viewmodel[property] decodeURI(value)
        window.onpopstate = window.history.onstatechange = updateFromUrl
        updateFromUrl()


    if not created
      if this.viewmodel.blaze_helpers
        helpers = this.viewmodel.blaze_helpers
        template.helpers( if _.isFunction(helpers) then helpers() else helpers )

      if this.viewmodel.blaze_events
        events = this.viewmodel.blaze_events
        template.events( if _.isFunction(events) then events() else events )
    created = true

  template.onRendered ->
    that = this
    if this.viewmodel._vm_autoruns?.length
      for autorun in this.viewmodel._vm_autoruns
        do (autorun) ->
          that.autorun (c) ->
            autorun.call(that.viewmodel, c)

    if this.viewmodel.beforeBind
      this.viewmodel.beforeBind this

    if this.viewmodel.onRendered
      this.viewmodel.onRendered this

    this.viewmodel.bind this

    if this.viewmodel.afterBind
      this.viewmodel.afterBind this

  template.onDestroyed ->
    if this.viewmodel.onDestroyed
      this.viewmodel.onDestroyed this
    this.viewmodel.dispose()

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
  
  ViewModel.parseBind(html.find(selector).data("bind"))