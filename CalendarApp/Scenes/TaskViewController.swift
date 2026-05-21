import UIKit

@MainActor
final class TaskViewController: UIViewController {

    private let eventStore: CalendarEventStore
    
    var onEventCreated: (() -> Void)?

    private var groupedEvents: [(date: Date, events: [CalendarEvent])] = []

    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ru_RU")
        calendar.firstWeekday = 2
        return calendar
    }()

    init(eventStore: CalendarEventStore) {
        self.eventStore = eventStore
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var title_label: UILabel = {
        let label = UILabel()
        label.text = "Задачи"
        label.textColor = .black
        label.font = .systemFont(ofSize: 30, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var table_view: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.backgroundColor = .clear
        table.dataSource = self
        table.delegate = self
        table.register(CalendarEventCell.self, forCellReuseIdentifier: CalendarEventCell.reuseIdentifier)
        table.separatorStyle = .none
        table.showsVerticalScrollIndicator = true
        table.alwaysBounceVertical = true
        table.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 90, right: 0)
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()

    private lazy var create_task_button: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Создать задачу", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.layer.cornerRadius = 22
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.16
        button.layer.shadowOffset = CGSize(width: 0, height: 8)
        button.layer.shadowRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(create_task_button_tapped), for: .touchUpInside)
        return button
    }()

    private lazy var empty_label: UILabel = {
        let label = UILabel()
        label.text = "Пока нет задач"
        label.textColor = .systemGray
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        configureUI()
        reloadEvents()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        reloadEvents()
    }

    private func configureUI() {
        view.backgroundColor = .systemGroupedBackground

        view.addSubview(title_label)
        view.addSubview(table_view)
        view.addSubview(empty_label)
        view.addSubview(create_task_button)

        NSLayoutConstraint.activate([
            title_label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            title_label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            title_label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            table_view.topAnchor.constraint(equalTo: title_label.bottomAnchor, constant: 12),
            table_view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            table_view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            table_view.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            empty_label.centerXAnchor.constraint(equalTo: table_view.centerXAnchor),
            empty_label.centerYAnchor.constraint(equalTo: table_view.centerYAnchor),

            create_task_button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            create_task_button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            create_task_button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            create_task_button.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    func refreshEvents() {

        reloadEvents()

    }

    private func reloadEvents() {
        Task { [weak self] in
            guard let self else { return }

            let allEvents = await eventStore.allEvents()

            let today = calendar.startOfDay(for: Date())

            let futureEvents = allEvents.filter { event in
                let eventDay = self.calendar.startOfDay(for: event.date)
                return eventDay >= today
            }

            groupedEvents = groupEventsByDate(futureEvents)

            table_view.reloadData()

            empty_label.isHidden = !groupedEvents.isEmpty
            table_view.isHidden = groupedEvents.isEmpty
        }
    }

    private func groupEventsByDate(_ events: [CalendarEvent]) -> [(date: Date, events: [CalendarEvent])] {
        let groupedDictionary = Dictionary(grouping: events) { event in
            calendar.startOfDay(for: event.date)
        }

        return groupedDictionary
            .map { item in
                (
                    date: item.key,
                    events: item.value.sorted { first, second in
                        if first.isCompleted != second.isCompleted {
                            return !first.isCompleted && second.isCompleted
                        }

                        if first.isAllDay != second.isAllDay {
                            return first.isAllDay && !second.isAllDay
                        }

                        return (first.time ?? "") < (second.time ?? "")
                    }
                )
            }
            .sorted { $0.date < $1.date }
    }

    private func makeSectionTitle(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "EEEE, d MMMM"

        let text = formatter.string(from: date)
        return text.prefix(1).uppercased() + text.dropFirst()
    }

    @objc private func create_task_button_tapped() {
        let createVC = CreateTaskViewController(eventStore: eventStore)

        createVC.onEventCreated = { [weak self] in
            self?.reloadEvents()
            self?.onEventCreated?()
        }

        let navigationController = UINavigationController(rootViewController: createVC)

        present(navigationController, animated: true)
    }

    private func openEditTask(_ event: CalendarEvent) {
        let editVC = CreateTaskViewController(eventStore: eventStore, editingEvent: event)

        editVC.onEventSaved = { [weak self] in
            self?.reloadEvents()
            self?.onEventCreated?()
        }

        let navigationController = UINavigationController(rootViewController: editVC)

        present(navigationController, animated: true)
    }

    private func completeTask(_ event: CalendarEvent) {
        Task { [weak self] in
            guard let self else { return }

            await self.eventStore.setCompleted(id: event.id, isCompleted: true)

            self.reloadEvents()
            self.onEventCreated?()
        }
    }
}

extension TaskViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        groupedEvents.count
    }

    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        groupedEvents[section].events.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let event = groupedEvents[indexPath.section].events[indexPath.row]

        let cell = tableView.dequeueReusableCell(
            withIdentifier: CalendarEventCell.reuseIdentifier,
            for: indexPath
        )

        guard let eventCell = cell as? CalendarEventCell else {
            return cell
        }

        let subtitle: String

        if event.isAllDay {
            subtitle = "Весь день • \(event.description)"
        } else {
            subtitle = "\(event.time ?? "") • \(event.description)"
        }

        eventCell.configure(
            title: event.title,
            subtitle: subtitle,
            indexPath: indexPath,
            rowsCount: groupedEvents[indexPath.section].events.count,
            isCompleted: event.isCompleted
        )

        eventCell.onDoneTapped = { [weak self] in
            self?.completeTask(event)
        }

        return eventCell
    }
    
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: true)

        let event = groupedEvents[indexPath.section].events[indexPath.row]
        openEditTask(event)
    }

    func tableView(
        _ tableView: UITableView,
        heightForRowAt indexPath: IndexPath
    ) -> CGFloat {
        72
    }

    func tableView(
        _ tableView: UITableView,
        heightForHeaderInSection section: Int
    ) -> CGFloat {
        48
    }

    func tableView(
        _ tableView: UITableView,
        viewForHeaderInSection section: Int
    ) -> UIView? {
        let container = UIView()
        container.backgroundColor = .clear

        let label = UILabel()
        label.text = makeSectionTitle(from: groupedEvents[section].date)
        label.textColor = .black
        label.font = .systemFont(ofSize: 21, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -4),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])

        return container
    }
}
