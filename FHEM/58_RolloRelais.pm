############################################################
# $Id: 58_RolloRelais.pm 1002 2017-02-08 17:58:00Z ThomasRamm $ #
#
############################################################
package main;

use strict;
use warnings;
use Time::HiRes;
use Data::Dumper; #Zum Entwickeln und Debuggen, gibt ganze Arrays im Log aus!

#***** Parameter
my %sets = (
  "direction" => "toggle,up,down",
  "power" => "toggle,on,off",
  "reset" => "on,off");

############################################################ INITIALIZE #####
# Die Funktion wird von Fhem.pl nach dem Laden des Moduls aufgerufen und bekommt einen Hash für das Modul als zentrale Datenstruktur übergeben.
sub RolloRelais_Initialize($) {
  my ($hash) = @_;
  my $name = $hash->{NAME};
  Log3 "global",4,"RolloRelais (?) >> Initialize";

  $hash->{DefFn}    = "RolloRelais_Define";
  $hash->{SetFn}    = "RolloRelais_Set";
  $hash->{AttrFn}   = "RolloRelais_Attr";

  $hash->{AttrList} = " onTime RelaisDirection RelaisPower";

  Log3 "global", 5, "RolloRelais (?) << Initialize";
}

################################################################ DEFINE #####
# wenn der Define-Befehl für ein Geräte ausgeführt wird und das Modul bereits geladen und mit der Initialize-Funktion initialisiert ist
sub RolloRelais_Define($$) {
  my ($hash,$def) = @_;
  my $name = $hash->{NAME};
  Log3 $name, 4, "RolloRelais ($name) >> Define";
  
  $hash->{STATE} = "off-up";

  readingsSingleUpdate($hash, 'direction','up',1);
  readingsSingleUpdate($hash, 'power','off',1);

  $attr{$name}{"onTime"} = 0.5;
  $attr{$name}{"RelaisDirection"} = "myRelaisDirection";
  $attr{$name}{"RelaisPower"} = "myRelaisPower";
  #ToDo: Oberfläche?
  #  $attr{$name}{"webCmd"} = "short-click:long-click:double-click";
  $attr{$name}{"devStateIcon"} = 'off-down:control_arrow_down on-down:control_arrow_down@red off-up:control_arrow_up on-up:control_arrow_up@red';
  
  Log3 $name,5,"RolloRelais ($name) << Define";
}

#################################################################### SET #####
sub RolloRelais_Set($@) {
  my ($hash,@a) = @_;
  my $name = $hash->{NAME};
  Log3 $name, 4, "RolloRelais ($name) >> Set";
 
#FEHLERHAFTE PARAMETER ABFRAGEN
  if ( @a < 2 ) {
    Log3 $name,3,"\"set RolloRelais\" needs at least an argument << Set";
    return "\"set RolloRelais\" needs at least an argument";
  }
  #my $name = shift @a;
  my $opt =  $a[1];
  my $value = "";
  $value = $a[2] if defined $a[2];

  #mögliche Set Eigenschaften und erlaubte Werte zurückgeben wenn ein unbekannter
  #Befehl kommt, dann wird das auch automatisch in die Oberfläche übernommen
  if(!defined($sets{$opt})) {
    my $param = "";
    foreach my $val (keys %sets) {
        $param .= " $val:$sets{$val}";
    }
    if ($opt ne "?") {
      Log3 $name, 3, "Unknown argument $opt, choose one of $param";
    }
    Log3 $name, 5, "ROLLO_Automatik ($name) << Set";
    return "Unknown argument $opt, choose one of $param";
  }

  #***** DIRECTION *****#
  if ($opt eq "direction") { 
    Log3 $name, 0, "BEFEHL IST: direction $value";
    
    my $direction = ReadingsVal($name,"direction","up");
    if ($value eq $direction) {
      Log3 $name, 5, "RolloRelais ($name) direction $value already set, nothing to do.";
      Log3 $name, 5, "RolloRelais ($name) << Set";
      return undef;

    } elsif ($value eq "up" || $value eq "down" || $value eq "toggle") {
      if ($value eq "toggle") {
        $value = ( $direction eq "up" ? "down" : 'up' );
      } 
      Log3 $name, 5, "RolloRelais ($name) IST: $direction SOLL: $value";
      my $time = AttrVal($name,'onTime',"0.5");
      my $hardware = AttrVal($name,'RelaisDirection',"");
      my $befehl = "Set $hardware on; sleep $time; Set $hardware off";
      Log3 $name, 5, "EXEC: $befehl ";
      
      my $power = ReadingsVal($name,"power","off");

      $hash->{STATE} = "$power-$value";
      readingsSingleUpdate($hash, 'direction',$value, 1);
      Log3 $name, 5, "STATE: $power-$value ";
      fhem($befehl);
    }

  #***** ON | OFF *****#
  } elsif ($opt eq "power") {
    Log3 $name, 5, "BEFEHL IST: power $value";

    my $power = ReadingsVal($name,"power","off");
    if ($value eq $power) {
      Log3 $name, 5, "RolloRelais ($name) power $value already set, nothing to do.";
      Log3 $name, 5, "RolloRelais ($name) << Set";
      return;

    } elsif ($value eq "on" || $value eq "off" || $value eq "toggle") {
      if ($value eq "toggle") {
        $value = ( $power eq "off" ? "on" : 'off' );
      } 
      Log3 $name, 5, "RolloRelais ($name) IST: $power SOLL: $value";
      my $hardware = AttrVal($name,'RelaisPower',"");
      my $time = AttrVal($name,'onTime',"0.5");
      my $befehl = "Set $hardware on; sleep $time; Set $hardware off";
      Log3 $name, 5, "EXEC: $befehl ";

      my $direction = ReadingsVal($name,"direction","up");
      $hash->{STATE} = "$value-$direction";
      readingsSingleUpdate($hash, 'power',$value,1);
      Log3 $name, 5, "STATE: $value-$direction";
      fhem($befehl);
    }

  #***** RESET *****#
  } elsif ($opt eq "reset") {
    Log3 $name, 5, "BEFEHL IST: RESET, NOCH NICHT PROGRAMMIERT";
  }

  if(1 == 2) {
    #readingsSingleUpdate($hash, 'direction','up',1);
    #readingsSingleUpdate($hash, 'power','off',1)
    my $state = $hash->{STATE};
    my $modul = $hash->{device};
    my $port = $hash->{port} // " ";
    my $time = AttrVal($name,'onTime',"0.5") if(defined($attr{$name}{onTime}));
    my $befehl = "Set " . $modul . " " . $port . " ";
    #Log3 $name,5,"EXEC: " . $befehl . "on;sleep " . $time . ";". $befehl . "off";
    #fhem($befehl . "on;sleep " . $time . ";". $befehl . "off");
    #readingsSingleUpdate($hash,"state",$opt,1);
  }
  
  Log3 $name,5,"RolloRelais ($name) << Set";
}

################################################################## ATTR #####
#
sub RolloRelais_Attr(@) {
  my ($cmd,$name,$aName,$aVal) = @_;
  Log3 $name,5,"RolloRelais ($name) >> Attr";  
  # $cmd can be "del" or "set"
  # aName and aVal are Attribute name and value
  if ($cmd eq "set") {
    #Aktivitäten die beim Ändern von Parametern durchgeführt werden sollen
  }
  Log3 $name,5,"RolloRelais ($name) << Attr";
  return undef;
}

1;

=pod

=begin html

<a name="RolloRelais"></a>
<h3>RolloRelais</h3>
<p>Logical modul to use a 'surge switch' for your blender. Send a short on/off to your device, but still remind device state.
  <ul>
    <li>power: on, off, toggle</li>
    <li>direction: up, down, toggle</li>
  <ul>
</p>
<h4>Example</h4>
<p>
  <code>define blender1 RolloRelais</code>
  <br />
</p>
<br />
<a name="RolloRelaisdefine"></a>
<h4>Define</h4>
<code>define &lt;name&gt; RolloRelais &lt;</code>
<br />
<a name="RolloRelaisset"></a>
<h4>Set</h4>
<a name="RolloRelaissetter">
<ul>
  <li><code>set &lt;name&gt; direction on/off/toggle</code></a><br />send short pulse to "RelaisDirection" only if the modul needs to change the direction</li>
  <li><code>set &lt;name&gt; power on/off/toggle</code></a><br /> send short pulse to "RelaisPower" - only if the modul needs to change power mode</li>
</ul>
<br />
<h4>Attributes</h4>
<ul>
  <li><a name="RelaisDirection"><code>attr &lt;name&gt; RelaisDirection NameOfHardwareModul</code></a>
    <br />must have attribute. The modul will send short pulse to this module to change the actual state.</li>
  <li><a name="RelaisPower"><code>attr &lt;name&gt; RelaisPower NameOfHardwareModul</code></a>
    <br />must have attribute. The modul will send short pulse to this module to change the actual state.</li>
  <li><a name="onTime"><code>attr &lt;name&gt; onTime	&lt;time&gt;</code></a>
    <br />time in seconds for the length of the pulse eg. 0.5 for a half second.<BR/>
    Format is in 24h, examples: 6:14, 19:00. Variable Names with a comparable time string as state also allowed</li>
</ul>
=end html

=begin html_DE

<a name="RolloRelais"></a>
        <h3>RolloRelais</h3>
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
            <code>define Taster1 RolloRelais myMcp20 PortB1</code>
            <br />
        </p>
        <br />
        <a name="RolloRelaisdefine"></a>
        <h4>Define</h4>
        <code>define &lt;name&gt; RolloRelais &lt;device&gt; &lt;port&gt; </code>
        <p><code>[&lt;device&gt;]</code><br />Das Device dessen Reading ausgewertet werden soll </p>
        <p><code>&lt;port&gt;</code><br />Der Auszuwertende Port/Reading des Device</p>
        <br />
        <br />
        <a name="RolloRelaisset"></a>
        <h4>Set</h4>
	<a name="RolloRelaissetter">
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
