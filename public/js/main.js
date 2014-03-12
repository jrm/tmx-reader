$(function () {
  
  $('#segments').dataTable();
  
  $('.audit-details').tooltip();
  
  $("#memories").on('click', '.delete-memory', function(e) { 
	    if (confirm("Are you sure you want to delete " + $(this).data("id") + " ?" )) {
	      var frm = $("<form>");
        frm.attr({'action':$(this).attr('href'), 'method': 'post'});
        frm.append('<input type="hidden" name="_method" value="delete" />');
        frm.appendTo("body");
        frm.submit();
        e.preventDefault();
      }
      return false;
  });  
	
  
});
