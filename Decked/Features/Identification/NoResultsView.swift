//
//  NoResultsView.swift
//  Decked
//
//  Shows OCR output and attempted queries when no matches found
//

import SwiftUI

struct NoResultsView: View {
    
    let hint: ParsedCardHint
    let attemptedQueries: [String]
    let warning: String?
    let autoConfirmSingleMatch: Bool
    let onShowResults: ([CardMatch]) -> Void
    let onShowDetail: (CardMatch) -> Void
    
    @State private var manualQuery = ""
    @State private var isSearching = false
    @State private var errorMessage: String?
    
    private let apiClient: CardSearchService = TCGDexClient()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                if let warning = warning {
                    warningBanner(text: warning)
                }
                ocrSection
                querySection
                manualSearchSection
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .background(Color.deckBackground.ignoresSafeArea())
        .navigationTitle("No Results")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36, weight: .semibold))
                .foregroundColor(.deckTextMuted)
            
            Text("No matches found")
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundColor(.deckTextPrimary)
            
            Text("We couldn't find a matching card. Try refining the search or check the OCR output below.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.deckTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 16)
    }
    
    private var ocrSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("OCR Output")
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundColor(.deckTextPrimary)
            
            if hint.rawLines.isEmpty {
                Text("No OCR lines captured.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.deckTextSecondary)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(hint.rawLines, id: \.self) { line in
                        Text(line)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.deckTextSecondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.deckSurface.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    private var querySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Queries Tried")
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundColor(.deckTextPrimary)
            
            if attemptedQueries.isEmpty {
                Text("No queries were generated.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.deckTextSecondary)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(attemptedQueries, id: \.self) { query in
                        Text(query)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.deckTextSecondary)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(Color.deckSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            }
        }
        .padding()
        .background(Color.deckSurface.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    private var manualSearchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Search manually")
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundColor(.deckTextPrimary)
            
            TextField("Enter card name", text: $manualQuery)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
                .padding()
                .background(Color.deckSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            if let errorMessage {
                Text(errorMessage)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.deckError)
            }
            
            PrimaryButton("Search", icon: "magnifyingglass", style: .primary, isLoading: isSearching) {
                Task {
                    await runManualSearch()
                }
            }
            .disabled(manualQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSearching)
            .opacity(manualQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
        }
        .padding()
        .background(Color.deckSurface.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    private func warningBanner(text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.deckWarning)
            Text(text)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundColor(.deckTextPrimary)
            Spacer()
        }
        .padding()
        .background(Color.deckSurface.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    private func runManualSearch() async {
        let query = manualQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        
        isSearching = true
        errorMessage = nil
        
        do {
            let hint = ParsedCardHint(
                nameGuess: query,
                nameFallbacks: [],
                numberGuess: nil,
                setNumberGuess: nil,
                setIdGuess: nil,
                rarityGuess: nil,
                rawLines: [query],
                language: .english,
                hp: nil,
                types: nil
            )
            let result = try await apiClient.searchCardsWithAttempts(hint: hint)
            if result.matches.isEmpty {
                errorMessage = "No matches found for \"\(query)\"."
            } else if result.matches.count == 1, autoConfirmSingleMatch {
                onShowDetail(result.matches[0])
            } else {
                onShowResults(result.matches)
            }
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
        }
        
        isSearching = false
    }
}
