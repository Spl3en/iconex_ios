//
//  ImportTwoViewController.swift
//  ios-iCONex
//
//  Copyright © 2018 theloop, Inc. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import MobileCoreServices

class ImportTwoViewController: UIViewController {

    @IBOutlet weak var container1: UIScrollView!
    @IBOutlet weak var headerTitleLabel: UILabel!
    @IBOutlet weak var headerDescLabel: UILabel!
    @IBOutlet weak var selectButton: UIButton!
    @IBOutlet weak var fileErrorLabel: UILabel!
    @IBOutlet weak var fileInfoContainer: UIView!
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var inputBox: IXInputBox!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var inputConstraint: NSLayoutConstraint!
    @IBOutlet weak var container2: UIScrollView!
    @IBOutlet weak var headerTitleLabel2: UILabel!
    @IBOutlet weak var headerDescLabel2: UILabel!
    @IBOutlet weak var coinSelectLabel: UILabel!
    @IBOutlet weak var selectedCoinLabel: UILabel!
    @IBOutlet weak var keyTitleLabel: UILabel!
    @IBOutlet weak var inputBox2: IXInputBox!
    @IBOutlet weak var qrContainer: UIView!
    @IBOutlet weak var qrButton: UIButton!
    
    var validatedData: (Codable, COINTYPE)?
    
    private var typeList: [(name: String, type: COINTYPE)]!
    private var selectedIndex = 0
    
    private let disposeBag = DisposeBag()

    var mode: Int = 0 {
        willSet {
            if newValue == 0 {
                self.container1.isHidden = false
                self.container2.isHidden = true
            } else {
                self.container1.isHidden = true
                self.container2.isHidden = false
            }
        }
    }
    
    var delegate: ImportStepDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initialize()
        initializeUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func initialize() {
        self.typeList = [("ICON", .icx), ("Ethereum", .eth)]
        
        inputBox.textField.rx.controlEvent(UIControlEvents.editingDidBegin).subscribe(onNext: { [unowned self] in
            self.inputBox.setState(.normal, "")
        }).disposed(by: disposeBag)
        inputBox.textField.rx.controlEvent(UIControlEvents.editingDidEnd).subscribe(onNext: { [unowned self] in
            self.nextButton.isEnabled = self.validation()
        }).disposed(by: disposeBag)
        inputBox.textField.rx.controlEvent(UIControlEvents.editingDidEndOnExit).subscribe(onNext: { [unowned self] in
            self.nextButton.isEnabled = self.validation()
        }).disposed(by: disposeBag)
        
        inputBox2.textField.rx.controlEvent(UIControlEvents.editingDidBegin).subscribe(onNext: { [unowned self] in
            self.inputBox2.setState(.normal, "")
        }).disposed(by: disposeBag)
        inputBox2.textField.rx.controlEvent(UIControlEvents.editingDidEnd).subscribe(onNext: { [unowned self] in
            self.nextButton.isEnabled = self.validation()
        }).disposed(by: disposeBag)
        inputBox2.textField.rx.controlEvent(UIControlEvents.editingDidEndOnExit).subscribe(onNext: { [unowned self] in
            self.nextButton.isEnabled = self.validation()
        }).disposed(by: disposeBag)
        
        qrButton.rx.controlEvent(UIControlEvents.touchUpInside).subscribe(onNext: { [unowned self] in
            let type = self.typeList[self.selectedIndex].1
            
            let reader = UIStoryboard(name: "Side", bundle: nil).instantiateViewController(withIdentifier: "QRReaderView") as! QRReaderViewController
            reader.mode = .privateKey
            reader.type = type
            
            reader.handler = { (code) in
                self.view.endEditing(true)
                self.inputBox2.textField.text = code
                self.nextButton.isEnabled = self.validation()
            }
            
            self.present(reader, animated: true, completion: {
                
            })
        }).disposed(by: disposeBag)
        
        keyboardHeight().observeOn(MainScheduler.instance).subscribe(onNext: { [unowned self] (height: CGFloat) in
            let keyHeight = (height == 0 ? 0 : height - 72)
            UIView.animate(withDuration: 0.25, animations: {
                self.container1.contentInset = UIEdgeInsetsMake(0, 0, keyHeight, 0)
                self.container2.contentInset = UIEdgeInsetsMake(0, 0, keyHeight, 0)
            })
            
        }).disposed(by: disposeBag)
        
        container1.rx.didEndDragging.observeOn(MainScheduler.instance)
            .subscribe(onNext: { [unowned self] _ in
                self.inputBox.textField.resignFirstResponder()
            }).disposed(by: disposeBag)
        
        container2.rx.didEndDragging.observeOn(MainScheduler.instance)
            .subscribe(onNext: { [unowned self] _ in
                self.inputBox2.textField.resignFirstResponder()
            }).disposed(by: disposeBag)
    }
    
    func initializeUI() {
        headerTitleLabel.text = Localized(key: "Import.Step2.Header_1")
        headerDescLabel.text = Localized(key: "Import.Step2.Desc_1")
        
        inputBox.setState(.normal, nil)
        inputBox.setType(.password)
        inputBox.textField.placeholder = Localized(key: "Placeholder.InputWalletPassword")
        
        selectButton.styleDark()
        selectButton.cornered()
        selectButton.setTitle(Localized(key: "Import.Step2.SelectFile"), for: .normal)
        fileErrorLabel.isHidden = true
        fileErrorLabel.textColor = UIColor(242, 48, 48)
        
        fileInfoContainer.corner(4)
        fileInfoContainer.border(1, UIColor.lightTheme.background.normal)
        
        fileNameLabel.textColor = UIColor.lightTheme.background.normal
        
        nextButton.styleDark()
        nextButton.rounded()
        nextButton.setTitle(Localized(key: "Import.Step2.Button.Title"), for: .normal)
        nextButton.isEnabled = false
        
        inputConstraint.constant = 30
        fileInfoContainer.alpha = 0
        fileInfoContainer.isHidden = true
        
        headerTitleLabel2.text = "Import.Step2.Header_2_1".localized
        headerDescLabel2.text = "Import.Step2.Desc_2_1".localized
        coinSelectLabel.text = "Import.Step2.Header_2_2".localized
        keyTitleLabel.text = "Import.Step2.Desc_2_2".localized
        inputBox2.setType(.address)
        inputBox2.setState(.normal, nil)
        inputBox2.textField.placeholder = "Placeholder.PrivateKey".localized
        
        qrContainer.layer.cornerRadius = 4
        qrContainer.layer.masksToBounds = true
        qrContainer.backgroundColor = UIColor.black
        
        refreshItem()
    }
    
    func refreshItem() {
        self.mode = WCreator.importStyle
        
        let item = typeList[selectedIndex]
        
        self.selectedCoinLabel.text = item.name
        
        self.validatedData = nil
        animateItemLayer(show: false)
        fileErrorLabel.text = ""
        inputBox.setState(.normal, nil)
        inputBox2.setState(.normal, nil)
        nextButton.isEnabled = false
    }
    
    func validation() -> Bool {
        if mode == 0 {
            // Load from Keystore File
            guard let password = inputBox.textField.text, password != "" else {
                inputBox.setState(.error, "Error.Password".localized)
                return false
            }
            fileErrorLabel.text = ""
            fileErrorLabel.isHidden = true
            if let item = validatedData {
                // 일반 지갑 파일
                
                if item.1 == .icx {
                    let icxKeystore = item.0 as! ICON.Keystore
                    let icxWallet = ICXWallet(keystore: icxKeystore)
                    do {
                        let _ = try icxWallet.extractICXPrivateKey(password: password)
                        
                        WCreator.newWallet = icxWallet
                    } catch {
                        Log.Debug(error)
                        
                        inputBox.setState(.error, "Error.Password.Wrong".localized)
                        return false
                    }
                    
                    inputBox.setState(.normal, "")
                    self.view.endEditing(true)
                    return true
                } else if item.1 == .eth {
                    let ethKeystore = item.0 as! ETH.KeyStore
                    let ethWallet = ETHWallet(keystore: ethKeystore)
                    do {
                        let _ = try ethWallet.extractETHPrivateKey(password: password)
                        WCreator.newWallet = ethWallet
                    } catch {
                        Log.Debug(error)
                        
                        inputBox.setState(.error, "Error.Password.Wrong".localized)
                        return false
                    }
                    
                    inputBox.setState(.normal, "")
                    self.view.endEditing(true)
                    return true
                } else {
                    return false
                }
            } else if WCreator.newBundle != nil {
                // 지갑 번들 파일
                if !WCreator.validateBundlePassword(password: inputBox.textField.text!) {
                    inputBox.setState(.error, "Error.Password.Wrong".localized)
                    return false
                }
                
                inputBox.setState(.normal, "")
                self.view.endEditing(true)
                return true
            } else {
                self.inputBox.setState(.error, "Error.NoBackupFile".localized)
                return false
            }
        } else {
            // Load from Private Key
            guard let privKey = self.inputBox2.textField.text, privKey != "", privKey.hexToData() != nil, privKey.length == 64 else {
                self.inputBox2.setState(.error, "Error.PrivateKey".localized)
                return false
            }
            
            WCreator.newPrivateKey = privKey
            
            do {
                let type = typeList[selectedIndex].type
                if type == .icx {
                    let canSave = try WCreator.validateICXPrivateKey()
                    
                    if !canSave {
                        self.inputBox2.setState(.error, "Error.Wallet.Duplicated.Address".localized)
                        return false
                    }
                    
                    self.inputBox2.setState(.normal, "")
                    self.view.endEditing(true)
                    return true
                } else {
                    let canSave = try WCreator.validateETHPrivateKey()
                    
                    if !canSave {
                        self.inputBox2.setState(.error, "Error.Wallet.Duplicated.Address".localized)
                        return false
                    }
                    
                    self.inputBox2.setState(.normal, "")
                    self.view.endEditing(true)
                    return true
                }
            } catch {
                Log.Debug("\(error)")
                self.inputBox2.setState(.error, "Error.PrivateKey".localized)
                return false
            }
        }
    }
    
    // import from keystore file
    @objc func clickedImport(_ sender: UIButton) {
        
        if mode == 0 {
            // Keystore 파일
            if let item = validatedData {
                // 일반 지갑 파일
                if inputBox.textField.text!.length < 1 {
                    inputBox.setState(.error, "Error.Password".localized)
                    return
                }
                
                if item.1 == .icx {
                    let icxKeystore = item.0 as! ICON.Keystore
                    let icxWallet = ICXWallet(keystore: icxKeystore)
                    do {
                        let _ = try icxWallet.extractICXPrivateKey(password: inputBox.textField.text!)
                        
                        WCreator.newWallet = icxWallet
                        
                        inputBox.setState(.normal, nil)
                        inputBox.textField.resignFirstResponder()
                        nextButton.isEnabled = true
                    } catch {
                        Log.Debug(error)
                        
                        inputBox.setState(.error, "Error.Password".localized)
                        nextButton.isEnabled = false
                    }
                } else if item.1 == .eth {
                    let ethKeystore = item.0 as! ETH.KeyStore
                    let ethWallet = ETHWallet(keystore: ethKeystore)
                    do {
                        let _ = try ethWallet.extractETHPrivateKey(password: inputBox.textField.text!)
                        
                        WCreator.newWallet = ethWallet
                        
                        inputBox.setState(.normal, nil)
                        inputBox.textField.resignFirstResponder()
                        nextButton.isEnabled = true
                    } catch {
                        Log.Debug(error)
                        
                        inputBox.setState(.error, "Error.Password".localized)
                        nextButton.isEnabled = false
                    }
                }
            } else if WCreator.newBundle != nil {
                // 지갑 번들 파일
                if inputBox.textField.text!.length < 1 {
                    inputBox.setState(.error, "Error.Password".localized)
                    return
                }
                
                if !WCreator.validateBundlePassword(password: inputBox.textField.text!) {
                    inputBox.setState(.error, "Error.Password".localized)
                    return
                }

                inputBox.setState(.normal, nil)
                inputBox.textField.resignFirstResponder()
                nextButton.isEnabled = true
            }
        } else {
            // 개인키
            let code = inputBox2.textField.text!
            if code.hexToData() != nil && code.length == 64 {
                WCreator.newPrivateKey = code
                
                do {
                    let type = typeList[selectedIndex].type
                    if type == .icx {
                        let canSave = try WCreator.validateICXPrivateKey()
                        
                        if canSave {
                            
                            nextButton.isEnabled = true
                            inputBox2.textField.resignFirstResponder()
                            
                            return
                        } else {
                            nextButton.isEnabled = false
                            Alert.Basic(message: "Error.Wallet.Duplicated.Address".localized).show(self)
                        }
                    } else {
                        let canSave = try WCreator.validateETHPrivateKey()
                        
                        if canSave {
                            
                            nextButton.isEnabled = true
                            inputBox2.textField.resignFirstResponder()
                            
                            return
                        } else {
                            nextButton.isEnabled = false
                            Alert.Basic(message: "Error.Wallet.Duplicated.Address".localized).show(self)
                        }
                    }
                } catch {
                    Log.Debug("\(error)")
                    nextButton.isEnabled = false
                    Alert.Basic(message: "Error.PrivateKey".localized).show(self)
                }
                
                
            } else {
                nextButton.isEnabled = false
                self.inputBox2.setState(.error, "Error.PrivateKey".localized)
            }
        }
        
        
    }
    
    @IBAction func clickedSelect(_ sender: Any) {
        refreshItem()
        let document = UIDocumentPickerViewController(documentTypes: ["public.text", "public.data", String(kUTTypePlainText), String(kUTTypeItem)], in: UIDocumentPickerMode.import)
        document.delegate = self
        present(document, animated: true, completion: nil)
    }
    
    @IBAction func clickedDelete(_ sender: Any) {
        animateItemLayer(show: false)
        validatedData = nil
    }
    
    func animateItemLayer(show: Bool) {
        if show {
            fileInfoContainer.isHidden = false
            self.inputConstraint.constant = 106
            UIView.animate(withDuration: 0.25, animations: {
                self.fileInfoContainer.alpha = 1.0
                self.view.layoutIfNeeded()
            })
        } else {
            self.inputConstraint.constant = 30
            UIView.animate(withDuration: 0.25, animations: {
                self.fileInfoContainer.alpha = 0.0
                self.view.layoutIfNeeded()
            }) { (isCompleted) in
                self.fileInfoContainer.isHidden = true
                self.fileNameLabel.text = nil
            }
        }
    }
    
    // import from privatekey
    @IBAction func clickedTypeSelect(_ sender: Any) {
        let selectable = UIStoryboard(name: "ActionControls", bundle: nil).instantiateViewController(withIdentifier: "SelectableActionController") as! SelectableActionController
        selectable.present(from: self, title: "Create.Wallet.Step1.StepTitle".localized, items: ["ICON (ICX)", "Ethereum(ETH)"])
        selectable.handler = ({ [unowned self] selectedIndex in
            self.selectedIndex = selectedIndex
            
            self.refreshItem()
        })
    }
    
    @IBAction func clickedNext(_ sender: Any) {
        if mode == 1 {
            WCreator.newType = self.typeList[self.selectedIndex].1
            if let delegate = self.delegate {
                delegate.next()
            }
        } else {
            if WCreator.newWallet != nil {
                WCreator.newType = self.typeList[self.selectedIndex].1
                if let delegate = self.delegate {
                    delegate.next()
                }
            } else if WCreator.newBundle != nil {
                
                let bundleImport = UIStoryboard(name: "Loading", bundle: nil).instantiateViewController(withIdentifier: "BundleImportListView")
                self.present(bundleImport, animated: true, completion: nil)
            }
        }
        
    }
}

//extension ImportTwoViewController: SelectableActionDelegate {
//    func selectableAction(selectedIndex: Int) {
//        self.selectedIndex = selectedIndex
//
//        refreshItem()
//    }
//}

extension ImportTwoViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        Log.Debug(url.lastPathComponent)
        if WCreator.checkWalletBundle(url: url) {
            validatedData = nil
            
            self.fileNameLabel.text = url.lastPathComponent
            animateItemLayer(show: true)
        } else {
            do {
                let data: (Codable, COINTYPE) = try WCreator.validateKeystore(urlOfData: url)
                
                Log.Debug(data.0)
                validatedData = data
                
                self.fileNameLabel.text = url.lastPathComponent
                animateItemLayer(show: true)
            } catch (let error as IXError) {
                switch error {
                case .duplicateAddress:
                    fileErrorLabel.text = "Error.Wallet.Duplicated.Address".localized
                    fileErrorLabel.isHidden = false
                    
                default:
                    fileErrorLabel.text = "Error.Wallet.InvalidFile".localized
                    fileErrorLabel.isHidden = false
                }
                
            } catch {
                fileErrorLabel.text = "Error.Wallet.InvalidFile".localized
                fileErrorLabel.isHidden = false
                Log.Debug("\(error)")
            }
        }
    }
}
