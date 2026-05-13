# hackathon-ifsp-jcr-2026 — Zeladoria Digital

## Project Overview
App de zeladoria urbana desenvolvido para o Hackathon do IFSP Jacareí (Instituto Federal de São Paulo - Campus Jacareí) durante a Semana Cultural 2026.

**Nome do app:** Zeladoria Digital  
**Plataformas:** Android, iOS, Web (Flutter cross-platform)

## Stack Técnica
- **Framework:** Flutter / Dart
- **Mapa:** OpenStreetMap via `flutter_map` + `latlong2` (100% gratuito, sem API key)
- **Localização:** `geolocator`
- **Backend:** Firebase Cloud Firestore (tempo real)
- **Auth:** Firebase Auth (anônimo + e-mail/senha) via `firebase_auth`
- **Storage:** Firebase Storage para fotos via `firebase_storage`
- **Imagens:** `image_picker` (câmera e galeria)

## Estrutura do Projeto
```
lib/
  main.dart                       # Entry point + auth anônima automática
  screens/
    map_screen.dart               # Mapa OSM, marcadores, filtros, AppBar flutuante
    login_screen.dart             # Tela de login/cadastro com branding
  widgets/
    report_modal.dart             # Modal de nova denúncia (categoria, gravidade, foto)
    report_detail_sheet.dart      # Sheet de detalhe + atualizar status
  services/
    firestore_service.dart        # Lógica Firestore (modelo Denuncia expandido)
    auth_service.dart             # Firebase Auth (anônimo, e-mail/senha, logout)

pubspec.yaml                      # Dependências do projeto
```

## Funcionalidades Implementadas
1. **Mapa OpenStreetMap** — tiles gratuitos, tema dark invertido, marcadores por categoria/status
2. **Autenticação** — login anônimo automático; login/cadastro por e-mail; logout
3. **Denúncias com gravidade** — campo `gravidade` (Baixa/Média/Alta) com ícones visuais
4. **Upload de foto** — câmera ou galeria, upload para Firebase Storage
5. **Atualizar status** — usuários logados podem mudar status de qualquer denúncia
6. **Filtros em tempo real** — barra de chips para Categoria, Gravidade e Status
7. **UI polida** — dark theme, animações, badges coloridos, AppBar flutuante

## Configuração Necessária (antes de rodar)

### Firebase (único passo necessário)
- Projeto já configurado: `hackathon-ifsp-jcr-2026`
- Ativar **Firebase Auth** (método: e-mail/senha + anônimo) no console
- Ativar **Firebase Storage** no console
- Ativar **Cloud Firestore** no console

## Comandos
```bash
flutter pub get       # instalar dependências
flutter run           # rodar no dispositivo/emulador
flutter build web     # build para web
```

## User Preferences
- Language: Portuguese (BR)
