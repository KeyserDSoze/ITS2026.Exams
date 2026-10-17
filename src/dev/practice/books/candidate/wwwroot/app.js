const list = document.querySelector('#books');
const form = document.querySelector('#book-form');
const input = document.querySelector('#title');
const message = document.querySelector('#message');
async function loadBooks() {
  // TODO: fetch GET /api/books, response.json(), aggiornare #books con textContent.
}
form.addEventListener('submit', async (event) => {
  event.preventDefault();
  // TODO: fetch POST /api/books, body JSON { title: input.value }.
  // TODO: gestire successo/errore, svuotare campo, aggiornare lista.
});
loadBooks();
