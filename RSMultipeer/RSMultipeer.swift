//
//  RSMultipeer.swift
//  RSMultipeer
//
//  Created by Rajeev Sharma on 2015-03-31.
//  Copyright (c) 2015 Rajeev. All rights reserved.
//

import Foundation
import MultipeerConnectivity


@objc protocol RSMultipeerDelegate {

    /**
    *  Found new peer
    *  @param peer  MCPeerID
    *  @param name  Peer display name during the advertisement
    *  @param info  Info if any
    *  @param index Index for updating the UI
    */
    func multipeerNewPeerFound(peerID: MCPeerID, withName: String, andInfo: NSDictionary, atIndex: NSInteger)

    /**
    *  Lost a peer, remove from UI
    *  @param peer  MCPeerID
    *  @param index Index to remove
    */
    func multipeerPeerLost(peerID: MCPeerID, atIndex: NSInteger)

    /**
    *  @param info NSDictionary: invitation context
    *  @param peer MCPeerID
    */
    func multipeerDidRecieveInfo(info: NSDictionary, fromPeer: MCPeerID, withInvitationHandler: (accept: Bool, session: MCSession) -> ())
    /**
    *  Notifies Broadcasting/Advertising Error
    *  @param Error NSError
    */
    func multipeerDidNotBroadcastWithError(error: NSError)
    
    /**
    *  Called when the peer is connected
    *  @param peerID
    */
    func connectedWithPeer(peerID:MCPeerID)
    
}

class RSMultipeer: NSObject, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate, MCSessionDelegate {
    
    
    var advertiser: MCNearbyServiceAdvertiser!
    var browser: MCNearbyServiceBrowser!
    var localPeerID: MCPeerID!
    var session: MCSession!
    var serviceType: String?
    var peersForIdentifier: NSMutableDictionary?
    var peers: NSMutableArray?
    var delegate: RSMultipeerDelegate?
    var invitationHandler: ((Bool, MCSession!)->Void)!
    
    
    func startBroadcasting() {
        self.advertiser.startAdvertisingPeer()
        self.browser.startBrowsingForPeers()
    }
    
    func stopBroadcasting() {
        self.advertiser.stopAdvertisingPeer()
        self.browser.stopBrowsingForPeers()
        self.peers?.removeAllObjects()
    }

    // Browser Delegate Callbacks
    
    func browser(browser: MCNearbyServiceBrowser!, didNotStartBrowsingForPeers error: NSError!) {
        println("didNotStartBrowsingForPeers \(error)")
        if let x = delegate {
            x.multipeerDidNotBroadcastWithError(error)
        }
    }
    
    func browser(browser: MCNearbyServiceBrowser!, foundPeer peerID: MCPeerID!, withDiscoveryInfo info: [NSObject : AnyObject]!) {
        println("Found peer \(peerID) with info: \(info)")
        if((peersForIdentifier?.objectForKey(peerID.displayName)) != nil) {
            var existedPeerID: MCPeerID?
            existedPeerID = peersForIdentifier?.objectForKey(peerID.displayName) as? MCPeerID
            //let index: Int
            //index = findIndexOfAnObject(self.peers, object: existedPeerID)
            peers?.insertObject(peerID, atIndex: 0)
            peersForIdentifier?.setObject(peerID, forKey: peerID.displayName)
        } else {
            peers?.insertObject(peerID, atIndex:0)
            peersForIdentifier?.setObject(peerID, forKey: peerID.displayName)
            if let x = delegate {
                var infoDictionary = NSDictionary(object: peerID.displayName, forKey: "info")
                x.multipeerNewPeerFound(peerID, withName:peerID.displayName, andInfo:infoDictionary, atIndex: 0)
            }
        }
    }

    func browser(browser: MCNearbyServiceBrowser!, lostPeer peerID: MCPeerID!) {
        println("Lost Peer \(peerID)")
        if((peersForIdentifier?.objectForKey(peerID.displayName)) != nil) {
            var existedPeerID: MCPeerID? = peersForIdentifier?.objectForKey(peerID.displayName) as? MCPeerID
            if let index: Int = peers?.indexOfObject(existedPeerID!) {
                peers?.removeObjectAtIndex(index)
                peersForIdentifier?.removeObjectForKey(peerID.displayName)
                if let x = delegate {
                    x.multipeerPeerLost(peerID, atIndex: index)
                }
            }
        }
    }

    // Advertiser Delegate Callbacks
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser!, didReceiveInvitationFromPeer peerID: MCPeerID!, withContext context: NSData!, invitationHandler: ((Bool, MCSession!) -> Void)!) {
        println("Did receive invitation from peer \(peerID.displayName) with context: \(context)")
        if let x = delegate {
            var infoDictionary = NSDictionary(object: peerID.displayName, forKey: "info")
            self.invitationHandler = invitationHandler
            x.multipeerDidRecieveInfo(infoDictionary, fromPeer: peerID, withInvitationHandler: self.invitationHandler)
        }
    }
    
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser!, didNotStartAdvertisingPeer error: NSError!) {
        println("didNotStartAdvertisingPeer with Error: \(error)")
        if let x = delegate {
            x.multipeerDidNotBroadcastWithError(error)
        }

    }
    
    // Session Delegate
    
    func session(session: MCSession!, peer peerID: MCPeerID!, didChangeState state: MCSessionState) {
        switch state{
        case MCSessionState.Connected:
            println("Connected to session: \(session)")
            delegate?.connectedWithPeer(peerID)
        case MCSessionState.Connecting:
            println("Connecting to session: \(session)")
        default:
            println("Did not connect to session: \(session)")
        }
    }
    
    func session(session: MCSession!, didFinishReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, atURL localURL: NSURL!, withError error: NSError!) {
        
    }
    
    func session(session: MCSession!, didReceiveData data: NSData!, fromPeer peerID: MCPeerID!) {
        
    }
    
    func session(session: MCSession!, didReceiveStream stream: NSInputStream!, withName streamName: String!, fromPeer peerID: MCPeerID!) {
        
    }
    
    func session(session: MCSession!, didStartReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, withProgress progress: NSProgress!) {
        
    }
    
    func session(session: MCSession!, didReceiveCertificate certificate: [AnyObject]!, fromPeer peerID: MCPeerID!, certificateHandler: ((Bool) -> Void)!) {
        certificateHandler(true)
    }
    
     override init () {
        super.init()
        peers  = NSMutableArray()
        peersForIdentifier = NSMutableDictionary()
        localPeerID = MCPeerID(displayName: UIDevice.currentDevice().name)
        session = MCSession(peer: self.localPeerID)
        session.delegate = self
        advertiser = MCNearbyServiceAdvertiser(peer: self.localPeerID, discoveryInfo: nil, serviceType: "glmyt-p2p")
        advertiser.delegate = self
        browser = MCNearbyServiceBrowser(peer: self.localPeerID, serviceType: "glmyt-p2p")
        browser.delegate = self
       
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationWillEnterForeground:", name: UIApplicationWillEnterForegroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationDidEnterBackground:", name: UIApplicationDidEnterBackgroundNotification, object: nil)
    
    }
    
    func applicationWillEnterForeground(notification: NSNotification) {
        startBroadcasting()
    }
    
    func applicationDidEnterBackground(notification: NSNotification) {
        stopBroadcasting()
        
    }
    
    // Helper Methods
    
    func findIndexOfAnObject<T: Equatable>(array: Array<T>, object: T) -> Int? {
        var i: Int
        
        for i = 0; i < array.count; ++i {
            if (array[i] == object) {
                return i
            }
        }
        
        return nil
    }
    
}