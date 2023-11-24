//
//  MenuGenerator.swift
//  Durigo
//
//  Created by Joshua Cardozo on 24/11/23.
//

import SwiftUI



extension MenuGenerator {
    struct MenuItem: View {
        let item: Category.Item
        
        var body: some View {
            VStack(alignment: .leading) {
                HStack {
                    Text(item.name)
                    if let subtext = item.subtext {
                        Text("(\(subtext))")
                    }
                    Spacer()
                    if item.price > 0 {
                        Text(item.price.asCurrencyString() ?? "")
                    } else {
                        Text("as per price")
                    }
                }
                .font(.poppinsBold(size: 30))
                if let description = item.description {
                    Text(description)
                        .font(.poppinsMedium(size: 24))
                }
            }
            .padding(.top, 35)
        }
    }
    
    struct MenuCategory: View {
        let name: String
        var body: some View {
            VStack {
                Rectangle()
                    .fill(Color.menuText)
                    .frame(height: 4)
                Text(name)
                    .font(.poppinsBold(size: 50))
                    .padding(.vertical, 20)
                Rectangle()
                    .fill(Color.menuText)
                    .frame(height: 4)
            }
            .padding(.top, 60)
        }
    }
    
    struct Page:View {
        var isFirst: Bool = false
        let left: [Category]
        let right: [Category]
        var body: some View {
            GeometryReader { geometry in
                VStack {
                    HStack(spacing: 0) {
                        VStack(spacing: 0) {
                            if isFirst {
                                Text("MENU")
                                    .font(.cormorantGaramondBold(size: 200))
                                    .padding(.top, 60)
                            }
                            
                            ForEach(left) { category in
                                MenuGenerator.MenuCategory(name: category.name)
                                ForEach(category.menus.filter({ $0.enabled })) { item in
                                    MenuGenerator.MenuItem(item: item)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 100)
                        .frame(width: geometry.size.width / 2)
                        
                        Rectangle()
                            .fill(Color.menuText)
                            .frame(width: 4)
                            .padding(.vertical, 60)
                        
                        VStack(spacing: 0) {
                            ForEach(right) { category in
                                MenuGenerator.MenuCategory(name: category.name)
                                ForEach(category.menus.filter({ $0.enabled })) { item in
                                    MenuGenerator.MenuItem(item: item)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 100)
                        .frame(width: geometry.size.width / 2)
                    }
                    HStack {
                        Text("Durigo's")
                            .font(.dancingScriptBold(size: 50))
                        Spacer()
                        Text("Grande Vanelim, Colva, salcete, Goa")
                            .font(.poppinsBold(size: 24))
                        Spacer()
                        Text("durigos.in")
                            .font(.poppinsBold(size: 24))
                    }
                    .padding(.horizontal, 100)
                    .padding(.bottom, 60)
                }
                
            }
            .frame(width: 1748, height: 2480)
            .background(Color.menuBackground)
            .foregroundStyle(Color.menuText)
        }
    }
    
    struct FrontCover: View {
        var body: some View {
            VStack {
                Text("Durigo's")
                    .font(.dancingScriptBold(size: 400))
                    .overlay(alignment: .bottomTrailing) {
                        Text("Since 1971")
                            .font(.dancingScriptBold(size: 100))
                            .offset(x: 100, y: 50)
                    }
            }
            .frame(width: 1748, height: 2480)
            .background(Color.menuBackground)
            .foregroundStyle(Color.menuText)
        }
    }
    
    struct BackCover: View {
        var body: some View {
            VStack {
                Text("For take away orders")
                    .font(.poppinsBold(size: 70))
                HStack(alignment: .top) {
                    Text("Contact: ")
                        .font(.poppinsMedium(size: 50))
                    VStack(alignment: .leading) {
                        Text("9145529203")
                            .font(.poppinsMedium(size: 50))
                        Text("9145925489")
                            .font(.poppinsMedium(size: 50))
                    }
                }
                
                HStack(alignment: .top) {
                    Text("Serving time: ")
                        .font(.poppinsMedium(size: 50))
                    VStack(alignment: .leading) {
                        Text("11:30 PM to 3:00 PM")
                            .font(.poppinsBold(size: 50))
                        Text("7:00 PM to 10:45 PM")
                            .font(.poppinsBold(size: 50))
                    }
                }
                .padding(.top, 100)
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top, spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .padding(.top, 8)
                        Text("Once an order is placed, it cannot be cancelled")
                    }
                    HStack(alignment: .top, spacing: 16) {
                        Image(systemName: "timer")
                            .padding(.top, 8)
                        Text("Please allow 30-40 minutes for meal preparation")
                    }
                    HStack(alignment: .top, spacing: 16) {
                        Image(systemName: "bag.badge.plus")
                            .padding(.top, 8)
                        Text("We kindly request that no outside food be brought into the restaurant")
                    }
                    HStack(alignment: .top, spacing: 16) {
                        Image(systemName: "creditcard")
                            .padding(.top, 8)
                        Text("Corkage charges are applicable. Please inquire with our staff for details")
                    }
                    HStack(alignment: .top, spacing: 16) {
                        Image(systemName: "hammer")
                            .padding(.top, 8)
                        Text("Please note, charges will apply for any breakages")
                    }
                    HStack(alignment: .top, spacing: 16) {
                        Image(systemName: "bag")
                            .padding(.top, 8)
                        Text("Please look after your personal belongings, as the management cannot assume responsibility for lost items")
                    }
                }
                .font(.poppinsMedium(size: 50))
                .padding(.top, 100)
                
                Spacer()
                
                VStack {
                    Image(systemName: "nosign")
                        .font(.poppinsBold(size: 100))
                    Text("Smoking in the restaurant is strictly prohibited")
                }
                .font(.poppinsBold(size: 50))
                .foregroundStyle(Color.noSmoking)
                
                Spacer()
            }
            .padding(100)
            .frame(width: 1748, height: 2480)
            .background(Color.menuBackground)
            .foregroundStyle(Color.menuText)
        }
    }
}

struct MenuGenerator: View {
    @EnvironmentObject private var menuLoader: MenuLoader
    var body: some View {
        VStack {
            GeometryReader { geometry in
                let finalScale = min(geometry.size.height / 2480, geometry.size.width / 1748)
                if let menu = menuLoader.menu {
                    TabView {
                        FrontCover()
                            .scaleEffect(finalScale)
                        Page(isFirst: true, left: [menu[0], menu[1], menu[4]], right: [menu[2], menu[3]])
                            .scaleEffect(finalScale)
                        Page(left: [menu[5], menu[6], menu[7]], right: [menu[8], menu[9], menu[10], menu[11]])
                            .scaleEffect(finalScale)
                        Page(left: [menu[12], menu[13], menu[14]], right: [menu[15], menu[16]])
                            .scaleEffect(finalScale)
                        Page(left: [menu[17], menu[18], menu[19]], right: [menu[20], menu[21]])
                            .scaleEffect(finalScale)
                        BackCover()
                            .scaleEffect(finalScale)
                    }
                    #if os(iOS)
                    .tabViewStyle(.page)
                    #endif
                    
                }
            }
        }
        .background(Color.secondary)
        .overlay(alignment: .topTrailing, content: {
            if let menu = menuLoader.menu {
                ShareLink("Export Menu", item: render(menu: menu))
                    .padding()
                    .background(Color.white)
                    .cornerRadius(6)
                    .padding()
            }
        })
        .task {
            await menuLoader.loadMenu()
        }
    }
    
    
    @MainActor func render(menu: [Category]) -> URL {
        // 1: Save it to our documents directory
        let url = URL.documentsDirectory.appending(path: "Menu.pdf")
        
        // 2: PDF size
        var box = CGRect(x: 0, y: 0, width: 1748, height: 2480)
        
        // 3: Create the CGContext for our PDF pages
        guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else {
            return url
        }
        
        pdf.beginPDFPage(nil)
        
        let fontCoverRenderer = ImageRenderer(content:
                                        FrontCover()
            .frame(width: 1748, height: 2480)
        )
        
        fontCoverRenderer.render { size, context in
            context(pdf)
        }
        
        pdf.endPDFPage()
        
        let pages =
        
                [Page(isFirst: true, left: [menu[0], menu[1], menu[4]], right: [menu[2], menu[3]]),
                Page(left: [menu[5], menu[6], menu[7]], right: [menu[8], menu[9], menu[10], menu[11]]),
                Page(left: [menu[12], menu[13], menu[14]], right: [menu[15], menu[16]]),
                Page(left: [menu[17], menu[18], menu[19]], right: [menu[20], menu[21]])
                 ]
            
        
        // 4: Render each page
        for page in pages {
            
            pdf.beginPDFPage(nil)
            
            let renderer = ImageRenderer(content:
                                            page
                .frame(width: 1748, height: 2480)
            )
            
            renderer.render { size, context in
                context(pdf)
            }
            
            pdf.endPDFPage()
            
        }
        
        pdf.beginPDFPage(nil)
        
        let backCoverRenderer = ImageRenderer(content:
                                        BackCover()
            .frame(width: 1748, height: 2480)
        )
        
        backCoverRenderer.render { size, context in
            context(pdf)
        }
        
        pdf.endPDFPage()
        
        
        
        
        pdf.closePDF()
        
        
        return url
    }
}

#Preview {
    VStack {
        MenuGenerator()
            
    }
    .environmentObject(MenuLoader())
}
