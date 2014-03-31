
Ensembl.Panel.ModalContent = Ensembl.Panel.ModalContent.extend({

  init: function() {
    this.base();
    $('select.species-selector').each(function(){ $(this).speciesSelector() });
    $('select.ajax-species-selector').each(function(){ $(this).ajaxSpeciesSelector() });
  }

});

