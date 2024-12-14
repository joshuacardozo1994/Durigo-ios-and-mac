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
    
    static let christmasMessages = [
        "Thanks for joining us during this special season. Merry Christmas! 🎄",
        "Merry Christmas! Your choice brightened our day. 🎄",
        "We truly enjoyed hosting you during this festive time. Merry Christmas! 🎄",
        "We hope your dining experience was wonderful. Merry Christmas! 🎄",
        "Your visit means a lot to us, especially during this holiday. Merry Christmas! 🎄",
        "We extend our heartfelt thanks for your support. Merry Christmas! 🎄",
        "We're absolutely thrilled that you dined with us this Christmas season. Merry Christmas! 🎄",
        "Merry Christmas! We hope your experience with us was truly memorable. 🎄",
        "Thanks for choosing us to celebrate this Christmas. Merry Christmas! 🎄",
        "Your visit is a gift to us this holiday season. Merry Christmas! 🎄"
    ]
    
    static let newYearMessages = [
        "Thank you for ringing in the New Year with us! Cheers to a wonderful year ahead. 🎉",
        "Happy New Year! Your presence made our celebration even more special. 🎊",
        "We're delighted to have hosted you as we welcomed the New Year. Cheers to new beginnings! 🎉",
        "May your New Year be filled with joy and prosperity. Thank you for celebrating with us! 🎊",
        "Your visit added sparkle to our New Year's celebration. Wishing you a year of happiness! 🎉",
        "We're grateful for your support and company as we step into the New Year. Happy New Year! 🎊",
        "Celebrating the New Year was more memorable with you. Wishing you all the best in the year to come! 🎉",
        "Happy New Year! We hope your time with us was the perfect start to a fantastic year. 🎊",
        "Thank you for choosing to welcome the New Year with us. May it bring you endless joy and success! 🎉",
        "Your presence was the highlight of our New Year's celebration. Wishing you a prosperous year ahead! 🎊"
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

extension Bill {
    struct SnowFlake: View {
        var body: some View {
            Image(systemName: "snowflake")
                .foregroundStyle(Color(hex: "#6889b8"))
                .opacity(0.2)
                .font(.system(size: 50))
        }
    }
}

struct Bill: View {
    let currentMenuItems: [MenuItem]
    let tableNumber: Int?
    var first = true
    var finalTotal: Int?
    @State private var maxWidth: CGFloat = 0
    
    func itemText(item: MenuItem) -> Text {
        var textArr = [Text("")]
        
        if item.servingSize?.shouldDisplay == true {
            textArr.append(Text(" \(item.servingSize?.name ?? "")").bold())
        }
        
        if let prefix = item.prefix {
            textArr.append(Text(" \(prefix)").bold())
        }
        
        textArr.append(Text(" \(item.name)"))
        
        return textArr.reduce(Text("")) { $0 + $1 }
    }
    
    var body: some View {
            VStack() {
                if first {
                    HStack {
                        Spacer()
                        Text("Durigo's")
                            .font(.dancingScriptBold(size: 45))
//                            .overlay {
//                                Image(.christmasBells)
//                                    .resizable()
//                                    .aspectRatio(contentMode: .fit)
//                                    .offset(x: -100)
//                            }
//                            .overlay {
//                                Image(.christmasBells)
//                                    .resizable()
//                                    .aspectRatio(contentMode: .fit)
//                                    .offset(x: 100)
//                            }
                        Spacer()
                        
                    }
                    .overlay(alignment: .topTrailing) {
                        Text("Date: \(Date().getTimeInFormat(dateStyle: .short, timeStyle: .none))")
                            .font(.system(size: 11))
                    }
                    .overlay(alignment: .topLeading) {
                        if let tableNumber {
                            if tableNumber == 0 {
                                Text("Parcel")
                                    .font(.system(size: 11))
                            } else {
                                Text("Table: \(tableNumber)")
                                    .font(.system(size: 11))
                            }
                            
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
                                Text("\(item.quantity.formatNumberWithFraction())").bold()
                                .background(
                                                            GeometryReader { geometry in
                                                                Color.clear.onAppear {
                                                                    let textWidth = geometry.size.width
                                                                    if textWidth > maxWidth {
                                                                        maxWidth = textWidth
                                                                    }
                                                                }
                                                            }
                                                        )
                                                        .frame(minWidth: maxWidth, alignment: .leading)
                            
                                
                                
                            itemText(item: item)
                                .layoutPriority(1)
                            VStack{
                                Line()
                                    .stroke(style: StrokeStyle(lineWidth: 0.5, dash: [5]))
                                    .frame(height: 0.5)
                                    .opacity(0.4)
                                    .padding(.bottom, 3)
                                
                            }
                            Text("₹\(Int(item.price*item.quantity))")
                        }
                    }
                    .font(.system(size: 12))
                }
                
                if let finalTotal {
                        HStack(alignment: .center) {
                            Text("Total: ₹\(finalTotal)")
                                .font(.system(size: 20))
                                .bold()
                            //"upi://pay?pa=9545925489@okbizaxis&pn=Durigo&am=\(String(currentMenuItems.getTotal())).00"
                            if let uiImage = "upi://pay?ver=01&mode=1&pa=88117166@idfcbank&pn=DURIGOBARANDRESTAURANT&tr=STQ241211070222532I024331&mc=5812&qrMedium=03".getQRCodeImage() {
#if os(iOS)
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .frame(width: 50, height: 50)
#endif
                                
                            }
//                            Image(.snowman)
//                                .resizable()
//                                .aspectRatio(contentMode: .fit)
//                                .frame(width: 50, height: 50)
                        }
                        
                        
                    
                    Spacer()
                    Text(ThankYouMessages.getRandomMessage())
                        .font(.dancingScriptRegular(size: 18))
                        .padding(.bottom, 8)
                    
                } else {
                    Spacer()
                }
                
            }
            .padding()
            .foregroundColor(.black)
//            VStack(spacing: 40) {
//                Spacer()
//                    .frame(height: 70)
//                ForEach(0...currentMenuItems.count/6, id: \.self) { _ in
//                    
//                    SnowFlake()
//                        .offset(x: CGFloat(Int.random(in: -100...100)))
//                }
//                Spacer()
//            }
        
    }
}

struct Bill_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            HStack { Spacer() }
            Spacer()
            Bill(currentMenuItems: [
                MenuItem(id: UUID(), name: "Soda", quantity: 1.5, price: 20),
                MenuItem(id: UUID(), name: "Fresh Lemon Soda", quantity: 2, price: 90),
                MenuItem(id: UUID(), name: "Virgin Mojito", quantity: 1, price: 220),
                MenuItem(id: UUID(), name: "Chonok", quantity: 1, price: 500),
                MenuItem(id: UUID(), name: "Chilli Chicken", quantity: 2.5, price: 250),
                MenuItem(id: UUID(), name: "Chicken Pulao", quantity: 1, price: 200),
                MenuItem(id: UUID(), name: "Ice Cream (Single scoop)", quantity: 1, price: 160),
                MenuItem(id: UUID(), name: "Chocolate Brownie (With ice-cream)", quantity: 2, price: 180),
                MenuItem(id: UUID(), name: "Chicken Soup", prefix: "1 by 2", quantity: 2, price: 180),
                MenuItem(id: UUID(), name: "Some drink", prefix: nil, suffix: nil, quantity: 2.5, price: 40, servingSize: Category.Item.ServingSize(id: UUID(), name: "peg", expression: "x", description: "something", shouldDisplay: true))
//                MenuItem(id: UUID(), name: "Ice Cream", quantity: 1, price: 100),
//                MenuItem(id: UUID(), name: "Caramel Pudding", quantity: 1, price: 100),
//                MenuItem(id: UUID(), name: "Pankcakes", quantity: 2, price: 100),
//                MenuItem(id: UUID(), name: "Item 12", quantity: 1, price: 100),
//                MenuItem(id: UUID(), name: "Item 13", quantity: 1, price: 100),
//                MenuItem(id: UUID(), name: "Item 14", quantity: 1, price: 100),
//                MenuItem(id: UUID(), name: "Item 15", quantity: 1, price: 100),
//                MenuItem(id: UUID(), name: "Item 16", quantity: 1, price: 100),
//                MenuItem(id: UUID(), name: "Item 17", quantity: 1, price: 100),
//                MenuItem(id: UUID(), name: "Item 18", quantity: 1, price: 100),
//                MenuItem(id: UUID(), name: "Item 19", quantity: 1, price: 100),
//                MenuItem(id: UUID(), name: "Item 20", quantity: 1, price: 100)
            ], tableNumber: 9, first: true, finalTotal: 420)
                .frame(width: 420, height: 595)
                .background(Color.white)
            Spacer()
        }
        .background(Color.gray)
    }
}
