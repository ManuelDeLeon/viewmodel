Package.describe({
  summary: "MVVM framework for Meteor",
  version: "1.1.3",
  git: "https://github.com/ManuelDeLeon/viewmodel"
});

Package.onUse(function(api) {
  api.versionsFrom('METEOR@0.9.2.2');
    api.use('coffeescript', ['client', 'server']);
    api.use('manuel:reactivearray@1.0.0', 'client')
    api.addFiles(['viewmodel.coffee'], 'client');
    api.export('ViewModel');
});
