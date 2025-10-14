//
//  MetricCard.swift
//  DoSurfWatch Watch App
//
//  Created by 잠만보김쥬디 on 10/15/25.
//

import SwiftUI

// MARK: - Metric Card Component
struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(icon)
                .font(.caption)
            
            Text(value)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
        .frame(maxWidth: .infinity)
    }
}
