# Second demo course with more graded work for student@example.com (what-if testing).
# Run: docker compose exec -T web bundle exec rails runner agents/scripts/setup_grades_demo_course.rb

COURSE_NAME = "What-If Grades Lab Course"
STUDENT_EMAIL = "student@example.com"

account = Account.default
teacher = Pseudonym.find_by(unique_id: "admin@example.com")&.user
raise "admin@example.com not found — run db:initial_setup first" unless teacher

password = "password"
pseudonym = account.pseudonyms.active.by_unique_id(STUDENT_EMAIL).first
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
    unique_id: STUDENT_EMAIL,
    password: password,
    password_confirmation: password,
    account: account
  )
  student.communication_channels.create!(path: STUDENT_EMAIL) { |cc| cc.workflow_state = "active" }
  puts "Created #{STUDENT_EMAIL}"
end

course = account.courses.active.find_by(name: COURSE_NAME)
unless course
  course = account.courses.create!(
    name: COURSE_NAME,
    course_code: "WIF-LAB"
  )
  course.enroll_user(teacher, "TeacherEnrollment", enrollment_state: "active")
  course.offer!
  puts "Created course id=#{course.id}"
else
  puts "Reusing course id=#{course.id}"
end

if student
  enrollment = course.enroll_user(student, "StudentEnrollment", enrollment_state: "active")
  enrollment.workflow_state = "active"
  enrollment.save!
end

course.update!(hide_final_grades: false)

# [title, points_possible, score or nil for ungraded]
# Graded scores ≈ 80.42% on completed work (382 / 475 pts) — varied item scores.
ASSIGNMENTS = [
  ["Reading Quiz 1", 25, 19],
  ["Reading Quiz 2", 25, 21],
  ["Homework 1", 50, 41],
  ["Homework 2", 50, 39],
  ["Lab Report", 75, 61],
  ["Midterm Exam", 150, 120],
  ["Group Project", 100, 81],
  ["Presentation", 50, nil],
  ["Final Paper", 100, nil],
  ["Final Exam", 250, nil],
].freeze

ASSIGNMENTS.each do |title, points_possible, score|
  assignment = course.assignments.active.find_by(title: title)
  unless assignment
    assignment = course.assignments.create!(
      title: title,
      points_possible: points_possible,
      submission_types: ["online_text_entry"],
      workflow_state: "published"
    )
    puts "  + #{title} (#{points_possible} pts)"
  elsif assignment.points_possible != points_possible
    assignment.points_possible = points_possible
    assignment.save!
    puts "  ~ #{title} points → #{points_possible}"
  end

  next unless student && score

  submission = assignment.submissions.find_by(user: student)
  if submission&.score == score
    puts "  ok #{title}: #{score}/#{points_possible}"
    next
  end

  assignment.grade_student(student, grade: score, grader: teacher)
  puts "  graded #{title}: #{score}/#{points_possible}"
end

graded_pts = ASSIGNMENTS.sum { |_, pts, score| score ? pts : 0 }
earned_pts = ASSIGNMENTS.sum { |_, _, score| score || 0 }
remaining_pts = ASSIGNMENTS.sum { |_, pts, score| score.nil? ? pts : 0 }
total_pts = ASSIGNMENTS.sum { |_, pts, _| pts }

puts ""
puts "COURSE_NAME=#{COURSE_NAME}"
puts "COURSE_ID=#{course.id}"
puts "GRADES_URL=/courses/#{course.id}/grades"
puts "STUDENT_EMAIL=#{STUDENT_EMAIL}"
pct = graded_pts.positive? ? (100.0 * earned_pts / graded_pts).round(2) : 0
puts "GRADED=#{earned_pts}/#{graded_pts} pts (#{pct}%, #{ASSIGNMENTS.count { |_, _, s| s }} assignments)"
puts "REMAINING_UNGRADED=#{remaining_pts} pts (#{ASSIGNMENTS.count { |_, _, s| s.nil? }} assignments)"
puts "TOTAL_POINTS=#{total_pts}"
