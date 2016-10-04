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
  updateButtons: function(sliderVal) {
    /*
     * Update button hrefs (and location input) at cur. pos
     */
    sliderVal = Math.round(typeof sliderVal === 'undefined' ? this._val2pos() : sliderVal);
    var rs    = this.currentLocations();
    var width = rs['r'][2]-rs['r'][1]+1;

    this.elLk.left1.attr('href', this.arrowHref(-width));
    this.elLk.left2.attr('href', this.arrowHref(-width * 2));
    this.elLk.right1.attr('href', this.arrowHref(width));
    this.elLk.right2.attr('href', this.arrowHref(width * 2));

    this.elLk.zoomIn.attr('href', this.zoomHref(0.5)).toggleClass('disabled', sliderVal === 0).helptip(sliderVal === 0 ? 'disable' : 'enable');
    this.elLk.zoomOut.attr('href', this.zoomHref(2)).toggleClass('disabled', sliderVal === 100).helptip(sliderVal === 100 ? 'disable' : 'enable');

    this.elLk.regionInput.val(rs['r'][0] + ':' + rs['r'][1] + '-'+rs['r'][2]);
  }
//

// The following code was being used for circular region support - currently disabled

// // EG constrain to a given window and handle circular regions
  
//   // zoom: function(factor) { // href for +/- buttons at cur pos. as string
//   //   var config = this.config();
//   //   var rs     = this.currentLocations();  
//   //   var start  = rs['r'][1];
//   //   var end    = rs['r'][2];
//   //   var width  = start > end ? end + config.end - start + 1 : end - start + 1;
//   //   rs = this.rescale(rs,width*factor);
//   //   if(factor>1) {
//   //     $.each(rs,function(k,v) {
//   //       if(v[1] == v[2]) { v[2]++; }
//   //     });
//   //   }   
//   //   return this.newLocation(rs);
//   // },

//   zoomHref: function (factor) {
//   /*
//    * Returns href for +/- buttons at cur pos. as string
//    */
//     var rs     = this.currentLocations();
//     var start  = rs['r'][1];
//     var end    = rs['r'][2];
//     var width  = start > end ? end + config.end - start + 1 : end - start + 1;
//     rs         = this.rescale(rs, width * factor);

//     if (factor > 1) {
//       $.each(rs, function (k, v) {
//         if (v[1] == v[2]) { v[2]++; }
//       });
//     }

//     return this.newHref(rs);
//   },

//   rescale: function(rs, newWidth) {
//   /*
//    * Resets the r params according to the new width provided
//    */    
//     var panel = this;
//     var config = panel.sliderConfig;
//     newWidth  = Math.round(newWidth);
//     var out = {};

//     $.each(rs,function(k,v) {
//       var start  = v[1];
//       var end    = v[2];
//       var width  = start > end ? end + config.end - start + 1 : end - start + 1;
//       var centre = start + Math.round(width / 2);
//       if (start > end  && centre > config.end) centre = centre - config.end + 1; // wrap for circular regions
//       var new_start = centre - Math.round(newWidth / 2);
//       var new_end   = centre + Math.round(newWidth / 2);
//       var new_region = [v[0], new_start, new_end, v[3]];
//       out[k] = k == 'r' ? panel.constrainToWindow(new_region) : panel.constrainStart(new_region);
//     });

//     return out;
//   },

//   arrowHref: function (step) {
//   /*
//    * Returns href for the arrow buttons at cur pos. as string
//    */
//     var panel = this;
//     var rs    = this.currentLocations();

//     $.each(rs,function(k, v) {
//       var new_region = [v[0], v[1] + step, v[2] + step, v[3]];
//       rs[k] = k == 'r' ? panel.constrainToWindow(new_region) : panel.constrainStart(new_region);
//     });

//     return this.newHref(rs);
//   },

//   constrainStart: function(r) {
//     var start = r[1];
//     var end = r[2];
//     if (start < 0) {
//       end  -= start;
//       start = 1; 
//     };
//     return [r[0], start, end, r[3]];
//   },

//   constrainToWindow: function(r) {
//     var c = this.constrain(r[1], r[2]);
//     return [r[0], c.start, c.end, r[3]];
//   },

//   constrain: function(s, e) {
//     var config = this.sliderConfig;
//     if (config.isCircular && config.start == 1) {
//       // it's a circular region and we could potentially overlap the origin
//       var max = config.end;
//       var window_size = (s <= e ? e - s : e + max - s) + 1; 
//       if (window_size >= max) {
//         // window covers whole region
//         s = 1;
//         e = max;
//       } else {
//         // wrap start pos
//         if (s < 0)   s += max;
//         if (s > max) s -= max;
//         if (s == 0)  s = 1;
//         // wrap end pos
//         if (e < 0)   e += max;
//         if (e > max) e -= max;
//         if (e == 0)  e = 1;
//       }
//     } else {
//       if (s > config.end)   s = config.end - config.min;
//       if (e > config.end)   e = config.end;
//       if (s < config.start) s = config.start;
//       if (e < config.start) e = config.start + config.min;
//     }
//     return {start: s, end: e};
//   },

//   val2pos: function () { // from 0-100 on UI slider to bp
//     var panel     = this;
    
//     var rs        = panel.currentLocations();
//     var start     = rs['r'][1];
//     var end       = rs['r'][2];
//     var config    = panel.config();
//     var input     = start > end ? end + config.end - start + 1 : end - start + 1;
//     var slide_mul = ( Math.log(config.max) - Math.log(config.min) ) / 100;
//     var slide_off = Math.log(config.min);
//     var out       = (Math.log(input)-slide_off)/slide_mul;
    
//     if(out < 0) { return 0; }
//     if(out > 100) { return 100; }
    
//     return out;
//   }

});
