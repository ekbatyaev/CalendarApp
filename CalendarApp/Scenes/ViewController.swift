import UIKit



struct Ticket {
    let date: String
    let price: Int
    let airport: String
    let source: String
}

enum CalendarTab: Int {
    case tickets
    case calendar
    case profile
}

actor TicketStore
{
    private var tickets: [Ticket] = []
    
    func clear(){
        tickets.removeAll()
    }
    
    func add(_ newTickets: [Ticket]) -> Int{
        tickets.append(contentsOf:  newTickets)
        tickets.sort{$0.price < $1.price}
        return tickets.count
    }
    
    func allTickets() -> [Ticket]{
        tickets
    }
    
    func count() -> Int{
        tickets.count
    }
}

@MainActor
final class ViewController: UIViewController {
    
    // MARK: - Properties
    
    private let ticketStore = TicketStore()
    private let calendarEventStore = CalendarEventStore()

    private var displayedTickets: [Ticket] = []

    private lazy var calendarViewController = CalendarViewController(
        eventStore: calendarEventStore
    )
    
    // MARK: - Subviews
    
    private lazy var find_tickets_button: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Найти билеты", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 22, weight: .semibold)
        button.layer.cornerRadius = 20
        button.layer.masksToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(find_tickets_button_tapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var activity_indicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .systemBlue
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private lazy var status_label: UILabel = {
        let label = UILabel()
        label.text = "Нажмите кнопку, чтобы начать поиск"
        label.textColor = .systemBlue
        label.textAlignment = .center
        label.alpha = 0.8
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var table_view: UITableView = {
        let table = UITableView()
        table.backgroundColor = .white
        table.translatesAutoresizingMaskIntoConstraints = false
        table.dataSource = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return table
    }()
    
    private lazy var calendar_container_view: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var selectedTab: CalendarTab = .tickets

    private lazy var customTabBar: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 28
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.12
        view.layer.shadowOffset = CGSize(width: 0, height: 8)
        view.layer.shadowRadius = 20
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var ticketsTabButton = makeTabButton(
        title: "Сегодня",
        imageName: "list.bullet.rectangle",
        tag: CalendarTab.tickets.rawValue
    )
    
    private lazy var calendarTabButton = makeTabButton(
        title: "Календарь",
        imageName: "calendar",
        tag: CalendarTab.calendar.rawValue
    )
    
    private lazy var profileTabButton = makeTabButton(
        title: "Задачи",
        imageName: "list.bullet.clipboard",
        tag: CalendarTab.profile.rawValue
    )
    
    // MARK: - Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    private func configureUI() {
        view.backgroundColor = .systemGroupedBackground

        view.addSubview(find_tickets_button)
        view.addSubview(activity_indicator)
        view.addSubview(status_label)
        view.addSubview(table_view)
        view.addSubview(calendar_container_view)
        view.addSubview(customTabBar)

        let tabStack = UIStackView(arrangedSubviews: [
            ticketsTabButton,
            calendarTabButton,
            profileTabButton
        ])

        tabStack.axis = .horizontal
        tabStack.distribution = .fillEqually
        tabStack.alignment = .center
        tabStack.translatesAutoresizingMaskIntoConstraints = false

        customTabBar.addSubview(tabStack)

        NSLayoutConstraint.activate([

            find_tickets_button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            find_tickets_button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            find_tickets_button.widthAnchor.constraint(equalToConstant: 250),
            find_tickets_button.heightAnchor.constraint(equalToConstant: 70),

            activity_indicator.topAnchor.constraint(equalTo: find_tickets_button.bottomAnchor, constant: 20),
            activity_indicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            status_label.topAnchor.constraint(equalTo: activity_indicator.bottomAnchor, constant: 20),
            status_label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            status_label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            table_view.topAnchor.constraint(equalTo: status_label.bottomAnchor, constant: 20),
            table_view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            table_view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // Главное изменение: таблица заканчивается выше tab bar
            table_view.bottomAnchor.constraint(equalTo: customTabBar.topAnchor, constant: -16),

            customTabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            customTabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            customTabBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            customTabBar.heightAnchor.constraint(equalToConstant: 74),

            tabStack.topAnchor.constraint(equalTo: customTabBar.topAnchor, constant: 8),
            tabStack.leadingAnchor.constraint(equalTo: customTabBar.leadingAnchor, constant: 8),
            tabStack.trailingAnchor.constraint(equalTo: customTabBar.trailingAnchor, constant: -8),
            tabStack.bottomAnchor.constraint(equalTo: customTabBar.bottomAnchor, constant: -8),
            
            calendar_container_view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            calendar_container_view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            calendar_container_view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            calendar_container_view.bottomAnchor.constraint(equalTo: customTabBar.topAnchor, constant: -16),
        ])

        table_view.backgroundColor = .clear
        table_view.layer.cornerRadius = 18
        table_view.clipsToBounds = true
    
        addCalendarController()
        
        updateTabBarAppearance()
    }
    
    private func makeTabButton(title: String, imageName: String, tag: Int) -> UIButton {
        let button = UIButton(type: .system)

        var configuration = UIButton.Configuration.plain()
        configuration.title = title
        configuration.image = UIImage(systemName: imageName)
        configuration.imagePlacement = .top
        configuration.imagePadding = 4
        configuration.baseForegroundColor = .systemGray

        button.configuration = configuration
        button.tag = tag
        button.addTarget(self, action: #selector(tabButtonTapped(_:)), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false

        return button
    }

    @objc private func tabButtonTapped(_ sender: UIButton) {
        guard let tab = CalendarTab(rawValue: sender.tag) else { return }

        selectedTab = tab
        updateTabBarAppearance()
        updateScreenForSelectedTab()
    }

    private func updateTabBarAppearance() {
        let buttons = [ticketsTabButton, calendarTabButton, profileTabButton]

        for button in buttons {
            let isSelected = button.tag == selectedTab.rawValue

            button.configuration?.baseForegroundColor = isSelected ? .systemBlue : .systemGray
            button.titleLabel?.font = .systemFont(
                ofSize: 13,
                weight: isSelected ? .semibold : .regular
            )
        }
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
    
    private func updateScreenForSelectedTab() {
        switch selectedTab {
        case .tickets:
            status_label.text = "Нажмите кнопку, чтобы начать поиск"

            find_tickets_button.isHidden = false
            activity_indicator.isHidden = false
            status_label.isHidden = false
            table_view.isHidden = false

            calendar_container_view.isHidden = true

        case .calendar:
            find_tickets_button.isHidden = true
            activity_indicator.isHidden = true
            status_label.isHidden = true
            table_view.isHidden = true

            calendar_container_view.isHidden = false

        case .profile:
            status_label.text = "Здесь будут задачи"

            find_tickets_button.isHidden = true
            activity_indicator.isHidden = true
            status_label.isHidden = false
            table_view.isHidden = true

            calendar_container_view.isHidden = true
        }
    }
    
    @objc private func find_tickets_button_tapped() {
        start_search()
    }
    
    private func start_search() {
        displayedTickets.removeAll()
        table_view.reloadData()
        
        find_tickets_button.isEnabled = false
        find_tickets_button.alpha = 0.6
        activity_indicator.startAnimating()
        status_label.text = "Ищу самые выгодные билеты..."
        
        Task { [weak self] in
            guard let self else { return }
            
            await self.ticketStore.clear()
            
            await withTaskGroup(of: Void.self) { group in
                group.addTask { [weak self] in
                    await self?.runSearch(sourceName: "Aviasales")
                }
                group.addTask { [weak self] in
                    await self?.runSearch(sourceName: "Skyscanner")
                }
                group.addTask { [weak self] in
                    await self?.runSearch(sourceName: "Tutu")
                }
                group.addTask { [weak self] in
                    await self?.runSearch(sourceName: "Google Flights")
                }
            }
            
            self.displayedTickets = await self.ticketStore.allTickets()
            self.table_view.reloadData()
            
            self.activity_indicator.stopAnimating()
            self.find_tickets_button.isEnabled = true
            self.find_tickets_button.alpha = 1.0
            self.status_label.text = "Поиск завершён. Найдено билетов: \(self.displayedTickets.count)"
        }
    }
    
    private func runSearch(sourceName: String) async {
        let delay = Int.random(in: 1...15)
        print("\(sourceName) начал поиск. Время: \(delay) сек.")
        
        try? await Task.sleep(for: .seconds(delay))
        
        let foundTickets = generate_tickets(source: sourceName)
        let totalCount = await ticketStore.add(foundTickets)
        
        displayedTickets = await ticketStore.allTickets()
        status_label.text = "\(sourceName) завершил поиск. Найдено билетов: \(totalCount)"
        table_view.reloadData()
    }
    
    private func generate_tickets(source: String) -> [Ticket] {
        let possible_tickets: [Ticket] = [
            Ticket(date: "05.04.2026 08:40", price: 12500, airport: "SVO → LED", source: source),
            Ticket(date: "05.04.2026 10:15", price: 9900, airport: "DME → KZN", source: source),
            Ticket(date: "05.04.2026 13:20", price: 15300, airport: "VKO → AER", source: source),
            Ticket(date: "05.04.2026 16:05", price: 11700, airport: "SVO → EKB", source: source),
            Ticket(date: "05.04.2026 19:45", price: 8600, airport: "DME → LED", source: source),
            Ticket(date: "05.04.2026 21:10", price: 14200, airport: "VKO → KGD", source: source)
        ]
        
        let count = Int.random(in: 1...4)
        return Array(possible_tickets.shuffled().prefix(count))
    }
}

extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        displayedTickets.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let ticket = displayedTickets[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        var content = cell.defaultContentConfiguration()
        content.text = "\(ticket.airport) • \(ticket.price) ₽"
        content.secondaryText = "Дата: \(ticket.date) | Источник: \(ticket.source)"
        
        content.textProperties.color = .black
        content.secondaryTextProperties.color = .gray
        
        cell.backgroundColor = .white
        cell.contentConfiguration = content
        
        return cell
    }
}
