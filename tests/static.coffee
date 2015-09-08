describe "ViewModel2", ->
  it "should have bindings object", (t) ->
    t.isTrue _.isObject(ViewModel2.bindings)
  it "should not ignoreErrors", (t) ->
    t.isUndefined ViewModel2.ignoreErrors

  context "addBinding", ->
    it "should not accept a string", (t) ->
      t.throws ->
        ViewModel2.addBinding ""
    it "should not accept an object without a name", (t) ->
      t.throws ->
        ViewModel2.addBinding {}
    it "should not accept an object without a name string", (t) ->
      t.throws ->
        ViewModel2.addBinding { name: 1 }
    it "should not accept an object without an empty name", (t) ->
      t.throws ->
        ViewModel2.addBinding { name: " ", bind: (->) }
    it "should not accept an object without a bind function 1", (t) ->
      t.throws ->
        ViewModel2.addBinding { name: "value" }
    it "should not accept an object without a bind function 2", (t) ->
      t.throws ->
        ViewModel2.addBinding { name: "value", bind: 1 }

    it "should accept an object with a name and a bind function", (t) ->
      ViewModel2.bindings = {}
      ViewModel2.addBinding { name: "value", bind: (->) }
      t.equal _.size(ViewModel2.bindings), 1

    it "bindIf has to be a function", (t) ->
      t.throws ->
        ViewModel2.addBinding { name: "value", bind: (->), bindIf: 1 }

    it "selector has to be a string", (t) ->
      t.throws ->
        ViewModel2.addBinding { name: "value", bind: (->), selector: 1 }

    it "events has to be an object", (t) ->
      t.throws ->
        ViewModel2.addBinding { name: "value", bind: (->), events: 1 }