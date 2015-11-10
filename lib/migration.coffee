@Migration = new ReactiveDict("ViewModel_Migration")
Reload._onMigrate ->
  try
    for vmId, viewmodel of ViewModel.byId
      vmHash = viewmodel.vmHash()
      Migration.set vmHash, viewmodel.data()
  catch error
    console.log error
  finally
    return [true]