# ClipKeep – Zwischenablage-App fürs iPhone

Eine private Clipboard-App nach dem Vorbild der Samsung-Zwischenablage:
Texte speichern, anheften und jederzeit wieder einfügen – direkt aus der Tastatur.

---

## 1. Der Plan

### Was iOS erlaubt (und was nicht)

| Samsung-Funktion | Auf dem iPhone möglich? | Lösung in ClipKeep |
|---|---|---|
| Alles Kopierte landet automatisch im Verlauf | ❌ iOS verbietet Apps, die Zwischenablage im Hintergrund mitzulesen | Ein Tipp zum Speichern: **Banner in der App**, **„Sichern“-Taste in der Tastatur** oder **Doppeltipp auf die iPhone-Rückseite** (Kurzbefehl) |
| Zwischenablage in der Tastatur | ✅ über eine eigene Tastatur-Erweiterung | **ClipKeep-Tastatur**: Tippen auf einen Eintrag fügt ihn ein |
| Einträge anheften | ✅ | Angeheftete Einträge stehen oben und werden nie gelöscht |
| Verlauf mit Limit | ✅ | Die letzten 200 nicht angehefteten Einträge |
| Suchen, bearbeiten, löschen, teilen | ✅ | In der App (Wischen bzw. lange drücken) |

### Aufbau

```
ClipKeep/
├── project.yml              ← XcodeGen: erzeugt daraus das Xcode-Projekt
├── Shared/                  ← Code, den App UND Tastatur nutzen
│   ├── AppGroup.swift       ← gemeinsamer Speicherort (App Group)
│   ├── ClipItem.swift       ← ein Eintrag (Text, Titel, angeheftet, Datum …)
│   └── ClipStore.swift      ← Laden/Speichern als JSON, Verlauf-Limit
├── App/                     ← die eigentliche iPhone-App (SwiftUI)
│   ├── ContentView.swift    ← Liste, Suche, Einsetzen-Knopf, Banner
│   ├── ClipEditView.swift   ← Eintrag anlegen/bearbeiten
│   ├── SettingsView.swift   ← Einrichtungshilfe, Verlauf löschen
│   └── SaveTextIntent.swift ← Kurzbefehl-Aktion „In ClipKeep speichern“
└── Keyboard/                ← Tastatur-Erweiterung
    ├── KeyboardViewController.swift
    └── KeyboardView.swift   ← Angeheftet/Verlauf, Sichern, 🌐, ⌫, ⏎
```

- **Kein Server, keine Cloud, kein Tracking.** Alles bleibt als Datei auf deinem iPhone.
- **iOS 17+**, Swift/SwiftUI, keine externen Bibliotheken.
- App und Tastatur teilen sich die Daten über eine **App Group** (`group.com.abdulwazery.clipkeep`).

### Mögliche Erweiterungen später
- Widget auf dem Home-/Sperrbildschirm mit den Top-Einträgen
- Kategorien/Ordner (z. B. „Arbeit“, „Privat“)
- Bilder und Links speichern
- iCloud-Sync zwischen iPhone und iPad
- Face-ID-Sperre für sensible Einträge (IBAN, Passwörter)

---

## 2. Auf dein iPhone bringen

### Was du brauchst
- Einen **Mac** mit **Xcode 16 oder neuer** (kostenlos im Mac App Store)
- Deine **Apple-ID**
- Ein USB-Kabel (nur beim ersten Mal)

### Schritte

1. **XcodeGen installieren und Projekt erzeugen** (im Terminal auf dem Mac):
   ```bash
   brew install xcodegen          # falls Homebrew fehlt: https://brew.sh
   git clone https://github.com/AbdulRaqibWazery/AbdulRaqibWazery.git
   cd AbdulRaqibWazery/ClipKeep
   xcodegen generate
   open ClipKeep.xcodeproj
   ```

2. **Signieren**: In Xcode links das Projekt **ClipKeep** anklicken →
   für **beide** Targets (`ClipKeep` und `ClipKeepKeyboard`) unter
   *Signing & Capabilities* dein **Team** (deine Apple-ID) auswählen.

3. **Falls Xcode meckert, dass die Bundle-ID oder App Group vergeben ist**:
   ersetze `com.abdulwazery` überall durch etwas Eigenes (z. B. `de.deinname`):
   - in `project.yml` (Bundle-IDs und App Group)
   - in `Shared/AppGroup.swift` (`identifier`)
   Danach erneut `xcodegen generate`.

4. **iPhone vorbereiten**: per Kabel verbinden, *Einstellungen → Datenschutz & Sicherheit →
   Entwicklermodus* einschalten (iPhone startet neu).

5. In Xcode oben dein iPhone als Ziel wählen und **▶︎ Run** drücken.
   Beim ersten Start: *Einstellungen → Allgemein → VPN & Geräteverwaltung →*
   dein Entwicklerprofil → **Vertrauen**.

> **Hinweis zur kostenlosen Apple-ID:** Selbst installierte Apps laufen damit **7 Tage**,
> danach einfach in Xcode erneut auf ▶︎ drücken. Mit dem Apple Developer Program
> (99 €/Jahr) gilt die Installation ein Jahr. Sollte die App Group mit deinem kostenlosen
> Konto nicht freigeschaltet werden, funktioniert die App weiterhin, nur die Tastatur
> sieht dann die Einträge nicht.

---

## 3. Einrichten & benutzen

### Tastatur aktivieren (wichtigster Teil)
1. *Einstellungen → Allgemein → Tastatur → Tastaturen → Tastatur hinzufügen …* → **ClipKeep**
2. Auf **ClipKeep** tippen → **Vollen Zugriff erlauben** einschalten
   (nötig, damit die Tastatur deine gespeicherten Texte lesen und die Zwischenablage sichern kann –
   ClipKeep hat trotzdem keinerlei Internetzugriff).
3. In einem beliebigen Textfeld auf 🌐 tippen (oder halten) → ClipKeep.
   - Eintrag antippen → wird eingefügt
   - **Sichern** → speichert, was gerade kopiert ist
   - 🌐 → zurück zur normalen Tastatur

### Texte speichern
- **In der App**: Wenn du etwas kopiert hast, erscheint oben ein Banner → *Einsetzen*.
  Oder der Einsetzen-Knopf oben rechts.
- **Eigene Textbausteine**: **+** → Titel (z. B. „Adresse“) und Text eingeben.
- **In der Tastatur**: Taste **Sichern**.
- **Per Doppeltipp auf die Rückseite** (am bequemsten):
  1. App **Kurzbefehle** → **+** → Aktion *Zwischenablage abrufen*
  2. Aktion *In ClipKeep speichern* hinzufügen
  3. *Einstellungen → Bedienungshilfen → Tippen → Auf Rückseite tippen → Doppeltippen* → deinen Kurzbefehl wählen
  4. Tipp: Damit nicht jedes Mal gefragt wird, unter *Einstellungen → Apps → Kurzbefehle → Aus anderen Apps einsetzen* „Erlauben“ wählen.

### In der App
- **Tippen** = kopieren
- **Nach rechts wischen** = anheften/lösen
- **Nach links wischen** = bearbeiten/löschen
- **Lange drücken** = Menü mit Teilen usw.
- **Suche** oben in der Liste
