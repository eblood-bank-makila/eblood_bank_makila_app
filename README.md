# eblood_bank_mak_app

Application d'interconnection des banques de sang, hopitaux, donneurs

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Publier via Bloonio Store

Mises à jour Dart à distance (code push). Configuration : `bloonio_store.yaml`.

```sh
curl -fsSL https://install.bloonio.com/store | bash   # installe le CLI bstore
bstore login
bstore release android                                # build + enregistre la release
bstore patch android --release-version 1.1.1+6        # <version+build> de la release
bstore patches rollback --release-version 1.1.1+6 --patch-number 1
```

- Avant `bstore release` : le `.env` suivi par git doit être la config de production (il est embarqué comme asset ; un patch ne peut pas le modifier).
- **Important** : envoyer sur Play l'AAB exact affiché par `bstore release`. Le versionCode est dérivé de l'heure de build : un bundle construit séparément aurait un autre code et ne recevrait pas les patches. Sinon, fixer `versionCodeOverride=NNN` dans `android/gradle.properties` pour les deux builds.
- Un patch ne contient que du code Dart. Tout changement natif, de plugin, d'asset ou de `.env` exige une nouvelle release.
- Outils de build minimum (Flutter 3.47.2 du Store) : Android Gradle Plugin 8.11.1, Kotlin 2.2.20, Gradle 8.14.3.

Guide : https://docs.bloonio.com/store/quickstart/
