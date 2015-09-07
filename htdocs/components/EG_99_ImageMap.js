Ensembl.Panel.ImageMap =  Ensembl.Panel.ImageMap.extend({

  constructor: function () {
    this.base.apply(this, arguments);
    this.allowHighlight = !!(window.location.pathname.match(/\/Location\/|\/Variation_(Gene|Transcript)\/Image/));
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
