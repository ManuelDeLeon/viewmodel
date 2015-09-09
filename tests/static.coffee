describe "ViewModel2", ->
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