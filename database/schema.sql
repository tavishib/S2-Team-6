CREATE DATABASE StudyMatch;
USE StudyMatch;
--Create table to store User information
CREATE TABLE User (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100) UNIQUE,
    password_hash VARCHAR(255)
);
--Create table to store Student information, linked to User table
CREATE TABLE Student (
    user_id INT PRIMARY KEY,
    major VARCHAR(100),
    FOREIGN KEY (user_id) REFERENCES User(user_id)
);
--Create table to store Administrator information, linked to User table
CREATE TABLE Administrator (
    user_id INT PRIMARY KEY,
    admin_level INT,
    FOREIGN KEY (user_id) REFERENCES User(user_id)
);
--Create table to store Course information
CREATE TABLE Course (
    course_id VARCHAR(20) PRIMARY KEY,
    deptName VARCHAR(50),
    title VARCHAR(100),
    term VARCHAR(20)
);
--Create table to store Study Group information, linked to Course and Student tables
CREATE TABLE Study_Group (
    group_id INT AUTO_INCREMENT PRIMARY KEY,
    course_id VARCHAR(20),
    leader_id INT,
    group_name VARCHAR(100),
    description TEXT,
    modality VARCHAR(20),
    max_capacity INT,
    current_status VARCHAR(20),
    location VARCHAR(100),

    FOREIGN KEY (course_id) REFERENCES Course(course_id),
    FOREIGN KEY (leader_id) REFERENCES Student(user_id)
);
--Create table to store Membership information, linking Students to Study Groups
CREATE TABLE Membership (
    user_id INT,
    group_id INT,
    joined_at DATETIME,
    membership_role VARCHAR(20),
    membership_status VARCHAR(20),

    PRIMARY KEY (user_id, group_id),

    FOREIGN KEY (user_id) REFERENCES Student(user_id),
    FOREIGN KEY (group_id) REFERENCES Study_Group(group_id)
);
--Create table to store Meeting Schedule information, linked to Study Group table
CREATE TABLE Meeting_Schedule (
    meeting_id INT AUTO_INCREMENT PRIMARY KEY,
    group_id INT,
    meeting_day VARCHAR(20),
    start_time TIME,
    end_time TIME,
    location VARCHAR(100),
    meeting_type VARCHAR(20),

    FOREIGN KEY (group_id) REFERENCES Study_Group(group_id)
);
--Create table to store Messages, linked to Study Group and User tables
CREATE TABLE Message (
    message_id INT AUTO_INCREMENT PRIMARY KEY,
    group_id INT,
    user_id INT,
    message_text TEXT,
    posted_at DATETIME,

    FOREIGN KEY (group_id) REFERENCES Study_Group(group_id),
    FOREIGN KEY (user_id) REFERENCES User(user_id)
);
--Create table to store Replies to Messages, linked to Message and User tables
CREATE TABLE Reply (
    reply_id INT AUTO_INCREMENT PRIMARY KEY,
    message_id INT,
    user_id INT,
    reply_text TEXT,
    posted_at DATETIME,

    FOREIGN KEY (message_id) REFERENCES Message(message_id),
    FOREIGN KEY (user_id) REFERENCES User(user_id)
);
--Create table to store Tags, which can be associated with Study Groups
CREATE TABLE Tag (
    tag_id INT AUTO_INCREMENT PRIMARY KEY,
    tag_name VARCHAR(50) UNIQUE
);
--Create table to link Study Groups and Tags, allowing for many-to-many relationships
CREATE TABLE Group_Tag (
    group_id INT,
    tag_id INT,

    PRIMARY KEY (group_id, tag_id),

    FOREIGN KEY (group_id) REFERENCES Study_Group(group_id),
    FOREIGN KEY (tag_id) REFERENCES Tag(tag_id)
);