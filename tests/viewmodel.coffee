describe "ViewModel", ->

  beforeEach ->
    @checkStub = sinon.stub ViewModel, "check"

  afterEach ->
    sinon.restoreAll()

  describe "constructor", ->
    it "adds property as function", ->
      vm = new ViewModel({ name: 'A'})
      assert.isFunction vm.name
      assert.equal 'A', vm.name()
      vm.name('B')
      assert.equal 'B', vm.name()

    it "doesn't convert functions", ->
      f = ->
      vm = new ViewModel
        fun: f
      assert.equal f, vm.fun

  describe "@nextId", ->
    it "increments the numbers", ->
      a = ViewModel.nextId()
      b = ViewModel.nextId()
      assert.equal b, a + 1

  describe "@reserved", ->
    it "has reserved words", ->
      assert.ok ViewModel.reserved.vmId

  describe "@onCreated", ->

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

      it "adds templateInstance to the view model", ->
        @retFun.call @instance
        assert.equal @instance.viewmodel.templateInstance, @instance

      it "adds view model properties as helpers", ->
        @retFun.call @instance
        assert.ok @helper.id

      it "doesn't add reserved words as helpers", ->
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

  describe "@getInitialObject", ->
    it "returns initial when initial is an object", ->
      initial = {}
      context = "X"
      ret = ViewModel.getInitialObject(initial, context)
      assert.equal initial, ret

    it "returns the result of the function when initial is a function", ->
      initial = (context) -> context + 1
      context = 1
      ret = ViewModel.getInitialObject(initial, context)
      assert.equal 2, ret

  describe "@makeReactiveProperty", ->
    it "returns a function", ->
      assert.isFunction ViewModel.makeReactiveProperty("X")
    it "sets default value", ->
      actual = ViewModel.makeReactiveProperty("X")
      assert.equal "X", actual()
    it "sets and gets values", ->
      actual = ViewModel.makeReactiveProperty("X")
      actual("Y")
      assert.equal "Y", actual()
    it "resets the value", ->
      actual = ViewModel.makeReactiveProperty("X")
      actual("Y")
      actual.reset()
      assert.equal "X", actual()
    it "has depend and changed", ->
      actual = ViewModel.makeReactiveProperty("X")
      assert.isFunction actual.depend
      assert.isFunction actual.changed
    it "reactifies arrays", ->
      actual = ViewModel.makeReactiveProperty([])
      assert.isTrue actual() instanceof ReactiveArray

    it "resets arrays", ->
      actual = ViewModel.makeReactiveProperty([1])
      actual().push(2)
      assert.equal 2, actual().length
      actual.reset()
      assert.equal 1, actual().length
      assert.equal 1, actual()[0]