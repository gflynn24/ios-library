/* Copyright Urban Airship and Contributors */

#import "UAShareAction.h"
#import "UAUtils+Internal.h"
#import "UAGlobal.h"
#import "UAActivityViewController.h"

@interface UAShareAction()
@property (nonatomic, strong) UAActivityViewController *lastActivityViewController;
@end

@implementation UAShareAction

- (BOOL)acceptsArguments:(UAActionArguments *)arguments {

    if (arguments.situation == UASituationBackgroundPush || arguments.situation == UASituationBackgroundInteractiveButton) {
        return NO;
    }

    if (![arguments.value isKindOfClass:[NSString class]]) {
        return NO;
    }

    return YES;
}

- (void)performWithArguments:(UAActionArguments *)arguments
           completionHandler:(UAActionCompletionHandler)completionHandler {

    UA_LDEBUG(@"Running share action: %@", arguments);

    NSArray *activityItems = @[arguments.value];

    UAActivityViewController *activityViewController = [[UAActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    activityViewController.excludedActivityTypes = @[UIActivityTypeAssignToContact, UIActivityTypePrint, UIActivityTypeSaveToCameraRoll, UIActivityTypeAirDrop, UIActivityTypePostToFacebook];

    UIUserInterfaceIdiom userInterfaceIdiom = [UIDevice currentDevice].userInterfaceIdiom;

    void (^displayShareBlock)(void) = ^(void) {

        self.lastActivityViewController = activityViewController;

        // iOS 8.0+
        if ([activityViewController respondsToSelector:@selector(popoverPresentationController)]) {

            UIPopoverPresentationController * popoverPresentationController = activityViewController.popoverPresentationController;

            popoverPresentationController.permittedArrowDirections = 0;

            // Set the delegate, center the popover on the screen
            popoverPresentationController.delegate = activityViewController;
            popoverPresentationController.sourceRect = activityViewController.sourceRect;
            popoverPresentationController.sourceView = [UAUtils topController].view;

            [[UAUtils topController] presentViewController:activityViewController animated:YES completion:nil];

        } else if (userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            [[UAUtils topController] presentViewController:activityViewController animated:YES completion:nil];
        }
    };


    void (^dismissalBlock)(void);
    UA_WEAKIFY(self);

    activityViewController.dismissalBlock = dismissalBlock = ^{
        UA_STRONGIFY(self)

        completionHandler([UAActionResult emptyResult]);

        self.lastActivityViewController = nil;
    };

    if (self.lastActivityViewController) {
        self.lastActivityViewController.dismissalBlock = ^{
            dismissalBlock();
            displayShareBlock();
        };

        if (userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            [self.lastActivityViewController dismissViewControllerAnimated:YES completion:nil];
        }
    } else {
        displayShareBlock();
    }
}

@end
