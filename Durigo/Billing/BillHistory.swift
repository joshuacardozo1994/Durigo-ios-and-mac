//
//  BillHistory.swift
//  Durigo
//
//  Detail view for a single bill. Lets the user change the payment status
//  (mark as paid via Cash / UPI / Card, or back to Pending) and re-upload
//  the change to the server.
//

import SwiftUI

struct BillHistory: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(Session.self) private var session
    @EnvironmentObject private var menuLoader: MenuLoader
    @EnvironmentObject private var navigation: Navigation

    @State private var showingBillRegenerateAlert = false
    @State private var uploader: BillUploader?
    @State private var changingPayment = false
    @State private var paymentError: String?

    let billHistoryItem: BillHistoryItem

    var body: some View {
        VStack(spacing: 0) {
            paymentHeader
            List {
                ForEach(billHistoryItem.items) { menuItem in
                    HStack {
                        Text(String(format: "%.1f ", menuItem.quantity))
                        +
                        Text(menuItem.servingSize?.shouldDisplay == true ? "\(menuItem.servingSize?.name ?? "") " : "").bold()
                        +
                        Text("\(menuItem.name)")
                        Spacer()
                        Text("\(Int(menuItem.price * menuItem.quantity))")
                    }
                }
            }
            totalSection
        }
        .alert("Are you sure you want to regenerate the bill", isPresented: $showingBillRegenerateAlert) {
            Button("Regenerate", role: .destructive) {
                menuLoader.billItems = billHistoryItem.items
                menuLoader.tableNumber = billHistoryItem.tableNumber
                menuLoader.waiter = billHistoryItem.waiter
                menuLoader.billID = billHistoryItem.id
                navigation.selection = .pos
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert(
            "Couldn't sync payment change",
            isPresented: Binding(
                get: { paymentError != nil },
                set: { if !$0 { paymentError = nil } }
            ),
            presenting: paymentError
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { msg in
            Text(msg)
        }
        .navigationTitle("\(billHistoryItem.tableNumber == 0 ? "Parcel Bill" : "Table \(billHistoryItem.tableNumber) Bill")")
        .toolbar {
            paymentMenuButton
            regenerateButton
        }
        .onAppear {
            if uploader == nil { uploader = BillUploader(session: session) }
        }
    }

    // MARK: - Payment header (status chip + change menu)

    private var paymentHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Payment")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                statusChip
            }
            Spacer()
            if changingPayment {
                ProgressView()
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    private var statusChip: some View {
        let (label, color) = paymentStatusDisplay(billHistoryItem.paymentStatus)
        return HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(.body, weight: .semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(color.opacity(0.12)))
        .overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 0.5))
    }

    private func paymentStatusDisplay(_ status: BillHistoryItemStatus) -> (String, Color) {
        switch status {
        case .paidByCash: ("Cash", .green)
        case .paidByUPI:  ("UPI", .purple)
        case .paidByCard: ("Card", .blue)
        case .pending:    ("Pending", .orange)
        }
    }

    // MARK: - Toolbar buttons

    private var paymentMenuButton: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button { setPaymentStatus(.paidByCash) } label: {
                    if billHistoryItem.paymentStatus == .paidByCash {
                        Label("Cash", systemImage: "checkmark")
                    } else {
                        Text("Cash")
                    }
                }
                Button { setPaymentStatus(.paidByUPI) } label: {
                    if billHistoryItem.paymentStatus == .paidByUPI {
                        Label("UPI", systemImage: "checkmark")
                    } else {
                        Text("UPI")
                    }
                }
                Button { setPaymentStatus(.paidByCard) } label: {
                    if billHistoryItem.paymentStatus == .paidByCard {
                        Label("Card", systemImage: "checkmark")
                    } else {
                        Text("Card")
                    }
                }
                Divider()
                Button { setPaymentStatus(.pending) } label: {
                    if billHistoryItem.paymentStatus == .pending {
                        Label("Pending", systemImage: "checkmark")
                    } else {
                        Text("Pending")
                    }
                }
            } label: {
                Label("Payment", systemImage: "creditcard")
            }
            .disabled(changingPayment)
            .accessibilityIdentifier("bill-payment-menu")
        }
    }

    private var regenerateButton: some ToolbarContent {
        ToolbarItem(placement: .secondaryAction) {
            Button {
                showingBillRegenerateAlert.toggle()
            } label: {
                Label("Regenerate", systemImage: "arrow.clockwise")
            }
        }
    }

    // MARK: - Total

    private var totalSection: some View {
        HStack {
            Text("\(billHistoryItem.items.count) Items")
            Spacer()
            Text("Total: \(billHistoryItem.items.getTotal())")
        }
        .padding(.horizontal)
        .font(.title)
        .bold()
    }

    // MARK: - Apply payment change

    private func setPaymentStatus(_ status: BillHistoryItemStatus) {
        guard billHistoryItem.paymentStatus != status else { return }
        let previous = billHistoryItem.paymentStatus

        billHistoryItem.paymentStatus = status
        billHistoryItem.syncedAt = nil
        try? modelContext.save()

        guard let uploader else { return }
        Task { @MainActor in
            changingPayment = true
            defer { changingPayment = false }
            do {
                try await uploader.uploadOne(billHistoryItem)
            } catch {
                // Roll back on network/server failure so SwiftData stays
                // consistent with the server.
                billHistoryItem.paymentStatus = previous
                try? modelContext.save()
                paymentError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        }
    }
}

#Preview {
    BillHistory(billHistoryItem: BillHistoryItem(id: UUID(), items: [MenuItem](), tableNumber: 1, waiter: "anthony"))
}
