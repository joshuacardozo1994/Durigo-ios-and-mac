//
//  MenuGenerator.swift
//  Durigo
//
//  Created by Joshua Cardozo on 24/11/23.
//

import SwiftUI

extension MenuGenerator {
    struct A4Size: Hashable, Identifiable {
        var id: String {
            return name
        }
        let name: String
        let size: CGSize
        
        func hash(into hasher: inout Hasher) {
                hasher.combine(name)
                hasher.combine(size.width)
                hasher.combine(size.height)
            }

        static func ==(lhs: A4Size, rhs: A4Size) -> Bool {
            return lhs.name == rhs.name && lhs.size.width == rhs.size.width && lhs.size.height == rhs.size.height
        }
    }
    
    struct Settings: View {
        let sizes = [
            A4Size(name: "72 PPI/DPI", size: CGSize(width: 595, height: 842)),
            A4Size(name: "96 PPI/DPI", size: CGSize(width: 794, height: 1123)),
            A4Size(name: "150 PPI/DPI", size: CGSize(width: 1240, height: 1754)),
            A4Size(name: "300 PPI/DPI", size: CGSize(width: 2480, height: 3508))
        ]
        @Binding var a4Size: A4Size
        @Binding var titleFontSize: CGFloat
        @Binding var subtitleFontSize: CGFloat
        
        @Binding var menuTextFontSize: CGFloat
        @Binding var categoryFontSize: CGFloat
        @Binding var itemFontSize: CGFloat
        @Binding var itemDescriptionFontSize: CGFloat
        @Binding var itemPageHorizontalPadding: CGFloat
        @Binding var itemPageVerticalPadding: CGFloat
        
        @Binding var backCoverTitleFontSize: CGFloat
        @Binding var backCoverPadding: CGFloat
        
        var body: some View {
            VStack(alignment: .leading) {
                Form {
                    Section {
                        Picker("Select Page Size", selection: $a4Size) {
                            ForEach(sizes) { size in
                                Text(size.name)
                                    .tag(size)
                            }
                        }
                    } header: {
                        Text("Page size")
                    }
                    Section {
                        Stepper("Title Font Size \(Int(titleFontSize))", value: $titleFontSize, step: 10)
                        Stepper("Subtitle Font Size \(Int(subtitleFontSize))", value: $subtitleFontSize, step: 10)
                    } header: {
                        Text("Front Cover")
                    }
                    Section {
                        Stepper("Menu Text Font Size \(Int(menuTextFontSize))", value: $menuTextFontSize, step: 10)
                        Stepper("Category Font Size \(Int(categoryFontSize))", value: $categoryFontSize)
                        Stepper("Item Font Size \(Int(itemFontSize))", value: $itemFontSize)
                        Stepper("Item Description Font Size \(Int(itemDescriptionFontSize))", value: $itemDescriptionFontSize)
                        Stepper("Horizontal Padding \(Int(itemPageHorizontalPadding))", value: $itemPageHorizontalPadding)
                        Stepper("Vertical Padding \(Int(itemPageVerticalPadding))", value: $itemPageVerticalPadding)
                    } header: {
                        Text("Item Pages")
                    }
                    Section {
                        Stepper("Back Cover Title Font Size \(Int(backCoverTitleFontSize))", value: $backCoverTitleFontSize)
                        Stepper("Back Cover Padding \(Int(backCoverPadding))", value: $backCoverPadding)
                    } header: {
                        Text("Back Cover")
                    }

                }
            }
            .padding(.top, 30)
        }
    }
    
    struct MenuItem: View {
        let item: Category.Item
        let fontSize: CGFloat
        let descriptionFontSize: CGFloat
        let topPadding: CGFloat
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    Text(item.name)
                    +
                    Text(item.suffix != nil ? "(\(item.suffix ?? ""))" : "")
                    
                    Spacer()
                    if item.price > 0 {
                        Text(item.price.asCurrencyString() ?? "")
                    } else {
                        Text("market price")
                    }
                }
                .font(.poppinsBold(size: fontSize))
                if let description = item.description {
                    Text(description)
                        .font(.poppinsMedium(size: descriptionFontSize))
                }
            }
            .padding(.top, topPadding)
        }
    }
    
    struct MenuCategory: View {
        let name: String
        let fontSize: CGFloat
        var body: some View {
            VStack {
                Rectangle()
                    .fill(Color.black)
                    .frame(height: 2)
                Text(name)
                    .font(.poppinsBold(size: fontSize))
                Rectangle()
                    .fill(Color.black)
                    .frame(height: 2)
            }
            .padding(.top, 30)
        }
    }
    
    struct Page:View {
        let a4Size: A4Size
        let menuTextFontSize: CGFloat
        let categoryFontSize: CGFloat
        let itemFontSize: CGFloat
        let itemTopPadding: CGFloat
        let itemDescriptionFontSize: CGFloat
        let horizontalPadding: CGFloat
        let verticalPadding: CGFloat
        var isFirst: Bool = false
        let left: [Category]
        let right: [Category]
        
        
        var body: some View {
            VStack {
                GeometryReader { geometry in
                    VStack {
                        HStack(alignment: .top, spacing: 0) {
                            VStack(spacing: 0) {
                                if isFirst {
                                    Text("MENU")
                                        .font(.cormorantGaramondBold(size: menuTextFontSize))
                                        .padding(.top, verticalPadding)
                                }
                                
                                
                                ForEach(left) { category in
                                    MenuGenerator.MenuCategory(name: category.name, fontSize: categoryFontSize)
                                    ForEach(category.items.filter({ [Category.Item.VisibilityScope.menu, Category.Item.VisibilityScope.both].contains($0.visibilityScope)})) { item in
                                        MenuGenerator.MenuItem(item: item, fontSize: itemFontSize, descriptionFontSize: itemDescriptionFontSize, topPadding: itemTopPadding)
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, horizontalPadding)
                            .frame(width: geometry.size.width / 2)
                            
                            Rectangle()
                                .fill(Color.black)
                                .frame(width: 2)
                                .padding(.vertical, verticalPadding)
                            
                            VStack(spacing: 0) {
                                ForEach(right) { category in
                                    MenuGenerator.MenuCategory(name: category.name, fontSize: categoryFontSize)
                                    ForEach(category.items.filter({ [Category.Item.VisibilityScope.menu, Category.Item.VisibilityScope.both].contains($0.visibilityScope)})) { item in
                                        MenuGenerator.MenuItem(item: item, fontSize: itemFontSize, descriptionFontSize: itemDescriptionFontSize, topPadding: itemTopPadding)
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, horizontalPadding)
                            .frame(width: geometry.size.width / 2)
                        }
                        HStack {
                            Text("Durigo's")
                                .font(.dancingScriptBold(size: categoryFontSize))
                            Spacer()
                            Text("Grande Vanelim, Colva, salcete, Goa")
                                .font(.poppinsBold(size: itemDescriptionFontSize))
                            Spacer()
                            Text("durigos.in")
                                .font(.poppinsBold(size: itemDescriptionFontSize))
                        }
                        .padding(.horizontal, 100)
                        .padding(.bottom, verticalPadding)
                    }
                    
                }
            }
            .frame(width: a4Size.size.width, height: a4Size.size.height)
            .clipped()
            .foregroundStyle(Color.black)
        }
    }
    
    struct FrontCover: View {
        let a4Size: A4Size
        let titleFontSize: CGFloat
        let subtitleFontSize: CGFloat
        var body: some View {
            VStack {
                Text("Durigo's")
                    .font(.dancingScriptBold(size: titleFontSize))
                    .overlay(alignment: .bottomTrailing) {
                        Text("Since 1971")
                            .font(.dancingScriptBold(size: subtitleFontSize))
                            .offset(x: 50, y: 50)
                    }
            }
            .frame(width: a4Size.size.width, height: a4Size.size.height)
            .clipped()
            .foregroundStyle(Color.black)
        }
    }
    
    struct BackCover: View {
        let a4Size: A4Size
        let backCoverTitleFontSize: CGFloat
        let textFontSize: CGFloat
        let padding: CGFloat
        var body: some View {
            VStack {
                Text("For take away orders")
                    .font(.poppinsBold(size: backCoverTitleFontSize))
                HStack(alignment: .top) {
                    Text("Contact: ")
                        
                    VStack(alignment: .leading) {
                        Text("9545925489")
                    }
                }
                .padding(.top)
                
                HStack(alignment: .top) {
                    Text("Serving time: ")
                    VStack(alignment: .leading) {
                        Text("11:30 PM to 3:00 PM")
                        Text("7:00 PM to 10:45 PM")
                    }
                }
                .padding(.top, padding)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .padding(.top, 8)
                        Text("Once an order is placed, it cannot be cancelled")
                    }
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "timer")
                            .padding(.top, 8)
                        Text("Please allow 30-40 minutes for meal preparation")
                    }
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "bag.badge.plus")
                            .padding(.top, 8)
                        Text("We kindly request that no outside food be brought into the restaurant")
                    }
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "creditcard")
                            .padding(.top, 8)
                        Text("Corkage charges are applicable. Please inquire with our staff for details")
                    }
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "hammer")
                            .padding(.top, 8)
                        Text("Please note, charges will apply for any breakages")
                    }
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "bag")
                            .padding(.top, 8)
                        Text("Please look after your personal belongings, as the management cannot assume responsibility for lost items")
                    }
                }
                .padding(.top, padding)
                
                Spacer()
                
                VStack {
                    Image(systemName: "nosign")
                        .font(.poppinsBold(size: 100))
                    Text("Smoking in the restaurant is strictly prohibited")
                }
                .foregroundStyle(Color.noSmoking)
                
                Spacer()
            }
            .font(.poppinsMedium(size: 24))
            .padding(padding)
            .frame(width: a4Size.size.width, height: a4Size.size.height)
            .clipped()
            .foregroundStyle(Color.black)
        }
    }
}

struct MenuGenerator: View {
    @EnvironmentObject private var menuLoader: MenuLoader
    @State private var a4Size = A4Size(name: "96 PPI/DPI", size: CGSize(width: 794, height: 1123))
    
    @State private var titleFontSize: CGFloat = 200
    @State private var subtitleFontSize: CGFloat = 50
    
    @State private var menuTextFontSize: CGFloat = 80
    @State private var categoryFontSize: CGFloat = 18
    @State private var itemFontSize: CGFloat = 16
    @State private var itemDescriptionFontSize: CGFloat = 12
    @State private var itemTopPadding: CGFloat = 6
    @State private var itemPageHorizontalPadding: CGFloat = 40
    @State private var itemPageVerticalPadding: CGFloat = 20
    
    @State private var backCoverTitleFontSize: CGFloat = 50
    @State private var backCoverPadding: CGFloat = 30
    
    @State private var isShowingSettings = false
    
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                let finalScale = min(geometry.size.height / a4Size.size.height, geometry.size.width / a4Size.size.width)
                if let menu = menuLoader.menu {
                    TabView {
                        FrontCover(a4Size: a4Size, titleFontSize: titleFontSize, subtitleFontSize: subtitleFontSize)
                            .background(Color.white)
                            .scaleEffect(finalScale)
                            
                        Page(a4Size: a4Size, menuTextFontSize: menuTextFontSize, categoryFontSize: categoryFontSize, itemFontSize: itemFontSize, itemTopPadding: itemTopPadding, itemDescriptionFontSize: itemDescriptionFontSize, horizontalPadding: itemPageHorizontalPadding, verticalPadding: itemPageVerticalPadding, isFirst: true, left: [menu[0], menu[3]], right: [menu[2],  menu[6], menu[9]])
                            .background(Color.white)
                            .scaleEffect(finalScale)
                            
                        Page(a4Size: a4Size, menuTextFontSize: menuTextFontSize, categoryFontSize: categoryFontSize, itemFontSize: itemFontSize, itemTopPadding: itemTopPadding, itemDescriptionFontSize: itemDescriptionFontSize, horizontalPadding: itemPageHorizontalPadding, verticalPadding: itemPageVerticalPadding, left: [menu[1], menu[5], menu[8]], right: [menu[4], menu[10], menu[7]])
                            .background(Color.white)
                            .scaleEffect(finalScale)
                            
                        Page(a4Size: a4Size, menuTextFontSize: menuTextFontSize, categoryFontSize: categoryFontSize, itemFontSize: itemFontSize, itemTopPadding: itemTopPadding, itemDescriptionFontSize: itemDescriptionFontSize, horizontalPadding: itemPageHorizontalPadding, verticalPadding: itemPageVerticalPadding, left: [menu[11], menu[12], menu[13]], right: [menu[14], menu[15]])
                            .background(Color.white)
                            .scaleEffect(finalScale)
                            
                        Page(a4Size: a4Size, menuTextFontSize: menuTextFontSize, categoryFontSize: categoryFontSize, itemFontSize: itemFontSize, itemTopPadding: itemTopPadding, itemDescriptionFontSize: itemDescriptionFontSize, horizontalPadding: itemPageHorizontalPadding, verticalPadding: itemPageVerticalPadding, left: [menu[16], menu[17], menu[18]], right: [menu[19], menu[20]])
                            .background(Color.white)
                            .scaleEffect(finalScale)
                            
                        BackCover(a4Size: a4Size, backCoverTitleFontSize: backCoverTitleFontSize, textFontSize: categoryFontSize, padding: backCoverPadding)
                            .background(Color.white)
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
        .overlay(alignment: .topLeading, content: {
            Button(action: { isShowingSettings.toggle() }) {
                Image(systemName: "gear")
                    .padding()
                    .background(Color.white)
                    .cornerRadius(6)
                    .padding()
            }
        })
        .popover(isPresented: $isShowingSettings, content: {
            Settings(a4Size: $a4Size, titleFontSize: $titleFontSize, subtitleFontSize: $subtitleFontSize, menuTextFontSize: $menuTextFontSize, categoryFontSize: $categoryFontSize, itemFontSize: $itemFontSize, itemDescriptionFontSize: $itemDescriptionFontSize, itemPageHorizontalPadding: $itemPageHorizontalPadding, itemPageVerticalPadding: $itemPageVerticalPadding, backCoverTitleFontSize: $backCoverTitleFontSize, backCoverPadding: $backCoverPadding)
        })
        .task {
            await menuLoader.loadMenu()
        }
    }
    
    
    @MainActor func render(menu: [Category]) -> URL {
        // 1: Save it to our documents directory
        let url = URL.documentsDirectory.appending(path: "Menu.pdf")
        
        // 2: PDF size
        var box = CGRect(x: 0, y: 0, width: a4Size.size.width, height: a4Size.size.height)
        
        // 3: Create the CGContext for our PDF pages
        guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else {
            return url
        }
        
        pdf.beginPDFPage(nil)
        
        let fontCoverRenderer = ImageRenderer(content:
                                                FrontCover(a4Size: a4Size, titleFontSize: titleFontSize, subtitleFontSize: subtitleFontSize)
            .frame(width: a4Size.size.width, height: a4Size.size.height)
        )
        
        fontCoverRenderer.render { size, context in
            context(pdf)
        }
        
        pdf.endPDFPage()
        

        let pages =
        
        [
            Page(a4Size: a4Size, menuTextFontSize: menuTextFontSize, categoryFontSize: categoryFontSize, itemFontSize: itemFontSize, itemTopPadding: itemTopPadding, itemDescriptionFontSize: itemDescriptionFontSize, horizontalPadding: itemPageHorizontalPadding, verticalPadding: itemPageVerticalPadding, isFirst: true, left: [menu[0], menu[3]], right: [menu[2],  menu[6], menu[9]]),
                
            Page(a4Size: a4Size, menuTextFontSize: menuTextFontSize, categoryFontSize: categoryFontSize, itemFontSize: itemFontSize, itemTopPadding: itemTopPadding, itemDescriptionFontSize: itemDescriptionFontSize, horizontalPadding: itemPageHorizontalPadding, verticalPadding: itemPageVerticalPadding, left: [menu[1], menu[5], menu[8]], right: [menu[4], menu[10], menu[7]]),
                
            Page(a4Size: a4Size, menuTextFontSize: menuTextFontSize, categoryFontSize: categoryFontSize, itemFontSize: itemFontSize, itemTopPadding: itemTopPadding, itemDescriptionFontSize: itemDescriptionFontSize, horizontalPadding: itemPageHorizontalPadding, verticalPadding: itemPageVerticalPadding, left: [menu[11], menu[12], menu[13]], right: [menu[14], menu[15]]),
                
            Page(a4Size: a4Size, menuTextFontSize: menuTextFontSize, categoryFontSize: categoryFontSize, itemFontSize: itemFontSize, itemTopPadding: itemTopPadding, itemDescriptionFontSize: itemDescriptionFontSize, horizontalPadding: itemPageHorizontalPadding, verticalPadding: itemPageVerticalPadding, left: [menu[16], menu[17], menu[18]], right: [menu[19], menu[20]])
        ]
            
        
        // 4: Render each page
        for page in pages {
            
            pdf.beginPDFPage(nil)
            
            let renderer = ImageRenderer(content:
                                            page
                .frame(width: a4Size.size.width, height: a4Size.size.height)
            )
            
            renderer.render { size, context in
                context(pdf)
            }
            
            pdf.endPDFPage()
            
        }
        
        pdf.beginPDFPage(nil)
        
        let backCoverRenderer = ImageRenderer(content:
                                                BackCover(a4Size: a4Size, backCoverTitleFontSize: backCoverTitleFontSize, textFontSize: categoryFontSize, padding: backCoverPadding)
            .frame(width: a4Size.size.width, height: a4Size.size.height)
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
