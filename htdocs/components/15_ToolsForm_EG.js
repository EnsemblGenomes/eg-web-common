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

/*
 * Base form for all tools forms
 */

Ensembl.Panel.ToolsForm = Ensembl.Panel.ToolsForm.extend({

  editExisting: function(noReset) {
  /*
   * Checks and populates the form with existing job if job data present as a hidden input
   * @return true if existing job present, false otherwise
   */
    var editingJobsData       = [];
    try {
      editingJobsData         = $.parseJSON(this.elLk.form.find('input[name=edit_jobs]').remove().val());
    } catch (ex) {}
// EG - we get a runtime error if editingJobsData is null unless we check it
    //if (editingJobsData.length) {
    if (editingJobsData && editingJobsData.length) {   
//       
      this.populateForm(editingJobsData, noReset);
      return true;
    }
    return false;
  }

});
