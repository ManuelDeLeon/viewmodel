@Migration = new ReactiveDict("ViewModel_Migration")
Reload._onMigrate ->
  for vmId, viewmodel of ViewModel.byId
    Migration.set viewmodel.vmHash(), viewmodel.data()
  return [true]