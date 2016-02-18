//
//  JDDraggableView.swift
//  JDDraggableYoutubeView
//
//  Created by Jack Dao on 2/17/16.
//  Copyright © 2016 Rubify. All rights reserved.
//

import UIKit

@objc enum JDDraggableState: Int {
    case Mini, Full
}

@objc protocol JDDraggableViewDelegate {
    optional func draggableViewRemoveFromSuperView(sender: JDDraggableView)
    optional func draggableView(sender: JDDraggableView, changeState: JDDraggableState)
}

class JDDraggableView: UIView {

    var draggableView: UIView?
    var contentView: UIView?
    var parentViewController: UIViewController?
    
    // max width = screen size width, max hieght calculater to width
    var miniWidth:CGFloat = 160
    var miniHeight:CGFloat = 100
    var alphaForHidden: CGFloat = 0.4
    let padding: CGFloat = 8
    
    var draggableState = JDDraggableState.Full
    var isAnimationRemove = false
    var isAnimationDraggable = false
    
    var oldPoint = CGPointZero
//    var changeMiniSizeButton: UIButton? = nil
    
    weak var delegate: JDDraggableViewDelegate?
    private var draggableRemoveFormSuperViewCallBack: (() -> ())?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addPanGestureToDraggableView() {
        let panGesture = UIPanGestureRecognizer(target: self, action: "panGestureRecognizer:")
        self.draggableView!.addGestureRecognizer(panGesture)

        let tapGesture = UITapGestureRecognizer(target: self, action: "tapGestureRecognizer:")
        self.draggableView?.addGestureRecognizer(tapGesture)
    }

    func tapGestureRecognizer(tapGesture: UITapGestureRecognizer) {
        if draggableState == .Mini {
            changeToFullFrame()
        }
    }
    
    func panGestureRecognizer(panGesture: UIPanGestureRecognizer) {

        if (panGesture.state == .Began) {
            self.oldPoint = panGesture.locationInView(self)
            return
        }
        
        let panX: CGFloat = panGesture.locationInView(self).x
        let panY: CGFloat = panGesture.locationInView(self).y
//        print("x: \(panX) - \(panY)")
        var frame = self.frame
        let mainScreen = self.frame
        frame.origin.y += panY - self.oldPoint.y
        if (frame.origin.y > mainScreen.size.height - self.miniHeight) {
            frame.origin.y = mainScreen.size.height - self.miniHeight
        }
        
        var xUpdate: CGFloat = (mainScreen.size.width - self.miniWidth) * frame.origin.y / (mainScreen.size.height - self.miniHeight)
        frame.origin.x = xUpdate
        if (xUpdate > mainScreen.size.width - self.miniWidth) {
            xUpdate = mainScreen.size.width - self.miniWidth
            frame.origin.x = xUpdate
        }
        
        if frame.origin.y < 0 {
            frame.origin.y = 0
            frame.origin.x = 0
        }
        
        frame.size.height = mainScreen.size.height - frame.origin.y
        frame.size.width = mainScreen.size.width - frame.origin.x
        
        
        if (panGesture.state == UIGestureRecognizerState.Ended) {
            if (self.isAnimationRemove && draggableState == .Mini) {
                // remove mini layer
                //            NSLog(@"%f", panX);
                let velocity: CGFloat = panGesture.locationInView(self).x
                //            NSLog(@"=====jack %f", velocity);
                let velocityMin: CGFloat = 700
                let xAnimationRemove: CGFloat = -self.miniWidth
                
                frame = self.frame
                frame.size.width = self.miniWidth
                frame.size.height = self.miniHeight
                if (velocity < 0) {
                    // scroll left
                    if (abs(velocity) > velocityMin) {
                        frame.origin.x = xAnimationRemove
                    } else {
                        if (frame.origin.x < (mainScreen.size.width - self.miniWidth)/2) {
                            frame.origin.x = xAnimationRemove
                        } else {
                            frame.origin.x = mainScreen.size.width - self.miniWidth
                        }
                    }
                } else {
                    // scroll right
                    if (abs(velocity) > velocityMin) {
                        frame.origin.x = mainScreen.size.width - self.miniWidth
                    } else {
                        if (frame.origin.x < (mainScreen.size.width - self.miniWidth)/2) {
                            frame.origin.x = xAnimationRemove;
                        } else {
                            frame.origin.x = mainScreen.size.width - self.miniWidth
                        }
                    }
                }
                
                var frameVideo = self.draggableView!.frame
                frameVideo.origin.x = padding
                frameVideo.origin.y = padding
                frameVideo.size.width = frame.size.width - 2 * padding
                frameVideo.size.height = frameVideo.size.width * self.miniHeight / self.miniWidth
                
                UIView.animateWithDuration(0.33, animations: { () -> Void in
                    self.frame = CGRectMake(frame.origin.x, frame.origin.y, self.frame.width, self.frame.height)
                    self.draggableView!.frame = frameVideo;
                    
                    var frameContent = self.contentView?.frame
                    frameContent?.origin.y = frameVideo.height + 2 * self.padding
                    self.contentView?.frame = frameContent!
                    
                    self.alpha = (frame.origin.x == xAnimationRemove) ? 0 : 1
                    
                    }, completion: { (finish) -> Void in
                        if (frame.origin.x == xAnimationRemove) {
                            self.hiddenView(false)
                            self.destroyControl()
                        }
                })
                
            } else {
                // change mini and lager
                let velocity: CGFloat = panGesture.velocityInView(self).y
                let velocityMin: CGFloat = 1200;
                if (velocity > 0) {
                    // scroll down
                    if (abs(velocity) > velocityMin) {
                        frame = scrollDown()
                    } else {
                        if (frame.origin.y > (mainScreen.size.height - self.miniHeight)/2) {
                            frame = scrollDown()
                        } else {
                            frame = scrollUp()
                        }
                    }
                } else {
                    // scroll up
                    if (abs(velocity) > velocityMin) {
                        frame = scrollUp()
                    } else {
                        if (frame.origin.y > (mainScreen.size.height - self.miniHeight)/2) {
                            frame = scrollDown()
                        } else {
                            frame = scrollUp()
                        }
                    }
                }
                
                var frameVideo = self.draggableView!.frame;
                frameVideo.origin.x = padding
                frameVideo.origin.y = padding
                frameVideo.size.width = (mainScreen.size.width - frame.origin.x) - 2 * padding;
                frameVideo.size.height = frameVideo.size.width * self.miniHeight / self.miniWidth
                
                UIView .animateWithDuration(0.33, animations: { () -> Void in
//                    self.transform = CGAffineTransformMakeTranslation(frame.origin.x, frame.origin.y);
                    self.frame = CGRectMake(frame.origin.x, frame.origin.y, self.frame.width, self.frame.height)
                    self.draggableView!.frame = frameVideo;
                    
                    var frameContent = self.contentView?.frame
                    frameContent?.origin.y = frameVideo.height + 2 * self.padding
                    self.contentView?.frame = frameContent!
                    
                    if (self.draggableState == .Mini) {
//                        [self.contentView setBackgroundColor:[UIColor colorWithWhite:0.5 alpha:0]];
                        self.contentView?.alpha = 0
                    } else {
                        self.contentView?.alpha = 1
                    }
//                    self.currentLayer.frame = self.videoView.bounds;
                    
                    }, completion: { (finish) -> Void in
                        self.delegate?.draggableView?(self, changeState: self.draggableState)
                })
                
            }
            
            self.isAnimationRemove = false
            self.isAnimationDraggable = false
            
        } else {
            if (fabs(panX - self.oldPoint.x) > fabs(panY - self.oldPoint.y) && draggableState == .Mini) {
                // remove mini layer
                //            NSLog(@"%f", panX);
                if (!self.isAnimationDraggable) {
                    self.isAnimationRemove = true
                }
            } else {
                if (!self.isAnimationRemove) {
                    self.isAnimationDraggable = true
                }
            }
            if (self.isAnimationRemove) {
                var frame = self.frame;
                frame.origin.x += panX - self.oldPoint.x
                self.frame = CGRectMake(frame.origin.x, frame.origin.y, self.frame.width, self.frame.height)
                let alpha = frame.origin.x / (mainScreen.size.width - self.miniWidth) + alphaForHidden
                self.alpha = alpha
            }
            if (self.isAnimationDraggable) {
                var frameVideo = self.draggableView!.frame
                frameVideo.origin.x = padding
                frameVideo.origin.y = padding
                frameVideo.size.width = (mainScreen.size.width - frame.origin.x) - 2 * padding
                frameVideo.size.height = frameVideo.size.width * self.miniHeight / self.miniWidth
                self.draggableView!.frame = frameVideo
                
//                self.currentLayer.bounds = self.videoView.bounds;
                var frameContent = self.contentView?.frame
                frameContent?.origin.y = frameVideo.height + 2 * padding
                self.contentView?.frame = frameContent!
                
                self.frame = CGRectMake(frame.origin.x, frame.origin.y, self.frame.width, self.frame.height)
//                self.transform = CGAffineTransformMakeTranslation(frame.origin.x, frame.origin.y)
                
                let alpha = 1 - frame.origin.x / (mainScreen.size.width - self.miniWidth)
                self.contentView?.alpha = alpha
//                [self.contentView setBackgroundColor:[UIColor colorWithWhite:0.5 alpha:alpha]];
            }
        }
    }
    
    func scrollDown() -> CGRect {
        draggableState = .Mini
        
        let mainScreen = self.frame
        var frame = self.frame
        frame.origin.y = mainScreen.size.height - self.miniHeight
        frame.origin.x = mainScreen.size.width - self.miniWidth
        frame.size.width = self.miniWidth
        frame.size.height = self.miniHeight
        
        return frame;
    }
    
    func scrollUp() -> CGRect {
        draggableState = .Full

        let mainScreen = self.frame
        var frame = self.frame
        frame.origin.y = 0
        frame.origin.x = 0
        frame.size.height = mainScreen.size.height
        frame.size.width = mainScreen.size.width
        
        return frame
    }
    
    func changeToFullFrame() {
        var frame = self.frame
        let mainScreen = self.parentViewController?.view.frame
        
        frame.origin.y = 0
        frame.origin.x = 0
        frame.size.height = mainScreen!.size.height
        frame.size.width = mainScreen!.size.width
        
        var frameVideo = self.draggableView!.frame
        frameVideo.size.width = frame.size.width - 2 * padding
        frameVideo.size.height = frameVideo.size.width * self.miniHeight / self.miniWidth
        
        var frameContent = self.contentView?.frame
        frameContent?.origin.y = frameVideo.height + 2 * self.padding
        self.contentView?.frame = frameContent!
        
        UIView.animateWithDuration(0.33, animations: { () -> Void in
            var tempFrame = self.frame
            tempFrame.origin = frame.origin
            self.frame = tempFrame
            
            self.draggableView!.frame = frameVideo
            self.contentView?.frame = frameContent!
            
            if (self.draggableState == .Mini) {
                self.contentView?.alpha = 1
            } else {
                self.contentView?.alpha = 0
            }
            
            }, completion: { (finish) -> Void in
                self.draggableState = .Full
                self.delegate?.draggableView?(self, changeState: self.draggableState)
        })
    }
    
    func changeToMiniFrame() {
        let mainScreen = self.frame
        var frame = self.frame
        frame.origin.y = mainScreen.size.height - self.miniHeight
        frame.origin.x = mainScreen.size.width - self.miniWidth
        
        var frameVideo = self.draggableView!.frame;
        frameVideo.origin.x = padding
        frameVideo.origin.y = padding
        frameVideo.size.width = self.miniWidth - 2 * padding;
        frameVideo.size.height = frameVideo.size.width * self.miniHeight / self.miniWidth
        
        UIView.animateWithDuration(0.33, animations: { () -> Void in
            self.draggableView?.frame = frameVideo
            self.frame = frame
            self.contentView?.alpha = 0
            
            }, completion: { (finish) -> Void in
                self.draggableState = .Mini
                self.delegate?.draggableView?(self, changeState: self.draggableState)
                
        })
    }
    
    func draggableRemoveFormSuperViewCallBack(callBackBlock:() -> ()) {
        self.draggableRemoveFormSuperViewCallBack = callBackBlock;
    }
    
    func destroyControl() {
        self.draggableState = .Full
        self.isAnimationRemove = false;
        self.isAnimationDraggable = false;
        
        self.parentViewController = nil
        self.draggableView?.removeFromSuperview()
        self.contentView?.removeFromSuperview()
        
        self.draggableRemoveFormSuperViewCallBack?()
    }
    
    func hiddenView(animated: Bool) {
        if (animated) {
            UIView.animateWithDuration(0.33, animations: { () -> Void in
                var frame = self.frame
                frame.origin = CGPointZero
                self.frame = frame
                
                self.alpha = 0;
                
                }, completion: { (finish) -> Void in
                    var frame = self.frame
                    frame.origin = CGPointMake(self.bounds.width/2, self.bounds.height * 3/4)
                    self.frame = frame
                    
                    self.removeFromSuperview()
                    
            })
        } else {
            var frame = self.frame;
            frame.origin.x = 0;
            frame.origin.y = 0;
            self.frame = frame;
            self.removeFromSuperview()
        }
    }
    
    func addChildViewIfNeed() {
        let orientation = UIDevice.currentDevice().orientation
        if (self.draggableView != nil) {
            if orientation == UIDeviceOrientation.LandscapeLeft || orientation == UIDeviceOrientation.LandscapeRight {
                self.draggableView?.frame = self.frame
            } else {
                var frameDraggableView = self.draggableView?.frame
                frameDraggableView?.origin.x = padding
                frameDraggableView?.origin.y = padding
                frameDraggableView?.size.width = self.frame.width - 2 * padding
                frameDraggableView?.size.height = (frameDraggableView!.size.width * self.miniHeight) / self.miniWidth
                self.draggableView?.frame = frameDraggableView!
            }
            self.draggableView?.autoresizingMask = [.FlexibleTopMargin, .FlexibleLeftMargin, .FlexibleBottomMargin, .FlexibleRightMargin]
            self.addSubview(self.draggableView!)
            addPanGestureToDraggableView()
        } else {
            return
        }
        
        if (self.contentView != nil) {
            self.contentView?.frame = CGRectMake(0, (self.draggableView?.frame.height)! + 2 * padding, self.frame.width, self.frame.height - self.draggableView!.frame.height)
            self.contentView?.autoresizingMask = [.FlexibleTopMargin, .FlexibleLeftMargin, .FlexibleBottomMargin, .FlexibleRightMargin]
            self.contentView?.alpha = 1
            self.addSubview(self.contentView!)
        }
    }
    
    func showViewInWindowWithAnimated(animated: Bool) {
        if let appDelegate = UIApplication.sharedApplication().delegate {
            resetAllProperty()
            self.parentViewController = appDelegate.window!!.rootViewController
            self.frame = (self.parentViewController?.view.bounds)!
            self.autoresizingMask = [.FlexibleTopMargin, .FlexibleLeftMargin,.FlexibleBottomMargin, .FlexibleRightMargin]
            self.parentViewController?.view.addSubview(self)
            addChildViewIfNeed()
            
            if animated {
                self.alpha = 0;
                self.frame = CGRectMake(self.frame.width/2, self.frame.height/2, self.frame.width, self.frame.height)
                
                UIView.animateWithDuration(0.33, animations: { () -> Void in
                    self.frame = CGRectMake(0, 0, self.frame.width, self.frame.height)
                    self.alpha = 1;
                    }, completion: { (finish) -> Void in
             
                })
            }
        } else {
            print("Error: AppDelagete nil")
        }
    }
    
    func showViewInViewController(parent: ViewController?, animated: Bool) {
        if let parentCheck = parent {
            resetAllProperty()
            self.parentViewController = parentCheck
            self.frame = (self.parentViewController?.view.bounds)!
            self.autoresizingMask = [.FlexibleTopMargin, .FlexibleLeftMargin,.FlexibleBottomMargin, .FlexibleRightMargin]
            self.parentViewController?.view.addSubview(self)
            addChildViewIfNeed()
            
            if animated {
                self.alpha = 0;
                self.frame = CGRectMake(self.frame.width/2, self.frame.height/2, self.frame.width, self.frame.height)
                
                UIView.animateWithDuration(0.33, animations: { () -> Void in
                    self.frame = CGRectMake(0, 0, self.frame.width, self.frame.height)
                    self.alpha = 1;
                    }, completion: { (finish) -> Void in
                        
                })
            }
            
        } else {
            print("Error: parent View Controller can not nil")
        }
    }
    
    func resetAllProperty() {
        self.parentViewController = nil
        self.oldPoint = CGPointZero
        self.draggableState = .Full
        self.isAnimationDraggable = false
        self.isAnimationRemove = false
        self.removeFromSuperview()
    }
}
