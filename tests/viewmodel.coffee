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

  describe "@addBinding", ->

    last = 1
    getBindingName = -> "test" + last++

    it "checks the arguments", ->
      ViewModel.addBinding "X"
      assert.isTrue @checkStub.calledWithExactly('@addBinding', "X")

    it "returns nothing", ->
      ret = ViewModel.addBinding "X"
      assert.isUndefined ret

    it "adds the binding to @bindings", ->
      name = getBindingName()
      ViewModel.addBinding
        name: name
        bind: -> "X"
      assert.equal 1, ViewModel.bindings[name].length
      assert.equal "X", ViewModel.bindings[name][0].bind()

    it "adds the binding to @bindings array", ->
      name = getBindingName()
      ViewModel.addBinding
        name: name
        bind: -> "X"
      ViewModel.addBinding
        name: name
        bind: -> "Y"
      assert.equal 2, ViewModel.bindings[name].length
      assert.equal "X", ViewModel.bindings[name][0].bind()
      assert.equal "Y", ViewModel.bindings[name][1].bind()

    it "adds default priority 1 to the binding", ->
      name = getBindingName()
      ViewModel.addBinding
        name: name
      assert.equal 1, ViewModel.bindings[name][0].priority

    it "adds priority 2 with a selector", ->
      name = getBindingName()
      ViewModel.addBinding
        name: name
        selector: 'A'
      assert.equal 2, ViewModel.bindings[name][0].priority

    it "adds priority 2 with a bindIf", ->
      name = getBindingName()
      ViewModel.addBinding
        name: name
        bindIf: ->
      assert.equal 2, ViewModel.bindings[name][0].priority

    it "adds priority 3 with a selector and bindIf", ->
      name = getBindingName()
      ViewModel.addBinding
        name: name
        selector: 'A'
        bindIf: ->
      assert.equal 3, ViewModel.bindings[name][0].priority

  ##################
  # Instance methods

  describe "#bind", ->

    beforeEach ->
      @viewmodel = new ViewModel()

    xit "checks the arguments", ->
      @viewmodel.bind "A", "B", "C"
      assert.isTrue @checkStub.calledWithExactly('@addBinding', "A", "B", "C", ViewModel.bindings)
