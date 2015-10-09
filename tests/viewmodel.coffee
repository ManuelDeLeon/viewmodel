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
      assert.equal "b-id", ViewModel.bindIdAttribute

  describe "@viewPrefix", ->
    it "has has default value", ->
      assert.equal "t-", ViewModel.viewPrefix

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
        '$': -> "X"
      instanceStub.returns templateInstance
      ViewModel.bindHelper("text: name")
      @onViewReadyFunction()
      assert.isTrue bindStub.calledWith { text: 'name' }, templateInstance, "X", ViewModel.bindings

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


  describe "@bindSingle", ->

    beforeEach ->
      @getBindArgumentStub = sinon.stub ViewModel, 'getBindArgument'
      @getBindingStub = sinon.stub ViewModel, 'getBinding'

    it "returns undefined", ->
      @getBindingStub.returns
        events: { a: 1 }
      element =
        bind: ->
      ret = ViewModel.bindSingle(null, element)
      assert.isUndefined ret

    it "uses getBindArgument", ->
      ViewModel.bindSingle 'templateInstance', 'element', 'bindName', 'bindValue', 'bindObject', 'viewmodel', 'bindingArray'
      assert.isTrue @getBindArgumentStub.calledWithExactly 'templateInstance', 'element', 'bindName', 'bindValue', 'bindObject', 'viewmodel'

    it "uses getBinding", ->
      bindArg = {}
      @getBindArgumentStub.returns bindArg
      ViewModel.bindSingle 'templateInstance', 'element', 'bindName', 'bindValue', 'bindObject', 'viewmodel', 'bindingArray'
      assert.isTrue @getBindingStub.calledWithExactly 'bindName', bindArg, 'bindingArray'

    it "executes autorun", ->
      bindArg =
        autorun: ->
      @getBindArgumentStub.returns bindArg
      spy = sinon.spy bindArg, 'autorun'
      bindingAutorun = ->
      @getBindingStub.returns
        autorun: bindingAutorun

      ViewModel.bindSingle()
      assert.isTrue spy.calledWithExactly bindingAutorun

    it "executes bind", ->
      @getBindArgumentStub.returns 'X'
      arg =
        bind: ->
      spy = sinon.spy arg, 'bind'
      @getBindingStub.returns arg

      ViewModel.bindSingle()
      assert.isTrue spy.calledWithExactly 'X'

    it "binds events", ->
      @getBindingStub.returns
        events: { a: 1, b: 2 }
      element =
        bind: ->
      spy = sinon.spy element, 'bind'
      ViewModel.bindSingle(null, element)
      assert.isTrue spy.calledTwice
      assert.isTrue spy.calledWith 'a'
      assert.isTrue spy.calledWith 'b'

  describe "@getBinding", ->

    it "returns default binding if can't find one", ->
      bindName = 'default'
      defaultB =
        name: bindName
      bindings = {}
      bindings[bindName] = [defaultB]

      ret = ViewModel.getBinding 'bindName', 'bindArg', bindings
      assert.equal ret, defaultB

    it "returns first binding in one element array", ->
      bindName = 'one'
      oneBinding =
        name: bindName
      bindings = {}
      bindings[bindName] = [oneBinding]

      ret = ViewModel.getBinding bindName, 'bindArg', bindings
      assert.equal ret, oneBinding

    it "returns highest priority binding", ->
      oneBinding =
        name: 'X'
        priority: 1
      twoBinding =
        name: 'X'
        priority: 2
      bindings =
        X: [oneBinding, twoBinding]

      ret = ViewModel.getBinding 'X', 'bindArg', bindings
      assert.equal ret, twoBinding

    it "returns first that passes bindIf", ->
      oneBinding =
        name: 'X'
        priority: 1
        bindIf: -> false
      twoBinding =
        name: 'X'
        priority: 1
        bindIf: -> true
      bindings =
        X: [oneBinding, twoBinding]

      ret = ViewModel.getBinding 'X', 'bindArg', bindings
      assert.equal ret, twoBinding

    it "returns first that passes selector", ->
      oneBinding =
        name: 'X'
        priority: 1
        selector: "A"
      twoBinding =
        name: 'X'
        priority: 1
        selector: "B"
      bindings =
        X: [oneBinding, twoBinding]

      bindArg =
        element:
          is: (s) -> s is "B"
      ret = ViewModel.getBinding 'X', bindArg, bindings
      assert.equal ret, twoBinding

    it "returns first that passes bindIf and selector", ->
      oneBinding =
        name: 'X'
        priority: 1
        selector: "B"
        bindIf: -> false
      twoBinding =
        name: 'X'
        priority: 1
        selector: "B"
        bindIf: -> true
      bindings =
        X: [oneBinding, twoBinding]

      bindArg =
        element:
          is: (s) -> s is "B"
      ret = ViewModel.getBinding 'X', bindArg, bindings
      assert.equal ret, twoBinding

    it "returns first that passes bindIf and selector with highest priority", ->
      oneBinding =
        name: 'X'
        priority: 1
        selector: "B"
        bindIf: -> true
      twoBinding =
        name: 'X'
        priority: 2
        selector: "B"
        bindIf: -> true
      bindings =
        X: [oneBinding, twoBinding]

      bindArg =
        element:
          is: (s) -> s is "B"
      ret = ViewModel.getBinding 'X', bindArg, bindings
      assert.equal ret, twoBinding

  describe "@getBindArgument", ->

    beforeEach ->
      @getVmValueGetterStub = sinon.stub ViewModel, 'getVmValueGetter'
      @getVmValueSetterStub = sinon.stub ViewModel, 'getVmValueSetter'

    it "returns right object", ->
      ret = ViewModel.getBindArgument 'templateInstance', 'element', 'bindName', 'bindValue', 'bindObject', 'viewmodel'
      ret = _.omit(ret, 'autorun', 'getVmValue', 'setVmValue')
      expected =
        templateInstance: 'templateInstance'
        element: 'element'
        elementBind: 'bindObject'
        bindName: 'bindName'
        bindValue: 'bindValue'
        viewmodel: 'viewmodel'
      assert.isTrue _.isEqual(expected, ret)

    it "returns argument with autorun", ->
      templateInstance =
        autorun: ->
      spy = sinon.spy templateInstance, 'autorun'
      bindArg = ViewModel.getBindArgument templateInstance, 'element', 'bindName', 'bindValue', 'bindObject', 'viewmodel'
      bindArg.autorun ->
      assert.isTrue spy.calledOnce

    it "returns argument with vmValueGetter", ->
      @getVmValueGetterStub.returns -> "A"
      bindArg = ViewModel.getBindArgument 'templateInstance', 'element', 'bindName', 'bindValue', 'bindObject', 'viewmodel'
      assert.equal "A", bindArg.getVmValue()

    it "returns argument with vmValueSetter", ->
      @getVmValueSetterStub.returns -> "A"
      bindArg = ViewModel.getBindArgument 'templateInstance', 'element', 'bindName', 'bindValue', 'bindObject', 'viewmodel'
      assert.equal "A", bindArg.setVmValue()

  describe "@getVmValueGetter", ->

    it "returns value from name", ->
      viewmodel =
        name: -> "A"
      bindValue = 'name'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.equal "A", getVmValue()

    it "returns false from !'A'", ->
      viewmodel =
        name: -> "A"
      bindValue = '!name'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.equal false, getVmValue()

    it "returns value from name.first (first is prop)", ->
      viewmodel =
        name: ->
          first: "A"
      bindValue = 'name.first'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.equal "A", getVmValue()
      return

    it "returns value from name.first (first is func)", ->
      viewmodel =
        name: ->
          first: -> "A"
      bindValue = 'name.first'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.equal "A", getVmValue()

    it "returns value from name()", ->
      viewmodel =
        name: -> "A"
      bindValue = 'name()'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.equal "A", getVmValue()

    it "doesn't give arguments to name()", ->
      viewmodel =
        name: -> arguments.length
      bindValue = 'name()'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.equal 0, getVmValue()

    it "returns value from name('a')", ->
      viewmodel =
        name: (a) -> a
      bindValue = "name('a')"
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.equal "a", getVmValue()

    it "returns value from name('a', 1)", ->
      viewmodel =
        name: (a, b) -> a + b
      bindValue = "name('a', 1)"
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.equal "a1", getVmValue()

    it "returns value from name(first) with string", ->
      viewmodel =
        name: (v) -> v
        first: -> "A"
      bindValue = 'name(first)'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.equal "A", getVmValue()

    it "returns value from name(first, second)", ->
      viewmodel =
        name: (a, b) -> a + b
        first: -> "A"
        second: -> "B"
      bindValue = 'name(first, second)'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.equal "AB", getVmValue()

    it "returns value from name(first, second) with numbers", ->
      viewmodel =
        name: (a, b) -> a + b
        first: -> 1
        second: -> 2
      bindValue = 'name(first, second)'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.equal 3, getVmValue()

    it "returns value from name(first, second) with booleans", ->
      viewmodel =
        name: (a, b) -> a or b
        first: -> false
        second: -> true
      bindValue = 'name(first, second)'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.isTrue getVmValue()

    it "returns value from name(first) with null", ->
      viewmodel =
        name: (a) -> a
        first: -> null
      bindValue = 'name(first)'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.isNull getVmValue()

    it "returns value from name(first) with undefined", ->
      viewmodel =
        name: (a) -> a
        first: -> undefined
      bindValue = 'name(first)'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.isUndefined getVmValue()

    it "returns value from name(first)", ->
      viewmodel =
        name: (v) -> v
      bindValue = 'name(first)'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.equal "first", getVmValue()

    it "returns value from name(1, 2)", ->
      viewmodel =
        name: (a, b) -> a + b
      bindValue = 'name(1, 2)'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.equal 3, getVmValue()

    it "returns value from name(false, true)", ->
      viewmodel =
        name: (a, b) -> a or b
      bindValue = 'name(false, true)'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.isTrue getVmValue()

    it "returns value from name(null)", ->
      viewmodel =
        name: (a) -> a
      bindValue = 'name(null)'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.isNull getVmValue()

    it "returns value from name(undefined)", ->
      viewmodel =
        name: (a) -> a
      bindValue = 'name(undefined)'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.isUndefined getVmValue()

    it "returns value from name(!first, !second) with booleans", ->
      viewmodel =
        name: (a, b) -> a and b
        first: -> false
        second: -> false
      bindValue = 'name(!first, !second)'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.isTrue getVmValue()

    it "returns value from name().first (first is prop)", ->
      viewmodel =
        name: ->
          first: "A"
      bindValue = 'name.first'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.equal "A", getVmValue()

    it "returns value from name().first (first is func)", ->
      viewmodel =
        name: ->
          first: -> "A"
      bindValue = 'name.first'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.equal "A", getVmValue()

    it "returns value from name(1).first (first is prop)", ->
      viewmodel =
        name: (v) ->
          if v is 1
            first: "A"
      bindValue = 'name(1).first'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.equal "A", getVmValue()

    it "returns value from name(1)", ->
      viewmodel =
        name: (a) -> a
      bindValue = 'name(1)'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.isTrue 1 is getVmValue()

    it "returns value from name().first()", ->
      viewmodel =
        name: ->
          first: -> "A"
      bindValue = 'name().first()'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.equal "A", getVmValue()


    it "returns value from name().first.second", ->
      viewmodel =
        name: ->
          first:
            second: "A"
      bindValue = 'name().first.second'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.equal "A", getVmValue()

    it "returns value from name().first.second()", ->
      viewmodel =
        name: ->
          first:
            second: -> "A"
      bindValue = 'name().first.second()'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.equal "A", getVmValue()

    it "returns value from name().first.second()", ->
      viewmodel =
        name: ->
          first:
            second: -> "A"
      bindValue = 'name().first.second()'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.equal "A", getVmValue()

    it "returns value from first + second", ->
      viewmodel =
        first: 1
        second: 2
      bindValue = 'first + second'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.equal 3, getVmValue()
      return

    it "returns value from first - second", ->
      viewmodel =
        first: 3
        second: 2
      bindValue = 'first - second'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.equal 1, getVmValue()
      return

    it "returns value from first * second", ->
      viewmodel =
        first: 3
        second: 2
      bindValue = 'first * second'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.equal 6, getVmValue()
      return

    it "returns value from first / second", ->
      viewmodel =
        first: 6
        second: 2
      bindValue = 'first / second'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.equal 3, getVmValue()
      return

    it "returns value from first && second", ->
      viewmodel =
        first: true
        second: true
      bindValue = 'first && second'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.isTrue getVmValue()
      return

    it "returns value from first || second", ->
      viewmodel =
        first: false
        second: true
      bindValue = 'first || second'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.isTrue getVmValue()
      return

    it "returns value from first == second", ->
      viewmodel =
        first: 1
        second: '1'
      bindValue = 'first == second'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.isTrue getVmValue()
      return

    it "returns value from first === second", ->
      viewmodel =
        first: 1
        second: 1
      bindValue = 'first === second'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.isTrue getVmValue()
      return

    it "returns value from first !== second", ->
      viewmodel =
        first: 1
        second: 1
      bindValue = 'first !== second'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.isFalse getVmValue()
      return

    it "returns value from first !=== second", ->
      viewmodel =
        first: 1
        second: 1
      bindValue = 'first !=== second'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.isFalse getVmValue()
      return

    it "returns value from first > second", ->
      viewmodel =
        first: 1
        second: 0
      bindValue = 'first > second'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.isTrue getVmValue()
      return

    it "returns value from first > second", ->
      viewmodel =
        first: 1
        second: 1
      bindValue = 'first > second'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.isFalse getVmValue()
      return

    it "returns value from first > second", ->
      viewmodel =
        first: 1
        second: 2
      bindValue = 'first > second'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.isFalse getVmValue()
      return

    it "returns value from first >= second", ->
      viewmodel =
        first: 1
        second: 0
      bindValue = 'first >= second'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.isTrue getVmValue()
      return

    it "returns value from first >= second", ->
      viewmodel =
        first: 1
        second: 1
      bindValue = 'first >= second'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.isTrue getVmValue()
      return

    it "returns value from first >= second", ->
      viewmodel =
        first: 1
        second: 2
      bindValue = 'first >= second'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.isFalse getVmValue()
      return

    it "returns value from first < second", ->
      viewmodel =
        first: 1
        second: 0
      bindValue = 'first < second'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.isFalse getVmValue()
      return

    it "returns value from first < second", ->
      viewmodel =
        first: 1
        second: 1
      bindValue = 'first < second'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.isFalse getVmValue()
      return

    it "returns value from first < second", ->
      viewmodel =
        first: 1
        second: 2
      bindValue = 'first < second'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.isTrue getVmValue()
      return

    it "returns value from first <= second", ->
      viewmodel =
        first: 1
        second: 0
      bindValue = 'first <= second'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.isFalse getVmValue()
      return

    it "returns value from first <= second", ->
      viewmodel =
        first: 1
        second: 1
      bindValue = 'first <= second'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.isTrue getVmValue()
      return

    it "returns value from first <= second", ->
      viewmodel =
        first: 1
        second: 2
      bindValue = 'first <= second'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.isTrue getVmValue()
      return

    it "returns value from first(1.1)", ->
      viewmodel =
        first: (v) -> v
      bindValue = 'first(1.1)'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.equal 1.1, getVmValue()
      return

    it "returns value from first1.second", ->
      viewmodel =
        first1:
          second: 2
      bindValue = 'first1.second'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.equal 2, getVmValue()
      return

    it "returns value from first.1second", ->
      viewmodel =
        first:
          '1second': 2
      bindValue = 'first.1second'
      getVmValue = ViewModel.getVmValueGetter(viewmodel, bindValue)
      assert.equal 2, getVmValue()
      return

  describe "@getVmValueSetter", ->

    it "sets first func", ->
      val = null
      viewmodel =
        first: (v) -> val = v
      bindValue = 'first'
      setVmValue = ViewModel.getVmValueSetter(viewmodel, bindValue)
      setVmValue(2)
      assert.equal 2, val
      return

    it "sets first prop", ->
      viewmodel =
        first: 1
      bindValue = 'first'
      setVmValue = ViewModel.getVmValueSetter(viewmodel, bindValue)
      setVmValue(2)
      assert.equal 2, viewmodel.first
      return





































