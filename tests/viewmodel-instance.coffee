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

    describe "loading hooks direct", ->
      beforeEach ->
        ViewModel.mixins = {}
        ViewModel.mixin
          hooksMixin:
            onCreated: -> 'onCreatedMixin'
            onRendered: -> 'onRenderedMixin'
            onDestroyed: -> 'onDestroyedMixin'
            autorun: -> 'autorunMixin'
        ViewModel.shared = {}
        ViewModel.share
          hooksShare:
            onCreated: -> 'onCreatedShare'
            onRendered: -> 'onRenderedShare'
            onDestroyed: -> 'onDestroyedShare'
            autorun: -> 'autorunShare'
              
        @viewmodel = new ViewModel
          share: 'hooksShare'
          mixin: 'hooksMixin'
          load:
            onCreated: -> 'onCreatedLoad'
            onRendered: -> 'onRenderedLoad'
            onDestroyed: -> 'onDestroyedLoad'
            autorun: -> 'autorunLoad'
          onCreated: -> 'onCreatedBase'
          onRendered: -> 'onRenderedBase'
          onDestroyed: -> 'onDestroyedBase'
          autorun: -> 'autorunBase'
        return

      it "adds hooks to onCreated", ->
        assert.equal @viewmodel.vmOnCreated.length, 4
        assert.equal @viewmodel.vmOnCreated[0](), 'onCreatedShare'
        assert.equal @viewmodel.vmOnCreated[1](), 'onCreatedMixin'
        assert.equal @viewmodel.vmOnCreated[2](), 'onCreatedLoad'
        assert.equal @viewmodel.vmOnCreated[3](), 'onCreatedBase'
      it "adds hooks to onRendered", ->
        assert.equal @viewmodel.vmOnRendered.length, 4
        assert.equal @viewmodel.vmOnRendered[0](), 'onRenderedShare'
        assert.equal @viewmodel.vmOnRendered[1](), 'onRenderedMixin'
        assert.equal @viewmodel.vmOnRendered[2](), 'onRenderedLoad'
        assert.equal @viewmodel.vmOnRendered[3](), 'onRenderedBase'
      it "adds hooks to onDestroyed", ->
        assert.equal @viewmodel.vmOnDestroyed.length, 4
        assert.equal @viewmodel.vmOnDestroyed[0](), 'onDestroyedShare'
        assert.equal @viewmodel.vmOnDestroyed[1](), 'onDestroyedMixin'
        assert.equal @viewmodel.vmOnDestroyed[2](), 'onDestroyedLoad'
        assert.equal @viewmodel.vmOnDestroyed[3](), 'onDestroyedBase'
      it "adds hooks to autorun", ->
        assert.equal @viewmodel.vmAutorun.length, 4
        assert.equal @viewmodel.vmAutorun[0](), 'autorunShare'
        assert.equal @viewmodel.vmAutorun[1](), 'autorunMixin'
        assert.equal @viewmodel.vmAutorun[2](), 'autorunLoad'
        assert.equal @viewmodel.vmAutorun[3](), 'autorunBase'

    describe "loading hooks from array", ->
      beforeEach ->
        ViewModel.mixins = {}
        ViewModel.mixin
          hooksMixin:
            onCreated: [ (-> 'onCreatedMixin')]
            onRendered: [ (-> 'onRenderedMixin')]
            onDestroyed: [ (-> 'onDestroyedMixin')]
            autorun: [ (-> 'autorunMixin')]
        ViewModel.shared = {}
        ViewModel.share
          hooksShare:
            onCreated: [ (-> 'onCreatedShare')]
            onRendered: [ (-> 'onRenderedShare')]
            onDestroyed: [ (-> 'onDestroyedShare')]
            autorun: [ (-> 'autorunShare')]

        @viewmodel = new ViewModel
          share: 'hooksShare'
          mixin: 'hooksMixin'
          load:
            onCreated: [ (-> 'onCreatedLoad')]
            onRendered: [ (-> 'onRenderedLoad')]
            onDestroyed: [ (-> 'onDestroyedLoad')]
            autorun: [ (-> 'autorunLoad')]
          onCreated: [ (-> 'onCreatedBase')]
          onRendered: [ (-> 'onRenderedBase')]
          onDestroyed: [ (-> 'onDestroyedBase')]
          autorun: [ (-> 'autorunBase')]
        return

      it "adds hooks to onCreated", ->
        assert.equal @viewmodel.vmOnCreated.length, 4
        assert.equal @viewmodel.vmOnCreated[0](), 'onCreatedShare'
        assert.equal @viewmodel.vmOnCreated[1](), 'onCreatedMixin'
        assert.equal @viewmodel.vmOnCreated[2](), 'onCreatedLoad'
        assert.equal @viewmodel.vmOnCreated[3](), 'onCreatedBase'
      it "adds hooks to onRendered", ->
        assert.equal @viewmodel.vmOnRendered.length, 4
        assert.equal @viewmodel.vmOnRendered[0](), 'onRenderedShare'
        assert.equal @viewmodel.vmOnRendered[1](), 'onRenderedMixin'
        assert.equal @viewmodel.vmOnRendered[2](), 'onRenderedLoad'
        assert.equal @viewmodel.vmOnRendered[3](), 'onRenderedBase'
      it "adds hooks to onDestroyed", ->
        assert.equal @viewmodel.vmOnDestroyed.length, 4
        assert.equal @viewmodel.vmOnDestroyed[0](), 'onDestroyedShare'
        assert.equal @viewmodel.vmOnDestroyed[1](), 'onDestroyedMixin'
        assert.equal @viewmodel.vmOnDestroyed[2](), 'onDestroyedLoad'
        assert.equal @viewmodel.vmOnDestroyed[3](), 'onDestroyedBase'
      it "adds hooks to autorun", ->
        assert.equal @viewmodel.vmAutorun.length, 4
        assert.equal @viewmodel.vmAutorun[0](), 'autorunShare'
        assert.equal @viewmodel.vmAutorun[1](), 'autorunMixin'
        assert.equal @viewmodel.vmAutorun[2](), 'autorunLoad'
        assert.equal @viewmodel.vmAutorun[3](), 'autorunBase'

  describe "load order", ->
    beforeEach ->
      ViewModel.mixins = {}
      ViewModel.mixin
        name:
          name: 'mixin'
      ViewModel.shared = {}
      ViewModel.share
        name:
          name: 'share'

      ViewModel.signals = {}
      ViewModel.signal
        name:
          name:
            target: document
            event: 'keydown'

    it "loads base name last", ->
      vm = new ViewModel({
        name: 'base',
        load: {
          name: 'load'
        },
        mixin: 'name',
        share: 'name',
        signal: 'name'
      })
      assert.equal vm.name(), "base"

    it "loads from load 2nd to last", ->
      vm = new ViewModel({
        load: {
          name: 'load'
        },
        mixin: 'name',
        share: 'name',
        signal: 'name'
      })
      assert.equal vm.name(), "load"

    it "loads from mixin 3rd to last", ->
      vm = new ViewModel({
        mixin: 'name',
        share: 'name',
        signal: 'name'
      })
      assert.equal vm.name(), "mixin"

    it "loads from share 4th to last", ->
      vm = new ViewModel({
        share: 'name',
        signal: 'name'
      })
      assert.equal vm.name(), "share"

    it "loads from signal first", ->
      vm = new ViewModel({
        signal: 'name'
      })
      assert.equal _.keys(vm.name()).length, 0

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

    it "adds onRendered from an array", ->
      f = ->
      @viewmodel.load([ onRendered: f ])
      assert.equal f, @viewmodel.vmOnRendered[0]

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

    it "overwrite existing functions", ->
      @viewmodel.load({ name: -> 'Alan' })
      old = @viewmodel.name
      @viewmodel.load({ name: 'Brito' })
      theNew = @viewmodel.name
      assert.equal 'Brito', @viewmodel.name()
      assert.equal theNew, @viewmodel.name
      assert.notEqual old, theNew

    it "doesn't add events", ->
      @viewmodel.load({ events: { 'click one' : -> } })
      assert.equal 0, @viewmodel.vmEvents.length

    it "adds events", ->
      @viewmodel.load({ events: { 'click one' : -> } }, true)
      assert.equal 1, @viewmodel.vmEvents.length

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

    it "returns the first view model up the chain", ->
      @viewmodel.templateInstance =
        view:
          parentView:
            name: 'Template.something'
            templateInstance: ->
              view:
                parentView:
                  name: 'Template.A'
                  templateInstance: ->
                    viewmodel: "Y"
      parent = @viewmodel.parent()
      assert.equal "Y", parent

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
        glob:
          mixin: 'person'
        prom:
          mixin:
            scoped: 'glob'
        bland:
          mixin: [ { subGlob: 'glob'}, 'house']

    it "sub-mixin adds property to vm", ->
      vm = new ViewModel
        mixin: 'glob'
      assert.equal 'X', vm.name()

    it "sub-mixin adds sub-property to vm", ->
      vm = new ViewModel
        mixin:
          scoped: 'glob'
      assert.equal 'X', vm.scoped.name()

    it "sub-mixin adds sub-property to vm prom", ->
      vm = new ViewModel
        mixin: 'prom'
      assert.equal 'X', vm.scoped.name()

    it "sub-mixin adds sub-property to vm bland", ->
      vm = new ViewModel
        mixin: 'bland'
      assert.equal 'A', vm.address()
      assert.equal 'X', vm.subGlob.name()

    it "sub-mixin adds sub-property to vm bland scoped", ->
      vm = new ViewModel
        mixin:
          scoped: 'bland'
      assert.equal 'A', vm.scoped.address()
      assert.equal 'X', vm.scoped.subGlob.name()

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

    it "adds mix to vm", ->
      vm = new ViewModel
        mixin: [
          { location: 'house' },
          'person'
        ]
      assert.equal 'A', vm.location.address()
      assert.equal 'X', vm.name()

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

    it "adds mix to vm", ->
      vm = new ViewModel
        share: [
          { location: 'house' },
          'person'
        ]
      assert.equal 'A', vm.location.address()
      assert.equal 'X', vm.name()