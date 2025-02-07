//
//  LivestreamViewController.swift
//  ReelAI
//
//  Created by GauntletAI on 2/6/25.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class MessagesViewController: UIViewController {
    
    // MARK: - Properties
    private var conversations: [Conversation] = []
    private var conversationsListener: ListenerRegistration?
    private let transition = HorizontalCoverTransition()
    
    // MARK: - UI Components
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Messages"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search messages"
        searchBar.searchBarStyle = .minimal
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        return searchBar
    }()
    
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .systemBackground
        tv.separatorStyle = .none
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "No messages yet"
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        fetchConversations()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(titleLabel)
        view.addSubview(searchBar)
        view.addSubview(tableView)
        view.addSubview(emptyStateLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            searchBar.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor)
        ])
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ConversationCell.self, forCellReuseIdentifier: ConversationCell.identifier)
    }
    
    // MARK: - Data Fetching
    private func fetchConversations() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        conversationsListener = db.collection("conversations")
            .whereField("participants", arrayContains: currentUserId)
            .order(by: "last_message_timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching conversations: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                let conversations = documents.compactMap { document -> Conversation? in
                    Conversation(from: document)
                }
                
                self.conversations = conversations
                self.emptyStateLabel.isHidden = !self.conversations.isEmpty
                self.tableView.reloadData()
                
                // Fetch user info for each conversation
                for (index, conversation) in conversations.enumerated() {
                    guard let otherUserId = conversation.participants.first(where: { $0 != currentUserId }) else { continue }
                    
                    db.collection("users").document(otherUserId).getDocument { [weak self] snapshot, error in
                        guard let self = self,
                              let data = snapshot?.data(),
                              let user = User(from: data, uid: otherUserId) else { return }
                        
                        conversation.otherUserInfo = user
                        
                        // Update the specific row
                        let indexPath = IndexPath(row: index, section: 0)
                        DispatchQueue.main.async {
                            if self.tableView.numberOfRows(inSection: 0) > index {
                                self.tableView.reloadRows(at: [indexPath], with: .none)
                            }
                        }
                    }
                }
            }
    }
}

// MARK: - UITableViewDelegate & DataSource
extension MessagesViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ConversationCell.identifier,
            for: indexPath
        ) as? ConversationCell else {
            return UITableViewCell()
        }
        
        let conversation = conversations[indexPath.row]
        cell.configure(with: conversation)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let conversation = conversations[indexPath.row]
        let chatVC = ChatViewController(conversation: conversation)
        chatVC.modalPresentationStyle = .fullScreen
        chatVC.transitioningDelegate = self
        present(chatVC, animated: true)
    }
}

// MARK: - UISearchBarDelegate
extension MessagesViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // TODO: Implement search functionality
    }
}

// MARK: - UIViewControllerTransitioningDelegate
extension MessagesViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.isPresenting = true
        return transition
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.isPresenting = false
        return transition
    }
}
