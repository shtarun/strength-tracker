import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct DataManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showExportShareSheet = false
    @State private var showImportFilePicker = false
    @State private var showImportConfirmation = false
    @State private var showImportInsights = false
    @State private var exportData: Data?
    @State private var pendingImportData: Data?
    @State private var importPreview: (version: String, sessionCount: Int, dateRange: String)?
    @State private var importInsights: ImportInsights?
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            List {
                // Export Section
                Section {
                    Button {
                        exportAllData()
                    } label: {
                        HStack {
                            Label("Export All Data", systemImage: "square.and.arrow.up")
                            Spacer()
                            if isProcessing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(isProcessing)
                } header: {
                    Text("Export")
                } footer: {
                    Text("Export your complete workout history, settings, and progress to a JSON file. Share it across devices or keep as a backup.")
                }
                
                // Import Section
                Section {
                    Button {
                        showImportFilePicker = true
                    } label: {
                        HStack {
                            Label("Import Data", systemImage: "square.and.arrow.down")
                            Spacer()
                            if isProcessing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(isProcessing)
                } header: {
                    Text("Import")
                } footer: {
                    Text("Import workout data from a StrengthTracker export file. Data will be merged with your existing workouts—duplicates are automatically skipped.")
                }
                
                // Format Info
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("JSON Format v\(StrengthTrackerExport.currentVersion)", systemImage: "doc.text")
                            .font(.headline)
                        
                        Text("The export file includes:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            FormatInfoRow(icon: "person.fill", text: "User profile & preferences")
                            FormatInfoRow(icon: "dumbbell.fill", text: "Equipment configuration")
                            FormatInfoRow(icon: "calendar", text: "All workout sessions")
                            FormatInfoRow(icon: "figure.strengthtraining.traditional", text: "Exercise sets & history")
                            FormatInfoRow(icon: "exclamationmark.triangle", text: "Pain flags")
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("File Format")
                }
            }
            .navigationTitle("Data Management")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showExportShareSheet) {
                if let data = exportData {
                    ShareSheet(
                        activityItems: [ExportFileProvider(data: data, filename: DataTransferService.shared.exportFileName())]
                    )
                }
            }
            .fileImporter(
                isPresented: $showImportFilePicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .alert("Import Data?", isPresented: $showImportConfirmation) {
                Button("Cancel", role: .cancel) {
                    pendingImportData = nil
                    importPreview = nil
                }
                Button("Import") {
                    performImport()
                }
            } message: {
                if let preview = importPreview {
                    Text("Found \(preview.sessionCount) workout sessions from \(preview.dateRange).\n\nThis will add new data to your existing workouts.")
                }
            }
            .sheet(isPresented: $showImportInsights) {
                if let insights = importInsights {
                    ImportInsightsView(insights: insights)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
        }
    }
    
    private func exportAllData() {
        isProcessing = true
        
        Task {
            do {
                let data = try DataTransferService.shared.exportData(from: modelContext)
                exportData = data
                showExportShareSheet = true
            } catch {
                errorMessage = "Failed to export data: \(error.localizedDescription)"
                showError = true
            }
            isProcessing = false
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            // Access security scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "Unable to access the selected file"
                showError = true
                return
            }
            
            defer { url.stopAccessingSecurityScopedResource() }
            
            do {
                let data = try Data(contentsOf: url)
                let preview = try DataTransferService.shared.validateImportData(data)
                
                pendingImportData = data
                importPreview = preview
                showImportConfirmation = true
            } catch {
                errorMessage = "Invalid file format: \(error.localizedDescription)"
                showError = true
            }
            
        case .failure(let error):
            errorMessage = "Failed to read file: \(error.localizedDescription)"
            showError = true
        }
    }
    
    private func performImport() {
        guard let data = pendingImportData else { return }
        
        isProcessing = true
        
        Task {
            do {
                let insights = try DataTransferService.shared.importData(from: data, into: modelContext)
                importInsights = insights
                showImportInsights = true
            } catch {
                errorMessage = "Import failed: \(error.localizedDescription)"
                showError = true
            }
            
            pendingImportData = nil
            importPreview = nil
            isProcessing = false
        }
    }
}

// MARK: - Supporting Views

struct FormatInfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 16)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct ImportInsightsView: View {
    @Environment(\.dismiss) private var dismiss
    let insights: ImportInsights
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.green)
                        VStack(alignment: .leading) {
                            Text("Import Complete")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Your data has been merged successfully")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    
                    // Stats Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatCard(
                            title: "Sessions",
                            value: "\(insights.sessionsImported)",
                            icon: "calendar.badge.plus",
                            color: .blue
                        )
                        StatCard(
                            title: "Sets",
                            value: "\(insights.setsImported)",
                            icon: "figure.strengthtraining.traditional",
                            color: .purple
                        )
                        StatCard(
                            title: "Volume",
                            value: formatVolume(insights.totalVolumeImported),
                            icon: "scalemass",
                            color: .orange
                        )
                        StatCard(
                            title: "Skipped",
                            value: "\(insights.duplicatesSkipped)",
                            icon: "arrow.triangle.2.circlepath",
                            color: .gray
                        )
                    }
                    
                    // Date Range
                    if let range = insights.dateRange {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Date Range", systemImage: "calendar")
                                .font(.headline)
                            
                            HStack {
                                let formatter = DateFormatter()
                                let _ = formatter.dateStyle = .medium
                                Text(formatter.string(from: range.lowerBound))
                                Image(systemName: "arrow.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(formatter.string(from: range.upperBound))
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    
                    // Top Exercises
                    if !insights.topExercises.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Top Exercises", systemImage: "trophy.fill")
                                .font(.headline)
                                .foregroundStyle(.orange)
                            
                            ForEach(insights.topExercises.prefix(5), id: \.name) { exercise in
                                HStack {
                                    Text(exercise.name)
                                        .font(.subheadline)
                                    Spacer()
                                    Text("\(exercise.sets) sets")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color(.tertiarySystemBackground))
                                        .cornerRadius(6)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    
                    // New Exercises Found
                    if !insights.newExercisesFound.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("New Exercises Found", systemImage: "sparkles")
                                .font(.headline)
                                .foregroundStyle(.cyan)
                            
                            Text("These exercises weren't in your library and were imported without linking:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            InsightsFlowLayout(spacing: 8) {
                                ForEach(insights.newExercisesFound.prefix(15), id: \.self) { name in
                                    Text(name)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.cyan.opacity(0.15))
                                        .foregroundStyle(.cyan)
                                        .cornerRadius(8)
                                }
                            }
                            
                            if insights.newExercisesFound.count > 15 {
                                Text("... and \(insights.newExercisesFound.count - 15) more")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    
                    // Errors/Warnings
                    if !insights.errors.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Warnings", systemImage: "exclamationmark.triangle.fill")
                                .font(.headline)
                                .foregroundStyle(.yellow)
                            
                            ForEach(insights.errors, id: \.self) { error in
                                Text("• \(error)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background(Color.yellow.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Import Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1_000_000 {
            return String(format: "%.1fM kg", volume / 1_000_000)
        } else if volume >= 1000 {
            return String(format: "%.0fK kg", volume / 1000)
        } else {
            return String(format: "%.0f kg", volume)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Flow Layout for Tags

struct InsightsFlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = InsightsFlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = InsightsFlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }
    
    struct InsightsFlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                
                self.size.width = max(self.size.width, x - spacing)
            }
            
            self.size.height = y + rowHeight
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Export File Provider

class ExportFileProvider: NSObject, UIActivityItemSource {
    let data: Data
    let filename: String
    
    init(data: Data, filename: String) {
        self.data = data
        self.filename = filename
        super.init()
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        filename
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? data.write(to: tempURL)
        return tempURL
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        "StrengthTracker Data Export"
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        UTType.json.identifier
    }
}

#Preview {
    DataManagementView()
        .modelContainer(for: [UserProfile.self, WorkoutSession.self], inMemory: true)
}

#Preview("Import Insights") {
    ImportInsightsView(insights: ImportInsights(
        sessionsImported: 45,
        setsImported: 892,
        newExercisesFound: ["Custom Press", "Modified Row", "Special Squat"],
        dateRange: Date().addingTimeInterval(-90*24*3600)...Date(),
        totalVolumeImported: 125_450,
        topExercises: [
            ("Bench Press", 156),
            ("Squat", 134),
            ("Deadlift", 98),
            ("Overhead Press", 78),
            ("Barbell Row", 67)
        ],
        duplicatesSkipped: 3,
        errors: []
    ))
}
