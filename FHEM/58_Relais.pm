############################################################
# $Id: 58_Relais.pm 1002 2017-02-08 17:58:00Z ThomasRamm $ #
#
############################################################
package main;

use strict;
use warnings;
use Time::HiRes;

#***** Parameter
my %sets = (
  "on" => "noArg",
  "off" => "noArg",
  "toggle" => "noArg",
  "reset" => "on,off");

############################################################ INITIALIZE #####
# Die Funktion wird von Fhem.pl nach dem Laden des Moduls aufgerufen und bekommt einen Hash für das Modul als zentrale Datenstruktur übergeben.
sub Relais_Initialize($) {
  my ($hash) = @_;
  my $name = $hash->{NAME};
  Log3 "global",4,"Relais (?) >> Initialize";

  $hash->{DefFn}    = "Relais_Define";
  $hash->{SetFn}    = "Relais_Set";
  $hash->{AttrFn}   = "Relais_Attr";

  $hash->{AttrList} = " onTime";

  Log3 "global",5,"Relais (?) << Initialize";
}

################################################################ DEFINE #####
# wenn der Define-Befehl für ein Geräte ausgeführt wird und das Modul bereits geladen und mit der Initialize-Funktion initialisiert ist
sub Relais_Define($$) {
  my ($hash,$def) = @_;
  my $name = $hash->{NAME};
  Log3 $name,5,"Relais ($name) >> Define";
  
  my @a = split( "[ \t][ \t]*", $def );
  my $anzahl = scalar @a;

  $hash->{device} = ($anzahl >= 2) ? $a[2] : "";
  $hash->{port} = ($anzahl >= 3) ?  $a[3] : "";
  $hash->{STATE} = "off";

  $attr{$name}{"onTime"} = 0.5;
  #ToDo: Oberfläche?
  #  $attr{$name}{"webCmd"} = "short-click:long-click:double-click";
  # $attr{$name}{"devStateIcon"} = 'short-click:control_on_off@green long-click:control_on_off@blue pushed:control_on_off@red double-click:control_on_off@orange';
  
  Log3 $name,5,"Relais ($name) << Define";
}

#################################################################### SET #####
sub Relais_Set($@) {
  my ($hash,@a) = @_;
  my $name = $hash->{NAME};
  Log3 $name,5,"Relais ($name) >> Set";
 
  #FEHLERHAFTE PARAMETER ABFRAGEN
  if ( @a < 2 ) {
    Log3 $name,3,"\"set Relais\" needs at least an argument";
    Log3 $name,5,"Relais ($name) << Set";
    return "\"set Relais\" needs at least an argument";
  }
  my $opt =  $a[1];

  if ($opt eq "reset") {
    if (@a >= 3) {
      readingsSingleUpdate($hash,"state",$a[2],1);
      Log3 $name,5,"Relais ($name) << Set";
      return;
    }
  }

  if(!defined($sets{$opt})) {
    my $param = "";
    foreach my $val (keys %sets) {
        $param .= " $val:$sets{$val}";
    }
    Log3 $name,3,"Unknown argument $opt, choose one of $param";
    Log3 $name,5,"Relais ($name) << Set";
    return "Unknown argument $opt, choose one of $param";
  }
  
  my $state = $hash->{STATE};

  Log3 $name,4,"$name IST $state SOLL $opt";

  if($opt ne $state) {

   if($opt eq "toggle") {
     $opt = ($state eq "on" ? "off" : "on");
   }
    
    my $modul = $hash->{device};
    my $port = $hash->{port} // " ";
    my $time = AttrVal($name,'onTime',"0.5") if(defined($attr{$name}{onTime}));
    my $befehl = "Set " . $modul . " " . $port . " ";

    Log3 $name,5,"EXEC: " . $befehl . "on;sleep " . $time . ";". $befehl . "off";

    fhem($befehl . "on;sleep " . $time . ";". $befehl . "off");

    readingsSingleUpdate($hash,"state",$opt,1);
  }
  
  Log3 $name,5,"Relais ($name) << Set";
}

################################################################## ATTR #####
#
sub Relais_Attr(@) {
  my ($cmd,$name,$aName,$aVal) = @_;
  Log3 $name,5,"Relais ($name) >> Attr";  
  # $cmd can be "del" or "set"
  # aName and aVal are Attribute name and value
  if ($cmd eq "set") {
    if ($aName eq "Regex") {
      eval { qr/$aVal/ };
      if ($@) {
        Log3 $name, 3, "Relais: Invalid regex in attr $name $aName $aVal: $@";
	      return "Invalid Regex $aVal";
      }
    }
  }
  Log3 $name,5,"Relais ($name) << Attr";
  return undef;
}

1;

=pod

=begin html

<a name="Relais"></a>
<h3>Relais</h3>
<p>Logical modul to use a 'surge switch' for your lights. Send a short on/off to your device, but still remind device state.
  <ul>
    <li>on, off</li>
    <li>reset: on, off</li>
  <ul>
</p>
<h4>Example</h4>
<p>
  <code>define button1 Relais myMcp20 PortB1</code>
  <br />
</p>
<br />
<a name="Relaisdefine"></a>
<h4>Define</h4>
<code>define &lt;name&gt; Relais &lt;device&gt; &lt;port&gt; </code>
<p><code>[&lt;device&gt;]</code><br />The device whose reading should be evaluated</p>
<p><code>&lt;port&gt;</code><br />The evaluated port / reading of the device</p>
<br />
<br />
<a name="Relaisset"></a>
<h4>Set</h4>
<a name="Relaissetter">
<ul>
  <li><code>set &lt;name&gt; on</code></a><br />set Hardware device-port ON/OFF if device not in ON state, set device status to ON</li>
  <li><code>set &lt;name&gt; off</code></a><br /> set Hardware device-port ON/OFF if device not in OFF state, set device status to OFF</li>
  <li><code>set &lt;name&gt; reset on</code></a><br /> set state of device to ON, without switch a hardware device</li>
  <li><code>set &lt;name&gt; reset off</code></a><br /> set status of device to OFF, without switch a hardware device</li>
</ul>
<br />
<h4>Attributes</h4>
<p>Module-specific attributes: <a href="#onTime">onTime</a></p>
<ul>
	<li><a name="onTime"><b>onTime</b></a>
        <p>time in seconds that a switch must be wait on ON until it will be set to OFF</p>
  </li>
</ul>
=end html

=begin html_DE

<a name="Relais"></a>
<h3>Relais</h3>
<p>Logisches Modul um einen 'Stromstossschalter' zu steuern. Sende ein kurzes ON/OFF an dein Gerät, und merke dir den aktuellen Gerätestatus.
  <ul>
    <li>on, off</li>
    <li>reset: on, off</li>
  <ul>
</p>
<h4>Beispiel</h4>
<p>
  <code>define button1 Relais myMcp20 PortB1</code>
  <br />
</p>
<br />
<a name="Relaisdefine"></a>
<h4>Define</h4>
<code>define &lt;name&gt; Relais &lt;device&gt; &lt;port&gt; </code>
<p><code>[&lt;device&gt;]</code><br />Das Hardwaregerät dessen Reading verknüpft werden soll</p>
<p><code>&lt;port&gt;</code> (optional)<br />Der Verknüpfte Port / Reading des Hardwaregeräts</p>
<br />
<br />
<a name="Relaisset"></a>
<h4>Set</h4>
<a name="Relaissetter">
<ul>
  <li><code>set &lt;name&gt; on</code></a><br />Setze dein Hardwaregerät kurz auf ON und dann wieder auf OFF, wenn der Status nicht bereits ON ist, speichere in der Oberfläche den Status ON</li>
  <li><code>set &lt;name&gt; off</code></a><br />Setze dein Hardwaregerät kurz auf ON und dann wieder auf OFF, wenn der Status nicht bereits OFF ist<, speichere in der Oberfläche den Status OFF/li>
  <li><code>set &lt;name&gt; reset on</code></a><br />Setze das Modul in FHEM auf ON, ohne dein Hardwaregerät zu schalten.</li>
  <li><code>set &lt;name&gt; reset off</code></a><br />Setze das Modul in FHEM auf OFF, ohne dein Hardwaregerät zu schalten.</li>
</ul>
<br />
<h4>Attributes</h4>
<p>Module-spezifische Attribute: <a href="#onTime">onTime</a></p>
<ul>
	<li><a name="onTime"><b>onTime</b></a>
        <p>Zeit in Sekunden die das Hardwaregerät beim Schalten ON sein soll, bevor es wieder OFF geschaltet wird. (Default = 0.5)</p>
  </li>
</ul>
=end html_DE

=cut
