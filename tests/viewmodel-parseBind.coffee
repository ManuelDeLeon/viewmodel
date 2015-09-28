describe "ViewModel", ->

  beforeEach ->
    @checkStub = sinon.stub ViewModel, "check"

  afterEach ->
    sinon.restoreAll()

  describe "@parseBind", ->

    it "checks the arguments", ->
      ViewModel.parseBind "X"
      assert.isTrue @checkStub.calledWithExactly('@parseBind', "X")