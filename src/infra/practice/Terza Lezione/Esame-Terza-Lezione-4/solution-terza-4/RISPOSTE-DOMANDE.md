# Esame-Terza-Lezione-4 — Indicazioni per il docente

## Domanda 1

IIS e il server web che pubblica la pagina HTML. Il file fornito website\index.html viene copiato in C:\LabWeb\Segreteria e aperto nel browser della VM tramite http://localhost:8157/.

## Domanda 2

Un utente locale e un account che puo accedere al computer. Un gruppo raccoglie account ai quali assegnare le stesse autorizzazioni. Assegnando Modify a SegreteriaOperators, segr_operator riceve il permesso tramite l'appartenenza al gruppo. Altri operatori possono ricevere lo stesso permesso entrando nel gruppo.

Sono sufficienti risposte semplici, corrette e coerenti con l'esercizio. Le domande non entrano nel totale automatico.

## Griglia tecnica: 20 punti

| Controllo | Punti |
|---|---:|
| IIS installato | 1 |
| W3SVC avviato | 1 |
| Sito avviato, percorso e index.html | 2 |
| Binding HTTP | 1 |
| Homepage HTTP 200 e testo | 2 |
| Firewall | 2 |
| Utente locale abilitato | 1 |
| Gruppo locale | 1 |
| Appartenenza diretta | 1 |
| Cartella dati | 1 |
| Modify al gruppo, nessuna ACE diretta all'utente | 2 |
| Task: account, trigger e azione | 3 |
| Esecuzione task e backup identico alla homepage | 2 |
