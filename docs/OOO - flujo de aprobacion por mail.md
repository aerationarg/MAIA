# Fuera de oficina: aprobar desde el mail con Power Automate

Objetivo: que cuando alguien envía una solicitud desde MAIA, al coordinador le llegue un mail de **aprobación** (con los botones Aprobar / Rechazar) y, cuando el coordinador aprueba, lo mismo le llegue a la coordinadora de RR.HH. La respuesta se escribe sola en la lista de SharePoint y MAIA la muestra.

No hace falta agregar columnas a la lista ni tocar nada del flujo viejo (el que se dispara con el formulario): este es un flujo **nuevo**, que mira la lista "OOO Solicitudes".

## Cómo funciona

```
MAIA crea / cambia un ítem en la lista  →  el flujo salta si el estado es
pendiente_coord o pendiente_rrhh  →  manda el approval por mail  →
al responder, el flujo actualiza el ítem (Estado, Rta…, Fecha…, Coment…)  →
MAIA lo ve al abrir la solapa (o con el botón ↻)
```

- Si alguien aprueba **desde MAIA** primero, el flujo, cuando le contesten el mail, se da cuenta de que ya no corresponde y no pisa nada.
- Si el coordinador aprueba (por mail o por MAIA), el ítem pasa a `pendiente_rrhh` y el flujo vuelve a saltar y le manda el approval a RR.HH.
- Si se rechaza (por mail o por MAIA), la persona lo corrige y lo reenvía desde MAIA: el ítem vuelve a `pendiente_coord` con una ronda más y el flujo manda otro approval.

## Armado del flujo (Power Automate → Mis flujos → Nuevo flujo → Flujo de nube automatizado)

Nombre sugerido: **MAIA – Aprobación de Fuera de oficina**

### 1. Disparador
**SharePoint → Cuando se crea o modifica un elemento**
- Dirección del sitio: el de Vacaciones y Licencias (`aerationargentina.sharepoint.com/sites/VacacionesyLicencias`).
- Nombre de la lista: **OOO Solicitudes** (si más adelante MAIA apunta a otra lista, se cambia acá).

Dentro del disparador, **⋯ → Configuración**:
- **Control de simultaneidad**: activar, grado de paralelismo **1**.
- **Condiciones del desencadenador** (agregar una, tal cual):
  ```
  @or(equals(triggerOutputs()?['body/Estado'],'pendiente_coord'),equals(triggerOutputs()?['body/Estado'],'pendiente_rrhh'))
  ```

### 2. Variables (tres acciones "Inicializar variable", tipo Cadena)

| Nombre | Valor (pestaña Expresión) |
|---|---|
| `etapa` | `if(equals(triggerOutputs()?['body/Estado'],'pendiente_coord'),'coord','rrhh')` |
| `aprobadores` | `if(equals(variables('etapa'),'coord'),replace(triggerOutputs()?['body/AprobCoord'],',',';'),'MAIL-DE-LA-COORDINADORA-DE-RRHH')` |
| `ronda` | `string(triggerOutputs()?['body/Ronda'])` |

En `aprobadores` reemplazá `MAIL-DE-LA-COORDINADORA-DE-RRHH` por el mail real (si son varias personas, separados por `;`). El coordinador del sector sale solo de la columna `AprobCoord`, que MAIA ya completa.

### 3. Aprobación
**Aprobaciones → Iniciar y esperar una aprobación**. Cambiale el nombre a la acción por **Aprobacion** (⋯ → Cambiar nombre; sin espacios ni tildes, así las expresiones de abajo funcionan).
- Tipo de aprobación: **Aprobar o rechazar: el primero en responder**.
- Título (expresión + texto): `Fuera de oficina (ronda <ronda>): <Title del ítem>`
  Se arma con: `Fuera de oficina (ronda ` + variable `ronda` + `): ` + el campo **Title** del disparador.
- Asignado a: la variable `aprobadores`.
- Detalles (texto, acepta Markdown). Armalo con contenido dinámico del disparador:
  ```
  **Persona:** [EmpleadoNombre] ([Sector])
  **Tipo:** [Tipo]
  **Desde / hasta:** [Desde (texto)] al [Hasta (texto)]
  **Días:** [Dias]
  **Se superpone con otras ausencias o eventos:** [Superposicion]
  **Cómo se gestiona:** [Gestion]
  **Comentarios:** [Comentarios]
  Etapa: [etapa] · Ronda: [Ronda]
  ```
- Vínculo del elemento: `https://aerationarg.github.io/MAIA/` · Descripción: `Abrir MAIA`.
- Opcional: marcar **Habilitar notificaciones** y **Habilitar volver a asignar** si quieren que el coordinador pueda derivarlo.

### 4. Releer el ítem y comprobar que sigue pendiente
**SharePoint → Obtener elemento** (cambiale el nombre a **ElementoActual**). Id: `ID` del disparador.

Después **Control → Condición** (cambiale el nombre a **SigueIgual**):
```
@and(equals(outputs('ElementoActual')?['body/Estado'],triggerOutputs()?['body/Estado']),equals(string(outputs('ElementoActual')?['body/Ronda']),variables('ronda')))
```
- **Si es falso**: acción **Terminar** → Estado "Cancelado", mensaje "Ya se resolvió desde MAIA". (Pasa cuando alguien aprobó desde MAIA antes de que respondan el mail.)
- **Si es verdadero**: el paso 5.

### 5. Actualizar el ítem (rama "Si es verdadero")
**SharePoint → Actualizar elemento**: sitio y lista iguales a los del disparador, Id = `ID` del disparador. Completá estos campos con expresiones (los demás dejalos vacíos):

| Campo | Expresión |
|---|---|
| **Estado** | `if(equals(outputs('Aprobacion')?['body/outcome'],'Approve'),if(equals(variables('etapa'),'coord'),'pendiente_rrhh','aprobada'),'rechazada')` |
| **RtaCoord** | `if(equals(variables('etapa'),'coord'),if(equals(outputs('Aprobacion')?['body/outcome'],'Approve'),'Aprobado','Rechazado'),outputs('ElementoActual')?['body/RtaCoord'])` |
| **FechaCoord** | `if(equals(variables('etapa'),'coord'),utcNow(),outputs('ElementoActual')?['body/FechaCoord'])` |
| **ComentCoord** | `if(equals(variables('etapa'),'coord'),first(outputs('Aprobacion')?['body/responses'])?['comments'],outputs('ElementoActual')?['body/ComentCoord'])` |
| **RtaRRHH** | `if(equals(variables('etapa'),'rrhh'),if(equals(outputs('Aprobacion')?['body/outcome'],'Approve'),'Aprobado','Rechazado'),outputs('ElementoActual')?['body/RtaRRHH'])` |
| **FechaRRHH** | `if(equals(variables('etapa'),'rrhh'),utcNow(),outputs('ElementoActual')?['body/FechaRRHH'])` |
| **ComentRRHH** | `if(equals(variables('etapa'),'rrhh'),first(outputs('Aprobacion')?['body/responses'])?['comments'],outputs('ElementoActual')?['body/ComentRRHH'])` |

Los textos `Aprobado` y `Rechazado` y los estados `pendiente_rrhh`, `aprobada`, `rechazada` tienen que escribirse **exactamente así** (minúsculas, con guion bajo): son los que MAIA entiende.

Importante: no toques **Historial**. MAIA lo completa solo con lo que se respondió por mail (aparece como "Aprobó (coordinador, por mail)").

### 6. (Opcional) Avisarle a la persona por mail
Después de actualizar, **Office 365 Outlook → Enviar un correo electrónico (V2)** a `EmpleadoEmail` con el resultado. Asunto sugerido: `Tu solicitud de Fuera de oficina: ` + Estado. Si lo agregan, MAIA no manda ese mail (solo la campanita cuando la resolución se hace desde MAIA).

## Activar en MAIA
1. En **Cfg → Fuera de oficina → Aprobación y avisos**, tildar **"Quien aprueba recibe un mail de aprobación de Power Automate"**. Así MAIA deja de mandarle mail a quien aprueba (le sigue avisando por la campanita) y no se duplica.
2. Dejar **"Avisar por campanita y por mail"** como esté: sigue controlando los avisos a la persona que pidió.

## Probar
1. Con el flujo **desactivado**, tildar la opción en MAIA no cambia nada del resto; activalo recién cuando esté armado.
2. Enviar una solicitud de prueba desde MAIA (con un usuario cuyo coordinador seas vos o alguien de prueba). Tiene que llegar el approval al mail.
3. Aprobar desde el mail: en MAIA (botón ↻) la solicitud pasa a "Pendiente de RR.HH." y llega el approval a RR.HH.
4. Rechazar desde el mail: en MAIA queda "Rechazada" con el comentario, y se puede corregir y reenviar.
5. Aprobar desde MAIA mientras el mail está pendiente, y después responder el mail: el flujo termina en "Cancelado" y no cambia nada.

## Si no anda
- **No llega el approval:** ver el historial de ejecuciones del flujo. Si no salta, revisar la condición del disparador y que la lista sea la correcta.
- **Salta pero falla "Actualizar elemento":** el dueño del flujo tiene que poder editar la lista.
- **Hay dos approvals iguales:** SharePoint a veces avisa dos veces un cambio. Con el paralelismo en 1 y la comprobación del paso 4 no se pisan, pero el segundo mail puede llegar; basta con ignorarlo.
- **Para otra lista (por ejemplo "Calendario"):** cambiar el nombre de la lista en el disparador y en "Obtener elemento"/"Actualizar elemento" y en Cfg de MAIA. Ojo: esa lista tendría que tener las columnas que MAIA usa (ver "Preparar la lista" en Cfg).
