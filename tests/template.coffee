describe "Template", ->

  beforeEach ->
    @checkStub = sinon.stub ViewModel, "check"
    @vmOnCreatedStub = sinon.stub ViewModel, "onCreated"
    @vmOnRenderedStub = sinon.stub ViewModel, "onRendered"

  afterEach ->
    sinon.restoreAll()

  describe "#viewmodel", ->
    beforeEach ->
      @context =
        onCreated: ->
        onRendered: ->
      @templateOnCreatedStub = sinon.stub(@context, "onCreated")
      @templateOnRenderedStub = sinon.stub(@context, "onRendered")

    it "checks the arguments", ->
      Template.prototype.viewmodel.call @context, "X"
      assert.isTrue @checkStub.calledWithExactly 'T#viewmodel', "X", @context

    it "saves the initial object", ->
      Template.prototype.viewmodel.call @context, "X"
      assert.equal "X", @context.viewmodelInitial

    it "adds onCreated ", ->
      @vmOnCreatedStub.returns "Y"
      Template.prototype.viewmodel.call @context, "X"
      assert.isTrue @vmOnCreatedStub.calledWithExactly(@context)
      assert.isTrue @templateOnCreatedStub.calledWithExactly("Y")

    it "returns undefined", ->
      assert.isUndefined Template.prototype.viewmodel.call(@context, "X")


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
