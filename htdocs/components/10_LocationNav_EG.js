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

Ensembl.Panel.LocationNav = Ensembl.Panel.LocationNav.extend({
  
// EG double-arrow buttons move two windows instaed of 1e6  
  updateButtons: function() { // update button hrefs (and loc) at cur. pos
    var panel = this;
    var r = this.currentLocation();
    var width = r[2]-r[1]+1;
    $('.left_2',panel.el).attr('href',panel.arrow(-width * 2)); 
    $('.left_1',panel.el).attr('href',panel.arrow(-width));
    $('.zoom_in',panel.el).attr('href',panel.zoom(0.5));
    $('.zoom_out',panel.el).attr('href',panel.zoom(2));
    $('.right_1',panel.el).attr('href',panel.arrow(width)); 
    $('.right_2',panel.el).attr('href',panel.arrow(width * 2)); 
    $('#loc_r',panel.el).val(r[0]+':'+r[1]+'-'+r[2]);
  }
//    

});
