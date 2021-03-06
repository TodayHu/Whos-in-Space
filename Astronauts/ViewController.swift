//
//  ViewController.swift
//  Astronauts
//
//  Created by Cameron Bernhardt on 7/15/14.
//  Copyright (c) 2014 Cameron Bernhardt. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    let height: CGFloat = UIScreen.mainScreen().bounds.size.height // Grab screen size
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Initial load
        self.loadData()
        
        let refresh: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Action, target: self, action: "share")
        refresh.tintColor = UIColor.whiteColor()
        
        let gear: UIBarButtonItem = UIBarButtonItem(image: UIImage(named: "Gear"), style: UIBarButtonItemStyle.Bordered, target: self, action: "openSettings")
        gear.tintColor = UIColor.whiteColor()
        
        let rightButtons: [UIBarButtonItem] = [refresh, gear]
        self.navigationItem.rightBarButtonItems = rightButtons
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getJSON(urlToRequest: String) -> NSData? {
        return NSData(contentsOfURL: NSURL(string: urlToRequest)!)
    }
    
    func parseJSON(inputData: NSData) -> NSDictionary? {
        var error: NSError?
        if let JSON: NSDictionary = NSJSONSerialization.JSONObjectWithData(inputData, options: NSJSONReadingOptions.MutableContainers, error: &error) as? NSDictionary {
            return JSON
        }
        
        return nil
    }
    
    @IBOutlet weak var numPeople: UILabel!
    @IBOutlet weak var descriptionText: UILabel!
    @IBOutlet weak var trailText: UILabel!
    var connected: Bool = false
    
    
    var urls: [String] = [] // Holds URLs for astronauts
    var ind: Int = 0 // Give each astronaut an ID to keep track
    var buttons: [UIButton] = []
    
    @IBAction func reload() {
        numPeople.hidden = true
        descriptionText.hidden = true
        
        for i in buttons { // Remove all of the buttons
            i.removeFromSuperview()
        }
        
        buttons = []
        
        ind = 0
        
        loadData()
    }
    
    func labelTapped(sender: UIButton!) { // Handles button clicks
        let urlIndex = sender.tag
        self.openUrl(urls[urlIndex])
    }
    
    func openUrl(url: String!) { // Opens URLs
        let targetURL = NSURL(string: url)!
        let application = UIApplication.sharedApplication()
        
        application.openURL(targetURL)
        
    }
    
    func loadData(){
        var dist: CGFloat = 0
        // Multipliers for constraint positioning later
        var constMultiplier: CGFloat = 1
        var topConst: CGFloat = 1.1
        
        // Fiddle with positioning based on device size; this is bad style, but I don't know a better way
        switch height {
        case 480: // 4s
            dist = 25
            constMultiplier = 1.03
            topConst = 1.05
        case 568: // 5/s
            dist = 30
            constMultiplier = 1.05
        case 667: // 6
            dist = 50
            constMultiplier = 1.08
        case 736: // 6 Plus
            dist = 70
            constMultiplier = 1.1
        default: // ??
            dist = 30
            constMultiplier = 1.05
        }
        
        if let request: NSData = getJSON("http://api.open-notify.org/astros.json") {
            self.connected = true
            let data: NSDictionary = parseJSON(request)!
            self.numPeople.hidden = false
            self.descriptionText.hidden = false
            self.trailText.hidden = false
            
            if let num: Int = data.valueForKey("number")?.integerValue {
                numPeople.text = "\(num)"
                
                // Save to defaults
                if let defaults: NSUserDefaults = NSUserDefaults(suiteName: "group.Astronauts") {
                    defaults.setInteger(num, forKey: "number")
                    defaults.synchronize()
                }
            }
            
            if let value: NSArray = data.valueForKey("people") as? NSArray {
                for person in value {
                    let name: String = person["name"] as! String // Name of astronaut
                    let craft: String = person["craft"] as! String // Location of astronaut
                    
                    var encodedURL = ""
                    
                    for j in name {
                        if j == " " {
                            encodedURL = encodedURL + "+"
                        } else {
                            encodedURL = encodedURL + (String(j))
                        }
                    }
                    
                    urls.append("http://google.com/search?q=" + encodedURL)
                    
                    // Create a button for each astronaut
                    let button = UIButton.buttonWithType(UIButtonType.System) as! UIButton
                    
                    button.tag = ind
                    button.titleLabel?.font = UIFont(name: "Arial", size: 17)
                    button.setTitleColor(UIColor.whiteColor(), forState:UIControlState.Normal)
                    button.setTitle("\(name): \(craft)", forState: UIControlState.Normal)
                    button.addTarget(self, action: "labelTapped:", forControlEvents: UIControlEvents.TouchUpInside)
                    
                    buttons.append(button)
                    
                    self.view.addSubview(button)
                    
                    // Positioning and constraints for buttons
                    button.setTranslatesAutoresizingMaskIntoConstraints(false)
                    
                    let constX = NSLayoutConstraint(item: button, attribute: .CenterX, relatedBy: .Equal, toItem: self.view, attribute: .CenterX, multiplier: 1, constant: 0)
                    self.view.addConstraint(constX)
                    
                    if ind == 0 {
                        let constY = NSLayoutConstraint(item: button, attribute: .Top, relatedBy: .Equal, toItem: self.trailText, attribute: .CenterY, multiplier: topConst, constant: 0)
                        self.view.addConstraint(constY)
                    } else {
                        let lastButton: UIButton = self.buttons[ind - 1]
                        let constY = NSLayoutConstraint(item: button, attribute: .Top, relatedBy: .Equal, toItem: lastButton, attribute: .CenterY, multiplier: constMultiplier, constant: 0)
                        self.view.addConstraint(constY)
                    }
                    
                    ind++
                }
            }
        } else { // No connection...or the API has been taken down, which would be bad (and possibly my fault)
            numPeople.hidden = true
            descriptionText.hidden = true
            trailText.hidden = true
            connected = false
            dispatch_async(dispatch_get_main_queue(), {
                self.alert("Data currently unavailable.", message: "Check your network connection.")
            })
            
        }
    }
    
    func alert(title: String, message: String) {
        if let gotModernAlert: AnyClass = NSClassFromString("UIAlertController") {
            let alert: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        } else {
            let alert: UIAlertView = UIAlertView()
            alert.delegate = self
            
            alert.title = title
            alert.message = message
            alert.addButtonWithTitle("OK")
            
            alert.show()
        }
    }
    
    
    // Sharing
    @IBAction func share() {
        if connected {
            if let number: String = numPeople.text {
                let message: String = "There are currently \(number) people in space!"
                
                if let myWebsite = NSURL(string: "http://tinyurl.com/whosinspace/") {
                    let objectsToShare: [AnyObject] = [message, myWebsite]
                    let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
                    
                    self.presentViewController(activityVC, animated: true, completion: nil)
                }
            }
        } else {
            self.alert("No connection.", message: "Why share what you don't have?")
        }
    }
    
    func openSettings() {
        self.performSegueWithIdentifier("openSettings", sender: self)
    }
}