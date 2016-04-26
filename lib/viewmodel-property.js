
const isNumber = function(obj) {
  // jQuery's isNumeric
  return !_.isArray(obj) && (obj - parseFloat(obj) + 1) >= 0;
};

const isInteger = function(n) {
  if (
    !isNumber(n)
    || ~n.toString().indexOf('.')
  ) return false;

  var value = parseFloat(n);
  return value === +value && value === (value | 0);
};

const isObject = function(obj) { return (typeof obj === "object") && (obj !== null) && !( obj instanceof Date) ; };

class Property {
  constructor(){
    this.checks = [];
    this.checksAsync = [];
    this.defaultValue = undefined;
    this.validMessageValue = "";
    this.invalidMessageValue = "";
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
  setDefault(value){
    if(typeof this.defaultValue === "undefined") this.defaultValue = value;
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
  validMessage(message) {
    this.validMessageValue = message;
    return this;
  }
  invalidMessage(message) {
    this.invalidMessageValue = message;
    return this;
  }

  get notBlank() {
    this.checks.push((value) => !!value.trim());
    return this;
  }
  get string() {
    this.setDefault("");
    this.checks.push((value) => _.isString(value));
    return this;
  }
  get integer() {
    this.setDefault(0);
    this.checks.push((n) => isInteger(n) );
    return this;
  }
  get number() {
    this.setDefault(0);
    this.checks.push((value) => isNumber(value));
    return this;
  }
  get boolean() {
    this.setDefault(false);
    this.checks.push((value) => _.isBoolean(value));
    return this;
  }
  get object() {
    this.checks.push((value) => isObject(value));
    return this;
  }
  get date() {
    this.checks.push((value) => value instanceof Date);
    return this;
  }
  


  
  static validator(value) {
    const property = new Property();
    if(_.isString(value)) {
      return property.string;
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