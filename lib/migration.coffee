@Migration = new ReactiveDict("ViewModel_Migration")
Reload._onMigrate ->
  for vmId, viewmodel of ViewModel.byId
    vmHash = viewmodel.vmHash()
    if Migration.get(vmHash)
      console.log viewmodel
    Migration.set vmHash, viewmodel.data()
  return [true]