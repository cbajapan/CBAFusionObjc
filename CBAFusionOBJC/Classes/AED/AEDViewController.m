#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_13
#import "AEDViewController.h"
@import FCSDKiOS;

API_AVAILABLE(ios(13))
@interface AEDViewController ()

@property ACBTopic *currentTopic;
@property NSMutableArray *topicList;

@end

@implementation AEDViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.topicList = [NSMutableArray arrayWithCapacity:30];
}

#pragma mark - Actions

- (IBAction)connectToTopic:(id)sender
{
    if (self.topicNameField.text.length == 0)
    {
        return;
    }
    
    int expiry = [self.expiryField.text intValue];
    self.currentTopic = [self.uc.aed createTopicWithName:self.topicNameField.text expiryTime:expiry delegate:self];
    
    [self.view endEditing:YES];
    self.topicNameField.text = @"";
    self.expiryField.text = @"";
}

- (IBAction)publishData:(id)sender
{
    if ((self.dataKeyField.text.length == 0) || (self.dataValueField.text.length == 0))
    {
        return;
    }
    
    if (self.currentTopic == nil)
    {
        [self warnNoConnectedTopic];
        return;
    }
    
    [self.currentTopic submitDataWithKey:self.dataKeyField.text value:self.dataValueField.text];
    
    [self.view endEditing:YES];
    self.dataKeyField.text = @"";
    self.dataValueField.text = @"";
}

- (IBAction)deleteData:(id)sender
{
    if (self.currentTopic == nil)
    {
        [self warnNoConnectedTopic];
        return;
    }
    
    [self.currentTopic deleteDataWithKey:self.dataKeyField.text];
    
    [self.view endEditing:YES];
    self.dataKeyField.text = @"";
    self.dataValueField.text = @"";
}

- (IBAction)sendMessage:(id)sender
{
    if (self.currentTopic == nil)
    {
        [self warnNoConnectedTopic];
        return;
    }
    
    [self.currentTopic sendAedMessage:self.messageField.text];
    
    [self.view endEditing:YES];
    self.messageField.text = @"";
}

//storyboard triggers this when "background" of forms are tapped, to dismiss the keyboard
- (IBAction)handleSingleTap:(UITapGestureRecognizer *) sender
{
    [self.view endEditing:YES];
}

#pragma mark - UITableView delegate / data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.topicList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"SimpleTableItem";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    if (@available(iOS 13, *)) {
        ACBTopic* rowTopic = [self.topicList objectAtIndex:indexPath.row];
        cell.textLabel.text = rowTopic.name;
        cell.accessoryType = (rowTopic == self.currentTopic) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    } else {
        // Fallback on earlier versions
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.topicListView cellForRowAtIndexPath:indexPath];
    self.currentTopic = [self.uc.aed createTopicWithName:cell.textLabel.text delegate:self];
    NSString *msg = [NSString stringWithFormat:@"Current topic is '%@'.", self.currentTopic.name];
    [self logMessage:msg];
    [tableView reloadData]; //to check the current topic
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (@available(iOS 13, *)) {
        ACBTopic* selectedTopic = [self.topicList objectAtIndex:indexPath.row];
        UIContextualAction *context1 = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:@"Delete" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            [self disconnectTopic:selectedTopic andDelete:YES];
        }];
        
        UIContextualAction *context2 = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:@"Disconnect" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            [self disconnectTopic:selectedTopic andDelete:NO];
        }];
        NSArray * actions = [NSArray arrayWithObjects:context1, context2, nil];
        UISwipeActionsConfiguration *swipeActions = [UISwipeActionsConfiguration configurationWithActions:actions];
        return swipeActions;
    } else {
        // Fallback on earlier versions
        return NULL;
    }
}

#pragma mark - Topic callbacks

- (void)topic:(ACBTopic *)topic didConnectWithData:(NSDictionary *)data
//this will tell us which topic we're connected to as well as give us
//all the topic data (up to the point where we get connected)
API_AVAILABLE(ios(13)){
    //Aquire all information about topic and it's data
    [self.topicList addObject:topic];
    [self.topicListView reloadData];
    self.currentTopic = topic;
    NSInteger topicExpiry = [[data objectForKey:@"timeout"] integerValue];
    
    //Print out successfull connection
    NSString* expiryClause = (topicExpiry > 0) ? [NSString stringWithFormat:@"expires in %ld mins", (long)topicExpiry] : @"no expiry";
    NSString *msg = [NSString stringWithFormat:@"Topic '%@' connected succesfully (%@).", self.currentTopic.name, expiryClause];
    [self logMessage:msg];
    msg = [NSString stringWithFormat:@"Current topic is '%@'. Topic Data:", self.currentTopic.name];
    [self logMessage:msg];
    
    // topic data is an array containing all our key/value pairs.
    NSArray *topicData = [data objectForKey:@"data"];
    if([topicData count] > 0)
    {
        //we can show our users the data in the topic as follows
        for(int i = 0; i < [topicData count] ; i++)
        {
            NSString *keyField = [[topicData objectAtIndex:i] valueForKey:@"key"];
            NSString *valueField = [[topicData objectAtIndex:i] valueForKey:@"value"];
            [self logMessage:[NSString stringWithFormat:@"Key:'%@' Value:'%@'",keyField,valueField]];
        }
    }
}

- (void)topicDidDelete:(ACBTopic *)topic
API_AVAILABLE(ios(13)){
    NSString *msg = [NSString stringWithFormat:@"Topic '%@' has been deleted.", topic.name];
    [self logMessage:msg];
    [self.topicList removeObject:topic];
    [self.topicListView reloadData];
}

- (void)topic:(ACBTopic *)topic didDeleteWithMessage:(NSString *)message
API_AVAILABLE(ios(13)){
    NSString *msg = [NSString stringWithFormat:@"%@ for topic '%@'.", message, topic.name];
    [self logMessage:msg];
}

- (void)topic:(ACBTopic * _Nonnull)topic didDeleteDataSuccessfullyWithKey:(NSString * _Nonnull)key version:(NSInteger)version  API_AVAILABLE(ios(13)){
    NSString *msg = [NSString stringWithFormat:@"Data with k: '%@' in topic '%@' deleted. Version: %li", key, topic.name, (long)version];
    [self logMessage:msg];
}

- (void)topic:(ACBTopic * _Nonnull)topic didSubmitWithKey:(NSString * _Nonnull)key value:(NSString * _Nonnull)value version:(NSInteger)version  API_AVAILABLE(ios(13)){
    NSString *msg = [NSString stringWithFormat:@"Data with k: '%@' v: '%@' in topic '%@' submitted. Version: %li", key, value, topic.name, (long)version];
    
    // this is where we can check to ensure that we don't already have a newer version of the
    // data for that key, just in case there's a race condition somewhere in the system.
    [self logMessage:msg];
}

- (void)topic:(ACBTopic *)topic didSendMessageSuccessfullyWithMessage:(NSString *)message
API_AVAILABLE(ios(13)){
    NSString *msg = [NSString stringWithFormat:@"Sent message - %@ for topic '%@'.", message, topic.name];
    [self logMessage:msg];
}

- (void)topic:(ACBTopic *)topic didNotConnectWithMessage:(NSString *)message
API_AVAILABLE(ios(13)){
    NSString *msg = [NSString stringWithFormat:@"Connect Failed - %@ for topic '%@'.", message, topic.name];
    [self logMessage:msg];
}

- (void)topic:(ACBTopic *)topic didNotDeleteWithMessage:(NSString *)message
API_AVAILABLE(ios(13)){
    NSString *msg = [NSString stringWithFormat:@"Delete Failed - %@ for topic '%@'.", message, topic.name];
    [self logMessage:msg];
}

- (void)topic:(ACBTopic *)topic didNotSubmitWithKey:(NSString *)key value:(NSString *)value message:(NSString *)message
API_AVAILABLE(ios(13)){
    NSString *msg = [NSString stringWithFormat:@"Publish Data Failed - %@ for topic '%@'.", message, topic.name];
    [self logMessage:msg];
}

- (void)topic:(ACBTopic *)topic didNotDeleteDataWithKey:(NSString *)key message:(NSString *)message
API_AVAILABLE(ios(13)){
    NSString *msg = [NSString stringWithFormat:@"Delete Data Failed - %@ for topic '%@'.", message, topic.name];
    [self logMessage:msg];
}

- (void)topic:(ACBTopic *)topic didNotSendMessage:(NSString *)originalMessage message:(NSString *)message
API_AVAILABLE(ios(13)){
    NSString *msg = [NSString stringWithFormat:@"Send Message Failed - %@ for topic '%@'.", message, topic.name];
    [self logMessage:msg];
}

//Event Notifications
- (void)topic:(ACBTopic * _Nonnull)topic didUpdateWithKey:(NSString * _Nonnull)key value:(NSString * _Nonnull)value version:(NSInteger)version deleted:(BOOL)deleted  API_AVAILABLE(ios(13)){
    NSString *msg = [NSString stringWithFormat:@"Topic '%@' updated, k: '%@', v: '%@'. Version: %li", topic.name, key, value, (long)version];
    [self logMessage:msg];
}

- (void)topic:(ACBTopic *)topic didReceiveMessage:(NSString *)message
API_AVAILABLE(ios(13)){
    NSString *msg = [NSString stringWithFormat:@"Received Message - \"%@\" for topic '%@'.", message, topic.name];
    [self logMessage:msg];
}


#pragma mark - utility methods

- (void)disconnectTopic:(ACBTopic*)disconnectedTopic andDelete:(BOOL)deleteTopic
API_AVAILABLE(ios(13)){
    if (self.currentTopic == disconnectedTopic)
    {
        self.currentTopic = nil;
    }
    
    if (disconnectedTopic.connected)
    {
        [disconnectedTopic disconnectWithDeleteFlag:deleteTopic];
        
        [self.topicList removeObject:disconnectedTopic];
        [self.topicListView reloadData];
        NSString *msg = [NSString stringWithFormat:@"Topic '%@' disconnected.", disconnectedTopic.name];
        [self logMessage:msg];
    }
    else
    {
        NSString *msg = [NSString stringWithFormat:@"Topic '%@' already disconnected.", self.currentTopic.name];
        [self logMessage:msg];
    }
    
    if ((self.currentTopic == nil) && (self.topicList.count > 0))
    {
        self.currentTopic = self.topicList.firstObject;
        [self.topicListView reloadData];
    }
}

- (void) logMessage: (NSString*) msg
{
    if (msg.length > 0)
    {
        self.logTextView.text = [NSString stringWithFormat:@"%@%@\n", self.logTextView.text, msg];
        
        //auto-scroll to bottom (the lines to disable and re-enable scrolling are a workaround for
        //an iOS bug, without these the view doesn't auto-scroll)
        NSRange range = NSMakeRange(self.logTextView.text.length, 0);
        [self.logTextView scrollRangeToVisible:range];
        [self.logTextView setScrollEnabled:NO];
        [self.logTextView setScrollEnabled:YES];
    }
}

- (void) warnNoConnectedTopic
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"No Topic" message:@"Please connect to a topic first." preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}


@end
#endif
