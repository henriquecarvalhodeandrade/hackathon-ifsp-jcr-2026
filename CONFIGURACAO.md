# Guia de Configuração — JacaMap

## 1. Firebase

### Passo 1 — Criar projeto no Firebase
1. Acesse [console.firebase.google.com](https://console.firebase.google.com)
2. Clique em **Adicionar projeto** e siga o assistente
3. Ative o **Cloud Firestore** em modo de teste

### Passo 2 — Adicionar o app Android
1. No Firebase Console, clique em **Adicionar app > Android**
2. Use o package name: `com.example.zeladoria_digital`
3. Baixe o arquivo `google-services.json`
4. Coloque o arquivo em: `android/app/google-services.json`

### Passo 3 — Adicionar o app iOS
1. No Firebase Console, clique em **Adicionar app > iOS**
2. Use o bundle ID: `com.example.zeladoriaDigital`
3. Baixe o arquivo `GoogleService-Info.plist`
4. Coloque o arquivo em: `ios/Runner/GoogleService-Info.plist`

### Passo 4 — Configurar o build.gradle (Android)
No arquivo `android/build.gradle` (raiz), adicione no bloco `dependencies`:
```groovy
classpath 'com.google.gms:google-services:4.4.0'
```

No arquivo `android/app/build.gradle`, adicione ao final:
```groovy
apply plugin: 'com.google.gms.google-services'
```

---

## 2. Google Maps API Key

### Obter a chave
1. Acesse [console.cloud.google.com](https://console.cloud.google.com)
2. Crie um projeto ou use o mesmo do Firebase
3. Vá em **APIs e Serviços > Credenciais > Criar credencial > Chave de API**
4. Ative as APIs necessárias:
   - **Maps SDK for Android**
   - **Maps SDK for iOS**
   - **Maps JavaScript API** (para web)

### Inserir a chave nos arquivos

| Plataforma | Arquivo | Campo |
|---|---|---|
| Android | `android/app/src/main/AndroidManifest.xml` | `android:value="SUA_GOOGLE_MAPS_API_KEY_AQUI"` |
| iOS | `ios/Runner/AppDelegate.swift` | `GMSServices.provideAPIKey("SUA_GOOGLE_MAPS_API_KEY_AQUI")` |
| Web | `web/index.html` | `?key=SUA_GOOGLE_MAPS_API_KEY_AQUI` |

---

## 3. Estrutura do Firestore

A coleção `denuncias` será criada automaticamente. Estrutura de cada documento:

```
denuncias/{id}
  ├── categoria   : string  (ex: "Buraco na Via")
  ├── descricao   : string  (ex: "Grande buraco na Rua X")
  ├── latitude    : double  (ex: -23.3055)
  ├── longitude   : double  (ex: -45.9659)
  ├── status      : string  (padrão: "Pendente")
  └── timestamp   : timestamp
```

### Regras de segurança sugeridas (Firestore)
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /denuncias/{doc} {
      allow read: if true;
      allow create: if true;
      allow update, delete: if false; // apenas admins
    }
  }
}
```

---

## 4. Executar o projeto

```bash
# Instalar dependências
flutter pub get

# Rodar no Android
flutter run -d android

# Rodar no iOS
flutter run -d ios

# Rodar na Web
flutter run -d chrome

# Build para produção (web)
flutter build web
```

---

## 5. Cores e Marcadores

| Status | Cor do marcador |
|---|---|
| Pendente | Vermelho |
| Em andamento | Amarelo |
| Resolvido | Verde |
