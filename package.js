Package.describe({
  name: 'manuel:viewmodel',
  summary: "Native MVVM framework for Meteor. Similar to Knockout and Angular.",
  version: "1.3.1",
  git: "https://github.com/ManuelDeLeon/viewmodel"
});

Package.onUse(function(api) {
  api.versionsFrom('METEOR@1.0');
    api.use('coffeescript');
    api.use('manuel:reactivearray@1.0.3');
    api.addFiles('viewmodel.coffee', 'client');
    api.export('ViewModel', 'client');
});
