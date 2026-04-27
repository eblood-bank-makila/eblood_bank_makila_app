/// Enum for collection CRUD info flags, matching backend seed keys.
enum CollectionCrudInfoFlag {
  fetchUrl('fetch_url'),
  createProcessingUrl('create_processing_url'),
  createHeadProcessUrl('create_head_process_url'),
  createChildProcessingUrl('create_child_processing_url'),
  createChildHeadProcessUrl('create_child_head_process_url'),
  updateProcessingUrl('update_processing_url'),
  updateHeadProcessUrl('update_head_process_url'),
  deleteProcessingUrl('delete_processing_url'),
  fetchOneInfoUrl('fetch_one_info_url'),
  fetchOneInfoForViewingUrl('fetch_one_info_for_viewing_url'),
  parentFieldName('parent_field_name'),
  putProcessingUrl('put_processing_url'),
  patchProcessingUrl('patch_processing_url'),
  downloadProcessUrl('download_process_url');

  final String value;
  const CollectionCrudInfoFlag(this.value);
}
