//
//  ResizerView.swift
//  ФАП
//
//  Created by Sergey Kowalew on 19.08.2026.
//


import SwiftUI

struct ResizerView: View {
    @Binding var width: CGFloat
    
    var body: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 5)
            .contentShape(Rectangle())
            .onHover { isHovering in
                if isHovering { NSCursor.resizeLeftRight.set() } 
                else { NSCursor.arrow.set() }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        width = max(40, width + value.translation.width)
                    }
            )
            .padding(.vertical, 2)
    }
}
