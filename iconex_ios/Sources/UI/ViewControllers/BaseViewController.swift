//
//  BaseViewController.swift
//  ios-iCONex
//
//  Copyright © 2018 theloop, Inc. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class BaseViewController: UIViewController {

    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        languageDidChanged().observeOn(MainScheduler.instance)
            .subscribe(onNext: { [unowned self] _ in
                self.languageChanged()
            }).disposed(by: disposeBag)
    }
    
    func languageChanged() {
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}
