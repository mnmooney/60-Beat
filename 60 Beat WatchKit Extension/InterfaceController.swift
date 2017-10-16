//
//  InterfaceController.swift
//  60 Beat WatchKit Extension
//
//  Created by Michael Mooney on 21/12/2015.
//  Copyright © 2015 Michael Mooney. All rights reserved.
//
//

import WatchKit
import Foundation
import HealthKit


class InterfaceController: WKInterfaceController, HKWorkoutSessionDelegate {
    
    
    @IBOutlet private weak var Question: WKInterfaceLabel!
    @IBOutlet private weak var Answer1: WKInterfaceButton!
    @IBOutlet private weak var Answer2: WKInterfaceButton!
    @IBOutlet private weak var Group: WKInterfaceGroup!
    @IBOutlet private weak var QuestionImage: WKInterfaceImage!
    @IBOutlet private weak var Seperator: WKInterfaceSeparator!
    @IBOutlet private weak var PointsLabel: WKInterfaceLabel!
    @IBOutlet private weak var SepLabel: WKInterfaceLabel!
    
    @IBOutlet private weak var Replay: WKInterfaceButton!
    @IBOutlet private weak var FinalScoreLabel: WKInterfaceLabel!
    @IBOutlet private weak var FinalScore: WKInterfaceLabel!
    @IBOutlet private weak var FinalImage: WKInterfaceImage!
    
    @IBOutlet private weak var Logo: WKInterfaceImage!
    @IBOutlet private weak var HighestLabel: WKInterfaceLabel!
    @IBOutlet private weak var LowestLabel: WKInterfaceLabel!
    @IBOutlet private weak var Play: WKInterfaceButton!
    
    @IBOutlet private weak var CheatingLblOne: WKInterfaceLabel!
    @IBOutlet private weak var CheatingLblTwo: WKInterfaceLabel!
    
    var IsAnswerOneRight = false
    var IsAnswerTwoRight = false
    var Score = 0
    var IsDone = 0
    var HeartRate:UInt16 = 0
    var momentpScoreOne = 0, momentpScoreTwo = 0, momentpScoreThree = 0, momentpScoreFour = 0, momentpScoreFive = 0, momentpScoreSix = 0, momentpScoreSeven = 0
    var breaker = 0
    var prev = 0
    var percentScore = 0
    var alreadyOpen = 0
    
    let healthStore = HKHealthStore()
    
    let workoutSession = HKWorkoutSession(activityType: HKWorkoutActivityType.CrossTraining, locationType: HKWorkoutSessionLocationType.Indoor)
    let heartRateUnit = HKUnit(fromString: "count/min")
    var anchor = HKQueryAnchor(fromValue: Int(HKAnchoredObjectQueryNoAnchor))
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        workoutSession.delegate = self
        
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        

        if alreadyOpen == 0 {

            
            CheatingLblOne.setHidden(true)
            CheatingLblOne.setAlpha(0)
            
            CheatingLblTwo.setHidden(true)
            CheatingLblTwo.setAlpha(0)
            
            Question.setAlpha(0)
            Answer1.setAlpha(0)
            Answer2.setAlpha(0)
            Group.setAlpha(0)
            QuestionImage.setAlpha(0)
            Seperator.setAlpha(0)
            PointsLabel.setAlpha(0)
            SepLabel.setAlpha(0)
            
            Question.setHidden(true)
            Answer1.setHidden(true)
            Answer2.setHidden(true)
            Group.setHidden(true)
            QuestionImage.setHidden(true)
            Seperator.setHidden(true)
            PointsLabel.setHidden(true)
            SepLabel.setHidden(true)
            
            Replay.setHidden(true)
            FinalScoreLabel.setHidden(true)
            FinalScore.setHidden(true)
            FinalImage.setHidden(true)
            
            FinalScoreLabel.setAlpha(0)
            Replay.setAlpha(0)
            FinalScore.setAlpha(0)
            FinalImage.setAlpha(0)
            
            percentScore = 0
            self.HeartRate = 0
            
            Logo.setHidden(false)
            Play.setHidden(false)
            HighestLabel.setHidden(false)
            LowestLabel.setHidden(false)
        }
        
        
        guard HKHealthStore.isHealthDataAvailable() == true else {
            return
        }
        
        
        guard let quantityType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate) else {
            displayNotAllowed()
            return
        }
        
        let dataTypes = Set(arrayLiteral: quantityType)
        healthStore.requestAuthorizationToShareTypes(nil, readTypes: dataTypes) { (success, error) -> Void in
            if success == false {
                self.displayNotAllowed()
            }
        }
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        IsDone = 0
        healthStore.endWorkoutSession(workoutSession)
    }
    
    func displayNotAllowed() {
        
    }
    
    func workoutSession(workoutSession: HKWorkoutSession, didChangeToState toState: HKWorkoutSessionState, fromState: HKWorkoutSessionState, date: NSDate) {
        switch toState {
        case .Running:
            workoutDidStart(date)
        case .Ended:
            workoutDidEnd(date)
        default:
            print("Unexpected state \(toState)")
        }
    }
    
    func workoutSession(workoutSession: HKWorkoutSession, didFailWithError error: NSError) {
        
    }
    
    func workoutDidStart(date : NSDate) {
        if let query = createHeartRateStreamingQuery(date) {
            healthStore.executeQuery(query)
        } else {
            
        }
    }
    
    func workoutDidEnd(date : NSDate) {
        if let query = createHeartRateStreamingQuery(date) {
            healthStore.stopQuery(query)
        } else {
            
        }
    }
    
    func createHeartRateStreamingQuery(workoutStartDate: NSDate) -> HKQuery? {
        // adding predicate will not work
        // let predicate = HKQuery.predicateForSamplesWithStartDate(workoutStartDate, endDate: nil, options: HKQueryOptions.None)
        
        guard let quantityType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate) else { return nil }
        
        let heartRateQuery = HKAnchoredObjectQuery(type: quantityType, predicate: nil, anchor: anchor, limit: Int(HKObjectQueryNoLimit)) { (query, sampleObjects, deletedObjects, newAnchor, error) -> Void in
            guard let newAnchor = newAnchor else {return}
            self.anchor = newAnchor
            self.updateHeartRate(sampleObjects)
        }
        
        heartRateQuery.updateHandler = {(query, samples, deleteObjects, newAnchor, error) -> Void in
            self.anchor = newAnchor!
            self.updateHeartRate(samples)
        }
        return heartRateQuery
    }
    
    func updateHeartRate(samples: [HKSample]?) {
        guard let heartRateSamples = samples as? [HKQuantitySample] else {return}
        
        dispatch_async(dispatch_get_main_queue()) {
            guard let sample = heartRateSamples.first else{return}
            let value = sample.quantity.doubleValueForUnit(self.heartRateUnit)
            let OtherVale = (UInt16(value))
            
            self.breaker += 1
            
            if self.breaker == 1 {
                self.momentpScoreOne = self.percentScore
                
                if self.momentpScoreOne > 20 {
                    self.Cheating()
                }
            } else if self.breaker == 2 {
                self.momentpScoreTwo = self.percentScore - self.momentpScoreOne
                
                if self.momentpScoreTwo > 20 {
                    self.Cheating()
                }
            } else if self.breaker == 3 {
                self.momentpScoreThree = self.percentScore - (self.momentpScoreOne + self.momentpScoreTwo)
                
                if self.momentpScoreThree > 20 {
                    self.Cheating()
                }
            } else if self.breaker == 4 {
                self.momentpScoreFour = self.percentScore - (self.momentpScoreOne + self.momentpScoreTwo + self.momentpScoreThree)
                
                if self.momentpScoreFour > 20 {
                    self.Cheating()
                }
            } else if self.breaker == 5 {
                self.momentpScoreFive = self.percentScore - (self.momentpScoreOne + self.momentpScoreTwo + self.momentpScoreThree + self.momentpScoreFour)
                
                if self.momentpScoreFive > 20 {
                    self.Cheating()
                }
            } else if self.breaker == 6 {
                self.momentpScoreSix = self.percentScore - (self.momentpScoreOne + self.momentpScoreTwo + self.momentpScoreThree +  self.momentpScoreFour + self.momentpScoreFive)
                
                if self.momentpScoreSix > 20 {
                    self.Cheating()
                }
            } else if self.breaker == 7 {
                self.momentpScoreSeven =  self.percentScore - (self.momentpScoreOne + self.momentpScoreTwo + self.momentpScoreThree +  self.momentpScoreFour + self.momentpScoreFive + self.momentpScoreSix)
                
                if self.momentpScoreOne > 20 {
                    self.Cheating()
                }
            }
            
            self.HeartRate = (OtherVale / 10) + self.HeartRate
            
            if self.HeartRate >= 60 {
                
                self.Question.setAlpha(0)
                self.Answer1.setAlpha(0)
                self.Answer2.setAlpha(0)
                self.Group.setAlpha(0)
                self.QuestionImage.setAlpha(0)
                self.Seperator.setAlpha(0)
                self.PointsLabel.setAlpha(0)
                self.SepLabel.setAlpha(0)
                
                self.Question.setHidden(true)
                self.Answer1.setHidden(true)
                self.Answer2.setHidden(true)
                self.Group.setHidden(true)
                self.QuestionImage.setHidden(true)
                self.Seperator.setHidden(true)
                self.PointsLabel.setHidden(true)
                self.SepLabel.setHidden(true)
                
                self.performSelector(#selector(InterfaceController.EndGame), withObject: nil, afterDelay: 0.1)
            }
        }
    }
    
    func EndGame()
    {
        Replay.setHidden(false)
        FinalScoreLabel.setHidden(false)
        FinalScore.setHidden(false)
        FinalImage.setHidden(false)
        
        FinalScoreLabel.setAlpha(1)
        Replay.setAlpha(1)
        FinalScore.setAlpha(1)
        FinalImage.setAlpha(1)
        
        FinalScoreLabel.setText("You answered \(percentScore) questions and got")
        FinalScore.setText("\(Score) right! ")
        
        healthStore.endWorkoutSession(workoutSession)
        Score = 0
        percentScore = 0
        self.HeartRate = 0
        IsDone = 0
        
    }
    
    //The actual game
    
    func StartGame() {
        
        percentScore = percentScore + 1
        
        if IsDone == 0 {
            IsDone = 1
            healthStore.endWorkoutSession(workoutSession)
            healthStore.startWorkoutSession(workoutSession)
        }
        
        let randomNumber = arc4random()%2
        
        if randomNumber == 0 {
            self.GeneralKnowledge()
        } else if randomNumber == 1 {
            self.Pictures()
        }  else {
            self.GeneralKnowledge()
        }
        
        if self.Answer1 == nil && self.Answer2 == nil {
            self.GeneralKnowledge()
        }
    }
    
    func GeneralKnowledge() {
        var RandomQuestion = arc4random()%350
        
        self.QuestionImage.setHidden(true)
        self.Question.setHidden(false)
        
        self.SepLabel.setHidden(true)
        self.SepLabel.setAlpha(0)
        
        let x = RandomQuestion
        
        if self.prev == Int(RandomQuestion) {
            repeat {
                RandomQuestion = arc4random()%350
                self.prev = Int(RandomQuestion)
            } while self.prev != Int(x)
        }
        
        self.prev = Int(RandomQuestion)
        
        //The Question From the actual game
        
        switch RandomQuestion {
        case let RandomQuestion where RandomQuestion == 1:
            Question.setText("Which rugby team has the nickname, The All Blacks?")
            Answer1.setTitle("New Zeland")
            Answer2.setTitle("Samoa")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 2:
            Question.setText("Who was the first paralympian to compete in an olympics?")
            Answer1.setTitle("Oscar Pistorius")
            Answer2.setTitle("Neroli Fairhall")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 3:
            Question.setText("What is the capital city of New Zeland?")
            Answer1.setTitle("Wellington")
            Answer2.setTitle("Auckland")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 4:
            Question.setText("Where is the Hobbiton film set nearer?")
            Answer1.setTitle("Wellington")
            Answer2.setTitle("Auckland")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 5:
            Question.setText("Whowas the first person from New Zeland to win an Oscar?")
            Answer1.setTitle("Jane Campion")
            Answer2.setTitle("Peter Jackson")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 6:
            Question.setText("The silver fern is a national symbol for which country?")
            Answer1.setTitle("Australia")
            Answer2.setTitle("New Zeland")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 7:
            Question.setText("Which rugby team has the nickname, The Springboks?")
            Answer1.setTitle("South Africa")
            Answer2.setTitle("Australia")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 8:
            Question.setText("Who was the first south african to be in an olympics and paralympics")
            Answer1.setTitle("Oscar Pistorius")
            Answer2.setTitle("Natalie du Toit")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 9:
            Question.setText("What is the capital city of Australia")
            Answer1.setTitle("Canberra")
            Answer2.setTitle("Sydney")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 10:
            Question.setText("What is the longest river in Australia?")
            Answer1.setTitle("Murrumbribidgee River")
            Answer2.setTitle("Nurray River")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 11:
            Question.setText("Who was the first living Aurtralian to win an Oscar for acting?")
            Answer1.setTitle("Geoffery Rush")
            Answer2.setTitle("Nicole Kidman")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 12:
            Question.setText("Which Australian won the best actress oscar for acting?")
            Answer1.setTitle("Cate Blanchett")
            Answer2.setTitle("Nicole Kidman")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 13:
            Question.setText("Which country has won the ICC cricket world cup the most?")
            Answer1.setTitle("Australia")
            Answer2.setTitle("India")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 14:
            Question.setText("What is the capital city of Canada?")
            Answer1.setTitle("Toronto")
            Answer2.setTitle("Ottawa")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 15:
            Question.setText("What is the official residence of the canadian prime minister?")
            Answer1.setTitle("24 Sussex Drive")
            Answer2.setTitle("Rideau Hall")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 16:
            Question.setText("Which beach did canadian soldiers liberate on D Day?")
            Answer1.setTitle("Sword Beach")
            Answer2.setTitle("Juno Beach")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 17:
            Question.setText("Which canadian ice hockey team has won the most stanley cups?")
            Answer1.setTitle("Montreal Canadiens")
            Answer2.setTitle("Toronto Maple Leafs")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 18:
            Question.setText("How many times have the canadian ice hockey team won a gold medal?")
            Answer1.setTitle("11")
            Answer2.setTitle("9")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 19:
            Question.setText("Canada is comprised of how many orivinces?")
            Answer1.setTitle("10")
            Answer2.setTitle("8")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 20:
            Question.setText("Niagara falls is located beside which canadian city?")
            Answer1.setTitle("Buffalo")
            Answer2.setTitle("Toronto")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 21:
            Question.setText("Cirque du soleil originated in which canadian city?")
            Answer1.setTitle("Montreal")
            Answer2.setTitle("Quebec City")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 22:
            Question.setText("How many times has Quebec held a vote on independence from canada?")
            Answer1.setTitle("1")
            Answer2.setTitle("2")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 23:
            Question.setText("The maple leaf is an emblem for which country?")
            Answer1.setTitle("Canada")
            Answer2.setTitle("USA")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 24:
            Question.setText("What is the highest peak in canada?")
            Answer1.setTitle("Mount Saint Elias")
            Answer2.setTitle("Mount Logan")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 25:
            Question.setText("What year did India gain it's independence from the uk?")
            Answer1.setTitle("1947")
            Answer2.setTitle("1949")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 26:
            Question.setText("The taj mahal was built in which indian city?")
            Answer1.setTitle("Kolkutta")
            Answer2.setTitle("Agra")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 27:
            Question.setText("How many times has india won the ICC cricket world cup?")
            Answer1.setTitle("2")
            Answer2.setTitle("1")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 28:
            Question.setText("Which city was chosen to host the 2010 commonwealth games?")
            Answer1.setTitle("Mumbai")
            Answer2.setTitle("Delhi")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 29:
            Question.setText("Who is the all time leading scorer in the ICC cricket world cup?")
            Answer1.setTitle("Rick Ponting")
            Answer2.setTitle("Sachin Tendulkar")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 30:
            Question.setText("Which rugby team has the nickname, The All Blacks?")
            Answer1.setTitle("Samoa")
            Answer2.setTitle("New Zealand")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 31:
            Question.setText("Who is Mario’s brother?")
            Answer1.setTitle("Luigi")
            Answer2.setTitle("Wario")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 32:
            Question.setText("How many planets are in our Solar System?")
            Answer1.setTitle("7")
            Answer2.setTitle("8")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 33:
            Question.setText("Who is the largest employer in the UK?")
            Answer1.setTitle("NHS")
            Answer2.setTitle("Tesco")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 34:
            Question.setText("Where is the Silverstone motor racing circuit?")
            Answer1.setTitle("UK")
            Answer2.setTitle("USA")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 35:
            Question.setText("Where is the Italian Grand Prix traditionally held?")
            Answer1.setTitle("Imola")
            Answer2.setTitle("Monza")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 36:
            Question.setText("Who was the first Roman Emperor?")
            Answer1.setTitle("Augustus")
            Answer2.setTitle("Julius Caesar")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 37:
            Question.setText("How many men were in a Century in the Imperial Roman Army?")
            Answer1.setTitle("100")
            Answer2.setTitle("80")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 38:
            Question.setText("When did the Roman Army first invade Britannia?")
            Answer1.setTitle("55BC")
            Answer2.setTitle("43AD")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 39:
            Question.setText("Who won the Battle of Zama?")
            Answer1.setTitle("Hannibal")
            Answer2.setTitle("Scipio")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 40:
            Question.setText("What year was the Roman Empire founded?")
            Answer1.setTitle("27BC")
            Answer2.setTitle("752BC")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 41:
            Question.setText("In legend, which brother supposedly built Rome?")
            Answer1.setTitle("Remus")
            Answer2.setTitle("Romulus")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 42:
            Question.setText("What video game character is given the task of rescuing Zelda?")
            Answer1.setTitle("Link")
            Answer2.setTitle("Ganon")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 43:
            Question.setText("Who is the largest employer in the USA?")
            Answer1.setTitle("Walmart")
            Answer2.setTitle("Dept. of Defence")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 44:
            Question.setText("Who created Buzz Lightyear?")
            Answer1.setTitle("Pixar")
            Answer2.setTitle("Dreamworks")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 45:
            Question.setText("Who does Shrek fall in love with?")
            Answer1.setTitle("Cinderella")
            Answer2.setTitle("Fiona")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 46:
            Question.setText("Which Billionaire inventor created Ironman?")
            Answer1.setTitle("Tony Stark")
            Answer2.setTitle("Elon Musk")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 47:
            Question.setText("Which country houses the bell known as Big Ben?")
            Answer1.setTitle("France")
            Answer2.setTitle("UK")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 48:
            Question.setText("Which of these is one of China’s Four Great Inventions?")
            Answer1.setTitle("Gunpowder")
            Answer2.setTitle("Acupuncture")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 49:
                Question.setText("Which of these is one of China’s Four Great Inventions?")
                Answer1.setTitle("Chopsticks")
                Answer2.setTitle("Paper Making")
                
                IsAnswerOneRight = false
                IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 50:
            Question.setText("Capital City of China?")
            Answer1.setTitle("Beijing")
            Answer2.setTitle("Shanghai")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 51:
            Question.setText("Longest river in China?")
            Answer1.setTitle("Yellow")
            Answer2.setTitle("Yangtze")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 52:
            Question.setText("Which country is the most populous?")
            Answer1.setTitle("China")
            Answer2.setTitle("India")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 53:
            Question.setText("Capital City of Monaco?")
            Answer1.setTitle("Monte Carlo")
            Answer2.setTitle("Monaco")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 54:
            Question.setText("How many players in a Rugby Union team?")
            Answer1.setTitle("15")
            Answer2.setTitle("11")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 55:
            Question.setText("Who hosted the 2012 Summer Olympic Games?")
            Answer1.setTitle("Beijing")
            Answer2.setTitle("London")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 56:
            Question.setText("First animated film nominated for the Best Picture Oscar?")
            Answer1.setTitle("Beauty & the Beast")
            Answer2.setTitle("Up")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 58:
            Question.setText("National Flower of France?")
            Answer1.setTitle("Rose")
            Answer2.setTitle("Iris")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 59:
            Question.setText("National Flower of Ireland?")
            Answer1.setTitle("Shamrock")
            Answer2.setTitle("Thistle")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 60:
            Question.setText("National Flower of Scotland?")
            Answer1.setTitle("Shamrock")
            Answer2.setTitle("Thistle")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 61:
            Question.setText("National Flower of Austria?")
            Answer1.setTitle("Edelweiss")
            Answer2.setTitle("Knapweed")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 62:
            Question.setText("National Flower of England?")
            Answer1.setTitle("Thistle")
            Answer2.setTitle("Rose")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 63:
            Question.setText("National Flower of India?")
            Answer1.setTitle("Lotus")
            Answer2.setTitle("Rose")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 64:
            Question.setText("Which country has won more FIFA World Cups?")
            Answer1.setTitle("Argentina")
            Answer2.setTitle("Brazil")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
            
        case let RandomQuestion where RandomQuestion == 65:
            Question.setText("Which country won the first World Cup in 1930?")
            Answer1.setTitle("Uruguay")
            Answer2.setTitle("Brazil")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
            
        case let RandomQuestion where RandomQuestion == 66:
            Question.setText("Who wrote 20,000 Leagues Under the Sea?")
            Answer1.setTitle("H.G. Wells")
            Answer2.setTitle("Jules Verne")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
            
        case let RandomQuestion where RandomQuestion == 67:
            Question.setText("Who wrote Animal Farm?")
            Answer1.setTitle("George Orwell")
            Answer2.setTitle("H.G. Wells")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
            
        case let RandomQuestion where RandomQuestion == 68:
            Question.setText("Who created the fictional character of Edmond Dantès?")
            Answer1.setTitle("Victor Hugo")
            Answer2.setTitle("Alexander Dumas")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
            
        case let RandomQuestion where RandomQuestion == 69:
            Question.setText("Who created the fictional character of Atticus Finch?")
            Answer1.setTitle("Harper Lee")
            Answer2.setTitle("J.K. Rowling")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
            
        case let RandomQuestion where RandomQuestion == 70:
            Question.setText("Who created the fictional character of Argus Filch?")
            Answer1.setTitle("Harper Lee")
            Answer2.setTitle("J.K. Rowling")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 71:
            Question.setText("Who created the fictional character of Mary Poppins?")
            Answer1.setTitle("P.L. Travers")
            Answer2.setTitle("A.A. Milne")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
            
        case let RandomQuestion where RandomQuestion == 72:
            Question.setText("Who created the fictional character of Baloo?")
            Answer1.setTitle("A.A. Milne")
            Answer2.setTitle("Rudyard Kipling")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
            
        case let RandomQuestion where RandomQuestion == 73:
            Question.setText("Which country has played in the most FIFA World Cup Finals?")
            Answer1.setTitle("Germany")
            Answer2.setTitle("Brazil")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 74:
            Question.setText("Who is the leading FIFA World Cup goalscorer?")
            Answer1.setTitle("Ronaldo")
            Answer2.setTitle("Miroslav Klose")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
            
        case let RandomQuestion where RandomQuestion == 75:
            Question.setText("Who has won more FIFA World Cups?")
            Answer1.setTitle("Pele")
            Answer2.setTitle("Maradona")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
            
        case let RandomQuestion where RandomQuestion == 76:
            Question.setText("Lowest point on the Earth’s surface?")
            Answer1.setTitle("Death Valley")
            Answer2.setTitle("Dead Sea")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
            
        case let RandomQuestion where RandomQuestion == 77:
            Question.setText("At their nearest points, which is closer?")
            Answer1.setTitle("I.S.S and London")
            Answer2.setTitle("Glasgow and London")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
            
        case let RandomQuestion where RandomQuestion == 78:
            Question.setText("Whose chipsets are in over 80% of smartphones?")
            Answer1.setTitle("Intel")
            Answer2.setTitle("ARM")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
            
        case let RandomQuestion where RandomQuestion == 79:
            Question.setText("Who reigned longer?")
            Answer1.setTitle("Queen Victoria")
            Answer2.setTitle("Julius Caesar")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
            
        case let RandomQuestion where RandomQuestion == 80:
            Question.setText("Where was Facebook started?")
            Answer1.setTitle("Stanford")
            Answer2.setTitle("Harvard")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 81:
            Question.setText("Where was Google started?")
            Answer1.setTitle("Stanford")
            Answer2.setTitle("Harvard")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
            
        case let RandomQuestion where RandomQuestion == 82:
            Question.setText("First woman to win the Oscar for Best Director?")
            Answer1.setTitle("Barbra Streisand")
            Answer2.setTitle("Kathryn Bigelow")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
            
        case let RandomQuestion where RandomQuestion == 84:
            Question.setText("Which rugby team has the nickname, The Pumas?")
            Answer1.setTitle("Argentina")
            Answer2.setTitle("Uruguay")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
            
        case let RandomQuestion where RandomQuestion == 85:
            Question.setText("Who did Serena Williams beat to win her first Grand Slam?")
            Answer1.setTitle("Venus Williams")
            Answer2.setTitle("Martina Hingis")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 86:
            Question.setText("What was the rocket that took the first human into space?")
            Answer1.setTitle("Vostok 1")
            Answer2.setTitle("Mercury 7")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
            
        case let RandomQuestion where RandomQuestion == 87:
            Question.setText("In which Harry Potter book was Sirius Black introduced?")
            Answer1.setTitle("Order of the Phoenix")
            Answer2.setTitle("Prisoner of Azkaban")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
            
        case let RandomQuestion where RandomQuestion == 88:
            Question.setText("What is the fourth Harry Potter book called?")
            Answer1.setTitle("Goblet of Fire")
            Answer2.setTitle("Prisoner of Azkaban")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
            
        case let RandomQuestion where RandomQuestion == 89:
            Question.setText("Who invented the telephone?")
            Answer1.setTitle("Andrew Carnegie")
            Answer2.setTitle("Alexander G. Bell")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
            
        case let RandomQuestion where RandomQuestion == 90:
            Question.setText("The Rockefeller’s made their money from which natural resource?")
            Answer1.setTitle("Oil")
            Answer2.setTitle("Iron")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 91:
            Question.setText("How many President’s faces are etched into Mount Rushmore?")
            Answer1.setTitle("Five")
            Answer2.setTitle("Four")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
            
        case let RandomQuestion where RandomQuestion == 92:
            Question.setText("Which American civilization built Chichen Itza?")
            Answer1.setTitle("Mayan")
            Answer2.setTitle("Inca")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
            
        case let RandomQuestion where RandomQuestion == 93:
            Question.setText("Which continent is home to Machu Pichu?")
            Answer1.setTitle("Asia")
            Answer2.setTitle("South America")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
            
        case let RandomQuestion where RandomQuestion == 94:
            Question.setText("Highest peak in Asia?")
            Answer1.setTitle("Mount Everest")
            Answer2.setTitle("Mount Fuji")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
            
        case let RandomQuestion where RandomQuestion == 95:
            Question.setText("Official currency of Palau?")
            Answer1.setTitle("Palauvian Peso")
            Answer2.setTitle("US Dollar")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
            
        case let RandomQuestion where RandomQuestion == 96:
            Question.setText("Where is the Space Needle located?")
            Answer1.setTitle("Seattle")
            Answer2.setTitle("Washington DC")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
            
        case let RandomQuestion where RandomQuestion == 97:
            Question.setText("Where was Marie Curie born?")
            Answer1.setTitle("France")
            Answer2.setTitle("Poland")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
            
        case let RandomQuestion where RandomQuestion == 98:
            Question.setText("Which African footballer has won the Champions League the most?")
            Answer1.setTitle("Samuel Eto’o")
            Answer2.setTitle("Didier Drogba")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
            
        case let RandomQuestion where RandomQuestion == 99:
            Question.setText("Who was the lead character in the BBC’s House of Cards?")
            Answer1.setTitle("Francis Underwood")
            Answer2.setTitle("Francis Urquhart")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
            
        case let RandomQuestion where RandomQuestion == 100:
            Question.setText("Which University has won The Boat Race the most?")
            Answer1.setTitle("Cambridge")
            Answer2.setTitle("Oxford")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
            
        case let RandomQuestion where RandomQuestion == 101:
            Question.setText("London Bridge was dismantled and rebuilt in which US State?")
            Answer1.setTitle("Nevada")
            Answer2.setTitle("Arizona")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
            
        case let RandomQuestion where RandomQuestion == 102:
            Question.setText("What is Sir Cecil Chubb famous for buying?")
            Answer1.setTitle("Stonehenge")
            Answer2.setTitle("London Bridge")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
            
        case let RandomQuestion where RandomQuestion == 103:
            Question.setText("What was the last Apollo mission to the Moon?")
            Answer1.setTitle("Apollo 18")
            Answer2.setTitle("Apollo 17")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
            
        case let RandomQuestion where RandomQuestion == 104:
            Question.setText("Which company was added to the DOW 30 in 2015?")
            Answer1.setTitle("Apple")
            Answer2.setTitle("Google")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
            
        case let RandomQuestion where RandomQuestion == 105:
            Question.setText("Which villain appeared at the end of The Incredibles?")
            Answer1.setTitle("Syndrome")
            Answer2.setTitle("The Underminer")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
            
        case let RandomQuestion where RandomQuestion == 106:
            Question.setText("Which company has been on the DOW 30 the longest?")
            Answer1.setTitle("General Electric")
            Answer2.setTitle("Exxon Mobil")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
            
        case let RandomQuestion where RandomQuestion == 107:
            Question.setText("Where did the Three Tenors first perform in public?")
            Answer1.setTitle("Los Angeles")
            Answer2.setTitle("Rome")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 108:
            Question.setText("Who was not a member of the Three Tenors?")
            Answer1.setTitle("Andrea Bocelli")
            Answer2.setTitle("José Carreras")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 109:
            Question.setText("Who did Roger Federer beat in his first Wimbledon final?")
            Answer1.setTitle("Andy Roddick")
            Answer2.setTitle("Mark Philippoussis")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 110:
            Question.setText("Which nation has won more Gold Rowing medals at the Olympics?")
            Answer1.setTitle("East Germany")
            Answer2.setTitle("USA")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 111:
            Question.setText("How many times have China topped the medal table at a Summer Olympics?")
            Answer1.setTitle("Once")
            Answer2.setTitle("Twice")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 112:
            Question.setText("Which famous composer was born in Salzburg, Austria?")
            Answer1.setTitle("Beethoven")
            Answer2.setTitle("Mozart")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 113:
            Question.setText("Who was born first?")
            Answer1.setTitle("Beethoven")
            Answer2.setTitle("Mozart")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 114:
            Question.setText("Øresund Bridge connects Denmark and which country?")
            Answer1.setTitle("Sweden")
            Answer2.setTitle("Norway")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 115:
            Question.setText("The Great Pyramid of Giza was the tomb for which Pharaoh?")
            Answer1.setTitle("Ramesses II")
            Answer2.setTitle("Khufu")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 116:
            Question.setText("How many British Prime Minsters have served under Queen Elizabeth II?")
            Answer1.setTitle("12")
            Answer2.setTitle("13")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 117:
            Question.setText("Who has the highest number of Prime Ministers serving them?")
            Answer1.setTitle("Elizabeth II")
            Answer2.setTitle("George III")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 118:
            Question.setText("Which US State has a higher population density?")
            Answer1.setTitle("Florida")
            Answer2.setTitle("California")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 119:
            Question.setText("Which US State has a higher population density?")
            Answer1.setTitle("New York")
            Answer2.setTitle("Rhode Island")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 120:
            Question.setText("What was Pixar Animation Studios’ fourth feature film?")
            Answer1.setTitle("Monsters Inc.")
            Answer2.setTitle("Toy Story 2")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 121:
            Question.setText("Where does Sherlock Holmes reside?")
            Answer1.setTitle("Butcher Street")
            Answer2.setTitle("Baker Street")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 122:
            Question.setText("Where is the Mona Lisa housed?")
            Answer1.setTitle("The Louvre")
            Answer2.setTitle("The National Gallery")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 123:
            Question.setText("Highest scorer in the 1992 Olympic 'Dream Team'?")
            Answer1.setTitle("Michael Jordan")
            Answer2.setTitle("Charles Barkley")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 124:
            Question.setText("Busiest train station in Japan?")
            Answer1.setTitle("Shinjuku")
            Answer2.setTitle("Shibuya")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 125:
            Question.setText("The Parthenon sits on which Greek mountaintop?")
            Answer1.setTitle("Mount Olympus")
            Answer2.setTitle("Athenian Acropolis")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 126:
            Question.setText("The Nou Camp football stadium resides in which city?")
            Answer1.setTitle("Barcelona")
            Answer2.setTitle("Valencia")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 127:
            Question.setText("What is the symbol of the Shinto religion?")
            Answer1.setTitle("Taijitu")
            Answer2.setTitle("Torii")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 128:
            Question.setText("Which Icelandic artist has sold more records?")
            Answer1.setTitle("Bjork")
            Answer2.setTitle("Sigur Ros")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 129:
            Question.setText("By Scottish classification, over what height are hills classified as Munroes?")
            Answer1.setTitle("Over 2000 feet")
            Answer2.setTitle("Over 3000 feet")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 130:
            Question.setText("Which university was founded in 1451?")
            Answer1.setTitle("Glasgow")
            Answer2.setTitle("St John’s, Cambridge")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 131:
            Question.setText("Kinkaku-ji Temple in Japan is known by what name?")
            Answer1.setTitle("Silver Pavilion")
            Answer2.setTitle("Golden Pavilion")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 132:
            Question.setText("Which Disney Theme Park opened first?")
            Answer1.setTitle("California Adventure")
            Answer2.setTitle("Tokyo DisneySea")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 133:
            Question.setText("Which British Prime Minister was first to be elected to Parliament?")
            Answer1.setTitle("Neville Chamberlain")
            Answer2.setTitle("Winston Churchill")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 134:
            Question.setText("Which British newspaper has run longer?")
            Answer1.setTitle("The Guardian")
            Answer2.setTitle("The Telegraph")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 135:
            Question.setText("When did the United Kingdom transfer sovereignty of Hong Kong to China?")
            Answer1.setTitle("1996")
            Answer2.setTitle("1997")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 136:
            Question.setText("Who designed the Statue of Liberty?")
            Answer1.setTitle("Bartholdi")
            Answer2.setTitle("Eiffel")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 137:
            Question.setText("Who was originally commissioned to design Washington DC?")
            Answer1.setTitle("Andrew Ellicott")
            Answer2.setTitle("Charles L’Enfant")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 138:
            Question.setText("Where is the de facto capital of the European Union?")
            Answer1.setTitle("Brussels")
            Answer2.setTitle("Berlin")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 139:
            Question.setText("The League of Nations was located in which city?")
            Answer1.setTitle("New York")
            Answer2.setTitle("Geneva")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 140:
            Question.setText("The United Nations World Headquarters is located in which city?")
            Answer1.setTitle("New York")
            Answer2.setTitle("Geneva")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 141:
            Question.setText("The African Union is located in which city?")
            Answer1.setTitle("Lagos")
            Answer2.setTitle("Addis Ababa")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 142:
            Question.setText("The Flosberry Flop was developed for which sport?")
            Answer1.setTitle("High Jump")
            Answer2.setTitle("Pole Vault")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 143:
            Question.setText("What was the first mass produced Ford?")
            Answer1.setTitle("Model S")
            Answer2.setTitle("Model T")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 144:
            Question.setText("Largest dry desert in the world?")
            Answer1.setTitle("Sahara")
            Answer2.setTitle("Antartica")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 145:
            Question.setText("Which city has a higher population density?")
            Answer1.setTitle("Singapore")
            Answer2.setTitle("Hong Kong")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 146:
            Question.setText("Capital city of Japan in 1821?")
            Answer1.setTitle("Tokyo")
            Answer2.setTitle("Kyoto")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 147:
            Question.setText("In which city was J.F.K assassinated?")
            Answer1.setTitle("Dallas")
            Answer2.setTitle("Houston")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 148:
            Question.setText("How many countries make up the Nordic Council?")
            Answer1.setTitle("4")
            Answer2.setTitle("5")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 149:
            Question.setText("How many countries in Europe have a Monarchy as Head of State?")
            Answer1.setTitle("9")
            Answer2.setTitle("12")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 150:
            Question.setText("The London Marathon traditionally finishes on which street?")
            Answer1.setTitle("The Mall")
            Answer2.setTitle("Oxford Street")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 151:
            Question.setText("The Tour de France traditionally finishes on which street?")
            Answer1.setTitle("L’Enfant Boulevard")
            Answer2.setTitle("Champs Elysee")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 152:
            Question.setText("What is the Japanese Throne called?")
            Answer1.setTitle("Chrystantheum")
            Answer2.setTitle("Cherry Iron")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 153:
            Question.setText("Steve McQueen starred in which prison break movie?")
            Answer1.setTitle("Escape from Alcatraz")
            Answer2.setTitle("The Great Escape")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 154:
            Question.setText("Which Japanese Emperor took the throne in 1989?")
            Answer1.setTitle("Akihito")
            Answer2.setTitle("Hirohito")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 155:
            Question.setText("Mt Kilimanjaro is located in which country?")
            Answer1.setTitle("Kenya")
            Answer2.setTitle("Tanzania")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 156:
            Question.setText("What is the tallest peak in Western Europe?")
            Answer1.setTitle("Mont Blanc")
            Answer2.setTitle("Matterhorn")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 157:
            Question.setText("What is the largest lake in Africa by surface area?")
            Answer1.setTitle("Lake Tanganyika")
            Answer2.setTitle("Lake Victoria")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 158:
            Question.setText("Who is credited with the creation of the World Wide Web?")
            Answer1.setTitle("Tim Berners-Lee")
            Answer2.setTitle("Al Gore")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 159:
            Question.setText("Pearl Harbour is located on which American Island?")
            Answer1.setTitle("Hawai’i")
            Answer2.setTitle("O’ahu")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 160:
            Question.setText("When did the United Kingdom enter World War II?")
            Answer1.setTitle("1939")
            Answer2.setTitle("1941")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 161:
            Question.setText("Capital city of Thailand?")
            Answer1.setTitle("Phuket")
            Answer2.setTitle("Bangkok")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 162:
            Question.setText("All time leading run scorer in the ICC Cricket World Cup?")
            Answer1.setTitle("Sachin Tendulkar")
            Answer2.setTitle("Ricky Ponting")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 163:
            Question.setText("How many kilometres of railway did Britain build in India before it’s independence?")
            Answer1.setTitle("Under 65,000km")
            Answer2.setTitle("Over 65,000km")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 164:
            Question.setText("Which Indian city hosted the 2010 Commonwealth Games?")
            Answer1.setTitle("Delhi")
            Answer2.setTitle("Mumbai")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 165:
            Question.setText("How many times has India won the ICC Cricket World Cup?")
            Answer1.setTitle("Once")
            Answer2.setTitle("Twice")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 166:
            Question.setText("Which Indian city is home to the Taj Mahal?")
            Answer1.setTitle("Agra")
            Answer2.setTitle("Kolkutta")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 167:
            Question.setText("What year did India gain it’s independence?")
            Answer1.setTitle("1947")
            Answer2.setTitle("1949")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 168:
            Question.setText("Highest peak in Canada?")
            Answer1.setTitle("Mount St Elias")
            Answer2.setTitle("Mount Logan")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 169:
            Question.setText("How many times has Quebec held a vote on independence from Canada?")
            Answer1.setTitle("Once")
            Answer2.setTitle("Twice")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 170:
            Question.setText("The Maple Leaf is an emblem for which country?")
            Answer1.setTitle("Canada")
            Answer2.setTitle("USA")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 171:
            Question.setText("Where is Cirque du Soleil headquarted?")
            Answer1.setTitle("Quebec City")
            Answer2.setTitle("Montreal")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 172:
            Question.setText("Niagara Falls is located beside which Canadian city?")
            Answer1.setTitle("Buffalo")
            Answer2.setTitle("Toronto")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 173:
            Question.setText("Canada is comprised of how many Provinces?")
            Answer1.setTitle("8")
            Answer2.setTitle("10")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 174:
            Question.setText("How many times have the Canadian Men’s Ice Hockey team won Olympic Gold?")
            Answer1.setTitle("9")
            Answer2.setTitle("11")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 175:
            Question.setText("Which Canadian Ice Hockey team has won the most Stanley Cups?")
            Answer1.setTitle("Montreal Canadiens")
            Answer2.setTitle("Toronto Maple Leafs")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 176:
            Question.setText("Official residence of the Canadian Prime Minister?")
            Answer1.setTitle("Rideau Hall")
            Answer2.setTitle("24 Sussex Drive")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 177:
            Question.setText("Which Australian won the Best Actress Oscar first?")
            Answer1.setTitle("Cate Blanchett")
            Answer2.setTitle("Nicole Kidman")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 178:
            Question.setText("Capital city of Australia?")
            Answer1.setTitle("Canberra")
            Answer2.setTitle("Sydney")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 179:
            Question.setText("Which rugby team has the nickname, The Springboks?")
            Answer1.setTitle("Australia")
            Answer2.setTitle("South Africa")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 180:
            Question.setText("The Silver Fern is a National Symbol for which country?")
            Answer1.setTitle("Australia")
            Answer2.setTitle("New Zealand")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 181:
            Question.setText("Capital city of New Zealand?")
            Answer1.setTitle("Auckland")
            Answer2.setTitle("Wellington")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 182:
            Question.setText("Where is the Hobbiton film set nearer?")
            Answer1.setTitle("Auckland")
            Answer2.setTitle("Wellington")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 183:
            Question.setText("Which beach did Canadian soldiers liberate on D Day?")
            Answer1.setTitle("Juno Beach")
            Answer2.setTitle("Sword Beach")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 184:
            Question.setText("Capital city of Canada?")
            Answer1.setTitle("Ottowa")
            Answer2.setTitle("Toronto")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 185:
            Question.setText("Which country has won the ICC Cricket World Cup the most?")
            Answer1.setTitle("Australia")
            Answer2.setTitle("India")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 186:
            Question.setText("Longest river in Australia?")
            Answer1.setTitle("Murrumbidgee")
            Answer2.setTitle("Murray")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 187:
            Question.setText("First living Australian to win an Oscar for acting?")
            Answer1.setTitle("Geoffrey Rush")
            Answer2.setTitle("Nicole Kidman")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 188:
            Question.setText("First South African to compete in both an Olympics and Paralympics?")
            Answer1.setTitle("Oscar Pistorius")
            Answer2.setTitle("Natalie du Toit")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 189:
            Question.setText("First person from New Zealand to win an Oscar?")
            Answer1.setTitle("Peter Jackson")
            Answer2.setTitle("Jane Campion")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 190:
            Question.setText("First Paralympian to also compete in an Olympics?")
            Answer1.setTitle("Neroli Fairhall")
            Answer2.setTitle("Oscar Pistorius")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 191:
            Question.setText("Which rugby team has the nickname, The All Blacks?")
            Answer1.setTitle("Samoa")
            Answer2.setTitle("New Zealand")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 193:
            Question.setText("First country to legalise gay marriage?")
            Answer1.setTitle("Netherlands")
            Answer2.setTitle("Canada")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
            
        case let RandomQuestion where RandomQuestion == 193:
            Question.setText("What percentage of the Netherlands is below sea level?")
            Answer1.setTitle("33%")
            Answer2.setTitle("25%")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 193:
            Question.setText("How much of the worlds bacon is produced in the Netherlands?")
            Answer1.setTitle("70%")
            Answer2.setTitle("50%")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 192:
            Question.setText("What was the official currency of Germany in 1990?")
            Answer1.setTitle("Germanic")
            Answer2.setTitle("Marc")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 193:
            Question.setText("Official currency of Colombia?")
            Answer1.setTitle("Colombian Peso")
            Answer2.setTitle("US Dollar")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 194:
            Question.setText("Official currency of Paraguay?")
            Answer1.setTitle("Paraguayan guaraní")
            Answer2.setTitle("Paraguayan Peso")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 195:
            Question.setText("Official currency of Kazakhstan?")
            Answer1.setTitle("Ruble")
            Answer2.setTitle("Tenge")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 196:
            Question.setText("Official currency of Laos?")
            Answer1.setTitle("Yuan")
            Answer2.setTitle("Kip")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 197:
            Question.setText("Capital City of Germany?")
            Answer1.setTitle("Vienna")
            Answer2.setTitle("Berlin")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 198:
            Question.setText("Who was born first?")
            Answer1.setTitle("Benjamin Franklin")
            Answer2.setTitle("Mozart")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 199:
            Question.setText("Which EU country has the largest population?")
            Answer1.setTitle("UK")
            Answer2.setTitle("Germany")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 200:
            Question.setText("Who does Germany share it’s largest border with?")
            Answer1.setTitle("Austria")
            Answer2.setTitle("Czech Republic")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 201:
            Question.setText("What is the longest river in Germany?")
            Answer1.setTitle("Danube")
            Answer2.setTitle("Rhine")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 202:
            Question.setText("Who does Italy share it’s largest border with?")
            Answer1.setTitle("Switzerland")
            Answer2.setTitle("Austria")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 203:
            Question.setText("What is the currency of France?")
            Answer1.setTitle("Franc")
            Answer2.setTitle("Euro")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 204:
            Question.setText("When is Bastille Day celebrated?")
            Answer1.setTitle("July 12th")
            Answer2.setTitle("July 14th")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 205:
            Question.setText("When did the Eiffel Tower open?")
            Answer1.setTitle("1889")
            Answer2.setTitle("1901")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 206:
            Question.setText("Tallest structure in France?")
            Answer1.setTitle("Eiffel Tower")
            Answer2.setTitle("Millau Viaduct")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
            
        case let RandomQuestion where RandomQuestion == 207:
            Question.setText("Longest river in France?")
            Answer1.setTitle("Loire")
            Answer2.setTitle("Seine")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 208:
            Question.setText("Who was born first?")
            Answer1.setTitle("Anne Frank")
            Answer2.setTitle("Martin Luther King")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 209:
            Question.setText("Which event happened first?")
            Answer1.setTitle("Oxford University Founded")
            Answer2.setTitle("Aztec Empire Began")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 210:
            Question.setText("Where is the tallest structure in the USA?")
            Answer1.setTitle("North Dakota")
            Answer2.setTitle("New York")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 211:
            Question.setText("Biggest selling album of all time?")
            Answer1.setTitle("Back in Black - AC/DC")
            Answer2.setTitle("Thriller - Jackson")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 212:
            Question.setText("Number of signatures on US Declaration of Independence?")
            Answer1.setTitle("56")
            Answer2.setTitle("60")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 213:
            Question.setText("Most No.1 Songs on the US Billboard Chart?")
            Answer1.setTitle("Elvis Presley")
            Answer2.setTitle("The Beatles")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 214:
            Question.setText("How many No.1 Songs did Michael JacsKSon have in the US?")
            Answer1.setTitle("13")
            Answer2.setTitle("15")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 215:
            Question.setText("The chemical element Krypton is denoted by which symbol?")
            Answer1.setTitle("K")
            Answer2.setTitle("Kr")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 216:
            Question.setText("What is Potassium’s symbol in the Periodic Table?")
            Answer1.setTitle("K")
            Answer2.setTitle("Pt")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 217:
            Question.setText("Who formulated the Periodic Table?")
            Answer1.setTitle("Mendelev")
            Answer2.setTitle("Nobel")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 218:
            Question.setText("Who scored The Nutcracker")
            Answer1.setTitle("Stravinsky")
            Answer2.setTitle("Tchaikovsky")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 219:
            Question.setText("Highest mountain in Russia?")
            Answer1.setTitle("Dykh-Tau")
            Answer2.setTitle("Mount Elbrus")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 220:
            Question.setText("Is Russia’s land mass larger than Pluto?")
            Answer1.setTitle("Yes")
            Answer2.setTitle("No")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 221:
            Question.setText("At their nearest point, how close are Russia and USA?")
            Answer1.setTitle("4km")
            Answer2.setTitle("27km")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 222:
            Question.setText("Who discovered the Electron?")
            Answer1.setTitle("Rutherford")
            Answer2.setTitle("Thompson")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 223:
            Question.setText("Who first discovered the Andromeda galaxy describing it as ‘A Little Cloud’?")
            Answer1.setTitle("Azophi")
            Answer2.setTitle("Copernicus")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 224:
            Question.setText("Who designed the wedding dress for the Duchess of Cambridge?")
            Answer1.setTitle("Stella McCartney")
            Answer2.setTitle("Sarah Burton")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 225:
            Question.setText("First winner of three Best Actor Oscars?")
            Answer1.setTitle("Daniel Day Lewis")
            Answer2.setTitle("Jack Nicholson")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 226:
            Question.setText("First winner of four Best Actress Oscars?")
            Answer1.setTitle("Meryl Streep")
            Answer2.setTitle("Katharine Hepburn")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 227:
            Question.setText("Who is the lead actor in Forrest Gump?")
            Answer1.setTitle("Tom Hanks")
            Answer2.setTitle("Gary Sinise")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 228:
            Question.setText("Who plays Princess Leia in Star Wars?")
            Answer1.setTitle("Stevie Nicks")
            Answer2.setTitle("Carrie Fisher")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
            
        case let RandomQuestion where RandomQuestion == 229:
            Question.setText("Who discovered Polonium")
            Answer1.setTitle("Marie Curie")
            Answer2.setTitle("Martin H. Klaproth")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
            
        case let RandomQuestion where RandomQuestion == 230:
            Question.setText("First Briton to go into Space?")
            Answer1.setTitle("Tim Peake")
            Answer2.setTitle("Helen Sharman")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 231:
            Question.setText("What's the middle of nowhere")
            Answer1.setTitle("H")
            Answer2.setTitle("Earth")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 232:
            Question.setText("What occurs once in every minute but never in a thousand years")
            Answer1.setTitle("Blue moon")
            Answer2.setTitle("M")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 233:
            Question.setText("What has two arms but no legs")
            Answer1.setTitle("Clock")
            Answer2.setTitle("Lion")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 234:
            Question.setText("What goes up but never comes down")
            Answer1.setTitle("Age")
            Answer2.setTitle("Hot air")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 235:
            Question.setText("What has two words but loads of letters")
            Answer1.setTitle("Post Office")
            Answer2.setTitle("Government")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 236:
            Question.setText("What kind of nut has a hole")
            Answer1.setTitle("Cashew")
            Answer2.setTitle("Donut")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
        case let RandomQuestion where RandomQuestion == 237:
            Question.setText("What is the easiest way to double your money")
            Answer1.setTitle("Work")
            Answer2.setTitle("Use a mirror")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 238:
            Question.setText("What has a neck but no head")
            Answer1.setTitle("Bottle")
            Answer2.setTitle("Box")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 239:
            Question.setText("What gets wetter as it dries")
            Answer1.setTitle("Plastic")
            Answer2.setTitle("Towel")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 240:
            Question.setText("Everyone has it and no one can lose it, what is it")
            Answer1.setTitle("Shadow")
            Answer2.setTitle("Money")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 241:
            Question.setText("What runs around a house but never moves")
            Answer1.setTitle("gas")
            Answer2.setTitle("fence")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 242:
            Question.setText("What is broken before its used")
            Answer1.setTitle("Egg")
            Answer2.setTitle("Bottle Lid")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 243:
            Question.setText("What gets whiter the dirtier it gets")
            Answer1.setTitle("Whiteboard")
            Answer2.setTitle("Blackboard")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 244:
            Question.setText("What can you catch but not throw")
            Answer1.setTitle("Cold")
            Answer2.setTitle("Warm")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 245:
            Question.setText("What works with something in its eye")
            Answer1.setTitle("spike")
            Answer2.setTitle("needle")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 246:
            Question.setText("What breaks everytime you name it")
            Answer1.setTitle("Silence")
            Answer2.setTitle("Death")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 247:
            Question.setText("I hide but my head is outside, what am I")
            Answer1.setTitle("Tree")
            Answer2.setTitle("Nail")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 248:
            Question.setText("What doesn't exist but has a name")
            Answer1.setTitle("Nothing")
            Answer2.setTitle("a number")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 249:
            Question.setText("What kind of tree do you carry in your hand")
            Answer1.setTitle("Oak")
            Answer2.setTitle("Palm")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 250:
            Question.setText("What has feet and legs but nothing else")
            Answer1.setTitle("Sock")
            Answer2.setTitle("Trousers")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 251:
            Question.setText("How long does a red blood cell last until it start to diffuse?")
            Answer1.setTitle("365 Days")
            Answer2.setTitle("120 Days")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 252:
            Question.setText("What is the process when water moleclues move from a high concentration to a low one?")
            Answer1.setTitle("Osmosis")
            Answer2.setTitle("Diffusion")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 253:
            Question.setText("What is the speed of light in a vaccum?")
            Answer1.setTitle("3x10^8 m/s")
            Answer2.setTitle("2x10^8 m/s")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 254:
            Question.setText("Which of the following causes the highest ionisation?")
            Answer1.setTitle("Gamma Ray")
            Answer2.setTitle("Alpha Particles")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 255:
            Question.setText("What is three times ten divided by 5?")
            Answer1.setTitle("6")
            Answer2.setTitle("3")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 256:
            Question.setText("What is the square root of two to the power of eight?")
            Answer1.setTitle("32")
            Answer2.setTitle("16")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 257:
            Question.setText("What is the warmest ocean?")
            Answer1.setTitle("Indian")
            Answer2.setTitle("Atlantic")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 258:
            Question.setText("What are the first four letter of the middle line in a keyboard?")
            Answer1.setTitle("QWERT")
            Answer2.setTitle("ASDF")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 259:
            Question.setText("What colour of light has the highest wavelength?")
            Answer1.setTitle("Red")
            Answer2.setTitle("Violet")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 260:
            Question.setText("Which of the following has 4 carbons?")
            Answer1.setTitle("Butane")
            Answer2.setTitle("Pentene")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 261:
            Question.setText("What is the backbone that makes up DNA?")
            Answer1.setTitle("Deoxyribose sugar")
            Answer2.setTitle("Phosphate")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 262:
            Question.setText("What is a protein made out of?")
            Answer1.setTitle("Amino Acids")
            Answer2.setTitle("Phosphate Acids")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 263:
            Question.setText("Which nuclear reaction is a build up of atoms?")
            Answer1.setTitle("Fission")
            Answer2.setTitle("Fusion")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 264:
            Question.setText("In which episode of Star Trek did Khan make his first apperance?")
            Answer1.setTitle("Space Speed")
            Answer2.setTitle("Balance of Terror")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 265:
            Question.setText("Who played Spock in Star Trek")
            Answer1.setTitle("George Takei")
            Answer2.setTitle("Leonard Nimoy")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 266:
            Question.setText("In which year did star trek first air?")
            Answer1.setTitle("1966")
            Answer2.setTitle("1978")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 267:
            Question.setText("Which franchise does 'To boldy go where no man has gone before' come from?'")
            Answer1.setTitle("House of cards")
            Answer2.setTitle("Star Trek")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 268:
            Question.setText("Where does 'you hvave no power here' come from?")
            Answer1.setTitle("Lord Of The Rings")
            Answer2.setTitle("Star Wars")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 269:
            Question.setText("Who said 'it always seems impossible until its done'?")
            Answer1.setTitle("J.F.K")
            Answer2.setTitle("Nelson Mandela")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 270:
            Question.setText("Who was the first ever 'debugger' in programming?")
            Answer1.setTitle("Ada Lovelace")
            Answer2.setTitle("Dennis Ritchie")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 271:
            Question.setText("Who created the music for Inception")
            Answer1.setTitle("Steve Jablonsky")
            Answer2.setTitle("Hans Zimmer")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 272:
            Question.setText("Who played gandalf?")
            Answer1.setTitle("Ian McKellen")
            Answer2.setTitle("Michael Gambon")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 273:
            Question.setText("Who wrote Great Expectations")
            Answer1.setTitle("William Shakespeare")
            Answer2.setTitle("Charles Dickens")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 274:
            Question.setText("Who created  Red Dead Revolver?")
            Answer1.setTitle("Rockstar")
            Answer2.setTitle("EA")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 275:
            Question.setText("Sir Arthus Conan Doyle is famous for creating which character?")
            Answer1.setTitle("Frodo Baggins")
            Answer2.setTitle("Sherlock Holmes")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 276:
            Question.setText("What is the name of Charles Dickens wife?")
            Answer1.setTitle("Catherine Thomson")
            Answer2.setTitle("Anne Hathaway")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 277:
            Question.setText("Who won the 1976 German Grand Prix race?")
            Answer1.setTitle("Niki Lauda")
            Answer2.setTitle("James Hunt")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 278:
            Question.setText("What is worlds oldest broadcasting service?")
            Answer1.setTitle("BBC")
            Answer2.setTitle("NBC")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 279:
            Question.setText("Where was the world first known Oil Well built?")
            Answer1.setTitle("USA")
            Answer2.setTitle("China")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 280:
            Question.setText("Which French region is not well known for wine making?")
            Answer1.setTitle("Oban")
            Answer2.setTitle("Alsace")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 281:
            Question.setText("What was the book Animal Farms inspired by?")
            Answer1.setTitle("Hitler")
            Answer2.setTitle("Stalin")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 282:
            Question.setText("Who wrote dulce et decorum est?")
            Answer1.setTitle("Wilfred Owen")
            Answer2.setTitle("George Orwells")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 283:
            Question.setText("In Computing Science which of the following is a programming error?")
            Answer1.setTitle("Mathematical")
            Answer2.setTitle("Logic")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 284:
            Question.setText("What stops the back flow of blood in the heart?")
            Answer1.setTitle("Valves")
            Answer2.setTitle("Atria")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 285:
            Question.setText("Where is parkour from?")
            Answer1.setTitle("USA")
            Answer2.setTitle("France")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 286:
            Question.setText("Which of the following is not a programming langauge?")
            Answer1.setTitle("Lunix")
            Answer2.setTitle("Unix")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 287:
            Question.setText("What doesn't come from an animal?")
            Answer1.setTitle("Veal")
            Answer2.setTitle("Fig")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 288:
            Question.setText("When was YouTube first invented?")
            Answer1.setTitle("2005")
            Answer2.setTitle("2006")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 289:
            Question.setText("Where is Turin located?")
            Answer1.setTitle("UK")
            Answer2.setTitle("Italy")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 290:
            Question.setText("What Castle was constructed first?")
            Answer1.setTitle("Windsor")
            Answer2.setTitle("Hemiji")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 291:
            Question.setText("When was Pablo Picasso born?")
            Answer1.setTitle("1853")
            Answer2.setTitle("1881")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 292:
            Question.setText("How many countries are on Antartica?")
            Answer1.setTitle("12")
            Answer2.setTitle("16")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 293:
            Question.setText("What painting did Mr Bean ruin?")
            Answer1.setTitle("Whistlers Mistress")
            Answer2.setTitle("Mona Lisa")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 294:
            Question.setText("How many monty python films are there?")
            Answer1.setTitle("4")
            Answer2.setTitle("9")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 295:
            Question.setText("When did monty python first air?")
            Answer1.setTitle("1970")
            Answer2.setTitle("1969")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 296:
            Question.setText("How many monty python episodes are there?")
            Answer1.setTitle("45")
            Answer2.setTitle("50")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 297:
            Question.setText("What is Michael Jacksons middle name?")
            Answer1.setTitle("George")
            Answer2.setTitle("Joseph")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 298:
            Question.setText("What is the name of the ageing rock star in Love Actally?")
            Answer1.setTitle("Bill Nighy")
            Answer2.setTitle("Bill Wyman")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 299:
            Question.setText("What grows in paddy fields?")
            Answer1.setTitle("Maize")
            Answer2.setTitle("Rice")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 300:
            Question.setText("What is a pepper?")
            Answer1.setTitle("Spice")
            Answer2.setTitle("Herb")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 301:
            Question.setText("Which films did Brad Pitt receive an acting credit?")
            Answer1.setTitle("Julius Caesar")
            Answer2.setTitle("Johnny Sude")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 302:
            Question.setText("Which of these cheeses are not made in Britain?")
            Answer1.setTitle("Beaver")
            Answer2.setTitle("Cheddar")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 303:
            Question.setText("Which of these is a normal name for a cut for beef?")
            Answer1.setTitle("Skillet")
            Answer2.setTitle("Shin")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 304:
            Question.setText("Which character has not appeared in the Looney Tunes?")
            Answer1.setTitle("Tex Avery")
            Answer2.setTitle("Cecil Turtle")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 305:
            Question.setText("Which of these characters is from the Simpsons?")
            Answer1.setTitle("Esther Walton")
            Answer2.setTitle("Jimbo Jones")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 306:
            Question.setText("Which character has appeared in the puppets tv series?")
            Answer1.setTitle("Doglion")
            Answer2.setTitle("Dr Tim")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 307:
            Question.setText("What is a traditional shape of pasta?")
            Answer1.setTitle("Pagliacci")
            Answer2.setTitle("Gigli")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 308:
            Question.setText("Which films does Sylvester Stallone appear in?")
            Answer1.setTitle("Nighthawks")
            Answer2.setTitle("Raging Bull")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 309:
            Question.setText("Opal is the Birthstone for which month?")
            Answer1.setTitle("November")
            Answer2.setTitle("October")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 310:
            Question.setText("What happens to the clocks in spring?")
            Answer1.setTitle("Go forwards")
            Answer2.setTitle("Go backwards")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 311:
            Question.setText("Where is O’Hare Airport?")
            Answer1.setTitle("New York")
            Answer2.setTitle("Chicago")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 312:
            Question.setText("What birth sign are you if born on 25th on December?")
            Answer1.setTitle("Capricorn")
            Answer2.setTitle("Sagittarius")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 313:
            Question.setText("How many members were originally in spice girls?")
            Answer1.setTitle("4")
            Answer2.setTitle("5")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 314:
            Question.setText("Who wrote the Peter Rabbit books?")
            Answer1.setTitle("Beatrix Potter")
            Answer2.setTitle("AA Milne")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 315:
            Question.setText("How many rails does a monorail have?")
            Answer1.setTitle("1")
            Answer2.setTitle("2")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 316:
            Question.setText("What is princess Anne’s daughter’s name?")
            Answer1.setTitle("Zara")
            Answer2.setTitle("Beatrice")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 317:
            Question.setText("How many of Henry VIII’s wives were beheaded?")
            Answer1.setTitle("4")
            Answer2.setTitle("2")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 318:
            Question.setText("How many balls are there on a pool table?")
            Answer1.setTitle("16")
            Answer2.setTitle("20")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 319:
            Question.setText("What year was the skateboard invented?")
            Answer1.setTitle("1968")
            Answer2.setTitle("1958")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 320:
            Question.setText("What year did London underground open?")
            Answer1.setTitle("1863")
            Answer2.setTitle("1883")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 321:
            Question.setText("What is a beavers home called?")
            Answer1.setTitle("A set")
            Answer2.setTitle("A lodge")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 322:
            Question.setText("What nation gave women the right to vote first?")
            Answer1.setTitle("New Zeland")
            Answer2.setTitle("Britain")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 323:
            Question.setText("Which singer is known as the queen of soul?")
            Answer1.setTitle("Diana Ross")
            Answer2.setTitle("Aretha Franklin")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 324:
            Question.setText("What is Ozzy Osbourne’s real name?")
            Answer1.setTitle("John Michael Osbourne")
            Answer2.setTitle("Michael Osbourne")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 325:
            Question.setText("What was Fred Flintstones best friend called?")
            Answer1.setTitle("Barney Bubble")
            Answer2.setTitle("Barney Rubble")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 326:
            Question.setText("Who plays Mrs Weasley in Harry Potter")
            Answer1.setTitle("Julie Walters")
            Answer2.setTitle("Julie Andrews")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 327:
            Question.setText("What was the name of Dick Turpin’s horse?")
            Answer1.setTitle("Black Beauty")
            Answer2.setTitle("Black Bess")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 328:
            Question.setText("which game has a candlestick as a weapon?")
            Answer1.setTitle("Cluedo")
            Answer2.setTitle("Monopoly")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 329:
            Question.setText("What is the world’s largest mammal?")
            Answer1.setTitle("Hump backed whale")
            Answer2.setTitle("Blue whale")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 330:
            Question.setText("What did price Phillip do when he married the queen?")
            Answer1.setTitle("Sailor")
            Answer2.setTitle("Soldier")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 331:
            Question.setText("What is a tomato?")
            Answer1.setTitle("Vegetable")
            Answer2.setTitle("Fruit")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 332:
            Question.setText("Whats the highest score you can get with 3 darts?")
            Answer1.setTitle("180")
            Answer2.setTitle("140")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 333:
            Question.setText("What does tea grow on?")
            Answer1.setTitle("Tree")
            Answer2.setTitle("Bush")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 334:
            Question.setText("How many tentacles does a squid have?")
            Answer1.setTitle("10")
            Answer2.setTitle("8")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 335:
            Question.setText("Who was the first to leave the spice girls?")
            Answer1.setTitle("Victoria Beckham")
            Answer2.setTitle("Geri Halliwell")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 336:
            Question.setText("Which band was Kerry McFadden in?")
            Answer1.setTitle("Atomic Kitten")
            Answer2.setTitle("Sugababes")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 337:
            Question.setText("Which bear wears a duffle coat?")
            Answer1.setTitle("Rupert")
            Answer2.setTitle("Paddington")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 338:
            Question.setText("Which of these is not a type of used in the English language?")
            Answer1.setTitle("Injuction")
            Answer2.setTitle("Preposition")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 339:
            Question.setText("Which mountain is over 3000 feet?")
            Answer1.setTitle("Fuji")
            Answer2.setTitle("K2")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 340:
            Question.setText("Which of these is an enemy of Batman?")
            Answer1.setTitle("False Face")
            Answer2.setTitle("Sandman")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 341:
            Question.setText("Which of these films does Jim Carrey appear in?")
            Answer1.setTitle("Arthur")
            Answer2.setTitle("The Dead Pool")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 342:
            Question.setText("Which of these is a variant of apple?")
            Answer1.setTitle("Alexander")
            Answer2.setTitle("Waldorf")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 343:
            Question.setText("Which player seeded in the top 32 at Wimbledon in 2009")
            Answer1.setTitle("Roland Gasquet")
            Answer2.setTitle("Fernando Gonzalez")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 344:
            Question.setText("Which of these in not a mountain range?")
            Answer1.setTitle("Stratos")
            Answer2.setTitle("Pelly")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 345:
            Question.setText("Which of these is a species of bear?")
            Answer1.setTitle("Corduroy")
            Answer2.setTitle("Kermode")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 346:
            Question.setText("Which film has Bruce Willis not appeared in?")
            Answer1.setTitle("In another Country")
            Answer2.setTitle("Bandits")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 347:
            Question.setText("With what letter does the longest lace name in Ireland begin?")
            Answer1.setTitle("B")
            Answer2.setTitle("M")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 348:
            Question.setText("When did the Flight of the Earls take place?")
            Answer1.setTitle("1607")
            Answer2.setTitle("1707")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 349:
            Question.setText("Around how many square Km is the island of Ireland?")
            Answer1.setTitle("104,000")
            Answer2.setTitle("84,000")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 350:
            Question.setText("Where is O’Skullvian’s Castle?")
            Answer1.setTitle("Killarney")
            Answer2.setTitle("Kilmoyley")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        default:
            Question.setText("Which of these metals is an alloy?")
            Answer1.setTitle("Bronze")
            Answer2.setTitle("Silver")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        }
    }
    
    func Pictures() {
        
        self.QuestionImage.setHidden(false)
        self.Question.setHidden(true)
        
        self.SepLabel.setHidden(false)
        self.SepLabel.setAlpha(1)
        
        var RandomQuestion = arc4random()%155
        
        let x = RandomQuestion
        
        if self.prev == Int(RandomQuestion) {
            repeat {
                RandomQuestion = arc4random()%155
                self.prev = Int(RandomQuestion)
            } while self.prev != Int(x)
        }
        
        self.prev = Int(RandomQuestion)
        
        switch RandomQuestion {
        case let RandomQuestion where RandomQuestion == 0:
            Answer1.setTitle("Mexico")
            Answer2.setTitle("Italy")
            QuestionImage.setImageNamed("CIThirtyFive.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 1:
            Answer1.setTitle("South Sudan")
            Answer2.setTitle("South Africa")
            QuestionImage.setImageNamed("CIOne.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 2:
            Answer1.setTitle("Argentina")
            Answer2.setTitle("Mexico")
            QuestionImage.setImageNamed("CITwo.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 3:
            Answer1.setTitle("New Zeland")
            Answer2.setTitle("United Kingdom")
            QuestionImage.setImageNamed("CIThree.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 4:
            Answer1.setTitle("Djibouti")
            Answer2.setTitle("Ethiopia")
            QuestionImage.setImageNamed("CIFour.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 5:
            Answer1.setTitle("Greenland")
            Answer2.setTitle("Brazil")
            QuestionImage.setImageNamed("CIFive.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 6:
            Answer1.setTitle("Germany")
            Answer2.setTitle("Hungary")
            QuestionImage.setImageNamed("CISix.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 7:
            Answer1.setTitle("Mongolia")
            Answer2.setTitle("Hong Kong")
            QuestionImage.setImageNamed("CISeven.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 8:
            Answer1.setTitle("Japan")
            Answer2.setTitle("Hawaii")
            QuestionImage.setImageNamed("CIEight.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 9:
            Answer1.setTitle("Banba")
            Answer2.setTitle("Nauru")
            QuestionImage.setImageNamed("CINine.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 10:
            Answer1.setTitle("France")
            Answer2.setTitle("Netherlands")
            QuestionImage.setImageNamed("CITen.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 11:
            Answer1.setTitle("USA")
            Answer2.setTitle("Malaysia")
            QuestionImage.setImageNamed("CIEleven.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 12:
            Answer1.setTitle("Bermuda")
            Answer2.setTitle("British Virgin Islands")
            QuestionImage.setImageNamed("CITwelve.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 13:
            Answer1.setTitle("Chad")
            Answer2.setTitle("Central African Republic")
            QuestionImage.setImageNamed("CIThirteen.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 14:
            Answer1.setTitle("Egypt")
            Answer2.setTitle("Yemen")
            QuestionImage.setImageNamed("CIFourteen.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 15:
            Answer1.setTitle("Iceland")
            Answer2.setTitle("Canada")
            QuestionImage.setImageNamed("CIFithteen.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 16:
            Answer1.setTitle("Greece")
            Answer2.setTitle("Turkey")
            QuestionImage.setImageNamed("CISixteen.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 17:
            Answer1.setTitle("Iraq")
            Answer2.setTitle("Iran")
            QuestionImage.setImageNamed("CISeventeen.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 18:
            Answer1.setTitle("Mexico")
            Answer2.setTitle("Italy")
            QuestionImage.setImageNamed("CIEighteen.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 19:
            Answer1.setTitle("Portugal")
            Answer2.setTitle("Spain")
            QuestionImage.setImageNamed("CINineteen.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 20:
            Answer1.setTitle("UAE")
            Answer2.setTitle("Iraq")
            QuestionImage.setImageNamed("CITwenty.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 21:
            Answer1.setTitle("Thailand")
            Answer2.setTitle("China")
            QuestionImage.setImageNamed("CITwentyOne.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 22:
            Answer1.setTitle("Kiribati")
            Answer2.setTitle("Banada")
            QuestionImage.setImageNamed("CITwentyTwo.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 23:
            Answer1.setTitle("Hong Kong")
            Answer2.setTitle("Kyrgyzstan")
            QuestionImage.setImageNamed("CITwentyThree.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 24:
            Answer1.setTitle("Moldova")
            Answer2.setTitle("Romania")
            QuestionImage.setImageNamed("CITwentyFour.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 25:
            Answer1.setTitle("France")
            Answer2.setTitle("Netheralnds")
            QuestionImage.setImageNamed("CITwentyFive.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 26:
            Answer1.setTitle("Norway")
            Answer2.setTitle("Denmark")
            QuestionImage.setImageNamed("CITwentySix.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 27:
            Answer1.setTitle("Sudan")
            Answer2.setTitle("Saudi Arabia")
            QuestionImage.setImageNamed("CITwentySeven.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 28:
            Answer1.setTitle("Swaziland")
            Answer2.setTitle("Lesotho")
            QuestionImage.setImageNamed("CITwentyEight.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 29:
            Answer1.setTitle("UK")
            Answer2.setTitle("USA")
            QuestionImage.setImageNamed("CITwentyNine.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 30:
            Answer1.setTitle("Yemen")
            Answer2.setTitle("Egypt")
            QuestionImage.setImageNamed("CIThirty.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 31:
            Answer1.setTitle("Netherlands")
            Answer2.setTitle("Russia")
            QuestionImage.setImageNamed("CIThirtyOne.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 32:
            Answer1.setTitle("Switzerland")
            Answer2.setTitle("Denamrk")
            QuestionImage.setImageNamed("CIThirtyTwo.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 33:
            Answer1.setTitle("New Zeland")
            Answer2.setTitle("Australia")
            QuestionImage.setImageNamed("CIThirtyThree.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 34:
            Answer1.setTitle("India")
            Answer2.setTitle("Pakistan")
            QuestionImage.setImageNamed("CIThirtyFour.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 35:
            Answer1.setTitle("Mexico")
            Answer2.setTitle("Italy")
            QuestionImage.setImageNamed("CIThirtyFive.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 36:
            Answer1.setTitle("Mexico")
            Answer2.setTitle("Italy")
            QuestionImage.setImageNamed("CIThirtyFive.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 37:
            Answer1.setTitle("Issac Newton")
            Answer2.setTitle("Nicola Tesla")
            QuestionImage.setImageNamed("POne.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 38:
            Answer1.setTitle("James Clark Maxwell")
            Answer2.setTitle("Charles Darwin")
            QuestionImage.setImageNamed("PTwo.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 39:
            Answer1.setTitle("Stephen Hawking")
            Answer2.setTitle("Albert Eingstien")
            QuestionImage.setImageNamed("PThree.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 40:
            Answer1.setTitle("Bill Gatesfal")
            Answer2.setTitle("Mark Zuckerberg")
            QuestionImage.setImageNamed("PFour.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 41:
            Answer1.setTitle("Albert Eingstien")
            Answer2.setTitle("Stephen Hawking")
            QuestionImage.setImageNamed("PFive.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 42:
            Answer1.setTitle("Steve Jobs")
            Answer2.setTitle("Bill Gates")
            QuestionImage.setImageNamed("PSix.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 43:
            Answer1.setTitle("Carl Gauss")
            Answer2.setTitle("Issac Newton")
            QuestionImage.setImageNamed("PSeven.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 44:
            Answer1.setTitle("James Gosling")
            Answer2.setTitle("Dennis Ritiche")
            QuestionImage.setImageNamed("PEight.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 45:
            Answer1.setTitle("Dustin Moskovitz")
            Answer2.setTitle("Chris Hughes")
            QuestionImage.setImageNamed("PNine.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 46:
            Answer1.setTitle("Tim Cook")
            Answer2.setTitle("Jony Ive")
            QuestionImage.setImageNamed("PTen.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 47:
            Answer1.setTitle("James Gosling")
            Answer2.setTitle("Dennis Ritiche")
            QuestionImage.setImageNamed("PEleven.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 48:
            Answer1.setTitle("Charles Babbage")
            Answer2.setTitle("Jon Neumann")
            QuestionImage.setImageNamed("PTwelve.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 49:
            Answer1.setTitle("Larray Page")
            Answer2.setTitle("Larray Ellison")
            QuestionImage.setImageNamed("PThirteen.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 50:
            Answer1.setTitle("Marie Curie")
            Answer2.setTitle("Rosalid Franklin")
            QuestionImage.setImageNamed("PFourteen.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 51:
            Answer1.setTitle("John Lasseter")
            Answer2.setTitle("Steve Wozniak")
            QuestionImage.setImageNamed("PFithteen.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 52:
            Answer1.setTitle("Ada Lovelace")
            Answer2.setTitle("Cleopatra")
            QuestionImage.setImageNamed("PSixteen.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 53:
            Answer1.setTitle("Tim Cook")
            Answer2.setTitle("Steve Jobs")
            QuestionImage.setImageNamed("PSeventeen.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 54:
            Answer1.setTitle("Alan Turing")
            Answer2.setTitle("Charles Babbage")
            QuestionImage.setImageNamed("PEighteen.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 55:
            Answer1.setTitle("Dong Nguyen")
            Answer2.setTitle("Markus Persson")
            QuestionImage.setImageNamed("PNineteen.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 56:
            Answer1.setTitle("Dmitri Mendeleev")
            Answer2.setTitle("James Maxwell")
            QuestionImage.setImageNamed("PTwenty.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 57:
            Answer1.setTitle("Marie Curie")
            Answer2.setTitle("Rosalid Franklin")
            
            QuestionImage.setImageNamed("PTwentyOne.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 58:
            Answer1.setTitle("Tim bernards Lee")
            Answer2.setTitle("Vint Cerf")
            QuestionImage.setImageNamed("PTwentyTwo.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 59:
            Answer1.setTitle("Rachel Carson")
            Answer2.setTitle("Sofia Kovalevskaya")
            QuestionImage.setImageNamed("PTwentyThree.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 60:
            Answer1.setTitle("Sergey Brin")
            Answer2.setTitle("Larray Page")
            QuestionImage.setImageNamed("PTwentyFour.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 61:
            Answer1.setTitle("Larray Ellison")
            Answer2.setTitle("Elon Musk")
            QuestionImage.setImageNamed("PTwentyFive.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 62:
            Answer1.setTitle("Marissa Mayer")
            Answer2.setTitle("Angela Ahrendts")
            QuestionImage.setImageNamed("PTwentySix.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 63:
            Answer1.setTitle("Anne Shelton")
            Answer2.setTitle("Vera Lynn")
            QuestionImage.setImageNamed("PTwentySeven.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 64:
            Answer1.setTitle("Mariah Carey")
            Answer2.setTitle("Madonna")
            QuestionImage.setImageNamed("PTwentyEight.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 65:
            Answer1.setTitle("Mariah Carey")
            Answer2.setTitle("Madonna")
            QuestionImage.setImageNamed("PTwentyNine.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 66:
            Answer1.setTitle("Lady Gaga")
            Answer2.setTitle("Katy Perry")
            QuestionImage.setImageNamed("PThirty.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 67:
            Answer1.setTitle("Lady Gaga")
            Answer2.setTitle("Katy Perry")
            QuestionImage.setImageNamed("PThirtyOne.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 68:
            Answer1.setTitle("Freddie Mercury")
            Answer2.setTitle("Bob Marley")
            QuestionImage.setImageNamed("PThirtyTwo.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 69:
            Answer1.setTitle("50 Cent")
            Answer2.setTitle("Eminem")
            QuestionImage.setImageNamed("PThirtyThree.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 70:
            Answer1.setTitle("Bob Marley")
            Answer2.setTitle("Freddie Mercury")
            QuestionImage.setImageNamed("PThirtyFour.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 71:
            Answer1.setTitle("Rihanna")
            Answer2.setTitle("Beyonce")
            QuestionImage.setImageNamed("PThirtyFive.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 72:
            Answer1.setTitle("Rihanna")
            Answer2.setTitle("Beyonce")
            QuestionImage.setImageNamed("PThirtySix.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 73:
            Answer1.setTitle("Motzart")
            Answer2.setTitle("Beethoven")
            QuestionImage.setImageNamed("PThirtySeven.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 74:
            Answer1.setTitle("Beetles")
            Answer2.setTitle("Queen")
            QuestionImage.setImageNamed("PThirtyEight.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 75:
            Answer1.setTitle("Whitney Houston")
            Answer2.setTitle("Adele")
            QuestionImage.setImageNamed("PThirtyNine.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 76:
            Answer1.setTitle("Whitney Houston")
            Answer2.setTitle("Adele")
            QuestionImage.setImageNamed("PFourty.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 77:
            Answer1.setTitle("Elvis Preasly")
            Answer2.setTitle("Michael Jackson")
            QuestionImage.setImageNamed("PFourtyOne.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 78:
            Answer1.setTitle("Taylor Swift")
            Answer2.setTitle("Beyonce")
            QuestionImage.setImageNamed("PFourtyTwo.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 79:
            Answer1.setTitle("Stanley Kubrick")
            Answer2.setTitle("Quentin Tarantino")
            QuestionImage.setImageNamed("PFourtyThree.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 80:
            Answer1.setTitle("Stanley Kubrick")
            Answer2.setTitle("Quentin Tarantino")
            QuestionImage.setImageNamed("PFourtyFour.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 81:
            Answer1.setTitle("Alfred Hitchcock")
            Answer2.setTitle("Charlie Chaplin")
            QuestionImage.setImageNamed("PFourtyFive.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 82:
            Answer1.setTitle("Christopher Nolan")
            Answer2.setTitle("David Fincher")
            QuestionImage.setImageNamed("PFourtySix.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 83:
            Answer1.setTitle("Charlie Chaplin")
            Answer2.setTitle("Alfred Hitchcock")
            QuestionImage.setImageNamed("PFourtySeven.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 84:
            Answer1.setTitle("David Fincher")
            Answer2.setTitle("JJAbrams")
            QuestionImage.setImageNamed("PFourtyEight.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 85:
            Answer1.setTitle("John Lasseter")
            Answer2.setTitle("JJAbrams")
            QuestionImage.setImageNamed("PFourtyNine.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 86:
            Answer1.setTitle("Sofja Wassiljewna")
            Answer2.setTitle("Sofia Coppola")
            QuestionImage.setImageNamed("PFithty.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 87:
            Answer1.setTitle("Emma Watson")
            Answer2.setTitle("Meryl Streep")
            QuestionImage.setImageNamed("PFithyOne.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 88:
            Answer1.setTitle("Samuel Jackson")
            Answer2.setTitle("Christian Bale")
            QuestionImage.setImageNamed("PFithyTwo.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 89:
            Answer1.setTitle("Keira Knightley")
            Answer2.setTitle("Emma Watson")
            QuestionImage.setImageNamed("PFithyThree.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 90:
            Answer1.setTitle("Morgan Freeman")
            Answer2.setTitle("Samuel Jackson")
            QuestionImage.setImageNamed("PFithyFour.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 91:
            Answer1.setTitle("Morgan Freeman")
            Answer2.setTitle("Samuel Jackson")
            QuestionImage.setImageNamed("PFithyFive.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 92:
            Answer1.setTitle("Meryl Streep")
            Answer2.setTitle("Judi Dench")
            QuestionImage.setImageNamed("PFithySix.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 93:
            Answer1.setTitle("Leonardo Dicaprio")
            Answer2.setTitle("Johnny Depp")
            QuestionImage.setImageNamed("PFithySeven.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 94:
            Answer1.setTitle("Helen Mirren")
            Answer2.setTitle("Cate Blanchett")
            QuestionImage.setImageNamed("PFithyEight.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 95:
            Answer1.setTitle("Tom Hanks")
            Answer2.setTitle("Tim Hanks")
            QuestionImage.setImageNamed("PFithyNine.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 96:
            Answer1.setTitle("Angelina Jolie")
            Answer2.setTitle("Meryl Streep")
            QuestionImage.setImageNamed("PSixty.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 97:
            Answer1.setTitle("J.F.Kennedy")
            Answer2.setTitle("Barack Obama")
            QuestionImage.setImageNamed("PSixtyOne.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 98:
            Answer1.setTitle("Napoleon")
            Answer2.setTitle("Alexander The Great")
            QuestionImage.setImageNamed("PSixtyTwo.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 99:
            Answer1.setTitle("Martin Luther King")
            Answer2.setTitle("Nelson Mandela")
            QuestionImage.setImageNamed("PSixtyThree.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 100:
            Answer1.setTitle("Queen Elizabeth II")
            Answer2.setTitle("Queen Elizabeth III")
            QuestionImage.setImageNamed("PSixtyFour.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 101:
            Answer1.setTitle("Claudette Colvin")
            Answer2.setTitle("Rosa Parks")
            QuestionImage.setImageNamed("PSixtyFive.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 102:
            Answer1.setTitle("Aung San Suu Kyi")
            Answer2.setTitle("Malala Yousafzai")
            QuestionImage.setImageNamed("PSixtySix.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 103:
            Answer1.setTitle("Mary Of Teck")
            Answer2.setTitle("Queen Victoria")
            QuestionImage.setImageNamed("PSixtySeven.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 104:
            Answer1.setTitle("Pope John Paul II")
            Answer2.setTitle("Pope Francis")
            QuestionImage.setImageNamed("PSixtyEight.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 105:
            Answer1.setTitle("Boris Yeltsin")
            Answer2.setTitle("Mikhail Gorbachev")
            QuestionImage.setImageNamed("PSixtyNine.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 106:
            Answer1.setTitle("Genghis Khan")
            Answer2.setTitle("Kublai Khan")
            QuestionImage.setImageNamed("PSeventy.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 107:
            Answer1.setTitle("Indira Gandhi")
            Answer2.setTitle("Mother Teresa")
            QuestionImage.setImageNamed("PSeventyOne.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 108:
            Answer1.setTitle("Martin Luther King")
            Answer2.setTitle("Mahatma Gandhi")
            QuestionImage.setImageNamed("PSeventyTwo.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 109:
            Answer1.setTitle("Angela Merkel")
            Answer2.setTitle("Margaret Thatcher")
            QuestionImage.setImageNamed("PSeventyThree.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 110:
            Answer1.setTitle("Malala Yousafzai")
            Answer2.setTitle("Mother Teresa")
            QuestionImage.setImageNamed("PSeventyFour.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 111:
            Answer1.setTitle("Nelson Mandela")
            Answer2.setTitle("Mahatma Gandhi")
            QuestionImage.setImageNamed("PSeventyFive.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 112:
            Answer1.setTitle("Kofi Annan")
            Answer2.setTitle("Ban Ki-moon")
            QuestionImage.setImageNamed("PSeventySix.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 113:
            Answer1.setTitle("Vladimir Lenin")
            Answer2.setTitle("Joseph Stalin")
            QuestionImage.setImageNamed("PSeventySeven.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 114:
            Answer1.setTitle("John F. Kennedy")
            Answer2.setTitle("Jack F. Kennedy")
            QuestionImage.setImageNamed("PSeventyEight.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 115:
            Answer1.setTitle("Subhas Bose")
            Answer2.setTitle("Jawaharlal Nehru")
            QuestionImage.setImageNamed("PSeventyNine.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 116:
            Answer1.setTitle("Indira Gandhi")
            Answer2.setTitle("Sonia Gandhi")
            QuestionImage.setImageNamed("PEighty.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 117:
            Answer1.setTitle("Heinrich Himmler")
            Answer2.setTitle("Adolf Hitler")
            QuestionImage.setImageNamed("PEightyOne.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 118:
            Answer1.setTitle("George Washington")
            Answer2.setTitle("Thomas Jefferson")
            QuestionImage.setImageNamed("PEightyTwo.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 119:
            Answer1.setTitle("Harry S. Truman")
            Answer2.setTitle("Franklin D. Roosevelt")
            QuestionImage.setImageNamed("PEightyThree.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 120:
            Answer1.setTitle("Emmeline Pankhurst")
            Answer2.setTitle("Christabel Pankhurst")
            QuestionImage.setImageNamed("PEightyFour.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 121:
            Answer1.setTitle("Anna Roosevelt")
            Answer2.setTitle("Eleanor Roosevelt")
            QuestionImage.setImageNamed("PEightyFive.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 122:
            Answer1.setTitle("Desmond Tutu")
            Answer2.setTitle("Jacob Zuma")
            QuestionImage.setImageNamed("PEightySix.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 123:
            Answer1.setTitle("Philippe Pétain")
            Answer2.setTitle("Charles de Gaulle")
            QuestionImage.setImageNamed("PEightySeven.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 124:
            Answer1.setTitle("Dalai Lama")
            Answer2.setTitle("Buddah")
            QuestionImage.setImageNamed("PEightyEight.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 125:
            Answer1.setTitle("Chiang Kai-shek")
            Answer2.setTitle("Mao Zedong")
            QuestionImage.setImageNamed("PEightyNine.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 126:
            Answer1.setTitle("Ban Ki-Moo")
            Answer2.setTitle("Kofi Annan")
            QuestionImage.setImageNamed("PNinety.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 127:
            Answer1.setTitle("Helen Keller")
            Answer2.setTitle("Amelia Earhart")
            QuestionImage.setImageNamed("PNinetyOne.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 128:
            Answer1.setTitle("Abraham Lincoln")
            Answer2.setTitle("William Lincoln")
            QuestionImage.setImageNamed("PNinetyTwo.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 129:
            Answer1.setTitle("Hirohito")
            Answer2.setTitle("Meiji Restoration")
            QuestionImage.setImageNamed("PNinetyThree.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 130:
            Answer1.setTitle("Winston Churchill")
            Answer2.setTitle("Neville Chamberlain")
            QuestionImage.setImageNamed("PNinetyFour.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 131:
            Answer1.setTitle("Dmitry Medvedev")
            Answer2.setTitle("Vladimir Putin")
            QuestionImage.setImageNamed("PNinetyFive.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 132:
            Answer1.setTitle("Angela Merkel")
            Answer2.setTitle("Christine Lagarde")
            QuestionImage.setImageNamed("PNinetySix.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 133:
            Answer1.setTitle("Charles Dickens")
            Answer2.setTitle("William Shakespeare")
            QuestionImage.setImageNamed("PNinetySeven.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 134:
            Answer1.setTitle("Leonardo da Vinci")
            Answer2.setTitle("Michelangelo")
            QuestionImage.setImageNamed("PNinetyEight.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 135:
            Answer1.setTitle("Augustus")
            Answer2.setTitle("Julius Caesar")
            QuestionImage.setImageNamed("PNinetyNine.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 136:
            Answer1.setTitle("Nikola Tesla")
            Answer2.setTitle("Albert Einstein")
            QuestionImage.setImageNamed("POneHundred.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 137:
            Answer1.setTitle("Sydney")
            Answer2.setTitle("Las Angeles")
            QuestionImage.setImageNamed("LOne.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 138:
            Answer1.setTitle("London")
            Answer2.setTitle("Singapore")
            QuestionImage.setImageNamed("LTwo.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 139:
            Answer1.setTitle("Seattle")
            Answer2.setTitle("Japan")
            QuestionImage.setImageNamed("LThree.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 140:
            Answer1.setTitle("Lisbon")
            Answer2.setTitle("San Francisco")
            QuestionImage.setImageNamed("LFour.png")
                
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 141:
            Answer1.setTitle("Barcelona")
            Answer2.setTitle("Madrid")
            QuestionImage.setImageNamed("LFive.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 142:
            Answer1.setTitle("Athens")
            Answer2.setTitle("Rome")
            QuestionImage.setImageNamed("LSix.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 143:
            Answer1.setTitle("Rio de Janeiro")
            Answer2.setTitle("São Paulo")
            QuestionImage.setImageNamed("LSeven.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 144:
            Answer1.setTitle("Las Vegas")
            Answer2.setTitle("Paris")
            QuestionImage.setImageNamed("LEight.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 145:
            Answer1.setTitle("Moscow")
            Answer2.setTitle("Riyadh")
            QuestionImage.setImageNamed("LNine.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 146:
            Answer1.setTitle("Beijing")
            Answer2.setTitle("Tokyo")
            QuestionImage.setImageNamed("LTen.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 147:
            Answer1.setTitle("Machu Picchu")
            Answer2.setTitle("Isla del Sol")
            QuestionImage.setImageNamed("LEleven.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 148:
            Answer1.setTitle("Rome")
            Answer2.setTitle("Athens")
            QuestionImage.setImageNamed("LTwelve.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 149:
            Answer1.setTitle("Giza")
            Answer2.setTitle("Cairo")
            QuestionImage.setImageNamed("LThirteen.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 150:
            Answer1.setTitle("Shanghai")
            Answer2.setTitle("Dubai")
            QuestionImage.setImageNamed("LFourteen.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 151:
            Answer1.setTitle("Mount Rushmore")
            Answer2.setTitle("Washington")
            QuestionImage.setImageNamed("LFithteen.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 152:
            Answer1.setTitle("Singapore")
            Answer2.setTitle("Chicago")
            QuestionImage.setImageNamed("LSixteen.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 153:
            Answer1.setTitle("Beijing")
            Answer2.setTitle("Shanghai")
            QuestionImage.setImageNamed("LSeventeen.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 154:
            Answer1.setTitle("Rome")
            Answer2.setTitle("Pisa")
            QuestionImage.setImageNamed("LEighteen.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        case let RandomQuestion where RandomQuestion == 155:
            Answer1.setTitle("London")
            Answer2.setTitle("Manchester")
            QuestionImage.setImageNamed("LNineteen.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        case let RandomQuestion where RandomQuestion == 156:
            Answer1.setTitle("Las Angeles")
            Answer2.setTitle("New York")
            QuestionImage.setImageNamed("LTwenty.png")
            
            IsAnswerOneRight = false
            IsAnswerTwoRight = true
            break
        default:
            Answer1.setTitle("Marie Curie")
            Answer2.setTitle("Rosalid Franklin")
            QuestionImage.setImageNamed("PFourteen.png")
            
            IsAnswerOneRight = true
            IsAnswerTwoRight = false
            break
        }
        
        if self.QuestionImage == nil {
            self.Pictures()
        }
    }
    
    @IBAction func AnswerOne() {
        if IsAnswerOneRight == true {
            Score = Score + 1
            Seperator.setColor(UIColor.greenColor())
            
        } else {
            Seperator.setColor(UIColor.redColor())
        }
        self.performSelector(#selector(InterfaceController.Revert), withObject: nil, afterDelay: 0.2)
        self.StartGame()
        PointsLabel.setText("Pts: \(Score)")
    }
    
    @IBAction func AnswerTwo() {
        if IsAnswerTwoRight == true {
            Score = Score + 1
            Seperator.setColor(UIColor.greenColor())
        } else {
            Seperator.setColor(UIColor.redColor())
        }
        self.performSelector(#selector(InterfaceController.Revert), withObject: nil, afterDelay: 0.2)
        self.StartGame()
        PointsLabel.setText("Pts: \(Score)")
    }
    
    func Revert() {
        
        Seperator.setColor(UIColor.darkGrayColor())
    }
    
    @IBAction func ReplayGame() {
        animateWithDuration(1) {
            
            self.Question.setHidden(false)
            self.Answer1.setHidden(false)
            self.Answer2.setHidden(false)
            self.Group.setHidden(false)
            self.Seperator.setHidden(false)
            self.PointsLabel.setHidden(false)
            
            self.Question.setAlpha(1)
            self.Answer1.setAlpha(1)
            self.Answer2.setAlpha(1)
            self.Group.setAlpha(1)
            self.QuestionImage.setAlpha(1)
            self.Seperator.setAlpha(1)
            self.PointsLabel.setAlpha(1)
            
            self.Replay.setAlpha(0)
            self.FinalImage.setAlpha(0)
            self.FinalScore.setAlpha(0)
            self.FinalScoreLabel.setAlpha(0)
        }
        
        self.breaker = 0
        
        self.momentpScoreOne = 0
        self.momentpScoreTwo = 0
        self.momentpScoreThree = 0
        self.momentpScoreFour = 0
        self.momentpScoreFive = 0
        self.momentpScoreSix = 0
        self.momentpScoreSeven = 0
        
        PointsLabel.setText("Pts: 000")
        
        self.GeneralKnowledge()
        self.Replay.setHidden(true)
        self.FinalImage.setHidden(true)
        self.FinalScore.setHidden(true)
        self.FinalScoreLabel.setHidden(true)
        
        self.CheatingLblOne.setHidden(true)
        self.CheatingLblOne.setAlpha(0)
        
        self.CheatingLblTwo.setHidden(true)
        self.CheatingLblTwo.setAlpha(0)
    }
    
    @IBAction func NewGame() {
        
        alreadyOpen = 1
        
        animateWithDuration(1) {
            
            self.Question.setHidden(false)
            self.Answer1.setHidden(false)
            self.Answer2.setHidden(false)
            self.Group.setHidden(false)
            self.Seperator.setHidden(false)
            self.PointsLabel.setHidden(false)
            
            self.Question.setAlpha(1)
            self.Answer1.setAlpha(1)
            self.Answer2.setAlpha(1)
            self.Group.setAlpha(1)
            self.QuestionImage.setAlpha(1)
            self.Seperator.setAlpha(1)
            self.PointsLabel.setAlpha(1)
            
            self.Question.setVerticalAlignment(.Top)
            self.Answer1.setVerticalAlignment(.Top)
            self.Answer2.setVerticalAlignment(.Top)
            self.Group.setVerticalAlignment(.Top)
            self.QuestionImage.setVerticalAlignment(.Top)
            self.Seperator.setVerticalAlignment(.Top)
            self.PointsLabel.setVerticalAlignment(.Top)
            
            self.Logo.setAlpha(0)
            self.Play.setAlpha(0)
            self.LowestLabel.setAlpha(0)
            self.HighestLabel.setAlpha(0)
            
            self.Logo.setVerticalAlignment(.Bottom)
            self.Play.setVerticalAlignment(.Bottom)
            self.HighestLabel.setVerticalAlignment(.Bottom)
            self.LowestLabel.setVerticalAlignment(.Bottom)
            
        }
        self.GeneralKnowledge()
        self.Logo.setHidden(true)
        self.Play.setHidden(true)
        self.HighestLabel.setHidden(true)
        self.LowestLabel.setHidden(true)
        
    }
    
    func Cheating() {
        
        self.Question.setAlpha(0)
        self.Answer1.setAlpha(0)
        self.Answer2.setAlpha(0)
        self.Group.setAlpha(0)
        self.QuestionImage.setAlpha(0)
        self.Seperator.setAlpha(0)
        self.PointsLabel.setAlpha(0)
        self.SepLabel.setAlpha(0)
        
        self.Question.setHidden(true)
        self.Answer1.setHidden(true)
        self.Answer2.setHidden(true)
        self.Group.setHidden(true)
        self.QuestionImage.setHidden(true)
        self.Seperator.setHidden(true)
        self.PointsLabel.setHidden(true)
        self.SepLabel.setHidden(true)
        
        self.CheatingLblOne.setHidden(false)
        self.CheatingLblOne.setAlpha(1)
        
        self.CheatingLblTwo.setHidden(false)
        self.CheatingLblTwo.setAlpha(1)
        
        self.Replay.setHidden(false)
        self.Replay.setAlpha(1)
       
        healthStore.endWorkoutSession(workoutSession)
        Score = 0
        percentScore = 0
        self.HeartRate = 0
        IsDone = 0
        
    }
}
