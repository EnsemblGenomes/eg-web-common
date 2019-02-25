/*
 * Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
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

if (Ensembl.Panel.GenoverseMenu) {

  Ensembl.Panel.GenoverseMenu = Ensembl.Panel.GenoverseMenu.extend({
     
    populateRegion: function () {
      var action  = this.params.browser.wheelAction === false ? 'Jump' : 'Zoom';
      var cssCls  = action === 'Jump' ? 'loc-change' : 'loc-zoom';
      var bps     = this.drag.end - this.drag.start + 1;
      var url     = this.baseURL.replace(/%s/, this.drag.chr + ':' + this.drag.start + '-' + this.drag.end);
      var mUrl    = Ensembl.updateURL({mr: this.drag.chr + ':' + this.drag.start + '-' + this.drag.end}, window.location.href);


  //// EG - add annotation link
      var menu = this.drag.end === this.drag.start
        ? [ '<a class="loc-icon-a constant _action_center" href="#"><span class="loc-icon loc-pin"></span>Centre here</a>' ]
        : [ '<a class="loc-icon-a constant _action_mark" href="' + mUrl + '"><span class="loc-icon loc-mark"></span>Mark region (' + bps + ' bp)</a>',
            '<a class="loc-icon-a constant _action_' + action.toLowerCase() + 'Here" href="' + url + '"><span class="loc-icon ' + cssCls + '"></span>' + action + ' to region (' + bps + ' bp)</a>' ];

      if ( $('#annotation-url').length ) {
        menu.push('<a class="loc-icon-a constant _action_extlink" href="%"><span class="loc-icon loc-webapollo"></span>View region in Apollo</a>'.replace('%', 
          $('#annotation-url').val()
            .replace('###SEQ_REGION###', this.drag.chr)
            .replace('###START###', this.drag.start)
            .replace('###END###', this.drag.end)
        ));
      }

      this.buildMenu(
        menu,
        'Region: ' + this.drag.chr + ':' + this.drag.start + '-' + this.drag.end
      );
  ////    
    },
  
  //// EG - hack to make extlinks work
    menuLinkClick: function (link, e) {
      var action = (link.className.match(/_action_(\w+)/) || ['']).pop();

      if (action === 'extlink') {
        Ensembl.redirect(link.href);
      } else {
        this.base(link, e);
      } 
    }
  ////
  });

}
