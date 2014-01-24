Ensembl.Panel.BlastSpeciesList = Ensembl.Panel.extend({
  constructor: function (id, params) {
    var panel = this;
    panel.base(id);
    Ensembl.EventManager.register('updateTaxonSelection', panel, panel.updateTaxonSelection);
  },
  
  init: function () {  
 		var panel = this;
 		panel.base();
 		panel.elLk.blastForm = $('form[name=settings]');
 		panel.elLk.list 		 = $('select', this.el);
 		panel.elLk.modalLink = $('.modal_link', this.el)
 		
 		panel.elLk.blastForm.submit(function(){
 			// ensure all species are selected
			$('option', panel.elLk.list).attr("selected", "selected");
		});
  },
  
  updateTaxonSelection: function(items) {
  	var panel = this;
  	var key;
  	
  	// empty and re-populate the species list
  	$('option', panel.elLk.list).remove();
  	$.each(items, function(index, item){
  		key = item.key.charAt(0).toUpperCase() + item.key.substr(1); // ucfirst
  		//$(panel.elLk.list).append(new Option(item.kye, item.key)); // this fails in IE - see http://bugs.jquery.com/ticket/1641
  		$(panel.elLk.list).append('<option value="' + key + '">' + key + '</option>'); // this works in IE 
  	}); 
  	
  	// update the modal link href
  	var modalBaseUrl = panel.elLk.modalLink.attr('href').split('?')[0];
  	var keys = $.map(items, function(item){ return item.key; });
  	var queryString = $.param({s: keys}, true);
  	panel.elLk.modalLink.attr('href', modalBaseUrl + '?' + queryString);
  }
});
