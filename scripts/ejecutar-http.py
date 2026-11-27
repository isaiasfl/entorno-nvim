#!/usr/bin/env python3
"""Ejecuta la petición HTTP bajo el cursor en un archivo .http/.rest usando curl."""
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

METHODS = {"GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"}
META_MARKER = "__ENTORNO_HTTP_META__"
VAR_DEF = re.compile(r"^@([A-Za-z_][A-Za-z0-9_-]*)\s*=\s*(.+?)\s*$")
VAR_REF = re.compile(r"\{\{\s*([^{}\s]+)\s*\}\}")
REQ_LINE = re.compile(r"^(GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS)\s+(\S+)(?:\s+HTTP/\S+)?\s*$")


def expand_vars(text: str, variables: dict[str, str]) -> str:
    def replace(match: re.Match[str]) -> str:
        name = match.group(1)
        if name.startswith("$env."):
            return os.environ.get(name[5:], match.group(0))
        return variables.get(name, match.group(0))

    return VAR_REF.sub(replace, text)


def parse_file(lines: list[str], cursor_line: int):
    variables: dict[str, str] = {}
    blocks: list[tuple[int, int, str, list[str]]] = []
    start = 1
    title = ""
    current: list[str] = []

    for idx, raw in enumerate(lines, start=1):
        stripped = raw.strip()
        if stripped.startswith("###"):
            if current:
                blocks.append((start, idx - 1, title, current))
                current = []
            start = idx
            title = stripped.lstrip("#").strip()
            continue
        m_var = VAR_DEF.match(stripped)
        if m_var and not current:
            variables[m_var.group(1)] = expand_vars(m_var.group(2), variables)
            continue
        current.append(raw)
    if current:
        blocks.append((start, len(lines), title, current))

    # Elegir el bloque que contiene el cursor; si no coincide, el primero válido.
    selected = None
    for block in blocks:
        if block[0] <= cursor_line <= block[1]:
            selected = block
            break
    if selected is None and blocks:
        selected = blocks[0]
    if selected is None:
        return None

    _, _, req_title, block_lines = selected
    method = None
    url = None
    headers: list[str] = []
    body_lines: list[str] = []
    in_body = False

    for raw in block_lines:
        stripped = raw.strip()
        if method is None:
            if not stripped or stripped.startswith("#") or stripped.startswith("//"):
                continue
            m_var = VAR_DEF.match(stripped)
            if m_var:
                variables[m_var.group(1)] = expand_vars(m_var.group(2), variables)
                continue
            m_req = REQ_LINE.match(stripped)
            if m_req:
                method = m_req.group(1)
                url = expand_vars(m_req.group(2), variables)
            continue

        if not in_body:
            if stripped == "":
                in_body = True
                continue
            if stripped.startswith("#") or stripped.startswith("//"):
                continue
            if ":" in raw:
                headers.append(expand_vars(stripped, variables))
        else:
            body_lines.append(expand_vars(raw, variables))

    if not method or not url:
        return None
    body = "\n".join(body_lines).strip()
    return req_title, method, url, headers, body


def color(code: str, text: str) -> str:
    if not sys.stdout.isatty():
        return text
    return f"\033[{code}m{text}\033[0m"


def status_badge(http_code: int) -> str:
    if 200 <= http_code < 300:
        return color("1;32", f"HTTP {http_code}")
    if 300 <= http_code < 500:
        return color("1;33", f"HTTP {http_code}")
    return color("1;31", f"HTTP {http_code}")


def main() -> int:
    if len(sys.argv) < 2:
        print("Uso: ejecutar-http.py <archivo.http> [linea_cursor]", file=sys.stderr)
        return 2
    path = Path(sys.argv[1])
    cursor_line = int(sys.argv[2]) if len(sys.argv) >= 3 and sys.argv[2].isdigit() else 1
    if not path.is_file():
        print(f"Error: no existe el archivo {path}", file=sys.stderr)
        return 1
    if not shutil.which("curl"):
        print("Error: curl no está instalado.", file=sys.stderr)
        return 1

    lines = path.read_text(encoding="utf-8").splitlines()
    parsed = parse_file(lines, cursor_line)
    if not parsed:
        print("No se encontró ninguna petición HTTP válida en este bloque.", file=sys.stderr)
        print("Ejemplo:\n  ### Listar\n  GET http://localhost:3000/api/items", file=sys.stderr)
        return 1

    title, method, url, headers, body = parsed
    if title:
        print(color("1;36", f"=== {title} ==="))
    print(f"{color('1', method)} {url}\n")

    cmd = [
        "curl",
        "-sS",
        "-i",
        "-X",
        method,
        "-w",
        f"\n{META_MARKER}%{{http_code}} %{{time_total}}",
    ]
    for h in headers:
        cmd.extend(["-H", h])
    if body:
        cmd.extend(["--data-binary", body])
    cmd.append(url)

    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        print(color("1;31", "Error de conexión con curl:"), file=sys.stderr)
        print(proc.stderr.strip(), file=sys.stderr)
        return proc.returncode

    output = proc.stdout
    http_code = 0
    elapsed_ms = 0
    if META_MARKER in output:
        output, meta = output.rsplit(META_MARKER, 1)
        parts = meta.strip().split()
        if len(parts) >= 2:
            http_code = int(parts[0])
            elapsed_ms = int(float(parts[1]) * 1000)

    # Separar cabeceras y cuerpo (maneja respuestas con 100 Continue o redirecciones)
    raw_headers, resp_body = "", output
    sep = "\r\n\r\n" if "\r\n\r\n" in output else "\n\n"
    if sep in output:
        raw_headers, resp_body = output.split(sep, 1)

    print(f"{status_badge(http_code)}  {color('2', f'({elapsed_ms} ms)')}")
    for line in raw_headers.splitlines()[1:]:
        low = line.lower()
        if low.startswith(("content-type:", "location:", "set-cookie:", "x-")):
            print(color("2", f"  {line}"))
    print()

    stripped_body = resp_body.strip()
    if stripped_body:
        try:
            parsed_json = json.loads(stripped_body)
            print(json.dumps(parsed_json, indent=2, ensure_ascii=False))
        except json.JSONDecodeError:
            print(stripped_body)
    else:
        print(color("2", "(sin cuerpo)"))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
