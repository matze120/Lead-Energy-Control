//
//  LeadDynamicController.swift
//  LeadDynamic
//
//  Created by Marcel Fornacon on 06.06.21.
//

import Foundation
import Network

class LeadController
{
    private var hostTCP: NWEndpoint.Host = ""  //send to broadcast address
    private let portTCP: NWEndpoint.Port = 8899
    
    private var Prefix: String = "\u{55}\u{99}\u{80}\u{a4}"
    private var Postfix: String = "\u{aa}\u{aa}\u{aa}\u{aa}"
    private var PostPrefix: String = "\u{02}\u{00}"
    private var Command: String = ""
    private var Value: UInt8 = 0
    private var Brightness: UInt8 = 0
    private var ColorTemp: UInt8 = 0
    private var OnOffState: Bool = false
    private var CheckSum: UInt8 = 0
    private var CompleteCommand: String = ""
    
    private var connection: NWConnection?
    
    init()
    {
    }
    
    public func Setup(IP: String)
    {
        //let ipTools = IPTools()
        self.hostTCP = NWEndpoint.Host(IP)
        
        self.connection = NWConnection(host: hostTCP, port: portTCP, using: .tcp)
        self.connection?.stateUpdateHandler = { (newState) in
            print("This is stateUpdateHandler:")
            switch (newState) {
                case .ready:
                    print("State: Ready\n")
                    //self.sendUDP(messageToUDP)
                    //self.receiveUDP()
                case .setup:
                    print("State: Setup\n")
                case .cancelled:
                    print("State: Cancelled\n")
                case .preparing:
                    print("State: Preparing\n")
                default:
                    print("ERROR! State not defined!\n")
            }
        }

        self.connection?.start(queue: .global())
    }
    
    private func sendTCP(_ content: String)
    {
        let contentToSendUDP = content.data(using: String.Encoding.isoLatin1)
        self.connection?.send(content: contentToSendUDP, completion: NWConnection.SendCompletion.contentProcessed(({ (NWError) in
            if (NWError == nil) {
                print("String was sent to UDP")
            } else {
                print("ERROR! Error when data (Type: Data) sending. NWError: \n \(NWError!)")
            }
        })))
    }
    
    // Switches the Lamp On or Off
    // Attention:
    // It's not possible to switch on the Lamp if it's switch off with the Dimm command.
    // ON = true
    // OFF = false
    public func OnOff(OnOff: Bool)
    {   // ON = 0xAB OFF = 0xA9
        if(OnOff)
        {
            self.OnOffState = true;
            self.Command = "\u{02}\u{12}";
            self.Value = 0xAB;
        }else
        {
            self.OnOffState = false;
            self.Command = "\u{02}\u{12}";
            self.Value = 0xA9;
        }
        SendCommand();
    }
    
    // Dimms the Lamp in 64 steps
    // it's possible to switch off the lamp with this command. Value 0
    public func Brightness(Brightness: UInt8)
    {
        self.Command = "\u{08}\u{33}"
        self.Brightness = Brightness;
        self.Value = UInt8(Brightness / 4);
        SendCommand();
    }
    
    // Set's the Color temp of the lamp in 32 Steps
    // 0x00 is cold
    // 0xff is warm
    public func ColorTemp(ColorTemp: UInt8)
    {
        self.Command = "\u{08}\u{36}";
        self.ColorTemp = ColorTemp;
        self.Value = UInt8(ColorTemp / 8);
        SendCommand();
    }
    
    // Calculates the Checksum for the prebuilded command.
    // PostPrefix + Command + value & 0xff = Checksum
    private func CalculateChecksum()
    {
        let WW: UInt8 = Array(String(self.PostPrefix).utf8)[0];
        let ww: UInt8 = Array(String(self.PostPrefix).utf8)[1];
        
        let XX: UInt8 = Array(String(self.Command).utf8)[0];
        let xx: UInt8 = Array(String(self.Command).utf8)[1];
        let YY = self.Value;
        
        self.CheckSum = WW + ww + XX + xx + YY & 0xff;
    }
    
    private func SendCommand()
    {
        self.CalculateChecksum();

        let ValueStr = String(UnicodeScalar(self.Value));
        let ChkSumStr = String(UnicodeScalar(self.CheckSum));
        
        let CommandString = self.Prefix + self.PostPrefix + self.Command + ValueStr + ChkSumStr + self.Postfix;

        print(String(format: "%2X \n", CommandString))

        self.sendTCP(CommandString);
    }
}
