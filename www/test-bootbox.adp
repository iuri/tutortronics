
<master>


<style>
  .on1 {
    background: #000000;
    width: 100%;
    height: 100%;
    position: fixed;
    opacity: 0.7;
    z-index: 11 !important;
    filter: alpha(opacity:70) !important;
    display: none;
  }
</style>

 
<script type="text/javascript">
  $(document).ready(function () {
    //    alert("HELLO");
    var time = "00:30s";

    window.setInterval(function () {
      window.setTimeout(function () {
        $("div.on1").fadeIn("slow");

      
        bootbox.confirm({
          message: "<center>Your session is about to expire! <br> " + time + " <br> Do you want to cotinue logged in?</center>",
    	  buttons: {
      	    confirm: {
              label: 'Yes',
	      className: 'btn-success'
      	    },
      	    cancel: {
              label: 'No',
	      className: 'btn-danger'
      	    }
    	  },
    	  callback: function (result) {
	    if (result == 1) {
	      $.ajax({
	        url: "renew-session",
	        success: function(result){
	          //alert(result);
		  $("div.on1").fadeOut("slow");

	        }
	      });
	    }
      	    // console.log('This was logged in the callback: ' + result);
    	  }
        });
      }, @alert_timeout@);
    }, @session_timeout@);
  });




</script>
      
<script src="https://code.jquery.com/jquery-1.12.3.min.js"></script>
<script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/anchor-js/3.2.0/anchor.js"></script>
<script src="/intranet/js/bootbox.js"></script>
