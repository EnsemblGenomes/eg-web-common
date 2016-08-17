/** @license
* Bootstrap.js by @fat & @mdo
* Copyright 2013 Twitter, Inc.
* http://www.apache.org/licenses/LICENSE-2.0.txt
*/

/* ===================================================
 * bootstrap-transition.js v2.3.1
 * http://twitter.github.com/bootstrap/javascript.html#transitions
 * ===================================================
 * Copyright 2012 Twitter, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ========================================================== */


!function ($) {

  "use strict"; // jshint ;_;


  /* CSS TRANSITION SUPPORT (http://www.modernizr.com/)
   * ======================================================= */

  $(function () {

    $.support.transition = (function () {

      var transitionEnd = (function () {

        var el = document.createElement('bootstrap')
          , transEndEventNames = {
               'WebkitTransition' : 'webkitTransitionEnd'
            ,  'MozTransition'    : 'transitionend'
            ,  'OTransition'      : 'oTransitionEnd otransitionend'
            ,  'transition'       : 'transitionend'
            }
          , name

        for (name in transEndEventNames){
          if (el.style[name] !== undefined) {
            return transEndEventNames[name]
          }
        }

      }())

      return transitionEnd && {
        end: transitionEnd
      }

    })()

  })

}(window.jQuery);
/* ============================================================
 * bootstrap-dropdown.js v2.3.1
 * http://twitter.github.com/bootstrap/javascript.html#dropdowns
 * ============================================================
 * Copyright 2012 Twitter, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ============================================================ */


!function ($) {

  "use strict"; // jshint ;_;


 /* DROPDOWN CLASS DEFINITION
  * ========================= */

  var toggle = '[data-toggle=dropdown]'
    , Dropdown = function (element) {
        var $el = $(element).on('click.dropdown.data-api', this.toggle)
        $('html').on('click.dropdown.data-api', function () {
          $el.parent().removeClass('open')
        })
      }

  Dropdown.prototype = {

    constructor: Dropdown

  , toggle: function (e) {
      var $this = $(this)
        , $parent
        , isActive

      if ($this.is('.disabled, :disabled')) return

      $parent = getParent($this)

      isActive = $parent.hasClass('open')

      clearMenus()

      if (!isActive) {
        $parent.toggleClass('open')
      }

      $this.focus()

      return false
    }

  , keydown: function (e) {
      var $this
        , $items
        , $active
        , $parent
        , isActive
        , index

      if (!/(38|40|27)/.test(e.keyCode)) return

      $this = $(this)

      e.preventDefault()
      e.stopPropagation()

      if ($this.is('.disabled, :disabled')) return

      $parent = getParent($this)

      isActive = $parent.hasClass('open')

      if (!isActive || (isActive && e.keyCode == 27)) {
        if (e.which == 27) $parent.find(toggle).focus()
        return $this.click()
      }

      $items = $('[role=menu] li:not(.divider):visible a', $parent)

      if (!$items.length) return

      index = $items.index($items.filter(':focus'))

      if (e.keyCode == 38 && index > 0) index--                                        // up
      if (e.keyCode == 40 && index < $items.length - 1) index++                        // down
      if (!~index) index = 0

      $items
        .eq(index)
        .focus()
    }

  }

  function clearMenus() {
    $(toggle).each(function () {
      getParent($(this)).removeClass('open')
    })
  }

  function getParent($this) {
    var selector = $this.attr('data-target')
      , $parent

    if (!selector) {
      selector = $this.attr('href')
      selector = selector && /#/.test(selector) && selector.replace(/.*(?=#[^\s]*$)/, '') //strip for ie7
    }

    $parent = selector && $(selector)

    if (!$parent || !$parent.length) $parent = $this.parent()

    return $parent
  }


  /* DROPDOWN PLUGIN DEFINITION
   * ========================== */

  var old = $.fn.dropdown

  $.fn.dropdown = function (option) {
    return this.each(function () {
      var $this = $(this)
        , data = $this.data('dropdown')
      if (!data) $this.data('dropdown', (data = new Dropdown(this)))
      if (typeof option == 'string') data[option].call($this)
    })
  }

  $.fn.dropdown.Constructor = Dropdown


 /* DROPDOWN NO CONFLICT
  * ==================== */

  $.fn.dropdown.noConflict = function () {
    $.fn.dropdown = old
    return this
  }


  /* APPLY TO STANDARD DROPDOWN ELEMENTS
   * =================================== */

  $(document)
    .on('click.dropdown.data-api', clearMenus)
    .on('click.dropdown.data-api', '.dropdown form', function (e) { e.stopPropagation() })
    .on('click.dropdown-menu', function (e) { e.stopPropagation() })
    .on('click.dropdown.data-api'  , toggle, Dropdown.prototype.toggle)
    .on('keydown.dropdown.data-api', toggle + ', [role=menu]' , Dropdown.prototype.keydown)

}(window.jQuery);

/* ========================================================

 * bootstrap-typeahead.js v2.3.1
 * http://twitter.github.com/bootstrap/javascript.html#typeahead
 * =============================================================
 * Copyright 2012 Twitter, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ============================================================ */


!function($){

  "use strict"; // jshint ;_;


 /* TYPEAHEAD PUBLIC CLASS DEFINITION
  * ================================= */

  var Typeahead = function (element, options) {
    this.$element = $(element)
    this.options = $.extend({}, $.fn.typeahead.defaults, options)
    this.matcher = this.options.matcher || this.matcher
    this.sorter = this.options.sorter || this.sorter
    this.highlighter = this.options.highlighter || this.highlighter
    this.updater = this.options.updater || this.updater
    this.source = this.options.source
    this.$menu = $(this.options.menu)
    this.shown = false
    this.lookup_timeoutID = undefined
    this.listen()
  }

  Typeahead.prototype = {

    constructor: Typeahead

  , select: function () {
      var val = this.$menu.find('.active').attr('data-value')
      this.$element
        .val(this.updater(val))
        .change()
      return this.hide()
    }

  , updater: function (item) {
      return item
    }

  , show: function () {
      var pos = $.extend({}, this.$element.position(), {
        height: this.$element[0].offsetHeight
      })

      this.$menu
        .insertAfter(this.$element)
        .css({
          top: pos.top + pos.height
        , left: pos.left
        })
        .show()

      this.shown = true
      return this
    }

  , hide: function () {
      this.$menu.hide()
      this.shown = false
      return this
    }

  , lookup: function (event) {
      var items

      this.query = this.$element.val()

      if (!this.query || this.query.length < this.options.minLength) {
        return this.shown ? this.hide() : this
      }

      items = $.isFunction(this.source) ? this.source(this.query, $.proxy(this.process, this)) : this.source

      return items ? this.process(items) : this
    }

  , process: function (items) {
      var that = this

      items = $.grep(items, function (item) {
        return that.matcher(item)
      })

      items = this.sorter(items)

      if (!items.length) {
        return this.shown ? this.hide() : this
      }

      return this.render(items.slice(0, this.options.items)).show()
    }

  , matcher: function (item) {
      return ~item.toLowerCase().indexOf(this.query.toLowerCase())
    }

  , sorter: function (items) {
      var beginswith = []
        , caseSensitive = []
        , caseInsensitive = []
        , item

      while (item = items.shift()) {
        if (!item.toLowerCase().indexOf(this.query.toLowerCase())) beginswith.push(item)
        else if (~item.indexOf(this.query)) caseSensitive.push(item)
        else caseInsensitive.push(item)
      }

      return beginswith.concat(caseSensitive, caseInsensitive)
    }

  , highlighter: function (item) {
      var query = this.query.replace(/[\-\[\]{}()*+?.,\\\^$|#\s]/g, '\\$&')
      return item.replace(new RegExp('(' + query + ')', 'ig'), function ($1, match) {
        return '<strong>' + match + '</strong>'
      })
    }

  , render: function (items) {
      var that = this

      items = $(items).map(function (i, item) {
        i = $(that.options.item).attr('data-value', item)
        i.find('a').html(that.highlighter(item))
        return i[0]
      })

      items.first().addClass('active')
      this.$menu.html(items)
      return this
    }

  , next: function (event) {
      var active = this.$menu.find('.active').removeClass('active')
        , next = active.next()

      if (!next.length) {
        next = $(this.$menu.find('li')[0])
      }

      next.addClass('active')
    }

  , prev: function (event) {
      var active = this.$menu.find('.active').removeClass('active')
        , prev = active.prev()

      if (!prev.length) {
        prev = this.$menu.find('li').last()
      }

      prev.addClass('active')
    }

  , listen: function () {
      this.$element
        .on('focus',    $.proxy(this.focus, this))
        .on('blur',     $.proxy(this.blur, this))
        .on('keypress', $.proxy(this.keypress, this))
        .on('keyup',    $.proxy(this.keyup, this))

      if (this.eventSupported('keydown')) {
        this.$element.on('keydown', $.proxy(this.keydown, this))
      }

      this.$menu
        .on('click', $.proxy(this.click, this))
        .on('mouseenter', 'li', $.proxy(this.mouseenter, this))
        .on('mouseleave', 'li', $.proxy(this.mouseleave, this))
    }

  , eventSupported: function(eventName) {
      var isSupported = eventName in this.$element
      if (!isSupported) {
        this.$element.setAttribute(eventName, 'return;')
        isSupported = typeof this.$element[eventName] === 'function'
      }
      return isSupported
    }

  , move: function (e) {
      if (!this.shown) return

      switch(e.keyCode) {
        case 9: // tab
        case 13: // enter
        case 27: // escape
          e.preventDefault()
          break

        case 38: // up arrow
          e.preventDefault()
          this.prev()
          break

        case 40: // down arrow
          e.preventDefault()
          this.next()
          break
      }

      e.stopPropagation()
    }

  , keydown: function (e) {
      this.suppressKeyPressRepeat = ~$.inArray(e.keyCode, [40,38,9,13,27])
      this.move(e)
    }

  , keypress: function (e) {
      if (this.suppressKeyPressRepeat) return
      this.move(e)
    }

  , keyup: function (e) {
      switch(e.keyCode) {
        case 40: // down arrow
        case 38: // up arrow
        case 16: // shift
        case 17: // ctrl
        case 18: // alt
          break

        case 9: // tab
        case 13: // enter
          if (!this.shown) return
          this.select()
          break

        case 27: // escape
          if (!this.shown) return
          this.hide()
          break

        default:
          //modified to reduce the number of repeated queries
          window.clearTimeout(this.lookup_timeoutID);
          this.lookup_timeoutID = window.setTimeout($.proxy(this.lookup, this), 300);
      }

      e.stopPropagation()
      e.preventDefault()
  }

  , focus: function (e) {
      this.focused = true
    }

  , blur: function (e) {
      this.focused = false
      if (!this.mousedover && this.shown) this.hide()
    }

  , click: function (e) {
      e.stopPropagation()
      e.preventDefault()
      this.select()
      this.$element.focus()
    }

  , mouseenter: function (e) {
      this.mousedover = true
      this.$menu.find('.active').removeClass('active')
      $(e.currentTarget).addClass('active')
    }

  , mouseleave: function (e) {
      this.mousedover = false
      if (!this.focused && this.shown) this.hide()
    }

  }


  /* TYPEAHEAD PLUGIN DEFINITION
   * =========================== */

  var old = $.fn.typeahead

  $.fn.typeahead = function (option) {
    return this.each(function () {
      var $this = $(this)
        , data = $this.data('typeahead')
        , options = typeof option == 'object' && option
      if (!data) $this.data('typeahead', (data = new Typeahead(this, options)))
      if (typeof option == 'string') data[option]()
    })
  }

  $.fn.typeahead.defaults = {
    source: []
  , items: 8
  , menu: '<ul class="typeahead dropdown-menu"></ul>'
  , item: '<li><a href="#"></a></li>'
  , minLength: 1
  }

  $.fn.typeahead.Constructor = Typeahead


 /* TYPEAHEAD NO CONFLICT
  * =================== */

  $.fn.typeahead.noConflict = function () {
    $.fn.typeahead = old
    return this
  }


 /* TYPEAHEAD DATA-API
  * ================== */

  $(document).on('focus.typeahead.data-api', '[data-provide="typeahead"]', function (e) {
    var $this = $(this)
    if ($this.data('typeahead')) return
    $this.typeahead($this.data())
  })

}(window.jQuery);

!function ($) {
  $.placement_fix = function(tip, element) {
      var $element, above, actualHeight, actualWidth, below, boundBottom, boundLeft, boundRight, boundTop, elementAbove, elementBelow, elementLeft, elementRight, isWithinBounds, left, pos, right;
      isWithinBounds = function(elementPosition) {
        return boundTop < elementPosition.top && boundLeft < elementPosition.left && boundRight > (elementPosition.left + actualWidth) && boundBottom > (elementPosition.top + actualHeight);
      };
      $element = $(element);
      pos = $.extend({}, $element.offset(), {
        width: element.offsetWidth,
        height: element.offsetHeight
      });
      $(tip).attr('visability','hidden');
      $(tip).appendTo(document.body)
      actualHeight = $(tip).height();
      actualWidth = $(tip).width();
      $(tip).remove();
      boundTop = $(document).scrollTop();
      boundLeft = $(document).scrollLeft();
      boundRight = boundLeft + $(window).width();
      boundBottom = boundTop + $(window).height();
      elementAbove = {
        top: pos.top - actualHeight,
        left: pos.left + pos.width / 2 - actualWidth / 2
      };
      elementBelow = {
        top: pos.top + pos.height,
        left: pos.left + pos.width / 2 - actualWidth / 2
      };
      elementLeft = {
        top: pos.top + pos.height / 2 - actualHeight / 2,
        left: pos.left - actualWidth
      };
      elementRight = {
        top: pos.top + pos.height / 2 - actualHeight / 2,
        left: pos.left + pos.width
      };
      
      //Abort if default placement is valid
      if(this.options.defualt_placement){
        switch (this.options.defualt_placement){
          case 'right':
            if (isWithinBounds(elementRight)){
              return "right";
            }
            break;
          case 'left':
            if (isWithinBounds(elementLeft)){
              return "left";
            }
            break;
          case 'top':
            if (isWithinBounds(elementAbove)){
              return "top";
            }
            break;
          case 'bottom':
            if (isWithinBounds(elementBelow)){
              return "bottom";
            }
            break;
        }
      }
        
      //Can't use defualt, find next best.
      if (isWithinBounds(elementAbove)) {
        return "top";
      } else if (isWithinBounds(elementRight)) {
          return "right";
      } else if (isWithinBounds(elementBelow)) {
          return "bottom";
      } else if (isWithinBounds(elementLeft)) {
          return "left";
      } else {
          return "top";
      }
    };

}(window.jQuery);


// lib/handlebars/base.js

/*jshint eqnull:true*/
this.Handlebars = {};

(function(Handlebars) {

Handlebars.VERSION = "1.0.rc.1";

Handlebars.helpers  = {};
Handlebars.partials = {};

Handlebars.registerHelper = function(name, fn, inverse) {
  if(inverse) { fn.not = inverse; }
  this.helpers[name] = fn;
};

Handlebars.registerPartial = function(name, str) {
  this.partials[name] = str;
};

Handlebars.registerHelper('helperMissing', function(arg) {
  if(arguments.length === 2) {
    return undefined;
  } else {
    throw new Error("Could not find property '" + arg + "'");
  }
});

var toString = Object.prototype.toString, functionType = "[object Function]";

Handlebars.registerHelper('blockHelperMissing', function(context, options) {
  var inverse = options.inverse || function() {}, fn = options.fn;


  var ret = "";
  var type = toString.call(context);

  if(type === functionType) { context = context.call(this); }

  if(context === true) {
    return fn(this);
  } else if(context === false || context == null) {
    return inverse(this);
  } else if(type === "[object Array]") {
    if(context.length > 0) {
      return Handlebars.helpers.each(context, options);
    } else {
      return inverse(this);
    }
  } else {
    return fn(context);
  }
});

Handlebars.K = function() {};

Handlebars.createFrame = Object.create || function(object) {
  Handlebars.K.prototype = object;
  var obj = new Handlebars.K();
  Handlebars.K.prototype = null;
  return obj;
};

Handlebars.registerHelper('each', function(context, options) {
  var fn = options.fn, inverse = options.inverse;
  var ret = "", data;

  if (options.data) {
    data = Handlebars.createFrame(options.data);
  }

  if(context && context.length > 0) {
    for(var i=0, j=context.length; i<j; i++) {
      if (data) { data.index = i; }
      ret = ret + fn(context[i], { data: data });
    }
  } else {
    ret = inverse(this);
  }
  return ret;
});

Handlebars.registerHelper('if', function(context, options) {
  var type = toString.call(context);
  if(type === functionType) { context = context.call(this); }

  if(!context || Handlebars.Utils.isEmpty(context)) {
    return options.inverse(this);
  } else {
    return options.fn(this);
  }
});

Handlebars.registerHelper('unless', function(context, options) {
  var fn = options.fn, inverse = options.inverse;
  options.fn = inverse;
  options.inverse = fn;

  return Handlebars.helpers['if'].call(this, context, options);
});

Handlebars.registerHelper('with', function(context, options) {
  return options.fn(context);
});

Handlebars.registerHelper('log', function(context) {
  Handlebars.log(context);
});

}(this.Handlebars));
;
// lib/handlebars/compiler/parser.js
/* Jison generated parser */
var handlebars = (function(){
var parser = {trace: function trace() { },
yy: {},
symbols_: {"error":2,"root":3,"program":4,"EOF":5,"statements":6,"simpleInverse":7,"statement":8,"openInverse":9,"closeBlock":10,"openBlock":11,"mustache":12,"partial":13,"CONTENT":14,"COMMENT":15,"OPEN_BLOCK":16,"inMustache":17,"CLOSE":18,"OPEN_INVERSE":19,"OPEN_ENDBLOCK":20,"path":21,"OPEN":22,"OPEN_UNESCAPED":23,"OPEN_PARTIAL":24,"params":25,"hash":26,"DATA":27,"param":28,"STRING":29,"INTEGER":30,"BOOLEAN":31,"hashSegments":32,"hashSegment":33,"ID":34,"EQUALS":35,"pathSegments":36,"SEP":37,"$accept":0,"$end":1},
terminals_: {2:"error",5:"EOF",14:"CONTENT",15:"COMMENT",16:"OPEN_BLOCK",18:"CLOSE",19:"OPEN_INVERSE",20:"OPEN_ENDBLOCK",22:"OPEN",23:"OPEN_UNESCAPED",24:"OPEN_PARTIAL",27:"DATA",29:"STRING",30:"INTEGER",31:"BOOLEAN",34:"ID",35:"EQUALS",37:"SEP"},
productions_: [0,[3,2],[4,3],[4,1],[4,0],[6,1],[6,2],[8,3],[8,3],[8,1],[8,1],[8,1],[8,1],[11,3],[9,3],[10,3],[12,3],[12,3],[13,3],[13,4],[7,2],[17,3],[17,2],[17,2],[17,1],[17,1],[25,2],[25,1],[28,1],[28,1],[28,1],[28,1],[28,1],[26,1],[32,2],[32,1],[33,3],[33,3],[33,3],[33,3],[33,3],[21,1],[36,3],[36,1]],
performAction: function anonymous(yytext,yyleng,yylineno,yy,yystate,$$,_$) {

var $0 = $$.length - 1;
switch (yystate) {
case 1: return $$[$0-1]; 
break;
case 2: this.$ = new yy.ProgramNode($$[$0-2], $$[$0]); 
break;
case 3: this.$ = new yy.ProgramNode($$[$0]); 
break;
case 4: this.$ = new yy.ProgramNode([]); 
break;
case 5: this.$ = [$$[$0]]; 
break;
case 6: $$[$0-1].push($$[$0]); this.$ = $$[$0-1]; 
break;
case 7: this.$ = new yy.BlockNode($$[$0-2], $$[$0-1].inverse, $$[$0-1], $$[$0]); 
break;
case 8: this.$ = new yy.BlockNode($$[$0-2], $$[$0-1], $$[$0-1].inverse, $$[$0]); 
break;
case 9: this.$ = $$[$0]; 
break;
case 10: this.$ = $$[$0]; 
break;
case 11: this.$ = new yy.ContentNode($$[$0]); 
break;
case 12: this.$ = new yy.CommentNode($$[$0]); 
break;
case 13: this.$ = new yy.MustacheNode($$[$0-1][0], $$[$0-1][1]); 
break;
case 14: this.$ = new yy.MustacheNode($$[$0-1][0], $$[$0-1][1]); 
break;
case 15: this.$ = $$[$0-1]; 
break;
case 16: this.$ = new yy.MustacheNode($$[$0-1][0], $$[$0-1][1]); 
break;
case 17: this.$ = new yy.MustacheNode($$[$0-1][0], $$[$0-1][1], true); 
break;
case 18: this.$ = new yy.PartialNode($$[$0-1]); 
break;
case 19: this.$ = new yy.PartialNode($$[$0-2], $$[$0-1]); 
break;
case 20: 
break;
case 21: this.$ = [[$$[$0-2]].concat($$[$0-1]), $$[$0]]; 
break;
case 22: this.$ = [[$$[$0-1]].concat($$[$0]), null]; 
break;
case 23: this.$ = [[$$[$0-1]], $$[$0]]; 
break;
case 24: this.$ = [[$$[$0]], null]; 
break;
case 25: this.$ = [[new yy.DataNode($$[$0])], null]; 
break;
case 26: $$[$0-1].push($$[$0]); this.$ = $$[$0-1]; 
break;
case 27: this.$ = [$$[$0]]; 
break;
case 28: this.$ = $$[$0]; 
break;
case 29: this.$ = new yy.StringNode($$[$0]); 
break;
case 30: this.$ = new yy.IntegerNode($$[$0]); 
break;
case 31: this.$ = new yy.BooleanNode($$[$0]); 
break;
case 32: this.$ = new yy.DataNode($$[$0]); 
break;
case 33: this.$ = new yy.HashNode($$[$0]); 
break;
case 34: $$[$0-1].push($$[$0]); this.$ = $$[$0-1]; 
break;
case 35: this.$ = [$$[$0]]; 
break;
case 36: this.$ = [$$[$0-2], $$[$0]]; 
break;
case 37: this.$ = [$$[$0-2], new yy.StringNode($$[$0])]; 
break;
case 38: this.$ = [$$[$0-2], new yy.IntegerNode($$[$0])]; 
break;
case 39: this.$ = [$$[$0-2], new yy.BooleanNode($$[$0])]; 
break;
case 40: this.$ = [$$[$0-2], new yy.DataNode($$[$0])]; 
break;
case 41: this.$ = new yy.IdNode($$[$0]); 
break;
case 42: $$[$0-2].push($$[$0]); this.$ = $$[$0-2]; 
break;
case 43: this.$ = [$$[$0]]; 
break;
}
},
table: [{3:1,4:2,5:[2,4],6:3,8:4,9:5,11:6,12:7,13:8,14:[1,9],15:[1,10],16:[1,12],19:[1,11],22:[1,13],23:[1,14],24:[1,15]},{1:[3]},{5:[1,16]},{5:[2,3],7:17,8:18,9:5,11:6,12:7,13:8,14:[1,9],15:[1,10],16:[1,12],19:[1,19],20:[2,3],22:[1,13],23:[1,14],24:[1,15]},{5:[2,5],14:[2,5],15:[2,5],16:[2,5],19:[2,5],20:[2,5],22:[2,5],23:[2,5],24:[2,5]},{4:20,6:3,8:4,9:5,11:6,12:7,13:8,14:[1,9],15:[1,10],16:[1,12],19:[1,11],20:[2,4],22:[1,13],23:[1,14],24:[1,15]},{4:21,6:3,8:4,9:5,11:6,12:7,13:8,14:[1,9],15:[1,10],16:[1,12],19:[1,11],20:[2,4],22:[1,13],23:[1,14],24:[1,15]},{5:[2,9],14:[2,9],15:[2,9],16:[2,9],19:[2,9],20:[2,9],22:[2,9],23:[2,9],24:[2,9]},{5:[2,10],14:[2,10],15:[2,10],16:[2,10],19:[2,10],20:[2,10],22:[2,10],23:[2,10],24:[2,10]},{5:[2,11],14:[2,11],15:[2,11],16:[2,11],19:[2,11],20:[2,11],22:[2,11],23:[2,11],24:[2,11]},{5:[2,12],14:[2,12],15:[2,12],16:[2,12],19:[2,12],20:[2,12],22:[2,12],23:[2,12],24:[2,12]},{17:22,21:23,27:[1,24],34:[1,26],36:25},{17:27,21:23,27:[1,24],34:[1,26],36:25},{17:28,21:23,27:[1,24],34:[1,26],36:25},{17:29,21:23,27:[1,24],34:[1,26],36:25},{21:30,34:[1,26],36:25},{1:[2,1]},{6:31,8:4,9:5,11:6,12:7,13:8,14:[1,9],15:[1,10],16:[1,12],19:[1,11],22:[1,13],23:[1,14],24:[1,15]},{5:[2,6],14:[2,6],15:[2,6],16:[2,6],19:[2,6],20:[2,6],22:[2,6],23:[2,6],24:[2,6]},{17:22,18:[1,32],21:23,27:[1,24],34:[1,26],36:25},{10:33,20:[1,34]},{10:35,20:[1,34]},{18:[1,36]},{18:[2,24],21:41,25:37,26:38,27:[1,45],28:39,29:[1,42],30:[1,43],31:[1,44],32:40,33:46,34:[1,47],36:25},{18:[2,25]},{18:[2,41],27:[2,41],29:[2,41],30:[2,41],31:[2,41],34:[2,41],37:[1,48]},{18:[2,43],27:[2,43],29:[2,43],30:[2,43],31:[2,43],34:[2,43],37:[2,43]},{18:[1,49]},{18:[1,50]},{18:[1,51]},{18:[1,52],21:53,34:[1,26],36:25},{5:[2,2],8:18,9:5,11:6,12:7,13:8,14:[1,9],15:[1,10],16:[1,12],19:[1,11],20:[2,2],22:[1,13],23:[1,14],24:[1,15]},{14:[2,20],15:[2,20],16:[2,20],19:[2,20],22:[2,20],23:[2,20],24:[2,20]},{5:[2,7],14:[2,7],15:[2,7],16:[2,7],19:[2,7],20:[2,7],22:[2,7],23:[2,7],24:[2,7]},{21:54,34:[1,26],36:25},{5:[2,8],14:[2,8],15:[2,8],16:[2,8],19:[2,8],20:[2,8],22:[2,8],23:[2,8],24:[2,8]},{14:[2,14],15:[2,14],16:[2,14],19:[2,14],20:[2,14],22:[2,14],23:[2,14],24:[2,14]},{18:[2,22],21:41,26:55,27:[1,45],28:56,29:[1,42],30:[1,43],31:[1,44],32:40,33:46,34:[1,47],36:25},{18:[2,23]},{18:[2,27],27:[2,27],29:[2,27],30:[2,27],31:[2,27],34:[2,27]},{18:[2,33],33:57,34:[1,58]},{18:[2,28],27:[2,28],29:[2,28],30:[2,28],31:[2,28],34:[2,28]},{18:[2,29],27:[2,29],29:[2,29],30:[2,29],31:[2,29],34:[2,29]},{18:[2,30],27:[2,30],29:[2,30],30:[2,30],31:[2,30],34:[2,30]},{18:[2,31],27:[2,31],29:[2,31],30:[2,31],31:[2,31],34:[2,31]},{18:[2,32],27:[2,32],29:[2,32],30:[2,32],31:[2,32],34:[2,32]},{18:[2,35],34:[2,35]},{18:[2,43],27:[2,43],29:[2,43],30:[2,43],31:[2,43],34:[2,43],35:[1,59],37:[2,43]},{34:[1,60]},{14:[2,13],15:[2,13],16:[2,13],19:[2,13],20:[2,13],22:[2,13],23:[2,13],24:[2,13]},{5:[2,16],14:[2,16],15:[2,16],16:[2,16],19:[2,16],20:[2,16],22:[2,16],23:[2,16],24:[2,16]},{5:[2,17],14:[2,17],15:[2,17],16:[2,17],19:[2,17],20:[2,17],22:[2,17],23:[2,17],24:[2,17]},{5:[2,18],14:[2,18],15:[2,18],16:[2,18],19:[2,18],20:[2,18],22:[2,18],23:[2,18],24:[2,18]},{18:[1,61]},{18:[1,62]},{18:[2,21]},{18:[2,26],27:[2,26],29:[2,26],30:[2,26],31:[2,26],34:[2,26]},{18:[2,34],34:[2,34]},{35:[1,59]},{21:63,27:[1,67],29:[1,64],30:[1,65],31:[1,66],34:[1,26],36:25},{18:[2,42],27:[2,42],29:[2,42],30:[2,42],31:[2,42],34:[2,42],37:[2,42]},{5:[2,19],14:[2,19],15:[2,19],16:[2,19],19:[2,19],20:[2,19],22:[2,19],23:[2,19],24:[2,19]},{5:[2,15],14:[2,15],15:[2,15],16:[2,15],19:[2,15],20:[2,15],22:[2,15],23:[2,15],24:[2,15]},{18:[2,36],34:[2,36]},{18:[2,37],34:[2,37]},{18:[2,38],34:[2,38]},{18:[2,39],34:[2,39]},{18:[2,40],34:[2,40]}],
defaultActions: {16:[2,1],24:[2,25],38:[2,23],55:[2,21]},
parseError: function parseError(str, hash) {
    throw new Error(str);
},
parse: function parse(input) {
    var self = this, stack = [0], vstack = [null], lstack = [], table = this.table, yytext = "", yylineno = 0, yyleng = 0, recovering = 0, TERROR = 2, EOF = 1;
    this.lexer.setInput(input);
    this.lexer.yy = this.yy;
    this.yy.lexer = this.lexer;
    this.yy.parser = this;
    if (typeof this.lexer.yylloc == "undefined")
        this.lexer.yylloc = {};
    var yyloc = this.lexer.yylloc;
    lstack.push(yyloc);
    var ranges = this.lexer.options && this.lexer.options.ranges;
    if (typeof this.yy.parseError === "function")
        this.parseError = this.yy.parseError;
    function popStack(n) {
        stack.length = stack.length - 2 * n;
        vstack.length = vstack.length - n;
        lstack.length = lstack.length - n;
    }
    function lex() {
        var token;
        token = self.lexer.lex() || 1;
        if (typeof token !== "number") {
            token = self.symbols_[token] || token;
        }
        return token;
    }
    var symbol, preErrorSymbol, state, action, a, r, yyval = {}, p, len, newState, expected;
    while (true) {
        state = stack[stack.length - 1];
        if (this.defaultActions[state]) {
            action = this.defaultActions[state];
        } else {
            if (symbol === null || typeof symbol == "undefined") {
                symbol = lex();
            }
            action = table[state] && table[state][symbol];
        }
        if (typeof action === "undefined" || !action.length || !action[0]) {
            var errStr = "";
            if (!recovering) {
                expected = [];
                for (p in table[state])
                    if (this.terminals_[p] && p > 2) {
                        expected.push("'" + this.terminals_[p] + "'");
                    }
                if (this.lexer.showPosition) {
                    errStr = "Parse error on line " + (yylineno + 1) + ":\n" + this.lexer.showPosition() + "\nExpecting " + expected.join(", ") + ", got '" + (this.terminals_[symbol] || symbol) + "'";
                } else {
                    errStr = "Parse error on line " + (yylineno + 1) + ": Unexpected " + (symbol == 1?"end of input":"'" + (this.terminals_[symbol] || symbol) + "'");
                }
                this.parseError(errStr, {text: this.lexer.match, token: this.terminals_[symbol] || symbol, line: this.lexer.yylineno, loc: yyloc, expected: expected});
            }
        }
        if (action[0] instanceof Array && action.length > 1) {
            throw new Error("Parse Error: multiple actions possible at state: " + state + ", token: " + symbol);
        }
        switch (action[0]) {
        case 1:
            stack.push(symbol);
            vstack.push(this.lexer.yytext);
            lstack.push(this.lexer.yylloc);
            stack.push(action[1]);
            symbol = null;
            if (!preErrorSymbol) {
                yyleng = this.lexer.yyleng;
                yytext = this.lexer.yytext;
                yylineno = this.lexer.yylineno;
                yyloc = this.lexer.yylloc;
                if (recovering > 0)
                    recovering--;
            } else {
                symbol = preErrorSymbol;
                preErrorSymbol = null;
            }
            break;
        case 2:
            len = this.productions_[action[1]][1];
            yyval.$ = vstack[vstack.length - len];
            yyval._$ = {first_line: lstack[lstack.length - (len || 1)].first_line, last_line: lstack[lstack.length - 1].last_line, first_column: lstack[lstack.length - (len || 1)].first_column, last_column: lstack[lstack.length - 1].last_column};
            if (ranges) {
                yyval._$.range = [lstack[lstack.length - (len || 1)].range[0], lstack[lstack.length - 1].range[1]];
            }
            r = this.performAction.call(yyval, yytext, yyleng, yylineno, this.yy, action[1], vstack, lstack);
            if (typeof r !== "undefined") {
                return r;
            }
            if (len) {
                stack = stack.slice(0, -1 * len * 2);
                vstack = vstack.slice(0, -1 * len);
                lstack = lstack.slice(0, -1 * len);
            }
            stack.push(this.productions_[action[1]][0]);
            vstack.push(yyval.$);
            lstack.push(yyval._$);
            newState = table[stack[stack.length - 2]][stack[stack.length - 1]];
            stack.push(newState);
            break;
        case 3:
            return true;
        }
    }
    return true;
}
};
/* Jison generated lexer */
var lexer = (function(){
var lexer = ({EOF:1,
parseError:function parseError(str, hash) {
        if (this.yy.parser) {
            this.yy.parser.parseError(str, hash);
        } else {
            throw new Error(str);
        }
    },
setInput:function (input) {
        this._input = input;
        this._more = this._less = this.done = false;
        this.yylineno = this.yyleng = 0;
        this.yytext = this.matched = this.match = '';
        this.conditionStack = ['INITIAL'];
        this.yylloc = {first_line:1,first_column:0,last_line:1,last_column:0};
        if (this.options.ranges) this.yylloc.range = [0,0];
        this.offset = 0;
        return this;
    },
input:function () {
        var ch = this._input[0];
        this.yytext += ch;
        this.yyleng++;
        this.offset++;
        this.match += ch;
        this.matched += ch;
        var lines = ch.match(/(?:\r\n?|\n).*/g);
        if (lines) {
            this.yylineno++;
            this.yylloc.last_line++;
        } else {
            this.yylloc.last_column++;
        }
        if (this.options.ranges) this.yylloc.range[1]++;

        this._input = this._input.slice(1);
        return ch;
    },
unput:function (ch) {
        var len = ch.length;
        var lines = ch.split(/(?:\r\n?|\n)/g);

        this._input = ch + this._input;
        this.yytext = this.yytext.substr(0, this.yytext.length-len-1);
        //this.yyleng -= len;
        this.offset -= len;
        var oldLines = this.match.split(/(?:\r\n?|\n)/g);
        this.match = this.match.substr(0, this.match.length-1);
        this.matched = this.matched.substr(0, this.matched.length-1);

        if (lines.length-1) this.yylineno -= lines.length-1;
        var r = this.yylloc.range;

        this.yylloc = {first_line: this.yylloc.first_line,
          last_line: this.yylineno+1,
          first_column: this.yylloc.first_column,
          last_column: lines ?
              (lines.length === oldLines.length ? this.yylloc.first_column : 0) + oldLines[oldLines.length - lines.length].length - lines[0].length:
              this.yylloc.first_column - len
          };

        if (this.options.ranges) {
            this.yylloc.range = [r[0], r[0] + this.yyleng - len];
        }
        return this;
    },
more:function () {
        this._more = true;
        return this;
    },
less:function (n) {
        this.unput(this.match.slice(n));
    },
pastInput:function () {
        var past = this.matched.substr(0, this.matched.length - this.match.length);
        return (past.length > 20 ? '...':'') + past.substr(-20).replace(/\n/g, "");
    },
upcomingInput:function () {
        var next = this.match;
        if (next.length < 20) {
            next += this._input.substr(0, 20-next.length);
        }
        return (next.substr(0,20)+(next.length > 20 ? '...':'')).replace(/\n/g, "");
    },
showPosition:function () {
        var pre = this.pastInput();
        var c = new Array(pre.length + 1).join("-");
        return pre + this.upcomingInput() + "\n" + c+"^";
    },
next:function () {
        if (this.done) {
            return this.EOF;
        }
        if (!this._input) this.done = true;

        var token,
            match,
            tempMatch,
            index,
            col,
            lines;
        if (!this._more) {
            this.yytext = '';
            this.match = '';
        }
        var rules = this._currentRules();
        for (var i=0;i < rules.length; i++) {
            tempMatch = this._input.match(this.rules[rules[i]]);
            if (tempMatch && (!match || tempMatch[0].length > match[0].length)) {
                match = tempMatch;
                index = i;
                if (!this.options.flex) break;
            }
        }
        if (match) {
            lines = match[0].match(/(?:\r\n?|\n).*/g);
            if (lines) this.yylineno += lines.length;
            this.yylloc = {first_line: this.yylloc.last_line,
                           last_line: this.yylineno+1,
                           first_column: this.yylloc.last_column,
                           last_column: lines ? lines[lines.length-1].length-lines[lines.length-1].match(/\r?\n?/)[0].length : this.yylloc.last_column + match[0].length};
            this.yytext += match[0];
            this.match += match[0];
            this.matches = match;
            this.yyleng = this.yytext.length;
            if (this.options.ranges) {
                this.yylloc.range = [this.offset, this.offset += this.yyleng];
            }
            this._more = false;
            this._input = this._input.slice(match[0].length);
            this.matched += match[0];
            token = this.performAction.call(this, this.yy, this, rules[index],this.conditionStack[this.conditionStack.length-1]);
            if (this.done && this._input) this.done = false;
            if (token) return token;
            else return;
        }
        if (this._input === "") {
            return this.EOF;
        } else {
            return this.parseError('Lexical error on line '+(this.yylineno+1)+'. Unrecognized text.\n'+this.showPosition(),
                    {text: "", token: null, line: this.yylineno});
        }
    },
lex:function lex() {
        var r = this.next();
        if (typeof r !== 'undefined') {
            return r;
        } else {
            return this.lex();
        }
    },
begin:function begin(condition) {
        this.conditionStack.push(condition);
    },
popState:function popState() {
        return this.conditionStack.pop();
    },
_currentRules:function _currentRules() {
        return this.conditions[this.conditionStack[this.conditionStack.length-1]].rules;
    },
topState:function () {
        return this.conditionStack[this.conditionStack.length-2];
    },
pushState:function begin(condition) {
        this.begin(condition);
    }});
lexer.options = {};
lexer.performAction = function anonymous(yy,yy_,$avoiding_name_collisions,YY_START) {

var YYSTATE=YY_START
switch($avoiding_name_collisions) {
case 0:
                                   if(yy_.yytext.slice(-1) !== "\\") this.begin("mu");
                                   if(yy_.yytext.slice(-1) === "\\") yy_.yytext = yy_.yytext.substr(0,yy_.yyleng-1), this.begin("emu");
                                   if(yy_.yytext) return 14;
                                 
break;
case 1: return 14; 
break;
case 2:
                                   if(yy_.yytext.slice(-1) !== "\\") this.popState();
                                   if(yy_.yytext.slice(-1) === "\\") yy_.yytext = yy_.yytext.substr(0,yy_.yyleng-1);
                                   return 14;
                                 
break;
case 3: return 24; 
break;
case 4: return 16; 
break;
case 5: return 20; 
break;
case 6: return 19; 
break;
case 7: return 19; 
break;
case 8: return 23; 
break;
case 9: return 23; 
break;
case 10: yy_.yytext = yy_.yytext.substr(3,yy_.yyleng-5); this.popState(); return 15; 
break;
case 11: return 22; 
break;
case 12: return 35; 
break;
case 13: return 34; 
break;
case 14: return 34; 
break;
case 15: return 37; 
break;
case 16: /*ignore whitespace*/ 
break;
case 17: this.popState(); return 18; 
break;
case 18: this.popState(); return 18; 
break;
case 19: yy_.yytext = yy_.yytext.substr(1,yy_.yyleng-2).replace(/\\"/g,'"'); return 29; 
break;
case 20: yy_.yytext = yy_.yytext.substr(1,yy_.yyleng-2).replace(/\\"/g,'"'); return 29; 
break;
case 21: yy_.yytext = yy_.yytext.substr(1); return 27; 
break;
case 22: return 31; 
break;
case 23: return 31; 
break;
case 24: return 30; 
break;
case 25: return 34; 
break;
case 26: yy_.yytext = yy_.yytext.substr(1, yy_.yyleng-2); return 34; 
break;
case 27: return 'INVALID'; 
break;
case 28: return 5; 
break;
}
};
lexer.rules = [/^(?:[^\x00]*?(?=(\{\{)))/,/^(?:[^\x00]+)/,/^(?:[^\x00]{2,}?(?=(\{\{|$)))/,/^(?:\{\{>)/,/^(?:\{\{#)/,/^(?:\{\{\/)/,/^(?:\{\{\^)/,/^(?:\{\{\s*else\b)/,/^(?:\{\{\{)/,/^(?:\{\{&)/,/^(?:\{\{![\s\S]*?\}\})/,/^(?:\{\{)/,/^(?:=)/,/^(?:\.(?=[} ]))/,/^(?:\.\.)/,/^(?:[\/.])/,/^(?:\s+)/,/^(?:\}\}\})/,/^(?:\}\})/,/^(?:"(\\["]|[^"])*")/,/^(?:'(\\[']|[^'])*')/,/^(?:@[a-zA-Z]+)/,/^(?:true(?=[}\s]))/,/^(?:false(?=[}\s]))/,/^(?:[0-9]+(?=[}\s]))/,/^(?:[a-zA-Z0-9_$-]+(?=[=}\s\/.]))/,/^(?:\[[^\]]*\])/,/^(?:.)/,/^(?:$)/];
lexer.conditions = {"mu":{"rules":[3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28],"inclusive":false},"emu":{"rules":[2],"inclusive":false},"INITIAL":{"rules":[0,1,28],"inclusive":true}};
return lexer;})()
parser.lexer = lexer;
function Parser () { this.yy = {}; }Parser.prototype = parser;parser.Parser = Parser;
return new Parser;
})();
if (typeof require !== 'undefined' && typeof exports !== 'undefined') {
exports.parser = handlebars;
exports.Parser = handlebars.Parser;
exports.parse = function () { return handlebars.parse.apply(handlebars, arguments); }
exports.main = function commonjsMain(args) {
    if (!args[1])
        throw new Error('Usage: '+args[0]+' FILE');
    var source, cwd;
    if (typeof process !== 'undefined') {
        source = require('fs').readFileSync(require('path').resolve(args[1]), "utf8");
    } else {
        source = require("file").path(require("file").cwd()).join(args[1]).read({charset: "utf-8"});
    }
    return exports.parser.parse(source);
}
if (typeof module !== 'undefined' && require.main === module) {
  exports.main(typeof process !== 'undefined' ? process.argv.slice(1) : require("system").args);
}
};
;
// lib/handlebars/compiler/base.js
Handlebars.Parser = handlebars;

Handlebars.parse = function(string) {
  Handlebars.Parser.yy = Handlebars.AST;
  return Handlebars.Parser.parse(string);
};

Handlebars.print = function(ast) {
  return new Handlebars.PrintVisitor().accept(ast);
};

Handlebars.logger = {
  DEBUG: 0, INFO: 1, WARN: 2, ERROR: 3, level: 3,

  // override in the host environment
  log: function(level, str) {}
};

Handlebars.log = function(level, str) { Handlebars.logger.log(level, str); };
;
// lib/handlebars/compiler/ast.js
(function() {

  Handlebars.AST = {};

  Handlebars.AST.ProgramNode = function(statements, inverse) {
    this.type = "program";
    this.statements = statements;
    if(inverse) { this.inverse = new Handlebars.AST.ProgramNode(inverse); }
  };

  Handlebars.AST.MustacheNode = function(rawParams, hash, unescaped) {
    this.type = "mustache";
    this.escaped = !unescaped;
    this.hash = hash;

    var id = this.id = rawParams[0];
    var params = this.params = rawParams.slice(1);

    // a mustache is an eligible helper if:
    // * its id is simple (a single part, not `this` or `..`)
    var eligibleHelper = this.eligibleHelper = id.isSimple;

    // a mustache is definitely a helper if:
    // * it is an eligible helper, and
    // * it has at least one parameter or hash segment
    this.isHelper = eligibleHelper && (params.length || hash);

    // if a mustache is an eligible helper but not a definite
    // helper, it is ambiguous, and will be resolved in a later
    // pass or at runtime.
  };

  Handlebars.AST.PartialNode = function(id, context) {
    this.type    = "partial";

    // TODO: disallow complex IDs

    this.id      = id;
    this.context = context;
  };

  var verifyMatch = function(open, close) {
    if(open.original !== close.original) {
      throw new Handlebars.Exception(open.original + " doesn't match " + close.original);
    }
  };

  Handlebars.AST.BlockNode = function(mustache, program, inverse, close) {
    verifyMatch(mustache.id, close);
    this.type = "block";
    this.mustache = mustache;
    this.program  = program;
    this.inverse  = inverse;

    if (this.inverse && !this.program) {
      this.isInverse = true;
    }
  };

  Handlebars.AST.ContentNode = function(string) {
    this.type = "content";
    this.string = string;
  };

  Handlebars.AST.HashNode = function(pairs) {
    this.type = "hash";
    this.pairs = pairs;
  };

  Handlebars.AST.IdNode = function(parts) {
    this.type = "ID";
    this.original = parts.join(".");

    var dig = [], depth = 0;

    for(var i=0,l=parts.length; i<l; i++) {
      var part = parts[i];

      if(part === "..") { depth++; }
      else if(part === "." || part === "this") { this.isScoped = true; }
      else { dig.push(part); }
    }

    this.parts    = dig;
    this.string   = dig.join('.');
    this.depth    = depth;

    // an ID is simple if it only has one part, and that part is not
    // `..` or `this`.
    this.isSimple = parts.length === 1 && !this.isScoped && depth === 0;
  };

  Handlebars.AST.DataNode = function(id) {
    this.type = "DATA";
    this.id = id;
  };

  Handlebars.AST.StringNode = function(string) {
    this.type = "STRING";
    this.string = string;
  };

  Handlebars.AST.IntegerNode = function(integer) {
    this.type = "INTEGER";
    this.integer = integer;
  };

  Handlebars.AST.BooleanNode = function(bool) {
    this.type = "BOOLEAN";
    this.bool = bool;
  };

  Handlebars.AST.CommentNode = function(comment) {
    this.type = "comment";
    this.comment = comment;
  };

})();;
// lib/handlebars/utils.js
Handlebars.Exception = function(message) {
  var tmp = Error.prototype.constructor.apply(this, arguments);

  for (var p in tmp) {
    if (tmp.hasOwnProperty(p)) { this[p] = tmp[p]; }
  }

  this.message = tmp.message;
};
Handlebars.Exception.prototype = new Error();

// Build out our basic SafeString type
Handlebars.SafeString = function(string) {
  this.string = string;
};
Handlebars.SafeString.prototype.toString = function() {
  return this.string.toString();
};

(function() {
  var escape = {
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': "&quot;",
    "'": "&#x27;",
    "`": "&#x60;"
  };

  var badChars = /[&<>"'`]/g;
  var possible = /[&<>"'`]/;

  var escapeChar = function(chr) {
    return escape[chr] || "&amp;";
  };

  Handlebars.Utils = {
    escapeExpression: function(string) {
      // don't escape SafeStrings, since they're already safe
      if (string instanceof Handlebars.SafeString) {
        return string.toString();
      } else if (string == null || string === false) {
        return "";
      }

      if(!possible.test(string)) { return string; }
      return string.replace(badChars, escapeChar);
    },

    isEmpty: function(value) {
      if (typeof value === "undefined") {
        return true;
      } else if (value === null) {
        return true;
      } else if (value === false) {
        return true;
      } else if(Object.prototype.toString.call(value) === "[object Array]" && value.length === 0) {
        return true;
      } else {
        return false;
      }
    }
  };
})();;
// lib/handlebars/compiler/compiler.js

/*jshint eqnull:true*/
Handlebars.Compiler = function() {};
Handlebars.JavaScriptCompiler = function() {};

(function(Compiler, JavaScriptCompiler) {
  // the foundHelper register will disambiguate helper lookup from finding a
  // function in a context. This is necessary for mustache compatibility, which
  // requires that context functions in blocks are evaluated by blockHelperMissing,
  // and then proceed as if the resulting value was provided to blockHelperMissing.

  Compiler.prototype = {
    compiler: Compiler,

    disassemble: function() {
      var opcodes = this.opcodes, opcode, out = [], params, param;

      for (var i=0, l=opcodes.length; i<l; i++) {
        opcode = opcodes[i];

        if (opcode.opcode === 'DECLARE') {
          out.push("DECLARE " + opcode.name + "=" + opcode.value);
        } else {
          params = [];
          for (var j=0; j<opcode.args.length; j++) {
            param = opcode.args[j];
            if (typeof param === "string") {
              param = "\"" + param.replace("\n", "\\n") + "\"";
            }
            params.push(param);
          }
          out.push(opcode.opcode + " " + params.join(" "));
        }
      }

      return out.join("\n");
    },

    guid: 0,

    compile: function(program, options) {
      this.children = [];
      this.depths = {list: []};
      this.options = options;

      // These changes will propagate to the other compiler components
      var knownHelpers = this.options.knownHelpers;
      this.options.knownHelpers = {
        'helperMissing': true,
        'blockHelperMissing': true,
        'each': true,
        'if': true,
        'unless': true,
        'with': true,
        'log': true
      };
      if (knownHelpers) {
        for (var name in knownHelpers) {
          this.options.knownHelpers[name] = knownHelpers[name];
        }
      }

      return this.program(program);
    },

    accept: function(node) {
      return this[node.type](node);
    },

    program: function(program) {
      var statements = program.statements, statement;
      this.opcodes = [];

      for(var i=0, l=statements.length; i<l; i++) {
        statement = statements[i];
        this[statement.type](statement);
      }
      this.isSimple = l === 1;

      this.depths.list = this.depths.list.sort(function(a, b) {
        return a - b;
      });

      return this;
    },

    compileProgram: function(program) {
      var result = new this.compiler().compile(program, this.options);
      var guid = this.guid++, depth;

      this.usePartial = this.usePartial || result.usePartial;

      this.children[guid] = result;

      for(var i=0, l=result.depths.list.length; i<l; i++) {
        depth = result.depths.list[i];

        if(depth < 2) { continue; }
        else { this.addDepth(depth - 1); }
      }

      return guid;
    },

    block: function(block) {
      var mustache = block.mustache,
          program = block.program,
          inverse = block.inverse;

      if (program) {
        program = this.compileProgram(program);
      }

      if (inverse) {
        inverse = this.compileProgram(inverse);
      }

      var type = this.classifyMustache(mustache);

      if (type === "helper") {
        this.helperMustache(mustache, program, inverse);
      } else if (type === "simple") {
        this.simpleMustache(mustache);

        // now that the simple mustache is resolved, we need to
        // evaluate it by executing `blockHelperMissing`
        this.opcode('pushProgram', program);
        this.opcode('pushProgram', inverse);
        this.opcode('pushLiteral', '{}');
        this.opcode('blockValue');
      } else {
        this.ambiguousMustache(mustache, program, inverse);

        // now that the simple mustache is resolved, we need to
        // evaluate it by executing `blockHelperMissing`
        this.opcode('pushProgram', program);
        this.opcode('pushProgram', inverse);
        this.opcode('pushLiteral', '{}');
        this.opcode('ambiguousBlockValue');
      }

      this.opcode('append');
    },

    hash: function(hash) {
      var pairs = hash.pairs, pair, val;

      this.opcode('push', '{}');

      for(var i=0, l=pairs.length; i<l; i++) {
        pair = pairs[i];
        val  = pair[1];

        this.accept(val);
        this.opcode('assignToHash', pair[0]);
      }
    },

    partial: function(partial) {
      var id = partial.id;
      this.usePartial = true;

      if(partial.context) {
        this.ID(partial.context);
      } else {
        this.opcode('push', 'depth0');
      }

      this.opcode('invokePartial', id.original);
      this.opcode('append');
    },

    content: function(content) {
      this.opcode('appendContent', content.string);
    },

    mustache: function(mustache) {
      var options = this.options;
      var type = this.classifyMustache(mustache);

      if (type === "simple") {
        this.simpleMustache(mustache);
      } else if (type === "helper") {
        this.helperMustache(mustache);
      } else {
        this.ambiguousMustache(mustache);
      }

      if(mustache.escaped && !options.noEscape) {
        this.opcode('appendEscaped');
      } else {
        this.opcode('append');
      }
    },

    ambiguousMustache: function(mustache, program, inverse) {
      var id = mustache.id, name = id.parts[0];

      this.opcode('getContext', id.depth);

      this.opcode('pushProgram', program);
      this.opcode('pushProgram', inverse);

      this.opcode('invokeAmbiguous', name);
    },

    simpleMustache: function(mustache, program, inverse) {
      var id = mustache.id;

      if (id.type === 'DATA') {
        this.DATA(id);
      } else if (id.parts.length) {
        this.ID(id);
      } else {
        // Simplified ID for `this`
        this.addDepth(id.depth);
        this.opcode('getContext', id.depth);
        this.opcode('pushContext');
      }

      this.opcode('resolvePossibleLambda');
    },

    helperMustache: function(mustache, program, inverse) {
      var params = this.setupFullMustacheParams(mustache, program, inverse),
          name = mustache.id.parts[0];

      if (this.options.knownHelpers[name]) {
        this.opcode('invokeKnownHelper', params.length, name);
      } else if (this.knownHelpersOnly) {
        throw new Error("You specified knownHelpersOnly, but used the unknown helper " + name);
      } else {
        this.opcode('invokeHelper', params.length, name);
      }
    },

    ID: function(id) {
      this.addDepth(id.depth);
      this.opcode('getContext', id.depth);

      var name = id.parts[0];
      if (!name) {
        this.opcode('pushContext');
      } else {
        this.opcode('lookupOnContext', id.parts[0]);
      }

      for(var i=1, l=id.parts.length; i<l; i++) {
        this.opcode('lookup', id.parts[i]);
      }
    },

    DATA: function(data) {
      this.options.data = true;
      this.opcode('lookupData', data.id);
    },

    STRING: function(string) {
      this.opcode('pushString', string.string);
    },

    INTEGER: function(integer) {
      this.opcode('pushLiteral', integer.integer);
    },

    BOOLEAN: function(bool) {
      this.opcode('pushLiteral', bool.bool);
    },

    comment: function() {},

    // HELPERS
    opcode: function(name) {
      this.opcodes.push({ opcode: name, args: [].slice.call(arguments, 1) });
    },

    declare: function(name, value) {
      this.opcodes.push({ opcode: 'DECLARE', name: name, value: value });
    },

    addDepth: function(depth) {
      if(isNaN(depth)) { throw new Error("EWOT"); }
      if(depth === 0) { return; }

      if(!this.depths[depth]) {
        this.depths[depth] = true;
        this.depths.list.push(depth);
      }
    },

    classifyMustache: function(mustache) {
      var isHelper   = mustache.isHelper;
      var isEligible = mustache.eligibleHelper;
      var options    = this.options;

      // if ambiguous, we can possibly resolve the ambiguity now
      if (isEligible && !isHelper) {
        var name = mustache.id.parts[0];

        if (options.knownHelpers[name]) {
          isHelper = true;
        } else if (options.knownHelpersOnly) {
          isEligible = false;
        }
      }

      if (isHelper) { return "helper"; }
      else if (isEligible) { return "ambiguous"; }
      else { return "simple"; }
    },

    pushParams: function(params) {
      var i = params.length, param;

      while(i--) {
        param = params[i];

        if(this.options.stringParams) {
          if(param.depth) {
            this.addDepth(param.depth);
          }

          this.opcode('getContext', param.depth || 0);
          this.opcode('pushStringParam', param.string);
        } else {
          this[param.type](param);
        }
      }
    },

    setupMustacheParams: function(mustache) {
      var params = mustache.params;
      this.pushParams(params);

      if(mustache.hash) {
        this.hash(mustache.hash);
      } else {
        this.opcode('pushLiteral', '{}');
      }

      return params;
    },

    // this will replace setupMustacheParams when we're done
    setupFullMustacheParams: function(mustache, program, inverse) {
      var params = mustache.params;
      this.pushParams(params);

      this.opcode('pushProgram', program);
      this.opcode('pushProgram', inverse);

      if(mustache.hash) {
        this.hash(mustache.hash);
      } else {
        this.opcode('pushLiteral', '{}');
      }

      return params;
    }
  };

  var Literal = function(value) {
    this.value = value;
  };

  JavaScriptCompiler.prototype = {
    // PUBLIC API: You can override these methods in a subclass to provide
    // alternative compiled forms for name lookup and buffering semantics
    nameLookup: function(parent, name, type) {
      if (/^[0-9]+$/.test(name)) {
        return parent + "[" + name + "]";
      } else if (JavaScriptCompiler.isValidJavaScriptVariableName(name)) {
        return parent + "." + name;
      }
      else {
        return parent + "['" + name + "']";
      }
    },

    appendToBuffer: function(string) {
      if (this.environment.isSimple) {
        return "return " + string + ";";
      } else {
        return "buffer += " + string + ";";
      }
    },

    initializeBuffer: function() {
      return this.quotedString("");
    },

    namespace: "Handlebars",
    // END PUBLIC API

    compile: function(environment, options, context, asObject) {
      this.environment = environment;
      this.options = options || {};

      Handlebars.log(Handlebars.logger.DEBUG, this.environment.disassemble() + "\n\n");

      this.name = this.environment.name;
      this.isChild = !!context;
      this.context = context || {
        programs: [],
        aliases: { }
      };

      this.preamble();

      this.stackSlot = 0;
      this.stackVars = [];
      this.registers = { list: [] };
      this.compileStack = [];

      this.compileChildren(environment, options);

      var opcodes = environment.opcodes, opcode;

      this.i = 0;

      for(l=opcodes.length; this.i<l; this.i++) {
        opcode = opcodes[this.i];

        if(opcode.opcode === 'DECLARE') {
          this[opcode.name] = opcode.value;
        } else {
          this[opcode.opcode].apply(this, opcode.args);
        }
      }

      return this.createFunctionContext(asObject);
    },

    nextOpcode: function() {
      var opcodes = this.environment.opcodes, opcode = opcodes[this.i + 1];
      return opcodes[this.i + 1];
    },

    eat: function(opcode) {
      this.i = this.i + 1;
    },

    preamble: function() {
      var out = [];

      if (!this.isChild) {
        var namespace = this.namespace;
        var copies = "helpers = helpers || " + namespace + ".helpers;";
        if (this.environment.usePartial) { copies = copies + " partials = partials || " + namespace + ".partials;"; }
        if (this.options.data) { copies = copies + " data = data || {};"; }
        out.push(copies);
      } else {
        out.push('');
      }

      if (!this.environment.isSimple) {
        out.push(", buffer = " + this.initializeBuffer());
      } else {
        out.push("");
      }

      // track the last context pushed into place to allow skipping the
      // getContext opcode when it would be a noop
      this.lastContext = 0;
      this.source = out;
    },

    createFunctionContext: function(asObject) {
      var locals = this.stackVars.concat(this.registers.list);

      if(locals.length > 0) {
        this.source[1] = this.source[1] + ", " + locals.join(", ");
      }

      // Generate minimizer alias mappings
      if (!this.isChild) {
        var aliases = [];
        for (var alias in this.context.aliases) {
          this.source[1] = this.source[1] + ', ' + alias + '=' + this.context.aliases[alias];
        }
      }

      if (this.source[1]) {
        this.source[1] = "var " + this.source[1].substring(2) + ";";
      }

      // Merge children
      if (!this.isChild) {
        this.source[1] += '\n' + this.context.programs.join('\n') + '\n';
      }

      if (!this.environment.isSimple) {
        this.source.push("return buffer;");
      }

      var params = this.isChild ? ["depth0", "data"] : ["Handlebars", "depth0", "helpers", "partials", "data"];

      for(var i=0, l=this.environment.depths.list.length; i<l; i++) {
        params.push("depth" + this.environment.depths.list[i]);
      }

      if (asObject) {
        params.push(this.source.join("\n  "));

        return Function.apply(this, params);
      } else {
        var functionSource = 'function ' + (this.name || '') + '(' + params.join(',') + ') {\n  ' + this.source.join("\n  ") + '}';
        Handlebars.log(Handlebars.logger.DEBUG, functionSource + "\n\n");
        return functionSource;
      }
    },

    // [blockValue]
    //
    // On stack, before: hash, inverse, program, value
    // On stack, after: return value of blockHelperMissing
    //
    // The purpose of this opcode is to take a block of the form
    // `{{#foo}}...{{/foo}}`, resolve the value of `foo`, and
    // replace it on the stack with the result of properly
    // invoking blockHelperMissing.
    blockValue: function() {
      this.context.aliases.blockHelperMissing = 'helpers.blockHelperMissing';

      var params = ["depth0"];
      this.setupParams(0, params);

      this.replaceStack(function(current) {
        params.splice(1, 0, current);
        return current + " = blockHelperMissing.call(" + params.join(", ") + ")";
      });
    },

    // [ambiguousBlockValue]
    //
    // On stack, before: hash, inverse, program, value
    // Compiler value, before: lastHelper=value of last found helper, if any
    // On stack, after, if no lastHelper: same as [blockValue]
    // On stack, after, if lastHelper: value
    ambiguousBlockValue: function() {
      this.context.aliases.blockHelperMissing = 'helpers.blockHelperMissing';

      var params = ["depth0"];
      this.setupParams(0, params);

      var current = this.topStack();
      params.splice(1, 0, current);

      this.source.push("if (!" + this.lastHelper + ") { " + current + " = blockHelperMissing.call(" + params.join(", ") + "); }");
    },

    // [appendContent]
    //
    // On stack, before: ...
    // On stack, after: ...
    //
    // Appends the string value of `content` to the current buffer
    appendContent: function(content) {
      this.source.push(this.appendToBuffer(this.quotedString(content)));
    },

    // [append]
    //
    // On stack, before: value, ...
    // On stack, after: ...
    //
    // Coerces `value` to a String and appends it to the current buffer.
    //
    // If `value` is truthy, or 0, it is coerced into a string and appended
    // Otherwise, the empty string is appended
    append: function() {
      var local = this.popStack();
      this.source.push("if(" + local + " || " + local + " === 0) { " + this.appendToBuffer(local) + " }");
      if (this.environment.isSimple) {
        this.source.push("else { " + this.appendToBuffer("''") + " }");
      }
    },

    // [appendEscaped]
    //
    // On stack, before: value, ...
    // On stack, after: ...
    //
    // Escape `value` and append it to the buffer
    appendEscaped: function() {
      var opcode = this.nextOpcode(), extra = "";
      this.context.aliases.escapeExpression = 'this.escapeExpression';

      if(opcode && opcode.opcode === 'appendContent') {
        extra = " + " + this.quotedString(opcode.args[0]);
        this.eat(opcode);
      }

      this.source.push(this.appendToBuffer("escapeExpression(" + this.popStack() + ")" + extra));
    },

    // [getContext]
    //
    // On stack, before: ...
    // On stack, after: ...
    // Compiler value, after: lastContext=depth
    //
    // Set the value of the `lastContext` compiler value to the depth
    getContext: function(depth) {
      if(this.lastContext !== depth) {
        this.lastContext = depth;
      }
    },

    // [lookupOnContext]
    //
    // On stack, before: ...
    // On stack, after: currentContext[name], ...
    //
    // Looks up the value of `name` on the current context and pushes
    // it onto the stack.
    lookupOnContext: function(name) {
      this.pushStack(this.nameLookup('depth' + this.lastContext, name, 'context'));
    },

    // [pushContext]
    //
    // On stack, before: ...
    // On stack, after: currentContext, ...
    //
    // Pushes the value of the current context onto the stack.
    pushContext: function() {
      this.pushStackLiteral('depth' + this.lastContext);
    },

    // [resolvePossibleLambda]
    //
    // On stack, before: value, ...
    // On stack, after: resolved value, ...
    //
    // If the `value` is a lambda, replace it on the stack by
    // the return value of the lambda
    resolvePossibleLambda: function() {
      this.context.aliases.functionType = '"function"';

      this.replaceStack(function(current) {
        return "typeof " + current + " === functionType ? " + current + "() : " + current;
      });
    },

    // [lookup]
    //
    // On stack, before: value, ...
    // On stack, after: value[name], ...
    //
    // Replace the value on the stack with the result of looking
    // up `name` on `value`
    lookup: function(name) {
      this.replaceStack(function(current) {
        return current + " == null || " + current + " === false ? " + current + " : " + this.nameLookup(current, name, 'context');
      });
    },

    // [lookupData]
    //
    // On stack, before: ...
    // On stack, after: data[id], ...
    //
    // Push the result of looking up `id` on the current data
    lookupData: function(id) {
      this.pushStack(this.nameLookup('data', id, 'data'));
    },

    // [pushStringParam]
    //
    // On stack, before: ...
    // On stack, after: string, currentContext, ...
    //
    // This opcode is designed for use in string mode, which
    // provides the string value of a parameter along with its
    // depth rather than resolving it immediately.
    pushStringParam: function(string) {
      this.pushStackLiteral('depth' + this.lastContext);
      this.pushString(string);
    },

    // [pushString]
    //
    // On stack, before: ...
    // On stack, after: quotedString(string), ...
    //
    // Push a quoted version of `string` onto the stack
    pushString: function(string) {
      this.pushStackLiteral(this.quotedString(string));
    },

    // [push]
    //
    // On stack, before: ...
    // On stack, after: expr, ...
    //
    // Push an expression onto the stack
    push: function(expr) {
      this.pushStack(expr);
    },

    // [pushLiteral]
    //
    // On stack, before: ...
    // On stack, after: value, ...
    //
    // Pushes a value onto the stack. This operation prevents
    // the compiler from creating a temporary variable to hold
    // it.
    pushLiteral: function(value) {
      this.pushStackLiteral(value);
    },

    // [pushProgram]
    //
    // On stack, before: ...
    // On stack, after: program(guid), ...
    //
    // Push a program expression onto the stack. This takes
    // a compile-time guid and converts it into a runtime-accessible
    // expression.
    pushProgram: function(guid) {
      if (guid != null) {
        this.pushStackLiteral(this.programExpression(guid));
      } else {
        this.pushStackLiteral(null);
      }
    },

    // [invokeHelper]
    //
    // On stack, before: hash, inverse, program, params..., ...
    // On stack, after: result of helper invocation
    //
    // Pops off the helper's parameters, invokes the helper,
    // and pushes the helper's return value onto the stack.
    //
    // If the helper is not found, `helperMissing` is called.
    invokeHelper: function(paramSize, name) {
      this.context.aliases.helperMissing = 'helpers.helperMissing';

      var helper = this.lastHelper = this.setupHelper(paramSize, name);
      this.register('foundHelper', helper.name);

      this.pushStack("foundHelper ? foundHelper.call(" +
        helper.callParams + ") " + ": helperMissing.call(" +
        helper.helperMissingParams + ")");
    },

    // [invokeKnownHelper]
    //
    // On stack, before: hash, inverse, program, params..., ...
    // On stack, after: result of helper invocation
    //
    // This operation is used when the helper is known to exist,
    // so a `helperMissing` fallback is not required.
    invokeKnownHelper: function(paramSize, name) {
      var helper = this.setupHelper(paramSize, name);
      this.pushStack(helper.name + ".call(" + helper.callParams + ")");
    },

    // [invokeAmbiguous]
    //
    // On stack, before: hash, inverse, program, params..., ...
    // On stack, after: result of disambiguation
    //
    // This operation is used when an expression like `{{foo}}`
    // is provided, but we don't know at compile-time whether it
    // is a helper or a path.
    //
    // This operation emits more code than the other options,
    // and can be avoided by passing the `knownHelpers` and
    // `knownHelpersOnly` flags at compile-time.
    invokeAmbiguous: function(name) {
      this.context.aliases.functionType = '"function"';

      this.pushStackLiteral('{}');
      var helper = this.setupHelper(0, name);

      var helperName = this.lastHelper = this.nameLookup('helpers', name, 'helper');
      this.register('foundHelper', helperName);

      var nonHelper = this.nameLookup('depth' + this.lastContext, name, 'context');
      var nextStack = this.nextStack();

      this.source.push('if (foundHelper) { ' + nextStack + ' = foundHelper.call(' + helper.callParams + '); }');
      this.source.push('else { ' + nextStack + ' = ' + nonHelper + '; ' + nextStack + ' = typeof ' + nextStack + ' === functionType ? ' + nextStack + '() : ' + nextStack + '; }');
    },

    // [invokePartial]
    //
    // On stack, before: context, ...
    // On stack after: result of partial invocation
    //
    // This operation pops off a context, invokes a partial with that context,
    // and pushes the result of the invocation back.
    invokePartial: function(name) {
      var params = [this.nameLookup('partials', name, 'partial'), "'" + name + "'", this.popStack(), "helpers", "partials"];

      if (this.options.data) {
        params.push("data");
      }

      this.context.aliases.self = "this";
      this.pushStack("self.invokePartial(" + params.join(", ") + ");");
    },

    // [assignToHash]
    //
    // On stack, before: value, hash, ...
    // On stack, after: hash, ...
    //
    // Pops a value and hash off the stack, assigns `hash[key] = value`
    // and pushes the hash back onto the stack.
    assignToHash: function(key) {
      var value = this.popStack();
      var hash = this.topStack();

      this.source.push(hash + "['" + key + "'] = " + value + ";");
    },

    // HELPERS

    compiler: JavaScriptCompiler,

    compileChildren: function(environment, options) {
      var children = environment.children, child, compiler;

      for(var i=0, l=children.length; i<l; i++) {
        child = children[i];
        compiler = new this.compiler();

        this.context.programs.push('');     // Placeholder to prevent name conflicts for nested children
        var index = this.context.programs.length;
        child.index = index;
        child.name = 'program' + index;
        this.context.programs[index] = compiler.compile(child, options, this.context);
      }
    },

    programExpression: function(guid) {
      this.context.aliases.self = "this";

      if(guid == null) {
        return "self.noop";
      }

      var child = this.environment.children[guid],
          depths = child.depths.list, depth;

      var programParams = [child.index, child.name, "data"];

      for(var i=0, l = depths.length; i<l; i++) {
        depth = depths[i];

        if(depth === 1) { programParams.push("depth0"); }
        else { programParams.push("depth" + (depth - 1)); }
      }

      if(depths.length === 0) {
        return "self.program(" + programParams.join(", ") + ")";
      } else {
        programParams.shift();
        return "self.programWithDepth(" + programParams.join(", ") + ")";
      }
    },

    register: function(name, val) {
      this.useRegister(name);
      this.source.push(name + " = " + val + ";");
    },

    useRegister: function(name) {
      if(!this.registers[name]) {
        this.registers[name] = true;
        this.registers.list.push(name);
      }
    },

    pushStackLiteral: function(item) {
      this.compileStack.push(new Literal(item));
      return item;
    },

    pushStack: function(item) {
      this.source.push(this.incrStack() + " = " + item + ";");
      this.compileStack.push("stack" + this.stackSlot);
      return "stack" + this.stackSlot;
    },

    replaceStack: function(callback) {
      var item = callback.call(this, this.topStack());

      this.source.push(this.topStack() + " = " + item + ";");
      return "stack" + this.stackSlot;
    },

    nextStack: function(skipCompileStack) {
      var name = this.incrStack();
      this.compileStack.push("stack" + this.stackSlot);
      return name;
    },

    incrStack: function() {
      this.stackSlot++;
      if(this.stackSlot > this.stackVars.length) { this.stackVars.push("stack" + this.stackSlot); }
      return "stack" + this.stackSlot;
    },

    popStack: function() {
      var item = this.compileStack.pop();

      if (item instanceof Literal) {
        return item.value;
      } else {
        this.stackSlot--;
        return item;
      }
    },

    topStack: function() {
      var item = this.compileStack[this.compileStack.length - 1];

      if (item instanceof Literal) {
        return item.value;
      } else {
        return item;
      }
    },

    quotedString: function(str) {
      return '"' + str
        .replace(/\\/g, '\\\\')
        .replace(/"/g, '\\"')
        .replace(/\n/g, '\\n')
        .replace(/\r/g, '\\r') + '"';
    },

    setupHelper: function(paramSize, name) {
      var params = [];
      this.setupParams(paramSize, params);
      var foundHelper = this.nameLookup('helpers', name, 'helper');

      return {
        params: params,
        name: foundHelper,
        callParams: ["depth0"].concat(params).join(", "),
        helperMissingParams: ["depth0", this.quotedString(name)].concat(params).join(", ")
      };
    },

    // the params and contexts arguments are passed in arrays
    // to fill in
    setupParams: function(paramSize, params) {
      var options = [], contexts = [], param, inverse, program;

      options.push("hash:" + this.popStack());

      inverse = this.popStack();
      program = this.popStack();

      // Avoid setting fn and inverse if neither are set. This allows
      // helpers to do a check for `if (options.fn)`
      if (program || inverse) {
        if (!program) {
          this.context.aliases.self = "this";
          program = "self.noop";
        }

        if (!inverse) {
         this.context.aliases.self = "this";
          inverse = "self.noop";
        }

        options.push("inverse:" + inverse);
        options.push("fn:" + program);
      }

      for(var i=0; i<paramSize; i++) {
        param = this.popStack();
        params.push(param);

        if(this.options.stringParams) {
          contexts.push(this.popStack());
        }
      }

      if (this.options.stringParams) {
        options.push("contexts:[" + contexts.join(",") + "]");
      }

      if(this.options.data) {
        options.push("data:data");
      }

      params.push("{" + options.join(",") + "}");
      return params.join(", ");
    }
  };

  var reservedWords = (
    "break else new var" +
    " case finally return void" +
    " catch for switch while" +
    " continue function this with" +
    " default if throw" +
    " delete in try" +
    " do instanceof typeof" +
    " abstract enum int short" +
    " boolean export interface static" +
    " byte extends long super" +
    " char final native synchronized" +
    " class float package throws" +
    " const goto private transient" +
    " debugger implements protected volatile" +
    " double import public let yield"
  ).split(" ");

  var compilerWords = JavaScriptCompiler.RESERVED_WORDS = {};

  for(var i=0, l=reservedWords.length; i<l; i++) {
    compilerWords[reservedWords[i]] = true;
  }

  JavaScriptCompiler.isValidJavaScriptVariableName = function(name) {
    if(!JavaScriptCompiler.RESERVED_WORDS[name] && /^[a-zA-Z_$][0-9a-zA-Z_$]+$/.test(name)) {
      return true;
    }
    return false;
  };

})(Handlebars.Compiler, Handlebars.JavaScriptCompiler);

Handlebars.precompile = function(string, options) {
  options = options || {};

  var ast = Handlebars.parse(string);
  var environment = new Handlebars.Compiler().compile(ast, options);
  return new Handlebars.JavaScriptCompiler().compile(environment, options);
};

Handlebars.compile = function(string, options) {
  options = options || {};

  var compiled;
  function compile() {
    var ast = Handlebars.parse(string);
    var environment = new Handlebars.Compiler().compile(ast, options);
    var templateSpec = new Handlebars.JavaScriptCompiler().compile(environment, options, undefined, true);
    return Handlebars.template(templateSpec);
  }

  // Template is only compiled on first use and cached after that point.
  return function(context, options) {
    if (!compiled) {
      compiled = compile();
    }
    return compiled.call(this, context, options);
  };
};
;
// lib/handlebars/runtime.js
Handlebars.VM = {
  template: function(templateSpec) {
    // Just add water
    var container = {
      escapeExpression: Handlebars.Utils.escapeExpression,
      invokePartial: Handlebars.VM.invokePartial,
      programs: [],
      program: function(i, fn, data) {
        var programWrapper = this.programs[i];
        if(data) {
          return Handlebars.VM.program(fn, data);
        } else if(programWrapper) {
          return programWrapper;
        } else {
          programWrapper = this.programs[i] = Handlebars.VM.program(fn);
          return programWrapper;
        }
      },
      programWithDepth: Handlebars.VM.programWithDepth,
      noop: Handlebars.VM.noop
    };

    return function(context, options) {
      options = options || {};
      return templateSpec.call(container, Handlebars, context, options.helpers, options.partials, options.data);
    };
  },

  programWithDepth: function(fn, data, $depth) {
    var args = Array.prototype.slice.call(arguments, 2);

    return function(context, options) {
      options = options || {};

      return fn.apply(this, [context, options.data || data].concat(args));
    };
  },
  program: function(fn, data) {
    return function(context, options) {
      options = options || {};

      return fn(context, options.data || data);
    };
  },
  noop: function() { return ""; },
  invokePartial: function(partial, name, context, helpers, partials, data) {
    var options = { helpers: helpers, partials: partials, data: data };

    if(partial === undefined) {
      throw new Handlebars.Exception("The partial " + name + " could not be found");
    } else if(partial instanceof Function) {
      return partial(context, options);
    } else if (!Handlebars.compile) {
      throw new Handlebars.Exception("The partial " + name + " could not be compiled when running in runtime-only mode");
    } else {
      partials[name] = Handlebars.compile(partial, {data: data !== undefined});
      return partials[name](context, options);
    }
  }
};

Handlebars.template = Handlebars.VM.template;
;
/** @license
 * jQuery Autocomplete plugin 1.1
 *
 * Copyright (c) 2009 JÃ¶rn Zaefferer
 *
 * Dual licensed under the MIT and GPL licenses:
 *   http://www.opensource.org/licenses/mit-license.php
 *   http://www.gnu.org/licenses/gpl.html
 *
 * Revision: $Id: jquery.autocomplete.js 15 2009-08-22 10:30:27Z joern.zaefferer $
 */

;(function($) {
  
$.fn.extend({
  autocomplete: function(urlOrData, options) {
    var isUrl = typeof urlOrData == "string";
    options = $.extend({}, $.Autocompleter.defaults, {
      url: isUrl ? urlOrData : null,
      data: isUrl ? null : urlOrData,
      delay: isUrl ? $.Autocompleter.defaults.delay : 10,
      max: options && !options.scroll ? 10 : 150
    }, options);
    
    // if highlight is set to false, replace it with a do-nothing function
    options.highlight = options.highlight || function(value) { return value; };
    
    // if the formatMatch option is not specified, then use formatItem for backwards compatibility
    options.formatMatch = options.formatMatch || options.formatItem;
    
    return this.each(function() {
      new $.Autocompleter(this, options);
    });
  },
  result: function(handler) {
    return this.bind("result", handler);
  },
  search: function(handler) {
    return this.trigger("search", [handler]);
  },
  flushCache: function() {
    return this.trigger("flushCache");
  },
  setOptions: function(options){
    return this.trigger("setOptions", [options]);
  },
  unautocomplete: function() {
    return this.trigger("unautocomplete");
  }
});

$.Autocompleter = function(input, options) {

  var KEY = {
    UP: 38,
    DOWN: 40,
    DEL: 46,
    TAB: 9,
    RETURN: 13,
    ESC: 27,
    COMMA: 188,
    PAGEUP: 33,
    PAGEDOWN: 34,
    BACKSPACE: 8
  };

  // Create $ object for input element
  var $input = $(input).attr("autocomplete", "off").addClass(options.inputClass);

  var timeout;
  var previousValue = "";
  var cache = $.Autocompleter.Cache(options);
  var hasFocus = 0;
  var lastKeyPressCode;
  var config = {
    mouseDownOnSelect: false
  };
  var select = $.Autocompleter.Select(options, input, selectCurrent, config);
  
  var blockSubmit;
  
  // prevent form submit in opera when selecting with return key
  $.browser.opera && $(input.form).bind("submit.autocomplete", function() {
    if (blockSubmit) {
      blockSubmit = false;
      return false;
    }
  });
  
  // only opera doesn't trigger keydown multiple times while pressed, others don't work with keypress at all
  $input.bind(($.browser.opera ? "keypress" : "keydown") + ".autocomplete", function(event) {
    // a keypress means the input has focus
    // avoids issue where input had focus before the autocomplete was applied
    hasFocus = 1;
    // track last key pressed
    lastKeyPressCode = event.keyCode;
    switch(event.keyCode) {
    
      case KEY.UP:
        event.preventDefault();
        if ( select.visible() ) {
          select.prev();
        } else {
          onChange(0, true);
        }
        break;
        
      case KEY.DOWN:
        event.preventDefault();
        if ( select.visible() ) {
          select.next();
        } else {
          onChange(0, true);
        }
        break;
        
      case KEY.PAGEUP:
        event.preventDefault();
        if ( select.visible() ) {
          select.pageUp();
        } else {
          onChange(0, true);
        }
        break;
        
      case KEY.PAGEDOWN:
        event.preventDefault();
        if ( select.visible() ) {
          select.pageDown();
        } else {
          onChange(0, true);
        }
        break;
      
      // matches also semicolon
      case options.multiple && $.trim(options.multipleSeparator) == "," && KEY.COMMA:
      case KEY.TAB:
      case KEY.RETURN:
        if( selectCurrent() ) {
          // stop default to prevent a form submit, Opera needs special handling
          event.preventDefault();
          blockSubmit = true;
          return false;
        }
        break;
        
      case KEY.ESC:
        select.hide();
        break;
        
      default:
        clearTimeout(timeout);
        timeout = setTimeout(onChange, options.delay);
        break;
    }
  }).focus(function(){
    // track whether the field has focus, we shouldn't process any
    // results if the field no longer has focus
    hasFocus++;
  }).blur(function() {
    hasFocus = 0;
    if (!config.mouseDownOnSelect) {
      hideResults();
    }
  }).click(function() {
    // show select when clicking in a focused field
    if ( hasFocus++ > 1 && !select.visible() ) {
      onChange(0, true);
    }
  }).bind("search", function() {
    // TODO why not just specifying both arguments?
    var fn = (arguments.length > 1) ? arguments[1] : null;
    function findValueCallback(q, data) {
      var result;
      if( data && data.length ) {
        for (var i=0; i < data.length; i++) {
          if( data[i].result.toLowerCase() == q.toLowerCase() ) {
            result = data[i];
            break;
          }
        }
      }
      if( typeof fn == "function" ) fn(result);
      else $input.trigger("result", result && [result.data, result.value]);
    }
    $.each(trimWords($input.val()), function(i, value) {
      request(value, findValueCallback, findValueCallback);
    });
  }).bind("flushCache", function() {
    cache.flush();
  }).bind("setOptions", function() {
    $.extend(options, arguments[1]);
    // if we've updated the data, repopulate
    if ( "data" in arguments[1] )
      cache.populate();
  }).bind("unautocomplete", function() {
    select.unbind();
    $input.unbind();
    $(input.form).unbind(".autocomplete");
  });
  
  
  function selectCurrent() {
    var selected = select.selected();
    if( !selected )
      return false;
    
    var v = selected.result;
    previousValue = v;
    
    if ( options.multiple ) {
      var words = trimWords($input.val());
      if ( words.length > 1 ) {
        var seperator = options.multipleSeparator.length;
        var cursorAt = $(input).selection().start;
        var wordAt, progress = 0;
        $.each(words, function(i, word) {
          progress += word.length;
          if (cursorAt <= progress) {
            wordAt = i;
            return false;
          }
          progress += seperator;
        });
        words[wordAt] = v;
        // TODO this should set the cursor to the right position, but it gets overriden somewhere
        //$.Autocompleter.Selection(input, progress + seperator, progress + seperator);
        v = words.join( options.multipleSeparator );
      }
      v += options.multipleSeparator;
    }
    
    $input.val(v);
    hideResultsNow();
    $input.trigger("result", [selected.data, selected.value]);
    return true;
  }
  
  function onChange(crap, skipPrevCheck) {
    if( lastKeyPressCode == KEY.DEL ) {
      select.hide();
      return;
    }
    
    var currentValue = $input.val();
    
    if ( !skipPrevCheck && currentValue == previousValue )
      return;
    
    previousValue = currentValue;
    
    currentValue = lastWord(currentValue);
    if ( currentValue.length >= options.minChars) {
      $input.addClass(options.loadingClass);
      if (!options.matchCase)
        currentValue = currentValue.toLowerCase();
      request(currentValue, receiveData, hideResultsNow);
    } else {
      stopLoading();
      select.hide();
    }
  };
  
  function trimWords(value) {
    if (!value)
      return [""];
    if (!options.multiple)
      return [$.trim(value)];
    return $.map(value.split(options.multipleSeparator), function(word) {
      return $.trim(value).length ? $.trim(word) : null;
    });
  }
  
  function lastWord(value) {
    if ( !options.multiple )
      return value;
    var words = trimWords(value);
    if (words.length == 1) 
      return words[0];
    var cursorAt = $(input).selection().start;
    if (cursorAt == value.length) {
      words = trimWords(value)
    } else {
      words = trimWords(value.replace(value.substring(cursorAt), ""));
    }
    return words[words.length - 1];
  }
  
  // fills in the input box w/the first match (assumed to be the best match)
  // q: the term entered
  // sValue: the first matching result
  function autoFill(q, sValue){
    // autofill in the complete box w/the first match as long as the user hasn't entered in more data
    // if the last user key pressed was backspace, don't autofill
    if( options.autoFill && (lastWord($input.val()).toLowerCase() == q.toLowerCase()) && lastKeyPressCode != KEY.BACKSPACE ) {
      // fill in the value (keep the case the user has typed)
      $input.val($input.val() + sValue.substring(lastWord(previousValue).length));
      // select the portion of the value not typed by the user (so the next character will erase)
      $(input).selection(previousValue.length, previousValue.length + sValue.length);
    }
  };

  function hideResults() {
    clearTimeout(timeout);
    timeout = setTimeout(hideResultsNow, 200);
  };

  function hideResultsNow() {
    var wasVisible = select.visible();
    select.hide();
    clearTimeout(timeout);
    stopLoading();
    if (options.mustMatch) {
      // call search and run callback
      $input.search(
        function (result){
          // if no value found, clear the input box
          if( !result ) {
            if (options.multiple) {
              var words = trimWords($input.val()).slice(0, -1);
              $input.val( words.join(options.multipleSeparator) + (words.length ? options.multipleSeparator : "") );
            }
            else {
              $input.val( "" );
              $input.trigger("result", null);
            }
          }
        }
      );
    }
  };

  function receiveData(q, data) {
    if ( data && data.length && hasFocus ) {
      stopLoading();
      select.display(data, q);
      autoFill(q, data[0].value);
      select.show();
    } else {
      hideResultsNow();
    }
  };

  function request(term, success, failure) {
    if (!options.matchCase)
      term = term.toLowerCase();
    var data = cache.load(term);
    // recieve the cached data
    if (data && data.length) {
      success(term, data);
    // if an AJAX url has been supplied, try loading the data now
    } else if( (typeof options.url == "string") && (options.url.length > 0) ){
      
      var extraParams = {
        timestamp: +new Date()
      };
      $.each(options.extraParams, function(key, param) {
        extraParams[key] = typeof param == "function" ? param() : param;
      });
      
      $.ajax({
        // try to leverage ajaxQueue plugin to abort previous requests
        mode: "abort",
        // limit abortion to this input
        port: "autocomplete" + input.name,
        dataType: options.dataType,
        url: options.url,
        data: $.extend({
          q: lastWord(term),
          limit: options.max
        }, extraParams),
        success: function(data) {
          var parsed = options.parse && options.parse(data) || parse(data);
          cache.add(term, parsed);
          success(term, parsed);
        }
      });
    } else {
      // if we have a failure, we need to empty the list -- this prevents the the [TAB] key from selecting the last successful match
      select.emptyList();
      failure(term);
    }
  };
  
  function parse(data) {
    var parsed = [];
    var rows = data.split("\n");
    for (var i=0; i < rows.length; i++) {
      var row = $.trim(rows[i]);
      if (row) {
        row = row.split("|");
        parsed[parsed.length] = {
          data: row,
          value: row[0],
          result: options.formatResult && options.formatResult(row, row[0]) || row[0]
        };
      }
    }
    return parsed;
  };

  function stopLoading() {
    $input.removeClass(options.loadingClass);
  };

};

$.Autocompleter.defaults = {
  inputClass: "ac_input",
  resultsClass: "ac_results",
  loadingClass: "ac_loading",
  minChars: 1,
  delay: 400,
  matchCase: false,
  matchSubset: true,
  matchContains: false,
  cacheLength: 10,
  max: 100,
  mustMatch: false,
  extraParams: {},
  selectFirst: true,
  formatItem: function(row) { return row[0]; },
  formatMatch: null,
  autoFill: false,
  width: 0,
  multiple: false,
  multipleSeparator: ", ",
  highlight: function(value, term) {
    return value.replace(new RegExp("(?![^&;]+;)(?!<[^<>]*)(" + term.replace(/([\^\$\(\)\[\]\{\}\*\.\+\?\|\\])/gi, "\\$1") + ")(?![^<>]*>)(?![^&;]+;)", "gi"), "<strong>$1</strong>");
  },
    scroll: true,
    scrollHeight: 180
};

$.Autocompleter.Cache = function(options) {

  var data = {};
  var length = 0;
  
  function matchSubset(s, sub) {
    if (!options.matchCase) 
      s = s.toLowerCase();
    var i = s.indexOf(sub);
    if (options.matchContains == "word"){
      i = s.toLowerCase().search("\\b" + sub.toLowerCase());
    }
    if (i == -1) return false;
    return i == 0 || options.matchContains;
  };
  
  function add(q, value) {
    if (length > options.cacheLength){
      flush();
    }
    if (!data[q]){ 
      length++;
    }
    data[q] = value;
  }
  
  function populate(){
    if( !options.data ) return false;
    // track the matches
    var stMatchSets = {},
      nullData = 0;

    // no url was specified, we need to adjust the cache length to make sure it fits the local data store
    if( !options.url ) options.cacheLength = 1;
    
    // track all options for minChars = 0
    stMatchSets[""] = [];
    
    // loop through the array and create a lookup structure
    for ( var i = 0, ol = options.data.length; i < ol; i++ ) {
      var rawValue = options.data[i];
      // if rawValue is a string, make an array otherwise just reference the array
      rawValue = (typeof rawValue == "string") ? [rawValue] : rawValue;
      
      var value = options.formatMatch(rawValue, i+1, options.data.length);
      if ( value === false )
        continue;
        
      var firstChar = value.charAt(0).toLowerCase();
      // if no lookup array for this character exists, look it up now
      if( !stMatchSets[firstChar] ) 
        stMatchSets[firstChar] = [];

      // if the match is a string
      var row = {
        value: value,
        data: rawValue,
        result: options.formatResult && options.formatResult(rawValue) || value
      };
      
      // push the current match into the set list
      stMatchSets[firstChar].push(row);

      // keep track of minChars zero items
      if ( nullData++ < options.max ) {
        stMatchSets[""].push(row);
      }
    };

    // add the data items to the cache
    $.each(stMatchSets, function(i, value) {
      // increase the cache size
      options.cacheLength++;
      // add to the cache
      add(i, value);
    });
  }
  
  // populate any existing data
  setTimeout(populate, 25);
  
  function flush(){
    data = {};
    length = 0;
  }
  
  return {
    flush: flush,
    add: add,
    populate: populate,
    load: function(q) {
      if (!options.cacheLength || !length)
        return null;
      /* 
       * if dealing w/local data and matchContains than we must make sure
       * to loop through all the data collections looking for matches
       */
      if( !options.url && options.matchContains ){
        // track all matches
        var csub = [];
        // loop through all the data grids for matches
        for( var k in data ){
          // don't search through the stMatchSets[""] (minChars: 0) cache
          // this prevents duplicates
          if( k.length > 0 ){
            var c = data[k];
            $.each(c, function(i, x) {
              // if we've got a match, add it to the array
              if (matchSubset(x.value, q)) {
                csub.push(x);
              }
            });
          }
        }       
        return csub;
      } else 
      // if the exact item exists, use it
      if (data[q]){
        return data[q];
      } else
      if (options.matchSubset) {
        for (var i = q.length - 1; i >= options.minChars; i--) {
          var c = data[q.substr(0, i)];
          if (c) {
            var csub = [];
            $.each(c, function(i, x) {
              if (matchSubset(x.value, q)) {
                csub[csub.length] = x;
              }
            });
            return csub;
          }
        }
      }
      return null;
    }
  };
};

$.Autocompleter.Select = function (options, input, select, config) {
  var CLASSES = {
    ACTIVE: "ac_over"
  };
  
  var listItems,
    active = -1,
    data,
    term = "",
    needsInit = true,
    element,
    list;
  
  // Create results
  function init() {
    if (!needsInit)
      return;
    element = $("<div/>")
    .hide()
    .addClass(options.resultsClass)
    .css("position", "absolute")
    .appendTo(document.body);
  
    list = $("<ul/>").appendTo(element).mouseover( function(event) {
      if(target(event).nodeName && target(event).nodeName.toUpperCase() == 'LI') {
              active = $("li", list).removeClass(CLASSES.ACTIVE).index(target(event));
          $(target(event)).addClass(CLASSES.ACTIVE);            
          }
    }).click(function(event) {
      $(target(event)).addClass(CLASSES.ACTIVE);
      select();
      // TODO provide option to avoid setting focus again after selection? useful for cleanup-on-focus
      input.focus();
      return false;
    }).mousedown(function() {
      config.mouseDownOnSelect = true;
    }).mouseup(function() {
      config.mouseDownOnSelect = false;
    });
    
    if( options.width > 0 )
      element.css("width", options.width);
      
    needsInit = false;
  } 
  
  function target(event) {
    var element = event.target;
    while(element && element.tagName != "LI")
      element = element.parentNode;
    // more fun with IE, sometimes event.target is empty, just ignore it then
    if(!element)
      return [];
    return element;
  }

  function moveSelect(step) {
    listItems.slice(active, active + 1).removeClass(CLASSES.ACTIVE);
    movePosition(step);
        var activeItem = listItems.slice(active, active + 1).addClass(CLASSES.ACTIVE);
        if(options.scroll) {
            var offset = 0;
            listItems.slice(0, active).each(function() {
        offset += this.offsetHeight;
      });
            if((offset + activeItem[0].offsetHeight - list.scrollTop()) > list[0].clientHeight) {
                list.scrollTop(offset + activeItem[0].offsetHeight - list.innerHeight());
            } else if(offset < list.scrollTop()) {
                list.scrollTop(offset);
            }
        }
  };
  
  function movePosition(step) {
    active += step;
    if (active < 0) {
      active = listItems.size() - 1;
    } else if (active >= listItems.size()) {
      active = 0;
    }
  }
  
  function limitNumberOfItems(available) {
    return options.max && options.max < available
      ? options.max
      : available;
  }
  
  function fillList() {
    list.empty();
    var max = limitNumberOfItems(data.length);
    for (var i=0; i < max; i++) {
      if (!data[i])
        continue;
      var formatted = options.formatItem(data[i].data, i+1, max, data[i].value, term);
      if ( formatted === false )
        continue;
      var li = $("<li/>").html( options.highlight(formatted, term) ).addClass(i%2 == 0 ? "ac_even" : "ac_odd").appendTo(list)[0];
      $.data(li, "ac_data", data[i]);
    }
    listItems = list.find("li");
    if ( options.selectFirst ) {
      listItems.slice(0, 1).addClass(CLASSES.ACTIVE);
      active = 0;
    }
    // apply bgiframe if available
    if ( $.fn.bgiframe )
      list.bgiframe();
  }
  
  return {
    display: function(d, q) {
      init();
      data = d;
      term = q;
      fillList();
    },
    next: function() {
      moveSelect(1);
    },
    prev: function() {
      moveSelect(-1);
    },
    pageUp: function() {
      if (active != 0 && active - 8 < 0) {
        moveSelect( -active );
      } else {
        moveSelect(-8);
      }
    },
    pageDown: function() {
      if (active != listItems.size() - 1 && active + 8 > listItems.size()) {
        moveSelect( listItems.size() - 1 - active );
      } else {
        moveSelect(8);
      }
    },
    hide: function() {
      element && element.hide();
      listItems && listItems.removeClass(CLASSES.ACTIVE);
      active = -1;
    },
    visible : function() {
      return element && element.is(":visible");
    },
    current: function() {
      return this.visible() && (listItems.filter("." + CLASSES.ACTIVE)[0] || options.selectFirst && listItems[0]);
    },
    show: function() {
      var offset = $(input).offset();
      element.css({
        width: typeof options.width == "string" || options.width > 0 ? options.width : $(input).width(),
        top: offset.top + input.offsetHeight,
        left: offset.left
      }).show();
            if(options.scroll) {
                list.scrollTop(0);
                list.css({
          maxHeight: options.scrollHeight,
          overflow: 'auto'
        });
        
                if($.browser.msie && typeof document.body.style.maxHeight === "undefined") {
          var listHeight = 0;
          listItems.each(function() {
            listHeight += this.offsetHeight;
          });
          var scrollbarsVisible = listHeight > options.scrollHeight;
                    list.css('height', scrollbarsVisible ? options.scrollHeight : listHeight );
          if (!scrollbarsVisible) {
            // IE doesn't recalculate width when scrollbar disappears
            listItems.width( list.width() - parseInt(listItems.css("padding-left")) - parseInt(listItems.css("padding-right")) );
          }
                }
                
            }
    },
    selected: function() {
      var selected = listItems && listItems.filter("." + CLASSES.ACTIVE).removeClass(CLASSES.ACTIVE);
      return selected && selected.length && $.data(selected[0], "ac_data");
    },
    emptyList: function (){
      list && list.empty();
    },
    unbind: function() {
      element && element.remove();
    }
  };
};

$.fn.selection = function(start, end) {
  if (start !== undefined) {
    return this.each(function() {
      if( this.createTextRange ){
        var selRange = this.createTextRange();
        if (end === undefined || start == end) {
          selRange.move("character", start);
          selRange.select();
        } else {
          selRange.collapse(true);
          selRange.moveStart("character", start);
          selRange.moveEnd("character", end);
          selRange.select();
        }
      } else if( this.setSelectionRange ){
        this.setSelectionRange(start, end);
      } else if( this.selectionStart ){
        this.selectionStart = start;
        this.selectionEnd = end;
      }
    });
  }
  var field = this[0];
  if ( field.createTextRange ) {
    var range = document.selection.createRange(),
      orig = field.value,
      teststring = "<->",
      textLength = range.text.length;
    range.text = teststring;
    var caretAt = field.value.indexOf(teststring);
    field.value = orig;
    this.selection(caretAt, caretAt + textLength);
    return {
      start: caretAt,
      end: caretAt + textLength
    }
  } else if( field.selectionStart !== undefined ){
    return {
      start: field.selectionStart,
      end: field.selectionEnd
    }
  }
};

})(jQuery);
/** @license
 * jQuery Color Animations
 * Copyright 2007 John Resig
 * Released under the MIT and GPL licenses.
 */

(function(jQuery){

    // We override the animation for all of these color styles
    jQuery.each(['backgroundColor', 'borderBottomColor', 'borderLeftColor', 'borderRightColor', 'borderTopColor', 'color', 'outlineColor'], function(i,attr){
        jQuery.fx.step[attr] = function(fx){
            if ( !fx.colorInit ) {
                fx.start = getColor( fx.elem, attr );
                fx.end = getRGB( fx.end );
                fx.colorInit = true;
            }

            fx.elem.style[attr] = "rgb(" + [
                Math.max(Math.min( parseInt((fx.pos * (fx.end[0] - fx.start[0])) + fx.start[0]), 255), 0),
                Math.max(Math.min( parseInt((fx.pos * (fx.end[1] - fx.start[1])) + fx.start[1]), 255), 0),
                Math.max(Math.min( parseInt((fx.pos * (fx.end[2] - fx.start[2])) + fx.start[2]), 255), 0)
            ].join(",") + ")";
        }
    });

    // Color Conversion functions from highlightFade
    // By Blair Mitchelmore
    // http://jquery.offput.ca/highlightFade/

    // Parse strings looking for color tuples [255,255,255]
    function getRGB(color) {
        var result;

        // Check if we're already dealing with an array of colors
        if ( color && color.constructor == Array && color.length == 3 )
            return color;

        // Look for rgb(num,num,num)
        if (result = /rgb\(\s*([0-9]{1,3})\s*,\s*([0-9]{1,3})\s*,\s*([0-9]{1,3})\s*\)/.exec(color))
            return [parseInt(result[1]), parseInt(result[2]), parseInt(result[3])];

        // Look for rgb(num%,num%,num%)
        if (result = /rgb\(\s*([0-9]+(?:\.[0-9]+)?)\%\s*,\s*([0-9]+(?:\.[0-9]+)?)\%\s*,\s*([0-9]+(?:\.[0-9]+)?)\%\s*\)/.exec(color))
            return [parseFloat(result[1])*2.55, parseFloat(result[2])*2.55, parseFloat(result[3])*2.55];

        // Look for #a0b1c2
        if (result = /#([a-fA-F0-9]{2})([a-fA-F0-9]{2})([a-fA-F0-9]{2})/.exec(color))
            return [parseInt(result[1],16), parseInt(result[2],16), parseInt(result[3],16)];

        // Look for #fff
        if (result = /#([a-fA-F0-9])([a-fA-F0-9])([a-fA-F0-9])/.exec(color))
            return [parseInt(result[1]+result[1],16), parseInt(result[2]+result[2],16), parseInt(result[3]+result[3],16)];

        // Look for rgba(0, 0, 0, 0) == transparent in Safari 3
        if (result = /rgba\(0, 0, 0, 0\)/.exec(color))
            return colors['transparent'];

        // Otherwise, we're most likely dealing with a named color
        return colors[jQuery.trim(color).toLowerCase()];
    }

    function getColor(elem, attr) {
        var color;

        do {
            color = jQuery.css(elem, attr);

            // Keep going until we find an element that has color, or we hit the body
            if ( color != '' && color != 'transparent' || jQuery.nodeName(elem, "body") )
                break;

            attr = "backgroundColor";
        } while ( elem = elem.parentNode );

        return getRGB(color);
    };

    // Some named colors to work with
    // From Interface by Stefan Petre
    // http://interface.eyecon.ro/

    var colors = {
        aqua:[0,255,255],
        azure:[240,255,255],
        beige:[245,245,220],
        black:[0,0,0],
        blue:[0,0,255],
        brown:[165,42,42],
        cyan:[0,255,255],
        darkblue:[0,0,139],
        darkcyan:[0,139,139],
        darkgrey:[169,169,169],
        darkgreen:[0,100,0],
        darkkhaki:[189,183,107],
        darkmagenta:[139,0,139],
        darkolivegreen:[85,107,47],
        darkorange:[255,140,0],
        darkorchid:[153,50,204],
        darkred:[139,0,0],
        darksalmon:[233,150,122],
        darkviolet:[148,0,211],
        fuchsia:[255,0,255],
        gold:[255,215,0],
        green:[0,128,0],
        indigo:[75,0,130],
        khaki:[240,230,140],
        lightblue:[173,216,230],
        lightcyan:[224,255,255],
        lightgreen:[144,238,144],
        lightgrey:[211,211,211],
        lightpink:[255,182,193],
        lightyellow:[255,255,224],
        lime:[0,255,0],
        magenta:[255,0,255],
        maroon:[128,0,0],
        navy:[0,0,128],
        olive:[128,128,0],
        orange:[255,165,0],
        pink:[255,192,203],
        purple:[128,0,128],
        violet:[128,0,128],
        red:[255,0,0],
        silver:[192,192,192],
        white:[255,255,255],
        yellow:[255,255,0],
        transparent: [255,255,255]
    };

})(jQuery);
/** @license
 * qTip2 - Pretty powerful tooltips - v2.0.1-94-
 * http://qtip2.com
 *
 * Copyright (c) 2013 Craig Michael Thompson
 * Released under the MIT, GPL licenses
 * http://jquery.org/license
 *
 * Date: Thu May 9 2013 04:46 UTC+0000
 * Plugins: tips modal viewport svg imagemap ie6
 * Styles: basic css3
 */
/*global window: false, jQuery: false, console: false, define: false */

/* Cache window, document, undefined */
(function( window, document, undefined ) {

// Uses AMD or browser globals to create a jQuery plugin.
(function( factory ) {
  "use strict";
  if(typeof define === 'function' && define.amd) {
    define(['jquery'], factory);
  }
  else if(jQuery && !jQuery.fn.qtip) {
    factory(jQuery);
  }
}
(function($) {
  /* This currently causes issues with Safari 6, so for it's disabled */
  //"use strict"; // (Dis)able ECMAScript "strict" operation for this function. See more: http://ejohn.org/blog/ecmascript-5-strict-mode-json-and-more/

;// Munge the primitives - Paul Irish tip
var TRUE = true,
FALSE = false,
NULL = null,

// Common variables
X = 'x', Y = 'y',
WIDTH = 'width',
HEIGHT = 'height',

// Positioning sides
TOP = 'top',
LEFT = 'left',
BOTTOM = 'bottom',
RIGHT = 'right',
CENTER = 'center',

// Position adjustment types
FLIP = 'flip',
FLIPINVERT = 'flipinvert',
SHIFT = 'shift',

// Shortcut vars
QTIP, PROTOTYPE, CORNER, CHECKS,
PLUGINS = {},
NAMESPACE = 'qtip',
ATTR_HAS = 'data-hasqtip',
ATTR_ID = 'data-qtip-id',
WIDGET = ['ui-widget', 'ui-tooltip'],
SELECTOR = '.'+NAMESPACE,
INACTIVE_EVENTS = 'click dblclick mousedown mouseup mousemove mouseleave mouseenter'.split(' '),

CLASS_FIXED = NAMESPACE+'-fixed',
CLASS_DEFAULT = NAMESPACE + '-default',
CLASS_FOCUS = NAMESPACE + '-focus',
CLASS_HOVER = NAMESPACE + '-hover',
CLASS_DISABLED = NAMESPACE+'-disabled',

replaceSuffix = '_replacedByqTip',
oldtitle = 'oldtitle',
trackingBound;

// Browser detection
BROWSER = {
  /*
   * IE version detection
   *
   * Adapted from: http://ajaxian.com/archives/attack-of-the-ie-conditional-comment
   * Credit to James Padolsey for the original implemntation!
   */
  ie: (function(){
    var v = 3, div = document.createElement('div');
    while ((div.innerHTML = '<!--[if gt IE '+(++v)+']><i></i><![endif]-->')) {
      if(!div.getElementsByTagName('i')[0]) { break; }
    }
    return v > 4 ? v : NaN;
  }()),
 
  /*
   * iOS version detection
   */
  iOS: parseFloat( 
    ('' + (/CPU.*OS ([0-9_]{1,5})|(CPU like).*AppleWebKit.*Mobile/i.exec(navigator.userAgent) || [0,''])[1])
    .replace('undefined', '3_2').replace('_', '.').replace('_', '')
  ) || FALSE
};

;function QTip(target, options, id, attr) {
  // Elements and ID
  this.id = id;
  this.target = target;
  this.tooltip = NULL;
  this.elements = elements = { target: target };

  // Internal constructs
  this._id = NAMESPACE + '-' + id;
  this.timers = { img: {} };
  this.options = options;
  this.plugins = {};

  // Cache object
  this.cache = cache = {
    event: {},
    target: $(),
    disabled: FALSE,
    attr: attr,
    onTooltip: FALSE,
    lastClass: ''
  };

  // Set the initial flags
  this.rendered = this.destroyed = this.disabled = this.waiting = 
    this.hiddenDuringWait = this.positioning = this.triggering = FALSE;
}
PROTOTYPE = QTip.prototype;

PROTOTYPE.render = function(show) {
  if(this.rendered || this.destroyed) { return this; } // If tooltip has already been rendered, exit

  var self = this,
    options = this.options,
    cache = this.cache,
    elements = this.elements,
    text = options.content.text,
    title = options.content.title,
    button = options.content.button,
    posOptions = options.position,
    namespace = '.'+this._id+' ',
    deferreds = [];

  // Add ARIA attributes to target
  $.attr(this.target[0], 'aria-describedby', this._id);

  // Create tooltip element
  this.tooltip = elements.tooltip = tooltip = $('<div/>', {
    'id': this._id,
    'class': [ NAMESPACE, CLASS_DEFAULT, options.style.classes, NAMESPACE + '-pos-' + options.position.my.abbrev() ].join(' '),
    'width': options.style.width || '',
    'height': options.style.height || '',
    'tracking': posOptions.target === 'mouse' && posOptions.adjust.mouse,

    /* ARIA specific attributes */
    'role': 'alert',
    'aria-live': 'polite',
    'aria-atomic': FALSE,
    'aria-describedby': this._id + '-content',
    'aria-hidden': TRUE
  })
  .toggleClass(CLASS_DISABLED, this.disabled)
  .attr(ATTR_ID, this.id)
  .data(NAMESPACE, this)
  .appendTo(posOptions.container)
  .append(
    // Create content element
    elements.content = $('<div />', {
      'class': NAMESPACE + '-content',
      'id': this._id + '-content',
      'aria-atomic': TRUE
    })
  );

  // Set rendered flag and prevent redundant reposition calls for now
  this.rendered = -1;
  this.positioning = TRUE;

  // Create title...
  if(title) {
    this._createTitle();

    // Update title only if its not a callback (called in toggle if so)
    if(!$.isFunction(title)) {
      deferreds.push( this._updateTitle(title, FALSE) );
    }
  }

  // Create button
  if(button) { this._createButton(); }

  // Set proper rendered flag and update content if not a callback function (called in toggle)
  if(!$.isFunction(text)) {
    deferreds.push( this._updateContent(text, FALSE) );
  }
  this.rendered = TRUE;

  // Setup widget classes
  this._setWidget();

  // Assign passed event callbacks (before plugins!)
  $.each(options.events, function(name, callback) {
    $.isFunction(callback) && tooltip.bind(
      (name === 'toggle' ? ['tooltipshow','tooltiphide'] : ['tooltip'+name])
        .join(namespace)+namespace, callback
    );
  });

  // Initialize 'render' plugins
  $.each(PLUGINS, function(name) {
    var instance;
    if(this.initialize === 'render' && (instance = this(self))) {
      self.plugins[name] = instance;
    }
  });

  // Assign events
  this._assignEvents();

  // When deferreds have completed
  $.when.apply($, deferreds).then(function() {
    // tooltiprender event
    self._trigger('render');

    // Reset flags
    self.positioning = FALSE;

    // Show tooltip if not hidden during wait period
    if(!self.hiddenDuringWait && (options.show.ready || show)) {
      self.toggle(TRUE, cache.event, FALSE);
    }
    self.hiddenDuringWait = FALSE;
  });

  // Expose API
  QTIP.api[this.id] = this;

  return this;
};

PROTOTYPE.destroy = function(immediate) {
  // Set flag the signify destroy is taking place to plugins
  // and ensure it only gets destroyed once!
  if(this.destroyed) { return this.target; }

  function process() {
    if(this.destroyed) { return; }
    this.destroyed = TRUE;
    
    var target = this.target,
      title = target.attr(oldtitle);

    // Destroy tooltip if rendered
    if(this.rendered) {
      this.tooltip.stop(1,0).find('*').remove().end().remove();
    }

    // Destroy all plugins
    $.each(this.plugins, function(name) {
      this.destroy && this.destroy();
    });

    // Clear timers and remove bound events
    clearTimeout(this.timers.show);
    clearTimeout(this.timers.hide);
    this._unassignEvents();

    // Remove api object and ARIA attributes
    target.removeData(NAMESPACE).removeAttr(ATTR_ID)
      .removeAttr('aria-describedby');

    // Reset old title attribute if removed
    if(this.options.suppress && title) {
      target.attr('title', title).removeAttr(oldtitle);
    }

    // Remove qTip events associated with this API
    this._unbind(target);

    // Remove ID from used id objects, and delete object references
    // for better garbage collection and leak protection
    this.options = this.elements = this.cache = this.timers = 
      this.plugins = this.mouse = NULL;

    // Delete epoxsed API object
    delete QTIP.api[this.id];
  }

  // If an immediate destory is needed
  if(immediate !== TRUE && this.rendered) {
    tooltip.one('tooltiphidden', $.proxy(process, this));
    !this.triggering && this.hide();
  }

  // If we're not in the process of hiding... process
  else { process.call(this); }

  return this.target;
};

;function invalidOpt(a) {
  return a === NULL || $.type(a) !== 'object';
}

function invalidContent(c) {
  return !( $.isFunction(c) || (c && c.attr) || c.length || ($.type(c) === 'object' && (c.jquery || c.then) ));
}

// Option object sanitizer
function sanitizeOptions(opts) {
  var content, text, ajax, once;

  if(invalidOpt(opts)) { return FALSE; }

  if(invalidOpt(opts.metadata)) {
    opts.metadata = { type: opts.metadata };
  }

  if('content' in opts) {
    content = opts.content;

    if(invalidOpt(content) || content.jquery || content.done) {
      content = opts.content = {
        text: (text = invalidContent(content) ? FALSE : content)
      };
    }
    else { text = content.text; }

    // DEPRECATED - Old content.ajax plugin functionality
    // Converts it into the proper Deferred syntax
    if('ajax' in content) {
      ajax = content.ajax;
      once = ajax && ajax.once !== FALSE;
      delete content.ajax;

      content.text = function(event, api) {
        var loading = text || $(this).attr(api.options.content.attr) || 'Loading...',

        deferred = $.ajax(
          $.extend({}, ajax, { context: api })
        )
        .then(ajax.success, NULL, ajax.error)
        .then(function(content) {
          if(content && once) { api.set('content.text', content); }
          return content;
        },
        function(xhr, status, error) {
          if(api.destroyed || xhr.status === 0) { return; }
          api.set('content.text', status + ': ' + error);
        });

        return !once ? (api.set('content.text', loading), deferred) : loading;
      };
    }

    if('title' in content) {
      if(!invalidOpt(content.title)) {
        content.button = content.title.button;
        content.title = content.title.text;
      }

      if(invalidContent(content.title || FALSE)) {
        content.title = FALSE;
      }
    }
  }

  if('position' in opts && invalidOpt(opts.position)) {
    opts.position = { my: opts.position, at: opts.position };
  }

  if('show' in opts && invalidOpt(opts.show)) {
    opts.show = opts.show.jquery ? { target: opts.show } : 
      opts.show === TRUE ? { ready: TRUE } : { event: opts.show };
  }

  if('hide' in opts && invalidOpt(opts.hide)) {
    opts.hide = opts.hide.jquery ? { target: opts.hide } : { event: opts.hide };
  }

  if('style' in opts && invalidOpt(opts.style)) {
    opts.style = { classes: opts.style };
  }

  // Sanitize plugin options
  $.each(PLUGINS, function() {
    this.sanitize && this.sanitize(opts);
  });

  return opts;
}

// Setup builtin .set() option checks
CHECKS = PROTOTYPE.checks = {
  builtin: {
    // Core checks
    '^id$': function(obj, o, v, prev) {
      var id = v === TRUE ? QTIP.nextid : v,
        new_id = NAMESPACE + '-' + id;

      if(id !== FALSE && id.length > 0 && !$('#'+new_id).length) {
        this._id = new_id;

        if(this.rendered) {
          this.tooltip[0].id = this._id;
          this.elements.content[0].id = this._id + '-content';
          this.elements.title[0].id = this._id + '-title';
        }
      }
      else { obj[o] = prev; }
    },
    '^prerender': function(obj, o, v) {
      v && !this.rendered && this.render(this.options.show.ready);
    },

    // Content checks
    '^content.text$': function(obj, o, v) {
      this._updateContent(v);
    },
    '^content.attr$': function(obj, o, v, prev) {
      if(this.options.content.text === this.target.attr(prev)) {
        this._updateContent( this.target.attr(v) );
      }
    },
    '^content.title$': function(obj, o, v) {
      // Remove title if content is null
      if(!v) { return this._removeTitle(); }

      // If title isn't already created, create it now and update
      v && !this.elements.title && this._createTitle();
      this._updateTitle(v);
    },
    '^content.button$': function(obj, o, v) {
      this._updateButton(v);
    },
    '^content.title.(text|button)$': function(obj, o, v) {
      this.set('content.'+o, v); // Backwards title.text/button compat
    }, 

    // Position checks
    '^position.(my|at)$': function(obj, o, v){
      'string' === typeof v && (obj[o] = new CORNER(v, o === 'at'));
    },
    '^position.container$': function(obj, o, v){
      this.tooltip.appendTo(v);
    },

    // Show checks
    '^show.ready$': function(obj, o, v) {
      v && (!this.rendered && this.render(TRUE) || this.toggle(TRUE));
    },

    // Style checks
    '^style.classes$': function(obj, o, v, p) {
      this.tooltip.removeClass(p).addClass(v);
    },
    '^style.width|height': function(obj, o, v) {
      this.tooltip.css(o, v);
    },
    '^style.widget|content.title': function() {
      this._setWidget();
    },
    '^style.def': function(obj, o, v) {
      this.tooltip.toggleClass(CLASS_DEFAULT, !!v);
    },

    // Events check
    '^events.(render|show|move|hide|focus|blur)$': function(obj, o, v) {
      tooltip[($.isFunction(v) ? '' : 'un') + 'bind']('tooltip'+o, v);
    },

    // Properties which require event reassignment
    '^(show|hide|position).(event|target|fixed|inactive|leave|distance|viewport|adjust)': function() {
      var posOptions = this.options.position;

      // Set tracking flag
      tooltip.attr('tracking', posOptions.target === 'mouse' && posOptions.adjust.mouse);

      // Reassign events
      this._unassignEvents();
      this._assignEvents();
    }
  }
};

// Dot notation converter
function convertNotation(options, notation) {
  var i = 0, obj, option = options,

  // Split notation into array
  levels = notation.split('.');

  // Loop through
  while( option = option[ levels[i++] ] ) {
    if(i < levels.length) { obj = option; }
  }

  return [obj || options, levels.pop()];
}

PROTOTYPE.get = function(notation) {
  if(this.destroyed) { return this; }

  var o = convertNotation(this.options, notation.toLowerCase()),
    result = o[0][ o[1] ];

  return result.precedance ? result.string() : result;
};

function setCallback(notation, args) {
  var category, rule, match;

  for(category in this.checks) {
    for(rule in this.checks[category]) {
      if(match = (new RegExp(rule, 'i')).exec(notation)) {
        args.push(match);

        if(category === 'builtin' || this.plugins[category]) {
          this.checks[category][rule].apply(
            this.plugins[category] || this, args
          );
        }
      }
    }
  }
}

var rmove = /^position\.(my|at|adjust|target|container|viewport)|style|content|show\.ready/i,
  rrender = /^prerender|show\.ready/i;

PROTOTYPE.set = function(option, value) {
  if(this.destroyed) { return this; }

  var rendered = this.rendered,
    reposition = FALSE,
    options = this.options,
    checks = this.checks,
    name;

  // Convert singular option/value pair into object form
  if('string' === typeof option) {
    name = option; option = {}; option[name] = value;
  }
  else { option = $.extend({}, option); }

  // Set all of the defined options to their new values
  $.each(option, function(notation, value) {
    if(!rendered && !rrender.test(notation)) {
      delete option[notation]; return;
    }

    // Set new obj value
    var obj = convertNotation(options, notation.toLowerCase()), previous;
    previous = obj[0][ obj[1] ];
    obj[0][ obj[1] ] = value && value.nodeType ? $(value) : value;

    // Also check if we need to reposition
    reposition = rmove.test(notation) || reposition;

    // Set the new params for the callback
    option[notation] = [obj[0], obj[1], value, previous];
  });

  // Re-sanitize options
  sanitizeOptions(options);

  /*
   * Execute any valid callbacks for the set options
   * Also set positioning flag so we don't get loads of redundant repositioning calls.
   */
  this.positioning = TRUE;
  $.each(option, $.proxy(setCallback, this));
  this.positioning = FALSE;

  // Update position if needed
  if(this.rendered && this.tooltip[0].offsetWidth > 0 && reposition) {
    this.reposition( options.position.target === 'mouse' ? NULL : this.cache.event );
  }

  return this;
};

;PROTOTYPE._update = function(content, element, reposition) {
  var self = this,
    cache = this.cache;

  // Make sure tooltip is rendered and content is defined. If not return
  if(!this.rendered || !content) { return FALSE; }

  // Use function to parse content
  if($.isFunction(content)) {
    content = content.call(this.elements.target, cache.event, this) || '';
  }

  // Handle deferred content
  if($.isFunction(content.then)) {
    cache.waiting = TRUE;
    return content.then(function(c) {
      cache.waiting = FALSE;
      return self._update(c, element, reposition);
    }, NULL, function(e) {
      return self._update(e, element, reposition);
    });
  }

  // If content is null... return false
  if(content === FALSE || (!content && content !== '')) { return FALSE; }

  // Append new content if its a DOM array and show it if hidden
  if(content.jquery && content.length > 0) {
    element.empty().append( content.css({ display: 'block' }) );
  }

  // Content is a regular string, insert the new content
  else { element.html(content); }

  // Ensure images have loaded...
  cache.waiting = TRUE;
  return element.imagesLoaded()
    .done(function(images) {
      cache.waiting = FALSE;

      // Reposition if rendered
      if(reposition !== FALSE && self.rendered && self.tooltip[0].offsetWidth > 0) {
        self.reposition(cache.event, !images.length);
      }
    })
    .promise();
};

PROTOTYPE._updateContent = function(content, reposition) {
  this._update(content, this.elements.content, reposition);
};

PROTOTYPE._updateTitle = function(content, reposition) {
  if(this._update(content, this.elements.title, reposition) === FALSE) {
    this._removeTitle(FALSE);
  }
};

PROTOTYPE._createTitle = function()
{
  var elements = this.elements,
    id = this._id+'-title';

  // Destroy previous title element, if present
  if(elements.titlebar) { this._removeTitle(); }

  // Create title bar and title elements
  elements.titlebar = $('<div />', {
    'class': NAMESPACE + '-titlebar ' + (this.options.style.widget ? createWidgetClass('header') : '')
  })
  .append(
    elements.title = $('<div />', {
      'id': id,
      'class': NAMESPACE + '-title',
      'aria-atomic': TRUE
    })
  )
  .insertBefore(elements.content)

  // Button-specific events
  .delegate('.qtip-close', 'mousedown keydown mouseup keyup mouseout', function(event) {
    $(this).toggleClass('ui-state-active ui-state-focus', event.type.substr(-4) === 'down');
  })
  .delegate('.qtip-close', 'mouseover mouseout', function(event){
    $(this).toggleClass('ui-state-hover', event.type === 'mouseover');
  });

  // Create button if enabled
  if(this.options.content.button) { this._createButton(); }
};

PROTOTYPE._removeTitle = function(reposition)
{
  var elements = this.elements;

  if(elements.title) {
    elements.titlebar.remove();
    elements.titlebar = elements.title = elements.button = NULL;

    // Reposition if enabled
    if(reposition !== FALSE) { this.reposition(); }
  }
};

;PROTOTYPE.reposition = function(event, effect) {
  if(!this.rendered || this.positioning || this.destroyed) { return this; }

  // Set positioning flag
  this.positioning = TRUE;

  var cache = this.cache,
    tooltip = this.tooltip,
    posOptions = this.options.position,
    target = posOptions.target,
    my = posOptions.my,
    at = posOptions.at,
    viewport = posOptions.viewport,
    container = posOptions.container,
    adjust = posOptions.adjust,
    method = adjust.method.split(' '),
    elemWidth = tooltip.outerWidth(FALSE),
    elemHeight = tooltip.outerHeight(FALSE),
    targetWidth = 0,
    targetHeight = 0,
    type = tooltip.css('position'),
    position = { left: 0, top: 0 },
    visible = tooltip[0].offsetWidth > 0,
    isScroll = event && event.type === 'scroll',
    win = $(window),
    mouse = this.mouse,
    pluginCalculations, offset;

  // Check if absolute position was passed
  if($.isArray(target) && target.length === 2) {
    // Force left top and set position
    at = { x: LEFT, y: TOP };
    position = { left: target[0], top: target[1] };
  }

  // Check if mouse was the target
  else if(target === 'mouse' && ((event && event.pageX) || cache.event.pageX)) {
    // Force left top to allow flipping
    at = { x: LEFT, y: TOP };

    // Use cached event if one isn't available for positioning
    event = mouse && mouse.pageX && (adjust.mouse || !event || !event.pageX) ? { pageX: mouse.pageX, pageY: mouse.pageY } :
      (event && (event.type === 'resize' || event.type === 'scroll') ? cache.event :
      event && event.pageX && event.type === 'mousemove' ? event :
      (!adjust.mouse || this.options.show.distance) && cache.origin && cache.origin.pageX ? cache.origin :
      event) || event || cache.event || mouse || {};

    // Use event coordinates for position
    if(type !== 'static') { position = container.offset(); }
    position = { left: event.pageX - position.left, top: event.pageY - position.top };

    // Scroll events are a pain, some browsers
    if(adjust.mouse && isScroll) {
      position.left -= mouse.scrollX - win.scrollLeft();
      position.top -= mouse.scrollY - win.scrollTop();
    }
  }

  // Target wasn't mouse or absolute...
  else {
    // Check if event targetting is being used
    if(target === 'event' && event && event.target && event.type !== 'scroll' && event.type !== 'resize') {
      cache.target = $(event.target);
    }
    else if(target !== 'event'){
      cache.target = $(target.jquery ? target : elements.target);
    }
    target = cache.target;

    // Parse the target into a jQuery object and make sure there's an element present
    target = $(target).eq(0);
    if(target.length === 0) { return this; }

    // Check if window or document is the target
    else if(target[0] === document || target[0] === window) {
      targetWidth = BROWSER.iOS ? window.innerWidth : target.width();
      targetHeight = BROWSER.iOS ? window.innerHeight : target.height();

      if(target[0] === window) {
        position = {
          top: (viewport || target).scrollTop(),
          left: (viewport || target).scrollLeft()
        };
      }
    }

    // Check if the target is an <AREA> element
    else if(PLUGINS.imagemap && target.is('area')) {
      pluginCalculations = PLUGINS.imagemap(this, target, at, PLUGINS.viewport ? method : FALSE);
    }

    // Check if the target is an SVG element
    else if(PLUGINS.svg && target[0].ownerSVGElement) {
      pluginCalculations = PLUGINS.svg(this, target, at, PLUGINS.viewport ? method : FALSE);
    }

    // Otherwise use regular jQuery methods
    else {
      targetWidth = target.outerWidth(FALSE);
      targetHeight = target.outerHeight(FALSE);
      position = target.offset();
    }

    // Parse returned plugin values into proper variables
    if(pluginCalculations) {
      targetWidth = pluginCalculations.width;
      targetHeight = pluginCalculations.height;
      offset = pluginCalculations.offset;
      position = pluginCalculations.position;
    }

    // Adjust position to take into account offset parents
    position = this.reposition.offset(target, position, container);

    // Adjust for position.fixed tooltips (and also iOS scroll bug in v3.2-4.0 & v4.3-4.3.2)
    if((BROWSER.iOS > 3.1 && BROWSER.iOS < 4.1) || 
      (BROWSER.iOS >= 4.3 && BROWSER.iOS < 4.33) || 
      (!BROWSER.iOS && type === 'fixed')
    ){
      position.left -= win.scrollLeft();
      position.top -= win.scrollTop();
    }

    // Adjust position relative to target
    if(!pluginCalculations || (pluginCalculations && pluginCalculations.adjustable !== FALSE)) {
      position.left += at.x === RIGHT ? targetWidth : at.x === CENTER ? targetWidth / 2 : 0;
      position.top += at.y === BOTTOM ? targetHeight : at.y === CENTER ? targetHeight / 2 : 0;
    }
  }

  // Adjust position relative to tooltip
  position.left += adjust.x + (my.x === RIGHT ? -elemWidth : my.x === CENTER ? -elemWidth / 2 : 0);
  position.top += adjust.y + (my.y === BOTTOM ? -elemHeight : my.y === CENTER ? -elemHeight / 2 : 0);

  // Use viewport adjustment plugin if enabled
  if(PLUGINS.viewport) {
    position.adjusted = PLUGINS.viewport(
      this, position, posOptions, targetWidth, targetHeight, elemWidth, elemHeight
    );

    // Apply offsets supplied by positioning plugin (if used)
    if(offset && position.adjusted.left) { position.left += offset.left; }
    if(offset && position.adjusted.top) {  position.top += offset.top; }
  }

  // Viewport adjustment is disabled, set values to zero
  else { position.adjusted = { left: 0, top: 0 }; }

  // tooltipmove event
  if(!this._trigger('move', [position, viewport.elem || viewport], event)) { return this; }
  delete position.adjusted;

  // If effect is disabled, target it mouse, no animation is defined or positioning gives NaN out, set CSS directly
  if(effect === FALSE || !visible || isNaN(position.left) || isNaN(position.top) || target === 'mouse' || !$.isFunction(posOptions.effect)) {
    tooltip.css(position);
  }

  // Use custom function if provided
  else if($.isFunction(posOptions.effect)) {
    posOptions.effect.call(tooltip, this, $.extend({}, position));
    tooltip.queue(function(next) {
      // Reset attributes to avoid cross-browser rendering bugs
      $(this).css({ opacity: '', height: '' });
      if(BROWSER.ie) { this.style.removeAttribute('filter'); }

      next();
    });
  }

  // Set positioning flag
  this.positioning = FALSE;

  return this;
};

// Custom (more correct for qTip!) offset calculator
PROTOTYPE.reposition.offset = function(elem, pos, container) {
  if(!container[0]) { return pos; }

  var ownerDocument = $(elem[0].ownerDocument),
    quirks = !!BROWSER.ie && document.compatMode !== 'CSS1Compat',
    parent = container[0],
    scrolled, position, parentOffset, overflow;

  function scroll(e, i) {
    pos.left += i * e.scrollLeft();
    pos.top += i * e.scrollTop();
  }

  // Compensate for non-static containers offset
  do {
    if((position = $.css(parent, 'position')) !== 'static') {
      if(position === 'fixed') {
        parentOffset = parent.getBoundingClientRect();
        scroll(ownerDocument, -1);
      }
      else {
        parentOffset = $(parent).position();
        parentOffset.left += (parseFloat($.css(parent, 'borderLeftWidth')) || 0);
        parentOffset.top += (parseFloat($.css(parent, 'borderTopWidth')) || 0);
      }

      pos.left -= parentOffset.left + (parseFloat($.css(parent, 'marginLeft')) || 0);
      pos.top -= parentOffset.top + (parseFloat($.css(parent, 'marginTop')) || 0);

      // If this is the first parent element with an overflow of "scroll" or "auto", store it
      if(!scrolled && (overflow = $.css(parent, 'overflow')) !== 'hidden' && overflow !== 'visible') { scrolled = $(parent); }
    }
  }
  while((parent = parent.offsetParent));

  // Compensate for containers scroll if it also has an offsetParent (or in IE quirks mode)
  if(scrolled && (scrolled[0] !== ownerDocument[0] || quirks)) {
    scroll(scrolled, 1);
  }

  return pos;
};

// Corner class
var C = (CORNER = PROTOTYPE.reposition.Corner = function(corner, forceY) {
  corner = ('' + corner).replace(/([A-Z])/, ' $1').replace(/middle/gi, CENTER).toLowerCase();
  this.x = (corner.match(/left|right/i) || corner.match(/center/) || ['inherit'])[0].toLowerCase();
  this.y = (corner.match(/top|bottom|center/i) || ['inherit'])[0].toLowerCase();
  this.forceY = !!forceY;

  var f = corner.charAt(0);
  this.precedance = (f === 't' || f === 'b' ? Y : X);
}).prototype;

C.invert = function(z, center) {
  this[z] = this[z] === LEFT ? RIGHT : this[z] === RIGHT ? LEFT : center || this[z];  
};

C.string = function() {
  var x = this.x, y = this.y;
  return x === y ? x : this.precedance === Y || (this.forceY && y !== 'center') ? y+' '+x : x+' '+y;
};

C.abbrev = function() {
  var result = this.string().split(' ');
  return result[0].charAt(0) + (result[1] && result[1].charAt(0) || '');
};

C.clone = function() {
  return new CORNER( this.string(), this.forceY );
};;
PROTOTYPE.toggle = function(state, event) {
  var cache = this.cache,
    options = this.options,
    tooltip = this.tooltip;

  // Try to prevent flickering when tooltip overlaps show element
  if(event) {
    if((/over|enter/).test(event.type) && (/out|leave/).test(cache.event.type) &&
      options.show.target.add(event.target).length === options.show.target.length &&
      tooltip.has(event.relatedTarget).length) {
      return this;
    }

    // Cache event
    cache.event = $.extend({}, event);
  }
    
  // If we're currently waiting and we've just hidden... stop it
  this.waiting && !state && (this.hiddenDuringWait = TRUE);

  // Render the tooltip if showing and it isn't already
  if(!this.rendered) { return state ? this.render(1) : this; }
  else if(this.destroyed) { return this; }

  var type = state ? 'show' : 'hide',
    opts = this.options[type],
    otherOpts = this.options[ !state ? 'show' : 'hide' ],
    posOptions = this.options.position,
    contentOptions = this.options.content,
    width = this.tooltip.css('width'),
    visible = this.tooltip[0].offsetWidth > 0,
    animate = state || opts.target.length === 1,
    sameTarget = !event || opts.target.length < 2 || cache.target[0] === event.target,
    identicalState, allow, showEvent, delay;

  // Detect state if valid one isn't provided
  if((typeof state).search('boolean|number')) { state = !visible; }

  // Check if the tooltip is in an identical state to the new would-be state
  identicalState = !tooltip.is(':animated') && visible === state && sameTarget;

  // Fire tooltip(show/hide) event and check if destroyed
  allow = !identicalState ? !!this._trigger(type, [90]) : NULL;

  // If the user didn't stop the method prematurely and we're showing the tooltip, focus it
  if(allow !== FALSE && state) { this.focus(event); }

  // If the state hasn't changed or the user stopped it, return early
  if(!allow || identicalState) { return this; }

  // Set ARIA hidden attribute
  $.attr(tooltip[0], 'aria-hidden', !!!state);

  // Execute state specific properties
  if(state) {
    // Store show origin coordinates
    cache.origin = $.extend({}, this.mouse);

    // Update tooltip content & title if it's a dynamic function
    if($.isFunction(contentOptions.text)) { this._updateContent(contentOptions.text, FALSE); }
    if($.isFunction(contentOptions.title)) { this._updateTitle(contentOptions.title, FALSE); }

    // Cache mousemove events for positioning purposes (if not already tracking)
    if(!trackingBound && posOptions.target === 'mouse' && posOptions.adjust.mouse) {
      $(document).bind('mousemove.'+NAMESPACE, this._storeMouse);
      trackingBound = TRUE;
    }

    // Update the tooltip position (set width first to prevent viewport/max-width issues)
    if(!width) { tooltip.css('width', tooltip.outerWidth(FALSE)); }
    this.reposition(event, arguments[2]);
    if(!width) { tooltip.css('width', ''); }

    // Hide other tooltips if tooltip is solo
    if(!!opts.solo) {
      (typeof opts.solo === 'string' ? $(opts.solo) : $(SELECTOR, opts.solo))
        .not(tooltip).not(opts.target).qtip('hide', $.Event('tooltipsolo'));
    }
  }
  else {
    // Clear show timer if we're hiding
    clearTimeout(this.timers.show);

    // Remove cached origin on hide
    delete cache.origin;

    // Remove mouse tracking event if not needed (all tracking qTips are hidden)
    if(trackingBound && !$(SELECTOR+'[tracking="true"]:visible', opts.solo).not(tooltip).length) {
      $(document).unbind('mousemove.'+NAMESPACE);
      trackingBound = FALSE;
    }

    // Blur the tooltip
    this.blur(event);
  }

  // Define post-animation, state specific properties
  after = $.proxy(function() {
    if(state) {
      // Prevent antialias from disappearing in IE by removing filter
      if(BROWSER.ie) { tooltip[0].style.removeAttribute('filter'); }

      // Remove overflow setting to prevent tip bugs
      tooltip.css('overflow', '');

      // Autofocus elements if enabled
      if('string' === typeof opts.autofocus) {
        $(this.options.show.autofocus, tooltip).focus();
      }

      // If set, hide tooltip when inactive for delay period
      this.options.show.target.trigger('qtip-'+this.id+'-inactive');
    }
    else {
      // Reset CSS states
      tooltip.css({
        display: '',
        visibility: '',
        opacity: '',
        left: '',
        top: ''
      });
    }

    // tooltipvisible/tooltiphidden events
    this._trigger(state ? 'visible' : 'hidden');
  }, this);

  // If no effect type is supplied, use a simple toggle
  if(opts.effect === FALSE || animate === FALSE) {
    tooltip[ type ]();
    after();
  }

  // Use custom function if provided
  else if($.isFunction(opts.effect)) {
    tooltip.stop(1, 1);
    opts.effect.call(tooltip, this);
    tooltip.queue('fx', function(n) {
      after(); n();
    });
  }

  // Use basic fade function by default
  else { tooltip.fadeTo(90, state ? 1 : 0, after); }

  // If inactive hide method is set, active it
  if(state) { opts.target.trigger('qtip-'+this.id+'-inactive'); }

  return this;
};

PROTOTYPE.show = function(event) { return this.toggle(TRUE, event); };

PROTOTYPE.hide = function(event) { return this.toggle(FALSE, event); };

;PROTOTYPE.focus = function(event) {
  if(!this.rendered || this.destroyed) { return this; }

  var qtips = $(SELECTOR),
    tooltip = this.tooltip,
    curIndex = parseInt(tooltip[0].style.zIndex, 10),
    newIndex = QTIP.zindex + qtips.length,
    focusedElem;

  // Only update the z-index if it has changed and tooltip is not already focused
  if(!tooltip.hasClass(CLASS_FOCUS)) {
    // tooltipfocus event
    if(this._trigger('focus', [newIndex], event)) {
      // Only update z-index's if they've changed
      if(curIndex !== newIndex) {
        // Reduce our z-index's and keep them properly ordered
        qtips.each(function() {
          if(this.style.zIndex > curIndex) {
            this.style.zIndex = this.style.zIndex - 1;
          }
        });

        // Fire blur event for focused tooltip
        qtips.filter('.' + CLASS_FOCUS).qtip('blur', event);
      }

      // Set the new z-index
      tooltip.addClass(CLASS_FOCUS)[0].style.zIndex = newIndex;
    }
  }

  return this;
};

PROTOTYPE.blur = function(event) {
  if(!this.rendered || this.destroyed) { return this; }

  // Set focused status to FALSE
  this.tooltip.removeClass(CLASS_FOCUS);

  // tooltipblur event
  this._trigger('blur', [ this.tooltip.css('zIndex') ], event);

  return this;
};

;PROTOTYPE.disable = function(state) {
  if(this.destroyed) { return this; }

  if('boolean' !== typeof state) {
    state = !(this.tooltip.hasClass(CLASS_DISABLED) || this.disabled);
  }

  if(this.rendered) {
    this.tooltip.toggleClass(CLASS_DISABLED, state)
      .attr('aria-disabled', state);
  }

  this.disabled = !!state;

  return this;
};

PROTOTYPE.enable = function() { return this.disable(FALSE); };

;PROTOTYPE._createButton = function()
{
  var self = this,
    elements = this.elements,
    tooltip = elements.tooltip,
    button = this.options.content.button,
    isString = typeof button === 'string',
    close = isString ? button : 'Close tooltip';

  if(elements.button) { elements.button.remove(); }

  // Use custom button if one was supplied by user, else use default
  if(button.jquery) {
    elements.button = button;
  }
  else {
    elements.button = $('<a />', {
      'class': 'qtip-close ' + (this.options.style.widget ? '' : NAMESPACE+'-icon'),
      'title': close,
      'aria-label': close
    })
    .prepend(
      $('<span />', {
        'class': 'ui-icon ui-icon-close',
        'html': '&times;'
      })
    );
  }

  // Create button and setup attributes
  elements.button.appendTo(elements.titlebar || tooltip)
    .attr('role', 'button')
    .click(function(event) {
      if(!tooltip.hasClass(CLASS_DISABLED)) { self.hide(event); }
      return FALSE;
    });
};

PROTOTYPE._updateButton = function(button)
{
  // Make sure tooltip is rendered and if not, return
  if(!this.rendered) { return FALSE; }

  var elem = this.elements.button;
  if(button) { this._createButton(); }
  else { elem.remove(); }
};

;// Widget class creator
function createWidgetClass(cls) {
  return WIDGET.concat('').join(cls ? '-'+cls+' ' : ' ');
}

// Widget class setter method
PROTOTYPE._setWidget = function()
{
  var on = this.options.style.widget,
    elements = this.elements,
    tooltip = elements.tooltip,
    disabled = tooltip.hasClass(CLASS_DISABLED);

  tooltip.removeClass(CLASS_DISABLED);
  CLASS_DISABLED = on ? 'ui-state-disabled' : 'qtip-disabled';
  tooltip.toggleClass(CLASS_DISABLED, disabled);

  tooltip.toggleClass('ui-helper-reset '+createWidgetClass(), on).toggleClass(CLASS_DEFAULT, this.options.style.def && !on);
  
  if(elements.content) {
    elements.content.toggleClass( createWidgetClass('content'), on);
  }
  if(elements.titlebar) {
    elements.titlebar.toggleClass( createWidgetClass('header'), on);
  }
  if(elements.button) {
    elements.button.toggleClass(NAMESPACE+'-icon', !on);
  }
};;function showMethod(event) {
  if(this.tooltip.hasClass(CLASS_DISABLED)) { return FALSE; }

  // Clear hide timers
  clearTimeout(this.timers.show);
  clearTimeout(this.timers.hide);

  // Start show timer
  var callback = $.proxy(function(){ this.toggle(TRUE, event); }, this);
  if(this.options.show.delay > 0) {
    this.timers.show = setTimeout(callback, this.options.show.delay);
  }
  else{ callback(); }
}

function hideMethod(event) {
  if(this.tooltip.hasClass(CLASS_DISABLED)) { return FALSE; }

  // Check if new target was actually the tooltip element
  var relatedTarget = $(event.relatedTarget),
    ontoTooltip = relatedTarget.closest(SELECTOR)[0] === this.tooltip[0],
    ontoTarget = relatedTarget[0] === this.options.show.target[0];

  // Clear timers and stop animation queue
  clearTimeout(this.timers.show);
  clearTimeout(this.timers.hide);

  // Prevent hiding if tooltip is fixed and event target is the tooltip.
  // Or if mouse positioning is enabled and cursor momentarily overlaps
  if(this !== relatedTarget[0] && 
    (this.options.position.target === 'mouse' && ontoTooltip) || 
    (this.options.hide.fixed && (
      (/mouse(out|leave|move)/).test(event.type) && (ontoTooltip || ontoTarget))
    ))
  {
    try {
      event.preventDefault();
      event.stopImmediatePropagation();
    } catch(e) {}

    return;
  }

  // If tooltip has displayed, start hide timer
  var callback = $.proxy(function(){ this.toggle(FALSE, event); }, this);
  if(this.options.hide.delay > 0) {
    this.timers.hide = setTimeout(callback, this.options.hide.delay);
  }
  else{ callback(); }
}

function inactiveMethod(event) {
  if(this.tooltip.hasClass(CLASS_DISABLED) || !this.options.hide.inactive) { return FALSE; }

  // Clear timer
  clearTimeout(this.timers.inactive);
  this.timers.inactive = setTimeout(
    $.proxy(function(){ this.hide(event); }, this), this.options.hide.inactive
  );
}

function repositionMethod(event) {
  if(this.rendered && this.tooltip[0].offsetWidth > 0) { this.reposition(event); }
}

// Store mouse coordinates
PROTOTYPE._storeMouse = function(event) {
  this.mouse = {
    pageX: event.pageX,
    pageY: event.pageY,
    type: 'mousemove',
    scrollX: window.pageXOffset || document.body.scrollLeft || document.documentElement.scrollLeft,
    scrollY: window.pageYOffset || document.body.scrollTop || document.documentElement.scrollTop
  };
};

// Bind events
PROTOTYPE._bind = function(targets, events, method, suffix, context) {
  var ns = '.' + this._id + (suffix ? '-'+suffix : '');
  events.length && $(targets).bind(
    (events.split ? events : events.join(ns + ' ')) + ns,
    $.proxy(method, context || this)
  );
};
PROTOTYPE._unbind = function(targets, suffix) {
  $(targets).unbind('.' + this._id + (suffix ? '-'+suffix : ''));
};

// Apply common event handlers using delegate (avoids excessive .bind calls!)
var ns = '.'+NAMESPACE;
function delegate(selector, events, method) { 
  $(document.body).delegate(selector,
    (events.split ? events : events.join(ns + ' ')) + ns,
    function() {
      var api = QTIP.api[ $.attr(this, ATTR_ID) ];
      api && method.apply(api, arguments);
    }
  );
}

$(function() {
  delegate(SELECTOR, ['mouseenter', 'mouseleave'], function(event) {
    var state = event.type === 'mouseenter',
      tooltip = $(event.currentTarget),
      target = $(event.relatedTarget || event.target),
      options = this.options;

    // On mouseenter...
    if(state) {
      // Focus the tooltip on mouseenter (z-index stacking)
      this.focus(event);

      // Clear hide timer on tooltip hover to prevent it from closing
      tooltip.hasClass(CLASS_FIXED) && !tooltip.hasClass(CLASS_DISABLED) && clearTimeout(this.timers.hide);
    }

    // On mouseleave...
    else {
      // Hide when we leave the tooltip and not onto the show target (if a hide event is set)
      if(options.position.target === 'mouse' && options.hide.event && 
        options.show.target && !target.closest(options.show.target[0]).length) {
        this.hide(event);
      }
    }

    // Add hover class
    tooltip.toggleClass(CLASS_HOVER, state);
  });

  // Define events which reset the 'inactive' event handler
  delegate('['+ATTR_ID+']', INACTIVE_EVENTS, inactiveMethod);
});

// Event trigger
PROTOTYPE._trigger = function(type, args, event) {
  var callback = $.Event('tooltip'+type);
  callback.originalEvent = (event && $.extend({}, event)) || this.cache.event || NULL;

  this.triggering = TRUE;
  this.tooltip.trigger(callback, [this].concat(args || []));
  this.triggering = FALSE;

  return !callback.isDefaultPrevented();
};

// Event assignment method
PROTOTYPE._assignEvents = function() {
  var options = this.options,
    posOptions = options.position,

    tooltip = this.tooltip,
    showTarget = options.show.target,
    hideTarget = options.hide.target,
    containerTarget = posOptions.container,
    viewportTarget = posOptions.viewport,
    documentTarget = $(document),
    bodyTarget = $(document.body),
    windowTarget = $(window),

    showEvents = options.show.event ? $.trim('' + options.show.event).split(' ') : [],
    hideEvents = options.hide.event ? $.trim('' + options.hide.event).split(' ') : [],
    toggleEvents = [];

  // Hide tooltips when leaving current window/frame (but not select/option elements)
  if(/mouse(out|leave)/i.test(options.hide.event) && options.hide.leave === 'window') {
    this._bind(documentTarget, ['mouseout', 'blur'], function(event) {
      if(!/select|option/.test(event.target.nodeName) && !event.relatedTarget) {
        this.hide(event);
      }
    });
  }

  // Enable hide.fixed by adding appropriate class
  if(options.hide.fixed) {
    hideTarget = hideTarget.add( tooltip.addClass(CLASS_FIXED) );
  }

  /*
   * Make sure hoverIntent functions properly by using mouseleave to clear show timer if
   * mouseenter/mouseout is used for show.event, even if it isn't in the users options.
   */
  else if(/mouse(over|enter)/i.test(options.show.event)) {
    this._bind(hideTarget, 'mouseleave', function() {
      clearTimeout(this.timers.show);
    });
  }

  // Hide tooltip on document mousedown if unfocus events are enabled
  if(('' + options.hide.event).indexOf('unfocus') > -1) {
    this._bind(containerTarget.closest('html'), ['mousedown', 'touchstart'], function(event) {
      var elem = $(event.target),
        enabled = this.rendered && !this.tooltip.hasClass(CLASS_DISABLED) && this.tooltip[0].offsetWidth > 0,
        isAncestor = elem.parents(SELECTOR).filter(this.tooltip[0]).length > 0;

      if(elem[0] !== this.target[0] && elem[0] !== this.tooltip[0] && !isAncestor &&
        !this.target.has(elem[0]).length && enabled
      ) {
        this.hide(event);
      }
    });
  }

  // Check if the tooltip hides when inactive
  if('number' === typeof options.hide.inactive) {
    // Bind inactive method to show target(s) as a custom event
    this._bind(showTarget, 'qtip-'+this.id+'-inactive', inactiveMethod);

    // Define events which reset the 'inactive' event handler
    this._bind(hideTarget.add(tooltip), QTIP.inactiveEvents, inactiveMethod, '-inactive');
  }

  // Apply hide events (and filter identical show events)
  hideEvents = $.map(hideEvents, function(type) {
    var showIndex = $.inArray(type, showEvents);

    // Both events and targets are identical, apply events using a toggle
    if((showIndex > -1 && hideTarget.add(showTarget).length === hideTarget.length)) {
      toggleEvents.push( showEvents.splice( showIndex, 1 )[0] ); return;
    }

    return type;
  });

  // Apply show/hide/toggle events
  this._bind(showTarget, showEvents, showMethod);
  this._bind(hideTarget, hideEvents, hideMethod);
  this._bind(showTarget, toggleEvents, function(event) {
    (this.tooltip[0].offsetWidth > 0 ? hideMethod : showMethod).call(this, event);
  });

  // Check if the tooltip hides when mouse is moved a certain distance
  if('number' === typeof options.hide.distance) {
    this._bind(showTarget.add(tooltip), 'mousemove', function(event) {
      var origin = this.cache.origin || {},
        limit = this.options.hide.distance,
        abs = Math.abs;

      // Check if the movement has gone beyond the limit, and hide it if so
      if(abs(event.pageX - origin.pageX) >= limit || abs(event.pageY - origin.pageY) >= limit) {
        this.hide(event);
      }

      // Cache mousemove coords on show targets
      this._storeMouse(event);
    });
  }

  // Mouse positioning events
  if(posOptions.target === 'mouse') {
    // If mouse adjustment is on...
    if(posOptions.adjust.mouse) {
      // Apply a mouseleave event so we don't get problems with overlapping
      if(options.hide.event) {
        // Track if we're on the target or not
        this._bind(showTarget, ['mouseenter', 'mouseleave'], function(event) {
          this.cache.onTarget = event.type === 'mouseenter';
        });
      }

      // Update tooltip position on mousemove
      this._bind(documentTarget, 'mousemove', function(event) {
        // Update the tooltip position only if the tooltip is visible and adjustment is enabled
        if(this.rendered && this.cache.onTarget && !this.tooltip.hasClass(CLASS_DISABLED) && this.tooltip[0].offsetWidth > 0) {
          this.reposition(event || this.mouse);
        }
      });
    }
  }

  // Adjust positions of the tooltip on window resize if enabled
  if(posOptions.adjust.resize || viewportTarget.length) {
    this._bind( $.event.special.resize ? viewportTarget : windowTarget, 'resize', repositionMethod );
  }

  // Adjust tooltip position on scroll of the window or viewport element if present
  if(posOptions.adjust.scroll) {
    this._bind( windowTarget.add(posOptions.container), 'scroll', repositionMethod );
  }
};

// Un-assignment method
PROTOTYPE._unassignEvents = function() {
  var targets = [
    this.options.show.target[0],
    this.options.hide.target[0],
    this.rendered && this.tooltip[0],
    this.options.position.container[0],
    this.options.position.viewport[0],
    this.options.position.container.closest('html')[0], // unfocus
    window,
    document
  ];

  // Check if tooltip is rendered
  if(this.rendered) {
    this._unbind($([]).pushStack( $.grep(targets, function(i) {
      return typeof i === 'object';
    })));
  }

  // Tooltip isn't yet rendered, remove render event
  else { $(targets[0]).unbind('.'+this._id+'-create'); }
};

;// Initialization method
function init(elem, id, opts)
{
  var obj, posOptions, attr, config, title,

  // Setup element references
  docBody = $(document.body),

  // Use document body instead of document element if needed
  newTarget = elem[0] === document ? docBody : elem,

  // Grab metadata from element if plugin is present
  metadata = (elem.metadata) ? elem.metadata(opts.metadata) : NULL,

  // If metadata type if HTML5, grab 'name' from the object instead, or use the regular data object otherwise
  metadata5 = opts.metadata.type === 'html5' && metadata ? metadata[opts.metadata.name] : NULL,

  // Grab data from metadata.name (or data-qtipopts as fallback) using .data() method,
  html5 = elem.data(opts.metadata.name || 'qtipopts');

  // If we don't get an object returned attempt to parse it manualyl without parseJSON
  try { html5 = typeof html5 === 'string' ? $.parseJSON(html5) : html5; } catch(e) {}

  // Merge in and sanitize metadata
  config = $.extend(TRUE, {}, QTIP.defaults, opts,
    typeof html5 === 'object' ? sanitizeOptions(html5) : NULL,
    sanitizeOptions(metadata5 || metadata));

  // Re-grab our positioning options now we've merged our metadata and set id to passed value
  posOptions = config.position;
  config.id = id;

  // Setup missing content if none is detected
  if('boolean' === typeof config.content.text) {
    attr = elem.attr(config.content.attr);

    // Grab from supplied attribute if available
    if(config.content.attr !== FALSE && attr) { config.content.text = attr; }

    // No valid content was found, abort render
    else { return FALSE; }
  }

  // Setup target options
  if(!posOptions.container.length) { posOptions.container = docBody; }
  if(posOptions.target === FALSE) { posOptions.target = newTarget; }
  if(config.show.target === FALSE) { config.show.target = newTarget; }
  if(config.show.solo === TRUE) { config.show.solo = posOptions.container.closest('body'); }
  if(config.hide.target === FALSE) { config.hide.target = newTarget; }
  if(config.position.viewport === TRUE) { config.position.viewport = posOptions.container; }

  // Ensure we only use a single container
  posOptions.container = posOptions.container.eq(0);

  // Convert position corner values into x and y strings
  posOptions.at = new CORNER(posOptions.at, TRUE);
  posOptions.my = new CORNER(posOptions.my);

  // Destroy previous tooltip if overwrite is enabled, or skip element if not
  if(elem.data(NAMESPACE)) {
    if(config.overwrite) {
      elem.qtip('destroy');
    }
    else if(config.overwrite === FALSE) {
      return FALSE;
    }
  }

  // Add has-qtip attribute
  elem.attr(ATTR_HAS, id);

  // Remove title attribute and store it if present
  if(config.suppress && (title = elem.attr('title'))) {
    // Final attr call fixes event delegatiom and IE default tooltip showing problem
    elem.removeAttr('title').attr(oldtitle, title).attr('title', '');
  }

  // Initialize the tooltip and add API reference
  obj = new QTip(elem, config, id, !!attr);
  elem.data(NAMESPACE, obj);

  // Catch remove/removeqtip events on target element to destroy redundant tooltip
  elem.one('remove.qtip-'+id+' removeqtip.qtip-'+id, function() { 
    var api; if((api = $(this).data(NAMESPACE))) { api.destroy(); }
  });

  return obj;
}

// jQuery $.fn extension method
QTIP = $.fn.qtip = function(options, notation, newValue)
{
  var command = ('' + options).toLowerCase(), // Parse command
    returned = NULL,
    args = $.makeArray(arguments).slice(1),
    event = args[args.length - 1],
    opts = this[0] ? $.data(this[0], NAMESPACE) : NULL;

  // Check for API request
  if((!arguments.length && opts) || command === 'api') {
    return opts;
  }

  // Execute API command if present
  else if('string' === typeof options)
  {
    this.each(function()
    {
      var api = $.data(this, NAMESPACE);
      if(!api) { return TRUE; }

      // Cache the event if possible
      if(event && event.timeStamp) { api.cache.event = event; }

      // Check for specific API commands
      if((command === 'option' || command === 'options') && notation) {
        if($.isPlainObject(notation) || newValue !== undefined) {
          api.set(notation, newValue);
        }
        else {
          returned = api.get(notation);
          return FALSE;
        }
      }

      // Execute API command
      else if(api[command]) {
        api[command].apply(api, args);
      }
    });

    return returned !== NULL ? returned : this;
  }

  // No API commands. validate provided options and setup qTips
  else if('object' === typeof options || !arguments.length)
  {
    opts = sanitizeOptions($.extend(TRUE, {}, options));

    // Bind the qTips
    return QTIP.bind.call(this, opts, event);
  }
};

// $.fn.qtip Bind method
QTIP.bind = function(opts, event)
{
  return this.each(function(i) {
    var options, targets, events, namespace, api, id;

    // Find next available ID, or use custom ID if provided
    id = $.isArray(opts.id) ? opts.id[i] : opts.id;
    id = !id || id === FALSE || id.length < 1 || QTIP.api[id] ? QTIP.nextid++ : id;

    // Setup events namespace
    namespace = '.qtip-'+id+'-create';

    // Initialize the qTip and re-grab newly sanitized options
    api = init($(this), id, opts);
    if(api === FALSE) { return TRUE; }
    else { QTIP.api[id] = api; }
    options = api.options;

    // Initialize plugins
    $.each(PLUGINS, function() {
      if(this.initialize === 'initialize') { this(api); }
    });

    // Determine hide and show targets
    targets = { show: options.show.target, hide: options.hide.target };
    events = {
      show: $.trim('' + options.show.event).replace(/ /g, namespace+' ') + namespace,
      hide: $.trim('' + options.hide.event).replace(/ /g, namespace+' ') + namespace
    };

    /*
     * Make sure hoverIntent functions properly by using mouseleave as a hide event if
     * mouseenter/mouseout is used for show.event, even if it isn't in the users options.
     */
    if(/mouse(over|enter)/i.test(events.show) && !/mouse(out|leave)/i.test(events.hide)) {
      events.hide += ' mouseleave' + namespace;
    }

    /*
     * Also make sure initial mouse targetting works correctly by caching mousemove coords
     * on show targets before the tooltip has rendered.
     *
     * Also set onTarget when triggered to keep mouse tracking working
     */
    targets.show.bind('mousemove'+namespace, function(event) {
      api._storeMouse(event);
      api.cache.onTarget = TRUE;
    });

    // Define hoverIntent function
    function hoverIntent(event) {
      function render() {
        // Cache mouse coords,render and render the tooltip
        api.render(typeof event === 'object' || options.show.ready);

        // Unbind show and hide events
        targets.show.add(targets.hide).unbind(namespace);
      }

      // Only continue if tooltip isn't disabled
      if(api.disabled) { return FALSE; }

      // Cache the event data
      api.cache.event = $.extend({}, event);
      api.cache.target = event ? $(event.target) : [undefined];

      // Start the event sequence
      if(options.show.delay > 0) {
        clearTimeout(api.timers.show);
        api.timers.show = setTimeout(render, options.show.delay);
        if(events.show !== events.hide) {
          targets.hide.bind(events.hide, function() { clearTimeout(api.timers.show); });
        }
      }
      else { render(); }
    }

    // Bind show events to target
    targets.show.bind(events.show, hoverIntent);

    // Prerendering is enabled, create tooltip now
    if(options.show.ready || options.prerender) { hoverIntent(event); }
  });
};

// Populated in render method
QTIP.api = {};;$.each({
  /* Allow other plugins to successfully retrieve the title of an element with a qTip applied */
  attr: function(attr, val) {
    if(this.length) {
      var self = this[0],
        title = 'title',
        api = $.data(self, 'qtip');

      if(attr === title && api && 'object' === typeof api && api.options.suppress) {
        if(arguments.length < 2) {
          return $.attr(self, oldtitle);
        }

        // If qTip is rendered and title was originally used as content, update it
        if(api && api.options.content.attr === title && api.cache.attr) {
          api.set('content.text', val);
        }

        // Use the regular attr method to set, then cache the result
        return this.attr(oldtitle, val);
      }
    }

    return $.fn['attr'+replaceSuffix].apply(this, arguments);
  },

  /* Allow clone to correctly retrieve cached title attributes */
  clone: function(keepData) {
    var titles = $([]), title = 'title',

    // Clone our element using the real clone method
    elems = $.fn['clone'+replaceSuffix].apply(this, arguments);

    // Grab all elements with an oldtitle set, and change it to regular title attribute, if keepData is false
    if(!keepData) {
      elems.filter('['+oldtitle+']').attr('title', function() {
        return $.attr(this, oldtitle);
      })
      .removeAttr(oldtitle);
    }

    return elems;
  }
}, function(name, func) {
  if(!func || $.fn[name+replaceSuffix]) { return TRUE; }

  var old = $.fn[name+replaceSuffix] = $.fn[name];
  $.fn[name] = function() {
    return func.apply(this, arguments) || old.apply(this, arguments);
  };
});

/* Fire off 'removeqtip' handler in $.cleanData if jQuery UI not present (it already does similar).
 * This snippet is taken directly from jQuery UI source code found here:
 *     http://code.jquery.com/ui/jquery-ui-git.js
 */
if(!$.ui) {
  $['cleanData'+replaceSuffix] = $.cleanData;
  $.cleanData = function( elems ) {
    for(var i = 0, elem; (elem = $( elems[i] )).length && elem.attr(ATTR_ID); i++) {
      try { elem.triggerHandler('removeqtip'); }
      catch( e ) {}
    }
    $['cleanData'+replaceSuffix]( elems );
  };
}

;// qTip version
QTIP.version = '2.0.1-94-';

// Base ID for all qTips
QTIP.nextid = 0;

// Inactive events array
QTIP.inactiveEvents = INACTIVE_EVENTS;

// Base z-index for all qTips
QTIP.zindex = 15000;

// Define configuration defaults
QTIP.defaults = {
  prerender: FALSE,
  id: FALSE,
  overwrite: TRUE,
  suppress: TRUE,
  content: {
    text: TRUE,
    attr: 'title',
    title: FALSE,
    button: FALSE
  },
  position: {
    my: 'top left',
    at: 'bottom right',
    target: FALSE,
    container: FALSE,
    viewport: FALSE,
    adjust: {
      x: 0, y: 0,
      mouse: TRUE,
      scroll: TRUE,
      resize: TRUE,
      method: 'flipinvert flipinvert'
    },
    effect: function(api, pos, viewport) {
      $(this).animate(pos, {
        duration: 200,
        queue: FALSE
      });
    }
  },
  show: {
    target: FALSE,
    event: 'mouseenter',
    effect: TRUE,
    delay: 90,
    solo: FALSE,
    ready: FALSE,
    autofocus: FALSE
  },
  hide: {
    target: FALSE,
    event: 'mouseleave',
    effect: TRUE,
    delay: 0,
    fixed: FALSE,
    inactive: FALSE,
    leave: 'window',
    distance: FALSE
  },
  style: {
    classes: '',
    widget: FALSE,
    width: FALSE,
    height: FALSE,
    def: TRUE
  },
  events: {
    render: NULL,
    move: NULL,
    show: NULL,
    hide: NULL,
    toggle: NULL,
    visible: NULL,
    hidden: NULL,
    focus: NULL,
    blur: NULL
  }
};

;var TIP,

// .bind()/.on() namespace
TIPNS = '.qtip-tip',

// Common CSS strings
MARGIN = 'margin',
BORDER = 'border',
COLOR = 'color',
BG_COLOR = 'background-color',
TRANSPARENT = 'transparent',
IMPORTANT = ' !important',

// Check if the browser supports <canvas/> elements
HASCANVAS = !!document.createElement('canvas').getContext,

// Invalid colour values used in parseColours()
INVALID = /rgba?\(0, 0, 0(, 0)?\)|transparent|#123456/i;

// Camel-case method, taken from jQuery source
// http://code.jquery.com/jquery-1.8.0.js
function camel(s) { return s.charAt(0).toUpperCase() + s.slice(1); }

/*
 * Modified from Modernizr's testPropsAll()
 * http://modernizr.com/downloads/modernizr-latest.js
 */
var cssProps = {}, cssPrefixes = ["Webkit", "O", "Moz", "ms"];
function vendorCss(elem, prop) {
  var ucProp = prop.charAt(0).toUpperCase() + prop.slice(1),
    props = (prop + ' ' + cssPrefixes.join(ucProp + ' ') + ucProp).split(' '),
    cur, val, i = 0;

  // If the property has already been mapped...
  if(cssProps[prop]) { return elem.css(cssProps[prop]); }

  while((cur = props[i++])) {
    if((val = elem.css(cur)) !== undefined) {
      return cssProps[prop] = cur, val;
    }
  }
}

// Parse a given elements CSS property into an int
function intCss(elem, prop) {
  return parseInt(vendorCss(elem, prop), 10);
}


// VML creation (for IE only)
if(!HASCANVAS) {
  createVML = function(tag, props, style) {
    return '<qtipvml:'+tag+' xmlns="urn:schemas-microsoft.com:vml" class="qtip-vml" '+(props||'')+
      ' style="behavior: url(#default#VML); '+(style||'')+ '" />';
  };
}



function Tip(qtip, options) {
  this._ns = 'tip';
  this.options = options;
  this.offset = options.offset;
  this.size = [ options.width, options.height ];

  // Initialize
  this.init( (this.qtip = qtip) );
}

$.extend(Tip.prototype, {
  init: function(qtip) {
    var context, tip;

    // Create tip element and prepend to the tooltip
    tip = this.element = qtip.elements.tip = $('<div />', { 'class': NAMESPACE+'-tip' }).prependTo(qtip.tooltip);

    // Create tip drawing element(s)
    if(HASCANVAS) {
      // save() as soon as we create the canvas element so FF2 doesn't bork on our first restore()!
      context = $('<canvas />').appendTo(this.element)[0].getContext('2d');

      // Setup constant parameters
      context.lineJoin = 'miter';
      context.miterLimit = 100;
      context.save();
    }
    else {
      context = createVML('shape', 'coordorigin="0,0"', 'position:absolute;');
      this.element.html(context + context);

      // Prevent mousing down on the tip since it causes problems with .live() handling in IE due to VML
      qtip._bind( $('*', tip).add(tip), ['click', 'mousedown'], function(event) { event.stopPropagation(); }, this._ns);
    }

    // Bind update events
    qtip._bind(qtip.tooltip, 'tooltipmove', this.reposition, this._ns, this);

    // Create it
    this.create();
  },

  _swapDimensions: function() {
    this.size[0] = this.options.height;
    this.size[1] = this.options.width;
  },
  _resetDimensions: function() {
    this.size[0] = this.options.width;
    this.size[1] = this.options.height;
  },

  _useTitle: function(corner) {
    var titlebar = this.qtip.elements.titlebar;
    return titlebar && (
      corner.y === TOP || (corner.y === CENTER && this.element.position().top + (size[1] / 2) + options.offset < titlebar.outerHeight(TRUE))
    );
  },

  _parseCorner: function(corner) {
    var my = this.qtip.options.position.my;

    // Detect corner and mimic properties
    if(corner === FALSE || my === FALSE) {
      corner = FALSE;
    }
    else if(corner === TRUE) {
      corner = new CORNER( my.string() );
    }
    else if(!corner.string) {
      corner = new CORNER(corner);
      corner.fixed = TRUE;
    }

    return corner;
  },

  _parseWidth: function(corner, side, use) {
    var elements = this.qtip.elements,
      prop = BORDER + camel(side) + 'Width';

    return (use ? intCss(use, prop) : (
      intCss(elements.content, prop) ||
      intCss(this._useTitle(corner) && elements.titlebar || elements.content, prop) ||
      intCss(tooltip, prop)
    )) || 0;
  },

  _parseRadius: function(corner) {
    var elements = this.qtip.elements,
      prop = BORDER + camel(corner.y) + camel(corner.x) + 'Radius';

    return BROWSER.ie < 9 ? 0 :
      intCss(this._useTitle(corner) && elements.titlebar || elements.content, prop) || 
      intCss(elements.tooltip, prop) || 0;
  },

  _invalidColour: function(elem, prop, compare) {
    var val = elem.css(prop);
    return !val || (compare && val === elem.css(compare)) || INVALID.test(val) ? FALSE : val;
  },

  _parseColours: function(corner) {
    var elements = this.qtip.elements,
      tip = this.element.css('cssText', ''),
      borderSide = BORDER + camel(corner[ corner.precedance ]) + camel(COLOR),
      colorElem = this._useTitle(corner) && elements.titlebar || elements.content,
      css = this._invalidColour, color = [];

    // Attempt to detect the background colour from various elements, left-to-right precedance
    color[0] = css(tip, BG_COLOR) || css(colorElem, BG_COLOR) || css(elements.content, BG_COLOR) || 
      css(tooltip, BG_COLOR) || tip.css(BG_COLOR);

    // Attempt to detect the correct border side colour from various elements, left-to-right precedance
    color[1] = css(tip, borderSide, COLOR) || css(colorElem, borderSide, COLOR) || 
      css(elements.content, borderSide, COLOR) || css(tooltip, borderSide, COLOR) || tooltip.css(borderSide);

    // Reset background and border colours
    $('*', tip).add(tip).css('cssText', BG_COLOR+':'+TRANSPARENT+IMPORTANT+';'+BORDER+':0'+IMPORTANT+';');

    return color;
  },

  _calculateSize: function(corner) {
    var y = corner.precedance === Y,
      width = this.options[ y ? 'height' : 'width' ],
      height = this.options[ y ? 'width' : 'height' ],
      isCenter = corner.abbrev() === 'c',
      base = width * (isCenter ? 0.5 : 1),
      pow = Math.pow,
      round = Math.round,
      bigHyp, ratio, result,

    smallHyp = Math.sqrt( pow(base, 2) + pow(height, 2) ),
    hyp = [ (this.border / base) * smallHyp, (this.border / height) * smallHyp ];

    hyp[2] = Math.sqrt( pow(hyp[0], 2) - pow(this.border, 2) );
    hyp[3] = Math.sqrt( pow(hyp[1], 2) - pow(this.border, 2) );

    bigHyp = smallHyp + hyp[2] + hyp[3] + (isCenter ? 0 : hyp[0]);
    ratio = bigHyp / smallHyp;

    result = [ round(ratio * width), round(ratio * height) ];

    return y ? result : result.reverse();
  },

  // Tip coordinates calculator
  _calculateTip: function(corner) { 
    var width = this.size[0], height = this.size[1],
      width2 = Math.ceil(width / 2), height2 = Math.ceil(height / 2),

    // Define tip coordinates in terms of height and width values
    tips = {
      br: [0,0,   width,height, width,0],
      bl: [0,0,   width,0,    0,height],
      tr: [0,height,  width,0,    width,height],
      tl: [0,0,   0,height,   width,height],
      tc: [0,height,  width2,0,   width,height],
      bc: [0,0,   width,0,    width2,height],
      rc: [0,0,   width,height2,  0,height],
      lc: [width,0, width,height, 0,height2]
    };

    // Set common side shapes
    tips.lt = tips.br; tips.rt = tips.bl;
    tips.lb = tips.tr; tips.rb = tips.tl;

    return tips[ corner.abbrev() ];
  },

  create: function() {
    // Determine tip corner
    var c = this.corner = (HASCANVAS || BROWSER.ie) && this._parseCorner(this.options.corner);
    
    // If we have a tip corner...
    if( (this.enabled = !!this.corner && this.corner.abbrev() !== 'c') ) {
      // Cache it
      this.qtip.cache.corner = c.clone();

      // Create it
      this.update();
    }

    // Toggle tip element
    this.element.toggle(this.enabled);

    return this.corner;
  },

  update: function(corner, position) {
    if(!this.enabled) { return this; }

    var elements = this.qtip.elements,
      tip = this.element,
      inner = tip.children(),
      options = this.options,
      size = this.size,
      mimic = options.mimic,
      round = Math.round,
      color, precedance, context,
      coords, translate, newSize, border;

    // Re-determine tip if not already set
    if(!corner) { corner = this.qtip.cache.corner || this.corner; }

    // Use corner property if we detect an invalid mimic value
    if(mimic === FALSE) { mimic = corner; }

    // Otherwise inherit mimic properties from the corner object as necessary
    else {
      mimic = new CORNER(mimic);
      mimic.precedance = corner.precedance;

      if(mimic.x === 'inherit') { mimic.x = corner.x; }
      else if(mimic.y === 'inherit') { mimic.y = corner.y; }
      else if(mimic.x === mimic.y) {
        mimic[ corner.precedance ] = corner[ corner.precedance ];
      }
    }
    precedance = mimic.precedance;

    // Ensure the tip width.height are relative to the tip position
    if(corner.precedance === X) { this._swapDimensions(); }
    else { this._resetDimensions(); }

    // Update our colours
    color = this.color = this._parseColours(corner);

    // Detect border width, taking into account colours
    if(color[1] !== TRANSPARENT) {
      // Grab border width
      border = this.border = this._parseWidth(corner, corner[corner.precedance]);

      // If border width isn't zero, use border color as fill (1.0 style tips)
      if(options.border && border < 1) { color[0] = color[1]; }

      // Set border width (use detected border width if options.border is true)
      this.border = border = options.border !== TRUE ? options.border : border;
    }

    // Border colour was invalid, set border to zero
    else { this.border = border = 0; }

    // Calculate coordinates
    coords = this._calculateTip(mimic);

    // Determine tip size
    newSize = this.size = this._calculateSize(corner);
    tip.css({
      width: newSize[0],
      height: newSize[1],
      lineHeight: newSize[1]+'px'
    });

    // Calculate tip translation
    if(corner.precedance === Y) {
      translate = [
        round(mimic.x === LEFT ? border : mimic.x === RIGHT ? newSize[0] - size[0] - border : (newSize[0] - size[0]) / 2),
        round(mimic.y === TOP ? newSize[1] - size[1] : 0)
      ];
    }
    else {
      translate = [
        round(mimic.x === LEFT ? newSize[0] - size[0] : 0),
        round(mimic.y === TOP ? border : mimic.y === BOTTOM ? newSize[1] - size[1] - border : (newSize[1] - size[1]) / 2)
      ];
    }

    // Canvas drawing implementation
    if(HASCANVAS) {
      // Set the canvas size using calculated size
      inner.attr(WIDTH, newSize[0]).attr(HEIGHT, newSize[1]);

      // Grab canvas context and clear/save it
      context = inner[0].getContext('2d');
      context.restore(); context.save();
      context.clearRect(0,0,3000,3000);

      // Set properties
      context.fillStyle = color[0];
      context.strokeStyle = color[1];
      context.lineWidth = border * 2;

      // Draw the tip
      context.translate(translate[0], translate[1]);
      context.beginPath();
      context.moveTo(coords[0], coords[1]);
      context.lineTo(coords[2], coords[3]);
      context.lineTo(coords[4], coords[5]);
      context.closePath();

      // Apply fill and border
      if(border) {
        // Make sure transparent borders are supported by doing a stroke
        // of the background colour before the stroke colour
        if(tooltip.css('background-clip') === 'border-box') {
          context.strokeStyle = color[0];
          context.stroke();
        }
        context.strokeStyle = color[1];
        context.stroke();
      }
      context.fill();
    }

    // VML (IE Proprietary implementation)
    else {
      // Setup coordinates string
      coords = 'm' + coords[0] + ',' + coords[1] + ' l' + coords[2] +
        ',' + coords[3] + ' ' + coords[4] + ',' + coords[5] + ' xe';

      // Setup VML-specific offset for pixel-perfection
      translate[2] = border && /^(r|b)/i.test(corner.string()) ? 
        BROWSER.ie === 8 ? 2 : 1 : 0;

      // Set initial CSS
      inner.css({
        coordsize: (size[0]+border) + ' ' + (size[1]+border),
        antialias: ''+(mimic.string().indexOf(CENTER) > -1),
        left: translate[0],
        top: translate[1],
        width: size[0] + border,
        height: size[1] + border
      })
      .each(function(i) {
        var $this = $(this);

        // Set shape specific attributes
        $this[ $this.prop ? 'prop' : 'attr' ]({
          coordsize: (size[0]+border) + ' ' + (size[1]+border),
          path: coords,
          fillcolor: color[0],
          filled: !!i,
          stroked: !i
        })
        .toggle(!!(border || i));

        // Check if border is enabled and add stroke element
        !i && $this.html( createVML(
          'stroke', 'weight="'+(border*2)+'px" color="'+color[1]+'" miterlimit="1000" joinstyle="miter"'
        ) );
      });
    }

    // Position if needed
    if(position !== FALSE) { this.calculate(corner); }
  },

  calculate: function(corner) {
    if(!this.enabled) { return FALSE; }

    var self = this,
      elements = this.qtip.elements,
      tip = this.element,
      userOffset = Math.max(0, this.options.offset),
      isWidget = this.qtip.tooltip.hasClass('ui-widget'),
      position = {  },
      precedance, size, corners;

    // Inherit corner if not provided
    corner = corner || this.corner;
    precedance = corner.precedance;

    // Determine which tip dimension to use for adjustment
    size = this._calculateSize(corner);

    // Setup corners and offset array
    corners = [ corner.x, corner.y ];
    if(precedance === X) { corners.reverse(); }

    // Calculate tip position
    $.each(corners, function(i, side) {
      var b, bc, br;

      if(side === CENTER) {
        b = precedance === Y ? LEFT : TOP;
        position[ b ] = '50%';
        position[MARGIN+'-' + b] = -Math.round(size[ precedance === Y ? 0 : 1 ] / 2) + userOffset;
      }
      else {
        b = self._parseWidth(corner, side, elements.tooltip);
        bc = self._parseWidth(corner, side, elements.content);
        br = self._parseRadius(corner);

        position[ side ] = Math.max(-self.border, i ? bc : (userOffset + (br > b ? br : -b)));
      }
    });

    // Adjust for tip size
    position[ corner[precedance] ] -= size[ precedance === X ? 0 : 1 ];

    // Set and return new position
    tip.css({ margin: '', top: '', bottom: '', left: '', right: '' }).css(position);
    return position;
  },

  reposition: function(event, api, pos, viewport) {
    if(!this.enabled) { return; }

    var cache = api.cache,
      newCorner = this.corner.clone(),
      adjust = pos.adjusted,
      method = api.options.position.adjust.method.split(' '),
      horizontal = method[0],
      vertical = method[1] || method[0],
      shift = { left: FALSE, top: FALSE, x: 0, y: 0 },
      offset, css = {}, props;

    // If our tip position isn't fixed e.g. doesn't adjust with viewport...
    if(this.corner.fixed !== TRUE) {
      // Horizontal - Shift or flip method
      if(horizontal === SHIFT && newCorner.precedance === X && adjust.left && newCorner.y !== CENTER) {
        newCorner.precedance = newCorner.precedance === X ? Y : X;
      }
      else if(horizontal !== SHIFT && adjust.left){
        newCorner.x = newCorner.x === CENTER ? (adjust.left > 0 ? LEFT : RIGHT) : (newCorner.x === LEFT ? RIGHT : LEFT);
      }

      // Vertical - Shift or flip method
      if(vertical === SHIFT && newCorner.precedance === Y && adjust.top && newCorner.x !== CENTER) {
        newCorner.precedance = newCorner.precedance === Y ? X : Y;
      }
      else if(vertical !== SHIFT && adjust.top) {
        newCorner.y = newCorner.y === CENTER ? (adjust.top > 0 ? TOP : BOTTOM) : (newCorner.y === TOP ? BOTTOM : TOP);
      }

      // Update and redraw the tip if needed (check cached details of last drawn tip)
      if(newCorner.string() !== cache.corner.string() && (cache.cornerTop !== adjust.top || cache.cornerLeft !== adjust.left)) {
        this.update(newCorner, FALSE);
      }
    }

    // Setup tip offset properties
    offset = this.calculate(newCorner, adjust);

    // Readjust offset object to make it left/top
    if(offset.right !== undefined) { offset.left = -offset.right; }
    if(offset.bottom !== undefined) { offset.top = -offset.bottom; }
    offset.user = Math.max(0, this.offset);

    // Viewport "shift" specific adjustments
    if(shift.left = (horizontal === SHIFT && !!adjust.left)) {
      if(newCorner.x === CENTER) {
        css[MARGIN+'-left'] = shift.x = offset[MARGIN+'-left'] - adjust.left;
      }
      else {
        props = offset.right !== undefined ?
          [ adjust.left, -offset.left ] : [ -adjust.left, offset.left ];

        if( (shift.x = Math.max(props[0], props[1])) > props[0] ) {
          pos.left -= adjust.left;
          shift.left = FALSE;
        }
        
        css[ offset.right !== undefined ? RIGHT : LEFT ] = shift.x;
      }
    }
    if(shift.top = (vertical === SHIFT && !!adjust.top)) {
      if(newCorner.y === CENTER) {
        css[MARGIN+'-top'] = shift.y = offset[MARGIN+'-top'] - adjust.top;
      }
      else {
        props = offset.bottom !== undefined ?
          [ adjust.top, -offset.top ] : [ -adjust.top, offset.top ];

        if( (shift.y = Math.max(props[0], props[1])) > props[0] ) {
          pos.top -= adjust.top;
          shift.top = FALSE;
        }

        css[ offset.bottom !== undefined ? BOTTOM : TOP ] = shift.y;
      }
    }

    /*
    * If the tip is adjusted in both dimensions, or in a
    * direction that would cause it to be anywhere but the
    * outer border, hide it!
    */
    this.element.css(css).toggle(
      !((shift.x && shift.y) || (newCorner.x === CENTER && shift.y) || (newCorner.y === CENTER && shift.x))
    );

    // Adjust position to accomodate tip dimensions
    pos.left -= offset.left.charAt ? offset.user : horizontal !== SHIFT || shift.top || !shift.left && !shift.top ? offset.left : 0;
    pos.top -= offset.top.charAt ? offset.user : vertical !== SHIFT || shift.left || !shift.left && !shift.top ? offset.top : 0;

    // Cache details
    cache.cornerLeft = adjust.left; cache.cornerTop = adjust.top;
    cache.corner = newCorner.clone();
  },

  destroy: function() {
    // Unbind events
    this.qtip._unbind(this.qtip.tooltip, this._ns);

    // Remove the tip element(s)
    if(this.qtip.elements.tip) {
      this.qtip.elements.tip.find('*')
        .remove().end().remove();
    }
  }
});

TIP = PLUGINS.tip = function(api) {
  return new Tip(api, api.options.style.tip);
};

// Initialize tip on render
TIP.initialize = 'render';

// Setup plugin sanitization options
TIP.sanitize = function(options) {
  if(options.style && 'tip' in options.style) {
    opts = options.style.tip;
    if(typeof opts !== 'object') { opts = options.style.tip = { corner: opts }; }
    if(!(/string|boolean/i).test(typeof opts.corner)) { opts.corner = TRUE; }
  }
};

// Add new option checks for the plugin
CHECKS.tip = {
  '^position.my|style.tip.(corner|mimic|border)$': function() {
    // Make sure a tip can be drawn
    this.create();
    
    // Reposition the tooltip
    this.qtip.reposition();
  },
  '^style.tip.(height|width)$': function(obj) {
    // Re-set dimensions and redraw the tip
    this.size = size = [ obj.width, obj.height ];
    this.update();

    // Reposition the tooltip
    this.qtip.reposition();
  },
  '^content.title|style.(classes|widget)$': function() {
    this.update();
  }
};

// Extend original qTip defaults
$.extend(TRUE, QTIP.defaults, {
  style: {
    tip: {
      corner: TRUE,
      mimic: FALSE,
      width: 6,
      height: 6,
      border: TRUE,
      offset: 0
    }
  }
});

;var MODAL, OVERLAY,
  MODALCLASS = 'qtip-modal',
  MODALSELECTOR = '.'+MODALCLASS;

OVERLAY = function()
{
  var self = this,
    focusableElems = {},
    current, onLast,
    prevState, elem;

  // Modified code from jQuery UI 1.10.0 source
  // http://code.jquery.com/ui/1.10.0/jquery-ui.js
  function focusable(element) {
    // Use the defined focusable checker when possible
    if($.expr[':'].focusable) { return $.expr[':'].focusable; }

    var isTabIndexNotNaN = !isNaN($.attr(element, 'tabindex')),
      nodeName = element.nodeName && element.nodeName.toLowerCase(),
      map, mapName, img;

    if('area' === nodeName) {
      map = element.parentNode;
      mapName = map.name;
      if(!element.href || !mapName || map.nodeName.toLowerCase() !== 'map') {
        return false;
      }
      img = $('img[usemap=#' + mapName + ']')[0];
      return !!img && img.is(':visible');
    }
    return (/input|select|textarea|button|object/.test( nodeName ) ?
        !element.disabled :
        'a' === nodeName ? 
          element.href || isTabIndexNotNaN : 
          isTabIndexNotNaN
      );
  }

  // Focus inputs using cached focusable elements (see update())
  function focusInputs(blurElems) {
    // Blurring body element in IE causes window.open windows to unfocus!
    if(focusableElems.length < 1 && blurElems.length) { blurElems.not('body').blur(); }

    // Focus the inputs
    else { focusableElems.first().focus(); }
  }

  // Steal focus from elements outside tooltip
  function stealFocus(event) {
    if(!elem.is(':visible')) { return; }

    var target = $(event.target),
      tooltip = current.tooltip,
      container = target.closest(SELECTOR),
      targetOnTop;

    // Determine if input container target is above this
    targetOnTop = container.length < 1 ? FALSE :
      (parseInt(container[0].style.zIndex, 10) > parseInt(tooltip[0].style.zIndex, 10));

    // If we're showing a modal, but focus has landed on an input below
    // this modal, divert focus to the first visible input in this modal
    // or if we can't find one... the tooltip itself
    if(!targetOnTop && target.closest(SELECTOR)[0] !== tooltip[0]) {
      focusInputs(target);
    }

    // Detect when we leave the last focusable element...
    onLast = event.target === focusableElems[focusableElems.length - 1];
  }

  $.extend(self, {
    init: function() {
      // Create document overlay
      elem = self.elem = $('<div />', {
        id: 'qtip-overlay',
        html: '<div></div>',
        mousedown: function() { return FALSE; }
      })
      .hide();

      // Update position on window resize or scroll
      function resize() {
        var win = $(this);
        elem.css({
          height: win.height(),
          width: win.width()
        });
      }
      $(window).bind('resize'+MODALSELECTOR, resize);
      resize(); // Fire it initially too

      // Make sure we can't focus anything outside the tooltip
      $(document.body).bind('focusin'+MODALSELECTOR, stealFocus);

      // Apply keyboard "Escape key" close handler
      $(document).bind('keydown'+MODALSELECTOR, function(event) {
        if(current && current.options.show.modal.escape && event.keyCode === 27) {
          current.hide(event);
        }
      });

      // Apply click handler for blur option
      elem.bind('click'+MODALSELECTOR, function(event) {
        if(current && current.options.show.modal.blur) {
          current.hide(event);
        }
      });

      return self;
    },

    update: function(api) {
      // Update current API reference
      current = api;

      // Update focusable elements if enabled
      if(api.options.show.modal.stealfocus !== FALSE) {
        focusableElems = api.tooltip.find('*').filter(function() {
          return focusable(this);
        });
      }
      else { focusableElems = []; }
    },

    toggle: function(api, state, duration) {
      var docBody = $(document.body),
        tooltip = api.tooltip,
        options = api.options.show.modal,
        effect = options.effect,
        type = state ? 'show': 'hide',
        visible = elem.is(':visible'),
        visibleModals = $(MODALSELECTOR).filter(':visible:not(:animated)').not(tooltip),
        zindex;

      // Set active tooltip API reference
      self.update(api);

      // If the modal can steal the focus...
      // Blur the current item and focus anything in the modal we an
      if(state && options.stealfocus !== FALSE) {
        focusInputs( $(':focus') );
      }

      // Toggle backdrop cursor style on show
      elem.toggleClass('blurs', options.blur);

      // Set position and append to body on show
      if(state) {
        elem.css({ left: 0, top: 0 })
          .appendTo(document.body);
      }

      // Prevent modal from conflicting with show.solo, and don't hide backdrop is other modals are visible
      if((elem.is(':animated') && visible === state && prevState !== FALSE) || (!state && visibleModals.length)) {
        return self;
      }

      // Stop all animations
      elem.stop(TRUE, FALSE);

      // Use custom function if provided
      if($.isFunction(effect)) {
        effect.call(elem, state);
      }

      // If no effect type is supplied, use a simple toggle
      else if(effect === FALSE) {
        elem[ type ]();
      }

      // Use basic fade function
      else {
        elem.fadeTo( parseInt(duration, 10) || 90, state ? 1 : 0, function() {
          if(!state) { elem.hide(); }
        });
      }

      // Reset position and detach from body on hide
      if(!state) {
        elem.queue(function(next) {
          elem.css({ left: '', top: '' });
          if(!$(MODALSELECTOR).length) { elem.detach(); }
          next();
        });
      }

      // Cache the state
      prevState = state;

      // If the tooltip is destroyed, set reference to null
      if(current.destroyed) { current = NULL; }

      return self;
    }
  }); 

  self.init();
};
OVERLAY = new OVERLAY();

function Modal(api, options) {
  this.options = options;
  this._ns = '-modal';

  this.init( (this.qtip = api) );
}

$.extend(Modal.prototype, {
  init: function(qtip) {
    var tooltip = qtip.tooltip;

    // If modal is disabled... return
    if(!this.options.on) { return this; }

    // Set overlay reference
    qtip.elements.overlay = OVERLAY.elem;

    // Add unique attribute so we can grab modal tooltips easily via a SELECTOR, and set z-index
    tooltip.addClass(MODALCLASS).css('z-index', PLUGINS.modal.zindex + $(MODALSELECTOR).length);
    
    // Apply our show/hide/focus modal events
    qtip._bind(tooltip, ['tooltipshow', 'tooltiphide'], function(event, api, duration) {
      var oEvent = event.originalEvent;

      // Make sure mouseout doesn't trigger a hide when showing the modal and mousing onto backdrop
      if(event.target === tooltip[0]) {
        if(oEvent && event.type === 'tooltiphide' && /mouse(leave|enter)/.test(oEvent.type) && $(oEvent.relatedTarget).closest(overlay[0]).length) {
          try { event.preventDefault(); } catch(e) {}
        }
        else if(!oEvent || (oEvent && !oEvent.solo)) {
          this.toggle(event, event.type === 'tooltipshow', duration);
        }
      }
    }, this._ns, this);

    // Adjust modal z-index on tooltip focus
    qtip._bind(tooltip, 'tooltipfocus', function(event, api) {
      // If focus was cancelled before it reached us, don't do anything
      if(event.isDefaultPrevented() || event.target !== tooltip[0]) { return; }

      var qtips = $(MODALSELECTOR),

      // Keep the modal's lower than other, regular qtips
      newIndex = PLUGINS.modal.zindex + qtips.length,
      curIndex = parseInt(tooltip[0].style.zIndex, 10);

      // Set overlay z-index
      OVERLAY.elem[0].style.zIndex = newIndex - 1;

      // Reduce modal z-index's and keep them properly ordered
      qtips.each(function() {
        if(this.style.zIndex > curIndex) {
          this.style.zIndex -= 1;
        }
      });

      // Fire blur event for focused tooltip
      qtips.filter('.' + CLASS_FOCUS).qtip('blur', event.originalEvent);

      // Set the new z-index
      tooltip.addClass(CLASS_FOCUS)[0].style.zIndex = newIndex;

      // Set current
      OVERLAY.update(api);

      // Prevent default handling
      try { event.preventDefault(); } catch(e) {}
    }, this._ns, this);

    // Focus any other visible modals when this one hides
    qtip._bind(tooltip, 'tooltiphide', function(event) {
      if(event.target === tooltip[0]) {
        $(MODALSELECTOR).filter(':visible').not(tooltip).last().qtip('focus', event);
      }
    }, this._ns, this);
  },

  toggle: function(event, state, duration) {
    // Make sure default event hasn't been prevented
    if(event && event.isDefaultPrevented()) { return this; }

    // Toggle it
    OVERLAY.toggle(this.qtip, !!state, duration);
  },

  destroy: function() {
    // Remove modal class
    this.qtip.tooltip.removeClass(MODALCLASS);

    // Remove bound events
    this.qtip._unbind(this.qtip.tooltip, this._ns);

    // Delete element reference
    OVERLAY.toggle(this.qtip, FALSE);
    delete this.qtip.elements.overlay;
  }
});


MODAL = PLUGINS.modal = function(api) {
  return new Modal(api, api.options.show.modal);
};

// Setup sanitiztion rules
MODAL.sanitize = function(opts) {
  if(opts.show) { 
    if(typeof opts.show.modal !== 'object') { opts.show.modal = { on: !!opts.show.modal }; }
    else if(typeof opts.show.modal.on === 'undefined') { opts.show.modal.on = TRUE; }
  }
};

// Base z-index for all modal tooltips (use qTip core z-index as a base)
MODAL.zindex = QTIP.zindex - 200;

// Plugin needs to be initialized on render
MODAL.initialize = 'render';

// Setup option set checks
CHECKS.modal = {
  '^show.modal.(on|blur)$': function() {
    // Initialise
    this.destroy();
    this.init();
    
    // Show the modal if not visible already and tooltip is visible
    this.qtip.elems.overlay.toggle(
      this.qtip.tooltip[0].offsetWidth > 0
    );
  }
};

// Extend original api defaults
$.extend(TRUE, QTIP.defaults, {
  show: {
    modal: {
      on: FALSE,
      effect: TRUE,
      blur: TRUE,
      stealfocus: TRUE,
      escape: TRUE
    }
  }
});
;PLUGINS.viewport = function(api, position, posOptions, targetWidth, targetHeight, elemWidth, elemHeight)
{
  var target = posOptions.target,
    tooltip = api.elements.tooltip,
    my = posOptions.my,
    at = posOptions.at,
    adjust = posOptions.adjust,
    method = adjust.method.split(' '),
    methodX = method[0],
    methodY = method[1] || method[0],
    viewport = posOptions.viewport,
    container = posOptions.container,
    cache = api.cache,
    tip = api.plugins.tip,
    adjusted = { left: 0, top: 0 },
    fixed, newMy, newClass;

  // If viewport is not a jQuery element, or it's the window/document or no adjustment method is used... return
  if(!viewport.jquery || target[0] === window || target[0] === document.body || adjust.method === 'none') {
    return adjusted;
  }

  // Cache our viewport details
  fixed = tooltip.css('position') === 'fixed';
  viewport = {
    elem: viewport,
    width: viewport[0] === window ? viewport.width() : viewport.outerWidth(FALSE),
    height: viewport[0] === window ? viewport.height() : viewport.outerHeight(FALSE),
    scrollleft: fixed ? 0 : viewport.scrollLeft(),
    scrolltop: fixed ? 0 : viewport.scrollTop(),
    offset: viewport.offset() || { left: 0, top: 0 }
  };
  container = {
    elem: container,
    scrollLeft: container.scrollLeft(),
    scrollTop: container.scrollTop(),
    offset: container.offset() || { left: 0, top: 0 }
  };

  // Generic calculation method
  function calculate(side, otherSide, type, adjust, side1, side2, lengthName, targetLength, elemLength) {
    var initialPos = position[side1],
      mySide = my[side], atSide = at[side],
      isShift = type === SHIFT,
      viewportScroll = -container.offset[side1] + viewport.offset[side1] + viewport['scroll'+side1],
      myLength = mySide === side1 ? elemLength : mySide === side2 ? -elemLength : -elemLength / 2,
      atLength = atSide === side1 ? targetLength : atSide === side2 ? -targetLength : -targetLength / 2,
      tipLength = tip && tip.size ? tip.size[lengthName] || 0 : 0,
      tipAdjust = tip && tip.corner && tip.corner.precedance === side && !isShift ? tipLength : 0,
      overflow1 = viewportScroll - initialPos + tipAdjust,
      overflow2 = initialPos + elemLength - viewport[lengthName] - viewportScroll + tipAdjust,
      offset = myLength - (my.precedance === side || mySide === my[otherSide] ? atLength : 0) - (atSide === CENTER ? targetLength / 2 : 0);

    // shift
    if(isShift) {
      tipAdjust = tip && tip.corner && tip.corner.precedance === otherSide ? tipLength : 0;
      offset = (mySide === side1 ? 1 : -1) * myLength - tipAdjust;

      // Adjust position but keep it within viewport dimensions
      position[side1] += overflow1 > 0 ? overflow1 : overflow2 > 0 ? -overflow2 : 0;
      position[side1] = Math.max(
        -container.offset[side1] + viewport.offset[side1] + (tipAdjust && tip.corner[side] === CENTER ? tip.offset : 0),
        initialPos - offset,
        Math.min(
          Math.max(-container.offset[side1] + viewport.offset[side1] + viewport[lengthName], initialPos + offset),
          position[side1]
        )
      );
    }

    // flip/flipinvert
    else {
      // Update adjustment amount depending on if using flipinvert or flip
      adjust *= (type === FLIPINVERT ? 2 : 0);

      // Check for overflow on the left/top
      if(overflow1 > 0 && (mySide !== side1 || overflow2 > 0)) {
        position[side1] -= offset + adjust;
        newMy.invert(side, side1);
      }

      // Check for overflow on the bottom/right
      else if(overflow2 > 0 && (mySide !== side2 || overflow1 > 0)  ) {
        position[side1] -= (mySide === CENTER ? -offset : offset) + adjust;
        newMy.invert(side, side2);
      }

      // Make sure we haven't made things worse with the adjustment and reset if so
      if(position[side1] < viewportScroll && -position[side1] > overflow2) {
        position[side1] = initialPos; newMy = my.clone();
      }
    }

    return position[side1] - initialPos;
  }

  // Set newMy if using flip or flipinvert methods
  if(methodX !== 'shift' || methodY !== 'shift') { newMy = my.clone(); }

  // Adjust position based onviewport and adjustment options
  adjusted = {
    left: methodX !== 'none' ? calculate( X, Y, methodX, adjust.x, LEFT, RIGHT, WIDTH, targetWidth, elemWidth ) : 0,
    top: methodY !== 'none' ? calculate( Y, X, methodY, adjust.y, TOP, BOTTOM, HEIGHT, targetHeight, elemHeight ) : 0
  };

  // Set tooltip position class if it's changed
  if(newMy && cache.lastClass !== (newClass = NAMESPACE + '-pos-' + newMy.abbrev())) {
    tooltip.removeClass(api.cache.lastClass).addClass( (api.cache.lastClass = newClass) );
  }

  return adjusted;
};;PLUGINS.polys = {
  // POLY area coordinate calculator
  //  Special thanks to Ed Cradock for helping out with this.
  //  Uses a binary search algorithm to find suitable coordinates.
  polygon: function(baseCoords, corner) {
    var result = {
      width: 0, height: 0,
      position: {
        top: 1e10, right: 0,
        bottom: 0, left: 1e10
      },
      adjustable: FALSE
    },
    i = 0, next,
    coords = [],
    compareX = 1, compareY = 1,
    realX = 0, realY = 0,
    newWidth, newHeight;

    // First pass, sanitize coords and determine outer edges
    i = baseCoords.length; while(i--) {
      next = [ parseInt(baseCoords[--i], 10), parseInt(baseCoords[i+1], 10) ];

      if(next[0] > result.position.right){ result.position.right = next[0]; }
      if(next[0] < result.position.left){ result.position.left = next[0]; }
      if(next[1] > result.position.bottom){ result.position.bottom = next[1]; }
      if(next[1] < result.position.top){ result.position.top = next[1]; }

      coords.push(next);
    }

    // Calculate height and width from outer edges
    newWidth = result.width = Math.abs(result.position.right - result.position.left);
    newHeight = result.height = Math.abs(result.position.bottom - result.position.top);

    // If it's the center corner...
    if(corner.abbrev() === 'c') {
      result.position = {
        left: result.position.left + (result.width / 2),
        top: result.position.top + (result.height / 2)
      };
    }
    else {
      // Second pass, use a binary search algorithm to locate most suitable coordinate
      while(newWidth > 0 && newHeight > 0 && compareX > 0 && compareY > 0)
      {
        newWidth = Math.floor(newWidth / 2);
        newHeight = Math.floor(newHeight / 2);

        if(corner.x === LEFT){ compareX = newWidth; }
        else if(corner.x === RIGHT){ compareX = result.width - newWidth; }
        else{ compareX += Math.floor(newWidth / 2); }

        if(corner.y === TOP){ compareY = newHeight; }
        else if(corner.y === BOTTOM){ compareY = result.height - newHeight; }
        else{ compareY += Math.floor(newHeight / 2); }

        i = coords.length; while(i--)
        {
          if(coords.length < 2){ break; }

          realX = coords[i][0] - result.position.left;
          realY = coords[i][1] - result.position.top;

          if((corner.x === LEFT && realX >= compareX) ||
          (corner.x === RIGHT && realX <= compareX) ||
          (corner.x === CENTER && (realX < compareX || realX > (result.width - compareX))) ||
          (corner.y === TOP && realY >= compareY) ||
          (corner.y === BOTTOM && realY <= compareY) ||
          (corner.y === CENTER && (realY < compareY || realY > (result.height - compareY)))) {
            coords.splice(i, 1);
          }
        }
      }
      result.position = { left: coords[0][0], top: coords[0][1] };
    }

    return result;
  },

  rect: function(ax, ay, bx, by, corner) {
    return {
      width: Math.abs(bx - ax),
      height: Math.abs(by - ay),
      position: {
        left: Math.min(ax, bx),
        top: Math.min(ay, by)
      }
    };
  },

  _angles: {
    tc: 3 / 2, tr: 7 / 4, tl: 5 / 4, 
    bc: 1 / 2, br: 1 / 4, bl: 3 / 4, 
    rc: 2, lc: 1, c: 0
  },
  ellipse: function(cx, cy, rx, ry, corner) {
    var c = PLUGINS.polys._angles[ corner.abbrev() ],
      rxc = rx * Math.cos( c * Math.PI ),
      rys = ry * Math.sin( c * Math.PI );

    return {
      width: (rx * 2) - Math.abs(rxc),
      height: (ry * 2) - Math.abs(rys),
      position: {
        left: cx + rxc,
        top: cy + rys
      },
      adjustable: FALSE
    };
  },
  circle: function(cx, cy, r, corner) {
    return PLUGINS.polys.ellipse(cx, cy, r, r, corner);
  }
};;PLUGINS.svg = function(api, svg, corner, adjustMethod)
{
  var doc = $(document),
    elem = svg[0],
    result = FALSE,
    name, box, position, dimensions;

  // Ascend the parentNode chain until we find an element with getBBox()
  while(!elem.getBBox) { elem = elem.parentNode; }
  if(!elem.getBBox || !elem.parentNode) { return FALSE; }

  // Determine which shape calculation to use
  switch(elem.nodeName) {
    case 'rect':
      position = PLUGINS.svg.toPixel(elem, elem.x.baseVal.value, elem.y.baseVal.value);
      dimensions = PLUGINS.svg.toPixel(elem,
        elem.x.baseVal.value + elem.width.baseVal.value,
        elem.y.baseVal.value + elem.height.baseVal.value
      );

      result = PLUGINS.polys.rect(
        position[0], position[1],
        dimensions[0], dimensions[1],
        corner
      );
    break;

    case 'ellipse':
    case 'circle':
      position = PLUGINS.svg.toPixel(elem,
        elem.cx.baseVal.value,
        elem.cy.baseVal.value
      );

      result = PLUGINS.polys.ellipse(
        position[0], position[1],
        (elem.rx || elem.r).baseVal.value, 
        (elem.ry || elem.r).baseVal.value,
        corner
      );
    break;

    case 'line':
    case 'polygon':
    case 'polyline':
      points = elem.points || [
        { x: elem.x1.baseVal.value, y: elem.y1.baseVal.value },
        { x: elem.x2.baseVal.value, y: elem.y2.baseVal.value }
      ];

      for(result = [], i = -1, len = points.numberOfItems || points.length; ++i < len;) {
        next = points.getItem ? points.getItem(i) : points[i];
        result.push.apply(result, PLUGINS.svg.toPixel(elem, next.x, next.y));
      }

      result = PLUGINS.polys.polygon(result, corner);
    break;

    // Invalid shape
    default: return FALSE;
  }

  // Adjust by scroll offset
  result.position.left += doc.scrollLeft();
  result.position.top += doc.scrollTop();

  return result;
};

PLUGINS.svg.toPixel = function(elem, x, y) {
  var mtx = elem.getScreenCTM(),
    root = elem.farthestViewportElement || elem,
    result, point;

  // Create SVG point
  if(!root.createSVGPoint) { return FALSE; }
  point = root.createSVGPoint();

  point.x = x; point.y = y;
  result = point.matrixTransform(mtx);
  return [ result.x, result.y ];
};;PLUGINS.imagemap = function(api, area, corner, adjustMethod)
{
  if(!area.jquery) { area = $(area); }

  var shape = area.attr('shape').toLowerCase().replace('poly', 'polygon'),
    image = $('img[usemap="#'+area.parent('map').attr('name')+'"]'),
    coordsString = area.attr('coords'),
    coordsArray = coordsString.split(','),
    imageOffset, coords, i, next;

  // If we can't find the image using the map...
  if(!image.length) { return FALSE; }

  // Pass coordinates string if polygon
  if(shape === 'polygon') {
    result = PLUGINS.polys.polygon(coordsArray, corner);
  }

  // Otherwise parse the coordinates and pass them as arguments
  else if(PLUGINS.polys[shape]) {
    for(i = -1, len = coordsArray.length, coords = []; ++i < len;) {
      coords.push( parseInt(coordsArray[i], 10) );
    }

    result = PLUGINS.polys[shape].apply(
      this, coords.concat(corner)
    );
  }

  // If no shapre calculation method was found, return false
  else { return FALSE; }

  // Make sure we account for padding and borders on the image
  imageOffset = image.offset();
  imageOffset.left += Math.ceil((image.outerWidth(FALSE) - image.width()) / 2);
  imageOffset.top += Math.ceil((image.outerHeight(FALSE) - image.height()) / 2);

  // Add image position to offset coordinates
  result.position.left += imageOffset.left;
  result.position.top += imageOffset.top;

  return result;
};;var IE6,

/* 
 * BGIFrame adaption (http://plugins.jquery.com/project/bgiframe)
 * Special thanks to Brandon Aaron
 */
BGIFRAME = '<iframe class="qtip-bgiframe" frameborder="0" tabindex="-1" src="javascript:\'\';" ' +
  ' style="display:block; position:absolute; z-index:-1; filter:alpha(opacity=0); ' +
    '-ms-filter:"progid:DXImageTransform.Microsoft.Alpha(Opacity=0)";"></iframe>';

function Ie6(api, qtip) {
  this._ns = 'ie6';
  this.init( (this.qtip = api) );
}

$.extend(Ie6.prototype, {
  _scroll : function() {
    var overlay = this.qtip.elements.overlay;
    overlay && (overlay[0].style.top = $(window).scrollTop() + 'px');
  },

  init: function(qtip) {
    var tooltip = qtip.tooltip,
      scroll;

    // Create the BGIFrame element if needed
    if($('select, object').length < 1) {
      this.bgiframe = qtip.elements.bgiframe = $(BGIFRAME).appendTo(tooltip);

      // Update BGIFrame on tooltip move
      qtip._bind(tooltip, 'tooltipmove', this.adjustBGIFrame, this._ns, this);
    }

    // redraw() container for width/height calculations
    this.redrawContainer = $('<div/>', { id: NAMESPACE+'-rcontainer' })
      .appendTo(document.body);

    // Fixup modal plugin if present too
    if( qtip.elements.overlay && qtip.elements.overlay.addClass('qtipmodal-ie6fix') ) {
      qtip._bind(window, ['scroll', 'resize'], this._scroll, this._ns, this);
      qtip._bind(tooltip, ['tooltipshow'], this._scroll, this._ns, this);
    }

    // Set dimensions
    this.redraw();
  },

  adjustBGIFrame: function() {
    var tooltip = this.qtip.tooltip,
      dimensions = {
        height: tooltip.outerHeight(FALSE),
        width: tooltip.outerWidth(FALSE)
      },
      plugin = this.qtip.plugins.tip,
      tip = this.qtip.elements.tip,
      tipAdjust, offset;

    // Adjust border offset
    offset = parseInt(tooltip.css('borderLeftWidth'), 10) || 0;
    offset = { left: -offset, top: -offset };

    // Adjust for tips plugin
    if(plugin && tip) {
      tipAdjust = (plugin.corner.precedance === 'x') ? [WIDTH, LEFT] : [HEIGHT, TOP];
      offset[ tipAdjust[1] ] -= tip[ tipAdjust[0] ]();
    }

    // Update bgiframe
    this.bgiframe.css(offset).css(dimensions);
  },

  // Max/min width simulator function
  redraw: function() {
    if(this.qtip.rendered < 1 || this.drawing) { return self; }

    var tooltip = this.qtip.tooltip,
      style = this.qtip.options.style,
      container = this.qtip.options.position.container,
      perc, width, max, min;

    // Set drawing flag
    this.qtip.drawing = 1;

    // If tooltip has a set height/width, just set it... like a boss!
    if(style.height) { tooltip.css(HEIGHT, style.height); }
    if(style.width) { tooltip.css(WIDTH, style.width); }

    // Simulate max/min width if not set width present...
    else {
      // Reset width and add fluid class
      tooltip.css(WIDTH, '').appendTo(this.redrawContainer);

      // Grab our tooltip width (add 1 if odd so we don't get wrapping problems.. huzzah!)
      width = tooltip.width();
      if(width % 2 < 1) { width += 1; }

      // Grab our max/min properties
      max = tooltip.css('maxWidth') || '';
      min = tooltip.css('minWidth') || '';

      // Parse into proper pixel values
      perc = (max + min).indexOf('%') > -1 ? container.width() / 100 : 0;
      max = ((max.indexOf('%') > -1 ? perc : 1) * parseInt(max, 10)) || width;
      min = ((min.indexOf('%') > -1 ? perc : 1) * parseInt(min, 10)) || 0;

      // Determine new dimension size based on max/min/current values
      width = max + min ? Math.min(Math.max(width, min), max) : width;

      // Set the newly calculated width and remvoe fluid class
      tooltip.css(WIDTH, Math.round(width)).appendTo(container);
    }

    // Set drawing flag
    this.drawing = 0;

    return self;
  },

  destroy: function() {
    // Remove iframe
    this.bgiframe && this.bgiframe.remove();

    // Remove bound events
    this.qtip._unbind([window, this.qtip.tooltip], this._ns);
  }
});

IE6 = PLUGINS.ie6 = function(api) {
  // Proceed only if the browser is IE6
  return BROWSER.ie === 6 ? new Ie6(api) : FALSE;
};

IE6.initialize = 'render';

CHECKS.ie6 = {
  '^content|style$': function() { 
    this.redraw();
  }
};;}));
}( window, document ));




/*!
 * jQuery imagesLoaded plugin v2.1.1
 * http://github.com/desandro/imagesloaded
 *
 * MIT License. by Paul Irish et al.
 */

/*jshint curly: true, eqeqeq: true, noempty: true, strict: true, undef: true, browser: true */
/*global jQuery: false */

;(function($, undefined) {
'use strict';

// blank image data-uri bypasses webkit log warning (thx doug jones)
var BLANK = 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==';

$.fn.imagesLoaded = function( callback ) {
  var $this = this,
    deferred = $.isFunction($.Deferred) ? $.Deferred() : 0,
    hasNotify = $.isFunction(deferred.notify),
    $images = $this.find('img').add( $this.filter('img') ),
    loaded = [],
    proper = [],
    broken = [];

  // Register deferred callbacks
  if ($.isPlainObject(callback)) {
    $.each(callback, function (key, value) {
      if (key === 'callback') {
        callback = value;
      } else if (deferred) {
        deferred[key](value);
      }
    });
  }

  function doneLoading() {
    var $proper = $(proper),
      $broken = $(broken);

    if ( deferred ) {
      if ( broken.length ) {
        deferred.reject( $images, $proper, $broken );
      } else {
        deferred.resolve( $images );
      }
    }

    if ( $.isFunction( callback ) ) {
      callback.call( $this, $images, $proper, $broken );
    }
  }

  function imgLoadedHandler( event ) {
    imgLoaded( event.target, event.type === 'error' );
  }

  function imgLoaded( img, isBroken ) {
    // don't proceed if BLANK image, or image is already loaded
    if ( img.src === BLANK || $.inArray( img, loaded ) !== -1 ) {
      return;
    }

    // store element in loaded images array
    loaded.push( img );

    // keep track of broken and properly loaded images
    if ( isBroken ) {
      broken.push( img );
    } else {
      proper.push( img );
    }

    // cache image and its state for future calls
    $.data( img, 'imagesLoaded', { isBroken: isBroken, src: img.src } );

    // trigger deferred progress method if present
    if ( hasNotify ) {
      deferred.notifyWith( $(img), [ isBroken, $images, $(proper), $(broken) ] );
    }

    // call doneLoading and clean listeners if all images are loaded
    if ( $images.length === loaded.length ) {
      setTimeout( doneLoading );
      $images.unbind( '.imagesLoaded', imgLoadedHandler );
    }
  }

  // if no images, trigger immediately
  if ( !$images.length ) {
    doneLoading();
  } else {
    $images.bind( 'load.imagesLoaded error.imagesLoaded', imgLoadedHandler )
    .each( function( i, el ) {
      var src = el.src;

      // find out if this image has been already checked for status
      // if it was, and src has not changed, call imgLoaded on it
      var cached = $.data( el, 'imagesLoaded' );
      if ( cached && cached.src === src ) {
        imgLoaded( el, cached.isBroken );
        return;
      }

      // if complete is true and browser supports natural sizes, try
      // to check for image status manually
      if ( el.complete && el.naturalWidth !== undefined ) {
        imgLoaded( el, el.naturalWidth === 0 || el.naturalHeight === 0 );
        return;
      }

      // cached images don't fire load sometimes, so we reset src, but only when
      // dealing with IE, or image is complete (loaded) and failed manual check
      // webkit hack from http://groups.google.com/group/jquery-dev/browse_thread/thread/eee6ab7b2da50e1f
      if ( el.readyState || el.complete ) {
        el.src = BLANK;
        el.src = src;
      }
    });
  }

  return deferred ? deferred.promise( $this ) : $this;
};

})(jQuery);
/** @license
RainbowVis-JS 
Released under MIT License
*/

function Rainbow()
{
  var gradients = null;
  var minNum = 0;
  var maxNum = 100;
  var colours = ['ff0000', 'ffff00', '00ff00', '0000ff']; 
  setColours(colours);
  
  function setColours (spectrum) 
  {
    if (spectrum.length < 2) {
      throw new Error('Rainbow must have two or more colours.');
    } else {
      var increment = (maxNum - minNum)/(spectrum.length - 1);
      var firstGradient = new ColourGradient();
      firstGradient.setGradient(spectrum[0], spectrum[1]);
      firstGradient.setNumberRange(minNum, minNum + increment);
      gradients = [ firstGradient ];
      
      for (var i = 1; i < spectrum.length - 1; i++) {
        var colourGradient = new ColourGradient();
        colourGradient.setGradient(spectrum[i], spectrum[i + 1]);
        colourGradient.setNumberRange(minNum + increment * i, minNum + increment * (i + 1)); 
        gradients[i] = colourGradient; 
      }

      colours = spectrum;
      return this;
    }
  }

  this.setColors = this.setColours;

  this.setSpectrum = function () 
  {
    setColours(arguments);
    return this;
  }

  this.setSpectrumByArray = function (array)
  {
    setColours(array);
        return this;
  }

  this.colourAt = function (number)
  {
    if (isNaN(number)) {
      throw new TypeError(number + ' is not a number');
    } else if (gradients.length === 1) {
      return gradients[0].colourAt(number);
    } else {
      var segment = (maxNum - minNum)/(gradients.length);
      var index = Math.min(Math.floor((Math.max(number, minNum) - minNum)/segment), gradients.length - 1);
      return gradients[index].colourAt(number);
    }
  }

  this.colorAt = this.colourAt;

  this.setNumberRange = function (minNumber, maxNumber)
  {
    if (maxNumber > minNumber) {
      minNum = minNumber;
      maxNum = maxNumber;
      setColours(colours);
    } else {
      throw new RangeError('maxNumber (' + maxNumber + ') is not greater than minNumber (' + minNumber + ')');
    }
    return this;
  }
}

function ColourGradient() 
{
  var startColour = 'ff0000';
  var endColour = '0000ff';
  var minNum = 0;
  var maxNum = 100;

  this.setGradient = function (colourStart, colourEnd)
  {
    startColour = getHexColour(colourStart);
    endColour = getHexColour(colourEnd);
  }

  this.setNumberRange = function (minNumber, maxNumber)
  {
    if (maxNumber > minNumber) {
      minNum = minNumber;
      maxNum = maxNumber;
    } else {
      throw new RangeError('maxNumber (' + maxNumber + ') is not greater than minNumber (' + minNumber + ')');
    }
  }

  this.colourAt = function (number)
  {
    return calcHex(number, startColour.substring(0,2), endColour.substring(0,2)) 
      + calcHex(number, startColour.substring(2,4), endColour.substring(2,4)) 
      + calcHex(number, startColour.substring(4,6), endColour.substring(4,6));
  }
  
  function calcHex(number, channelStart_Base16, channelEnd_Base16)
  {
    var num = number;
    if (num < minNum) {
      num = minNum;
    }
    if (num > maxNum) {
      num = maxNum;
    } 
    var numRange = maxNum - minNum;
    var cStart_Base10 = parseInt(channelStart_Base16, 16);
    var cEnd_Base10 = parseInt(channelEnd_Base16, 16); 
    var cPerUnit = (cEnd_Base10 - cStart_Base10)/numRange;
    var c_Base10 = Math.round(cPerUnit * (num - minNum) + cStart_Base10);
    return formatHex(c_Base10.toString(16));
  }

  formatHex = function (hex) 
  {
    if (hex.length === 1) {
      return '0' + hex;
    } else {
      return hex;
    }
  } 
  
  function isHexColour(string)
  {
    var regex = /^#?[0-9a-fA-F]{6}$/i;
    return regex.test(string);
  }

  function getHexColour(string)
  {
    if (isHexColour(string)) {
      return string.substring(string.length - 6, string.length);
    } else {
      var colourNames =
      [
        ['red', 'ff0000'],
        ['lime', '00ff00'],
        ['blue', '0000ff'],
        ['yellow', 'ffff00'],
        ['orange', 'ff8000'],
        ['aqua', '00ffff'],
        ['fuchsia', 'ff00ff'],
        ['white', 'ffffff'],
        ['black', '000000'],
        ['gray', '808080'],
        ['grey', '808080'],
        ['silver', 'c0c0c0'],
        ['maroon', '800000'],
        ['olive', '808000'],
        ['green', '008000'],
        ['teal', '008080'],
        ['navy', '000080'],
        ['purple', '800080']
      ];
      for (var i = 0; i < colourNames.length; i++) {
        if (string.toLowerCase() === colourNames[i][0]) {
          return colourNames[i][1];
        }
      }
      throw new Error(string + ' is not a valid colour.');
    }
  }
}

/** @license
* â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â” \\
* â”‚ RaphaÃ«l 2.1.0 - JavaScript Vector Library                          â”‚ \\
* â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¤ \\
* â”‚ Copyright Â© 2008-2012 Dmitry Baranovskiy (http://raphaeljs.com)    â”‚ \\
* â”‚ Copyright Â© 2008-2012 Sencha Labs (http://sencha.com)              â”‚ \\
* â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¤ \\
* â”‚ Licensed under the MIT (http://raphaeljs.com/license.html) license.â”‚ \\
* â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜ \\
* Copyright (c) 2013 Adobe Systems Incorporated. All rights reserved.
* 
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
* 
* http://www.apache.org/licenses/LICENSE-2.0
* 
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
* â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â” \\
* â”‚ Eve 0.4.2 - JavaScript Events Library                      â”‚ \\
* â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¤ \\
* â”‚ Author Dmitry Baranovskiy (http://dmitry.baranovskiy.com/) â”‚ \\
* â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜ \\
*/

(function (glob) {
    var version = "0.4.2",
        has = "hasOwnProperty",
        separator = /[\.\/]/,
        wildcard = "*",
        fun = function () {},
        numsort = function (a, b) {
            return a - b;
        },
        current_event,
        stop,
        events = {n: {}},
    /*\
     * eve
     [ method ]

     * Fires event with given `name`, given scope and other parameters.

     > Arguments

     - name (string) name of the *event*, dot (`.`) or slash (`/`) separated
     - scope (object) context for the event handlers
     - varargs (...) the rest of arguments will be sent to event handlers

     = (object) array of returned values from the listeners
    \*/
        eve = function (name, scope) {
      name = String(name);
            var e = events,
                oldstop = stop,
                args = Array.prototype.slice.call(arguments, 2),
                listeners = eve.listeners(name),
                z = 0,
                f = false,
                l,
                indexed = [],
                queue = {},
                out = [],
                ce = current_event,
                errors = [];
            current_event = name;
            stop = 0;
            for (var i = 0, ii = listeners.length; i < ii; i++) if ("zIndex" in listeners[i]) {
                indexed.push(listeners[i].zIndex);
                if (listeners[i].zIndex < 0) {
                    queue[listeners[i].zIndex] = listeners[i];
                }
            }
            indexed.sort(numsort);
            while (indexed[z] < 0) {
                l = queue[indexed[z++]];
                out.push(l.apply(scope, args));
                if (stop) {
                    stop = oldstop;
                    return out;
                }
            }
            for (i = 0; i < ii; i++) {
                l = listeners[i];
                if ("zIndex" in l) {
                    if (l.zIndex == indexed[z]) {
                        out.push(l.apply(scope, args));
                        if (stop) {
                            break;
                        }
                        do {
                            z++;
                            l = queue[indexed[z]];
                            l && out.push(l.apply(scope, args));
                            if (stop) {
                                break;
                            }
                        } while (l)
                    } else {
                        queue[l.zIndex] = l;
                    }
                } else {
                    out.push(l.apply(scope, args));
                    if (stop) {
                        break;
                    }
                }
            }
            stop = oldstop;
            current_event = ce;
            return out.length ? out : null;
        };
    // Undocumented. Debug only.
    eve._events = events;
    /*\
     * eve.listeners
     [ method ]

     * Internal method which gives you array of all event handlers that will be triggered by the given `name`.

     > Arguments

     - name (string) name of the event, dot (`.`) or slash (`/`) separated

     = (array) array of event handlers
    \*/
    eve.listeners = function (name) {
        var names = name.split(separator),
            e = events,
            item,
            items,
            k,
            i,
            ii,
            j,
            jj,
            nes,
            es = [e],
            out = [];
        for (i = 0, ii = names.length; i < ii; i++) {
            nes = [];
            for (j = 0, jj = es.length; j < jj; j++) {
                e = es[j].n;
                items = [e[names[i]], e[wildcard]];
                k = 2;
                while (k--) {
                    item = items[k];
                    if (item) {
                        nes.push(item);
                        out = out.concat(item.f || []);
                    }
                }
            }
            es = nes;
        }
        return out;
    };
    
    /*\
     * eve.on
     [ method ]
     **
     * Binds given event handler with a given name. You can use wildcards â€œ`*`â€ for the names:
     | eve.on("*.under.*", f);
     | eve("mouse.under.floor"); // triggers f
     * Use @eve to trigger the listener.
     **
     > Arguments
     **
     - name (string) name of the event, dot (`.`) or slash (`/`) separated, with optional wildcards
     - f (function) event handler function
     **
     = (function) returned function accepts a single numeric parameter that represents z-index of the handler. It is an optional feature and only used when you need to ensure that some subset of handlers will be invoked in a given order, despite of the order of assignment. 
     > Example:
     | eve.on("mouse", eatIt)(2);
     | eve.on("mouse", scream);
     | eve.on("mouse", catchIt)(1);
     * This will ensure that `catchIt()` function will be called before `eatIt()`.
   *
     * If you want to put your handler before non-indexed handlers, specify a negative value.
     * Note: I assume most of the time you donâ€™t need to worry about z-index, but itâ€™s nice to have this feature â€œjust in caseâ€.
    \*/
    eve.on = function (name, f) {
    name = String(name);
    if (typeof f != "function") {
      return function () {};
    }
        var names = name.split(separator),
            e = events;
        for (var i = 0, ii = names.length; i < ii; i++) {
            e = e.n;
            e = e.hasOwnProperty(names[i]) && e[names[i]] || (e[names[i]] = {n: {}});
        }
        e.f = e.f || [];
        for (i = 0, ii = e.f.length; i < ii; i++) if (e.f[i] == f) {
            return fun;
        }
        e.f.push(f);
        return function (zIndex) {
            if (+zIndex == +zIndex) {
                f.zIndex = +zIndex;
            }
        };
    };
    /*\
     * eve.f
     [ method ]
     **
     * Returns function that will fire given event with optional arguments.
   * Arguments that will be passed to the result function will be also
   * concated to the list of final arguments.
   | el.onclick = eve.f("click", 1, 2);
   | eve.on("click", function (a, b, c) {
   |     console.log(a, b, c); // 1, 2, [event object]
   | });
     > Arguments
   - event (string) event name
   - varargs (â€¦) and any other arguments
   = (function) possible event handler function
    \*/
  eve.f = function (event) {
    var attrs = [].slice.call(arguments, 1);
    return function () {
      eve.apply(null, [event, null].concat(attrs).concat([].slice.call(arguments, 0)));
    };
  };
    /*\
     * eve.stop
     [ method ]
     **
     * Is used inside an event handler to stop the event, preventing any subsequent listeners from firing.
    \*/
    eve.stop = function () {
        stop = 1;
    };
    /*\
     * eve.nt
     [ method ]
     **
     * Could be used inside event handler to figure out actual name of the event.
     **
     > Arguments
     **
     - subname (string) #optional subname of the event
     **
     = (string) name of the event, if `subname` is not specified
     * or
     = (boolean) `true`, if current eventâ€™s name contains `subname`
    \*/
    eve.nt = function (subname) {
        if (subname) {
            return new RegExp("(?:\\.|\\/|^)" + subname + "(?:\\.|\\/|$)").test(current_event);
        }
        return current_event;
    };
    /*\
     * eve.nts
     [ method ]
     **
     * Could be used inside event handler to figure out actual name of the event.
     **
     **
     = (array) names of the event
    \*/
    eve.nts = function () {
        return current_event.split(separator);
    };
    /*\
     * eve.off
     [ method ]
     **
     * Removes given function from the list of event listeners assigned to given name.
   * If no arguments specified all the events will be cleared.
     **
     > Arguments
     **
     - name (string) name of the event, dot (`.`) or slash (`/`) separated, with optional wildcards
     - f (function) event handler function
    \*/
    /*\
     * eve.unbind
     [ method ]
     **
     * See @eve.off
    \*/
    eve.off = eve.unbind = function (name, f) {
    if (!name) {
        eve._events = events = {n: {}};
      return;
    }
        var names = name.split(separator),
            e,
            key,
            splice,
            i, ii, j, jj,
            cur = [events];
        for (i = 0, ii = names.length; i < ii; i++) {
            for (j = 0; j < cur.length; j += splice.length - 2) {
                splice = [j, 1];
                e = cur[j].n;
                if (names[i] != wildcard) {
                    if (e[names[i]]) {
                        splice.push(e[names[i]]);
                    }
                } else {
                    for (key in e) if (e[has](key)) {
                        splice.push(e[key]);
                    }
                }
                cur.splice.apply(cur, splice);
            }
        }
        for (i = 0, ii = cur.length; i < ii; i++) {
            e = cur[i];
            while (e.n) {
                if (f) {
                    if (e.f) {
                        for (j = 0, jj = e.f.length; j < jj; j++) if (e.f[j] == f) {
                            e.f.splice(j, 1);
                            break;
                        }
                        !e.f.length && delete e.f;
                    }
                    for (key in e.n) if (e.n[has](key) && e.n[key].f) {
                        var funcs = e.n[key].f;
                        for (j = 0, jj = funcs.length; j < jj; j++) if (funcs[j] == f) {
                            funcs.splice(j, 1);
                            break;
                        }
                        !funcs.length && delete e.n[key].f;
                    }
                } else {
                    delete e.f;
                    for (key in e.n) if (e.n[has](key) && e.n[key].f) {
                        delete e.n[key].f;
                    }
                }
                e = e.n;
            }
        }
    };
    /*\
     * eve.once
     [ method ]
     **
     * Binds given event handler with a given name to only run once then unbind itself.
     | eve.once("login", f);
     | eve("login"); // triggers f
     | eve("login"); // no listeners
     * Use @eve to trigger the listener.
     **
     > Arguments
     **
     - name (string) name of the event, dot (`.`) or slash (`/`) separated, with optional wildcards
     - f (function) event handler function
     **
     = (function) same return function as @eve.on
    \*/
    eve.once = function (name, f) {
        var f2 = function () {
            eve.unbind(name, f2);
            return f.apply(this, arguments);
        };
        return eve.on(name, f2);
    };
    /*\
     * eve.version
     [ property (string) ]
     **
     * Current version of the library.
    \*/
    eve.version = version;
    eve.toString = function () {
        return "You are running Eve " + version;
    };
    (typeof module != "undefined" && module.exports) ? (module.exports = eve) : (typeof define != "undefined" ? (define("eve", [], function() { return eve; })) : (glob.eve = eve));
})(this);
// â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â” \\
// â”‚ "RaphaÃ«l 2.1.0" - JavaScript Vector Library                         â”‚ \\
// â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¤ \\
// â”‚ Copyright (c) 2008-2011 Dmitry Baranovskiy (http://raphaeljs.com)   â”‚ \\
// â”‚ Copyright (c) 2008-2011 Sencha Labs (http://sencha.com)             â”‚ \\
// â”‚ Licensed under the MIT (http://raphaeljs.com/license.html) license. â”‚ \\
// â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜ \\
(function (glob, factory) {
    // AMD support
    if (typeof define === "function" && define.amd) {
        // Define as an anonymous module
        define(["eve"], function( eve ) {
            return factory(glob, eve);
        });
    } else {
        // Browser globals (glob is window)
        // Raphael adds itself to window
        factory(glob, glob.eve);
    }
}(this, function (window, eve) {
    /*\
     * Raphael
     [ method ]
     **
     * Creates a canvas object on which to draw.
     * You must do this first, as all future calls to drawing methods
     * from this instance will be bound to this canvas.
     > Parameters
     **
     - container (HTMLElement|string) DOM element or its ID which is going to be a parent for drawing surface
     - width (number)
     - height (number)
     - callback (function) #optional callback function which is going to be executed in the context of newly created paper
     * or
     - x (number)
     - y (number)
     - width (number)
     - height (number)
     - callback (function) #optional callback function which is going to be executed in the context of newly created paper
     * or
     - all (array) (first 3 or 4 elements in the array are equal to [containerID, width, height] or [x, y, width, height]. The rest are element descriptions in format {type: type, <attributes>}). See @Paper.add.
     - callback (function) #optional callback function which is going to be executed in the context of newly created paper
     * or
     - onReadyCallback (function) function that is going to be called on DOM ready event. You can also subscribe to this event via Eveâ€™s â€œDOMLoadâ€ event. In this case method returns `undefined`.
     = (object) @Paper
     > Usage
     | // Each of the following examples create a canvas
     | // that is 320px wide by 200px high.
     | // Canvas is created at the viewportâ€™s 10,50 coordinate.
     | var paper = Raphael(10, 50, 320, 200);
     | // Canvas is created at the top left corner of the #notepad element
     | // (or its top right corner in dir="rtl" elements)
     | var paper = Raphael(document.getElementById("notepad"), 320, 200);
     | // Same as above
     | var paper = Raphael("notepad", 320, 200);
     | // Image dump
     | var set = Raphael(["notepad", 320, 200, {
     |     type: "rect",
     |     x: 10,
     |     y: 10,
     |     width: 25,
     |     height: 25,
     |     stroke: "#f00"
     | }, {
     |     type: "text",
     |     x: 30,
     |     y: 40,
     |     text: "Dump"
     | }]);
    \*/
    function R(first) {
        if (R.is(first, "function")) {
            return loaded ? first() : eve.on("raphael.DOMload", first);
        } else if (R.is(first, array)) {
            return R._engine.create[apply](R, first.splice(0, 3 + R.is(first[0], nu))).add(first);
        } else {
            var args = Array.prototype.slice.call(arguments, 0);
            if (R.is(args[args.length - 1], "function")) {
                var f = args.pop();
                return loaded ? f.call(R._engine.create[apply](R, args)) : eve.on("raphael.DOMload", function () {
                    f.call(R._engine.create[apply](R, args));
                });
            } else {
                return R._engine.create[apply](R, arguments);
            }
        }
    }
    R.version = "2.1.0";
    R.eve = eve;
    var loaded,
        separator = /[, ]+/,
        elements = {circle: 1, rect: 1, path: 1, ellipse: 1, text: 1, image: 1},
        formatrg = /\{(\d+)\}/g,
        proto = "prototype",
        has = "hasOwnProperty",
        g = {
            doc: document,
            win: window
        },
        oldRaphael = {
            was: Object.prototype[has].call(g.win, "Raphael"),
            is: g.win.Raphael
        },
        Paper = function () {
            /*\
             * Paper.ca
             [ property (object) ]
             **
             * Shortcut for @Paper.customAttributes
            \*/
            /*\
             * Paper.customAttributes
             [ property (object) ]
             **
             * If you have a set of attributes that you would like to represent
             * as a function of some number you can do it easily with custom attributes:
             > Usage
             | paper.customAttributes.hue = function (num) {
             |     num = num % 1;
             |     return {fill: "hsb(" + num + ", 0.75, 1)"};
             | };
             | // Custom attribute â€œhueâ€ will change fill
             | // to be given hue with fixed saturation and brightness.
             | // Now you can use it like this:
             | var c = paper.circle(10, 10, 10).attr({hue: .45});
             | // or even like this:
             | c.animate({hue: 1}, 1e3);
             | 
             | // You could also create custom attribute
             | // with multiple parameters:
             | paper.customAttributes.hsb = function (h, s, b) {
             |     return {fill: "hsb(" + [h, s, b].join(",") + ")"};
             | };
             | c.attr({hsb: "0.5 .8 1"});
             | c.animate({hsb: [1, 0, 0.5]}, 1e3);
            \*/
            this.ca = this.customAttributes = {};
        },
        paperproto,
        appendChild = "appendChild",
        apply = "apply",
        concat = "concat",
        supportsTouch = ('ontouchstart' in g.win) || g.win.DocumentTouch && g.doc instanceof DocumentTouch, //taken from Modernizr touch test
        E = "",
        S = " ",
        Str = String,
        split = "split",
        events = "click dblclick mousedown mousemove mouseout mouseover mouseup touchstart touchmove touchend touchcancel"[split](S),
        touchMap = {
            mousedown: "touchstart",
            mousemove: "touchmove",
            mouseup: "touchend"
        },
        lowerCase = Str.prototype.toLowerCase,
        math = Math,
        mmax = math.max,
        mmin = math.min,
        abs = math.abs,
        pow = math.pow,
        PI = math.PI,
        nu = "number",
        string = "string",
        array = "array",
        toString = "toString",
        fillString = "fill",
        objectToString = Object.prototype.toString,
        paper = {},
        push = "push",
        ISURL = R._ISURL = /^url\(['"]?([^\)]+?)['"]?\)$/i,
        colourRegExp = /^\s*((#[a-f\d]{6})|(#[a-f\d]{3})|rgba?\(\s*([\d\.]+%?\s*,\s*[\d\.]+%?\s*,\s*[\d\.]+%?(?:\s*,\s*[\d\.]+%?)?)\s*\)|hsba?\(\s*([\d\.]+(?:deg|\xb0|%)?\s*,\s*[\d\.]+%?\s*,\s*[\d\.]+(?:%?\s*,\s*[\d\.]+)?)%?\s*\)|hsla?\(\s*([\d\.]+(?:deg|\xb0|%)?\s*,\s*[\d\.]+%?\s*,\s*[\d\.]+(?:%?\s*,\s*[\d\.]+)?)%?\s*\))\s*$/i,
        isnan = {"NaN": 1, "Infinity": 1, "-Infinity": 1},
        bezierrg = /^(?:cubic-)?bezier\(([^,]+),([^,]+),([^,]+),([^\)]+)\)/,
        round = math.round,
        setAttribute = "setAttribute",
        toFloat = parseFloat,
        toInt = parseInt,
        upperCase = Str.prototype.toUpperCase,
        availableAttrs = R._availableAttrs = {
            "arrow-end": "none",
            "arrow-start": "none",
            blur: 0,
            "clip-rect": "0 0 1e9 1e9",
            cursor: "default",
            cx: 0,
            cy: 0,
            fill: "#fff",
            "fill-opacity": 1,
            font: '10px "Arial"',
            "font-family": '"Arial"',
            "font-size": "10",
            "font-style": "normal",
            "font-weight": 400,
            gradient: 0,
            height: 0,
            href: "http://raphaeljs.com/",
            "letter-spacing": 0,
            opacity: 1,
            path: "M0,0",
            r: 0,
            rx: 0,
            ry: 0,
            src: "",
            stroke: "#000",
            "stroke-dasharray": "",
            "stroke-linecap": "butt",
            "stroke-linejoin": "butt",
            "stroke-miterlimit": 0,
            "stroke-opacity": 1,
            "stroke-width": 1,
            target: "_blank",
            "text-anchor": "middle",
            title: "Raphael",
            transform: "",
            width: 0,
            x: 0,
            y: 0
        },
        availableAnimAttrs = R._availableAnimAttrs = {
            blur: nu,
            "clip-rect": "csv",
            cx: nu,
            cy: nu,
            fill: "colour",
            "fill-opacity": nu,
            "font-size": nu,
            height: nu,
            opacity: nu,
            path: "path",
            r: nu,
            rx: nu,
            ry: nu,
            stroke: "colour",
            "stroke-opacity": nu,
            "stroke-width": nu,
            transform: "transform",
            width: nu,
            x: nu,
            y: nu
        },
        whitespace = /[\x09\x0a\x0b\x0c\x0d\x20\xa0\u1680\u180e\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u202f\u205f\u3000\u2028\u2029]/g,
        commaSpaces = /[\x09\x0a\x0b\x0c\x0d\x20\xa0\u1680\u180e\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u202f\u205f\u3000\u2028\u2029]*,[\x09\x0a\x0b\x0c\x0d\x20\xa0\u1680\u180e\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u202f\u205f\u3000\u2028\u2029]*/,
        hsrg = {hs: 1, rg: 1},
        p2s = /,?([achlmqrstvxz]),?/gi,
        pathCommand = /([achlmrqstvz])[\x09\x0a\x0b\x0c\x0d\x20\xa0\u1680\u180e\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u202f\u205f\u3000\u2028\u2029,]*((-?\d*\.?\d*(?:e[\-+]?\d+)?[\x09\x0a\x0b\x0c\x0d\x20\xa0\u1680\u180e\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u202f\u205f\u3000\u2028\u2029]*,?[\x09\x0a\x0b\x0c\x0d\x20\xa0\u1680\u180e\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u202f\u205f\u3000\u2028\u2029]*)+)/ig,
        tCommand = /([rstm])[\x09\x0a\x0b\x0c\x0d\x20\xa0\u1680\u180e\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u202f\u205f\u3000\u2028\u2029,]*((-?\d*\.?\d*(?:e[\-+]?\d+)?[\x09\x0a\x0b\x0c\x0d\x20\xa0\u1680\u180e\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u202f\u205f\u3000\u2028\u2029]*,?[\x09\x0a\x0b\x0c\x0d\x20\xa0\u1680\u180e\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u202f\u205f\u3000\u2028\u2029]*)+)/ig,
        pathValues = /(-?\d*\.?\d*(?:e[\-+]?\d+)?)[\x09\x0a\x0b\x0c\x0d\x20\xa0\u1680\u180e\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u202f\u205f\u3000\u2028\u2029]*,?[\x09\x0a\x0b\x0c\x0d\x20\xa0\u1680\u180e\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u202f\u205f\u3000\u2028\u2029]*/ig,
        radial_gradient = R._radial_gradient = /^r(?:\(([^,]+?)[\x09\x0a\x0b\x0c\x0d\x20\xa0\u1680\u180e\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u202f\u205f\u3000\u2028\u2029]*,[\x09\x0a\x0b\x0c\x0d\x20\xa0\u1680\u180e\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u202f\u205f\u3000\u2028\u2029]*([^\)]+?)\))?/,
        eldata = {},
        sortByKey = function (a, b) {
            return a.key - b.key;
        },
        sortByNumber = function (a, b) {
            return toFloat(a) - toFloat(b);
        },
        fun = function () {},
        pipe = function (x) {
            return x;
        },
        rectPath = R._rectPath = function (x, y, w, h, r) {
            if (r) {
                return [["M", x + r, y], ["l", w - r * 2, 0], ["a", r, r, 0, 0, 1, r, r], ["l", 0, h - r * 2], ["a", r, r, 0, 0, 1, -r, r], ["l", r * 2 - w, 0], ["a", r, r, 0, 0, 1, -r, -r], ["l", 0, r * 2 - h], ["a", r, r, 0, 0, 1, r, -r], ["z"]];
            }
            return [["M", x, y], ["l", w, 0], ["l", 0, h], ["l", -w, 0], ["z"]];
        },
        ellipsePath = function (x, y, rx, ry) {
            if (ry == null) {
                ry = rx;
            }
            return [["M", x, y], ["m", 0, -ry], ["a", rx, ry, 0, 1, 1, 0, 2 * ry], ["a", rx, ry, 0, 1, 1, 0, -2 * ry], ["z"]];
        },
        getPath = R._getPath = {
            path: function (el) {
                return el.attr("path");
            },
            circle: function (el) {
                var a = el.attrs;
                return ellipsePath(a.cx, a.cy, a.r);
            },
            ellipse: function (el) {
                var a = el.attrs;
                return ellipsePath(a.cx, a.cy, a.rx, a.ry);
            },
            rect: function (el) {
                var a = el.attrs;
                return rectPath(a.x, a.y, a.width, a.height, a.r);
            },
            image: function (el) {
                var a = el.attrs;
                return rectPath(a.x, a.y, a.width, a.height);
            },
            text: function (el) {
                var bbox = el._getBBox();
                return rectPath(bbox.x, bbox.y, bbox.width, bbox.height);
            },
            set : function(el) {
                var bbox = el._getBBox();
                return rectPath(bbox.x, bbox.y, bbox.width, bbox.height);
            }
        },
        /*\
         * Raphael.mapPath
         [ method ]
         **
         * Transform the path string with given matrix.
         > Parameters
         - path (string) path string
         - matrix (object) see @Matrix
         = (string) transformed path string
        \*/
        mapPath = R.mapPath = function (path, matrix) {
            if (!matrix) {
                return path;
            }
            var x, y, i, j, ii, jj, pathi;
            path = path2curve(path);
            for (i = 0, ii = path.length; i < ii; i++) {
                pathi = path[i];
                for (j = 1, jj = pathi.length; j < jj; j += 2) {
                    x = matrix.x(pathi[j], pathi[j + 1]);
                    y = matrix.y(pathi[j], pathi[j + 1]);
                    pathi[j] = x;
                    pathi[j + 1] = y;
                }
            }
            return path;
        };

    R._g = g;
    /*\
     * Raphael.type
     [ property (string) ]
     **
     * Can be â€œSVGâ€, â€œVMLâ€ or empty, depending on browser support.
    \*/
    R.type = (g.win.SVGAngle || g.doc.implementation.hasFeature("http://www.w3.org/TR/SVG11/feature#BasicStructure", "1.1") ? "SVG" : "VML");
    if (R.type == "VML") {
        var d = g.doc.createElement("div"),
            b;
        d.innerHTML = '<v:shape adj="1"/>';
        b = d.firstChild;
        b.style.behavior = "url(#default#VML)";
        if (!(b && typeof b.adj == "object")) {
            return (R.type = E);
        }
        d = null;
    }
    /*\
     * Raphael.svg
     [ property (boolean) ]
     **
     * `true` if browser supports SVG.
    \*/
    /*\
     * Raphael.vml
     [ property (boolean) ]
     **
     * `true` if browser supports VML.
    \*/
    R.svg = !(R.vml = R.type == "VML");
    R._Paper = Paper;
    /*\
     * Raphael.fn
     [ property (object) ]
     **
     * You can add your own method to the canvas. For example if you want to draw a pie chart,
     * you can create your own pie chart function and ship it as a RaphaÃ«l plugin. To do this
     * you need to extend the `Raphael.fn` object. You should modify the `fn` object before a
     * RaphaÃ«l instance is created, otherwise it will take no effect. Please note that the
     * ability for namespaced plugins was removed in Raphael 2.0. It is up to the plugin to
     * ensure any namespacing ensures proper context.
     > Usage
     | Raphael.fn.arrow = function (x1, y1, x2, y2, size) {
     |     return this.path( ... );
     | };
     | // or create namespace
     | Raphael.fn.mystuff = {
     |     arrow: function () {â€¦},
     |     star: function () {â€¦},
     |     // etcâ€¦
     | };
     | var paper = Raphael(10, 10, 630, 480);
     | // then use it
     | paper.arrow(10, 10, 30, 30, 5).attr({fill: "#f00"});
     | paper.mystuff.arrow();
     | paper.mystuff.star();
    \*/
    R.fn = paperproto = Paper.prototype = R.prototype;
    R._id = 0;
    R._oid = 0;
    /*\
     * Raphael.is
     [ method ]
     **
     * Handfull replacement for `typeof` operator.
     > Parameters
     - o (â€¦) any object or primitive
     - type (string) name of the type, i.e. â€œstringâ€, â€œfunctionâ€, â€œnumberâ€, etc.
     = (boolean) is given value is of given type
    \*/
    R.is = function (o, type) {
        type = lowerCase.call(type);
        if (type == "finite") {
            return !isnan[has](+o);
        }
        if (type == "array") {
            return o instanceof Array;
        }
        return  (type == "null" && o === null) ||
                (type == typeof o && o !== null) ||
                (type == "object" && o === Object(o)) ||
                (type == "array" && Array.isArray && Array.isArray(o)) ||
                objectToString.call(o).slice(8, -1).toLowerCase() == type;
    };

    function clone(obj) {
        if (Object(obj) !== obj) {
            return obj;
        }
        var res = new obj.constructor;
        for (var key in obj) if (obj[has](key)) {
            res[key] = clone(obj[key]);
        }
        return res;
    }

    /*\
     * Raphael.angle
     [ method ]
     **
     * Returns angle between two or three points
     > Parameters
     - x1 (number) x coord of first point
     - y1 (number) y coord of first point
     - x2 (number) x coord of second point
     - y2 (number) y coord of second point
     - x3 (number) #optional x coord of third point
     - y3 (number) #optional y coord of third point
     = (number) angle in degrees.
    \*/
    R.angle = function (x1, y1, x2, y2, x3, y3) {
        if (x3 == null) {
            var x = x1 - x2,
                y = y1 - y2;
            if (!x && !y) {
                return 0;
            }
            return (180 + math.atan2(-y, -x) * 180 / PI + 360) % 360;
        } else {
            return R.angle(x1, y1, x3, y3) - R.angle(x2, y2, x3, y3);
        }
    };
    /*\
     * Raphael.rad
     [ method ]
     **
     * Transform angle to radians
     > Parameters
     - deg (number) angle in degrees
     = (number) angle in radians.
    \*/
    R.rad = function (deg) {
        return deg % 360 * PI / 180;
    };
    /*\
     * Raphael.deg
     [ method ]
     **
     * Transform angle to degrees
     > Parameters
     - deg (number) angle in radians
     = (number) angle in degrees.
    \*/
    R.deg = function (rad) {
        return rad * 180 / PI % 360;
    };
    /*\
     * Raphael.snapTo
     [ method ]
     **
     * Snaps given value to given grid.
     > Parameters
     - values (array|number) given array of values or step of the grid
     - value (number) value to adjust
     - tolerance (number) #optional tolerance for snapping. Default is `10`.
     = (number) adjusted value.
    \*/
    R.snapTo = function (values, value, tolerance) {
        tolerance = R.is(tolerance, "finite") ? tolerance : 10;
        if (R.is(values, array)) {
            var i = values.length;
            while (i--) if (abs(values[i] - value) <= tolerance) {
                return values[i];
            }
        } else {
            values = +values;
            var rem = value % values;
            if (rem < tolerance) {
                return value - rem;
            }
            if (rem > values - tolerance) {
                return value - rem + values;
            }
        }
        return value;
    };
    
    /*\
     * Raphael.createUUID
     [ method ]
     **
     * Returns RFC4122, version 4 ID
    \*/
    var createUUID = R.createUUID = (function (uuidRegEx, uuidReplacer) {
        return function () {
            return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(uuidRegEx, uuidReplacer).toUpperCase();
        };
    })(/[xy]/g, function (c) {
        var r = math.random() * 16 | 0,
            v = c == "x" ? r : (r & 3 | 8);
        return v.toString(16);
    });

    /*\
     * Raphael.setWindow
     [ method ]
     **
     * Used when you need to draw in `&lt;iframe>`. Switched window to the iframe one.
     > Parameters
     - newwin (window) new window object
    \*/
    R.setWindow = function (newwin) {
        eve("raphael.setWindow", R, g.win, newwin);
        g.win = newwin;
        g.doc = g.win.document;
        if (R._engine.initWin) {
            R._engine.initWin(g.win);
        }
    };
    var toHex = function (color) {
        if (R.vml) {
            // http://dean.edwards.name/weblog/2009/10/convert-any-colour-value-to-hex-in-msie/
            var trim = /^\s+|\s+$/g;
            var bod;
            try {
                var docum = new ActiveXObject("htmlfile");
                docum.write("<body>");
                docum.close();
                bod = docum.body;
            } catch(e) {
                bod = createPopup().document.body;
            }
            var range = bod.createTextRange();
            toHex = cacher(function (color) {
                try {
                    bod.style.color = Str(color).replace(trim, E);
                    var value = range.queryCommandValue("ForeColor");
                    value = ((value & 255) << 16) | (value & 65280) | ((value & 16711680) >>> 16);
                    return "#" + ("000000" + value.toString(16)).slice(-6);
                } catch(e) {
                    return "none";
                }
            });
        } else {
            var i = g.doc.createElement("i");
            i.title = "Rapha\xebl Colour Picker";
            i.style.display = "none";
            g.doc.body.appendChild(i);
            toHex = cacher(function (color) {
                i.style.color = color;
                return g.doc.defaultView.getComputedStyle(i, E).getPropertyValue("color");
            });
        }
        return toHex(color);
    },
    hsbtoString = function () {
        return "hsb(" + [this.h, this.s, this.b] + ")";
    },
    hsltoString = function () {
        return "hsl(" + [this.h, this.s, this.l] + ")";
    },
    rgbtoString = function () {
        return this.hex;
    },
    prepareRGB = function (r, g, b) {
        if (g == null && R.is(r, "object") && "r" in r && "g" in r && "b" in r) {
            b = r.b;
            g = r.g;
            r = r.r;
        }
        if (g == null && R.is(r, string)) {
            var clr = R.getRGB(r);
            r = clr.r;
            g = clr.g;
            b = clr.b;
        }
        if (r > 1 || g > 1 || b > 1) {
            r /= 255;
            g /= 255;
            b /= 255;
        }
        
        return [r, g, b];
    },
    packageRGB = function (r, g, b, o) {
        r *= 255;
        g *= 255;
        b *= 255;
        var rgb = {
            r: r,
            g: g,
            b: b,
            hex: R.rgb(r, g, b),
            toString: rgbtoString
        };
        R.is(o, "finite") && (rgb.opacity = o);
        return rgb;
    };
    
    /*\
     * Raphael.color
     [ method ]
     **
     * Parses the color string and returns object with all values for the given color.
     > Parameters
     - clr (string) color string in one of the supported formats (see @Raphael.getRGB)
     = (object) Combined RGB & HSB object in format:
     o {
     o     r (number) red,
     o     g (number) green,
     o     b (number) blue,
     o     hex (string) color in HTML/CSS format: #â€¢â€¢â€¢â€¢â€¢â€¢,
     o     error (boolean) `true` if string canâ€™t be parsed,
     o     h (number) hue,
     o     s (number) saturation,
     o     v (number) value (brightness),
     o     l (number) lightness
     o }
    \*/
    R.color = function (clr) {
        var rgb;
        if (R.is(clr, "object") && "h" in clr && "s" in clr && "b" in clr) {
            rgb = R.hsb2rgb(clr);
            clr.r = rgb.r;
            clr.g = rgb.g;
            clr.b = rgb.b;
            clr.hex = rgb.hex;
        } else if (R.is(clr, "object") && "h" in clr && "s" in clr && "l" in clr) {
            rgb = R.hsl2rgb(clr);
            clr.r = rgb.r;
            clr.g = rgb.g;
            clr.b = rgb.b;
            clr.hex = rgb.hex;
        } else {
            if (R.is(clr, "string")) {
                clr = R.getRGB(clr);
            }
            if (R.is(clr, "object") && "r" in clr && "g" in clr && "b" in clr) {
                rgb = R.rgb2hsl(clr);
                clr.h = rgb.h;
                clr.s = rgb.s;
                clr.l = rgb.l;
                rgb = R.rgb2hsb(clr);
                clr.v = rgb.b;
            } else {
                clr = {hex: "none"};
                clr.r = clr.g = clr.b = clr.h = clr.s = clr.v = clr.l = -1;
            }
        }
        clr.toString = rgbtoString;
        return clr;
    };
    /*\
     * Raphael.hsb2rgb
     [ method ]
     **
     * Converts HSB values to RGB object.
     > Parameters
     - h (number) hue
     - s (number) saturation
     - v (number) value or brightness
     = (object) RGB object in format:
     o {
     o     r (number) red,
     o     g (number) green,
     o     b (number) blue,
     o     hex (string) color in HTML/CSS format: #â€¢â€¢â€¢â€¢â€¢â€¢
     o }
    \*/
    R.hsb2rgb = function (h, s, v, o) {
        if (this.is(h, "object") && "h" in h && "s" in h && "b" in h) {
            v = h.b;
            s = h.s;
            h = h.h;
            o = h.o;
        }
        h *= 360;
        var R, G, B, X, C;
        h = (h % 360) / 60;
        C = v * s;
        X = C * (1 - abs(h % 2 - 1));
        R = G = B = v - C;

        h = ~~h;
        R += [C, X, 0, 0, X, C][h];
        G += [X, C, C, X, 0, 0][h];
        B += [0, 0, X, C, C, X][h];
        return packageRGB(R, G, B, o);
    };
    /*\
     * Raphael.hsl2rgb
     [ method ]
     **
     * Converts HSL values to RGB object.
     > Parameters
     - h (number) hue
     - s (number) saturation
     - l (number) luminosity
     = (object) RGB object in format:
     o {
     o     r (number) red,
     o     g (number) green,
     o     b (number) blue,
     o     hex (string) color in HTML/CSS format: #â€¢â€¢â€¢â€¢â€¢â€¢
     o }
    \*/
    R.hsl2rgb = function (h, s, l, o) {
        if (this.is(h, "object") && "h" in h && "s" in h && "l" in h) {
            l = h.l;
            s = h.s;
            h = h.h;
        }
        if (h > 1 || s > 1 || l > 1) {
            h /= 360;
            s /= 100;
            l /= 100;
        }
        h *= 360;
        var R, G, B, X, C;
        h = (h % 360) / 60;
        C = 2 * s * (l < .5 ? l : 1 - l);
        X = C * (1 - abs(h % 2 - 1));
        R = G = B = l - C / 2;

        h = ~~h;
        R += [C, X, 0, 0, X, C][h];
        G += [X, C, C, X, 0, 0][h];
        B += [0, 0, X, C, C, X][h];
        return packageRGB(R, G, B, o);
    };
    /*\
     * Raphael.rgb2hsb
     [ method ]
     **
     * Converts RGB values to HSB object.
     > Parameters
     - r (number) red
     - g (number) green
     - b (number) blue
     = (object) HSB object in format:
     o {
     o     h (number) hue
     o     s (number) saturation
     o     b (number) brightness
     o }
    \*/
    R.rgb2hsb = function (r, g, b) {
        b = prepareRGB(r, g, b);
        r = b[0];
        g = b[1];
        b = b[2];

        var H, S, V, C;
        V = mmax(r, g, b);
        C = V - mmin(r, g, b);
        H = (C == 0 ? null :
             V == r ? (g - b) / C :
             V == g ? (b - r) / C + 2 :
                      (r - g) / C + 4
            );
        H = ((H + 360) % 6) * 60 / 360;
        S = C == 0 ? 0 : C / V;
        return {h: H, s: S, b: V, toString: hsbtoString};
    };
    /*\
     * Raphael.rgb2hsl
     [ method ]
     **
     * Converts RGB values to HSL object.
     > Parameters
     - r (number) red
     - g (number) green
     - b (number) blue
     = (object) HSL object in format:
     o {
     o     h (number) hue
     o     s (number) saturation
     o     l (number) luminosity
     o }
    \*/
    R.rgb2hsl = function (r, g, b) {
        b = prepareRGB(r, g, b);
        r = b[0];
        g = b[1];
        b = b[2];

        var H, S, L, M, m, C;
        M = mmax(r, g, b);
        m = mmin(r, g, b);
        C = M - m;
        H = (C == 0 ? null :
             M == r ? (g - b) / C :
             M == g ? (b - r) / C + 2 :
                      (r - g) / C + 4);
        H = ((H + 360) % 6) * 60 / 360;
        L = (M + m) / 2;
        S = (C == 0 ? 0 :
             L < .5 ? C / (2 * L) :
                      C / (2 - 2 * L));
        return {h: H, s: S, l: L, toString: hsltoString};
    };
    R._path2string = function () {
        return this.join(",").replace(p2s, "$1");
    };
    function repush(array, item) {
        for (var i = 0, ii = array.length; i < ii; i++) if (array[i] === item) {
            return array.push(array.splice(i, 1)[0]);
        }
    }
    function cacher(f, scope, postprocessor) {
        function newf() {
            var arg = Array.prototype.slice.call(arguments, 0),
                args = arg.join("\u2400"),
                cache = newf.cache = newf.cache || {},
                count = newf.count = newf.count || [];
            if (cache[has](args)) {
                repush(count, args);
                return postprocessor ? postprocessor(cache[args]) : cache[args];
            }
            count.length >= 1e3 && delete cache[count.shift()];
            count.push(args);
            cache[args] = f[apply](scope, arg);
            return postprocessor ? postprocessor(cache[args]) : cache[args];
        }
        return newf;
    }

    var preload = R._preload = function (src, f) {
        var img = g.doc.createElement("img");
        img.style.cssText = "position:absolute;left:-9999em;top:-9999em";
        img.onload = function () {
            f.call(this);
            this.onload = null;
            g.doc.body.removeChild(this);
        };
        img.onerror = function () {
            g.doc.body.removeChild(this);
        };
        g.doc.body.appendChild(img);
        img.src = src;
    };
    
    function clrToString() {
        return this.hex;
    }

    /*\
     * Raphael.getRGB
     [ method ]
     **
     * Parses colour string as RGB object
     > Parameters
     - colour (string) colour string in one of formats:
     # <ul>
     #     <li>Colour name (â€œ<code>red</code>â€, â€œ<code>green</code>â€, â€œ<code>cornflowerblue</code>â€, etc)</li>
     #     <li>#â€¢â€¢â€¢ â€” shortened HTML colour: (â€œ<code>#000</code>â€, â€œ<code>#fc0</code>â€, etc)</li>
     #     <li>#â€¢â€¢â€¢â€¢â€¢â€¢ â€” full length HTML colour: (â€œ<code>#000000</code>â€, â€œ<code>#bd2300</code>â€)</li>
     #     <li>rgb(â€¢â€¢â€¢, â€¢â€¢â€¢, â€¢â€¢â€¢) â€” red, green and blue channelsâ€™ values: (â€œ<code>rgb(200,&nbsp;100,&nbsp;0)</code>â€)</li>
     #     <li>rgb(â€¢â€¢â€¢%, â€¢â€¢â€¢%, â€¢â€¢â€¢%) â€” same as above, but in %: (â€œ<code>rgb(100%,&nbsp;175%,&nbsp;0%)</code>â€)</li>
     #     <li>hsb(â€¢â€¢â€¢, â€¢â€¢â€¢, â€¢â€¢â€¢) â€” hue, saturation and brightness values: (â€œ<code>hsb(0.5,&nbsp;0.25,&nbsp;1)</code>â€)</li>
     #     <li>hsb(â€¢â€¢â€¢%, â€¢â€¢â€¢%, â€¢â€¢â€¢%) â€” same as above, but in %</li>
     #     <li>hsl(â€¢â€¢â€¢, â€¢â€¢â€¢, â€¢â€¢â€¢) â€” same as hsb</li>
     #     <li>hsl(â€¢â€¢â€¢%, â€¢â€¢â€¢%, â€¢â€¢â€¢%) â€” same as hsb</li>
     # </ul>
     = (object) RGB object in format:
     o {
     o     r (number) red,
     o     g (number) green,
     o     b (number) blue
     o     hex (string) color in HTML/CSS format: #â€¢â€¢â€¢â€¢â€¢â€¢,
     o     error (boolean) true if string canâ€™t be parsed
     o }
    \*/
    R.getRGB = cacher(function (colour) {
        if (!colour || !!((colour = Str(colour)).indexOf("-") + 1)) {
            return {r: -1, g: -1, b: -1, hex: "none", error: 1, toString: clrToString};
        }
        if (colour == "none") {
            return {r: -1, g: -1, b: -1, hex: "none", toString: clrToString};
        }
        !(hsrg[has](colour.toLowerCase().substring(0, 2)) || colour.charAt() == "#") && (colour = toHex(colour));
        var res,
            red,
            green,
            blue,
            opacity,
            t,
            values,
            rgb = colour.match(colourRegExp);
        if (rgb) {
            if (rgb[2]) {
                blue = toInt(rgb[2].substring(5), 16);
                green = toInt(rgb[2].substring(3, 5), 16);
                red = toInt(rgb[2].substring(1, 3), 16);
            }
            if (rgb[3]) {
                blue = toInt((t = rgb[3].charAt(3)) + t, 16);
                green = toInt((t = rgb[3].charAt(2)) + t, 16);
                red = toInt((t = rgb[3].charAt(1)) + t, 16);
            }
            if (rgb[4]) {
                values = rgb[4][split](commaSpaces);
                red = toFloat(values[0]);
                values[0].slice(-1) == "%" && (red *= 2.55);
                green = toFloat(values[1]);
                values[1].slice(-1) == "%" && (green *= 2.55);
                blue = toFloat(values[2]);
                values[2].slice(-1) == "%" && (blue *= 2.55);
                rgb[1].toLowerCase().slice(0, 4) == "rgba" && (opacity = toFloat(values[3]));
                values[3] && values[3].slice(-1) == "%" && (opacity /= 100);
            }
            if (rgb[5]) {
                values = rgb[5][split](commaSpaces);
                red = toFloat(values[0]);
                values[0].slice(-1) == "%" && (red *= 2.55);
                green = toFloat(values[1]);
                values[1].slice(-1) == "%" && (green *= 2.55);
                blue = toFloat(values[2]);
                values[2].slice(-1) == "%" && (blue *= 2.55);
                (values[0].slice(-3) == "deg" || values[0].slice(-1) == "\xb0") && (red /= 360);
                rgb[1].toLowerCase().slice(0, 4) == "hsba" && (opacity = toFloat(values[3]));
                values[3] && values[3].slice(-1) == "%" && (opacity /= 100);
                return R.hsb2rgb(red, green, blue, opacity);
            }
            if (rgb[6]) {
                values = rgb[6][split](commaSpaces);
                red = toFloat(values[0]);
                values[0].slice(-1) == "%" && (red *= 2.55);
                green = toFloat(values[1]);
                values[1].slice(-1) == "%" && (green *= 2.55);
                blue = toFloat(values[2]);
                values[2].slice(-1) == "%" && (blue *= 2.55);
                (values[0].slice(-3) == "deg" || values[0].slice(-1) == "\xb0") && (red /= 360);
                rgb[1].toLowerCase().slice(0, 4) == "hsla" && (opacity = toFloat(values[3]));
                values[3] && values[3].slice(-1) == "%" && (opacity /= 100);
                return R.hsl2rgb(red, green, blue, opacity);
            }
            rgb = {r: red, g: green, b: blue, toString: clrToString};
            rgb.hex = "#" + (16777216 | blue | (green << 8) | (red << 16)).toString(16).slice(1);
            R.is(opacity, "finite") && (rgb.opacity = opacity);
            return rgb;
        }
        return {r: -1, g: -1, b: -1, hex: "none", error: 1, toString: clrToString};
    }, R);
    /*\
     * Raphael.hsb
     [ method ]
     **
     * Converts HSB values to hex representation of the colour.
     > Parameters
     - h (number) hue
     - s (number) saturation
     - b (number) value or brightness
     = (string) hex representation of the colour.
    \*/
    R.hsb = cacher(function (h, s, b) {
        return R.hsb2rgb(h, s, b).hex;
    });
    /*\
     * Raphael.hsl
     [ method ]
     **
     * Converts HSL values to hex representation of the colour.
     > Parameters
     - h (number) hue
     - s (number) saturation
     - l (number) luminosity
     = (string) hex representation of the colour.
    \*/
    R.hsl = cacher(function (h, s, l) {
        return R.hsl2rgb(h, s, l).hex;
    });
    /*\
     * Raphael.rgb
     [ method ]
     **
     * Converts RGB values to hex representation of the colour.
     > Parameters
     - r (number) red
     - g (number) green
     - b (number) blue
     = (string) hex representation of the colour.
    \*/
    R.rgb = cacher(function (r, g, b) {
        return "#" + (16777216 | b | (g << 8) | (r << 16)).toString(16).slice(1);
    });
    /*\
     * Raphael.getColor
     [ method ]
     **
     * On each call returns next colour in the spectrum. To reset it back to red call @Raphael.getColor.reset
     > Parameters
     - value (number) #optional brightness, default is `0.75`
     = (string) hex representation of the colour.
    \*/
    R.getColor = function (value) {
        var start = this.getColor.start = this.getColor.start || {h: 0, s: 1, b: value || .75},
            rgb = this.hsb2rgb(start.h, start.s, start.b);
        start.h += .075;
        if (start.h > 1) {
            start.h = 0;
            start.s -= .2;
            start.s <= 0 && (this.getColor.start = {h: 0, s: 1, b: start.b});
        }
        return rgb.hex;
    };
    /*\
     * Raphael.getColor.reset
     [ method ]
     **
     * Resets spectrum position for @Raphael.getColor back to red.
    \*/
    R.getColor.reset = function () {
        delete this.start;
    };

    // http://schepers.cc/getting-to-the-point
    function catmullRom2bezier(crp, z) {
        var d = [];
        for (var i = 0, iLen = crp.length; iLen - 2 * !z > i; i += 2) {
            var p = [
                        {x: +crp[i - 2], y: +crp[i - 1]},
                        {x: +crp[i],     y: +crp[i + 1]},
                        {x: +crp[i + 2], y: +crp[i + 3]},
                        {x: +crp[i + 4], y: +crp[i + 5]}
                    ];
            if (z) {
                if (!i) {
                    p[0] = {x: +crp[iLen - 2], y: +crp[iLen - 1]};
                } else if (iLen - 4 == i) {
                    p[3] = {x: +crp[0], y: +crp[1]};
                } else if (iLen - 2 == i) {
                    p[2] = {x: +crp[0], y: +crp[1]};
                    p[3] = {x: +crp[2], y: +crp[3]};
                }
            } else {
                if (iLen - 4 == i) {
                    p[3] = p[2];
                } else if (!i) {
                    p[0] = {x: +crp[i], y: +crp[i + 1]};
                }
            }
            d.push(["C",
                  (-p[0].x + 6 * p[1].x + p[2].x) / 6,
                  (-p[0].y + 6 * p[1].y + p[2].y) / 6,
                  (p[1].x + 6 * p[2].x - p[3].x) / 6,
                  (p[1].y + 6*p[2].y - p[3].y) / 6,
                  p[2].x,
                  p[2].y
            ]);
        }

        return d;
    }
    /*\
     * Raphael.parsePathString
     [ method ]
     **
     * Utility method
     **
     * Parses given path string into an array of arrays of path segments.
     > Parameters
     - pathString (string|array) path string or array of segments (in the last case it will be returned straight away)
     = (array) array of segments.
    \*/
    R.parsePathString = function (pathString) {
        if (!pathString) {
            return null;
        }
        var pth = paths(pathString);
        if (pth.arr) {
            return pathClone(pth.arr);
        }
        
        var paramCounts = {a: 7, c: 6, h: 1, l: 2, m: 2, r: 4, q: 4, s: 4, t: 2, v: 1, z: 0},
            data = [];
        if (R.is(pathString, array) && R.is(pathString[0], array)) { // rough assumption
            data = pathClone(pathString);
        }
        if (!data.length) {
            Str(pathString).replace(pathCommand, function (a, b, c) {
                var params = [],
                    name = b.toLowerCase();
                c.replace(pathValues, function (a, b) {
                    b && params.push(+b);
                });
                if (name == "m" && params.length > 2) {
                    data.push([b][concat](params.splice(0, 2)));
                    name = "l";
                    b = b == "m" ? "l" : "L";
                }
                if (name == "r") {
                    data.push([b][concat](params));
                } else while (params.length >= paramCounts[name]) {
                    data.push([b][concat](params.splice(0, paramCounts[name])));
                    if (!paramCounts[name]) {
                        break;
                    }
                }
            });
        }
        data.toString = R._path2string;
        pth.arr = pathClone(data);
        return data;
    };
    /*\
     * Raphael.parseTransformString
     [ method ]
     **
     * Utility method
     **
     * Parses given path string into an array of transformations.
     > Parameters
     - TString (string|array) transform string or array of transformations (in the last case it will be returned straight away)
     = (array) array of transformations.
    \*/
    R.parseTransformString = cacher(function (TString) {
        if (!TString) {
            return null;
        }
        var paramCounts = {r: 3, s: 4, t: 2, m: 6},
            data = [];
        if (R.is(TString, array) && R.is(TString[0], array)) { // rough assumption
            data = pathClone(TString);
        }
        if (!data.length) {
            Str(TString).replace(tCommand, function (a, b, c) {
                var params = [],
                    name = lowerCase.call(b);
                c.replace(pathValues, function (a, b) {
                    b && params.push(+b);
                });
                data.push([b][concat](params));
            });
        }
        data.toString = R._path2string;
        return data;
    });
    // PATHS
    var paths = function (ps) {
        var p = paths.ps = paths.ps || {};
        if (p[ps]) {
            p[ps].sleep = 100;
        } else {
            p[ps] = {
                sleep: 100
            };
        }
        setTimeout(function () {
            for (var key in p) if (p[has](key) && key != ps) {
                p[key].sleep--;
                !p[key].sleep && delete p[key];
            }
        });
        return p[ps];
    };
    /*\
     * Raphael.findDotsAtSegment
     [ method ]
     **
     * Utility method
     **
     * Find dot coordinates on the given cubic bezier curve at the given t.
     > Parameters
     - p1x (number) x of the first point of the curve
     - p1y (number) y of the first point of the curve
     - c1x (number) x of the first anchor of the curve
     - c1y (number) y of the first anchor of the curve
     - c2x (number) x of the second anchor of the curve
     - c2y (number) y of the second anchor of the curve
     - p2x (number) x of the second point of the curve
     - p2y (number) y of the second point of the curve
     - t (number) position on the curve (0..1)
     = (object) point information in format:
     o {
     o     x: (number) x coordinate of the point
     o     y: (number) y coordinate of the point
     o     m: {
     o         x: (number) x coordinate of the left anchor
     o         y: (number) y coordinate of the left anchor
     o     }
     o     n: {
     o         x: (number) x coordinate of the right anchor
     o         y: (number) y coordinate of the right anchor
     o     }
     o     start: {
     o         x: (number) x coordinate of the start of the curve
     o         y: (number) y coordinate of the start of the curve
     o     }
     o     end: {
     o         x: (number) x coordinate of the end of the curve
     o         y: (number) y coordinate of the end of the curve
     o     }
     o     alpha: (number) angle of the curve derivative at the point
     o }
    \*/
    R.findDotsAtSegment = function (p1x, p1y, c1x, c1y, c2x, c2y, p2x, p2y, t) {
        var t1 = 1 - t,
            t13 = pow(t1, 3),
            t12 = pow(t1, 2),
            t2 = t * t,
            t3 = t2 * t,
            x = t13 * p1x + t12 * 3 * t * c1x + t1 * 3 * t * t * c2x + t3 * p2x,
            y = t13 * p1y + t12 * 3 * t * c1y + t1 * 3 * t * t * c2y + t3 * p2y,
            mx = p1x + 2 * t * (c1x - p1x) + t2 * (c2x - 2 * c1x + p1x),
            my = p1y + 2 * t * (c1y - p1y) + t2 * (c2y - 2 * c1y + p1y),
            nx = c1x + 2 * t * (c2x - c1x) + t2 * (p2x - 2 * c2x + c1x),
            ny = c1y + 2 * t * (c2y - c1y) + t2 * (p2y - 2 * c2y + c1y),
            ax = t1 * p1x + t * c1x,
            ay = t1 * p1y + t * c1y,
            cx = t1 * c2x + t * p2x,
            cy = t1 * c2y + t * p2y,
            alpha = (90 - math.atan2(mx - nx, my - ny) * 180 / PI);
        (mx > nx || my < ny) && (alpha += 180);
        return {
            x: x,
            y: y,
            m: {x: mx, y: my},
            n: {x: nx, y: ny},
            start: {x: ax, y: ay},
            end: {x: cx, y: cy},
            alpha: alpha
        };
    };
    /*\
     * Raphael.bezierBBox
     [ method ]
     **
     * Utility method
     **
     * Return bounding box of a given cubic bezier curve
     > Parameters
     - p1x (number) x of the first point of the curve
     - p1y (number) y of the first point of the curve
     - c1x (number) x of the first anchor of the curve
     - c1y (number) y of the first anchor of the curve
     - c2x (number) x of the second anchor of the curve
     - c2y (number) y of the second anchor of the curve
     - p2x (number) x of the second point of the curve
     - p2y (number) y of the second point of the curve
     * or
     - bez (array) array of six points for bezier curve
     = (object) point information in format:
     o {
     o     min: {
     o         x: (number) x coordinate of the left point
     o         y: (number) y coordinate of the top point
     o     }
     o     max: {
     o         x: (number) x coordinate of the right point
     o         y: (number) y coordinate of the bottom point
     o     }
     o }
    \*/
    R.bezierBBox = function (p1x, p1y, c1x, c1y, c2x, c2y, p2x, p2y) {
        if (!R.is(p1x, "array")) {
            p1x = [p1x, p1y, c1x, c1y, c2x, c2y, p2x, p2y];
        }
        var bbox = curveDim.apply(null, p1x);
        return {
            x: bbox.min.x,
            y: bbox.min.y,
            x2: bbox.max.x,
            y2: bbox.max.y,
            width: bbox.max.x - bbox.min.x,
            height: bbox.max.y - bbox.min.y
        };
    };
    /*\
     * Raphael.isPointInsideBBox
     [ method ]
     **
     * Utility method
     **
     * Returns `true` if given point is inside bounding boxes.
     > Parameters
     - bbox (string) bounding box
     - x (string) x coordinate of the point
     - y (string) y coordinate of the point
     = (boolean) `true` if point inside
    \*/
    R.isPointInsideBBox = function (bbox, x, y) {
        return x >= bbox.x && x <= bbox.x2 && y >= bbox.y && y <= bbox.y2;
    };
    /*\
     * Raphael.isBBoxIntersect
     [ method ]
     **
     * Utility method
     **
     * Returns `true` if two bounding boxes intersect
     > Parameters
     - bbox1 (string) first bounding box
     - bbox2 (string) second bounding box
     = (boolean) `true` if they intersect
    \*/
    R.isBBoxIntersect = function (bbox1, bbox2) {
        var i = R.isPointInsideBBox;
        return i(bbox2, bbox1.x, bbox1.y)
            || i(bbox2, bbox1.x2, bbox1.y)
            || i(bbox2, bbox1.x, bbox1.y2)
            || i(bbox2, bbox1.x2, bbox1.y2)
            || i(bbox1, bbox2.x, bbox2.y)
            || i(bbox1, bbox2.x2, bbox2.y)
            || i(bbox1, bbox2.x, bbox2.y2)
            || i(bbox1, bbox2.x2, bbox2.y2)
            || (bbox1.x < bbox2.x2 && bbox1.x > bbox2.x || bbox2.x < bbox1.x2 && bbox2.x > bbox1.x)
            && (bbox1.y < bbox2.y2 && bbox1.y > bbox2.y || bbox2.y < bbox1.y2 && bbox2.y > bbox1.y);
    };
    function base3(t, p1, p2, p3, p4) {
        var t1 = -3 * p1 + 9 * p2 - 9 * p3 + 3 * p4,
            t2 = t * t1 + 6 * p1 - 12 * p2 + 6 * p3;
        return t * t2 - 3 * p1 + 3 * p2;
    }
    function bezlen(x1, y1, x2, y2, x3, y3, x4, y4, z) {
        if (z == null) {
            z = 1;
        }
        z = z > 1 ? 1 : z < 0 ? 0 : z;
        var z2 = z / 2,
            n = 12,
            Tvalues = [-0.1252,0.1252,-0.3678,0.3678,-0.5873,0.5873,-0.7699,0.7699,-0.9041,0.9041,-0.9816,0.9816],
            Cvalues = [0.2491,0.2491,0.2335,0.2335,0.2032,0.2032,0.1601,0.1601,0.1069,0.1069,0.0472,0.0472],
            sum = 0;
        for (var i = 0; i < n; i++) {
            var ct = z2 * Tvalues[i] + z2,
                xbase = base3(ct, x1, x2, x3, x4),
                ybase = base3(ct, y1, y2, y3, y4),
                comb = xbase * xbase + ybase * ybase;
            sum += Cvalues[i] * math.sqrt(comb);
        }
        return z2 * sum;
    }
    function getTatLen(x1, y1, x2, y2, x3, y3, x4, y4, ll) {
        if (ll < 0 || bezlen(x1, y1, x2, y2, x3, y3, x4, y4) < ll) {
            return;
        }
        var t = 1,
            step = t / 2,
            t2 = t - step,
            l,
            e = .01;
        l = bezlen(x1, y1, x2, y2, x3, y3, x4, y4, t2);
        while (abs(l - ll) > e) {
            step /= 2;
            t2 += (l < ll ? 1 : -1) * step;
            l = bezlen(x1, y1, x2, y2, x3, y3, x4, y4, t2);
        }
        return t2;
    }
    function intersect(x1, y1, x2, y2, x3, y3, x4, y4) {
        if (
            mmax(x1, x2) < mmin(x3, x4) ||
            mmin(x1, x2) > mmax(x3, x4) ||
            mmax(y1, y2) < mmin(y3, y4) ||
            mmin(y1, y2) > mmax(y3, y4)
        ) {
            return;
        }
        var nx = (x1 * y2 - y1 * x2) * (x3 - x4) - (x1 - x2) * (x3 * y4 - y3 * x4),
            ny = (x1 * y2 - y1 * x2) * (y3 - y4) - (y1 - y2) * (x3 * y4 - y3 * x4),
            denominator = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4);

        if (!denominator) {
            return;
        }
        var px = nx / denominator,
            py = ny / denominator,
            px2 = +px.toFixed(2),
            py2 = +py.toFixed(2);
        if (
            px2 < +mmin(x1, x2).toFixed(2) ||
            px2 > +mmax(x1, x2).toFixed(2) ||
            px2 < +mmin(x3, x4).toFixed(2) ||
            px2 > +mmax(x3, x4).toFixed(2) ||
            py2 < +mmin(y1, y2).toFixed(2) ||
            py2 > +mmax(y1, y2).toFixed(2) ||
            py2 < +mmin(y3, y4).toFixed(2) ||
            py2 > +mmax(y3, y4).toFixed(2)
        ) {
            return;
        }
        return {x: px, y: py};
    }
    function inter(bez1, bez2) {
        return interHelper(bez1, bez2);
    }
    function interCount(bez1, bez2) {
        return interHelper(bez1, bez2, 1);
    }
    function interHelper(bez1, bez2, justCount) {
        var bbox1 = R.bezierBBox(bez1),
            bbox2 = R.bezierBBox(bez2);
        if (!R.isBBoxIntersect(bbox1, bbox2)) {
            return justCount ? 0 : [];
        }
        var l1 = bezlen.apply(0, bez1),
            l2 = bezlen.apply(0, bez2),
            n1 = ~~(l1 / 5),
            n2 = ~~(l2 / 5),
            dots1 = [],
            dots2 = [],
            xy = {},
            res = justCount ? 0 : [];
        for (var i = 0; i < n1 + 1; i++) {
            var p = R.findDotsAtSegment.apply(R, bez1.concat(i / n1));
            dots1.push({x: p.x, y: p.y, t: i / n1});
        }
        for (i = 0; i < n2 + 1; i++) {
            p = R.findDotsAtSegment.apply(R, bez2.concat(i / n2));
            dots2.push({x: p.x, y: p.y, t: i / n2});
        }
        for (i = 0; i < n1; i++) {
            for (var j = 0; j < n2; j++) {
                var di = dots1[i],
                    di1 = dots1[i + 1],
                    dj = dots2[j],
                    dj1 = dots2[j + 1],
                    ci = abs(di1.x - di.x) < .001 ? "y" : "x",
                    cj = abs(dj1.x - dj.x) < .001 ? "y" : "x",
                    is = intersect(di.x, di.y, di1.x, di1.y, dj.x, dj.y, dj1.x, dj1.y);
                if (is) {
                    if (xy[is.x.toFixed(4)] == is.y.toFixed(4)) {
                        continue;
                    }
                    xy[is.x.toFixed(4)] = is.y.toFixed(4);
                    var t1 = di.t + abs((is[ci] - di[ci]) / (di1[ci] - di[ci])) * (di1.t - di.t),
                        t2 = dj.t + abs((is[cj] - dj[cj]) / (dj1[cj] - dj[cj])) * (dj1.t - dj.t);
                    if (t1 >= 0 && t1 <= 1 && t2 >= 0 && t2 <= 1) {
                        if (justCount) {
                            res++;
                        } else {
                            res.push({
                                x: is.x,
                                y: is.y,
                                t1: t1,
                                t2: t2
                            });
                        }
                    }
                }
            }
        }
        return res;
    }
    /*\
     * Raphael.pathIntersection
     [ method ]
     **
     * Utility method
     **
     * Finds intersections of two paths
     > Parameters
     - path1 (string) path string
     - path2 (string) path string
     = (array) dots of intersection
     o [
     o     {
     o         x: (number) x coordinate of the point
     o         y: (number) y coordinate of the point
     o         t1: (number) t value for segment of path1
     o         t2: (number) t value for segment of path2
     o         segment1: (number) order number for segment of path1
     o         segment2: (number) order number for segment of path2
     o         bez1: (array) eight coordinates representing beziÃ©r curve for the segment of path1
     o         bez2: (array) eight coordinates representing beziÃ©r curve for the segment of path2
     o     }
     o ]
    \*/
    R.pathIntersection = function (path1, path2) {
        return interPathHelper(path1, path2);
    };
    R.pathIntersectionNumber = function (path1, path2) {
        return interPathHelper(path1, path2, 1);
    };
    function interPathHelper(path1, path2, justCount) {
        path1 = R._path2curve(path1);
        path2 = R._path2curve(path2);
        var x1, y1, x2, y2, x1m, y1m, x2m, y2m, bez1, bez2,
            res = justCount ? 0 : [];
        for (var i = 0, ii = path1.length; i < ii; i++) {
            var pi = path1[i];
            if (pi[0] == "M") {
                x1 = x1m = pi[1];
                y1 = y1m = pi[2];
            } else {
                if (pi[0] == "C") {
                    bez1 = [x1, y1].concat(pi.slice(1));
                    x1 = bez1[6];
                    y1 = bez1[7];
                } else {
                    bez1 = [x1, y1, x1, y1, x1m, y1m, x1m, y1m];
                    x1 = x1m;
                    y1 = y1m;
                }
                for (var j = 0, jj = path2.length; j < jj; j++) {
                    var pj = path2[j];
                    if (pj[0] == "M") {
                        x2 = x2m = pj[1];
                        y2 = y2m = pj[2];
                    } else {
                        if (pj[0] == "C") {
                            bez2 = [x2, y2].concat(pj.slice(1));
                            x2 = bez2[6];
                            y2 = bez2[7];
                        } else {
                            bez2 = [x2, y2, x2, y2, x2m, y2m, x2m, y2m];
                            x2 = x2m;
                            y2 = y2m;
                        }
                        var intr = interHelper(bez1, bez2, justCount);
                        if (justCount) {
                            res += intr;
                        } else {
                            for (var k = 0, kk = intr.length; k < kk; k++) {
                                intr[k].segment1 = i;
                                intr[k].segment2 = j;
                                intr[k].bez1 = bez1;
                                intr[k].bez2 = bez2;
                            }
                            res = res.concat(intr);
                        }
                    }
                }
            }
        }
        return res;
    }
    /*\
     * Raphael.isPointInsidePath
     [ method ]
     **
     * Utility method
     **
     * Returns `true` if given point is inside a given closed path.
     > Parameters
     - path (string) path string
     - x (number) x of the point
     - y (number) y of the point
     = (boolean) true, if point is inside the path
    \*/
    R.isPointInsidePath = function (path, x, y) {
        var bbox = R.pathBBox(path);
        return R.isPointInsideBBox(bbox, x, y) &&
               interPathHelper(path, [["M", x, y], ["H", bbox.x2 + 10]], 1) % 2 == 1;
    };
    R._removedFactory = function (methodname) {
        return function () {
            eve("raphael.log", null, "Rapha\xebl: you are calling to method \u201c" + methodname + "\u201d of removed object", methodname);
        };
    };
    /*\
     * Raphael.pathBBox
     [ method ]
     **
     * Utility method
     **
     * Return bounding box of a given path
     > Parameters
     - path (string) path string
     = (object) bounding box
     o {
     o     x: (number) x coordinate of the left top point of the box
     o     y: (number) y coordinate of the left top point of the box
     o     x2: (number) x coordinate of the right bottom point of the box
     o     y2: (number) y coordinate of the right bottom point of the box
     o     width: (number) width of the box
     o     height: (number) height of the box
     o     cx: (number) x coordinate of the center of the box
     o     cy: (number) y coordinate of the center of the box
     o }
    \*/
    var pathDimensions = R.pathBBox = function (path) {
        var pth = paths(path);
        if (pth.bbox) {
            return clone(pth.bbox);
        }
        if (!path) {
            return {x: 0, y: 0, width: 0, height: 0, x2: 0, y2: 0};
        }
        path = path2curve(path);
        var x = 0, 
            y = 0,
            X = [],
            Y = [],
            p;
        for (var i = 0, ii = path.length; i < ii; i++) {
            p = path[i];
            if (p[0] == "M") {
                x = p[1];
                y = p[2];
                X.push(x);
                Y.push(y);
            } else {
                var dim = curveDim(x, y, p[1], p[2], p[3], p[4], p[5], p[6]);
                X = X[concat](dim.min.x, dim.max.x);
                Y = Y[concat](dim.min.y, dim.max.y);
                x = p[5];
                y = p[6];
            }
        }
        var xmin = mmin[apply](0, X),
            ymin = mmin[apply](0, Y),
            xmax = mmax[apply](0, X),
            ymax = mmax[apply](0, Y),
            width = xmax - xmin,
            height = ymax - ymin,
                bb = {
                x: xmin,
                y: ymin,
                x2: xmax,
                y2: ymax,
                width: width,
                height: height,
                cx: xmin + width / 2,
                cy: ymin + height / 2
            };
        pth.bbox = clone(bb);
        return bb;
    },
        pathClone = function (pathArray) {
            var res = clone(pathArray);
            res.toString = R._path2string;
            return res;
        },
        pathToRelative = R._pathToRelative = function (pathArray) {
            var pth = paths(pathArray);
            if (pth.rel) {
                return pathClone(pth.rel);
            }
            if (!R.is(pathArray, array) || !R.is(pathArray && pathArray[0], array)) { // rough assumption
                pathArray = R.parsePathString(pathArray);
            }
            var res = [],
                x = 0,
                y = 0,
                mx = 0,
                my = 0,
                start = 0;
            if (pathArray[0][0] == "M") {
                x = pathArray[0][1];
                y = pathArray[0][2];
                mx = x;
                my = y;
                start++;
                res.push(["M", x, y]);
            }
            for (var i = start, ii = pathArray.length; i < ii; i++) {
                var r = res[i] = [],
                    pa = pathArray[i];
                if (pa[0] != lowerCase.call(pa[0])) {
                    r[0] = lowerCase.call(pa[0]);
                    switch (r[0]) {
                        case "a":
                            r[1] = pa[1];
                            r[2] = pa[2];
                            r[3] = pa[3];
                            r[4] = pa[4];
                            r[5] = pa[5];
                            r[6] = +(pa[6] - x).toFixed(3);
                            r[7] = +(pa[7] - y).toFixed(3);
                            break;
                        case "v":
                            r[1] = +(pa[1] - y).toFixed(3);
                            break;
                        case "m":
                            mx = pa[1];
                            my = pa[2];
                        default:
                            for (var j = 1, jj = pa.length; j < jj; j++) {
                                r[j] = +(pa[j] - ((j % 2) ? x : y)).toFixed(3);
                            }
                    }
                } else {
                    r = res[i] = [];
                    if (pa[0] == "m") {
                        mx = pa[1] + x;
                        my = pa[2] + y;
                    }
                    for (var k = 0, kk = pa.length; k < kk; k++) {
                        res[i][k] = pa[k];
                    }
                }
                var len = res[i].length;
                switch (res[i][0]) {
                    case "z":
                        x = mx;
                        y = my;
                        break;
                    case "h":
                        x += +res[i][len - 1];
                        break;
                    case "v":
                        y += +res[i][len - 1];
                        break;
                    default:
                        x += +res[i][len - 2];
                        y += +res[i][len - 1];
                }
            }
            res.toString = R._path2string;
            pth.rel = pathClone(res);
            return res;
        },
        pathToAbsolute = R._pathToAbsolute = function (pathArray) {
            var pth = paths(pathArray);
            if (pth.abs) {
                return pathClone(pth.abs);
            }
            if (!R.is(pathArray, array) || !R.is(pathArray && pathArray[0], array)) { // rough assumption
                pathArray = R.parsePathString(pathArray);
            }
            if (!pathArray || !pathArray.length) {
                return [["M", 0, 0]];
            }
            var res = [],
                x = 0,
                y = 0,
                mx = 0,
                my = 0,
                start = 0;
            if (pathArray[0][0] == "M") {
                x = +pathArray[0][1];
                y = +pathArray[0][2];
                mx = x;
                my = y;
                start++;
                res[0] = ["M", x, y];
            }
            var crz = pathArray.length == 3 && pathArray[0][0] == "M" && pathArray[1][0].toUpperCase() == "R" && pathArray[2][0].toUpperCase() == "Z";
            for (var r, pa, i = start, ii = pathArray.length; i < ii; i++) {
                res.push(r = []);
                pa = pathArray[i];
                if (pa[0] != upperCase.call(pa[0])) {
                    r[0] = upperCase.call(pa[0]);
                    switch (r[0]) {
                        case "A":
                            r[1] = pa[1];
                            r[2] = pa[2];
                            r[3] = pa[3];
                            r[4] = pa[4];
                            r[5] = pa[5];
                            r[6] = +(pa[6] + x);
                            r[7] = +(pa[7] + y);
                            break;
                        case "V":
                            r[1] = +pa[1] + y;
                            break;
                        case "H":
                            r[1] = +pa[1] + x;
                            break;
                        case "R":
                            var dots = [x, y][concat](pa.slice(1));
                            for (var j = 2, jj = dots.length; j < jj; j++) {
                                dots[j] = +dots[j] + x;
                                dots[++j] = +dots[j] + y;
                            }
                            res.pop();
                            res = res[concat](catmullRom2bezier(dots, crz));
                            break;
                        case "M":
                            mx = +pa[1] + x;
                            my = +pa[2] + y;
                        default:
                            for (j = 1, jj = pa.length; j < jj; j++) {
                                r[j] = +pa[j] + ((j % 2) ? x : y);
                            }
                    }
                } else if (pa[0] == "R") {
                    dots = [x, y][concat](pa.slice(1));
                    res.pop();
                    res = res[concat](catmullRom2bezier(dots, crz));
                    r = ["R"][concat](pa.slice(-2));
                } else {
                    for (var k = 0, kk = pa.length; k < kk; k++) {
                        r[k] = pa[k];
                    }
                }
                switch (r[0]) {
                    case "Z":
                        x = mx;
                        y = my;
                        break;
                    case "H":
                        x = r[1];
                        break;
                    case "V":
                        y = r[1];
                        break;
                    case "M":
                        mx = r[r.length - 2];
                        my = r[r.length - 1];
                    default:
                        x = r[r.length - 2];
                        y = r[r.length - 1];
                }
            }
            res.toString = R._path2string;
            pth.abs = pathClone(res);
            return res;
        },
        l2c = function (x1, y1, x2, y2) {
            return [x1, y1, x2, y2, x2, y2];
        },
        q2c = function (x1, y1, ax, ay, x2, y2) {
            var _13 = 1 / 3,
                _23 = 2 / 3;
            return [
                    _13 * x1 + _23 * ax,
                    _13 * y1 + _23 * ay,
                    _13 * x2 + _23 * ax,
                    _13 * y2 + _23 * ay,
                    x2,
                    y2
                ];
        },
        a2c = function (x1, y1, rx, ry, angle, large_arc_flag, sweep_flag, x2, y2, recursive) {
            // for more information of where this math came from visit:
            // http://www.w3.org/TR/SVG11/implnote.html#ArcImplementationNotes
            var _120 = PI * 120 / 180,
                rad = PI / 180 * (+angle || 0),
                res = [],
                xy,
                rotate = cacher(function (x, y, rad) {
                    var X = x * math.cos(rad) - y * math.sin(rad),
                        Y = x * math.sin(rad) + y * math.cos(rad);
                    return {x: X, y: Y};
                });
            if (!recursive) {
                xy = rotate(x1, y1, -rad);
                x1 = xy.x;
                y1 = xy.y;
                xy = rotate(x2, y2, -rad);
                x2 = xy.x;
                y2 = xy.y;
                var cos = math.cos(PI / 180 * angle),
                    sin = math.sin(PI / 180 * angle),
                    x = (x1 - x2) / 2,
                    y = (y1 - y2) / 2;
                var h = (x * x) / (rx * rx) + (y * y) / (ry * ry);
                if (h > 1) {
                    h = math.sqrt(h);
                    rx = h * rx;
                    ry = h * ry;
                }
                var rx2 = rx * rx,
                    ry2 = ry * ry,
                    k = (large_arc_flag == sweep_flag ? -1 : 1) *
                        math.sqrt(abs((rx2 * ry2 - rx2 * y * y - ry2 * x * x) / (rx2 * y * y + ry2 * x * x))),
                    cx = k * rx * y / ry + (x1 + x2) / 2,
                    cy = k * -ry * x / rx + (y1 + y2) / 2,
                    f1 = math.asin(((y1 - cy) / ry).toFixed(9)),
                    f2 = math.asin(((y2 - cy) / ry).toFixed(9));

                f1 = x1 < cx ? PI - f1 : f1;
                f2 = x2 < cx ? PI - f2 : f2;
                f1 < 0 && (f1 = PI * 2 + f1);
                f2 < 0 && (f2 = PI * 2 + f2);
                if (sweep_flag && f1 > f2) {
                    f1 = f1 - PI * 2;
                }
                if (!sweep_flag && f2 > f1) {
                    f2 = f2 - PI * 2;
                }
            } else {
                f1 = recursive[0];
                f2 = recursive[1];
                cx = recursive[2];
                cy = recursive[3];
            }
            var df = f2 - f1;
            if (abs(df) > _120) {
                var f2old = f2,
                    x2old = x2,
                    y2old = y2;
                f2 = f1 + _120 * (sweep_flag && f2 > f1 ? 1 : -1);
                x2 = cx + rx * math.cos(f2);
                y2 = cy + ry * math.sin(f2);
                res = a2c(x2, y2, rx, ry, angle, 0, sweep_flag, x2old, y2old, [f2, f2old, cx, cy]);
            }
            df = f2 - f1;
            var c1 = math.cos(f1),
                s1 = math.sin(f1),
                c2 = math.cos(f2),
                s2 = math.sin(f2),
                t = math.tan(df / 4),
                hx = 4 / 3 * rx * t,
                hy = 4 / 3 * ry * t,
                m1 = [x1, y1],
                m2 = [x1 + hx * s1, y1 - hy * c1],
                m3 = [x2 + hx * s2, y2 - hy * c2],
                m4 = [x2, y2];
            m2[0] = 2 * m1[0] - m2[0];
            m2[1] = 2 * m1[1] - m2[1];
            if (recursive) {
                return [m2, m3, m4][concat](res);
            } else {
                res = [m2, m3, m4][concat](res).join()[split](",");
                var newres = [];
                for (var i = 0, ii = res.length; i < ii; i++) {
                    newres[i] = i % 2 ? rotate(res[i - 1], res[i], rad).y : rotate(res[i], res[i + 1], rad).x;
                }
                return newres;
            }
        },
        findDotAtSegment = function (p1x, p1y, c1x, c1y, c2x, c2y, p2x, p2y, t) {
            var t1 = 1 - t;
            return {
                x: pow(t1, 3) * p1x + pow(t1, 2) * 3 * t * c1x + t1 * 3 * t * t * c2x + pow(t, 3) * p2x,
                y: pow(t1, 3) * p1y + pow(t1, 2) * 3 * t * c1y + t1 * 3 * t * t * c2y + pow(t, 3) * p2y
            };
        },
        curveDim = cacher(function (p1x, p1y, c1x, c1y, c2x, c2y, p2x, p2y) {
            var a = (c2x - 2 * c1x + p1x) - (p2x - 2 * c2x + c1x),
                b = 2 * (c1x - p1x) - 2 * (c2x - c1x),
                c = p1x - c1x,
                t1 = (-b + math.sqrt(b * b - 4 * a * c)) / 2 / a,
                t2 = (-b - math.sqrt(b * b - 4 * a * c)) / 2 / a,
                y = [p1y, p2y],
                x = [p1x, p2x],
                dot;
            abs(t1) > "1e12" && (t1 = .5);
            abs(t2) > "1e12" && (t2 = .5);
            if (t1 > 0 && t1 < 1) {
                dot = findDotAtSegment(p1x, p1y, c1x, c1y, c2x, c2y, p2x, p2y, t1);
                x.push(dot.x);
                y.push(dot.y);
            }
            if (t2 > 0 && t2 < 1) {
                dot = findDotAtSegment(p1x, p1y, c1x, c1y, c2x, c2y, p2x, p2y, t2);
                x.push(dot.x);
                y.push(dot.y);
            }
            a = (c2y - 2 * c1y + p1y) - (p2y - 2 * c2y + c1y);
            b = 2 * (c1y - p1y) - 2 * (c2y - c1y);
            c = p1y - c1y;
            t1 = (-b + math.sqrt(b * b - 4 * a * c)) / 2 / a;
            t2 = (-b - math.sqrt(b * b - 4 * a * c)) / 2 / a;
            abs(t1) > "1e12" && (t1 = .5);
            abs(t2) > "1e12" && (t2 = .5);
            if (t1 > 0 && t1 < 1) {
                dot = findDotAtSegment(p1x, p1y, c1x, c1y, c2x, c2y, p2x, p2y, t1);
                x.push(dot.x);
                y.push(dot.y);
            }
            if (t2 > 0 && t2 < 1) {
                dot = findDotAtSegment(p1x, p1y, c1x, c1y, c2x, c2y, p2x, p2y, t2);
                x.push(dot.x);
                y.push(dot.y);
            }
            return {
                min: {x: mmin[apply](0, x), y: mmin[apply](0, y)},
                max: {x: mmax[apply](0, x), y: mmax[apply](0, y)}
            };
        }),
        path2curve = R._path2curve = cacher(function (path, path2) {
            var pth = !path2 && paths(path);
            if (!path2 && pth.curve) {
                return pathClone(pth.curve);
            }
            var p = pathToAbsolute(path),
                p2 = path2 && pathToAbsolute(path2),
                attrs = {x: 0, y: 0, bx: 0, by: 0, X: 0, Y: 0, qx: null, qy: null},
                attrs2 = {x: 0, y: 0, bx: 0, by: 0, X: 0, Y: 0, qx: null, qy: null},
                processPath = function (path, d) {
                    var nx, ny;
                    if (!path) {
                        return ["C", d.x, d.y, d.x, d.y, d.x, d.y];
                    }
                    !(path[0] in {T:1, Q:1}) && (d.qx = d.qy = null);
                    switch (path[0]) {
                        case "M":
                            d.X = path[1];
                            d.Y = path[2];
                            break;
                        case "A":
                            path = ["C"][concat](a2c[apply](0, [d.x, d.y][concat](path.slice(1))));
                            break;
                        case "S":
                            nx = d.x + (d.x - (d.bx || d.x));
                            ny = d.y + (d.y - (d.by || d.y));
                            path = ["C", nx, ny][concat](path.slice(1));
                            break;
                        case "T":
                            d.qx = d.x + (d.x - (d.qx || d.x));
                            d.qy = d.y + (d.y - (d.qy || d.y));
                            path = ["C"][concat](q2c(d.x, d.y, d.qx, d.qy, path[1], path[2]));
                            break;
                        case "Q":
                            d.qx = path[1];
                            d.qy = path[2];
                            path = ["C"][concat](q2c(d.x, d.y, path[1], path[2], path[3], path[4]));
                            break;
                        case "L":
                            path = ["C"][concat](l2c(d.x, d.y, path[1], path[2]));
                            break;
                        case "H":
                            path = ["C"][concat](l2c(d.x, d.y, path[1], d.y));
                            break;
                        case "V":
                            path = ["C"][concat](l2c(d.x, d.y, d.x, path[1]));
                            break;
                        case "Z":
                            path = ["C"][concat](l2c(d.x, d.y, d.X, d.Y));
                            break;
                    }
                    return path;
                },
                fixArc = function (pp, i) {
                    if (pp[i].length > 7) {
                        pp[i].shift();
                        var pi = pp[i];
                        while (pi.length) {
                            pp.splice(i++, 0, ["C"][concat](pi.splice(0, 6)));
                        }
                        pp.splice(i, 1);
                        ii = mmax(p.length, p2 && p2.length || 0);
                    }
                },
                fixM = function (path1, path2, a1, a2, i) {
                    if (path1 && path2 && path1[i][0] == "M" && path2[i][0] != "M") {
                        path2.splice(i, 0, ["M", a2.x, a2.y]);
                        a1.bx = 0;
                        a1.by = 0;
                        a1.x = path1[i][1];
                        a1.y = path1[i][2];
                        ii = mmax(p.length, p2 && p2.length || 0);
                    }
                };
            for (var i = 0, ii = mmax(p.length, p2 && p2.length || 0); i < ii; i++) {
                p[i] = processPath(p[i], attrs);
                fixArc(p, i);
                p2 && (p2[i] = processPath(p2[i], attrs2));
                p2 && fixArc(p2, i);
                fixM(p, p2, attrs, attrs2, i);
                fixM(p2, p, attrs2, attrs, i);
                var seg = p[i],
                    seg2 = p2 && p2[i],
                    seglen = seg.length,
                    seg2len = p2 && seg2.length;
                attrs.x = seg[seglen - 2];
                attrs.y = seg[seglen - 1];
                attrs.bx = toFloat(seg[seglen - 4]) || attrs.x;
                attrs.by = toFloat(seg[seglen - 3]) || attrs.y;
                attrs2.bx = p2 && (toFloat(seg2[seg2len - 4]) || attrs2.x);
                attrs2.by = p2 && (toFloat(seg2[seg2len - 3]) || attrs2.y);
                attrs2.x = p2 && seg2[seg2len - 2];
                attrs2.y = p2 && seg2[seg2len - 1];
            }
            if (!p2) {
                pth.curve = pathClone(p);
            }
            return p2 ? [p, p2] : p;
        }, null, pathClone),
        parseDots = R._parseDots = cacher(function (gradient) {
            var dots = [];
            for (var i = 0, ii = gradient.length; i < ii; i++) {
                var dot = {},
                    par = gradient[i].match(/^([^:]*):?([\d\.]*)/);
                dot.color = R.getRGB(par[1]);
                if (dot.color.error) {
                    return null;
                }
                dot.color = dot.color.hex;
                par[2] && (dot.offset = par[2] + "%");
                dots.push(dot);
            }
            for (i = 1, ii = dots.length - 1; i < ii; i++) {
                if (!dots[i].offset) {
                    var start = toFloat(dots[i - 1].offset || 0),
                        end = 0;
                    for (var j = i + 1; j < ii; j++) {
                        if (dots[j].offset) {
                            end = dots[j].offset;
                            break;
                        }
                    }
                    if (!end) {
                        end = 100;
                        j = ii;
                    }
                    end = toFloat(end);
                    var d = (end - start) / (j - i + 1);
                    for (; i < j; i++) {
                        start += d;
                        dots[i].offset = start + "%";
                    }
                }
            }
            return dots;
        }),
        tear = R._tear = function (el, paper) {
            el == paper.top && (paper.top = el.prev);
            el == paper.bottom && (paper.bottom = el.next);
            el.next && (el.next.prev = el.prev);
            el.prev && (el.prev.next = el.next);
        },
        tofront = R._tofront = function (el, paper) {
            if (paper.top === el) {
                return;
            }
            tear(el, paper);
            el.next = null;
            el.prev = paper.top;
            paper.top.next = el;
            paper.top = el;
        },
        toback = R._toback = function (el, paper) {
            if (paper.bottom === el) {
                return;
            }
            tear(el, paper);
            el.next = paper.bottom;
            el.prev = null;
            paper.bottom.prev = el;
            paper.bottom = el;
        },
        insertafter = R._insertafter = function (el, el2, paper) {
            tear(el, paper);
            el2 == paper.top && (paper.top = el);
            el2.next && (el2.next.prev = el);
            el.next = el2.next;
            el.prev = el2;
            el2.next = el;
        },
        insertbefore = R._insertbefore = function (el, el2, paper) {
            tear(el, paper);
            el2 == paper.bottom && (paper.bottom = el);
            el2.prev && (el2.prev.next = el);
            el.prev = el2.prev;
            el2.prev = el;
            el.next = el2;
        },
        /*\
         * Raphael.toMatrix
         [ method ]
         **
         * Utility method
         **
         * Returns matrix of transformations applied to a given path
         > Parameters
         - path (string) path string
         - transform (string|array) transformation string
         = (object) @Matrix
        \*/
        toMatrix = R.toMatrix = function (path, transform) {
            var bb = pathDimensions(path),
                el = {
                    _: {
                        transform: E
                    },
                    getBBox: function () {
                        return bb;
                    }
                };
            extractTransform(el, transform);
            return el.matrix;
        },
        /*\
         * Raphael.transformPath
         [ method ]
         **
         * Utility method
         **
         * Returns path transformed by a given transformation
         > Parameters
         - path (string) path string
         - transform (string|array) transformation string
         = (string) path
        \*/
        transformPath = R.transformPath = function (path, transform) {
            return mapPath(path, toMatrix(path, transform));
        },
        extractTransform = R._extractTransform = function (el, tstr) {
            if (tstr == null) {
                return el._.transform;
            }
            tstr = Str(tstr).replace(/\.{3}|\u2026/g, el._.transform || E);
            var tdata = R.parseTransformString(tstr),
                deg = 0,
                dx = 0,
                dy = 0,
                sx = 1,
                sy = 1,
                _ = el._,
                m = new Matrix;
            _.transform = tdata || [];
            if (tdata) {
                for (var i = 0, ii = tdata.length; i < ii; i++) {
                    var t = tdata[i],
                        tlen = t.length,
                        command = Str(t[0]).toLowerCase(),
                        absolute = t[0] != command,
                        inver = absolute ? m.invert() : 0,
                        x1,
                        y1,
                        x2,
                        y2,
                        bb;
                    if (command == "t" && tlen == 3) {
                        if (absolute) {
                            x1 = inver.x(0, 0);
                            y1 = inver.y(0, 0);
                            x2 = inver.x(t[1], t[2]);
                            y2 = inver.y(t[1], t[2]);
                            m.translate(x2 - x1, y2 - y1);
                        } else {
                            m.translate(t[1], t[2]);
                        }
                    } else if (command == "r") {
                        if (tlen == 2) {
                            bb = bb || el.getBBox(1);
                            m.rotate(t[1], bb.x + bb.width / 2, bb.y + bb.height / 2);
                            deg += t[1];
                        } else if (tlen == 4) {
                            if (absolute) {
                                x2 = inver.x(t[2], t[3]);
                                y2 = inver.y(t[2], t[3]);
                                m.rotate(t[1], x2, y2);
                            } else {
                                m.rotate(t[1], t[2], t[3]);
                            }
                            deg += t[1];
                        }
                    } else if (command == "s") {
                        if (tlen == 2 || tlen == 3) {
                            bb = bb || el.getBBox(1);
                            m.scale(t[1], t[tlen - 1], bb.x + bb.width / 2, bb.y + bb.height / 2);
                            sx *= t[1];
                            sy *= t[tlen - 1];
                        } else if (tlen == 5) {
                            if (absolute) {
                                x2 = inver.x(t[3], t[4]);
                                y2 = inver.y(t[3], t[4]);
                                m.scale(t[1], t[2], x2, y2);
                            } else {
                                m.scale(t[1], t[2], t[3], t[4]);
                            }
                            sx *= t[1];
                            sy *= t[2];
                        }
                    } else if (command == "m" && tlen == 7) {
                        m.add(t[1], t[2], t[3], t[4], t[5], t[6]);
                    }
                    _.dirtyT = 1;
                    el.matrix = m;
                }
            }

            /*\
             * Element.matrix
             [ property (object) ]
             **
             * Keeps @Matrix object, which represents element transformation
            \*/
            el.matrix = m;

            _.sx = sx;
            _.sy = sy;
            _.deg = deg;
            _.dx = dx = m.e;
            _.dy = dy = m.f;

            if (sx == 1 && sy == 1 && !deg && _.bbox) {
                _.bbox.x += +dx;
                _.bbox.y += +dy;
            } else {
                _.dirtyT = 1;
            }
        },
        getEmpty = function (item) {
            var l = item[0];
            switch (l.toLowerCase()) {
                case "t": return [l, 0, 0];
                case "m": return [l, 1, 0, 0, 1, 0, 0];
                case "r": if (item.length == 4) {
                    return [l, 0, item[2], item[3]];
                } else {
                    return [l, 0];
                }
                case "s": if (item.length == 5) {
                    return [l, 1, 1, item[3], item[4]];
                } else if (item.length == 3) {
                    return [l, 1, 1];
                } else {
                    return [l, 1];
                }
            }
        },
        equaliseTransform = R._equaliseTransform = function (t1, t2) {
            t2 = Str(t2).replace(/\.{3}|\u2026/g, t1);
            t1 = R.parseTransformString(t1) || [];
            t2 = R.parseTransformString(t2) || [];
            var maxlength = mmax(t1.length, t2.length),
                from = [],
                to = [],
                i = 0, j, jj,
                tt1, tt2;
            for (; i < maxlength; i++) {
                tt1 = t1[i] || getEmpty(t2[i]);
                tt2 = t2[i] || getEmpty(tt1);
                if ((tt1[0] != tt2[0]) ||
                    (tt1[0].toLowerCase() == "r" && (tt1[2] != tt2[2] || tt1[3] != tt2[3])) ||
                    (tt1[0].toLowerCase() == "s" && (tt1[3] != tt2[3] || tt1[4] != tt2[4]))
                    ) {
                    return;
                }
                from[i] = [];
                to[i] = [];
                for (j = 0, jj = mmax(tt1.length, tt2.length); j < jj; j++) {
                    j in tt1 && (from[i][j] = tt1[j]);
                    j in tt2 && (to[i][j] = tt2[j]);
                }
            }
            return {
                from: from,
                to: to
            };
        };
    R._getContainer = function (x, y, w, h) {
        var container;
        container = h == null && !R.is(x, "object") ? g.doc.getElementById(x) : x;
        if (container == null) {
            return;
        }
        if (container.tagName) {
            if (y == null) {
                return {
                    container: container,
                    width: container.style.pixelWidth || container.offsetWidth,
                    height: container.style.pixelHeight || container.offsetHeight
                };
            } else {
                return {
                    container: container,
                    width: y,
                    height: w
                };
            }
        }
        return {
            container: 1,
            x: x,
            y: y,
            width: w,
            height: h
        };
    };
    /*\
     * Raphael.pathToRelative
     [ method ]
     **
     * Utility method
     **
     * Converts path to relative form
     > Parameters
     - pathString (string|array) path string or array of segments
     = (array) array of segments.
    \*/
    R.pathToRelative = pathToRelative;
    R._engine = {};
    /*\
     * Raphael.path2curve
     [ method ]
     **
     * Utility method
     **
     * Converts path to a new path where all segments are cubic bezier curves.
     > Parameters
     - pathString (string|array) path string or array of segments
     = (array) array of segments.
    \*/
    R.path2curve = path2curve;
    /*\
     * Raphael.matrix
     [ method ]
     **
     * Utility method
     **
     * Returns matrix based on given parameters.
     > Parameters
     - a (number)
     - b (number)
     - c (number)
     - d (number)
     - e (number)
     - f (number)
     = (object) @Matrix
    \*/
    R.matrix = function (a, b, c, d, e, f) {
        return new Matrix(a, b, c, d, e, f);
    };
    function Matrix(a, b, c, d, e, f) {
        if (a != null) {
            this.a = +a;
            this.b = +b;
            this.c = +c;
            this.d = +d;
            this.e = +e;
            this.f = +f;
        } else {
            this.a = 1;
            this.b = 0;
            this.c = 0;
            this.d = 1;
            this.e = 0;
            this.f = 0;
        }
    }
    (function (matrixproto) {
        /*\
         * Matrix.add
         [ method ]
         **
         * Adds given matrix to existing one.
         > Parameters
         - a (number)
         - b (number)
         - c (number)
         - d (number)
         - e (number)
         - f (number)
         or
         - matrix (object) @Matrix
        \*/
        matrixproto.add = function (a, b, c, d, e, f) {
            var out = [[], [], []],
                m = [[this.a, this.c, this.e], [this.b, this.d, this.f], [0, 0, 1]],
                matrix = [[a, c, e], [b, d, f], [0, 0, 1]],
                x, y, z, res;

            if (a && a instanceof Matrix) {
                matrix = [[a.a, a.c, a.e], [a.b, a.d, a.f], [0, 0, 1]];
            }

            for (x = 0; x < 3; x++) {
                for (y = 0; y < 3; y++) {
                    res = 0;
                    for (z = 0; z < 3; z++) {
                        res += m[x][z] * matrix[z][y];
                    }
                    out[x][y] = res;
                }
            }
            this.a = out[0][0];
            this.b = out[1][0];
            this.c = out[0][1];
            this.d = out[1][1];
            this.e = out[0][2];
            this.f = out[1][2];
        };
        /*\
         * Matrix.invert
         [ method ]
         **
         * Returns inverted version of the matrix
         = (object) @Matrix
        \*/
        matrixproto.invert = function () {
            var me = this,
                x = me.a * me.d - me.b * me.c;
            return new Matrix(me.d / x, -me.b / x, -me.c / x, me.a / x, (me.c * me.f - me.d * me.e) / x, (me.b * me.e - me.a * me.f) / x);
        };
        /*\
         * Matrix.clone
         [ method ]
         **
         * Returns copy of the matrix
         = (object) @Matrix
        \*/
        matrixproto.clone = function () {
            return new Matrix(this.a, this.b, this.c, this.d, this.e, this.f);
        };
        /*\
         * Matrix.translate
         [ method ]
         **
         * Translate the matrix
         > Parameters
         - x (number)
         - y (number)
        \*/
        matrixproto.translate = function (x, y) {
            this.add(1, 0, 0, 1, x, y);
        };
        /*\
         * Matrix.scale
         [ method ]
         **
         * Scales the matrix
         > Parameters
         - x (number)
         - y (number) #optional
         - cx (number) #optional
         - cy (number) #optional
        \*/
        matrixproto.scale = function (x, y, cx, cy) {
            y == null && (y = x);
            (cx || cy) && this.add(1, 0, 0, 1, cx, cy);
            this.add(x, 0, 0, y, 0, 0);
            (cx || cy) && this.add(1, 0, 0, 1, -cx, -cy);
        };
        /*\
         * Matrix.rotate
         [ method ]
         **
         * Rotates the matrix
         > Parameters
         - a (number)
         - x (number)
         - y (number)
        \*/
        matrixproto.rotate = function (a, x, y) {
            a = R.rad(a);
            x = x || 0;
            y = y || 0;
            var cos = +math.cos(a).toFixed(9),
                sin = +math.sin(a).toFixed(9);
            this.add(cos, sin, -sin, cos, x, y);
            this.add(1, 0, 0, 1, -x, -y);
        };
        /*\
         * Matrix.x
         [ method ]
         **
         * Return x coordinate for given point after transformation described by the matrix. See also @Matrix.y
         > Parameters
         - x (number)
         - y (number)
         = (number) x
        \*/
        matrixproto.x = function (x, y) {
            return x * this.a + y * this.c + this.e;
        };
        /*\
         * Matrix.y
         [ method ]
         **
         * Return y coordinate for given point after transformation described by the matrix. See also @Matrix.x
         > Parameters
         - x (number)
         - y (number)
         = (number) y
        \*/
        matrixproto.y = function (x, y) {
            return x * this.b + y * this.d + this.f;
        };
        matrixproto.get = function (i) {
            return +this[Str.fromCharCode(97 + i)].toFixed(4);
        };
        matrixproto.toString = function () {
            return R.svg ?
                "matrix(" + [this.get(0), this.get(1), this.get(2), this.get(3), this.get(4), this.get(5)].join() + ")" :
                [this.get(0), this.get(2), this.get(1), this.get(3), 0, 0].join();
        };
        matrixproto.toFilter = function () {
            return "progid:DXImageTransform.Microsoft.Matrix(M11=" + this.get(0) +
                ", M12=" + this.get(2) + ", M21=" + this.get(1) + ", M22=" + this.get(3) +
                ", Dx=" + this.get(4) + ", Dy=" + this.get(5) + ", sizingmethod='auto expand')";
        };
        matrixproto.offset = function () {
            return [this.e.toFixed(4), this.f.toFixed(4)];
        };
        function norm(a) {
            return a[0] * a[0] + a[1] * a[1];
        }
        function normalize(a) {
            var mag = math.sqrt(norm(a));
            a[0] && (a[0] /= mag);
            a[1] && (a[1] /= mag);
        }
        /*\
         * Matrix.split
         [ method ]
         **
         * Splits matrix into primitive transformations
         = (object) in format:
         o dx (number) translation by x
         o dy (number) translation by y
         o scalex (number) scale by x
         o scaley (number) scale by y
         o shear (number) shear
         o rotate (number) rotation in deg
         o isSimple (boolean) could it be represented via simple transformations
        \*/
        matrixproto.split = function () {
            var out = {};
            // translation
            out.dx = this.e;
            out.dy = this.f;

            // scale and shear
            var row = [[this.a, this.c], [this.b, this.d]];
            out.scalex = math.sqrt(norm(row[0]));
            normalize(row[0]);

            out.shear = row[0][0] * row[1][0] + row[0][1] * row[1][1];
            row[1] = [row[1][0] - row[0][0] * out.shear, row[1][1] - row[0][1] * out.shear];

            out.scaley = math.sqrt(norm(row[1]));
            normalize(row[1]);
            out.shear /= out.scaley;

            // rotation
            var sin = -row[0][1],
                cos = row[1][1];
            if (cos < 0) {
                out.rotate = R.deg(math.acos(cos));
                if (sin < 0) {
                    out.rotate = 360 - out.rotate;
                }
            } else {
                out.rotate = R.deg(math.asin(sin));
            }

            out.isSimple = !+out.shear.toFixed(9) && (out.scalex.toFixed(9) == out.scaley.toFixed(9) || !out.rotate);
            out.isSuperSimple = !+out.shear.toFixed(9) && out.scalex.toFixed(9) == out.scaley.toFixed(9) && !out.rotate;
            out.noRotation = !+out.shear.toFixed(9) && !out.rotate;
            return out;
        };
        /*\
         * Matrix.toTransformString
         [ method ]
         **
         * Return transform string that represents given matrix
         = (string) transform string
        \*/
        matrixproto.toTransformString = function (shorter) {
            var s = shorter || this[split]();
            if (s.isSimple) {
                s.scalex = +s.scalex.toFixed(4);
                s.scaley = +s.scaley.toFixed(4);
                s.rotate = +s.rotate.toFixed(4);
                return  (s.dx || s.dy ? "t" + [s.dx, s.dy] : E) + 
                        (s.scalex != 1 || s.scaley != 1 ? "s" + [s.scalex, s.scaley, 0, 0] : E) +
                        (s.rotate ? "r" + [s.rotate, 0, 0] : E);
            } else {
                return "m" + [this.get(0), this.get(1), this.get(2), this.get(3), this.get(4), this.get(5)];
            }
        };
    })(Matrix.prototype);

    // WebKit rendering bug workaround method
    var version = navigator.userAgent.match(/Version\/(.*?)\s/) || navigator.userAgent.match(/Chrome\/(\d+)/);
    if ((navigator.vendor == "Apple Computer, Inc.") && (version && version[1] < 4 || navigator.platform.slice(0, 2) == "iP") ||
        (navigator.vendor == "Google Inc." && version && version[1] < 8)) {
        /*\
         * Paper.safari
         [ method ]
         **
         * There is an inconvenient rendering bug in Safari (WebKit):
         * sometimes the rendering should be forced.
         * This method should help with dealing with this bug.
        \*/
        paperproto.safari = function () {
            var rect = this.rect(-99, -99, this.width + 99, this.height + 99).attr({stroke: "none"});
            setTimeout(function () {rect.remove();});
        };
    } else {
        paperproto.safari = fun;
    }
 
    var preventDefault = function () {
        this.returnValue = false;
    },
    preventTouch = function () {
        return this.originalEvent.preventDefault();
    },
    stopPropagation = function () {
        this.cancelBubble = true;
    },
    stopTouch = function () {
        return this.originalEvent.stopPropagation();
    },
    addEvent = (function () {
        if (g.doc.addEventListener) {
            return function (obj, type, fn, element) {
                var realName = supportsTouch && touchMap[type] ? touchMap[type] : type,
                    f = function (e) {
                        var scrollY = g.doc.documentElement.scrollTop || g.doc.body.scrollTop,
                            scrollX = g.doc.documentElement.scrollLeft || g.doc.body.scrollLeft,
                            x = e.clientX + scrollX,
                            y = e.clientY + scrollY;
                    if (supportsTouch && touchMap[has](type)) {
                        for (var i = 0, ii = e.targetTouches && e.targetTouches.length; i < ii; i++) {
                            if (e.targetTouches[i].target == obj) {
                                var olde = e;
                                e = e.targetTouches[i];
                                e.originalEvent = olde;
                                e.preventDefault = preventTouch;
                                e.stopPropagation = stopTouch;
                                break;
                            }
                        }
                    }
                    return fn.call(element, e, x, y);
                };
                obj.addEventListener(realName, f, false);
                return function () {
                    obj.removeEventListener(realName, f, false);
                    return true;
                };
            };
        } else if (g.doc.attachEvent) {
            return function (obj, type, fn, element) {
                var f = function (e) {
                    e = e || g.win.event;
                    var scrollY = g.doc.documentElement.scrollTop || g.doc.body.scrollTop,
                        scrollX = g.doc.documentElement.scrollLeft || g.doc.body.scrollLeft,
                        x = e.clientX + scrollX,
                        y = e.clientY + scrollY;
                    e.preventDefault = e.preventDefault || preventDefault;
                    e.stopPropagation = e.stopPropagation || stopPropagation;
                    return fn.call(element, e, x, y);
                };
                obj.attachEvent("on" + type, f);
                var detacher = function () {
                    obj.detachEvent("on" + type, f);
                    return true;
                };
                return detacher;
            };
        }
    })(),
    drag = [],
    dragMove = function (e) {
        var x = e.clientX,
            y = e.clientY,
            scrollY = g.doc.documentElement.scrollTop || g.doc.body.scrollTop,
            scrollX = g.doc.documentElement.scrollLeft || g.doc.body.scrollLeft,
            dragi,
            j = drag.length;
        while (j--) {
            dragi = drag[j];
            if (supportsTouch) {
                var i = e.touches.length,
                    touch;
                while (i--) {
                    touch = e.touches[i];
                    if (touch.identifier == dragi.el._drag.id) {
                        x = touch.clientX;
                        y = touch.clientY;
                        (e.originalEvent ? e.originalEvent : e).preventDefault();
                        break;
                    }
                }
            } else {
                e.preventDefault();
            }
            var node = dragi.el.node,
                o,
                next = node.nextSibling,
                parent = node.parentNode,
                display = node.style.display;
            g.win.opera && parent.removeChild(node);
            node.style.display = "none";
            o = dragi.el.paper.getElementByPoint(x, y);
            node.style.display = display;
            g.win.opera && (next ? parent.insertBefore(node, next) : parent.appendChild(node));
            o && eve("raphael.drag.over." + dragi.el.id, dragi.el, o);
            x += scrollX;
            y += scrollY;
            eve("raphael.drag.move." + dragi.el.id, dragi.move_scope || dragi.el, x - dragi.el._drag.x, y - dragi.el._drag.y, x, y, e);
        }
    },
    dragUp = function (e) {
        R.unmousemove(dragMove).unmouseup(dragUp);
        var i = drag.length,
            dragi;
        while (i--) {
            dragi = drag[i];
            dragi.el._drag = {};
            eve("raphael.drag.end." + dragi.el.id, dragi.end_scope || dragi.start_scope || dragi.move_scope || dragi.el, e);
        }
        drag = [];
    },
    /*\
     * Raphael.el
     [ property (object) ]
     **
     * You can add your own method to elements. This is usefull when you want to hack default functionality or
     * want to wrap some common transformation or attributes in one method. In difference to canvas methods,
     * you can redefine element method at any time. Expending element methods wouldnâ€™t affect set.
     > Usage
     | Raphael.el.red = function () {
     |     this.attr({fill: "#f00"});
     | };
     | // then use it
     | paper.circle(100, 100, 20).red();
    \*/
    elproto = R.el = {};
    /*\
     * Element.click
     [ method ]
     **
     * Adds event handler for click for the element.
     > Parameters
     - handler (function) handler for the event
     = (object) @Element
    \*/
    /*\
     * Element.unclick
     [ method ]
     **
     * Removes event handler for click for the element.
     > Parameters
     - handler (function) #optional handler for the event
     = (object) @Element
    \*/
    
    /*\
     * Element.dblclick
     [ method ]
     **
     * Adds event handler for double click for the element.
     > Parameters
     - handler (function) handler for the event
     = (object) @Element
    \*/
    /*\
     * Element.undblclick
     [ method ]
     **
     * Removes event handler for double click for the element.
     > Parameters
     - handler (function) #optional handler for the event
     = (object) @Element
    \*/
    
    /*\
     * Element.mousedown
     [ method ]
     **
     * Adds event handler for mousedown for the element.
     > Parameters
     - handler (function) handler for the event
     = (object) @Element
    \*/
    /*\
     * Element.unmousedown
     [ method ]
     **
     * Removes event handler for mousedown for the element.
     > Parameters
     - handler (function) #optional handler for the event
     = (object) @Element
    \*/
    
    /*\
     * Element.mousemove
     [ method ]
     **
     * Adds event handler for mousemove for the element.
     > Parameters
     - handler (function) handler for the event
     = (object) @Element
    \*/
    /*\
     * Element.unmousemove
     [ method ]
     **
     * Removes event handler for mousemove for the element.
     > Parameters
     - handler (function) #optional handler for the event
     = (object) @Element
    \*/
    
    /*\
     * Element.mouseout
     [ method ]
     **
     * Adds event handler for mouseout for the element.
     > Parameters
     - handler (function) handler for the event
     = (object) @Element
    \*/
    /*\
     * Element.unmouseout
     [ method ]
     **
     * Removes event handler for mouseout for the element.
     > Parameters
     - handler (function) #optional handler for the event
     = (object) @Element
    \*/
    
    /*\
     * Element.mouseover
     [ method ]
     **
     * Adds event handler for mouseover for the element.
     > Parameters
     - handler (function) handler for the event
     = (object) @Element
    \*/
    /*\
     * Element.unmouseover
     [ method ]
     **
     * Removes event handler for mouseover for the element.
     > Parameters
     - handler (function) #optional handler for the event
     = (object) @Element
    \*/
    
    /*\
     * Element.mouseup
     [ method ]
     **
     * Adds event handler for mouseup for the element.
     > Parameters
     - handler (function) handler for the event
     = (object) @Element
    \*/
    /*\
     * Element.unmouseup
     [ method ]
     **
     * Removes event handler for mouseup for the element.
     > Parameters
     - handler (function) #optional handler for the event
     = (object) @Element
    \*/
    
    /*\
     * Element.touchstart
     [ method ]
     **
     * Adds event handler for touchstart for the element.
     > Parameters
     - handler (function) handler for the event
     = (object) @Element
    \*/
    /*\
     * Element.untouchstart
     [ method ]
     **
     * Removes event handler for touchstart for the element.
     > Parameters
     - handler (function) #optional handler for the event
     = (object) @Element
    \*/
    
    /*\
     * Element.touchmove
     [ method ]
     **
     * Adds event handler for touchmove for the element.
     > Parameters
     - handler (function) handler for the event
     = (object) @Element
    \*/
    /*\
     * Element.untouchmove
     [ method ]
     **
     * Removes event handler for touchmove for the element.
     > Parameters
     - handler (function) #optional handler for the event
     = (object) @Element
    \*/
    
    /*\
     * Element.touchend
     [ method ]
     **
     * Adds event handler for touchend for the element.
     > Parameters
     - handler (function) handler for the event
     = (object) @Element
    \*/
    /*\
     * Element.untouchend
     [ method ]
     **
     * Removes event handler for touchend for the element.
     > Parameters
     - handler (function) #optional handler for the event
     = (object) @Element
    \*/
    
    /*\
     * Element.touchcancel
     [ method ]
     **
     * Adds event handler for touchcancel for the element.
     > Parameters
     - handler (function) handler for the event
     = (object) @Element
    \*/
    /*\
     * Element.untouchcancel
     [ method ]
     **
     * Removes event handler for touchcancel for the element.
     > Parameters
     - handler (function) #optional handler for the event
     = (object) @Element
    \*/
    for (var i = events.length; i--;) {
        (function (eventName) {
            R[eventName] = elproto[eventName] = function (fn, scope) {
                if (R.is(fn, "function")) {
                    this.events = this.events || [];
                    this.events.push({name: eventName, f: fn, unbind: addEvent(this.shape || this.node || g.doc, eventName, fn, scope || this)});
                }
                return this;
            };
            R["un" + eventName] = elproto["un" + eventName] = function (fn) {
                var events = this.events || [],
                    l = events.length;
                while (l--){
                    if (events[l].name == eventName && (R.is(fn, "undefined") || events[l].f == fn)) {
                        events[l].unbind();
                        events.splice(l, 1);
                        !events.length && delete this.events;
                    }
                }
                return this;
            };
        })(events[i]);
    }
    
    /*\
     * Element.data
     [ method ]
     **
     * Adds or retrieves given value asociated with given key.
     ** 
     * See also @Element.removeData
     > Parameters
     - key (string) key to store data
     - value (any) #optional value to store
     = (object) @Element
     * or, if value is not specified:
     = (any) value
     > Usage
     | for (var i = 0, i < 5, i++) {
     |     paper.circle(10 + 15 * i, 10, 10)
     |          .attr({fill: "#000"})
     |          .data("i", i)
     |          .click(function () {
     |             alert(this.data("i"));
     |          });
     | }
    \*/
    elproto.data = function (key, value) {
        var data = eldata[this.id] = eldata[this.id] || {};
        if (arguments.length == 1) {
            if (R.is(key, "object")) {
                for (var i in key) if (key[has](i)) {
                    this.data(i, key[i]);
                }
                return this;
            }
            eve("raphael.data.get." + this.id, this, data[key], key);
            return data[key];
        }
        data[key] = value;
        eve("raphael.data.set." + this.id, this, value, key);
        return this;
    };
    /*\
     * Element.removeData
     [ method ]
     **
     * Removes value associated with an element by given key.
     * If key is not provided, removes all the data of the element.
     > Parameters
     - key (string) #optional key
     = (object) @Element
    \*/
    elproto.removeData = function (key) {
        if (key == null) {
            eldata[this.id] = {};
        } else {
            eldata[this.id] && delete eldata[this.id][key];
        }
        return this;
    };
     /*\
     * Element.getData
     [ method ]
     **
     * Retrieves the element data
     = (object) data
    \*/
    elproto.getData = function () {
        return clone(eldata[this.id] || {});
    };
    /*\
     * Element.hover
     [ method ]
     **
     * Adds event handlers for hover for the element.
     > Parameters
     - f_in (function) handler for hover in
     - f_out (function) handler for hover out
     - icontext (object) #optional context for hover in handler
     - ocontext (object) #optional context for hover out handler
     = (object) @Element
    \*/
    elproto.hover = function (f_in, f_out, scope_in, scope_out) {
        return this.mouseover(f_in, scope_in).mouseout(f_out, scope_out || scope_in);
    };
    /*\
     * Element.unhover
     [ method ]
     **
     * Removes event handlers for hover for the element.
     > Parameters
     - f_in (function) handler for hover in
     - f_out (function) handler for hover out
     = (object) @Element
    \*/
    elproto.unhover = function (f_in, f_out) {
        return this.unmouseover(f_in).unmouseout(f_out);
    };
    var draggable = [];
    /*\
     * Element.drag
     [ method ]
     **
     * Adds event handlers for drag of the element.
     > Parameters
     - onmove (function) handler for moving
     - onstart (function) handler for drag start
     - onend (function) handler for drag end
     - mcontext (object) #optional context for moving handler
     - scontext (object) #optional context for drag start handler
     - econtext (object) #optional context for drag end handler
     * Additionaly following `drag` events will be triggered: `drag.start.<id>` on start, 
     * `drag.end.<id>` on end and `drag.move.<id>` on every move. When element will be dragged over another element 
     * `drag.over.<id>` will be fired as well.
     *
     * Start event and start handler will be called in specified context or in context of the element with following parameters:
     o x (number) x position of the mouse
     o y (number) y position of the mouse
     o event (object) DOM event object
     * Move event and move handler will be called in specified context or in context of the element with following parameters:
     o dx (number) shift by x from the start point
     o dy (number) shift by y from the start point
     o x (number) x position of the mouse
     o y (number) y position of the mouse
     o event (object) DOM event object
     * End event and end handler will be called in specified context or in context of the element with following parameters:
     o event (object) DOM event object
     = (object) @Element
    \*/
    elproto.drag = function (onmove, onstart, onend, move_scope, start_scope, end_scope) {
        function start(e) {
            (e.originalEvent || e).preventDefault();
            var scrollY = g.doc.documentElement.scrollTop || g.doc.body.scrollTop,
                scrollX = g.doc.documentElement.scrollLeft || g.doc.body.scrollLeft;
            this._drag.x = e.clientX + scrollX;
            this._drag.y = e.clientY + scrollY;
            this._drag.id = e.identifier;
            !drag.length && R.mousemove(dragMove).mouseup(dragUp);
            drag.push({el: this, move_scope: move_scope, start_scope: start_scope, end_scope: end_scope});
            onstart && eve.on("raphael.drag.start." + this.id, onstart);
            onmove && eve.on("raphael.drag.move." + this.id, onmove);
            onend && eve.on("raphael.drag.end." + this.id, onend);
            eve("raphael.drag.start." + this.id, start_scope || move_scope || this, e.clientX + scrollX, e.clientY + scrollY, e);
        }
        this._drag = {};
        draggable.push({el: this, start: start});
        this.mousedown(start);
        return this;
    };
    /*\
     * Element.onDragOver
     [ method ]
     **
     * Shortcut for assigning event handler for `drag.over.<id>` event, where id is id of the element (see @Element.id).
     > Parameters
     - f (function) handler for event, first argument would be the element you are dragging over
    \*/
    elproto.onDragOver = function (f) {
        f ? eve.on("raphael.drag.over." + this.id, f) : eve.unbind("raphael.drag.over." + this.id);
    };
    /*\
     * Element.undrag
     [ method ]
     **
     * Removes all drag event handlers from given element.
    \*/
    elproto.undrag = function () {
        var i = draggable.length;
        while (i--) if (draggable[i].el == this) {
            this.unmousedown(draggable[i].start);
            draggable.splice(i, 1);
            eve.unbind("raphael.drag.*." + this.id);
        }
        !draggable.length && R.unmousemove(dragMove).unmouseup(dragUp);
        drag = [];
    };
    /*\
     * Paper.circle
     [ method ]
     **
     * Draws a circle.
     **
     > Parameters
     **
     - x (number) x coordinate of the centre
     - y (number) y coordinate of the centre
     - r (number) radius
     = (object) RaphaÃ«l element object with type â€œcircleâ€
     **
     > Usage
     | var c = paper.circle(50, 50, 40);
    \*/
    paperproto.circle = function (x, y, r) {
        var out = R._engine.circle(this, x || 0, y || 0, r || 0);
        this.__set__ && this.__set__.push(out);
        return out;
    };
    /*\
     * Paper.rect
     [ method ]
     *
     * Draws a rectangle.
     **
     > Parameters
     **
     - x (number) x coordinate of the top left corner
     - y (number) y coordinate of the top left corner
     - width (number) width
     - height (number) height
     - r (number) #optional radius for rounded corners, default is 0
     = (object) RaphaÃ«l element object with type â€œrectâ€
     **
     > Usage
     | // regular rectangle
     | var c = paper.rect(10, 10, 50, 50);
     | // rectangle with rounded corners
     | var c = paper.rect(40, 40, 50, 50, 10);
    \*/
    paperproto.rect = function (x, y, w, h, r) {
        var out = R._engine.rect(this, x || 0, y || 0, w || 0, h || 0, r || 0);
        this.__set__ && this.__set__.push(out);
        return out;
    };
    /*\
     * Paper.ellipse
     [ method ]
     **
     * Draws an ellipse.
     **
     > Parameters
     **
     - x (number) x coordinate of the centre
     - y (number) y coordinate of the centre
     - rx (number) horizontal radius
     - ry (number) vertical radius
     = (object) RaphaÃ«l element object with type â€œellipseâ€
     **
     > Usage
     | var c = paper.ellipse(50, 50, 40, 20);
    \*/
    paperproto.ellipse = function (x, y, rx, ry) {
        var out = R._engine.ellipse(this, x || 0, y || 0, rx || 0, ry || 0);
        this.__set__ && this.__set__.push(out);
        return out;
    };
    /*\
     * Paper.path
     [ method ]
     **
     * Creates a path element by given path data string.
     > Parameters
     - pathString (string) #optional path string in SVG format.
     * Path string consists of one-letter commands, followed by comma seprarated arguments in numercal form. Example:
     | "M10,20L30,40"
     * Here we can see two commands: â€œMâ€, with arguments `(10, 20)` and â€œLâ€ with arguments `(30, 40)`. Upper case letter mean command is absolute, lower caseâ€”relative.
     *
     # <p>Here is short list of commands available, for more details see <a href="http://www.w3.org/TR/SVG/paths.html#PathData" title="Details of a path's data attribute's format are described in the SVG specification.">SVG path string format</a>.</p>
     # <table><thead><tr><th>Command</th><th>Name</th><th>Parameters</th></tr></thead><tbody>
     # <tr><td>M</td><td>moveto</td><td>(x y)+</td></tr>
     # <tr><td>Z</td><td>closepath</td><td>(none)</td></tr>
     # <tr><td>L</td><td>lineto</td><td>(x y)+</td></tr>
     # <tr><td>H</td><td>horizontal lineto</td><td>x+</td></tr>
     # <tr><td>V</td><td>vertical lineto</td><td>y+</td></tr>
     # <tr><td>C</td><td>curveto</td><td>(x1 y1 x2 y2 x y)+</td></tr>
     # <tr><td>S</td><td>smooth curveto</td><td>(x2 y2 x y)+</td></tr>
     # <tr><td>Q</td><td>quadratic BÃ©zier curveto</td><td>(x1 y1 x y)+</td></tr>
     # <tr><td>T</td><td>smooth quadratic BÃ©zier curveto</td><td>(x y)+</td></tr>
     # <tr><td>A</td><td>elliptical arc</td><td>(rx ry x-axis-rotation large-arc-flag sweep-flag x y)+</td></tr>
     # <tr><td>R</td><td><a href="http://en.wikipedia.org/wiki/Catmullâ€“Rom_spline#Catmull.E2.80.93Rom_spline">Catmull-Rom curveto</a>*</td><td>x1 y1 (x y)+</td></tr></tbody></table>
     * * â€œCatmull-Rom curvetoâ€ is a not standard SVG command and added in 2.0 to make life easier.
     * Note: there is a special case when path consist of just three commands: â€œM10,10Râ€¦zâ€. In this case path will smoothly connects to its beginning.
     > Usage
     | var c = paper.path("M10 10L90 90");
     | // draw a diagonal line:
     | // move to 10,10, line to 90,90
     * For example of path strings, check out these icons: http://raphaeljs.com/icons/
    \*/
    paperproto.path = function (pathString) {
        pathString && !R.is(pathString, string) && !R.is(pathString[0], array) && (pathString += E);
        var out = R._engine.path(R.format[apply](R, arguments), this);
        this.__set__ && this.__set__.push(out);
        return out;
    };
    /*\
     * Paper.image
     [ method ]
     **
     * Embeds an image into the surface.
     **
     > Parameters
     **
     - src (string) URI of the source image
     - x (number) x coordinate position
     - y (number) y coordinate position
     - width (number) width of the image
     - height (number) height of the image
     = (object) RaphaÃ«l element object with type â€œimageâ€
     **
     > Usage
     | var c = paper.image("apple.png", 10, 10, 80, 80);
    \*/
    paperproto.image = function (src, x, y, w, h) {
        var out = R._engine.image(this, src || "about:blank", x || 0, y || 0, w || 0, h || 0);
        this.__set__ && this.__set__.push(out);
        return out;
    };
    /*\
     * Paper.text
     [ method ]
     **
     * Draws a text string. If you need line breaks, put â€œ\nâ€ in the string.
     **
     > Parameters
     **
     - x (number) x coordinate position
     - y (number) y coordinate position
     - text (string) The text string to draw
     = (object) RaphaÃ«l element object with type â€œtextâ€
     **
     > Usage
     | var t = paper.text(50, 50, "RaphaÃ«l\nkicks\nbutt!");
    \*/
    paperproto.text = function (x, y, text) {
        var out = R._engine.text(this, x || 0, y || 0, Str(text));
        this.__set__ && this.__set__.push(out);
        return out;
    };
    /*\
     * Paper.set
     [ method ]
     **
     * Creates array-like object to keep and operate several elements at once.
     * Warning: it doesnâ€™t create any elements for itself in the page, it just groups existing elements.
     * Sets act as pseudo elements â€” all methods available to an element can be used on a set.
     = (object) array-like object that represents set of elements
     **
     > Usage
     | var st = paper.set();
     | st.push(
     |     paper.circle(10, 10, 5),
     |     paper.circle(30, 10, 5)
     | );
     | st.attr({fill: "red"}); // changes the fill of both circles
    \*/
    paperproto.set = function (itemsArray) {
        !R.is(itemsArray, "array") && (itemsArray = Array.prototype.splice.call(arguments, 0, arguments.length));
        var out = new Set(itemsArray);
        this.__set__ && this.__set__.push(out);
        out["paper"] = this;
        out["type"] = "set";
        return out;
    };
    /*\
     * Paper.setStart
     [ method ]
     **
     * Creates @Paper.set. All elements that will be created after calling this method and before calling
     * @Paper.setFinish will be added to the set.
     **
     > Usage
     | paper.setStart();
     | paper.circle(10, 10, 5),
     | paper.circle(30, 10, 5)
     | var st = paper.setFinish();
     | st.attr({fill: "red"}); // changes the fill of both circles
    \*/
    paperproto.setStart = function (set) {
        this.__set__ = set || this.set();
    };
    /*\
     * Paper.setFinish
     [ method ]
     **
     * See @Paper.setStart. This method finishes catching and returns resulting set.
     **
     = (object) set
    \*/
    paperproto.setFinish = function (set) {
        var out = this.__set__;
        delete this.__set__;
        return out;
    };
    /*\
     * Paper.setSize
     [ method ]
     **
     * If you need to change dimensions of the canvas call this method
     **
     > Parameters
     **
     - width (number) new width of the canvas
     - height (number) new height of the canvas
    \*/
    paperproto.setSize = function (width, height) {
        return R._engine.setSize.call(this, width, height);
    };
    /*\
     * Paper.setViewBox
     [ method ]
     **
     * Sets the view box of the paper. Practically it gives you ability to zoom and pan whole paper surface by 
     * specifying new boundaries.
     **
     > Parameters
     **
     - x (number) new x position, default is `0`
     - y (number) new y position, default is `0`
     - w (number) new width of the canvas
     - h (number) new height of the canvas
     - fit (boolean) `true` if you want graphics to fit into new boundary box
    \*/
    paperproto.setViewBox = function (x, y, w, h, fit) {
        return R._engine.setViewBox.call(this, x, y, w, h, fit);
    };
    /*\
     * Paper.top
     [ property ]
     **
     * Points to the topmost element on the paper
    \*/
    /*\
     * Paper.bottom
     [ property ]
     **
     * Points to the bottom element on the paper
    \*/
    paperproto.top = paperproto.bottom = null;
    /*\
     * Paper.raphael
     [ property ]
     **
     * Points to the @Raphael object/function
    \*/
    paperproto.raphael = R;
    var getOffset = function (elem) {
        var box = elem.getBoundingClientRect(),
            doc = elem.ownerDocument,
            body = doc.body,
            docElem = doc.documentElement,
            clientTop = docElem.clientTop || body.clientTop || 0, clientLeft = docElem.clientLeft || body.clientLeft || 0,
            top  = box.top  + (g.win.pageYOffset || docElem.scrollTop || body.scrollTop ) - clientTop,
            left = box.left + (g.win.pageXOffset || docElem.scrollLeft || body.scrollLeft) - clientLeft;
        return {
            y: top,
            x: left
        };
    };
    /*\
     * Paper.getElementByPoint
     [ method ]
     **
     * Returns you topmost element under given point.
     **
     = (object) RaphaÃ«l element object
     > Parameters
     **
     - x (number) x coordinate from the top left corner of the window
     - y (number) y coordinate from the top left corner of the window
     > Usage
     | paper.getElementByPoint(mouseX, mouseY).attr({stroke: "#f00"});
    \*/
    paperproto.getElementByPoint = function (x, y) {
        var paper = this,
            svg = paper.canvas,
            target = g.doc.elementFromPoint(x, y);
        if (g.win.opera && target.tagName == "svg") {
            var so = getOffset(svg),
                sr = svg.createSVGRect();
            sr.x = x - so.x;
            sr.y = y - so.y;
            sr.width = sr.height = 1;
            var hits = svg.getIntersectionList(sr, null);
            if (hits.length) {
                target = hits[hits.length - 1];
            }
        }
        if (!target) {
            return null;
        }
        while (target.parentNode && target != svg.parentNode && !target.raphael) {
            target = target.parentNode;
        }
        target == paper.canvas.parentNode && (target = svg);
        target = target && target.raphael ? paper.getById(target.raphaelid) : null;
        return target;
    };

    /*\
     * Paper.getElementsByBBox
     [ method ]
     **
     * Returns set of elements that have an intersecting bounding box
     **
     > Parameters
     **
     - bbox (object) bbox to check with
     = (object) @Set
     \*/
    paperproto.getElementsByBBox = function (bbox) {
        var set = this.set();
        this.forEach(function (el) {
            if (R.isBBoxIntersect(el.getBBox(), bbox)) {
                set.push(el);
            }
        });
        return set;
    };

    /*\
     * Paper.getById
     [ method ]
     **
     * Returns you element by its internal ID.
     **
     > Parameters
     **
     - id (number) id
     = (object) RaphaÃ«l element object
    \*/
    paperproto.getById = function (id) {
        var bot = this.bottom;
        while (bot) {
            if (bot.id == id) {
                return bot;
            }
            bot = bot.next;
        }
        return null;
    };
    /*\
     * Paper.forEach
     [ method ]
     **
     * Executes given function for each element on the paper
     *
     * If callback function returns `false` it will stop loop running.
     **
     > Parameters
     **
     - callback (function) function to run
     - thisArg (object) context object for the callback
     = (object) Paper object
     > Usage
     | paper.forEach(function (el) {
     |     el.attr({ stroke: "blue" });
     | });
    \*/
    paperproto.forEach = function (callback, thisArg) {
        var bot = this.bottom;
        while (bot) {
            if (callback.call(thisArg, bot) === false) {
                return this;
            }
            bot = bot.next;
        }
        return this;
    };
    /*\
     * Paper.getElementsByPoint
     [ method ]
     **
     * Returns set of elements that have common point inside
     **
     > Parameters
     **
     - x (number) x coordinate of the point
     - y (number) y coordinate of the point
     = (object) @Set
    \*/
    paperproto.getElementsByPoint = function (x, y) {
        var set = this.set();
        this.forEach(function (el) {
            if (el.isPointInside(x, y)) {
                set.push(el);
            }
        });
        return set;
    };
    function x_y() {
        return this.x + S + this.y;
    }
    function x_y_w_h() {
        return this.x + S + this.y + S + this.width + " \xd7 " + this.height;
    }
    /*\
     * Element.isPointInside
     [ method ]
     **
     * Determine if given point is inside this elementâ€™s shape
     **
     > Parameters
     **
     - x (number) x coordinate of the point
     - y (number) y coordinate of the point
     = (boolean) `true` if point inside the shape
    \*/
    elproto.isPointInside = function (x, y) {
        var rp = this.realPath = this.realPath || getPath[this.type](this);
        return R.isPointInsidePath(rp, x, y);
    };
    /*\
     * Element.getBBox
     [ method ]
     **
     * Return bounding box for a given element
     **
     > Parameters
     **
     - isWithoutTransform (boolean) flag, `true` if you want to have bounding box before transformations. Default is `false`.
     = (object) Bounding box object:
     o {
     o     x: (number) top left corner x
     o     y: (number) top left corner y
     o     x2: (number) bottom right corner x
     o     y2: (number) bottom right corner y
     o     width: (number) width
     o     height: (number) height
     o }
    \*/
    elproto.getBBox = function (isWithoutTransform) {
        if (this.removed) {
            return {};
        }
        var _ = this._;
        if (isWithoutTransform) {
            if (_.dirty || !_.bboxwt) {
                this.realPath = getPath[this.type](this);
                _.bboxwt = pathDimensions(this.realPath);
                _.bboxwt.toString = x_y_w_h;
                _.dirty = 0;
            }
            return _.bboxwt;
        }
        if (_.dirty || _.dirtyT || !_.bbox) {
            if (_.dirty || !this.realPath) {
                _.bboxwt = 0;
                this.realPath = getPath[this.type](this);
            }
            _.bbox = pathDimensions(mapPath(this.realPath, this.matrix));
            _.bbox.toString = x_y_w_h;
            _.dirty = _.dirtyT = 0;
        }
        return _.bbox;
    };
    /*\
     * Element.clone
     [ method ]
     **
     = (object) clone of a given element
     **
    \*/
    elproto.clone = function () {
        if (this.removed) {
            return null;
        }
        var out = this.paper[this.type]().attr(this.attr());
        this.__set__ && this.__set__.push(out);
        return out;
    };
    /*\
     * Element.glow
     [ method ]
     **
     * Return set of elements that create glow-like effect around given element. See @Paper.set.
     *
     * Note: Glow is not connected to the element. If you change element attributes it wonâ€™t adjust itself.
     **
     > Parameters
     **
     - glow (object) #optional parameters object with all properties optional:
     o {
     o     width (number) size of the glow, default is `10`
     o     fill (boolean) will it be filled, default is `false`
     o     opacity (number) opacity, default is `0.5`
     o     offsetx (number) horizontal offset, default is `0`
     o     offsety (number) vertical offset, default is `0`
     o     color (string) glow colour, default is `black`
     o }
     = (object) @Paper.set of elements that represents glow
    \*/
    elproto.glow = function (glow) {
        if (this.type == "text") {
            return null;
        }
        glow = glow || {};
        var s = {
            width: (glow.width || 10) + (+this.attr("stroke-width") || 1),
            fill: glow.fill || false,
            opacity: glow.opacity || .5,
            offsetx: glow.offsetx || 0,
            offsety: glow.offsety || 0,
            color: glow.color || "#000"
        },
            c = s.width / 2,
            r = this.paper,
            out = r.set(),
            path = this.realPath || getPath[this.type](this);
        path = this.matrix ? mapPath(path, this.matrix) : path;
        for (var i = 1; i < c + 1; i++) {
            out.push(r.path(path).attr({
                stroke: s.color,
                fill: s.fill ? s.color : "none",
                "stroke-linejoin": "round",
                "stroke-linecap": "round",
                "stroke-width": +(s.width / c * i).toFixed(3),
                opacity: +(s.opacity / c).toFixed(3)
            }));
        }
        return out.insertBefore(this).translate(s.offsetx, s.offsety);
    };
    var curveslengths = {},
    getPointAtSegmentLength = function (p1x, p1y, c1x, c1y, c2x, c2y, p2x, p2y, length) {
        if (length == null) {
            return bezlen(p1x, p1y, c1x, c1y, c2x, c2y, p2x, p2y);
        } else {
            return R.findDotsAtSegment(p1x, p1y, c1x, c1y, c2x, c2y, p2x, p2y, getTatLen(p1x, p1y, c1x, c1y, c2x, c2y, p2x, p2y, length));
        }
    },
    getLengthFactory = function (istotal, subpath) {
        return function (path, length, onlystart) {
            path = path2curve(path);
            var x, y, p, l, sp = "", subpaths = {}, point,
                len = 0;
            for (var i = 0, ii = path.length; i < ii; i++) {
                p = path[i];
                if (p[0] == "M") {
                    x = +p[1];
                    y = +p[2];
                } else {
                    l = getPointAtSegmentLength(x, y, p[1], p[2], p[3], p[4], p[5], p[6]);
                    if (len + l > length) {
                        if (subpath && !subpaths.start) {
                            point = getPointAtSegmentLength(x, y, p[1], p[2], p[3], p[4], p[5], p[6], length - len);
                            sp += ["C" + point.start.x, point.start.y, point.m.x, point.m.y, point.x, point.y];
                            if (onlystart) {return sp;}
                            subpaths.start = sp;
                            sp = ["M" + point.x, point.y + "C" + point.n.x, point.n.y, point.end.x, point.end.y, p[5], p[6]].join();
                            len += l;
                            x = +p[5];
                            y = +p[6];
                            continue;
                        }
                        if (!istotal && !subpath) {
                            point = getPointAtSegmentLength(x, y, p[1], p[2], p[3], p[4], p[5], p[6], length - len);
                            return {x: point.x, y: point.y, alpha: point.alpha};
                        }
                    }
                    len += l;
                    x = +p[5];
                    y = +p[6];
                }
                sp += p.shift() + p;
            }
            subpaths.end = sp;
            point = istotal ? len : subpath ? subpaths : R.findDotsAtSegment(x, y, p[0], p[1], p[2], p[3], p[4], p[5], 1);
            point.alpha && (point = {x: point.x, y: point.y, alpha: point.alpha});
            return point;
        };
    };
    var getTotalLength = getLengthFactory(1),
        getPointAtLength = getLengthFactory(),
        getSubpathsAtLength = getLengthFactory(0, 1);
    /*\
     * Raphael.getTotalLength
     [ method ]
     **
     * Returns length of the given path in pixels.
     **
     > Parameters
     **
     - path (string) SVG path string.
     **
     = (number) length.
    \*/
    R.getTotalLength = getTotalLength;
    /*\
     * Raphael.getPointAtLength
     [ method ]
     **
     * Return coordinates of the point located at the given length on the given path.
     **
     > Parameters
     **
     - path (string) SVG path string
     - length (number)
     **
     = (object) representation of the point:
     o {
     o     x: (number) x coordinate
     o     y: (number) y coordinate
     o     alpha: (number) angle of derivative
     o }
    \*/
    R.getPointAtLength = getPointAtLength;
    /*\
     * Raphael.getSubpath
     [ method ]
     **
     * Return subpath of a given path from given length to given length.
     **
     > Parameters
     **
     - path (string) SVG path string
     - from (number) position of the start of the segment
     - to (number) position of the end of the segment
     **
     = (string) pathstring for the segment
    \*/
    R.getSubpath = function (path, from, to) {
        if (this.getTotalLength(path) - to < 1e-6) {
            return getSubpathsAtLength(path, from).end;
        }
        var a = getSubpathsAtLength(path, to, 1);
        return from ? getSubpathsAtLength(a, from).end : a;
    };
    /*\
     * Element.getTotalLength
     [ method ]
     **
     * Returns length of the path in pixels. Only works for element of â€œpathâ€ type.
     = (number) length.
    \*/
    elproto.getTotalLength = function () {
        if (this.type != "path") {return;}
        if (this.node.getTotalLength) {
            return this.node.getTotalLength();
        }
        return getTotalLength(this.attrs.path);
    };
    /*\
     * Element.getPointAtLength
     [ method ]
     **
     * Return coordinates of the point located at the given length on the given path. Only works for element of â€œpathâ€ type.
     **
     > Parameters
     **
     - length (number)
     **
     = (object) representation of the point:
     o {
     o     x: (number) x coordinate
     o     y: (number) y coordinate
     o     alpha: (number) angle of derivative
     o }
    \*/
    elproto.getPointAtLength = function (length) {
        if (this.type != "path") {return;}
        return getPointAtLength(this.attrs.path, length);
    };
    /*\
     * Element.getSubpath
     [ method ]
     **
     * Return subpath of a given element from given length to given length. Only works for element of â€œpathâ€ type.
     **
     > Parameters
     **
     - from (number) position of the start of the segment
     - to (number) position of the end of the segment
     **
     = (string) pathstring for the segment
    \*/
    elproto.getSubpath = function (from, to) {
        if (this.type != "path") {return;}
        return R.getSubpath(this.attrs.path, from, to);
    };
    /*\
     * Raphael.easing_formulas
     [ property ]
     **
     * Object that contains easing formulas for animation. You could extend it with your own. By default it has following list of easing:
     # <ul>
     #     <li>â€œlinearâ€</li>
     #     <li>â€œ&lt;â€ or â€œeaseInâ€ or â€œease-inâ€</li>
     #     <li>â€œ>â€ or â€œeaseOutâ€ or â€œease-outâ€</li>
     #     <li>â€œ&lt;>â€ or â€œeaseInOutâ€ or â€œease-in-outâ€</li>
     #     <li>â€œbackInâ€ or â€œback-inâ€</li>
     #     <li>â€œbackOutâ€ or â€œback-outâ€</li>
     #     <li>â€œelasticâ€</li>
     #     <li>â€œbounceâ€</li>
     # </ul>
     # <p>See also <a href="http://raphaeljs.com/easing.html">Easing demo</a>.</p>
    \*/
    var ef = R.easing_formulas = {
        linear: function (n) {
            return n;
        },
        "<": function (n) {
            return pow(n, 1.7);
        },
        ">": function (n) {
            return pow(n, .48);
        },
        "<>": function (n) {
            var q = .48 - n / 1.04,
                Q = math.sqrt(.1734 + q * q),
                x = Q - q,
                X = pow(abs(x), 1 / 3) * (x < 0 ? -1 : 1),
                y = -Q - q,
                Y = pow(abs(y), 1 / 3) * (y < 0 ? -1 : 1),
                t = X + Y + .5;
            return (1 - t) * 3 * t * t + t * t * t;
        },
        backIn: function (n) {
            var s = 1.70158;
            return n * n * ((s + 1) * n - s);
        },
        backOut: function (n) {
            n = n - 1;
            var s = 1.70158;
            return n * n * ((s + 1) * n + s) + 1;
        },
        elastic: function (n) {
            if (n == !!n) {
                return n;
            }
            return pow(2, -10 * n) * math.sin((n - .075) * (2 * PI) / .3) + 1;
        },
        bounce: function (n) {
            var s = 7.5625,
                p = 2.75,
                l;
            if (n < (1 / p)) {
                l = s * n * n;
            } else {
                if (n < (2 / p)) {
                    n -= (1.5 / p);
                    l = s * n * n + .75;
                } else {
                    if (n < (2.5 / p)) {
                        n -= (2.25 / p);
                        l = s * n * n + .9375;
                    } else {
                        n -= (2.625 / p);
                        l = s * n * n + .984375;
                    }
                }
            }
            return l;
        }
    };
    ef.easeIn = ef["ease-in"] = ef["<"];
    ef.easeOut = ef["ease-out"] = ef[">"];
    ef.easeInOut = ef["ease-in-out"] = ef["<>"];
    ef["back-in"] = ef.backIn;
    ef["back-out"] = ef.backOut;

    var animationElements = [],
        requestAnimFrame = window.requestAnimationFrame       ||
                           window.webkitRequestAnimationFrame ||
                           window.mozRequestAnimationFrame    ||
                           window.oRequestAnimationFrame      ||
                           window.msRequestAnimationFrame     ||
                           function (callback) {
                               setTimeout(callback, 16);
                           },
        animation = function () {
            var Now = +new Date,
                l = 0;
            for (; l < animationElements.length; l++) {
                var e = animationElements[l];
                if (e.el.removed || e.paused) {
                    continue;
                }
                var time = Now - e.start,
                    ms = e.ms,
                    easing = e.easing,
                    from = e.from,
                    diff = e.diff,
                    to = e.to,
                    t = e.t,
                    that = e.el,
                    set = {},
                    now,
                    init = {},
                    key;
                if (e.initstatus) {
                    time = (e.initstatus * e.anim.top - e.prev) / (e.percent - e.prev) * ms;
                    e.status = e.initstatus;
                    delete e.initstatus;
                    e.stop && animationElements.splice(l--, 1);
                } else {
                    e.status = (e.prev + (e.percent - e.prev) * (time / ms)) / e.anim.top;
                }
                if (time < 0) {
                    continue;
                }
                if (time < ms) {
                    var pos = easing(time / ms);
                    for (var attr in from) if (from[has](attr)) {
                        switch (availableAnimAttrs[attr]) {
                            case nu:
                                now = +from[attr] + pos * ms * diff[attr];
                                break;
                            case "colour":
                                now = "rgb(" + [
                                    upto255(round(from[attr].r + pos * ms * diff[attr].r)),
                                    upto255(round(from[attr].g + pos * ms * diff[attr].g)),
                                    upto255(round(from[attr].b + pos * ms * diff[attr].b))
                                ].join(",") + ")";
                                break;
                            case "path":
                                now = [];
                                for (var i = 0, ii = from[attr].length; i < ii; i++) {
                                    now[i] = [from[attr][i][0]];
                                    for (var j = 1, jj = from[attr][i].length; j < jj; j++) {
                                        now[i][j] = +from[attr][i][j] + pos * ms * diff[attr][i][j];
                                    }
                                    now[i] = now[i].join(S);
                                }
                                now = now.join(S);
                                break;
                            case "transform":
                                if (diff[attr].real) {
                                    now = [];
                                    for (i = 0, ii = from[attr].length; i < ii; i++) {
                                        now[i] = [from[attr][i][0]];
                                        for (j = 1, jj = from[attr][i].length; j < jj; j++) {
                                            now[i][j] = from[attr][i][j] + pos * ms * diff[attr][i][j];
                                        }
                                    }
                                } else {
                                    var get = function (i) {
                                        return +from[attr][i] + pos * ms * diff[attr][i];
                                    };
                                    // now = [["r", get(2), 0, 0], ["t", get(3), get(4)], ["s", get(0), get(1), 0, 0]];
                                    now = [["m", get(0), get(1), get(2), get(3), get(4), get(5)]];
                                }
                                break;
                            case "csv":
                                if (attr == "clip-rect") {
                                    now = [];
                                    i = 4;
                                    while (i--) {
                                        now[i] = +from[attr][i] + pos * ms * diff[attr][i];
                                    }
                                }
                                break;
                            default:
                                var from2 = [][concat](from[attr]);
                                now = [];
                                i = that.paper.customAttributes[attr].length;
                                while (i--) {
                                    now[i] = +from2[i] + pos * ms * diff[attr][i];
                                }
                                break;
                        }
                        set[attr] = now;
                    }
                    that.attr(set);
                    (function (id, that, anim) {
                        setTimeout(function () {
                            eve("raphael.anim.frame." + id, that, anim);
                        });
                    })(that.id, that, e.anim);
                } else {
                    (function(f, el, a) {
                        setTimeout(function() {
                            eve("raphael.anim.frame." + el.id, el, a);
                            eve("raphael.anim.finish." + el.id, el, a);
                            R.is(f, "function") && f.call(el);
                        });
                    })(e.callback, that, e.anim);
                    that.attr(to);
                    animationElements.splice(l--, 1);
                    if (e.repeat > 1 && !e.next) {
                        for (key in to) if (to[has](key)) {
                            init[key] = e.totalOrigin[key];
                        }
                        e.el.attr(init);
                        runAnimation(e.anim, e.el, e.anim.percents[0], null, e.totalOrigin, e.repeat - 1);
                    }
                    if (e.next && !e.stop) {
                        runAnimation(e.anim, e.el, e.next, null, e.totalOrigin, e.repeat);
                    }
                }
            }
            R.svg && that && that.paper && that.paper.safari();
            animationElements.length && requestAnimFrame(animation);
        },
        upto255 = function (color) {
            return color > 255 ? 255 : color < 0 ? 0 : color;
        };
    /*\
     * Element.animateWith
     [ method ]
     **
     * Acts similar to @Element.animate, but ensure that given animation runs in sync with another given element.
     **
     > Parameters
     **
     - el (object) element to sync with
     - anim (object) animation to sync with
     - params (object) #optional final attributes for the element, see also @Element.attr
     - ms (number) #optional number of milliseconds for animation to run
     - easing (string) #optional easing type. Accept on of @Raphael.easing_formulas or CSS format: `cubic&#x2010;bezier(XX,&#160;XX,&#160;XX,&#160;XX)`
     - callback (function) #optional callback function. Will be called at the end of animation.
     * or
     - element (object) element to sync with
     - anim (object) animation to sync with
     - animation (object) #optional animation object, see @Raphael.animation
     **
     = (object) original element
    \*/
    elproto.animateWith = function (el, anim, params, ms, easing, callback) {
        var element = this;
        if (element.removed) {
            callback && callback.call(element);
            return element;
        }
        var a = params instanceof Animation ? params : R.animation(params, ms, easing, callback),
            x, y;
        runAnimation(a, element, a.percents[0], null, element.attr());
        for (var i = 0, ii = animationElements.length; i < ii; i++) {
            if (animationElements[i].anim == anim && animationElements[i].el == el) {
                animationElements[ii - 1].start = animationElements[i].start;
                break;
            }
        }
        return element;
        // 
        // 
        // var a = params ? R.animation(params, ms, easing, callback) : anim,
        //     status = element.status(anim);
        // return this.animate(a).status(a, status * anim.ms / a.ms);
    };
    function CubicBezierAtTime(t, p1x, p1y, p2x, p2y, duration) {
        var cx = 3 * p1x,
            bx = 3 * (p2x - p1x) - cx,
            ax = 1 - cx - bx,
            cy = 3 * p1y,
            by = 3 * (p2y - p1y) - cy,
            ay = 1 - cy - by;
        function sampleCurveX(t) {
            return ((ax * t + bx) * t + cx) * t;
        }
        function solve(x, epsilon) {
            var t = solveCurveX(x, epsilon);
            return ((ay * t + by) * t + cy) * t;
        }
        function solveCurveX(x, epsilon) {
            var t0, t1, t2, x2, d2, i;
            for(t2 = x, i = 0; i < 8; i++) {
                x2 = sampleCurveX(t2) - x;
                if (abs(x2) < epsilon) {
                    return t2;
                }
                d2 = (3 * ax * t2 + 2 * bx) * t2 + cx;
                if (abs(d2) < 1e-6) {
                    break;
                }
                t2 = t2 - x2 / d2;
            }
            t0 = 0;
            t1 = 1;
            t2 = x;
            if (t2 < t0) {
                return t0;
            }
            if (t2 > t1) {
                return t1;
            }
            while (t0 < t1) {
                x2 = sampleCurveX(t2);
                if (abs(x2 - x) < epsilon) {
                    return t2;
                }
                if (x > x2) {
                    t0 = t2;
                } else {
                    t1 = t2;
                }
                t2 = (t1 - t0) / 2 + t0;
            }
            return t2;
        }
        return solve(t, 1 / (200 * duration));
    }
    elproto.onAnimation = function (f) {
        f ? eve.on("raphael.anim.frame." + this.id, f) : eve.unbind("raphael.anim.frame." + this.id);
        return this;
    };
    function Animation(anim, ms) {
        var percents = [],
            newAnim = {};
        this.ms = ms;
        this.times = 1;
        if (anim) {
            for (var attr in anim) if (anim[has](attr)) {
                newAnim[toFloat(attr)] = anim[attr];
                percents.push(toFloat(attr));
            }
            percents.sort(sortByNumber);
        }
        this.anim = newAnim;
        this.top = percents[percents.length - 1];
        this.percents = percents;
    }
    /*\
     * Animation.delay
     [ method ]
     **
     * Creates a copy of existing animation object with given delay.
     **
     > Parameters
     **
     - delay (number) number of ms to pass between animation start and actual animation
     **
     = (object) new altered Animation object
     | var anim = Raphael.animation({cx: 10, cy: 20}, 2e3);
     | circle1.animate(anim); // run the given animation immediately
     | circle2.animate(anim.delay(500)); // run the given animation after 500 ms
    \*/
    Animation.prototype.delay = function (delay) {
        var a = new Animation(this.anim, this.ms);
        a.times = this.times;
        a.del = +delay || 0;
        return a;
    };
    /*\
     * Animation.repeat
     [ method ]
     **
     * Creates a copy of existing animation object with given repetition.
     **
     > Parameters
     **
     - repeat (number) number iterations of animation. For infinite animation pass `Infinity`
     **
     = (object) new altered Animation object
    \*/
    Animation.prototype.repeat = function (times) { 
        var a = new Animation(this.anim, this.ms);
        a.del = this.del;
        a.times = math.floor(mmax(times, 0)) || 1;
        return a;
    };
    function runAnimation(anim, element, percent, status, totalOrigin, times) {
        percent = toFloat(percent);
        var params,
            isInAnim,
            isInAnimSet,
            percents = [],
            next,
            prev,
            timestamp,
            ms = anim.ms,
            from = {},
            to = {},
            diff = {};
        if (status) {
            for (i = 0, ii = animationElements.length; i < ii; i++) {
                var e = animationElements[i];
                if (e.el.id == element.id && e.anim == anim) {
                    if (e.percent != percent) {
                        animationElements.splice(i, 1);
                        isInAnimSet = 1;
                    } else {
                        isInAnim = e;
                    }
                    element.attr(e.totalOrigin);
                    break;
                }
            }
        } else {
            status = +to; // NaN
        }
        for (var i = 0, ii = anim.percents.length; i < ii; i++) {
            if (anim.percents[i] == percent || anim.percents[i] > status * anim.top) {
                percent = anim.percents[i];
                prev = anim.percents[i - 1] || 0;
                ms = ms / anim.top * (percent - prev);
                next = anim.percents[i + 1];
                params = anim.anim[percent];
                break;
            } else if (status) {
                element.attr(anim.anim[anim.percents[i]]);
            }
        }
        if (!params) {
            return;
        }
        if (!isInAnim) {
            for (var attr in params) if (params[has](attr)) {
                if (availableAnimAttrs[has](attr) || element.paper.customAttributes[has](attr)) {
                    from[attr] = element.attr(attr);
                    (from[attr] == null) && (from[attr] = availableAttrs[attr]);
                    to[attr] = params[attr];
                    switch (availableAnimAttrs[attr]) {
                        case nu:
                            diff[attr] = (to[attr] - from[attr]) / ms;
                            break;
                        case "colour":
                            from[attr] = R.getRGB(from[attr]);
                            var toColour = R.getRGB(to[attr]);
                            diff[attr] = {
                                r: (toColour.r - from[attr].r) / ms,
                                g: (toColour.g - from[attr].g) / ms,
                                b: (toColour.b - from[attr].b) / ms
                            };
                            break;
                        case "path":
                            var pathes = path2curve(from[attr], to[attr]),
                                toPath = pathes[1];
                            from[attr] = pathes[0];
                            diff[attr] = [];
                            for (i = 0, ii = from[attr].length; i < ii; i++) {
                                diff[attr][i] = [0];
                                for (var j = 1, jj = from[attr][i].length; j < jj; j++) {
                                    diff[attr][i][j] = (toPath[i][j] - from[attr][i][j]) / ms;
                                }
                            }
                            break;
                        case "transform":
                            var _ = element._,
                                eq = equaliseTransform(_[attr], to[attr]);
                            if (eq) {
                                from[attr] = eq.from;
                                to[attr] = eq.to;
                                diff[attr] = [];
                                diff[attr].real = true;
                                for (i = 0, ii = from[attr].length; i < ii; i++) {
                                    diff[attr][i] = [from[attr][i][0]];
                                    for (j = 1, jj = from[attr][i].length; j < jj; j++) {
                                        diff[attr][i][j] = (to[attr][i][j] - from[attr][i][j]) / ms;
                                    }
                                }
                            } else {
                                var m = (element.matrix || new Matrix),
                                    to2 = {
                                        _: {transform: _.transform},
                                        getBBox: function () {
                                            return element.getBBox(1);
                                        }
                                    };
                                from[attr] = [
                                    m.a,
                                    m.b,
                                    m.c,
                                    m.d,
                                    m.e,
                                    m.f
                                ];
                                extractTransform(to2, to[attr]);
                                to[attr] = to2._.transform;
                                diff[attr] = [
                                    (to2.matrix.a - m.a) / ms,
                                    (to2.matrix.b - m.b) / ms,
                                    (to2.matrix.c - m.c) / ms,
                                    (to2.matrix.d - m.d) / ms,
                                    (to2.matrix.e - m.e) / ms,
                                    (to2.matrix.f - m.f) / ms
                                ];
                                // from[attr] = [_.sx, _.sy, _.deg, _.dx, _.dy];
                                // var to2 = {_:{}, getBBox: function () { return element.getBBox(); }};
                                // extractTransform(to2, to[attr]);
                                // diff[attr] = [
                                //     (to2._.sx - _.sx) / ms,
                                //     (to2._.sy - _.sy) / ms,
                                //     (to2._.deg - _.deg) / ms,
                                //     (to2._.dx - _.dx) / ms,
                                //     (to2._.dy - _.dy) / ms
                                // ];
                            }
                            break;
                        case "csv":
                            var values = Str(params[attr])[split](separator),
                                from2 = Str(from[attr])[split](separator);
                            if (attr == "clip-rect") {
                                from[attr] = from2;
                                diff[attr] = [];
                                i = from2.length;
                                while (i--) {
                                    diff[attr][i] = (values[i] - from[attr][i]) / ms;
                                }
                            }
                            to[attr] = values;
                            break;
                        default:
                            values = [][concat](params[attr]);
                            from2 = [][concat](from[attr]);
                            diff[attr] = [];
                            i = element.paper.customAttributes[attr].length;
                            while (i--) {
                                diff[attr][i] = ((values[i] || 0) - (from2[i] || 0)) / ms;
                            }
                            break;
                    }
                }
            }
            var easing = params.easing,
                easyeasy = R.easing_formulas[easing];
            if (!easyeasy) {
                easyeasy = Str(easing).match(bezierrg);
                if (easyeasy && easyeasy.length == 5) {
                    var curve = easyeasy;
                    easyeasy = function (t) {
                        return CubicBezierAtTime(t, +curve[1], +curve[2], +curve[3], +curve[4], ms);
                    };
                } else {
                    easyeasy = pipe;
                }
            }
            timestamp = params.start || anim.start || +new Date;
            e = {
                anim: anim,
                percent: percent,
                timestamp: timestamp,
                start: timestamp + (anim.del || 0),
                status: 0,
                initstatus: status || 0,
                stop: false,
                ms: ms,
                easing: easyeasy,
                from: from,
                diff: diff,
                to: to,
                el: element,
                callback: params.callback,
                prev: prev,
                next: next,
                repeat: times || anim.times,
                origin: element.attr(),
                totalOrigin: totalOrigin
            };
            animationElements.push(e);
            if (status && !isInAnim && !isInAnimSet) {
                e.stop = true;
                e.start = new Date - ms * status;
                if (animationElements.length == 1) {
                    return animation();
                }
            }
            if (isInAnimSet) {
                e.start = new Date - e.ms * status;
            }
            animationElements.length == 1 && requestAnimFrame(animation);
        } else {
            isInAnim.initstatus = status;
            isInAnim.start = new Date - isInAnim.ms * status;
        }
        eve("raphael.anim.start." + element.id, element, anim);
    }
    /*\
     * Raphael.animation
     [ method ]
     **
     * Creates an animation object that can be passed to the @Element.animate or @Element.animateWith methods.
     * See also @Animation.delay and @Animation.repeat methods.
     **
     > Parameters
     **
     - params (object) final attributes for the element, see also @Element.attr
     - ms (number) number of milliseconds for animation to run
     - easing (string) #optional easing type. Accept one of @Raphael.easing_formulas or CSS format: `cubic&#x2010;bezier(XX,&#160;XX,&#160;XX,&#160;XX)`
     - callback (function) #optional callback function. Will be called at the end of animation.
     **
     = (object) @Animation
    \*/
    R.animation = function (params, ms, easing, callback) {
        if (params instanceof Animation) {
            return params;
        }
        if (R.is(easing, "function") || !easing) {
            callback = callback || easing || null;
            easing = null;
        }
        params = Object(params);
        ms = +ms || 0;
        var p = {},
            json,
            attr;
        for (attr in params) if (params[has](attr) && toFloat(attr) != attr && toFloat(attr) + "%" != attr) {
            json = true;
            p[attr] = params[attr];
        }
        if (!json) {
            return new Animation(params, ms);
        } else {
            easing && (p.easing = easing);
            callback && (p.callback = callback);
            return new Animation({100: p}, ms);
        }
    };
    /*\
     * Element.animate
     [ method ]
     **
     * Creates and starts animation for given element.
     **
     > Parameters
     **
     - params (object) final attributes for the element, see also @Element.attr
     - ms (number) number of milliseconds for animation to run
     - easing (string) #optional easing type. Accept one of @Raphael.easing_formulas or CSS format: `cubic&#x2010;bezier(XX,&#160;XX,&#160;XX,&#160;XX)`
     - callback (function) #optional callback function. Will be called at the end of animation.
     * or
     - animation (object) animation object, see @Raphael.animation
     **
     = (object) original element
    \*/
    elproto.animate = function (params, ms, easing, callback) {
        var element = this;
        if (element.removed) {
            callback && callback.call(element);
            return element;
        }
        var anim = params instanceof Animation ? params : R.animation(params, ms, easing, callback);
        runAnimation(anim, element, anim.percents[0], null, element.attr());
        return element;
    };
    /*\
     * Element.setTime
     [ method ]
     **
     * Sets the status of animation of the element in milliseconds. Similar to @Element.status method.
     **
     > Parameters
     **
     - anim (object) animation object
     - value (number) number of milliseconds from the beginning of the animation
     **
     = (object) original element if `value` is specified
     * Note, that during animation following events are triggered:
     *
     * On each animation frame event `anim.frame.<id>`, on start `anim.start.<id>` and on end `anim.finish.<id>`.
    \*/
    elproto.setTime = function (anim, value) {
        if (anim && value != null) {
            this.status(anim, mmin(value, anim.ms) / anim.ms);
        }
        return this;
    };
    /*\
     * Element.status
     [ method ]
     **
     * Gets or sets the status of animation of the element.
     **
     > Parameters
     **
     - anim (object) #optional animation object
     - value (number) #optional 0 â€“ 1. If specified, method works like a setter and sets the status of a given animation to the value. This will cause animation to jump to the given position.
     **
     = (number) status
     * or
     = (array) status if `anim` is not specified. Array of objects in format:
     o {
     o     anim: (object) animation object
     o     status: (number) status
     o }
     * or
     = (object) original element if `value` is specified
    \*/
    elproto.status = function (anim, value) {
        var out = [],
            i = 0,
            len,
            e;
        if (value != null) {
            runAnimation(anim, this, -1, mmin(value, 1));
            return this;
        } else {
            len = animationElements.length;
            for (; i < len; i++) {
                e = animationElements[i];
                if (e.el.id == this.id && (!anim || e.anim == anim)) {
                    if (anim) {
                        return e.status;
                    }
                    out.push({
                        anim: e.anim,
                        status: e.status
                    });
                }
            }
            if (anim) {
                return 0;
            }
            return out;
        }
    };
    /*\
     * Element.pause
     [ method ]
     **
     * Stops animation of the element with ability to resume it later on.
     **
     > Parameters
     **
     - anim (object) #optional animation object
     **
     = (object) original element
    \*/
    elproto.pause = function (anim) {
        for (var i = 0; i < animationElements.length; i++) if (animationElements[i].el.id == this.id && (!anim || animationElements[i].anim == anim)) {
            if (eve("raphael.anim.pause." + this.id, this, animationElements[i].anim) !== false) {
                animationElements[i].paused = true;
            }
        }
        return this;
    };
    /*\
     * Element.resume
     [ method ]
     **
     * Resumes animation if it was paused with @Element.pause method.
     **
     > Parameters
     **
     - anim (object) #optional animation object
     **
     = (object) original element
    \*/
    elproto.resume = function (anim) {
        for (var i = 0; i < animationElements.length; i++) if (animationElements[i].el.id == this.id && (!anim || animationElements[i].anim == anim)) {
            var e = animationElements[i];
            if (eve("raphael.anim.resume." + this.id, this, e.anim) !== false) {
                delete e.paused;
                this.status(e.anim, e.status);
            }
        }
        return this;
    };
    /*\
     * Element.stop
     [ method ]
     **
     * Stops animation of the element.
     **
     > Parameters
     **
     - anim (object) #optional animation object
     **
     = (object) original element
    \*/
    elproto.stop = function (anim) {
        for (var i = 0; i < animationElements.length; i++) if (animationElements[i].el.id == this.id && (!anim || animationElements[i].anim == anim)) {
            if (eve("raphael.anim.stop." + this.id, this, animationElements[i].anim) !== false) {
                animationElements.splice(i--, 1);
            }
        }
        return this;
    };
    function stopAnimation(paper) {
        for (var i = 0; i < animationElements.length; i++) if (animationElements[i].el.paper == paper) {
            animationElements.splice(i--, 1);
        }
    }
    eve.on("raphael.remove", stopAnimation);
    eve.on("raphael.clear", stopAnimation);
    elproto.toString = function () {
        return "Rapha\xebl\u2019s object";
    };

    // Set
    var Set = function (items) {
        this.items = [];
        this.length = 0;
        this.type = "set";
        if (items) {
            for (var i = 0, ii = items.length; i < ii; i++) {
                if (items[i] && (items[i].constructor == elproto.constructor || items[i].constructor == Set)) {
                    this[this.items.length] = this.items[this.items.length] = items[i];
                    this.length++;
                }
            }
        }
    },
    setproto = Set.prototype;
    /*\
     * Set.push
     [ method ]
     **
     * Adds each argument to the current set.
     = (object) original element
    \*/
    setproto.push = function () {
        var item,
            len;
        for (var i = 0, ii = arguments.length; i < ii; i++) {
            item = arguments[i];
            if (item && (item.constructor == elproto.constructor || item.constructor == Set)) {
                len = this.items.length;
                this[len] = this.items[len] = item;
                this.length++;
            }
        }
        return this;
    };
    /*\
     * Set.pop
     [ method ]
     **
     * Removes last element and returns it.
     = (object) element
    \*/
    setproto.pop = function () {
        this.length && delete this[this.length--];
        return this.items.pop();
    };
    /*\
     * Set.forEach
     [ method ]
     **
     * Executes given function for each element in the set.
     *
     * If function returns `false` it will stop loop running.
     **
     > Parameters
     **
     - callback (function) function to run
     - thisArg (object) context object for the callback
     = (object) Set object
    \*/
    setproto.forEach = function (callback, thisArg) {
        for (var i = 0, ii = this.items.length; i < ii; i++) {
            if (callback.call(thisArg, this.items[i], i) === false) {
                return this;
            }
        }
        return this;
    };
    for (var method in elproto) if (elproto[has](method)) {
        setproto[method] = (function (methodname) {
            return function () {
                var arg = arguments;
                return this.forEach(function (el) {
                    el[methodname][apply](el, arg);
                });
            };
        })(method);
    }
    setproto.attr = function (name, value) {
        if (name && R.is(name, array) && R.is(name[0], "object")) {
            for (var j = 0, jj = name.length; j < jj; j++) {
                this.items[j].attr(name[j]);
            }
        } else {
            for (var i = 0, ii = this.items.length; i < ii; i++) {
                this.items[i].attr(name, value);
            }
        }
        return this;
    };
    /*\
     * Set.clear
     [ method ]
     **
     * Removeds all elements from the set
    \*/
    setproto.clear = function () {
        while (this.length) {
            this.pop();
        }
    };
    /*\
     * Set.splice
     [ method ]
     **
     * Removes given element from the set
     **
     > Parameters
     **
     - index (number) position of the deletion
     - count (number) number of element to remove
     - insertionâ€¦ (object) #optional elements to insert
     = (object) set elements that were deleted
    \*/
    setproto.splice = function (index, count, insertion) {
        index = index < 0 ? mmax(this.length + index, 0) : index;
        count = mmax(0, mmin(this.length - index, count));
        var tail = [],
            todel = [],
            args = [],
            i;
        for (i = 2; i < arguments.length; i++) {
            args.push(arguments[i]);
        }
        for (i = 0; i < count; i++) {
            todel.push(this[index + i]);
        }
        for (; i < this.length - index; i++) {
            tail.push(this[index + i]);
        }
        var arglen = args.length;
        for (i = 0; i < arglen + tail.length; i++) {
            this.items[index + i] = this[index + i] = i < arglen ? args[i] : tail[i - arglen];
        }
        i = this.items.length = this.length -= count - arglen;
        while (this[i]) {
            delete this[i++];
        }
        return new Set(todel);
    };
    /*\
     * Set.exclude
     [ method ]
     **
     * Removes given element from the set
     **
     > Parameters
     **
     - element (object) element to remove
     = (boolean) `true` if object was found & removed from the set
    \*/
    setproto.exclude = function (el) {
        for (var i = 0, ii = this.length; i < ii; i++) if (this[i] == el) {
            this.splice(i, 1);
            return true;
        }
    };
    setproto.animate = function (params, ms, easing, callback) {
        (R.is(easing, "function") || !easing) && (callback = easing || null);
        var len = this.items.length,
            i = len,
            item,
            set = this,
            collector;
        if (!len) {
            return this;
        }
        callback && (collector = function () {
            !--len && callback.call(set);
        });
        easing = R.is(easing, string) ? easing : collector;
        var anim = R.animation(params, ms, easing, collector);
        item = this.items[--i].animate(anim);
        while (i--) {
            this.items[i] && !this.items[i].removed && this.items[i].animateWith(item, anim, anim);
        }
        return this;
    };
    setproto.insertAfter = function (el) {
        var i = this.items.length;
        while (i--) {
            this.items[i].insertAfter(el);
        }
        return this;
    };
    setproto.getBBox = function () {
        var x = [],
            y = [],
            x2 = [],
            y2 = [];
        for (var i = this.items.length; i--;) if (!this.items[i].removed) {
            var box = this.items[i].getBBox();
            x.push(box.x);
            y.push(box.y);
            x2.push(box.x + box.width);
            y2.push(box.y + box.height);
        }
        x = mmin[apply](0, x);
        y = mmin[apply](0, y);
        x2 = mmax[apply](0, x2);
        y2 = mmax[apply](0, y2);
        return {
            x: x,
            y: y,
            x2: x2,
            y2: y2,
            width: x2 - x,
            height: y2 - y
        };
    };
    setproto.clone = function (s) {
        s = this.paper.set();
        for (var i = 0, ii = this.items.length; i < ii; i++) {
            s.push(this.items[i].clone());
        }
        return s;
    };
    setproto.toString = function () {
        return "Rapha\xebl\u2018s set";
    };

    setproto.glow = function(glowConfig) {
        var ret = this.paper.set();
        this.forEach(function(shape, index){
            var g = shape.glow(glowConfig);
            if(g != null){
                g.forEach(function(shape2, index2){
                    ret.push(shape2);
                });
            }
        });
        return ret;
    };

    /*\
     * Raphael.registerFont
     [ method ]
     **
     * Adds given font to the registered set of fonts for RaphaÃ«l. Should be used as an internal call from within CufÃ³nâ€™s font file.
     * Returns original parameter, so it could be used with chaining.
     # <a href="http://wiki.github.com/sorccu/cufon/about">More about CufÃ³n and how to convert your font form TTF, OTF, etc to JavaScript file.</a>
     **
     > Parameters
     **
     - font (object) the font to register
     = (object) the font you passed in
     > Usage
     | Cufon.registerFont(Raphael.registerFont({â€¦}));
    \*/
    R.registerFont = function (font) {
        if (!font.face) {
            return font;
        }
        this.fonts = this.fonts || {};
        var fontcopy = {
                w: font.w,
                face: {},
                glyphs: {}
            },
            family = font.face["font-family"];
        for (var prop in font.face) if (font.face[has](prop)) {
            fontcopy.face[prop] = font.face[prop];
        }
        if (this.fonts[family]) {
            this.fonts[family].push(fontcopy);
        } else {
            this.fonts[family] = [fontcopy];
        }
        if (!font.svg) {
            fontcopy.face["units-per-em"] = toInt(font.face["units-per-em"], 10);
            for (var glyph in font.glyphs) if (font.glyphs[has](glyph)) {
                var path = font.glyphs[glyph];
                fontcopy.glyphs[glyph] = {
                    w: path.w,
                    k: {},
                    d: path.d && "M" + path.d.replace(/[mlcxtrv]/g, function (command) {
                            return {l: "L", c: "C", x: "z", t: "m", r: "l", v: "c"}[command] || "M";
                        }) + "z"
                };
                if (path.k) {
                    for (var k in path.k) if (path[has](k)) {
                        fontcopy.glyphs[glyph].k[k] = path.k[k];
                    }
                }
            }
        }
        return font;
    };
    /*\
     * Paper.getFont
     [ method ]
     **
     * Finds font object in the registered fonts by given parameters. You could specify only one word from the font name, like â€œMyriadâ€ for â€œMyriad Proâ€.
     **
     > Parameters
     **
     - family (string) font family name or any word from it
     - weight (string) #optional font weight
     - style (string) #optional font style
     - stretch (string) #optional font stretch
     = (object) the font object
     > Usage
     | paper.print(100, 100, "Test string", paper.getFont("Times", 800), 30);
    \*/
    paperproto.getFont = function (family, weight, style, stretch) {
        stretch = stretch || "normal";
        style = style || "normal";
        weight = +weight || {normal: 400, bold: 700, lighter: 300, bolder: 800}[weight] || 400;
        if (!R.fonts) {
            return;
        }
        var font = R.fonts[family];
        if (!font) {
            var name = new RegExp("(^|\\s)" + family.replace(/[^\w\d\s+!~.:_-]/g, E) + "(\\s|$)", "i");
            for (var fontName in R.fonts) if (R.fonts[has](fontName)) {
                if (name.test(fontName)) {
                    font = R.fonts[fontName];
                    break;
                }
            }
        }
        var thefont;
        if (font) {
            for (var i = 0, ii = font.length; i < ii; i++) {
                thefont = font[i];
                if (thefont.face["font-weight"] == weight && (thefont.face["font-style"] == style || !thefont.face["font-style"]) && thefont.face["font-stretch"] == stretch) {
                    break;
                }
            }
        }
        return thefont;
    };
    /*\
     * Paper.print
     [ method ]
     **
     * Creates path that represent given text written using given font at given position with given size.
     * Result of the method is path element that contains whole text as a separate path.
     **
     > Parameters
     **
     - x (number) x position of the text
     - y (number) y position of the text
     - string (string) text to print
     - font (object) font object, see @Paper.getFont
     - size (number) #optional size of the font, default is `16`
     - origin (string) #optional could be `"baseline"` or `"middle"`, default is `"middle"`
     - letter_spacing (number) #optional number in range `-1..1`, default is `0`
     - line_spacing (number) #optional number in range `1..3`, default is `1`
     = (object) resulting path element, which consist of all letters
     > Usage
     | var txt = r.print(10, 50, "print", r.getFont("Museo"), 30).attr({fill: "#fff"});
    \*/
    paperproto.print = function (x, y, string, font, size, origin, letter_spacing, line_spacing) {
        origin = origin || "middle"; // baseline|middle
        letter_spacing = mmax(mmin(letter_spacing || 0, 1), -1);
        line_spacing = mmax(mmin(line_spacing || 1, 3), 1);
        var letters = Str(string)[split](E),
            shift = 0,
            notfirst = 0,
            path = E,
            scale;
        R.is(font, "string") && (font = this.getFont(font));
        if (font) {
            scale = (size || 16) / font.face["units-per-em"];
            var bb = font.face.bbox[split](separator),
                top = +bb[0],
                lineHeight = bb[3] - bb[1],
                shifty = 0,
                height = +bb[1] + (origin == "baseline" ? lineHeight + (+font.face.descent) : lineHeight / 2);
            for (var i = 0, ii = letters.length; i < ii; i++) {
                if (letters[i] == "\n") {
                    shift = 0;
                    curr = 0;
                    notfirst = 0;
                    shifty += lineHeight * line_spacing;
                } else {
                    var prev = notfirst && font.glyphs[letters[i - 1]] || {},
                        curr = font.glyphs[letters[i]];
                    shift += notfirst ? (prev.w || font.w) + (prev.k && prev.k[letters[i]] || 0) + (font.w * letter_spacing) : 0;
                    notfirst = 1;
                }
                if (curr && curr.d) {
                    path += R.transformPath(curr.d, ["t", shift * scale, shifty * scale, "s", scale, scale, top, height, "t", (x - top) / scale, (y - height) / scale]);
                }
            }
        }
        return this.path(path).attr({
            fill: "#000",
            stroke: "none"
        });
    };

    /*\
     * Paper.add
     [ method ]
     **
     * Imports elements in JSON array in format `{type: type, <attributes>}`
     **
     > Parameters
     **
     - json (array)
     = (object) resulting set of imported elements
     > Usage
     | paper.add([
     |     {
     |         type: "circle",
     |         cx: 10,
     |         cy: 10,
     |         r: 5
     |     },
     |     {
     |         type: "rect",
     |         x: 10,
     |         y: 10,
     |         width: 10,
     |         height: 10,
     |         fill: "#fc0"
     |     }
     | ]);
    \*/
    paperproto.add = function (json) {
        if (R.is(json, "array")) {
            var res = this.set(),
                i = 0,
                ii = json.length,
                j;
            for (; i < ii; i++) {
                j = json[i] || {};
                elements[has](j.type) && res.push(this[j.type]().attr(j));
            }
        }
        return res;
    };

    /*\
     * Raphael.format
     [ method ]
     **
     * Simple format function. Replaces construction of type â€œ`{<number>}`â€ to the corresponding argument.
     **
     > Parameters
     **
     - token (string) string to format
     - â€¦ (string) rest of arguments will be treated as parameters for replacement
     = (string) formated string
     > Usage
     | var x = 10,
     |     y = 20,
     |     width = 40,
     |     height = 50;
     | // this will draw a rectangular shape equivalent to "M10,20h40v50h-40z"
     | paper.path(Raphael.format("M{0},{1}h{2}v{3}h{4}z", x, y, width, height, -width));
    \*/
    R.format = function (token, params) {
        var args = R.is(params, array) ? [0][concat](params) : arguments;
        token && R.is(token, string) && args.length - 1 && (token = token.replace(formatrg, function (str, i) {
            return args[++i] == null ? E : args[i];
        }));
        return token || E;
    };
    /*\
     * Raphael.fullfill
     [ method ]
     **
     * A little bit more advanced format function than @Raphael.format. Replaces construction of type â€œ`{<name>}`â€ to the corresponding argument.
     **
     > Parameters
     **
     - token (string) string to format
     - json (object) object which properties will be used as a replacement
     = (string) formated string
     > Usage
     | // this will draw a rectangular shape equivalent to "M10,20h40v50h-40z"
     | paper.path(Raphael.fullfill("M{x},{y}h{dim.width}v{dim.height}h{dim['negative width']}z", {
     |     x: 10,
     |     y: 20,
     |     dim: {
     |         width: 40,
     |         height: 50,
     |         "negative width": -40
     |     }
     | }));
    \*/
    R.fullfill = (function () {
        var tokenRegex = /\{([^\}]+)\}/g,
            objNotationRegex = /(?:(?:^|\.)(.+?)(?=\[|\.|$|\()|\[('|")(.+?)\2\])(\(\))?/g, // matches .xxxxx or ["xxxxx"] to run over object properties
            replacer = function (all, key, obj) {
                var res = obj;
                key.replace(objNotationRegex, function (all, name, quote, quotedName, isFunc) {
                    name = name || quotedName;
                    if (res) {
                        if (name in res) {
                            res = res[name];
                        }
                        typeof res == "function" && isFunc && (res = res());
                    }
                });
                res = (res == null || res == obj ? all : res) + "";
                return res;
            };
        return function (str, obj) {
            return String(str).replace(tokenRegex, function (all, key) {
                return replacer(all, key, obj);
            });
        };
    })();
    /*\
     * Raphael.ninja
     [ method ]
     **
     * If you want to leave no trace of RaphaÃ«l (Well, RaphaÃ«l creates only one global variable `Raphael`, but anyway.) You can use `ninja` method.
     * Beware, that in this case plugins could stop working, because they are depending on global variable existance.
     **
     = (object) Raphael object
     > Usage
     | (function (local_raphael) {
     |     var paper = local_raphael(10, 10, 320, 200);
     |     â€¦
     | })(Raphael.ninja());
    \*/
    R.ninja = function () {
        oldRaphael.was ? (g.win.Raphael = oldRaphael.is) : delete Raphael;
        return R;
    };
    /*\
     * Raphael.st
     [ property (object) ]
     **
     * You can add your own method to elements and sets. It is wise to add a set method for each element method
     * you added, so you will be able to call the same method on sets too.
     **
     * See also @Raphael.el.
     > Usage
     | Raphael.el.red = function () {
     |     this.attr({fill: "#f00"});
     | };
     | Raphael.st.red = function () {
     |     this.forEach(function (el) {
     |         el.red();
     |     });
     | };
     | // then use it
     | paper.set(paper.circle(100, 100, 20), paper.circle(110, 100, 20)).red();
    \*/
    R.st = setproto;
    // Firefox <3.6 fix: http://webreflection.blogspot.com/2009/11/195-chars-to-help-lazy-loading.html
    (function (doc, loaded, f) {
        if (doc.readyState == null && doc.addEventListener){
            doc.addEventListener(loaded, f = function () {
                doc.removeEventListener(loaded, f, false);
                doc.readyState = "complete";
            }, false);
            doc.readyState = "loading";
        }
        function isLoaded() {
            (/in/).test(doc.readyState) ? setTimeout(isLoaded, 9) : R.eve("raphael.DOMload");
        }
        isLoaded();
    })(document, "DOMContentLoaded");

    eve.on("raphael.DOMload", function () {
        loaded = true;
    });

// â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â” \\
// â”‚ RaphaÃ«l - JavaScript Vector Library                                 â”‚ \\
// â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¤ \\
// â”‚ SVG Module                                                          â”‚ \\
// â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¤ \\
// â”‚ Copyright (c) 2008-2011 Dmitry Baranovskiy (http://raphaeljs.com)   â”‚ \\
// â”‚ Copyright (c) 2008-2011 Sencha Labs (http://sencha.com)             â”‚ \\
// â”‚ Licensed under the MIT (http://raphaeljs.com/license.html) license. â”‚ \\
// â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜ \\

(function(){
    if (!R.svg) {
        return;
    }
    var has = "hasOwnProperty",
        Str = String,
        toFloat = parseFloat,
        toInt = parseInt,
        math = Math,
        mmax = math.max,
        abs = math.abs,
        pow = math.pow,
        separator = /[, ]+/,
        eve = R.eve,
        E = "",
        S = " ";
    var xlink = "http://www.w3.org/1999/xlink",
        markers = {
            block: "M5,0 0,2.5 5,5z",
            classic: "M5,0 0,2.5 5,5 3.5,3 3.5,2z",
            diamond: "M2.5,0 5,2.5 2.5,5 0,2.5z",
            open: "M6,1 1,3.5 6,6",
            oval: "M2.5,0A2.5,2.5,0,0,1,2.5,5 2.5,2.5,0,0,1,2.5,0z"
        },
        markerCounter = {};
    R.toString = function () {
        return  "Your browser supports SVG.\nYou are running Rapha\xebl " + this.version;
    };
    var $ = function (el, attr) {
        if (attr) {
            if (typeof el == "string") {
                el = $(el);
            }
            for (var key in attr) if (attr[has](key)) {
                if (key.substring(0, 6) == "xlink:") {
                    el.setAttributeNS(xlink, key.substring(6), Str(attr[key]));
                } else {
                    el.setAttribute(key, Str(attr[key]));
                }
            }
        } else {
            el = R._g.doc.createElementNS("http://www.w3.org/2000/svg", el);
            el.style && (el.style.webkitTapHighlightColor = "rgba(0,0,0,0)");
        }
        return el;
    },
    addGradientFill = function (element, gradient) {
        var type = "linear",
            id = element.id + gradient,
            fx = .5, fy = .5,
            o = element.node,
            SVG = element.paper,
            s = o.style,
            el = R._g.doc.getElementById(id);
        if (!el) {
            gradient = Str(gradient).replace(R._radial_gradient, function (all, _fx, _fy) {
                type = "radial";
                if (_fx && _fy) {
                    fx = toFloat(_fx);
                    fy = toFloat(_fy);
                    var dir = ((fy > .5) * 2 - 1);
                    pow(fx - .5, 2) + pow(fy - .5, 2) > .25 &&
                        (fy = math.sqrt(.25 - pow(fx - .5, 2)) * dir + .5) &&
                        fy != .5 &&
                        (fy = fy.toFixed(5) - 1e-5 * dir);
                }
                return E;
            });
            gradient = gradient.split(/\s*\-\s*/);
            if (type == "linear") {
                var angle = gradient.shift();
                angle = -toFloat(angle);
                if (isNaN(angle)) {
                    return null;
                }
                var vector = [0, 0, math.cos(R.rad(angle)), math.sin(R.rad(angle))],
                    max = 1 / (mmax(abs(vector[2]), abs(vector[3])) || 1);
                vector[2] *= max;
                vector[3] *= max;
                if (vector[2] < 0) {
                    vector[0] = -vector[2];
                    vector[2] = 0;
                }
                if (vector[3] < 0) {
                    vector[1] = -vector[3];
                    vector[3] = 0;
                }
            }
            var dots = R._parseDots(gradient);
            if (!dots) {
                return null;
            }
            id = id.replace(/[\(\)\s,\xb0#]/g, "_");
            
            if (element.gradient && id != element.gradient.id) {
                SVG.defs.removeChild(element.gradient);
                delete element.gradient;
            }

            if (!element.gradient) {
                el = $(type + "Gradient", {id: id});
                element.gradient = el;
                $(el, type == "radial" ? {
                    fx: fx,
                    fy: fy
                } : {
                    x1: vector[0],
                    y1: vector[1],
                    x2: vector[2],
                    y2: vector[3],
                    gradientTransform: element.matrix.invert()
                });
                SVG.defs.appendChild(el);
                for (var i = 0, ii = dots.length; i < ii; i++) {
                    el.appendChild($("stop", {
                        offset: dots[i].offset ? dots[i].offset : i ? "100%" : "0%",
                        "stop-color": dots[i].color || "#fff"
                    }));
                }
            }
        }
        $(o, {
            fill: "url(#" + id + ")",
            opacity: 1,
            "fill-opacity": 1
        });
        s.fill = E;
        s.opacity = 1;
        s.fillOpacity = 1;
        return 1;
    },
    updatePosition = function (o) {
        var bbox = o.getBBox(1);
        $(o.pattern, {patternTransform: o.matrix.invert() + " translate(" + bbox.x + "," + bbox.y + ")"});
    },
    addArrow = function (o, value, isEnd) {
        if (o.type == "path") {
            var values = Str(value).toLowerCase().split("-"),
                p = o.paper,
                se = isEnd ? "end" : "start",
                node = o.node,
                attrs = o.attrs,
                stroke = attrs["stroke-width"],
                i = values.length,
                type = "classic",
                from,
                to,
                dx,
                refX,
                attr,
                w = 3,
                h = 3,
                t = 5;
            while (i--) {
                switch (values[i]) {
                    case "block":
                    case "classic":
                    case "oval":
                    case "diamond":
                    case "open":
                    case "none":
                        type = values[i];
                        break;
                    case "wide": h = 5; break;
                    case "narrow": h = 2; break;
                    case "long": w = 5; break;
                    case "short": w = 2; break;
                }
            }
            if (type == "open") {
                w += 2;
                h += 2;
                t += 2;
                dx = 1;
                refX = isEnd ? 4 : 1;
                attr = {
                    fill: "none",
                    stroke: attrs.stroke
                };
            } else {
                refX = dx = w / 2;
                attr = {
                    fill: attrs.stroke,
                    stroke: "none"
                };
            }
            if (o._.arrows) {
                if (isEnd) {
                    o._.arrows.endPath && markerCounter[o._.arrows.endPath]--;
                    o._.arrows.endMarker && markerCounter[o._.arrows.endMarker]--;
                } else {
                    o._.arrows.startPath && markerCounter[o._.arrows.startPath]--;
                    o._.arrows.startMarker && markerCounter[o._.arrows.startMarker]--;
                }
            } else {
                o._.arrows = {};
            }
            if (type != "none") {
                var pathId = "raphael-marker-" + type,
                    markerId = "raphael-marker-" + se + type + w + h;
                if (!R._g.doc.getElementById(pathId)) {
                    p.defs.appendChild($($("path"), {
                        "stroke-linecap": "round",
                        d: markers[type],
                        id: pathId
                    }));
                    markerCounter[pathId] = 1;
                } else {
                    markerCounter[pathId]++;
                }
                var marker = R._g.doc.getElementById(markerId),
                    use;
                if (!marker) {
                    marker = $($("marker"), {
                        id: markerId,
                        markerHeight: h,
                        markerWidth: w,
                        orient: "auto",
                        refX: refX,
                        refY: h / 2
                    });
                    use = $($("use"), {
                        "xlink:href": "#" + pathId,
                        transform: (isEnd ? "rotate(180 " + w / 2 + " " + h / 2 + ") " : E) + "scale(" + w / t + "," + h / t + ")",
                        "stroke-width": (1 / ((w / t + h / t) / 2)).toFixed(4)
                    });
                    marker.appendChild(use);
                    p.defs.appendChild(marker);
                    markerCounter[markerId] = 1;
                } else {
                    markerCounter[markerId]++;
                    use = marker.getElementsByTagName("use")[0];
                }
                $(use, attr);
                var delta = dx * (type != "diamond" && type != "oval");
                if (isEnd) {
                    from = o._.arrows.startdx * stroke || 0;
                    to = R.getTotalLength(attrs.path) - delta * stroke;
                } else {
                    from = delta * stroke;
                    to = R.getTotalLength(attrs.path) - (o._.arrows.enddx * stroke || 0);
                }
                attr = {};
                attr["marker-" + se] = "url(#" + markerId + ")";
                if (to || from) {
                    attr.d = R.getSubpath(attrs.path, from, to);
                }
                $(node, attr);
                o._.arrows[se + "Path"] = pathId;
                o._.arrows[se + "Marker"] = markerId;
                o._.arrows[se + "dx"] = delta;
                o._.arrows[se + "Type"] = type;
                o._.arrows[se + "String"] = value;
            } else {
                if (isEnd) {
                    from = o._.arrows.startdx * stroke || 0;
                    to = R.getTotalLength(attrs.path) - from;
                } else {
                    from = 0;
                    to = R.getTotalLength(attrs.path) - (o._.arrows.enddx * stroke || 0);
                }
                o._.arrows[se + "Path"] && $(node, {d: R.getSubpath(attrs.path, from, to)});
                delete o._.arrows[se + "Path"];
                delete o._.arrows[se + "Marker"];
                delete o._.arrows[se + "dx"];
                delete o._.arrows[se + "Type"];
                delete o._.arrows[se + "String"];
            }
            for (attr in markerCounter) if (markerCounter[has](attr) && !markerCounter[attr]) {
                var item = R._g.doc.getElementById(attr);
                item && item.parentNode.removeChild(item);
            }
        }
    },
    dasharray = {
        "": [0],
        "none": [0],
        "-": [3, 1],
        ".": [1, 1],
        "-.": [3, 1, 1, 1],
        "-..": [3, 1, 1, 1, 1, 1],
        ". ": [1, 3],
        "- ": [4, 3],
        "--": [8, 3],
        "- .": [4, 3, 1, 3],
        "--.": [8, 3, 1, 3],
        "--..": [8, 3, 1, 3, 1, 3]
    },
    addDashes = function (o, value, params) {
        value = dasharray[Str(value).toLowerCase()];
        if (value) {
            var width = o.attrs["stroke-width"] || "1",
                butt = {round: width, square: width, butt: 0}[o.attrs["stroke-linecap"] || params["stroke-linecap"]] || 0,
                dashes = [],
                i = value.length;
            while (i--) {
                dashes[i] = value[i] * width + ((i % 2) ? 1 : -1) * butt;
            }
            $(o.node, {"stroke-dasharray": dashes.join(",")});
        }
    },
    setFillAndStroke = function (o, params) {
        var node = o.node,
            attrs = o.attrs,
            vis = node.style.visibility;
        node.style.visibility = "hidden";
        for (var att in params) {
            if (params[has](att)) {
                if (!R._availableAttrs[has](att)) {
                    continue;
                }
                var value = params[att];
                attrs[att] = value;
                switch (att) {
                    case "blur":
                        o.blur(value);
                        break;
                    case "href":
                    case "title":
                    case "target":
                        var pn = node.parentNode;
                        if (pn.tagName.toLowerCase() != "a") {
                            var hl = $("a");
                            pn.insertBefore(hl, node);
                            hl.appendChild(node);
                            pn = hl;
                        }
                        if (att == "target") {
                            pn.setAttributeNS(xlink, "show", value == "blank" ? "new" : value);
                        } else {
                            pn.setAttributeNS(xlink, att, value);
                        }
                        break;
                    case "cursor":
                        node.style.cursor = value;
                        break;
                    case "transform":
                        o.transform(value);
                        break;
                    case "arrow-start":
                        addArrow(o, value);
                        break;
                    case "arrow-end":
                        addArrow(o, value, 1);
                        break;
                    case "clip-rect":
                        var rect = Str(value).split(separator);
                        if (rect.length == 4) {
                            o.clip && o.clip.parentNode.parentNode.removeChild(o.clip.parentNode);
                            var el = $("clipPath"),
                                rc = $("rect");
                            el.id = R.createUUID();
                            $(rc, {
                                x: rect[0],
                                y: rect[1],
                                width: rect[2],
                                height: rect[3]
                            });
                            el.appendChild(rc);
                            o.paper.defs.appendChild(el);
                            $(node, {"clip-path": "url(#" + el.id + ")"});
                            o.clip = rc;
                        }
                        if (!value) {
                            var path = node.getAttribute("clip-path");
                            if (path) {
                                var clip = R._g.doc.getElementById(path.replace(/(^url\(#|\)$)/g, E));
                                clip && clip.parentNode.removeChild(clip);
                                $(node, {"clip-path": E});
                                delete o.clip;
                            }
                        }
                    break;
                    case "path":
                        if (o.type == "path") {
                            $(node, {d: value ? attrs.path = R._pathToAbsolute(value) : "M0,0"});
                            o._.dirty = 1;
                            if (o._.arrows) {
                                "startString" in o._.arrows && addArrow(o, o._.arrows.startString);
                                "endString" in o._.arrows && addArrow(o, o._.arrows.endString, 1);
                            }
                        }
                        break;
                    case "width":
                        node.setAttribute(att, value);
                        o._.dirty = 1;
                        if (attrs.fx) {
                            att = "x";
                            value = attrs.x;
                        } else {
                            break;
                        }
                    case "x":
                        if (attrs.fx) {
                            value = -attrs.x - (attrs.width || 0);
                        }
                    case "rx":
                        if (att == "rx" && o.type == "rect") {
                            break;
                        }
                    case "cx":
                        node.setAttribute(att, value);
                        o.pattern && updatePosition(o);
                        o._.dirty = 1;
                        break;
                    case "height":
                        node.setAttribute(att, value);
                        o._.dirty = 1;
                        if (attrs.fy) {
                            att = "y";
                            value = attrs.y;
                        } else {
                            break;
                        }
                    case "y":
                        if (attrs.fy) {
                            value = -attrs.y - (attrs.height || 0);
                        }
                    case "ry":
                        if (att == "ry" && o.type == "rect") {
                            break;
                        }
                    case "cy":
                        node.setAttribute(att, value);
                        o.pattern && updatePosition(o);
                        o._.dirty = 1;
                        break;
                    case "r":
                        if (o.type == "rect") {
                            $(node, {rx: value, ry: value});
                        } else {
                            node.setAttribute(att, value);
                        }
                        o._.dirty = 1;
                        break;
                    case "src":
                        if (o.type == "image") {
                            node.setAttributeNS(xlink, "href", value);
                        }
                        break;
                    case "stroke-width":
                        if (o._.sx != 1 || o._.sy != 1) {
                            value /= mmax(abs(o._.sx), abs(o._.sy)) || 1;
                        }
                        if (o.paper._vbSize) {
                            value *= o.paper._vbSize;
                        }
                        node.setAttribute(att, value);
                        if (attrs["stroke-dasharray"]) {
                            addDashes(o, attrs["stroke-dasharray"], params);
                        }
                        if (o._.arrows) {
                            "startString" in o._.arrows && addArrow(o, o._.arrows.startString);
                            "endString" in o._.arrows && addArrow(o, o._.arrows.endString, 1);
                        }
                        break;
                    case "stroke-dasharray":
                        addDashes(o, value, params);
                        break;
                    case "fill":
                        var isURL = Str(value).match(R._ISURL);
                        if (isURL) {
                            el = $("pattern");
                            var ig = $("image");
                            el.id = R.createUUID();
                            $(el, {x: 0, y: 0, patternUnits: "userSpaceOnUse", height: 1, width: 1});
                            $(ig, {x: 0, y: 0, "xlink:href": isURL[1]});
                            el.appendChild(ig);

                            (function (el) {
                                R._preload(isURL[1], function () {
                                    var w = this.offsetWidth,
                                        h = this.offsetHeight;
                                    $(el, {width: w, height: h});
                                    $(ig, {width: w, height: h});
                                    o.paper.safari();
                                });
                            })(el);
                            o.paper.defs.appendChild(el);
                            $(node, {fill: "url(#" + el.id + ")"});
                            o.pattern = el;
                            o.pattern && updatePosition(o);
                            break;
                        }
                        var clr = R.getRGB(value);
                        if (!clr.error) {
                            delete params.gradient;
                            delete attrs.gradient;
                            !R.is(attrs.opacity, "undefined") &&
                                R.is(params.opacity, "undefined") &&
                                $(node, {opacity: attrs.opacity});
                            !R.is(attrs["fill-opacity"], "undefined") &&
                                R.is(params["fill-opacity"], "undefined") &&
                                $(node, {"fill-opacity": attrs["fill-opacity"]});
                        } else if ((o.type == "circle" || o.type == "ellipse" || Str(value).charAt() != "r") && addGradientFill(o, value)) {
                            if ("opacity" in attrs || "fill-opacity" in attrs) {
                                var gradient = R._g.doc.getElementById(node.getAttribute("fill").replace(/^url\(#|\)$/g, E));
                                if (gradient) {
                                    var stops = gradient.getElementsByTagName("stop");
                                    $(stops[stops.length - 1], {"stop-opacity": ("opacity" in attrs ? attrs.opacity : 1) * ("fill-opacity" in attrs ? attrs["fill-opacity"] : 1)});
                                }
                            }
                            attrs.gradient = value;
                            attrs.fill = "none";
                            break;
                        }
                        clr[has]("opacity") && $(node, {"fill-opacity": clr.opacity > 1 ? clr.opacity / 100 : clr.opacity});
                    case "stroke":
                        clr = R.getRGB(value);
                        node.setAttribute(att, clr.hex);
                        att == "stroke" && clr[has]("opacity") && $(node, {"stroke-opacity": clr.opacity > 1 ? clr.opacity / 100 : clr.opacity});
                        if (att == "stroke" && o._.arrows) {
                            "startString" in o._.arrows && addArrow(o, o._.arrows.startString);
                            "endString" in o._.arrows && addArrow(o, o._.arrows.endString, 1);
                        }
                        break;
                    case "gradient":
                        (o.type == "circle" || o.type == "ellipse" || Str(value).charAt() != "r") && addGradientFill(o, value);
                        break;
                    case "opacity":
                        if (attrs.gradient && !attrs[has]("stroke-opacity")) {
                            $(node, {"stroke-opacity": value > 1 ? value / 100 : value});
                        }
                        // fall
                    case "fill-opacity":
                        if (attrs.gradient) {
                            gradient = R._g.doc.getElementById(node.getAttribute("fill").replace(/^url\(#|\)$/g, E));
                            if (gradient) {
                                stops = gradient.getElementsByTagName("stop");
                                $(stops[stops.length - 1], {"stop-opacity": value});
                            }
                            break;
                        }
                    default:
                        att == "font-size" && (value = toInt(value, 10) + "px");
                        var cssrule = att.replace(/(\-.)/g, function (w) {
                            return w.substring(1).toUpperCase();
                        });
                        node.style[cssrule] = value;
                        o._.dirty = 1;
                        node.setAttribute(att, value);
                        break;
                }
            }
        }

        tuneText(o, params);
        node.style.visibility = vis;
    },
    leading = 1.2,
    tuneText = function (el, params) {
        if (el.type != "text" || !(params[has]("text") || params[has]("font") || params[has]("font-size") || params[has]("x") || params[has]("y"))) {
            return;
        }
        var a = el.attrs,
            node = el.node,
            fontSize = node.firstChild ? toInt(R._g.doc.defaultView.getComputedStyle(node.firstChild, E).getPropertyValue("font-size"), 10) : 10;

        if (params[has]("text")) {
            a.text = params.text;
            while (node.firstChild) {
                node.removeChild(node.firstChild);
            }
            var texts = Str(params.text).split("\n"),
                tspans = [],
                tspan;
            for (var i = 0, ii = texts.length; i < ii; i++) {
                tspan = $("tspan");
                i && $(tspan, {dy: fontSize * leading, x: a.x});
                tspan.appendChild(R._g.doc.createTextNode(texts[i]));
                node.appendChild(tspan);
                tspans[i] = tspan;
            }
        } else {
            tspans = node.getElementsByTagName("tspan");
            for (i = 0, ii = tspans.length; i < ii; i++) if (i) {
                $(tspans[i], {dy: fontSize * leading, x: a.x});
            } else {
                $(tspans[0], {dy: 0});
            }
        }
        $(node, {x: a.x, y: a.y});
        el._.dirty = 1;
        var bb = el._getBBox(),
            dif = a.y - (bb.y + bb.height / 2);
        dif && R.is(dif, "finite") && $(tspans[0], {dy: dif});
    },
    Element = function (node, svg) {
        var X = 0,
            Y = 0;
        /*\
         * Element.node
         [ property (object) ]
         **
         * Gives you a reference to the DOM object, so you can assign event handlers or just mess around.
         **
         * Note: Donâ€™t mess with it.
         > Usage
         | // draw a circle at coordinate 10,10 with radius of 10
         | var c = paper.circle(10, 10, 10);
         | c.node.onclick = function () {
         |     c.attr("fill", "red");
         | };
        \*/
        this[0] = this.node = node;
        /*\
         * Element.raphael
         [ property (object) ]
         **
         * Internal reference to @Raphael object. In case it is not available.
         > Usage
         | Raphael.el.red = function () {
         |     var hsb = this.paper.raphael.rgb2hsb(this.attr("fill"));
         |     hsb.h = 1;
         |     this.attr({fill: this.paper.raphael.hsb2rgb(hsb).hex});
         | }
        \*/
        node.raphael = true;
        /*\
         * Element.id
         [ property (number) ]
         **
         * Unique id of the element. Especially usesful when you want to listen to events of the element, 
         * because all events are fired in format `<module>.<action>.<id>`. Also useful for @Paper.getById method.
        \*/
        this.id = R._oid++;
        node.raphaelid = this.id;
        this.matrix = R.matrix();
        this.realPath = null;
        /*\
         * Element.paper
         [ property (object) ]
         **
         * Internal reference to â€œpaperâ€ where object drawn. Mainly for use in plugins and element extensions.
         > Usage
         | Raphael.el.cross = function () {
         |     this.attr({fill: "red"});
         |     this.paper.path("M10,10L50,50M50,10L10,50")
         |         .attr({stroke: "red"});
         | }
        \*/
        this.paper = svg;
        this.attrs = this.attrs || {};
        this._ = {
            transform: [],
            sx: 1,
            sy: 1,
            deg: 0,
            dx: 0,
            dy: 0,
            dirty: 1
        };
        !svg.bottom && (svg.bottom = this);
        /*\
         * Element.prev
         [ property (object) ]
         **
         * Reference to the previous element in the hierarchy.
        \*/
        this.prev = svg.top;
        svg.top && (svg.top.next = this);
        svg.top = this;
        /*\
         * Element.next
         [ property (object) ]
         **
         * Reference to the next element in the hierarchy.
        \*/
        this.next = null;
    },
    elproto = R.el;

    Element.prototype = elproto;
    elproto.constructor = Element;

    R._engine.path = function (pathString, SVG) {
        var el = $("path");
        SVG.canvas && SVG.canvas.appendChild(el);
        var p = new Element(el, SVG);
        p.type = "path";
        setFillAndStroke(p, {
            fill: "none",
            stroke: "#000",
            path: pathString
        });
        return p;
    };
    /*\
     * Element.rotate
     [ method ]
     **
     * Deprecated! Use @Element.transform instead.
     * Adds rotation by given angle around given point to the list of
     * transformations of the element.
     > Parameters
     - deg (number) angle in degrees
     - cx (number) #optional x coordinate of the centre of rotation
     - cy (number) #optional y coordinate of the centre of rotation
     * If cx & cy arenâ€™t specified centre of the shape is used as a point of rotation.
     = (object) @Element
    \*/
    elproto.rotate = function (deg, cx, cy) {
        if (this.removed) {
            return this;
        }
        deg = Str(deg).split(separator);
        if (deg.length - 1) {
            cx = toFloat(deg[1]);
            cy = toFloat(deg[2]);
        }
        deg = toFloat(deg[0]);
        (cy == null) && (cx = cy);
        if (cx == null || cy == null) {
            var bbox = this.getBBox(1);
            cx = bbox.x + bbox.width / 2;
            cy = bbox.y + bbox.height / 2;
        }
        this.transform(this._.transform.concat([["r", deg, cx, cy]]));
        return this;
    };
    /*\
     * Element.scale
     [ method ]
     **
     * Deprecated! Use @Element.transform instead.
     * Adds scale by given amount relative to given point to the list of
     * transformations of the element.
     > Parameters
     - sx (number) horisontal scale amount
     - sy (number) vertical scale amount
     - cx (number) #optional x coordinate of the centre of scale
     - cy (number) #optional y coordinate of the centre of scale
     * If cx & cy arenâ€™t specified centre of the shape is used instead.
     = (object) @Element
    \*/
    elproto.scale = function (sx, sy, cx, cy) {
        if (this.removed) {
            return this;
        }
        sx = Str(sx).split(separator);
        if (sx.length - 1) {
            sy = toFloat(sx[1]);
            cx = toFloat(sx[2]);
            cy = toFloat(sx[3]);
        }
        sx = toFloat(sx[0]);
        (sy == null) && (sy = sx);
        (cy == null) && (cx = cy);
        if (cx == null || cy == null) {
            var bbox = this.getBBox(1);
        }
        cx = cx == null ? bbox.x + bbox.width / 2 : cx;
        cy = cy == null ? bbox.y + bbox.height / 2 : cy;
        this.transform(this._.transform.concat([["s", sx, sy, cx, cy]]));
        return this;
    };
    /*\
     * Element.translate
     [ method ]
     **
     * Deprecated! Use @Element.transform instead.
     * Adds translation by given amount to the list of transformations of the element.
     > Parameters
     - dx (number) horisontal shift
     - dy (number) vertical shift
     = (object) @Element
    \*/
    elproto.translate = function (dx, dy) {
        if (this.removed) {
            return this;
        }
        dx = Str(dx).split(separator);
        if (dx.length - 1) {
            dy = toFloat(dx[1]);
        }
        dx = toFloat(dx[0]) || 0;
        dy = +dy || 0;
        this.transform(this._.transform.concat([["t", dx, dy]]));
        return this;
    };
    /*\
     * Element.transform
     [ method ]
     **
     * Adds transformation to the element which is separate to other attributes,
     * i.e. translation doesnâ€™t change `x` or `y` of the rectange. The format
     * of transformation string is similar to the path string syntax:
     | "t100,100r30,100,100s2,2,100,100r45s1.5"
     * Each letter is a command. There are four commands: `t` is for translate, `r` is for rotate, `s` is for
     * scale and `m` is for matrix.
     *
     * There are also alternative â€œabsoluteâ€ translation, rotation and scale: `T`, `R` and `S`. They will not take previous transformation into account. For example, `...T100,0` will always move element 100 px horisontally, while `...t100,0` could move it vertically if there is `r90` before. Just compare results of `r90t100,0` and `r90T100,0`.
     *
     * So, the example line above could be read like â€œtranslate by 100, 100; rotate 30Â° around 100, 100; scale twice around 100, 100;
     * rotate 45Â° around centre; scale 1.5 times relative to centreâ€. As you can see rotate and scale commands have origin
     * coordinates as optional parameters, the default is the centre point of the element.
     * Matrix accepts six parameters.
     > Usage
     | var el = paper.rect(10, 20, 300, 200);
     | // translate 100, 100, rotate 45Â°, translate -100, 0
     | el.transform("t100,100r45t-100,0");
     | // if you want you can append or prepend transformations
     | el.transform("...t50,50");
     | el.transform("s2...");
     | // or even wrap
     | el.transform("t50,50...t-50-50");
     | // to reset transformation call method with empty string
     | el.transform("");
     | // to get current value call it without parameters
     | console.log(el.transform());
     > Parameters
     - tstr (string) #optional transformation string
     * If tstr isnâ€™t specified
     = (string) current transformation string
     * else
     = (object) @Element
    \*/
    elproto.transform = function (tstr) {
        var _ = this._;
        if (tstr == null) {
            return _.transform;
        }
        R._extractTransform(this, tstr);

        this.clip && $(this.clip, {transform: this.matrix.invert()});
        this.pattern && updatePosition(this);
        this.node && $(this.node, {transform: this.matrix});
    
        if (_.sx != 1 || _.sy != 1) {
            var sw = this.attrs[has]("stroke-width") ? this.attrs["stroke-width"] : 1;
            this.attr({"stroke-width": sw});
        }

        return this;
    };
    /*\
     * Element.hide
     [ method ]
     **
     * Makes element invisible. See @Element.show.
     = (object) @Element
    \*/
    elproto.hide = function () {
        !this.removed && this.paper.safari(this.node.style.display = "none");
        return this;
    };
    /*\
     * Element.show
     [ method ]
     **
     * Makes element visible. See @Element.hide.
     = (object) @Element
    \*/
    elproto.show = function () {
        !this.removed && this.paper.safari(this.node.style.display = "");
        return this;
    };
    /*\
     * Element.remove
     [ method ]
     **
     * Removes element from the paper.
    \*/
    elproto.remove = function () {
        if (this.removed || !this.node.parentNode) {
            return;
        }
        var paper = this.paper;
        paper.__set__ && paper.__set__.exclude(this);
        eve.unbind("raphael.*.*." + this.id);
        if (this.gradient) {
            paper.defs.removeChild(this.gradient);
        }
        R._tear(this, paper);
        if (this.node.parentNode.tagName.toLowerCase() == "a") {
            this.node.parentNode.parentNode.removeChild(this.node.parentNode);
        } else {
            this.node.parentNode.removeChild(this.node);
        }
        for (var i in this) {
            this[i] = typeof this[i] == "function" ? R._removedFactory(i) : null;
        }
        this.removed = true;
    };
    elproto._getBBox = function () {
        if (this.node.style.display == "none") {
            this.show();
            var hide = true;
        }
        var bbox = {};
        try {
            bbox = this.node.getBBox();
        } catch(e) {
            // Firefox 3.0.x plays badly here
        } finally {
            bbox = bbox || {};
        }
        hide && this.hide();
        return bbox;
    };
    /*\
     * Element.attr
     [ method ]
     **
     * Sets the attributes of the element.
     > Parameters
     - attrName (string) attributeâ€™s name
     - value (string) value
     * or
     - params (object) object of name/value pairs
     * or
     - attrName (string) attributeâ€™s name
     * or
     - attrNames (array) in this case method returns array of current values for given attribute names
     = (object) @Element if attrsName & value or params are passed in.
     = (...) value of the attribute if only attrsName is passed in.
     = (array) array of values of the attribute if attrsNames is passed in.
     = (object) object of attributes if nothing is passed in.
     > Possible parameters
     # <p>Please refer to the <a href="http://www.w3.org/TR/SVG/" title="The W3C Recommendation for the SVG language describes these properties in detail.">SVG specification</a> for an explanation of these parameters.</p>
     o arrow-end (string) arrowhead on the end of the path. The format for string is `<type>[-<width>[-<length>]]`. Possible types: `classic`, `block`, `open`, `oval`, `diamond`, `none`, width: `wide`, `narrow`, `medium`, length: `long`, `short`, `midium`.
     o clip-rect (string) comma or space separated values: x, y, width and height
     o cursor (string) CSS type of the cursor
     o cx (number) the x-axis coordinate of the center of the circle, or ellipse
     o cy (number) the y-axis coordinate of the center of the circle, or ellipse
     o fill (string) colour, gradient or image
     o fill-opacity (number)
     o font (string)
     o font-family (string)
     o font-size (number) font size in pixels
     o font-weight (string)
     o height (number)
     o href (string) URL, if specified element behaves as hyperlink
     o opacity (number)
     o path (string) SVG path string format
     o r (number) radius of the circle, ellipse or rounded corner on the rect
     o rx (number) horisontal radius of the ellipse
     o ry (number) vertical radius of the ellipse
     o src (string) image URL, only works for @Element.image element
     o stroke (string) stroke colour
     o stroke-dasharray (string) [â€œâ€, â€œ`-`â€, â€œ`.`â€, â€œ`-.`â€, â€œ`-..`â€, â€œ`. `â€, â€œ`- `â€, â€œ`--`â€, â€œ`- .`â€, â€œ`--.`â€, â€œ`--..`â€]
     o stroke-linecap (string) [â€œ`butt`â€, â€œ`square`â€, â€œ`round`â€]
     o stroke-linejoin (string) [â€œ`bevel`â€, â€œ`round`â€, â€œ`miter`â€]
     o stroke-miterlimit (number)
     o stroke-opacity (number)
     o stroke-width (number) stroke width in pixels, default is '1'
     o target (string) used with href
     o text (string) contents of the text element. Use `\n` for multiline text
     o text-anchor (string) [â€œ`start`â€, â€œ`middle`â€, â€œ`end`â€], default is â€œ`middle`â€
     o title (string) will create tooltip with a given text
     o transform (string) see @Element.transform
     o width (number)
     o x (number)
     o y (number)
     > Gradients
     * Linear gradient format: â€œ`â€¹angleâ€º-â€¹colourâ€º[-â€¹colourâ€º[:â€¹offsetâ€º]]*-â€¹colourâ€º`â€, example: â€œ`90-#fff-#000`â€ â€“ 90Â°
     * gradient from white to black or â€œ`0-#fff-#f00:20-#000`â€ â€“ 0Â° gradient from white via red (at 20%) to black.
     *
     * radial gradient: â€œ`r[(â€¹fxâ€º, â€¹fyâ€º)]â€¹colourâ€º[-â€¹colourâ€º[:â€¹offsetâ€º]]*-â€¹colourâ€º`â€, example: â€œ`r#fff-#000`â€ â€“
     * gradient from white to black or â€œ`r(0.25, 0.75)#fff-#000`â€ â€“ gradient from white to black with focus point
     * at 0.25, 0.75. Focus point coordinates are in 0..1 range. Radial gradients can only be applied to circles and ellipses.
     > Path String
     # <p>Please refer to <a href="http://www.w3.org/TR/SVG/paths.html#PathData" title="Details of a pathâ€™s data attributeâ€™s format are described in the SVG specification.">SVG documentation regarding path string</a>. RaphaÃ«l fully supports it.</p>
     > Colour Parsing
     # <ul>
     #     <li>Colour name (â€œ<code>red</code>â€, â€œ<code>green</code>â€, â€œ<code>cornflowerblue</code>â€, etc)</li>
     #     <li>#â€¢â€¢â€¢ â€” shortened HTML colour: (â€œ<code>#000</code>â€, â€œ<code>#fc0</code>â€, etc)</li>
     #     <li>#â€¢â€¢â€¢â€¢â€¢â€¢ â€” full length HTML colour: (â€œ<code>#000000</code>â€, â€œ<code>#bd2300</code>â€)</li>
     #     <li>rgb(â€¢â€¢â€¢, â€¢â€¢â€¢, â€¢â€¢â€¢) â€” red, green and blue channelsâ€™ values: (â€œ<code>rgb(200,&nbsp;100,&nbsp;0)</code>â€)</li>
     #     <li>rgb(â€¢â€¢â€¢%, â€¢â€¢â€¢%, â€¢â€¢â€¢%) â€” same as above, but in %: (â€œ<code>rgb(100%,&nbsp;175%,&nbsp;0%)</code>â€)</li>
     #     <li>rgba(â€¢â€¢â€¢, â€¢â€¢â€¢, â€¢â€¢â€¢, â€¢â€¢â€¢) â€” red, green and blue channelsâ€™ values: (â€œ<code>rgba(200,&nbsp;100,&nbsp;0, .5)</code>â€)</li>
     #     <li>rgba(â€¢â€¢â€¢%, â€¢â€¢â€¢%, â€¢â€¢â€¢%, â€¢â€¢â€¢%) â€” same as above, but in %: (â€œ<code>rgba(100%,&nbsp;175%,&nbsp;0%, 50%)</code>â€)</li>
     #     <li>hsb(â€¢â€¢â€¢, â€¢â€¢â€¢, â€¢â€¢â€¢) â€” hue, saturation and brightness values: (â€œ<code>hsb(0.5,&nbsp;0.25,&nbsp;1)</code>â€)</li>
     #     <li>hsb(â€¢â€¢â€¢%, â€¢â€¢â€¢%, â€¢â€¢â€¢%) â€” same as above, but in %</li>
     #     <li>hsba(â€¢â€¢â€¢, â€¢â€¢â€¢, â€¢â€¢â€¢, â€¢â€¢â€¢) â€” same as above, but with opacity</li>
     #     <li>hsl(â€¢â€¢â€¢, â€¢â€¢â€¢, â€¢â€¢â€¢) â€” almost the same as hsb, see <a href="http://en.wikipedia.org/wiki/HSL_and_HSV" title="HSL and HSV - Wikipedia, the free encyclopedia">Wikipedia page</a></li>
     #     <li>hsl(â€¢â€¢â€¢%, â€¢â€¢â€¢%, â€¢â€¢â€¢%) â€” same as above, but in %</li>
     #     <li>hsla(â€¢â€¢â€¢, â€¢â€¢â€¢, â€¢â€¢â€¢, â€¢â€¢â€¢) â€” same as above, but with opacity</li>
     #     <li>Optionally for hsb and hsl you could specify hue as a degree: â€œ<code>hsl(240deg,&nbsp;1,&nbsp;.5)</code>â€ or, if you want to go fancy, â€œ<code>hsl(240Â°,&nbsp;1,&nbsp;.5)</code>â€</li>
     # </ul>
    \*/
    elproto.attr = function (name, value) {
        if (this.removed) {
            return this;
        }
        if (name == null) {
            var res = {};
            for (var a in this.attrs) if (this.attrs[has](a)) {
                res[a] = this.attrs[a];
            }
            res.gradient && res.fill == "none" && (res.fill = res.gradient) && delete res.gradient;
            res.transform = this._.transform;
            return res;
        }
        if (value == null && R.is(name, "string")) {
            if (name == "fill" && this.attrs.fill == "none" && this.attrs.gradient) {
                return this.attrs.gradient;
            }
            if (name == "transform") {
                return this._.transform;
            }
            var names = name.split(separator),
                out = {};
            for (var i = 0, ii = names.length; i < ii; i++) {
                name = names[i];
                if (name in this.attrs) {
                    out[name] = this.attrs[name];
                } else if (R.is(this.paper.customAttributes[name], "function")) {
                    out[name] = this.paper.customAttributes[name].def;
                } else {
                    out[name] = R._availableAttrs[name];
                }
            }
            return ii - 1 ? out : out[names[0]];
        }
        if (value == null && R.is(name, "array")) {
            out = {};
            for (i = 0, ii = name.length; i < ii; i++) {
                out[name[i]] = this.attr(name[i]);
            }
            return out;
        }
        if (value != null) {
            var params = {};
            params[name] = value;
        } else if (name != null && R.is(name, "object")) {
            params = name;
        }
        for (var key in params) {
            eve("raphael.attr." + key + "." + this.id, this, params[key]);
        }
        for (key in this.paper.customAttributes) if (this.paper.customAttributes[has](key) && params[has](key) && R.is(this.paper.customAttributes[key], "function")) {
            var par = this.paper.customAttributes[key].apply(this, [].concat(params[key]));
            this.attrs[key] = params[key];
            for (var subkey in par) if (par[has](subkey)) {
                params[subkey] = par[subkey];
            }
        }
        setFillAndStroke(this, params);
        return this;
    };
    /*\
     * Element.toFront
     [ method ]
     **
     * Moves the element so it is the closest to the viewerâ€™s eyes, on top of other elements.
     = (object) @Element
    \*/
    elproto.toFront = function () {
        if (this.removed) {
            return this;
        }
        if (this.node.parentNode.tagName.toLowerCase() == "a") {
            this.node.parentNode.parentNode.appendChild(this.node.parentNode);
        } else {
            this.node.parentNode.appendChild(this.node);
        }
        var svg = this.paper;
        svg.top != this && R._tofront(this, svg);
        return this;
    };
    /*\
     * Element.toBack
     [ method ]
     **
     * Moves the element so it is the furthest from the viewerâ€™s eyes, behind other elements.
     = (object) @Element
    \*/
    elproto.toBack = function () {
        if (this.removed) {
            return this;
        }
        var parent = this.node.parentNode;
        if (parent.tagName.toLowerCase() == "a") {
            parent.parentNode.insertBefore(this.node.parentNode, this.node.parentNode.parentNode.firstChild); 
        } else if (parent.firstChild != this.node) {
            parent.insertBefore(this.node, this.node.parentNode.firstChild);
        }
        R._toback(this, this.paper);
        var svg = this.paper;
        return this;
    };
    /*\
     * Element.insertAfter
     [ method ]
     **
     * Inserts current object after the given one.
     = (object) @Element
    \*/
    elproto.insertAfter = function (element) {
        if (this.removed) {
            return this;
        }
        var node = element.node || element[element.length - 1].node;
        if (node.nextSibling) {
            node.parentNode.insertBefore(this.node, node.nextSibling);
        } else {
            node.parentNode.appendChild(this.node);
        }
        R._insertafter(this, element, this.paper);
        return this;
    };
    /*\
     * Element.insertBefore
     [ method ]
     **
     * Inserts current object before the given one.
     = (object) @Element
    \*/
    elproto.insertBefore = function (element) {
        if (this.removed) {
            return this;
        }
        var node = element.node || element[0].node;
        node.parentNode.insertBefore(this.node, node);
        R._insertbefore(this, element, this.paper);
        return this;
    };
    elproto.blur = function (size) {
        // Experimental. No Safari support. Use it on your own risk.
        var t = this;
        if (+size !== 0) {
            var fltr = $("filter"),
                blur = $("feGaussianBlur");
            t.attrs.blur = size;
            fltr.id = R.createUUID();
            $(blur, {stdDeviation: +size || 1.5});
            fltr.appendChild(blur);
            t.paper.defs.appendChild(fltr);
            t._blur = fltr;
            $(t.node, {filter: "url(#" + fltr.id + ")"});
        } else {
            if (t._blur) {
                t._blur.parentNode.removeChild(t._blur);
                delete t._blur;
                delete t.attrs.blur;
            }
            t.node.removeAttribute("filter");
        }
    };
    R._engine.circle = function (svg, x, y, r) {
        var el = $("circle");
        svg.canvas && svg.canvas.appendChild(el);
        var res = new Element(el, svg);
        res.attrs = {cx: x, cy: y, r: r, fill: "none", stroke: "#000"};
        res.type = "circle";
        $(el, res.attrs);
        return res;
    };
    R._engine.rect = function (svg, x, y, w, h, r) {
        var el = $("rect");
        svg.canvas && svg.canvas.appendChild(el);
        var res = new Element(el, svg);
        res.attrs = {x: x, y: y, width: w, height: h, r: r || 0, rx: r || 0, ry: r || 0, fill: "none", stroke: "#000"};
        res.type = "rect";
        $(el, res.attrs);
        return res;
    };
    R._engine.ellipse = function (svg, x, y, rx, ry) {
        var el = $("ellipse");
        svg.canvas && svg.canvas.appendChild(el);
        var res = new Element(el, svg);
        res.attrs = {cx: x, cy: y, rx: rx, ry: ry, fill: "none", stroke: "#000"};
        res.type = "ellipse";
        $(el, res.attrs);
        return res;
    };
    R._engine.image = function (svg, src, x, y, w, h) {
        var el = $("image");
        $(el, {x: x, y: y, width: w, height: h, preserveAspectRatio: "none"});
        el.setAttributeNS(xlink, "href", src);
        svg.canvas && svg.canvas.appendChild(el);
        var res = new Element(el, svg);
        res.attrs = {x: x, y: y, width: w, height: h, src: src};
        res.type = "image";
        return res;
    };
    R._engine.text = function (svg, x, y, text) {
        var el = $("text");
        svg.canvas && svg.canvas.appendChild(el);
        var res = new Element(el, svg);
        res.attrs = {
            x: x,
            y: y,
            "text-anchor": "middle",
            text: text,
            font: R._availableAttrs.font,
            stroke: "none",
            fill: "#000"
        };
        res.type = "text";
        setFillAndStroke(res, res.attrs);
        return res;
    };
    R._engine.setSize = function (width, height) {
        this.width = width || this.width;
        this.height = height || this.height;
        this.canvas.setAttribute("width", this.width);
        this.canvas.setAttribute("height", this.height);
        if (this._viewBox) {
            this.setViewBox.apply(this, this._viewBox);
        }
        return this;
    };
    R._engine.create = function () {
        var con = R._getContainer.apply(0, arguments),
            container = con && con.container,
            x = con.x,
            y = con.y,
            width = con.width,
            height = con.height;
        if (!container) {
            throw new Error("SVG container not found.");
        }
        var cnvs = $("svg"),
            css = "overflow:hidden;",
            isFloating;
        x = x || 0;
        y = y || 0;
        width = width || 512;
        height = height || 342;
        $(cnvs, {
            height: height,
            version: 1.1,
            width: width,
            xmlns: "http://www.w3.org/2000/svg"
        });
        if (container == 1) {
            cnvs.style.cssText = css + "position:absolute;left:" + x + "px;top:" + y + "px";
            R._g.doc.body.appendChild(cnvs);
            isFloating = 1;
        } else {
            cnvs.style.cssText = css + "position:relative";
            if (container.firstChild) {
                container.insertBefore(cnvs, container.firstChild);
            } else {
                container.appendChild(cnvs);
            }
        }
        container = new R._Paper;
        container.width = width;
        container.height = height;
        container.canvas = cnvs;
        container.clear();
        container._left = container._top = 0;
        isFloating && (container.renderfix = function () {});
        container.renderfix();
        return container;
    };
    R._engine.setViewBox = function (x, y, w, h, fit) {
        eve("raphael.setViewBox", this, this._viewBox, [x, y, w, h, fit]);
        var size = mmax(w / this.width, h / this.height),
            top = this.top,
            aspectRatio = fit ? "meet" : "xMinYMin",
            vb,
            sw;
        if (x == null) {
            if (this._vbSize) {
                size = 1;
            }
            delete this._vbSize;
            vb = "0 0 " + this.width + S + this.height;
        } else {
            this._vbSize = size;
            vb = x + S + y + S + w + S + h;
        }
        $(this.canvas, {
            viewBox: vb,
            preserveAspectRatio: aspectRatio
        });
        while (size && top) {
            sw = "stroke-width" in top.attrs ? top.attrs["stroke-width"] : 1;
            top.attr({"stroke-width": sw});
            top._.dirty = 1;
            top._.dirtyT = 1;
            top = top.prev;
        }
        this._viewBox = [x, y, w, h, !!fit];
        return this;
    };
    /*\
     * Paper.renderfix
     [ method ]
     **
     * Fixes the issue of Firefox and IE9 regarding subpixel rendering. If paper is dependant
     * on other elements after reflow it could shift half pixel which cause for lines to lost their crispness.
     * This method fixes the issue.
     **
       Special thanks to Mariusz Nowak (http://www.medikoo.com/) for this method.
    \*/
    R.prototype.renderfix = function () {
        var cnvs = this.canvas,
            s = cnvs.style,
            pos;
        try {
            pos = cnvs.getScreenCTM() || cnvs.createSVGMatrix();
        } catch (e) {
            pos = cnvs.createSVGMatrix();
        }
        var left = -pos.e % 1,
            top = -pos.f % 1;
        if (left || top) {
            if (left) {
                this._left = (this._left + left) % 1;
                s.left = this._left + "px";
            }
            if (top) {
                this._top = (this._top + top) % 1;
                s.top = this._top + "px";
            }
        }
    };
    /*\
     * Paper.clear
     [ method ]
     **
     * Clears the paper, i.e. removes all the elements.
    \*/
    R.prototype.clear = function () {
        R.eve("raphael.clear", this);
        var c = this.canvas;
        while (c.firstChild) {
            c.removeChild(c.firstChild);
        }
        this.bottom = this.top = null;
        (this.desc = $("desc")).appendChild(R._g.doc.createTextNode("Created with Rapha\xebl " + R.version));
        c.appendChild(this.desc);
        c.appendChild(this.defs = $("defs"));
    };
    /*\
     * Paper.remove
     [ method ]
     **
     * Removes the paper from the DOM.
    \*/
    R.prototype.remove = function () {
        eve("raphael.remove", this);
        this.canvas.parentNode && this.canvas.parentNode.removeChild(this.canvas);
        for (var i in this) {
            this[i] = typeof this[i] == "function" ? R._removedFactory(i) : null;
        }
    };
    var setproto = R.st;
    for (var method in elproto) if (elproto[has](method) && !setproto[has](method)) {
        setproto[method] = (function (methodname) {
            return function () {
                var arg = arguments;
                return this.forEach(function (el) {
                    el[methodname].apply(el, arg);
                });
            };
        })(method);
    }
})();

// â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â” \\
// â”‚ RaphaÃ«l - JavaScript Vector Library                                 â”‚ \\
// â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¤ \\
// â”‚ VML Module                                                          â”‚ \\
// â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¤ \\
// â”‚ Copyright (c) 2008-2011 Dmitry Baranovskiy (http://raphaeljs.com)   â”‚ \\
// â”‚ Copyright (c) 2008-2011 Sencha Labs (http://sencha.com)             â”‚ \\
// â”‚ Licensed under the MIT (http://raphaeljs.com/license.html) license. â”‚ \\
// â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜ \\

(function(){
    if (!R.vml) {
        return;
    }
    var has = "hasOwnProperty",
        Str = String,
        toFloat = parseFloat,
        math = Math,
        round = math.round,
        mmax = math.max,
        mmin = math.min,
        abs = math.abs,
        fillString = "fill",
        separator = /[, ]+/,
        eve = R.eve,
        ms = " progid:DXImageTransform.Microsoft",
        S = " ",
        E = "",
        map = {M: "m", L: "l", C: "c", Z: "x", m: "t", l: "r", c: "v", z: "x"},
        bites = /([clmz]),?([^clmz]*)/gi,
        blurregexp = / progid:\S+Blur\([^\)]+\)/g,
        val = /-?[^,\s-]+/g,
        cssDot = "position:absolute;left:0;top:0;width:1px;height:1px",
        zoom = 21600,
        pathTypes = {path: 1, rect: 1, image: 1},
        ovalTypes = {circle: 1, ellipse: 1},
        path2vml = function (path) {
            var total =  /[ahqstv]/ig,
                command = R._pathToAbsolute;
            Str(path).match(total) && (command = R._path2curve);
            total = /[clmz]/g;
            if (command == R._pathToAbsolute && !Str(path).match(total)) {
                var res = Str(path).replace(bites, function (all, command, args) {
                    var vals = [],
                        isMove = command.toLowerCase() == "m",
                        res = map[command];
                    args.replace(val, function (value) {
                        if (isMove && vals.length == 2) {
                            res += vals + map[command == "m" ? "l" : "L"];
                            vals = [];
                        }
                        vals.push(round(value * zoom));
                    });
                    return res + vals;
                });
                return res;
            }
            var pa = command(path), p, r;
            res = [];
            for (var i = 0, ii = pa.length; i < ii; i++) {
                p = pa[i];
                r = pa[i][0].toLowerCase();
                r == "z" && (r = "x");
                for (var j = 1, jj = p.length; j < jj; j++) {
                    r += round(p[j] * zoom) + (j != jj - 1 ? "," : E);
                }
                res.push(r);
            }
            return res.join(S);
        },
        compensation = function (deg, dx, dy) {
            var m = R.matrix();
            m.rotate(-deg, .5, .5);
            return {
                dx: m.x(dx, dy),
                dy: m.y(dx, dy)
            };
        },
        setCoords = function (p, sx, sy, dx, dy, deg) {
            var _ = p._,
                m = p.matrix,
                fillpos = _.fillpos,
                o = p.node,
                s = o.style,
                y = 1,
                flip = "",
                dxdy,
                kx = zoom / sx,
                ky = zoom / sy;
            s.visibility = "hidden";
            if (!sx || !sy) {
                return;
            }
            o.coordsize = abs(kx) + S + abs(ky);
            s.rotation = deg * (sx * sy < 0 ? -1 : 1);
            if (deg) {
                var c = compensation(deg, dx, dy);
                dx = c.dx;
                dy = c.dy;
            }
            sx < 0 && (flip += "x");
            sy < 0 && (flip += " y") && (y = -1);
            s.flip = flip;
            o.coordorigin = (dx * -kx) + S + (dy * -ky);
            if (fillpos || _.fillsize) {
                var fill = o.getElementsByTagName(fillString);
                fill = fill && fill[0];
                o.removeChild(fill);
                if (fillpos) {
                    c = compensation(deg, m.x(fillpos[0], fillpos[1]), m.y(fillpos[0], fillpos[1]));
                    fill.position = c.dx * y + S + c.dy * y;
                }
                if (_.fillsize) {
                    fill.size = _.fillsize[0] * abs(sx) + S + _.fillsize[1] * abs(sy);
                }
                o.appendChild(fill);
            }
            s.visibility = "visible";
        };
    R.toString = function () {
        return  "Your browser doesn\u2019t support SVG. Falling down to VML.\nYou are running Rapha\xebl " + this.version;
    };
    var addArrow = function (o, value, isEnd) {
        var values = Str(value).toLowerCase().split("-"),
            se = isEnd ? "end" : "start",
            i = values.length,
            type = "classic",
            w = "medium",
            h = "medium";
        while (i--) {
            switch (values[i]) {
                case "block":
                case "classic":
                case "oval":
                case "diamond":
                case "open":
                case "none":
                    type = values[i];
                    break;
                case "wide":
                case "narrow": h = values[i]; break;
                case "long":
                case "short": w = values[i]; break;
            }
        }
        var stroke = o.node.getElementsByTagName("stroke")[0];
        stroke[se + "arrow"] = type;
        stroke[se + "arrowlength"] = w;
        stroke[se + "arrowwidth"] = h;
    },
    setFillAndStroke = function (o, params) {
        // o.paper.canvas.style.display = "none";
        o.attrs = o.attrs || {};
        var node = o.node,
            a = o.attrs,
            s = node.style,
            xy,
            newpath = pathTypes[o.type] && (params.x != a.x || params.y != a.y || params.width != a.width || params.height != a.height || params.cx != a.cx || params.cy != a.cy || params.rx != a.rx || params.ry != a.ry || params.r != a.r),
            isOval = ovalTypes[o.type] && (a.cx != params.cx || a.cy != params.cy || a.r != params.r || a.rx != params.rx || a.ry != params.ry),
            res = o;


        for (var par in params) if (params[has](par)) {
            a[par] = params[par];
        }
        if (newpath) {
            a.path = R._getPath[o.type](o);
            o._.dirty = 1;
        }
        params.href && (node.href = params.href);
        params.title && (node.title = params.title);
        params.target && (node.target = params.target);
        params.cursor && (s.cursor = params.cursor);
        "blur" in params && o.blur(params.blur);
        if (params.path && o.type == "path" || newpath) {
            node.path = path2vml(~Str(a.path).toLowerCase().indexOf("r") ? R._pathToAbsolute(a.path) : a.path);
            if (o.type == "image") {
                o._.fillpos = [a.x, a.y];
                o._.fillsize = [a.width, a.height];
                setCoords(o, 1, 1, 0, 0, 0);
            }
        }
        "transform" in params && o.transform(params.transform);
        if (isOval) {
            var cx = +a.cx,
                cy = +a.cy,
                rx = +a.rx || +a.r || 0,
                ry = +a.ry || +a.r || 0;
            node.path = R.format("ar{0},{1},{2},{3},{4},{1},{4},{1}x", round((cx - rx) * zoom), round((cy - ry) * zoom), round((cx + rx) * zoom), round((cy + ry) * zoom), round(cx * zoom));
        }
        if ("clip-rect" in params) {
            var rect = Str(params["clip-rect"]).split(separator);
            if (rect.length == 4) {
                rect[2] = +rect[2] + (+rect[0]);
                rect[3] = +rect[3] + (+rect[1]);
                var div = node.clipRect || R._g.doc.createElement("div"),
                    dstyle = div.style;
                dstyle.clip = R.format("rect({1}px {2}px {3}px {0}px)", rect);
                if (!node.clipRect) {
                    dstyle.position = "absolute";
                    dstyle.top = 0;
                    dstyle.left = 0;
                    dstyle.width = o.paper.width + "px";
                    dstyle.height = o.paper.height + "px";
                    node.parentNode.insertBefore(div, node);
                    div.appendChild(node);
                    node.clipRect = div;
                }
            }
            if (!params["clip-rect"]) {
                node.clipRect && (node.clipRect.style.clip = "auto");
            }
        }
        if (o.textpath) {
            var textpathStyle = o.textpath.style;
            params.font && (textpathStyle.font = params.font);
            params["font-family"] && (textpathStyle.fontFamily = '"' + params["font-family"].split(",")[0].replace(/^['"]+|['"]+$/g, E) + '"');
            params["font-size"] && (textpathStyle.fontSize = params["font-size"]);
            params["font-weight"] && (textpathStyle.fontWeight = params["font-weight"]);
            params["font-style"] && (textpathStyle.fontStyle = params["font-style"]);
        }
        if ("arrow-start" in params) {
            addArrow(res, params["arrow-start"]);
        }
        if ("arrow-end" in params) {
            addArrow(res, params["arrow-end"], 1);
        }
        if (params.opacity != null || 
            params["stroke-width"] != null ||
            params.fill != null ||
            params.src != null ||
            params.stroke != null ||
            params["stroke-width"] != null ||
            params["stroke-opacity"] != null ||
            params["fill-opacity"] != null ||
            params["stroke-dasharray"] != null ||
            params["stroke-miterlimit"] != null ||
            params["stroke-linejoin"] != null ||
            params["stroke-linecap"] != null) {
            var fill = node.getElementsByTagName(fillString),
                newfill = false;
            fill = fill && fill[0];
            !fill && (newfill = fill = createNode(fillString));
            if (o.type == "image" && params.src) {
                fill.src = params.src;
            }
            params.fill && (fill.on = true);
            if (fill.on == null || params.fill == "none" || params.fill === null) {
                fill.on = false;
            }
            if (fill.on && params.fill) {
                var isURL = Str(params.fill).match(R._ISURL);
                if (isURL) {
                    fill.parentNode == node && node.removeChild(fill);
                    fill.rotate = true;
                    fill.src = isURL[1];
                    fill.type = "tile";
                    var bbox = o.getBBox(1);
                    fill.position = bbox.x + S + bbox.y;
                    o._.fillpos = [bbox.x, bbox.y];

                    R._preload(isURL[1], function () {
                        o._.fillsize = [this.offsetWidth, this.offsetHeight];
                    });
                } else {
                    fill.color = R.getRGB(params.fill).hex;
                    fill.src = E;
                    fill.type = "solid";
                    if (R.getRGB(params.fill).error && (res.type in {circle: 1, ellipse: 1} || Str(params.fill).charAt() != "r") && addGradientFill(res, params.fill, fill)) {
                        a.fill = "none";
                        a.gradient = params.fill;
                        fill.rotate = false;
                    }
                }
            }
            if ("fill-opacity" in params || "opacity" in params) {
                var opacity = ((+a["fill-opacity"] + 1 || 2) - 1) * ((+a.opacity + 1 || 2) - 1) * ((+R.getRGB(params.fill).o + 1 || 2) - 1);
                opacity = mmin(mmax(opacity, 0), 1);
                fill.opacity = opacity;
                if (fill.src) {
                    fill.color = "none";
                }
            }
            node.appendChild(fill);
            var stroke = (node.getElementsByTagName("stroke") && node.getElementsByTagName("stroke")[0]),
            newstroke = false;
            !stroke && (newstroke = stroke = createNode("stroke"));
            if ((params.stroke && params.stroke != "none") ||
                params["stroke-width"] ||
                params["stroke-opacity"] != null ||
                params["stroke-dasharray"] ||
                params["stroke-miterlimit"] ||
                params["stroke-linejoin"] ||
                params["stroke-linecap"]) {
                stroke.on = true;
            }
            (params.stroke == "none" || params.stroke === null || stroke.on == null || params.stroke == 0 || params["stroke-width"] == 0) && (stroke.on = false);
            var strokeColor = R.getRGB(params.stroke);
            stroke.on && params.stroke && (stroke.color = strokeColor.hex);
            opacity = ((+a["stroke-opacity"] + 1 || 2) - 1) * ((+a.opacity + 1 || 2) - 1) * ((+strokeColor.o + 1 || 2) - 1);
            var width = (toFloat(params["stroke-width"]) || 1) * .75;
            opacity = mmin(mmax(opacity, 0), 1);
            params["stroke-width"] == null && (width = a["stroke-width"]);
            params["stroke-width"] && (stroke.weight = width);
            width && width < 1 && (opacity *= width) && (stroke.weight = 1);
            stroke.opacity = opacity;
        
            params["stroke-linejoin"] && (stroke.joinstyle = params["stroke-linejoin"] || "miter");
            stroke.miterlimit = params["stroke-miterlimit"] || 8;
            params["stroke-linecap"] && (stroke.endcap = params["stroke-linecap"] == "butt" ? "flat" : params["stroke-linecap"] == "square" ? "square" : "round");
            if (params["stroke-dasharray"]) {
                var dasharray = {
                    "-": "shortdash",
                    ".": "shortdot",
                    "-.": "shortdashdot",
                    "-..": "shortdashdotdot",
                    ". ": "dot",
                    "- ": "dash",
                    "--": "longdash",
                    "- .": "dashdot",
                    "--.": "longdashdot",
                    "--..": "longdashdotdot"
                };
                stroke.dashstyle = dasharray[has](params["stroke-dasharray"]) ? dasharray[params["stroke-dasharray"]] : E;
            }
            newstroke && node.appendChild(stroke);
        }
        if (res.type == "text") {
            res.paper.canvas.style.display = E;
            var span = res.paper.span,
                m = 100,
                fontSize = a.font && a.font.match(/\d+(?:\.\d*)?(?=px)/);
            s = span.style;
            a.font && (s.font = a.font);
            a["font-family"] && (s.fontFamily = a["font-family"]);
            a["font-weight"] && (s.fontWeight = a["font-weight"]);
            a["font-style"] && (s.fontStyle = a["font-style"]);
            fontSize = toFloat(a["font-size"] || fontSize && fontSize[0]) || 10;
            s.fontSize = fontSize * m + "px";
            res.textpath.string && (span.innerHTML = Str(res.textpath.string).replace(/</g, "&#60;").replace(/&/g, "&#38;").replace(/\n/g, "<br>"));
            var brect = span.getBoundingClientRect();
            res.W = a.w = (brect.right - brect.left) / m;
            res.H = a.h = (brect.bottom - brect.top) / m;
            // res.paper.canvas.style.display = "none";
            res.X = a.x;
            res.Y = a.y + res.H / 2;

            ("x" in params || "y" in params) && (res.path.v = R.format("m{0},{1}l{2},{1}", round(a.x * zoom), round(a.y * zoom), round(a.x * zoom) + 1));
            var dirtyattrs = ["x", "y", "text", "font", "font-family", "font-weight", "font-style", "font-size"];
            for (var d = 0, dd = dirtyattrs.length; d < dd; d++) if (dirtyattrs[d] in params) {
                res._.dirty = 1;
                break;
            }
        
            // text-anchor emulation
            switch (a["text-anchor"]) {
                case "start":
                    res.textpath.style["v-text-align"] = "left";
                    res.bbx = res.W / 2;
                break;
                case "end":
                    res.textpath.style["v-text-align"] = "right";
                    res.bbx = -res.W / 2;
                break;
                default:
                    res.textpath.style["v-text-align"] = "center";
                    res.bbx = 0;
                break;
            }
            res.textpath.style["v-text-kern"] = true;
        }
        // res.paper.canvas.style.display = E;
    },
    addGradientFill = function (o, gradient, fill) {
        o.attrs = o.attrs || {};
        var attrs = o.attrs,
            pow = Math.pow,
            opacity,
            oindex,
            type = "linear",
            fxfy = ".5 .5";
        o.attrs.gradient = gradient;
        gradient = Str(gradient).replace(R._radial_gradient, function (all, fx, fy) {
            type = "radial";
            if (fx && fy) {
                fx = toFloat(fx);
                fy = toFloat(fy);
                pow(fx - .5, 2) + pow(fy - .5, 2) > .25 && (fy = math.sqrt(.25 - pow(fx - .5, 2)) * ((fy > .5) * 2 - 1) + .5);
                fxfy = fx + S + fy;
            }
            return E;
        });
        gradient = gradient.split(/\s*\-\s*/);
        if (type == "linear") {
            var angle = gradient.shift();
            angle = -toFloat(angle);
            if (isNaN(angle)) {
                return null;
            }
        }
        var dots = R._parseDots(gradient);
        if (!dots) {
            return null;
        }
        o = o.shape || o.node;
        if (dots.length) {
            o.removeChild(fill);
            fill.on = true;
            fill.method = "none";
            fill.color = dots[0].color;
            fill.color2 = dots[dots.length - 1].color;
            var clrs = [];
            for (var i = 0, ii = dots.length; i < ii; i++) {
                dots[i].offset && clrs.push(dots[i].offset + S + dots[i].color);
            }
            fill.colors = clrs.length ? clrs.join() : "0% " + fill.color;
            if (type == "radial") {
                fill.type = "gradientTitle";
                fill.focus = "100%";
                fill.focussize = "0 0";
                fill.focusposition = fxfy;
                fill.angle = 0;
            } else {
                // fill.rotate= true;
                fill.type = "gradient";
                fill.angle = (270 - angle) % 360;
            }
            o.appendChild(fill);
        }
        return 1;
    },
    Element = function (node, vml) {
        this[0] = this.node = node;
        node.raphael = true;
        this.id = R._oid++;
        node.raphaelid = this.id;
        this.X = 0;
        this.Y = 0;
        this.attrs = {};
        this.paper = vml;
        this.matrix = R.matrix();
        this._ = {
            transform: [],
            sx: 1,
            sy: 1,
            dx: 0,
            dy: 0,
            deg: 0,
            dirty: 1,
            dirtyT: 1
        };
        !vml.bottom && (vml.bottom = this);
        this.prev = vml.top;
        vml.top && (vml.top.next = this);
        vml.top = this;
        this.next = null;
    };
    var elproto = R.el;

    Element.prototype = elproto;
    elproto.constructor = Element;
    elproto.transform = function (tstr) {
        if (tstr == null) {
            return this._.transform;
        }
        var vbs = this.paper._viewBoxShift,
            vbt = vbs ? "s" + [vbs.scale, vbs.scale] + "-1-1t" + [vbs.dx, vbs.dy] : E,
            oldt;
        if (vbs) {
            oldt = tstr = Str(tstr).replace(/\.{3}|\u2026/g, this._.transform || E);
        }
        R._extractTransform(this, vbt + tstr);
        var matrix = this.matrix.clone(),
            skew = this.skew,
            o = this.node,
            split,
            isGrad = ~Str(this.attrs.fill).indexOf("-"),
            isPatt = !Str(this.attrs.fill).indexOf("url(");
        matrix.translate(-.5, -.5);
        if (isPatt || isGrad || this.type == "image") {
            skew.matrix = "1 0 0 1";
            skew.offset = "0 0";
            split = matrix.split();
            if ((isGrad && split.noRotation) || !split.isSimple) {
                o.style.filter = matrix.toFilter();
                var bb = this.getBBox(),
                    bbt = this.getBBox(1),
                    dx = bb.x - bbt.x,
                    dy = bb.y - bbt.y;
                o.coordorigin = (dx * -zoom) + S + (dy * -zoom);
                setCoords(this, 1, 1, dx, dy, 0);
            } else {
                o.style.filter = E;
                setCoords(this, split.scalex, split.scaley, split.dx, split.dy, split.rotate);
            }
        } else {
            o.style.filter = E;
            skew.matrix = Str(matrix);
            skew.offset = matrix.offset();
        }
        oldt && (this._.transform = oldt);
        return this;
    };
    elproto.rotate = function (deg, cx, cy) {
        if (this.removed) {
            return this;
        }
        if (deg == null) {
            return;
        }
        deg = Str(deg).split(separator);
        if (deg.length - 1) {
            cx = toFloat(deg[1]);
            cy = toFloat(deg[2]);
        }
        deg = toFloat(deg[0]);
        (cy == null) && (cx = cy);
        if (cx == null || cy == null) {
            var bbox = this.getBBox(1);
            cx = bbox.x + bbox.width / 2;
            cy = bbox.y + bbox.height / 2;
        }
        this._.dirtyT = 1;
        this.transform(this._.transform.concat([["r", deg, cx, cy]]));
        return this;
    };
    elproto.translate = function (dx, dy) {
        if (this.removed) {
            return this;
        }
        dx = Str(dx).split(separator);
        if (dx.length - 1) {
            dy = toFloat(dx[1]);
        }
        dx = toFloat(dx[0]) || 0;
        dy = +dy || 0;
        if (this._.bbox) {
            this._.bbox.x += dx;
            this._.bbox.y += dy;
        }
        this.transform(this._.transform.concat([["t", dx, dy]]));
        return this;
    };
    elproto.scale = function (sx, sy, cx, cy) {
        if (this.removed) {
            return this;
        }
        sx = Str(sx).split(separator);
        if (sx.length - 1) {
            sy = toFloat(sx[1]);
            cx = toFloat(sx[2]);
            cy = toFloat(sx[3]);
            isNaN(cx) && (cx = null);
            isNaN(cy) && (cy = null);
        }
        sx = toFloat(sx[0]);
        (sy == null) && (sy = sx);
        (cy == null) && (cx = cy);
        if (cx == null || cy == null) {
            var bbox = this.getBBox(1);
        }
        cx = cx == null ? bbox.x + bbox.width / 2 : cx;
        cy = cy == null ? bbox.y + bbox.height / 2 : cy;
    
        this.transform(this._.transform.concat([["s", sx, sy, cx, cy]]));
        this._.dirtyT = 1;
        return this;
    };
    elproto.hide = function () {
        !this.removed && (this.node.style.display = "none");
        return this;
    };
    elproto.show = function () {
        !this.removed && (this.node.style.display = E);
        return this;
    };
    elproto._getBBox = function () {
        if (this.removed) {
            return {};
        }
        return {
            x: this.X + (this.bbx || 0) - this.W / 2,
            y: this.Y - this.H,
            width: this.W,
            height: this.H
        };
    };
    elproto.remove = function () {
        if (this.removed || !this.node.parentNode) {
            return;
        }
        this.paper.__set__ && this.paper.__set__.exclude(this);
        R.eve.unbind("raphael.*.*." + this.id);
        R._tear(this, this.paper);
        this.node.parentNode.removeChild(this.node);
        this.shape && this.shape.parentNode.removeChild(this.shape);
        for (var i in this) {
            this[i] = typeof this[i] == "function" ? R._removedFactory(i) : null;
        }
        this.removed = true;
    };
    elproto.attr = function (name, value) {
        if (this.removed) {
            return this;
        }
        if (name == null) {
            var res = {};
            for (var a in this.attrs) if (this.attrs[has](a)) {
                res[a] = this.attrs[a];
            }
            res.gradient && res.fill == "none" && (res.fill = res.gradient) && delete res.gradient;
            res.transform = this._.transform;
            return res;
        }
        if (value == null && R.is(name, "string")) {
            if (name == fillString && this.attrs.fill == "none" && this.attrs.gradient) {
                return this.attrs.gradient;
            }
            var names = name.split(separator),
                out = {};
            for (var i = 0, ii = names.length; i < ii; i++) {
                name = names[i];
                if (name in this.attrs) {
                    out[name] = this.attrs[name];
                } else if (R.is(this.paper.customAttributes[name], "function")) {
                    out[name] = this.paper.customAttributes[name].def;
                } else {
                    out[name] = R._availableAttrs[name];
                }
            }
            return ii - 1 ? out : out[names[0]];
        }
        if (this.attrs && value == null && R.is(name, "array")) {
            out = {};
            for (i = 0, ii = name.length; i < ii; i++) {
                out[name[i]] = this.attr(name[i]);
            }
            return out;
        }
        var params;
        if (value != null) {
            params = {};
            params[name] = value;
        }
        value == null && R.is(name, "object") && (params = name);
        for (var key in params) {
            eve("raphael.attr." + key + "." + this.id, this, params[key]);
        }
        if (params) {
            for (key in this.paper.customAttributes) if (this.paper.customAttributes[has](key) && params[has](key) && R.is(this.paper.customAttributes[key], "function")) {
                var par = this.paper.customAttributes[key].apply(this, [].concat(params[key]));
                this.attrs[key] = params[key];
                for (var subkey in par) if (par[has](subkey)) {
                    params[subkey] = par[subkey];
                }
            }
            // this.paper.canvas.style.display = "none";
            if (params.text && this.type == "text") {
                this.textpath.string = params.text;
            }
            setFillAndStroke(this, params);
            // this.paper.canvas.style.display = E;
        }
        return this;
    };
    elproto.toFront = function () {
        !this.removed && this.node.parentNode.appendChild(this.node);
        this.paper && this.paper.top != this && R._tofront(this, this.paper);
        return this;
    };
    elproto.toBack = function () {
        if (this.removed) {
            return this;
        }
        if (this.node.parentNode.firstChild != this.node) {
            this.node.parentNode.insertBefore(this.node, this.node.parentNode.firstChild);
            R._toback(this, this.paper);
        }
        return this;
    };
    elproto.insertAfter = function (element) {
        if (this.removed) {
            return this;
        }
        if (element.constructor == R.st.constructor) {
            element = element[element.length - 1];
        }
        if (element.node.nextSibling) {
            element.node.parentNode.insertBefore(this.node, element.node.nextSibling);
        } else {
            element.node.parentNode.appendChild(this.node);
        }
        R._insertafter(this, element, this.paper);
        return this;
    };
    elproto.insertBefore = function (element) {
        if (this.removed) {
            return this;
        }
        if (element.constructor == R.st.constructor) {
            element = element[0];
        }
        element.node.parentNode.insertBefore(this.node, element.node);
        R._insertbefore(this, element, this.paper);
        return this;
    };
    elproto.blur = function (size) {
        var s = this.node.runtimeStyle,
            f = s.filter;
        f = f.replace(blurregexp, E);
        if (+size !== 0) {
            this.attrs.blur = size;
            s.filter = f + S + ms + ".Blur(pixelradius=" + (+size || 1.5) + ")";
            s.margin = R.format("-{0}px 0 0 -{0}px", round(+size || 1.5));
        } else {
            s.filter = f;
            s.margin = 0;
            delete this.attrs.blur;
        }
    };

    R._engine.path = function (pathString, vml) {
        var el = createNode("shape");
        el.style.cssText = cssDot;
        el.coordsize = zoom + S + zoom;
        el.coordorigin = vml.coordorigin;
        var p = new Element(el, vml),
            attr = {fill: "none", stroke: "#000"};
        pathString && (attr.path = pathString);
        p.type = "path";
        p.path = [];
        p.Path = E;
        setFillAndStroke(p, attr);
        vml.canvas.appendChild(el);
        var skew = createNode("skew");
        skew.on = true;
        el.appendChild(skew);
        p.skew = skew;
        p.transform(E);
        return p;
    };
    R._engine.rect = function (vml, x, y, w, h, r) {
        var path = R._rectPath(x, y, w, h, r),
            res = vml.path(path),
            a = res.attrs;
        res.X = a.x = x;
        res.Y = a.y = y;
        res.W = a.width = w;
        res.H = a.height = h;
        a.r = r;
        a.path = path;
        res.type = "rect";
        return res;
    };
    R._engine.ellipse = function (vml, x, y, rx, ry) {
        var res = vml.path(),
            a = res.attrs;
        res.X = x - rx;
        res.Y = y - ry;
        res.W = rx * 2;
        res.H = ry * 2;
        res.type = "ellipse";
        setFillAndStroke(res, {
            cx: x,
            cy: y,
            rx: rx,
            ry: ry
        });
        return res;
    };
    R._engine.circle = function (vml, x, y, r) {
        var res = vml.path(),
            a = res.attrs;
        res.X = x - r;
        res.Y = y - r;
        res.W = res.H = r * 2;
        res.type = "circle";
        setFillAndStroke(res, {
            cx: x,
            cy: y,
            r: r
        });
        return res;
    };
    R._engine.image = function (vml, src, x, y, w, h) {
        var path = R._rectPath(x, y, w, h),
            res = vml.path(path).attr({stroke: "none"}),
            a = res.attrs,
            node = res.node,
            fill = node.getElementsByTagName(fillString)[0];
        a.src = src;
        res.X = a.x = x;
        res.Y = a.y = y;
        res.W = a.width = w;
        res.H = a.height = h;
        a.path = path;
        res.type = "image";
        fill.parentNode == node && node.removeChild(fill);
        fill.rotate = true;
        fill.src = src;
        fill.type = "tile";
        res._.fillpos = [x, y];
        res._.fillsize = [w, h];
        node.appendChild(fill);
        setCoords(res, 1, 1, 0, 0, 0);
        return res;
    };
    R._engine.text = function (vml, x, y, text) {
        var el = createNode("shape"),
            path = createNode("path"),
            o = createNode("textpath");
        x = x || 0;
        y = y || 0;
        text = text || "";
        path.v = R.format("m{0},{1}l{2},{1}", round(x * zoom), round(y * zoom), round(x * zoom) + 1);
        path.textpathok = true;
        o.string = Str(text);
        o.on = true;
        el.style.cssText = cssDot;
        el.coordsize = zoom + S + zoom;
        el.coordorigin = "0 0";
        var p = new Element(el, vml),
            attr = {
                fill: "#000",
                stroke: "none",
                font: R._availableAttrs.font,
                text: text
            };
        p.shape = el;
        p.path = path;
        p.textpath = o;
        p.type = "text";
        p.attrs.text = Str(text);
        p.attrs.x = x;
        p.attrs.y = y;
        p.attrs.w = 1;
        p.attrs.h = 1;
        setFillAndStroke(p, attr);
        el.appendChild(o);
        el.appendChild(path);
        vml.canvas.appendChild(el);
        var skew = createNode("skew");
        skew.on = true;
        el.appendChild(skew);
        p.skew = skew;
        p.transform(E);
        return p;
    };
    R._engine.setSize = function (width, height) {
        var cs = this.canvas.style;
        this.width = width;
        this.height = height;
        width == +width && (width += "px");
        height == +height && (height += "px");
        cs.width = width;
        cs.height = height;
        cs.clip = "rect(0 " + width + " " + height + " 0)";
        if (this._viewBox) {
            R._engine.setViewBox.apply(this, this._viewBox);
        }
        return this;
    };
    R._engine.setViewBox = function (x, y, w, h, fit) {
        R.eve("raphael.setViewBox", this, this._viewBox, [x, y, w, h, fit]);
        var width = this.width,
            height = this.height,
            size = 1 / mmax(w / width, h / height),
            H, W;
        if (fit) {
            H = height / h;
            W = width / w;
            if (w * H < width) {
                x -= (width - w * H) / 2 / H;
            }
            if (h * W < height) {
                y -= (height - h * W) / 2 / W;
            }
        }
        this._viewBox = [x, y, w, h, !!fit];
        this._viewBoxShift = {
            dx: -x,
            dy: -y,
            scale: size
        };
        this.forEach(function (el) {
            el.transform("...");
        });
        return this;
    };
    var createNode;
    R._engine.initWin = function (win) {
            var doc = win.document;
            doc.createStyleSheet().addRule(".rvml", "behavior:url(#default#VML)");
            try {
                !doc.namespaces.rvml && doc.namespaces.add("rvml", "urn:schemas-microsoft-com:vml");
                createNode = function (tagName) {
                    return doc.createElement('<rvml:' + tagName + ' class="rvml">');
                };
            } catch (e) {
                createNode = function (tagName) {
                    return doc.createElement('<' + tagName + ' xmlns="urn:schemas-microsoft.com:vml" class="rvml">');
                };
            }
        };
    R._engine.initWin(R._g.win);
    R._engine.create = function () {
        var con = R._getContainer.apply(0, arguments),
            container = con.container,
            height = con.height,
            s,
            width = con.width,
            x = con.x,
            y = con.y;
        if (!container) {
            throw new Error("VML container not found.");
        }
        var res = new R._Paper,
            c = res.canvas = R._g.doc.createElement("div"),
            cs = c.style;
        x = x || 0;
        y = y || 0;
        width = width || 512;
        height = height || 342;
        res.width = width;
        res.height = height;
        width == +width && (width += "px");
        height == +height && (height += "px");
        res.coordsize = zoom * 1e3 + S + zoom * 1e3;
        res.coordorigin = "0 0";
        res.span = R._g.doc.createElement("span");
        res.span.style.cssText = "position:absolute;left:-9999em;top:-9999em;padding:0;margin:0;line-height:1;";
        c.appendChild(res.span);
        cs.cssText = R.format("top:0;left:0;width:{0};height:{1};display:inline-block;position:relative;clip:rect(0 {0} {1} 0);overflow:hidden", width, height);
        if (container == 1) {
            R._g.doc.body.appendChild(c);
            cs.left = x + "px";
            cs.top = y + "px";
            cs.position = "absolute";
        } else {
            if (container.firstChild) {
                container.insertBefore(c, container.firstChild);
            } else {
                container.appendChild(c);
            }
        }
        res.renderfix = function () {};
        return res;
    };
    R.prototype.clear = function () {
        R.eve("raphael.clear", this);
        this.canvas.innerHTML = E;
        this.span = R._g.doc.createElement("span");
        this.span.style.cssText = "position:absolute;left:-9999em;top:-9999em;padding:0;margin:0;line-height:1;display:inline;";
        this.canvas.appendChild(this.span);
        this.bottom = this.top = null;
    };
    R.prototype.remove = function () {
        R.eve("raphael.remove", this);
        this.canvas.parentNode.removeChild(this.canvas);
        for (var i in this) {
            this[i] = typeof this[i] == "function" ? R._removedFactory(i) : null;
        }
        return true;
    };

    var setproto = R.st;
    for (var method in elproto) if (elproto[has](method) && !setproto[has](method)) {
        setproto[method] = (function (methodname) {
            return function () {
                var arg = arguments;
                return this.forEach(function (el) {
                    el[methodname].apply(el, arg);
                });
            };
        })(method);
    }
})();

    // EXPOSE
    // SVG and VML are appended just before the EXPOSE line
    // Even with AMD, Raphael should be defined globally
    oldRaphael.was ? (g.win.Raphael = R) : (Raphael = R);

    return R;
}));
/** @license
 * Scroller
 * http://github.com/zynga/scroller
 *
 * Copyright 2011, Zynga Inc.
 * Licensed under the MIT License.
 * https://raw.github.com/zynga/scroller/master/MIT-LICENSE.txt
 *
 * Based on the work of: Unify Project (unify-project.org)
 * http://unify-project.org
 * Copyright 2011, Deutsche Telekom AG
 * License: MIT + Apache (V2)
 *
 * Inspired by: https://github.com/inexorabletash/raf-shim/blob/master/raf.js
 */
(function(global)
{
  if(global.requestAnimationFrame) {
    return;
  }

  // Basic emulation of native methods for internal use

  var now = Date.now || function() {
    return +new Date;
  };

  var getKeys = Object.keys || function(obj) {

    var keys = {};
    for (var key in obj) {
      keys[key] = true;
    }

    return keys;

  };

  var isEmpty = Object.empty || function(obj) {

    for (var key in obj) {
      return false;
    }

    return true;

  };


  // requestAnimationFrame polyfill
  // http://webstuff.nfshost.com/anim-timing/Overview.html

  var postfix = "RequestAnimationFrame";
  var prefix = (function()
  {
    var all = "webkit,moz,o,ms".split(",");
    for (var i=0; i<4; i++) {
      if (global[all[i]+postfix] != null) {
        return all[i];
      }
    }
  })();

  // Vendor specific implementation
  if (prefix)
  {
    global.requestAnimationFrame = global[prefix+postfix];
    global.cancelRequestAnimationFrame = global[prefix+"Cancel"+postfix];
    return;
  }

  // Custom implementation
  var TARGET_FPS = 60;
  var requests = {};
  var rafHandle = 1;
  var timeoutHandle = null;

  global.requestAnimationFrame = function(callback, root)
  {
    var callbackHandle = rafHandle++;

    // Store callback
    requests[callbackHandle] = callback;

    // Create timeout at first request
    if (timeoutHandle === null)
    {
      timeoutHandle = setTimeout(function()
      {
        var time = now();
        var currentRequests = requests;
        var keys = getKeys(currentRequests);

        // Reset data structure before executing callbacks
        requests = {};
        timeoutHandle = null;

        // Process all callbacks
        for (var i=0, l=keys.length; i<l; i++) {
          currentRequests[keys[i]](time);
        }
      }, 1000 / TARGET_FPS);
    }

    return callbackHandle;
  };

  global.cancelRequestAnimationFrame = function(handle)
  {
    delete requests[handle];

    // Stop timeout if all where removed
    if (isEmpty(requests))
    {
      clearTimeout(timeoutHandle);
      timeoutHandle = null;
    }
  };

})(this);/*
 * Scroller
 * http://github.com/zynga/scroller
 *
 * Copyright 2011, Zynga Inc.
 * Licensed under the MIT License.
 * https://raw.github.com/zynga/scroller/master/MIT-LICENSE.txt
 *
 * Based on the work of: Unify Project (unify-project.org)
 * http://unify-project.org
 * Copyright 2011, Deutsche Telekom AG
 * License: MIT + Apache (V2)
 */

/**
 * Generic animation class with support for dropped frames both optional easing and duration.
 *
 * Optional duration is useful when the lifetime is defined by another condition than time
 * e.g. speed of an animating object, etc.
 *
 * Dropped frame logic allows to keep using the same updater logic independent from the actual
 * rendering. This eases a lot of cases where it might be pretty complex to break down a state
 * based on the pure time difference.
 */
(function(global) {
  var time = Date.now || function() {
    return +new Date();
  };
  var desiredFrames = 60;
  var millisecondsPerSecond = 1000;
  var running = {};
  var counter = 1;

  // Create namespaces
  if (!global.core) {
    global.core = { effect : {} };
  } else if (!core.effect) {
    core.effect = {};
  }

  core.effect.Animate = {

    /**
     * Stops the given animation.
     *
     * @param id {Integer} Unique animation ID
     * @return {Boolean} Whether the animation was stopped (aka, was running before)
     */
    stop: function(id) {
      var cleared = running[id] != null;
      if (cleared) {
        running[id] = null;
      }

      return cleared;
    },


    /**
     * Whether the given animation is still running.
     *
     * @param id {Integer} Unique animation ID
     * @return {Boolean} Whether the animation is still running
     */
    isRunning: function(id) {
      return running[id] != null;
    },


    /**
     * Start the animation.
     *
     * @param stepCallback {Function} Pointer to function which is executed on every step.
     *   Signature of the method should be `function(percent, now, virtual) { return continueWithAnimation; }`
     * @param verifyCallback {Function} Executed before every animation step.
     *   Signature of the method should be `function() { return continueWithAnimation; }`
     * @param completedCallback {Function}
     *   Signature of the method should be `function(droppedFrames, finishedAnimation) {}`
     * @param duration {Integer} Milliseconds to run the animation
     * @param easingMethod {Function} Pointer to easing function
     *   Signature of the method should be `function(percent) { return modifiedValue; }`
     * @param root {Element ? document.body} Render root, when available. Used for internal
     *   usage of requestAnimationFrame.
     * @return {Integer} Identifier of animation. Can be used to stop it any time.
     */
    start: function(stepCallback, verifyCallback, completedCallback, duration, easingMethod, root) {

      var start = time();
      var lastFrame = start;
      var percent = 0;
      var dropCounter = 0;
      var id = counter++;

      if (!root) {
        root = document.body;
      }

      // Compacting running db automatically every few new animations
      if (id % 20 === 0) {
        var newRunning = {};
        for (var usedId in running) {
          newRunning[usedId] = true;
        }
        running = newRunning;
      }

      // This is the internal step method which is called every few milliseconds
      var step = function(virtual) {

        // Normalize virtual value
        var render = virtual !== true;

        // Get current time
        var now = time();

        // Verification is executed before next animation step
        if (!running[id] || (verifyCallback && !verifyCallback(id))) {

          running[id] = null;
          completedCallback && completedCallback(desiredFrames - (dropCounter / ((now - start) / millisecondsPerSecond)), id, false);
          return;

        }

        // For the current rendering to apply let's update omitted steps in memory.
        // This is important to bring internal state variables up-to-date with progress in time.
        if (render) {

          var droppedFrames = Math.round((now - lastFrame) / (millisecondsPerSecond / desiredFrames)) - 1;
          for (var j = 0; j < Math.min(droppedFrames, 4); j++) {
            step(true);
            dropCounter++;
          }

        }

        // Compute percent value
        if (duration) {
          percent = (now - start) / duration;
          if (percent > 1) {
            percent = 1;
          }
        }

        // Execute step callback, then...
        var value = easingMethod ? easingMethod(percent) : percent;
        if ((stepCallback(value, now, render) === false || percent === 1) && render) {
          running[id] = null;
          completedCallback && completedCallback(desiredFrames - (dropCounter / ((now - start) / millisecondsPerSecond)), id, percent === 1 || duration == null);
        } else if (render) {
          lastFrame = now;
          requestAnimationFrame(step, root);
        }
      };

      // Mark as running
      running[id] = true;

      // Init first step
      requestAnimationFrame(step, root);

      // Return unique animation ID
      return id;
    }
  };
})(this);

var EasyScroller = function(content, options) {

  this.content = content;
  this.container = content.parentNode;
  this.options = options || {};

  // create Scroller instance
  var that = this;
  this.scroller = new Scroller(function(left, top, zoom) {
    that.render(left, top, zoom);
  }, options);

  // bind events
  this.bindEvents();

  // the content element needs a correct transform origin for zooming
  this.content.style[EasyScroller.vendorPrefix + 'TransformOrigin'] = "left top";

  // reflow for the first time
  this.reflow();

};

EasyScroller.prototype.render = (function() {

  var docStyle = document.documentElement.style;

  var engine;
  if (window.opera && Object.prototype.toString.call(opera) === '[object Opera]') {
    engine = 'presto';
  } else if ('MozAppearance' in docStyle) {
    engine = 'gecko';
  } else if ('WebkitAppearance' in docStyle) {
    engine = 'webkit';
  } else if (typeof navigator.cpuClass === 'string') {
    engine = 'trident';
  }

  var vendorPrefix = EasyScroller.vendorPrefix = {
    trident: 'ms',
    gecko: 'Moz',
    webkit: 'Webkit',
    presto: 'O'
  }[engine];

  var helperElem = document.createElement("div");
  var undef;

  var perspectiveProperty = vendorPrefix + "Perspective";
  var transformProperty = vendorPrefix + "Transform";

  if (helperElem.style[perspectiveProperty] !== undef) {

    return function(left, top, zoom) {
      this.content.style[transformProperty] = 'translate3d(' + (-left) + 'px,' + (-top) + 'px,0) scale(' + zoom + ')';
    };

  } else if (helperElem.style[transformProperty] !== undef) {

    return function(left, top, zoom) {
      this.content.style[transformProperty] = 'translate(' + (-left) + 'px,' + (-top) + 'px) scale(' + zoom + ')';
    };

  } else {

    return function(left, top, zoom) {
      this.content.style.marginLeft = left ? (-left/zoom) + 'px' : '';
      this.content.style.marginTop = top ? (-top/zoom) + 'px' : '';
      this.content.style.zoom = zoom || '';
    };

  }
})();

EasyScroller.prototype.reflow = function() {

  // set the right scroller dimensions
  this.scroller.setDimensions(this.container.clientWidth, this.container.clientHeight, this.content.offsetWidth, this.content.offsetHeight);

  // refresh the position for zooming purposes
  var rect = this.container.getBoundingClientRect();
  this.scroller.setPosition(rect.left + this.container.clientLeft, rect.top + this.container.clientTop);

};

EasyScroller.prototype.bindEvents = function() {

  var that = this;

  // reflow handling
  $(window).bind("resize", function() {
    that.reflow();
  });

  // added this here, not ideal, but it makes sure that the logo will
  // scroll correctly when the model tab is revealed.
  $('#modelTab').bind('click', function() {
    that.reflow();
  });


  // touch devices bind touch events
  if ('ontouchstart' in window) {

    this.container.addEventListener("touchstart", function(e) {

      // Don't react if initial down happens on a form element
      if (e.touches[0] && e.touches[0].target && e.touches[0].target.tagName.match(/input|textarea|select/i)) {
        return;
      }

      that.scroller.doTouchStart(e.touches, new Date().getTime());
      e.preventDefault();

    }, false);

    document.addEventListener("touchmove", function(e) {
      that.scroller.doTouchMove(e.touches, new Date().getTime(), e.scale);
    }, false);

    document.addEventListener("touchend", function(e) {
      that.scroller.doTouchEnd(new Date().getTime());
    }, false);

    document.addEventListener("touchcancel", function(e) {
      that.scroller.doTouchEnd(new Date().getTime());
    }, false);

  // non-touch bind mouse events
  } else {

    var mousedown = false;

    $(this.container).bind("mousedown", function(e) {

      if (e.target.tagName.match(/input|textarea|select/i)) {
        return;
      }


      that.scroller.doTouchStart([{
        pageX: e.pageX,
        pageY: e.pageY
      }], new Date().getTime());

      mousedown = true;
      e.preventDefault();

    });

    $(document).bind("mousemove", function(e) {

      if (!mousedown) {
        return;
      }

      that.scroller.doTouchMove([{
        pageX: e.pageX,
        pageY: e.pageY
      }], new Date().getTime());

      mousedown = true;

    });

    $(document).bind("mouseup", function(e) {

      if (!mousedown) {
        return;
      }

      that.scroller.doTouchEnd(new Date().getTime());

      mousedown = false;

    });

    $(this.container).bind("mousewheel", function(e) {
      if(that.options.zooming) {
        that.scroller.doMouseZoom(e.wheelDelta, new Date().getTime(), e.pageX, e.pageY);
        e.preventDefault();
      }
    });

  }

};

/*
 * Scroller
 * http://github.com/zynga/scroller
 *
 * Copyright 2011, Zynga Inc.
 * Licensed under the MIT License.
 * https://raw.github.com/zynga/scroller/master/MIT-LICENSE.txt
 *
 * Based on the work of: Unify Project (unify-project.org)
 * http://unify-project.org
 * Copyright 2011, Deutsche Telekom AG
 * License: MIT + Apache (V2)
 */

var Scroller;

(function() {

  /**
   * A pure logic 'component' for 'virtual' scrolling/zooming.
   */
  Scroller = function(callback, options) {

    this.__callback = callback;

    this.options = {

      /** Enable scrolling on x-axis */
      scrollingX: true,

      /** Enable scrolling on y-axis */
      scrollingY: true,

      /** Enable animations for deceleration, snap back, zooming and scrolling */
      animating: true,

      /** Enable bouncing (content can be slowly moved outside and jumps back after releasing) */
      bouncing: true,

      /** Enable locking to the main axis if user moves only slightly on one of them at start */
      locking: true,

      /** Enable pagination mode (switching between full page content panes) */
      paging: false,

      /** Enable snapping of content to a configured pixel grid */
      snapping: false,

      /** Enable zooming of content via API, fingers and mouse wheel */
      zooming: false,

      /** Minimum zoom level */
      minZoom: 0.5,

      /** Maximum zoom level */
      maxZoom: 3

    };

    for (var key in options) {
      this.options[key] = options[key];
    }

  };


  // Easing Equations (c) 2003 Robert Penner, all rights reserved.
  // Open source under the BSD License.

  /**
   * @param pos {Number} position between 0 (start of effect) and 1 (end of effect)
  **/
  var easeOutCubic = function(pos) {
    return (Math.pow((pos - 1), 3) + 1);
  };

  /**
   * @param pos {Number} position between 0 (start of effect) and 1 (end of effect)
  **/
  var easeInOutCubic = function(pos) {
    if ((pos /= 0.5) < 1) {
      return 0.5 * Math.pow(pos, 3);
    }

    return 0.5 * (Math.pow((pos - 2), 3) + 2);
  };


  var members = {

    /*
    ---------------------------------------------------------------------------
      INTERNAL FIELDS :: STATUS
    ---------------------------------------------------------------------------
    */

    /** {Boolean} Whether only a single finger is used in touch handling */
    __isSingleTouch: false,

    /** {Boolean} Whether a touch event sequence is in progress */
    __isTracking: false,

    /**
     * {Boolean} Whether a gesture zoom/rotate event is in progress. Activates when
     * a gesturestart event happens. This has higher priority than dragging.
     */
    __isGesturing: false,

    /**
     * {Boolean} Whether the user has moved by such a distance that we have enabled
     * dragging mode. Hint: It's only enabled after some pixels of movement to
     * not interrupt with clicks etc.
     */
    __isDragging: false,

    /**
     * {Boolean} Not touching and dragging anymore, and smoothly animating the
     * touch sequence using deceleration.
     */
    __isDecelerating: false,

    /**
     * {Boolean} Smoothly animating the currently configured change
     */
    __isAnimating: false,



    /*
    ---------------------------------------------------------------------------
      INTERNAL FIELDS :: DIMENSIONS
    ---------------------------------------------------------------------------
    */

    /** {Integer} Available outer left position (from document perspective) */
    __clientLeft: 0,

    /** {Integer} Available outer top position (from document perspective) */
    __clientTop: 0,

    /** {Integer} Available outer width */
    __clientWidth: 0,

    /** {Integer} Available outer height */
    __clientHeight: 0,

    /** {Integer} Outer width of content */
    __contentWidth: 0,

    /** {Integer} Outer height of content */
    __contentHeight: 0,

    /** {Integer} Snapping width for content */
    __snapWidth: 100,

    /** {Integer} Snapping height for content */
    __snapHeight: 100,

    /** {Integer} Height to assign to refresh area */
    __refreshHeight: null,

    /** {Boolean} Whether the refresh process is enabled when the event is released now */
    __refreshActive: false,

    /** {Function} Callback to execute on activation. This is for signalling the user about a refresh is about to happen when he release */
    __refreshActivate: null,

    /** {Function} Callback to execute on deactivation. This is for signalling the user about the refresh being cancelled */
    __refreshDeactivate: null,

    /** {Function} Callback to execute to start the actual refresh. Call {@link #refreshFinish} when done */
    __refreshStart: null,

    /** {Number} Zoom level */
    __zoomLevel: 1,

    /** {Number} Scroll position on x-axis */
    __scrollLeft: 0,

    /** {Number} Scroll position on y-axis */
    __scrollTop: 0,

    /** {Integer} Maximum allowed scroll position on x-axis */
    __maxScrollLeft: 0,

    /** {Integer} Maximum allowed scroll position on y-axis */
    __maxScrollTop: 0,

    /* {Number} Scheduled left position (final position when animating) */
    __scheduledLeft: 0,

    /* {Number} Scheduled top position (final position when animating) */
    __scheduledTop: 0,

    /* {Number} Scheduled zoom level (final scale when animating) */
    __scheduledZoom: 0,



    /*
    ---------------------------------------------------------------------------
      INTERNAL FIELDS :: LAST POSITIONS
    ---------------------------------------------------------------------------
    */

    /** {Number} Left position of finger at start */
    __lastTouchLeft: null,

    /** {Number} Top position of finger at start */
    __lastTouchTop: null,

    /** {Date} Timestamp of last move of finger. Used to limit tracking range for deceleration speed. */
    __lastTouchMove: null,

    /** {Array} List of positions, uses three indexes for each state: left, top, timestamp */
    __positions: null,



    /*
    ---------------------------------------------------------------------------
      INTERNAL FIELDS :: DECELERATION SUPPORT
    ---------------------------------------------------------------------------
    */

    /** {Integer} Minimum left scroll position during deceleration */
    __minDecelerationScrollLeft: null,

    /** {Integer} Minimum top scroll position during deceleration */
    __minDecelerationScrollTop: null,

    /** {Integer} Maximum left scroll position during deceleration */
    __maxDecelerationScrollLeft: null,

    /** {Integer} Maximum top scroll position during deceleration */
    __maxDecelerationScrollTop: null,

    /** {Number} Current factor to modify horizontal scroll position with on every step */
    __decelerationVelocityX: null,

    /** {Number} Current factor to modify vertical scroll position with on every step */
    __decelerationVelocityY: null,



    /*
    ---------------------------------------------------------------------------
      PUBLIC API
    ---------------------------------------------------------------------------
    */

    /**
     * Configures the dimensions of the client (outer) and content (inner) elements.
     * Requires the available space for the outer element and the outer size of the inner element.
     * All values which are falsy (null or zero etc.) are ignored and the old value is kept.
     *
     * @param clientWidth {Integer ? null} Inner width of outer element
     * @param clientHeight {Integer ? null} Inner height of outer element
     * @param contentWidth {Integer ? null} Outer width of inner element
     * @param contentHeight {Integer ? null} Outer height of inner element
     */
    setDimensions: function(clientWidth, clientHeight, contentWidth, contentHeight) {

      var self = this;

      // Only update values which are defined
      if (clientWidth) {
        self.__clientWidth = clientWidth;
      }

      if (clientHeight) {
        self.__clientHeight = clientHeight;
      }

      if (contentWidth) {
        self.__contentWidth = contentWidth;
      }

      if (contentHeight) {
        self.__contentHeight = contentHeight;
      }

      // Refresh maximums
      self.__computeScrollMax();

      // Refresh scroll position
      self.scrollTo(self.__scrollLeft, self.__scrollTop, true);

    },


    /**
     * Sets the client coordinates in relation to the document.
     *
     * @param left {Integer ? 0} Left position of outer element
     * @param top {Integer ? 0} Top position of outer element
     */
    setPosition: function(left, top) {

      var self = this;

      self.__clientLeft = left || 0;
      self.__clientTop = top || 0;

    },


    /**
     * Configures the snapping (when snapping is active)
     *
     * @param width {Integer} Snapping width
     * @param height {Integer} Snapping height
     */
    setSnapSize: function(width, height) {

      var self = this;

      self.__snapWidth = width;
      self.__snapHeight = height;

    },


    /**
     * Activates pull-to-refresh. A special zone on the top of the list to start a list refresh whenever
     * the user event is released during visibility of this zone. This was introduced by some apps on iOS like
     * the official Twitter client.
     *
     * @param height {Integer} Height of pull-to-refresh zone on top of rendered list
     * @param activateCallback {Function} Callback to execute on activation. This is for signalling the user about a refresh is about to happen when he release.
     * @param deactivateCallback {Function} Callback to execute on deactivation. This is for signalling the user about the refresh being cancelled.
     * @param startCallback {Function} Callback to execute to start the real async refresh action. Call {@link #finishPullToRefresh} after finish of refresh.
     */
    activatePullToRefresh: function(height, activateCallback, deactivateCallback, startCallback) {

      var self = this;

      self.__refreshHeight = height;
      self.__refreshActivate = activateCallback;
      self.__refreshDeactivate = deactivateCallback;
      self.__refreshStart = startCallback;

    },


    /**
     * Signalizes that pull-to-refresh is finished.
     */
    finishPullToRefresh: function() {

      var self = this;

      self.__refreshActive = false;
      if (self.__refreshDeactivate) {
        self.__refreshDeactivate();
      }

      self.scrollTo(self.__scrollLeft, self.__scrollTop, true);

    },


    /**
     * Returns the scroll position and zooming values
     *
     * @return {Map} `left` and `top` scroll position and `zoom` level
     */
    getValues: function() {

      var self = this;

      return {
        left: self.__scrollLeft,
        top: self.__scrollTop,
        zoom: self.__zoomLevel
      };

    },


    /**
     * Returns the maximum scroll values
     *
     * @return {Map} `left` and `top` maximum scroll values
     */
    getScrollMax: function() {

      var self = this;

      return {
        left: self.__maxScrollLeft,
        top: self.__maxScrollTop
      };

    },


    /**
     * Zooms to the given level. Supports optional animation. Zooms
     * the center when no coordinates are given.
     *
     * @param level {Number} Level to zoom to
     * @param animate {Boolean ? false} Whether to use animation
     * @param originLeft {Number ? null} Zoom in at given left coordinate
     * @param originTop {Number ? null} Zoom in at given top coordinate
     */
    zoomTo: function(level, animate, originLeft, originTop) {

      var self = this;

      if (!self.options.zooming) {
        throw new Error("Zooming is not enabled!");
      }

      // Stop deceleration
      if (self.__isDecelerating) {
        core.effect.Animate.stop(self.__isDecelerating);
        self.__isDecelerating = false;
      }

      var oldLevel = self.__zoomLevel;

      // Normalize input origin to center of viewport if not defined
      if (originLeft == null) {
        originLeft = self.__clientWidth / 2;
      }

      if (originTop == null) {
        originTop = self.__clientHeight / 2;
      }

      // Limit level according to configuration
      level = Math.max(Math.min(level, self.options.maxZoom), self.options.minZoom);

      // Recompute maximum values while temporary tweaking maximum scroll ranges
      self.__computeScrollMax(level);

      // Recompute left and top coordinates based on new zoom level
      var left = ((originLeft + self.__scrollLeft) * level / oldLevel) - originLeft;
      var top = ((originTop + self.__scrollTop) * level / oldLevel) - originTop;

      // Limit x-axis
      if (left > self.__maxScrollLeft) {
        left = self.__maxScrollLeft;
      } else if (left < 0) {
        left = 0;
      }

      // Limit y-axis
      if (top > self.__maxScrollTop) {
        top = self.__maxScrollTop;
      } else if (top < 0) {
        top = 0;
      }

      // Push values out
      self.__publish(left, top, level, animate);

    },


    /**
     * Zooms the content by the given factor.
     *
     * @param factor {Number} Zoom by given factor
     * @param animate {Boolean ? false} Whether to use animation
     * @param originLeft {Number ? 0} Zoom in at given left coordinate
     * @param originTop {Number ? 0} Zoom in at given top coordinate
     */
    zoomBy: function(factor, animate, originLeft, originTop) {

      var self = this;

      self.zoomTo(self.__zoomLevel * factor, animate, originLeft, originTop);

    },


    /**
     * Scrolls to the given position. Respect limitations and snapping automatically.
     *
     * @param left {Number?null} Horizontal scroll position, keeps current if value is <code>null</code>
     * @param top {Number?null} Vertical scroll position, keeps current if value is <code>null</code>
     * @param animate {Boolean?false} Whether the scrolling should happen using an animation
     * @param zoom {Number?null} Zoom level to go to
     */
    scrollTo: function(left, top, animate, zoom) {


      var self = this;

      // Stop deceleration
      if (self.__isDecelerating) {
        core.effect.Animate.stop(self.__isDecelerating);
        self.__isDecelerating = false;
      }

      // Correct coordinates based on new zoom level
      if (zoom != null && zoom !== self.__zoomLevel) {

        if (!self.options.zooming) {
          throw new Error("Zooming is not enabled!");
        }

        left *= zoom;
        top *= zoom;

        // Recompute maximum values while temporary tweaking maximum scroll ranges
        self.__computeScrollMax(zoom);

      } else {

        // Keep zoom when not defined
        zoom = self.__zoomLevel;

      }

      if (!self.options.scrollingX) {

        left = self.__scrollLeft;

      } else {

        if (self.options.paging) {
          left = Math.round(left / self.__clientWidth) * self.__clientWidth;
        } else if (self.options.snapping) {
          left = Math.round(left / self.__snapWidth) * self.__snapWidth;
        }

      }

      if (!self.options.scrollingY) {

        top = self.__scrollTop;

      } else {

        if (self.options.paging) {
          top = Math.round(top / self.__clientHeight) * self.__clientHeight;
        } else if (self.options.snapping) {
          top = Math.round(top / self.__snapHeight) * self.__snapHeight;
        }

      }

      // Limit for allowed ranges
      left = Math.max(Math.min(self.__maxScrollLeft, left), 0);
      top = Math.max(Math.min(self.__maxScrollTop, top), 0);

      // Don't animate when no change detected, still call publish to make sure
      // that rendered position is really in-sync with internal data
      if (left === self.__scrollLeft && top === self.__scrollTop) {
        animate = false;
      }

      $(document).trigger("scrolledTo", [left, top, zoom] );
      // Publish new values
      self.__publish(left, top, zoom, animate);

    },


    /**
     * Scroll by the given offset
     *
     * @param left {Number ? 0} Scroll x-axis by given offset
     * @param top {Number ? 0} Scroll x-axis by given offset
     * @param animate {Boolean ? false} Whether to animate the given change
     */
    scrollBy: function(left, top, animate) {

      var self = this;

      var startLeft = self.__isAnimating ? self.__scheduledLeft : self.__scrollLeft;
      var startTop = self.__isAnimating ? self.__scheduledTop : self.__scrollTop;

      self.scrollTo(startLeft + (left || 0), startTop + (top || 0), animate);

    },



    /*
    ---------------------------------------------------------------------------
      EVENT CALLBACKS
    ---------------------------------------------------------------------------
    */

    /**
     * Mouse wheel handler for zooming support
     */
    doMouseZoom: function(wheelDelta, timeStamp, pageX, pageY) {

      var self = this;
      var change = wheelDelta > 0 ? 0.97 : 1.03;

      return self.zoomTo(self.__zoomLevel * change, false, pageX - self.__clientLeft, pageY - self.__clientTop);

    },


    /**
     * Touch start handler for scrolling support
     */
    doTouchStart: function(touches, timeStamp) {

      // Array-like check is enough here
      if (touches.length == null) {
        throw new Error("Invalid touch list: " + touches);
      }

      if (timeStamp instanceof Date) {
        timeStamp = timeStamp.valueOf();
      }
      if (typeof timeStamp !== "number") {
        throw new Error("Invalid timestamp value: " + timeStamp);
      }

      var self = this;

      // Stop deceleration
      if (self.__isDecelerating) {
        core.effect.Animate.stop(self.__isDecelerating);
        self.__isDecelerating = false;
      }

      // Stop animation
      if (self.__isAnimating) {
        core.effect.Animate.stop(self.__isAnimating);
        self.__isAnimating = false;
      }

      // Use center point when dealing with two fingers
      var currentTouchLeft, currentTouchTop;
      var isSingleTouch = touches.length === 1;
      if (isSingleTouch) {
        currentTouchLeft = touches[0].pageX;
        currentTouchTop = touches[0].pageY;
      } else {
        currentTouchLeft = Math.abs(touches[0].pageX + touches[1].pageX) / 2;
        currentTouchTop = Math.abs(touches[0].pageY + touches[1].pageY) / 2;
      }

      // Store initial positions
      self.__initialTouchLeft = currentTouchLeft;
      self.__initialTouchTop = currentTouchTop;

      // Store current zoom level
      self.__zoomLevelStart = self.__zoomLevel;

      // Store initial touch positions
      self.__lastTouchLeft = currentTouchLeft;
      self.__lastTouchTop = currentTouchTop;

      // Store initial move time stamp
      self.__lastTouchMove = timeStamp;

      // Reset initial scale
      self.__lastScale = 1;

      // Reset locking flags
      self.__enableScrollX = !isSingleTouch && self.options.scrollingX;
      self.__enableScrollY = !isSingleTouch && self.options.scrollingY;

      // Reset tracking flag
      self.__isTracking = true;

      // Dragging starts directly with two fingers, otherwise lazy with an offset
      self.__isDragging = !isSingleTouch;

      // Some features are disabled in multi touch scenarios
      self.__isSingleTouch = isSingleTouch;

      // Clearing data structure
      self.__positions = [];

    },


    /**
     * Touch move handler for scrolling support
     */
    doTouchMove: function(touches, timeStamp, scale) {

      // Array-like check is enough here
      if (touches.length == null) {
        throw new Error("Invalid touch list: " + touches);
      }

      if (timeStamp instanceof Date) {
        timeStamp = timeStamp.valueOf();
      }
      if (typeof timeStamp !== "number") {
        throw new Error("Invalid timestamp value: " + timeStamp);
      }

      var self = this;

      // Ignore event when tracking is not enabled (event might be outside of element)
      if (!self.__isTracking) {
        return;
      }


      var currentTouchLeft, currentTouchTop;

      // Compute move based around of center of fingers
      if (touches.length === 2) {
        currentTouchLeft = Math.abs(touches[0].pageX + touches[1].pageX) / 2;
        currentTouchTop = Math.abs(touches[0].pageY + touches[1].pageY) / 2;
      } else {
        currentTouchLeft = touches[0].pageX;
        currentTouchTop = touches[0].pageY;
      }

      var positions = self.__positions;

      // Are we already in dragging mode?
      if (self.__isDragging) {

        // Compute move distance
        var moveX = currentTouchLeft - self.__lastTouchLeft;
        var moveY = currentTouchTop - self.__lastTouchTop;

        // Read previous scroll position and zooming
        var scrollLeft = self.__scrollLeft;
        var scrollTop = self.__scrollTop;
        var level = self.__zoomLevel;

        // Work with scaling
        if (scale != null && self.options.zooming) {

          var oldLevel = level;

          // Recompute level based on previous scale and new scale
          level = level / self.__lastScale * scale;

          // Limit level according to configuration
          level = Math.max(Math.min(level, self.options.maxZoom), self.options.minZoom);

          // Only do further compution when change happened
          if (oldLevel !== level) {

            // Compute relative event position to container
            var currentTouchLeftRel = currentTouchLeft - self.__clientLeft;
            var currentTouchTopRel = currentTouchTop - self.__clientTop;

            // Recompute left and top coordinates based on new zoom level
            scrollLeft = ((currentTouchLeftRel + scrollLeft) * level / oldLevel) - currentTouchLeftRel;
            scrollTop = ((currentTouchTopRel + scrollTop) * level / oldLevel) - currentTouchTopRel;

            // Recompute max scroll values
            self.__computeScrollMax(level);

          }
        }

        if (self.__enableScrollX) {

          scrollLeft -= moveX;
          var maxScrollLeft = self.__maxScrollLeft;

          if (scrollLeft > maxScrollLeft || scrollLeft < 0) {

            // Slow down on the edges
            if (self.options.bouncing) {

              scrollLeft += (moveX / 2);

            } else if (scrollLeft > maxScrollLeft) {

              scrollLeft = maxScrollLeft;

            } else {

              scrollLeft = 0;

            }
          }
        }

        // Compute new vertical scroll position
        if (self.__enableScrollY) {

          scrollTop -= moveY;
          var maxScrollTop = self.__maxScrollTop;

          if (scrollTop > maxScrollTop || scrollTop < 0) {

            // Slow down on the edges
            if (self.options.bouncing) {

              scrollTop += (moveY / 2);

              // Support pull-to-refresh (only when only y is scrollable)
              if (!self.__enableScrollX && self.__refreshHeight != null) {

                if (!self.__refreshActive && scrollTop <= -self.__refreshHeight) {

                  self.__refreshActive = true;
                  if (self.__refreshActivate) {
                    self.__refreshActivate();
                  }

                } else if (self.__refreshActive && scrollTop > -self.__refreshHeight) {

                  self.__refreshActive = false;
                  if (self.__refreshDeactivate) {
                    self.__refreshDeactivate();
                  }

                }
              }

            } else if (scrollTop > maxScrollTop) {

              scrollTop = maxScrollTop;

            } else {

              scrollTop = 0;

            }
          }
        }

        // Keep list from growing infinitely (holding min 10, max 20 measure points)
        if (positions.length > 60) {
          positions.splice(0, 30);
        }

        // Track scroll movement for decleration
        positions.push(scrollLeft, scrollTop, timeStamp);

        // Sync scroll position
        self.__publish(scrollLeft, scrollTop, level);

      // Otherwise figure out whether we are switching into dragging mode now.
      } else {

        var minimumTrackingForScroll = self.options.locking ? 3 : 0;
        var minimumTrackingForDrag = 5;

        var distanceX = Math.abs(currentTouchLeft - self.__initialTouchLeft);
        var distanceY = Math.abs(currentTouchTop - self.__initialTouchTop);

        self.__enableScrollX = self.options.scrollingX && distanceX >= minimumTrackingForScroll;
        self.__enableScrollY = self.options.scrollingY && distanceY >= minimumTrackingForScroll;

        positions.push(self.__scrollLeft, self.__scrollTop, timeStamp);

        self.__isDragging = (self.__enableScrollX || self.__enableScrollY) && (distanceX >= minimumTrackingForDrag || distanceY >= minimumTrackingForDrag);

      }

      // Update last touch positions and time stamp for next event
      self.__lastTouchLeft = currentTouchLeft;
      self.__lastTouchTop = currentTouchTop;
      self.__lastTouchMove = timeStamp;
      self.__lastScale = scale;

    },


    /**
     * Touch end handler for scrolling support
     */
    doTouchEnd: function(timeStamp) {

      if (timeStamp instanceof Date) {
        timeStamp = timeStamp.valueOf();
      }
      if (typeof timeStamp !== "number") {
        throw new Error("Invalid timestamp value: " + timeStamp);
      }

      var self = this;

      // Ignore event when tracking is not enabled (no touchstart event on element)
      // This is required as this listener ('touchmove') sits on the document and not on the element itself.
      if (!self.__isTracking) {
        return;
      }

      // Not touching anymore (when two finger hit the screen there are two touch end events)
      self.__isTracking = false;

      // Be sure to reset the dragging flag now. Here we also detect whether
      // the finger has moved fast enough to switch into a deceleration animation.
      if (self.__isDragging) {

        // Reset dragging flag
        self.__isDragging = false;

        // Start deceleration
        // Verify that the last move detected was in some relevant time frame
        if (self.__isSingleTouch && self.options.animating && (timeStamp - self.__lastTouchMove) <= 100) {

          // Then figure out what the scroll position was about 100ms ago
          var positions = self.__positions;
          var endPos = positions.length - 1;
          var startPos = endPos;

          // Move pointer to position measured 100ms ago
          for (var i = endPos; i > 0 && positions[i] > (self.__lastTouchMove - 100); i -= 3) {
            startPos = i;
          }

          // If start and stop position is identical in a 100ms timeframe,
          // we cannot compute any useful deceleration.
          if (startPos !== endPos) {

            // Compute relative movement between these two points
            var timeOffset = positions[endPos] - positions[startPos];
            var movedLeft = self.__scrollLeft - positions[startPos - 2];
            var movedTop = self.__scrollTop - positions[startPos - 1];

            // Based on 50ms compute the movement to apply for each render step
            self.__decelerationVelocityX = movedLeft / timeOffset * (1000 / 60);
            self.__decelerationVelocityY = movedTop / timeOffset * (1000 / 60);

            // How much velocity is required to start the deceleration
            var minVelocityToStartDeceleration = self.options.paging || self.options.snapping ? 4 : 1;

            // Verify that we have enough velocity to start deceleration
            if (Math.abs(self.__decelerationVelocityX) > minVelocityToStartDeceleration || Math.abs(self.__decelerationVelocityY) > minVelocityToStartDeceleration) {

              // Deactivate pull-to-refresh when decelerating
              if (!self.__refreshActive) {

                self.__startDeceleration(timeStamp);

              }
            }
          }
        }
      }

      // If this was a slower move it is per default non decelerated, but this
      // still means that we want snap back to the bounds which is done here.
      // This is placed outside the condition above to improve edge case stability
      // e.g. touchend fired without enabled dragging. This should normally do not
      // have modified the scroll positions or even showed the scrollbars though.
      if (!self.__isDecelerating) {

        if (self.__refreshActive && self.__refreshStart) {

          // Use publish instead of scrollTo to allow scrolling to out of boundary position
          // We don't need to normalize scrollLeft, zoomLevel, etc. here because we only y-scrolling when pull-to-refresh is enabled
          self.__publish(self.__scrollLeft, -self.__refreshHeight, self.__zoomLevel, true);

          if (self.__refreshStart) {
            self.__refreshStart();
          }

        } else {

          self.scrollTo(self.__scrollLeft, self.__scrollTop, true, self.__zoomLevel);

          // Directly signalize deactivation (nothing todo on refresh?)
          if (self.__refreshActive) {

            self.__refreshActive = false;
            if (self.__refreshDeactivate) {
              self.__refreshDeactivate();
            }

          }
        }
      }

      // Fully cleanup list
      self.__positions.length = 0;

    },



    /*
    ---------------------------------------------------------------------------
      PRIVATE API
    ---------------------------------------------------------------------------
    */

    /**
     * Applies the scroll position to the content element
     *
     * @param left {Number} Left scroll position
     * @param top {Number} Top scroll position
     * @param animate {Boolean?false} Whether animation should be used to move to the new coordinates
     */
    __publish: function(left, top, zoom, animate) {

      var self = this;

      // Remember whether we had an animation, then we try to continue based on the current "drive" of the animation
      var wasAnimating = self.__isAnimating;
      if (wasAnimating) {
        core.effect.Animate.stop(wasAnimating);
        self.__isAnimating = false;
      }

      if (animate && self.options.animating) {

        // Keep scheduled positions for scrollBy/zoomBy functionality
        self.__scheduledLeft = left;
        self.__scheduledTop = top;
        self.__scheduledZoom = zoom;

        var oldLeft = self.__scrollLeft;
        var oldTop = self.__scrollTop;
        var oldZoom = self.__zoomLevel;

        var diffLeft = left - oldLeft;
        var diffTop = top - oldTop;
        var diffZoom = zoom - oldZoom;

        var step = function(percent, now, render) {

          if (render) {

            self.__scrollLeft = oldLeft + (diffLeft * percent);
            self.__scrollTop = oldTop + (diffTop * percent);
            self.__zoomLevel = oldZoom + (diffZoom * percent);

            // Push values out
            if (self.__callback) {
              self.__callback(self.__scrollLeft, self.__scrollTop, self.__zoomLevel);
            }

          }
        };

        var verify = function(id) {
          return self.__isAnimating === id;
        };

        var completed = function(renderedFramesPerSecond, animationId, wasFinished) {
          if (animationId === self.__isAnimating) {
            self.__isAnimating = false;
          }

          if (self.options.zooming) {
            self.__computeScrollMax();
          }
        };

        // When continuing based on previous animation we choose an ease-out animation instead of ease-in-out
        self.__isAnimating = core.effect.Animate.start(step, verify, completed, 250, wasAnimating ? easeOutCubic : easeInOutCubic);

      } else {

        self.__scheduledLeft = self.__scrollLeft = left;
        self.__scheduledTop = self.__scrollTop = top;
        self.__scheduledZoom = self.__zoomLevel = zoom;

        // Push values out
        if (self.__callback) {
          self.__callback(left, top, zoom);
        }

        // Fix max scroll ranges
        if (self.options.zooming) {
          self.__computeScrollMax();
        }
      }
    },


    /**
     * Recomputes scroll minimum values based on client dimensions and content dimensions.
     */
    __computeScrollMax: function(zoomLevel) {

      var self = this;

      if (zoomLevel == null) {
        zoomLevel = self.__zoomLevel;
      }

      self.__maxScrollLeft = Math.max((self.__contentWidth * zoomLevel) - self.__clientWidth, 0);
      self.__maxScrollTop = Math.max((self.__contentHeight * zoomLevel) - self.__clientHeight, 0);

    },



    /*
    ---------------------------------------------------------------------------
      ANIMATION (DECELERATION) SUPPORT
    ---------------------------------------------------------------------------
    */

    /**
     * Called when a touch sequence end and the speed of the finger was high enough
     * to switch into deceleration mode.
     */
    __startDeceleration: function(timeStamp) {

      var self = this;

      if (self.options.paging) {

        var scrollLeft = Math.max(Math.min(self.__scrollLeft, self.__maxScrollLeft), 0);
        var scrollTop = Math.max(Math.min(self.__scrollTop, self.__maxScrollTop), 0);
        var clientWidth = self.__clientWidth;
        var clientHeight = self.__clientHeight;

        // We limit deceleration not to the min/max values of the allowed range, but to the size of the visible client area.
        // Each page should have exactly the size of the client area.
        self.__minDecelerationScrollLeft = Math.floor(scrollLeft / clientWidth) * clientWidth;
        self.__minDecelerationScrollTop = Math.floor(scrollTop / clientHeight) * clientHeight;
        self.__maxDecelerationScrollLeft = Math.ceil(scrollLeft / clientWidth) * clientWidth;
        self.__maxDecelerationScrollTop = Math.ceil(scrollTop / clientHeight) * clientHeight;

      } else {

        self.__minDecelerationScrollLeft = 0;
        self.__minDecelerationScrollTop = 0;
        self.__maxDecelerationScrollLeft = self.__maxScrollLeft;
        self.__maxDecelerationScrollTop = self.__maxScrollTop;

      }

      // Wrap class method
      var step = function(percent, now, render) {
        self.__stepThroughDeceleration(render);
      };

      // How much velocity is required to keep the deceleration running
      var minVelocityToKeepDecelerating = self.options.snapping ? 4 : 0.1;

      // Detect whether it's still worth to continue animating steps
      // If we are already slow enough to not being user perceivable anymore, we stop the whole process here.
      var verify = function() {
        return Math.abs(self.__decelerationVelocityX) >= minVelocityToKeepDecelerating || Math.abs(self.__decelerationVelocityY) >= minVelocityToKeepDecelerating;
      };

      var completed = function(renderedFramesPerSecond, animationId, wasFinished) {
        self.__isDecelerating = false;

        // Animate to grid when snapping is active, otherwise just fix out-of-boundary positions
        self.scrollTo(self.__scrollLeft, self.__scrollTop, self.options.snapping);
      };

      // Start animation and switch on flag
      self.__isDecelerating = core.effect.Animate.start(step, verify, completed);

    },


    /**
     * Called on every step of the animation
     *
     * @param inMemory {Boolean?false} Whether to not render the current step, but keep it in memory only. Used internally only!
     */
    __stepThroughDeceleration: function(render) {

      var self = this;


      //
      // COMPUTE NEXT SCROLL POSITION
      //

      // Add deceleration to scroll position
      var scrollLeft = self.__scrollLeft + self.__decelerationVelocityX;
      var scrollTop = self.__scrollTop + self.__decelerationVelocityY;


      //
      // HARD LIMIT SCROLL POSITION FOR NON BOUNCING MODE
      //

      if (!self.options.bouncing) {

        var scrollLeftFixed = Math.max(Math.min(self.__maxScrollLeft, scrollLeft), 0);
        if (scrollLeftFixed !== scrollLeft) {
          scrollLeft = scrollLeftFixed;
          self.__decelerationVelocityX = 0;
        }

        var scrollTopFixed = Math.max(Math.min(self.__maxScrollTop, scrollTop), 0);
        if (scrollTopFixed !== scrollTop) {
          scrollTop = scrollTopFixed;
          self.__decelerationVelocityY = 0;
        }

      }


      //
      // UPDATE SCROLL POSITION
      //

      if (render) {

        self.__publish(scrollLeft, scrollTop, self.__zoomLevel);

      } else {

        self.__scrollLeft = scrollLeft;
        self.__scrollTop = scrollTop;

      }


      //
      // SLOW DOWN
      //

      // Slow down velocity on every iteration
      if (!self.options.paging) {

        // This is the factor applied to every iteration of the animation
        // to slow down the process. This should emulate natural behavior where
        // objects slow down when the initiator of the movement is removed
        var frictionFactor = 0.95;

        self.__decelerationVelocityX *= frictionFactor;
        self.__decelerationVelocityY *= frictionFactor;

      }


      //
      // BOUNCING SUPPORT
      //

      if (self.options.bouncing) {

        var scrollOutsideX = 0;
        var scrollOutsideY = 0;

        // This configures the amount of change applied to deceleration/acceleration when reaching boundaries
        var penetrationDeceleration = 0.03;
        var penetrationAcceleration = 0.08;

        // Check limits
        if (scrollLeft < self.__minDecelerationScrollLeft) {
          scrollOutsideX = self.__minDecelerationScrollLeft - scrollLeft;
        } else if (scrollLeft > self.__maxDecelerationScrollLeft) {
          scrollOutsideX = self.__maxDecelerationScrollLeft - scrollLeft;
        }

        if (scrollTop < self.__minDecelerationScrollTop) {
          scrollOutsideY = self.__minDecelerationScrollTop - scrollTop;
        } else if (scrollTop > self.__maxDecelerationScrollTop) {
          scrollOutsideY = self.__maxDecelerationScrollTop - scrollTop;
        }

        // Slow down until slow enough, then flip back to snap position
        if (scrollOutsideX !== 0) {
          if (scrollOutsideX * self.__decelerationVelocityX <= 0) {
            self.__decelerationVelocityX += scrollOutsideX * penetrationDeceleration;
          } else {
            self.__decelerationVelocityX = scrollOutsideX * penetrationAcceleration;
          }
        }

        if (scrollOutsideY !== 0) {
          if (scrollOutsideY * self.__decelerationVelocityY <= 0) {
            self.__decelerationVelocityY += scrollOutsideY * penetrationDeceleration;
          } else {
            self.__decelerationVelocityY = scrollOutsideY * penetrationAcceleration;
          }
        }
      }
    }
  };

  // Copy over members to prototype
  for (var key in members) {
    Scroller.prototype[key] = members[key];
  }

})();
/* global jQuery */
/* global Raphael */
/* global qtip*/

(function( $ ){
  'use strict';
  var site_url = document.location.origin + '/',
  pathname = document.location.pathname,
  reg =/Tools\/hmmer/,
  match = pathname.match(reg);

  if(match){
    site_url = document.location.origin +'/Tools/hmmer/';
  }
   $.fn.drawDistributionTree = function (tree, top_node_id, options) {
    function TaxTree(target, tree, top_node_id, options) {
      this.options = $.extend({}, this.defaults, options);
      this.tree = tree;
      this.container = target;
      this.drawTaxonTreeFromNode(top_node_id || 0);
    }

    TaxTree.prototype.defaults = {
      'width': 800,
      'height': 165,
      'depth': 2,
      'line_color': '#900',
      'arrow_color': '#aaa',
      'radius': 6
    };

    TaxTree.prototype.drawTaxonTreeFromNode = function (ncbi) {
      var node = this.findNode(ncbi);
      var row_count;
      var dimensions;

      if (node) {
        //work out canvas height
        row_count = this.countRows(node);
        dimensions = this.calculateDimensions(row_count);

        if ($(this.container).children().length > 0) {
          $(this.container).children().remove();
        }

        this.canvas = new Raphael(this.container.get(0), dimensions.width, dimensions.height);

        if (node.parent || node.parent === 0) {
          this.drawReverseArrow(node);
          this.drawBreadCrumbTrail(node, tree);
        }

        this.drawNodes(node);
        this.showOrHideTableRows(node);
        this.renderTitle();
      }

      return this;
    };


    TaxTree.prototype.renderTitle = function () {
      $(this.container).prepend('<h5 class="centered">Taxonomic distribution of hits in representative proteomes <a id="taxtreehelp" href="'+site_url+'/help/result#disttree") %]"><img src="'+site_url+'/static/images/help.gif"/></a></h5><div class="help">This species tree shows all the sequence hits distributed across a tree derived from the set of representative proteomes.</div>');
      $(this.container).find('h5 a').tooltip('above');
    };

    TaxTree.prototype.findNode = function (ncbi, current_node) {
      var child;
      var target_node;
      //init current_node if not passed in
      if (current_node === undefined) {
        current_node = this.tree;
      }

      //check if we have found our node
      if (parseInt(current_node.ncbi,10) === parseInt(ncbi,10)) {
        return current_node;
      }

      for (child in current_node.children) {
        target_node = this.findNode(ncbi, current_node.children[child]);
        if (target_node) {return target_node;}
      }

      return; //should only get here if ncbi not found
    };

    TaxTree.prototype.calculateDimensions = function (row_count) {
      var height = (row_count * 40 ) + 45;
      if (height < this.options.height) {
        height = this.options.height;
      }

      return {'height': height, 'width': this.options.width};
    };

    TaxTree.prototype.countRows = function (node) {
      var that = this;
      var row_count = 1;
      var col_count = 1;

      //logic extracted to function for recursion
      var count_child_column = function (node) {
        var child;

        if (node.children && (col_count <= that.options.depth)) {
          col_count++;
          row_count = row_count + node.children.length -1; //-1 to account for first child being on same row
          for (child in node.children) {
            count_child_column(node.children[child]);
          }
          col_count--;
        }
      };

      count_child_column(node);
      return row_count;
    };

    TaxTree.prototype.drawBreadCrumbTrail = function (node) {
      var that = this;
      var parents = [];

      //logic moved to function for recursion
      var findParents = function(node) {
        var this_parent;
        if (node.parent || parseInt(node.parent,10) === 0) {
          this_parent = that.findNode(node.parent);
          parents.unshift({'name':this_parent['short'], 'ncbi':this_parent.ncbi});
          findParents(this_parent);
        }
      };

      var renderParent = function(parent, x, y) {
        var t = that.canvas.text(x, y, parent.name + ' /')
          .attr({'text-anchor': 'start'})
          .click($.proxy(function () {
            this.canvas.clear();
            this.drawTaxonTreeFromNode(parent.ncbi);
            window.scrollTo(0,0);
          }, that));
        that.canvas.rect(x, y - (t.getBBox().height / 2), t.getBBox().width, t.getBBox().height)
          .attr({'stroke':'none'})
          .click($.proxy(function () {
            this.canvas.clear();
            this.drawTaxonTreeFromNode(parent.ncbi);
            window.scrollTo(0,0);
        }, that));
        return t;
      };

      findParents(node);

      //for each entry in parents draw breadcrumb trail
      var x = 0, y = 10;
      for (var i = 0; i < parents.length; i++) {
        var t = renderParent(parents[i], x, y);
        var width = t.getBBox().width + 5;
        if ((x + width) > this.canvas.width) {
          //breadcrumb line == too long, need to wrap.
          x = 10;
          y += 12;
          t.remove();
          t = renderParent(parents[i], x, y);
          width = t.getBBox().width + 5;
        }
        x += width;
      }
    };

    TaxTree.prototype.drawReverseArrow = function (node) {
      var arrowPath = 'M20 29l40 0c5 0 5 12 0 12l-40 0l0 3l-15 -9l15 -9l0 3';
      var st = this.canvas.set();
      var ar = this.canvas.path(arrowPath)
        .attr({stroke: '#aaa', fill: this.options.arrow_color});
      var tbox = this.canvas.rect(17, 31, 45, 8, 4)
            .attr({stroke:'none',fill:'#fff'});
      var label = this.canvas.text(39, 35, 'back');
      st.push(ar, tbox, label)
        .click($.proxy(function () {
          this.canvas.clear();
          this.drawTaxonTreeFromNode(node.parent, this.canvas);
          window.scrollTo(0,0);
        }, this));
    };

    TaxTree.prototype.drawNodes = function (node) {
      var that = this;
      var row=0;
      var layoutNodes = function(node, col, parentGlyph){
        if (col === undefined) { col = 0;}

        if (col <= that.options.depth) {
          var x = (col * 160) + 70;
          var y = (row * 40) + 35;
          var glyph = renderNode(node, x, y);

          if (node.children === undefined || col === that.options.depth) {
            row++;
          }

          //draw pie chart
          var chart = $(that.canvas.pieChart(x + glyph.getBBox().width + 10, y, that.options.radius, node.count));
          var breakdown_html = '<table>' +
            '<tr><th rowspan="2">Query found in:</th><th colspan="2">Not found in:</th></tr>' +
            '<tr><th>Complete</th><th>Incomplete</th></tr>' +
            '<tr><td><span class="dist-found">' + node.count[0] + '</span></td>' +
            '<td><span class="dist-complete">' + node.count[1] + '</span></td>' +
            '<td><span class="dist-incomplete">' + node.count[2] + '</span></td></tr>' +
            '</table>';

          if (node.truncated) {
            breakdown_html = breakdown_html + "<br/><p><b>There were no matches past this point so the tree has been truncated.</b><p>";
          }

          breakdown_html = breakdown_html + '</div>'
          for (var i=0; i< chart.length; i++) {
            $(chart[i].node).qtip({position: {
                my: 'bottom center',
                at: 'top center'
              },
              content: {
                title: node.count[0] + node.count[1] + node.count[2] + ' proteomes at this taxonomic level.',
                text:  breakdown_html
              },
              style: {
                classes: 'ui-tooltip-hmmerdisttree ui-tooltip-rounded'
              }
            });
          }

          // draw the "more" arrows
          if (col === that.options.depth && node.children) {
            drawArrow(node,glyph,x,y);
          }

          if (parentGlyph) {
            linkNodes(parentGlyph, glyph);
          }

          if (node.children) {
            for (var i = 0; i < node.children.length; i++) {
              layoutNodes(node.children[i], col + 1, glyph);
            }
          }
        }
      };

      var renderNode = function(node, x, y) {
        var t = that.canvas.text(x, y, node['short']).attr({'text-anchor': 'start'})
          .click($.proxy(function () {
            that.canvas.clear();
            that.drawTaxonTreeFromNode(node.ncbi);
            window.scrollTo(0,0);
          }, that));

        // if name + node count  > col_width and it has children
        // then truncate it.
        var labelWidth = t.getBBox().width;
        if(labelWidth > 120 && node.children) {
          // work out the percentage of the label that will fit into the
          // desired width
          var percent =  120 / labelWidth;
          // split the label into an array
          var textArray = node['short'].split('');
          // grab the section of the array that is equal to the previously
          // defined percentage minus some additional space for numbers and the
          // ellipse.
          var ellipsedText = textArray.slice(0, (textArray.length * percent) - 6).join('') + '...';
          // replace the text that is too long with the truncated text.
          t.attr('text', ellipsedText);
        }

        that.canvas.rect(x, y - (t.getBBox().height / 2), t.getBBox().width + 30, t.getBBox().height)
          .attr({'stroke':'none'})
          .click($.proxy(function () {
            that.canvas.clear();
            that.drawTaxonTreeFromNode(node.ncbi);
            window.scrollTo(0,0);
          }, that));

        return t;
      };

      var drawArrow = function(node, glyph, x , y) {
        var st = that.canvas.set();
        var offset = x + glyph.getBBox().width + 10 + that.options.radius + 10;
        var arrowPath = 'M' + (offset) + ' ' + (y - 6) + 'l40 0l0 -3l15 9l-15 9l0 -3l-40 0 c-5 0 -5 -12 0 -12';
        var moreCount = that.countLeafNodes(node);
        st.push(
          that.canvas.path(arrowPath)
            .attr({stroke: '#aaa', fill: that.options.arrow_color}),
          that.canvas.rect((offset), (y - 4), 45, 8, 4)
            .attr({stroke:'none',fill:'#fff'}),
          that.canvas.text((offset + 20), (y), moreCount)
        ).click(function () {
          that.canvas.clear();
          that.drawTaxonTreeFromNode(node.ncbi);
          window.scrollTo(0,0);
        });
      };

      var linkNodes = function (parent, child) {
        var px  = parent.attrs.x + (parent.getBBox().width) + 5 + that.options.radius +10;
        var cx  = child.attrs.x - 2;
        var cy1 = parseInt(parent.attrs.y);
        var cy2 = parseInt(child.attrs.y);
        var cx1 = parseInt(((cx - px) / 2) + px);
        var cx2 = cx1;

        var path = 'M' + px + ' ' + parent.attrs.y + 'C' + cx1 + ' ' + cy1 + ' ' + cx2 + ' ' + cy2 + ' '  + cx + ' ' + child.attrs.y;
        that.canvas.path(path).attr({stroke: that.options.line_color});
      };

      layoutNodes(node);
    };

    TaxTree.prototype.countLeafNodes = function (node) {
      var count = 0;
      var child;
      if (node.children) {
        for (child in node.children) {
          count = count + this.countLeafNodes(node.children[child]);
        }
      } else {
        count = 1;
      }
      return count;
    };

      TaxTree.prototype.showOrHideTableRows = function(node) {
        // Change the taxid variable in the restrict_all form to equal
        // the new max for this node
        var link = $('.dl_phmmer').attr('href');
        var score_link = window.location.href;

        // if score_link ends with taxonomy, strip it
        score_link = score_link.replace(/\/taxonomy[\/]?$/, '');

        if (node.ncbi > 1) {

          score_link = score_link + '/taxonomy/' + node.ncbi;

          // change the taxid in the download link to equal the new root
          if (link.match(/taxon\//)) {
            link = link.replace(/taxon\/\d*/, 'taxon/' + node.ncbi);
          }
          else {
            link = link + '/taxon/' + node.ncbi;
          }
        }
        else {
          link = link.replace(/\/taxon\/\d*/, '');
        }
        $('.dl_phmmer').attr('href', link);

        score_link = score_link + '/score';
        $('#taxon_link').attr('href', score_link);

        var species = {};
        // recurse through tree below current node and add species leaves
        // to the species hash.
        this.findAllLeafNodeTaxIds(node, species);
        // then use that array to loop over the table and hide rows that
        // don't have a tax id in the species hash.
        $('.resultTable tbody tr').each(function() {
          var row = $(this);
          if (species[row.attr('id')]) {
            row.show();
          }
          else {
            row.hide();
          }
        });
      };

      TaxTree.prototype.findAllLeafNodeTaxIds = function (node, hashObj) {
        if (node.children) { // not a leaf node, keep going
          for (var i = 0; i < node.children.length; i++) {
            this.findAllLeafNodeTaxIds(node.children[i], hashObj);
          }
        }
        else {
          hashObj['taxon_' + node.ncbi] = 1;
        }
      };

    new TaxTree(this, tree, top_node_id, options);
   };

})( jQuery );
function PfamGraphic(parent, sequence) {
  this._middleClickListenerAdded = false;

  this._imageParams = {
    headSizeCircle:  3,
    headSizeSquare:  6,
    headSizeDiamond: 4,
    headSizeArrow:   3,
    headSizePointer: 3,
    headSizeLine:    3,

    sequenceEndPadding: 2,

    xOffset: 0,
    yOffset: 0,

    defaultMarkupHeight:         20,
    lollipopToLollipopIncrement: 7,
    bridgeToBridgeIncrement:     2,
    bridgeToLollipopIncrement:   5,
    largeJaggedSteps:            6,

    fontSize: "10px",

    regionHeight:    20,
    motifHeight:     14,
    motifOpacity:    0.6,
    labelPadding:    3,
    residueWidth:    0.5,
    xscale:          1.0,
    yscale:          1.0,
    envOpacity:      0.6,
    highlightWeight: 1,
    highlightColour: "#000000"
  };

  this._options = {
    baseUrl:   "",
    imageMap:  true,
    labels:    true,
    tips:      true,
    tipStyle:  "pfam",
    newCanvas: true
  };

  this._markupSpec = {
    valignValues:       ['top', 'bottom'],
    linesStyleValues:   ['mixed', 'bold', 'dashed'],
    lollipopHeadValues: ['diamond', 'circle', 'square', 'arrow', 'pointer', 'line'],
    regionEndValues:    ['curved', 'straight', 'jagged', 'arrow']
  };

  this._heights = {};
  this._areasHash = {};
  this._cache = {};
  this._saveLevel = 0;
  this._rendered_regions = {};
  this._highlighted = {};

  // support functions

  this._parseInt = function( value ) {
    if (value === undefined) {
      return;
    }
    var num = parseInt(value, 10);
    return (num !== "NaN") ? num : value;
  };

  this.capitalize = function (word) {
    return word.charAt(0).toUpperCase() + word.substring(1).toLowerCase();
  };

  this._getRGBColour = function (hexString) {

    var longHexMatches  = /^#?([A-F0-9]{6})$/i.exec(hexString),
      shortHexMatches = /^#?([A-F0-9]{3})$/i.exec(hexString),
      h, r, g, b, rgb;

    if ( longHexMatches === null && shortHexMatches === null ) {
      this._throw( "not a valid hex color ('" + hexString + "')" );
    }

    if ( longHexMatches !== null ) {
      h = longHexMatches[1];
      r = parseInt( h.substring( 0, 2 ), 16 );
      g = parseInt( h.substring( 2, 4 ), 16 );
      b = parseInt( h.substring( 4, 6 ), 16 );
    } else if ( shortHexMatches !== null ) {
      h = shortHexMatches[1];
      r = parseInt( "" + h.substring( 0, 1 ) + h.substring( 0, 1 ), 16 );
      g = parseInt( "" + h.substring( 1, 2 ) + h.substring( 1, 2 ), 16 );
      b = parseInt( "" + h.substring( 2, 3 ) + h.substring( 2, 3 ), 16 );
    }

    rgb = [ r, g, b ];
    rgb.r = r;
    rgb.g = g;
    rgb.b = b;

    return rgb;
  };

  // end support functions

  this.setParent = function( parent ) {
    this._parent = $(parent);

    if ( !this._parent.length ) {
      this._throw( "couldn't find the parent node" );
    }

    return this;
  };

  if ( parent !== undefined ) {
    this.setParent( parent );
  }

  this._walkSequence = function() {
    var self = this;
    var s = this._sequence;
    s.length = this._parseInt( s.length );
    $.each([ s.motifs, s.regions, s.markups ], function( j ) {
       $.each(this, function(i) {
         this.start    = self._parseInt( this.start );
         this.end      = self._parseInt( this.end );
         this.aliStart = self._parseInt( this.aliStart );
         this.aliEnd   = self._parseInt( this.aliEnd );
       });
    });
  };

  this._buildMarkups = function() {
    var self = this;

    var heights = { lollipops: { up:   [],
                                 down: [],
                                 markups: [],
                                 downMax: 0,
                                 upMax: 0 },
                    bridges:   { up:   [],
                                 down: [],
                                 markups: [],
                                 downMax: 0,
                                 upMax: 0 } },
        bridgeMarkups   = [],
        ip              = this._imageParams,
        ms              = this._markupSpec;

    var orderedMarkups = [];
    $.each(this._sequence.markups, function(i, markup ) {

      var start = Math.floor( markup.start );
      if ( start === "NaN" ) {
        this._throw( "markup start position is not a number: '" +
                     markup.start + "'" );
      }

      if ( orderedMarkups[markup.start] === undefined ) {
        orderedMarkups[markup.start] = [];
      }

      orderedMarkups[markup.start].push( markup );
    });

    orderedMarkups = $.map(orderedMarkups, function(i) {
          return i;
        });

    var residueWidth = this._imageParams.residueWidth;

    $.each(orderedMarkups, function( i, markup ) {

      var start = Math.floor( markup.start );
      if ( start === "NaN" ) {
        this._throw( "markup start position is not a number: '" +
               markup.start + "'" );
      }

      if ( markup.end === undefined ) {
        heights.lollipops.markups.push( markup );
      } else {
        bridgeMarkups.push( markup );
        return;
      }

      if ( markup.v_align !== undefined &&
           $.inArray(markup.v_align, ms.valignValues) === -1) {
        this._throw( "markup 'v_align' value is not valid: '" +
                     markup.v_align + "'" );
      }

      if ( markup.headStyle !== undefined &&
           $.inArray(markup.headStyle, ms.lollipopHeadValues) === -1) {
        this._throw( "markup 'headStyle' value is not valid: '" +
                     markup.headStyle + "'" );
      }

      var up = ( markup.v_align === undefined || markup.v_align === "top" );

      var h = up ? heights.lollipops.up : heights.lollipops.down;

      if ( h[ start - ( 1 / residueWidth ) ] !== undefined ||
           h[ start                        ] !== undefined ||
           h[ start + ( 1 / residueWidth ) ] !== undefined ) {

        var firstLollipopHeight = Math.max.apply(Math, h.slice( start - ( 1 / residueWidth ),
                                           start + ( 1 / residueWidth ) ));
        h[ start ] = firstLollipopHeight + ip.lollipopToLollipopIncrement;

      } else {

        h[start] = ip.defaultMarkupHeight;

      }

      var headSize = ip["headSize" + self.capitalize(markup.headStyle)];

      if ( up ) {
        heights.lollipops.upMax = Math.max( h[start] + headSize,
                                            heights.lollipops.upMax );
      } else {
        heights.lollipops.downMax = Math.max( h[start] + headSize,
                                              heights.lollipops.downMax );
      }

    });

    $.each(bridgeMarkups, function(i, bridgeMarkup ) {


      var bridge = { markup: bridgeMarkup };

      heights.bridges.markups.push( bridge );

      var start = Math.floor( bridgeMarkup.start );
      if ( start === "NaN" ) {
        this._throw( "bridge start position is not a number: '" + bridgeMarkup.start + "'" );
      }

      var end = Math.floor( bridgeMarkup.end );
      if ( end === "NaN" ) {
        this._throw( "bridge end position is not a number: '" + bridgeMarkup.end + "'" );
      }

      bridge.up = ( bridgeMarkup.v_align === undefined || bridgeMarkup.v_align === "top" );
      var hl = bridge.up ? heights.lollipops.up : heights.lollipops.down,
          hb = bridge.up ? heights.bridges.up   : heights.bridges.down;

      var maxBridgeHeight = Math.max.apply(Math, $.map(hb.slice( start, end ), function (i) { return i }));
      var bridgeHeight = ip.defaultMarkupHeight;

      if ( maxBridgeHeight === -Infinity ) {
        //do nothing
      }
      else {
        if ( $.inArray( bridgeHeight, $.map(hb.slice( start, end ), function (i) { return i})) >= 0) {
          bridgeHeight = maxBridgeHeight + ip.bridgeToBridgeIncrement;
        }
      }

      var maxLollipopHeight = Math.max.apply(Math, hl.slice( start - 4, end + 4 ));

      if ( maxLollipopHeight !== undefined ) {
        if ( ( maxLollipopHeight + ip.bridgeToLollipopIncrement ) >= bridgeHeight ) {
          bridgeHeight = maxLollipopHeight + ip.bridgeToLollipopIncrement;
        }
      }

      bridge.height = bridgeHeight;

      for (var i= start; i <= end ;i++) {
        if ( hb[i] === undefined ) {
          hb[i] = [];
        }
        hb[i].push( bridgeHeight );
      }

      if ( bridge.up ) {
        heights.bridges.upMax = Math.max( bridgeHeight, heights.bridges.upMax ) + 2;
      } else {
        heights.bridges.downMax = Math.max( bridgeHeight, heights.bridges.downMax ) + 2;
      }

    });

    this._heights = heights;

  };

  this.setImageParams = function ( params ) {
    if ( params !== undefined ) {
      if ( typeof params !== "object" ) {
        this._throw( "'imageParams' must be a valid object" );
      }
      this._imageParams = $.extend( this._imageParams, params );
    }
  };

  this.setSequence = function( sequence ) {

    if ( typeof sequence !== "object" ) {
      this._throw( "must supply a valid sequence object" );
    }

    if ( sequence.length === undefined ) {
      this._throw( "must specify a sequence length" );
    }

    if ( isNaN( sequence.length ) ) {
      this._throw( "sequence length must be a valid number" );
    }

    if ( parseInt( sequence.length, 10 ) <= 0 ) {
      this._throw( "sequence length must be a positive integer" );
    }

    if ( sequence.regions !== undefined ) {
      if ( typeof sequence.regions !== "object" ) {
        this._throw( "'regions' must be a valid object" );
      }
    }
    else {
      sequence.regions = [];
    }

    if ( sequence.markups !== undefined ) {
      if ( typeof sequence.markups !== "object" ) {
        this._throw( "'markups' must be a valid object" );
      }
    }
    else {
      sequence.markups = [];
    }

    if ( sequence.motifs !== undefined ) {
      if ( typeof sequence.motifs !== "object" ) {
        this._throw( "'motifs' must be a valid object" );
      }
    }
    else {
      sequence.motifs = [];
    }

    if ( sequence.options !== undefined ) {
      if ( typeof sequence.options !== "object" ) {
        this._throw( "'options' must be a valid object" );
      }
      this._options = $.extend( this._options, sequence.options );
    }

    if ( sequence.imageParams !== undefined ) {
      if ( typeof sequence.imageParams !== "object" ) {
        this._throw( "'imageParams' must be a valid object" );
      }
      this.setImageParams( sequence.imageParams );
    }

    this._sequence = sequence;

    this._walkSequence();

    this._imageWidth = (this._sequence.length * this._imageParams.residueWidth) + this._imageParams.sequenceEndPadding;

    if (this._parent.width() < this._imageWidth) {
      this._imageWidth = this._parent.width();
    }

    this._regionHeight = this._imageParams.regionHeight;

    this._seqHeight = Math.round( this._regionHeight / 6 );

    this._seqStep   = Math.round( this._seqHeight / 5 );

    this._buildMarkups();

    this._canvasHeight = Math.max.apply(Math, [ this._heights.lollipops.upMax,
                           this._heights.bridges.upMax,
                           ( this._regionHeight / 2 + 1 ) ]) +
                         Math.max.apply(Math, [ this._heights.lollipops.downMax,
                           this._heights.bridges.downMax,
                           ( this._regionHeight / 2 + 1 ) ]) + 5;

    this._canvasHeight *= this._imageParams.yscale;

    if ( this._sequence.highlight !== undefined ) {
      this._canvasHeight += ( 5 + Math.ceil( this._imageParams.highlightWeight / 2 ) );
    }

    this._canvasWidth = this._imageWidth + 1 + (this._imageParams.sequenceEndPadding * 2);

    this._canvasWidth *= this._imageParams.xscale;

    this._baseline = Math.max.apply(Math, [ this._heights.lollipops.upMax,
                       this._heights.bridges.upMax,
                       this._imageParams.regionHeight / 2 ]) + 1;

    return this;
  };

  if ( sequence !== undefined ) {

    this.setSequence( sequence );
  }

  this._throw = function( message ) {
    throw { name: "PfamGraphicException",
            message: message,
            toString: function() { return this.message; } };
  };

  this.highlight = function(params) {
    // return unless we have a region name
    if ( params.uniq === undefined ) {
      return;
    }

    if (this._rendered_regions[params.uniq] === undefined) {
      return;
    }

    if ( params.status === undefined || params.status === 'on') {
      // highlight the named region
      if(!this._highlighted[params.uniq]) {
        this._highlighted[params.uniq] = [];
      }
      for (var i = 0; i < this._rendered_regions[params.uniq].length; i++) {
        this._highlighted[params.uniq][i] = this._rendered_regions[params.uniq][i].glow({width: 5, opacity:0.6});
      }
    }
    else {
      // turn off the highlight
      for (var i = 0; i < this._highlighted[params.uniq].length; i++) {
        this._highlighted[params.uniq][i].remove();
      }
      delete this._highlighted[params.uniq];
    }
  }

  this.render = function( parent, sequence ) {

    if ( sequence !== undefined ) {
      this.setSequence( sequence );
    }

    if ( parent !== undefined ) {
      this.setParent( parent );
    }

    if ( this._sequence === undefined ) {
      this._throw( "sequence was not supplied" );
    }

    if ( this._options.newCanvas &&
         this._parent === undefined ) {
      this._throw( "parent node was not supplied" );
    }

    if ( ( ! this._canvas ) || this._options.newCanvas ) {
      this._buildCanvas( this._canvasWidth, this._canvasHeight );
    }

    var all_elements = this._draw();
    this._drawTitle(all_elements);

    // draw the sliding marker
    var marker = this._canvas.rect(-100, 0, 1, this._canvas.height)
      .attr({"fill" : "#666666", "stroke-opacity" : 0});

    var self = this;
    function scale(coord, orig, desired) {
      var scaled = (desired * coord) / orig;
      return scaled;
    };

    this._parent.find('svg').on('coverage.move', function (e, position) {
      var seq_length_in_px = (self._canvas.width - 100) - (self._labelWidth + 7);
      var x = Math.round(scale(position, self._sequence.length, seq_length_in_px ) + 100);
      marker.attr({x: x});
    });
    // end the sliding marker

    return this;
  };

  this._drawTitle = function (graphics) {
    if (this._sequence.title === undefined) {
      return;
    }
    //shift all the graphics to the right
    graphics.transform("t100,0");
    this._canvas.setSize(this._canvas.width + 100, this._canvas.height);
    this._canvas.text(50, (this._canvas.height / 2) - 2, this._sequence.title);
  };

  this.resize = function(width, height) {

    if (width > this._canvasWidth) {
      return;
    }

    if(!width) {
      width = this._canvasWidth;
    }
    if (!height) {
      height = this._canvasHeight;
    }

    var seq_length = this._sequence.length * this._imageParams.residueWidth;

    if (this._sequence.title) {
      seq_length = seq_length + 100;
    }

    if (this._labelWidth) {
      seq_length = seq_length + this._labelWidth + 5;
    }

    this._canvas.setSize(width, height);
    this._canvas.setViewBox(0, 0, seq_length, height);
    return this;
  }

  this._buildCanvas = function( width, height ) {
    var wrapperDiv = this._parent.closest("div");
    if ( wrapperDiv && width > wrapperDiv.scrollWidth ) {
      this._parent.addClassName( "canvasScroller" );
    }

    var canvas = Raphael(this._parent.get(0), width, height);

    this._canvas = canvas;

    if ( this._canvas === undefined || this._canvas === null ) {
      this._throw( "couldn't find the canvas node" );
    }

    this._areasList = [];

    return this;
  };

  this._drawRegion = function( region ) {

    if ($.inArray(region.startStyle, this._markupSpec.regionEndValues) === -1) {
      this._throw( "region start style is not valid: '" + region.startStyle + "'" );
    }

    if ($.inArray(region.endStyle, this._markupSpec.regionEndValues) === -1) {
      this._throw( "region end style is not valid: '" + region.endStyle + "'" );
    }

    var height = Math.floor( this._regionHeight ) - 2,
        radius = Math.round( height / 2 ),
        arrow  = radius,
        width  = ( region.end - (region.start + 1) ) * this._imageParams.residueWidth + 1,

        x = Math.max( 1, Math.floor( region.start * this._imageParams.residueWidth )),
        y = Math.floor( this._baseline - radius ) + 0.5;


    if ((arrow * 2) > width) {
      arrow = (width/2);
      radius = arrow;
    }

    var  regionParams = {
          x: x,
          y: y,
          w: width,
          h: height,
          r: radius,
          a: arrow,
          s: region.startStyle,
          e: region.endStyle
        };


    var path = this._buildRegionPath( regionParams, region);

    var fill = "90-#fff-" + region.color + ":50-" + region.color+ ":70-#fff";
    var glyph = this._canvas.path(path).attr({stroke: region.color, fill: fill});

    if (region.metadata) {

      if (!this._rendered_regions[region.metadata._uniq]) {
        this._rendered_regions[region.metadata._uniq] = [];
      }

      this._rendered_regions[region.metadata._uniq].push(glyph);
    }

    var areas;
    if ( region.aliStart !== undefined && region.aliEnd !== undefined ) {
      areas = this._drawEnvelope( region, radius, height );
    }

    if ( this._options.labels ) {
      this._drawText( x, this._baseline, width, region.text );
    }

    var area = this._canvas.rect(x,y,width,height).attr({opacity: 0, fill: '#000'});

    this._buildTip( region, area );

  };

  this._buildTip = function( item, glyph, type) {
    if ($.fn.qtip === undefined) return;

    if ( item.metadata === undefined ) {
      return;
    }

    var md = item.metadata;

    var tipTitle;
    if ( md.accession !== undefined && md.identifier !== undefined ) {
      tipTitle = md.identifier + " (" + md.accession.toUpperCase() + ")";
    } else if ( md.identifier !== undefined ) {
      tipTitle = md.identifier;
    } else if ( md.accession !== undefined ) {
      tipTitle = md.accession.toUpperCase();
    } else {
      tipTitle = md.type;
    }

    var coords = '<span class="inactive">n/a</span>';
    if ( md.start !== undefined && md.end !== undefined ) {
      coords = md.start + " - " + md.end;
      if ( md.aliStart !== undefined && md.aliEnd !== undefined ) {
        coords = coords.concat( " (alignment region " + md.aliStart + " - " + md.aliEnd + ")" );
      }
    }

    var desc = ( md.description || '<span class="inactive">n/a</span>' );
    if (md.accession) {
      desc = desc + ' [<a href="' + item.href  + '" class="ext">' + md.database + '</a>]';
    }
    if (type && type === 'motif') {
      if (md.href) {
        desc = md.description + ' [<a href="' + md.href + '" class="ext">' + md.src + '</a>]';
      }
    }

    var model = null;

    if (item.modelStart) {
      // work out the width of the match
      var match_width = item.modelEnd - item.modelStart + 1;
      var scaled_match_width = (match_width * 200) / item.modelLength;
      // work out the start
      var scaled_start = (item.modelStart - 1) / (item.modelLength / 200) ;
      var match = '<span style="width:' + scaled_match_width + 'px;background: '+
        item.color +';left:' + scaled_start + 'px"></span>';

      model = '1 <span class="model_position">' +  match  + '</span> ' + item.modelLength;
    }


    var tipBody = '    <dt>Description:</dt>' +
      '    <dd>' + desc  +'</dd>' +
      '    <dt>Coordinates:</dt>' +
      '    <dd>' + coords + '</dd>';

    if (model) {
      tipBody = tipBody +  '<dt>Model Match:</dt><dd>' + model + '</dd>';
    }

    tipBody = '<div class="tipContent"><dl>' + tipBody + '  </dl></div>';
    $(glyph.node).qtip({
      position: {
        viewport: $(window),
        my: 'bottom center',
        at: 'top center'
      },
      content: {
        title: tipTitle,
        text: tipBody
      },
      show: {
        solo: true
      },
      hide: {
        event: 'unfocus',
        inactive: 2000
      },
      style: {
        classes: 'ui-tooltip-hmmer ui-tooltip-rounded'
      }
    });
  }
  this._drawText = function( x, midpoint, regionWidth, text ) {

    var textX = x + ( regionWidth / 2 );
    var ts = this._canvas.text( textX, midpoint, text)
              .attr({stroke: '#eee', 'stroke-width': 2, 'stroke-opacity': 0.7});

    var bbox = ts.getBBox();

    if (bbox.width > regionWidth || bbox.height > this._regionHeight ) {
      ts.remove();
    }
    else {
      var t = this._canvas.text( textX, midpoint, text);
    }

  };

  this._drawEnvelope = function( region, radius, height ) {

    if ( parseInt( region.start, 10 ) > parseInt( region.aliStart, 10 ) ) {
      this._throw( "regions must have start <= aliStart (" + region.start + " is > " + region.aliStart + ")" );
    }

    if ( parseInt( region.end, 10 ) < parseInt( region.aliEnd, 10 ) ) {
      this._throw( "regions must have end >= aliEnd (" + region.end + " is < " + region.aliEnd + ")" );
    }

    var y  = this._baseline - radius,
        xs = this._imageParams.residueWidth,
        l,
        r;

    if ( region.aliStart &&
         region.aliStart > region.start ) {
      l = { x: Math.floor( region.start * xs ),
            y: Math.floor( y - 1 ) + 1,
            w: Math.floor( region.aliStart * xs ) - Math.floor( region.start * xs ) + 1,
            h: height + 1 };
    }

    if ( region.aliEnd &&
         region.aliEnd < region.end ) {
      r = { x: Math.floor( region.aliEnd * xs ) + 1,
            y: Math.floor( y - 1 ) + 1,
            w: Math.floor( region.end * xs ) - Math.floor( region.aliEnd * xs ),
            h: height + 1 };
    }

    var fillStyle = { opacity: this._imageParams.envOpacity,
                       fill: '#ffffff', stroke: '#ffffff' };

    if ( l !== undefined ) {
      this._canvas.rect( l.x, l.y, l.w, l.h ).attr(fillStyle);
    }

    if ( r !== undefined ) {
      this._canvas.rect( r.x, r.y, r.w, r.h ).attr(fillStyle);
    }

  };

  this._buildRegionPath = function( params, region ) {
    var path = "M";

    // move to top left of region
    // draw left side down to bottom of region
    switch ( params.s ) {
      case "curved":
        path += (params.x + params.r) + " " + params.y;
        path += this._drawLeftRounded( params.r, params.h );
        break;
      case "jagged":
        path += params.x + " " + params.y;
        path += this._drawJagged( params.x, params.y, params.h, true );
        break;
      case "straight":
        path += params.x + " " + params.y;
        path += "l0 " + params.h;
        break;
      case "arrow":
        path += (params.x + params.a) + " " + params.y;
        path += this._drawLeftArrow( params.a, params.h );
        break;
    }

    // draw horizontal line from bottom left to bottom right
    if ( params.s.match(/^curved|arrow$/) && params.e.match(/^curved|arrow$/) ) {
      var l_width = (params.w - (params.r * 2));
      if (l_width < 0) {
        l_width = 0;
      }
      path += "l" + l_width + " 0";
    }
    else if ( params.s.match(/^curved|arrow$/) || params.e.match(/^curved|arrow$/) ) {
      path += "l" + (params.w - params.r) + " 0";
    }
    else {
      path += "l" + params.w + " 0";
    }


    // draw right side up to top of region
    switch ( params.e ) {
      case "curved":
        path += this._drawRightRounded( params.r, params.h );
        break;
      case "jagged":
        path += this._drawJagged( params.x + params.w, params.y + params.h, params.h, false );
        break;
      case "straight":
        path += "l0 -" + params.h;
        break;
      case "arrow":
        path += this._drawRightArrow( params.a, params.h );
        break;
    }

    // close path - complete line from right to left top
    path += "z";
    return path;

  };

  this._drawRightRounded = function( radius, height ) {
    var radius = radius + 2;
    return "c" + radius + " " + 0 + " " + radius + " " + -height + " " + 0 + " " + -height;
  };

  this._drawLeftRounded = function( radius, height ) {
    var radius = radius + 2;
    return "c" + -radius + " " + 0 + " " + -radius + " " + height + " " + 0 + " " + height;
  };

  this._drawLeftArrow = function( arrow, height ) {
    var path = "l" + -arrow + " " + (height/2) + "l" + arrow + " " + (height/2);
    return path;
  };

  this._drawRightArrow = function( arrow, height ) {
    var path = "l" + arrow + " " + -(height/2) + "l" + -arrow + " " + -(height/2);
    return path;
  };

  this._drawJagged = function( x, y, height, left ) {

    var steps = parseInt( this._imageParams.largeJaggedSteps, 10 );
    steps += steps % 2;

    var yShifts = this._getSteps( height, steps );

    var step = height / steps;

    var path = '';

    for ( var i = 0; i < yShifts.length; i = i + 1 ) {
      if ( i % 2 !== 0 ) {
        if ( left ) {
          path += "L" + x + " " + (y + yShifts[i]);
        } else {
          path += "L" + x + " " + (y - yShifts[i]);
        }
      }
      else {
        if ( left ) {
          path += "L" + (x + step) + " " + (y + yShifts[i]);
        } else {
          path += "L" + (x - step) + " " + (y - yShifts[i]);
        }
      }
    }

    if ( left ) {
      path += "L" + x + " " + (y + height);
    } else {
      path += "L" + x + " " + (y - height);
    }
    return path;
  };

  this._getSteps = function( height, steps ) {

    var cacheKey = "shifts_" + height + "_" + steps;
    var list = this._cache[cacheKey];

    if ( list === undefined ) {

      var step = height / steps;

      var yShifts = [];
      for ( var i = 0; i < ( steps / 2 ); i = i + 1 ) {
        yShifts.push( ( height / 2 ) - ( i * step ) );
        yShifts.push( ( height / 2 ) + ( i * step ) );
      }

      list = $.unique(yShifts).sort( function (a, b) { return a - b; } );

      this._cache[cacheKey] = list;
    }

    return list;
  };

  this._drawBridge = function( bridge ) {
    var self = this;

    var start  = bridge.markup.start,
        end    = bridge.markup.end,
        height = bridge.height,
        up     = bridge.up,

        color = "#000000",

        x1 = Math.floor( start * this._imageParams.residueWidth ) + 1.5,
        x2 = Math.floor( end   * this._imageParams.residueWidth ) + 1.5,
        y1 = Math.round( up ? this._topOffset : this._botOffset ) + 0.5,
        y2,
        label,

        xo = this._imageParams.xOffset, // need X- and Y-offsets
        yo = this._imageParams.yOffset;


    if ( up ) {
      y2 = Math.ceil( this._baseline - height ) - 0.5;
    } else {
      y2 = Math.floor( this._baseline + height ) + 0.5;
    }

    if ( bridge.markup.color.match( "^\\#[0-9A-Fa-f]{6}$" ) ) {
      color = bridge.markup.color;
    }

    var path = "M" + x1 + " " + y1 + "L" + x1 + " " + y2 + "L" + x2 + " " + y2 + "L" + x2 + " " + y1;
    var strokeColor = color || "#000";
    this._canvas.path(path).attr({ 'stroke': strokeColor });

    var tip = {};

    if ( bridge.markup.metadata ) {
      var md = bridge.markup.metadata;

        tip.title = self.capitalize( md.type || "Bridge" );
        tip.body =
          '<div class="tipContent">' +
          '  <dl>' +
          '    <dt>Coordinates:</dt>' +
          '    <dd>' + md.start + '-' + md.end + '</dd>' +
          '    <dt>Source:</dt>' +
          '    <dd>' + ( md.database || '<span class="na">n/a</span>' ) + '</dd>' +
          '  </dl>' +
          '</div>';
    }

    var ys = [ y1, y2 ].sort(function( a, b ) { return a - b; } );
    this._areasList.push( { start:  start,
                            type:   "bridge-start",
                            color: color,
                            end:    end,
                            tip:    tip,
                            coords: [ xo + x1 - 1, yo + ys[0] - 1, 
                                      xo + x1 + 1, yo + ys[1] + 1 ] } );
    this._areasList.push( { start:  start,
                            type:   "bridge-horizontal",
                            color: color,
                            end:    end,
                            tip:    tip,
                            coords: [ xo + x1 - 1, yo + ys[1] - 1, 
                                      xo + x2 + 1, yo + ys[1] + 1 ] } );
    this._areasList.push( { start:  start,
                            type:   "bridge-end",
                            color: color,
                            end:    end,
                            tip:    tip,
                            coords: [ xo + x2 - 1, yo + ys[0] - 1, 
                                      xo + x2 + 1, yo + ys[1] + 1 ] } );

  };

  this._drawLollipopHead = function( x, y1, y2, start, up, style, color, lineColour, tip, metadata ) {

    var xo = this._imageParams.xOffset,
        yo = this._imageParams.yOffset,
        r,
        d;

    switch ( style ) {

      case "circle":
        r = this._imageParams.headSizeCircle;

        var strokeColor = color || "#f00";
        this._canvas.circle(x, y2, r).attr({ fill: strokeColor, stroke: strokeColor });

        this._areasList.push( { tip:      tip,
                                type:     "lollipop-head",
                                shape:    "circle",
                                color:   color || "red",
                                start:    start,
                                coords:   [ xo + x - r, yo + y2 - r, 
                                            xo + x + r, yo + y2 + r ] } );
        break;

      case "square":
        d = this._imageParams.headSizeSquare / 2;
        var strokeColor = color || "#64C809"; //rgb(100, 200, 9)
        this._canvas.rect(x - d, y2 - d, d * 2, d * 2)
                      .attr({ fill: strokeColor, stroke: strokeColor });

        this._areasList.push( { tip:      tip,
                                type:     "lollipop-head",
                                start:    start,
                                color:   color || "rgb(100, 200, 9)",
                                coords:   [ xo + x - d, yo + y2 - d, 
                                            xo + x + d, yo + y2 + d ] } );
        break;

      case "diamond":
        d = this._imageParams.headSizeDiamond;
        var strokeColor = color || "#64C809";
        this._canvas.rect(x - (d/2), y2 - (d/2), d, d)
                      .attr({ fill: strokeColor, stroke: strokeColor })
                      .rotate(45);

        this._areasList.push( { tip:      tip,
                                ty2pe:     "lollipop-head",
                                shape:    "poly",
                                start:    start,
                                color:   color || "rgb(100, 200, 9)",
                                coords:   [ xo + x - d, yo + y2 - d, 
                                            xo + x + d, yo + y2 + d ] } );
        break;

      case "line":
        d = this._imageParams.headSizeLine;
        var path = "M" + x + " " + (y2 - d) + "L" + x + " " + (y2 + d);
        var strokeColor = color || "#3228ff"; // rgb(50, 40, 255)
        this._canvas.path(path).attr({ 'stroke': strokeColor });
        this._areasList.push( { tip:      tip,
                                type:     "lollipop-head",
                                start:    start,
                                color:   color || "rgb(50, 40, 255)",
                                coords:   [ xo + x - 1, yo + y2 - d - 1,
                                            xo + x + 1, yo + y2 + d + 1 ] } );
        break;

      case "arrow":
        d = this._imageParams.headSizeArrow;

        var coords;
        if ( up ) {
          var path = "M" + x + " " + y2 + "L" + x + " " + (y2 - d);
          var strokeColor = lineColour || "#000";
          this._canvas.path(path).attr({ 'stroke': strokeColor });

          var path = "M" + (x - d)  + " " + (y2 + d * 0.5) + "L" + x + " " + (y2 - d) + "L" + (x + d) + " " + (y2 + d * 0.5);
          var strokeColor = color || "#3228ff"; // rgb(50, 40, 255)
          this._canvas.path(path).attr({ 'stroke': strokeColor });

          coords = [ xo + x - d, yo + y2, 
                     xo + x + d, yo + y2 + d * 0.5 ];
        } else { 
          this._context.beginPath();
          this._context.moveTo( x,     y2  );
          this._context.lineTo( x,     y2 + d );
          this._context.strokeStyle = lineColour || "#000000";  
          this._context.stroke();
          this._context.beginPath();
          this._context.moveTo( x - d, y2 - d * 0.5 );
          this._context.lineTo( x,     y2 + d );
          this._context.lineTo( x + d, y2 - d * 1.5 );


          coords = [ xo + x - d, yo + y2 - d * 1.5, 
                     xo + x + d, yo + y2 - d ];
        }
        this._areasList.push( { tip:      tip,
                                type:     "lollipop-head",
                                color:   color || "rgb(50, 40, 255)",
                                start:    start,
                                shape:    "poly",
                                coords:   coords } );
        break;

      case "pointer":
        d = this._imageParams.headSizePointer;

        var coords;
        if ( up ) {
          var path = "M" + (x - d) + " " + (y1 - d * 1.5) + "L" + x + " " + (y1) + "L" + ( x + d) + " " + (y1 - d * 1.5);
          var strokeColor = color || "#3228ff"; // rgb(50, 40, 255)
          this._canvas.path(path).attr({ 'stroke': strokeColor });
          coords = [ xo + x - d, yo + y1, 
                     xo + x + d, yo + y1 - d ];
        } else { 
          var path = "M" + (x - d) + " " + (y1 + d * 1.5) + "L" + x + " " + (y1) + "L" + ( x + d) + " " + (y1 + d * 1.5);
          var strokeColor = color || "#3228ff"; // rgb(50, 40, 255)
          this._canvas.path(path).attr({ 'stroke': strokeColor });
          coords = [ xo + x - d, yo + y1 + d, 
                     xo + x + d, yo + y1 ];
        }

        this._areasList.push( { tip:      tip,
                                type:     "lollipop-head",
                                color:   color || "rgb(50, 40, 255)",
                                start:    start,
                                shape:    "poly",
                                coords:   coords } );
        break;
    }

  };

  this._drawHit = function( hit ) {
    var self = this;
    var xs = this._imageParams.residueWidth;
    var len = Math.floor(hit.tend * xs) - Math.floor(hit.tstart * xs);
    var fillStyle = {
      fill: '#666666',
      stroke: '#000000',
      opacity: 1
    };
    var x = Math.floor( hit.tstart * xs )
    var y = this._canvasHeight - 4;
    var glyph = this._canvas.rect( x, y, len, 2 ).attr(fillStyle);

    $(glyph.node).qtip({position: {
        viewport: $(window),
        my: 'left top',
        at: 'right center'
      },
      content: {
        title: 'Match Coordinates',
        text: '<dl class="narrow"><dt>Target: </dt><dd>' + hit.tstart + ' - ' + hit.tend + '</dd><dt>Query: </dt><dd>' + hit.qstart + ' - ' + hit.qend + '</dd></dl>'
      },
      show: {
        solo: true
      },
      style: {
        classes: 'ui-tooltip-hmmerdist ui-tooltip-rounded'
      }
    });
  };

  this._drawLollipop = function( markup ) {
    var self = this;

    var start = markup.start,

        up = markup.v_align === undefined || markup.v_align === "top",

        x1 = Math.floor( start * this._imageParams.residueWidth ) + 1.5,
        y1,
        y2;

    if ( up ) {
      y1 = Math.round( this._topOffset + 1 ) - 0.5;
      y2 = Math.floor( y1 - this._heights.lollipops.up[start] + ( this._baseline - this._topOffset ) + 1 );
    } else {
      y1 = Math.round( this._botOffset + 1 ) - 0.5;
      y2 = Math.ceil( y1 + this._heights.lollipops.down[start] - ( this._botOffset - this._baseline ) - 1 );
    }

    var path = "M" + x1 + " " + y1 + "L" + x1 + " " + y2;
    var strokeColor = markup.lineColour || "#000000";
    this._canvas.path(path).attr({ 'stroke': strokeColor });

    var xo = this._imageParams.xOffset,
        yo = this._imageParams.yOffset;

    var ys = [ y1, y2 ].sort(function( a, b ) { return a - b; } );
    var area = { start:    start,
                 type:     "lollipop",
                 coords:   [ xo + Math.floor( x1 ) - 1, yo + ys[0] - 1, 
                             xo + Math.floor( x1 ) + 1, yo + ys[1] + 1 ] };
    this._areasList.push( area );

    if ( markup.href !== undefined ) {
      area.href = markup.href;
    }

    var tip = {};

    if ( markup.metadata ) {
      var md = markup.metadata;

        tip.title = self.capitalize( md.type || "Annotation" );
        tip.body =
          '<div class="tipContent">' +
          '  <dl>' +
          '    <dt>Description:</dt>' +
          '    <dd>' + md.description + '</dd>' +
          '    <dt>Position:</dt>' +
          '    <dd>' + md.start + '</dd>' +
          '    <dt>Source:</dt>' +
          '    <dd>' + ( md.database || '<span class="na">n/a</span>' ) + '</dd>' +
          '  </dl>' +
          '</div>';
    }
    area.tip = tip;

    if ( markup.headStyle ) {
      this._drawLollipopHead( x1, y1, y2, start, up, markup.headStyle,
                              markup.color, markup.lineColour, area.tip,
                              markup.metadata );
    }

  };

  this._draw = function() {

    var self = this;
    this._canvas.setStart();

    if ( this._applyImageParams ) {

      var ip = this._imageParams;

      this._applyImageParams = false;
    }

    var seqArea = this._drawSequence();

    $.each(this._heights.bridges.markups, function(i, bridge ) {
      if ( bridge.display !== undefined &&
           bridge.display !== null &&
           ! bridge.display ) {
        return;
      }
      self._drawBridge( bridge );
    });

    $.each(this._heights.lollipops.markups.reverse(), function(i, lollipop ) {
      if ( lollipop.display !== undefined &&
           lollipop.display !== null &&
           ! lollipop.display ) {
        return;
      }
      self._drawLollipop( lollipop );
    });

    $.each(this._sequence.regions, function(i, region) {
      if ( region.display !== undefined &&
           region.display !== null &&
           ! region.display ) {
        return;
      }
      self._drawRegion( region );
    });

    if (this._sequence.hits) {
      $.each(this._sequence.hits, function(i, hit) {
        self._drawHit( hit );
      });
    }

    $.each(this._sequence.motifs, function(i, motif ) {
      if ( motif.display !== undefined &&
           motif.display !== null &&
           ! motif.display ) {
        return;
      }
      self._drawMotif( motif );
    });

    if ( this._sequence.highlight !== undefined &&
         parseInt( this._sequence.highlight.start, 10 ) &&
         parseInt( this._sequence.highlight.end, 10 ) ) {
      this._drawHighlight();
    }

    return this._canvas.setFinish();
  };

  this._drawMotif = function( motif ) {
    var self = this;

    motif.start = parseInt( motif.start, 10 );
    motif.end   = parseInt( motif.end,   10 );

    var height = Math.floor( this._imageParams.motifHeight ) - 2,
        radius = Math.round( height / 2 ),
        width  = ( motif.end - motif.start + 1 ) * this._imageParams.residueWidth,

        x = Math.max( 1, Math.floor( motif.start * this._imageParams.residueWidth ) + 1 ),
        y = Math.floor( this._baseline - radius ) + 0.5;

    var motifColour;

    var glyph = undefined;

    if ( motif.color instanceof Array ) {

      if ( motif.color.length !== 3 ) {
        this._throw( "motifs must have either one or three colors" );
      }

      color = [];

      var ip = this._imageParams;

      $.each(motif.color, function( i, c ) {
        var rgbColour = self._getRGBColour( c );
        color.push( { rgb:  "rgb("  + rgbColour.join(",") + ")",
                       rgba: "rgba(" + rgbColour.join(",") + "," + ip.motifOpacity + ")" } );
      });

      var step   = Math.round( height / 3 );
      for ( var i = 0; i < 3; i = i + 1 ) {
        glyph = this._canvas.rect(x, y + ( step * i), width, step).attr({fill: color[i].rgb, 'stroke-opacity':0});
      }

    }
    else {

      color = this._getRGBColour( motif.color );
      var rgb  = "rgb(" + color.join(",") + ")";
      var rgba = "rgba(" + color.join(",") + "," + this._imageParams.motifOpacity + ")";

      glyph = this._canvas.rect(x, y, width, parseInt( height, 10 ) + 1 )
          .attr({fill:rgb, opacity: this._imageParams.motifOpacity, 'stroke-opacity':0 });

    }


    if ( motif.metadata            !== undefined &&
         motif.metadata.identifier !== undefined ) {
      motif.metadata.description = motif.metadata.identifier;
    } else if ( motif.text !== undefined ) {
      motif.metadata.description = motif.text;
    } else {
      motif.metadata.description = "motif, " + motif.start + " - " + motif.end;
    }

    var xo = this._imageParams.xOffset,
        yo = this._imageParams.yOffset;

    var area = { text:   motif.metadata.description,
                 type:   "motif",
                 start:  motif.aliStart || motif.start,
                 end:    motif.aliEnd   || motif.end,
                 color: color,
                 coords: [ xo + x,         yo + y,
                           xo + x + width, yo + y + height ] };
    this._areasList.push( area );

    if ( motif.href !== undefined ) {
      area.href = motif.href;
    }

    this._buildTip( motif, glyph, 'motif');

  };

  this._drawSequence = function() {

    this._topOffset = Math.floor( this._baseline - ( this._seqHeight / 2 ) );
    this._botOffset = Math.floor( this._baseline + ( this._seqHeight / 2 ) + 1 );

    var seq_length = this._sequence.length * this._imageParams.residueWidth;

    var gradient = this._canvas.rect( 1, this._topOffset + 0.5, seq_length, ( this._seqHeight / 2 ) * 3 );
    gradient.attr({ 'fill': '270-#999-#eee:40-#ccc:60-#999', 'stroke': 'none' });

    var lengthLabel = this._canvas.text((this._sequence.length * this._imageParams.residueWidth) + 5, this._topOffset + (this._seqHeight / 2), this._sequence.length);
    lengthLabel.attr({'text-anchor': 'start'});

    // now that we have a label, we are going to have to resize the canvas to fit it on.
    var labelWidth = lengthLabel.getBBox().width;
    this._labelWidth = labelWidth;
    this._canvas.setSize( this._canvasWidth + labelWidth, this._canvasHeight );



    var xo = this._imageParams.xOffset,
        yo = this._imageParams.yOffset;

    return { label:  "sequence",
             text:   "sequence",
             coords: [ xo,                    yo + this._topOffset,
                       xo + this._imageWidth, yo + this._topOffset + this._seqStep * 5 ] };
  };
}

/*jslint browser: true,  nomen: true  */

var canv_support = null;

function isCanvasSupported() {
  "use strict";
  if (!canv_support) {
    var elem = document.createElement('canvas');
    canv_support = !!(elem.getContext && elem.getContext('2d'));
  }
  return canv_support;
}

(function ($) {
  function scale(coord, orig, desired) {
    var scaled = (desired * coord) / orig;
    return scaled;
  };

  function nice_number(value, round_) {
    //default value for round_ is false
    round_ = round_ || false;
    // :latex: \log_y z = \frac{\log_x z}{\log_x y}
    var exponent = Math.floor(Math.log(value) / Math.log(10)),
      fraction = value / Math.pow(10, exponent);

    if (round_)
      if (fraction < 1.5)
        nice_fraction = 1.
      else if (fraction < 3.)
        nice_fraction = 2.
      else if (fraction < 7.)
        nice_fraction = 5.
      else
        nice_fraction = 10.
    else
      if (fraction <= 1)
        nice_fraction = 1.
      else if (fraction <= 2)
        nice_fraction = 2.
      else if (fraction <= 5)
        nice_fraction = 5.
      else
        nice_fraction = 10.

    return nice_fraction * Math.pow(10, exponent);
  }


  function nice_bounds(axis_start, axis_end, num_ticks) {
    //default value is 10
    num_ticks = num_ticks || 10;
    var axis_width = axis_end - axis_start;

    if (axis_width === 0) {
      axis_start -= 0.5;
      axis_end += 0.5;
      axis_width = axis_end - axis_start;
    }

    var nice_range = nice_number(axis_width);
    var nice_tick = nice_number(nice_range / (num_ticks - 1), true);
    var axis_start = Math.floor(axis_start / nice_tick) * nice_tick;
    var axis_end = Math.ceil(axis_end / nice_tick) * nice_tick;
    return {
      "min": axis_start,
      "max": axis_end,
      "steps": nice_tick
    }
  }

  // Hit Profile Graphic

  function HitProfilePlot(options) {
    options = options || {};
    this.smoothed_data = options.data.smoothed || null;
    this.original_data = options.data.original || null;
    this.target = options.target || $('body');
    this.height = options.height || 130;
    this.smoothed = options.smoothed || true;
    this.leftMargin = 30;
    this.bottomMargin = 30;

    this.data = function () {
      if (this.smoothed) {
        return this.smoothed_data;
      }
      return this.original_data;
    };

    this.width  = options.width || this.data()[0].length;


    this.render = function () {
      this.canvas = Raphael(this.target.get(0), this.width, this.height);

      this.draw_axes();
      this.draw_labels();
      this.draw_identity();
      this.draw_coverage();
      this.draw_similarity();

      var self = this,
        marker = this.canvas.set();
      marker.push(
        this.canvas.circle(-100, this.height - 20, 10)
          .attr({"stroke" : "#666666", "fill" : "#ffffff"}),
        this.canvas.text(-100, this.height - 20, '1')
      );
      var crosshair = this.canvas.rect(-100, 0, 1, this.height - this.bottomMargin)
        .attr({"fill" : "#666666", "stroke-opacity" : 0});

      var move_target = this.canvas.rect(0, 0, this.width, this.height)
        .attr({"opacity" : 0, "fill" : "#ffffff" })
        .mousemove(function (e) {
          if (e.layerX > self.leftMargin) {
            //work out the position for the label
            var text = scale(
              e.layerX - self.leftMargin,
              self.width - self.leftMargin,
              self.data()[0].length
            );
            marker.attr({x : e.layerX, cx : e.layerX, text : Math.round(text)});
            crosshair.attr({x : e.layerX});
            $('svg').trigger('coverage.move', [text]);
          } else {
            marker.attr({x : -100, cx : -100});
            crosshair.attr({x : -100});
          }
        })
        .mouseout(function(e) {
          marker.attr({x : -100, cx : -100});
          crosshair.attr({x : -100});
          $('svg').trigger('coverage.move', [-1000]);
        })

      var toggle_data = $(this.target).find('.toggle_data');

      if (toggle_data.length > 0) {
        toggle_data.bind('click', function (e) {
          console.log('clicky');
          if (self.smoothed) {
            self.smoothed = false;
            $(this).text('smoothed');
          } else {
            self.smoothed = true;
            $(this).text('raw');
          }
          self.target.find('svg').remove();
          $(this).unbind('click');
          self.render();
        });
      }

      var close = $(this.target).find('.close');

      if (close.length > 0) {
        close.bind('click', function (e) {
          $(this).parent().hide();
          $('#heatmaps').show();
        });
      }

      return;
    };

    this.draw_coverage = function () {
      var self = this,
        prevX = null,
        prevY = null,
        path  = '';

      $.each(self.data()[0], function (i) {
        var y = self.height - Math.round(100 * this) - self.bottomMargin,
          x = scale(i, self.data()[0].length, self.width - self.leftMargin);
        if (i > 0) {
          if (prevX) {
            path = path + 'L' + (prevX + self.leftMargin) + ',' + prevY;
          }
          prevX = x;
          prevY = y;
        } else {
          path = 'M' + (x + self.leftMargin) + ',' + y;
        }
      });
      this.canvas.path(path).attr({'stroke': '#990000'});
    };

    this.draw_similarity = function () {
      var self = this,
        prevX = null,
        prevY = null,
        path  = '';

      $.each(self.data()[1], function (i) {
        var y = self.height - Math.round(100 * this) - self.bottomMargin,
          x = scale(i, self.data()[0].length, self.width - self.leftMargin);
        if (i > 0) {
          if (prevX) {
            path = path + 'L' + (prevX + self.leftMargin) + ',' + prevY;
          }
          prevX = x;
          prevY = y;
        } else {
          path = 'M' + (x + self.leftMargin) + ',' + y;
        }
      });
      this.canvas.path(path).attr({'stroke': '#000099'});
    };

    this.draw_identity = function () {
      var self = this,
        prevX = null,
        prevY = null,
        // start the line at the graph origin so we can fill this
        path = 'M' + self.leftMargin + ',' + (self.height - self.bottomMargin);

      $.each(self.data()[2], function (i) {
        var y = self.height - Math.round(100 * this) - self.bottomMargin,
          x = scale(i, self.data()[0].length, self.width - self.leftMargin);
        path = path + 'L' + (prevX + self.leftMargin) + ',' + prevY;
        prevX = x;
        prevY = y;
      });
      // final line so the fill runs along the bottom of the graph
      path = path + 'L' + (prevX + self.leftMargin) + ',' +  (self.height - self.bottomMargin);
      this.canvas.path(path).attr({'stroke': '#999999', 'fill': '#cccccc'});
    };

    this.draw_labels = function () {
      //draw y-min
      this.canvas.text(this.leftMargin - 4, this.height - this.bottomMargin, '0').attr({"text-anchor":"end"});

      // draw x-min
      this.canvas.text(this.leftMargin, this.height - (this.bottomMargin - 10), '1');

      //draw x-max
      var x_max_label = this.canvas.text(this.width, this.height - (this.bottomMargin - 10), this.data()[0].length).attr({"text-anchor": "end"});
      this.canvas.path(this.line_string((this.width - 1), (this.height - (this.bottomMargin)), (this.width - 1), (this.height - (this.bottomMargin - 3))));

      //draw y-max
      var x_max_left = this.width - x_max_label.getBBox().width,
        y_max_bottom = 10;
      this.canvas.text(this.leftMargin - 4, 4, 100).attr({"text-anchor": "end"});
      this.canvas.path(this.line_string(this.leftMargin, 1, (this.leftMargin - 3), 1));

      //draw y-ticks
      var y_ticks = nice_bounds(0, parseInt(100, 10), 5),
        y_start = y_ticks.steps;
      for (var y_start = y_ticks.steps; y_start < y_ticks.max; y_start += y_ticks.steps) {
        var y = this.height - (scale(y_start, 100, this.height - this.bottomMargin) + this.bottomMargin);
        if ( y <= y_max_bottom) {
          break;
        }
        var x = this.leftMargin;
        this.canvas.path(this.line_string(x,y,(x - 3),y));
        this.canvas.text(x - 4, y, y_start).attr({"text-anchor": "end"});
      }

      //draw x-ticks
      var x_ticks = nice_bounds(0, parseInt(this.data()[0].length), 10);
      var x_start = x_ticks.steps;
      for (var x_start = x_ticks.steps; x_start < x_ticks.max; x_start += x_ticks.steps) {
        var x = scale(x_start, this.data()[0].length, this.width - this.leftMargin) + this.leftMargin;
        var text = this.canvas.text(-100, -100, x_start);
        var text_width = text.getBBox().width;

        var x_right = x + (text_width / 2);
        if (x_right >= x_max_left) {
          break;
        }
        var y = this.height - this.bottomMargin;
        this.canvas.path(this.line_string(x, y, x, y + 3));
        this.canvas.text(x, y + 10, x_start);
      }
    }

    this.line_string = function (x1,y1,x2,y2) {
      return "M" + x1 + ',' + y1 + 'L' + x2 + ',' + y2;
    }

    this.draw_axes = function() {
      var color = '#333';

      // y-axis
      var ypath = "M" + this.leftMargin + ',' + 0
        + "L" + this.leftMargin + ',' + (this.height - (this.bottomMargin - 3));
      this.canvas.path(ypath);
      this.canvas.text(0, (this.height - this.bottomMargin) / 2, "Percent")
        .transform("r-90t0,10");

      // x-axis
      var xpath = "M" + (this.leftMargin - 3) + "," + (this.height - this.bottomMargin)
        + "L" + (this.leftMargin + this.width) + "," + (this.height - this.bottomMargin);
      this.canvas.path(xpath);
      this.canvas.text((this.width / 2) + (this.leftMargin / 2), this.height - this.bottomMargin + 22, "Position");

    }
  }

  $.fn.coveragePlot = function(data, width) {
    var plot = new HitProfilePlot({data: data, target: $(this), width: width});
    plot.render();
  };

  $.fn.similarityHeatMap = function (data, width) {
    var plot = new HeatMap({type:'similarity', data: data, target: $(this)});
    plot.render();
    plot.resize($('#domGraph').parent().width());
  };

  function HeatMap(options) {
    options = options || {};
    this.data = options.data.smoothed || null;
    this.type   = options.type || 'coverage';
    this.target = options.target || $('body');
    this.height = options.height || 16;
    this.leftMargin = 100;
    this.residueWidth = 0.5;
    this.seq_length = Math.ceil(this.data[0].length * this.residueWidth);

    this.width = this.seq_length + 2 + this.leftMargin;

    this.render = function () {
      this.canvas = Raphael(this.target.get(0), this.width, this.height);
      this.draw_labels();

      //this.draw_container();
      this.draw_heatpoints();

    };

    this.resize = function(width, height) {

      if (width > this.width) {
        return;
      }

      if(!width) {
        width = this.width;
      }
      if (!height) {
        height = this.height;
      }

      var seq_length = this.seq_length * this.residueWidth;

      seq_length = seq_length + this.leftMargin + 640;

      this.canvas.setSize(width, height);
      this.canvas.setViewBox(0, 0, seq_length, height);
      return this;
    }

    this.draw_labels = function () {
      // seq length label - hidden for now as other elements on the page
      // already show it. Might want to make it visible later.
      var len_label = this.canvas.text(0, 0, this.data[0].length).attr({opacity:0});
      // now resize the canvas to fit the right label width
      var lwidth = len_label.getBBox().width;
      this.canvas.setSize( this.width + lwidth, this.height );
      // left label
      this.canvas.text(this.leftMargin / 2, this.height / 2, 'hit ' + this.type);
    };

    this.draw_heatpoints = function () {
      var self = this;
      /* loop over the data and draw a colored stripe for each point
        based on its percentage */
      var data = (this.type.match(/coverage/))? this.data[0] : this.data[1];

      var heatmap = new Rainbow();
      heatmap.setSpectrum('#fff0ac','#990000');

      $.each(data, function(i) {
        var color = '#' + heatmap.colourAt(100 * this);
        var x = Math.ceil(i * self.residueWidth) + self.leftMargin;
        self.canvas.rect(x, 1, 1, self.height - 2).attr({stroke: color});
      });

    };

    this.draw_container = function () {

      this.canvas.rect(0 + this.leftMargin - 1, 0, this.seq_length + 2, this.height).attr(
          {stroke: '#666'});
    };
  }

  $.fn.coverageHeatMap = function (data, width) {
    var plot = new HeatMap({type:'coverage', data: data, target: $(this)});
    plot.render();
    plot.resize($('#domGraph').parent().width());
    var click_target = $('<div class="clickable toggle"><span class="pictos clickable">Y</span></div>')
      .bind('click', function() {
        $('#coverageGraph').show();
        if (! $('#coverageGraph svg').length > 0) {
          var width = $('#domGraph svg').width();
          if (width < 400 ) {
            width = 400;
          }
          // have to show() first or things like getBBox() don't work in
          // subsequent methods as the graphic hasn't been rendered on
          // the page so the browser has no dimensions to work with.
          $('#coverageGraph').css({'width': width});
          $('#coverageGraph').coveragePlot(data, width);
        }
        $('#heatmaps').hide();
      });

    var new_width = plot.canvas.width;
    $(this).parent().css({"width": new_width}).append(click_target);
  };

})( jQuery );
Handlebars.registerHelper("twoSig", function (num, digits) {
  return parseFloat(num).toFixed(digits);
});

Handlebars.registerHelper("regions", function (segments) {
  var out = '';
  for (var i = 0; i < segments.length; i++) {
    if (i > 0) {
      out += ", ";
    }
    out += segments[i].start + "-" + segments[i].end;
  }
  return out;
});
(function( $ ){
  var seqAttrs = {
    fill: "#aaa",
    stroke: "#aaa",
    'stroke-width': 0
  };
  var hilight = {
    fill: "#fff",
    'stroke-width': 0,
    opacity: "0.2"
  };
  var hitAttrs = {
    stroke: "#000",
    'stroke-width': 0.5
  };

  var colors = [
    '#900',
    '#f9ea6d',
    '#090',
    '#009'
  ];

  var width = 150;
  var height = 14;

  var adjustScale = function(data) {
    var scaled = $.extend(true, {}, data);

    /* need to scale the sequences. find the longest and make that = 100%
    then scale the second sequence accordingly.
    */
    var seqs = [data.target.len, data.query.len];
    var longest = Math.max.apply(Math, seqs);
    for (var seq in data) {
      scaled[seq].len = Math.round((data[seq].len * width) / longest);
      for (var hit in data[seq].hits) {
        scaled[seq].hits[hit][0] =  Math.round(((data[seq].hits[hit][0] - 1) * width) / longest);
        scaled[seq].hits[hit][1] =  Math.round(((data[seq].hits[hit][1] - 1) * width) / longest);
      }
    }
    return scaled;
  };

  var drawHit = function(canvas, hit, y) {
    var width = (hit[1] - hit[0]) + 1;
    var attribs = $.extend(hitAttrs, {fill: colors[hit[2]]});
    canvas.rect(hit[0], y, width, 4).attr(attribs);
    canvas.rect(hit[0], y, width, 2).attr(hilight);
  };

  $.fn.hitLocation = function(data, debug) {
    return this.each(function(i){
      var scaled = adjustScale(data[i]);
      var canvas = Raphael(this, width, height);
      //draw the target/query sequences
      canvas.rect(0, 3, scaled.query.len, 2).attr(seqAttrs);
      canvas.rect(0, 9, scaled.target.len, 2).attr(seqAttrs);

      //draw the matches on the query
      for (var hit in scaled.query.hits) {
        drawHit(canvas, scaled.query.hits[hit], 2);
      };

      //draw the matches on the target
      for (var hit in scaled.target.hits) {
        drawHit(canvas, scaled.target.hits[hit], 8);
      };

      if(debug) {
        for (var i=0; i <= width;i+=2) {
          canvas.rect(i,0,1,14).attr({fill:'#000','stroke-width': 0, opacity: 0.1});
        }
        for (var i=0; i <= height;i+=2) {
          canvas.rect(0,i,width,1).attr({fill:'#000','stroke-width': 0, opacity: 0.1});
        }
      }
    });
  };
})( jQuery );
var hmmer_theme_hmmer_dashboard = function() {
  "use strict";

  var hmmer_theme = function (div) {

    //sunburst
    // var hmmer_elem = hmmer_vis.sunburst()
    // var hmmer_cloud = hmmer_vis.word_cloud();
    // var hmmer_histo = hmmer_vis.histogram();
    // var hmmer_tree_legend = hmmer_vis.tree_legend();
    var hmmer_hits_viewer = hmmer_vis.hits_view();
    var hmmer_sunburst = hmmer_vis.sunburst2();
    var hmmer_domain_architectures_view = hmmer_vis.domain_architectures_view();
    // var hmmer_pie_chart = hmmer_vis.pie_chart();
    // var hmmer_data_table = hmmer_vis.data_table();
    // var hmmer_lineage_plot = hmmer_vis.lineage_plot();

    // var hmmer_pdb_viewer = hmmer_vis.pdb_viewer();
    // hmmer_pdb_viewer(document.getElementById("chart"));

    // hmmer_sunburst(document.getElementById("chart"));

    // hmmer_tree_legend(document.getElementById("legend"));
    // hmmer_cloud(div);
    // hmmer_pie_chart(div);
    // hmmer_data_table(document.getElementById("testtable"));
    // hmmer_lineage_plot(document.getElementById("lineage_plot"));

    // start the spinners
    start_spinner();


    var hmmer_top_hits_url = "https://rawgit.com/fabsta/d3_sunburst/master/data/stats.json";
    var hmmer_domain_tree_url = "http://wwwdev.ebi.ac.uk/Tools/hmmer/results/484B2AFA-CBC2-11E4-B744-822AB8F19640/fail/";
    var hmmer_pfama_url = "http://wwwdev.ebi.ac.uk/Tools/hmmer//annotation/pfama/9B22C480-CBD7-11E4-AADB-FCB7088B62CF";

var uuid = "9B22C480-CBD7-11E4-AADB-FCB7088B62CF";

  // d3.json(hmmer_pfama_url, function(error, data){
  //   // $.get("../../data/pfama.html", function (data) {
  //         document.getElementById('pfama_result').innerHTML = data;
  //
  //         var chart = new PfamGraphic('#domGraph', example_sequence);
  //         var pg = new PfamGraphic('#domGraph', data.sequence);
  //         pg.render();
  //         var new_width = $('#domGraph').parent().width();
  //         pg.resize( new_width );
  //
  //
  //         // $.loadPfamAnnotation(data.uuid);
  //     });
    // hits dashboard

    // d3.json("../../data/stats_brca2.json", function(error, data) {
      // d3.json("../../data/stats_ecoli.json", function(error, data) {
      //d3.json("../../data/stats.json", function(error, data) {
      d3.json(hmmer_top_hits_url, function(error, data) {
        if (error) {
        return console.warn(error);
      }
      else{
        d3.select("#top_hits_spinner").style("visibility", "hidden");
        hmmer_hits_viewer(document.getElementById("hits_viewer"), data);

        // if (typeof data.distTree !== 'undefined'){
        //   console.log("Found distTree entry: ");
        //   hmmer_sunburst(document.getElementById("chart"), JSON.parse(data.distTree), "dist_tree")
        //   d3.select("#taxonomy_view_spinner").style("visibility", "hidden");
        // }
        if (typeof data.fullTree !== 'undefined'){
          console.log("Found fullTree entry: ");
          hmmer_sunburst(document.getElementById("chart"), JSON.parse(data.fullTree), "full_tree")
          d3.select("#taxonomy_view_spinner").style("visibility", "hidden");
        }



        if (typeof data.pdb !== 'undefined'){
          console.log("Found pdb entry: "+data.pdb);
          d3.select("#pdb_spinner").style("visibility", "hidden");
          d3.select("#pdb_div").text("Show pdb structure of "+data.pdb+" here");
        }
        if(typeof data.dom_architectures !== 'undefined'){
          console.log("Found dom_architectures entry: ");
          hmmer_domain_architectures_view(document.getElementById("domain_architectures_view"), data.dom_architectures);
          d3.select("#domain_architecture_spinner").style("visibility", "hidden");
        }
      }
    });


    // d3.json(hmmer_domain_tree_url, function(error, root) {
    // if (error) {
    //   return console.warn(error);
    // }
    // else{
    //   d3.select("#taxonomy_view_spinner").style("visibility", "hidden");
    //   d3.select("#domain_architecture_spinner").style("visibility", "hidden");
    //   // hmmer_hits_viewer(document.getElementById("hits_viewer"));
    // }
    // });

    // domain architectures
    // d3.json("../../data/dist.json", function(error, root) {
    // if (error) return console.warn(error);
    // hmmer_hits_viewer(document.getElementById("hits_viewer"));
    // });

    // pdb viewer
    // d3.json("../../data/dist.json", function(error, root) {
    // if (error) return console.warn(error);
    // hmmer_hits_viewer(document.getElementById("hits_viewer"));
    // });




  };


  function start_spinner(){
    var spinners = ['top_hits_spinner', 'taxonomy_view_spinner', 'domain_architecture_spinner', 'pdb_spinner'];
    for(var spinner_id of spinners){
      d3.select("#"+spinner_id).style("visibility", "visible");
    }
  }

  return hmmer_theme;
};
(function ($) {

  var canv_support = null;

  function isCanvasSupported(){
    if (!canv_support) {
      var elem = document.createElement('canvas');
      canv_support = !!(elem.getContext && elem.getContext('2d'));
    }
    return canv_support;
  }


  function HMMLogo(options) {
    options = (options) ? options : {};

    this.column_width = options.column_width || 34;
    this.height = options.height || 300;
    this.data = options.data || null;
    this.scale_height_enabled = options.height_toggle || null;
    if (options.zoom_buttons && options.zoom_buttons === 'disabled') {
      this.zoom_enabled = null;
    }
    else {
      this.zoom_enabled = true;
    }

    this.alphabet = options.alphabet || 'dna';
    this.dom_element = options.dom_element || $('body');
    this.start = options.start || 1;
    this.end = options.end || this.data.height_arr.length;
    this.zoom = parseFloat(options.zoom) || 0.4;
    this.default_zoom = this.zoom;

    if (options.scaled_max) {
      this.data.max_height = options.data.max_height_obs || this.data.max_height || 2;
    }
    else {
      this.data.max_height = options.data.max_height_theory || this.data.max_height || 2;
    }


    this.dna_colors = {
      'A': '#cbf751',
      'C': '#5ec0cc',
      'G': '#ffdf59',
      'T': '#b51f16',
      'U': '#b51f16'
    };

    this.aa_colors = {
      'A': '#FF9966',
      'C': '#009999',
      'D': '#FF0000',
      'E': '#CC0033',
      'F': '#00FF00',
      'G': '#f2f20c',
      'H': '#660033',
      'I': '#CC9933',
      'K': '#663300',
      'L': '#FF9933',
      'M': '#CC99CC',
      'N': '#336666',
      'P': '#0099FF',
      'Q': '#6666CC',
      'R': '#990000',
      'S': '#0000FF',
      'T': '#00FFFF',
      'V': '#FFCC33',
      'W': '#66CC66',
      'Y': '#006600'
    };

    // set the color library to use.
    this.colors = this.dna_colors;

    if (this.alphabet === 'aa') {
      this.colors = this.aa_colors;
    }

    this.canvas_width = 5000;

    // this needs to be set to null here so that we can initialise it after
    // the render function has fired and the width determined.
    this.scrollme = null;

    this.previous_target = 0;
    // keeps track of which canvas elements have been drawn and which ones haven't.
    this.rendered = [];
    this.previous_zoom = 0;

    // the main render function that draws the logo based on the provided options.
    this.render = function(options) {
      if (!this.data) {
        return;
      }
      options    = (options) ? options : {};
      var zoom   = options.zoom || this.zoom;
      var target = options.target || 1;
      var scaled = options.scaled || null;

      if (target === this.previous_target) {
        return;
      }

      this.previous_target = target;


      if ( options.start ) {
        this.start = options.start;
      }
      if ( options.end ) {
        this.end = options.end;
      }

      if (zoom <= 0.1) {
        zoom = 0.1;
      }
      else if (zoom >= 1) {
        zoom = 1;
      }


      var end = this.end || this.data.height_arr.length;
      end     = (end > this.data.height_arr.length) ? this.data.height_arr.length : end;
      end     = (end < start) ? start : end;

      var start = this.start || 1;
      start     = (start > end) ? end : start;
      start     = (start > 1) ? start : 1;


      this.y = this.height - 20;

      // Check to see if the logo will fit on the screen at full zoom.
      this.max_width = this.column_width * ((end - start) + 1);
      var parent_width = $(this.dom_element).parent().width();
      // If it fits then zoom out and disable zooming.
      if (parent_width > this.max_width) {
        zoom = 1;
        this.zoom_enabled = false;
      }

      this.zoom = zoom;

      this.zoomed_column = this.column_width * zoom;
      this.total_width = this.zoomed_column * ((end - start) + 1);

      // If zoom is not maxed and we still aren't filling the window
      // then ramp up the zoom level until it fits, then disable zooming.
      // Then we get a decent logo with out needing to zoom in or out.
      if (zoom < 1) {
        while (this.total_width < parent_width) {
          this.zoom += 0.1;
          this.zoomed_column = this.column_width * this.zoom;
          this.total_width = this.zoomed_column * ((end - start) + 1);
          this.zoom_enabled = false;
          if (zoom >= 1) {
            break;
          }
        }
      }

      if (target > this.total_width) {
        target = this.total_width;
      }
      $(this.dom_element).attr({'width':this.total_width + 'px'}).css({width:this.total_width + 'px'});

      var canvas_count = Math.ceil(this.total_width / this.canvas_width);
      this.columns_per_canvas = Math.ceil(this.canvas_width / this.zoomed_column);


      if (this.previous_zoom !== this.zoom) {
        $(this.dom_element).find('canvas').remove();
        this.previous_zoom = this.zoom;
        this.rendered = [];
      }

      this.canvases = [];
      this.contexts = [];

      var max_canvas_width = 1;

      for (var i = 0; i < canvas_count; i++) {

        var split_start = (this.columns_per_canvas * i) + start;
        var split_end   = split_start + this.columns_per_canvas - 1;
        if (split_end > end) {
          split_end = end;
        }

        var adjusted_width = ((split_end - split_start) + 1) * this.zoomed_column;

        if (adjusted_width > max_canvas_width) {
          max_canvas_width = adjusted_width;
        }

        var canv_start = max_canvas_width * i;
        var canv_end = canv_start + adjusted_width;

        if (target < canv_end + (canv_end / 2) && target > canv_start - (canv_start / 2)) {
          // Check that we aren't redrawing the canvas and if not, then attach it and draw.
          if (this.rendered[i] !== 1) {

            this.canvases[i] = attach_canvas(this.dom_element, this.height, adjusted_width, i, max_canvas_width);
            this.contexts[i] = this.canvases[i].getContext('2d');
            this.contexts[i].setTransform(1, 0, 0, 1, 0, 0);
            this.contexts[i].clearRect(0, 0, adjusted_width, this.height);
            this.contexts[i].fillStyle = "#ffffff";
            this.contexts[i].fillRect (0, 0, canv_end, this.height);


            if (this.zoomed_column > 12) {
              var fontsize = parseInt(10 * this.zoom, 10);
              fontsize = (fontsize > 10) ? 10 : fontsize;
              this.render_with_text(split_start, split_end, i, fontsize);
            }
            else {
              this.render_with_rects(split_start, split_end, i);
            }
            this.rendered[i] = 1;
          }
        }

      }

      // check if the scroller object has been initialised and if not then do so.
      // we do this here as opposed to at object creation, because we need to
      // make sure the logo has been rendered and the width is correct, otherwise
      // we get a weird initial state where the canvas will bounce back to the
      // beginning the first time it is scrolled, because it thinks it has a
      // width of 0.
      if (!this.scrollme) {
        if (Modernizr.canvas) {
          this.scrollme = new EasyScroller($(this.dom_element)[0], {
            scrollingX: 1,
            scrollingY: 0
          });
        }
      }

      if (target !== 1 && Modernizr.canvas) {
        this.scrollme.reflow();
      }
    };

    this.render_x_axis = function () {
      $(this.dom_element).parent().before('<p id="logo_xaxis" class="centered" style="margin-left:40px">Model Position</p>');
    };

    this.render_y_axis = function () {
      //attach a canvas for the y-axis
      $(this.dom_element).parent().before('<canvas id="logo_yaxis" class="logo_yaxis" height="300" width="40"></canvas>');
      var canvas = $('#logo_yaxis');
      if(!isCanvasSupported()) {
        canvas[0] = G_vmlCanvasManager.initElement(canvas[0]);
      }
      var context = canvas[0].getContext('2d');
      //draw tick marks
      context.beginPath();
      context.moveTo(40, 1);
      context.lineTo(30, 1);
      context.moveTo(40, 271);
      context.lineTo(30, 271);
      context.moveTo(40, (271 / 2));
      context.lineTo(30, (271 / 2));
      context.lineWidth = 1;
      context.strokeStyle = "#666666";
      context.stroke();
      context.fillStyle = "#000000";
      context.textAlign = "right";
      context.font = "bold 10px Arial";
      context.textBaseline = "top";
      context.fillText(parseFloat(this.data.max_height).toFixed(1), 28, 0);
      context.textBaseline = "middle";
      context.fillText(parseFloat(this.data.max_height / 2).toFixed(1), 28, (271/2));
      context.fillText('0', 28, 271);
      // draw the label
      context.save();
      context.translate(10, this.height / 2);
      context.rotate(-Math.PI/2);
      context.textAlign = "center";
      context.font = "normal 12px Arial";
      context.fillText("Information Content", 1, 0);
      context.restore();
    };

    this.render_x_axis();
    this.render_y_axis();

    this.render_with_text = function(start, end, context_num, fontsize) {
      var x = 0;
      var column_num = start;
      // add 3 extra columns so that numbers don't get clipped at the end of a canvas
      // that ends before a large column. DF0000830 was suffering at zoom level 0.6,
      // column 2215. This adds a little extra overhead, but is the easiest fix for now.
      if (end + 3 <= this.end) {
        end += 3;
      }

      for ( var i = start; i <= end; i++ ) {
        if (this.data.mmline && this.data.mmline[i - 1] === 1) {
          this.contexts[context_num].fillStyle = '#cccccc';
          this.contexts[context_num].fillRect (x, 10, this.zoomed_column, this.height - 40);
        }
        else {
          var column = this.data.height_arr[i - 1];
          if (column) {
            var previous_height = 0;
            var letters = column.length;
            for ( var j = 0; j < letters; j++ ) {
              var letter = column[j];
              var values = letter.split(':', 2);
              if (values[1] > 0.01) {
                var letter_height = (1 * values[1]) / this.data.max_height;
                var x_pos = x + (this.zoomed_column / 2);
                var y_pos = 269 - previous_height;
                var glyph_height = 258 * letter_height;

                // The positioning in IE is off, so we need to modify the y_pos when
                // canvas is not supported and we are using VML instead.
                if(!isCanvasSupported()) {
                  y_pos = y_pos + (glyph_height * (letter_height / 2));
                }

                this.contexts[context_num].font = "bold 350px Arial";
                this.contexts[context_num].textAlign = "center";
                this.contexts[context_num].fillStyle = this.colors[values[0]];
                // fonts are scaled to fit into the column width
                // formula is y = 0.0024 * col_width + 0.0405
                x_scale = ((0.0024 * this.zoomed_column) + 0.0405).toFixed(2);
                this.contexts[context_num].transform (x_scale, 0, 0, letter_height, x_pos, y_pos);
                this.contexts[context_num].fillText(values[0], 0, 0);
                this.contexts[context_num].setTransform (1, 0, 0, 1, 0, 0);
                previous_height = previous_height + glyph_height;
              }
            }
          }
        }

        //draw insert length ticks
        draw_ticks(this.contexts[context_num], x, this.height - 15, 5);
        // draw insert probability ticks
        draw_ticks(this.contexts[context_num], x, this.height - 30, 5);

        if (this.zoom < 0.7) {
          if (i % 5 === 0) {
            // draw column dividers
            draw_ticks(this.contexts[context_num], x + this.zoomed_column, this.height - 30, 0 - this.height - 30, '#dddddd');
            // draw top ticks
            draw_ticks(this.contexts[context_num], x + this.zoomed_column, 0, 5);
            // draw column numbers
            draw_column_number(this.contexts[context_num], x + 2, 10, this.zoomed_column, column_num, 10, true);
          }
        }
        else {
          // draw column dividers
          draw_ticks(this.contexts[context_num], x, this.height - 30, 0 - this.height - 30, '#dddddd');
          // draw top ticks
          draw_ticks(this.contexts[context_num], x, 0, 5);
          // draw column numbers
          draw_column_number(this.contexts[context_num], x, 10, this.zoomed_column, column_num, fontsize);
        }



        draw_insert_odds(this.contexts[context_num], x, this.height, this.zoomed_column, this.data.insert_probs[i - 1] / 100, fontsize);
        draw_insert_length(this.contexts[context_num], x, this.height - 5, this.zoomed_column, this.data.insert_lengths[i - 1], fontsize);



        x += this.zoomed_column;
        column_num++;
      }
      draw_border(this.contexts[context_num], this.height - 15, this.total_width);
      draw_border(this.contexts[context_num], this.height - 30, this.total_width);
      draw_border(this.contexts[context_num], 0, this.total_width);
    };

    this.render_with_rects = function(start, end, context_num) {
      var x = 0;
      var column_num = start;
      for ( var i = start; i <= end; i++ ) {
        if (this.data.mmline && this.data.mmline[i - 1] === 1) {
          this.contexts[context_num].fillStyle = '#cccccc';
          this.contexts[context_num].fillRect (x, 10, this.zoomed_column, this.height - 40);
        }
        else {
          var column = this.data.height_arr[i - 1];
          var previous_height = 0;
          var letters = column.length;
          for ( var j = 0; j < letters; j++ ) {
            var letter = column[j];
            var values = letter.split(':', 2);
            if (values[1] > 0.01) {
              var letter_height = (1 * values[1]) / this.data.max_height;
              var x_pos = x;
              var glyph_height = 258 * letter_height;
              var y_pos = 269 - previous_height - glyph_height;

              this.contexts[context_num].fillStyle = this.colors[values[0]];
              this.contexts[context_num].fillRect (x_pos, y_pos, this.zoomed_column, glyph_height);

              previous_height = previous_height + glyph_height;
            }
          }
        }

        var mod = 10;

        if ( this.zoom < 0.2) {
          mod = 20;
        }
        else if (this.zoom < 0.3) {
          mod = 10;
        }

        if (i % mod === 0) {
          // draw column dividers
          draw_ticks(this.contexts[context_num], x + this.zoomed_column, this.height - 30, 0 - this.height, '#dddddd');
          // draw top ticks
          draw_ticks(this.contexts[context_num], x + this.zoomed_column, 0, 5);
          // draw column numbers
          draw_column_number(this.contexts[context_num], x - 2,  10, this.zoomed_column, column_num, 10, true);
        }


        // draw insert probabilities/lengths
        draw_small_insert(this.contexts[context_num], x, this.height - 28, this.zoomed_column, this.data.insert_probs[i - 1] / 100, this.data.insert_lengths[i - 1]);

        x += this.zoomed_column;
        column_num++;
      }

    };

    this.toggle_scale = function() {
      // work out the current column we are on so we can return there
      var before_left = this.scrollme.scroller.getValues().left;
      var col_width = (this.column_width * this.zoom);
      var col_count = before_left / col_width;
      var half_visible_columns = ($('#logo_container').width() / col_width) / 2;
      var col_total = Math.ceil(col_count + half_visible_columns);

      // toggle the max height
      if(this.data.max_height === this.data.max_height_obs) {
        this.data.max_height = this.data.max_height_theory;
      }
      else {
        this.data.max_height = this.data.max_height_obs;
      }
      // reset the redered counter so that each section will re-render
      // with the new heights
      this.rendered = [];
      //update the y-axis
      $('#logo_yaxis').remove();
      this.render_y_axis();

      // re-flow and re-render the content
      this.scrollme.reflow();
      //scroll off by one to force a render of the canvas.
      this.scrollToColumn(col_total +1);
      //scroll back to the location we started at.
      this.scrollToColumn(col_total);
    };

    this.change_zoom = function(options) {
      var zoom_level = 0.3;
      if (options.target) {
        zoom_level = options.target;
      }
      else if(options.distance) {
        zoom_level = (parseFloat(this.zoom) - parseFloat(options.distance)).toFixed(1);
        if (options.direction === '+') {
          zoom_level = (parseFloat(this.zoom) + parseFloat(options.distance)).toFixed(1);
        }
      }

      if (zoom_level > 1) {
        zoom_level = 1;
      }
      else if (zoom_level < 0.1) {
        zoom_level = 0.1;
      }

      // see if we need to zoom or not
      var expected_width = ($('#logo_graphic').width() * zoom_level ) / this.zoom;
      if (expected_width > $('#logo_container').width()) {
        //work out my current position
        var before_left = this.scrollme.scroller.getValues().left;

        var col_width = (this.column_width * this.zoom);
        var col_count = before_left / col_width;
        var half_visible_columns = ($('#logo_container').width() / col_width) / 2;
        var col_total = Math.ceil(col_count + half_visible_columns);


        this.zoom = zoom_level;
        this.render({zoom: this.zoom});
        this.scrollme.reflow();

        //scroll to previous position
        this.scrollToColumn(col_total);
      }
      return this.zoom;
    };

    this.scrollToColumn = function(num, animate) {
      var half_view = ($('#logo_container').width() / 2) - ((this.column_width * this.zoom) / 2);
      var new_column = num - 1;
      var new_left = new_column  * (this.column_width * this.zoom);

      this.scrollme.scroller.scrollTo(new_left - half_view, 0, animate);
    };

    function draw_small_insert(context, x, y, col_width, odds, length) {
      var fill = "#ffffff";
      if (odds > 0.4) {
        fill = '#d7301f';
      }
      else if ( odds > 0.3) {
        fill = '#fc8d59';
      }
      else if ( odds > 0.2) {
        fill = '#fdcc8a';
      }
      else if ( odds > 0.1) {
        fill = '#fef0d9';
      }
      context.fillStyle = fill;
      context.fillRect (x, y , col_width, 10);

      fill = "#ffffff";
      // draw insert length
      if (length > 99) {
        fill = '#2171b5';
      }
      else if ( length > 49) {
        fill = '#6baed6';
      }
      else if ( length > 9) {
        fill = '#bdd7e7';
      }
      context.fillStyle = fill;
      context.fillRect (x, y + 12 , col_width, 10);
    }

    function draw_border(context, y, width) {
      context.beginPath();
      context.moveTo(0, y);
      context.lineTo(width, y);
      context.lineWidth = 1;
      context.strokeStyle = "#999999";
      context.stroke();
    }

    function draw_insert_odds(context, x, height, col_width, text, fontsize) {
      var y        = height - 20;
      var fill     = '#ffffff';
      var textfill = '#000000';

      if (text > 0.4) {
        fill     = '#d7301f';
        textfill = '#ffffff';
      }
      else if ( text > 0.3) {
        fill = '#fc8d59';
      }
      else if ( text > 0.2) {
        fill = '#fdcc8a';
      }
      else if ( text > 0.1) {
        fill = '#fef0d9';
      }


      context.font = fontsize + "px Arial";
      context.fillStyle = fill;
      context.fillRect (x, y - 10 , col_width, 14);
      context.textAlign = "center";
      context.fillStyle = textfill;
      context.fillText(text, x + (col_width / 2), y);

      //draw vertical line to indicate where the insert would occur
      if ( text > 0.1) {
        draw_ticks(context, x + col_width, height - 30, 0 - height - 30, fill);
      }
    }

    function draw_insert_length(context, x, y, col_width, text, fontsize) {
      var fill = '#ffffff';
      var textfill = '#000000';

      if (text > 99) {
        fill     = '#2171b5';
        textfill = '#ffffff';
      }
      else if ( text > 49) {
        fill = '#6baed6';
      }
      else if ( text > 9) {
        fill = '#bdd7e7';
      }
      context.font = fontsize +"px Arial";
      context.fillStyle = fill;
      context.fillRect (x, y - 10 , col_width, 14);
      context.textAlign = "center";
      context.fillStyle = textfill;
      context.fillText(text, x + (col_width / 2), y);
    }

    function draw_column_number(context, x, y, col_width, col_num, fontsize, right) {
      context.font = fontsize + "px Arial";
      if (right) {
        context.textAlign = "right";
      }
      else {
        context.textAlign = "center";
      }
      context.fillStyle = "#666666";
      context.fillText(col_num, x + (col_width / 2), y);
    }

    function draw_ticks(context, x, y, height, color) {
      color = (color) ? color :'#999999';
      context.beginPath();
      context.moveTo(x, y);
      context.lineTo(x, y + height);
      context.strokeStyle = color;
      context.stroke();
    }

    function attach_canvas(DOMid, height, width, id, canv_width) {
      var canvas = $(DOMid).find('#canv_' + id);

      if (!canvas.length) {
        $(DOMid).append('<canvas class="canvas_logo" id="canv_' + id + '"  height="'+ height +'" width="'+ width + '" style="left:' + canv_width * id + 'px"></canvas>');
        canvas = $(DOMid).find('#canv_' + id);
      }

      $(canvas).attr('width', width).attr('height',height);

      if(!isCanvasSupported()) {
        canvas[0] = G_vmlCanvasManager.initElement(canvas[0]);
      }

      return canvas[0];
    }

  }


  $.fn.hmm_logo = function(options) {
    options = (options) ? options : {};
    options.dom_element = $(this);
    var zoom = options.zoom || 0.3;

    var logo = new HMMLogo(options);
    logo.render(options);

    if(Modernizr.canvas) {

      var form = $('<form>');

      if( logo.scale_height_enabled ) {
        form.append('<button id="scale" class="button">Scale Toggle</button><br/>');
      }

      $(this).parent().after('<form><label for="position">Column number</label>' +
        '<input type="text" name="position" id="position"></input>' +
        '<button class="button" id="logo_change">Go</button>' +
        '</form>').after(form);

      $('#logo_reset').bind('click', function(e) {
        e.preventDefault();
        var hmm_logo = logo;
        hmm_logo.change_zoom({'target': hmm_logo.default_zoom});
      });

      $('#logo_change').bind('click', function(e) {
        e.preventDefault();
      });

      if (logo.zoom_enabled) {
        form.append('<button id="zoomout" class="button">-</button>'+
        '<button id="zoomin" class="button">+</button>');

        $('#zoomin').bind('click', function (e) {
          e.preventDefault();
          var hmm_logo = logo;
          hmm_logo.change_zoom({'distance': 0.1, 'direction': '+'});
        });

        $('#zoomout').bind('click', function (e) {
          e.preventDefault();
          var hmm_logo = logo;
          hmm_logo.change_zoom({'distance': 0.1, 'direction': '-'});
        });

      }

      $('#scale').bind('click', function(e) {
        e.preventDefault();
        var hmm_logo = logo;
        hmm_logo.toggle_scale();
      });

      $('#position').bind('change', function() {
        var hmm_logo = logo;
        if (!this.value.match(/^\d+$/m)) {
          return;
        }
        hmm_logo.scrollToColumn(this.value, 1);
      });

      $('#logo_graphic').bind('dblclick', function(e) {
        // need to get coordinates, then scroll to location and zoom.
        var offset = $(this).offset();
        var x = parseInt((e.pageX - offset.left), 10);
        var hmm_logo = logo;
        var half_viewport = ($('#logo_container').width() / 2);
        hmm_logo.scrollme.scroller.scrollTo(x - half_viewport, 0, 0);

        var current = hmm_logo.zoom;
        if (current < 1) {
          hmm_logo.change_zoom({'target':1});
        }
        else {
          hmm_logo.change_zoom({'target':0.3});
        }
      });

    }

    if(!Modernizr.canvas) {
      $('#logo_container').bind('scroll', function () {
        $(document).trigger("scrolledTo", [this.scrollLeft, 1, 1] );
      });
    }

    $(document).bind("scrolledTo", function(e, left, top, zoom) {
      var hmm_logo = logo;
      logo.render({target: left});
    });

    $(document).keydown(function(e) {
      if(!e.ctrlKey) {
        if (e.which === 61 || e.which == 107) {
          zoom += 0.1;
          logo.change_zoom({'distance': 0.1, 'direction': '+'});
        }
        if (e.which === 109 || e.which === 0) {
          zoom = zoom - 0.1;
          logo.change_zoom({'distance': 0.1, 'direction': '-'});
        }
      }
    });

  };
})( jQuery );
/*global Raphael*/
/*global $*/

Raphael.fn.pieChart = function (cx, cy, r, values, options) {
  'use strict';
  var defaults = {
    stroke: 1,
    //colors: ['#009dcc', '#a00', '#999']
    colors: ['#006600', '#999999', '#FFC200']
  };
  var settings = $.extend({}, defaults, options);
  var paper = this;
  var rad = Math.PI / 180;
  var chart = this.set();
  var angle = 0;
  var total = 0;
  var values_length = values.length;
  var index;

  var process = function (j) {
    if (values[j] === 0) {
      return;
    }
    var value = values[j];
    var angleplus = 360 * value / total;
    var p = sector(cx, cy, r, angle, angle + angleplus,
      {'fill': settings.colors[j], 'stroke': settings.stroke, 'stroke-width': 1, 'fill-opacity': 0.8, 'stroke-opacity': 0.8});
    angle += angleplus;
    chart.push(p);
  };

  var sector = function (cx, cy, r, startAngle, endAngle, params) {
    var x1 = cx + r * Math.cos(-startAngle * rad);
    var x2 = cx + r * Math.cos(-endAngle * rad);
    var y1 = cy + r * Math.sin(-startAngle * rad);
    var y2 = cy + r * Math.sin(-endAngle * rad);

    if (x1 === x2  && y1 === y2){
      return paper.circle(cx, cy, r).attr(params);
    } else {
      return paper.path(['M', cx, cy, 'L', x1, y1, 'A', r, r, 0, +(endAngle - startAngle > 180), 0, x2, y2, 'z']).attr(params);
    }
  };

  for (index = 0; index < values_length; index++) {
      total += values[index];
  }
  for (index = 0; index < values_length; index++) {
      process(index);
  }

  //add a transparent circle over the existing chart that will act as anchor for events
  chart.push(paper.circle(cx,cy, r).attr({'fill': settings.colors[1], 'stroke': settings.stroke, 'stroke-width': 0, 'fill-opacity': 0, 'stroke-opacity': 0}).toFront());
  return chart;
};
/********************************************************************
Used to build the taxonomy filter for Hmmerweb
********************************************************************/
  var site_url = document.location.origin + '/',
  pathname = document.location.pathname,
  reg =/Tools\/hmmer/,
  match = pathname.match(reg);
  if(match){
    site_url = document.location.origin +'/Tools/hmmer/';
  }
  console.log("we are here and should be fine");
!function ($) {
  "use strict";

  /*************************************************
   Tax Filter Tree
  *************************************************/
  /* represents a branch or leaf */
  var TaxNodeItem = function(parent, item) {
    this.init(parent, item);
  };

  TaxNodeItem.prototype = {
    constructor: TaxNodeItem,
    init: function (parent, item){
        var node, node_name;
        this.short_name = item['short'];
        this.long_name = item['long'];
        this.ncbi = item.ncbi;
        this.complete = item.complete;

        //create this node
        node = $('<li>').addClass("taxNodeItem");

        //add "check box"
        var cb_id = 'cb_' + this.ncbi;
        this.checkbox = $('<input id="'+ cb_id +'" type="checkbox" name="taxfilter" class="taxfilter_selection">');
        $(this.checkbox).val(this.ncbi);
        $(this.checkbox).on('click', this.do_checkbox_change);
        node.append(this.checkbox);
        var label = $("<label>").attr('for', cb_id).append($('<span>').addClass('check_image'));
        var tooltip_data = this.long_name +
          ' (taxid:<a class="ext" title="Link to taxonomy browser on NCBI site" href="http://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?id=' +
          this.ncbi + '">' +
          this.ncbi+'</a>)';
        node_name =  $('<span>').addClass("nodeName").html(this.short_name);
        label.attr('data-popover_data', tooltip_data);
        label.append(node_name);
        node.append(label);

        //add children
        if (item.children){
          //add node
          node.append(new TaxNode(node, item.children));

          //add the "+/-"
          $(node).prepend('<div class="expandable_marker more"></div>');
        }else {
          $(node).addClass('noChildren');
        }

        //add events & triggers
        $(node).children('div').on('click', this.do_toggle);
        $(node).children('ul').hide();

        $(parent).append(node);
    },
    do_toggle: function() {
        var parent_li = $(this).parent();
        var children = $(this).siblings('ul');
        var t = document.createTextNode('temp text');

        //stop from collapsing if no child node
        if(children.length === 0) {
          return;
        }

        //set the class on the expandable marker span
        var marker_span = $(parent_li).find('div:first');
        if ($(marker_span).hasClass('more')){
          $(marker_span).removeClass('more').addClass('less');
        } else {
          $(marker_span).removeClass('less').addClass('more');
        }

        //show/hide this nodes children
        $(children).toggle('slide');

        //show/hide this nodes parent's (the li) siblings
        $(this).parent().siblings('li').toggle('slide');

        //Reset decendent nodes (clears tree nav history)
        $(children).find('li').show();
        $(children).find('ul').hide();
        $(children).find('div.less').removeClass('less').addClass('more');

    },
    do_checkbox_change: function(){
        //clear partial_check classes for this branch
        //(if we are selecting or deselecting, all leaf nodes will be in same state)
        $(this).parent().find('input').removeClass("partial_check").removeClass("show_check");

        //set all decendents to same state
        $(this).parent().find('input').prop('checked', $(this).prop("checked"));

        //set checked class
        $(this).parent().find('input:checked').addClass("show_check");

        //check parent state
        $.fn.taxonomyTree.do_checkbox_parent_check(this);

        //update the selected items tracking...
        $('.taxTreeRoot').data('tax_tree').update_selected_items();

        //force IE to refresh the dom for the tree
        document.body.className = document.body.className;
      }
  };

  /* Tax Filter Tree Node */
  /* denotes a branch */
  var TaxNode = function(parent, source){
    this.init(parent, source);
  };

  TaxNode.prototype = {
    constructor: TaxNode,
    init: function(parent, source){

      //options should contain an array of items
      var node;

      node = $('<ul>').addClass('taxNode');

      $.each(source, function(index, item){
        new TaxNodeItem(node, item);
      });

      parent.append(node);

    }
  };

  /* Tax Filter Tree */
  /* container for all branch and leaf nodes */
  var TaxonomyTree = function (element, options){
    this.init(element, options);
  };

  TaxonomyTree.prototype = {
    constructor: TaxonomyTree,
    init: function (element, options) {
      this.type = "taxonomyTree";
      this.$element = $(element);
      this.options = this.getOptions(options);

      //get source (doing it this way allows for ajax function)
      this.options.source = typeof this.options.source == 'function' ?
        this.options.source.call(this) : this.options.source;

      new TaxNode(this.$element, this.options.source);
    },
    getOptions: function(options) {
      return $.extend({}, $.fn.taxonomyTree.defaults, options);
    },
    reset: function(target_element) {
      //clear the check boxes
      this.$element.find('input').attr('checked', false);
      this.$element.find('input').removeClass('partial_check').removeClass("show_check");

      //collapse the tree
      //Reset decendent nodes (clears tree nav history)
      this.$element.find('ul:first').find('li').show();
      this.$element.find('ul:first').find('ul').hide();
      this.$element.find('ul:first').find('div.less').removeClass('less').addClass('more');

      //reset the arrows
      $('div.less').removeClass('more').addClass('less');

      this.update_selected_items();
    },
    update_selected_items: function(){
      $('#tax_included').val(this.get_ids_selected(this.$element));
    },
    get_ids_selected: function(node_ele){
      var checkbox,
        selected_ids = [],
        that = this;

      $(node_ele).find('ul:first').children('li').each(function(index, item){
        //check if it is checked.. add to array if is
        checkbox = $(item).find('input:checkbox:first');
        if (checkbox.is(':checked')){
          selected_ids.push(checkbox.val());
        } else if (checkbox.hasClass('partial_check')) {
          selected_ids.push(that.get_ids_selected(item));
        }
      });
      return selected_ids.join();
    }
  };

  $.fn.taxonomyTree = function (options) {
    $(this).addClass('taxTreeRoot');
    $(this).data('tax_tree', new TaxonomyTree(this, options));

    //add tooltips to tree
    $('.taxNodeItem > label').each(function(){
      $(this).qtip({
        content: {
          text: $(this).attr('data-popover_data')
        },
        style: {
          tip: {
            corner: 'left center'
          },
          classes: "ui-tooltip-hmmer ui-tooltip-rounded auto_width"
        },
        show: {
          solo: true,
          event: "mouseover"
        },
        hide: {
          fixed: true,
          delay: 1000,
          event: "mouseout"
        },
        position: {
          at: 'center right',
          my: 'center left',
          target: $(this)
        }
      });
    });
  };

  $.fn.taxonomyTree.defaults = {
    source: []
  };

  $.fn.taxonomyTree.do_checkbox_parent_check = function(current_node){

      var this_li = $(current_node).parent();
      var this_ul = $(this_li).parent();
      var parent_li = $(this_ul).parent();
      var parent_checkbox = $(parent_li).children('input');

      //check if parent node is in tree
      if (!$(parent_li).is('li')){
        return;
      }

      //check if all items at this level are checked
      //set parent (checked &/ class)
      var count_checked = $(parent_li).find('ul input:checked').size();
      var total_checkboxes = $(parent_li).find('ul input').size();
      if ( total_checkboxes == count_checked){
        $(parent_checkbox).prop('checked', 'checked');
        $(parent_checkbox).removeClass('partial_check').addClass("show_check");
      } else {
        $(parent_checkbox).prop('checked', '');
        if (count_checked > 0){
          $(parent_checkbox).removeClass("show_check").addClass('partial_check');
        } else {
          $(parent_checkbox).removeClass('partial_check').removeClass("show_check");
        }
      }

      //do it again...
      $.fn.taxonomyTree.do_checkbox_parent_check(parent_checkbox);
  };

  /*************************************************************
  Tax filter lookup
  extends twitter bootstaps typeahead
  *************************************************************/
  var TaxIdLookup = function(element, options) {
    /* duplicated from typeahead since type ahead does not impliment init */
    this.$element = $(element);
    this.options = $.extend({}, $.fn.typeahead.defaults, options);
    //this.options.item = "<li><span class='left'></span></li>"
    this.matcher = this.options.matcher || this.matcher;
    this.sorter = this.options.sorter || this.sorter;
    this.highlighter = this.options.highlighter || this.highlighter;
    this.updater = this.options.updater || this.updater;
    this.source = this.options.source;
    this.$menu = $(this.options.menu);
    this.shown = false;
    this.selected_items = [];
    this.listen();
    this.number_selected = 0;
    this.options.max_selected = 10;
  };

  TaxIdLookup.prototype =  $.extend({}, $.fn.typeahead.Constructor.prototype, {
    constructor: TaxIdLookup,
    reset: function() {
      this.selected_items = [];
      this.update_selected_items();
    },
    select: function () {
      this.include_item();

      //clear the input box
      this.$element.val("").change();

      return this.hide();
    },
    process: function (items){
      if (this.number_selected >= this.options.max_selected){
        return;
      }
      var that = this;

      $(items).map(function(i, item){
        item.display_name =  item['name']+ '<span class="taxid"> (taxid:'+item['taxid']+')</span>';
      });

      if (!items.length) {
        if (this.shown){
          this.hide();
        }
        return;
      }

      return this.render(items).show();
    },
    render: function(items){
        var that = this,
          node,
          control_span,
          inclusion;

        items = $(items).map(function (i, item) {
          //create the new item
          i = $(that.options.item);

          //add the attributs
          i.attr('data-display_name', item.display_name);
          i.attr('data-taxid', item.taxid);
          i.attr('data-lft', item.lft);
          i.attr('data-rgt', item.rgt);
          i.attr('data-name', item.name);

          //set the class and parent_item attr
          inclusion = that.get_inclusion_item(item.lft);
          var prefix = "";
          if (inclusion != undefined) {
            i.attr('data-ancestor', inclusion);
            prefix = "<span class='before'>Exclude: </span>";
            i.addClass('exclusion');
          } else {
            i.addClass('inclusion');
            prefix = "<span class='before'>Include: </span>";
          }

          //set the content
          i.find('a').html(prefix + item.display_name);

          return i[0];
        });

        items.first().addClass('active');
        this.$menu.html(items);
        this.$menu.find('li span:first-child').on('click', $.proxy(this.click, this));
        return this;
    },
    get_inclusion_item: function(lft){
        var including_items,
          item_class;

        //is this item included in previously selected?
        including_items = new Array();
        $(this.selected_items).each(function(index, item){
          if(parseInt(item.lft,10) <= parseInt(lft,10) && parseInt(item.rgt,10) >= parseInt(lft,10)){
            including_items.push(index);
        }}).get();

        return including_items[0];
    },
    include_item: function(item){
        var item_attributes,
          $item,
          that = this,
          temp_items,
          temp_index;

        //get the item selected if not passed
        if(!item){
          item = $('#taxfilter_content .active:first')[0];
        }
        $item = $(item);

        //get the attributes
        item_attributes = {};
        item_attributes['taxid'] = $item.attr('data-taxid');
        item_attributes['lft'] = $item.attr('data-lft');
        item_attributes['rgt'] = $item.attr('data-rgt');
        item_attributes['display_name'] = $item.attr('data-display_name');
        item_attributes['name'] = $item.attr('data-name');

        //add to selected_items
        if($item.hasClass('inclusion')){
          item_attributes['exclusions'] = [];

           //if inclusion, make sure we don't need to replace existing
          //find previously selected items(psi) covored by this item
          temp_items = this.selected_items;
          temp_index = 0;
          $(this.selected_items).each(function(index, psi){
            if (parseInt(psi.lft, 10) >= parseInt(item_attributes['lft'], 10) && parseInt(psi.rgt,10) <= parseInt(item_attributes['rgt'],10) ){
              item_attributes.exclusions = item_attributes.exclusions.concat(psi.exclusions);
              temp_items.splice(temp_index,1);
              temp_index = temp_index - 1;
            }
            temp_index = temp_index + 1;
          });
          this.selected_items = temp_items;
          this.selected_items.push(item_attributes);
        } else {
          //remove exclusions in new range
          temp_items = this.selected_items[$item.attr('data-ancestor')].exclusions;
          temp_index = 0;
          $(this.selected_items[$item.attr('data-ancestor')].exclusions).each(function(index, pse){
            if (pse.lft >= item_attributes['lft'] && pse.rgt <= item_attributes['rgt'] ){
              temp_items.splice(temp_index,1);
              temp_index = temp_index - 1;
            }
            temp_index = temp_index + 1;
          });
          this.selected_items[$item.attr('data-ancestor')].exclusions = temp_items;
          this.selected_items[$item.attr('data-ancestor')].exclusions.push(item_attributes);
        }
        //update the selected items display
        this.update_selected_items();

    },
    remove_selected_item: function(taxId){
      //remove item from this.selected_items
      var temp_items,
        temp_items2;

      temp_items = this.selected_items;
      $(this.selected_items).each(function(index, item){
        if (item.taxid == taxId){
          temp_items.splice(index,1);
          return;
        } else {
          temp_items2 = item.exclusions;
          $(item.exclusions).each(function(index2, item2){
            if (item2.taxid == taxId){
              temp_items2.splice(index2, 1);
              return;
            }
          });
          item.exclusions = temp_items2;
        }
      });
      this.selected_items = temp_items;

      //update selected items displau
      this.update_selected_items();
    },
    update_selected_items: function(){
      var parent_node,
        child_node,
        container,
        content,
        child_content,
        exclusions,
        excluded_child,
        remove_link,
        that = this,
        included_ids =[],
        excluded_ids =[];

      container = $('#selected_taxids');
      parent_node = "<ul>";
      child_node = "<li>";
      content = $(parent_node);
      $(this.selected_items).each(function(index, included_item){
        content.append(function(){
          child_content = $(child_node);
          child_content.attr('data-taxid', included_item.taxid);
          child_content.append($('<span> '+ included_item.display_name +' </span>'));
          var title_text = "Remove " + included_item.name;
          if (included_item.exclusions.length > 0){
            title_text = title_text + " and it's exclusions";
          }
          remove_link = $('<a class="right pictos" title="'+ title_text +'">D</a>').on(
            'click',$.proxy(that.remove_selected_item, that, included_item.taxid));
          child_content.append(remove_link);
          included_ids.push(included_item.taxid);
          if (included_item.exclusions.length > 0){
            child_content.append(function(){
              exclusions = $(parent_node);
              $(included_item.exclusions).each(function(index, excluded_item){
                excluded_child = $(child_node);
                excluded_child.attr('data-taxid', excluded_item.taxid);
                excluded_child.append($('<span><span class="before">But not:</span> '+ excluded_item.display_name +' </span>'));
                remove_link = $('<a class="right pictos" title="Remove ' + excluded_item.name + '">D</a>').on(
                  'click',$.proxy(that.remove_selected_item, that, excluded_item.taxid));
                excluded_child.append(remove_link);
                exclusions.append(excluded_child);
                excluded_ids.push(excluded_item.taxid);
              });
              return exclusions;
            });
          }
          return child_content;
        });
      });
      $(container).html(content);

      $('#tax_included').val(included_ids.join(','));
      $('#tax_excluded').val(excluded_ids.join(','));
      this.number_selected = included_ids.length + excluded_ids.length;

      if (this.number_selected === 0){
        $(container).hide();
      } else {
        $(container).show();
      }
    }
  });

  $.fn.taxIdLookup = function(options){
    $(this).data('taxidlookup', new TaxIdLookup(this, options));
  };

  $.resetTaxonomyFilters = function(){
    if (!$('#taxfilter_content').hasClass('loaded')) return;
    var reset1 = $.proxy($('.taxidsearch').data('taxidlookup').reset, $('.taxidsearch').data('taxidlookup'));
    var reset2 = $.proxy($('#tax_filter').data('tax_tree').reset, $('#tax_filter').data('tax_tree'));
    reset1();
    reset2();
  };

}(window.jQuery);

/****************************************************
Setup
*****************************************************/
loadTaxTree = function(e){
  if ($('#taxfilter_content').hasClass('loaded')){
    return;
  }

  $('#tax_filter').taxonomyTree({
    source: function(){
      var returned_json;
      $.ajax({
        url: site_url+'/static/taxonomy/taxon.json',
        dataType: 'json',
        async: false,
        success: function(json){returned_json = json;}
      });
      return returned_json;
    }
  });
  $('#taxfilter_content').addClass('loaded');
}

$(document).on('click','label[for=tax_tree_radio]', loadTaxTree);

$(document).ready(function(){
  var site_url = document.location.origin + '/',
  pathname = document.location.pathname,
  reg =/Tools\/hmmer/,
  match = pathname.match(reg);
  if(match){
    site_url = document.location.origin +'/Tools/hmmer/';
  }
  $('.taxidsearch').taxIdLookup({
    minLength: 3,
    items: 15,
    source: function (query, process) {
      return $.ajax({
        url: site_url+'/autocomplete/taxonomyid',
        type: 'get',
        data: {q: query, timestamp: Math.floor(+new Date() / 1000), included: $('#tax_included').val(), excluded: $('#tax_excluded').val()},
        dataType: 'json',
        success: function (results) {
          process(results);
        }
      });
    }
  });

  //enable the add all link
  $('.include-all-taxa').bind('click',
    function(e){
      e.preventDefaults;

      //easiest way is to fake out the tax search widget to think we clicked an item in the typeahead dropdown
      //requires that a selected item be passed.. so create a fake one
      var all_item = $('<div>');
      all_item.attr('data-taxid', '1');
      all_item.attr('data-lft', '0');
      all_item.attr('data-rgt', '99999999');
      all_item.attr('data-display_name', 'All Organisms');
      all_item.attr('data-name', 'All Organisms');

      all_item.addClass('inclusion');

      //We need the call to look like it was initiated internally, so proxy it.
      var include = $.proxy($('.taxidsearch').data('taxidlookup').include_item, $('.taxidsearch').data('taxidlookup'));

      //add the item
      include(all_item);
    });

  //stop the search field from trying to submit the form when enter is pressed
  $('.taxidsearch').keydown(function(event){
        if(event.keyCode == 13) {
      event.preventDefault();
      return false;
    }
  });

  //disable tax filter for some db selections
  $("input[name='seqdb']").on('click', function(e){
    var target = e.target;

    if ($(target).hasClass('disable_tax_filter')){
      $('#taxfilter_content').addClass('disabled');
    } else {
      $('#taxfilter_content').removeClass('disabled');
    }
  });

  $('.disable_tax_filter').each(function(index, node){
    if ($(node).prop('checked')){
      $('#taxfilter_content').addClass('disabled');
    }
  });
})

/****************************************************
//reload tax filter from form data
*****************************************************/

$('document').ready(function(){
   var reload_func = function(tax_data){
     if ( tax_data !== undefined && tax_data.length > 0){
       //Expand the taxonomy filter section
       $('#taxfilter_content').addClass('reloading');
       var e = {};
       $('.taxonomy legend span').click();

       //Get the data
       var json_data = $.parseJSON(tax_data);
       var included_ids = json_data['tax_included'];
       var excluded_ids = json_data['tax_excluded'];
       var include = $.proxy($('.taxidsearch').data('taxidlookup').include_item, $('.taxidsearch').data('taxidlookup'));
       var get_inclusion = $.proxy($('.taxidsearch').data('taxidlookup').get_inclusion_item, $('.taxidsearch').data('taxidlookup'));
       var make_display_name = function(name, taxid){
         var dn = name + '<span class="taxid"> (taxid:'+taxid+')</span>'; 
         return name
       };
       var add_items = function(taxid, tax_item_data, mode){

         var inc_item = $('<div>');
         if (taxid === '1') {
           inc_item.attr('data-taxid', '1');
           inc_item.attr('data-lft', '0');
           inc_item.attr('data-rgt', '99999999');
           inc_item.attr('data-display_name', 'All Organisms');
           inc_item.attr('data-name', 'All Organisms');
         } else {
           inc_item.attr('data-taxid', taxid);
           inc_item.attr('data-lft', tax_item_data['lft']);
           inc_item.attr('data-rgt', tax_item_data['rgt']);
           inc_item.attr('data-display_name', make_display_name(tax_item_data['name'], taxid));
           inc_item.attr('data-name', tax_item_data['name']);
         }
         if (mode == "exclusion") {
           inc_item.attr('data-ancestor', get_inclusion(tax_item_data['lft']));
         }
         inc_item.addClass(mode);
         include(inc_item);
       };
       //Which widget?
       var filterType = $('#last_tab_clicked').val();
       if (filterType === undefined || filterType == '') {
         filterType = 'search';
       };
       
       if (filterType == "search"){
         $.each(included_ids, function(taxid, tax_item_data) {
           add_items(taxid, tax_item_data, "inclusion");
         });
         //add excluded items
         if (excluded_ids !== undefined) {
           $.each(excluded_ids, function(taxid, tax_item_data) {
              add_items(taxid, tax_item_data, "exclusion");
            });
          }
          $('#tax_search_radio').prop('checked', 'checked');
          $('#tax_search_radio').closest('li').addClass('selected');
          $('#tax_tree_radioOpt').closest('.group').hide();
       } else {
          loadTaxTree(e);
          $($("#tax_included").val().split(',')).each(function(index, taxid){
             var cb_id = "#cb_" + taxid;
             $(cb_id).click();
          });
          $('#tax_tree_radio').prop('checked', 'checked');
          $('#tax_tree_radio').closest('li').addClass('selected');
          $('#tax_search_radioOpt').closest('.group').hide();
       }
       $('#taxfilter_content').removeClass('reloading');
     } else {
       $('#tax_search_radio').click();
     }
   }
   
  //check if we need to get the taxfilter_data
  if (( $('#taxfilter_data').val() === undefined || $('#taxfilter_data').val().length == 0 ) && 
     (( $('#tax_included').val() !== undefined && $('#tax_included').val().length > 0 ) || 
      ( $('#tax_excluded').val() !== undefined && $('#tax_excluded').val().length > 0))) {
      
       var filterType = $('#last_tab_clicked').val();
       if (filterType === undefined || filterType == '') {
         filterType = 'search';
       };
       $.ajax({
         url: site_url+'/search/taxfilter_data?nocache=',
         data: {taxFilterType: filterType, 
                tax_included: $('#tax_included').val(),
                tax_excluded: $('#tax_excluded').val()},
         type: 'POST',
         async: false,
         success: function(json){
           reload_func(json);
         }
       });
      
  } else {
    reload_func($('#taxfilter_data').val());
  };
});



/* global jQuery, Raphael, taxTree, sparkMax */

(function( $ ){
  "use strict";

  //defaults
  var width  = 800;
  var height = 165;
  var canvas = null;
  var nodes = [];
  // var cols = [];
  var depth = 4;
  var row   = 0;
  var drow  = 0;
  var container = null;

  // for (var d = 0; d <= depth; d++) {
  //   cols.push(0);
  // }

  $.fn.drawTaxonTree = function (tree, id, canv) {
    var node = findNode(id, tree);
    container = this;

    if (node) {

      //work out canvas height
      drow = 0;
      plotDimensions(node, depth, 0, 1);
      var glyph_extent = (drow * 40 ) + 45;
      height = glyph_extent;

      if (canv) {
        $(container).children().remove();
      }

      canvas = Raphael(this.get(0), width, height);
      row = 0;
      if (node[6] && node[6] != node.id) {
        // if node has a parent, draw a back arrow.
        drawReverseArrow(node);
        drawBreadCrumbTrail(node, tree);
      }
      layoutNodes(node, depth, 0, 1);
      showOrHideTableRows(node);
      renderTitle();
    }

    return this;
  };

  var showOrHideTableRows = function(node) {
    // Change the taxid variable in the restrict_all form to equal
    // the new max for this node
    var link = $('.dl_phmmer').attr('href');
    var score_link = window.location.href;

    // if score_link ends with taxonomy, strip it
    score_link = score_link.replace(/\/taxonomy[\/]?$/, '');

    if (node[1] > 1) {

      score_link = score_link + '/taxonomy/' + node[1];

      // change the taxid in the download link to equal the new root
      if (link.match(/taxon\//)) {
        link = link.replace(/taxon\/\d*/, 'taxon/' + node[1]);
      }
      else {
        link = link + '/taxon/' + node[1];
      }
    }
    else {
      link = link.replace(/\/taxon\/\d*/, '');
    }
    $('.dl_phmmer').attr('href', link);

    score_link = score_link + '/score';
    $('#taxon_link').attr('href', score_link);

    var species = {};
    // recurse through tree below current node and add species leaves
    // to the species hash.
    findAllLeafNodeTaxIds(node, species);
    // then use that array to loop over the table and hide rows that
    // don't have a tax id in the species hash.
    $('.resultTable tbody tr').each(function() {
      var row = $(this);
      if (species[row.attr('id')]) {
        row.show();
      }
      else {
        row.hide();
      }
    });
  };

  var findAllLeafNodeTaxIds = function (node, hashObj) {
    if (node[0]) { // not a leaf node, keep going
      for (var i = 0; i < node[0].length; i++) {
        findAllLeafNodeTaxIds(node[0][i], hashObj);
      }
    }
    else {
      hashObj['taxon_' + node[1]] = 1;
    }
  };



  var drawBreadCrumbTrail = function (node, tree) {
    var parents = [];
    // get parent obj and unshift onto parents
    // recurse up tree until we hit root, shift onto parents as we go.
    findParents(node[6], tree, parents);
    // for each entry in parents draw breadcrumb trail
    var x = 0, y = 10;
    for (var i = 0; i < parents.length; i++) {
      var t = renderParent(parents[i], x, y);
      var width = t.getBBox().width + 5;
      if ((x + width) > canvas.width) {
        //breadcrumb line == too long, need to wrap.
        x = 10;
        y += 12;
        t.remove();
        t = renderParent(parents[i], x, y);
        width = t.getBBox().width + 5;
      }
      x += width;
    }
  };

  var renderParent = function(node, x, y) {
    var name = node[2];


    var t = canvas.text(x, y, name + ' (' + node[5] + ')' + ' /')
      .attr({'text-anchor': 'start'})
      .click(function () {
        canvas.clear();
        container.drawTaxonTree(taxTree, node[1], canvas);
        window.scrollTo(0,0);
      });
    canvas.rect(x, y - (t.getBBox().height / 2), t.getBBox().width, t.getBBox().height)
      .attr({'stroke':'none'})
      .click(function () {
        canvas.clear();
        container.drawTaxonTree(taxTree, node[1], canvas);
        window.scrollTo(0,0);
      });
    return t;
  };

  var findParents = function(id, tree, parents) {
    var node = findNode(id, tree);
    parents.unshift(node);

    // if the parent id is null we have root, so we are done
    if (node[6] != null) {
      findParents(node[6], tree, parents);
    }
  };

  var drawReverseArrow = function (node) {
    var arrowPath = 'M20 29l40 0c5 0 5 12 0 12l-40 0l0 3l-15 -9l15 -9l0 3';
    var st = canvas.set();
    var ar = canvas.path(arrowPath)
      .attr({stroke: '#aaa', fill: '#aaa'});
    var tbox = canvas.rect(17, 31, 45, 8, 4)
          .attr({stroke:'none',fill:'#fff'});
    var label = canvas.text(39, 35, 'back');
    st.push(ar, tbox, label)
      .click(function () {
        canvas.clear();
        container.drawTaxonTree(taxTree, node[6], canvas);
        window.scrollTo(0,0);
      });

  };

  var drawArrow = function(node, glyph, x , y) {
    var st = canvas.set();
    var arrowPath = 'M' + (x + glyph.getBBox().width + 10) + ' ' + (y - 6) + 'l40 0l0 -3l15 9l-15 9l0 -3l-40 0 c-5 0 -5 -12 0 -12';
    var moreCount = node[9];
    st.push(
      canvas.path(arrowPath)
        .attr({stroke: '#aaa', fill: '#aaa'}),
      canvas.rect((x + glyph.getBBox().width + 10), (y - 4), 45, 8, 4)
        .attr({stroke:'none',fill:'#fff'}),
      canvas.text((x + glyph.getBBox().width + 30), (y), moreCount)
    ).click(function () {
      canvas.clear();
      container.drawTaxonTree(taxTree, node[1], canvas);
      window.scrollTo(0,0);
    });
  };

  //initial loop over the data to find dimensions for the tree graphic 
  var plotDimensions = function(node, level, col, id){
    if (level > 0) {

      if (!node[5]) {
        return;
      }

      if (!node[0] || level == 1) {
        drow++;
      }

      // cols[col]++;

      //increment all previous columns
      // for (var c = 0; c < col; c++){
      //   cols[c] = cols[col];
      // }

      if (node[0] && node[0].length > 0) {
        for (var i = 0; i < node[0].length; i++) {
          plotDimensions(node[0][i], level - 1, col + 1, id);
        }
      }
    }
  };

  // function to show node plus n levels of children if present
  var layoutNodes = function(node, level, col, id, parentNode){
    if (level > 0) {

      var x = (col * 140) + 70;
      var y = (row * 40) + 35;

      if (!node[5]) {
        return;
      }

      if (y > height) {
        height = y + 35;
      }

      var glyph = renderNode(node, x, y);

      renderSparkBar(node, x, y);

      if (!node[0] || level == 1) {
        row++;
      }

      // draw the "more" arrows
      if (level == 1 && node[0]) {
        drawArrow(node,glyph,x,y);
      }

      if (parentNode) {
        linkNodes(parentNode, glyph);
      }

      // cols[col]++;

      //increment all previous columns
      // for (var c = 0; c < col; c++){
      //   cols[c] = cols[col];
      // }

      if (node[0]) {

        for (var i = 0; i < node[0].length; i++) {
          layoutNodes(node[0][i], level - 1, col + 1, id, glyph);
        }
      }
    }
  };

  // link two nodes together with a nice curve
  var linkNodes = function (parent, child) {
    var px  = parent.attrs.x + (parent.getBBox().width) + 5;
    var cx  = child.attrs.x - 2;
    var cy1 = parseInt(parent.attrs.y);
    var cy2 = parseInt(child.attrs.y);
    var cx1 = parseInt(((cx - px) / 2) + px);
    var cx2 = cx1;

    var path = 'M' + px + ' ' + parent.attrs.y + 'C' + cx1 + ' ' + cy1 + ' ' + cx2 + ' ' + cy2 + ' '  + cx + ' ' + child.attrs.y;
    canvas.path(path).attr({stroke: "#900"});
  };

  // recursive function to find node with given id
  var findNode = function (id, tree) {
    var result;
    if (tree[1] == id) {
      result = tree;
    }
    else {
      for (var child in tree[0]) {
        var node = findNode( id, tree[0][child]);
        if (node) {
          result = node;
          break;
        }
      }
    }
    return result;
  };

  //function to draw the nodes on a canvas
  var renderNode = function(node, x, y) {
    var name = node[2];

    var label = name + '(' + node[5] + ')';

    var t = canvas.text(x, y, label).attr({'text-anchor': 'start'})
      .click(function () {
        canvas.clear();
        container.drawTaxonTree(taxTree, node[1], canvas);
        window.scrollTo(0,0);
      });

    // if name + node count  > col_width and it has children
    // then truncate it.
    var labelWidth = t.getBBox().width;
    if(labelWidth > 140 && node[0]) {
      // work out the percentage of the label that will fit into the
      // desired width
      var percent =  140 / labelWidth;
      // split the label into an array
      var textArray = name.split('');
      // grab the section of the array that is equal to the previously
      // defined percentage minus some additional space for numbers and the
      // ellipse.
      var ellipsedText = textArray.slice(0, (textArray.length * percent) - 6).join('') + "...";
      // add the numbers back on
      ellipsedText += '(' + node[5] + ')';
      // replace the text that is too long with the truncated text.
      t.attr('text', ellipsedText);
    }


    canvas.rect(x, y - (t.getBBox().height / 2), t.getBBox().width, t.getBBox().height)
      .attr({'stroke':'none'})
      .click(function () {
        canvas.clear();
        container.drawTaxonTree(taxTree, node[1], canvas);
        window.scrollTo(0,0);
      });
    nodes.push(t);
    return t;
  };

  /*var renderSparkLine = function(node, x, y, level) {
    // replace array with data from the node when present

    var array = node[7];
    var max   = sparkMax[node[8]];
    //var scale = 20;
    var path = 'M' + x + ' ' + (y + 20) + ' ';
    var scaled = [];
    for (var i = 0; i < array.length; i++) {
      scaled[i] = ((array[i]/max) * 15);
    }

    for (var j = 0; j < scaled.length; j++) {
      if(j > 0 ){
        var vert = (-(scaled[j] - scaled[j-1]));
        path += ( 'l 2 ' + vert + ' ' );
      }
    }

    var l = canvas.path(path).attr({stroke: '#ccc'});
    return l;
  };*/

  var renderSparkBar = function(node, x, y) {

    //This is the data for hit distribution
    var array = node[7];
    //This is the max from the level
    var max   = sparkMax[node[8]];

    //Draw a horizontal line, 2 pixels below the graph
    var path = 'M' + x + ' ' + (y + 22) + ' l60 0';
    var l = canvas.path(path).attr({stroke: '#ccc'});

    //Our graph height
    y += 20;
    for (var i = 0; i < array.length; i++) {
      var h = (10 * array[i]) / max;
      if ( h > 0 ) {
        //draw each block in the graph
        canvas.rect( x + (i * 2), (y - h ), 1, h)
          .attr({stroke: '#333', fill: '#333', 'stroke-opacity':0.8});
      }
    }

    return l;
  };

  var renderTitle = function () {
    //$(container).prepend('<h5 class="centered">Taxonomic distribution of all search hits <a id="taxtreehelp" href="[% c.uri_for("/help/result#taxtree") %]"><img src="[% c.uri_for("/static/images/help.gif") %]"/></a></h5><div class="help"></div> ');
    $(container).prepend('<h5 class="centered">Taxonomic distribution of all search hits <a id="taxtreehelp" href="/Tools/hmmer/help/result#taxtree"><img src="/Tools/hmmer/static/images/help.gif"/></a></h5><div class="help">This species tree shows all the sequence hits distributed across a tree derived from the NCBI taxonomy database.</div>');
    $(container).find('h5 a').tooltip('above');
  };

})( jQuery );
/** @preserve
 * HMMER website functions.
*/

(function($) {
  var site_url = document.location.origin + '/',
  pathname = document.location.pathname,
  reg =/Tools\/hmmer/,
  match = pathname.match(reg);
  var query_length;
  if(match){
    site_url = document.location.origin +'/Tools/hmmer/';
  }
  console.log("in hmmer.js, site_url is "+site_url)
  $.ajaxSetup({
    // set a default timeout of 10 seconds for all ajax methods.
    timeout: $('document').timeout
  });

  $('#error').ajaxError(function (e, request, settings, exception) {
    $(this).children().remove().end().addClass('warning').append('<p>There was an error dynamically loading content for this page. Refreshing the page may clear this problem. If it continues to persist, please contact <a href="mailto:hmmer-help@ebi.ac.uk">us</a>.</p>');
  });

  $(window).unload(function () {
    // try to make sure buttons aren't disabled if someone clicks back button.
    $('form input[type=submit]').removeAttr('disabled');
    $('.loading').remove();
  });

  $('document').ready(function () {
    $('.nav_toggle').click(function () { $('#tabs').toggleClass('tab_hidden'); });
    $('.subnav_toggle').click(function () { $('#subnav').toggleClass('tab_hidden'); });
    $('.menu').nav_menu();

    /**** show hidden selections for jackhmmer *******************/
    $('.js_show').show().find('input').click(function () {
      var input = $(this),
        uuid = input.closest('table').attr('jobid'),
        status = input.prop('checked');

      $.post(site_url+'/results/' + uuid + '/score', {
        seq: input.attr('value'),
        status:  status,
        threshold: input.hasClass('above')
      }, function (data) {
        if (status === false && input.hasClass('above')) {
          input.closest('tr').addClass('removed');
        } else {
          input.closest('tr').removeClass('removed');
        }
      }, 'json');
    });

    /********************* init form settings ********************/

    //Autocomplete

    /* will call a url like so :
       /autocomplete/accorid?q=asr&limit=21&timestamp=1364304164428
       where q is the query string and limit is the number of results to return. */

    $('#acc, #hmm_acc, .all_acc').attr('autocomplete', 'off');
    $('#acc').typeahead({
      minLength: 3,
      items: 21,
      source: function (query, process) {
        return $.ajax({
          url: site_url+'/autocomplete/accorid',
          type: 'get',
          data: {q: query, timestamp: Math.floor(+new Date() / 1000)},
          dataType: 'text',
          success: function (results) {
            return process(results.split('\n'));
          }
        });
      }
    });

    $('#hmm_acc').typeahead({
      minLength: 1,
      items: 21,
      source: function (query, process) {
        return $.ajax({
          url: site_url+'/autocomplete/hmmaccorid',
          type: 'get',
          data: {q: query, timestamp: Math.floor(+new Date() / 1000)},
          dataType: 'text',
          success: function (results) {
            return process(results.split('\n'));
          }
        });
      }
    });

    $('.all_acc').typeahead({
      minLength: 1,
      items: 21,
      source: function (query, process) {
        return $.ajax({
          url: site_url+'/autocomplete/allaccorid',
          type: 'get',
          data: {q: query, timestamp: Math.floor(+new Date() / 1000)},
          dataType: 'text',
          success: function (results) {
            return process(results.split('\n'));
          }
        });
      }
    });

    $('#pfamEvalue').attr('disabled', true);

    // insert the advanced search toggle
    if($('.advField').length > 0){
      var button = $('<button id="advOpts" class="button">Advanced</button>').click(function(e) {
        $('.advField').show();
        $(this).hide();
        e.preventDefault();
      });

      $('.advField').after($('<div class="centered">').append(button));
    }

    // enable forms on page reload.
    $('form input[type=submit]').removeAttr('disabled');
    $('.loading').remove();

    $('form input[type=reset]').click(function(){
      $('form input[type=submit]').removeAttr('disabled').removeClass('disabled-button');
      $('.loading').remove();
    });

    $('form').submit(function(){
      if ($(this).attr('id') !== 'customize') {
        $('input[type=submit]', this).attr('disabled', 'disabled').addClass('disabled-button').after('<span class="loading">loading, please wait...</span>');
      }
    });

    /******************* init form validation ********************/

    $('form.download').bind('validate', function() {
      if($(this).validateForm()) {
        $(this).submit();
      }
    });

    $('form.search').bind('validate', function() {
      // need to clear out the hidden seq input methods so we don't get a conflict.
      $('.seqInput[id!="seq' + $('.seq_options .selected').attr('alt') + '"]').children('input, textarea').val('').text('');

      if($(this).validateForm()) {
        $(this).submit();
      }
    });

    $('#subbutton').click(function() {
      $('#tax_filter').find('input').attr('disabled', 'disabled');
      $(this).closest('form').trigger('validate');
      $('#tax_filter').find('input').removeAttr("disabled");
      return false;
    });

    /******************* modify row count warning ********************/
    var advrowslink = $('<a>Advanced</a>').click(function() {
      $('.adv').click();
    });

    var restoredefaults = $('<a>restoring the default row count</a>').click(function() {
      $('#r100').click();
      $('#info').empty().removeClass('warning');
    });

    $('#row_warn_replace').empty().append("We suggest clicking on the '").append(advrowslink).append("' link and reducing the number of rows to less than 1000 or ").append(restoredefaults).append('.');

    /***************** setup tabs***********************/
    // find all the sections that need to be tabbed
    $('.tabbed').each(function () {
      var tabbed = $(this),
        // put a new navigation list before the first child fieldset
        nav_list = $('<ul>').addClass('tabbed_nav clearfix');
      tabbed.find('fieldset:first').before(nav_list);
      // for each legend add an item to the tabbed_nav list
      tabbed.find('fieldset legend').each(function (i) {
        nav_list.append($('<li>').append($(this).html()));
      });
      // remove the redundant legends and add a group class for formating
      tabbed.find('fieldset').addClass('group').find('legend').remove();

      //add confirmation
      if (tabbed.parent().hasClass('taxonomy')){
        $(tabbed).find('li').each(function(){
          var that = $(this);
          var message = $('<p/>', { text: "This will clear your current selections, are you sure?" }),
          ok = $('<input>', {
            "type": 'button',
            "value": 'Ok',
            "class": 'confirm_ok',
            "click": function() {
              //reset taxonomy filter
              $.resetTaxonomyFilters();

              //change the tab..
              e = {target: that.find('input')[0],
                   isPropagationStopped: function(){return false;}
                  };
              tab_click(e);
              $('.qtip').qtip('hide');
            }
          }),
          cancel = $('<input>', {
            "type": 'button',
            "value": 'Cancel',
            "class": 'confirm_cancel',
            "click": function() {
              //do nothing (well... hide the qtip)
              $('.qtip').qtip('hide');
            }
          });
          var content = $('<div>').append(message).append(ok).append(cancel);

          var tab = $(this);
          $(this).qtip({
            content: {
              text: content,
              title: "Please confirm"
            },
            position: {
              my: 'bottom center',
              at: 'top center'
            },
            style: {
              classes: "ui-tooltip-hmmer ui-tooltip-rounded confirm-dialog"
            },
            show: {
              event: '', //Stop the qtip from showing on normal events
              modal: {
                on: true
              }
            },
            hide: false
          });
        });
      }

      // build the toggle events.
      var tab_click = function (e) {
        if (e.isPropagationStopped()){
          return(false);
        }

        var target = $(e.target);
        target.prop('checked',true);
        // trigger the select so we show the correct tab
        target.closest('.tabbed_nav').find('li').removeClass('selected');
        target.closest('li').addClass('selected');
        // disable the form elements in all tabs
        tabbed.find('fieldset input').attr('disabled', 'disabled');
        // enable form elements in this tab
        var selected = '#' + target.attr('id') + 'Opt';
        $(selected).find('input').removeAttr('disabled');
        // hide all the sections
        tabbed.find('fieldset').hide();
        // show selected
        $(selected).parent().show();
        //track last clicked tab
        if (tabbed.closest('.tabbed').parent().hasClass('taxonomy')) {
          if ($(e.target).val() !== 'evalue') {
            $('#last_tab_clicked').val($(e.target).val());
          }
        }
      };

      var sections = nav_list.find('input');
      sections.each( function(){

        //carve out for taxonomy confirmation
        if($(this).closest('.tabbed').parent().hasClass('taxonomy')){
          $(this).on('click', function(e){
            if($('#tax_included').val().length > 0 && !$('#taxfilter_content').hasClass('reloading')){
              $(this).closest('li').qtip('show', e);
              $('.confirm_ok:visible').focus();
              return false;
            } else {
              tab_click(e);
            }
          });
        } else {
          $(this).on('click', tab_click);
        }
      });


      // click on the radio button that was selected.
      if (!$(this).parent().hasClass('taxonomy') || $('#taxfilter_data').length <= 0){
        nav_list.find('input[type=radio]:checked').click();
      }
    });


    /******************** init click functions ********************/
    $('#reset').on('click', resetForm);
    $('#example').on('click', exampleSeq);
    $('#aliexample').on('click', exampleAli);
    $('#hmmexample').on('click', exampleHmm);

    $('.seq_options a').click(function(){
      $('.seq_options a').removeClass('selected');
      $(this).addClass('selected');
      $('.seqInput').hide();
      $('#seq' + $(this).attr('alt')).show();
    });

    $('.collapsible legend span').on('click',
      function(){
        if ($(this).closest('fieldset').hasClass('collapsed')){
          $(this).closest('fieldset').removeClass('collapsed').addClass('expanded');
          if ($(this).closest('div').hasClass('disabled') === false){
            $(this).closest('fieldset').children('div').show('fast');
          }
        } else {
          $(this).closest('fieldset').removeClass('expanded').addClass('collapsed').children('div').hide('fast');
        }
      }
    );

    $('#gaButton').click(function () {
      $('#pfamEvalue').attr('disabled', true);
    });

    $('#eButton').click(function () {
      $('#pfamEvalue').attr('disabled', false);
    });



    /************************** setup tooltips ******************/
    $.fn.tooltip = function (position) {
      $(this).each(function () {
        $(this).click(function (e) {
          e.preventDefault();
        });
        var content = $(this).parent().siblings('.help').append('<br/>').append($('<a>more</a>').attr('href',$(this).attr('href'))).html(),
          at = 'center right',
          my = 'center left',
          corner = 'left center';

        if (position === 'above') {
          at = 'top center';
          my = 'bottom center';
          corner = 'bottom center'
        }

        $(this).qtip({
          content: {
            text: content
          },
          style: {
            tip: {
              corner: corner
            },
            classes: "ui-tooltip-hmmer ui-tooltip-rounded"
          },
          show: {
            solo: true,
            event: "mouseover"
          },
          hide: {
            fixed: true,
            delay: 1000,
            event: "mouseout"
          },
          position: {
            at: at,
            my: my,
            target: $(this)
          }
        });

      });
      return this;
    };

    $('.collapsible legend a, .custom h5 a, .custom .title a, h5.left a, .tooltip, .tooltip_item').tooltip();
    /********************key press toggle stats ***************/

    $(document).keydown(function(e) {
      if (e.altKey && e.ctrlKey && e.which === 68) {
        $('.stats, .easter').toggle();
      }
    });

    /*********** phmmer/hmmsearch alignment toggling code ********/
    $('.alilink').on('click', function(e) {
      e.preventDefault();
    });

    var ali_loading = [];

    $(document).on('click', '.resultTable .aliswitch', function(e) {
      var td = $(this);
      var link = td.find('a');

      var position = td.parent().index();

      var colspan = 0;

      if ($(this).closest('table').attr('id') === 'list') {
        colspan = $(this).closest('table').find('.titleRow th:visible').length;
      }
      else {
        colspan = $(this).closest('table').find('.titleRow th').length;
      }
      $('td.alignment').attr('colspan', colspan);

      if (td.closest('tr').next('.ali').length) {
        link.hasClass('rotate90') ? link.removeClass('rotate90') : link.addClass('rotate90');
        td.closest('tr').next('.ali').toggle();
      }
      else {
        if (!ali_loading[position]) {
          ali_loading[position] = true;
          $.get(link.attr('href'), function(data) {
            var alignment = $('<tr>').addClass('ali').append($('<td colspan="'+ colspan +'">').append(data));
            link.closest('tr').after(alignment);
            link.hasClass('rotate90') ? link.removeClass('rotate90') : link.addClass('rotate90');
            // add tooltips
            var contents = $('#alignmentKey').html();
            alignment.find('div').qtip({
              content: contents,
              style: {
                classes: "ui-tooltip-hmmer-align ui-tooltip-rounded"
              },
              show: {
                solo: true,
                event: "mouseover"
              },
              hide: {
                event: "mouseout"
              },
              position: {
                at: "bottom center",
                my: "top center"
              }
            });
            ali_loading[position] = false;
          });
        }
      }
      e.preventDefault();
    });

    $('#ali_show_all').on('click', function(e) {
      var button = $(this);
      button.attr('disabled', 'disabled');
      $('.ali').show();
      $('.alitoggle').each(function () {
        $(this).addClass('rotate90');
      });
      button.replaceWith('<a href="" class="small" id="ali_hide_all">(hide&nbsp;all)</a>');
      e.preventDefault();
    });

    $('#ali_hide_all').on('click', function(e) {
      var button = $(this);
      button.attr('disabled', 'disabled');
      $('.ali').hide();
      $('.aliswitch a').removeClass('rotate90');
      button.replaceWith('<a href="" class="small" id="ali_show_all">(show&nbsp;all)</a>');
      e.preventDefault();
    });

    /**************** identical sequences popup *****************/

    $.fn.seqpopup = function() {
      $(this).each(function() {
        $(this).qtip({
          content: {
            text: 'loading...',
            ajax: {
              url: $(this).attr('href')
            },
            title: {
              text: 'Identical Sequences',
              button: 'Close'
            }
          },
          position: {
            my: 'center',
            at: 'center',
            target: $(this).closest('tr'),
            effect: false
          },
          show: {
            event: 'click',
            solo: true
          },
          style: {
            classes: 'ui-tooltip-hmmerseq ui-tooltip-rounded ui-tooltip-shadow'
          },
          hide: 'unfocus'
        }).click(function(e){ e.preventDefault();});
      });
    };

    $('#list .seqlink').seqpopup();

    /**************** search again popup ****************************/

    $.fn.searchAgainPopUp = function () {

      $(this).each(function() {
        var url = $(this).attr('href');
        var uuid = $(this).attr('data-jobid');
        var link = site_url+'/search/hmmsearch?uuid=' + uuid;

        var content = $('<p>Perform a new search</p>').append(
          $('<ul>')
            .append($('<li>')
              .append($('<a>with new input</a>')
                .attr('href', url)))
            .append($('<li>')
              .append($('<a>with these results</a>')
                .attr('href', link))));

        $(this).qtip({
          content: content,
          style: {
            tip: {
              corner: "top right",
              border: 1
            },
            classes: "ui-tooltip-rounded ui-tooltip-hmmerdist"
          },
          show: {
            event: "mouseover"
          },
          hide: 'unfocus',
          position: {
            at: "bottom right",
            my: "top right"
          }
        }).click(function(e){ e.preventDefault();});
      });
    };

    $('.reuse').searchAgainPopUp();

    /**************** identical sequences next link *****************/
    $(document).on('click', '#identical_nav', function(e) {
      var link = $(this);
      $.get(link.attr('href'), function(data) {
        link.closest('div').replaceWith(data);
      });
      e.preventDefault();
    });

    /**************** setup meta info toggle *******************/

    $.fn.meta_toggle = function() {
      $(this).find('.provenance').hide().end().find(' > a').toggler(
          function() { $(this).next().slideDown();},
          function() { $(this).next().slideUp(); }
        );
    };

    /******************* add customize toggle *********************/
    $.fn.addCustomToggle = function () {
      this.each(function () {
        var link = $('<a href="#" class="button small">Customize</a>').click(function(e) {
          $('.custom').toggle();
          e.preventDefault();
        });
        $(this).append(link);
      });
      return this;
    };
    $('#list caption span.right').addCustomToggle();

    /**************** setup simple table toggle *******************/

    $.fn.simpleTable = function() {
      var table = $(this);
      if (this.length === 0 || table.hasClass('superfamily')) {
        return;
      }

      var adv = $('<a class="button small">Advanced</a>').addClass('right').click(function() {
        if ($(this).text() === 'Advanced')  {
          $(this).text('Standard');
          $(this).parents('table').find('td.advanced, th.advanced').show();
        }
        else {
          $(this).text('Advanced');
          $(this).parents('table').find('td.advanced, th.advanced').hide();
        }
      });
      adv.qtip({
        content: "Click to toggle more information about the Alignment, Model, Bias and Bit Score.",
        style: {
          tip: {
            corner: "bottom right",
            border: 1
          },
          classes: "ui-tooltip-hmmer ui-tooltip-rounded"
        },
        show: {
          event: "mouseover"
        },
        hide: {
          event: "mouseout"
        },
        position: {
          at: "top center",
          my: "bottom right"
        }
      });
      table.find('> caption').prepend(adv);
      table.find('td.advanced, th.advanced').hide();
    };

    /******************* toggle hmmscan alignments *********************/
    $.fn.alignmentToggle = function(wide) {
      if (this.length === 0) {
        return;
      }
      var table = $(this);
      var rowspan = 2;
      var colspan = 16;
      if (wide) {
        rowspan = 3;
        colspan = 18;
      }
    console.log('prpending rowspan '+ rowspan);
      table.find('tr:eq(0)').prepend('<th rowspan="' + rowspan  + '"></th>');
      table.find('> tbody > tr:even').prepend('<td class="centered alishow"><a class="alitoggle" href="">&gt;</a></td>');
      table.find('> tbody > tr:odd > td').attr('colspan', colspan);
      table.find('tfoot td').attr('colspan', colspan);

      table.find('td.alishow a').click(function(e) {
        $(this).parent().parent().next().toggle();
        $(this).hasClass('rotate90') ? $(this).removeClass('rotate90') : $(this).addClass('rotate90');
        e.preventDefault();
      });
      // add tooltip
      var contents = $('#scanAlignmentKey').html();
      table.find('tr.alignment').qtip({
        content: contents,
        style: {
          classes: "ui-tooltip-hmmer-align ui-tooltip-rounded",
          tip: {
            corner: 'top center',
            border: 1
          }
        },
        show: {
          solo: true,
          event: "mouseenter"
        },
        hide: {
          event: "mouseleave"
        },
        position: {
          at: "bottom center",
          my: "top center"
        }
      });
      return table;
    };

    /********************* toggle hmmscan table ********************/
    $.fn.addHmmscanToggle = function () {
      var table = $(this);
      table.hide();
      var block = $('<div class="centered">');
      var link = $('<a>Show hit details</a>').attr('href','')
        .toggler(function(e) {
          table.show();
          $(this).text('Hide details');
          e.preventDefault();
        }, function (e) {
          table.hide();
          $(this).text('Show hit details');
          e.preventDefault();
        });
      $('.domwrapper').after(block.append(link));
    };

  /********** scroll after page load if sent via hit dist ********/

  var scrollOnLoad = (function () {
    var row = window.location.search.match(/row=r(\d+)/);
    if (row) {
      var targetRow = row[1];//get row from url
      $('#list tbody tr').eq(targetRow - 1)[0].scrollIntoView();
      $('#list tbody tr').eq(targetRow - 1).css('backgroundColor','#ffe87c')
        .animate({'backgroundColor': '#ffffff'},3000, function() {
          $(this).css('backgroundColor','');
        });
    }
    else {
      var target = window.location.search.match(/jumpto=(\w+)/);
      if (target) {
        $(window)[0].scrollTo(0, $('#' + target[1]).offset().top - 24);
        $('#' + target[1]).css('backgroundColor','#ffe87c')
          .animate({'backgroundColor': '#ffffff'},3000, function() {
            $(this).css('backgroundColor','');
          });
      }
    }
  })();


    if ($('#aliupload').length > 0) {

      $('#iterativeSearchForm #jack_example').click(function (e) {
        if($('#aliupload:checked').val()) {
          var exHmm = $('#example_ali').text();
          $("#seq").val(exHmm).text(exHmm).change();
        }
        else {
          var exSeq = $('#example_seq').text();
          $("#seq").val(exSeq).text(exSeq).change();
        }
        e.preventDefault();
      });

      if ($('#aliupload:checked').val()) {
        $('#gapPen').hide().find('input,select').attr('disabled',true);
        //Attach this here so that we can figure out what the default was if someone hits the reset button.
      }
      else {
        $('#gapPen').show().find('input,select').removeAttr('disabled');
      }

      $('#aliupload').bind('click', function(){
        $("#seq").removeClass('sequence').addClass('hmmseq');
        $('#gapPen').hide().find('input,select').attr('disabled',true);
      });

      $('#sequpload').bind('click', function(){
        $("#seq").removeClass('hmmseq').addClass('sequence');
        $('#gapPen').show().find('input,select').removeAttr('disabled');
      });

      /* Since the reset button wont reset the hidden elements, we have to take care of it.
       * This uses the previously stored default to reset the form. We have to use the
       * previously stored default, because the click event fires before the form data is
       * reset and we have no way of knowing what the default was otherwise. */
      $('#reset').click(function() {
          $('#gapPen').hide().find('input,select').attr('disabled',true);
      });
    }

    $('.archshow').on('click', function(e) {
      var link = $(this);
      e.preventDefault();

      // already loading the content, so just return.
      if (link.closest('li').children('.loading').length > 0) {
        return;
      }

      if (link.closest('li').children('table').length === 0) {
        var loader = $('<div>').addClass('centered loading').append($('<p>loading...</p>'), $('<img/>')
                        .attr('src','/Tools/hmmer/static/images/loading.gif')
                        .attr('alt','loading'));
        link.closest('li').append(loader);
        $.get(link.attr('href'), function(data) {
          loader.replaceWith(data);
          // render the domains
          link.closest('li').children('table').find('.domGraphics').each(function(){
            $(this).text('');
            var id = '#' + $(this).attr('id');
            var seq_id = id.replace('#dom_','seq_');
            var pg = new PfamGraphic();
            pg.setParent(id);
            pg.setSequence(window[seq_id]);
            pg.render();
            var new_width = $(this).parent().width();
            pg.resize( new_width );
          });
          link.children('span.show').text('Hide All');
        });
      }
      else {
        link.closest('li').children('table').toggle();
        link.closest('li').children('.more_arch_hits').toggle();
        link.children('span.show').text(link.children('span.show').text() === 'Show All' ? 'Hide All' : 'Show All'  );
        link.removeClass('archshow').addClass('archtoggle').click(function(e) {
          $(this).closest('li').children('table').toggle();
          $(this).closest('li').children('.more_arch_hits').toggle();
          var ltext = $(this).children('span.show');
          ltext.text((ltext.text() === 'Show All' ? 'Hide All' : 'Show All'));
          e.preventDefault();
        });
      }
    });

    $(document).on('click', '.more_arch_hits', function(e) {
      var link = $(this);
      e.preventDefault();
      link.hide();

      var loader = $('<div>').addClass('centered loading').append($('<p>loading...</p>'), $('<img/>')
                      .attr('src','/Tools/hmmer/static/images/loading.gif')
                      .attr('alt','loading'));
      link.closest('li').append(loader);
      $.get(link.attr('href'), function(data) {
        loader.replaceWith(data);
        var domObj = link.closest('li').children('table').find('.domGraphics');
        link.remove();
        domObj.each(function(){
          if ($(this).children('svg').length === 0) {
            $(this).empty();
            var id = '#' + $(this).attr('id');
            var seq_id = id.replace('#dom_','seq_');
            var pg = new PfamGraphic();
            pg.setParent(id);
            pg.setSequence(window[seq_id]);
            pg.render();
          }
        });
      });
    });

    /**
    * init fixed position header
    * this keeps the primary navigation at the top of the page when
    * scrolling to the bottom.
    **/

    if (!$('html').hasClass('older')) {
      var win = $(window), isFixed = 0;
      var navTop = $('nav').length && 55;
      win.bind('scroll', function () {
        var i, scrollTop = win.scrollTop();
        //check for cookie-banner
        if ($('#cookie-banner').css('top') === "0px") {
          navTop = $('nav').length && 177;
        }
        else {
          navTop = $('nav').length && 55;
        }

        if (scrollTop >= navTop && !isFixed) {
          isFixed = 1;
          $('nav').addClass('fixed').removeClass('relative');
          $('#header').addClass('ex');
          $('#subnav').addClass('scrolled');
        }
        else if (scrollTop <= navTop && isFixed) {
          isFixed = 0;
          $('nav').removeClass('fixed').addClass('relative');
          $('#header').removeClass('ex');
          $('#subnav').removeClass('scrolled');
          }
      });
    }

    // init close me link for results customize message
    $(document).on('click', '.notify a', function(e){
      e.preventDefault();
      $(this).parent().hide();
      //set custom_alert value in session, so we remember to leave this hidden.
      $.post(site_url+'/session/custom_hide', {
        off: true
      }, function() {}, 'json');
    });

    // add additional iteration button to jackhmmer results
    var iterbutton = $('.iterbutton').clone();
    iterbutton.find('input').click(function(e) {
      $('#next_iteration').submit();
      $(this).attr('disabled', 'disabled')
        .addClass('disabled-button')
        .after('<span class="loading">loading, please wait...</span>');
     });
    $('#jackhmmer_nav .actions').after(iterbutton);


    /******************* jump to link fix ***************************/
    // This fixes things that were below the floating header after
    // a jump.

    // grab the id out of the link
    $('.jumplink').on('click', function(e){
      var page = $(this).attr('href').match(/page=(\d+)/);
      // if on the same page
      if(parseInt(dist_data.page, 10) === parseInt(page[1], 10)) {
        e.preventDefault();
        // scroll the page.
        $(window)[0].scrollTo(0, $('#first_new').offset().top - 24);
        $('#first_new').css('backgroundColor','#ffe87c')
          .animate({'backgroundColor': '#ffffff'},3000, function() {
            $(this).css('backgroundColor','');
          });
      }
      else {
        e.preventDefault();
        //strip off the # tag and fire off the location change
        window.location = $(this).attr('href').replace(/#first_new/,';jumpto=first_new');
      }
    });


    // show hmm logos if they are requested
    $('.hmmlogo').each(function() {
      var uuid = $(this).attr('data-uuid');
      var url = site_url +'/results/hmmlogo/' + uuid + '.png';
      var img = $('<img>').attr('alt', 'HMM Logo').attr('src', url);
      $(this).append(img);
    });
    if (typeof logo_data !== 'undefined') {
      $('#logo_graphic').hmm_logo({column_width: 34, data: logo_data, alphabet: 'aa', scaled_max: true });
    }


    // disable multibutton navigation after clicking to prevent multiple requests
    // for the same content.
    $('.oneclick a').on('click', function(e){
      if ($(this).hasClass('noNav')) {return;}
      $(this).text('loading...').unbind('click')
        .click(function(e) {
          e.preventDefault();
      });
    });

    $('.taxonomy_nav .multibutton a').on('click', function(e){
      $('.taxonomy_nav .multibutton li.current').removeClass('current');
      $(this).parent().addClass('current');
      $('#jitTree').empty();
      if ($(this).hasClass('distTree')) {
        $('#jitTree').drawDistributionTree(distTree, 0);
      } else {
        $('#jitTree').drawTaxonTree(taxTree, 1);
      }
    });

    $('.jump').jumper();

    // add a select all link to the hmmscan db selection
    if ($('#hmmdb').length > 0) {
      var link = $('<a>(select all)</a>').css('display','block').bind('click', function (e) {
        e.preventDefault();
        $('#hmmdb').find('input')
          .prop('checked', 'checked').first().trigger('change');
      });

      $('#hmmdb .group').append(link);
    }

  });

  /*****************navigation menu pop up********************/

  $.fn.nav_menu = function() {
    $(this).each(function() {
      $(this).click(function (e) {
        e.preventDefault();
      });
      var content = $('#menu-popup').html();

      var tooltips = $(this).qtip({
        content: content,
        style: {
          tip: {
            corner: false,
          },
          classes: "ui-tooltip-hmmernav",
        },
        show: {
          event: "mouseenter",
          target: $('.menu')
        },
        hide: {
          event: "unfocus"
        },
        position: {
          adjust: {
            y: -30,
          },
          at: "bottom right",
          my: "top right",
          target: $('.menu')
        }
      });
      var api = tooltips.qtip('api');
      $(document).on('mouseleave', '.menu-list', function(e) {
        e.preventDefault();
        api.hide();
      });
      $(document).on('mouseenter', '.current_tab', function(e) {
        api.show();
      });
    });
  };


  /*********jump on page without header overlap*****************/

  $.fn.jumper = function () {
    if ($(this).length === 0) {
      return;
    }
    var target = $(this).attr('href');
    var top = $(target).position().top;
    $(this).click( function(e) {
      e.preventDefault();
      window.scrollTo(0, top);
    });
  };


  /*******************hmmscan search form***********************/
  check_thresholds = function () {
    //grab all the check boxes
    var cboxes = $('#hmmdb input:checked'),
      disable = null;
    //iterate over and see if gene3d or superfamily is checked
    cboxes.each(function () {
      console.log('checking ',$(this).prop('id'))
      console.log(this);
      if ($(this).prop('checked') && /superfamily|gene3d|pirsf/.test($(this).prop('id'))) {
        console.log('disable pirsf')
        disable = 1;
      }
    });
    //enable or disable input accordingly.
    if (disable) {
      $('#thres p.jshide').show();
      $('#thres input').attr('disabled','disabled');
    }
    else {
      $('#thres p.jshide').hide();
      $('#thres input').removeAttr('disabled');
    }

  };

  /*********************sortable tables***********************/
  $.fn.sortable = function(){
    var table = $(this);
    // attach onclick events to thead
    $(this).find('thead .sortable').bind('click', function() {

      // removed sorted from all columns
      $(this).closest('thead').find('.sorted').removeClass('sorted');

      // mark this as sorted for styling
      $(this).addClass('sorted');

      // need to figure out which column we are sorting on
      var column_number = $(this).attr('data-column');
      // build array to manipulate with the sort
      var rows = [];
      var row_total = table.find('tbody tr').not('.alignment').size();

      for (var row = 0; row < row_total; row++) {
        rows[row] = [];
      }

      table.find('tbody tr').not('.alignment').each(function(i){
        rows[i][0] = $(this).find('td').eq(column_number).text();
        rows[i][1] = this;
      });

      // now sort the rows array
      if ($(this).hasClass('numeric')) {
        rows.sort(function (a, b) { return a[0] - b[0] ; });
      }
      else if ($(this).hasClass('evalue')) {
        rows.sort(function (a, b) { return parseFloat(a[0]) - parseFloat(b[0]) ; });
      }
      else {
        rows.sort();
      }

      //now remove each one from the dom and put it at the end of the table.
      for (var row2 = 0; row2 < row_total; row2++) {
        var meta = rows[row2][1];
        var alignment = $(rows[row2][1]).next('.alignment');

        $(meta).detach();
        $(alignment).detach();

        table.find('tbody').append(meta).append(alignment);
      }
    });
  };


  /********************distribution graphic tooltip***********/
   $.fn.help = function() {
     if (this.length === 0) {
       return;
     }
     var content = $(this).parent().siblings('.help')
                     .append('<br/>')
                     .append($('<a>more</a>')
                     .attr('href',$(this).attr('href'))).html();

     $(this).click(function(e) {
       e.preventDefault();
     }).qtip({
       content: content,
       style: {
         tip: {
           border: 1
         },
         classes: "ui-tooltip-hmmerdist ui-tooltip-rounded"
       },
       show: {
         solo: true,
         event: "mouseover"
       },
       hide: {
         fixed: true,
         delay: 1000,
         event: "mouseout"
       },
       position: {
         viewport: $(window),
         at: "top center",
         my: "bottom right"
       }
     });
   };

  $.insertPfamDomains = function(uuid, annotationUUID) {
    if (!annotationUUID) {
      $.post(site_url+'/annotation/pfama', { uuid: uuid }, null, 'json').done(
        function(data) {
          $.loadPfamAnnotation(data.uuid);
        }
      );
    }
    else {
      $.loadPfamAnnotation(annotationUUID);
    }
  };

  $(document).on('load_annotations', '#domGraph', function() {
    var ncoils = null;

    $(this).parent().after($('#annotation_ind').html());
    /* coils annotation */
    if (typeof annotationcoilsUUID === 'undefined') {
      $.post(site_url+'/annotation/coils', { uuid: uuid }, null, 'json').done(
        function(data) {
          ncoils = $.loadNcoilsAnnotation(data.uuid);
        }
      );
    }
    else {
      ncoils = $.loadNcoilsAnnotation(annotationcoilsUUID);
    }


    var phobius = null;

    /* phobius annotation */
    if (typeof annotationphobiusUUID === 'undefined') {
      $.post(site_url+'/annotation/phobius', { uuid: uuid },null, 'json').done(
        function(data) {
          phobius = $.loadPhobiusAnnotation(data.uuid);
        }
      );
    }
    else {
      phobius = $.loadPhobiusAnnotation(annotationphobiusUUID);
    }


    var disorder = null;

    /* disorder annotation */
    if (typeof annotationdisorderUUID === 'undefined') {
      $.post(site_url+'/annotation/disorder', { uuid: uuid }, null, 'json').done(
        function(data) {
          disorder = $.loadDisorderAnnotation(data.uuid);
        }
      );
    }
    else {
      disorder = $.loadDisorderAnnotation(annotationdisorderUUID);
    }


    /* superfamily annotation */
    if (typeof annotationsuperfamilyUUID !== 'undefined') {
      $.loadHmmscanAnnotation(annotationsuperfamilyUUID, 'superfamily');
    }

    /* tigrfam annotation */
    if (typeof annotationtigrfamUUID !== 'undefined') {
      $.loadHmmscanAnnotation(annotationtigrfamUUID, 'tigrfam');
    }

    /* gene3d annotation */
    if (typeof annotationgene3dUUID !== 'undefined') {
      $.loadHmmscanAnnotation(annotationgene3dUUID, 'gene3d');
    }
    /* pirsf annotation */
    if (typeof annotationpirsfUUID !== 'undefined') {
      $.loadHmmscanAnnotation(annotationpirsfUUID, 'pirsf');
    }

    $.when(ncoils, phobius, disorder).done(function() {
      if (typeof url_restrictions == 'undefined') {
        if (typeof search_algo !== 'undefined' && search_algo === 'phmmer') {
          $.loadCoverageAndIdentityPlot(uuid);
        }
      }
      $('.domwrapper .tooltip').tooltip();
    });

  });

  $.loadPhmmer = function(uuid, status, page, annotationUUID, withAli) {

    $('.hmmscanresult').find('.domwrapper > div').append(
      $('<img/>').attr('src',site_url+'/static/images/loading.gif').attr('alt','Annotating seq')
    );
    if(query_length > 2000){
    $('.phmmerresult td').append("it might take a while");
  }
  $('.phmmerresult td').append(
      $('<img/>').attr('src',site_url+'/static/images/loading.gif').attr('alt','Searching seq')
    );

    // make sure the search number is added to the UUID, so that the ajax response is
    // correct. Otherwise you get a nasty recursion.
    var current_url = window.location.pathname.replace(/^\/results\/[^\/]*/, "$&.1");

    $.ajax({
      url: current_url,
      data: {'addpfam': 1, 'page': page, 'ali': withAli },
      statusCode: {
        /* if job has not run then tell the server to run it and get the results. */
        202: function (data) {
          $.post(site_url+'/search/phmmer/' + uuid + '.1', {'noredirect': 1}, function(response) {
            $.get(response.location, {'addpfam': 1, 'page': page, 'ali': withAli }, function (data) {
              insertPhmmerIntoPage(data);
            });
          }, 'json')
      .fail(function (jqXHR, textStatus, error) {
            console.log('ajax request failed');
            //console.log(jqXHR.responseText);
            $('.phmmerresult').replaceWith("<h3>Search Failed</h3><p>We're sorry, it looks like something went wrong with our search system. It may be a transient error, so please feel free to try the search again. Alternatively, please contact us.</p>");
            //$('.phmmerresult').replaceWith(jqXHR.responseText);
        });   
    //.error(function() { 
      //     console.log('ajax request failed');
        //    console.log(jqXHR.responseText);
        //    $('.phmmerresult').replaceWith(jqXHR.responseText);
    //      alert('Internal Server Error');
      //});

        },
        /* if job has already been run then just fetch results. */
        200: function (data) {
          insertPhmmerIntoPage(data);
        }
      }
    }).fail(function (jqXHR, textStatus, error) {
      console.log('ajax request failed');
      console.log(jqXHR.responseText);
      $('.phmmerresult').replaceWith(jqXHR.responseText);
    });
  };

  function insertPhmmerIntoPage(data) {
    $('.phmmerresult').replaceWith(data);
    $('#list .seqlink').seqpopup();
    $('#barGraph').distGraph();
    $('.meta').meta_toggle();
    $('.custom h5 a, .custom .title a').tooltip();
    $('#list caption span.right').addCustomToggle();
    if (typeof hitPositionData !== 'undefined') {
      $('.hitpos').hitLocation(hitPositionData);
    }
    $('.res_nav').show();
    $('body').data('phmmer.loaded', 1);
    if (typeof url_restrictions == 'undefined') {
      if (typeof search_algo !== 'undefined' && search_algo === 'phmmer') {
        $.loadCoverageAndIdentityPlot(uuid);
      }
    }
  }


  $.loadNcoilsAnnotation = function(uuid) {
    return $.getJSON(site_url+'/annotation/coils/' + uuid + '?graphics=1').done(
      function (data) {
      $('#domGraph').after('<div id="coilsGraph"></div>');
      data.graphic.title = 'coiled-coil';
      data.graphic.imageParams = {motifHeight: 10, regionHeight: 10};
      var pg = new PfamGraphic('#coilsGraph', data.graphic);
      if (pg._sequence.motifs.length > 0) {
        pg.render();
        var new_width = $('#domGraph').parent().width();
        pg.resize( new_width );
      }
      $('#ann_coiled').children('span').attr('data-icon', '3').addClass('ann_ok');
    })
    .fail(function() {
      $('#ann_coiled').children('span').attr('data-icon', '*').addClass('ann_fail');
    });
  };

  $.loadPhobiusAnnotation = function(uuid) {
    return $.getJSON(site_url+'/annotation/phobius/' + uuid + '?graphics=1').done(
      function (data) {
      $('#domGraph').after('<div id="phobiusGraph"></div>');
      data.graphic.title = 'tm & signal peptide';
      data.graphic.imageParams = {motifHeight: 10, regionHeight: 10};
      var pg = new PfamGraphic('#phobiusGraph', data.graphic);
      if (pg._sequence.motifs.length > 0) {
        pg.render();
        var new_width = $('#domGraph').parent().width();
        pg.resize( new_width );
      }
      $('#ann_signal').children('span').attr('data-icon', '3').addClass('ann_ok');
    })
    .error(function() {
      $('#ann_signal').children('span').attr('data-icon', '*').addClass('ann_fail');
    });
  };

  $.loadDisorderAnnotation = function(uuid) {
    return $.getJSON(site_url+'/annotation/disorder/' + uuid + '?graphics=1').done(
      function (data) {
      $('#domGraph').after('<div id="disorderGraph"></div>');
      data.graphic.title = 'disorder';
      data.graphic.imageParams = {motifHeight: 10, regionHeight: 10};
      var pg = new PfamGraphic('#disorderGraph', data.graphic);
      if (pg._sequence.motifs.length > 0) {
        pg.render();
        var new_width = $('#domGraph').parent().width();
        pg.resize( new_width );
      }
      $('#ann_disorder').children('span').attr('data-icon', '3').addClass('ann_ok');
    })
    .error(function() {
      $('#ann_disorder').children('span').attr('data-icon', '*').addClass('ann_fail');
    });
  };

  $.loadCoverageAndIdentityPlot = function(uuid) {
    if ($('body').data('phmmer.loaded') && $('body').data('hmmscan.loaded')) {
      $.getJSON(site_url+'/annotation/coverageandidentity/' + uuid).done(function (data) {
        if ($('#coverageheat > svg').length > 0) {
          // do nothing as the data has already been loaded.
        }
        else {
          $('body').data('coverage_loaded', 1);
          $('.domwrapper > div').append($('#coverageTemplate').html());
          var width = $('#domGraph svg').width();
          $('#coverageheat').coverageHeatMap(data, width);
          $('#similarityheat').similarityHeatMap(data, width);
          if (width < 400 ) {
            width = 400;
          }
        }
      });
    }
  }


  $.loadHmmscanAnnotation = function(uuid,type) {
    var titles = {
      tigrfam:'TIGRFAM',
      superfamily:'Superfamily',
      gene3d:'Gene3D',
      pirsf:'PIRSF'
    };
    $.getJSON(site_url+'/annotation/' + type + '/' + uuid, function (data) {
      $('#domGraph').after('<div id="' + type + 'Graph"></div>');
      data.graphic.title = titles[type];
      data.uuid = uuid;

      $.each(data.hits, function(){
        $.each(this.domains, function() {
          if (this.is_reported == '0') {
            this.is_reported = '';
          }
          if (this.significant == '0') {
            this.significant = '';
            data.insignificant_count = 1;
          }
          if (this.is_included == '0') {
            this.is_included = '';
          }
        });
      });

      var source   = $("#" + type + "-results-table").html();
      var template = Handlebars.compile(source);
      var html     = template(data);

      $('.' + type).replaceWith(html);
      $('#' + type + 'Results').simpleTable();
      $('#' + type + 'Results').sortable();

      if (data.graphic && data.graphic.regions && data.graphic.regions.length > 0) {
        var pg = new PfamGraphic('#' + type + 'Graph', data.graphic);
        pg.render();
        var new_width = $('#domGraph').parent().width();
        pg.resize( new_width );

        $("#" + type + "Results tbody tr:not('.alignment')")
          .bind('mouseover', function () {
            var uniq  = $(this).attr('data-uniq');
            pg.highlight({uniq:uniq});
          })
          .bind('mouseout', function () {
            var uniq  = $(this).attr('data-uniq');
            pg.highlight({uniq:uniq, status:'off'});
          });
      }
    })
    .error(function() { });
  };

  $.loadPfamAnnotation = function(uuid) {
    $.get(site_url+'/annotation/pfama/' + uuid, function (data) {
      $('.hmmscanresult').replaceWith(data);
      var pg = new PfamGraphic('#domGraph', sequence);
      pg.render();
      var new_width = $('#domGraph').parent().width();
      pg.resize( new_width );

      $("#hmmscan tbody tr:not('.alignment')")
        .bind('mouseover', function () {
          var uniq  = $(this).attr('data-uniq');
          pg.highlight({uniq:uniq});
        })
        .bind('mouseout', function () {
          var uniq  = $(this).attr('data-uniq');
          pg.highlight({uniq:uniq, status:'off'});
        });

      $('#hmmscan').simpleTable();
      $('#hmmscan').alignmentToggle();
      $('#hmmscan').sortable();
      $('.hmmscan').addHmmscanToggle();
      $('.meta').meta_toggle();
      $('body').data('hmmscan.loaded', 1);
      $('#domGraph').trigger('load_annotations');
    });
  };

  /****************** batch status checking ***********************/

  $.fn.batchUpdate = function (data, uuid, algo) {
    var table = $(this);
    // update summary counts
    $('.summary_status .attention').text(data.summary.sum.searchnum);
    var statMessage = 'Your job is queued behind ' + data.queue.position + ' other searches. (approximate wait time: ' + data.queue.time + ')';

    if (data.queue.position === '0') {
      statMessage = 'Your job is running.';
    }

    if (data.summary.sum.status === 'DONE') {
      statMessage = 'Your job has finished.';
    }
    else if (data.summary.sum.status === 'RUN') {
      statMessage = 'Your job is running.';
    }
    else if (data.summary.sum.status === 'ERROR') {
      statMessage = 'Your job failed to complete.';
    }
    $('.summary_status p:eq(1)').text(statMessage);
    if (data.summary.sum.status !== 'DONE') {
      $('.summary_status p:eq(1)').append('<img src="/Tools/hmmer/static/images/spinner.gif"/>');
    }
    else {
      $('.summary_status p:eq(2)').remove();
    }
    if (data.summary.sum.searchnum) {
      // for each search result update the jobs that are finished.
      if (algo === 'jackhmmer') {
        $.each(data.summary.results, function (i) {
          var row = table.find('tbody tr').eq(i);
          if (this.status === 'DONE' || this.status === 'RUN') {
            var link = $('<a>' + uuid + '.' + (i + 1) + '</a>').attr('href',  site_url+'/results/' + uuid+ '.' + ( i + 1) + '/score');
            row.removeClass('pending')
              .find('td:eq(5)').text(this.hitsnum).end()
              .find('td:eq(1)').html(link).end();

            if (this.lost !== '-') {
              row.find('td:eq(3)').text('-' + this.lost).addClass('lost');
            }

            if (this.added !== '-') {
              row.find('td:eq(2)').text('+' + this.added).addClass('new');
            }

            if (this.lost_below !== '-') {
              row.find('td:eq(4)').text(this.lost_below).addClass('dropped');
            }
          }
          else if (this.status === 'ERROR') {
            row.removeClass('pending').addClass('fail')
              .find('td:eq(5)').text('-').end()
              .find('td:eq(4)').text('-').end()
              .find('td:eq(3)').text('-').end()
              .find('td:eq(2)').text('-').end()
              .find('td:eq(1)').text(this.errstr);
          }
        });

        if (data.summary.sum.converged) {
          table.find('tbody tr.pending').remove();
          table.find('caption').text('Jackhmmer Summary (Converged)');
        }

      }
      else {
        $.each(data.summary.results, function (i) {
          var row = table.find('tbody tr').eq(i);
          if (row.find('td:eq(3)').text() !== this.status ) {
            if (this.status === 'DONE' || this.status === 'RUN') {
              var link = $('<a>show</a>').attr('href', site_url+ '/results/' + uuid+ '.' + ( i + 1) + '/score');
              if (row.find('td').size() == 8) {
                row.removeClass('pending')
                  .find('td:eq(3)').text(this.status).end()
                  .find('td:eq(2)').text(this.hitsnum).end()
                  .find('td:eq(7)').html(link).end()
                  .find('td:eq(4)').text(this.tophit.acc).end()
                  .find('td:eq(5)').text(this.tophit.desc).end()
                  .find('td:eq(6)').text(this.tophit.evalue);
              }
              else {
                row.removeClass('pending')
                  .find('td:eq(3)').text(this.status).end()
                  .find('td:eq(2)').text(this.hitsnum).end()
                  .find('td:eq(6)').html(link).end()
                  .find('td:eq(4)').text(this.tophit.acc).end()
                  .find('td:eq(5)').text(this.tophit.desc).end();
              }
            }
            else if (this.status === 'ERROR') {
              row.removeClass('pending').addClass('fail')
                .find('td:eq(3)').text(this.status).end()
                .find('td:eq(2)').text(this.errstr);
            }
          }
        });
      }
    }
    return;
  };

  /****************** smart poller from github ***********************/


  $.smartPoller = function(wait, poller) {
    if ($.isFunction(wait)) {
      poller = wait;
      wait = 1000;
    }

    (function startPoller() {
      setTimeout(function() {
        poller.call(this, startPoller);
      }, wait);
      wait = wait * 1.1;
    })();
  };

  /****************** form validation ***********************/

  $.fn.validateForm = function (load) {
    var valid = true;
    $('#error').empty().removeClass('warning');
    $('.invalid').removeClass('invalid');
    this.each(function () {
      for ( var i = 0; i < this.elements.length; i++) {
        // do validation here
        if($(this.elements[i]).validateField(load)) {
          valid = false;
        }
      }
    });
    return valid;
  };

  $.fn.validateField = function (load) {
    var errors = [];
    for (var name in validations) {
      var re = new RegExp("(^|\\s)" + name + "(\\s|$)");
      if (re.test(this.attr('class'))) {
        var result = validations[name].test(this,load);
        if (result && !result[0]) { // validation failed
          errors.push( result[1] );
        }
      }
    }
    if ( errors.length ) {
      $(this).showErrors(errors);
    }
    return errors.length > 0;
  };

  $.fn.showErrors = function (errors) {
    this.addClass('invalid');
    $('#error').addClass('warning');
    var existing = $('#error').find('p').map(function () {
      return $(this).text();
    });
    $(errors).each(function() {
      if ($.inArray( this.toString(), existing) === -1) {
        $('#error').append('<p>' + this + '</p>');
      }
    });
  };

  function stripHeader(string) {
    var lines = $.map(string.split('\n'), function(n,i) {
      if (n.match(/^[^>]/)) {
        return n;
      }
    });
    return lines.join('').replace(/[\s\r]+/g,'');
  }

  var validations = {
    required: {
      test: function( obj, load) {
        var title = obj.attr('title');
        // If object is check box/radio button then need to grab all
        // and see if at least one is checked.
        if (obj.attr('type') === 'radio') {
          var name = obj.attr('name');
          var checked = obj.closest('form').find('input[name=' + name + ']').filter(':checked');
          if(checked.val()){
            return [true];
          }
          else {
            return [false, title + " value must be selected"];
          }
        }
        var status = obj.val().length > 0 || load;
        return [status, title + " field is required"];
      }
    },
    hmmfile: {
      test: function ( obj, load) {
        if (obj.closest('form').find('#seq').val().length > 0) {
          if (obj.val().length === 0) {
            return [true];
          }
          return [false, "Please upload a file or paste in an alignment/hmm, not both."];
        }
      }
    },
    hmmseq: {
      test: function ( obj, load) {
        if (obj.closest('form').find('#file').val().length > 0) {
          if (obj.val().length === 0) {
            return [true];
          }
          return [false, "Please upload a file or paste in an alignment/hmm, not both."];
        }
        if (obj.closest('form').find('#hmm_acc').val().length > 0) {
          if (obj.val().length === 0) {
            return [true];
          }
          return [false, "Please choose an accession/ID or paste in a sequence, not both."];
        }
        else {
          if (obj.val().length === 0) {
            return [false, 'There was no input alignment or HMM.'];
          }
          return [true];
        }
      }
    },
    hmm_acc: {
      test: function ( obj, load) {
        if (obj.val().match(/^[\w\.\-@]*$/i)) {
          return [true];
        }
        return [false, "The accession/ID is not valid."];
      }
    },
    acc: {
      test: function ( obj, load) {
        if (obj.closest('form').find('#file').val().length > 0) {
          if (obj.val().length === 0) {
            return [true];
          }
          return [false, "Please choose an accession or upload a file, not both."];
        }
      }
    },
    sequence: {
      test: function ( obj, load) {
        var acc = obj.closest('form').find('#acc, #all_acc');

        if (acc && acc.val().length > 0) {
          if (obj.val().length === 0) {
            return [true];
          }
          return [false, "Please choose an accession or upload a sequence, not both."];
        }
        if (obj.closest('form').find('#file').val().length > 0) {
          if (obj.val().length === 0) {
            return [true];
          }
          return [false, "Please upload only a file or paste in a sequence, not both."];
        }
        //sequence is missing
        if (obj.val().length === 0) {
          return [false, "Please specify a search sequence."];
        }
        var seq = stripHeader(obj.val());
         query_length = seq.length;
        // sequence has illegal characters
        if (seq.match(/[^abcdefghijklmnopqrstuvwxyz\*]/i)) {
          return [false, "The sequence seems to contain illegal characters."];
        }
        // sequence composition no good
        var frag = seq.substring(0,50);
        var fLength = frag.length;
        var n = 0;
        if (fLength > 30) {
          for (var i = 0;i < fLength ;i++) {
            var l = frag.substr(i,1);
            if (l.match(/[acgtu]/i)) {
              n++;
            }
          }
        }
        if ((n / fLength) > 0.95 ) {
          return [false, "The input sequence doesn't appear to be a protein sequence."];
        }
        //sequence is too long?
        if (seq.length > 10000) {
          return [false, "The sequence is too long. Please use sequences with less than 10,000 residues. This may be a bona fide sequence such as Titin, but we current can not search long sequences due to memory constraints."];
        }
        //sequence length too short
        if (seq.length < 10) {
          return [false, "The sequence is too short. Please use sequences with 10 or more residues."];
        }

        return [true];
      }
    },
    hmmdb: {
      test: function(obj, load) {
        if (obj.attr('checked')) {
          var dbList = ['gene3d', 'pfam', 'superfamily', 'tigrfam', 'pirsf'];
          if ($.inArray(obj.val(), dbList) == -1) {
            return [false, "The chosen hmm database is not supported."];
          }
        }
        return [true];
      }
    },
    incE: {
      test: function (obj, load) {
        if (obj.closest('form').find('input[name=threshold]').filter(':checked').val() == 'evalue') {
          if( (obj.val() != parseFloat(obj.val())) || ( obj.val() > 10 || obj.val < 0)) {
            return [false, "incE should be a numeric value between 0 and 10" ];
          }
        }
        return [true];
      }
    },
    incdomE: {
      test: function (obj, load) {
        if (obj.closest('form').find('input[name=threshold]').filter(':checked').val() == 'evalue') {
          if( (obj.val() != parseFloat(obj.val())) || ( obj.val() > 10 || obj.val < 0)) {
            return [false, "incdomE should be a numeric value between 0 and 10"];
          }
        }
        return [true];
      }
    },
    repE: {
      test: function (obj, load) {
        if (obj.closest('form').find('input[name=threshold]').filter(':checked').val() == 'evalue') {
          if( (obj.val() != parseFloat(obj.val())) || ( obj.val() > 10 || obj.val < 0)) {
            return [false, "E should be a numeric value between 0 and 10"];
          }
        }
        return [true];
      }
    },
    domE: {
      test: function (obj, load) {
        if (obj.closest('form').find('input[name=threshold]').filter(':checked').val() == 'evalue') {
          if( (obj.val() != parseFloat(obj.val())) || ( obj.val() > 10 || obj.val < 0)) {
            return [false, "domE should be a numeric value between 0 and 10"];
          }
        }
        return [true];
      }
    },
    incT: {
      test: function (obj, load) {
        if (obj.closest('form').find('input[name=threshold]').filter(':checked').val() == 'bit') {
          if( (obj.val() != parseFloat(obj.val())) || ( obj.val() < 0)) {
            return [false, "incT should be a numeric value greater than or equal to 0"];
          }
        }
        return [true];
      }
    },
    incdomT: {
      test: function (obj, load) {
        if (obj.closest('form').find('input[name=threshold]').filter(':checked').val() == 'bit') {
          if( (obj.val() != parseFloat(obj.val())) || ( obj.val() < 0)) {
            return [false, "incdomT should be a numeric value greater than or equal to 0"];
          }
        }
        return [true];
      }
    },
    T: {
      test: function (obj, load) {
        if (obj.closest('form').find('input[name=threshold]').filter(':checked').val() == 'bit') {
          if( (obj.val() != parseFloat(obj.val())) || ( obj.val() < 0)) {
            return [false, "T should be a numeric value greater than or equal to 0"];
          }
        }
        return [true];
      }
    },
    domT: {
      test: function (obj, load) {
        if (obj.closest('form').find('input[name=threshold]').filter(':checked').val() == 'bit') {
          if( (obj.val() != parseFloat(obj.val())) || ( obj.val() < 0)) {
            return [false, "domT should be a numeric value greater than or equal to 0"];
          }
        }
        return [true];
      }
    },
    popen: {
      test: function (obj, load) {
        if ( obj.val() > 0.5 || obj.val() < 0) {
          return [false, "The Gap opening penalty must be a number between 0 and 0.5"];
        }
        return [true];
      }
    },
    pextend: {
      test: function (obj, load) {
        if ( obj.val() > 1 || obj.val() < 0) {
          return [false, "The Gap extending penalty must be a number between 0 and 1"];
        }
        return [true];
      }
    },
    mx: {
      test: function ( obj, load) {
        var matrixList = ['BLOSUM45','BLOSUM62','BLOSUM90','PAM30','PAM70'];
        if ($.inArray(obj.val(), matrixList) == -1) {
          return [false, "The matrix file specified is unrecognised. Please select another."];
        }
        return [true];
      }
    },
    numeric: {
      test: function (obj, load) {
        if (obj.val() != parseFloat(obj.val())) {
          var title = obj.attr('title');
          return [false, title + " field must contain a number"];
        }
        return [true];
      }
    },
    seqdb: {
      test: function( obj, load) {
        if (obj.prop('checked')) {
          var dbList = ['uniprotkb','swissprot','pdb','unimes', 'rp55', 'rp15', 'rp35', 'rp75', 'refseq', 'uniprotrefprot', 'pfamseq', 'ensemblplants','qfo'];
          if ($.inArray(obj.val(), dbList) == -1) {
            return [false, "The chosen sequence database is not supported."];
          }
        }
        return [true];
      }
    },
    pfamEvalue: {
      test: function (obj, load) {
        if( (obj.val() != parseFloat(obj.val())) || ( obj.val() > 10 || obj.val < 0)) {
          return [false, "pfam E value should be a numeric value between 0 and 10"];
        }
        return [true];
      }
    }
  };


  /****************** distribution graphic ******************/

  $.fn.distGraph = function() {
    if (typeof hitGraphData == 'undefined') { return; }
    if ( $('#barGraph').length == 0 ) { return; }
    $(this).siblings().removeClass('hidden');

    // the graphic is already there if we find #barGraph
    if ($(this).children('#barGraph').children('svg').length > 0) { return; }
    var height = 50;
    var width  = 410;
    var paper  = Raphael('barGraph', width, height);
    var data   = hitGraphData[0].slice().reverse();
    var labels = hitGraphData[1].slice().reverse();
    var oMax = 0;

    var fills = [
          "#900",     // Bacteria
          "#f3c800",  // Eukaryota
          "#009dcc",  // Archaea
          "#630000",  // Viruses
          "#999",     // Unclassified Sequences
          "#333"      // Other Sequences
    ];

    var species = [
          'Bacteria',
          'Eukaryota',
          'Archaea',
          'Viruses',
          'Unclassified Sequences',
          'Other Sequences'
    ];

    var classes = [
          'bact',
          'euk',
          'arc',
          'vir',
          'unc',
          'oth'
    ];

    var remaining = 0;
    for (var j = 0; j < data.length; j++){
      var colTotal = 0;
      for (var k = 0; k < data[j].length; k++) {
        remaining += parseInt(data[j][k], 10);
        colTotal += parseInt(data[j][k], 10);
      }
      if (colTotal > oMax) { oMax = colTotal; }
    }

    // draw an arrow to indicate low to high direction
    var arrow = paper.path("M0 25 L345 22 L345 18 L360 25 L345 33 L345 29 L0 25")
                      .attr({stroke: "#000", fill: "#999", opacity: "0.2" });
    // draw some text to indicate high vs low.
    var more   = paper.text(382, (height/2) + 1 , 'more\nsignificant').attr({fill: "#444"});
    for (var i = 0; i < data.length; i++) {
      // draw a grey line marker to indicate position of the bin
      var path = "M" + (i * 12) + ' ' + (height - 1) + 'L' + (i * 12 + 10) + ' ' + (height - 1);
      var hits = 0;
      for (var d = 0; d < data[i].length; d++) {
        hits += parseInt(data[i][d], 10);
      }
      // draw a rectangle for each data point if it is greater than 0
      if (hits) {
        var p = paper.path(path).attr({stroke: '#666'});
        var label = labels[i];

        // work out remaining rows so we know where in the table to link to
        remaining -= hits;
        var row = remaining;

        var previous = 0;
        for (var t = 0; t < data[i].length; t++){
          if (data[i][t] > 0) {
            //draw the scaled rectangles for each kingdom
            var pos = (47 * data[i][t]) / oMax;
            r = paper.rect((i * 12), (47 - (pos + previous)), 10, pos)
                .attr({stroke: fills[t], fill: fills[t], 'stroke-opacity':0.8});
            previous += pos;
          }
        }

        // create a mouse over target that is bigger than the scaled column
        target = paper.rect((i * 12), 0, 10, 47)
                  .attr({'stroke-opacity': 0,
                          fill: '#FFE87C',
                          stroke: '#FFE87C',
                          opacity:0,
                          title: label + "(" + hits + ")"})
                  .mouseover(function(e) {
                    this.attr({opacity: 0.5, 'stroke-opacity': 0.5});
                  })
                  .mouseout(function(e) {
                    this.attr({opacity: 0, 'stroke-opacity': 0});
                  })
                  .click(function(e) {
                    if (dist_data.rows === 'All') {
                      $('#list > tbody > tr').not('.ali').eq(this._row - 1).css('backgroundColor','#ffe87c')
                        .animate({'backgroundColor': '#ffffff'},3000, function() {
                          $(this).css('backgroundColor','');
                        })[0].scrollIntoView(false);
                    }
                    else {
                      var targetPage = Math.ceil( this._row / parseInt(dist_data.rows, 10) );
                      if (targetPage === 0) {
                        targetPage = 1;
                      }
                      var targetRow;
                      if (targetPage == dist_data.page) {
                        targetRow = this._row - ((dist_data.page - 1) * parseInt(dist_data.rows, 10));
                        $('#list > tbody > tr').not('.ali').eq(targetRow - 1).css('backgroundColor','#ffe87c')
                          .animate({'backgroundColor': '#ffffff'},3000, function() {
                            $(this).css('backgroundColor','');
                          })[0].scrollIntoView(false);
                      }
                      else {
                        targetRow = this._row - ((targetPage - 1) * parseInt(dist_data.rows)) ;
                        var url = site_url + '/results/' + dist_data.uuid + '/score?page=' + targetPage + ';row=r' + targetRow;
                        if (dist_data.addpfam) {
                          url += ';pfam=1';
                        }
                        window.location = url;
                      }
                    }
                  });
        // create the tool tip for each bin.
        //
        var title = "<p>E-value: " + label  + '</p>';
        var text = '<ul class="breakdown">';
        for (var t = 0; t < data[i].length; t++){
          if (data[i][t] > 0) {
            text += '<li class="' + classes[t] + '"><span>' + species[t] + ": " + data[i][t] + "</span></li>";
          }
        }
        text += "</ul>";
        $(target.node).qtip({position: {
            viewport: $(window),
            my: 'bottom center',
            at: 'top center'
          },
          content: {
            title: title,
            text:  text
          },
          style: {
            classes: 'ui-tooltip-hmmerdist ui-tooltip-rounded'
          }
        });
        target._row = row + 1;
      }
      else {
        var p = paper.path(path).attr({stroke: '#ccc'});
      }
    }
    $('#disthelp').help();
  };

  /************************** misc functions ******************/
  function resetForm() {
    $('textarea').val('').text('');
    $('#ga').click();
  }

  function exampleSeq (e){
    var exSeq = ">2abl_A mol:protein length:163  ABL TYROSINE KINASE\n\
MGPSENDPNLFVALYDFVASGDNTLSITKGEKLRVLGYNHNGEWCEAQTKNGQGWVPSNYITPVNSLEKHS\
WYHGPVSRNAAEYLLSSGINGSFLVRESESSPGQRSISLRYEGRVYHYRINTASDGKLYVSSESRFNTLAE\
LVHHHSTVADGLITTLHYPAP";
    $("textarea").val(exSeq).text(exSeq).change();
    e.preventDefault();
  }

  function exampleAli (e){
    var exHmm = $('#example_ali').text();
    $("textarea").val(exHmm).text(exHmm).change();
    e.preventDefault();
  }

  function exampleHmm (e){
    var exHmm = $('#example_hmm').text();
    $("textarea").val(exHmm).text(exHmm).change();
    e.preventDefault();
  }

})(jQuery);

//Fix for toggle(function, function, ...) being removed in jquery 1.9
(function( $ ){
  $.fn.toggler = function( fn, fn2 ) {
    var args = arguments,guid = fn.guid || $.guid++,i=0,
    toggler = function( event ) {
      var lastToggle = ( $._data( this, "lastToggle" + fn.guid ) || 0 ) % i;
      $._data( this, "lastToggle" + fn.guid, lastToggle + 1 );
      event.preventDefault();
      return args[ lastToggle ].apply( this, arguments ) || false;
    };
    toggler.guid = guid;
    while ( i < args.length ) {
      args[ i++ ].guid = guid;
    }
    return this.click( toggler );
  };


})( jQuery );

$(function(){
  $('.youTubeVideo').click(function(){
    var vidtitle = $(this).parents('.videoThum').next('.videoInfo').find('h2').text();
    $('.video-container .iframe h2').text(vidtitle);
    var winWidth = $(window).width();
        var winHeight = $(window).height();
        var centerDiv = $('.popup');
        var left = winWidth / 2 - ((parseInt(centerDiv.css("width"))) / 2);
        var top = winHeight / 2 - ((parseInt(centerDiv.css("height"))) / 2);
        centerDiv.css({'left': left,'top': '15%'});
        $('.youtube').show();
      $('.popup.youtube, .overlaybg').show();
     $("html,body").animate({scrollTop: 0}, 800);
    var ind = $(this).parents('.videoThum').addClass('aaa').parents('.guideBox').siblings().find('.videoThum').removeClass('aaa');  
    var linkSrc = $(this).parents('.videoThum').find('a').attr('rel');
     //$('.youtube .video-container').find('iframe').attr('src', linkSrc);
    $('#tutorialmovie').attr('src',linkSrc );
    $("#sampleMovie").load();
  }); 
  
  $('.close, .overlaybg').click(function(){
    //$('.youtube .video-container').find('iframe').attr('src', '');              
    $('.youtube .video-container').find('source').attr('src', '');              
    $('.popup.youtube, .overlaybg').hide();
  }); 
  });
