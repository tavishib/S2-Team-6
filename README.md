# S2-Team-6
# StudyMatch

StudyMatch is a web-based platform designed to help students find, create, and participate in course-based study groups. The system allows students to collaborate effectively while administrators manage courses and maintain platform integrity.

---

## Team 6

* Rupashi Bahl
* Tavishi Bansal
* Aung Aung

---

## Project Overview

StudyMatch provides a space where students can:

* Search for study groups based on course, tags, and meeting preferences
* Create and manage their own study groups
* Join or leave groups
* View group members and meeting schedules
* Participate in group discussions through messaging

Administrators can:

* Manage courses
* Moderate study groups
* Manage users and enforce platform rules

---

## Technologies Used

* **Frontend:** HTML, CSS, JavaScript (JSP-based UI)
* **Backend:** Java (JSP/Servlet structure)
* **Database:** MySQL (designed using MySQL Workbench)
* **Version Control:** GitHub

---

## Database Design

The StudyMatch database is designed using a relational model and includes the following key entities:

* User (supertype)
* Student, Administrator (subtypes)
* Course
* Study_Group
* Membership
* Meeting_Schedule
* Message
* Reply
* Tag
* Group_Tag

### Key Features:

* Primary and foreign key constraints enforce data integrity
* Many-to-many relationships handled via associative tables (Membership, Group_Tag)
* Database normalized to reduce redundancy

---

## Project Structure

```
StudyMatch/
├── index.jsp
├── css/
│   └── styles.css
├── js/
│   └── main.js
├── database/
│   └── schema.sql
└── README.md
```

---

## Sample Data

The database includes sample data with:

* 10+ users and students
* Multiple courses and study groups
* Membership records
* Messages and replies
* Tags and group associations

This demonstrates relationships and ensures the system behaves as expected.

---

## How to Run

1. Clone the repository:

   ```
   git clone <https://github.com/tavishib/S2-Team-6.git>
   ```

2. Import the database:

   * Open MySQL Workbench
   * Create a schema named `StudyMatch`
   * Run the `schema.sql` file

3. Run the web application:

   * Deploy on a Java server (e.g., Apache Tomcat)
   * Open `index.jsp` in browser

---

## Demo Features

* Dashboard-style homepage
* Study group search interface
* Group creation navigation
* Responsive UI design
