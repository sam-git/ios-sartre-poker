//
//  GameViewController.m
//  PokerBasic
//
//  Created by Samuel Michael Russell Grace on 24/01/13.
//
//

#import "GameViewController.h"
#import "State.h"

@interface GameViewController ()
@property (weak, nonatomic) IBOutlet UITextView *infoTextView;
@property (weak, nonatomic) IBOutlet UIButton *logoutButton;

@property (weak, nonatomic) IBOutlet UILabel *nameOnServerLabel;
@property (weak, nonatomic) IBOutlet UILabel *dealerLabel;
@property (weak, nonatomic) IBOutlet UILabel *gameStageLabel;

@property (weak, nonatomic) IBOutlet UILabel *botStackLabel;
@property (weak, nonatomic) IBOutlet UILabel *botBetAmountLabel;

@property (weak, nonatomic) IBOutlet UILabel *potLabel;
@property (weak, nonatomic) IBOutlet UILabel *commCardsLabel;

@property (weak, nonatomic) IBOutlet UILabel *playerBetAmountLabel;
@property (weak, nonatomic) IBOutlet UILabel *playerHoleCardsLabel;
@property (weak, nonatomic) IBOutlet UILabel *playerStackLabel;

@property (weak, nonatomic) IBOutlet UIButton *checkCallButton;
@property (weak, nonatomic) IBOutlet UIButton *betRaiseButton;
@property (weak, nonatomic) IBOutlet UIButton *foldButton;

- (IBAction)actionButtonPress:(id)sender;

@property State *currentState;
@property State *prevState;

@end

@implementation GameViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.infoTextView.editable = false;
    
    NSString *logoutButtonText = [NSString stringWithFormat:@"Logout %@", self.loginNameText];
    //self.logoutButton.titleLabel = logoutButtonText;
    [self.logoutButton setTitle:logoutButtonText forState:UIControlStateNormal];
    
    self.infoTextView.text = [self.client description];
    //[self.client showState];
    
    
    [self.client loadState:^(NSDictionary *JSON) {

        self.currentState = [[State alloc]initWithAttributes:JSON];
        [self newGame];
        
    }failure:^{
        NSLog(@"Failure in loadState block from gamecontroller");
    }];
    
    //NSLog(self.currentState.player.name, @"HERE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
    NSLog(@"HERE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setLabels {
    
    State *state = self.currentState;
    self.nameOnServerLabel.text = state.player.name;
    
    //self.dealerLabel.text = dealer.name;
    self.dealerLabel.text = state.game.dealer;
    
    self.gameStageLabel.text = state.game.gameStage;
    //self.commCardsLabel.text = @"XX XX XX | XX | XX";
    
    NSString *newString = [[[state.game.communityCards description] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@" "];
    self.commCardsLabel.text = newString;
    
    //pay blinds
    self.botBetAmountLabel.text = [NSString stringWithFormat:@"%d", state.bot.currentStageContribution];
    self.playerBetAmountLabel.text = [NSString stringWithFormat:@"%d", state.player.currentStageContribution];
    
    //pay blinds - update stacks
    self.botStackLabel.text = [NSString stringWithFormat:@"%d", state.bot.stack];
    self.playerStackLabel.text = [NSString stringWithFormat:@"%d", state.player.stack];
    
    //pay blinds - update pot
    self.potLabel.text = [NSString stringWithFormat:@"%d", state.game.pot];
    
    //deal cards
    //self.playerHoleCardsLabel.text = [state.player.holeCards objectAtIndex:0];
    self.playerHoleCardsLabel.text = [state.player.holeCards description];
}

-(void)displayMoves {
//    NSString *availableMoves = [NSString stringWithFormat:@"Fold, %@", [state.player.validMoves description]];
//    [self setInfoText:availableMoves];
    State *state = self.currentState;
    [self.checkCallButton setTitle:[state.player.validMoves objectAtIndex:0] forState:UIControlStateNormal];
    [self.betRaiseButton setTitle:[state.player.validMoves objectAtIndex:1] forState:UIControlStateNormal];
    
    self.betRaiseButton.enabled = true;
    self.checkCallButton.enabled = true;
    self.foldButton.enabled = true;
}

- (void)newGame {
    
    self.prevState = nil;
    State *state = self.currentState;
    [self setLabels];
    
    //set dealer
    Player *dealer;
    Player *bigBlind;
    Boolean botIsDealer;
    if ([state.game.dealer isEqualToString:_BOT]) {
        dealer = state.bot;
        bigBlind = state.player;
        botIsDealer = true;
    } else {
        dealer = state.player;
        bigBlind = state.bot;
        botIsDealer = false;
    }
    NSString *dealerString = [NSString stringWithFormat:@"Dealer is %@", dealer.name];
    [self setInfoText:dealerString];
    
    //pay blinds
    NSString *anteString = [NSString stringWithFormat:@"%@ pays small blind of 1\n%@ pays big blind of 2.", dealer.name, bigBlind.name];
    [self setInfoText:anteString];
    
    //If Satre goes first:
    if (botIsDealer) {
        if ([[state.bot.lastAction objectAtIndex:0] isEqualToString:_RAISE] ) {
            NSString *actionString = [NSString stringWithFormat:@"%@ %@s to %@", state.bot.name, [state.bot.lastAction objectAtIndex:0], [state.bot.lastAction objectAtIndex:1]];
            [self setInfoText:actionString];
        }
    }
    [self displayMoves];

}

- (void)setInfoText:(NSString *)text {
    NSString *one = self.infoTextView.text;
    NSString *new = [NSString stringWithFormat:@"%@\n%@", one, text];
    self.infoTextView.text = new;
    [self.infoTextView scrollRangeToVisible:NSMakeRange(new.length, 0)];
    //[TextView scrollRangeToVisible:NSMakeRange([TextView.text length], 0)];
   
}

- (IBAction)actionButtonPress:(id)sender {
    
    self.betRaiseButton.enabled = false;
    self.checkCallButton.enabled = false;
    self.foldButton.enabled = false;
    
    if (![sender isKindOfClass:[UIButton class]])
        return;
    NSString *move = [sender currentTitle];
    
    [self setInfoText:[NSString stringWithFormat:@"%@ %@s", self.currentState.player.name, move]];
    
    self.prevState = self.currentState;
    [self.client playerMove:move success:^(NSDictionary *JSON) {
        
        self.currentState = [[State alloc]initWithAttributes:JSON];
        [self playerActed];
        
    }failure:^{
        NSLog(@"Failure in loadState block from gamecontroller");
    }];
    NSLog(@"End of actionButtonPress");
}

-(void) playerActed {
    //Game has ended
    if (self.currentState.game.gameHasEnded) {
        [self setInfoText:self.currentState.game.gameStage];
        [self startNewHand];
        return;
    }
    
    [self setLabels];
    [self displayMoves];
    
    if ([self.currentState.game.gameStage isEqualToString:self.prevState.game.gameStage]) {
        //Bot checked
        if (self.currentState.bot.currentStageContribution == self.prevState.bot.currentStageContribution) {
            [self setInfoText:@"Bot checks. This can't happen. If bot checks we have changed state"];
        }
        if (self.currentState.bot.currentStageContribution > self.prevState.bot.currentStageContribution) {
            [self setInfoText:@"Bot raises."];
        }
    }
}

-(void) startNewHand {
    [self.client newGame:^(NSDictionary *JSON) {
        
        self.currentState = [[State alloc]initWithAttributes:JSON];
        [self newGame];
        
    }failure:^{
        NSLog(@"Failure in loadState block from gamecontroller");
    }];
}
    
@end
