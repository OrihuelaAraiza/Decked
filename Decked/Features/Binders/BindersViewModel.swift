//
//  BindersViewModel.swift
//  Decked
//
//  ViewModel for binders management with Core Data
//

import Foundation
import Combine
import CoreData

@MainActor
final class BindersViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var binders: [BinderEntity] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    
    // MARK: - Private Properties
    
    private let viewContext: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
        fetchBinders()
    }
    
    // MARK: - Public Methods
    
    func fetchBinders() {
        isLoading = true
        error = nil
        
        let request = BinderEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \BinderEntity.createdAt, ascending: false)
        ]
        
        do {
            binders = try viewContext.fetch(request)
            print("✅ Fetched \(binders.count) binders")
        } catch {
            print("❌ Failed to fetch binders: \(error)")
            self.error = "Failed to load binders: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func deleteBinder(_ binder: BinderEntity) {
        viewContext.delete(binder)
        
        do {
            try viewContext.save()
            print("✅ Deleted binder: \(binder.title)")
            fetchBinders()
        } catch {
            print("❌ Failed to delete binder: \(error)")
            self.error = "Failed to delete binder: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Computed Properties
    
    var totalCards: Int {
        binders.reduce(0) { $0 + $1.cardCount }
    }
    
    var totalValue: Double {
        binders.reduce(0) { $0 + $1.totalValue }
    }
    
    var hasBinders: Bool {
        !binders.isEmpty
    }
}
