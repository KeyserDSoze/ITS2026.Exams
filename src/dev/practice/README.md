# Esercitazioni Development .NET 10 — percorso progressivo

Sono **12 casi didattici fittizi pubblici**, non esami finali veri: i primi due sono quelli già introdotti, rinumerati; i casi **003–012 sono 10 nuovi esercizi**. Ogni cartella numerata contiene `candidate/` (traccia, TODO, domanda1.txt e domanda2.txt), `solution/` (codice completo), `grader/` (correttore 20 punti), `GUIDA-DOCENTE.md` (passaggi).

## Indice delle prove, dalla più semplice alla più articolata

| Prova | Evoluzione | Consegna | Soluzione | Guida |
| --- | --- | --- | --- | --- |
| [001 — Catalogo libri](001_catalogo_libri/candidate/README.md) | GET, POST e validazione | [Traccia](001_catalogo_libri/candidate/) | [Soluzione](001_catalogo_libri/solution/) | [Guida](001_catalogo_libri/GUIDA-DOCENTE.md) |
| [002 — Registro segnalazioni](002_registro_segnalazioni/candidate/README.md) | GET, POST e messaggi frontend | [Traccia](002_registro_segnalazioni/candidate/) | [Soluzione](002_registro_segnalazioni/solution/) | [Guida](002_registro_segnalazioni/GUIDA-DOCENTE.md) |
| [003 — Lista della spesa](003_lista_spesa/candidate/README.md) | GET/POST e primo intervento HTML/CSS | [Traccia](003_lista_spesa/candidate/) | [Soluzione](003_lista_spesa/solution/) | [Guida](003_lista_spesa/GUIDA-DOCENTE.md) |
| [004 — Rubrica contatti](004_rubrica_contatti/candidate/README.md) | Due campi obbligatori e form | [Traccia](004_rubrica_contatti/candidate/) | [Soluzione](004_rubrica_contatti/solution/) | [Guida](004_rubrica_contatti/GUIDA-DOCENTE.md) |
| [005 — Prenotazioni aule](005_prenotazioni_aule/candidate/README.md) | GET/POST, due campi e lista formattata | [Traccia](005_prenotazioni_aule/candidate/) | [Soluzione](005_prenotazioni_aule/solution/) | [Guida](005_prenotazioni_aule/GUIDA-DOCENTE.md) |
| [006 — Inventario prodotti](006_inventario_prodotti/candidate/README.md) | Primo DELETE | [Traccia](006_inventario_prodotti/candidate/) | [Soluzione](006_inventario_prodotti/solution/) | [Guida](006_inventario_prodotti/GUIDA-DOCENTE.md) |
| [007 — Film preferiti](007_film_preferiti/candidate/README.md) | DELETE e pulsanti per riga | [Traccia](007_film_preferiti/candidate/) | [Soluzione](007_film_preferiti/solution/) | [Guida](007_film_preferiti/GUIDA-DOCENTE.md) |
| [008 — Note spese](008_note_spese/candidate/README.md) | POST a due campi e DELETE | [Traccia](008_note_spese/candidate/) | [Soluzione](008_note_spese/solution/) | [Guida](008_note_spese/GUIDA-DOCENTE.md) |
| [009 — Attività giornaliere](009_attivita_giornaliere/candidate/README.md) | PATCH stato booleano | [Traccia](009_attivita_giornaliere/candidate/) | [Soluzione](009_attivita_giornaliere/solution/) | [Guida](009_attivita_giornaliere/GUIDA-DOCENTE.md) |
| [010 — Prestito attrezzature](010_prestito_attrezzature/candidate/README.md) | PATCH e DELETE | [Traccia](010_prestito_attrezzature/candidate/) | [Soluzione](010_prestito_attrezzature/solution/) | [Guida](010_prestito_attrezzature/GUIDA-DOCENTE.md) |
| [011 — Catalogo corsi](011_catalogo_corsi/candidate/README.md) | PUT di modifica e DELETE | [Traccia](011_catalogo_corsi/candidate/) | [Soluzione](011_catalogo_corsi/solution/) | [Guida](011_catalogo_corsi/GUIDA-DOCENTE.md) |
| [012 — Bacheca annunci](012_bacheca_annunci/candidate/README.md) | PATCH, DELETE e filtro DOM | [Traccia](012_bacheca_annunci/candidate/) | [Soluzione](012_bacheca_annunci/solution/) | [Guida](012_bacheca_annunci/GUIDA-DOCENTE.md) |

**Stack:** .NET SDK 10, ASP.NET Core Minimal API, C#, HTML5, CSS3 e JavaScript vanilla, JSON e liste in memoria. Nessun database/autenticazione.

## Distribuzione agli studenti

Consegnare **solo** `candidate/` della prova assegnata (la `solution/` è pubblica sul repository a scopo didattico: usarla solo dopo la consegna). Ogni prova ha marker fittizio `.exam-id` e le due risposte aperte.

## Esecuzione

```powershell
dotnet run --project ./src/dev/practice/001_catalogo_libri/candidate/ExamApp.csproj
```

Aprire l'indirizzo localhost mostrato da `dotnet run` (oppure eseguire `dotnet run` direttamente dalla cartella del progetto). Per la correzione della prima soluzione:

```powershell
./src/dev/practice/001_catalogo_libri/grader/grade.ps1 -ExamRoot ./src/dev/practice/001_catalogo_libri/solution
```

Il sistema `tools/grade-exam.ps1` identifica automaticamente le prove tramite marker `DEV-001-SAMPLE` ... `DEV-012-SAMPLE`, e genera report JSON/HTML. `tools/build-packages.ps1` crea gli ZIP candidati e il correttore USB.

## Valutazione e limiti del correttore

Ogni prova: tecnica **0–20**, due domande **0–10**. Il grader chiama realmente gli endpoint GET/POST/mutazioni e controlla le risposte e lo stato in memoria; verifica anche la presenza dei principali elementi JS/HTML/CSS, ma **non automatizza un browser reale**. Va quindi completato con una verifica visiva e funzionale del frontend. La correzione pubblica delle domande è basata solo sulla lunghezza.

**Attenzione:** questo è materiale formativo pubblico. Eventuali tracce e soluzioni degli esami finali veri vanno tenute fuori da `main`, secondo `docs/public-boundary.md`.
