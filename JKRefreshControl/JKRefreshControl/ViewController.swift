//
//  ViewController.swift
//  JKRefreshControl
//
//  Created by EnjoySR on 2016/10/10.
//  Copyright © 2016年 EnjoySR. All rights reserved.
//

import UIKit

class ViewController: UITableViewController {
    
    lazy var datas: [UIColor] = [UIColor]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupUI()
        self.initData()
    }
    
    private func setupUI() {
        self.tableView.separatorStyle = .none
        self.tableView.addSubview(refresh)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Clear", style: UIBarButtonItemStyle.plain, target: self, action: #selector(clean))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Refresh", style: UIBarButtonItemStyle.plain, target: refresh, action: #selector(JKRefreshControl.beginRefreshing))
    }
    
    
    @objc private func clean() {
        self.datas.removeAll()
        self.tableView.reloadData()
    }
    
    /// 模拟添加数据
    private func initData() {
        for _ in 0..<5 {
            let color = UIColor(red: CGFloat(arc4random() % 256) / 255, green: CGFloat(arc4random() % 256) / 255, blue: CGFloat(arc4random() % 256) / 255, alpha: 1)
            datas.append(color)
        }
    }
    
    /// 模拟加载数据
    @objc private func loadData() {
        
        DispatchQueue.global().async {
            
            for _ in 0..<3 {
                let color = UIColor(red: CGFloat(arc4random() % 256) / 255, green: CGFloat(arc4random() % 256) / 255, blue: CGFloat(arc4random() % 256) / 255, alpha: 1)
                self.datas.insert(color, at: 0)
            }
            
            Thread.sleep(forTimeInterval: 1)
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.refresh.endRefreshing()
            }
        }
    }
    
    // MARK: - 懒加载控件
    lazy var refresh: JKRefreshControl = {
        let refresh = JKRefreshControl()
        refresh.addTarget(self, action: #selector(loadData), for: .valueChanged)
        return refresh
    }()
}

extension ViewController {

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datas.count;
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.backgroundColor = datas[indexPath.row]
        cell.textLabel?.text = "\(datas.count - indexPath.row)"
        return cell
    }
}
