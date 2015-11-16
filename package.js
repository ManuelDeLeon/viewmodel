Package.describe({
  name: 'manuel:viewmodel',
  summary: "MVVM, two-way data binding, and components for Meteor. Similar to Angular and Knockout.",
  version: "1.9.16",
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
    'session@1.1.1',
    'manuel:reactivearray@1.0.5',
    'manuel:isdev@1.0.0'
  ], CLIENT);

  api.addFiles([
    'helper.coffee',
    'monkeypatch.js',
    'viewmodel.coffee',
    'hooks.coffee',
    'binds.coffee'
  ], CLIENT);

  api.export([
    'ViewModel'
  ], CLIENT);
});