//
//  BillHistoryList.swift
//  Durigo
//
//  Created by Joshua Cardozo on 19/11/23.
//

import SwiftUI
import SwiftData
import LocalAuthentication

struct BillHistoryList: View {
    @State private var selectedTable: Int?
    @State private var selectedWaiter: String?
    @State private var showTodaysBills = false
    @State private var sharingURL: URL?
    @State private var selectedPaymentStatus: BillHistoryItemStatus?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.scenePhase) private var scenePhase

    // Pagination state
    private let pageSize = 20
    @State private var displayedItems: [BillHistoryItem] = []
    @State private var currentPage = 0
    @State private var hasMoreItems = true
    @State private var isLoading = false

    // Bill sync state
    @State private var uploader = BillUploader()
    @State private var showingSyncSettings = false
    @State private var syncErrorMessage: String?
    @State private var lastSyncSummary: UploadSummary?
    @State private var lastDownloadSummary: DownloadSummary?
    @State private var selectedBillID: UUID?

    func setAppBadgeCount() {
//        let pendingBillsCount = (billHistoryItems.filter { $0.paymentStatus == .pending }).count
//        UNUserNotificationCenter.current().setBadgeCount(pendingBillsCount)
    }

    private func loadItems(reset: Bool = false) {
        guard !isLoading else { return }
        isLoading = true

        if reset {
            currentPage = 0
            displayedItems = []
            hasMoreItems = true
        }

        // Build date predicate when filtering to today only (can be pushed to DB)
        let predicate: Predicate<BillHistoryItem>?
        if showTodaysBills {
            let startOfDay = Calendar.current.startOfDay(for: Date())
            let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
            predicate = #Predicate<BillHistoryItem> { $0.date >= startOfDay && $0.date < endOfDay }
        } else {
            predicate = nil
        }

        var descriptor = FetchDescriptor<BillHistoryItem>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        // Only paginate when no in-memory filters are active; otherwise fetch all matching rows
        let hasInMemoryFilters = selectedTable != nil || selectedWaiter != nil || selectedPaymentStatus != nil
        if !hasInMemoryFilters {
            descriptor.fetchLimit = pageSize
            descriptor.fetchOffset = currentPage * pageSize
        }

        do {
            let fetchedItems = try modelContext.fetch(descriptor)

            // Apply remaining filters in-memory (table, waiter, payment status)
            let newItems = fetchedItems.filter { item in
                if let selectedTable, item.tableNumber != selectedTable { return false }
                if let selectedWaiter, item.waiter != selectedWaiter { return false }
                if let selectedPaymentStatus, item.paymentStatus != selectedPaymentStatus { return false }
                return true
            }

            if reset {
                displayedItems = newItems
            } else {
                displayedItems.append(contentsOf: newItems)
            }

            // Only track "more pages" when pagination is active
            hasMoreItems = !hasInMemoryFilters && fetchedItems.count == pageSize
            currentPage += 1
        } catch {
            print("Failed to fetch items: \(error)")
        }

        isLoading = false
    }

    private func loadMoreIfNeeded(currentItem: BillHistoryItem) {
        guard hasMoreItems, !isLoading else { return }
        let thresholdIndex = displayedItems.index(displayedItems.endIndex, offsetBy: -5)
        if let currentIndex = displayedItems.firstIndex(where: { $0.id == currentItem.id }),
           currentIndex >= thresholdIndex {
            loadItems()
        }
    }

    @ViewBuilder
    private func syncIndicator(for bill: BillHistoryItem) -> some View {
        if bill.syncedAt != nil {
            Image(systemName: "checkmark.icloud.fill")
                .font(.caption)
                .foregroundStyle(.green)
                .accessibilityLabel("Synced")
                .accessibilityIdentifier("syncStatus-synced-\(bill.id.uuidString)")
        } else {
            Button {
                Task { await syncOne(bill) }
            } label: {
                Image(systemName: "icloud.and.arrow.up")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Upload")
            .accessibilityIdentifier("syncStatus-pending-\(bill.id.uuidString)")
        }
    }

    private func unsyncedBills() throws -> [BillHistoryItem] {
        let descriptor = FetchDescriptor<BillHistoryItem>(
            predicate: #Predicate { $0.syncedAt == nil },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    private func syncOne(_ bill: BillHistoryItem) async {
        do {
            try await uploader.uploadOne(bill)
            try? modelContext.save()
        } catch let err as BillSyncError {
            syncErrorMessage = err.errorDescription
        } catch {
            syncErrorMessage = error.localizedDescription
        }
    }

    private func pullFromServer() async {
        do {
            let summary = try await uploader.downloadAll(into: modelContext)
            lastDownloadSummary = summary
            loadItems(reset: true)
        } catch let err as BillSyncError {
            syncErrorMessage = err.errorDescription
        } catch {
            syncErrorMessage = error.localizedDescription
        }
    }

    private func syncAllUnsynced(batchSize: Int = 200, silentIfEmpty: Bool = true) async {
        do {
            let bills = try unsyncedBills()
            guard !bills.isEmpty else {
                if !silentIfEmpty {
                    lastSyncSummary = UploadSummary(attempted: 0, succeeded: [], failed: [])
                }
                return
            }
            var totalSucceeded: [UUID] = []
            var totalFailed: [(id: UUID, error: BillSyncError)] = []
            for chunk in stride(from: 0, to: bills.count, by: batchSize) {
                let slice = Array(bills[chunk..<min(chunk + batchSize, bills.count)])
                let summary = try await uploader.uploadMany(slice)
                totalSucceeded.append(contentsOf: summary.succeeded)
                totalFailed.append(contentsOf: summary.failed)
                try? modelContext.save()
            }
            lastSyncSummary = UploadSummary(
                attempted: bills.count,
                succeeded: totalSucceeded,
                failed: totalFailed
            )
        } catch let err as BillSyncError {
            syncErrorMessage = err.errorDescription
        } catch {
            syncErrorMessage = error.localizedDescription
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if displayedItems.isEmpty && !isLoading {
                    VStack {
                        Spacer()
                        ContentUnavailableView(
                            "No Bills available\(showTodaysBills ? " for today" : "") \(selectedTable != nil ? " for this table" : "")",
                            systemImage: "exclamationmark.triangle",
                            description: Text("Try a different filter, or clear your filters")
                        )
                        Spacer()
                    }
                } else {
                List {

                    ForEach(displayedItems) { billHistoryItem in
                        NavigationLink {
                            BillHistory(billHistoryItem: billHistoryItem)
                        } label: {
                            VStack(alignment: .leading, spacing: 12) {
                                // Top: Table and Amount
                                HStack(alignment: .firstTextBaseline) {
                                    Text(billHistoryItem.tableNumber == 0 ? "Parcel" : "Table \(billHistoryItem.tableNumber)")
                                        .font(.headline)

                                    syncIndicator(for: billHistoryItem)

                                    Spacer()

                                    Text(billHistoryItem.items.getTotal().asCurrencyString() ?? "")
                                        .font(.system(.title3, design: .rounded))
                                        .fontWeight(.semibold)
                                        .accessibilityIdentifier("BillHistoryList-Item-\(billHistoryItem.id.uuidString)")
                                }
                                
                                // Middle: Details
                                HStack {
                                    Menu {
                                        Menu {
                                            Button(action: {
                                                billHistoryItem.paymentStatus = .paidByCash
                                                setAppBadgeCount()
                                            }) {
                                                Label("Cash", systemImage: "banknote")
                                            }
                                            
                                            Button(action: {
                                                billHistoryItem.paymentStatus = .paidByUPI
                                                setAppBadgeCount()
                                            }) {
                                                Label("UPI", systemImage: "indianrupeesign")
                                            }
                                            
                                            Button(action: {
                                                billHistoryItem.paymentStatus = .paidByCard
                                                setAppBadgeCount()
                                            }) {
                                                Label("Card", systemImage: "creditcard")
                                            }
                                        } label: {
                                            Label("Paid", systemImage: "checkmark.circle")
                                        }
                                        
                                        Button(action: {
                                            billHistoryItem.paymentStatus = .pending
                                            setAppBadgeCount()
                                        }) {
                                            Label("Pending", systemImage: "hourglass")
                                        }
                                        
                                    } label: {
                                        HStack(spacing: 6) {
                                            switch billHistoryItem.paymentStatus {
                                            case .pending:
                                                Circle()
                                                    .fill(Color.red)
                                                    .frame(width: 6, height: 6)
                                                Text("Pending")
                                                    .font(.subheadline)
                                                    .foregroundStyle(.red)
                                            case .paidByCard:
                                                Circle()
                                                    .fill(Color(red: 0.5, green: 0.4, blue: 0.9))
                                                    .frame(width: 6, height: 6)
                                                Text("Card")
                                                    .font(.subheadline)
                                                    .foregroundStyle(.secondary)
                                            case .paidByCash:
                                                Circle()
                                                    .fill(Color(red: 0.2, green: 0.7, blue: 0.3))
                                                    .frame(width: 6, height: 6)
                                                Text("Cash")
                                                    .font(.subheadline)
                                                    .foregroundStyle(.secondary)
                                            case .paidByUPI:
                                                Circle()
                                                    .fill(Color(red: 1.0, green: 0.6, blue: 0.2))
                                                    .frame(width: 6, height: 6)
                                                Text("UPI")
                                                    .font(.subheadline)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        .accessibilityIdentifier("paymentStatus-\(billHistoryItem.id)")
                                    }
                                    
                                    Text("•")
                                        .foregroundStyle(.tertiary)
                                    
                                    Text("\(billHistoryItem.items.count) items")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    
                                    Text("•")
                                        .foregroundStyle(.tertiary)
                                    
                                    Text(billHistoryItem.waiter)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                
                                // Bottom: Date
                                Text(billHistoryItem.date.getTimeInFormat(dateStyle: .medium, timeStyle: .short))
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 8)
                        }
                        .onAppear {
                            loadMoreIfNeeded(currentItem: billHistoryItem)
                        }
                    }

                    if hasMoreItems {
                        HStack {
                            Spacer()
                            ProgressView()
                                .onAppear {
                                    loadItems()
                                }
                            Spacer()
                        }
                    }
                }

            }
            }
            .onAppear {
                if displayedItems.isEmpty {
                    loadItems(reset: true)
                }
            }
            .onChange(of: showTodaysBills) { _, _ in loadItems(reset: true) }
            .onChange(of: selectedTable) { _, _ in loadItems(reset: true) }
            .onChange(of: selectedWaiter) { _, _ in loadItems(reset: true) }
            .onChange(of: selectedPaymentStatus) { _, _ in loadItems(reset: true) }
            .refreshable {
                loadItems(reset: true)
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                Menu {
                    Button(action: {
                        showTodaysBills.toggle()
                    }) {
                        Label("\(showTodaysBills ? "●" : "") Show todays bills", systemImage: "calendar")
                    }
                    TableDropdownSelector(showIfSelected: true, selectedOption: $selectedTable, options: Array(1...20))
                    WaiterDropdownSelector(showIfSelected: true, selectedOption: $selectedWaiter, options: ["Alcin", "Anthony", "Antone", "Amanda", "Monica", "Joshua"])
                    
                    Menu {
                        Menu {
                            Button(action: {
                                selectedPaymentStatus = .paidByCash
                            }) {
                                Label("Cash", systemImage: "banknote")
                            }
                            
                            Button(action: {
                                selectedPaymentStatus = .paidByUPI
                            }) {
                                Label("UPI", systemImage: "indianrupeesign")
                            }
                            
                            Button(action: {
                                selectedPaymentStatus = .paidByCard
                            }) {
                                Label("Card", systemImage: "creditcard")
                            }
                        } label: {
                            Label("Paid", systemImage: "checkmark.circle")
                        }
                        
                        Button(action: {
                            selectedPaymentStatus = .pending
                        }) {
                            Label("Pending", systemImage: "hourglass")
                        }
                        
                    } label: {
                        VStack {
                            switch selectedPaymentStatus {
                            case .pending:
                                Label("Pending", systemImage: "hourglass")
                                    .foregroundStyle(Color.red)
                            case .paidByCard:
                                Label("Paid by card", systemImage: "creditcard")
                                    .foregroundStyle(Color.green)
                            case .paidByCash:
                                Label("Paid by cash", systemImage: "banknote")
                                    .foregroundStyle(Color.green)
                            case .paidByUPI:
                                Label("Paid by UPI", systemImage: "indianrupeesign")
                                    .foregroundStyle(Color.green)
                            case .none:
                                Label("Select a Payment Status", systemImage: "info")
                            }
                        }
                    }
                    Section {
                        Button(action: {
                            showTodaysBills = false
                            selectedTable = nil
                            selectedWaiter = nil
                            selectedPaymentStatus = nil
                        }) {
                            Label("Clear filters", systemImage: "xmark.circle")
                        }
                    }

                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .overlay(alignment: .topTrailing) {
                            let isFilterApplied = !(showTodaysBills == false && selectedTable == nil && selectedWaiter == nil && selectedPaymentStatus == nil)
                            Circle()
                                .fill(isFilterApplied ? Color.red : Color.clear)
                                .frame(width: 10, height: 10)
                        }
                }
            }
            .toolbar {
                if let sharingURL {
                    ShareLink(item: sharingURL)
                }
                Button(action: {
                    let url = URL.documentsDirectory.appending(path: "billsHistory.durigobills")
                    do {
                        // Fetch all items for sharing
                        let descriptor = FetchDescriptor<BillHistoryItem>(
                            sortBy: [SortDescriptor(\.date, order: .reverse)]
                        )
                        let allItems = try modelContext.fetch(descriptor)
                        let data = try JSONEncoder().encode(DurigoBills(items: allItems.map({ BillHistoryItemCopy(billHistoryItem: $0) })))
                        try data.write(to: url, options: [.atomic, .completeFileProtection])
                        sharingURL = url
                    } catch {
                        print("Failed to share: \(error)")
                    }
                }) {
                    Text("Share")
                }
            }
            .toolbar {
                Menu {
                    Button {
                        Task { await pullFromServer() }
                    } label: {
                        Label("Pull from Server", systemImage: "icloud.and.arrow.down.fill")
                    }
                    .disabled(uploader.isUploading)

                    Button {
                        Task { await syncAllUnsynced(silentIfEmpty: false) }
                    } label: {
                        Label("Sync All Unsynced", systemImage: "icloud.and.arrow.up.fill")
                    }
                    .disabled(uploader.isUploading)

                    Divider()

                    Button {
                        showingSyncSettings = true
                    } label: {
                        Label("Sync Settings", systemImage: "gearshape")
                    }
                } label: {
                    if uploader.isUploading {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "icloud")
                            .accessibilityIdentifier("syncMenu")
                    }
                }
            }
            .sheet(isPresented: $showingSyncSettings) {
                BillSyncSettings()
            }
            .alert("Sync Error", isPresented: .init(get: { syncErrorMessage != nil }, set: { if !$0 { syncErrorMessage = nil } })) {
                Button("OK") { syncErrorMessage = nil }
                Button("Settings") {
                    syncErrorMessage = nil
                    showingSyncSettings = true
                }
            } message: {
                Text(syncErrorMessage ?? "")
            }
            .alert("Sync Complete", isPresented: .init(get: { lastSyncSummary != nil }, set: { if !$0 { lastSyncSummary = nil } })) {
                Button("OK") { lastSyncSummary = nil }
            } message: {
                if let s = lastSyncSummary {
                    Text("\(s.succeeded.count) of \(s.attempted) bills synced.\(s.failed.isEmpty ? "" : " \(s.failed.count) failed.")")
                }
            }
            .overlay(alignment: .bottom) {
                if let progress = uploader.progress, uploader.isUploading {
                    HStack(spacing: 12) {
                        ProgressView(value: Double(progress.done), total: Double(progress.total))
                            .progressViewStyle(.linear)
                            .frame(maxWidth: 200)
                        Text("\(progress.done)/\(progress.total)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.regularMaterial, in: Capsule())
                    .padding(.bottom, 24)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active && KeychainHelper.load(.billUploadToken) != nil {
                    Task {
                        await pullFromServer()
                        await syncAllUnsynced()
                    }
                }
            }
            .task {
                // First-render trigger (scenePhase onChange doesn't fire on initial launch).
                // Pull server bills into SwiftData, then push any locally-unsynced ones up.
                if KeychainHelper.load(.billUploadToken) != nil {
                    await pullFromServer()
                    await syncAllUnsynced()
                }
            }
        }
        .lockWithBiometric()

    }
}

#if DEBUG
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: BillHistoryItem.self, configurations: config)
    
    PreviewData.billHistoryItems.forEach { billHistoryItem in
        container.mainContext.insert(billHistoryItem)
    }
    return BillHistoryList()
        .modelContainer(container)

}
#endif
