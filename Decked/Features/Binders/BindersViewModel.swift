//
//  BindersViewModel.swift
//  Decked
//
//  ViewModels for binder management
//

import Foundation
import Combine

// MARK: - Binders ViewModel

final class BindersViewModel: ObservableObject {
    
    @Published private(set) var binders: [Binder] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    
    private let binderService: BinderServiceProtocol
    
    init(binderService: BinderServiceProtocol = BinderService.shared) {
        self.binderService = binderService
    }
    
    @MainActor
    func loadBinders() async {
        isLoading = true
        binders = await binderService.getBinders()
        isLoading = false
    }
    
    @MainActor
    func createBinder(_ binder: Binder) async {
        do {
            try await binderService.createBinder(binder)
            await loadBinders()
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    @MainActor
    func deleteBinder(_ binderId: UUID) async {
        do {
            try await binderService.deleteBinder(binderId)
            await loadBinders()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Binder Detail ViewModel

final class BinderDetailViewModel: ObservableObject {
    
    @Published private(set) var cards: [CollectionCard] = []
    @Published private(set) var isLoading = false
    
    let binder: Binder
    private let binderService: BinderServiceProtocol
    private let collectionService: CollectionServiceProtocol
    
    var totalValue: Double? {
        let values = cards.compactMap { $0.estimatedValue }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +)
    }
    
    init(
        binder: Binder,
        binderService: BinderServiceProtocol = BinderService.shared,
        collectionService: CollectionServiceProtocol = CollectionService.shared
    ) {
        self.binder = binder
        self.binderService = binderService
        self.collectionService = collectionService
    }
    
    @MainActor
    func loadCards() async {
        isLoading = true
        
        let allCards = await collectionService.getCards()
        cards = allCards.filter { binder.cardIds.contains($0.id) }
        
        isLoading = false
    }
    
    @MainActor
    func removeCard(_ cardId: UUID) async {
        // TODO: Implement card removal from binder
    }
}

// MARK: - Binder Service Protocol

protocol BinderServiceProtocol {
    func getBinders() async -> [Binder]
    func getBinder(_ id: UUID) async -> Binder?
    func createBinder(_ binder: Binder) async throws
    func updateBinder(_ binder: Binder) async throws
    func deleteBinder(_ id: UUID) async throws
    func addCardToBinder(_ cardId: UUID, binderId: UUID) async throws
    func removeCardFromBinder(_ cardId: UUID, binderId: UUID) async throws
}

// MARK: - Binder Service (UserDefaults-based for MVP)

final class BinderService: BinderServiceProtocol {
    
    static let shared = BinderService()
    
    private let userDefaults = UserDefaults.standard
    private let bindersKey = "decked_binders"
    
    private init() {}
    
    func getBinders() async -> [Binder] {
        guard let data = userDefaults.data(forKey: bindersKey) else {
            return []
        }
        
        do {
            let binders = try JSONDecoder().decode([Binder].self, from: data)
            return binders.sorted { $0.sortOrder < $1.sortOrder }
        } catch {
            print("Failed to decode binders: \(error)")
            return []
        }
    }
    
    func getBinder(_ id: UUID) async -> Binder? {
        let binders = await getBinders()
        return binders.first { $0.id == id }
    }
    
    func createBinder(_ binder: Binder) async throws {
        var binders = await getBinders()
        var newBinder = binder
        newBinder = Binder(
            id: binder.id,
            name: binder.name,
            description: binder.description,
            coverImageURL: binder.coverImageURL,
            accentColorHex: binder.accentColorHex,
            cardIds: binder.cardIds,
            createdAt: binder.createdAt,
            updatedAt: Date(),
            isPublic: binder.isPublic,
            sortOrder: binders.count
        )
        binders.append(newBinder)
        try saveBinders(binders)
    }
    
    func updateBinder(_ binder: Binder) async throws {
        var binders = await getBinders()
        guard let index = binders.firstIndex(where: { $0.id == binder.id }) else {
            throw BinderError.notFound
        }
        
        var updatedBinder = binder
        updatedBinder = Binder(
            id: binder.id,
            name: binder.name,
            description: binder.description,
            coverImageURL: binder.coverImageURL,
            accentColorHex: binder.accentColorHex,
            cardIds: binder.cardIds,
            createdAt: binder.createdAt,
            updatedAt: Date(),
            isPublic: binder.isPublic,
            sortOrder: binder.sortOrder
        )
        binders[index] = updatedBinder
        try saveBinders(binders)
    }
    
    func deleteBinder(_ id: UUID) async throws {
        var binders = await getBinders()
        binders.removeAll { $0.id == id }
        try saveBinders(binders)
    }
    
    func addCardToBinder(_ cardId: UUID, binderId: UUID) async throws {
        guard var binder = await getBinder(binderId) else {
            throw BinderError.notFound
        }
        
        if !binder.cardIds.contains(cardId) {
            var newCardIds = binder.cardIds
            newCardIds.append(cardId)
            
            binder = Binder(
                id: binder.id,
                name: binder.name,
                description: binder.description,
                coverImageURL: binder.coverImageURL,
                accentColorHex: binder.accentColorHex,
                cardIds: newCardIds,
                createdAt: binder.createdAt,
                updatedAt: Date(),
                isPublic: binder.isPublic,
                sortOrder: binder.sortOrder
            )
            try await updateBinder(binder)
        }
    }
    
    func removeCardFromBinder(_ cardId: UUID, binderId: UUID) async throws {
        guard var binder = await getBinder(binderId) else {
            throw BinderError.notFound
        }
        
        var newCardIds = binder.cardIds
        newCardIds.removeAll { $0 == cardId }
        
        binder = Binder(
            id: binder.id,
            name: binder.name,
            description: binder.description,
            coverImageURL: binder.coverImageURL,
            accentColorHex: binder.accentColorHex,
            cardIds: newCardIds,
            createdAt: binder.createdAt,
            updatedAt: Date(),
            isPublic: binder.isPublic,
            sortOrder: binder.sortOrder
        )
        try await updateBinder(binder)
    }
    
    private func saveBinders(_ binders: [Binder]) throws {
        let data = try JSONEncoder().encode(binders)
        userDefaults.set(data, forKey: bindersKey)
    }
}

// MARK: - Binder Errors

enum BinderError: LocalizedError {
    case notFound
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Binder not found"
        case .saveFailed:
            return "Failed to save binder"
        }
    }
}
