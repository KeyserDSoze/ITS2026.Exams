const list = document.querySelector('#entries');
const form = document.querySelector('#entry-form');
const input = document.querySelector('#title');
const message = document.querySelector('#message');

async function loadEntries() {
  // TODO JS 1: GET /api/courses con fetch e response.json().
  // TODO JS 2: riempire #entries creando li e assegnando textContent.
  // TODO JS: ogni elemento deve avere un pulsante Elimina che chiama DELETE.
  // TODO JS: aggiungere un comando Modifica che usa PUT.
  
}

form.addEventListener('submit', async (event) => {
  event.preventDefault();
  // TODO JS: POST /api/courses con Content-Type application/json e
  // body JSON { title: input.value }.
  // TODO JS: mostrare messaggio di successo/errore e richiamare loadEntries().
});

loadEntries();
