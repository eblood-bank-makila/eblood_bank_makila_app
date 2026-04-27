/// RBAC models for parsing the slimmed-down DEFAULT JSON from
/// GET /static/data/get-agent-applications.
/// All values are plain types (no ConfigDataStruc wrappers).

/// RBAC endpoint info (url + sudo flags).
class RbacEndpoint {
  final String url;
  final bool isSudoAction;
  final bool isSudoGroupAction;

  const RbacEndpoint({
    this.url = '',
    this.isSudoAction = false,
    this.isSudoGroupAction = false,
  });

  factory RbacEndpoint.fromJson(Map<String, dynamic> json) {
    return RbacEndpoint(
      url: json['url']?.toString() ?? '',
      isSudoAction: json['is_sudo_action'] == true,
      isSudoGroupAction: json['is_sudo_group_action'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'is_sudo_action': isSudoAction,
        'is_sudo_group_action': isSudoGroupAction,
      };
}

/// A single collection CRUD metadata entry.
class RbacCollectionCrudItem {
  final String flag;
  final String hardCodeFlag;
  final RbacEndpoint? rbacEndpoint;

  const RbacCollectionCrudItem({
    this.flag = '',
    this.hardCodeFlag = '',
    this.rbacEndpoint,
  });

  factory RbacCollectionCrudItem.fromJson(Map<String, dynamic> json) {
    return RbacCollectionCrudItem(
      flag: json['flag']?.toString() ?? '',
      hardCodeFlag: json['hard_code_flag']?.toString() ?? '',
      rbacEndpoint: json['rbac_endpoint'] != null
          ? RbacEndpoint.fromJson(json['rbac_endpoint'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'flag': flag,
        'hard_code_flag': hardCodeFlag,
        if (rbacEndpoint != null) 'rbac_endpoint': rbacEndpoint!.toJson(),
      };
}

/// RBAC action item.
class RbacAction {
  final String flag;
  final String hardCodeFlag;
  final String label;

  const RbacAction({this.flag = '', this.hardCodeFlag = '', this.label = ''});

  factory RbacAction.fromJson(Map<String, dynamic> json) {
    return RbacAction(
      flag: json['flag']?.toString() ?? '',
      hardCodeFlag: json['hard_code_flag']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'flag': flag,
        'hard_code_flag': hardCodeFlag,
        'label': label,
      };
}

/// RBAC component item.
class RbacComponent {
  final String flag;
  final String hardCodeFlag;
  final String label;

  const RbacComponent({this.flag = '', this.hardCodeFlag = '', this.label = ''});

  factory RbacComponent.fromJson(Map<String, dynamic> json) {
    return RbacComponent(
      flag: json['flag']?.toString() ?? '',
      hardCodeFlag: json['hard_code_flag']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'flag': flag,
        'hard_code_flag': hardCodeFlag,
        'label': label,
      };
}

/// RBAC path guard.
class RbacPathGuard {
  final String path;
  final String pathGuard;

  const RbacPathGuard({this.path = '', this.pathGuard = ''});

  factory RbacPathGuard.fromJson(Map<String, dynamic> json) {
    return RbacPathGuard(
      path: json['path']?.toString() ?? '',
      pathGuard: json['path_guard']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'path': path,
        'path_guard': pathGuard,
      };
}

/// RBAC Menu item (recursive – has sub_menus).
class RbacMenu {
  final String id;
  final String name;
  final String descriptionStr;
  final String flag;
  final int orderBy;
  final String applicationGroupFlag;
  final bool isHidden;
  final bool isActivated;
  final String iconUrl;
  final RbacPathGuard rbacPathGuard;
  final List<RbacMenu> subMenus;
  final List<RbacAction> rbacActions;
  final List<RbacComponent> rbacComponents;
  final List<RbacCollectionCrudItem> collectionCrudInfo;

  const RbacMenu({
    this.id = '',
    this.name = '',
    this.descriptionStr = '',
    this.flag = '',
    this.orderBy = 0,
    this.applicationGroupFlag = '',
    this.isHidden = false,
    this.isActivated = true,
    this.iconUrl = '',
    this.rbacPathGuard = const RbacPathGuard(),
    this.subMenus = const [],
    this.rbacActions = const [],
    this.rbacComponents = const [],
    this.collectionCrudInfo = const [],
  });

  factory RbacMenu.fromJson(Map<String, dynamic> json) {
    return RbacMenu(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      descriptionStr: json['description_str']?.toString() ?? '',
      flag: json['flag']?.toString() ?? '',
      orderBy: json['order_by'] is int ? json['order_by'] : 0,
      applicationGroupFlag: json['application_group_flag']?.toString() ?? '',
      isHidden: json['ishidden'] == true,
      isActivated: json['isactivated'] != false,
      iconUrl: (json['icon'] is Map) ? (json['icon']['icon_url']?.toString() ?? '') : '',
      rbacPathGuard: RbacPathGuard.fromJson(json['rbac_path_guard'] ?? {}),
      subMenus: (json['sub_menus'] as List<dynamic>?)
              ?.map((e) => RbacMenu.fromJson(e))
              .toList() ??
          [],
      rbacActions: (json['rbac_actions'] as List<dynamic>?)
              ?.map((e) => RbacAction.fromJson(e))
              .toList() ??
          [],
      rbacComponents: (json['rbac_components'] as List<dynamic>?)
              ?.map((e) => RbacComponent.fromJson(e))
              .toList() ??
          [],
      collectionCrudInfo: (json['collection_crud_info'] as List<dynamic>?)
              ?.map((e) => RbacCollectionCrudItem.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description_str': descriptionStr,
        'flag': flag,
        'order_by': orderBy,
        'application_group_flag': applicationGroupFlag,
        'ishidden': isHidden,
        'isactivated': isActivated,
        'icon': {'icon_url': iconUrl},
        'rbac_path_guard': rbacPathGuard.toJson(),
        'sub_menus': subMenus.map((e) => e.toJson()).toList(),
        'rbac_actions': rbacActions.map((e) => e.toJson()).toList(),
        'rbac_components': rbacComponents.map((e) => e.toJson()).toList(),
        'collection_crud_info': collectionCrudInfo.map((e) => e.toJson()).toList(),
      };
}

/// RBAC Application item (top-level, contains sub_menus).
class RbacApplication {
  final String id;
  final String name;
  final String descriptionStr;
  final String flag;
  final int orderBy;
  final String applicationGroupFlag;
  final bool isHidden;
  final bool isActivated;
  final String iconUrl;
  final RbacPathGuard rbacPathGuard;
  final List<RbacMenu> subMenus;
  final List<RbacAction> rbacActions;
  final List<RbacComponent> rbacComponents;
  final List<RbacCollectionCrudItem> collectionCrudInfo;

  const RbacApplication({
    this.id = '',
    this.name = '',
    this.descriptionStr = '',
    this.flag = '',
    this.orderBy = 0,
    this.applicationGroupFlag = '',
    this.isHidden = false,
    this.isActivated = true,
    this.iconUrl = '',
    this.rbacPathGuard = const RbacPathGuard(),
    this.subMenus = const [],
    this.rbacActions = const [],
    this.rbacComponents = const [],
    this.collectionCrudInfo = const [],
  });

  factory RbacApplication.fromJson(Map<String, dynamic> json) {
    return RbacApplication(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      descriptionStr: json['description_str']?.toString() ?? '',
      flag: json['flag']?.toString() ?? '',
      orderBy: json['order_by'] is int ? json['order_by'] : 0,
      applicationGroupFlag: json['application_group_flag']?.toString() ?? '',
      isHidden: json['ishidden'] == true,
      isActivated: json['isactivated'] != false,
      iconUrl: (json['icon'] is Map) ? (json['icon']['icon_url']?.toString() ?? '') : '',
      rbacPathGuard: RbacPathGuard.fromJson(json['rbac_path_guard'] ?? {}),
      subMenus: (json['sub_menus'] as List<dynamic>?)
              ?.map((e) => RbacMenu.fromJson(e))
              .toList() ??
          [],
      rbacActions: (json['rbac_actions'] as List<dynamic>?)
              ?.map((e) => RbacAction.fromJson(e))
              .toList() ??
          [],
      rbacComponents: (json['rbac_components'] as List<dynamic>?)
              ?.map((e) => RbacComponent.fromJson(e))
              .toList() ??
          [],
      collectionCrudInfo: (json['collection_crud_info'] as List<dynamic>?)
              ?.map((e) => RbacCollectionCrudItem.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description_str': descriptionStr,
        'flag': flag,
        'order_by': orderBy,
        'application_group_flag': applicationGroupFlag,
        'ishidden': isHidden,
        'isactivated': isActivated,
        'icon': {'icon_url': iconUrl},
        'rbac_path_guard': rbacPathGuard.toJson(),
        'sub_menus': subMenus.map((e) => e.toJson()).toList(),
        'rbac_actions': rbacActions.map((e) => e.toJson()).toList(),
        'rbac_components': rbacComponents.map((e) => e.toJson()).toList(),
        'collection_crud_info': collectionCrudInfo.map((e) => e.toJson()).toList(),
      };
}
