# INFRA-SAMPLE - Windows Server / IIS

Configurare la VM affinché il sito fornito sia pubblicato correttamente.

## Requisiti

1. installare IIS;
2. creare il sito `ExamSite`;
3. usare come physical path `C:\Exam\website`;
4. configurare HTTP sulla porta `8081`;
5. creare una regola firewall inbound TCP per la porta 8081;
6. creare l'utente locale `exam_user`;
7. creare `C:\ExamData`;
8. assegnare a `exam_user` il permesso Modify su `C:\ExamData`;
9. creare una Scheduled Task chiamata `ExamHealthCheck`.

Il sito deve mostrare `EXAM SITE - OK` quando raggiunto.

Al termine compilare `domanda1.txt` e `domanda2.txt`. Non modificare `.exam-id`.