---
title: "Prueba práctica de Python"
lang: es
module: "DWEC 2026_2027"
centre: "IES Hermenegildo Lanz"
teacher: "Isaías FL"
---

# Prueba práctica: funciones y listas

::: datos-examen
**Nombre y apellidos:** ____________________________________

**Grupo:** __________
:::

Lee cada apartado con atención. Justifica las respuestas y utiliza nombres de
variables claros cuando tengas que escribir código.

## 1. Comprensión de código

Observa el programa y responde sin ejecutarlo:

```{.python .numberLines}
def resumen(notas):
    aprobadas = [nota for nota in notas if nota >= 5]
    if not aprobadas:
        return 0, 0
    media = sum(aprobadas) / len(aprobadas)
    return len(aprobadas), round(media, 2)

resultado = resumen([4.5, 7, 8.5, 3, 6])
print(resultado)
```

```js
let a = 10;
let b = 10;

```


1. ¿Qué muestra la llamada a `print`?
2. Explica qué contiene `aprobadas` al terminar la línea 2.
3. ¿Para qué sirve la condición de la línea 3?

## 2. Completa la función

Sustituye `TODO` para devolver únicamente los nombres que comienzan por vocal.
La comparación no debe distinguir entre mayúsculas y minúsculas.

```python
def comienzan_por_vocal(nombres):
    vocales = "aeiou"
    return [nombre for nombre in nombres if TODO]
```

**Solución:**

____________________________________________________________________________

::: page-break
:::

# Segunda parte

## 3. Localiza y corrige el error

El siguiente código pretende calcular el precio final después de aplicar un
descuento, pero produce un resultado incorrecto:

```{.python .numberLines}
def aplicar_descuento(precio, porcentaje):
    descuento = precio * porcentaje
    return precio - descuento

print(aplicar_descuento(80, 20))
```

Indica qué línea modificarías, escribe la corrección y explica el motivo.

____________________________________________________________________________

____________________________________________________________________________

## 4. Diseño de una solución

Escribe una función `es_palindromo(texto)` que:

- ignore espacios;
- no distinga mayúsculas de minúsculas;
- devuelva `True` o `False`;
- incluya un ejemplo de uso.

```python
def es_palindromo(texto):
    # Escribe aquí tu solución
    pass
```

## 5. Criterios de valoración

| Criterio | Puntuación |
|:--|--:|
| Resultado correcto y completo | 4 puntos |
| Explicación y razonamiento | 3 puntos |
| Claridad y nombres de variables | 2 puntos |
| Presentación | 2 punto |

## 6. Conclusión

Como conclusión se puede sacar que :

- Todo ha funcionado bien
- No ha necesitado cambios
