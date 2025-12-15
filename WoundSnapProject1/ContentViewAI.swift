//
//  ContentViewAI.swift
//  WoundSnapProject1
//
//  Created by Syed Taha Shah on 12/6/25.
//

import SwiftUI
import CoreML
import ParseSwift
import Combine
import Foundation
import Vision

// — OPENFDA INTEGRATION START —

struct FDAResult: Codable, Sendable {
    let results: [DrugInfo]
}

struct DrugInfo: Codable, Hashable, Identifiable, Sendable {
    var id: String { UUID().uuidString }
    
    let purpose: [String]?
    let indications_and_usage: [String]?
    let warnings: [String]?
    let dosage_and_administration: [String]?
}

struct FDAError: Codable, Sendable {
    let error: FDAErrorMessage
}

struct FDAErrorMessage: Codable, Sendable {
    let code: String
    let message: String
}

@MainActor
class FDAService: ObservableObject {
    @Published var info: DrugInfo?
    @Published var infos: [DrugInfo] = []
    @Published var isLoading = false
    @Published var searchedDrugs: [String] = []

    func fetchInfo(for drug: String) async {
        isLoading = true
        
        let cleanDrug = drug.trimmingCharacters(in: .whitespacesAndNewlines)
        let query = cleanDrug.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cleanDrug
        
        let urlString = "https://api.fda.gov/drug/label.json?search=openfda.generic_name:\(query)&limit=1&api_key=WQt303NWHLUHhWYOgUrbrUJG6SMaRI4gRLZ1Xh1h"

        print("🔍 Fetching FDA info for: \(drug) → URL: \(urlString)")

        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL for drug: \(drug)")
            isLoading = false
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            let decoded = try JSONDecoder().decode(FDAResult.self, from: data)
            print("✅ Successfully decoded FDA response for \(drug)")
            
            if let first = decoded.results.first {
                self.infos.append(first)
                print("✅ Added FDA info for \(drug). Total: \(self.infos.count)")
            } else {
                print("⚠️ No results in FDA response for \(drug)")
            }
            
        } catch {
            print("❌ Failed to decode FDA response for \(drug): \(error)")
        }
        
        isLoading = false
    }

    func fetchMultiple(drugs: [String]) async {
        self.infos.removeAll()
        self.searchedDrugs = drugs
        self.isLoading = true
        
        print("📋 Starting FDA fetch for drugs: \(drugs)")
        
        for drug in drugs {
            await fetchInfo(for: drug)
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds between requests
        }
        
        self.isLoading = false
        print("✅ Finished fetching all drugs. Total infos: \(self.infos.count)")
    }
}

struct DrugRecommendation {
    static let mapping: [String: [String]] = [
        "abrasions": ["Neosporin", "Polysporin", "Bacitracin"],
        "burns": ["Silver Sulfadiazine", "Aloe Vera", "Hydrocortisone"],
        "bruises": ["Arnica", "Ibuprofen", "Acetaminophen"],
        "cut": ["Neosporin", "Bacitracin", "Betadine"],
        "laceration": ["Neosporin", "Betadine", "Hydrogen Peroxide"],
        "stab_wound": ["Betadine", "Hydrogen Peroxide", "Neosporin"],
        "ingrown_nails": ["Betadine", "Epsom Salt", "Hydrogen Peroxide"],
        "level0": ["Salicylic Acid", "Benzoyl Peroxide", "Glycolic Acid"],
        "level1": ["Benzoyl Peroxide", "Salicylic Acid", "Tea Tree Oil"],
        "level2": ["Adapalene", "Benzoyl Peroxide", "Salicylic Acid"],
        "level3": ["Adapalene", "Benzoyl Peroxide", "Salicylic Acid"],
        "akiec": ["Fluorouracil", "Imiquimod", "Diclofenac"],
        "bcc": ["Fluorouracil", "Imiquimod", "Vismodegib"],
        "mel": ["Imiquimod", "Interferon", "Dabrafenib"],
        "nv": ["No treatment", "Hydrocortisone", "Aloe Vera"],
        "vasc": ["Propranolol", "Timolol", "Laser Therapy"],
        "bkl": ["Fluorouracil", "Imiquimod", "Cryotherapy"],
        "df": ["No treatment", "Hydrocortisone", "Aloe Vera"]
    ]
    
    static let fallbackDrugs = ["Neosporin", "Hydrocortisone", "Ibuprofen", "Acetaminophen", "Aloe Vera"]
}

func mapWoundToDrug(_ woundLabel: String) -> String {
    let label = woundLabel.lowercased()
    if label.contains("burn") { return "silver sulfadiazine" }
    if label.contains("cut") || label.contains("laceration") { return "bacitracin" }
    if label.contains("abrasion") { return "polysporin" }
    if label.contains("bruises") { return "arnica" }
    if label.contains("infection") { return "neosporin" }
    return "bacitracin"
}

// — OPENFDA INTEGRATION END —

struct ContentViewAI: View {
    @State private var inputImage: UIImage?
    @State private var showingImagePicker = false
    @State private var predictedClass = ""
    @State private var confidence = 0.0
    @State private var isAnalyzing = false
    @State private var errorMessage = ""
    @State private var userDescription: String = ""

    @StateObject private var fdaService = FDAService()

    private let classNames = [
        "abrasions", "akiec", "bcc", "bkl", "bruises",
        "burns", "cut", "df", "ingrown_nails", "laceration",
        "level0", "level1", "level2", "level3", "mel",
        "nv", "stab_wound", "vasc"
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 10) {
                        Image(systemName: "cross.case.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        Text("WoundSnap")
                            .font(.largeTitle)
                            .bold()
                        Text("AI Skin Analysis")
                            .foregroundColor(.secondary)
                        Text("Syed Taha Shah")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("Z23473148")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)

                    // Image Display
                    ZStack {
                        if let image = inputImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 280)
                                .cornerRadius(15)
                        } else {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.gray.opacity(0.1))
                                .frame(height: 280)
                                .overlay(
                                    VStack(spacing: 10) {
                                        Image(systemName: "photo.on.rectangle")
                                            .font(.system(size: 50))
                                            .foregroundColor(.gray)
                                        Text("No image selected")
                                            .foregroundColor(.gray)
                                    }
                                )
                        }
                    }
                    .padding(.horizontal)

                    // Error Message
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // Action Buttons
                    VStack(spacing: 15) {
                        Button(action: { showingImagePicker = true }) {
                            Label("Select Photo", systemImage: "photo.on.rectangle")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }

                        Button(action: { analyzeImage() }) {
                            HStack {
                                if isAnalyzing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                }
                                Text(isAnalyzing ? "Analyzing..." : "Analyze Image")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(inputImage == nil ? Color.gray : Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .disabled(inputImage == nil || isAnalyzing)
                        }
                    }
                    .padding(.horizontal)

                    // Results
                    if !predictedClass.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Analysis Result")
                                .font(.headline)

                            VStack(alignment: .leading, spacing: 8) {
                                Text(formatClassName(predictedClass))
                                    .font(.title2)
                                    .bold()
                                    .foregroundColor(.primary)

                                Text("\(Int(confidence * 100))% confident")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                medicalAdvice(for: predictedClass)

                                // Display FDA drug information
                                if !fdaService.infos.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Medications Found")
                                            .font(.headline)
                                            .foregroundColor(.blue)
                                        
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Searched for: \(fdaService.searchedDrugs.joined(separator: ", "))")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            
                                            Text("Found \(fdaService.infos.count) medication(s) in FDA database:")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 10) {
                                            ForEach(fdaService.infos) { drugInfo in
                                                VStack(alignment: .leading, spacing: 6) {
                                                    if let purpose = drugInfo.purpose?.first {
                                                        HStack {
                                                            Image(systemName: "pills.fill")
                                                                .foregroundColor(.blue)
                                                            Text(purpose)
                                                                .font(.body)
                                                                .foregroundColor(.primary)
                                                                .bold()
                                                        }
                                                        .padding(.bottom, 4)
                                                        
                                                        if let usage = drugInfo.indications_and_usage?.first {
                                                            VStack(alignment: .leading, spacing: 2) {
                                                                Text("Usage:")
                                                                    .font(.caption)
                                                                    .bold()
                                                                    .foregroundColor(.secondary)
                                                                Text(usage)
                                                                    .font(.caption)
                                                                    .foregroundColor(.secondary)
                                                                    .fixedSize(horizontal: false, vertical: true)
                                                            }
                                                            .padding(.bottom, 2)
                                                        }
                                                        
                                                        if let dosage = drugInfo.dosage_and_administration?.first {
                                                            VStack(alignment: .leading, spacing: 2) {
                                                                Text("Dosage:")
                                                                    .font(.caption)
                                                                    .bold()
                                                                    .foregroundColor(.secondary)
                                                                Text(dosage)
                                                                    .font(.caption)
                                                                    .foregroundColor(.secondary)
                                                                    .fixedSize(horizontal: false, vertical: true)
                                                            }
                                                            .padding(.bottom, 2)
                                                        }
                                                        
                                                        if let warnings = drugInfo.warnings?.first {
                                                            VStack(alignment: .leading, spacing: 2) {
                                                                Text("Warnings:")
                                                                    .font(.caption)
                                                                    .bold()
                                                                    .foregroundColor(.red)
                                                                Text(warnings)
                                                                    .font(.caption)
                                                                    .foregroundColor(.red)
                                                                    .fixedSize(horizontal: false, vertical: true)
                                                            }
                                                        }
                                                    } else {
                                                        Text("FDA Approved Medication")
                                                            .font(.body)
                                                            .foregroundColor(.primary)
                                                            .bold()
                                                    }
                                                }
                                                .padding(10)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .background(Color.blue.opacity(0.05))
                                                .cornerRadius(8)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                                                )
                                            }
                                        }
                                    }
                                    .padding(.top, 8)
                                } else if fdaService.isLoading {
                                    VStack(spacing: 12) {
                                        ProgressView()
                                            .scaleEffect(1.2)
                                            .padding(.bottom, 4)
                                        
                                        VStack(spacing: 4) {
                                            Text("Searching FDA Database...")
                                                .font(.subheadline)
                                                .foregroundColor(.primary)
                                            Text("Looking up medication information")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                                    .background(Color.gray.opacity(0.05))
                                    .cornerRadius(10)
                                } else if !predictedClass.isEmpty && !fdaService.isLoading {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Recommended Medications")
                                            .font(.headline)
                                            .foregroundColor(.orange)
                                        
                                        Text("Common treatments for \(formatClassName(predictedClass)):")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        
                                        if let recommendedDrugs = DrugRecommendation.mapping[predictedClass] {
                                            VStack(alignment: .leading, spacing: 8) {
                                                ForEach(recommendedDrugs, id: \.self) { drug in
                                                    HStack {
                                                        Image(systemName: "checkmark.circle.fill")
                                                            .foregroundColor(.green)
                                                        Text(drug)
                                                            .font(.body)
                                                            .foregroundColor(.primary)
                                                    }
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 6)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .background(Color.green.opacity(0.05))
                                                    .cornerRadius(6)
                                                }
                                            }
                                            .padding(10)
                                            .background(Color.orange.opacity(0.05))
                                            .cornerRadius(10)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                                            )
                                        }
                                    }
                                    .padding(.top, 8)
                                }

                                // User Description
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Add your description:")
                                        .font(.subheadline)
                                        .bold()
                                    TextEditor(text: $userDescription)
                                        .frame(height: 80)
                                        .padding(6)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                                        )
                                        .background(Color.gray.opacity(0.05))
                                        .cornerRadius(8)
                                }
                                .padding(.top, 8)

                                // Post button
                                Button(action: { uploadAnalyzedImage() }) {
                                    Label("Post this Image", systemImage: "square.and.arrow.up")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                                .padding(.top, 8)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(backgroundColor(for: predictedClass))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .transition(.opacity)
                    }

                    Spacer(minLength: 20)

                    // Footer
                    VStack(spacing: 4) {
                        Text("For educational purposes only")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Not a substitute for professional medical advice")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 20)
                    .padding(.top, 20)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $inputImage)
            }
            .onChange(of: inputImage) { _ in
                predictedClass = ""
                confidence = 0.0
                errorMessage = ""
                userDescription = ""
                fdaService.info = nil
                fdaService.infos.removeAll()
                fdaService.searchedDrugs.removeAll()
            }
        }
    }

    // MARK: - Helpers
    
    private func formatClassName(_ name: String) -> String {
        switch name {
        case "akiec": return "Actinic Keratosis"
        case "bcc": return "Basal Cell Carcinoma"
        case "bkl": return "Benign Keratosis"
        case "df": return "Dermatofibroma"
        case "mel": return "Melanoma"
        case "nv": return "Melanocytic Nevi"
        case "vasc": return "Vascular Lesion"
        case "level0": return "Acne - Clear/Normal"
        case "level1": return "Acne - Mild"
        case "level2": return "Acne - Moderate"
        case "level3": return "Acne - Severe"
        case "ingrown_nails": return "Ingrown Nails"
        case "stab_wound": return "Stab/Puncture Wound"
        case "abrasions": return "Abrasion"
        case "bruises": return "Bruise/Contusion"
        case "burns": return "Burn"
        case "cut": return "Cut/Incised Wound"
        case "laceration": return "Laceration/Tear"
        default: return name.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    private func medicalAdvice(for condition: String) -> some View {
        Group {
            if condition == "mel" || condition == "bcc" {
                adviceView(icon: "exclamationmark.triangle.fill", color: .red, title: "Urgent: Possible skin cancer", subtitle: "Consult a dermatologist immediately")
            } else if condition == "akiec" {
                adviceView(icon: "exclamationmark.triangle.fill", color: .orange, title: "Pre-cancerous lesion", subtitle: "Should be evaluated by a dermatologist")
            } else if condition.hasPrefix("level") {
                adviceView(icon: "info.circle.fill", color: .orange, title: "Acne Severity Level", subtitle: condition == "level3" ? "Severe acne - may require prescription treatment" : "Moderate acne - consider consulting a dermatologist")
            } else if condition == "burns" {
                adviceView(icon: "exclamationmark.triangle.fill", color: .orange, title: "Burn injury", subtitle: "Clean with cool water, monitor for infection")
            } else if condition == "stab_wound" || condition == "laceration" {
                adviceView(icon: "exclamationmark.triangle.fill", color: .red, title: "Deep wound - seek medical attention", subtitle: "Risk of infection or internal damage")
            } else if condition == "ingrown_nails" {
                adviceView(icon: "info.circle.fill", color: .blue, title: "Ingrown Nail", subtitle: "Keep area clean, avoid tight shoes")
            }
        }
    }

    private func adviceView(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(alignment: .top) {
            Image(systemName: icon)
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .bold()
                    .foregroundColor(color)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(color)
            }
        }
        .padding(.top, 4)
    }

    private func backgroundColor(for condition: String) -> Color {
        if condition == "mel" || condition == "bcc" || condition == "stab_wound" {
            return Color.red.opacity(0.1)
        } else if condition == "akiec" || (condition.hasPrefix("level") && condition != "level0") {
            return Color.orange.opacity(0.1)
        } else if condition == "laceration" || condition == "burns" {
            return Color.orange.opacity(0.08)
        } else {
            return Color.blue.opacity(0.1)
        }
    }

    // MARK: - ML Analysis

    private func analyzeImage() {
        guard let image = inputImage else { return }

        isAnalyzing = true
        errorMessage = ""
        fdaService.infos.removeAll()
        fdaService.searchedDrugs.removeAll()

        Task {
            do {
                // Try using Vision framework first (more reliable)
                let model = try WoundSnap()
                
                if let (predictedClass, confidence) = image.predictWithVision(model: model) {
                    await MainActor.run {
                        self.predictedClass = predictedClass
                        self.confidence = confidence
                        self.isAnalyzing = false
                        print("✅ Vision predicted: \(predictedClass) with \(confidence * 100)% confidence")
                        
                        // Fetch drug recommendations
                        self.fetchDrugRecommendations()
                    }
                } else {
                    // Fallback to manual MLMultiArray method
                    guard let mlArray = image.toMLMultiArray224() else {
                        await MainActor.run {
                            self.errorMessage = "Failed to prepare image for analysis"
                            self.isAnalyzing = false
                        }
                        return
                    }

                    let prediction = try model.prediction(input_2: mlArray)
                    let outputMultiArray = prediction.Identity

                    var outputFloats = [Float](repeating: 0.0, count: outputMultiArray.count)
                    for i in 0..<outputMultiArray.count {
                        outputFloats[i] = Float(truncating: outputMultiArray[i])
                    }

                    var maxConfidence: Float = -Float.infinity
                    var maxIndex = 0
                    for i in 0..<min(classNames.count, outputFloats.count) {
                        if outputFloats[i] > maxConfidence {
                            maxConfidence = outputFloats[i]
                            maxIndex = i
                        }
                    }

                    await MainActor.run {
                        self.predictedClass = classNames[maxIndex]
                        self.confidence = Double(maxConfidence)
                        self.isAnalyzing = false

                        // Fetch drug recommendations
                        self.fetchDrugRecommendations()
                    }
                }

            } catch {
                print("❌ ML Error details: \(error)")
                await MainActor.run {
                    self.errorMessage = "Analysis failed: \(error.localizedDescription)"
                    self.isAnalyzing = false
                }
            }
        }
    }

    private func fetchDrugRecommendations() {
        print("🔍 Current predictedClass: \(predictedClass)")
        
        fdaService.infos.removeAll()
        fdaService.searchedDrugs.removeAll()
        
        Task {
            if let recommendedDrugs = DrugRecommendation.mapping[predictedClass] {
                print("📋 Found drugs in mapping: \(recommendedDrugs)")
                
                await fdaService.fetchMultiple(drugs: recommendedDrugs)
                
                if await fdaService.infos.isEmpty && !fdaService.isLoading {
                    print("⚠️ No FDA data found. Trying fallback drugs...")
                    await fdaService.fetchMultiple(drugs: DrugRecommendation.fallbackDrugs)
                }
            } else {
                let drug = mapWoundToDrug(predictedClass)
                print("🔄 Using fallback drug: \(drug)")
                await fdaService.fetchMultiple(drugs: [drug] + DrugRecommendation.fallbackDrugs)
            }
        }
    }

    // MARK: - Upload Post after Analysis
    private func uploadAnalyzedImage() {
        guard let image = inputImage,
              let data = image.jpegData(compressionQuality: 0.8),
              let currentUser = User.current else {
            errorMessage = "Cannot upload: missing image or user."
            return
        }

        let parseFile = ParseFile(name: "analyzed.jpg", data: data)

        var post = Post()
        post.image = parseFile
        post.category = predictedClass
        post.userName = currentUser.displayName ?? "Anonymous"

        var finalDescription = "ML Prediction: \(formatClassName(predictedClass)) (\(Int(confidence * 100))% confident)"

        if !fdaService.infos.isEmpty {
            finalDescription += "\nSuggested Medications:"
            for (index, info) in fdaService.infos.enumerated() {
                if let purpose = info.purpose?.first {
                    finalDescription += "\n\(index + 1). \(purpose)"
                }
            }
        } else if let recommendedDrugs = DrugRecommendation.mapping[predictedClass] {
            finalDescription += "\nCommon Treatments: \(recommendedDrugs.joined(separator: ", "))"
        }

        let trimmedDesc = userDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedDesc.isEmpty {
            finalDescription += "\nUser Description: \(trimmedDesc)"
        }

        post.description = finalDescription

        post.save { result in
            switch result {
            case .success(_):
                errorMessage = ""
                userDescription = ""
                print("✅ Post uploaded successfully")
            case .failure(let error):
                errorMessage = "Failed to upload post: \(error.localizedDescription)"
            }
        }
    }
}

struct ContentViewAI_Previews: PreviewProvider {
    static var previews: some View {
        ContentViewAI()
    }
}
