//
//  DeckedApp.swift
//  Decked
//
//  Premium Pokémon TCG card collection app
//

import SwiftUI

@main
struct DeckedApp: App {
    
    let persistenceController = PersistenceController.shared
    
    init() {
        configureAppAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, persistenceController.viewContext)
                .preferredColorScheme(.dark)
        }
    }
    
    private func configureAppAppearance() {
        // Navigation bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor(Color.deckBackground)
        navBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(Color.deckTextPrimary)
        ]
        navBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(Color.deckTextPrimary)
        ]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        
        // TextField appearance
        UITextField.appearance().tintColor = UIColor(Color.deckAccent)
    }
}
