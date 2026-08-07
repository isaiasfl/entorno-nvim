interface Student {
  name: string;
}

const greet = (student: Student): string => `Hola, ${student.name}`;

console.log(greet({ name: "Treesitter" }));
