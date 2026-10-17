const list = document.querySelector('#entries');
const form = document.querySelector('#entry-form');
const input = document.querySelector('#name');
const message = document.querySelector('#message');

async function loadEntries() {
  // TODO JS 1: GET /api/tasks con fetch e response.json().
  // TODO JS 2: riempire #entries creando li e assegnando textContent.
  // TODO JS: aggiungere il pulsante per cambiare lo stato via PATCH.
  
}

form.addEventListener('submit', async (event) => {
  event.preventDefault();
  // TODO JS: POST /api/tasks con Content-Type application/json e
  // body JSON { name: input.value }.
  // TODO JS: mostrare messaggio di successo/errore e richiamare loadEntries().
});

loadEntries();
