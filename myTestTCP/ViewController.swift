//
//  ViewController.swift
//  myStory
//
//  Created by zhouhua on 2019/12/15.
//  Copyright © 2019 zhouhua. All rights reserved.
//参考 https://blog.csdn.net/u011146511/article/details/79447641
// 参考https://www.freecodecamp.org/news/ultimate-how-to-bluetooth-swift-with-hardware-in-20-minutes/
//参考 https://github.com/BradyBrenot/huestacean/issues/62
//https://developer.apple.com/library/archive/qa/qa1740/_index.html
//参考 https://developer.apple.com/library/archive/samplecode/OpenGLScreenCapture/Introduction/Intro.html

//参考 如何放到右上角状态栏 https://medium.com/@hoishing/menu-bar-apps-f2d270150660

import Cocoa
import CoreBluetooth
import SwiftUI
import Foundation // for tcp


extension Date {

    /// 获取当前 秒级 时间戳 - 10位
    var timeStamp : String {
        let timeInterval: TimeInterval = self.timeIntervalSince1970
        let timeStamp = Int(timeInterval)
        return "\(timeStamp)"
    }

    /// 获取当前 毫秒级 时间戳 - 13位
    var milliStamp : String {
        let timeInterval: TimeInterval = self.timeIntervalSince1970
        let millisecond = CLongLong(round(timeInterval*1000))
        return "\(millisecond)"
    }
}
let activeDisplays = UnsafeMutablePointer<CGDirectDisplayID>.allocate(capacity: 1)
func screen2ColorData() -> Data{
    var rgb:Data = Data.init(count: 4)
    let myrect:CGRect = CGRect(x: 200,y: 500,width: 20,height: 20)
    let screenShot:CGImage = CGDisplayCreateImage(activeDisplays[Int(0)],rect: myrect)!
    let dp: UnsafePointer<UInt8> = CFDataGetBytePtr(screenShot.dataProvider?.data)
    print("hello\(dp[0]) \(dp[1]) \(dp[2])")
    rgb[0] = 0xFE
    rgb[1] = dp[2]
    rgb[2] = dp[1]
    rgb[3] = dp[0]
    return rgb
}
func TakeScreensShots(folderName: String){

    var displayCount: UInt32 = 0;
    var result = CGGetActiveDisplayList(0, nil, &displayCount)
    if (result != CGError.success) {
        print("error: \(result)")
        return
    }
    let allocated = Int(displayCount)
    let activeDisplays = UnsafeMutablePointer<CGDirectDisplayID>.allocate(capacity: allocated)
    result = CGGetActiveDisplayList(displayCount, activeDisplays, &displayCount)

    if (result != CGError.success) {
        print("error: \(result)")
        return
    }

    for i in 1...displayCount {
        let unixTimestamp = CreateTimeStamp()
        let fileUrl = URL(fileURLWithPath: folderName + "\(unixTimestamp)" + "_" + "\(i)" + ".jpg", isDirectory: true)
        print(CreateTimeStamp())
        let screenShot:CGImage = CGDisplayCreateImage(activeDisplays[Int(i-1)])!
        //let screenShotRect:CGImage = CGDisplayCreateImageForRect(activeDisplays[Int(i-1)], <#CGRect#>)
        //it;s more efficient
        print(CreateTimeStamp())
        
        //print(screenShot.dataProvider?.data)
        let dp: UnsafePointer<UInt8> = CFDataGetBytePtr(screenShot.dataProvider?.data)
        
        print(dp[0],dp[1],dp[2],dp[3],dp[4],dp[5],dp[6])
        
        let bitmapRep = NSBitmapImageRep(cgImage: screenShot)
        print((bitmapRep))
        let jpegData = bitmapRep.representation(using: NSBitmapImageRep.FileType.jpeg, properties: [:])!


        do {
            try jpegData.write(to: fileUrl, options: .atomic)
        }
        catch {print("error: \(error)")}
        print(CreateTimeStamp())
    }
}

func CreateTimeStamp() -> Int32
{
    return Int32(Date().timeIntervalSince1970)
}
func getNowTimeStampMillisecond() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.dateFormat = "YYYY-MM-dd HH:mm:ss SSS"//设置时间格式；hh——>12小时制， HH———>24小时制
        //设置时区
        let timeZone = TimeZone.init(identifier: "Asia/Shanghai")
        formatter.timeZone = timeZone
        let dateNow = Date()//当前时间
        let timeStamp = String.init(format: "%ld", Int(dateNow.timeIntervalSince1970) * 1000)
        return timeStamp
}

class ViewController: NSViewController, CBPeripheralDelegate, CBCentralManagerDelegate {
    func centralManagerDidUpdateState( _ central: CBCentralManager) {
        print("Central state update")
        if central.state == .poweredOn {
            print("Central powered on,let's scan")
            centralManager?.scanForPeripherals(withServices: nil, options:nil)
        } else {
            print("other statu update,never mind")
        }
    }
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if #available(OSX 10.13, *) {
            print("found device",peripheral.identifier)
            print(getNowTimeStampMillisecond())
        } else {
            // Fallback on earlier versions
            print("found device",peripheral.name)
        };
        if peripheral.name == "tHID"{
            if #available(OSX 10.13, *) {
                print("found ",peripheral.name," uuid=",peripheral.identifier)
            } else {
                // Fallback on earlier versions
                print("found ",peripheral.name," uuid=",peripheral.name)
            }
            self.centralManager.stopScan()
            self.peripheral = peripheral
            self.peripheral.delegate = self
            self.centralManager.connect(self.peripheral, options: nil)
            print("connecting")
        }
    }
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral){
        if peripheral == self.peripheral {
            print("Connected,lets discover services!")
            peripheral.discoverServices(nil)
        }
    }
    let service_uuid_ihoment = CBUUID.init(string:"11111111-1111-1111-1111-111111111100")
    let character_uuid_ihoment = CBUUID.init(string:"11111111-1111-1111-1111-111111111111")
    

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                //print(service.uuid)
                if service.uuid == service_uuid_ihoment {
                    print("ihoment zhouhua service found")
                    peripheral.discoverCharacteristics([character_uuid_ihoment], for: service)
                    return
                }
            }
        }
    }
    var myChar:CBCharacteristic?
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid == character_uuid_ihoment {
                    print("ihoment zhouhua characteristic found")
                    myChar = characteristic
                    /*if characteristic.properties.contains(.write) && peripheral != nil {
                        print("lets write")
                        var mm:String = "abcdef9999999999999988887878788888000jjjj";
                        var dd:NSData = mm.data(using: String.Encoding.utf8,allowLossyConversion: true) as! NSData
                        peripheral.writeValue(dd as Data, for: characteristic, type: .withResponse)
                        
                        //self.centralManager.cancelPeripheralConnection(peripheral)
                    }*/
                }
            }
        }
    }
    func mmm(withCharacteristic characteristic: CBCharacteristic,myVal:Data){
        if characteristic.properties.contains(.write) && peripheral != nil{
            //var mm:String = "abcdef9999999999999988887878788888000jjjj";
            //var dd:NSData = mm.data(using: String.Encoding.utf8,allowLossyConversion: true) as! NSData
            peripheral.writeValue(myVal as Data,  for:characteristic, type: .withResponse)
        }
    }
    
    
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral!
    override func viewDidLoad() {
        super.viewDidLoad()
        //TakeScreensShots(folderName: "/Users/zhouhua/Downloads/");
        // Do any additional setup after loading the view.
        centralManager = CBCentralManager(delegate: self, queue: nil)
        //centralManager?.scanForPeripherals(withServices: nil, options: nil)
        print("start scan")
        /*
        Thread.detachNewThread {
            print("start server")
            startServer(12346);
        }
        Thread.detachNewThread {
            print("start send")
            //let server = TCPServer(address: "127.0.0.1", port: 8080)
            //server.listen()
                
             while (true){
                var ss = UnsafeMutablePointer<Int8>.allocate(capacity: 200)
                var ant:Int32 = recvStuck(ss, 20)
                var b:Data = Data(bytes:ss,count: 20)
                print(getNowTimeStampMillisecond())
                /*for i in 0...19{
                    print(ss[i])
                    b[i] = UInt8(ss[i])
                }*/
                //b.withUnsafeMutableBytes({ (bytes: UnsafeMutablePointer<Int8>) -> Void in ss})
                
                if ant == 20 && self.myChar != nil{
                    self.mmm(withCharacteristic: self.myChar!,myVal: b)
                }else{
                    //print("hello")
                    usleep(100000)
                }
            }
        }*/
        Thread.detachNewThread {
             while (true){
                var b = screen2ColorData()
                print(getNowTimeStampMillisecond())
                if b != nil && self.myChar != nil{
                    self.mmm(withCharacteristic: self.myChar!,myVal: b)
                    usleep(100000)
                }else{
                    //print("hello")
                    usleep(100000)
                }
            }
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    

}

