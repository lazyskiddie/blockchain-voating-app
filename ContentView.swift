//
//  ContentView.swift
//  MyReactNativeApp
//
//  Created by singh sandeepkumar vinodkumar on 07/01/25.
//

import SwiftUI
import Combine
import CryptoKit

struct Block: Identifiable {
    let id = UUID()
    var index: Int
    var timestamp: String
    var vote: String
    var voter: String
    var previousHash: String
    var hash: String
}

struct User: Identifiable {
    let id = UUID()
    var username: String
    var email: String
    var password: String
    var isAdmin: Bool
    var isVerified: Bool
}

class BlockchainViewModel: ObservableObject {
    @Published var blockchain: [Block] = []
    @Published var users: [User] = []
    @Published var currentUser: User? = nil
    @Published var vote: String = ""
    @Published var hasVoted: Bool = false
    @Published var errorMessage: String?

    init() {
        // Seed users
        users = [
            User(username: "Sandeep", email: "admin@example.com", password: "curl@#_&", isAdmin: true, isVerified: true),
            User(username: "User1", email: "user1@example.com", password: "User123", isAdmin: false, isVerified: true),
            User(username: "Prince", email: "user2@example.com", password: "user123", isAdmin: false, isVerified: true),
            User(username: "Ram", email: "user2@example.com", password: "user123", isAdmin: false, isVerified: true)
        ]
    }

    func login(username: String, password: String) -> Bool {
        if let user = users.first(where: { $0.username == username && $0.password == password }) {
            currentUser = user
            return true
        } else {
            errorMessage = "Invalid username or password"
            return false
        }
    }

    func logout() {
        currentUser = nil
    }

    func addBlock(vote: String, voter: String) {
        let index = blockchain.last?.index ?? 0
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let previousHash = blockchain.last?.hash ?? ""
        let hash = calculateHash(index: index, previousHash: previousHash, timestamp: timestamp, vote: vote, voter: voter)

        let newBlock = Block(index: index + 1, timestamp: timestamp, vote: vote, voter: voter, previousHash: previousHash, hash: hash)
        blockchain.append(newBlock)
    }

    func calculateHash(index: Int, previousHash: String, timestamp: String, vote: String, voter: String) -> String {
        let combined = "\(index)\(previousHash)\(timestamp)\(vote)\(voter)"
        let data = combined.data(using: .utf8)!
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02hhx", $0) }.joined()
    }

    func submitVote() {
        guard let currentUser = currentUser else { return }
        if hasVoted {
            errorMessage = "You vote has registered!"
        } else {
            addBlock(vote: vote, voter: currentUser.username)
            hasVoted = true
        }
    }
}

struct LoginView: View {
    @ObservedObject var viewModel: BlockchainViewModel
    @State private var username = ""
    @State private var password = ""

    var body: some View {
        VStack {
            Text("Login").font(.largeTitle)
            TextField("Username", text: $username).textFieldStyle(RoundedBorderTextFieldStyle())
            SecureField("Password", text: $password).textFieldStyle(RoundedBorderTextFieldStyle())
            Button("Login") {
                if viewModel.login(username: username, password: password) {
                    // Successful login
                } else {
                    // Handle error
                }
            }
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage).foregroundColor(.red)
            }
        }.padding()
    }
}

struct VoteView: View {
    @ObservedObject var viewModel: BlockchainViewModel

    var body: some View {
        VStack {
            if let user = viewModel.currentUser {
                Text("Welcome \(user.username)").font(.headline)
                if !viewModel.hasVoted {
                    TextField("Your Vote", text: $viewModel.vote).textFieldStyle(RoundedBorderTextFieldStyle())
                    Button("Submit Vote") {
                        viewModel.submitVote()
                    }
                } else {
                    Text("You have voted!").foregroundColor(.green)
                }
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage).foregroundColor(.red)
                }
            }
        }.padding()
    }
}

struct AdminView: View {
    @ObservedObject var viewModel: BlockchainViewModel

    var body: some View {
        VStack {
            Text("Admin Dashboard").font(.largeTitle)
            ForEach(viewModel.blockchain) { block in
                VStack(alignment: .leading) {
                    Text("Block \(block.index)").font(.headline)
                    Text("Vote: \(block.vote)")
                    Text("Voter: \(block.voter)")
                    Text("Timestamp: \(block.timestamp)")
                    Text("Hash: \(block.hash)")
                }
                Divider()
            }
        }.padding()
    }
}

struct ContentView: View {
    @ObservedObject var viewModel = BlockchainViewModel()

    var body: some View {
        if viewModel.currentUser == nil {
            LoginView(viewModel: viewModel)
        } else if viewModel.currentUser?.isAdmin == true {
            AdminView(viewModel: viewModel)
        } else {
            VoteView(viewModel: viewModel)
        }
    }
}

struct VotingApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

