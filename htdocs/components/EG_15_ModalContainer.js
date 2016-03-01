/*
 * Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *      http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

Ensembl.Panel.ModalContainer = Ensembl.Panel.ModalContainer.extend({
  
  getContent: function (url, id) {
    if (this.xhr) {
      this.xhr.abort();
    }
    
    var reload = url.match(/reset=/)  || $('.modal_reload', this.el).remove().length;
    var hash;
    
    if (id && id.match('-')) {
      hash = id.split('-');
      id   = hash.shift();
      hash = hash.join('-');
    } else {
      hash = (url.match(/#(.+)$/) || [])[1];
    }
    
    id = id || (hash ? this.activePanel : 'modal_default');
    
    var contentEl = this.elLk.content.filter('#' + id);
    
    this.elLk.content.hide();
    this.activePanel = id;
    
    if (this.modalReload[id]) {
      delete this.modalReload[id];
      reload = true;
    }
    
    if (reload) {
      contentEl.empty();
    } else if (id.match(/config/) && contentEl.children(':not(.spinner, .ajax_error)').length) {
      Ensembl.EventManager.triggerSpecific('showConfiguration', id, hash);
      this.changeTab(this.elLk.content.filter('#' + id).data('tab'));
      this.elLk.closeButton.attr({ title: 'Save and close', alt: 'Save and close' });
      
      return;
    }
    
    contentEl.html('<div class="spinner">Loading Content</div>').show();



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

    this.xhr = $.ajax({
      url: Ensembl.replaceTimestamp(url),
      dataType: 'json',
      context: this,
      //EG - ENSEMBL-4218
      type: type,
      data: data,
      //EG
      success: function (json) {
        var params = hash ? $.extend(json.params || {}, { hash: hash }) : json.params;
        var wrapper, buttonText, forceReload, nav;
        
        if (json.redirectURL) {
          return this.getContent(json.redirectURL, id);
        }
        
        switch (json.panelType) {
          case 'ModalContent': buttonText = 'Close';          break;
          case 'Configurator': buttonText = 'Save and close'; break;
          default:             buttonText = 'Update options'; break;
        }
        
        if (json.activeTab) {
          this.changeTab(this.elLk.tabs.has('.' + json.activeTab));
        }
        
        Ensembl.EventManager.trigger('destroyPanel', id, 'empty'); // clean up handlers, save memory
        
        wrapper = $(json.wrapper);
        
        if (json.tools) {
          json.nav += json.tools;
        }
        
        if (json.nav) {
          nav = [ '<div class="modal_nav nav">', json.nav, '</div>' ].join('');
        } else {
          wrapper.addClass('no_local_context');
        }
        
        contentEl.html(json.content).wrapInner(wrapper).prepend(nav).find('.tool_buttons > p').show();
        
        this.elLk.closeButton.attr({ title: buttonText, alt: buttonText });
        
        forceReload = $('.modal_reload', contentEl);
        
        if (reload || forceReload.length) {
          this.setPageReload($('input.component', contentEl).val(), false, !!forceReload.length, forceReload.attr('href'));
        }
        
        if (url.match(/reset=/)) {
          params.reset = url.match(/reset=(\w+)/)[1];
        }
        
        Ensembl.EventManager.trigger('createPanel', id, json.panelType || $((json.content.match(/<input[^<]*class="[^<]*panel_type[^<]*"[^<]*>/) || [])[0]).val(), params);
        
        wrapper = nav = forceReload = null;
      },
      error: function (e) {
         if (e.status !== 0) {
          contentEl.html('<div class="error ajax_error"><h3>Ajax error</h3><div class="error-pad"><p>Sorry, the page request failed to load.</p></div></div>');
        }
      },
      complete: function () {
        this.xhr = false;
      }
    });
  }
  
});
