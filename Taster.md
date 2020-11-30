# Taster
FHEM Modul 58_TASTER.pm

Dieses Modul ist eine Erweiterung für die Hausautomatisierungsplattform [FHEM](http://fhem.de])
Ziel dieses Moduls ist es auf einfache Weise Taster mehrfach zu belegen, so dass ein Tastendruck, doppelte Tastendrücke und lange Tastendrücke erkannt und unterschiedlich darauf reagiert werden kann.
Das Modul wertet on/off Stati eines Readings oder anderen Device aus und zählt/speichert die Millisekunden die zwischen den Readingaktualisierungen liegen. Dabei kann das Modul folgende Situationen erkennen:
- kurzer Tastendruck
- langer Tastendruck
- doppelter Tastendruck
- Taste wird gerade gedrückt

Getestet habe ich dieses Modul bisher mit einem I2C_MCP23017, einer Siemens S5 Steuerungsanlage sowie mit Dummy die den Status On/Off annehmen können.
Das Hauptaugenmerk liegt bei diesem Modul darauf die verschiedenen Tastendrücke auszuwerten, die Darstellung
der Tasten auf der Oberfläche und die Set-Methoden dienen mehr dem Debugging, nichts desto trotz wird der letzte Tastendruck bzw. ein "Wird gerade gedrückt" visuell dargestellt und es ist möglich die verschiedenen Tastendrücke per set zu simulieren. 
Die zur Darstellung benutzte devStateIcon-Definition sowie webCmd-Definition wird bei einem define automatisch mit erzeugt, so dass man sich da einiges an Tipp-Arbeit spart wenn man die Darstellung so übernimmt.

Wird ein Doppelklick definiert bedeutet dies natürlich das auch bei jedem einfachen Tastendruck kurz gewartet wird ob ein zweiter folgt und somit die Schaltvorgänge alle etwas verzögert ausgeführt werden. Ich habe eine Wartezeit von 0,5 Sekunden bei den meisten Tastern und empfinde es als nicht störend. Soll der doppelte Tastendruck nicht ausgewertet werden, sondern nur ein kurzer oder langer Tastendruck, dann einfach die Definitionen für den doppelten Tastendruck löschen oder die Wartezeit auf 0 setzen, dann werden die Schaltvorgänge wieder sofort ausgeführt.

Der zuletzt erkannte Tastendruck wird im state-Reading gespeichert.
Zusätzlich zur Auswertung des Tastendrucks kann man auch gleich noch einen Befehl hinterlegen der bei diesem Tastendruck ausgewertet werden soll, so dass man sich ein DOIF oder notify sparen kann. Das macht das ganze für mich etwas übersichtlicher.

In der Definition wird das Hardwaremodul und [optional: das Reading (der Port/Adresse)] des "on"/"off" Tasters angegeben</p>

**Beispiel**
`define Taster1 TASTER myMcp20 PortB1`

###Modul Installation

durch den Befehl
update add https://raw.githubusercontent.com/ThomasRamm/fhem-modules/master/controls_taster.txt
wird das Modul dem allgemeinem Updateprozess hinzugefügt,
mit update all wird dann sowohl fhem als auch dieses Modul aktualisiert.
Details zu update findest du im [fhem wiki](https://wiki.fhem.de/wiki/Update#update_add)

##Moduldefinition und -funktion##

###Define###
`define <name> TASTER <device> <port>`
- device = Das Device in fhem dessen Reading ausgewertet werden soll
- port = Der Auszuwertende Port/Reading des Device

###Set###
`set <name> pushed`
Status des devices auf 'pushed' setzen und verknüpfte aktionen auslösen
 
`set <name> short-click`
 Status des devices auf 'short-click' setzen und verknüpfte aktionen auslösen
 
`set <name> double-click`
 Status des devices auf 'double-click' setzen und verknüpfte aktionen auslösen
 
`set <name> long-click`
 Status des devices auf 'long-click' setzen und verknüpfte aktionen auslösen

###Attribute###
####long-click-time####
  Zeit in Sekunden die eine Taste gedrückt werden muss um als "Langer Tastendruck" ausgewertet zu werden
####long-click-define####
  Optionaler Befehl der bei einem langen Tastendruck ausgeführt werden soll.
  Hier ist alles erlaubt was auch in der Befehlszeile von fhem eingegeben werden kann.
####short-click-define####
  Optionaler Befehl der bei einem kurzen Tastendruck ausgeführt werden soll.
  Hier ist alles erlaubt was auch in der Befehlszeile von fhem eingegeben werden kann.
####double-click-time####
  Zeit in Sekunden die nach einem Tastendruck gewartet werden soll. Erfolgt innerhalb dieser Zeit ein weiterer Tastendruck, so wird ein "Doppelter Tastendruck" ausgewertet.
####double-click-define####
  Optionaler Befehl der bei einem kurzen Tastendruck ausgeführt werden soll.
  Hier ist alles erlaubt was auch in der Befehlszeile von fhem eingegeben werden kann.
####pushed-click-define####
  Optionaler Befehl der bei einem kurzen Tastendruck ausgeführt werden soll.
  Hier ist alles erlaubt was auch in der Befehlszeile von fhem eingegeben werden kann.

## Beispielkonfiguration inkl. Readings##
Ich benutzt das Modul um bei einem einfachen Klick das Licht, bei einem Doppelklick meinen Rolladen zu bedienen. Fährt der Rolladen gerade, so reicht wiederrum ein einfacher Klick um ihn zu stoppen.

```
define TasterWL TASTER modulE22 PortB0
attr TasterWL devStateIcon short-click:control_on_off@green long-click:control_on_off@blue pushed:control_on_off@red double-click:control_on_off@orange
attr TasterWL double-click-define set RolladenTerassentuer,RolladenWohnzimmer offen
attr TasterWL double-click-time 0.5
attr TasterWL long-click-define set dummy1 toggle
attr TasterWL long-click-time 1
attr TasterWL short-click-define {if (Value("RolladenTerassentuer") =~ /drive/) {fhem("set RolladenTerassentuer,RolladenWohnzimmer stop")} else {fhem("set WohnzimmerLicht1 toggle")}}
attr TasterWL webCmd short-click:long-click:double-click[/code]
```
Beschreibung der Zeilen:

1. die Definition meines Linken Wohnzimmer-Tasters, der Taster ist in fhem als modulE22, dort das Reading PortB0 definiert.
2. das Icon auf der Oberfläche. Diese Definition wird automatisch eingefügt.
3. Der Befehl der bei einem Doppelten Klick ausgeführt wird (Rollos auf)
4. Wenn zwischen zwei Tastendrücken <= 0,5 Sekunden liegen, dann als Doppel-Klick auswerten
5. Einen Langen Tastendruck werte ich hier nicht aus, zur besseren Doku hier habe ich einen dummy eingetragen
6. Wird die Taste beim drücken >= 1 sekunde gehalten, wird der Druck als langer Tastendruck ausgewertet
7. Bei einem kurzen Tastendruck wird ein kleiner Perl-Code ausgeführt, der prüft ob das Rollo gerade fährt, wenn ja dann Rollo stoppen, sonst mein Wohnzimmerlicht schalten
8. die Set-Befehle auf der Oberfläche, dieses Attribut wird ebenfalls automatisch eingefügt.

Bei Fragen und Fehlern und Anregungen wendet ihr euch an besten an mich über den Eintrag zu diesem Modul im [FHEM Forum](https://forum.fhem.de/index.php/topic,47219.0.html)
