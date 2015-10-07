describe "ViewModel instance", ->

  beforeEach ->
    @checkStub = sinon.stub ViewModel, "check"
    @viewmodel = new ViewModel()

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

  describe "#bind", ->

    beforeEach ->
      @bindSingleStub = sinon.stub ViewModel, 'bindSingle'

    it "checks the arguments", ->
      @viewmodel.bind {}
      assert.isTrue @checkStub.calledWith '#bind'

    it "calls bindSingle for each entry in bindObject", ->
      bindObject =
        a: 1
        b: 2
      vm = {}
      bindings =
        a: 1
        b: 2
      @viewmodel.bind.call vm, bindObject, 'templateInstance', 'element', bindings
      assert.isTrue @bindSingleStub.calledTwice
      assert.isTrue @bindSingleStub.calledWith 'templateInstance', 'element', 'a', 1, bindObject, vm, bindings
      assert.isTrue @bindSingleStub.calledWith 'templateInstance', 'element', 'b', 2, bindObject, vm, bindings

    it "returns undefined", ->
      bindObject = {}
      ret = @viewmodel.bind bindObject, 'templateInstance', 'element', 'bindings'
      assert.isUndefined ret
