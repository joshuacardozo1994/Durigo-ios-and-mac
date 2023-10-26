//
//  Bill.swift
//  pdf test
//
//  Created by Joshua Cardozo on 14/10/23.
//

import SwiftUI

struct Bill: View {
    let currentMenuItems: [MenuItem]
    var first = true
    var finalTotal: Int?
    var body: some View {
        VStack() {
            if first {
                HStack {
                    Spacer()
                    Text("Durigo's")
                        .font(.custom("DancingScript-Bold", size: 45))
                    Spacer()
                    
                }
                .overlay(alignment: .topTrailing) {
                    Text("Date: \(Date().getTimeInFormat(dateStyle: .short, timeStyle: .none))")
                        .font(.system(size: 11))
                }
                
                Text("+91 9545925489")
                    .font(.system(size: 11))
                Text("Grande Vanelim Colva ")
                    .font(.system(size: 11))
                    .padding(.bottom)
            } else {
                Spacer()
                    .frame(height: 60)
            }
            VStack(spacing: 4) {
                ForEach(currentMenuItems) { item in
                    HStack {
                        Text("\(item.quantity)")
                            .bold()
                        Text("\(item.name)")
                        Spacer()
                        Text("₹\(item.price*item.quantity)")
                    }
                }
                .font(.system(size: 12))
            }
            
            if let finalTotal {
                Divider()
                
                //            Spacer()
                VStack {
                    HStack(alignment: .center) {
                        Text("Total: ₹\(finalTotal)")
                            .font(.system(size: 20))
                            .bold()
                        //"upi://pay?pa=9545925489@okbizaxis&pn=Durigo&am=\(String(currentMenuItems.getTotal())).00"
                        if let uiImage = "upi://pay?pa=9545925489@okbizaxis&pn=Durigo".getQRCodeImage() {
                            Image(uiImage: uiImage)
                                .resizable()
                                .frame(width: 50, height: 50)
                            
                            
                        }
                    }
                    
                    
                }
                Spacer()
                Text("Thank you for dining with us! 😀")
                    .font(.custom("DancingScript-Regular", size: 20))
                
                
            } else {
                Spacer()
            }
            
        }
        .padding()
        .foregroundColor(.black)
    }
}

struct Bill_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            Bill(currentMenuItems: [
                MenuItem(id: 0, name: "Soda", quantity: 1, price: 20),
                MenuItem(id: 1, name: "Fresh Lemon Soda", quantity: 2, price: 90),
                MenuItem(id: 2, name: "Virgin Mojito", quantity: 1, price: 220),
                MenuItem(id: 3, name: "Chonok", quantity: 1, price: 500),
                MenuItem(id: 4, name: "Chilli Chicken", quantity: 2, price: 250),
                MenuItem(id: 5, name: "Chicken Pulao", quantity: 1, price: 200),
                MenuItem(id: 6, name: "Beef Soup", quantity: 1, price: 160),
                MenuItem(id: 7, name: "Mackerel", quantity: 2, price: 180),
                MenuItem(id: 8, name: "Ice Cream", quantity: 1, price: 100),
                MenuItem(id: 9, name: "Caramel Pudding", quantity: 1, price: 100),
                MenuItem(id: 10, name: "Pankcakes", quantity: 2, price: 100),
                MenuItem(id: 11, name: "Item 12", quantity: 1, price: 100),
                MenuItem(id: 12, name: "Item 13", quantity: 1, price: 100),
                MenuItem(id: 13, name: "Item 14", quantity: 1, price: 100),
                MenuItem(id: 14, name: "Item 15", quantity: 1, price: 100),
                MenuItem(id: 15, name: "Item 16", quantity: 1, price: 100),
                MenuItem(id: 16, name: "Item 17", quantity: 1, price: 100),
                MenuItem(id: 17, name: "Item 18", quantity: 1, price: 100),
                MenuItem(id: 18, name: "Item 19", quantity: 1, price: 100),
                MenuItem(id: 19, name: "Item 20", quantity: 1, price: 100)
            ], first: true, finalTotal: 270)
                .frame(width: 420, height: 595)
                .background(Color.white)
            Spacer()
        }
        .background(Color.gray)
    }
}
