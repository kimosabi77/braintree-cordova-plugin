module.exports = {

    Pay: function (onsuccess, onfail, base_url, amount, pri_desc, sec_desc) {
        // Get Client Token
        // alert("execute MyBraintree Pay");

     //    $.ajax({
     //    	url: base_url + "/token", 
     //    	dataType: "json",
     //    	success: function(result){
     //    		// alert(result.client_token);
     //    		alert(JSON.stringify(result));
    	// 	},
    	// 	error: function(xhr,status,error) {
    	// 		alert("xhr" + xhr);
    	// 		alert("status" + status);
    	// 		alert("error" + error);
    	// 	}
    	// });

        cordova.exec(onsuccess, onfail, "MyBraintree", "Pay", [base_url, amount, pri_desc, sec_desc]);

    }
}