Ensembl.Panel.ImageMap =  Ensembl.Panel.ImageMap.extend({
  init: function(){
    this.zMenus           = [];
    this.base();
  },
  
  getContent: function (url, el, params, newContent) {
    var i = this.zMenus.length;
    while (i--) {
      Ensembl.EventManager.trigger('destroyPanel', this.zMenus[i]);
    }
    this.zMenus = {};
    if (newContent && newContent !== true) {
      Ensembl.updateURL(newContent); // A link was clicked that needs to add parameters to the url
      newContent = false;
    }
    this.base(url, el, params, newContent);
  },
  
  makeZMenu: function (e, coords) {
    var area = coords.r ? this.dragRegion : this.getArea(coords);

    if (!area || $(area.a).hasClass('label')) {
      return;
    }
  
    this.zMenus['zmenu_' + area.a.coords.replace(/[ ,]/g, '_')] = 1;

    this.base(e, coords);
  },
  
  makeImageMap: function () {
    var panel = this;
    
    var highlight = !!(window.location.pathname.match(/\/Location\/|\/Variation_(Gene|Transcript)\/Image/) && !this.vdrag);
    var rect      = [ 'l', 't', 'r', 'b' ];
    var speciesNumber, c, r, start, end, scale;

    this.elLk.areas.each(function () {
      c = { a: this };

      if (this.shape && this.shape.toLowerCase() !== 'rect') {
        c.c = [];
        $.each(this.coords.split(/[ ,]/), function () { c.c.push(parseInt(this, 10)); });
      } else {
        $.each(this.coords.split(/[ ,]/), function (i) { c[rect[i]] = parseInt(this, 10); });
      }

      panel.areas.push(c);

      if (this.className.match(/drag/)) {
        // r = [ '#drag', image number, species number, species name, region, start, end, strand ]
        r     = c.a.href.split('|');
        start = parseInt(r[5], 10);
        end   = parseInt(r[6], 10);
        scale = (end - start + 1) / (c.r - c.l); // bps per pixel on image

        c.range = { start: start, end: end, scale: scale };

        panel.draggables.push(c);

        if (highlight === true) {
          r = this.href.split('|');
          speciesNumber = parseInt(r[1], 10) - 1;

          if (panel.multi || !speciesNumber) {
            if (!panel.highlightRegions[speciesNumber]) {
              panel.highlightRegions[speciesNumber] = [];
              panel.speciesCount++;
            }

            panel.highlightRegions[speciesNumber].push({ region: c });
            panel.imageNumber = parseInt(r[2], 10);

            Ensembl.images[panel.imageNumber] = Ensembl.images[panel.imageNumber] || {};
            Ensembl.images[panel.imageNumber][speciesNumber] = [ panel.imageNumber, speciesNumber, parseInt(r[5], 10), parseInt(r[6], 10) ];
          }
        }
      }
    });

    if (Ensembl.images.total) {
      this.highlightAllImages();
    }
    
    this.elLk.drag.on({
      mousedown: function (e) {
        // Only draw the drag box for left clicks.
        // This property exists in all our supported browsers, and browsers without it will draw the box for all clicks
        if (!e.which || e.which === 1) {
          panel.dragStart(e);
        }

        return false;
      },
      click: function (e) {
        if (panel.clicking) {
          panel.makeZMenu(e, panel.getMapCoords(e));
        } else {
          panel.clicking = true;
        }
      }
    });
  },
  
  hashChange: function () {
    if (!!window.location.pathname.match(/\/Variation_Gene\/Image/)) {
      if (this.hashChangeReload || this.lastImage) {
        this.elLk.exportMenu.remove();
        Ensembl.Panel.Content.prototype.hashChange.call(this);
      }
      
      Ensembl.EventManager.trigger('highlightAllImages');
    } else {
      this.base.apply(this,arguments);
    }
  }
});
