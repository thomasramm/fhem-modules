
# Relais / Stromstoßschalter
FHEM Modul 58_Relais.pm

Bei manchen Modulen muß kurz ein ON/OFF gesendet werden, um den Status zu wechseln. z.B. bei einem Automatischen Fenster der Firma Roto, wird ein ON/OFF geschickt um das Fenster zu öffnen und ein weiteres ON/OFF um das auffahren zu stoppen.
Dieses Modul hilft dabei die Logik zu Verwalten und den aktuellen Status (Fenster fährt gerade oder Fenster macht nichts) zu speichern.
Wird das Modul Relais auf ON geschaltet, wird dem verknüpften Hardware Modul ein ON - und 1 sekunde später ein OFF gesendet. der Status des Relais in FHEM bleibt auf ON (Fenster fährt gerade). Wird dann das Modul wieder auf OFF geschaltet, wird dem verknüpften Hardware Modul wieder ein ON+OFF geschickt und der Status auf der Oberfläche wird OFF angezeigt.

## Befehle
* on: setze Hardware device-port ON/OFF, aber nur wenn der aktuelle Status nicht bereits ON ist.
* off: setze Hardware device-port ON/OFF, aber nur wenn der aktuelle Status nicht bereits OFF ist.
* reset [on, off]: setze dein Modul auf ON bzw. OFF, ohne das Hardware-device zu schalten.

Mithilfe von RESET kann der aktuelle Status in FHEM mit dem Modul syncronisiert werden, falls er aus irgendeinem Grund abweichen sollte.

## Attribute
* onTime

Zeit in Sekunfen für die das Verknüpfte Hardwaremodul bei einem Wechsel ON sein soll. Default = 0.5

## Define

define <name> Relais <device> <port>

* Name -> Name deines Geräts
* Device -> zu schaltendes Gerät 
* Port (optional) -> Reading des Device das geschaltet werden soll
