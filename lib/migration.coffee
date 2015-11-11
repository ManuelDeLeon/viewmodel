@Migration = new ReactiveDict("ViewModel_Migration")
Reload._onMigrate ->
  return [true] if not ViewModel.persist
  for vmId, viewmodel of ViewModel.byId
    vmHash = viewmodel.vmHash()
    if Migration.get(vmHash)
      templateName = ViewModel.templateName(viewmodel.templateInstance)
      console.error "Could not create unique identifier for an instance of template '#{templateName}'. This can usually be resolved by wrapping a plain text in a div or adding a vmTag to the view model. Now you need to manually refresh the page. See https://viewmodel.org/misc#hotcodepush for more information."
      return [false]
    Migration.set vmHash, viewmodel.data()
  return [true]
#  catch error
#    console.log error
#  finally
#    return [true]