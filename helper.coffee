class @Helper
  @isObject = (obj) -> Object.prototype.toString.call(obj) is '[object Object]'
  @isString = (obj) -> Object.prototype.toString.call(obj) is '[object String]'
  @isArray = (obj) -> obj instanceof Array
  @isElement = (o) -> (if typeof HTMLElement is "object" then o instanceof HTMLElement else o and typeof o is "object" and o isnt null and o.nodeType is 1 and typeof o.nodeName is "string")

  @delayed = { }
  @delay = (time, nameOrFunc, fn) ->
    func = fn || nameOrFunc
    name = nameOrFunc if fn
    d = @delayed[name] if name
    Meteor.clearTimeout d if d?
    id = Meteor.setTimeout func, time
    @delayed[name] = id if name

  bindingToken = RegExp("\"(?:[^\"\\\\]|\\\\.)*\"|'(?:[^'\\\\]|\\\\.)*'|/(?:[^/\\\\]|\\\\.)*/w*|[^\\s:,/][^,\"'{}()/:[\\]]*[^\\s,\"'{}()/:[\\]]|[^\\s]","g")
  divisionLookBehind = /[\])"'A-Za-z0-9_$]+$/
  keywordRegexLookBehind =
    in: 1
    return: 1
    typeof: 1

  @parseBind = (objectLiteralString) ->
    str = $.trim(objectLiteralString)
    str = str.slice(1, -1) if str.charCodeAt(0) is 123
    result = {}
    toks = str.match(bindingToken)
    depth = 0
    key = undefined
    values = undefined
    if toks
      toks.push ','
      i = -1
      tok = undefined
      while tok = toks[++i]
        c = tok.charCodeAt(0)
        if c is 44
          if depth <= 0
            if key
              unless values
                result['unknown'] = key
              else
                v = values.join ''
                v = @parseBind(v) if v.indexOf('{') is 0
                result[key] = v
            key = values = depth = 0
            continue
        else if c is 58
          unless values
            continue
        else if c is 47 and i and tok.length > 1
          match = toks[i-1].match(divisionLookBehind)
          if match and not keywordRegexLookBehind[match[0]]
            str = str.substr(str.indexOf(tok) + 1)
            toks = str.match(bindingToken)
            toks.push(',')
            i = -1
            tok = '/'
        else if c in [40, 123, 91]
          ++depth
        else if c in [41, 125, 93]
          --depth
        else if not key and not values
          key = (if (c is 34 or c is 39) then tok.slice(1, -1) else tok)
          continue

        if values
          values.push tok
        else
          values = [tok]
    result

  @reservedWords = ['_vm_properties', '_vm_reservedWords','bind', 'extend', 'addHelper', 'addHelpers', 'toJS', 'fromJS', '_vm_id', 'dispose', 'reset', 'parent', '_vm_addDelayedProperty', '_vm_delayed', '_vm_toJS', 'blaze_events', 'blaze_helpers', 'onRendered', 'onCreated', 'onDestroyed', '_vm_hasId', 'templateInstance', 'autorun', '_vm_children', 'children']

