delay = (f) ->
  setTimeout(f, 0)

describe "bindings", ->

  beforeEach ->
    @viewmodel = new ViewModel
      name: ''
      changeName: (v) -> this.name v
      on: true
      off: false
      array: []
    @element = $("<button></button>")
    @templateInstance =
      autorun: Tracker.autorun

  describe "input value", ->
    beforeEach ->
      bindObject =
        value: 'name'
      @viewmodel.bind bindObject, @templateInstance, @element, ViewModel.bindings


    it "sets value from vm", (done) ->
      @viewmodel.name 'X'
      delay =>
        assert.equal "X", @element.val()
        done()

    it "sets value from element", (done) ->
      @element.val 'X'
      @element.trigger 'input'
      delay =>
        assert.equal "X", @viewmodel.name()
        done()

    it "can handle undefined", (done) ->
      @element.val 'X'
      @viewmodel.name undefined
      delay =>
        assert.equal "", @element.val()
        done()

    it "can handle null", (done) ->
      @element.val 'X'
      @viewmodel.name null
      delay =>
        assert.equal "", @element.val()
        done()

    it "sets value from element (propertychange)", (done) ->
      @element.val 'X'
      @element.trigger 'propertychange'
      delay =>
        assert.equal "X", @viewmodel.name()
        done()

  describe "input value throttle", ->
    beforeEach ->
      @clock = sinon.useFakeTimers()
      bindObject =
        value: 'name'
        throttle: '10'
        bindId: 1
      @viewmodel.bind bindObject, @templateInstance, @element, ViewModel.bindings, 99, {}

    afterEach ->
      @clock.restore()

    it "delays value from element", ->
      @element.val 'X'
      @element.trigger 'input'
      @clock.tick 1
      assert.equal '', @viewmodel.name()
      @clock.tick 12
      assert.equal 'X', @viewmodel.name()
      return

    it "throttles the value", ->
      @element.val 'X'
      @element.trigger 'input'
      @clock.tick 8
      assert.equal '', @viewmodel.name()
      @element.val 'Y'
      @element.trigger 'input'
      @clock.tick 8
      assert.equal '', @viewmodel.name()
      @element.val 'Z'
      @element.trigger 'input'
      @clock.tick 12
      assert.equal 'Z', @viewmodel.name()
      return

  describe "default", ->
    beforeEach ->
      bindObject =
        click: 'changeName("X")'
      @viewmodel.bind bindObject, @templateInstance, @element, ViewModel.bindings

    it "triggers event", (done) ->
      @element.trigger 'click'
      delay =>
        assert.equal "X", @viewmodel.name()
        done()

  describe "toggle", ->
    beforeEach ->
      bindObject =
        toggle: 'off'
      @viewmodel.bind bindObject, @templateInstance, @element, ViewModel.bindings

    it "flips boolean", (done) ->
      @element.trigger 'click'
      delay =>
        assert.equal true, @viewmodel.off()
        done()

  describe "if", ->
    beforeEach ->
      bindObject =
        if: 'on'
      @viewmodel.bind bindObject, @templateInstance, @element, ViewModel.bindings

    it "hides element when true", (done) ->
      delay =>
        assert.equal "inline-block", @element.inlineStyle("display")
        done()

    it "hides element when false", (done) ->
      @viewmodel.on false
      delay =>
        assert.equal "none", @element.inlineStyle("display")
        done()

  describe "visible", ->
    beforeEach ->
      bindObject =
        visible: 'on'
      @viewmodel.bind bindObject, @templateInstance, @element, ViewModel.bindings

    it "hides element when true", (done) ->
      delay =>
        assert.equal "inline-block", @element.inlineStyle("display")
        done()

    it "hides element when false", (done) ->
      @viewmodel.on false
      delay =>
        assert.equal "none", @element.inlineStyle("display")
        done()

  describe "unless", ->
    beforeEach ->
      bindObject =
        unless: 'off'
      @viewmodel.bind bindObject, @templateInstance, @element, ViewModel.bindings

    it "hides element when true", (done) ->
      delay =>
        assert.equal "inline-block", @element.inlineStyle("display")
        done()

    it "hides element when false", (done) ->
      @viewmodel.off true
      delay =>
        assert.equal "none", @element.inlineStyle("display")
        done()

  describe "hide", ->
    beforeEach ->
      bindObject =
        hide: 'off'
      @viewmodel.bind bindObject, @templateInstance, @element, ViewModel.bindings

    it "hides element when true", (done) ->
      delay =>
        assert.equal "inline-block", @element.inlineStyle("display")
        done()

    it "hides element when false", (done) ->
      @viewmodel.off true
      delay =>
        assert.equal "none", @element.inlineStyle("display")
        done()

  describe "text", ->
    beforeEach ->
      bindObject =
        text: 'name'
      @viewmodel.bind bindObject, @templateInstance, @element, ViewModel.bindings

    it "sets from vm", (done) ->
      @viewmodel.name 'X'
      delay =>
        assert.equal "X", @element.text()
        done()

  describe "html", ->
    beforeEach ->
      bindObject =
        html: 'name'
      @viewmodel.bind bindObject, @templateInstance, @element, ViewModel.bindings

    it "sets from vm", (done) ->
      @viewmodel.name 'X'
      delay =>
        assert.equal "X", @element.html()
        done()

  describe "change", ->

    it "uses default without other bindings", (done) ->
      bindObject =
        change: 'name'
      @viewmodel.bind bindObject, @templateInstance, @element, ViewModel.bindings
      @element.trigger 'change'
      delay =>
        assert.isTrue @viewmodel.name() instanceof jQuery.Event
        done()

    it "uses other bindings", (done) ->
      bindObject =
        value: 'name'
        change: 'on'
      @viewmodel.bind bindObject, @templateInstance, @element, ViewModel.bindings
      @element.trigger 'change'
      delay =>
        assert.isFalse @viewmodel.name() instanceof jQuery.Event
        done()

  describe "enter", ->
    beforeEach ->
      bindObject =
        enter: "changeName('X')"
      @viewmodel.bind bindObject, @templateInstance, @element, ViewModel.bindings

    it "uses e.which", (done) ->
      e = jQuery.Event("keyup")
      e.which = 13
      @element.trigger e
      delay =>
        assert.equal 'X', @viewmodel.name()
        done()

    it "uses e.keyCode", (done) ->
      e = jQuery.Event("keyup")
      e.keyCode = 13
      @element.trigger e
      delay =>
        assert.equal 'X', @viewmodel.name()
        done()

    it "doesn't do anything without key", (done) ->
      e = jQuery.Event("keyup")
      @element.trigger e
      delay =>
        assert.equal '', @viewmodel.name()
        done()

  describe "attr", ->
    beforeEach ->
      bindObject =
        attr:
          title: 'name'
          viewBox: 'on'
      @viewmodel.bind bindObject, @templateInstance, @element, ViewModel.bindings

    it "sets from vm", (done) ->
      @viewmodel.name 'X'
      @viewmodel.on 'Y'
      @viewmodel.viewBox
      delay =>
        assert.equal 'X', @element.attr('title')
        assert.equal 'Y', @element[0].getAttribute('viewBox')
        done()



  describe "addAttributeBinding", ->
    it "sets from array", (done) ->
      ViewModel.addAttributeBinding( ['href'] )
      bindObject =
        href: 'on'
      @viewmodel.bind bindObject, @templateInstance, @element, ViewModel.bindings
      @viewmodel.on 'Y'
      delay =>
        assert.equal 'Y', @element.attr('href')
        done()

    it "sets from string", (done) ->
      ViewModel.addAttributeBinding( 'src' )
      bindObject =
        src: 'on'
      @viewmodel.bind bindObject, @templateInstance, @element, ViewModel.bindings
      @viewmodel.on 'Y'
      delay =>
        assert.equal 'Y', @element.attr('src')
        done()


  describe "check", ->
    beforeEach ->
      bindObject =
        check: 'on'
      @element = $("<input type='checkbox'>")
      @viewmodel.bind bindObject, @templateInstance, @element, ViewModel.bindings

    it "has default value", (done) ->
      delay =>
        assert.isTrue @element.is(':checked')
        assert.isTrue @viewmodel.on()
        done()

    it "sets value from vm", (done) ->
      @viewmodel.on false
      delay =>
        assert.isFalse @element.is(':checked')
        done()

    it "sets value from element", (done) ->
      @element.prop 'checked', false
      @element.trigger 'change'
      delay =>
        assert.isFalse @viewmodel.on()
        done()

  describe "checkbox group", ->
    beforeEach ->
      bindObject =
        group: 'array'
      @element = $("<input type='checkbox' value='A'>")
      @viewmodel.bind bindObject, @templateInstance, @element, ViewModel.bindings

    it "has default value", (done) ->
      delay =>
        assert.equal 0, @viewmodel.array().length
        assert.isFalse @element.is(':checked')
        done()

    it "sets value from vm", (done) ->
      @viewmodel.array().push('A')
      delay =>
        assert.isTrue @element.is(':checked')
        done()

    it "sets value from element", (done) ->
      @element.prop 'checked', true
      @element.trigger 'change'
      delay =>
        assert.equal 1, @viewmodel.array().length
        done()

  describe "radio group", ->
    beforeEach ->
      bindObject =
        group: 'name'
      @element = $("<input type='radio' value='A' name='B'>")
      @viewmodel.bind bindObject, @templateInstance, @element, ViewModel.bindings

    it "has default value", (done) ->
      delay =>
        assert.equal '', @viewmodel.name()
        assert.isFalse @element.is(':checked')
        done()

    it "sets value from vm", (done) ->
      @viewmodel.name('A')
      delay =>
        assert.isTrue @element.is(':checked')
        done()

    it "sets value from element", (done) ->
      triggeredChange = false
      @templateInstance.$ = ->
        each: -> triggeredChange = true
      @element.prop 'checked', true
      @element.trigger 'change'
      delay =>
        assert.equal 'A', @viewmodel.name()
        assert.isTrue triggeredChange
        done()

  describe "style", ->
    it "element has the style from object", (done) ->
      bindObject =
        style:
          color: "'red'"
      @viewmodel.bind bindObject, @templateInstance, @element, ViewModel.bindings
      delay =>
        assert.equal "red", @element.inlineStyle("color")
        done()
      return

    it "element has the style from string", (done) ->
      bindObject =
        style: "styles.label"
      @viewmodel.load
        styles:
          label:
            color: 'red'
      @viewmodel.bind bindObject, @templateInstance, @element, ViewModel.bindings
      delay =>
        assert.equal "red", @element.inlineStyle("color")
        done()
      return

    it "element has the style from string take 2", (done) ->
      bindObject =
        style: "styleLabel"
      @viewmodel.load
        styleLabel: "color: red"
      @viewmodel.bind bindObject, @templateInstance, @element, ViewModel.bindings
      delay =>
        assert.equal "red", @element.inlineStyle("color")
        done()
      return

    it "element has the style with commas", (done) ->
      bindObject =
        style: "styleLabel"
      @viewmodel.load
        styleLabel: "color: red, border-color: blue"
      @viewmodel.bind bindObject, @templateInstance, @element, ViewModel.bindings
      delay =>
        assert.equal "red", @element.inlineStyle("color")
        assert.equal "blue", @element.inlineStyle("border-color")
        done()
      return

    it "element has the style with semi-colons", (done) ->
      bindObject =
        style: "styleLabel"
      @viewmodel.load
        styleLabel: "color: red; border-color: blue;"
      @viewmodel.bind bindObject, @templateInstance, @element, ViewModel.bindings
      delay =>
        assert.equal "red", @element.inlineStyle("color")
        assert.equal "blue", @element.inlineStyle("border-color")
        done()
      return

    it "element has the style from array", (done) ->
      bindObject =
        style: "[styles.label, styles.button]"
      @viewmodel.load
        styles:
          label:
            color: 'red'
          button:
            height: '10px'
      @viewmodel.bind bindObject, @templateInstance, @element, ViewModel.bindings
      delay =>
        assert.equal "red", @element.inlineStyle("color")
        assert.equal "10px", @element.inlineStyle("height")
        done()
      return