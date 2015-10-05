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

    it "calls bindSingle for each entry in bindObject", ->
      bindObject =
        a: 1
        b: 2
      @viewmodel.bind 

