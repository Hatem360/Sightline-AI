//
//  ContentView.swift
//  Sightline-AI
//
//  Created by Hatem Karoui on 29.07.25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Sightline AI")
                .font(.title)
                .fontWeight(.bold)
            
            Text("System Monitoring App")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ContentView()
}
