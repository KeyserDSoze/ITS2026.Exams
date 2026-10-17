const list = document.querySelector('#tickets');
const form = document.querySelector('#ticket-form');
const input = document.querySelector('#description');
const message = document.querySelector('#message');
async function loadTickets() {
  // TODO: fetch GET /api/tickets, elaborare response.json(), creare <li> con textContent.
}
form.addEventListener('submit', async (event) => {
  event.preventDefault();
  // TODO: fetch POST /api/tickets, body JSON { description: input.value }.
  // TODO: gestire successo/errore, svuotare il campo, aggiornare la lista.
});
loadTickets();
