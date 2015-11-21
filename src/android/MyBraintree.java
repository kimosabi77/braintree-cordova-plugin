package com.my.mybraintree;

import android.app.AlertDialog;
import android.app.AlertDialog.Builder;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.Context;
import android.util.Log;
import android.widget.Toast;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import com.braintreepayments.api.dropin.*;
import com.loopj.android.http.*;
import com.google.gson.Gson;

public class MyBraintree extends CordovaPlugin {
    private static final int REQUEST_CODE = 100;
    private AsyncHttpClient client = new AsyncHttpClient();
        // callbacks
    private CallbackContext callbackContext;

    private String SERVER_BASE;
    private String CUSTOMER_ID;
    private String clientToken;
    private String amount;
    private String primaryDescription;
    private String secondaryDescription;

    private final String TAG = "com.my.mybraintree";

    private Context mContext;
	private Gson gson = new Gson();

    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);
        //Log.v(TAG,"Init CoolPlugin");

        mContext = cordova.getActivity().getApplicationContext();
    }

    public boolean execute(String action, JSONArray args, CallbackContext callbackContext)
    throws JSONException {
    	//Log.v(TAG,"execute");
        if (action.equals("Pay")) {
        	//Log.v(TAG,"Call Pay");

        	SERVER_BASE = args.getString(0);
            CUSTOMER_ID = args.getString(1)
        	amount = args.getString(2);
        	primaryDescription = args.getString(3);
        	secondaryDescription = args.getString(4);

            getToken();

            this.callbackContext = callbackContext;

            PluginResult result = new PluginResult(PluginResult.Status.NO_RESULT);
            result.setKeepCallback(true);
            callbackContext.sendPluginResult(result);

            return true;
        }
        return false;
    }

    private void ShowDropIn() {
        Customization customization = new Customization.CustomizationBuilder()
        .primaryDescription(primaryDescription)
        .secondaryDescription(secondaryDescription)
        .amount(amount)
        .submitButtonText("Pay")
        .build();

        Intent intent = new Intent(mContext, BraintreePaymentActivity.class);
        intent.putExtra(BraintreePaymentActivity.EXTRA_CUSTOMIZATION, customization);
        intent.putExtra(BraintreePaymentActivity.EXTRA_CLIENT_TOKEN, clientToken);

        cordova.setActivityResultCallback (this);
        cordova.getActivity().startActivityForResult(intent, REQUEST_CODE);
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
    	if (requestCode == REQUEST_CODE) {
	        if (resultCode == BraintreePaymentActivity.RESULT_OK) {
	        	// using Android SDK v1.
	            String paymentMethodNonce = data.getStringExtra(BraintreePaymentActivity.EXTRA_PAYMENT_METHOD_NONCE);

                //Log.v(TAG,"Payment Method Nonce : %s" + paymentMethodNonce);

	            RequestParams requestParams = new RequestParams();
	            requestParams.put("payment_method_nonce", paymentMethodNonce);
	            requestParams.put("amount", amount);

	            // send nonce to server
	            client.post(SERVER_BASE + "/payment", requestParams, new AsyncHttpResponseHandler() {
	                @Override
	                public void onSuccess(String content) {
	                	Bean data = gson.fromJson(content, Bean.class);
	                	if (data.success) {
	                        Toast.makeText(mContext, "Payment successed", Toast.LENGTH_LONG).show();

                            PluginResult result = new PluginResult(PluginResult.Status.OK, content);
                            callbackContext.sendPluginResult(result);
	                	} else {
	                        Toast.makeText(mContext, "Payment Failed : " + data.message, Toast.LENGTH_LONG).show();

                            PluginResult result = new PluginResult(PluginResult.Status.ERROR);
                            callbackContext.sendPluginResult(result);
                        }

	                	Log.v(TAG, "Payment result : " + content);

	                }
	            });

	        	// using Android SDK v2.
//	            PaymentMethod paymentMethod = data.getParcelableExtra(
//	                    BraintreePaymentActivity.EXTRA_PAYMENT_METHOD
//	                  );
//                String nonce = paymentMethod.getNonce();
//            	Log.v(TAG, "Nonce : " + nonce);
//
//
//                // Send the nonce to your server.
//                AsyncHttpClient client = new AsyncHttpClient();
//                RequestParams params = new RequestParams();
//                params.put("payment_method_nonce", nonce);
//                client.post(SERVER_BASE + "/payment-methods", params,
//					new AsyncHttpResponseHandler() {
//
//					    @Override
//					    public void onSuccess(String content) {
//		                    Toast.makeText(mContext, content, Toast.LENGTH_LONG).show();
//		                	Log.v(TAG, "Payment Result : " + content);
//
//					    }
//					}
//                );

	        }
    	}
    }

    private void getToken() {
    	//Log.v(TAG, "Connect to " + SERVER_BASE + "/token");

        RequestParams requestParams = new RequestParams();
        requestParams.put("customer_id", CUSTOMER_ID);
        client.post(SERVER_BASE + "/token", requestParams,new AsyncHttpResponseHandler() {

            @Override
            public void onSuccess(String content) {
            	Bean data = gson.fromJson(content, Bean.class);
                clientToken = data.client_token;

            	//Log.v(TAG, "content : " + content);
            	//Log.v(TAG, "client_token : " + clientToken);
            	

            	if (data.success)
            		ShowDropIn();
            	else {
                    Toast.makeText(mContext, "Getting client token Failed", Toast.LENGTH_LONG).show();

                    PluginResult result = new PluginResult(PluginResult.Status.ERROR);
                    callbackContext.sendPluginResult(result);
                }
            }
        });
    }
    
    private class Bean {
    	private boolean success;
    	private String client_token;
    	private String message;
    }
}