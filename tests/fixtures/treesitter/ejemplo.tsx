// Fixture visual para Tree-sitter y semantic tokens de TypeScript/React.
interface GreetingProps {
  name: string;
  visits: number;
}

type Greeting = string;

export function GreetingCard({ name, visits }: GreetingProps) {
  const message: Greeting = "Hola";
  const initialVisits = 1;
  return <main data-visits={visits + initialVisits}><h1 title={message}>{name}</h1></main>;
}
