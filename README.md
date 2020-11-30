# fhem-modules

Die Module dieses Repositories sind Erweiterungen für die Hausautomatisierungsplattform [FHEM](http://fhem.de])
Ziel dieser Module ist es auf einfache Weise spezielle Objekte zur Verfügung zu stellen, die sonst nur durch mehrere Objekte in FHEM realisiert werden müssten.

## FHEM Befehle für externe Module
im FHEM Befehlsfenster folgende Befehle eingeben:

**Installation:** update add URL

**Auf Updates prüfen:** update all URL

Die URL für die Module lauten:

Modul Relais: `https://raw.githubusercontent.com/thomasramm/fhem-modules/master/controls_relais.txt`

Modul RolloRelais `https://raw.githubusercontent.com/thomasramm/fhem-modules/master/controls_rollorelais.txt`

Modul Taster `https://raw.githubusercontent.com/thomasramm/fhem-modules/master/controls_taster.txt`

Alle Module: `https://raw.githubusercontent.com/thomasramm/fhem-modules/master/controls_thomasramm.txt`


## Die Module

### [Taster](Taster.md)
Anlegen von Tastern mit mehrfachbelegung (Einfacher Tastendruck, doppelter Tastendruck, langer Tastendruck)

### [Relais](Relais.md)
Schalten von Stromstoßschaltern.

### Rollo
Modul um Rollos über Relais zu steuern. Die Relais kennen nur ON/OFF (fahre das Rollo), das Modul speichert sich über zusätzliche Berechnungen den aktuellen Stand des Rollo (0%-100% zu) und fügt der Oberfläche entsprechende Icons hinzu, die den Status visualisieren. Dazu kommen Attribute wie Blockiert (das Rollo darf nicht gefahren werden), die wieder von anderen Modulen beschrieben werden können, wie z.b. einem Fensterkontakt.

Da ich diese Art von Rollo nicht mehr habe, habe ich das Modul an RettungsTim übergeben. Ihr findet das Modul sowie Beschreibungen dazu hier:
[fhem-rollo](https://github.com/RettungsTim/fhem-rollo)

### RolloRelais
Beschreibung folgt



