describe "ViewModel2 Static", ->
  it "should have bindings object", (t) ->
    t.isTrue _.isObject(ViewModel2.bindings)
  it "should not ignoreErrors", (t) ->
    t.isUndefined ViewModel2.ignoreErrors

  context "addBinding", ->
    it "should check the arguments", (t) ->
      cache = ViewModel2.check
      used = null
      ViewModel2.check = (args...) -> used = args
      ViewModel2.addBinding "X"
      ViewModel2.check = cache
      t.equal used.length, 2
      t.equal used[0], "@@addBinding"
      t.equal used[1], "X"

    it "should not return anything", (t) ->
      cache = ViewModel2.check
      ViewModel2.check = ->
      ret = ViewModel2.addBinding "X"
      ViewModel2.check = cache
      t.isUndefined ret

  context "check", ->
    it "should not check with ignoreErrors true", (t) ->
      ignoreErrorsCache = ViewModel2.ignoreErrors
      debugCache = Package['manuel:viewmodel-debug']
      used = false
      ViewModel2.ignoreErrors = true
      Package['manuel:viewmodel-debug'] =
        VmCheck: -> used = true
      ViewModel2.check "A", "B"
      Package['manuel:viewmodel-debug'] = debugCache
      ViewModel2.ignoreErrors = ignoreErrorsCache
      t.isFalse used

    it "should check by default", (t) ->
      debugCache = Package['manuel:viewmodel-debug']
      used = false
      Package['manuel:viewmodel-debug'] =
        VmCheck: -> used = true
      ViewModel2.check "A", "B"
      Package['manuel:viewmodel-debug'] = debugCache
      t.isTrue used

    it "should return undefined", (t) ->
      ignoreErrorsCache = ViewModel2.ignoreErrors
      ViewModel2.ignoreErrors = true
      ret = ViewModel2.check()
      ViewModel2.ignoreErrors = ignoreErrorsCache
      t.isUndefined ret