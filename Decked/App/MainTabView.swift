//
//  MainTabView.swift
//  Decked
//
//  Main tab navigation for the app
//

import SwiftUI

struct MainTabView: View {
    
    @State private var selectedTab: Tab = .scanner
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Scanner Tab
            ScannerView()
                .tabItem {
                    Label("Scan", systemImage: "camera.viewfinder")
                }
                .tag(Tab.scanner)
            
            // Collection Tab
            CollectionView()
                .tabItem {
                    Label("Collection", systemImage: "square.stack.3d.up.fill")
                }
                .tag(Tab.collection)
            
            // Binders Tab
            BindersView()
                .tabItem {
                    Label("Binders", systemImage: "folder.fill")
                }
                .tag(Tab.binders)
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
        .tint(.deckAccent)
        .onAppear {
            configureTabBarAppearance()
        }
    }
    
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.deckBackground)
        
        // Normal state
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.deckTextMuted)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Color.deckTextMuted)
        ]
        
        // Selected state
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.deckAccent)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color.deckAccent)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Tab Enum

enum Tab: Hashable {
    case scanner
    case collection
    case binders
    case settings
}

// MARK: - Settings View

struct SettingsView: View {
    
    @AppStorage("debugMode") private var debugMode = false
    @AppStorage("scanInterval") private var scanInterval = 0.75
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.deckBackground
                    .ignoresSafeArea()
                
                List {
                    // App Section
                    Section {
                        HStack(spacing: 16) {
                            // App icon
                            RoundedRectangle(cornerRadius: 16)
                                .fill(DeckGradients.accentGradient)
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Text("D")
                                        .font(.system(.title, design: .rounded, weight: .bold))
                                        .foregroundColor(.deckBackground)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Decked")
                                    .font(.system(.headline, design: .rounded, weight: .bold))
                                    .foregroundColor(.deckTextPrimary)
                                
                                Text("Version 1.0.0")
                                    .font(.system(.caption, design: .default))
                                    .foregroundColor(.deckTextSecondary)
                            }
                            
                            Spacer()
                        }
                        .listRowBackground(Color.deckSurface)
                    }
                    
                    // Scanner Settings
                    Section("Scanner") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Scan Interval")
                                    .foregroundColor(.deckTextPrimary)
                                Spacer()
                                Text(String(format: "%.2fs", scanInterval))
                                    .foregroundColor(.deckAccent)
                            }
                            
                            Slider(value: $scanInterval, in: 0.25...2.0, step: 0.25)
                                .tint(.deckAccent)
                        }
                        .listRowBackground(Color.deckSurface)
                        
                        Toggle("Debug Mode", isOn: $debugMode)
                            .tint(.deckAccent)
                            .foregroundColor(.deckTextPrimary)
                            .listRowBackground(Color.deckSurface)
                    }
                    
                    // Collection Section
                    Section("Collection") {
                        NavigationLink {
                            Text("Export coming soon")
                                .foregroundColor(.deckTextSecondary)
                        } label: {
                            Label("Export Collection", systemImage: "square.and.arrow.up")
                                .foregroundColor(.deckTextPrimary)
                        }
                        .listRowBackground(Color.deckSurface)
                        
                        NavigationLink {
                            Text("Import coming soon")
                                .foregroundColor(.deckTextSecondary)
                        } label: {
                            Label("Import Collection", systemImage: "square.and.arrow.down")
                                .foregroundColor(.deckTextPrimary)
                        }
                        .listRowBackground(Color.deckSurface)
                    }
                    
                    // About Section
                    Section("About") {
                        Link(destination: URL(string: "https://pokemontcg.io")!) {
                            HStack {
                                Label("Pokémon TCG API", systemImage: "link")
                                    .foregroundColor(.deckTextPrimary)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundColor(.deckTextMuted)
                            }
                        }
                        .listRowBackground(Color.deckSurface)
                        
                        NavigationLink {
                            PrivacyView()
                        } label: {
                            Label("Privacy Policy", systemImage: "hand.raised")
                                .foregroundColor(.deckTextPrimary)
                        }
                        .listRowBackground(Color.deckSurface)
                        
                        NavigationLink {
                            AcknowledgementsView()
                        } label: {
                            Label("Acknowledgements", systemImage: "heart")
                                .foregroundColor(.deckTextPrimary)
                        }
                        .listRowBackground(Color.deckSurface)
                    }
                    
                    // Danger Zone
                    Section {
                        Button(role: .destructive) {
                            // Clear cache action
                        } label: {
                            Label("Clear Cache", systemImage: "trash")
                        }
                        .listRowBackground(Color.deckSurface)
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.deckBackground, for: .navigationBar)
        }
    }
}

// MARK: - Privacy View

struct PrivacyView: View {
    var body: some View {
        ZStack {
            Color.deckBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Privacy Policy")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundColor(.deckTextPrimary)
                    
                    Text("""
                    Decked respects your privacy. Here's how we handle your data:
                    
                    **Camera Access**
                    We use the camera solely for scanning Pokémon cards. Images are processed on-device and never uploaded to any server.
                    
                    **Local Storage**
                    Your collection data is stored locally on your device. We do not collect or transmit any personal information.
                    
                    **Third-Party Services**
                    We use the Pokémon TCG API for card data. This service receives only card identification queries, not personal information.
                    
                    **Future Features**
                    When CloudKit sync is implemented, your data will be stored in your personal iCloud account, protected by Apple's security measures.
                    """)
                    .font(.system(.body, design: .default))
                    .foregroundColor(.deckTextSecondary)
                }
                .padding()
            }
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Acknowledgements View

struct AcknowledgementsView: View {
    var body: some View {
        ZStack {
            Color.deckBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Acknowledgements")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundColor(.deckTextPrimary)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Pokémon TCG API")
                            .font(.system(.headline, design: .rounded, weight: .semibold))
                            .foregroundColor(.deckTextPrimary)
                        
                        Text("Card data and images provided by the Pokémon TCG API (pokemontcg.io)")
                            .font(.system(.body, design: .default))
                            .foregroundColor(.deckTextSecondary)
                    }
                    .padding()
                    .background(Color.deckSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Disclaimer")
                            .font(.system(.headline, design: .rounded, weight: .semibold))
                            .foregroundColor(.deckTextPrimary)
                        
                        Text("Pokémon and Pokémon character names are trademarks of Nintendo. This app is not affiliated with, endorsed, sponsored, or approved by Nintendo, The Pokémon Company, or any of their subsidiaries.")
                            .font(.system(.body, design: .default))
                            .foregroundColor(.deckTextSecondary)
                    }
                    .padding()
                    .background(Color.deckSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
            }
        }
        .navigationTitle("Acknowledgements")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
}
