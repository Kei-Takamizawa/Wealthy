//
//  AITickerView.swift
//  Wealthy
//
//  Created by Harrison on 12/28/25.
//

import SwiftUI

struct AITickerView: View {
    let text: String
    let onTapSparkle: () -> Void
    let onFinish: () -> Void // Callback when animation ends
    
    @State private var offsetX: CGFloat = 0
    @State private var contentWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 0.12))
                
                // Scrolling Text
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(text)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .fixedSize(horizontal: true, vertical: false)
                        .background(GeometryReader { textGeo -> Color in
                            let width = textGeo.size.width
                            if abs(self.contentWidth - width) > 1 {
                                DispatchQueue.main.async {
                                    self.contentWidth = width
                                    resetAnimation()
                                }
                            }
                            return Color.clear
                        })
                        .offset(x: offsetX)
                }
                .disabled(true) 
                .mask(
                    HStack(spacing: 0) {
                        LinearGradient(gradient: Gradient(colors: [.clear, .black]), startPoint: .leading, endPoint: .trailing)
                            .frame(width: 20)
                        Rectangle().fill(.black)
                        LinearGradient(gradient: Gradient(colors: [.black, .clear]), startPoint: .leading, endPoint: .trailing)
                            .frame(width: 20)
                    }
                )
                .onAppear {
                    self.containerWidth = geometry.size.width
                    startAnimation()
                }
                
                // Icon Overlay (Interactive)
                HStack {
                    Button(action: {
                        onTapSparkle()
                    }) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.yellow)
                            .padding(.leading, 12)
                            .padding(.vertical, 8) // Hit area
                    }
                    Spacer()
                }
            }
        }
        .frame(height: 44)
    }
    
    private func resetAnimation() {
        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true
        withTransaction(transaction) {
             offsetX = containerWidth
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        guard contentWidth > 0, containerWidth > 0 else { return }
        
        // Start position
        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            offsetX = containerWidth
        }
        
        let distance = containerWidth + contentWidth
        let duration = Double(distance) / 50.0 // Constant speed
        
        // One-shot animation
        withAnimation(.linear(duration: duration)) {
            offsetX = -contentWidth
        }
        
        // Callback after completion
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            onFinish()
        }
    }
}

#Preview {
    AITickerView(text: "Today's Advice: You spent a bit more on Food than usual. Try cooking at home tomorrow! 🍳", onTapSparkle: {}, onFinish: {})
        .frame(width: 350)
        .padding()
        .background(.black)
}
