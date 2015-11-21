#import "CMyBraintree.h"
#import <Cordova/CDV.h>

@implementation MyBraintree

BOOL success;
NSString *client_token;
NSString *message;
NSString *result;
NSString *content;

NSString *callbackID;

NSString *base_url;
NSString *amount;
NSString *primary_description;
NSString *secondary_description;

- (void)pluginInitialize {
    
    NSLog(@"Bluetooth Serial Cordova Plugin - BLE version");
    NSLog(@"(c)2013-2014 Don Coleman");
    
    [super pluginInitialize];

    
}

- (void) Pay:(CDVInvokedUrlCommand *)command {
    __block CDVPluginResult *pluginResult = nil;

    base_url = [command.arguments objectAtIndex:0];
    customer_id = [command.arguments objectAtIndex:1];
    amount = [command.arguments objectAtIndex:2];
    primary_description = [command.arguments objectAtIndex:3];
    secondary_description = [command.arguments objectAtIndex:4];
    
    NSURL *clientTokenURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/token", base_url]];
    NSMutableURLRequest *clientTokenRequest = [NSMutableURLRequest requestWithURL:clientTokenURL];
    NSDictionary *params = @{@"payment_method_nonce": paymentMethodNonce, @"amount": amount};
    [clientTokenRequest setValue:@"text/plain" forHTTPHeaderField:@"Accept" setHTTPBody:[self httpBodyForParamsDictionary:params]];
    clientTokenRequest.HTTPMethod = @"POST";
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:clientTokenRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        // TODO: Handle errors
        NSString *returnedString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [self parseJSON:returnedString];
        
        if (!error) {
            if (success) {
                
                NSLog(@"client Token : %@", client_token);
                
                // Initialize `Braintree` once per checkout session
                self.braintree = [Braintree braintreeWithClientToken:client_token];
                
                // As an example, you may wish to present our Drop-In UI at this point.
                // Continue to the next section to learn more...
                
                
                // Create a BTDropInViewController
                BTDropInViewController *dropInViewController = [self.braintree dropInViewControllerWithDelegate:self];
                // This is where you might want to customize your Drop in. (See below.)
                
                // The way you present your BTDropInViewController instance is up to you.
                // In this example, we wrap it in a new, modally presented navigation controller:
                dropInViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                                                      target:self
                                                                                                                      action:@selector(userDidCancelPayment)];
                
                dropInViewController.summaryTitle = primary_description;
                dropInViewController.summaryDescription = secondary_description;
                dropInViewController.displayAmount = amount;
                
                UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:dropInViewController];
                [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:navigationController animated:YES completion:nil];
                
                callbackID = [command.callbackId copy];

                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
                [pluginResult setKeepCallbackAsBool:TRUE];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                
                return;
            }
        }

        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }] resume];

    
}

- (void)userDidCancelPayment {
    [[UIApplication sharedApplication].keyWindow.rootViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)dropInViewController:(__unused BTDropInViewController *)viewController didSucceedWithPaymentMethod:(BTPaymentMethod *)paymentMethod {
    [self postNonceToServer:paymentMethod.nonce]; // Send payment method nonce to your server
    [[UIApplication sharedApplication].keyWindow.rootViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)dropInViewControllerDidCancel:(__unused BTDropInViewController *)viewController {
    [[UIApplication sharedApplication].keyWindow.rootViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)postNonceToServer:(NSString *)paymentMethodNonce {
    // Update URL with your server
    NSURL *paymentURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/payment", base_url]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:paymentURL];
    
    NSDictionary *params = @{@"payment_method_nonce": paymentMethodNonce, @"amount": amount};
    [request setHTTPBody:[self httpBodyForParamsDictionary:params]];
    
    request.HTTPMethod = @"POST";
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        // TODO: Handle success and failure
        
        CDVPluginResult *pluginResult = nil;

        if(!error) {
            content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            [self parseJSON:content];
            
            if (success) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: content];
                [pluginResult setKeepCallbackAsBool:TRUE];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackID];

                return;
            }
        }

        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackID];
    }] resume];
}

-(void) parseJSON:(NSString *)returnedString {
    NSData *returnedData = [returnedString dataUsingEncoding:NSUTF8StringEncoding];
    
    if(NSClassFromString(@"NSJSONSerialization"))
    {
        NSError *error = nil;
        id object = [NSJSONSerialization
                     JSONObjectWithData:returnedData
                     options:0
                     error:&error];
        
        if(error) { success = NO; return; }
        
        if([object isKindOfClass:[NSDictionary class]])
        {
            NSDictionary *results = object;
            
            for (NSString* key in results) {
                id value = [results objectForKey:key];
                NSLog(@"key=%@ value=%@", key, value);
                
                if ([key isEqualToString:@"success"]) {
                    success = [value boolValue];
                } else if ([key isEqualToString:@"client_token"]) {
                    client_token = [NSString stringWithFormat:@"%@", value];
                } else if ([key isEqualToString:@"message"]) {
                    message = [NSString stringWithFormat:@"%@", value];
                } else if ([key isEqualToString:@"result"]) {
                    result = [NSString stringWithFormat:@"%@", value];
                }
            }
        }
        else
        {
            success = NO;
        }
    }
    else
    {
        success = NO;
    }
}

- (NSData *)httpBodyForParamsDictionary:(NSDictionary *)paramDictionary
{
    NSMutableArray *parameterArray = [NSMutableArray array];
    
    [paramDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
        NSString *param = [NSString stringWithFormat:@"%@=%@", key, [self percentEscapeString:obj]];
        [parameterArray addObject:param];
    }];
    
    NSString *string = [parameterArray componentsJoinedByString:@"&"];
    
    return [string dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)percentEscapeString:(NSString *)string
{
    NSString *result = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                 (CFStringRef)string,
                                                                                 (CFStringRef)@" ",
                                                                                 (CFStringRef)@":/?@!$&'()*+,;=",
                                                                                 kCFStringEncodingUTF8));
    return [result stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    
}
@end