import SwiftUI
import SwiftData
import PhotosUI

struct PhotoTimelineView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ProgressPhoto.date, order: .reverse) private var photos: [ProgressPhoto]
    @StateObject private var purchaseManager = PurchaseManager.shared

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showPoseChooser = false
    @State private var pendingImageData: Data?
    @State private var selectedPose = "Front"
    @State private var bodyWeightText = ""
    @State private var filterPose = "All"
    @State private var compareSelection: [ProgressPhoto] = []
    @State private var showCompare = false
    @State private var confirmDelete: ProgressPhoto?

    private var poses: [String] {
        var seen: [String] = ["All"]
        for p in photos where !seen.contains(p.pose) { seen.append(p.pose) }
        return seen
    }

    private var filtered: [ProgressPhoto] {
        filterPose == "All" ? photos : photos.filter { $0.pose == filterPose }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if compareSelection.count == 2 {
                        compareButton
                    }
                    poseFilter
                    if filtered.isEmpty {
                        emptyState
                    } else {
                        photoGrid
                    }
                }
                .padding(.horizontal)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.charcoal)
            .navigationTitle("Photos")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    PhotosPicker(selection: $selectedItems, matching: .images) {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add progress photo")
                }
            }
            .onChange(of: selectedItems) { _, items in
                guard let item = items.first else { return }
                selectedItems = []
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        pendingImageData = data
                        showPoseChooser = true
                    }
                }
            }
            .sheet(isPresented: $showPoseChooser) { poseChooserSheet }
            .sheet(isPresented: $showCompare) { CompareSheet(photos: compareSelection) }
            .alert("Delete Photo", isPresented: .init(
                get: { confirmDelete != nil },
                set: { if !$0 { confirmDelete = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    if let photo = confirmDelete {
                        context.delete(photo)
                        try? context.save()
                        compareSelection.removeAll { $0.id == photo.id }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This photo will be removed from your timeline and iCloud.")
            }
        }
    }

    private var compareButton: some View {
        Button {
            showCompare = true
        } label: {
            Label("Compare selected photos", systemImage: "arrow.left.arrow.right.square.fill")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(.borderedProminent)
        .tint(Theme.orange)
    }

    private var poseFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(poses, id: \.self) { pose in
                    Button {
                        filterPose = pose
                        compareSelection = []
                    } label: {
                        Text(pose)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(filterPose == pose ? Theme.orange : Theme.surface))
                            .foregroundStyle(filterPose == pose ? .white : .primary)
                    }
                }
            }
        }
    }

    private var photoGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            ForEach(filtered, id: \.id) { photo in
                photoCell(photo)
            }
        }
    }

    private func photoCell(_ photo: ProgressPhoto) -> some View {
        let isSelected = compareSelection.contains { $0.id == photo.id }
        return Button {
            toggleSelect(photo)
        } label: {
            ZStack(alignment: .topTrailing) {
                if let ui = UIImage(data: photo.photoData) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .clipped()
                }
                VStack {
                    HStack {
                        Text(photo.pose)
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(.black.opacity(0.55)))
                            .foregroundStyle(.white)
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Theme.gold)
                        }
                    }
                    Spacer()
                    HStack {
                        Text(photo.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(.black.opacity(0.55)))
                            .foregroundStyle(.white)
                        Spacer()
                        Menu {
                            Button("Delete", role: .destructive) { confirmDelete = photo }
                        } label: {
                            Image(systemName: "ellipsis.circle.fill")
                                .foregroundStyle(.white)
                        }
                    }
                }
                .padding(6)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isSelected ? Theme.gold : .clear, lineWidth: 3)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Delete", role: .destructive) { confirmDelete = photo }
        }
    }

    private func toggleSelect(_ photo: ProgressPhoto) {
        if let idx = compareSelection.firstIndex(where: { $0.id == photo.id }) {
            compareSelection.remove(at: idx)
        } else {
            if compareSelection.count == 2 { compareSelection.removeFirst() }
            compareSelection.append(photo)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 44))
                .foregroundStyle(Theme.orange)
            Text("Your progress timeline")
                .font(.headline)
            Text("Same pose, same lighting, every month. Tap two photos to compare.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            PhotosPicker(selection: $selectedItems, matching: .images) {
                Text("Add First Photo")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var poseChooserSheet: some View {
        NavigationStack {
            Form {
                Section("Pose") {
                    Picker("Pose", selection: $selectedPose) {
                        ForEach(["Front", "Side", "Back"], id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                }
                Section {
                    TextField("Body weight lb (optional)", text: $bodyWeightText)
                        .keyboardType(.decimalPad)
                }
                Section {
                    Button("Save to Timeline") {
                        savePending()
                    }
                }
            }
            .navigationTitle("New Progress Photo")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }

    private func savePending() {
        guard let data = pendingImageData else { return }
        let weight = Double(bodyWeightText) ?? 0
        context.insert(ProgressPhoto(date: .now, photoData: data, pose: selectedPose, bodyWeight: weight))
        try? context.save()
        pendingImageData = nil
        bodyWeightText = ""
        showPoseChooser = false
    }
}

struct CompareSheet: View {
    @Environment(\.dismiss) private var dismiss
    let photos: [ProgressPhoto]
    @State private var slider: CGFloat = 0.5

    private var before: ProgressPhoto? { photos.min { $0.date < $1.date } }
    private var after: ProgressPhoto? { photos.max { $0.date < $1.date } }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if let before, let after, let bImage = UIImage(data: before.photoData), let aImage = UIImage(data: after.photoData) {
                    GeometryReader { geo in
                        ZStack {
                            Image(uiImage: aImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: geo.size.width)
                            Image(uiImage: bImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: geo.size.width)
                                .mask(
                                    HStack(spacing: 0) {
                                        Rectangle().frame(width: geo.size.width * slider)
                                        Color.clear
                                    }
                                )
                            Rectangle()
                                .fill(Theme.gold)
                                .frame(width: 2)
                                .frame(maxHeight: .infinity)
                                .position(x: geo.size.width * slider, y: geo.size.height / 2)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .gesture(
                            DragGesture(minimumDistance: 0).onChanged { value in
                                slider = min(1, max(0, value.location.x / geo.size.width))
                            }
                        )
                    }
                    HStack {
                        VStack(spacing: 2) {
                            Text(before.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption.weight(.semibold))
                            if before.bodyWeight > 0 { Text("\(Int(before.bodyWeight)) lb").font(.caption2).foregroundStyle(.secondary) }
                        }
                        Spacer()
                        Text("Drag to compare")
                            .font(.caption)
                            .foregroundStyle(Theme.gold)
                        Spacer()
                        VStack(spacing: 2) {
                            Text(after.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption.weight(.semibold))
                            if after.bodyWeight > 0 { Text("\(Int(after.bodyWeight)) lb").font(.caption2).foregroundStyle(.secondary) }
                        }
                    }
                    let days = DayKey.daysBetween(before.date, after.date)
                    if days > 0 {
                        Text("\(days) days between photos — same pose, same you, more gains.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Pick two photos to compare.")
                }
            }
            .padding()
            .navigationTitle("Compare")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
