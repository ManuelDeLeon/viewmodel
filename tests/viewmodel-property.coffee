describe "ViewModel Properties", ->
  describe "string", ->
    prop = new ViewModel.Property().string

    it "fails with a number", ->
      assert.isFalse prop.validate(1)

    it "fails with an object", ->
      assert.isFalse prop.validate({})

    it "passes with a string", ->
      assert.isTrue prop.validate("")

    it "fails with a date", ->
      assert.isFalse prop.validate(new Date())

    it "fails with a boolean", ->
      assert.isFalse prop.validate(true)

  describe "number", ->
    prop = new ViewModel.Property().number

    it "passes with an integer", ->
      assert.isTrue prop.validate(1)

    it "passes with a float", ->
      assert.isTrue prop.validate(1.1)

    it "passes with a string/float", ->
      assert.isTrue prop.validate("1.0")

    it "fails with a number + string", ->
      assert.isFalse prop.validate("1a")

    it "fails with an object", ->
      assert.isFalse prop.validate({})

    it "fails with an empty string", ->
      assert.isFalse prop.validate("")

    it "fails with a date", ->
      assert.isFalse prop.validate(new Date())

    it "fails with a boolean", ->
      assert.isFalse prop.validate(true)

  describe "integer", ->
    prop = new ViewModel.Property().integer

    it "passes with an integer", ->
      assert.isTrue prop.validate(1)

    it "fails with a float", ->
      assert.isFalse prop.validate(1.1)

    it "passes with a string/integer", ->
      assert.isTrue prop.validate("1")

    it "fails with a number + string", ->
      assert.isFalse prop.validate("1a")

    it "fails with an object", ->
      assert.isFalse prop.validate({})

    it "fails with an empty string", ->
      assert.isFalse prop.validate("")

    it "fails with a date", ->
      assert.isFalse prop.validate(new Date())

    it "fails with a boolean", ->
      assert.isFalse prop.validate(true)

  describe "boolean", ->
    prop = new ViewModel.Property().boolean

    it "fails with a number", ->
      assert.isFalse prop.validate(1)

    it "fails with an object", ->
      assert.isFalse prop.validate({})

    it "fails with a string", ->
      assert.isFalse prop.validate("")

    it "fails with a date", ->
      assert.isFalse prop.validate(new Date())

    it "passes with a boolean", ->
      assert.isTrue prop.validate(false)

  describe "object", ->
    prop = new ViewModel.Property().object

    it "fails with a number", ->
      assert.isFalse prop.validate(1)

    it "passes with an object", ->
      assert.isTrue prop.validate({})

    it "fails with a string", ->
      assert.isFalse prop.validate("")

    it "fails with a date", ->
      assert.isFalse prop.validate(new Date())

    it "fails with a boolean", ->
      assert.isFalse prop.validate(true)

  describe "date", ->
    prop = new ViewModel.Property().date

    it "fails with a number", ->
      assert.isFalse prop.validate(1)

    it "fails with an object", ->
      assert.isFalse prop.validate({})

    it "fails with a string", ->
      assert.isFalse prop.validate("")

    it "passes with a date", ->
      assert.isTrue prop.validate(new Date())

    it "fails with a boolean", ->
      assert.isFalse prop.validate(true)