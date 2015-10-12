if (!sinon.patched) {
  sinon.patched = true;
  sinon.____originalStub = sinon.stub;
  sinon.____stubs = [];
  sinon.stub = function () {
    var stub = sinon.____originalStub.apply(sinon, arguments);
    sinon.____stubs.push(stub);
    return stub;
  };

  sinon.restoreAll = function () {
    sinon.____stubs.forEach(function (stub) {
      stub.restore();
    });
    sinon.____stubs = [];
  };
}