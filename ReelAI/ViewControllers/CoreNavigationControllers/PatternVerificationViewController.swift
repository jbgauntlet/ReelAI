import UIKit
import FirebaseFirestore

class PatternVerificationViewController: UIViewController {
    
    // MARK: - Properties
    private let videoId: String
    private let pattern: String
    private var patternJson: [String: Any]
    private var editedJson: [String: Any]
    var onCompletion: (() -> Void)?
    
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
    
    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Save Changes", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Initialization
    init(videoId: String, pattern: String, patternJson: [String: Any]) {
        self.videoId = videoId
        self.pattern = pattern
        self.patternJson = patternJson
        self.editedJson = patternJson
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupPatternFields()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(stackView)
        contentView.addSubview(saveButton)
        
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
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            saveButton.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 20),
            saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            saveButton.heightAnchor.constraint(equalToConstant: 44),
            saveButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
        
        saveButton.addTarget(self, action: #selector(handleSave), for: .touchUpInside)
        
        // Set title based on pattern
        titleLabel.text = "Verify \(pattern.capitalized) Data"
    }
    
    private func setupPatternFields() {
        // Clear existing fields
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        switch pattern {
        case "workout":
            setupWorkoutFields()
        case "recipe":
            setupRecipeFields()
        case "tutorial":
            setupTutorialFields()
        default:
            break
        }
    }
    
    private func setupWorkoutFields() {
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
        let titleLabel = UILabel()
        titleLabel.text = "Exercise \(index + 1)"
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        stack.addArrangedSubview(titleLabel)
        
        // Fields
        let fields = ["name", "sets", "reps", "weight", "duration", "intensity", "rest_duration"]
        for field in fields {
            if let value = exercise[field] {
                let fieldView = createFieldView(label: field.capitalized, value: "\(value)", tag: index)
                stack.addArrangedSubview(fieldView)
            }
        }
        
        return container
    }
    
    private func setupRecipeFields() {
        guard let recipe = patternJson as? [String: Any] else { return }
        
        // Recipe name
        if let name = recipe["name"] {
            let nameField = createFieldView(label: "Name", value: "\(name)", tag: 0)
            stackView.addArrangedSubview(nameField)
        }
        
        // Ingredients
        if let ingredients = recipe["ingredients"] as? [[String: Any]] {
            let ingredientsLabel = UILabel()
            ingredientsLabel.text = "Ingredients"
            ingredientsLabel.font = .systemFont(ofSize: 18, weight: .bold)
            stackView.addArrangedSubview(ingredientsLabel)
            
            for (index, ingredient) in ingredients.enumerated() {
                let ingredientView = createIngredientView(ingredient, index: index)
                stackView.addArrangedSubview(ingredientView)
            }
        }
        
        // Steps
        if let steps = recipe["steps"] as? [String] {
            let stepsLabel = UILabel()
            stepsLabel.text = "Steps"
            stepsLabel.font = .systemFont(ofSize: 18, weight: .bold)
            stackView.addArrangedSubview(stepsLabel)
            
            for (index, step) in steps.enumerated() {
                let stepField = createFieldView(label: "Step \(index + 1)", value: step, tag: index)
                stackView.addArrangedSubview(stepField)
            }
        }
        
        // Additional fields
        let fields = ["prepTime", "cookTime", "servings"]
        for field in fields {
            if let value = recipe[field] {
                let fieldView = createFieldView(label: field.capitalized, value: "\(value)", tag: 0)
                stackView.addArrangedSubview(fieldView)
            }
        }
    }
    
    private func createIngredientView(_ ingredient: [String: Any], index: Int) -> UIView {
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
        
        // Ingredient fields
        let fields = ["item", "amount", "unit"]
        for field in fields {
            if let value = ingredient[field] {
                let fieldView = createFieldView(label: field.capitalized, value: "\(value)", tag: index)
                stack.addArrangedSubview(fieldView)
            }
        }
        
        return container
    }
    
    private func setupTutorialFields() {
        guard let tutorial = patternJson as? [String: Any] else { return }
        
        // Subject
        if let subject = tutorial["subject"] {
            let subjectField = createFieldView(label: "Subject", value: "\(subject)", tag: 0)
            stackView.addArrangedSubview(subjectField)
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
        
        // Step title
        let titleLabel = UILabel()
        titleLabel.text = "Step \(index + 1)"
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        stack.addArrangedSubview(titleLabel)
        
        // Fields
        let fields = ["title", "description", "duration"]
        for field in fields {
            if let value = step[field] {
                let fieldView = createFieldView(label: field.capitalized, value: "\(value)", tag: index)
                stack.addArrangedSubview(fieldView)
            }
        }
        
        return container
    }
    
    private func createFieldView(label labelText: String, value: String, tag: Int) -> UIView {
        let container = UIView()
        
        let labelView = UILabel()
        labelView.text = labelText
        labelView.font = .systemFont(ofSize: 14, weight: .medium)
        labelView.textColor = .secondaryLabel
        labelView.translatesAutoresizingMaskIntoConstraints = false
        
        let textField = UITextField()
        textField.text = value
        textField.borderStyle = .roundedRect
        textField.tag = tag
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(labelView)
        container.addSubview(textField)
        
        NSLayoutConstraint.activate([
            labelView.topAnchor.constraint(equalTo: container.topAnchor),
            labelView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            labelView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            textField.topAnchor.constraint(equalTo: labelView.bottomAnchor, constant: 4),
            textField.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            textField.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    // MARK: - Actions
    @objc private func handleSave() {
        // Update Firestore with edited JSON
        let db = Firestore.firestore()
        db.collection("videos").document(videoId).updateData([
            "pattern_json": editedJson
        ]) { [weak self] error in
            if let error = error {
                print("Error updating pattern JSON: \(error.localizedDescription)")
                // Show error alert
                let alert = UIAlertController(
                    title: "Error",
                    message: "Failed to save changes: \(error.localizedDescription)",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            } else {
                self?.dismiss(animated: true) {
                    self?.onCompletion?()
                }
            }
        }
    }
}

// MARK: - UITextFieldDelegate
extension PatternVerificationViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        // Update edited JSON based on field changes
        // Implementation depends on pattern type and field structure
    }
} 