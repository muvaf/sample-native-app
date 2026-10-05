//
//  ContentView.swift
//  sample-native-app
//
//  Created by Muvaffak on 1/16/26.
//

import SwiftUI

struct ContentView: View {
    @State private var showingAbout = false

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("hello niteshift")
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .top) {
            HStack(spacing: 12) {
                Image(systemName: "globe")
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
                Text("Niteshift")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button {
                    showingAbout = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("About Niteshift")
                .accessibilityIdentifier("aboutButton")
            }
            .padding(.leading, 20)
            .padding(.trailing, 6)
            .padding(.vertical, 6)
            .glassEffect(.regular, in: Capsule())
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .sheet(isPresented: $showingAbout) {
            NavigationStack {
                VStack(spacing: 16) {
                    Image(systemName: "globe")
                        .font(.largeTitle)
                        .foregroundStyle(.tint)
                    Text("hello niteshift")
                        .font(.title2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle("About Niteshift")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            showingAbout = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    ContentView()
}
