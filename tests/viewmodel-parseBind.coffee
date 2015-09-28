describe "ViewModel", ->

  beforeEach ->
    @checkStub = sinon.stub ViewModel, "check"

  afterEach ->
    sinon.restoreAll()

  describe "@parseBind", ->

    it "parses object", ->
      obj = ViewModel.parseBind "text: name, full: first + ' ' + last"
      assert.isTrue _.isEqual({ text: "name", full: "first +' '+ last" }, obj)

