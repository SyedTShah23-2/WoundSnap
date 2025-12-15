//
//  PostImageView.swift
//  WoundSnapProject1
//
//  Created by Syed Taha Shah on 12/7/25.
//


import SwiftUI
import ParseSwift

struct PostImageView: View {
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var category = "abrasions"
    @State private var description = ""
    @State private var errorMessage = ""

    let categories = ["abrasions", "akiec", "bcc", "bkl", "bruises", "burns", "cut",
                      "df", "ingrown_nails", "laceration", "level0", "level1", "level2",
                      "level3", "mel", "nv", "stab_wound", "vasc"]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Optional image picker
                Button("Select Image") {
                    showingImagePicker = true
                }

                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 250)
                }

                // Description field
                TextField("Add a description...", text: $description)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)

                // Category picker
                Picker("Category", selection: $category) {
                    ForEach(categories, id: \.self) { Text($0.capitalized) }
                }
                .pickerStyle(MenuPickerStyle())

                // Post button
                Button("Post") {
                    uploadPost()
                }

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
        }
    }

    private func uploadPost() {
        guard let currentUser = User.current else { return }

        var post = Post()
        post.category = category
        post.userName = currentUser.displayName ?? "Anonymous"
        post.description = description
        post.comments = []

        // Only attach image if selected
        if let image = selectedImage, let data = image.jpegData(compressionQuality: 0.8) {
            post.image = ParseFile(name: "image.jpg", data: data)
        }

        post.save { result in
            switch result {
            case .success(_):
                selectedImage = nil
                description = ""
                errorMessage = ""
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}