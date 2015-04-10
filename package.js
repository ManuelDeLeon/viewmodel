Package.describe({
  name: 'manuel:viewmodel',
  summary: "MVVM, two-way data binding, and components for Meteor. Similar to Knockout.",
  version: "1.4.2",
  git: "https://github.com/ManuelDeLeon/viewmodel"
});

Package.onUse(function(api) {
  api.versionsFrom('METEOR@1.0.4');
    api.use('coffeescript');
    api.use('blaze', 'client');
    api.use('manuel:reactivearray@1.0.5');
    api.addFiles('viewmodel.coffee', 'client');
    api.addFiles('hook.coffee', 'client');
    api.export('ViewModel', 'client');
});
