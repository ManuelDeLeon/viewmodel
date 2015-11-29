describe "Template", ->

  beforeEach ->
    @checkStub = sinon.stub ViewModel, "check"
    @vmOnCreatedStub = sinon.stub ViewModel, "onCreated"
    @vmOnRenderedStub = sinon.stub ViewModel, "onRendered"
    @vmOnDestroyedStub = sinon.stub ViewModel, "onDestroyed"

  afterEach ->
    sinon.restoreAll()

  describe "#viewmodel", ->
    beforeEach ->
      @context =
        onCreated: ->
        onRendered: ->
        onDestroyed: ->
      @templateOnCreatedStub = sinon.stub(@context, "onCreated")
      @templateOnRenderedStub = sinon.stub(@context, "onRendered")
      @templateOnDestroyedStub = sinon.stub(@context, "onDestroyed")

    it "checks the arguments", ->
      Template.prototype.viewmodel.call @context, "X"
      assert.isTrue @checkStub.calledWithExactly 'T#viewmodel', "X", @context

    it "saves the initial object", ->
      Template.prototype.viewmodel.call @context, "X"
      assert.equal "X", @context.viewmodelInitial

    it "adds onCreated", ->
      @vmOnCreatedStub.returns "Y"
      Template.prototype.viewmodel.call @context, "X"
      assert.isTrue @vmOnCreatedStub.calledWithExactly(@context)
      assert.isTrue @templateOnCreatedStub.calledWithExactly("Y")

    it "adds onRendered", ->
      @vmOnRenderedStub.returns "Y"
      Template.prototype.viewmodel.call @context, "X"
      assert.isTrue @vmOnRenderedStub.calledWithExactly("X")
      assert.isTrue @templateOnRenderedStub.calledWithExactly("Y")

    it "adds onDestroyed", ->
      @vmOnDestroyedStub.returns "Y"
      Template.prototype.viewmodel.call @context, "X"
      assert.isTrue @vmOnDestroyedStub.called
      assert.isTrue @templateOnDestroyedStub.calledWithExactly("Y")
      
    it "returns undefined", ->
      assert.isUndefined Template.prototype.viewmodel.call(@context, "X")

    it "adds the events", ->
      called = []
      initial =
        events:
          a: null
          b: null
      @context.events = (eventObj) -> called.push eventObj
      Template.prototype.viewmodel.call @context, initial
      assert.isFunction called[0].a
      assert.isFunction called[1].b
      assert.equal called.length, 2

  describe "#createViewModel", ->
    beforeEach ->
      @createViewModel = Template.prototype.createViewModel
      @getInitialObjectStub = sinon.stub ViewModel, 'getInitialObject'
      @getInitialObjectStub.returns "X"
      @template =
        viewmodelInitial: "A"

    it "checks the arguments", ->
      @createViewModel.call @template, "B"
      assert.isTrue @checkStub.calledWithExactly 'T#createViewModel', "B", @template

    it "calls getInitialObject", ->
      @createViewModel.call @template, "B"
      assert.isTrue @getInitialObjectStub.calledWith("A", "B")

    it "returns a view model", ->
      vm = @createViewModel.call @template, "B"
      assert.isTrue vm instanceof ViewModel
