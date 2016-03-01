
Ensembl.Panel.ModalContent = Ensembl.Panel.ModalContent.extend({

  init: function() {
    this.base();
    $('select.species-selector').each(function(){ $(this).speciesSelector() });
    $('select.ajax-species-selector').each(function(){ $(this).ajaxSpeciesSelector() });
  }


  getContent: function (link, url) {
    this.elLk.content.html('<div class="panel"><div class="spinner">Loading Content</div></div>');
    
    //EG - ENSEMBL-4218
    /*
    * If the URL is longer than 1500 characters, request is sent by POST.
    */
    var data = {};
    var type;

    if(url.length > 1500){
      $.each((url.split(/\?/)[1] || '').split(/&|;/), function(i, param) {
        param = param.split('=');
        if (typeof param[0] !== 'undefined' && !(param[0] in data)) {
          data[param[0]] = param[1];
        }
      });
      url = url.split(/\?/)[0];
      type = 'POST';
    }
    else {
      type = 'GET';
    }
    //EG

    $.ajax({
      url: Ensembl.replaceTimestamp(url),
      dataType: 'json',
      context: this,
      //EG - ENSEMBL-4218
      type: type,
      data: data,
      //EG
      success: function (json) {
        if (json.redirectURL && json.redirectType === 'modal') {
          return this.getContent(link, json.redirectURL);
        } else if (json.redirectType === 'page') {
          return Ensembl.redirect(json.redirectURL);
        } else if (json.redirectType === 'download') {
          Ensembl.EventManager.trigger('modalClose');
          window.location.href = json.redirectURL;
          return;
        }
        
        // Avoid race conditions if the user has clicked another nav link while waiting for content to load
        if (typeof link === 'undefined' || link.hasClass('active')) {
          this.updateContent(json);
        }
      },
      error: function (e) {
        if (e.status !== 0) {
          this.displayErrorMessage();
        }
      }
    });
  }

});

