from helpers import Student, average_score, format_name

student = Student("Ana", [8.5, 9.0])
average = average_score(student.scores)
label = format_name(student.name)

bad_average = average_score("not a list")
print(missing_student)
