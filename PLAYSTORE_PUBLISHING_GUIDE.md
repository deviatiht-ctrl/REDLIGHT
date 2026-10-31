# Gid Konplè pou Pibliye REDLIGHT AUTOPARTS sou Google Play Store

Dokiman sa a fèt pou gide w etap pa etap pou pibliye aplikasyon **REDLIGHT AUTOPARTS** sou Google Play Store san okenn blokaj oswa rejè. Tout egzijans Google Play (Target SDK, Data Safety, Privacy Policy, AAB, Keystore) respekte a 100%.

---

## 1. Idantifyan Aplikasyon an (Package Details)

- **Non Aplikasyon an** : `REDLIGHT AUTOPARTS`
- **Application ID (Package Name)** : `com.cvisual.redlight_autoparts`
- **Version Actuelle** : `1.0.0` (Build `1`)
- **Min SDK** : 21 (Android 5.0 Lollipop+)
- **Target SDK** : 34 / 35 (Android 14/15) — Konfòm ak egzijans Google Play Store.

---

## 2. Kreye Kle Siyati (Upload Keystore)

Google Play mande pou chak aplikasyon siyen ak yon kle sekirize anvan w uploade li.

### Etap A : Jenere Keystore la
Ouvri tèminal ou (PowerShell oswa CMD) epi kouri kòmand sa a :

```powershell
keytool -genkey -v -keystore c:\Users\cbj1_u3\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

*Remak : Kenbe modpas ou chwazi a an sekirite epi pa pèdi fichye `upload-keystore.jks` sa a.*

### Etap B : Kreye fichye `android/key.properties`
Kreye yon fichye ki rele `key.properties` anndan dosye `android/` :

```properties
storePassword=MODPAS_OU_TE_METE_A
keyPassword=MODPAS_OU_TE_METE_A
keyAlias=upload
storeFile=c:/Users/cbj1_u3/upload-keystore.jks
```

*(Fichye sa a deja nan `.gitignore` pou sekirite, li p ap janm monte sou Git).*

### Etap C : Konfigire Siyati nan `android/app/build.gradle.kts`
Lè w prale nan faz pwodiksyon final, asire w `build.gradle.kts` li kle sa a :

```kotlin
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = java.util.Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = file(keystoreProperties.getProperty("storeFile"))
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}
```

---

## 3. Jenere Android App Bundle (.AAB)

Google Play pa aksepte APK pou nouvo aplikasyon ankò; li mande fòma **.aab** (Android App Bundle).

Kouri kòmand sa a nan rasin pwojè a :

```bash
flutter build appbundle --release
```

Fichye final la ap disponib nan :
`build/app/outputs/bundle/release/app-release.aab`

Se fichye sa a w ap telechaje (upload) dirèkteman sou Google Play Console.

---

## 4. Repons Egzat pou Fòmilè Google Play Console

Lè w ap ranpli fòmilè yo nan Google Play Console, itilize repons sa yo pou evite nenpòt rejè :

### A. Data Safety (Sekirite Done)
- **Èske aplikasyon an kolekte done itilizatè ?** -> **Wi (Yes)**.
- **Èske tout done yo chifre nan tranzisyon (Encrypted in transit) ?** -> **Wi (Yes)** — Tout apèl fèt sou HTTPS/TLS sekirize.
- **Èske itilizatè a ka mande efase kont li ak done li ?** -> **Wi (Yes)** — Aplikasyon an gen fonksyon efasman kont dirèk nan Pwofil (`/account/delete`).
- **Detay sou done ki kolekte :**
  1. **Enfòmasyon Pèsonèl (Personal Info)**:
     - Non (Name) : Wi (App Functionality / Jesyon Kòmand)
     - Imèl (Email) : Wi (Account Management / Otantifikasyon)
     - Telefòn (Phone number) : Wi (Livrezon & Peman MonCash/NatCash)
     - Adrès (Address) : Wi (Livrezon koli pyès machin)
  2. **Enfòmasyon Finansyè (Financial Info)**:
     - Peman fèt via API Plop Plop (Third-party processor). Aplikasyon an **PA** stoke okenn nimewo kat kredi oswa kòd PIN.
  3. **Pozisyon (Location)**:
     - Pa gen GPS an tan reyèl ki kolekte nan background sou aparèy itilizatè a. Sèlman kowòdone livrezon admin an mete pou swivi koli a.

### B. App Access (Aksè Aplikasyon)
- Chwazi : **All or some functionality is restricted** (Gen fonksyon ki mande kont).
- Bay Google yon kont tès :
  - **Username / Email** : `demo@redlight.ht`
  - **Password** : `RedlightDemo2026!`
  - *(Oswa kreye yon kont espesyal nan Supabase pou revizè Google yo ka konekte fasil).*

### C. Content Rating (Klasifikasyon Kontni - IARC)
- Kategori : **Consumer / E-Commerce**.
- Vyolans, sèks, dwòg, jwèt aza : **Non (No)** pou tout.
- Rezilta a ap : **PEGI 3 / Everyone (Tout piblik)**.

### D. Target Audience (Piblik Vizé)
- Chwazi : **18 ans et plus (18 and above)** oswa **13 ans et plus**.
- Aplikasyon an pa vize timoun (Not targeted at children).

### E. News, COVID, Government, Financial features
- Chwazi **Non (No)** pou tout. Se yon boutik e-commerce pyès oto estanda.

---

## 5. Metadata pou Fich Play Store (Store Listing)

### Tit Aplikasyon an (Max 30 karaktè)
`REDLIGHT AUTOPARTS`

### Ti Deskripsyon (Short Description - Max 80 karaktè)
`Achte pyès machin ou an Ayiti fasil, peye an sekirite epi swiv livrezon koli w.`

### Deskripsyon Konplè (Full Description)
```text
Byenveni sou REDLIGHT AUTOPARTS — premye aplikasyon e-commerce pou achte pyès machin ak tout kalite akseswa otomobil an Ayiti.

Poukisa chwazi REDLIGHT AUTOPARTS ?
• Katalòg Rich : Motè, fren, sispansyon, filtè, batri, lwil, ak tout pyès orijinal pou machin ou.
• Peman Sekirize san difikilte : Peye dirèkteman anndan app la avèk MonCash, Natcash, KashPaw oswa Kat labank atravè pòtay sekirize Plop Plop.
• Swivi Koli an Tan Reyèl : Konnen egzakteman ki kote kòmand ou ye depi lè li kite depo a rive nan men w (avèk kat entèraktif ak dat livrezon estime ETA).
• 4 Lang Disponib : Kreyòl ayisyen, Français, English, Español.
• Sipò Kliyan Rapid : Ekip nou an la pou reponn tout kesyon w epi ede w jwenn bon pyès pou modèl machin ou.

Telechaje REDLIGHT AUTOPARTS jodi a epi resevwa pyès ou byen vit kèlkeswa kote w ye an Ayiti !
```

---

## 6. Lyen Politik sou Vi Prive (Privacy Policy URL)

Google Play Store **egzije** yon URL kote politik vi prive a aksesib piblikman sou entènèt.

Nou te kreye de fichye pare pou itilize :
1. `PRIVACY_POLICY.md` (vèsyon Markdown)
2. `web/privacy_policy.html` (vèsyon sit wèb HTML pwofesyonèl)

Ou ka héberge paj HTML sa a gratis sou :
- **Vercel** (kote web app la deja deploye) : `https://redlight-autoparts.vercel.app/privacy_policy.html`
- **GitHub Pages**
- **Supabase Storage** (mete l nan yon bucket piblik)

---

## 7. Règ Tès Fèmen Google Play (Closed Testing)

Si kont devlopè Google Play ou a se yon kont pèsonèl ki kreye apre Novanm 2023, Google mande :
1. **20 testè** ki enskri nan Closed Testing track la.
2. Yo dwe kenbe aplikasyon an enstale pandan omwen **14 jou kontinye**.
3. Apre 14 jou yo, bouton "Apply for Production" an ap vin aktif pou aplikasyon an ka pibliye piblikman sou Play Store.

Si se yon kont antrepriz (Organization account), ou ka pibliye dirèkteman san egzijans 20 testè sa a.
