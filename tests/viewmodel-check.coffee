describe "ViewModel", ->

  describe "@check", ->
    beforeEach ->
      Package['manuel:viewmodel-debug'] =
        VmCheck: ->
      @vmCheckStub = sinon.stub Package['manuel:viewmodel-debug'], "VmCheck"

    afterEach ->
      sinon.restoreAll()

    it "doesn't check if ignoreErrors is true", ->
      ViewModel.ignoreErrors = true
      ViewModel.check()
      ViewModel.ignoreErrors = false
      assert.isFalse @vmCheckStub.called

    it "calls VmCheck with parameters", ->
      ViewModel.check 1, 2, 3
      assert.isTrue @vmCheckStub.calledWithExactly 1, 2, 3

    it "returns undefined", ->
      assert.isUndefined ViewModel.check()
