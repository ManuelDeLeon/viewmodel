_bindingToken = RegExp("\"(?:[^\"\\\\]|\\\\.)*\"|'(?:[^'\\\\]|\\\\.)*'|/(?:[^/\\\\]|\\\\.)*/w*|[^\\s:,/][^,\"'{}()/:[\\]]*[^\\s,\"'{}()/:[\\]]|[^\\s]","g")
_divisionLookBehind = /[\])"'A-Za-z0-9_$]+$/
_keywordRegexLookBehind =
  in: 1
  return: 1
  typeof: 1

ViewModel.parseBind = (objectLiteralString) ->
  str = $.trim(objectLiteralString)
  str = str.slice(1, -1) if str.charCodeAt(0) is 123
  result = {}
  toks = str.match(_bindingToken)
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
        match = toks[i-1].match(_divisionLookBehind)
        if match and not _keywordRegexLookBehind[match[0]]
          str = str.substr(str.indexOf(tok) + 1)
          toks = str.match(_bindingToken)
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
  return result