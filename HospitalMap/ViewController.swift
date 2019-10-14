//
//  ViewController.swift
//  HospitalMap
//
//  Created by 차요셉 on 22/04/2019.
//  Copyright © 2019 차요셉. All rights reserved.
//

import UIKit
import Speech
class ViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
   
   
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var transcribeButton1: UIButton!
    @IBOutlet weak var stopButton1: UIButton!
    @IBOutlet weak var myTextView1: UITextView!
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "ko-KR"))!
    
    private var speechRecognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var speechRecognitionTask: SFSpeechRecognitionTask?
    
    private let audioEngine = AVAudioEngine()
    @IBAction func doneToPickerViewController(segue:UIStoryboardSegue) {
        
    }
    var pickerDataSource = ["광진구","구로구","동대문구","종로구"]
    
    var url : String = "http://apis.data.go.kr/B551182/hospInfoService/getHospBasisList?pageNo=1&numOfRows=10&serviceKey=sea100UMmw23Xycs33F1EQnumONR%2F9ElxBLzkilU9Yr1oT4TrCot8Y2p0jyuJP72x9rG9D8CN5yuEs6AS2sAiw%3D%3D&sidoCd=110000&sgguCd="
    
    var sgguCd : String = "110023" //디폴트 시구코드 = 광진구
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if row == 0 {
            sgguCd = "110023"
        } else if row == 1 {
            sgguCd = "110005"
        } else if row == 2 {
            sgguCd = "110007"
        } else {
            sgguCd = "110016"
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerDataSource.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerDataSource[row]
    }
    
  
    
    
    
    @IBAction func startTranscribing1(_ sender: Any) {
        transcribeButton1.isEnabled = false
        stopButton1.isEnabled = true
        try! startSession()
    }
    
    @IBAction func stopTranscribing1(_ sender: Any) {
        if audioEngine.isRunning {
            audioEngine.stop()
            speechRecognitionRequest?.endAudio()
            transcribeButton1.isEnabled = true
            stopButton1.isEnabled = false
        }
        
        switch (self.myTextView1.text) {
        case "광진구" :
            self.pickerView.selectRow(0, inComponent: 0, animated: true)
            break
        case "구로구" :
            self.pickerView.selectRow(1, inComponent: 0, animated: true)
            break
        case "동대문구" :
            self.pickerView.selectRow(2, inComponent: 0, animated: true)
            break
        case "종로구" :
            self.pickerView.selectRow(3, inComponent: 0, animated: true)
            break
        default:
            break
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        authorizeSR()
        self.pickerView.delegate = self
        self.pickerView.dataSource = self
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToTableView" {
            if let navController = segue.destination as? UINavigationController {   // 네비게이션 뷰가 있으면 꼭 navcontroller 선언후 navcontroller의                                                                      // 제일 처음뷰 즉 navController.topViewcontroller
                if let hospitalTableViewController = navController.topViewController as? HospitalTableViewController {
                    hospitalTableViewController.url = url + sgguCd
                }
            }
        }
    }
    
    
    func authorizeSR() {
        SFSpeechRecognizer.requestAuthorization{
            authStaus in OperationQueue.main.addOperation {
                switch authStaus {
                case .authorized:
                    self.transcribeButton1.isEnabled = true
                    
                case .denied:
                    self.transcribeButton1.isEnabled = false
                    self.transcribeButton1.setTitle("Speech recognition access denied by user", for: .disabled)
                case .restricted:
                    self.transcribeButton1.isEnabled = false
                    self.transcribeButton1.setTitle("Speech recognition restricted on device", for: .disabled)
                case .notDetermined:
                    self.transcribeButton1.isEnabled = false
                    self.transcribeButton1.setTitle("Speech recognition not authorized", for: .disabled)
                }
            }
        }
    }
    
    func startSession() throws {
        if let recognitionTask = speechRecognitionTask {
            recognitionTask.cancel()
            self.speechRecognitionTask = nil
        }
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(AVAudioSession.Category.record)
        
        speechRecognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = speechRecognitionRequest else {
            fatalError("SFSpeechAudioBufferRecognitionRequest object creation failed")
        }
        
        let inputNode = audioEngine.inputNode
        recognitionRequest.shouldReportPartialResults = true
        
        speechRecognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) {
            result, error in
            
            var finished = false
            if let result = result {
                self.myTextView1.text = result.bestTranscription.formattedString
                finished = result.isFinal
            }
            
            if error != nil || finished {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.speechRecognitionRequest = nil
                self.speechRecognitionTask = nil
                self.transcribeButton1.isEnabled = true
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            
            self.speechRecognitionRequest?.append(buffer)
        }
        audioEngine.prepare()
        try audioEngine.start()
    }
}

