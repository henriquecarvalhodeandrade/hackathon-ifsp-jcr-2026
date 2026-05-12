# hackathon-ifsp-jcr-2026 — Zeladoria Digital

## Project Overview
App de zeladoria urbana desenvolvido para o Hackathon do IFSP Jacareí (Instituto Federal de São Paulo - Campus Jacareí) durante a Semana Cultural 2026.

**Nome do app:** Zeladoria Digital  
**Plataformas:** Android, iOS, Web (Flutter cross-platform)

## Stack Técnica
- **Framework:** Flutter / Dart
- **Mapa:** Google Maps Flutter (`google_maps_flutter`)
- **Localização:** `geolocator`
- **Backend:** Firebase Cloud Firestore (tempo real)
- **Auth/Init:** `firebase_core`

## Estrutura do Projeto
```
lib/
  main.dart                  # Entry point + inicialização Firebase
  screens/
    map_screen.dart          # Tela principal com mapa em tela cheia
  widgets/
    report_modal.dart        # Modal de denúncia (BottomSheet)
  services/
    firestore_service.dart   # Toda a lógica Firebase/Firestore

android/app/src/main/
  AndroidManifest.xml        # Permissões + API Key do Google Maps (Android)

ios/Runner/
  AppDelegate.swift          # API Key do Google Maps (iOS)
  Info.plist                 # Permissões de localização (iOS)

web/
  index.html                 # Script do Google Maps (Web)

pubspec.yaml                 # Dependências do projeto
CONFIGURACAO.md              # Guia completo de configuração Firebase + Maps
```

## Configuração Necessária (antes de rodar)

### 1. Firebase
- Criar projeto em https://console.firebase.google.com
- Baixar `google-services.json` → colocar em `android/app/`
- Baixar `GoogleService-Info.plist` → colocar em `ios/Runner/`
- Ativar Cloud Firestore no console

### 2. Google Maps API Key
Substituir `SUA_GOOGLE_MAPS_API_KEY_AQUI` em:
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/AppDelegate.swift`
- `web/index.html`

Ver guia completo em `CONFIGURACAO.md`.

## Comandos
```bash
flutter pub get       # instalar dependências
flutter run           # rodar no dispositivo/emulador
flutter build web     # build para web
```

## User Preferences
- Language: Portuguese (BR)
