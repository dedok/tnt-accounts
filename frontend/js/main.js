/**
 * Helpers {{{
 */
function say_error(data) {
  console.log('Error = ', data);
  alert('Ошибка! Сообщение = ' + data.error.message);
}

function say_ok(data) {
  console.log('Ok = ', data);
  alert('Выполнено! Cообщение = ' + JSON.stringify(data));
}


function post(url, data, ok, err) {
  if (typeof(ok) == 'undefined' || ok == NULL) {
    ok = say_ok;
  }
  if (typeof(err) == 'undefined' || err == NULL) {
    err = say_error;
  }

  $.ajax({
    type: "POST",
    url: url,
    data: JSON.stringify(data),
    contentType: "application/json; charset=utf-8",
    dataType: "json",
    success: ok,
    failure: say_error,
  });
}
/** }}} */


/**
 * Operations {{{
 */
$("#show_operations").bind("click", function() {
  $('#add_user_container').hide();
  $('#lists_container').hide();
  $('#balance_container').hide();

  $('#operations_container').show();
});


$("#apply_operation").bind("click", function() {

  post('/api/add/operation', {
    params:[{
      timestamp: Math.floor(Date.now()/1000),
      account_id: Number($('#op_account_id').val()),
      type: Number($('#operation_type option:selected').val()),
      description: $('#description').val(),
      amount: Number($('#amount').val())
    }]
  });
});
/** }}} */


/**
 * Balance {{{
 */
$("#show_balance").bind("click", function() {
  $('#add_user_container').hide();
  $('#lists_container').hide();
  $('#operations_container').hide();

  $('#balance_container').show();
});


$("#get_balance").bind("click", function() {
  $.get('/api/get/account/balance?account_id=' + $('#gb_account_id').val(),
        say_ok).fail(function(data) { say_error(data); });
});
/** }}} */


/**
 * Lists {{{
 */

$("#show_lists").bind("click", function() {
  $('#add_user_container').hide();
  $('#operations_container').hide();
  $('#balance_container').hide();

  $('#lists_container').show();
});


$("#get_last_n_operations").bind("click", function() {

  $.get('/api/get/account/operations?account_id=' +
      Number($('#ll_account_id').val()),
      function(_) {

        var table = {aaData: [],
            bPaging: false,
            bSearching: false,
            bDestroy: true
        };

        var result = typeof(_) === 'string' ? JSON.parse(_).result : _.result;

        var user = result[0];
        var data = result[1];

        for (var i = 0; i < data.length; i++) {
          table.aaData.push($.map(data[i], function(v) { return v; }));
        }

        n_out_table = $('#n_out').dataTable(table);
      }
  ).fail(say_error());
});

$("#get_operations_for_period").bind("click", function() {

  var ts_end = $('#ts_end').val()
  var ts_start = $('#ts_start').val();

  $.get('/api/get/operations?ts_start=' + ts_start + '&ts_end=' + ts_end,
    function(_) {

      var table = {aaData: [],
          bSearching: false,
          bDestroy: true
      };


      var r = typeof(_) === 'string' ? JSON.parse(_).result : _.result;

    try {
      for (var i = 0; i < r.length; i++) {
        var arr = $.map(r[i][0], function(v) { return v; });
        var arr_1 = $.map(r[i][1], function(v) { return v; });
        table.aaData.push(arr.concat(arr_1));
      }
      p_out_table = $('#p_out').dataTable(table);
    } catch (e) {
        console.log(e);    
    }

    }
  ).fail(say_error)
});
/** }}} */

/**
 *  Add user {{{
 */
$("#show_add_user").bind("click", function() {
  $('#operations_container').hide();
  $('#lists_container').hide();
  $('#balance_container').hide();

  $('#add_user_container').show();
});

$("#do_add_user").bind("click", function() {

  post('/api/add/user', {
    params:[{
      account_id: Number($('#au_account_id').val()),
      user_name: $('#user_name').val()
    }]
  });
});
/** }}} */
