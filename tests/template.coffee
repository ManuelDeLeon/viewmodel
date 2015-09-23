describe "Template Instance", ->
  beforeEach ->
    @checkStub = sinon.stub ViewModel, "check"

  afterEach ->
    @checkStub.restore()

  it "has viewmodel method", ->
    assert.isFunction Template.prototype.viewmodel

  it "checks the arguments", ->
    Template.prototype.viewmodel()
    assert.isTrue @checkStub.calledOnce


#describe "Template", ->
#  context "viewmodel method", ->
#    cache = {}
#    cacheValues = ->
#      cache['check'] = ViewModel2.check
#      cache['created'] = ViewModel2.onCreated
#      ViewModel2.check = ->
#      ViewModel2.onCreated = ->
#
#
#    restoreValues = ->
#      ViewModel2.check = cache['check']
#      ViewModel2.onCreated = cache['created']
#
#    it "should have it", (t) ->
#      t.isTrue _.isFunction Blaze.Template.prototype.viewmodel
#
#    it "should check the arguments", (t) ->
#      cacheValues()
#      template =
#        onCreated: ->
#      used = null
#      ViewModel2.check = (args...) -> used = args
#      Blaze.Template.prototype.viewmodel.call template, "X"
#      restoreValues()
#      t.equal used.length, 2
#      t.equal used[0], "T@viewmodel"
#      t.equal used[1], "X"
#
#    it "should not return anything", (t) ->
#      cacheValues()
#      template =
#        onCreated: ->
#      ret = Blaze.Template.prototype.viewmodel.call template, "X"
#      restoreValues()
#      t.isUndefined ret
#
#    it "should set vmInitial", (t) ->
#      cacheValues()
#      template =
#        onCreated: ->
#      Blaze.Template.prototype.viewmodel.call template, "X"
#      restoreValues()
#      t.equal "X", template.vmInitial
#
#    it "should call onCreated", (t) ->
#      cacheValues()
#      called = false
#      template =
#        onCreated: (obj) ->
#          called = obj is template
#      ViewModel2.onCreated = (v) -> v
#      Blaze.Template.prototype.viewmodel.call template, "X"
#      restoreValues()
#      t.isTrue called