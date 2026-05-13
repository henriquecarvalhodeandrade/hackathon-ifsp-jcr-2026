<div align="center">

# 🏙️ JacaMap

**Plataforma colaborativa de zeladoria urbana para Jacareí — SP**

*Hackathon IFSP Jacareí 2026*

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%2B%20Auth-FFCA28?style=flat-square&logo=firebase)
![OpenStreetMap](https://img.shields.io/badge/Mapa-OpenStreetMap-7EBC6F?style=flat-square&logo=openstreetmap)
![License](https://img.shields.io/badge/Licença-MIT-green?style=flat-square)

</div>

---

## O que é?

O **JacaMap** é um aplicativo mobile e web que permite que qualquer cidadão de Jacareí **registre, acompanhe e vote** em problemas urbanos como buracos nas vias, falta de iluminação pública, acúmulo de lixo, enchentes e outros.

O app funciona como um **mapa colaborativo em tempo real**: todos veem os problemas reportados pela comunidade, e qualquer usuário pode acompanhar o status de cada ocorrência conforme a prefeitura ou voluntários vão atualizando.

### Por que isso importa?
> A zeladoria urbana muitas vezes falha não pela falta de ação, mas pela falta de visibilidade. Um buraco que todo mundo passa por cima mas ninguém reportou. O JacaMap resolve exatamente isso.

---

## Funcionalidades do MVP

| Feature | Status |
|---|---|
| 🗺️ Mapa em tempo real com OpenStreetMap | ✅ Implementado |
| 📍 Mira central para posicionar a ocorrência | ✅ Implementado |
| 📋 Registro de denúncias (categoria, gravidade, foto, descrição) | ✅ Implementado |
| 🔍 Filtros por categoria, gravidade e status | ✅ Implementado |
| 📸 Upload de foto para o Firebase Storage | ✅ Implementado |
| 🔐 Autenticação (e-mail/senha + anônimo) via Firebase Auth | ✅ Implementado |
| 🔄 Atualização de status das denúncias em tempo real | ✅ Implementado |
| 🌙 Tema dark com visual premium | ✅ Implementado |
| 📲 Suporte a Web, Android e iOS | ✅ Implementado |

---

## Arquitetura

```
lib/
├── main.dart                     # Inicialização do app e Firebase
├── firebase_options.dart         # Configurações do Firebase
├── screens/
│   ├── map_screen.dart           # Tela principal — mapa interativo
│   └── login_screen.dart         # Pop-up de autenticação
├── widgets/
│   ├── report_modal.dart         # Bottom sheet para registrar ocorrência
│   └── report_detail_sheet.dart  # Bottom sheet de detalhes da ocorrência
└── services/
    ├── auth_service.dart         # Autenticação (Firebase Auth)
    └── firestore_service.dart    # CRUD e streaming do Firestore
```

### Fluxo de dados

```
Usuário abre o app
   │
   ├─► Login anônimo automático (visualização gratuita)
   │
   ├─► Mapa carrega denúncias em tempo real (stream Firestore)
   │
   └─► Para reportar → Login completo obrigatório
           │
           └─► Foto (opcional) → Storage → Denúncia → Firestore
```

---

## Dependências

```yaml
dependencies:
  flutter_map: ^6.1.0        # Mapa OpenStreetMap (gratuito, sem API key)
  latlong2: ^0.9.0           # Tipos de coordenadas geográficas
  geolocator: ^11.0.0        # GPS do dispositivo
  firebase_core: ^2.32.0     # Core Firebase
  cloud_firestore: ^4.17.5   # Banco de dados em tempo real
  firebase_auth: ^4.20.0     # Autenticação
  firebase_storage: ^11.7.7  # Armazenamento de fotos
  image_picker: ^1.1.2       # Câmera e galeria
  cupertino_icons: ^1.0.6    # Ícones iOS
```

> **Ponto forte:** usamos **OpenStreetMap** em vez do Google Maps — completamente **gratuito**, sem API Key, sem limite de requisições.

---

## Como rodar

### Pré-requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) `>= 3.0.0`
- Conta no [Firebase](https://firebase.google.com) (projeto já configurado)
- Android Studio / VS Code / Chrome

### 1. Clone o repositório

```bash
git clone https://github.com/seu-usuario/hackathon-ifsp-jcr-2026.git
cd hackathon-ifsp-jcr-2026
```

### 2. Instale as dependências

```bash
flutter pub get
```

### 3. Configure o Firebase

O projeto já possui as chaves configuradas em `lib/main.dart` para o ambiente de hackathon.

Para seu próprio projeto Firebase:
1. Crie um projeto em [console.firebase.google.com](https://console.firebase.google.com)
2. Ative **Authentication** (E-mail/senha + Anônimo)
3. Ative **Cloud Firestore**
4. Ative **Firebase Storage**
5. Substitua as configurações em `lib/main.dart` → `FirebaseOptions(...)`

> Veja `CONFIGURACAO.md` para instruções detalhadas.

### 4. Rode o app

```bash
# Web (mais rápido para testar)
flutter run -d chrome

# Android
flutter run -d android

# iOS
flutter run -d ios
```

---

## Estrutura do Firestore

A coleção `denuncias` é criada automaticamente. Cada documento possui:

| Campo | Tipo | Descrição |
|---|---|---|
| `categoria` | string | Ex: `"Buraco na Via"` |
| `descricao` | string | Texto livre do cidadão |
| `latitude` | double | Coordenada geográfica |
| `longitude` | double | Coordenada geográfica |
| `status` | string | `Pendente`, `Em andamento` ou `Resolvido` |
| `gravidade` | string | `Baixa`, `Média` ou `Alta` |
| `fotoUrl` | string? | URL do Firebase Storage (opcional) |
| `userId` | string? | UID do autor (anônimo ou autenticado) |
| `timestamp` | timestamp | Data/hora do registro |

---

## Licença

MIT © Hackathon IFSP Jacareí 2026
