//
//  ViewController.swift
//  RSMultipeer
//
//  Created by Rajeev Sharma on 2015-03-31.
//  Copyright (c) 2015 Rajeev. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ViewController: UIViewController, RSMultipeerDelegate {
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var myPeerID: MCPeerID?
    override func viewDidLoad() {
        super.viewDidLoad()

        appDelegate.rsmultipeer.delegate = self
        appDelegate.rsmultipeer.advertiser.startAdvertisingPeer()
        appDelegate.rsmultipeer.browser.startBrowsingForPeers()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func multipeerNewPeerFound(peerID: MCPeerID, withName: String, andInfo: NSDictionary, atIndex: NSInteger) {
        println("Found peer in VC: \(peerID.displayName)")
        if((self.myPeerID) != nil) {
            self.myPeerID = nil
        }
        self.myPeerID = peerID
    }
    
    func multipeerPeerLost(peerID: MCPeerID, atIndex: NSInteger) {
        println("Lost peer: \(peerID.displayName)")
    }
    
    func multipeerDidRecieveInfo(info: NSDictionary, fromPeer: MCPeerID, withInvitationHandler: (accept: Bool, session: MCSession) -> ()) {
        println("Peer Recieved Info from peer: \(fromPeer.displayName)")
        
        var alertView: UIAlertView!
        var alertController: UIAlertController!
        if objc_getClass("UIAlertController") != nil {
            println("UIAlertController can be instantiated")
            //make and use a UIAlertController
            alertController = UIAlertController(title: "Connect!", message: "\(fromPeer.displayName) wants to connect with you.", preferredStyle: UIAlertControllerStyle.Alert)
            let acceptAction: UIAlertAction = UIAlertAction(title: "Accept", style: UIAlertActionStyle.Default) { (alertAction) -> Void in
                self.appDelegate.rsmultipeer.invitationHandler(true, self.appDelegate.rsmultipeer.session)
            }
            let declineAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (alertAction) -> Void in
                self.appDelegate.rsmultipeer.invitationHandler(false, nil)
            }
            alertController.addAction(acceptAction)
            alertController.addAction(declineAction)
            self.presentViewController(alertController, animated: true, completion: nil)
        } else {
            println("Using UIAlerView in iOS7")
            alertView = UIAlertView()
            alertView.title = "Connect!"
            alertView.delegate = self
            alertView.message = "\(fromPeer.displayName) wants to connect with you."
            alertView.addButtonWithTitle("Accept")
            alertView.addButtonWithTitle("Decline")
            alertView.show()
        }
    }
    
    func multipeerDidNotBroadcastWithError(error: NSError) {
            println("multipeerDidNotBroadcastWithError: \(error)")
    }
    
    func connectedWithPeer(peerID: MCPeerID) {
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            if objc_getClass("UIAlertController") != nil {
            let alertController = UIAlertController(title: "", message: "\(peerID.displayName) is connected!.", preferredStyle: UIAlertControllerStyle.Alert)
            let acceptAction: UIAlertAction = UIAlertAction(title: "Connected", style: UIAlertActionStyle.Default) { (alertAction) -> Void in
            }
            alertController.addAction(acceptAction)
            self.presentViewController(alertController, animated: true, completion: nil)
        } else {
                let alertView: UIAlertView = UIAlertView()
                alertView.title = "Connected!"
                alertView.message = "\(peerID.displayName) is now connected!"
                alertView.addButtonWithTitle("OK")
                alertView.show()
            }
        }
    }
    
    @IBAction func invitePeer(sender: AnyObject) {
        self.myPeerID = appDelegate.rsmultipeer.peers?.objectAtIndex(0) as? MCPeerID
        [appDelegate.rsmultipeer.browser.invitePeer(self.myPeerID, toSession: appDelegate.rsmultipeer.session, withContext: nil, timeout: 30.0)]
    }
    
    // AlertView Delegate
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if(buttonIndex == 0) {
            self.appDelegate.rsmultipeer.invitationHandler(true, self.appDelegate.rsmultipeer.session)
        }
    }
}

