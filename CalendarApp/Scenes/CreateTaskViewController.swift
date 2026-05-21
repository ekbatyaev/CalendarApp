import UIKit

@MainActor
final class CreateTaskViewController: UIViewController {

    private let eventStore: CalendarEventStore
    private let editingEvent: CalendarEvent?
    
    var onEventCreated: (() -> Void)?
    var onEventSaved: (() -> Void)?

    init(eventStore: CalendarEventStore, editingEvent: CalendarEvent? = nil) {
        self.eventStore = eventStore
        self.editingEvent = editingEvent
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let title_text_field: UITextField = {
        let field = UITextField()
        field.placeholder = "Название задачи"
        field.backgroundColor = .white
        field.layer.cornerRadius = 14
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        field.leftViewMode = .always
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()

    private let description_text_view: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = .white
        textView.layer.cornerRadius = 14
        textView.font = .systemFont(ofSize: 16)
        textView.text = "Описание"
        textView.textColor = .systemGray
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()

    private let all_day_switch: UISwitch = {
        let switchView = UISwitch()
        switchView.isOn = false
        switchView.translatesAutoresizingMaskIntoConstraints = false
        return switchView
    }()

    private let all_day_label: UILabel = {
        let label = UILabel()
        label.text = "Весь день"
        label.textColor = .black
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let date_picker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .dateAndTime
        picker.preferredDatePickerStyle = .compact
        picker.locale = Locale(identifier: "ru_RU")
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()

    private let save_button: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Сохранить задачу", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.layer.cornerRadius = 18
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        configureUI()
        configureForEditingIfNeeded()
    }

    private func configureUI() {
        view.backgroundColor = .systemGroupedBackground
        title = editingEvent == nil ? "Новая задача" : "Редактировать задачу"

        description_text_view.delegate = self

        view.addSubview(title_text_field)
        view.addSubview(description_text_view)
        view.addSubview(all_day_label)
        view.addSubview(all_day_switch)
        view.addSubview(date_picker)
        view.addSubview(save_button)

        save_button.addTarget(self, action: #selector(save_button_tapped), for: .touchUpInside)
        all_day_switch.addTarget(self, action: #selector(all_day_switch_changed), for: .valueChanged)

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Отмена",
            style: .plain,
            target: self,
            action: #selector(cancel_button_tapped)
        )

        NSLayoutConstraint.activate([
            title_text_field.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            title_text_field.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            title_text_field.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            title_text_field.heightAnchor.constraint(equalToConstant: 54),

            description_text_view.topAnchor.constraint(equalTo: title_text_field.bottomAnchor, constant: 16),
            description_text_view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            description_text_view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            description_text_view.heightAnchor.constraint(equalToConstant: 120),

            all_day_label.topAnchor.constraint(equalTo: description_text_view.bottomAnchor, constant: 24),
            all_day_label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            all_day_switch.centerYAnchor.constraint(equalTo: all_day_label.centerYAnchor),
            all_day_switch.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            date_picker.topAnchor.constraint(equalTo: all_day_label.bottomAnchor, constant: 24),
            date_picker.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            save_button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            save_button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            save_button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            save_button.heightAnchor.constraint(equalToConstant: 58)
        ])
    }

    private func configureForEditingIfNeeded() {
        guard let event = editingEvent else { return }

        title_text_field.text = event.title

        if event.description.isEmpty {
            description_text_view.text = "Описание"
            description_text_view.textColor = .systemGray
        } else {
            description_text_view.text = event.description
            description_text_view.textColor = .black
        }

        all_day_switch.isOn = event.isAllDay
        date_picker.date = event.date
        date_picker.datePickerMode = event.isAllDay ? .date : .dateAndTime
        save_button.setTitle("Сохранить изменения", for: .normal)
    }

    @objc private func save_button_tapped() {
        let title = title_text_field.text ?? ""

        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        let description: String

        if description_text_view.textColor == .systemGray {
            description = ""
        } else {
            description = description_text_view.text
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "HH:mm"

        let isAllDay = all_day_switch.isOn

        let event = CalendarEvent(
            id: editingEvent?.id ?? UUID(),
            title: title,
            date: date_picker.date,
            time: isAllDay ? nil : formatter.string(from: date_picker.date),
            isAllDay: isAllDay,
            description: description,
            isCompleted: editingEvent?.isCompleted ?? false
        )

        Task { [weak self] in
            guard let self else { return }

            if self.editingEvent == nil {
                await self.eventStore.add(event)
                self.onEventCreated?()
            } else {
                await self.eventStore.update(event)
                self.onEventSaved?()
            }

            self.dismiss(animated: true)
        }
        
    }

    @objc private func cancel_button_tapped() {
        dismiss(animated: true)
    }

    @objc private func all_day_switch_changed() {
        date_picker.datePickerMode = all_day_switch.isOn ? .date : .dateAndTime
    }
}

extension CreateTaskViewController: UITextViewDelegate {

    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "Описание" {
            textView.text = ""
            textView.textColor = .black
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text = "Описание"
            textView.textColor = .systemGray
        }
    }
}
