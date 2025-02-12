import UIKit

class PatternDisplayViewController: UIViewController {
    
    // MARK: - Properties
    private let pattern: String
    private let patternJson: [String: Any]
    
    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 16
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .systemGray
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Initialization
    init(pattern: String, patternJson: [String: Any]) {
        self.pattern = pattern
        self.patternJson = patternJson
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupPatternDisplay()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(stackView)
        view.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
        
        closeButton.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
        
        // Set title based on pattern
        titleLabel.text = pattern.capitalized
    }
    
    private func setupPatternDisplay() {
        switch pattern {
        case "workout":
            displayWorkout()
        case "recipe":
            displayRecipe()
        case "tutorial":
            displayTutorial()
        default:
            break
        }
    }
    
    private func displayWorkout() {
        guard let workout = patternJson as? [String: Any],
              let exercises = workout["exercises"] as? [[String: Any]] else { return }
        
        for (index, exercise) in exercises.enumerated() {
            let exerciseView = createExerciseView(exercise, index: index)
            stackView.addArrangedSubview(exerciseView)
        }
    }
    
    private func createExerciseView(_ exercise: [String: Any], index: Int) -> UIView {
        let container = UIView()
        container.backgroundColor = .systemGray6
        container.layer.cornerRadius = 8
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])
        
        // Exercise title
        if let name = exercise["name"] as? String {
            let titleLabel = UILabel()
            titleLabel.text = name
            titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
            stack.addArrangedSubview(titleLabel)
        }
        
        // Details
        let detailsStack = UIStackView()
        detailsStack.axis = .horizontal
        detailsStack.distribution = .fillEqually
        detailsStack.spacing = 8
        
        if let sets = exercise["sets"] {
            let label = UILabel()
            label.text = "\(sets) sets"
            detailsStack.addArrangedSubview(label)
        }
        
        if let reps = exercise["reps"] {
            let label = UILabel()
            label.text = "\(reps) reps"
            detailsStack.addArrangedSubview(label)
        }
        
        if let weight = exercise["weight"] {
            let label = UILabel()
            label.text = "\(weight)"
            detailsStack.addArrangedSubview(label)
        }
        
        stack.addArrangedSubview(detailsStack)
        
        // Additional info
        if let duration = exercise["duration"] {
            let label = UILabel()
            label.text = "Duration: \(duration)"
            stack.addArrangedSubview(label)
        }
        
        if let intensity = exercise["intensity"] {
            let label = UILabel()
            label.text = "Intensity: \(intensity)"
            stack.addArrangedSubview(label)
        }
        
        if let restDuration = exercise["rest_duration"] {
            let label = UILabel()
            label.text = "Rest: \(restDuration)"
            stack.addArrangedSubview(label)
        }
        
        return container
    }
    
    private func displayRecipe() {
        guard let recipe = patternJson as? [String: Any] else { return }
        
        // Recipe name
        if let name = recipe["name"] as? String {
            let nameLabel = UILabel()
            nameLabel.text = name
            nameLabel.font = .systemFont(ofSize: 20, weight: .bold)
            stackView.addArrangedSubview(nameLabel)
        }
        
        // Time and servings info
        let infoStack = UIStackView()
        infoStack.axis = .horizontal
        infoStack.distribution = .fillEqually
        infoStack.spacing = 8
        
        if let prepTime = recipe["prepTime"] {
            let label = UILabel()
            label.text = "Prep: \(prepTime)"
            infoStack.addArrangedSubview(label)
        }
        
        if let cookTime = recipe["cookTime"] {
            let label = UILabel()
            label.text = "Cook: \(cookTime)"
            infoStack.addArrangedSubview(label)
        }
        
        if let servings = recipe["servings"] {
            let label = UILabel()
            label.text = "Serves: \(servings)"
            infoStack.addArrangedSubview(label)
        }
        
        stackView.addArrangedSubview(infoStack)
        
        // Ingredients
        if let ingredients = recipe["ingredients"] as? [[String: Any]] {
            let titleLabel = UILabel()
            titleLabel.text = "Ingredients"
            titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
            stackView.addArrangedSubview(titleLabel)
            
            for ingredient in ingredients {
                let label = UILabel()
                if let item = ingredient["item"] as? String,
                   let amount = ingredient["amount"],
                   let unit = ingredient["unit"] as? String {
                    label.text = "• \(amount) \(unit) \(item)"
                }
                stackView.addArrangedSubview(label)
            }
        }
        
        // Steps
        if let steps = recipe["steps"] as? [String] {
            let titleLabel = UILabel()
            titleLabel.text = "Instructions"
            titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
            stackView.addArrangedSubview(titleLabel)
            
            for (index, step) in steps.enumerated() {
                let label = UILabel()
                label.text = "\(index + 1). \(step)"
                label.numberOfLines = 0
                stackView.addArrangedSubview(label)
            }
        }
    }
    
    private func displayTutorial() {
        guard let tutorial = patternJson as? [String: Any] else { return }
        
        // Subject
        if let subject = tutorial["subject"] as? String {
            let subjectLabel = UILabel()
            subjectLabel.text = subject
            subjectLabel.font = .systemFont(ofSize: 20, weight: .bold)
            stackView.addArrangedSubview(subjectLabel)
        }
        
        // Steps
        if let steps = tutorial["steps"] as? [[String: Any]] {
            for (index, step) in steps.enumerated() {
                let stepView = createTutorialStepView(step, index: index)
                stackView.addArrangedSubview(stepView)
            }
        }
    }
    
    private func createTutorialStepView(_ step: [String: Any], index: Int) -> UIView {
        let container = UIView()
        container.backgroundColor = .systemGray6
        container.layer.cornerRadius = 8
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])
        
        // Step number
        let numberLabel = UILabel()
        numberLabel.text = "Step \(index + 1)"
        numberLabel.font = .systemFont(ofSize: 14, weight: .medium)
        numberLabel.textColor = .secondaryLabel
        stack.addArrangedSubview(numberLabel)
        
        // Title
        if let title = step["title"] as? String {
            let titleLabel = UILabel()
            titleLabel.text = title
            titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
            stack.addArrangedSubview(titleLabel)
        }
        
        // Description
        if let description = step["description"] as? String {
            let descLabel = UILabel()
            descLabel.text = description
            descLabel.numberOfLines = 0
            stack.addArrangedSubview(descLabel)
        }
        
        // Duration
        if let duration = step["duration"] as? String {
            let durationLabel = UILabel()
            durationLabel.text = "Duration: \(duration)"
            durationLabel.font = .systemFont(ofSize: 14)
            durationLabel.textColor = .secondaryLabel
            stack.addArrangedSubview(durationLabel)
        }
        
        return container
    }
    
    // MARK: - Actions
    @objc private func handleClose() {
        dismiss(animated: true)
    }
} 