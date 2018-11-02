############################################################
# $Id: 58_TASTER.pm 1002 2017-02-08 17:58:00Z ThomasRamm $ #
#
############################################################
package main;

use strict;
use warnings;
use Time::HiRes;
use Data::Dumper;

#***** alle möglichen stati die ein Taster haben kann
my %sets = (
  "pushed" => "noArg",
  "long-click" => "noArg",
  "short-click" => "noArg",
  "double-click" => "noArg");

#***** Ich benutze keine gets. zum testen von Funktionalität kann dies benutzt werden
# auf der oberfläche gibt es dann einen neuen Schalter der die Subroutine TASTER_Get
# aufruf. dort können dann Tests etc. entwickelt werden
my %gets = (
#  "write_hash_to_log" => "write");
 );

############################################################ INITIALIZE #####
# Die Funktion wird von Fhem.pl nach dem Laden des Moduls 
# aufgerufen und bekommt einen Hash für das Modul als zentrale 
# Datenstruktur übergeben.
sub TASTER_Initialize($) {
  my ($hash) = @_;
  my $name = $hash->{NAME};
  Log3 "global",4,"TASTER (?) >> Initialize";

  $hash->{DefFn}    = "TASTER_Define";
  $hash->{UndefFn}  = "TASTER_Undef";
  $hash->{SetFn}    = "TASTER_Set";
  $hash->{GetFn}    = "TASTER_Get";
  $hash->{AttrFn}   = "TASTER_Attr";
  $hash->{NotifyFn} = "TASTER_Notify";

  #zusätzliche Benutzerdefinierte Attribute die auf der Oberfläche gesetzt
  #werden können. hier sollten alle Parameter rein
  $hash->{AttrList} = " "
#    . " device"
#    . " port"
#    . " IODev"  #hat eine besondere Bedeutung, evtl hier das Hardwaremodul eintragen
    . " long-click-time"
    . " long-click-define"
#   . " short-click-time" #Short-click benötigt keine Time, ist durch long-click festgelegt
    . " short-click-define"
    . " double-click-time"
    . " pushed-define"
    . " double-click-define";
  Log3 "global",5,"TASTER (?) << Initialize";
}

################################################################ DEFINE #####
# Die Define-Funktion eines Moduls wird von Fhem aufgerufen wenn 
# der Define-Befehl für ein Geräte ausgeführt wird und das Modul 
# bereits geladen und mit der Initialize-Funktion initialisiert ist
sub TASTER_Define($$) {
  my ($hash,$def) = @_;
  my $name = $hash->{NAME};
  Log3 $name,5,"TASTER ($name) >> Define";
  
  my @a = split( "[ \t][ \t]*", $def );

  # Name des Geräts 
  #$name = $a[0]; #-> myTASTER

  # Typ des Geräts
  #$typ = $a[1]; #-> 'TASTER'

  #Parameter1: Name des Geräts das die Eingänge enthält
  $hash->{device} = $a[2];
  
  #Parameter2: Adresse des TASTER Pin
  $hash->{port} = $a[3];

  #als Ausgangswert gehe ich davon aus das das TASTER offen ist
  $hash->{STATE} = "short-click";

  #Als Vorgabe einige Attribute definieren, das macht weniger Arbeit als sie
  #bei jedem TASTER komplett neu zu erfassen

  $attr{$name}{"long-click-time"} = 1;    #wird der Taster länger als 1 Sekunde gedrückt ist es ein long-click
  $attr{$name}{"double-click-time"} = 0.5;  #Zeit zwischen zwei click die zu einen double-click führen
  $attr{$name}{"webCmd"} = "short-click:long-click:double-click";
  $attr{$name}{"devStateIcon"} = 'short-click:control_on_off@green long-click:control_on_off@blue pushed:control_on_off@red double-click:control_on_off@orange';

  #AssignIoPort($hash);
  #IOWrite schreibt später

  $hash->{NOTIFYDEV} = $a[2];
  
  Log3 $name,5,"TASTER ($name) << Define";
}

################################################################# UNDEF #####
# wird aufgerufen wenn ein Gerät mit delete gelöscht wird oder bei 
# der Abarbeitung des Befehls rereadcfg, der ebenfalls alle Geräte 
# löscht und danach das Konfigurationsfile neu abarbeitet.
sub TASTER_Undef($) {
  my ($hash) = @_;
  my $name = $hash->{NAME};
  Log3 $name,5,"TASTER ($name) >> Undef";

  RemoveInternalTimer($hash);

  Log3 $name,5,"TASTER ($name) << Undef";
}

#################################################################### SET #####
# Sie ist dafür gedacht, Werte zum physischen Gerät zu schicken. 
# das brauchen wir hier aber nicht. 
# Wir lesen den Status aus und berechnen das Ergebnis, oder setzen direkt das
# Ergebnis
sub TASTER_Set($@) {
  my ($hash,@a) = @_;
  my $name = $hash->{NAME};
  Log3 $name,5,"TASTER ($name) >> Set";
 
  #FEHLERHAFTE PARAMETER ABFRAGEN
  if ( @a < 2 ) {
    Log3 $name,3,"\"set TASTER\" needs at least an argument";
    Log3 $name,5,"TASTER ($name) << Set";
    return "\"set TASTER\" needs at least an argument";
  }
  #my $name = shift @a;
  my $opt =  $a[1]; #shift @a;

  Log3 $name,4,"TASTER_Set Befehl=$opt";

  #mögliche Set Eigenschaften und erlaubte Werte zurückgeben wenn ein unbekannter
  #Befehl kommt, dann wird das auch automatisch in die Oberfläche übernommen
  if(!defined($sets{$opt})) {
    my $param = "";
    foreach my $val (keys %sets) {
        $param .= " $val:$sets{$val}";
    }
    Log3 $name,3,"Unknown argument $opt, choose one of $param";
    Log3 $name,5,"TASTER ($name) << Set";
    return "Unknown argument $opt, choose one of $param";
  }
  #Das eigentliche ausführen des Define-Befehls
  $hash->{STATE} = $opt;
  TASTER_Execute($hash);
  Log3 $name,5,"TASTER ($name) << Set";
}

#****************************************************************************
# Führt evtl. vorhandene define aus
sub TASTER_Execute($) {
  my ($hash) = @_;
  my $name = $hash->{NAME};
  Log3 $name,5,"TASTER ($name) >> Execute";

  #***** Auftrag lesen ******#
  my $state = $hash->{STATE};
  my $define = AttrVal($name,$state."-define",undef);

  if (!(defined $define)) {
    Log3 $name,4,"TASTER ($name) << Execute (kein Befehl definiert)";
    return;
  }
  Log3 $name,4,"$name Befehl:$define";

  #ein Perlausdruck wurde eingegeben
  if (substr($define, 0, 1) eq "{") {
    eval($define);
  #ein fhem-Befehl wurde ausgegeben
  } else {
    fhem($define);
  }
  Log3 $name,5,"TASTER ($name) << Execute";
  return;
}

################################################################### GET #####
#
sub TASTER_Get($@) {
  my ($hash, @a) = @_;
  my $name = $hash->{NAME};
  Log3 $name,5,"TASTER ($name) >> Get";

  if ( @a < 2 ) {
    Log3 $name,3, "\"get TASTER\" needs at least one argument";
    Log3 $name,5,"TASTER ($name) << Get";
    return "\"get TASTER\" needs at least one argument";
  }

  #existiert die abzufragende Eigenschaft in der Liste %gets (Am Anfang)
  #die Oberfläche liest hier auch die möglichen Parameter aus indem sie
  #die Funktion mit dem Parameter ? aufruft
  my $opt = $a[1];
  if(!$gets{$opt}) {
    my @cList = keys %gets;
    Log3 $name,3,"Unknown argument $opt, choose one of " . join(" ", @cList) if ($opt ne "?");
    Log3 $name,5,"TASTER ($name) << Get";
    return "Unknown argument $opt, choose one of " . join(" ", @cList);
  }
  my $val = "";
  if (@a > 2) {
    $val = $a[2];
  }
  Log3 $name,5,"TASTER_Get -> $opt:$val";

  Log3 $name,5,"TASTER ($name) << Get";
}

################################################################## ATTR #####
#
sub TASTER_Attr(@) {
  my ($cmd,$name,$aName,$aVal) = @_;
  Log3 $name,5,"TASTER ($name) >> Attr";  
  # $cmd can be "del" or "set"
  # aName and aVal are Attribute name and value
  if ($cmd eq "set") {
    if ($aName eq "Regex") {
      eval { qr/$aVal/ };
      if ($@) {
        Log3 $name, 3, "TASTER: Invalid regex in attr $name $aName $aVal: $@";
	return "Invalid Regex $aVal";
      }
    }
  }
  Log3 $name,5,"TASTER ($name) << Attr";
  return undef;
}

################################################################ NOTIFY #####
# Die X_Notify-Funktion wird aus der Funktion DoTrigger in fhem.pl 
# heraus aufgerufen wenn ein Modul Events erzeugt hat. Damit kann
# ein Modul auf Events anderer Module reagieren. 
sub TASTER_Notify($$) {
  my ($hash, $dev_hash) = @_;
  my $name = $hash->{NAME}; # own name / hash
  my $devName = $dev_hash->{NAME}; # Device that created the events
  Log3 $name,5,"TASTER ($name) >> Notify";

  my $device = $hash->{device} // "";

  return if ($device ne $devName);

  my $port = $hash->{port};
  $port //= "";

  my $value = "";
  my $max = int(@{$dev_hash->{CHANGED}}); # number of events / changes
  for (my $i = 0; $i < $max; $i++) {
    my $s = $dev_hash->{CHANGED}[$i];
      if ($port ne "") {
	next if ($s !~ /^$port/);
	my @param = split(':',$s);
    	next if ($port ne $param[0]);
	$value = trim($param[1]);
      } else {
	$value = $s;
      }

    #***** Änderung am Status meines Devices! *****#
    readingsSingleUpdate($hash,"value",$value,0);
    Log3 $name,4,"TASTER ($name) -> Notify -> longpress wird ausgewertet";
    Longpress($hash);
  }
  Log3 $name,5,"TASTER ($name) << Notify";
}
sub ltrim($) { my $s = shift; $s =~ s/^\s+//;       return $s };
sub rtrim($) { my $s = shift; $s =~ s/\s+$//;       return $s };
sub  trim($) { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };

# Berechnet den Status des Taster und setzt state
# Mögliche Werte:
#  * pushed
#  * double-click
#  * short-click
#  * long-click
#der State solch eines Buttons ist on,long oder short, je nachdem was
#gedrückt worden ist. Im Toggle steht entweder die Zeit zu dem der
#schalter gedrückt worden ist, oder die Anzahl Sekunden wie lange er
#gehalten worden ist nachdem er losgelassen worden ist.
sub Longpress($) {
  my ($hash) = @_;
  my $name = $hash->{NAME};
  Log3 $name,5,"TASTER ($name) >> Longpress";
  RemoveInternalTimer($hash);
  my $start = gettimeofday;
  my $VALUE = ReadingsVal($name,"value",undef);
  my $doubleClick = ReadingsVal($name,"DoubleClick","");

  #***** Der Taster wird gerade gedrückt *****#
  if ($VALUE eq "on") {
    readingsSingleUpdate($hash,'zeit-down',$start,0);
    if ($doubleClick eq "wait") {
      #ich warte auf den zweiten click und der Taster wurde tatsächlich nochmal gedrückt
      readingsSingleUpdate($hash,"DoubleClick","true",0);
    }
    setzeStatus($hash,"pushed");
    Log3 $name,5,"TASTER ($name) << Longpress state=gedrückt";
    return;
  }
  #***** Taster losgelassen *****#
  #* Wert zwischenspeichern
  my $lastClick = ReadingsVal($name,"zeit-up",undef);
  my $down = ReadingsVal($name,"zeit-down",undef);
  my $doubleClickTime = AttrVal($name,"double-click-time","0");
  my $longTime = AttrVal($name,"long-click-time","");

  readingsSingleUpdate($hash,"zeit-up",$start,0);

  #doppel-click
  if ($doubleClick eq "true") {
    readingsSingleUpdate($hash,"DoubleClick","off",0);
    setzeStatus($hash,"double-click");
    Log3 $name,5,"TASTER ($name) << Longpress state=double-click";
    return;

  #wenn Doppelklick aktiviert ist muss erst noch die Zeit abgewartet
  #werden bevor die Aktion ausgewertet wird
  } elsif ($doubleClick eq "off" && $doubleClickTime > 0) {  
    readingsSingleUpdate($hash,"DoubleClick","wait",0);
    InternalTimer(gettimeofday()+$doubleClickTime, "Longpress", $hash, 0);
    Log3 $name,5,"TASTER ($name) << Longpress state=wait for double click";
    return;
  }
  
  #ich will nicht auf doppel-click warten, oder die Zeit ist vorbei
  readingsSingleUpdate($hash,"DoubleClick","off",0) if ($doubleClick ne "off");

  #* Short-click auswerten
  if ((!defined $down) || $longTime == 0) {
    setzeStatus($hash,"short-click");
    Log3 $name,5,"TASTER ($name) << Longpress state=short-click";
    return;
  }

  #* Long-click auswerten
  my $sekunden = $start - $down;
  my $status = ($longTime < $sekunden)? "long-click" : "short-click";
  readingsSingleUpdate($hash,"click-time",$sekunden,0);
  
  Log3 $name,4,"sekunden=$sekunden, status=$status, longtime=$longTime";
  
  setzeStatus($hash,$status);
  Log3 $name,5,"TASTER ($name) << Longpress state=$status";
  return;
}

sub setzeStatus($$) {
  my ($hash,$state) = @_;
  my $name = $hash->{NAME};  
  readingsSingleUpdate($hash,"state",$state,1);
  TASTER_Execute($hash);
}

1;

=pod

=begin html
<a name="TASTER"></a>
        <h3>TASTER</h3>
        <p>Logical modul to extend a "on"/"off" reading for the possibility to evaluate the following states from an keystroke
<ul><li>short press</li>
<li>long press</li>
<li>press twice</li>
<li>key is being pressed</li></ul>.
The main focus in this module is to evaluate the various keystrokes. The visualisation of the button status is for debugging very helpfull.
In the definition you can define the name of your module and the name of a reading (port,adress)</p>
        <h4>Example</h4>
        <p>
            <code>define button1 TASTER myMcp20 PortB1</code>
            <br />
        </p>
        <br />
        <a name="TASTERdefine"></a>
        <h4>Define</h4>
        <code>define &lt;name&gt; TASTER &lt;device&gt; &lt;port&gt; </code>
        <p><code>[&lt;device&gt;]</code><br />The device whose reading should be evaluated</p>
        <p><code>&lt;port&gt;</code><br />The evaluated port / reading of the device</p>
        <br />
        <br />
        <a name="TASTERset"></a>
        <h4>Set</h4>
	<a name="TASTERsetter">
                <ul>
                  <li><code>set &lt;name&gt; pushed</code></a><br />trigger event 'pushed' of the button, trigger associated commands</li>
		  <li><code>set &lt;name&gt; short-click</code></a><br /> trigger event 'short-click' of the button, trigger associated commands</li>
		  <li><code>set &lt;name&gt; double-click</code></a><br /> trigger event 'double-click' of the button, trigger associated commands</li>
		  <li><code>set &lt;name&gt; long-click</code></a><br /> trigger event 'long-click' of the button, trigger associated commands</li>
                </ul>
        <br />
        <h4>Attributes</h4>
        <p>Module-specific attributes:
                   <a href="#long-click-time">long-click-time</a>,
                   <a href="#long-click-define">long-click-define</a>,
                   <a href="#short-click-define">short-click-define</a>, 
                   <a href="#double-click-time">double-click-time</a>,
                   <a href="#double-click-define">double-click-define</a>, 
                   <a href="#pushed-define">pushed-define</a>
            </p>
	<ul>
	<li><a name="long-click-time"><b>long-click-time</b></a>
        <p>time in seconds that a key must be pressed to be evaluated as "long-click"</p>
	</li><li><a name="long-click-define"><b>long-click-define</b>
	<p>optional command to be executed on long clicks<BR/>
           here everything is permitted which can also be entered on the command line of fhem</p>
	</li><li><a name="short-click-define"><b>short-click-define</b></a>
	<p>optional command to be executed on short clicks<BR/>
           here everything is permitted which can also be entered on the command line of fhem</p>
	</li><li><a name="double-click-time"><b>double-click-time</b></a>
	<p>The time in seconds to wait for a second keypress. if the button is pressed twice within this time, the double-click event is triggerd </p>
	</li><li><a name="double-click-define"><b>double-click-define</b></a>
	<p>optional command to be executed on double clicks<BR/>
           here everything is permitted which can also be entered on the command line of fhem</p>
	</li><li><a name="pushed-click-define"><b>pushed-click-define</b></a>
	<p>optional command to be executed when the button is pushed<BR/>
           here everything is permitted which can also be entered on the command line of fhem</p>
        </li></ul>
=end html

=begin html_DE

<a name="TASTER"></a>
        <h3>TASTER</h3>
        <p>Logisches Modul das ein "on"/"off" Reading um die Möglichkeit erweitert den Tastendruck
nach folgenden Stati auszuwerten
<ul><li>kurzer Tastendruck</li>
<li>langer Tastendruck</li>
<li>doppelter Tastendruck</li>
<li>Taste wird gerade gedrückt</li></ul>.
Das Hauptaugenmerk liegt bei diesem Modul darauf die verschiedenen Tastendrücke auszuwerten, die Darstellung
der Tasten auf der Oberfläche und die Set-Methoden dienen mehr dem Debugging.
In der Definition wird das Hardwaremodul und das Reading (der Port/Adresse) des "on"/"off" Tasters angegeben</p>
        <h4>Beispiel</h4>
        <p>
            <code>define Taster1 TASTER myMcp20 PortB1</code>
            <br />
        </p>
        <br />
        <a name="TASTERdefine"></a>
        <h4>Define</h4>
        <code>define &lt;name&gt; TASTER &lt;device&gt; &lt;port&gt; </code>
        <p><code>[&lt;device&gt;]</code><br />Das Device dessen Reading ausgewertet werden soll </p>
        <p><code>&lt;port&gt;</code><br />Der Auszuwertende Port/Reading des Device</p>
        <br />
        <br />
        <a name="TASTERset"></a>
        <h4>Set</h4>
	<a name="TASTERsetter">
                <ul>
                  <li><code>set &lt;name&gt; pushed</code></a><br />Status des devices auf 'pushed' setzen, verknüpft aktionen auslösen</li>
		  <li><code>set &lt;name&gt; short-click</code></a><br /> Status des devices auf 'short-click' setzen, verknüpft aktionen auslösen</li>
		  <li><code>set &lt;name&gt; double-click</code></a><br /> Status des devices auf 'double-click' setzen, verknüpft aktionen auslösen</li>
		  <li><code>set &lt;name&gt; long-click</code></a><br /> Status des devices auf 'long-click' setzen, verknüpft aktionen auslösen</li>
                </ul>
        <br />
        <h4>Attribute</h4>
        <p>Modulspezifische attribute:
                   <a href="#long-click-time">long-click-time</a>,
                   <a href="#long-click-define">long-click-define</a>,
                   <a href="#short-click-define">short-click-define</a>, 
                   <a href="#double-click-time">double-click-time</a>,
                   <a href="#double-click-define">double-click-define</a>, 
                   <a href="#pushed-define">pushed-define</a>
            </p>
	<ul>
	<li><a name="long-click-time"><b>long-click-time</b></a>
        <p>Zeit in Sekunden die eine Taste gedrückt werden muss um als "Langer Tastendruck" ausgewertet zu werden</p>
	</li><li><a name="long-click-define"><b>long-click-define</b>
	<p>Optionaler Befehl der bei einem langen Tastendruck ausgeführt werden soll.<BR/>
           Hier ist alles erlaubt was auch in der Befehlszeile von fhem eingegeben werden kann.</p>
	</li><li><a name="short-click-define"><b>short-click-define</b></a>
	<p>Optionaler Befehl der bei einem kurzen Tastendruck ausgeführt werden soll.<BR/>
           Hier ist alles erlaubt was auch in der Befehlszeile von fhem eingegeben werden kann.</p>
	</li><li><a name="double-click-time"><b>double-click-time</b></a>
	<p>Zeit in Sekunden die nach einem Tastendruck gewartet werden soll. Erfolgt innerhalb dieser
           Zeit ein weiterer Tastendruck, so wird ein "Doppelter Tastendruck" ausgewertet.</p>
	</li><li><a name="double-click-define"><b>double-click-define</b></a>
	<p>Optionaler Befehl der bei einem kurzen Tastendruck ausgeführt werden soll.<BR/>
           Hier ist alles erlaubt was auch in der Befehlszeile von fhem eingegeben werden kann.</p>
	</li><li><a name="pushed-click-define"><b>pushed-click-define</b></a>
	<p>Optionaler Befehl der bei einem kurzen Tastendruck ausgeführt werden soll.<BR/>
           Hier ist alles erlaubt was auch in der Befehlszeile von fhem eingegeben werden kann.</p>
        </li></ul>
=end html_DE

=cut

