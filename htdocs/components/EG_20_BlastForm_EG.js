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

var tempEPBS = Ensembl.Panel.BlastForm.Sequence;

Ensembl.Panel.BlastForm = Ensembl.Panel.BlastForm.extend({
  init: function () {
    this.base();
    this.showBlastMessage();
  },
  
  resetSpecies: function(speciesList) {
    if (typeof speciesList[0] !== 'object') {
      // Todo: handle default species - currently it is passed as single production_name string 
      //       and we don't have the display name. Instead we do nothing and rely on the name pre-populated
      //       on the server-side. This means that using the 'Clear' button does not reset default species.
      return;
    }

    var seen   = {};
    var unique = [];
    $.each(speciesList, function(i, sp){
      if (!seen[sp.key]) {
        unique.push(sp);
        seen[sp.key] = true;
      }
    });

    unique.sort(function(a,b) { return a.key < b.key ? -1 : a.key > b.key ? 1 : 0 });

    setTimeout(function() { Ensembl.EventManager.trigger('updateTaxonSelection', unique) }, 200);
  },

  showBlastMessage: function() {
    var notified    = Ensembl.cookie.get('ncbiblast_notified');

    if (!notified) {
      $(['<div class="blast-message hidden">',
        '<div></div>',
        '<p><b>PLEASE NOTE</b></p>',
        '<p>As of release 27, this tool is using <a href="http://www.ebi.ac.uk/Tools/sss/ncbiblast/">NCBI BLAST+</a> instead of <a href="http://www.ebi.ac.uk/Tools/sss/wublast/">WU-BLAST</a>. Consequently new jobs may generate different results to existing saved jobs.</p>',
        '<p><button>Don\'t show this again</button></p>',
        '</div>'
      ].join(''))
        .appendTo(document.body).show().find('button,div').on('click', function (e) {
          Ensembl.cookie.set('ncbiblast_notified', 'yes');
          $(this).parents('div').first().fadeOut(200);
      }).filter('div').helptip({content:"Don't show this again"});
      return true;
    }

    return false;
  }
});

Ensembl.Panel.BlastForm.Sequence = tempEPBS;