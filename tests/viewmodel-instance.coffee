describe "ViewModel instance", ->

  beforeEach ->
    @checkStub = sinon.stub ViewModel, "check"
    @viewmodel = new ViewModel()

  afterEach ->
    sinon.restoreAll()

  describe "constructor", ->
    it "checks the arguments", ->
      obj = { name: 'A'}
      vm = new ViewModel obj
      assert.isTrue @checkStub.calledWith '#constructor', obj

    it "adds property as function", ->
      vm = new ViewModel({ name: 'A'})
      assert.isFunction vm.name
      assert.equal 'A', vm.name()
      vm.name('B')
      assert.equal 'B', vm.name()

    it "adds properties in load object", ->
      obj = { name: "A" }
      vm = new ViewModel
        load: obj
      assert.equal 'A', vm.name()

    it "adds properties in load array", ->
      arr = [ { name: "A" }, { age: 1 } ]
      vm = new ViewModel
        load: arr
      assert.equal 'A', vm.name()
      assert.equal 1, vm.age()

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

  describe "#load", ->

    it "adds a property to the view model", ->
      @viewmodel.load({ name: 'Alan' })
      assert.equal 'Alan', @viewmodel.name()

    it "adds a properties from an array", ->
      @viewmodel.load([{ name: 'Alan' },{ two: 'Brito' }])
      assert.equal 'Alan', @viewmodel.name()
      assert.equal 'Brito', @viewmodel.two()

    it "adds function to the view model", ->
      f = ->
      @viewmodel.load({ fun: f })
      assert.equal f, @viewmodel.fun

    it "doesn't create a new property when extending the same name", ->
      @viewmodel.load({ name: 'Alan' })
      old = @viewmodel.name
      @viewmodel.load({ name: 'Brito' })
      assert.equal 'Brito', @viewmodel.name()
      assert.equal old, @viewmodel.name

    it "doesn't do anything with null and undefined", ->
      @viewmodel.load(undefined )
      @viewmodel.load(null)

  describe "#parent", ->

    beforeEach ->
      @viewmodel.templateInstance =
        view:
          parentView:
            name: 'Template.A'
            templateInstance: ->
              viewmodel: "X"

    it "returns the view model of the parent template", ->
      parent = @viewmodel.parent()
      assert.equal "X", parent

    it "checks the arguments", ->
      @viewmodel.parent('X')
      assert.isTrue @checkStub.calledWith '#parent', 'X'

  describe "#children", ->

    beforeEach ->
      @viewmodel.children().push
        age: -> 1
        name: -> "AA"
        templateInstance:
          view:
            name: 'Template.A'
      @viewmodel.children().push
        age: -> 2
        name: -> "BB"
        templateInstance:
          view:
            name: 'Template.B'
      @viewmodel.children().push
        age: -> 1
        templateInstance:
          view:
            name: 'Template.A'

    it "returns all without arguments", ->
      assert.equal 3, @viewmodel.children().length
      @viewmodel.children().push("X")
      assert.equal 4, @viewmodel.children().length
      assert.equal "X", @viewmodel.children()[3]

    it "returns by template when passed a string", ->
      arr = @viewmodel.children('A')
      assert.equal 2, arr.length
      assert.equal 1, arr[0].age()
      assert.equal 1, arr[1].age()

    it "returns array from a predicate", ->
      arr = @viewmodel.children((vm) -> vm.age() is 2)
      assert.equal 1, arr.length
      assert.equal "BB", arr[0].name()

    it "calls .depend", ->
      array = @viewmodel.children()
      spy = sinon.spy array, 'depend'
      @viewmodel.children()
      assert.isTrue spy.called

    it "doesn't check without arguments", ->
      @viewmodel.children()
      assert.isFalse @checkStub.calledWith '#children'

    it "checks with arguments", ->
      @viewmodel.children('X')
      assert.isTrue @checkStub.calledWith '#children', 'X'

  describe "#reset", ->

    beforeEach ->
      @viewmodel.templateInstance =
        view:
          name: 'body'
      @viewmodel.load
        name: 'A'
        arr: ['A']

    it "resets a string", ->
      @viewmodel.name('B')
      @viewmodel.reset()
      assert.equal "A", @viewmodel.name()

    it "resets an array", ->
      @viewmodel.arr().push('B')
      @viewmodel.reset()
      assert.equal 1, @viewmodel.arr().length
      assert.equal 'A', @viewmodel.arr()[0]

  describe "#data", ->

    beforeEach ->
      @viewmodel.load
        name: 'A'
        arr: ['B']

    it "creates js object", ->
      obj = @viewmodel.data()
      assert.equal 'A', obj.name
      assert.equal 'B', obj.arr[0]
      return

    it "only loads fields specified", ->
      obj = @viewmodel.data(['name'])
      assert.equal 'A', obj.name
      assert.isUndefined obj.arr
      return

  describe "#load", ->

    beforeEach ->
      @viewmodel.load
        name: 'A'
        age: 2
        f: -> 'X'

    it "loads js object", ->
      @viewmodel.load
        name: 'B'
        f: -> 'Y'
      assert.equal 'B', @viewmodel.name()
      assert.equal 2, @viewmodel.age()
      assert.equal 'Y', @viewmodel.f()
      return

  describe "mixin", ->

    beforeEach ->
      ViewModel.mixin
        house:
          address: 'A'
        person:
          name: 'X'

    it "adds property to vm", ->
      vm = new ViewModel
        mixin: 'house'
      assert.equal 'A', vm.address()

    it "adds property to vm from array", ->
      vm = new ViewModel
        mixin: ['house']
      assert.equal 'A', vm.address()

    it "doesn't share the property", ->
      vm1 = new ViewModel
        mixin: 'house'
      vm2 = new ViewModel
        mixin: 'house'
      vm2.address 'B'
      assert.equal 'A', vm1.address()
      assert.equal 'B', vm2.address()

    it "adds object to vm", ->
      vm = new ViewModel
        mixin:
          location: 'house'
      assert.equal 'A', vm.location.address()

    it "adds array to vm", ->
      vm = new ViewModel
        mixin:
          location: ['house', 'person']
      assert.equal 'A', vm.location.address()
      assert.equal 'X', vm.location.name()

  describe "share", ->

    beforeEach ->
      ViewModel.share
        house:
          address: 'A'
        person:
          name: 'X'

    it "adds property to vm", ->
      vm = new ViewModel
        share: 'house'
      assert.equal 'A', vm.address()

    it "adds property to vm from array", ->
      vm = new ViewModel
        share: ['house']
      assert.equal 'A', vm.address()

    it "adds object to vm", ->
      vm = new ViewModel
        share:
          location: 'house'
      assert.equal 'A', vm.location.address()

    it "shares the property", ->
      vm1 = new ViewModel
        share: 'house'
      vm2 = new ViewModel
        share: 'house'
      vm2.address 'B'
      assert.equal 'B', vm1.address()
      assert.equal 'B', vm2.address()
      assert.equal vm1.address, vm1.address

    it "adds array to vm", ->
      vm = new ViewModel
        share:
          location: ['house', 'person']
      assert.equal 'A', vm.location.address()
      assert.equal 'X', vm.location.name()