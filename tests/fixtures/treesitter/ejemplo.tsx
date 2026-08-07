type GreetingProps = {
  name: string;
};

export function Greeting({ name }: GreetingProps) {
  return <main><h1>Hola, {name}</h1></main>;
}
