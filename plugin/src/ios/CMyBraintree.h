#import <Cordova/CDV.h>
#import "Braintree/Braintree.h"

@interface MyBraintree : CDVPlugin <BTDropInViewControllerDelegate>


@property (nonatomic, strong) Braintree *braintree;

// This will return the file contents in a JSON object via the getFileContents utility method
- (void) Pay:(CDVInvokedUrlCommand *)command;

@end