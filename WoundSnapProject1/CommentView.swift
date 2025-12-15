//
//  CommentView.swift
//  WoundSnapProject1
//
//  Created by Syed Taha Shah on 12/7/25.
//


import SwiftUI
import ParseSwift

struct CommentView: View {
    @State var post: Post
    @State private var newCommentText = ""
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            VStack {
                List {
                    if let comments = post.comments {
                        ForEach(comments) { comment in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(comment.userName ?? "Anonymous")
                                    .font(.caption)
                                    .bold()
                                Text(comment.text ?? "")
                                    .font(.body)
                            }
                            .padding(.vertical, 2)
                        }
                    } else {
                        Text("No comments yet.")
                            .foregroundColor(.secondary)
                    }
                }

                HStack {
                    TextField("Add a comment...", text: $newCommentText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button("Post") {
                        addComment()
                    }
                    .disabled(newCommentText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding()
            }
            .navigationTitle("Comments")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }

    private func addComment() {
        guard let currentUser = User.current else { return }

        var comment = Comment()
        comment.userName = currentUser.displayName ?? "Anonymous"
        comment.text = newCommentText.trimmingCharacters(in: .whitespaces)

        post.comments = (post.comments ?? []) + [comment]

        // Save updated post
        post.save { result in
            switch result {
            case .success(_):
                newCommentText = ""
            case .failure(let error):
                print("Error saving comment: \(error)")
            }
        }
    }
}