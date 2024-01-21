//
//  col2Grid.swift
//  Durigo
//
//  Created by Joshua Cardozo on 09/01/24.
//

import SwiftUI

struct col2Grid: View {
    let count = 30
    var body: some View {
        let spacing = (1123-80)/CGFloat((count)) - 1
        HStack(alignment: .top, spacing: 0) {
            VStack(spacing: spacing) {
                ForEach(Array(0...count), id: \.self) { _ in
                    Rectangle()
                        .fill(Color.black)
                        .frame(height: 1)
                }
            }
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 1)
                    .padding(.leading, spacing)
            }
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 1)
            }
            Rectangle()
                .fill(Color.black)
                .frame(width: 1)
            VStack(spacing: spacing) {
                ForEach(Array(0...count), id: \.self) { _ in
                    Rectangle()
                        .fill(Color.black)
                        .frame(height: 1)
                }
            }
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 1)
                    .padding(.leading, spacing)
            }
            .overlay(alignment: .trailing) {
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 1)
            }
        }
        .padding(.top, 80)
        .overlay(alignment: .topLeading) {
            Text("Date:")
                .foregroundStyle(Color.black)
                .font(.title)
                .padding()
        }
    }
}

#Preview {
    VStack {
        col2Grid()
            .frame(width: 794, height: 1123)
            .clipped()
            .background(Color.white)
            .scaleEffect(0.45)
    }
    .background(Color.gray)
}
