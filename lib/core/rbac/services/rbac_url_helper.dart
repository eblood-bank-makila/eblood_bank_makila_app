import 'package:flutter/foundation.dart';
import '../enums/collection_crud_info_flag.dart';
import '../models/rbac_models.dart';

/// URL info with sudo action flags.
class RbacUrlInfo {
  final String url;
  final bool isSudoAction;
  final bool isSudoGroupAction;

  const RbacUrlInfo({
    this.url = '',
    this.isSudoAction = false,
    this.isSudoGroupAction = false,
  });

  static const empty = RbacUrlInfo();
}

/// Stateless helper for resolving RBAC URLs and checking actions
/// from collection_crud_info and rbac_actions lists.
///
/// Equivalent of Angular `RbacUrlHelperService`.
class RbacUrlHelper {
  // ──────────────────────────────────────────────────
  // Core URL resolution
  // ──────────────────────────────────────────────────

  /// Get RBAC URL from a crud info list by flag + hard_code_flag.
  String getRbacUrl(
    CollectionCrudInfoFlag flag,
    String hardCodeFlag,
    List<RbacCollectionCrudItem> crudInfo, [
    String defaultValue = '',
  ]) {
    for (final item in crudInfo) {
      if (item.flag == flag.value && item.hardCodeFlag == hardCodeFlag) {
        return item.rbacEndpoint?.url ?? defaultValue;
      }
    }
    if (kDebugMode) {
      debugPrint('[RbacUrlHelper] ⚠️ No URL found for flag=${flag.value}, '
          'hardCodeFlag=$hardCodeFlag in ${crudInfo.length} items. '
          'Available: ${crudInfo.map((e) => "(${e.flag}, ${e.hardCodeFlag})").toList()}');
    }
    return defaultValue;
  }

  /// Get RBAC URL info (url + sudo flags) from a crud info list.
  RbacUrlInfo getRbacUrlInfo(
    CollectionCrudInfoFlag flag,
    String hardCodeFlag,
    List<RbacCollectionCrudItem> crudInfo,
  ) {
    for (final item in crudInfo) {
      if (item.flag == flag.value && item.hardCodeFlag == hardCodeFlag) {
        final ep = item.rbacEndpoint;
        if (ep == null) return RbacUrlInfo.empty;
        return RbacUrlInfo(
          url: ep.url,
          isSudoAction: ep.isSudoAction,
          isSudoGroupAction: ep.isSudoGroupAction,
        );
      }
    }
    return RbacUrlInfo.empty;
  }

  /// Try multiple hard_code_flags in order, return the first matching URL.
  String getRbacUrlWithFallback(
    CollectionCrudInfoFlag flag,
    List<String> hardCodeFlags,
    List<RbacCollectionCrudItem> crudInfo, [
    String defaultValue = '',
  ]) {
    for (final hcf in hardCodeFlags) {
      final url = getRbacUrl(flag, hcf, crudInfo);
      if (url.isNotEmpty) return url;
    }
    return defaultValue;
  }

  /// Check if a specific RBAC URL exists.
  bool hasRbacUrl(
    CollectionCrudInfoFlag flag,
    String hardCodeFlag,
    List<RbacCollectionCrudItem> crudInfo,
  ) {
    return getRbacUrl(flag, hardCodeFlag, crudInfo).isNotEmpty;
  }

  // ──────────────────────────────────────────────────
  // Convenience URL getters
  // ──────────────────────────────────────────────────

  String getFetchUrl(List<RbacCollectionCrudItem> crudInfo, [String hardCodeFlag = 'main']) =>
      getRbacUrl(CollectionCrudInfoFlag.fetchUrl, hardCodeFlag, crudInfo);

  String getFetchOneInfoUrl(List<RbacCollectionCrudItem> crudInfo, [String hardCodeFlag = 'main']) =>
      getRbacUrl(CollectionCrudInfoFlag.fetchOneInfoUrl, hardCodeFlag, crudInfo);

  String getCreateProcessingUrl(List<RbacCollectionCrudItem> crudInfo, [String hardCodeFlag = 'main']) =>
      getRbacUrl(CollectionCrudInfoFlag.createProcessingUrl, hardCodeFlag, crudInfo);

  String getCreateHeadProcessUrl(List<RbacCollectionCrudItem> crudInfo, [String hardCodeFlag = 'main']) =>
      getRbacUrl(CollectionCrudInfoFlag.createHeadProcessUrl, hardCodeFlag, crudInfo);

  String getUpdateProcessingUrl(List<RbacCollectionCrudItem> crudInfo, [String hardCodeFlag = 'main']) =>
      getRbacUrl(CollectionCrudInfoFlag.updateProcessingUrl, hardCodeFlag, crudInfo);

  String getUpdateHeadProcessUrl(List<RbacCollectionCrudItem> crudInfo, [String hardCodeFlag = 'main']) =>
      getRbacUrl(CollectionCrudInfoFlag.updateHeadProcessUrl, hardCodeFlag, crudInfo);

  String getDeleteProcessingUrl(List<RbacCollectionCrudItem> crudInfo, [String hardCodeFlag = 'main']) =>
      getRbacUrl(CollectionCrudInfoFlag.deleteProcessingUrl, hardCodeFlag, crudInfo);

  String getPatchProcessingUrl(List<RbacCollectionCrudItem> crudInfo, [String hardCodeFlag = 'main']) =>
      getRbacUrl(CollectionCrudInfoFlag.patchProcessingUrl, hardCodeFlag, crudInfo);

  String getFetchOneInfoForViewingUrl(List<RbacCollectionCrudItem> crudInfo, [String hardCodeFlag = 'main']) =>
      getRbacUrl(CollectionCrudInfoFlag.fetchOneInfoForViewingUrl, hardCodeFlag, crudInfo);

  String getParentFieldName(List<RbacCollectionCrudItem> crudInfo, [String hardCodeFlag = 'main']) =>
      getRbacUrl(CollectionCrudInfoFlag.parentFieldName, hardCodeFlag, crudInfo);

  String getDownloadProcessUrl(List<RbacCollectionCrudItem> crudInfo, [String hardCodeFlag = 'main']) =>
      getRbacUrl(CollectionCrudInfoFlag.downloadProcessUrl, hardCodeFlag, crudInfo);

  // ──────────────────────────────────────────────────
  // Convenience URL info getters (with sudo flags)
  // ──────────────────────────────────────────────────

  RbacUrlInfo getFetchUrlInfo(List<RbacCollectionCrudItem> crudInfo, [String hardCodeFlag = 'main']) =>
      getRbacUrlInfo(CollectionCrudInfoFlag.fetchUrl, hardCodeFlag, crudInfo);

  RbacUrlInfo getCreateProcessingUrlInfo(List<RbacCollectionCrudItem> crudInfo, [String hardCodeFlag = 'main']) =>
      getRbacUrlInfo(CollectionCrudInfoFlag.createProcessingUrl, hardCodeFlag, crudInfo);

  RbacUrlInfo getUpdateProcessingUrlInfo(List<RbacCollectionCrudItem> crudInfo, [String hardCodeFlag = 'main']) =>
      getRbacUrlInfo(CollectionCrudInfoFlag.updateProcessingUrl, hardCodeFlag, crudInfo);

  RbacUrlInfo getDeleteProcessingUrlInfo(List<RbacCollectionCrudItem> crudInfo, [String hardCodeFlag = 'main']) =>
      getRbacUrlInfo(CollectionCrudInfoFlag.deleteProcessingUrl, hardCodeFlag, crudInfo);

  RbacUrlInfo getPatchProcessingUrlInfo(List<RbacCollectionCrudItem> crudInfo, [String hardCodeFlag = 'main']) =>
      getRbacUrlInfo(CollectionCrudInfoFlag.patchProcessingUrl, hardCodeFlag, crudInfo);

  // ──────────────────────────────────────────────────
  // Sudo info by URL string
  // ──────────────────────────────────────────────────

  /// Get sudo flags for a URL by searching through crud info.
  RbacUrlInfo getSudoInfoByUrl(String url, List<RbacCollectionCrudItem> crudInfo) {
    if (url.isEmpty) return RbacUrlInfo.empty;
    for (final item in crudInfo) {
      if (item.rbacEndpoint?.url == url) {
        final ep = item.rbacEndpoint!;
        return RbacUrlInfo(
          url: url,
          isSudoAction: ep.isSudoAction,
          isSudoGroupAction: ep.isSudoGroupAction,
        );
      }
    }
    return RbacUrlInfo.empty;
  }

  bool isSudoAction(String url, List<RbacCollectionCrudItem> crudInfo) =>
      getSudoInfoByUrl(url, crudInfo).isSudoAction;

  bool requiresSudo(String url, List<RbacCollectionCrudItem> crudInfo) {
    final info = getSudoInfoByUrl(url, crudInfo);
    return info.isSudoAction || info.isSudoGroupAction;
  }

  // ──────────────────────────────────────────────────
  // Action checkers
  // ──────────────────────────────────────────────────

  /// Check if an action with the given hard_code_flag exists.
  bool hasAction(String hardCodeFlag, List<RbacAction> actions) {
    return actions.any((a) => a.hardCodeFlag == hardCodeFlag);
  }

  /// Get an action by hard_code_flag.
  RbacAction? getAction(String hardCodeFlag, List<RbacAction> actions) {
    for (final a in actions) {
      if (a.hardCodeFlag == hardCodeFlag) return a;
    }
    return null;
  }

  bool hasCreateAction(List<RbacAction> actions, [String hardCodeFlag = 'creation_action_flag']) =>
      hasAction(hardCodeFlag, actions);

  bool hasUpdateAction(List<RbacAction> actions, [String hardCodeFlag = 'table_action_update_flag']) =>
      hasAction(hardCodeFlag, actions);

  bool hasDeleteAction(List<RbacAction> actions, [String hardCodeFlag = 'table_action_delete_flag']) =>
      hasAction(hardCodeFlag, actions);

  bool hasCustomAction(List<RbacAction> actions, String hardCodeFlag) =>
      hasAction(hardCodeFlag, actions);

  // ──────────────────────────────────────────────────
  // Component checkers
  // ──────────────────────────────────────────────────

  bool hasComponent(String hardCodeFlag, List<RbacComponent> components) {
    return components.any((c) => c.hardCodeFlag == hardCodeFlag);
  }
}
