import UIKit

struct CalendarDay {
    let date: Date
    let number: Int
    let isCurrentMonth: Bool
    let isToday: Bool
    let isSelected: Bool
}


final class CalendarEventCell: UITableViewCell {

    static let reuseIdentifier = "CalendarEventCell"
        
    
    private let card_view: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        return view
    }()

    private let title_label: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let subtitle_label: UILabel = {
        let label = UILabel()
        label.textColor = .systemGray
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let separator_view: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray5
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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

        title_label.text = nil
        subtitle_label.text = nil
        separator_view.isHidden = false
        card_view.layer.cornerRadius = 0
        card_view.layer.maskedCorners = []
        
        card_view.alpha = 1
        title_label.attributedText = nil
        title_label.textColor = .black
        subtitle_label.textColor = .systemGray
    }

    private func configureUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(card_view)
        card_view.addSubview(title_label)
        card_view.addSubview(subtitle_label)
        card_view.addSubview(separator_view)

        NSLayoutConstraint.activate([
            card_view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            card_view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            card_view.topAnchor.constraint(equalTo: contentView.topAnchor),
            card_view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            title_label.leadingAnchor.constraint(equalTo: card_view.leadingAnchor, constant: 16),
            title_label.trailingAnchor.constraint(equalTo: card_view.trailingAnchor, constant: -16),
            title_label.topAnchor.constraint(equalTo: card_view.topAnchor, constant: 12),

            subtitle_label.leadingAnchor.constraint(equalTo: title_label.leadingAnchor),
            subtitle_label.trailingAnchor.constraint(equalTo: title_label.trailingAnchor),
            subtitle_label.topAnchor.constraint(equalTo: title_label.bottomAnchor, constant: 4),

            separator_view.leadingAnchor.constraint(equalTo: card_view.leadingAnchor, constant: 16),
            separator_view.trailingAnchor.constraint(equalTo: card_view.trailingAnchor),
            separator_view.bottomAnchor.constraint(equalTo: card_view.bottomAnchor),
            separator_view.heightAnchor.constraint(equalToConstant: 1)
        ])
    }

    func configure(
        title: String,
        subtitle: String,
        indexPath: IndexPath,
        rowsCount: Int,
        isCompleted: Bool = false
    ) {
        title_label.attributedText = nil
        title_label.text = title
        subtitle_label.text = subtitle

        title_label.textColor = .black
        subtitle_label.textColor = .systemGray

        card_view.alpha = isCompleted ? 0.45 : 1

        let isFirst = indexPath.row == 0
        let isLast = indexPath.row == rowsCount - 1

        card_view.layer.cornerRadius = 16

        if rowsCount == 1 {
            card_view.layer.maskedCorners = [
                .layerMinXMinYCorner,
                .layerMaxXMinYCorner,
                .layerMinXMaxYCorner,
                .layerMaxXMaxYCorner
            ]
            separator_view.isHidden = true
        } else if isFirst {
            card_view.layer.maskedCorners = [
                .layerMinXMinYCorner,
                .layerMaxXMinYCorner
            ]
            separator_view.isHidden = false
        } else if isLast {
            card_view.layer.maskedCorners = [
                .layerMinXMaxYCorner,
                .layerMaxXMaxYCorner
            ]
            separator_view.isHidden = true
        } else {
            card_view.layer.cornerRadius = 0
            card_view.layer.maskedCorners = []
            separator_view.isHidden = false
        }
    }
}

@MainActor
final class CalendarViewController: UIViewController {

    private let eventStore: CalendarEventStore
    
    var onEventUpdated: (() -> Void)?
    
    private var collectionViewHeightConstraint: NSLayoutConstraint?

    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ru_RU")
        calendar.firstWeekday = 2
        return calendar
    }()

    private var currentDate = Date()
    private var selectedDate = Date()

    private var days: [CalendarDay] = []
    private var selectedDateEvents: [CalendarEvent] = []

    init(eventStore: CalendarEventStore) {
        self.eventStore = eventStore
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Subviews

    private lazy var month_label: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = .systemFont(ofSize: 26, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var previous_month_button: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .systemBlue
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(previous_month_button_tapped), for: .touchUpInside)
        return button
    }()

    private lazy var next_month_button: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        button.tintColor = .systemBlue
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(next_month_button_tapped), for: .touchUpInside)
        return button
    }()

    private lazy var weekdays_stack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var collection_view: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 4
        layout.minimumInteritemSpacing = 0

        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = .clear
        collection.dataSource = self
        collection.delegate = self
        collection.register(CalendarDayCell.self, forCellWithReuseIdentifier: CalendarDayCell.reuseIdentifier)
        collection.translatesAutoresizingMaskIntoConstraints = false
        return collection
    }()
    
    private lazy var selected_date_label: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var events_table_view: UITableView = {
        let table = UITableView()
        table.backgroundColor = .clear
        table.dataSource = self
        table.delegate = self
        table.register(CalendarEventCell.self, forCellReuseIdentifier: CalendarEventCell.reuseIdentifier)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.alwaysBounceVertical = true
        table.showsVerticalScrollIndicator = true
        table.separatorStyle = .none
        table.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 16, right: 0)
        return table
    }()

    private lazy var empty_events_label: UILabel = {
        let label = UILabel()
        label.text = "На этот день пока нет дел"
        label.textColor = .systemGray
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Lifecycle
    
    

    override func viewDidLoad() {
        super.viewDidLoad()

        configureUI()
        configureWeekdays()
        reloadCalendar()
        reloadEventsForSelectedDate()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        reloadEventsForSelectedDate()
    }

    // MARK: - Methods

    private func configureUI() {
        view.backgroundColor = .systemGroupedBackground

        view.addSubview(month_label)
        view.addSubview(previous_month_button)
        view.addSubview(next_month_button)
        view.addSubview(weekdays_stack)
        view.addSubview(collection_view)
        view.addSubview(selected_date_label)
        view.addSubview(events_table_view)
        view.addSubview(empty_events_label)
        
        collectionViewHeightConstraint = collection_view.heightAnchor.constraint(equalToConstant: 300)
        
        NSLayoutConstraint.activate([
            month_label.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            month_label.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            previous_month_button.centerYAnchor.constraint(equalTo: month_label.centerYAnchor),
            previous_month_button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            previous_month_button.widthAnchor.constraint(equalToConstant: 44),
            previous_month_button.heightAnchor.constraint(equalToConstant: 44),

            next_month_button.centerYAnchor.constraint(equalTo: month_label.centerYAnchor),
            next_month_button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            next_month_button.widthAnchor.constraint(equalToConstant: 44),
            next_month_button.heightAnchor.constraint(equalToConstant: 44),

            weekdays_stack.topAnchor.constraint(equalTo: month_label.bottomAnchor, constant: 15),
            weekdays_stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            weekdays_stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            weekdays_stack.heightAnchor.constraint(equalToConstant: 28),

            collection_view.topAnchor.constraint(equalTo: weekdays_stack.bottomAnchor, constant: 6),
            collection_view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collection_view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionViewHeightConstraint!,
            
            selected_date_label.topAnchor.constraint(equalTo: collection_view.bottomAnchor, constant: 16),
            selected_date_label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            selected_date_label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            events_table_view.topAnchor.constraint(equalTo: selected_date_label.bottomAnchor, constant: 4),
            events_table_view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            events_table_view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            events_table_view.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            empty_events_label.centerXAnchor.constraint(equalTo: events_table_view.centerXAnchor),
            empty_events_label.centerYAnchor.constraint(equalTo: events_table_view.centerYAnchor),
            empty_events_label.leadingAnchor.constraint(equalTo: events_table_view.leadingAnchor, constant: 20),
            empty_events_label.trailingAnchor.constraint(equalTo: events_table_view.trailingAnchor, constant: -20)
        ])
    }

    private func configureWeekdays() {
        let weekdays = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]

        weekdays.forEach { weekday in
            let label = UILabel()
            label.text = weekday
            label.textColor = .systemGray
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 14, weight: .semibold)
            weekdays_stack.addArrangedSubview(label)
        }
    }

    private func reloadCalendar() {
        month_label.text = makeMonthTitle(from: currentDate)
        days = generateDays(for: currentDate)

        let rowsCount = CGFloat(days.count / 7)
        let rowHeight: CGFloat = 48
        let lineSpacing: CGFloat = 4

        collectionViewHeightConstraint?.constant =
            rowsCount * rowHeight + max(0, rowsCount - 1) * lineSpacing

        collection_view.reloadData()
    }

    private func makeMonthTitle(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "LLLL yyyy"

        let text = formatter.string(from: date)
        return text.prefix(1).uppercased() + text.dropFirst()
    }

    private func generateDays(for date: Date) -> [CalendarDay] {
        guard
            let monthInterval = calendar.dateInterval(of: .month, for: date),
            let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
            let lastWeek = calendar.dateInterval(
                of: .weekOfMonth,
                for: monthInterval.end.addingTimeInterval(-1)
            )
        else {
            return []
        }

        var result: [CalendarDay] = []
        var current = firstWeek.start

        while current < lastWeek.end {
            let number = calendar.component(.day, from: current)
            let isCurrentMonth = calendar.isDate(current, equalTo: date, toGranularity: .month)
            let isToday = calendar.isDateInToday(current)

            let isSelected = calendar.isDate(current, inSameDayAs: selectedDate)

            result.append(
                CalendarDay(
                    date: current,
                    number: number,
                    isCurrentMonth: isCurrentMonth,
                    isToday: isToday,
                    isSelected: isSelected
                )
            )

            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: current) else {
                break
            }

            current = nextDay
        }

        return result
    }
    
    private func reloadEventsForSelectedDate() {
        selected_date_label.text = makeSelectedDateTitle(from: selectedDate)

        Task { [weak self] in
            guard let self else { return }

            let events = await eventStore.events(for: selectedDate)

            selectedDateEvents = events.sorted { first, second in
                if first.isCompleted != second.isCompleted {
                    return !first.isCompleted && second.isCompleted
                }

                if first.isAllDay != second.isAllDay {
                    return first.isAllDay && !second.isAllDay
                }

                return (first.time ?? "") < (second.time ?? "")
            }

            events_table_view.reloadData()

            empty_events_label.isHidden = !selectedDateEvents.isEmpty
            events_table_view.isHidden = selectedDateEvents.isEmpty
        }
    }
    
    
    func refreshEvents() {
        reloadCalendar()
        reloadEventsForSelectedDate()
    }
    
    private func makeSelectedDateTitle(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM, EEEE"

        let text = formatter.string(from: date)
        return text.prefix(1).uppercased() + text.dropFirst()
    }

    @objc private func previous_month_button_tapped() {
        guard let newDate = calendar.date(byAdding: .month, value: -1, to: currentDate) else {
            return
        }

        currentDate = newDate
        reloadCalendar()
    }

    @objc private func next_month_button_tapped() {
        guard let newDate = calendar.date(byAdding: .month, value: 1, to: currentDate) else {
            return
        }

        currentDate = newDate
        reloadCalendar()
    }
}

extension CalendarViewController: UICollectionViewDataSource {

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        days.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CalendarDayCell.reuseIdentifier,
            for: indexPath
        )

        guard let calendarCell = cell as? CalendarDayCell else {
            return cell
        }

        calendarCell.configure(with: days[indexPath.item])
        return calendarCell
    }
}

extension CalendarViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let width = collectionView.bounds.width / 7
        return CGSize(width: width, height: 48)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        let day = days[indexPath.item]

        selectedDate = day.date

        if !day.isCurrentMonth {
            currentDate = day.date
        }

        reloadCalendar()
        reloadEventsForSelectedDate()
    }
}

extension CalendarViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        selectedDateEvents.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let event = selectedDateEvents[indexPath.row]

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
            rowsCount: selectedDateEvents.count,
            isCompleted: event.isCompleted
        )

        return eventCell
    }
    
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        let event = selectedDateEvents[indexPath.row]

        Task { [weak self] in
            guard let self else { return }

            await self.eventStore.toggleCompleted(id: event.id)

            self.reloadEventsForSelectedDate()

            self.onEventUpdated?()
        }
    }

    func tableView(
        _ tableView: UITableView,
        heightForRowAt indexPath: IndexPath
    ) -> CGFloat {
        72
    }
}


final class CalendarDayCell: UICollectionViewCell {

    static let reuseIdentifier = "CalendarDayCell"

    private lazy var circle_view: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBlue
        view.isHidden = true
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var day_label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        circle_view.layer.cornerRadius = 19
        circle_view.layer.masksToBounds = true
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        day_label.text = nil
        day_label.textColor = .black
        day_label.font = .systemFont(ofSize: 17, weight: .medium)
        circle_view.isHidden = true
        circle_view.backgroundColor = .systemBlue
        
        
    }

    private func configureUI() {
        contentView.addSubview(circle_view)
        contentView.addSubview(day_label)

        NSLayoutConstraint.activate([
            circle_view.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            circle_view.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            circle_view.widthAnchor.constraint(equalToConstant: 38),
            circle_view.heightAnchor.constraint(equalToConstant: 38),

            day_label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            day_label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            day_label.widthAnchor.constraint(equalTo: contentView.widthAnchor),
            day_label.heightAnchor.constraint(equalTo: contentView.heightAnchor)
        ])
    }

    func configure(with day: CalendarDay) {
        day_label.text = "\(day.number)"

        if day.isSelected {
            circle_view.isHidden = false
            circle_view.backgroundColor = .systemBlue
            day_label.textColor = .white
            day_label.font = .systemFont(ofSize: 17, weight: .bold)

        } else if day.isToday {
            circle_view.isHidden = false
            circle_view.backgroundColor = .systemGray4
            day_label.textColor = .systemBlue
            day_label.font = .systemFont(ofSize: 17, weight: .bold)

        } else if day.isCurrentMonth {
            circle_view.isHidden = true
            day_label.textColor = .black
            day_label.font = .systemFont(ofSize: 17, weight: .medium)

        } else {
            circle_view.isHidden = true
            day_label.textColor = .systemGray3
            day_label.font = .systemFont(ofSize: 17, weight: .regular)
        }
    }
}



