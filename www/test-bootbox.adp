
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

    window.setInterval(function () {
      $("div.on1").fadeIn("slow");

      bootbox.confirm({
	size: "small",
	message: "Your session is about to expire!",
      	callback: function(result){
	  if(result) {
	    // go
	  }
	}
      });

      $('#ajax-status-message').html('Your session is about to expire! <br> You may click here if you want to extend the session interval');

      $('#ajax-status-message').fadeIn();
    }, 100);

    return false;
  });
</script>
      



