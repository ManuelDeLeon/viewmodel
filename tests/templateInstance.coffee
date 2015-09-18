describe "Template Instance", ->
  context "viewmodel method", ->
    it "should have it", (t) ->
      t.isTrue _.isFunction Blaze.Template.prototype.viewmodel

    it "should check the arguments", (t) ->
      cache = ViewModel2.check
      used = null
      ViewModel2.check = (args...) -> used = args
      Blaze.Template.prototype.viewmodel "X"
      ViewModel2.check = cache
      t.equal used.length, 2
      t.equal used[0], "T@viewmodel"
      t.equal used[1], "X"

    it "should not return anything", (t) ->
      cache = ViewModel2.check
      ViewModel2.check = ->
      ret = Blaze.Template.prototype.viewmodel "X"
      ViewModel2.check = cache
      t.isUndefined ret

