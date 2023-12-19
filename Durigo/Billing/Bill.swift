//
//  Bill.swift
//  pdf test
//
//  Created by Joshua Cardozo on 14/10/23.
//

import SwiftUI

struct ThankYouMessages {
    static let messages = [
        "We're grateful for your visit and look forward to serving you again.",
        "Thank you for choosing us for your meal today.",
        "It was a pleasure to host you at our table.",
        "We hope you enjoyed your dining experience with us.",
        "Your patronage is appreciated. We can't wait to welcome you back!",
        "Thank you for your support. We hope to delight you again soon.",
        "We're thrilled you dined with us. Thank you!",
        "Thank you for being our guest. We hope your experience was memorable.",
        "Thank you for allowing us to serve you today.",
        "We value your visit and hope to see you again very soon."
    ]
    
    static func getRandomMessage() -> String {
        messages.randomElement() ?? "Thank you for dining with us"
    }
}

struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        return path
    }
}

struct Bill: View {
    let currentMenuItems: [MenuItem]
    let tableNumber: Int?
    var first = true
    var finalTotal: Int?
    var body: some View {
        VStack() {
            if first {
                HStack {
                    Spacer()
                    Text("Durigo's")
                        .font(.dancingScriptBold(size: 45))
                    Spacer()
                    
                }
                .overlay(alignment: .topTrailing) {
                    Text("Date: \(Date().getTimeInFormat(dateStyle: .short, timeStyle: .none))")
                        .font(.system(size: 11))
                }
                .overlay(alignment: .topLeading) {
                    if let tableNumber {
                        Text("Table: \(tableNumber)")
                            .font(.system(size: 11))
                    }
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
                    HStack(alignment: .bottom) {
                        Text("\(item.quantity)")
                            .bold()
                        if let servingSize = item.servingSize, servingSize.shouldDisplay {
                            Text(servingSize.name)
                                .bold()
                        }
                        if let prefix = item.prefix {
                            Text(prefix)
                        }
                        Text("\(item.name)")
                        VStack{
                            Line()
                                .stroke(style: StrokeStyle(lineWidth: 0.5, dash: [5]))
                                .frame(height: 0.5)
                                .opacity(0.4)
                                .padding(.bottom, 3)
                            
                        }
                        Text("₹\(item.price*item.quantity)")
                    }
                }
                .font(.system(size: 12))
            }
            
            if let finalTotal {
                VStack {
                    HStack(alignment: .center) {
                        Text("Total: ₹\(finalTotal)")
                            .font(.system(size: 20))
                            .bold()
                        //"upi://pay?pa=9545925489@okbizaxis&pn=Durigo&am=\(String(currentMenuItems.getTotal())).00"
                        if let uiImage = "upi://pay?pa=9545925489@okbizaxis&pn=Durigo".getQRCodeImage() {
                            #if os(iOS)
                            Image(uiImage: uiImage)
                                .resizable()
                                .frame(width: 50, height: 50)
                            #endif
                            
                        }
                    }
                    
                    
                }
                Spacer()
                Text(ThankYouMessages.getRandomMessage())
                    .font(.custom("DancingScript-Regular", size: 18))
                    .padding(.bottom, 8)
                
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
                MenuItem(id: UUID(), name: "Soda", quantity: 1, price: 20),
                MenuItem(id: UUID(), name: "Fresh Lemon Soda", quantity: 2, price: 90),
                MenuItem(id: UUID(), name: "Virgin Mojito", quantity: 1, price: 220),
                MenuItem(id: UUID(), name: "Chonok", quantity: 1, price: 500),
                MenuItem(id: UUID(), name: "Chilli Chicken", quantity: 2, price: 250),
                MenuItem(id: UUID(), name: "Chicken Pulao", quantity: 1, price: 200),
                MenuItem(id: UUID(), name: "Beef Soup", quantity: 1, price: 160),
                MenuItem(id: UUID(), name: "Mackerel", quantity: 2, price: 180),
                MenuItem(id: UUID(), name: "Ice Cream", quantity: 1, price: 100),
                MenuItem(id: UUID(), name: "Caramel Pudding", quantity: 1, price: 100),
                MenuItem(id: UUID(), name: "Pankcakes", quantity: 2, price: 100),
                MenuItem(id: UUID(), name: "Item 12", quantity: 1, price: 100),
                MenuItem(id: UUID(), name: "Item 13", quantity: 1, price: 100),
                MenuItem(id: UUID(), name: "Item 14", quantity: 1, price: 100),
                MenuItem(id: UUID(), name: "Item 15", quantity: 1, price: 100),
                MenuItem(id: UUID(), name: "Item 16", quantity: 1, price: 100),
                MenuItem(id: UUID(), name: "Item 17", quantity: 1, price: 100),
                MenuItem(id: UUID(), name: "Item 18", quantity: 1, price: 100),
                MenuItem(id: UUID(), name: "Item 19", quantity: 1, price: 100),
//                MenuItem(id: UUID(), name: "Item 20", quantity: 1, price: 100)
            ], tableNumber: 9, first: true, finalTotal: 420)
                .frame(width: 420, height: 595)
                .background(Color.white)
            Spacer()
        }
        .background(Color.gray)
    }
}
