//
//  BillManager.swift
//  Roomies
//
//  Created by Keaton Burleson on 11/4/18.
//  Copyright © 2018 Keaton Burleson. All rights reserved.
//

import Foundation
import Firebase
import CodableFirebase

class BillManager {
    var apartmentManager: ApartmentManager? = nil
    var currentApartmentID = ""
    var currentApartment: Apartment? = nil
    var delegate: BillManagerDelegate? = nil
    var beforeUpdateCount = 0
    var billsListener: ListenerRegistration? = nil

    init(apartmentID: String, userManager: UserManager) {
        currentApartmentID = apartmentID
        apartmentManager = ApartmentManager(withUserManager: userManager)
        apartmentManager?.getApartmentForID(apartmentID: currentApartmentID) { (apartment) in
            self.currentApartment = apartment
            self.startWatchingBills()
        }
    }

    func startWatchingBills() {
        billsListener = Firestore.firestore().collection("bills").whereField("attachedApartmentID", isEqualTo: currentApartmentID).addSnapshotListener { (querySnapshot, error) in
            guard let snapshot = querySnapshot
                else {
                    return
            }

            snapshot.documentChanges.forEach { diff in
                let bill = try! FirebaseDecoder().decode(Bill.self, from: diff.document.data())
                if (diff.type == .added) {
                    self.delegate?.billAdded(addedBill: bill)
                    self.apartmentManager?.updateApartmentData(modificationType: .add, data: bill.billID, apartment: self.currentApartment!, key: "billIDs")
                }
                if (diff.type == .modified) {
                    self.delegate?.billChanged(changedBill: bill)
                }
                
                if (diff.type == .removed) {
                    self.delegate?.billRemoved(removedBill: bill)
                    self.apartmentManager?.updateApartmentData(modificationType: .remove, data: bill.billID, apartment: self.currentApartment!, key: "billIDs")
                }
            }
        }
    }

    func addBill(newBill: Bill) {
        let billData = try! FirebaseEncoder().encode(newBill) as! [String: Any]

        self.apartmentManager?.updateApartmentData(modificationType: .add, data: newBill.billID, apartment: self.currentApartment!, key: "billIDs")
        Firestore.firestore().collection("bills").document(newBill.billID).setData(billData)
    }

    func removeBill(removedBill: Bill) {
        self.apartmentManager?.updateApartmentData(modificationType: .remove, data: removedBill.billID, apartment: self.currentApartment!, key: "billIDs")
        Firestore.firestore().collection("bills").document(removedBill.billID).delete()
    }

    func updateBill(modifiedBill: Bill) {
        self.apartmentManager?.updateApartmentData(modificationType: .update, data: modifiedBill.billID, apartment: self.currentApartment!, key: "billIDs")
    }


}

protocol BillManagerDelegate {
    func billRemoved(removedBill: Bill)
    func billAdded(addedBill: Bill)
    func billChanged(changedBill: Bill)
}
