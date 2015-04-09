
#import "ViewController.h"
#import <pop/POP.h>
#import <AsyncDisplayKit/AsyncDisplayKit.h>

@interface ViewController()<POPAnimationDelegate>{
    CGFloat _screenWidth;
    CGFloat _screenHeight;
    
    UIScrollView *_scroll;
    
    ASImageNode *_ball;
    ASImageNode *_field;
    
    BOOL _goCrazy;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _screenHeight = [UIScreen mainScreen].bounds.size.height;
    _screenWidth = [UIScreen mainScreen].bounds.size.width;
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    _scroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, _screenHeight/3.0, _screenWidth, _screenHeight * (2.0/3.0))];
    _scroll.contentSize = CGSizeMake(1000, 1000);
    _scroll.backgroundColor = [UIColor whiteColor];
    
    _scroll.scrollEnabled = YES;
    
    [self.view addSubview:_scroll];

    [self addSoccerField];
    
    [self generateRandomSquares];
    
    [self addCrazyButton];
}

- (void)addSoccerField;
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        _field = [[ASImageNode alloc] init];
        _field.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height/3);
        _field.image = [UIImage imageNamed:@"soccer-field"];
        _field.layerBacked = YES;
        
        _ball = [[ASImageNode alloc] init];
        _ball.frame = CGRectMake(10, 10, 30, 30);
        _ball.image = [UIImage imageNamed:@"soccer-ball"];
        
        _ball.userInteractionEnabled = YES;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.view.layer addSublayer:_field.layer];
            [self.view addSubview:_ball.view];
            
            UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPan:)];
            [_ball.view addGestureRecognizer:pan];
        });
    });
}


- (void)generateRandomSquares;
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{

        NSMutableArray *array = @[].mutableCopy;
        
        for (int i = 0; i < 1000; i++) {
            CGFloat randy = arc4random()%1000;
            CGFloat randx = arc4random()%1000;
            
            CGFloat width = arc4random()%200 + 50;
            CGFloat height = arc4random()%150 + 50;
            
            ASImageNode *node = [[ASImageNode alloc] init];
            node.frame = CGRectMake(randx, randy, width, height);
            node.contentMode = UIViewContentModeScaleAspectFill;
            node.image = [UIImage imageNamed:@"jony"];
            
            [array addObject:node];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            for (ASDisplayNode *node in array) {
                [_scroll addSubview:node.view];
            }
            if (_goCrazy) {
                [self performSelector:@selector(removeChildren) withObject:nil afterDelay:0.5];
            }
        });
    });
    

}

- (void)addCrazyButton;
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:@"Go crazy!" forState:UIControlStateNormal];
    button.layer.cornerRadius = 4;
    
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.layer.shadowColor = [UIColor lightGrayColor].CGColor;
    button.layer.shadowOpacity = 1.0;
    button.layer.shadowOffset = CGSizeMake(1, 1);
    [button setTitleShadowColor:[UIColor blackColor] forState:UIControlStateNormal];
    [button setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateSelected];
    button.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:24];
    UIColor *color = [UIColor colorWithRed:(52/255.f) green:(152/255.f) blue:(219/255.f) alpha:1.0];
    button.backgroundColor = color;
    
    button.bounds = CGRectMake(0, 0, _screenWidth - 8, 75);
    button.center = CGPointMake(_screenWidth/2.0, _screenHeight - (45));
    
    [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (void)buttonTapped:(UIButton *)button;
{
    if (_goCrazy == NO) {
        [button setTitle:@"Stop the Madness!" forState:UIControlStateNormal];
        _goCrazy = YES;
        [self generateRandomSquares];
    } else {
        [button setTitle:@"Go crazy!" forState:UIControlStateNormal];
        _goCrazy = NO;
    }
}

- (void)didPan:(UIPanGestureRecognizer *)pan;
{
    if (pan.state == UIGestureRecognizerStateBegan) {
        [_ball pop_removeAllAnimations];
    } else if (pan.state == UIGestureRecognizerStateChanged) {
        _ball.position = [pan locationInView:self.view];
    } else if (pan.state == UIGestureRecognizerStateEnded) {
        CGPoint velocity = [pan velocityInView:self.view];
        POPDecayAnimation *animation = [POPDecayAnimation animationWithPropertyNamed:kPOPLayerPosition];
        animation.fromValue = [NSValue valueWithCGPoint:_ball.position];
        animation.velocity = [NSValue valueWithCGPoint:velocity];
        animation.delegate = self;
        [_ball pop_addAnimation:animation forKey:nil];
    }
}

- (void)pop_animationDidReachToValue:(POPAnimation *)anim;
{
    if (_ball.position.x > _screenWidth || _ball.position.x < 0) {
        _ball.position = CGPointMake( 10, 10);
    }
}

- (void)pop_animationDidApply:(POPDecayAnimation *)anim;
{
    if (_ball.position.x < 0 || _ball.position.x > _screenWidth || _ball.position.y < 0 || _ball.position.y > _screenHeight/3.0) {
        CGPoint newVelocity;
        NSValue *velocityValue = anim.velocity;
        CGPoint velocity = [velocityValue CGPointValue];
        [_ball pop_removeAllAnimations];
        
        if (_ball.position.x < 0) {
            _ball.position = CGPointMake(0, _ball.position.y);
            newVelocity = (CGPoint){-velocity.x, velocity.y};
        } else if (_ball.position.x > _screenWidth) {
            _ball.position = CGPointMake(_screenWidth, _ball.position.y);
            newVelocity = (CGPoint){-velocity.x, velocity.y};
        }
        
        if (_ball.position.y < 0) {
            _ball.position = CGPointMake(_ball.position.x, 0);
            newVelocity = (CGPoint){velocity.x, -velocity.y};
            
        } else if (_ball.position.y > (_screenHeight/3.0)) {
            _ball.position = CGPointMake(_ball.position.x, _screenHeight/3.0);
            newVelocity = (CGPoint){velocity.x, -velocity.y};
        }
        
        POPDecayAnimation *newAnimation = [POPDecayAnimation animationWithPropertyNamed:kPOPLayerPosition];
        newAnimation.fromValue = [NSValue valueWithCGPoint:_ball.position];
        newAnimation.velocity = [NSValue valueWithCGPoint:newVelocity];
        newAnimation.delegate = self;
        
        [_ball pop_addAnimation:newAnimation forKey:nil];
    }
}

- (void)removeChildren;
{
    for (UIView *child in _scroll.subviews) {
        [child removeFromSuperview];
    }
    
    [self generateRandomSquares];
}

- (BOOL)prefersStatusBarHidden;
{
    return YES;
}

@end
