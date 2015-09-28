describe "ViewModel", ->

  beforeEach ->
    @checkStub = sinon.stub ViewModel, "check"

  afterEach ->
    sinon.restoreAll()

  describe "@nextId", ->
    it "increments the numbers", ->
      a = ViewModel.nextId()
      b = ViewModel.nextId()
      assert.equal b, a + 1

  describe "@reserved", ->
    it "has reserved words", ->
      assert.ok ViewModel.reserved.vmId

  describe "@onCreated", ->

    it "checks the arguments", ->
      ViewModel.onCreated "X"
      assert.isTrue @checkStub.calledWithExactly('@onCreated', "X")

    it "returns a function", ->
      assert.isFunction ViewModel.onCreated()

    describe "return function", ->

      beforeEach ->
        @helper = null
        @template =
          createViewModel: ->
            vm = new ViewModel()
            vm.vmId = ->
            vm.id = ->
            return vm
          helpers: (obj) => @helper = obj

        @retFun = ViewModel.onCreated(@template)
        @helpersSpy = sinon.spy @template, 'helpers'
        @instance =
          data: "A"

      it "sets the viewmodel property on the template instance", ->
        @retFun.call @instance
        assert.isTrue @instance.viewmodel instanceof ViewModel

      it "adds view model properties as helpers", ->
        @retFun.call @instance
        assert.ok @helper.id

      it "doesn't add reserved words to the view model", ->
        @retFun.call @instance
        assert.notOk @helper.vmId

  describe "@bindIdAttribute", ->
    it "has has default value", ->
      assert.equal "bind-id", ViewModel.bindIdAttribute

  describe "@bindHelper", ->
    beforeEach ->
      @nextIdStub = sinon.stub ViewModel, 'nextId'
      @nextIdStub.returns 99
      @onViewReadyFunction = null
      Blaze.currentView =
        onViewReady: (f) => @onViewReadyFunction = f

    it "checks the arguments", ->
      ViewModel.bindHelper "X"
      assert.isTrue @checkStub.calledWithExactly('@bindHelper', "X")

    it "returns object with the next bind id", ->
      ret = ViewModel.bindHelper()
      assert.equal ret[ViewModel.bindIdAttribute], 99

    it "binds the view model when the view is ready", ->
      viewmodel = new ViewModel()
      bindStub = sinon.stub viewmodel, 'bind'
      instanceStub = sinon.stub Template, 'instance'
      templateInstance =
        viewmodel: viewmodel
      instanceStub.returns templateInstance
      ViewModel.bindHelper("text: name")
      @onViewReadyFunction()
      assert.isTrue bindStub.calledWith 99, { text: 'name' }, templateInstance

  describe "@bindHelperName", ->
    it "has has default value", ->
      assert.equal "b", ViewModel.bindHelperName