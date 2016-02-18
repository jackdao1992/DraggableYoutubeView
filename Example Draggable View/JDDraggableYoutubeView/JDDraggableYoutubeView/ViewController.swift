//
//  ViewController.swift
//  JDDraggableYoutubeView
//
//  Created by Jack Dao on 2/17/16.
//  Copyright © 2016 Rubify. All rights reserved.
//

import UIKit
import MediaPlayer
import AVKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var draggableView: JDDraggableView?
    var draggableViewVideoView: JDDraggableView?
    
    var player = AVPlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        draggableView = JDDraggableView()
        
        let topView = UIView(frame: CGRectZero)
        topView.backgroundColor = UIColor.redColor()
        draggableView?.draggableView = topView
        
        let bottomView = UITableView(frame: CGRectZero)
        bottomView.dataSource = self
        bottomView.delegate = self
        draggableView?.contentView = bottomView
        
        draggableView?.miniWidth = self.view.frame.width / 2
        draggableView?.miniHeight = (self.view.frame.width / 2) * 100 / 160
        draggableView?.alphaForHidden = 0.2
        
        
        // create movie player
        draggableViewVideoView = JDDraggableView()
        
        do {
        try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        } catch {
            
        }
        let moviePath = NSBundle.mainBundle().pathForResource("demo_movie", ofType: "mov")
        player = AVPlayer(URL: NSURL(fileURLWithPath: moviePath!))
        let playerController = AVPlayerViewController()
        playerController.player = player
        playerController.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.addChildViewController(playerController)
//        player.play()
        draggableViewVideoView?.draggableView = playerController.view
        
        draggableViewVideoView?.contentView = bottomView
        
        draggableViewVideoView?.draggableRemoveFormSuperViewCallBack({ () -> () in
            self.player.pause()
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func testButtonTouched(sender: AnyObject) {
        draggableView?.showViewInViewController(self, animated: true)
//        draggableView?.showViewInWindowWithAnimated(true)
    }
    
    @IBAction func mpMovieControllerButtonTouched(sender: AnyObject) {
        draggableViewVideoView?.showViewInWindowWithAnimated(true)
        self.player.play()
    }
    
    // MARK: -- table view
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("cell")
        
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "cell")
        }
        
        cell?.textLabel?.text = "Row \(indexPath.row)"
        
        return cell!
    }
}

