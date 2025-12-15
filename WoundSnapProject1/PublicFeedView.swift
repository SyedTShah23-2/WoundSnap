//
//  PublicFeedView.swift
//  WoundSnapProject1
//
//  Created by Syed Taha Shah on 12/7/25.
//


import SwiftUI
import ParseSwift

struct PublicFeedView: View {
    @Binding var userLoggedIn: Bool
    @State private var posts: [Post] = []
    @State private var showingLogoutAlert = false
    @State private var selectedCategory: String = "All"
    @State private var expandedPosts: Set<String> = [] // Track expanded posts
    @State private var newCommentText: [String: String] = [:] // Track input per post

    let categories = ["All", "Abrasions", "Actinic Keratosis", "Basal Cell Carcinoma", "Benign Keratosis", "Bruises",
                      "Burns", "Cuts", "Dermatofibroma", "Ingrown Nails", "Lacerations",
                      "Mild Acne", "Moderate Acne", "Severe Acne", "Cystic Acne", "Melanoma",
                      "Nevus", "Stab Wounds", "Vascular Lesions"]

    var body: some View {
        NavigationView {
            VStack {
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(categories, id: \.self) { category in
                            Button(action: { selectedCategory = category }) {
                                Text(category)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedCategory == category ? Color.blue : Color.gray.opacity(0.3))
                                    .foregroundColor(selectedCategory == category ? .white : .black)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 5)

                // Post List
                List(filteredPosts) { post in
                    let postId = post.id

                    VStack(alignment: .leading, spacing: 8) {
                        // Post Header
                        HStack {
                            Text(post.userName ?? "Anonymous")
                                .font(.headline)
                            Spacer()
                            Text(getFriendlyCategoryName(post.category ?? ""))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .onTapGesture { // Header toggles expansion
                            withAnimation { togglePostExpansion(postId: postId) }
                        }

                        // Post Image
                        if let parseFile = post.image, let url = parseFile.url {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.1))
                                        .frame(height: 200)
                                        .onTapGesture { // Image toggles expansion
                                            withAnimation { togglePostExpansion(postId: postId) }
                                        }
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxHeight: 200)
                                        .cornerRadius(12)
                                        .onTapGesture { // Image toggles expansion
                                            withAnimation { togglePostExpansion(postId: postId) }
                                        }
                                case .failure(_):
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.red.opacity(0.1))
                                        .frame(height: 200)
                                        .onTapGesture { // Image toggles expansion
                                            withAnimation { togglePostExpansion(postId: postId) }
                                        }
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }

                        // Descriptions
                        VStack(alignment: .leading, spacing: 4) {
                            if let description = post.description, !description.isEmpty {
                                Text(description).font(.subheadline)
                            }
                            if let mlDesc = post.mlDescription, !mlDesc.isEmpty {
                                Text(mlDesc)
                                    .font(.subheadline)
                                    .italic()
                                    .foregroundColor(.secondary)
                            }
                        }

                        // Comments Section
                        VStack(alignment: .leading, spacing: 8) {
                            // Show existing comments
                            if let comments = post.comments, !comments.isEmpty {
                                // Show only first comment when not expanded
                                if comments.count > 0 {
                                    let commentToShow = isPostExpanded(postId: postId) ? comments : [comments[0]]
                                    
                                    ForEach(commentToShow) { comment in
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(comment.userName ?? "Anonymous").bold()
                                            Text(comment.text ?? "")
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                                
                                // Show "See all/Hide comments" button if there are more than 1 comment
                                if comments.count > 1 {
                                    Button(action: {
                                        withAnimation { togglePostExpansion(postId: postId) }
                                    }) {
                                        Text(isPostExpanded(postId: postId) ? "Hide comments" : "See all comments (\(comments.count - 1))")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                    .padding(.top, 4)
                                }
                            }
                            
                            // Show comment input field when expanded
                            if isPostExpanded(postId: postId) {
                                HStack {
                                    TextField("Add a comment...", text: Binding(
                                        get: { newCommentText[postId] ?? "" },
                                        set: { newCommentText[postId] = $0 }
                                    ))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())

                                    Button("Send") {
                                        let text = newCommentText[postId]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                                        guard !text.isEmpty else { return }
                                        submitComment(post: post, text: text)
                                    }
                                    .disabled((newCommentText[postId]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "").isEmpty)
                                }
                                .padding(.top, 8)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .listStyle(PlainListStyle())
            }
            .navigationBarTitle("WoundSnap", displayMode: .inline)
            .navigationBarItems(trailing: Button("Log Out") {
                showingLogoutAlert = true
            })
            .alert(isPresented: $showingLogoutAlert) {
                Alert(
                    title: Text("Log Out"),
                    message: Text("Are you sure you want to log out?"),
                    primaryButton: .destructive(Text("Log Out")) {
                        logout()
                    },
                    secondaryButton: .cancel()
                )
            }
            .onAppear(perform: loadPosts)
        }
    }

    // MARK: - Filtered posts
    var filteredPosts: [Post] {
        if selectedCategory == "All" {
            return posts
        } else {
            // Map friendly name back to database name for filtering
            let databaseCategoryName = getDatabaseCategoryName(selectedCategory)
            return posts.filter { $0.category == databaseCategoryName }
        }
    }

    // MARK: - Category name mapping
    private func getFriendlyCategoryName(_ databaseName: String) -> String {
        let mapping: [String: String] = [
            "abrasions": "Abrasions",
            "akiec": "Actinic Keratosis",
            "bcc": "Basal Cell Carcinoma",
            "bkl": "Benign Keratosis",
            "bruises": "Bruises",
            "burns": "Burns",
            "cut": "Cuts",
            "df": "Dermatofibroma",
            "ingrown_nails": "Ingrown Nails",
            "laceration": "Lacerations",
            "level0": "Mild Acne",
            "level1": "Moderate Acne",
            "level2": "Severe Acne",
            "level3": "Cystic Acne",
            "mel": "Melanoma",
            "nv": "Nevus",
            "stab_wound": "Stab Wounds",
            "vasc": "Vascular Lesions"
        ]
        
        return mapping[databaseName] ?? databaseName.capitalized
    }
    
    private func getDatabaseCategoryName(_ friendlyName: String) -> String {
        let mapping: [String: String] = [
            "Abrasions": "abrasions",
            "Actinic Keratosis": "akiec",
            "Basal Cell Carcinoma": "bcc",
            "Benign Keratosis": "bkl",
            "Bruises": "bruises",
            "Burns": "burns",
            "Cuts": "cut",
            "Dermatofibroma": "df",
            "Ingrown Nails": "ingrown_nails",
            "Lacerations": "laceration",
            "Mild Acne": "level0",
            "Moderate Acne": "level1",
            "Severe Acne": "level2",
            "Cystic Acne": "level3",
            "Melanoma": "mel",
            "Nevus": "nv",
            "Stab Wounds": "stab_wound",
            "Vascular Lesions": "vasc"
        ]
        
        return mapping[friendlyName] ?? friendlyName.lowercased()
    }

    // MARK: - Expand/Collapse
    private func togglePostExpansion(postId: String) {
        if expandedPosts.contains(postId) {
            expandedPosts.remove(postId)
        } else {
            expandedPosts.insert(postId)
        }
    }

    private func isPostExpanded(postId: String) -> Bool {
        expandedPosts.contains(postId)
    }

    // MARK: - Load posts
    private func loadPosts() {
        // Use include to fetch comments with posts
        Post.query()
            .include("comments") // This tells Parse to include comment objects
            .order([.descending("createdAt")])
            .find { result in
                switch result {
                case .success(let fetchedPosts):
                    DispatchQueue.main.async {
                        posts = fetchedPosts
                        print("✅ Loaded \(posts.count) posts with comments")
                        
                        // Debug: Check comments
                        for post in posts {
                            print("Post '\(post.description?.prefix(20) ?? "N/A")...' has \(post.comments?.count ?? 0) comments")
                            if let comments = post.comments {
                                for comment in comments {
                                    print("  - Comment ID: \(comment.objectId ?? "N/A"), Text: \(comment.text?.prefix(20) ?? "N/A")...")
                                }
                            }
                        }
                    }
                case .failure(let error):
                    print("Failed to fetch posts: \(error)")
                }
            }
    }

    // MARK: - Submit comment
    private func submitComment(post: Post, text: String) {
        _ = post
        
        // Get the user's display name, username, or fallback to "Anonymous"
        let currentUser = User.current
        let userNameToUse = currentUser?.displayName ?? currentUser?.username ?? "Anonymous"
        
        // Create a comment object
        var comment = Comment()
        comment.text = text
        comment.userName = userNameToUse

        // First save the comment to get a real objectId from Parse
        comment.save { commentResult in
            switch commentResult {
            case .success(let savedComment):
                // Now add the saved comment (with real objectId) to the post
                var postToUpdate = post
                
                if postToUpdate.comments != nil {
                    postToUpdate.comments!.append(savedComment)
                } else {
                    postToUpdate.comments = [savedComment]
                }

                // Save the updated post
                postToUpdate.save { postResult in
                    switch postResult {
                    case .success(let savedPost):
                        DispatchQueue.main.async {
                            // Update the local posts array
                            if let index = posts.firstIndex(where: { $0.id == savedPost.id }) {
                                posts[index] = savedPost
                            }
                            
                            // Clear the input field
                            newCommentText[post.id] = ""
                            
                            // Ensure the post stays expanded
                            if !expandedPosts.contains(post.id) {
                                expandedPosts.insert(post.id)
                            }
                            
                            print("✅ Comment saved with ID: \(savedComment.objectId ?? "N/A")")
                        }
                    case .failure(let error):
                        print("Failed to save post with new comment: \(error)")
                    }
                }
            case .failure(let error):
                print("Failed to save comment: \(error)")
            }
        }
    }

    // MARK: - Log Out
    private func logout() {
        User.logout { result in
            switch result {
            case .success:
                print("✅ Logged out successfully")
                DispatchQueue.main.async {
                    userLoggedIn = false
                }
            case .failure(let error):
                print("❌ Logout failed: \(error)")
            }
        }
    }
}

struct PublicFeedView_Previews: PreviewProvider {
    static var previews: some View {
        PublicFeedView(userLoggedIn: .constant(true))
    }
}
