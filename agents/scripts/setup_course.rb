account = Account.default
account.enable_feature!(:create_course_subaccount_picker)
puts "flag: #{account.feature_enabled?(:create_course_subaccount_picker)}"
u = Pseudonym.find_by(unique_id: "admin@example.com").user
c = account.courses.active.find_by(name: "What-If Test Course")
unless c
  c = account.courses.create!(name: "What-If Test Course")
  c.enroll_user(u, "TeacherEnrollment", enrollment_state: "active")
  c.offer!
end
puts "Course: /courses/#{c.id}"
