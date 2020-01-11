if(typeof widget_image == 'undefined') {
    dynamicload('js/widget_image.js');
}

var widget_itunes_artwork = $.extend({}, widget_image, {
    widgetname: 'itunes_artwork',
    init_attr: function(elem) {
        elem.data('get',        elem.data('get')        || 'STATE');
        // data-get is an array
        if(! $.isArray(elem.data('get'))) {
            // ..like it or lump it
            elem.data('get', new Array(elem.data('get')));
        }
        // create a data-var for each field of the get-array and subscribe to it's update events
        for(var g=0; g<elem.data('get').length; g++) {
            var get = elem.data('get')[g];
            elem.data(get, get);
            readings[get] = true;
            DEBUG && console.log(this.widgetname, 'init_attr', get);
        }

        // reading and reading-value that say "Player has stopped"
        elem.data('get-playstatus',             elem.data('get-playstatus')         || 'STATE');
        elem.data('get-playstatus-stop',        elem.data('get-playstatus-stopp')   || 'stop');
        readings[elem.data('get-playstatus')] = true;

        // dir for standard images
        var dir = $('script[src$="fhem-tablet-ui.js"]').attr('src').replace(/(.*\/).*/, '$1');

        elem.data('opacity',        elem.data('opacity')        || 1);
        elem.data('size',           elem.data('size')           || 150);
        elem.data('height',         elem.data('size'));
        elem.data('width',          elem.data('size'));
        elem.data('media',          elem.data('media')          || 'music');
        elem.data('entity',         elem.data('entity')         || 'song');
        elem.data('timeout',        elem.data('timeout')        || 3000);
        elem.data('loadingimg',     elem.data('loadingimg')     || dir + '../images/loading.svg');
        elem.data('stoppedimg',     elem.data('stoppedimg')     || dir + '../images/stop.svg');
        elem.data('notfoundimg',    elem.data('notfoundimg')    || dir + '../images/unknown.svg');
        elem.data('stripbrackets',  elem.data('stripbrackets')  || false);
        elem.data('stripregex',     elem.data('stripregex')     || '');

        var img = elem.find('img');
        img.attr('src', elem.data('loadingimg'));

        if(elem.data('notfoundimg').match(/^[^:]+:[^:]+$/)) {
            initReadingsArray(elem.data('notfoundimg'));
            requestFhem(elem.data('notfoundimg'));
        }
    },
    update_value_cb : function(value) {
        if(value && value.match(/^\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d$/)) {
            return '';
        }
        return value;
    },
    itunes: function (elem, val) {
        DEBUG && console.log(this.widgetname, 'itunes.start', val);
        $.ajax({
            url: "https://itunes.apple.com/search",
            dataType: "jsonp",
            data: {
                term:       val.join(' '),
                media:      elem.data('media'),
                entity:     elem.data('entity'),
            },
            base:           this,
            elem:           elem,
            val:            val,
            size:           elem.data('size'),
            img:            elem.find('img'),
            timeout:        elem.data('timeout'),
            beforeSend: function(jqXHR, settings) {
                jqXHR.url = settings.url;
            },
            error: function (jqXHR, textStatus, message) {
                DEBUG && console.log(this.base.widgetname, 'itunes.error', textStatus, message, jqXHR.url);
            },
            success: function (data, textStatus, jqXHR) {
                if($.isArray(data.results) && data.results[0] && data.results[0].artworkUrl100) {
                    var artwork;
                    if(this.size <=60) {
                        artwork = data.results[0].artworkUrl60;
                    } else {
                        artwork = data.results[0].artworkUrl100;
                    }
                    if(artwork) {
                        var pxratiosize;
                        if(window.devicePixelRatio) {
                            pxratiosize = Math.round(window.devicePixelRatio*this.size);
                        } else {
                            pxratiosize = this.size;
                        }
                        artwork = artwork.replace(/100x100/, pxratiosize+'x'+pxratiosize);

                        this.img.attr('src', artwork);
                        DEBUG && console.log(this.base.widgetname, 'itunes.artwork', artwork);
                    } else {
                        DEBUG && console.log(this.base.widgetname, 'itunes.artwork', '-');
                    }
                } else {
                    // no results found for our search terms
                    DEBUG && console.log(this.base.widgetname, 'itunes.results', '-');
                    
                    var img;
                    if(this.elem.data('notfoundimg') && this.elem.data('notfoundimg').match(/^[^:]+:[^:]+$/)) {
                        var nfimg = this.elem.data('notfoundimg').split(':');
                        var device = nfimg[0];
                        var reading = nfimg[1];
                        img = getDeviceValueByName(device, reading);
                        if(!img) {
                            // poor hack to overcome timing issues with asynchronous requestFhem
                            setTimeout({elem:this}, function(){
                                img = getDeviceValueByName(device, reading);
                                elem.img.attr('src', img);
                                console.log(this.base.widgetname, 'notfoundimage delayed', device, reading, img);
                            },500);
                        }
                        console.log(this.base.widgetname, 'notfoundimage', device, reading, img);
                    } else {
                        img = this.elem.data('notfoundimg');
                    }
                    
                    this.img.attr('src', img);
                    // ..shorten the terms by 1 and try again until only one term is left
                    if(val.length>1) {
                        this.val.pop();
                        this.base.itunes(elem, this.val);
                    }
                }
            },
        });
    },
    update: function (dev,par) {
        var base = this;
        var deviceElements = this.elements.filter('div[data-device="'+dev+'"]');
        deviceElements.each(function(index) {
            var img = $(this).find('img');
            // is the music player stopped?
            var playstatus = getDeviceValue($(this), 'get-playstatus');
            if(playstatus == $(this).data('get-playstatus-stop')) {
                img.attr('src', $(this).data('stoppedimg'));
                img.css('visibility','visible');
                DEBUG && console.log(base.widgetname, 'playstatus', $(this).data('get-playstatus'), playstatus);
            } else {
                DEBUG && console.log(base.widgetname, 'playstatus', $(this).data('get-playstatus'), playstatus);
                var parok=false;
                var get = $(this).data('get');
                // check if par is of interest to this device
                for(var g=0; g<get.length; g++) {
                    if(par == get[g]) {
                        parok = true;
                        break;
                    }
                }

                // enforce update if playstatus has changed from stop to anything else
                if(playstatus && $(this).data('_playstatus') && $(this).data('_playstatus') == $(this).data('get-playstatus-stop') && $(this).data('_playstatus') != playstatus) {
                    parok = true;
                    $(this).data('force', true);
                    DEBUG && console.log(base.widgetname, 'enforce update', $(this).data('_playstatus'), playstatus);
                } else {
                    $(this).data('force', false);
                }

                if(parok && ! $(this).data('updateinprogress')) {
                    $(this).data('updateinprogress', true);
                    // there's a timing issue with readings updates in MPD
                    var timedUpdate = setTimeout($.proxy(function() {
                        var get = $(this).data('get');
                        var done=0;
                        var changed=false;
                        var val = new Array();
                        for(var g=0; g<get.length; g++) {
                            // get all readings
                            val[g] = getDeviceValue($(this), get[g]);
                            // remember old readings and see if they've changed
                            if($(this).data('ov'+g) != val[g]) {
                                $(this).data('ov'+g, val[g]);
                                changed=true;
                            }

                            // count read values; update is done only if all values are available
                            if(val[g]) {
                                done++;
                            }
                        }

                        // fetch coverimage after all readings are read
                        if((changed || $(this).data('force')) && val.length == done) {
                            $(this).find('img').attr('src', $(this).data('loadingimg'));
                            $(this).find('img').css('visibility', 'visible');

			                for(var g=0; g<get.length; g++) {
			                    // delete timestamp values (workarroud for list-bug in requestFhem)
			                    val[g] = base.update_value_cb(val[g]);
			                    // strip brackets
			                    if($(this).data('stripbrackets')) {
			                        var pre = val[g];
			                        val[g] = val[g].replace(/\(.*?\)/g, '');
			                        val[g] = val[g].replace(/\[.*?\]/g, '');
			                        val[g] = val[g].replace(/\{.*?\}/g, '');
			                        val[g] = val[g].replace(/\<.*?\>/g, '');
			                        DEBUG && console.log(base.widgetname, 'stripbrackets', pre, val[g]);
			                    }
			                    // strip regex
			                    if($(this).data('stripregex')) {
			                        var pre = val[g];
			                        val[g] = val[g].replace(new RegExp($(this).data('stripregex'), 'g'), '');
			                        DEBUG && console.log(base.widgetname, 'stripregex', $(this).data('stripregex'), pre, val[g]);
			                    }
			                }
                            DEBUG && console.log(base.widgetname, 'update', get, val);
			                $(this).find('img').attr('src', $(this).data('loadingimg'));
			                base.itunes($(this), val);
                        }

                        $(this).data('updateinprogress', false);
                    }, this), 300);
                } else {
                    DEBUG && console.log(base.widgetname, 'ignoring', par, parok, $(this).data('updateinprogress'));
                }
            }
            $(this).data('_playstatus', playstatus);
	    });
    }
});

// https://www.apple.com/itunes/affiliates/resources/documentation/itunes-store-web-service-search-api.html