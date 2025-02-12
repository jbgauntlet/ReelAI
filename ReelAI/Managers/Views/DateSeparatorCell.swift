import UIKit

class DateSeparatorCell: UICollectionViewCell {
    static let identifier = "DateSeparatorCell"
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let leftLine: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let rightLine: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(dateLabel)
        contentView.addSubview(leftLine)
        contentView.addSubview(rightLine)
        
        NSLayoutConstraint.activate([
            dateLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            dateLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            dateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leftLine.trailingAnchor, constant: 8),
            dateLabel.trailingAnchor.constraint(lessThanOrEqualTo: rightLine.leadingAnchor, constant: -8),
            
            leftLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            leftLine.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            leftLine.heightAnchor.constraint(equalToConstant: 0.5),
            leftLine.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.2),
            
            rightLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            rightLine.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            rightLine.heightAnchor.constraint(equalToConstant: 0.5),
            rightLine.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.2)
        ])
    }
    
    func configure(with date: Date) {
        let formatter = DateFormatter()
        
        if Calendar.current.isDateInToday(date) {
            dateLabel.text = "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            dateLabel.text = "Yesterday"
        } else if Calendar.current.isDate(date, equalTo: Date(), toGranularity: .year) {
            formatter.dateFormat = "MMMM d"
            dateLabel.text = formatter.string(from: date)
        } else {
            formatter.dateFormat = "MMMM d, yyyy"
            dateLabel.text = formatter.string(from: date)
        }
    }
} 