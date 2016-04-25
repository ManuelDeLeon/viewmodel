class Property {
  constructor(){
    this.checks = [];
    this.checksAsync = [];
    this.defaultValue = undefined;
  }
  validate(value){
    for(var check of this.checks) {
      if (!check(value)) return false;
    }
    return true;
  }
  validateAsync(value, done){
    for(var check of this.checksAsync) {
      check(value, done);
    }
  }
  hasAsync(){
    return this.checksAsync.length;
  }
  min(minValue) {
    this.checks.push((value) => parseFloat(value) >= minValue);
    return this;
  }
  max(maxValue) {
    this.checks.push((value) => value <= maxValue);
    return this;
  }

  check(fun) {
    this.checks.push(fun);
    return this;
  }

  checkAsync(fun){
    this.checksAsync.push(fun);
    return this;
  }

  default(value) {
    this.defaultValue = value;
    return this;
  }
  get notBlank() {
    this.checks.push((value) => !!value.trim());
    return this;
  }
  get text() {
    if(typeof this.defaultValue === "undefined") this.defaultValue = "";
    this.checks.push((value) => _.isString(value));
    return this;
  }
  get integer() {
    if(typeof this.defaultValue === "undefined") this.defaultValue = 0;
    this.checks.push((n) => {
        var value = parseFloat(n);
        return value === +value && value === (value | 0);
      }
    );
    return this;
  }
  get number() {
    this.checks.push((value) => !isNaN(parseFloat(value)) && isFinite(value));
    return this;
  }
  
  static validator(value) {
    const property = new Property();
    if(_.isString(value)) {
      return property.text;
    } else if(_.isNumber(value)) {
      return property.number;
    } else {
      return property;
    }
  }
}

Object.defineProperties(ViewModel, {
  "property": { get: function () { return new Property; } }
});

ViewModel.Property = Property;