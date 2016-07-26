Ensembl.Panel.ZMenu = Ensembl.Panel.ZMenu.extend({
  populateAjax: function (url, expand) {
    url = url || this.href
    this.crossOrigin = url && url.match(/^http/) ? url.split('/').slice(0,3).join('/') : false;

    if (url && window.location.pathname.match(/\/Gene\/Variation_Gene/) && !url.match(/\/ZMenu\//)) {
      url = url.replace(/\/(\w+\/\w+)\?/, '/ZMenu/$1?');
    }

    this.base(url, expand);
  },

  buildMenuAjax: function () {
    var domain = this.crossOrigin;
     
    this.base.apply(this, arguments);
    
    if (domain) {
      this.el.find('a:not([href^="http"]):not([href^="ftp"])').attr('href', function (i, href) { return domain +href; });
    }
  },

//////////////////////////
  populateNoAjax: function () {
    if (this.href && this.href.match(/http/)) {
      var domain = this.href.split('/')[2].split('.');
      var title;
      
      if (domain[0].match(/www/)) {
        // URL starts with www it is ensembl, gramene or ensemblgenomes
        title = domain[1].substr(0, 1).toUpperCase() + domain[1].substr(1, domain[1].length);
      } else if (this.href.match(/\.ensembl\./)) {
        var site = domain.length > 3 ? domain[1] : domain[0];
        title = 'Ensembl' + site.substr(0, 1).toUpperCase() + site.substr(1, site.length);
      }
       
      var caption = 'Go to ' + title;
      var link = this.href.replace(/ZMenu\//, '');
      
      if (link.match(/ComparaTree/)) {
        link = link.replace(/ComparaTree/, 'Compara_Tree');
      }

      this.buildMenu(
        [ '<a href="' + link + '">View in ' + title + '</a>' ],
        'External data'
      );
    } else {
      this.base.apply(this, arguments);
    }
  },

  populateRegion: function () {
    var variationGene = !!window.location.pathname.match(/\/Variation_(Gene|Transcript)\/Image/);
    
    if (!variationGene || !this.coords.r) {
      return this._populateRegion();
    }

    var min   = this.start;
    var max   = this.end;
    var scale = (max - min + 1) / (this.areaCoords.r - this.areaCoords.l);
    var start = Math.floor(min + (this.coords.s - this.areaCoords.l) * scale);
    var end   = Math.floor(min + (this.coords.s + this.coords.r - this.areaCoords.l) * scale);
    
    if (start > end) {
      var tmp = start;
      start = end;
      end   = tmp;
    }

    start = Math.max(start, min);
    end   = Math.min(end,   max);

    this.buildMenu(
      [ '<a class="location_change" href="' + this.baseURL.replace(/%s/, this.chr + ':' + start + '-' + end) + '">Jump to region (' + (end - start) + ' bp)</a>' ],
      'Region: ' + this.chr + ':' + start + '-' + end
    );
  },

  // _populateRegion is a copy of Ensembl's populateRegion func, with some EG modifications
  _populateRegion: function () {
    console.log("_populate region");
    var panel        = this;
    var min          = this.start;
    var max          = this.end;
    var locationView = !!window.location.pathname.match('/Location/') && !window.location.pathname.match(/\/(Chromosome|Synteny)/);
    var scale        = (max - min + 1) / (this.areaCoords.r - this.areaCoords.l);
    var url          = this.baseURL;
    var menu, caption, start, end, tmp, cls;
    
    // Gene, transcript views
    function notLocation() {
      var view = end - start + 1 > Ensembl.maxRegionLength ? 'Overview' : 'View';
          url  = url.replace(/.+\?/, '?');
          menu = [ '<a class="loc-icon-a" href="' + panel.speciesPath + '/Location/' + view + url + '"><span class="loc-icon loc-change"></span>Jump to region ' + view.toLowerCase() + '</a>' ];
    }
    
    // Multi species view
    function multi() {
      var label = start ? 'region' : 'location';
          menu  = [ '<a href="' + url.replace(/;action=primary;id=\d+/, '') + '">Realign using this ' + label + '</a>' ];
        
      if (panel.multi) {
        menu.push('<a href="' + url + '">Use ' + label + ' as primary</a>');
      } else {
        menu.push('<a href="' + url.replace(/[rg]\d+=[^;]+;?/g, '') + '">Jump to ' + label + '</a>');
      }
    
      caption = panel.species.replace(/_/g, ' ') + ' ' + panel.chr + ':' + (start ? start + '-' + end : panel.location);
    }
    
    // AlignSlice view
    function align() {
      var label  = start ? 'region' : 'location';
          label += panel.species === Ensembl.species ? '' : ' on ' + Ensembl.species.replace(/_/g, ' ');
      
      menu    = [ '<a href="' + url.replace(/%s/, Ensembl.coreParams.r + ';align_start=' + start + ';align_end=' + end) + '">Jump to best aligned ' + label + '</a>' ];
      caption = 'Alignment: ' + (start ? start + '-' + end : panel.location);
    }
    
    // Region select
    if (this.coords.r) {
      start = Math.floor(min + (this.coords.s - this.areaCoords.l) * scale);
      end   = Math.floor(min + (this.coords.s + this.coords.r - this.areaCoords.l) * scale);
      
      if (start > end) {
        tmp   = start;
        start = end;
        end   = tmp;
      }
      
      start = Math.max(start, min);
      end   = Math.min(end,   max);
      
      if (this.strand === 1) {
        this.location = (start + end) / 2;
      } else {
        this.location = (2 * this.start + 2 * this.end - start - end) / 2;
        
        tmp   = start;
        start = this.end + this.start - end;
        end   = this.end + this.start - tmp;
      }
      
      if (this.align === true) {
        align();
      } else {
        url     = url.replace(/%s/, this.chr + ':' + start + '-' + end);
        caption = 'Region: ' + this.chr + ':' + start + '-' + end;
        
        if (!locationView) {
          notLocation();
        } else if (this.multi !== false) {
          multi();
        } else {
          cls = '_location_change';
          
          if (end - start + 1 > Ensembl.maxRegionLength) {
            if (url.match('/View')) {
              url = url.replace('/View', '/Overview');
              cls = '';
            }
          }
          
          menu = [ '<a class="' + cls + ' loc-icon-a" href="' + url + '"><span class="loc-icon loc-change"></span>Jump to region (' + (end - start + 1) + ' bp)</a>' ];
//// EG - add annotation linl          
          if ( $('#annotation-url').length ) {
            menu.push('<a class="loc-icon-a constant" href="%"><span class="loc-icon loc-webapollo"></span>View region in WebApollo</a>'.replace('%', 
              $('#annotation-url').val()
                .replace('###SEQ_REGION###', this.chr)
                .replace('###START###', start)
                .replace('###END###', end)
            ));
          }
////        
        }
      }

      if (this.multi === false) {
        menu.unshift('<a class="_location_mark loc-icon-a" href="' + Ensembl.updateURL({mr: this.chr + ':' + start + '-' + end}, window.location.href) + '"><span class="loc-icon loc-mark"></span>Mark region (' + (end - start + 1) + ' bp)</a>');
      }

    } else { // Point select
      this.location = Math.floor(min + (this.coords.x - this.areaCoords.l) * scale);
      
      if (this.align === true) {
        url = this.zoomURL(1/10);
        align();
      } else {
        url     = this.zoomURL(1);
        caption = 'Location: ' + this.chr + ':' + this.location;
        
        if (!locationView) {
          notLocation();
        } else if (this.multi !== false) {
          multi();
        } else {
          menu = [
            '<a class="_location_change" href="' + this.zoomURL(10) + '">Zoom out x10</a>',
            '<a class="_location_change" href="' + this.zoomURL(5)  + '">Zoom out x5</a>',
            '<a class="_location_change" href="' + this.zoomURL(2)  + '">Zoom out x2</a>',
            '<a class="_location_change" href="' + url + '">Centre here</a>'
          ];

          // Only add zoom in links if there is space to zoom in to.
          $.each([2, 5, 10], function () {
            var href = panel.zoomURL(1 / this);
            
            if (href !== '') {
              menu.push('<a class="_location_change" href="' + href + '">Zoom in x' + this + '</a>');
            }
          });
        }
      }
    }
    
    this.buildMenu(menu, caption);
  },
  
  populateVRegion: function () {
    var min    = this.start;
    var max    = this.end;
    var scale  = (max - min + 1) / (this.areaCoords.b - this.areaCoords.t);
    var length = Math.min(Ensembl.location.length, Ensembl.maxRegionLength) / 2;
    var start, end, view, menu, caption, tmp, url;
    
    if (scale === max) {
      scale /= 2; // For very small images, halve the scale. This will stop start > end problems
    }
    
    // Region select
    if (this.coords.r) {
      start = Math.floor(min + (this.coords.s - this.areaCoords.t) * scale);
      end   = Math.floor(min + (this.coords.s + this.coords.r - this.areaCoords.t) * scale);
      view  = end - start + 1 > Ensembl.maxRegionLength ? 'Overview' : 'View';
      
      if (start > end) {
        tmp   = start;
        start = end;
        end   = tmp;
      }
      
      start   = Math.max(start, min);
      end     = Math.min(end,   max);
      caption = this.chr + ': ' + start + '-' + end;
      
      this.location = (start + end) / 2;
    } else {
      this.location = Math.floor(min + (this.coords.y - this.areaCoords.t) * scale);
      
      view    = 'View';
      start   = Math.max(Math.floor(this.location - length), 1);
      end     =          Math.floor(this.location + length);
      caption = this.chr + ': ' + this.location;
    }
    
    url  = this.baseURL.replace(/.+\?/, '?').replace(/%s/, this.chr + ':' + start + '-' + end);
    menu = [ '<a href="' + this.speciesPath + '/Location/' + view + url + '">Jump to region ' + view.toLowerCase() + '</a>' ];
//// EG - ENSEMBL-3311 disable confusing link
    if (!window.location.pathname.match('/Chromosome')) {
      menu.push('<a href="' + this.speciesPath + '/Location/Chromosome' + url + '">Chromosome summary</a>');
    }
////   
    this.buildMenu(menu, caption);
  },

  variationZoomURL: function (scale, min, max) {
    var w = Ensembl.location.length * scale;
    
    if (w < 1) {
      return '';
    }

    var start = Math.round(this.location - (w - 1) / 2);
    var end   = Math.round(this.location + (w - 1) / 2); // No constraints on end - can't know how long the chromosome is, and perl will deal with overflow
        min   = min || 0;
        max   = max || 0;
    
    if (start < 1) {
      start = this.start;
    }
    
    start = Math.min(Math.max(start, min), max);
    end   = Math.min(Math.max(end,   min), max);
    
    if (this.align === true) {
      return this.baseURL.replace(/%s/, Ensembl.coreParams.r + ';align_start=' + start + ';align_end=' + end);
    } else {
      return this.baseURL.replace(/%s/, (this.chr || Ensembl.location.name) + ':' + start + '-' + end);
    }
  }
    
  
}, { template: Ensembl.Panel.ZMenu.template });
