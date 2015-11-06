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
      
      this.populate(false, '<tr><td colspan="2"><a href="' + this.href.replace(/ZMenu\//, '') + '">Go to ' + title + '</a></td></tr>');
    } else {
      this.base.apply(this, arguments);
    }
  },

  populateRegion: function () {
    var variationGene = !!window.location.pathname.match(/\/Variation_(Gene|Transcript)\/Image/);
    
    if (!variationGene || !this.coords.r) {
      return this.base();
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
    menu = [ '<a href="' + this.speciesPath + '/Location/' + view + url + '">Jump to location ' + view.toLowerCase() + '</a>' ];
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
      return this.baseURL.replace(/%s/, this.chr + ':' + start + '-' + end);
    }
  }
    
  
}, { template: Ensembl.Panel.ZMenu.template });
