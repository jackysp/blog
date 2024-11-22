---
title: How to Practice Using SQL
date: 2014-06-05
---

The text provided is a detailed set of instructions and queries for practicing SQL using PostgreSQL 9.4 BETA 2, focusing on creating and querying tables related to students, courses, scores, and teachers. Here's a summary:

### Database Structure
The database consists of four tables:
1. **STUDENT**: Contains student number (SNO), name (SNAME), gender (SSEX), birthday (SBIRTHDAY), and class (CLASS).
2. **COURSE**: Includes course number (CNO), name (CNAME), and teacher number (TNO).
3. **SCORE**: Records student number (SNO), course number (CNO), and degree (DEGREE).
4. **TEACHER**: Holds teacher number (TNO), name (TNAME), gender (TSEX), birthday (TBIRTHDAY), professional title (PROF), and department (DEPART).

### Sample Data
- Students such as Zeng Hua, Kang Ming, and Wang Fang are stored with specific details, including their class and gender.
- Courses like "Introduction to Computers" and "Operating Systems" are associated with teacher numbers.
- Scores are recorded for students across various courses.
- Teachers are described with their professional roles and departments.

### Query Problems
Several SQL queries are suggested for practice, such as:
- Extracting specific columns like SNAME, SSEX, and CLASS from the STUDENT table.
- Listing distinct departments for teachers.
- Calculating and sorting grades within the SCORE table.
- Performing database operations to find student averages, count of students per class, and comparing scores.

### Advanced Query Exercises
- Performing set operations and conditional joins to answer complex questions like finding students who scored more than others or comparing teachers' scores.
- Use of SQL functions like `DATE_PART`, subqueries, and unions to gather specific data.

### Additional Queries
- Techniques to refine queries for performance, like avoiding the `NOT IN` method.
- Handling conditions like age calculations using `AGE(SBIRTHDAY)` and filtering by name patterns.

Overall, these exercises provide a robust framework for practicing SQL skills on a structured set of sample data, focusing on various database manipulation and retrieval techniques.7. **Query**: 
   - `SELECT A.TNAME, B.CNAME FROM TEACHER A JOIN COURSE B ON A.TNO = B.TNO WHERE A.TSEX='男';`
   - Explanation: Joins teacher and course tables to select male teachers and their course names.

8. **Query**: 
   - `SELECT A.* FROM SCORE A WHERE DEGREE=(SELECT MAX(DEGREE) FROM SCORE B);`
   - Explanation: Selects all columns from the highest score in the score table.

9. **Query**: 
   - `SELECT SNAME FROM STUDENT A WHERE SSEX=(SELECT SSEX FROM STUDENT B WHERE B.SNAME='李军');`
   - Explanation: Selects student names who have the same gender as the student named 'Li Jun.'

10. **Query**: 
    - `SELECT SNAME FROM STUDENT A WHERE SSEX=(SELECT SSEX FROM STUDENT B WHERE B.SNAME='李军') AND CLASS=(SELECT CLASS FROM STUDENT C WHERE C.SNAME='李军');`
    - Explanation: Selects student names who have the same gender and class as the student named 'Li Jun.'

11. **Two Answers:**
    - `SELECT A.* FROM SCORE A JOIN STUDENT B ON A.SNO = B.SNO JOIN COURSE C ON A.CNO = C.CNO WHERE B.SSEX='男' AND C.CNAME='计算机导论';`
    - `SELECT * FROM SCORE WHERE SNO IN(SELECT SNO FROM STUDENT WHERE SSEX='男') AND CNO=(SELECT CNO FROM COURSE WHERE CNAME='计算机导论');`
    - Explanation: Both queries select scores of male students for the course 'Introduction to Computer Science.'