describe "Template", ->

  beforeEach ->
    @checkStub = sinon.stub ViewModel, "check"
    @vmOnCreatedStub = sinon.stub ViewModel, "onCreated"

  afterEach ->
    sinon.restoreAll()

  describe "#viewmodel", ->
    beforeEach ->
      @context =
        onCreated: ->
      @templateOnCreatedSpy = sinon.spy(@context, "onCreated")

    it "checks the arguments", ->
      Template.prototype.viewmodel.call @context, "X"
      assert.isTrue @checkStub.calledWithExactly('T#viewmodel', "X")

    it "saves the initial object", ->
      Template.prototype.viewmodel.call @context, "X"
      assert.equal "X", @context.viewmodelInitial

    it "adds onCreated ", ->
      @vmOnCreatedStub.returns "Y"
      Template.prototype.viewmodel.call @context, "X"
      assert.isTrue @vmOnCreatedStub.calledWithExactly(@context)
      assert.isTrue @templateOnCreatedSpy.calledWithExactly("Y")

    it "returns undefined", ->
      assert.isUndefined Template.prototype.viewmodel.call(@context, "X")


  describe "#createViewModel", ->
    beforeEach ->
      @createViewModel = Template.prototype.createViewModel
      @template =
        viewmodelInitial: {}

