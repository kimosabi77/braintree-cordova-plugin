module.exports = {

    Pay: function (onsuccess, onfail, base_url, customer_id, amount, pri_desc, sec_desc) {
        cordova.exec(onsuccess, onfail, "MyBraintree", "Pay", [base_url,customer_id,amount, pri_desc, sec_desc]);
    }
}