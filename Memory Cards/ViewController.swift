//
//  ViewController.swift
//  Memory Cards
//
//  Created by Danny Tsang on 8/5/21.
//

import UIKit

enum CardState {
    case normal, flipped, matched
}

class Card {
    var word: String
    var state: CardState
    
    init(word:String, state: CardState = .normal) {
        self.word = word
        self.state = state
    }
}

class ViewController: UIViewController {

    var cardsArray = [Card]()
    var buttonArray = [UIButton]()
    var labelArray = [UILabel]()
    var cardsFlipped = 0

    var wait: Bool = false
    var cheatActivated: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        title = "Memori-"
        
        // Setup Interface
        let restartButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(restartGameButton))
        navigationItem.leftBarButtonItem = restartButton

        let cheatButton = UIBarButtonItem(barButtonSystemItem: .organize, target: self, action: #selector(activateCheat))
        navigationItem.rightBarButtonItem = cheatButton

        
        // Setup Game
        generateCards()
        drawCards()
        
        
        
    }
    
    func generateCards() {
        let dictionary = [
            "😀":"😀",
            "🤪":"🤪",
            "😄":"😄",
            "😆":"😆",
            "😅":"😅",
            "😂":"😂",
            "🤣":"🤣",
            "😍":"😍"
        ]
        
        let allKeys = dictionary.keys

        for key in allKeys{
            let cardA = Card(word: key)
            let cardB = Card(word: dictionary[key]!)
            cardsArray.append(cardA)
            cardsArray.append(cardB)
        }
        print(cardsArray)
        
        cardsArray.shuffle()
    }
    

    func drawCards() {
        
        // Create a 4x4 grid of cards spaced evenly through the screen.
        let spacer = 10
        let yOffset = 100
        
        let cardWidth = (Int(self.view.frame.width) - (5 * spacer)) / 4
        let cardHeight = cardWidth + cardWidth/2
        
        for row in 0 ..< 4 {
            for col in 0 ..< 4 {
                let cardIndex = (row * 4) + col + 1
                
                let x = (col * cardWidth) + (spacer * col) + spacer
                let y = yOffset + (row * cardHeight) + (spacer * row) + spacer
                
                let labelView = UIView(frame: CGRect(x: x, y: y, width: cardWidth, height: cardHeight))
                view.addSubview(labelView)
                
                let label = UILabel(frame: CGRect(x: 0, y: 0, width: cardWidth, height: cardHeight))
                label.text = "\(cardsArray[cardIndex - 1].word)"
                label.textAlignment = .center
                label.font = UIFont.systemFont(ofSize: 50)
                label.backgroundColor = UIColor.red
                label.tag = cardIndex
                labelView.addSubview(label)
                labelArray.append(label)
                
                let button = UIButton(frame: CGRect(x: 0, y: 0, width: cardWidth, height: cardHeight))
                button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
//                button.setTitle("\(cardsArray[cardIndex - 1].word)", for: .normal)
                button.tag = cardIndex
                button.backgroundColor = UIColor.blue
                labelView.addSubview(button)
                buttonArray.append(button)

            }
        }
    }

    @objc func buttonTapped(sender:UIButton) {
        // Disallow taps if we are in waiting for animation or a check to complete.
        if wait == true || cardsFlipped == 2 {
            return
        }
//        print("Button Tapped - \(sender.tag)")
        let index = sender.tag - 1
        
        // Check if card is already flipped or matched
        if cardsArray[index].state != .normal {
            return
        }
        
        // Check which turn this is.
        if cardsFlipped < 2 {
            // Flip the card by updating the button text.
            flipCard(at: index)
            cardsArray[index].state = .flipped
            cardsFlipped += 1
        }

        // If 2 cards are now flipped check if there is a match.
        if cardsFlipped == 2 {
            checkMatch()
        }
        
    }
    
    func flipCard(at index:Int) {
        wait = true
        DispatchQueue.main.async { [weak self] in
            guard let labelParentView = self?.labelArray[index] else { return }
            guard let button = self?.buttonArray[index] else { return }
            UIView.transition(from: button, to: labelParentView, duration: 0.5, options: [.transitionFlipFromRight, .showHideTransitionViews]) { _ in
//                button.setTitle("\(self?.cardsArray[index].word ?? "")", for: .normal)
                self?.wait = false
            }
        }
    }
    
    func flipCardBack(at index:Int, delay:TimeInterval = 0.0) {
        wait = true
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let labelParentView = self?.labelArray[index] else { return }
            guard let button = self?.buttonArray[index] else { return }
            UIView.transition(from: labelParentView, to: button, duration: 0.5, options: [.transitionFlipFromLeft, .showHideTransitionViews]) { _ in
//                button.setTitle("\(self?.cardsArray[index].word ?? "")", for: .normal)
                self?.wait = false
            }
        }
    }
    
    func checkMatch () {
        // Get the two cards that are flipped.
        var cardA: Card?
        var cardB: Card?
        
        var indexA: Int?
        var indexB: Int?
        
        for (index, card) in cardsArray.enumerated() {
            if card.state == .flipped {
                if cardA == nil {
                    cardA = card
                    indexA = index
                } else {
                    cardB = card
                    indexB = index
                    break
                }
            }
        }
        
        // Ensure we found two cards in the cards array.
        guard let cardA = cardA else { return }
        guard let cardB = cardB else { return }
        guard let indexA = indexA else { return }
        guard let indexB = indexB else { return }
        
        let labelA = labelArray[indexA]
        let labelB = labelArray[indexB]
        
        // Check if the two cards match.
        // If Match, leave the cards alone, and disable them.
        // If not, flip both cards back over by changing the text back to the tag.
        if cardA.word == cardB.word {
            //Match Found
            cardA.state = .matched
            cardB.state = .matched
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                labelA.backgroundColor = UIColor.green
                labelB.backgroundColor = UIColor.green
                
                // Reset flipped cards count.
                self?.cardsFlipped = 0

                // Check if the game is over.
                self?.checkGameOver()
                self?.wait = false
            }
        } else {
            cardA.state = .normal
            cardB.state = .normal
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                // Reset cards flipped.
                self?.flipCardBack(at: indexA, delay: 0)
                self?.flipCardBack(at: indexB, delay: 0.2)
                self?.cardsFlipped = 0
                
                self?.wait = false
            }
        }
    }
    
    func checkGameOver() {
        for card in cardsArray {
            if card.state == .normal || card.state == .flipped {
                return
            }
        }
        
        let ac = UIAlertController(title: "You Win!", message: nil, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Restart", style: .default, handler:restartGameAction))
        present(ac, animated: true)
    }
    
    func restartGameAction(action: UIAlertAction) {
        restartGame()
    }
    
    @objc func restartGameButton() {
        restartGame()
    }
    
    func restartGame() {
        for (index, card) in cardsArray.enumerated() {
            if card.state != .normal {
                flipCardBack(at: index, delay: Double.random(in: 0.0 ... 0.5))
                card.state = .normal
            }
        }
        
        cardsArray.shuffle()
        
        for (index, label) in labelArray.enumerated() {
            label.text = "\(cardsArray[index].word)"
            label.backgroundColor = UIColor.red
        }

    }
    
    @objc func activateCheat() {

        cheatActivated = !cheatActivated

        for (index, button) in buttonArray.enumerated() {
            if cheatActivated {
                button.setTitle("\(cardsArray[index].word)", for: .normal)
            } else {
                button.setTitle("", for: .normal)
            }
        }
        
    }
}

