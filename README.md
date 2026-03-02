# Discipline (Дисциплина) 🚀

![Discipline Hero](assets/readme/hero.png)

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Clean Architecture](https://img.shields.io/badge/Architecture-Clean-red?style=for-the-badge)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

**Discipline** — это современное приложение для управления задачами и формирования привычек, созданное для тех, кто ценит строгую дисциплину и визуальный прогресс. 

---

## ✨ Основные Возможности

### 🧠 Умная Логика Повторений
Никаких "просто ежедневных" задач (хотя они тоже есть). Наш движок поддерживает:
*   **WEEKLY**: Выбирайте конкретные дни недели (Пн/Ср/Пт).
*   **INTERVAL**: Планируйте задачи раз в N дней.
*   **ONE_TIME**: Быстрые разовые дела, привязанные к календарю.

### 📈 Продвинутая Статистика и Геймификация
*   **Streak (🔥 Огонь)**: Ваша серия дней без пропусков постоянных задач.
*   **Баллы и Уровни**: За каждую выполненную задачу вы получаете очки. Прокачивайте свой уровень дисциплины!
*   **История 14 дней**: Наглядный календарный вид ваших успехов и пропусков.

### 💎 Премиальный UI/UX
*   **Material 3 Design**: Тёмная тема с аккуратными акцентами `RedAccent`.
*   **Плавные Анимации**: Мягкое зачеркивание текста и анимированные чекбоксы.
*   **Удобство ввода**: Оптимизированное время (Input Mode) для работы в любых условиях.

![Discipline Mockups](assets/readme/tasks.png)

---

## 🛠 Технологический Стек

| Компонент | Технология |
| :--- | :--- |
| **Framework** | [Flutter](https://flutter.dev) |
| **State Management** | [flutter_bloc](https://pub.dev/packages/flutter_bloc) |
| **Persistence** | [Drift (SQLite)](https://drift.simonbinder.eu/) |
| **DI** | [GetIt](https://pub.dev/packages/get_it) |
| **Architecture** | Clean Architecture (Domain, Data, Presentation) |

---

## 🏗 Архитектура

Приложение построено по принципам **Clean Architecture**:

```mermaid
graph TD
    UI[Presentation / UI] --> Bloc[BLoC / States]
    Bloc --> Engine[Domain / UseCases]
    Engine --> Entities[Domain / Entities]
    Engine --> DB[Data / Drift Database]
```

---

## 🚀 Начало Работы

### Требования
*   Flutter SDK (3.x+)
*   Dart SDK

### Установка
1. Клонируйте репозиторий:
   ```bash
   git clone https://github.com/F0nkell/F.O.K.us_Mobile.git
   ```
2. Подтяните зависимости:
   ```bash
   flutter pub get
   ```
3. Сгенерируйте файлы базы данных:
   ```bash
   dart run build_runner build
   ```
4. Запустите приложение:
   ```bash
   flutter run
   ```

---

## 📸 Скриншоты

<table border="0">
 <tr>
    <td><img src="assets/readme/tasks.png" width="300" alt="Список задач"></td>
    <td><img src="assets/readme/stats.png" width="300" alt="Статистика"></td>
 </tr>
</table>

---

## 📝 Лицензия

Распространяется под лицензией MIT. Подробности в [LICENSE](LICENSE).

---
*Разработано с ❤️ от F0nkell для настоящих воинов дисциплины.*
