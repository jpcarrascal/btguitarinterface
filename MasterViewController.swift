//
//  MasterViewController.swift
//  BT Guitar Interface
//
//  Created by JP Carrascal on 05/03/16.
//  Copyright © 2016 Spacebarman. All rights reserved.
//

import Cocoa
import OSCKit
import IOBluetooth

////class MasterViewController: NSViewController {
class MasterViewController: NSViewController, NRFManagerDelegate {

    @IBOutlet weak var outputSelect: NSTabViewItem!
    @IBOutlet weak var scanProgress: NSProgressIndicator!
    @IBOutlet weak var scanText: NSTextField!
    @IBOutlet weak var BTConnectText: NSButton!
    @IBOutlet weak var BTIndicator: NSImageView!
    @IBOutlet weak var OSCActive: NSButton!
    @IBOutlet weak var MIDIActive: NSButton!
    @IBOutlet weak var OSCAddress: NSTextField!
    @IBOutlet weak var OSCPort: NSTextField!
    @IBOutlet weak var OSCAddrRibbon: NSTextField!
    @IBOutlet weak var OSCAddrKnob: NSTextField!
    @IBOutlet weak var OSCAddrAccel: NSTextField!
    @IBOutlet weak var MIDIDevice: NSComboBox!
    @IBOutlet weak var MIDIChannel: NSComboBox!
    @IBOutlet weak var MIDICCRibbon: NSTextField!
    @IBOutlet weak var MIDICCKnob: NSTextField!
    @IBOutlet weak var MIDICCAccX: NSTextField!
    @IBOutlet weak var MIDICCAccY: NSTextField!
    @IBOutlet weak var MIDICCAccZ: NSTextField!
    
    private let client = OSCClient()
//    private let server = OSCServer()
    private let message = OSCMessage()
    private var receivedMessages = [String]()
    private var serverAddress:String = ""
    private var serverPort:Int = 0
    private var prevValues = [Int]()
    private var deviceListNames = [String]()
    private var BTStatus = false;

    
    ////
    var nrfManager:NRFManager!
    var midiManager:MIDIManager!

    @IBAction func BTConnect(sender: AnyObject) {
        if self.BTStatus {
            self.nrfManager.disconnect()
        } else {
            self.scanProgress.startAnimation(nil)
            self.scanText.stringValue = "Searching for to " + nrfManager.RFDuinoName
            self.nrfManager.connect()
        }
    }
    
/*    @IBAction func about(sender: AnyObject) {
        if let checkURL = NSURL(string: "//www.spacebarman.com") {
            if NSWorkspace.sharedWorkspace().openURL(checkURL) {
                print("url successfully opened")
            }
        } else {
            print("invalid url")
        }
    }
*/  
    @IBAction func selectOutputProtocol(sender: AnyObject) {
        if OSCActive.intValue == 1 {
            nrfManager.dataCallback = {
                (data:NSData?, string:String?)->() in
                //print("Recieved data - String: \(string) - Data: \(data)")
                if let dataString = string {
                    let dataArray = dataString.characters.split{$0 == ","}.map(String.init)
                    for index in 0...(self.receivedMessages.count-1) {
                        if let value = Int(dataArray[index].stringByReplacingOccurrencesOfString("\0", withString: "")) {
                            if(value != self.prevValues[index]){
                                self.message.arguments = [value]
                                self.message.address = self.receivedMessages[index]
                                self.client.sendMessage(self.message, to: "udp://\(self.serverAddress):\(self.serverPort)")
                                //print("Sent \(self.OSCAddresses[index]), \(value)")
                                self.prevValues[index] = value
                            }
                        }
                    }
                }
            }
            print("Using OSC")
        } else if MIDIActive.intValue == 1 {
            nrfManager.dataCallback = {
                (data:NSData?, string:String?)->() in
                //print("Recieved data - String: \(string) - Data: \(data)")
                if let dataString = string {
                    let dataArray = dataString.characters.split{$0 == ","}.map(String.init)
                    for index in 0...(self.receivedMessages.count-1) {
                        if let value = Int(dataArray[index].stringByReplacingOccurrencesOfString("\0", withString: "")) {
                            if(value != self.prevValues[index]){
                                //print("Sending MIDI")
                                self.prevValues[index] = value
                            }
                        }
                    }
                }
            }
            print("Using MIDI")
        } else {
            nrfManager.dataCallback = nil
            print("Enjoy the silence...")
        }
    }
    
    @IBAction func refreshMIDIDevices(sender: AnyObject) {
        midiManager.getActiveMIDIDevices()
        print(midiManager.activeMIDIDeviceNames)
        print(midiManager.activeMIDIDevices)
        MIDIDevice.removeAllItems()
        MIDIDevice.addItemsWithObjectValues(midiManager.activeMIDIDeviceNames)
        MIDIDevice.selectItemAtIndex(0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        ////
        scanProgress.startAnimation(nil)
        
        serverAddress = OSCAddress.stringValue
        serverPort = OSCPort.integerValue
        receivedMessages.append(OSCAddrRibbon.stringValue)
        receivedMessages.append(OSCAddrKnob.stringValue)
        receivedMessages.append(OSCAddrAccel.stringValue)
        prevValues = [0,0,0]
        
        nrfManager = NRFManager(
            onConnect: {
                self.BTStatus = true
                print("Connected")
                self.BTConnectText.enabled = true
                self.BTConnectText.title = "Disconnect"
                self.nrfManager.autoConnect = true
                self.BTIndicator.image = NSImage(named: "NSStatusAvailable")
                self.scanProgress.stopAnimation(nil)
                self.scanText.stringValue = "Connected to " + self.nrfManager.RFDuinoName
            },
            onDisconnect: {
                self.BTStatus = false
                print("Disconnected")
                self.BTConnectText.title = "Connect"
                self.nrfManager.autoConnect = false
                self.BTIndicator.image = NSImage(named: "NSStatusPartiallyAvailable")
                self.scanText.stringValue = "RFDuino found (not connected)"
            },
            onData: nil,
            autoConnect: true
        )
        nrfManager.verbose = false;
        scanText.stringValue = "Searching for to " + nrfManager.RFDuinoName + "..."
        BTConnectText.title = "Connecting"
        BTConnectText.enabled = false
        print(OSCAddress.stringValue)
        print(OSCPort.stringValue)
        
        
        MIDIChannel.addItemsWithObjectValues([1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16])
        MIDIChannel.selectItemAtIndex(0)
        midiManager = MIDIManager()
        refreshMIDIDevices(0)
  /*
        
//        private var availableDevices = MIKMIDIDeviceManager.sharedDeviceManager().availableDevices
//        NSArray *availableMIDIDevices = [[MIKMIDIDeviceManager sharedDeviceManager] availableDevices];
        
        
        var date = NSDate().timeIntervalSince1970
//        var noteOn = MIKMIDINoteOnCommand(note: 60, velocity: 127, channel: 0, timestamp: date)
//        var noteOff = MIKMIDINoteOnCommand(note: 60, velocity: 127, channel: 0, timestamp: date)
        
        
        let msg = MIDIChannelMessage(status: 1, data1: 2, data2: 3, reserved: 0)
        let cc = MIKMIDIControlChangeCommand(forCommandType: MIKMIDICommandType)

        var dest = MIKMIDIDestinationEndpoint()
        var dm = MIKMIDIDeviceManager.sharedDeviceManager()
        dm.sendCommands([cc], toEndpoint: <#T##MIKMIDIDestinationEndpoint#>)
            sendCommands([cc], toEndpoint: dest)
        
//        [dm sendCommands:@[noteOn, noteOff] toEndpoint:destinationEndpoint error:&error];
*/
    }
    
    override func awakeFromNib() {

    }

}
