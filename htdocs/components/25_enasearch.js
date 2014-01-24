var R1;
var resFile;

function updateParams(evalue, splicing, masking, domain) {
  setSelect('evalue', evalue);
  setCheckBox('masking', masking);
  setCheckBox('splicing', splicing);
  setCheckBox('sdomain', domain);
}

function resetStatus() {
        document.getElementById("jobstatus").value='new'; 
//        $('#blastForm').append('<input type="hidden" name="newjob" id="newjob" value="new" />');
}

function setUpdate(jobid, evalue, splicing, masking, domain) {
  var pm = $("#progress-msg");
  pm.html('Contacting ENA ...');
  updateParams(evalue, splicing, masking, domain);
  R1 = setInterval(function () {
    var url = '/Multi/enastatus?job='+jobid;
    var c = updateP(url);
    if (c > 0) {
        clearInterval(R1);
        document.getElementById("jobstatus").value='ready'; 
//$('#blastForm').append('<input type="hidden" name="jobstatus" id="jobstatus" value="ready" />');
        document.getElementById("blastForm").submit();
    }
 }, 900);
}


function setSelect(el, sval) {
  var sel = document.getElementById(el);
  for(i=0;i<sel.length;i++) { 
     if(sel.options[i].value == sval) { break; } 
  }
  sel.options.selectedIndex = i;
}

function setCheckBox(el, sval) {
  var sel = document.getElementById(el);
  if (sel) {
  if (sval) {
    sel.checked = true;
  } else {
    sel.checked = false;
  }
}
}

function updateP(pFile) {
  $.ajaxSetup({ cache: false });
  $.getJSON(pFile, function(pData, textStatus) {
    var prog = pData.progress;
    var c = pData.count;
    var s = pData.status;

    var pb = $("#progress-bar");

    var message = 'Contacting ENA ...';

    if (s == 'COMPLETE') {
	message = "Completed.  Found " + c + " hits.";
        pb.addClass("completed");
    } else {
       if (prog > -1) {
          message = 'Running search [ ' + prog + '% ]';
       }
    }

    pb.css('width', prog + '%');

    var pm = $("#progress-msg");
    pm.html(message);

});
    var pb = $("#progress-bar");
    if (pb.hasClass("completed")) {
	return 1;
    }
    return 0;
}

function showAlignment(id) {
 var eid = '#' + id;
 var w = window.open();
 var html = $(eid).html();
 w.document.writeln(html);
}

function sortResults(col) {
 $('#blastForm').append('<input type="hidden" name="order" value="' + col + '" />');
// $('#blastForm').append('<input type="hidden" name="jobstatus" value="ready" />');
        document.getElementById("jobstatus").value='ready'; 
        document.getElementById("blastForm").submit();
}


function setPage(page, col) {
 $('#blastForm').append('<input type="hidden" name="order" value="' + col + '" />');
 $('#blastForm').append('<input type="hidden" name="page" value="' + page + '" />');
// $('#blastForm').append('<input type="hidden" name="jobstatus" value="ready" />');
        document.getElementById("jobstatus").value='ready'; 
 document.getElementById("blastForm").submit();
}
