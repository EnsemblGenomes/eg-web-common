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

if (Ensembl.Panel.BlastForm) {

  var tempEPBS = Ensembl.Panel.BlastForm.Sequence;

  Ensembl.Panel.BlastForm = Ensembl.Panel.BlastForm.extend({
   
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
    }

  });

  Ensembl.Panel.BlastForm.Sequence = tempEPBS;
}