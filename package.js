Package.describe({
  name: 'manuel:viewmodel2',
  summary: "MVVM, two-way data binding, and components for Meteor. Similar to Angular and Knockout.",
  version: "2.0.0",
  git: "https://github.com/ManuelDeLeon/viewmodel"
});

var CLIENT = 'client';

Package.onUse(function(api) {
  api.use([
    'coffeescript',
    'blaze',
    'blaze-html-templates',
    'jquery',
    'underscore',
    'manuel:reactivearray',
    'manuel:viewmodel-debug'
  ], CLIENT);

  api.addFiles([
    'lib/viewmodel.coffee',
    'lib/viewmodel-parseBind.coffee',
    'lib/template.coffee'
  ], CLIENT);

  api.export([
    'ViewModel'
  ], CLIENT);
});

Package.onTest(function(api) {

  api.use([
    'coffeescript',
    'blaze',
    'blaze-html-templates',
    'jquery',
    'underscore',
    'practicalmeteor:mocha',
    'practicalmeteor:sinon'

  ], CLIENT);

  api.addFiles([
    'lib/viewmodel.coffee',
    'lib/viewmodel-parseBind.coffee',
    'lib/template.coffee',
    'tests/sinon-restore.js',
    'tests/viewmodel.coffee',
    'tests/viewmodel-check.coffee',
    'tests/viewmodel-parseBind.coffee',
    'tests/template.coffee'
  ], CLIENT);

  api.export([
    'ViewModel'
  ], CLIENT);
});