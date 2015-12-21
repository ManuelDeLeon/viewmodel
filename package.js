Package.describe({
  name: 'manuel:viewmodel',
  summary: "MVVM, two-way data binding, and components for Meteor. Similar to Angular and Knockout.",
  version: "2.5.3",
  git: "https://github.com/ManuelDeLeon/viewmodel"
});

var CLIENT = 'client';

Package.onUse(function(api) {
  api.use([
    'coffeescript@1.0.10',
    'blaze@2.1.3',
    'blaze-html-templates@1.0.1',
    'jquery@1.11.4',
    'underscore@1.0.4',
    'tracker@1.0.9',
    'reload@1.1.4',
    'sha@1.0.4',
    'reactive-dict@1.1.3',
    'manuel:reactivearray@1.0.5',
    'manuel:viewmodel-debug@2.4.0',
    'manuel:isdev@1.0.0'
  ], CLIENT);

  api.addFiles([
    'lib/viewmodel.coffee',
    'lib/viewmodel-parseBind.coffee',
    'lib/bindings.coffee',
    'lib/template.coffee',
    'lib/migration.coffee',
    'lib/viewmodel-onUrl.coffee',
    'lib/lzstring.js'
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
    'tracker',
    'reload',
    'sha',
    'reactive-dict',
    'manuel:reactivearray',
    'practicalmeteor:mocha',
    'practicalmeteor:sinon',
    'manuel:isdev'

  ], CLIENT);

  api.addFiles([
    'lib/viewmodel.coffee',
    'lib/viewmodel-parseBind.coffee',
    'lib/bindings.coffee',
    'lib/template.coffee',
    'lib/migration.coffee',
    'tests/jquery-patch.js',
    'tests/sinon-restore.js',
    'tests/bindings.coffee',
    'tests/viewmodel.coffee',
    'tests/viewmodel-instance.coffee',
    'tests/viewmodel-check.coffee',
    'tests/viewmodel-parseBind.coffee',
    'tests/template.coffee'
  ], CLIENT);

  api.export([
    'ViewModel'
  ], CLIENT);
});