//
//  CreateLockViewController.swift
//  ios-iCONex
//
//  Copyright © 2018 theloop, Inc. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class CreateLockViewController: UIViewController {
    enum CreateLockMode {
        case create
        case change
        case remove
        case recreate
    }
    
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var navTitle: UILabel!
    @IBOutlet weak var lockHeader: UILabel!
    @IBOutlet weak var secureContainer: UIView!
    @IBOutlet weak var numpadContainer: UIView!
    
    var mode: CreateLockMode?
    
    private let disposeBag = DisposeBag()
    private var __passcode: String = ""
    private var __firstCode: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initialize()
        initializeUI()
    }
    
    func initialize() {
        closeButton.rx.controlEvent(UIControlEvents.touchUpInside)
            .subscribe(onNext: { [unowned self] in
                if self.mode == .recreate {
                    self.navigationController?.dismiss(animated: true, completion: nil)
                } else {
                    self.navigationController?.popViewController(animated: true)
                }
            }).disposed(by: disposeBag)
    }
    
    func initializeUI() {
        
        for view in self.numpadContainer.subviews {
            guard let button = view.subviews.first as? UIButton else {
                continue
            }
            let backImage = UIImage(color: UIColor(hex: 0x000000, alpha: 0.1))
            button.layer.masksToBounds = true
            button.layer.cornerRadius = button.layer.frame.size.height / 2
            button.setBackgroundImage(backImage, for: .highlighted)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 32)
            button.setTitleColor(UIColor.black, for: .normal)
            
            if button.tag == 11 {
                button.addTarget(self, action: #selector(clickedDelete(_:)), for: .touchUpInside)
            } else {
                button.addTarget(self, action: #selector(clickedNumber(_:)), for: .touchUpInside)
            }
        }
        
        let size = CGSize(width: 12, height: 12)
        
        for i in 0..<6 {
            let x = i * 16 + i * Int(size.width)
            
            let imageView = UIImageView(frame: CGRect(origin: CGPoint(x: x , y: 0), size: size))
            imageView.layer.masksToBounds = true
            imageView.layer.borderWidth = 2.0
            imageView.layer.borderColor = UIColor.black.cgColor
            imageView.layer.cornerRadius = size.height / 2
            
            let highlighted = UIImage(color: UIColor.black)
            let normal = UIImage(color: UIColor.clear)
            
            imageView.image = normal
            imageView.highlightedImage = highlighted
            
            self.secureContainer.addSubview(imageView)
        }
        
        guard let mode = self.mode else {
            return
        }
        
        switch mode {
        case .create, .recreate:
            navTitle.text = "LockScreen.Setting.Title".localized
            lockHeader.text = "LockScreen.Setting.Passcode.Header".localized
            
        case .change:
            navTitle.text = "LockScreen.Setting.ChangeCode.Title".localized
            lockHeader.text = "LockScreen.Setting.Passcode.Change.Current".localized
            
        case .remove:
            navTitle.text = "Passcode.Code.Enter".localized
            lockHeader.text = "LockScreen.Setting.Passcode.Change.Current".localized
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @objc func clickedNumber(_ sender: UIButton) {
        if __passcode.length < 6 {
            __passcode = __passcode + "\(sender.tag)"
            
            if __passcode.length == 6 {
                // 6 자리 입력 완료
                if mode! == .create || mode! == .recreate {
                    if let firstCode = __firstCode {
                        if firstCode == __passcode {
                            if Tools.createPasscode(code: firstCode) {
                                
                            }
                            if mode! == .recreate {
                                let app = UIApplication.shared.delegate as! AppDelegate
                                let root = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as? UINavigationController
                                app.window?.rootViewController = root
                                let main = root?.viewControllers[0] as! MainViewController
                                let lock = UIStoryboard(name: "Side", bundle: nil).instantiateViewController(withIdentifier: "LockSettingView")
                                let nav = UINavigationController(rootViewController: lock)
                                nav.isNavigationBarHidden = true
                                main.present(nav, animated: true, completion: nil)
                                self.navigationController?.dismiss(animated: false, completion: {
                                    
                                })
                                
                            } else {
                                self.navigationController?.popViewController(animated: true)
                            }
                        } else {
                            __passcode = ""
                            __firstCode = nil
                            lockHeader.text = "LockScreen.Setting.Passcode.Change.Error".localized
                        }
                    } else {
                        lockHeader.text = "LockScreen.Setting.Passcode.Header_2".localized
                        __firstCode = __passcode
                        __passcode = ""
                    }
                } else if mode! == .change {
                    if __firstCode == nil {
                        if Tools.verifyPasscode(code: __passcode) {
                            lockHeader.text = "LockScreen.Setting.Passcode.Change.New".localized
                            __passcode = ""
                            self.mode = .create
                        } else {
                            lockHeader.text = "LockScreen.Setting.Passcode.Header_Error".localized
                            __passcode = ""
                        }
                    }
                } else {
                    if Tools.verifyPasscode(code: __passcode) {
                        Tools.removePasscode()
                        Tools.removeTouchID()
                        self.navigationController?.popViewController(animated: true)
                    } else {
                        lockHeader.text = "LockScreen.Setting.Passcode.Header_Error".localized
                        __passcode = ""
                    }
                }
            }
        }
        
        self.refresh()
    }
    
    @objc func clickedDelete(_ sender: UIButton) {
        if __passcode.length > 0 {
            __passcode = String(__passcode.prefix(__passcode.length - 1))
        }
        self.refresh()
    }
    
    func refresh() {
        for i in 0..<6 {
            let imageView = self.secureContainer.subviews[i] as! UIImageView
            if i < __passcode.length {
                imageView.isHighlighted = true
            } else {
                imageView.isHighlighted = false
            }
        }
    }
}
