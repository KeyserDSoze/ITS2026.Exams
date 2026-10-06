# Grader privati per gli esami reali

Il repository pubblico non deve conoscere gli ID, le tracce o le soluzioni degli esami reali.

Per questo il correttore supporta un overlay esterno:

```text
private-graders/
  <EXAM-ID>/
    grade.ps1
```

La cartella `private-graders/` è ignorata da Git e non deve essere committata.

## Contratto di `grade.ps1`

Ogni grader privato deve accettare:

```powershell
param(
    [Parameter(Mandatory=$true)][string]$ExamRoot,
    [switch]$Json
)
```

Quando viene invocato con `-Json`, deve restituire un oggetto JSON con questa forma:

```json
{
  "exam": "EXAM-ID",
  "score": 17,
  "maxScore": 20,
  "checks": [
    { "name": "controllo1", "points": 2, "passed": true }
  ]
}
```

`maxScore` deve essere sempre `20`.

## Discovery

Il candidato conserva nel pacchetto:

```text
.exam-id
```

nel formato:

```text
EXAM-ID|TOKEN
```

Per i casi pubblici `DEV-SAMPLE` e `INFRA-SAMPLE` il grader è incorporato nel repository.
Per qualsiasi altro ID, `grade-exam.ps1` cerca automaticamente:

```text
private-graders/<EXAM-ID>/grade.ps1
```

In alternativa è possibile indicare un percorso esterno con:

```powershell
-PrivateGraderRoot D:\EsamiPrivati\graders
```

oppure con la variabile ambiente:

```text
ITS_EXAM_PRIVATE_GRADERS
```

## Creazione della chiavetta privata

Partendo da una cartella privata di grader:

```powershell
.\tools\build-private-usb.ps1 `
  -PrivateGraderRoot D:\EsamiPrivati\graders
```

viene prodotto:

```text
dist-private/USB-CORRETTORE-PRIVATE.zip
```

Lo ZIP contiene il framework pubblico più i grader privati. Il contenuto di `dist-private/` è ignorato da Git e non deve essere pubblicato come artifact della CI pubblica.

## Test pubblico del meccanismo

La CI crea a runtime un grader fittizio `PRIVATE-SAMPLE`, lo usa per correggere una consegna temporanea e verifica anche la costruzione dello ZIP privato. Nessun ID o requisito dell'esame reale viene quindi committato.
