# Esercitazioni Development .NET 10

**Casi pubblici fittizi** per preparazione ITS, mai tracce finali reali.

1. [Catalogo libri — esercitazione guidata](books/LEZIONE-GUIDATA.md): [traccia candidato](books/candidate/README.md), [soluzione](books/solution/), correzione 20/20.
2. [Segnalazioni — esercitazione autonoma](tickets/candidate/README.md): distribuire la sola cartella `tickets/candidate/`. Soluzione volutamente non pubblicata.

Stack: ASP.NET Core Minimal API `net10.0`, C#, HTML/CSS, JavaScript vanilla, API REST JSON e memoria volatile. Serve il .NET 10 SDK. Avviare `dotnet run` nella cartella candidata.

I due marker pubblici finiscono in `-SAMPLE` e il correttore USB li riconosce. Per provare dalla radice della repo:

```powershell
./tools/grade-exam.ps1 -SearchRoot ./src/dev/practice/books/candidate -ExamId DEV-BOOKS-SAMPLE
./tools/grade-exam.ps1 -SearchRoot ./src/dev/practice/tickets/candidate -ExamId DEV-TICKETS-SAMPLE
```

Per esami reali mantenere fuori dal repository pubblico tracce, marker, grader e soluzioni.
