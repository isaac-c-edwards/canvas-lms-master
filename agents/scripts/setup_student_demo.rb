# Demo student + graded assignments for What-If manual verification (issue #10).
course = Course.find(1)
teacher = Pseudonym.find_by(unique_id: "admin@example.com").user
raise "Course 1 or admin not found" unless course && teacher

email = "student@example.com"
password = "password"

pseudonym = Account.default.pseudonyms.active.by_unique_id(email).first
if pseudonym
  student = pseudonym.user
  pseudonym.password = pseudonym.password_confirmation = password
  pseudonym.save!
else
  student = User.create!(
    name: "Test Student",
    short_name: "Test",
    sortable_name: "Student, Test"
  )
  student.register!
  pseudonym = student.pseudonyms.create!(
    unique_id: email,
    password: password,
    password_confirmation: password,
    account: Account.default
  )
  student.communication_channels.create!(path: email) { |cc| cc.workflow_state = "active" }
end

enrollment = course.enroll_user(student, "StudentEnrollment", enrollment_state: "active")
enrollment.workflow_state = "active"
enrollment.save!

course.update!(hide_final_grades: false)

unless course.assignments.active.where(title: "Midterm Project").exists?
  a1 = course.assignments.create!(
    title: "Midterm Project",
    points_possible: 800,
    submission_types: ["online_text_entry"],
    workflow_state: "published"
  )
  a1.grade_student(student, grade: 800, grader: teacher)

  course.assignments.create!(
    title: "Final Exam",
    points_possible: 200,
    submission_types: ["online_text_entry"],
    workflow_state: "published"
  )
end

puts "STUDENT_EMAIL=#{email}"
puts "STUDENT_PASSWORD=#{password}"
puts "COURSE_ID=#{course.id}"
puts "GRADES_URL=/courses/#{course.id}/grades"
