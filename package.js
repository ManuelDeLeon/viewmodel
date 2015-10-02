Package.describe({
  name: 'manuel:viewmodel',
  summary: "MVVM, two-way data binding, and components for Meteor. Similar to Angular and Knockout.",
  version: "1.9.13",
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
    'tracker',
    'session',
    'manuel:reactivearray',
    'manuel:isdev'
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