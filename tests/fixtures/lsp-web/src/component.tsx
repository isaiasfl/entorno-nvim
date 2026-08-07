declare global {
  namespace JSX {
    interface IntrinsicElements {
      button: { children?: unknown; type?: "button" | "submit" }
    }
  }
}

export function Counter() {
  const count: number = 1
  return <button type="button">{count}</button>
}
