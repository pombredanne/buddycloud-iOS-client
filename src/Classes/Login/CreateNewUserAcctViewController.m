/* 
 CreateNewUserAcctViewController.m
 Buddycloud
 
 Created by Adnan U - [Deminem] on 12/11/10.
 Copyright 2010 buddycloud. All rights reserved.
 
 */
 
#import "CreateNewUserAcctViewController.h"

static NSString *createNewUserAcctViewController = @"CreateNewUserAcctViewController";

@implementation CreateNewUserAcctViewController

@synthesize createTitleLabel, registerTitleLabel, userNameLabel, newPasswordLabel, userNameTxtField, newPasswordTxtField, helpBtn;

- (id)initWithTitle:(NSString *)title {
	if (self = [super initWithNibName:createNewUserAcctViewController bundle: [NSBundle mainBundle]]) {
		self.title = title;
		
		[[TTNavigator navigator].URLMap from:kexploreChannelsURLPath
							toViewController:self selector:@selector(allowUserToExploreChannels:withUserIno:)];
		
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(createBtnLabel, @"") 
																				   style:UIBarButtonItemStyleBordered
																				  target:self action:@selector(join:)] autorelease]; 
		
		self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(cancelBtnLabel, @"") 
																				  style:UIBarButtonItemStyleBordered
																				 target:self action:@selector(cancel:)] autorelease];

		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(registeredWithSuccess:)
													 name: [Events USER_REGISTRATION_SUCCESS]
												   object: nil];

		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(registeredWithFailure:)
													 name: [Events USER_REGISTRATION_FAILED]
												   object: nil];
	}
	
	return self;
}

- (void)dealloc {
	[[TTNavigator navigator].URLMap removeURL:kexploreChannelsURLPath];
	
	[super dealloc];
}

- (void)viewWillAppear:(BOOL)flag {
    [super viewWillAppear:flag];
    [self.userNameTxtField becomeFirstResponder];
}

- (void)viewDidLoad {
	
	[super viewDidLoad];
	
	self.createTitleLabel.text = NSLocalizedString(createBuddyCloudId, @"");
	self.registerTitleLabel.text = NSLocalizedString(registerAcctMsg, @"");
	self.userNameLabel.text = [NSString stringWithFormat:NSLocalizedString(chooseAWildCard, @""), NSLocalizedString(userName, @"")];
	self.newPasswordLabel.text = [NSString stringWithFormat:NSLocalizedString(chooseAWildCard, @""), NSLocalizedString(password, @"")];

	self.userNameTxtField.placeholder = NSLocalizedString(userName, @"");
	self.userNameTxtField.delegate = self;
	
	self.newPasswordTxtField.placeholder = NSLocalizedString(password, @"");
	self.newPasswordTxtField.delegate = self;
}

- (void)showErrorMsg:(NSString *)sMsg {
	
	NSString *errorMsg = [NSString stringWithFormat:@"<p><span class=''>%@</span></p>", sMsg];
	TTView *errorView = (TTView *)[self.view viewWithTag:errorMsgView_tag];
	
	if (errorView == nil) {
		errorView = [[[UIView alloc] initWithFrame:CGRectMake(self.newPasswordLabel.frame.origin.x, self.newPasswordLabel.frame.origin.y + self.newPasswordLabel.frame.size.height + 5.0, self.view.width - 20.0, 50.0)] autorelease];
		[errorView setBackgroundColor:[UIColor clearColor]];
		[errorView setTag:errorMsgView_tag];
		
		UIImageView *errorImg = [[[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 16.0, 16.0)] autorelease];
		errorImg.image = [UIImage imageNamed:@"error.png"];
		[errorView addSubview:errorImg];
		
		TTStyledTextLabel *errorMsgLabel = [[[TTStyledTextLabel alloc] initWithFrame:CGRectMake(20.0, 0.0, errorView.frame.size.width, errorView.frame.size.height)] autorelease];
		[errorMsgLabel setBackgroundColor:[UIColor clearColor]];
		[errorMsgLabel setTextColor:[UIColor redColor]];
		[errorMsgLabel setHighlightedTextColor:[UIColor redColor]];
		[errorMsgLabel setFont:[UIFont fontWithName:@"Helvetica" size:12]];
		[errorMsgLabel setUserInteractionEnabled:YES];
		[errorMsgLabel setTextAlignment:UITextAlignmentLeft];
		[errorMsgLabel setTag:errorLabel_tag];
		[errorView addSubview:errorMsgLabel];	
		
		[self.view addSubview:errorView];
	}
	
	TTStyledTextLabel *errorMsgLabel = (TTStyledTextLabel *)[self.view viewWithTag:errorLabel_tag];
	[errorMsgLabel setText:[TTStyledText textFromXHTML:errorMsg lineBreaks:NO URLs:NO]];
}

- (void)removeErrorMsg {
	TTView *errorView = (TTView *)[self.view viewWithTag:errorMsgView_tag];
	if (errorView) {
		[errorView removeFromSuperview];	//remove the error view.
	}
}

- (void)join:(id)sender {
	NSLog(@"join.....");
	UIAlertView *alertView = nil;
	[self removeErrorMsg];
	
	if ( (self.userNameTxtField.text != nil && ![self.userNameTxtField.text isEmptyOrWhitespace]) &&
		 (self.newPasswordTxtField.text != nil && ![self.newPasswordTxtField.text isEmptyOrWhitespace]) )
	{
		[[BuddycloudAppDelegate sharedAppDelegate].spiralLoadingView showActivityLabelWithStyle:TTActivityLabelStyleBlackBezel 
																					   withText:NSLocalizedString(loading, @"")
																		   withTransparentSheet:YES
																			  withActivityFrame:CGRectMake(self.view.width/2 - 50.0, self.view.height/2 - (100.0 + 30.0), 100.0, 100.0)]; 
		
		//In-band registration.
		XMPPEngine *xmppEngine = (XMPPEngine *)[[BuddycloudAppDelegate sharedAppDelegate] xmppEngine];
		NSRange range = [self.userNameTxtField.text rangeOfString:@"@" options:NSLiteralSearch];
		NSString *newJIDStr = nil;
		
		//Before disconnect, check if it's not the same username through which it's already login.
		if(range.location != NSNotFound && range.length > 0) {
			if ([[xmppEngine.xmppStream.myJID bare] isEqualToString:self.userNameTxtField.text]) {
				
				//Stop the activity.
				[[BuddycloudAppDelegate sharedAppDelegate].spiralLoadingView stopActivity];
				
				alertView = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(alertPrompt, @"")
														message:[NSString stringWithFormat:NSLocalizedString(userNameLoggedInConflictError, @""), NSLocalizedString(userName, @"")]
													   delegate:self
											  cancelButtonTitle:NSLocalizedString(okButtonLabel, @"") 
											  otherButtonTitles:nil] autorelease];
				[alertView show];
				
				return;
			}
			
			newJIDStr = self.userNameTxtField.text;
		}
 
		[xmppEngine disconnect];	//disconnect the previous session before in-band registration.
		
		xmppEngine.isNewUserRegisteration = YES;
		xmppEngine.password = self.newPasswordTxtField.text;
		XMPPJID *newJID = (newJIDStr) ? [XMPPJID jidWithString: newJIDStr 
													  resource: XMPP_BC_IPHONE_RESOURCE] : 
										[XMPPJID jidWithUser: self.userNameTxtField.text 
																  domain: XMPP_BC_DOMAIN 
																resource: XMPP_BC_IPHONE_RESOURCE];
		
		[xmppEngine.xmppStream setMyJID:newJID];
		
		//NOTE: It will authenticate the user if it's already registered user on BC, otherwise register the new account and authenticate anonoymously.
		[xmppEngine connect];
	}
	else {
		//Stop the activity.
		[[BuddycloudAppDelegate sharedAppDelegate].spiralLoadingView stopActivity];
		
		if ([self.userNameTxtField.text isEmptyOrWhitespace]) {
			alertView = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(alertPrompt, @"")
													message:[NSString stringWithFormat:NSLocalizedString(wilcardCanNotBeEmpty, @""), NSLocalizedString(userName, @"")]
												   delegate:self
										  cancelButtonTitle:NSLocalizedString(okButtonLabel, @"") 
										  otherButtonTitles:nil] autorelease];
			[alertView show];
		}
		else if ([self.newPasswordTxtField.text isEmptyOrWhitespace]) {
			alertView = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(alertPrompt, @"")
													message:[NSString stringWithFormat:NSLocalizedString(wilcardCanNotBeEmpty, @""), NSLocalizedString(password, @"")]
												   delegate:self
										  cancelButtonTitle:NSLocalizedString(okButtonLabel, @"") 
										  otherButtonTitles:nil] autorelease];
			[alertView show];
			[alertView show];
		}
		
		NSLog(@"Something wrong with credentials...");
	}
}

- (void)cancel:(id)sender {
	[[TTNavigator navigator].visibleViewController dismissModalViewControllerAnimated:YES];
}

- (void)registeredWithSuccess:(NSNotification *)notification {
	
	XMPPStream *stream = (XMPPStream *)[notification object];
	
	@try {
		if (stream) {
			[[BuddycloudAppDelegate sharedAppDelegate].spiralLoadingView stopActivity];
			[[TTNavigator navigator] openURLAction:[TTURLAction actionWithURLPath:[NSString stringWithFormat:kexploreChannelsWithTitleAndUsernameURLPath,
																				   NSLocalizedString(buddycloud, @""), [stream.myJID full], self.newPasswordTxtField.text]]];	
		}
	}
	@catch (NSException * e) {
		NSLog(@"registeredWithSuccess .. %@", [e description]);
	}
}

- (void)registeredWithFailure:(NSNotification *)notification {
	[[BuddycloudAppDelegate sharedAppDelegate].spiralLoadingView stopActivity];
	
	NSNumber *errorCode = [notification object];
	NSLog(@"Errors....%d", errorCode);
	UIAlertView *alertView = nil;
	
	switch ([errorCode intValue]) {
		case kreg_badRequestError:
			NSLog(@"Username kreg_badRequestError....");
			break;
			
		case kreg_notAllowedError:
			NSLog(@"Username kreg_notAllowedError....");
			break;
			
		case kreg_infoMissingError:
			NSLog(@"Username kreg_infoMissingError....");
			break;
			
		case kreg_userNameConflictError:
			NSLog(@"Username kreg_userNameConflictError....");
			[self showErrorMsg:NSLocalizedString(userNameConflictError, @"")];

			alertView = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(alertPrompt, @"")
													message:NSLocalizedString(userNameConflictError, @"")
												   delegate:self 
										  cancelButtonTitle:NSLocalizedString(okButtonLabel, @"") 
										  otherButtonTitles:nil] autorelease];
			[alertView show];
			
			break;
			
		default:
			NSLog(@"unknown error....");
			break;
	}
}

- (UIViewController *)allowUserToExploreChannels:(NSString *)title withUserIno:(NSDictionary *)userInfo {
	
	NSLog(@"userinfo : %@", userInfo);
	
	UserAccountMsgViewController *acctMsgViewController = [[[UserAccountMsgViewController alloc] initWithTitle:title 
																								  withUserName:[userInfo valueForKey:@"username"]
																								  withPassword:[userInfo valueForKey:@"password"]] autorelease];
	
	return acctMsgViewController;
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark UITextFieldDelegate Delegates
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
	if (theTextField == self.userNameTxtField) {
		[self.newPasswordTxtField becomeFirstResponder];
	}
	else if (theTextField == self.newPasswordTxtField) {
		[self join:newPasswordTxtField];
		return YES;
	}
	
	return NO;
}

@end
