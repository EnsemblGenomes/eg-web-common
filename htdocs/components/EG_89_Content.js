Ensembl.Panel.Content = Ensembl.Panel.Content.extend({
  
  init: function() {
    $('select.species-selector').each(function(){ $(this).speciesSelector() });
    $('select.ajax-species-selector').each(function(){ $(this).ajaxSpeciesSelector() });
    this.base();
        this.el.find(".species_lightbox").fancybox();
  },
  
  dataTable: function () {
    var panel = this;
   
    this.elLk.updateGeneTree = $('input.update_genetree', this.el).on('click', function () {
     
      var ht = this.value.match(/[#?;&]ht=([^;&]+)/)[1];
      var match = decodeURIComponent(window.location[Ensembl.locationURL]).match(/[#?;&]collapse=([^;&]*)/);
      var collapse = match ? match[1] : '';
 
      Ensembl.historyReady = true;
      Ensembl.updateURL({ ht: ht });
     
      panel.elLk.updateGeneTree.not(this).prop('checked', false);
      panel.elLk.clearHighlightSelectors.prop('checked', false);

      this.checked = true;
      Ensembl.EventManager.triggerSpecific('updatePanel', 'ComparaTree', undefined, null, { updateURL: Ensembl.updateURL({ ht: ht, collapse: collapse, update_panel: 1 }, this.value) }); // reload image
    });

    this.elLk.clearHighlightSelectors = $('input.clear_highlight_selectors', this.el).on('click', function () {
      
      Ensembl.historyReady = true;
      Ensembl.updateURL({ ht: '' });
      panel.elLk.updateGeneTree.prop('checked', false);

      this.checked = true;
      Ensembl.EventManager.triggerSpecific('updatePanel', 'ComparaTree', undefined, null, { updateURL: Ensembl.updateURL({ update_panel: 1 }, this.value) });
    });
 
    this.base();
  }
});
