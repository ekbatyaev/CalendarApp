import UIKit

enum CalendarTab: Int {
    case today
    case calendar
    case tasks
}

@MainActor
final class ViewController: UIViewController {

    // MARK: - Properties

    private let calendarEventStore = CalendarEventStore()

    private var todayEvents: [CalendarEvent] = []
    private var todayActiveEvents: [CalendarEvent] = []
    private var todayCompletedEvents: [CalendarEvent] = []

    private lazy var calendarViewController = CalendarViewController(
        eventStore: calendarEventStore
    )

    private lazy var taskViewController = TaskViewController(
        eventStore: calendarEventStore
    )

    private var selectedTab: CalendarTab = .today

    // MARK: - Subviews

    private lazy var title_label: UILabel = {
        let label = UILabel()
        label.text = "Сегодня"
        label.textColor = AppStyle.textPrimary
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var status_label: UILabel = {
        let label = UILabel()
        label.text = "Задачи на сегодня"
        label.textColor = AppStyle.textSecondary
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var table_view: UITableView = {
        let table = UITableView()
        table.backgroundColor = .clear
        table.translatesAutoresizingMaskIntoConstraints = false
        table.dataSource = self
        table.delegate = self
        table.register(TodayTaskCell.self, forCellReuseIdentifier: TodayTaskCell.reuseIdentifier)
        table.separatorStyle = .none
        table.rowHeight = 78
        table.showsVerticalScrollIndicator = true
        table.alwaysBounceVertical = true
        table.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 16, right: 0)
        return table
    }()

    private lazy var empty_label: UILabel = {
        let label = UILabel()
        label.text = "На сегодня задач нет"
        label.textColor = AppStyle.textSecondary
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var calendar_container_view: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var tasks_container_view: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var customTabBar: UIView = {
        let view = UIView()
        view.applyCardStyle(cornerRadius: 28)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var todayTabButton = makeTabButton(
        title: "Сегодня",
        imageName: "list.bullet.rectangle",
        tag: CalendarTab.today.rawValue
    )

    private lazy var calendarTabButton = makeTabButton(
        title: "Календарь",
        imageName: "calendar",
        tag: CalendarTab.calendar.rawValue
    )

    private lazy var tasksTabButton = makeTabButton(
        title: "Задачи",
        imageName: "list.bullet.clipboard",
        tag: CalendarTab.tasks.rawValue
    )

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureUI()
        reloadTodayEvents()
    }

    // MARK: - Configuration

    private func configureUI() {
        view.backgroundColor = AppStyle.background

        view.addSubview(title_label)
        view.addSubview(status_label)
        view.addSubview(table_view)
        view.addSubview(empty_label)
        view.addSubview(calendar_container_view)
        view.addSubview(tasks_container_view)
        view.addSubview(customTabBar)

        let tabStack = UIStackView(arrangedSubviews: [
            todayTabButton,
            calendarTabButton,
            tasksTabButton
        ])

        tabStack.axis = .horizontal
        tabStack.distribution = .fillEqually
        tabStack.alignment = .center
        tabStack.translatesAutoresizingMaskIntoConstraints = false

        customTabBar.addSubview(tabStack)

        NSLayoutConstraint.activate([
            title_label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            title_label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            title_label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            status_label.topAnchor.constraint(equalTo: title_label.bottomAnchor, constant: 6),
            status_label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            status_label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            table_view.topAnchor.constraint(equalTo: status_label.bottomAnchor, constant: 12),
            table_view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            table_view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            table_view.bottomAnchor.constraint(equalTo: customTabBar.topAnchor, constant: -16),

            empty_label.centerXAnchor.constraint(equalTo: table_view.centerXAnchor),
            empty_label.centerYAnchor.constraint(equalTo: table_view.centerYAnchor),

            calendar_container_view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            calendar_container_view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            calendar_container_view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            calendar_container_view.bottomAnchor.constraint(equalTo: customTabBar.topAnchor, constant: -16),

            tasks_container_view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tasks_container_view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tasks_container_view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tasks_container_view.bottomAnchor.constraint(equalTo: customTabBar.topAnchor, constant: -16),

            customTabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            customTabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            customTabBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            customTabBar.heightAnchor.constraint(equalToConstant: 74),

            tabStack.topAnchor.constraint(equalTo: customTabBar.topAnchor, constant: 8),
            tabStack.leadingAnchor.constraint(equalTo: customTabBar.leadingAnchor, constant: 8),
            tabStack.trailingAnchor.constraint(equalTo: customTabBar.trailingAnchor, constant: -8),
            tabStack.bottomAnchor.constraint(equalTo: customTabBar.bottomAnchor, constant: -8)
        ])

        addCalendarController()
        addTaskController()

        taskViewController.onEventCreated = { [weak self] in
            self?.reloadTodayEvents()
            self?.calendarViewController.refreshEvents()
        }
        
        calendarViewController.onEventUpdated = { [weak self] in
            self?.reloadTodayEvents()
            self?.taskViewController.refreshEvents()
        }

        updateTabBarAppearance()
        updateScreenForSelectedTab()
    }

    private func makeTabButton(title: String, imageName: String, tag: Int) -> UIButton {
        let button = UIButton(type: .system)

        var configuration = UIButton.Configuration.plain()
        configuration.title = title
        configuration.image = UIImage(systemName: imageName)
        configuration.imagePlacement = .top
        configuration.imagePadding = 4
        configuration.baseForegroundColor = AppStyle.textSecondary

        button.configuration = configuration
        button.tag = tag
        button.addTarget(self, action: #selector(tabButtonTapped(_:)), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false

        return button
    }

    private func addCalendarController() {
        addChild(calendarViewController)
        calendar_container_view.addSubview(calendarViewController.view)

        calendarViewController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            calendarViewController.view.topAnchor.constraint(equalTo: calendar_container_view.topAnchor),
            calendarViewController.view.leadingAnchor.constraint(equalTo: calendar_container_view.leadingAnchor),
            calendarViewController.view.trailingAnchor.constraint(equalTo: calendar_container_view.trailingAnchor),
            calendarViewController.view.bottomAnchor.constraint(equalTo: calendar_container_view.bottomAnchor)
        ])

        calendarViewController.didMove(toParent: self)
    }

    private func addTaskController() {
        addChild(taskViewController)
        tasks_container_view.addSubview(taskViewController.view)

        taskViewController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            taskViewController.view.topAnchor.constraint(equalTo: tasks_container_view.topAnchor),
            taskViewController.view.leadingAnchor.constraint(equalTo: tasks_container_view.leadingAnchor),
            taskViewController.view.trailingAnchor.constraint(equalTo: tasks_container_view.trailingAnchor),
            taskViewController.view.bottomAnchor.constraint(equalTo: tasks_container_view.bottomAnchor)
        ])

        taskViewController.didMove(toParent: self)
    }

    // MARK: - Data

    private func reloadTodayEvents() {
        Task { [weak self] in
            guard let self else { return }

            let events = await self.calendarEventStore.events(for: Date())

            self.todayEvents = events

            self.todayActiveEvents = events.filter {
                !$0.isCompleted
            }

            self.todayCompletedEvents = events.filter {
                $0.isCompleted
            }

            self.updateTodaySummary()
            self.table_view.reloadData()
        }
    }


    private func updateTodaySummary() {
        let totalCount = todayActiveEvents.count + todayCompletedEvents.count

        empty_label.isHidden = totalCount != 0
        table_view.isHidden = totalCount == 0

        if totalCount == 0 {
            status_label.text = "На сегодня задач нет"
        } else if todayCompletedEvents.isEmpty {
            status_label.text = "Задачи на сегодня: \(todayActiveEvents.count)"
        } else {
            status_label.text = "Осталось: \(todayActiveEvents.count) • Выполнено: \(todayCompletedEvents.count)"
        }
    }

    private func toggleTodayEvent(_ event: CalendarEvent) {
        Task { [weak self] in
            guard let self else { return }

            await self.calendarEventStore.setCompleted(
                id: event.id,
                isCompleted: !event.isCompleted
            )

            self.reloadTodayEvents()
            self.calendarViewController.refreshEvents()
            self.taskViewController.refreshEvents()
        }
    }

    private func openEditTask(_ event: CalendarEvent) {
        let editVC = CreateTaskViewController(eventStore: calendarEventStore, editingEvent: event)

        editVC.onEventSaved = { [weak self] in
            self?.reloadTodayEvents()
            self?.calendarViewController.refreshEvents()
            self?.taskViewController.refreshEvents()
        }

        let navigationController = UINavigationController(rootViewController: editVC)

        present(navigationController, animated: true)
    }

    // MARK: - Tabs

    @objc private func tabButtonTapped(_ sender: UIButton) {
        guard let tab = CalendarTab(rawValue: sender.tag) else { return }

        selectedTab = tab
        updateTabBarAppearance()
        updateScreenForSelectedTab()
    }

    private func updateTabBarAppearance() {
        let buttons = [todayTabButton, calendarTabButton, tasksTabButton]

        for button in buttons {
            let isSelected = button.tag == selectedTab.rawValue

            button.configuration?.baseForegroundColor = isSelected ? AppStyle.primary : AppStyle.textSecondary
            button.titleLabel?.font = .systemFont(
                ofSize: 13,
                weight: isSelected ? .semibold : .regular
            )
        }
    }

    private func updateScreenForSelectedTab() {
        switch selectedTab {
        case .today:
            title_label.isHidden = false
            status_label.isHidden = false

            updateTodaySummary()

            calendar_container_view.isHidden = true
            tasks_container_view.isHidden = true

            reloadTodayEvents()

        case .calendar:
            title_label.isHidden = true
            status_label.isHidden = true
            table_view.isHidden = true
            empty_label.isHidden = true

            calendar_container_view.isHidden = false
            tasks_container_view.isHidden = true

            calendarViewController.refreshEvents()

        case .tasks:
            title_label.isHidden = true
            status_label.isHidden = true
            table_view.isHidden = true
            empty_label.isHidden = true

            calendar_container_view.isHidden = true
            tasks_container_view.isHidden = false

            taskViewController.refreshEvents()
        }
    }

    @objc private func doneButtonTapped(_ sender: UIButton) {
        let point = sender.convert(CGPoint.zero, to: table_view)

        guard let indexPath = table_view.indexPathForRow(at: point) else {
            return
        }

        let event = indexPath.section == 1
            ? todayCompletedEvents[indexPath.row]
            : todayActiveEvents[indexPath.row]

        UIView.animate(withDuration: 0.15) {
            sender.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        } completion: { [weak self] _ in
            UIView.animate(withDuration: 0.12) {
                sender.transform = .identity
            } completion: { [weak self] _ in
                self?.toggleTodayEvent(event)
            }
        }
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension ViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return todayCompletedEvents.isEmpty ? 1 : 2
    }

    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        return section == 0 ? todayActiveEvents.count : todayCompletedEvents.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let isCompletedSection = indexPath.section == 1

        let event = isCompletedSection
            ? todayCompletedEvents[indexPath.row]
            : todayActiveEvents[indexPath.row]

        let cell = tableView.dequeueReusableCell(
            withIdentifier: TodayTaskCell.reuseIdentifier,
            for: indexPath
        )

        guard let todayCell = cell as? TodayTaskCell else {
            return cell
        }

        todayCell.configure(
            title: event.title,
            subtitle: makeSubtitle(for: event),
            index: indexPath.row,
            isCompleted: isCompletedSection,
            target: self,
            action: #selector(doneButtonTapped(_:))
        )

        return todayCell
    }

    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: true)

        let event = indexPath.section == 1
            ? todayCompletedEvents[indexPath.row]
            : todayActiveEvents[indexPath.row]

        openEditTask(event)
    }

    func tableView(
        _ tableView: UITableView,
        titleForHeaderInSection section: Int
    ) -> String? {
        return section == 1 ? "Выполнено сегодня" : nil
    }

    func tableView(
        _ tableView: UITableView,
        willDisplayHeaderView view: UIView,
        forSection section: Int
    ) {
        guard let header = view as? UITableViewHeaderFooterView else { return }

        header.textLabel?.textColor = AppStyle.textSecondary
        header.textLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
    }

    private func makeSubtitle(for event: CalendarEvent) -> String {
        if event.isAllDay {
            return event.description.isEmpty
                ? "Весь день"
                : "Весь день • \(event.description)"
        } else {
            return event.description.isEmpty
                ? "\(event.time ?? "")"
                : "\(event.time ?? "") • \(event.description)"
        }
    }
}

// MARK: - TodayTaskCell

final class TodayTaskCell: UITableViewCell {

    static let reuseIdentifier = "TodayTaskCell"

    private let card_view: UIView = {
        let view = UIView()
        view.applyCardStyle(cornerRadius: 18)
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let title_label: UILabel = {
        let label = UILabel()
        label.textColor = AppStyle.textPrimary
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let subtitle_label: UILabel = {
        let label = UILabel()
        label.textColor = AppStyle.textSecondary
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let done_button: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "circle"), for: .normal)
        button.tintColor = AppStyle.primary
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        title_label.attributedText = nil
        title_label.text = nil
        subtitle_label.text = nil
        subtitle_label.textColor = AppStyle.textSecondary

        card_view.alpha = 1

        done_button.isUserInteractionEnabled = true
        done_button.setImage(UIImage(systemName: "circle"), for: .normal)
        done_button.tintColor = AppStyle.accent
        done_button.removeTarget(nil, action: nil, for: .allEvents)
        done_button.tag = 0
    }

    private func configureUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(card_view)

        card_view.addSubview(title_label)
        card_view.addSubview(subtitle_label)
        card_view.addSubview(done_button)

        NSLayoutConstraint.activate([
            card_view.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            card_view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            card_view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            card_view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),

            done_button.trailingAnchor.constraint(equalTo: card_view.trailingAnchor, constant: -16),
            done_button.centerYAnchor.constraint(equalTo: card_view.centerYAnchor),
            done_button.widthAnchor.constraint(equalToConstant: 34),
            done_button.heightAnchor.constraint(equalToConstant: 34),

            title_label.topAnchor.constraint(equalTo: card_view.topAnchor, constant: 13),
            title_label.leadingAnchor.constraint(equalTo: card_view.leadingAnchor, constant: 16),
            title_label.trailingAnchor.constraint(equalTo: done_button.leadingAnchor, constant: -12),

            subtitle_label.topAnchor.constraint(equalTo: title_label.bottomAnchor, constant: 4),
            subtitle_label.leadingAnchor.constraint(equalTo: title_label.leadingAnchor),
            subtitle_label.trailingAnchor.constraint(equalTo: title_label.trailingAnchor)
        ])
    }

    func configure(
        title: String,
        subtitle: String,
        index: Int,
        isCompleted: Bool,
        target: Any?,
        action: Selector
    ) {
        title_label.attributedText = nil
        title_label.text = title
        title_label.textColor = AppStyle.textPrimary

        subtitle_label.text = subtitle
        subtitle_label.textColor = AppStyle.textSecondary

        done_button.tag = index

        done_button.removeTarget(nil, action: nil, for: .allEvents)
        done_button.addTarget(target, action: action, for: .touchUpInside)
        done_button.isUserInteractionEnabled = true

        if isCompleted {
            done_button.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
            done_button.tintColor = AppStyle.success
            card_view.alpha = 0.65
        } else {
            done_button.setImage(UIImage(systemName: "circle"), for: .normal)
            done_button.tintColor = AppStyle.accent
            card_view.alpha = 1
        }
    }
}
