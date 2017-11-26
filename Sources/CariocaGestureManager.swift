//
//  CariocaGestureManager.swift
//  CariocaMenu
//
//  Created by Arnaud Schloune on 21/11/2017.
//  Copyright © 2017 CariocaMenu. All rights reserved.
//

import Foundation
import UIKit

///Selector shortcuts, used for gestures
fileprivate extension Selector {
    ///Gesture for panning from any screen edge
    static let pannedFromScreenEdge = #selector(CariocaGestureManager.panGestureEvent(_:))
}

///Manages all the gestures
class CariocaGestureManager {
    ///The hostview of the menu
    let hostView: UIView
    ///The menu's controller
    let controller: CariocaController
    ///The edges of the menu
    let edges: [UIRectEdge]
    ///The menu's opening edge
    let openingEdge: UIRectEdge
    ///The edge gestures
    let edgePanGestures: [UIScreenEdgePanGestureRecognizer] = []
    ///The events delegate
    weak var delegate: CariocaGestureManagerDelegate?
    ///The Y position in which the ScreenEdgePan started.
    var originalScreeenEdgePanY: CGFloat = 0.0
    ///The menu's container
    let container: CariocaMenuContainerView

    ///Initialises the gesture manager
    ///- Parameter hostView: The menu's host view
    ///- Parameter controller: The menu's content controller
    ///- Parameter edges: The menu's edges
    ///- Parameter container: The menu's container view
    init(hostView: UIView,
         controller: CariocaController,
         edges: [UIRectEdge],
         container: CariocaMenuContainerView) {
        //TODO: Check that the edges are only .left or .right, as they are the only supported
        self.hostView = hostView
        self.controller = controller
        self.edges = edges
        self.openingEdge = edges.first!
        self.container = container
        makeEdgePanGestures()
    }

    ///Create the required gestures depending on the edges
    func makeEdgePanGestures() {
        edges.forEach { edge in
            let panGesture = UIScreenEdgePanGestureRecognizer(target: self,
                                                              action: .pannedFromScreenEdge)
            panGesture.edges = edge
            hostView.addGestureRecognizer(panGesture)
        }
    }
    ///Pan gesture event received
    ///- Parameter gesture: UIScreenEdgePanGestureRecognizer
    @objc func panGestureEvent(_ gesture: UIScreenEdgePanGestureRecognizer) {
        let yLocation = gesture.location(in: gesture.view).y
        let frameHeight = hostView.frame.height
        let yRange: ClosedRange<CGFloat> = 20.0...frameHeight - container.menuHeight
        // TODO: Find the matching indicator view based on the edge
        if gesture.state == .began {
            delegate?.willOpenFromEdge(edge: gesture.edges)
            originalScreeenEdgePanY = yLocation
        }
        var matchingIndex = 0
        if gesture.state == .changed {
            delegate?.showMenu()
            /*
             showMenu()
             showIndicatorOnTopOfMenu(openingEdge)
             */
            let topY = CariocaGestureManager.topYConstraint(yLocation: yLocation,
                                                            originalScreeenEdgePanY: originalScreeenEdgePanY,
                                                            menuHeight: container.menuHeight,
                                                            heightForRow: controller.heightForRow(),
                                                            selectedIndex: delegate?.selectedIndex ?? 0,
                                                            yRange: yRange,
                                                            isOffscreenAllowed: true)
            container.topConstraint.constant = topY
            delegate?.didUpdateY(topY)
            matchingIndex = CariocaGestureManager.matchingIndex(yLocation: yLocation,
                                                                menuYPosition: topY,
                                                                menuItemHeight: controller.heightForRow(),
                                                                numberOfMenuItems: controller.numberOfRows(controller.tableView))
            delegate?.didUpdateSelectionIndex(matchingIndex)
        }
        if gesture.state == .ended {
            delegate?.didSelectItem(at: matchingIndex)
            delegate?.hideMenu()
        }
        if gesture.state == .failed { CariocaMenu.log("Failed : \(gesture)") }
        if gesture.state == .possible { CariocaMenu.log("Possible : \(gesture)") }
        if gesture.state == .cancelled { CariocaMenu.log("cancelled : \(gesture)") }
    }

    // swiftlint:disable function_parameter_count
    ///Calculates the y top constraint, to move the menu
    ///- Parameter yLocation: The gesture's location
    ///- Parameter originalScreenEdgePanY: The Y location where the gesture started
    ///- Parameter menuHeight: The total menu height
    ///- Parameter heightForRow: The height of each menu item
    ///- Parameter selectedIndex: The menu's previously selected index
    ///- Parameter yRange: The y range representing the top/bottom Y limits where the menu can go
    ///- Parameter isOffscreenAllowed: Can the menu go out of the screen ?
    ///- Returns: CGFloat: The new menu's Y position
    class func topYConstraint(yLocation: CGFloat,
                              originalScreeenEdgePanY: CGFloat,
                              menuHeight: CGFloat,
                              heightForRow: CGFloat,
                              selectedIndex: Int,
                              yRange: ClosedRange<CGFloat>,
                              isOffscreenAllowed: Bool) -> CGFloat {

        var yPosition = originalScreeenEdgePanY
            - (heightForRow * CGFloat(selectedIndex))
            - (heightForRow / 2.0)
            + originalScreeenEdgePanY - yLocation

        if !isOffscreenAllowed {
            if yPosition < yRange.lowerBound {
                yPosition = yRange.lowerBound
            } else if yPosition > yRange.upperBound {
                yPosition = yRange.upperBound
            }
        }
        return yPosition
    }
    // swiftlint:enable function_parameter_count

    ///Calculates the menu's matching index based on Y position
    ///- Parameter yLocation: The gesture's location
    ///- Parameter :
    ///- Parameter :
    ///- Parameter :
    ///- Returns: CGFloat: The new menu's Y position
    class func matchingIndex(yLocation: CGFloat,
                             menuYPosition: CGFloat,
                             menuItemHeight: CGFloat,
                             numberOfMenuItems: Int) -> Int {
        var matchingIndex = Int(floor((yLocation - menuYPosition) / menuItemHeight))
        //check if < 0 or > numberOfMenuItems
        matchingIndex = (matchingIndex < 0) ?
            0 : ((matchingIndex > numberOfMenuItems - 1) ? (numberOfMenuItems - 1) : matchingIndex)
        return matchingIndex
    }
}